#include "FFmpegDecoder.h"

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/error.h>
#include <libavutil/imgutils.h>
#include <libavutil/time.h>
#include <libswscale/swscale.h>
}

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <mutex>
#include <limits>
#include <optional>
#include <thread>

namespace {
constexpr std::int32_t kStatusError = -1;
constexpr std::int32_t kStatusPreparing = 1;
constexpr std::int32_t kStatusPlaying = 2;
constexpr std::int32_t kStatusPaused = 3;
constexpr std::int32_t kStatusEnded = 4;

std::string ffmpegError(int code) {
    char text[AV_ERROR_MAX_STRING_SIZE]{};
    av_strerror(code, text, sizeof(text));
    return text;
}
}

struct FFmpegDecoder::Impl {
    explicit Impl(std::string_view sourcePath) : path(sourcePath), worker([this] { run(); }) {}

    ~Impl() {
        stop.store(true, std::memory_order_release);
        control.notify_all();
        if (worker.joinable()) worker.join();
    }

    std::string path;
    std::thread worker;
    std::atomic<bool> stop{false};
    std::atomic<std::int32_t> playbackStatus{kStatusPreparing};
    std::atomic<std::int32_t> videoWidth{0};
    std::atomic<std::int32_t> videoHeight{0};
    std::atomic<float> videoDurationMs{0.0f};

    mutable std::mutex stateMutex;
    std::condition_variable control;
    std::condition_variable frameReady;
    bool playing = false;
    bool loop = false;
    float volume = 1.0f;
    double pausedPositionMs = 0.0;
    double clockBaseMs = 0.0;
    std::chrono::steady_clock::time_point clockStart{};
    std::optional<double> seekRequestMs;
    std::uint64_t controlGeneration = 0;
    std::optional<double> frameRequestMs;
    std::uint64_t frameRequestGeneration = 0;
    std::uint64_t frameCompletedGeneration = 0;
    bool frameRequestSucceeded = false;

    mutable std::mutex frameMutex;
    FFmpegVideoFrame currentFrame;
    std::array<std::shared_ptr<std::vector<std::uint8_t>>, 2> frameBuffers{
        std::make_shared<std::vector<std::uint8_t>>(),
        std::make_shared<std::vector<std::uint8_t>>()
    };
    mutable std::mutex errorMutex;
    std::string lastError;

    double currentPositionLocked(std::chrono::steady_clock::time_point now) const {
        if (!playing) return pausedPositionMs;
        const double elapsed = std::chrono::duration<double, std::milli>(now - clockStart).count();
        const double duration = videoDurationMs.load(std::memory_order_acquire);
        return duration > 0.0 ? std::min(clockBaseMs + elapsed, duration) : clockBaseMs + elapsed;
    }

    void setError(std::string message) {
        {
            std::lock_guard lock(errorMutex);
            lastError = std::move(message);
        }
        playbackStatus.store(kStatusError, std::memory_order_release);
    }

    static int interrupt(void* opaque) {
        return static_cast<Impl*>(opaque)->stop.load(std::memory_order_acquire) ? 1 : 0;
    }

    std::shared_ptr<std::vector<std::uint8_t>> acquireFrameBuffer(std::size_t size) {
        std::lock_guard lock(frameMutex);
        for (const auto& buffer : frameBuffers) {
            if (buffer.get() != currentFrame.pixels.get() && buffer.use_count() == 1) {
                buffer->resize(size);
                return buffer;
            }
        }
        auto replacement = std::make_shared<std::vector<std::uint8_t>>(size);
        frameBuffers[0] = replacement;
        return replacement;
    }

