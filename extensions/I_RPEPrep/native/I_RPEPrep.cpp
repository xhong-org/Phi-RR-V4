#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <Windows.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <limits>
#include <vector>

#define GMEXPORT extern "C" __declspec(dllexport)

namespace {

struct BpmSeg {
    double startBeat = 0;
    double endBeat = 0;
    double bpm = 140;
    double floorSec = 0;
};

struct SpeedEv {
    double startTime = 0;
    double endTime = 0;
    double start = 0;
    double stop = 0;
};

struct Fitted {
    double startSec = 0;
    double endSec = 0;
    double value = 0;
    double endValue = 0;
    double floorPosition = 0;
};

std::vector<BpmSeg> g_bpm;

bool read_u32(const uint8_t*& p, const uint8_t* end, uint32_t& out) {
    if (!p || end - p < 4) return false;
    uint32_t value = 0;
    std::memcpy(&value, p, 4);
    p += 4;
    out = value;
    return true;
}

bool read_f64(const uint8_t*& p, const uint8_t* end, double& out) {
    if (!p || end - p < 8) return false;
    std::memcpy(&out, p, 8);
    p += 8;
    return true;
}

int segment_at_beat(double beat) {
    const int n = static_cast<int>(g_bpm.size());
    if (n <= 0) return 0;
    int low = 0;
    int high = n;
    while (low < high) {
        const int mid = (low + high) / 2;
        if (g_bpm[mid].startBeat <= beat) low = mid + 1;
        else high = mid;
    }
    return (low > 0) ? (low - 1) : 0;
}

double beat_to_sec(double beat) {
    if (g_bpm.empty()) return beat * (60.0 / 140.0);
    const BpmSeg& seg = g_bpm[segment_at_beat(beat)];
    const double bpm = (seg.bpm > 0) ? seg.bpm : 140.0;
    return seg.floorSec + (beat - seg.startBeat) * (60.0 / bpm);
}

double layer_value(const std::vector<SpeedEv>& layer, double beat, bool use_left_limit) {
    if (layer.empty()) return 0;
    double result = layer[0].start;
    for (const auto& ev : layer) {
        if (beat < ev.startTime) break;
        if (use_left_limit && beat == ev.startTime) break;
        if (beat >= ev.endTime) result = ev.stop;
        else {
            const double span = ev.endTime - ev.startTime;
            if (span <= 0) result = ev.stop;
            else result = ev.start + (beat - ev.startTime) * ((ev.stop - ev.start) / span);
        }
    }
    return result;
}

} // namespace

GMEXPORT double __EXT_NATIVE__i_rpe_prep_available() {
    return 1;
}

GMEXPORT double __EXT_NATIVE__i_rpe_prep_set_bpm(char* data, double length) {
    g_bpm.clear();
    if (!data || length < 4) return 0;
    const auto* p = reinterpret_cast<const uint8_t*>(data);
    const auto* end = p + static_cast<size_t>(length);
    uint32_t count = 0;
    if (!read_u32(p, end, count) || count > 4096) return 0;
    g_bpm.reserve(count);
    for (uint32_t i = 0; i < count; ++i) {
        BpmSeg seg;
        if (!read_f64(p, end, seg.startBeat) || !read_f64(p, end, seg.endBeat)
            || !read_f64(p, end, seg.bpm) || !read_f64(p, end, seg.floorSec)) {
            g_bpm.clear();
            return 0;
        }
        g_bpm.push_back(seg);
    }
    return 1;
}

GMEXPORT double __EXT_NATIVE__i_rpe_prep_speed_fit(char* in_data, double in_len, char* out_data, double out_len) {
    if (!in_data || !out_data || in_len < 4 || out_len < 4) return 0;
    const auto* p = reinterpret_cast<const uint8_t*>(in_data);
    const auto* end = p + static_cast<size_t>(in_len);
    uint32_t layer_count = 0;
    if (!read_u32(p, end, layer_count) || layer_count > 256) return 0;
    std::vector<std::vector<SpeedEv>> layers;
    layers.reserve(layer_count);
    std::vector<double> splits;
    for (uint32_t li = 0; li < layer_count; ++li) {
        uint32_t n = 0;
        if (!read_u32(p, end, n) || n > 100000) return 0;
        std::vector<SpeedEv> layer;
        layer.reserve(n);
        for (uint32_t i = 0; i < n; ++i) {
            SpeedEv ev;
            if (!read_f64(p, end, ev.startTime) || !read_f64(p, end, ev.endTime)
                || !read_f64(p, end, ev.start) || !read_f64(p, end, ev.stop)) return 0;
            layer.push_back(ev);
            splits.push_back(ev.startTime);
            splits.push_back(ev.endTime);
        }
        layers.push_back(std::move(layer));
    }
    std::sort(splits.begin(), splits.end());
    struct BeatFit { double startTime; double endTime; double start; double stop; };
    std::vector<BeatFit> beat_fitted;
    for (size_t i = 0; i + 1 < splits.size(); ++i) {
        const double split_start = splits[i];
        const double split_end = splits[i + 1];
        if (split_start == split_end) continue;
        double value_start = 0;
        double value_end = 0;
        for (const auto& layer : layers) {
            value_start += layer_value(layer, split_start, false);
            value_end += layer_value(layer, split_end, true);
        }
        beat_fitted.push_back({split_start, split_end, value_start, value_end});
    }
    std::vector<Fitted> fitted;
    for (size_t fsi = 0; fsi < beat_fitted.size(); ++fsi) {
        const auto& row = beat_fitted[fsi];
        double sample_start_sec = beat_to_sec(row.startTime);
        if (!std::isfinite(sample_start_sec)) continue;
        double sample_end_sec = beat_to_sec(row.endTime);
        if (fsi + 1 < beat_fitted.size()) {
            const double next_start_sec = beat_to_sec(beat_fitted[fsi + 1].startTime);
            if (std::isfinite(next_start_sec) && next_start_sec > sample_start_sec) {
                sample_end_sec = next_start_sec;
            }
        }
        if (!std::isfinite(sample_end_sec) || sample_end_sec <= sample_start_sec) continue;
        Fitted out;
        out.startSec = sample_start_sec;
        out.endSec = sample_end_sec;
        out.value = row.start / 4.5;
        out.endValue = row.stop / 4.5;
        fitted.push_back(out);
    }
    double speed_floor = 0;
    for (auto& row : fitted) {
        row.floorPosition = speed_floor;
        speed_floor += (row.endSec - row.startSec) * (row.value + row.endValue) * 0.5;
    }
    if (!fitted.empty() && std::isfinite(fitted.back().endSec)) {
        Fitted tail = fitted.back();
        Fitted last;
        last.startSec = tail.endSec;
        last.endSec = std::numeric_limits<double>::infinity();
        last.value = tail.endValue;
        last.endValue = tail.endValue;
        last.floorPosition = speed_floor;
        fitted.push_back(last);
    }
    const size_t bytes = 4 + fitted.size() * 40;
    if (bytes > static_cast<size_t>(out_len)) return 0;
    auto* out = reinterpret_cast<uint8_t*>(out_data);
    const uint32_t n = static_cast<uint32_t>(fitted.size());
    std::memcpy(out, &n, 4);
    out += 4;
    for (const auto& row : fitted) {
        std::memcpy(out, &row.startSec, 8); out += 8;
        std::memcpy(out, &row.endSec, 8); out += 8;
        std::memcpy(out, &row.value, 8); out += 8;
        std::memcpy(out, &row.endValue, 8); out += 8;
        std::memcpy(out, &row.floorPosition, 8); out += 8;
    }
    return static_cast<double>(bytes);
}
