#pragma once

#include <cstdint>
#include <cstring>
#include <fstream>
#include <string>
#include <string_view>
#include <vector>

inline bool magic_starts_with(const std::uint8_t* data, std::size_t size, const char* sig, std::size_t sig_size) {
    return size >= sig_size && std::memcmp(data, sig, sig_size) == 0;
}

inline bool magic_equals_u32_le(const std::uint8_t* data, std::size_t size, std::uint32_t value) {
    if (size < 4) return false;
    const std::uint32_t got = static_cast<std::uint32_t>(data[0] | (data[1] << 8) | (data[2] << 16) | (data[3] << 24));
    return got == value;
}

inline std::string archive_kind_from_header(const std::uint8_t* data, std::size_t size) {
    if (size >= 6 && data[0] == 0x37 && data[1] == 0x7A && data[2] == 0xBC && data[3] == 0xAF
        && data[4] == 0x27 && data[5] == 0x1C) {
        return "7z";
    }
    if (magic_starts_with(data, size, "Rar!\x1A\x07\x01\x00", 8)) return "rar";
    if (magic_starts_with(data, size, "Rar!\x1A\x07\x00", 7)) return "rar";
    if (magic_equals_u32_le(data, size, 0x04034b50u) || magic_equals_u32_le(data, size, 0x06054b50u)
        || magic_equals_u32_le(data, size, 0x08074b50u) || magic_equals_u32_le(data, size, 0x02014b50u)) {
        return "zip";
    }
    if (size >= 4 && data[0] == 0x50 && data[1] == 0x4B && (data[2] == 0x03 || data[2] == 0x05 || data[2] == 0x07)) {
        return "zip";
    }
    if (size >= 6 && data[0] == 0xFD && data[1] == 0x37 && data[2] == 0x7A && data[3] == 0x58
        && data[4] == 0x5A && data[5] == 0x00) {
        return "xz";
    }
    if (size >= 3 && data[0] == 0x1F && data[1] == 0x8B) return "gzip";
    if (size >= 3 && data[0] == 'B' && data[1] == 'Z' && data[2] == 'h') return "bzip2";
    if (size >= 4 && data[0] == 0x28 && data[1] == 0xB5 && data[2] == 0x2F && data[3] == 0xFD) return "zstd";
    if (size >= 262) {
        if (std::memcmp(data + 257, "ustar", 5) == 0) return "tar";
    }
    if (size >= 8 && std::memcmp(data, "\x89PNG\r\n\x1A\n", 8) == 0) return "unknown";
    return "unknown";
}

inline bool read_file_prefix(const std::string& path, std::vector<std::uint8_t>* out, std::size_t max_bytes) {
    std::ifstream input(path, std::ios::binary);
    if (!input) return false;
    out->assign(max_bytes, 0);
    input.read(reinterpret_cast<char*>(out->data()), static_cast<std::streamsize>(max_bytes));
    out->resize(static_cast<std::size_t>(input.gcount()));
    return !out->empty() || input.eof();
}

inline std::string detect_archive_kind_from_path(std::string_view path) {
    std::vector<std::uint8_t> header;
    if (!read_file_prefix(std::string(path), &header, 512)) return "unknown";
    return archive_kind_from_header(header.data(), header.size());
}