    void publishFrame(AVFrame* decoded, SwsContext*& scaler, double frameMs) {
        const int width = decoded->width;
        const int height = decoded->height;
        if (width <= 0 || height <= 0) {
            setError("The decoder produced an invalid frame size.");
            return;
        }
        scaler = sws_getCachedContext(scaler, width, height,
            static_cast<AVPixelFormat>(decoded->format), width, height, AV_PIX_FMT_NV12,
            SWS_BILINEAR, nullptr, nullptr, nullptr);
        if (!scaler) {
            setError("sws_getCachedContext failed.");
            return;
        }
        const int uvStride = (width + 1) & ~1;
        const auto maxSize = std::numeric_limits<std::size_t>::max();
        if (static_cast<std::size_t>(width) > maxSize / static_cast<std::size_t>(height)
            || static_cast<std::size_t>(uvStride) > maxSize / static_cast<std::size_t>((height + 1) / 2)) {
            setError("The decoded frame is too large.");
            return;
        }
        const std::size_t ySize = static_cast<std::size_t>(width) * static_cast<std::size_t>(height);
        const std::size_t uvSize = static_cast<std::size_t>(uvStride)
            * static_cast<std::size_t>((height + 1) / 2);
        if (ySize > maxSize - uvSize) {
            setError("The decoded frame is too large.");
            return;
        }
        auto pixels = acquireFrameBuffer(ySize + uvSize);
        std::uint8_t* output[] = {pixels->data(), pixels->data() + ySize, nullptr, nullptr};
        int outputStride[] = {width, uvStride, 0, 0};
        if (sws_scale(scaler, decoded->data, decoded->linesize, 0, height, output, outputStride) != height) {
            setError("sws_scale failed to convert the complete frame.");
            return;
        }
        std::lock_guard lock(frameMutex);
        currentFrame.pixels = std::move(pixels);
        currentFrame.width = width;
        currentFrame.height = height;
        currentFrame.yStride = outputStride[0];
        currentFrame.uvStride = outputStride[1];
        currentFrame.uvOffset = ySize;
        currentFrame.colourSpace = decoded->colorspace;
        currentFrame.fullRange = decoded->color_range == AVCOL_RANGE_JPEG;
        ++currentFrame.generation;
        (void)frameMs;
    }

    bool receiveFrame(AVFormatContext* format, AVCodecContext* codec, int streamIndex,
        AVPacket* packet, AVFrame* decoded, bool& inputEnded) {
        while (!stop.load(std::memory_order_acquire)) {
            int result = avcodec_receive_frame(codec, decoded);
            if (result == 0) return true;
            if (result == AVERROR_EOF) return false;
            if (result != AVERROR(EAGAIN)) {
                setError("avcodec_receive_frame failed: " + ffmpegError(result));
                return false;
            }
            if (inputEnded) {
                avcodec_send_packet(codec, nullptr);
                continue;
            }
            while ((result = av_read_frame(format, packet)) >= 0) {
                if (packet->stream_index != streamIndex) {
                    av_packet_unref(packet);
                    continue;
                }
                result = avcodec_send_packet(codec, packet);
                av_packet_unref(packet);
                if (result < 0 && result != AVERROR(EAGAIN)) {
                    setError("avcodec_send_packet failed: " + ffmpegError(result));
                    return false;
                }
                break;
            }
            if (result < 0) {
                inputEnded = true;
                avcodec_send_packet(codec, nullptr);
            }
        }
        return false;
    }

