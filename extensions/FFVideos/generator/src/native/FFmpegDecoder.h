#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

struct FFmpegVideoFrame {
    std::shared_ptr<const std::vector<std::uint8_t>> pixels;
    std::int32_t width = 0;
    std::int32_t height = 0;
    std::int32_t yStride = 0;
    std::int32_t uvStride = 0;
    std::size_t uvOffset = 0;
    std::int32_t colourSpace = 0;
    bool fullRange = false;
    std::uint64_t generation = 0;
};

class FFmpegDecoder {
public:
    explicit FFmpegDecoder(std::string_view path);
    ~FFmpegDecoder();

    FFmpegDecoder(const FFmpegDecoder&) = delete;
    FFmpegDecoder& operator=(const FFmpegDecoder&) = delete;

    bool play();
    bool pause();
    bool seek(float positionMs);
    bool prepareFrame(float positionMs, float timeoutMs);
    bool setLoop(bool enabled);
    bool setVolume(float volume);

    std::int32_t status() const;
    float durationMs() const;
    float positionMs() const;
    std::int32_t width() const;
    std::int32_t height() const;
    std::string error() const;
    FFmpegVideoFrame frame() const;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};