    void run() {
        AVFormatContext* format = avformat_alloc_context();
        if (!format) {
            setError("avformat_alloc_context failed.");
            return;
        }
        format->interrupt_callback = {interrupt, this};
        int result = avformat_open_input(&format, path.c_str(), nullptr, nullptr);
        if (result < 0) {
            setError("avformat_open_input failed: " + ffmpegError(result));
            avformat_free_context(format);
            return;
        }
        result = avformat_find_stream_info(format, nullptr);
        if (result < 0) {
            setError("avformat_find_stream_info failed: " + ffmpegError(result));
            avformat_close_input(&format);
            return;
        }
        const int streamIndex = av_find_best_stream(format, AVMEDIA_TYPE_VIDEO, -1, -1, nullptr, 0);
        if (streamIndex < 0) {
            setError("No decodable video stream was found.");
            avformat_close_input(&format);
            return;
        }
        AVStream* stream = format->streams[streamIndex];
        const AVCodec* decoder = avcodec_find_decoder(stream->codecpar->codec_id);
        if (!decoder) {
            setError("No FFmpeg decoder is available for this video codec.");
            avformat_close_input(&format);
            return;
        }
        AVCodecContext* codec = avcodec_alloc_context3(decoder);
        if (!codec) {
            setError("avcodec_alloc_context3 failed.");
            avformat_close_input(&format);
            return;
        }
        result = avcodec_parameters_to_context(codec, stream->codecpar);
        const unsigned hardwareThreads = std::max(1u, std::thread::hardware_concurrency());
        codec->thread_count = static_cast<int>(std::min(hardwareThreads, 4u));
        codec->thread_type = FF_THREAD_FRAME | FF_THREAD_SLICE;
        if (result >= 0) result = avcodec_open2(codec, decoder, nullptr);
        if (result < 0) {
            setError("avcodec_open2 failed: " + ffmpegError(result));
            avcodec_free_context(&codec);
            avformat_close_input(&format);
            return;
        }

        videoWidth.store(codec->width, std::memory_order_release);
        videoHeight.store(codec->height, std::memory_order_release);
        double duration = 0.0;
        if (format->duration != AV_NOPTS_VALUE) duration = format->duration * 1000.0 / AV_TIME_BASE;
        else if (stream->duration != AV_NOPTS_VALUE) duration = stream->duration * av_q2d(stream->time_base) * 1000.0;
        videoDurationMs.store(static_cast<float>(std::max(0.0, duration)), std::memory_order_release);
        playbackStatus.store(kStatusPaused, std::memory_order_release);

        AVPacket* packet = av_packet_alloc();
        AVFrame* decoded = av_frame_alloc();
        AVFrame* offlineCurrent = av_frame_alloc();
        AVFrame* offlineNext = av_frame_alloc();
        if (!packet || !decoded || !offlineCurrent || !offlineNext) {
            setError("Failed to allocate FFmpeg packet or frame storage.");
            av_frame_free(&offlineNext);
            av_frame_free(&offlineCurrent);
            av_frame_free(&decoded);
            av_packet_free(&packet);
            avcodec_free_context(&codec);
            avformat_close_input(&format);
            return;
        }
        SwsContext* scaler = nullptr;
        bool inputEnded = false;
        double discardBeforeMs = -1.0;
        bool publishPausedSeek = false;
        bool offlineInitialized = false;
        bool offlineEnded = false;
        double offlineCurrentMs = -1.0;
        double offlineNextMs = -1.0;
        double offlineLastTargetMs = -1.0;
        double offlinePublishedMs = -1.0;
        const std::int64_t streamStartTimestamp = stream->start_time == AV_NOPTS_VALUE ? 0 : stream->start_time;
        const double streamStartMs = streamStartTimestamp * av_q2d(stream->time_base) * 1000.0;

        const auto decodedFrameMs = [&](const AVFrame* frame, double fallback) {
            const std::int64_t timestamp = frame->best_effort_timestamp;
            if (timestamp == AV_NOPTS_VALUE) return std::max(0.0, fallback);
            return std::max(0.0, timestamp * av_q2d(stream->time_base) * 1000.0 - streamStartMs);
        };

        // Decode the first frame immediately so a newly opened paused video can be drawn.
        {
            std::lock_guard lock(stateMutex);
            seekRequestMs = 0.0;
        }

        while (!stop.load(std::memory_order_acquire)) {
            {
                std::unique_lock lock(stateMutex);
                control.wait(lock, [this] {
                    return stop.load(std::memory_order_acquire) || playing
                        || seekRequestMs.has_value() || frameRequestMs.has_value();
                });
                if (stop.load(std::memory_order_acquire)) break;
                if (frameRequestMs) {
                    const double target = *frameRequestMs;
                    const std::uint64_t requestGeneration = frameRequestGeneration;
                    frameRequestMs.reset();
                    const bool resetOffline = !offlineInitialized || target + 1.0 < offlineLastTargetMs;
                    lock.unlock();

                    bool requestSucceeded = true;
                    if (resetOffline) {
                        const std::int64_t timestamp = streamStartTimestamp + av_rescale_q(
                            static_cast<std::int64_t>(std::llround(target)), AVRational{1, 1000}, stream->time_base);
                        result = av_seek_frame(format, streamIndex, timestamp, AVSEEK_FLAG_BACKWARD);
                        if (result < 0) {
                            setError("av_seek_frame failed: " + ffmpegError(result));
                            requestSucceeded = false;
                        } else {
                            avcodec_flush_buffers(codec);
                            av_packet_unref(packet);
                            av_frame_unref(decoded);
                            av_frame_unref(offlineCurrent);
                            av_frame_unref(offlineNext);
                            inputEnded = false;
                            offlineEnded = false;
                            offlineCurrentMs = -1.0;
                            offlineNextMs = -1.0;
                            offlinePublishedMs = -1.0;
                            offlineInitialized = true;
                        }
                    }

                    const auto readOfflineNext = [&]() {
                        if (offlineNext->data[0] || offlineEnded) return offlineNext->data[0] != nullptr;
                        if (!receiveFrame(format, codec, streamIndex, packet, decoded, inputEnded)) {
                            offlineEnded = true;
                            return false;
                        }
                        offlineNextMs = decodedFrameMs(decoded, target);
                        av_frame_move_ref(offlineNext, decoded);
                        return true;
                    };

                    if (requestSucceeded && !offlineCurrent->data[0]) {
                        if (readOfflineNext()) {
                            av_frame_move_ref(offlineCurrent, offlineNext);
                            offlineCurrentMs = offlineNextMs;
                            offlineNextMs = -1.0;
                        } else {
                            requestSucceeded = false;
                        }
                    }
                    while (requestSucceeded && readOfflineNext() && offlineNextMs <= target + 0.5) {
                        av_frame_unref(offlineCurrent);
                        av_frame_move_ref(offlineCurrent, offlineNext);
                        offlineCurrentMs = offlineNextMs;
                        offlineNextMs = -1.0;
                    }
                    if (requestSucceeded && offlineCurrent->data[0]) {
                        if (offlinePublishedMs < 0.0 || std::abs(offlineCurrentMs - offlinePublishedMs) > 0.001) {
                            publishFrame(offlineCurrent, scaler, offlineCurrentMs);
                            offlinePublishedMs = offlineCurrentMs;
                        }
                        requestSucceeded = playbackStatus.load(std::memory_order_acquire) != kStatusError;
                    } else {
                        requestSucceeded = false;
                    }
                    offlineLastTargetMs = target;

                    lock.lock();
                    if (requestGeneration >= frameCompletedGeneration) {
                        frameCompletedGeneration = requestGeneration;
                        frameRequestSucceeded = requestSucceeded;
                    }
                    frameReady.notify_all();
                    continue;
                }
                if (seekRequestMs) {
                    const double target = *seekRequestMs;
                    seekRequestMs.reset();
                    const std::int64_t timestamp = streamStartTimestamp + av_rescale_q(
                        static_cast<std::int64_t>(std::llround(target)), AVRational{1, 1000}, stream->time_base);
                    lock.unlock();
                    result = av_seek_frame(format, streamIndex, timestamp, AVSEEK_FLAG_BACKWARD);
                    if (result < 0) {
                        setError("av_seek_frame failed: " + ffmpegError(result));
                        break;
                    }
                    avcodec_flush_buffers(codec);
                    av_packet_unref(packet);
                    av_frame_unref(decoded);
                    inputEnded = false;
                    discardBeforeMs = target;
                    lock.lock();
                    publishPausedSeek = !playing;
                }
            }

            if (!receiveFrame(format, codec, streamIndex, packet, decoded, inputEnded)) {
                if (playbackStatus.load(std::memory_order_acquire) == kStatusError) break;
                std::unique_lock lock(stateMutex);
                if (loop && !stop.load(std::memory_order_acquire)) {
                    seekRequestMs = 0.0;
                    pausedPositionMs = 0.0;
                    clockBaseMs = 0.0;
                    clockStart = std::chrono::steady_clock::now();
                    ++controlGeneration;
                    continue;
                }
                playing = false;
                pausedPositionMs = videoDurationMs.load(std::memory_order_acquire);
                playbackStatus.store(kStatusEnded, std::memory_order_release);
                continue;
            }

            const std::int64_t timestamp = decoded->best_effort_timestamp;
            double frameMs = 0.0;
            if (timestamp == AV_NOPTS_VALUE) {
                std::lock_guard lock(stateMutex);
                frameMs = currentPositionLocked(std::chrono::steady_clock::now());
            } else {
                frameMs = timestamp * av_q2d(stream->time_base) * 1000.0 - streamStartMs;
            }
            frameMs = std::max(0.0, frameMs);
            if (discardBeforeMs >= 0.0 && frameMs + 1.0 < discardBeforeMs) {
                av_frame_unref(decoded);
                continue;
            }
            discardBeforeMs = -1.0;

            bool skipFrame = false;
            {
                std::unique_lock lock(stateMutex);
                const std::uint64_t generation = controlGeneration;
                if (publishPausedSeek) {
                    pausedPositionMs = std::max(0.0, frameMs);
                    clockBaseMs = pausedPositionMs;
                    publishPausedSeek = false;
                } else {
                    while (playing && !seekRequestMs && generation == controlGeneration) {
                        const double clock = currentPositionLocked(std::chrono::steady_clock::now());
                        const double delay = frameMs - clock;
                        if (delay <= 2.0) {
                            skipFrame = clock - frameMs > 120.0;
                            break;
                        }
                        control.wait_for(lock, std::chrono::duration<double, std::milli>(std::min(delay, 20.0)));
                    }
                    if (!playing || seekRequestMs || generation != controlGeneration) skipFrame = true;
                }
            }
            if (!skipFrame) publishFrame(decoded, scaler, frameMs);
            av_frame_unref(decoded);
            if (playbackStatus.load(std::memory_order_acquire) == kStatusError) break;
        }

        sws_freeContext(scaler);
        av_frame_free(&offlineNext);
        av_frame_free(&offlineCurrent);
        av_frame_free(&decoded);
        av_packet_free(&packet);
        avcodec_free_context(&codec);
        avformat_close_input(&format);
    }
};

FFmpegDecoder::FFmpegDecoder(std::string_view path) : impl_(std::make_unique<Impl>(path)) {}
FFmpegDecoder::~FFmpegDecoder() = default;

bool FFmpegDecoder::play() {
    std::lock_guard lock(impl_->stateMutex);
    const auto status = impl_->playbackStatus.load(std::memory_order_acquire);
    if (status == kStatusError || status == kStatusPreparing) return false;
    if (status == kStatusEnded) impl_->seekRequestMs = 0.0;
    impl_->clockBaseMs = impl_->pausedPositionMs;
    impl_->clockStart = std::chrono::steady_clock::now();
    impl_->playing = true;
    ++impl_->controlGeneration;
    impl_->playbackStatus.store(kStatusPlaying, std::memory_order_release);
    impl_->control.notify_all();
    return true;
}

bool FFmpegDecoder::pause() {
    std::lock_guard lock(impl_->stateMutex);
    if (!impl_->playing) return impl_->playbackStatus.load(std::memory_order_acquire) == kStatusPaused;
    impl_->pausedPositionMs = impl_->currentPositionLocked(std::chrono::steady_clock::now());
    impl_->playing = false;
    ++impl_->controlGeneration;
    impl_->playbackStatus.store(kStatusPaused, std::memory_order_release);
    impl_->control.notify_all();
    return true;
}

bool FFmpegDecoder::seek(float positionMs) {
    if (!std::isfinite(positionMs)) return false;
    std::lock_guard lock(impl_->stateMutex);
    const double duration = impl_->videoDurationMs.load(std::memory_order_acquire);
    const double requested = std::max(0.0, static_cast<double>(positionMs));
    const double target = duration > 0.0 ? std::min(requested, duration) : requested;
    impl_->pausedPositionMs = target;
    impl_->clockBaseMs = target;
    impl_->clockStart = std::chrono::steady_clock::now();
    impl_->seekRequestMs = target;
    ++impl_->controlGeneration;
    if (impl_->playbackStatus.load(std::memory_order_acquire) == kStatusEnded) {
        impl_->playbackStatus.store(impl_->playing ? kStatusPlaying : kStatusPaused, std::memory_order_release);
    }
    impl_->control.notify_all();
    return true;
}

bool FFmpegDecoder::prepareFrame(float positionMs, float timeoutMs) {
    if (!std::isfinite(positionMs) || !std::isfinite(timeoutMs) || timeoutMs <= 0.0f) return false;
    std::unique_lock lock(impl_->stateMutex);
    const auto status = impl_->playbackStatus.load(std::memory_order_acquire);
    if (status == kStatusError || status == kStatusPreparing) return false;
    const double duration = impl_->videoDurationMs.load(std::memory_order_acquire);
    const double requested = std::max(0.0, static_cast<double>(positionMs));
    const double target = duration > 0.0 ? std::min(requested, duration) : requested;
    impl_->playing = false;
    impl_->seekRequestMs.reset();
    impl_->pausedPositionMs = target;
    impl_->clockBaseMs = target;
    impl_->frameRequestMs = target;
    const std::uint64_t requestGeneration = ++impl_->frameRequestGeneration;
    ++impl_->controlGeneration;
    impl_->playbackStatus.store(kStatusPaused, std::memory_order_release);
    impl_->control.notify_all();
    const bool completed = impl_->frameReady.wait_for(lock,
        std::chrono::duration<double, std::milli>(timeoutMs), [this, requestGeneration] {
            return impl_->frameCompletedGeneration >= requestGeneration
                || impl_->playbackStatus.load(std::memory_order_acquire) == kStatusError
                || impl_->stop.load(std::memory_order_acquire);
        });
    return completed && impl_->frameCompletedGeneration >= requestGeneration
        && impl_->frameRequestSucceeded;
}

bool FFmpegDecoder::setLoop(bool enabled) {
    std::lock_guard lock(impl_->stateMutex);
    impl_->loop = enabled;
    return true;
}

bool FFmpegDecoder::setVolume(float volume) {
    if (!std::isfinite(volume)) return false;
    std::lock_guard lock(impl_->stateMutex);
    impl_->volume = std::clamp(volume, 0.0f, 1.0f);
    return true;
}

std::int32_t FFmpegDecoder::status() const { return impl_->playbackStatus.load(std::memory_order_acquire); }
float FFmpegDecoder::durationMs() const { return impl_->videoDurationMs.load(std::memory_order_acquire); }

float FFmpegDecoder::positionMs() const {
    std::lock_guard lock(impl_->stateMutex);
    return static_cast<float>(impl_->currentPositionLocked(std::chrono::steady_clock::now()));
}

std::int32_t FFmpegDecoder::width() const { return impl_->videoWidth.load(std::memory_order_acquire); }
std::int32_t FFmpegDecoder::height() const { return impl_->videoHeight.load(std::memory_order_acquire); }

std::string FFmpegDecoder::error() const {
    std::lock_guard lock(impl_->errorMutex);
    return impl_->lastError;
}

FFmpegVideoFrame FFmpegDecoder::frame() const {
    std::lock_guard lock(impl_->frameMutex);
    return impl_->currentFrame;
}
