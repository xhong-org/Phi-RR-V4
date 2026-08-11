#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <Windows.h>
#include <d3d11.h>
#include <dxgi.h>
#include <wrl/client.h>
#include "../third_party/ffnvcodec/nvEncodeAPI.h"
#include "../third_party/amf/AMFMinimal.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <deque>
#include <iterator>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace {
using Microsoft::WRL::ComPtr;

HANDLE g_process = nullptr;
HANDLE g_thread = nullptr;
HANDLE g_stdin = nullptr;
std::string g_error;
int g_width = 0;
int g_height = 0;
double g_fps = 0.0;
int g_crf = 18;
std::string g_ffmpeg = "ffmpeg.exe";
std::string g_preset = "medium";
std::string g_encoder = "auto";
std::string g_active_encoder = "x264";
std::string g_audio_path;
double g_audio_delay_seconds = 0.0;
ComPtr<ID3D11Device> g_device;
ComPtr<ID3D11DeviceContext> g_context;
ComPtr<ID3D11Texture2D> g_resolved;
std::array<ComPtr<ID3D11Texture2D>, 2> g_staging;
DXGI_FORMAT g_capture_format = DXGI_FORMAT_UNKNOWN;
UINT g_capture_width = 0;
UINT g_capture_height = 0;
UINT g_capture_samples = 0;
std::vector<std::uint8_t> g_row;
std::string g_output_path;
std::uint64_t g_captured_frames = 0;
bool g_pipe_bgra = false;
constexpr UINT kNoStagingSlot = UINT_MAX;
UINT g_next_staging_slot = 0;
UINT g_pending_staging_slot = kNoStagingSlot;

struct HitSoundEvent {
    std::string path;
    double time = 0.0;
    double volume = 0.7;
};

std::vector<HitSoundEvent> g_hitsounds;

struct NvencSlot {
    ComPtr<ID3D11Texture2D> texture;
    NV_ENC_REGISTERED_PTR registered = nullptr;
    NV_ENC_INPUT_PTR mapped = nullptr;
    NV_ENC_OUTPUT_PTR bitstream = nullptr;
};

struct NvencState {
    HMODULE library = nullptr;
    NV_ENCODE_API_FUNCTION_LIST functions{};
    void* encoder = nullptr;
    HANDLE output = INVALID_HANDLE_VALUE;
    std::wstring raw_path;
    std::array<NvencSlot, 4> slots;
    std::deque<UINT> pending;
    UINT next_slot = 0;
    std::uint64_t frame_index = 0;
    NV_ENC_BUFFER_FORMAT buffer_format = NV_ENC_BUFFER_FORMAT_UNDEFINED;
    bool active = false;
};

NvencState g_nvenc;

struct AmfState {
    struct Timing {
        amf_pts pts = 0;
        amf_pts duration = 0;
    };
    HMODULE library = nullptr;
    amf::AMFFactory* factory = nullptr;
    amf::AMFContext* context = nullptr;
    amf::AMFComponent* converter = nullptr;
    amf::AMFComponent* encoder = nullptr;
    HANDLE output = INVALID_HANDLE_VALUE;
    std::wstring raw_path;
    std::uint64_t frame_index = 0;
    std::deque<Timing> pending_timings;
    amf::AMF_SURFACE_FORMAT input_format = amf::AMF_SURFACE_UNKNOWN;
    DXGI_FORMAT texture_format = DXGI_FORMAT_UNKNOWN;
    bool active = false;
};

AmfState g_amf;

std::wstring utf8_to_wide(std::string_view value) {
    if (value.empty()) return {};
    const int size = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(),
        static_cast<int>(value.size()), nullptr, 0);
    if (size <= 0) return {};
    std::wstring result(static_cast<std::size_t>(size), L'\0');
    MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(),
        static_cast<int>(value.size()), result.data(), size);
    return result;
}

std::wstring quote(std::wstring_view value) {
    std::wstring result = L"\"";
    unsigned backslashes = 0;
    for (const wchar_t character : value) {
        if (character == L'\\') {
            ++backslashes;
            continue;
        }
        if (character == L'\"') {
            result.append(backslashes * 2 + 1, L'\\');
            result.push_back(character);
            backslashes = 0;
            continue;
        }
        result.append(backslashes, L'\\');
        backslashes = 0;
        result.push_back(character);
    }
    result.append(backslashes * 2, L'\\');
    result.push_back(L'\"');
    return result;
}

void close_handles() {
    if (g_stdin) CloseHandle(g_stdin);
    if (g_thread) CloseHandle(g_thread);
    if (g_process) CloseHandle(g_process);
    g_stdin = nullptr;
    g_thread = nullptr;
    g_process = nullptr;
}

void reset_capture_resources() {
    g_resolved.Reset();
    for (auto& staging : g_staging) staging.Reset();
    g_capture_format = DXGI_FORMAT_UNKNOWN;
    g_capture_width = 0;
    g_capture_height = 0;
    g_capture_samples = 0;
    g_next_staging_slot = 0;
    g_pending_staging_slot = kNoStagingSlot;
    g_row.clear();
}

bool select_pipe_format() {
    if (!g_context) return false;
    ComPtr<ID3D11RenderTargetView> target_view;
    g_context->OMGetRenderTargets(1, &target_view, nullptr);
    if (!target_view) return false;
    D3D11_RENDER_TARGET_VIEW_DESC view_desc{};
    target_view->GetDesc(&view_desc);
    switch (view_desc.Format) {
        case DXGI_FORMAT_B8G8R8A8_UNORM:
        case DXGI_FORMAT_B8G8R8A8_UNORM_SRGB:
        case DXGI_FORMAT_B8G8R8X8_UNORM:
        case DXGI_FORMAT_B8G8R8X8_UNORM_SRGB:
            g_pipe_bgra = true;
            return true;
        case DXGI_FORMAT_R8G8B8A8_UNORM:
        case DXGI_FORMAT_R8G8B8A8_UNORM_SRGB:
            g_pipe_bgra = false;
            return true;
        default:
            return false;
    }
}

UINT adapter_vendor_id() {
    if (!g_device) return 0;
    ComPtr<IDXGIDevice> dxgi_device;
    ComPtr<IDXGIAdapter> adapter;
    DXGI_ADAPTER_DESC description{};
    if (FAILED(g_device.As(&dxgi_device)) || !dxgi_device
        || FAILED(dxgi_device->GetAdapter(&adapter)) || !adapter
        || FAILED(adapter->GetDesc(&description))) return 0;
    return description.VendorId;
}

bool write_pipe_bytes(const void* data, std::size_t byte_count) {
    const auto* bytes = static_cast<const std::uint8_t*>(data);
    std::size_t written_total = 0;
    while (written_total < byte_count) {
        const DWORD chunk = static_cast<DWORD>(std::min<std::size_t>(
            byte_count - written_total, 16u * 1024u * 1024u));
        DWORD written = 0;
        if (!WriteFile(g_stdin, bytes + written_total, chunk, &written, nullptr) || written == 0) {
            g_error = "Unable to write a video frame to FFmpeg.";
            return false;
        }
        written_total += written;
    }
    return true;
}

bool ensure_capture_resources(ID3D11Texture2D* target, DXGI_FORMAT view_format) {
    D3D11_TEXTURE2D_DESC source{};
    target->GetDesc(&source);
    if (g_staging[0] && g_staging[1]
        && g_capture_width == source.Width && g_capture_height == source.Height
        && g_capture_samples == source.SampleDesc.Count && g_capture_format == view_format) {
        return true;
    }

    reset_capture_resources();
    D3D11_TEXTURE2D_DESC staging = source;
    staging.MipLevels = 1;
    staging.ArraySize = 1;
    staging.SampleDesc.Count = 1;
    staging.SampleDesc.Quality = 0;
    staging.Usage = D3D11_USAGE_STAGING;
    staging.BindFlags = 0;
    staging.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    staging.MiscFlags = 0;
    for (auto& staging_texture : g_staging) {
        if (FAILED(g_device->CreateTexture2D(&staging, nullptr, &staging_texture))) {
            g_error = "Unable to create the D3D11 staging textures.";
            reset_capture_resources();
            return false;
        }
    }

    if (source.SampleDesc.Count > 1) {
        D3D11_TEXTURE2D_DESC resolved = source;
        resolved.MipLevels = 1;
        resolved.ArraySize = 1;
        resolved.SampleDesc.Count = 1;
        resolved.SampleDesc.Quality = 0;
        resolved.Usage = D3D11_USAGE_DEFAULT;
        resolved.BindFlags = 0;
        resolved.CPUAccessFlags = 0;
        resolved.MiscFlags = 0;
        if (FAILED(g_device->CreateTexture2D(&resolved, nullptr, &g_resolved))) {
            g_error = "Unable to create the D3D11 resolve texture.";
            reset_capture_resources();
            return false;
        }
    }

    g_capture_width = source.Width;
    g_capture_height = source.Height;
    g_capture_samples = source.SampleDesc.Count;
    g_capture_format = view_format;
    return true;
}

bool write_staging_frame(UINT slot) {
    if (slot >= g_staging.size() || !g_staging[slot]) {
        g_error = "The pending D3D11 staging frame is unavailable.";
        return false;
    }
    D3D11_MAPPED_SUBRESOURCE mapped{};
    if (FAILED(g_context->Map(g_staging[slot].Get(), 0, D3D11_MAP_READ, 0, &mapped))) {
        g_error = "Unable to map the D3D11 staging texture.";
        return false;
    }

    const bool rgba = g_capture_format == DXGI_FORMAT_R8G8B8A8_UNORM
        || g_capture_format == DXGI_FORMAT_R8G8B8A8_UNORM_SRGB;
    const bool bgra = g_capture_format == DXGI_FORMAT_B8G8R8A8_UNORM
        || g_capture_format == DXGI_FORMAT_B8G8R8A8_UNORM_SRGB;
    const bool bgrx = g_capture_format == DXGI_FORMAT_B8G8R8X8_UNORM
        || g_capture_format == DXGI_FORMAT_B8G8R8X8_UNORM_SRGB;
    if (!rgba && !bgra && !bgrx) {
        g_context->Unmap(g_staging[slot].Get(), 0);
        g_error = "Unsupported D3D11 render-target pixel format.";
        return false;
    }

    bool success = true;
    const std::size_t row_bytes = static_cast<std::size_t>(g_capture_width) * 4u;
    const bool direct = (g_pipe_bgra && (bgra || bgrx)) || (!g_pipe_bgra && rgba);
    if (direct && mapped.RowPitch == row_bytes) {
        success = write_pipe_bytes(mapped.pData, row_bytes * g_capture_height);
    } else {
        constexpr std::size_t transfer_bytes = 4u * 1024u * 1024u;
        const UINT rows_per_chunk = static_cast<UINT>(std::max<std::size_t>(
            1, transfer_bytes / row_bytes));
        g_row.resize(static_cast<std::size_t>(rows_per_chunk) * row_bytes);
        for (UINT first_y = 0; first_y < g_capture_height && success; first_y += rows_per_chunk) {
            const UINT row_count = std::min(rows_per_chunk, g_capture_height - first_y);
            for (UINT local_y = 0; local_y < row_count; ++local_y) {
                const auto* row = static_cast<const std::uint8_t*>(mapped.pData)
                    + static_cast<std::size_t>(first_y + local_y) * mapped.RowPitch;
                auto* destination = g_row.data() + static_cast<std::size_t>(local_y) * row_bytes;
                if (direct) {
                    std::memcpy(destination, row, row_bytes);
                    continue;
                }
                for (UINT x = 0; x < g_capture_width; ++x) {
                    const std::size_t pixel = static_cast<std::size_t>(x) * 4u;
                    destination[pixel] = row[pixel + 2];
                    destination[pixel + 1] = row[pixel + 1];
                    destination[pixel + 2] = row[pixel];
                    destination[pixel + 3] = bgrx ? 255u : row[pixel + 3];
                }
            }
            success = write_pipe_bytes(g_row.data(), static_cast<std::size_t>(row_count) * row_bytes);
        }
    }
    g_context->Unmap(g_staging[slot].Get(), 0);
    return success;
}

bool flush_pending_capture() {
    if (g_pending_staging_slot == kNoStagingSlot) return true;
    const UINT slot = g_pending_staging_slot;
    g_pending_staging_slot = kNoStagingSlot;
    return write_staging_frame(slot);
}

double finish_process() {
    if (!g_process) return 1.0;
    if (g_stdin) {
        CloseHandle(g_stdin);
        g_stdin = nullptr;
    }
    WaitForSingleObject(g_process, INFINITE);
    DWORD exit_code = 1;
    GetExitCodeProcess(g_process, &exit_code);
    close_handles();
    if (exit_code != 0) {
        g_error = "FFmpeg exited with code " + std::to_string(exit_code) + ".";
        return 0.0;
    }
    return 1.0;
}

bool run_process(std::wstring command) {
    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    startup.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
    startup.wShowWindow = SW_HIDE;
    startup.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
    startup.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
    startup.hStdError = GetStdHandle(STD_ERROR_HANDLE);
    PROCESS_INFORMATION process{};
    if (!CreateProcessW(nullptr, command.data(), nullptr, nullptr, TRUE, CREATE_NO_WINDOW,
        nullptr, nullptr, &startup, &process)) {
        g_error = "Unable to start FFmpeg hitsound mixing (Win32 error "
            + std::to_string(GetLastError()) + ").";
        return false;
    }
    CloseHandle(process.hThread);
    WaitForSingleObject(process.hProcess, INFINITE);
    DWORD exit_code = 1;
    GetExitCodeProcess(process.hProcess, &exit_code);
    CloseHandle(process.hProcess);
    if (exit_code != 0) {
        g_error = "FFmpeg hitsound mixing exited with code " + std::to_string(exit_code) + ".";
        return false;
    }
    return true;
}

std::string preferred_hardware_encoder() {
    switch (adapter_vendor_id()) {
        case 0x10DE: return "nvenc";
        case 0x1002:
        case 0x1022: return "amf";
        case 0x8086: return "qsv";
        default: return "x264";
    }
}

std::wstring encoder_codec_name(std::string_view encoder) {
    if (encoder == "nvenc") return L"h264_nvenc";
    if (encoder == "amf") return L"h264_amf";
    if (encoder == "qsv") return L"h264_qsv";
    return L"libx264";
}

bool probe_hardware_encoder(std::string_view encoder) {
    if (encoder == "x264") return true;
    const std::string previous_error = g_error;
    std::wstring command = quote(utf8_to_wide(g_ffmpeg))
        + L" -hide_banner -loglevel error -f lavfi -i "
          L"\"color=size=64x64:rate=1:duration=0.1\" -frames:v 1 -vf format=nv12 -c:v "
        + encoder_codec_name(encoder) + L" -f null NUL";
    const bool available = run_process(std::move(command));
    g_error = previous_error;
    return available;
}

std::wstring nvenc_preset() {
    if (g_preset == "ultrafast" || g_preset == "superfast") return L"p1";
    if (g_preset == "veryfast" || g_preset == "faster") return L"p2";
    if (g_preset == "fast") return L"p3";
    if (g_preset == "slow") return L"p5";
    if (g_preset == "slower") return L"p6";
    if (g_preset == "veryslow") return L"p7";
    return L"p4";
}

std::wstring hardware_encoder_options() {
    const std::wstring quality = std::to_wstring(g_crf);
    if (g_active_encoder == "nvenc") {
        return L" -c:v h264_nvenc -preset " + nvenc_preset()
            + L" -tune hq -rc vbr -cq " + quality + L" -b:v 0";
    }
    if (g_active_encoder == "amf") {
        const wchar_t* quality_mode = (g_preset == "ultrafast" || g_preset == "superfast"
            || g_preset == "veryfast") ? L"speed" : (g_preset == "slow"
            || g_preset == "slower" || g_preset == "veryslow") ? L"quality" : L"balanced";
        return L" -c:v h264_amf -quality " + std::wstring(quality_mode)
            + L" -rc cqp -qp_i " + quality + L" -qp_p " + quality + L" -qp_b " + quality;
    }
    if (g_active_encoder == "qsv") {
        const wchar_t* preset = (g_preset == "ultrafast" || g_preset == "superfast")
            ? L"veryfast" : (g_preset == "slow" || g_preset == "slower"
            || g_preset == "veryslow") ? L"slow" : L"medium";
        return L" -c:v h264_qsv -preset " + std::wstring(preset)
            + L" -global_quality " + quality;
    }
    return L" -c:v libx264 -preset " + utf8_to_wide(g_preset)
        + L" -crf " + quality;
}

bool write_file_bytes(HANDLE file, const void* data, std::size_t byte_count) {
    const auto* bytes = static_cast<const std::uint8_t*>(data);
    std::size_t written_total = 0;
    while (written_total < byte_count) {
        const DWORD chunk = static_cast<DWORD>(std::min<std::size_t>(
            byte_count - written_total, 16u * 1024u * 1024u));
        DWORD written = 0;
        if (!WriteFile(file, bytes + written_total, chunk, &written, nullptr) || written == 0) {
            g_error = "Unable to write the temporary hitsound PCM track.";
            return false;
        }
        written_total += written;
    }
    return true;
}

bool mux_h264_bitstream(const std::wstring& raw_path) {
    const std::wstring output = utf8_to_wide(g_output_path);
    std::wstring command = quote(utf8_to_wide(g_ffmpeg))
        + L" -hide_banner -loglevel warning -y -fflags +genpts -r "
        + std::to_wstring(g_fps) + L" -i " + quote(raw_path)
        + L" -itsoffset " + std::to_wstring(g_audio_delay_seconds)
        + L" -i " + quote(utf8_to_wide(g_audio_path))
        + L" -map 0:v:0 -map 1:a:0? -c:v copy -c:a aac -b:a 192k"
          L" -movflags +faststart " + quote(output);
    return run_process(std::move(command));
}

const GUID& nvenc_preset_guid() {
    if (g_preset == "ultrafast" || g_preset == "superfast") return NV_ENC_PRESET_P1_GUID;
    if (g_preset == "veryfast" || g_preset == "faster") return NV_ENC_PRESET_P2_GUID;
    if (g_preset == "fast") return NV_ENC_PRESET_P3_GUID;
    if (g_preset == "slow") return NV_ENC_PRESET_P5_GUID;
    if (g_preset == "slower") return NV_ENC_PRESET_P6_GUID;
    if (g_preset == "veryslow") return NV_ENC_PRESET_P7_GUID;
    return NV_ENC_PRESET_P4_GUID;
}

std::string nvenc_status_text(NVENCSTATUS status) {
    if (g_nvenc.encoder && g_nvenc.functions.nvEncGetLastErrorString) {
        if (const char* detail = g_nvenc.functions.nvEncGetLastErrorString(g_nvenc.encoder)) {
            if (*detail) return detail;
        }
    }
    return "NVENC status " + std::to_string(static_cast<int>(status));
}

bool nvenc_check(NVENCSTATUS status, const char* operation) {
    if (status == NV_ENC_SUCCESS) return true;
    g_error = std::string(operation) + " failed: " + nvenc_status_text(status) + ".";
    return false;
}

void reset_nvenc(bool delete_raw) {
    if (g_nvenc.encoder) {
        for (auto& slot : g_nvenc.slots) {
            if (slot.mapped && g_nvenc.functions.nvEncUnmapInputResource) {
                g_nvenc.functions.nvEncUnmapInputResource(g_nvenc.encoder, slot.mapped);
            }
            slot.mapped = nullptr;
            if (slot.registered && g_nvenc.functions.nvEncUnregisterResource) {
                g_nvenc.functions.nvEncUnregisterResource(g_nvenc.encoder, slot.registered);
            }
            slot.registered = nullptr;
            if (slot.bitstream && g_nvenc.functions.nvEncDestroyBitstreamBuffer) {
                g_nvenc.functions.nvEncDestroyBitstreamBuffer(g_nvenc.encoder, slot.bitstream);
            }
            slot.bitstream = nullptr;
            slot.texture.Reset();
        }
        if (g_nvenc.functions.nvEncDestroyEncoder) {
            g_nvenc.functions.nvEncDestroyEncoder(g_nvenc.encoder);
        }
    }
    g_nvenc.encoder = nullptr;
    if (g_nvenc.output != INVALID_HANDLE_VALUE) CloseHandle(g_nvenc.output);
    g_nvenc.output = INVALID_HANDLE_VALUE;
    if (g_nvenc.library) FreeLibrary(g_nvenc.library);
    g_nvenc.library = nullptr;
    g_nvenc.functions = {};
    g_nvenc.pending.clear();
    g_nvenc.next_slot = 0;
    g_nvenc.frame_index = 0;
    g_nvenc.buffer_format = NV_ENC_BUFFER_FORMAT_UNDEFINED;
    g_nvenc.active = false;
    if (delete_raw && !g_nvenc.raw_path.empty()) DeleteFileW(g_nvenc.raw_path.c_str());
    g_nvenc.raw_path.clear();
}

bool drain_nvenc_slot(UINT slot_index) {
    if (slot_index >= g_nvenc.slots.size()) return false;
    auto& slot = g_nvenc.slots[slot_index];
    NV_ENC_LOCK_BITSTREAM lock{};
    lock.version = NV_ENC_LOCK_BITSTREAM_VER;
    lock.outputBitstream = slot.bitstream;
    if (!nvenc_check(g_nvenc.functions.nvEncLockBitstream(g_nvenc.encoder, &lock),
        "NvEncLockBitstream")) return false;
    const bool written = write_file_bytes(g_nvenc.output, lock.bitstreamBufferPtr,
        lock.bitstreamSizeInBytes);
    const bool unlocked = nvenc_check(g_nvenc.functions.nvEncUnlockBitstream(
        g_nvenc.encoder, slot.bitstream), "NvEncUnlockBitstream");
    bool unmapped = true;
    if (slot.mapped) {
        unmapped = nvenc_check(g_nvenc.functions.nvEncUnmapInputResource(
            g_nvenc.encoder, slot.mapped), "NvEncUnmapInputResource");
        slot.mapped = nullptr;
    }
    return written && unlocked && unmapped;
}

bool initialize_zero_copy_nvenc(ID3D11Texture2D* target, DXGI_FORMAT view_format) {
    reset_nvenc(true);
    if (!target || adapter_vendor_id() != 0x10DE) return false;
    g_nvenc.library = LoadLibraryW(L"nvEncodeAPI64.dll");
    if (!g_nvenc.library) {
        g_error = "nvEncodeAPI64.dll is unavailable.";
        reset_nvenc(true);
        return false;
    }
    using GetMaxVersion = NVENCSTATUS (NVENCAPI*)(uint32_t*);
    using CreateInstance = NVENCSTATUS (NVENCAPI*)(NV_ENCODE_API_FUNCTION_LIST*);
    const auto get_max_version = reinterpret_cast<GetMaxVersion>(GetProcAddress(
        g_nvenc.library, "NvEncodeAPIGetMaxSupportedVersion"));
    const auto create_instance = reinterpret_cast<CreateInstance>(GetProcAddress(
        g_nvenc.library, "NvEncodeAPICreateInstance"));
    uint32_t max_version = 0;
    if (!get_max_version || !create_instance
        || get_max_version(&max_version) != NV_ENC_SUCCESS || max_version < NVENCAPI_VERSION) {
        g_error = "The NVIDIA driver does not support the required NVENC API version.";
        reset_nvenc(true);
        return false;
    }
    g_nvenc.functions.version = NV_ENCODE_API_FUNCTION_LIST_VER;
    if (!nvenc_check(create_instance(&g_nvenc.functions), "NvEncodeAPICreateInstance")) {
        reset_nvenc(true);
        return false;
    }
    NV_ENC_OPEN_ENCODE_SESSION_EX_PARAMS open{};
    open.version = NV_ENC_OPEN_ENCODE_SESSION_EX_PARAMS_VER;
    open.deviceType = NV_ENC_DEVICE_TYPE_DIRECTX;
    open.device = g_device.Get();
    open.apiVersion = NVENCAPI_VERSION;
    if (!nvenc_check(g_nvenc.functions.nvEncOpenEncodeSessionEx(&open, &g_nvenc.encoder),
        "NvEncOpenEncodeSessionEx")) {
        reset_nvenc(true);
        return false;
    }

    NV_ENC_PRESET_CONFIG preset{};
    preset.version = NV_ENC_PRESET_CONFIG_VER;
    preset.presetCfg.version = NV_ENC_CONFIG_VER;
    const GUID& preset_guid = nvenc_preset_guid();
    NVENCSTATUS preset_status = g_nvenc.functions.nvEncGetEncodePresetConfigEx
        ? g_nvenc.functions.nvEncGetEncodePresetConfigEx(g_nvenc.encoder,
            NV_ENC_CODEC_H264_GUID, preset_guid, NV_ENC_TUNING_INFO_HIGH_QUALITY, &preset)
        : g_nvenc.functions.nvEncGetEncodePresetConfig(g_nvenc.encoder,
            NV_ENC_CODEC_H264_GUID, preset_guid, &preset);
    if (!nvenc_check(preset_status, "NvEncGetEncodePresetConfig")) {
        reset_nvenc(true);
        return false;
    }
    NV_ENC_CONFIG config = preset.presetCfg;
    config.version = NV_ENC_CONFIG_VER;
    config.profileGUID = NV_ENC_H264_PROFILE_HIGH_GUID;
    config.gopLength = static_cast<uint32_t>(std::max(1.0, std::round(g_fps * 2.0)));
    config.frameIntervalP = 1;
    config.rcParams.rateControlMode = NV_ENC_PARAMS_RC_CONSTQP;
    const uint32_t qp = static_cast<uint32_t>(std::clamp(g_crf, 0, 51));
    config.rcParams.constQP.qpIntra = qp;
    config.rcParams.constQP.qpInterP = qp;
    config.rcParams.constQP.qpInterB = qp;
    config.encodeCodecConfig.h264Config.repeatSPSPPS = 1;
    config.encodeCodecConfig.h264Config.outputAUD = 1;

    const uint32_t rate_den = 1000;
    const uint32_t rate_num = static_cast<uint32_t>(std::max(1.0, std::round(g_fps * rate_den)));
    NV_ENC_INITIALIZE_PARAMS initialize{};
    initialize.version = NV_ENC_INITIALIZE_PARAMS_VER;
    initialize.encodeGUID = NV_ENC_CODEC_H264_GUID;
    initialize.presetGUID = preset_guid;
    initialize.encodeWidth = static_cast<uint32_t>(g_width);
    initialize.encodeHeight = static_cast<uint32_t>(g_height);
    initialize.darWidth = static_cast<uint32_t>(g_width);
    initialize.darHeight = static_cast<uint32_t>(g_height);
    initialize.frameRateNum = rate_num;
    initialize.frameRateDen = rate_den;
    initialize.enablePTD = 1;
    initialize.enableEncodeAsync = 0;
    initialize.tuningInfo = NV_ENC_TUNING_INFO_HIGH_QUALITY;
    initialize.encodeConfig = &config;
    if (!nvenc_check(g_nvenc.functions.nvEncInitializeEncoder(g_nvenc.encoder, &initialize),
        "NvEncInitializeEncoder")) {
        reset_nvenc(true);
        return false;
    }

    if (view_format == DXGI_FORMAT_R8G8B8A8_UNORM
        || view_format == DXGI_FORMAT_R8G8B8A8_UNORM_SRGB) {
        g_nvenc.buffer_format = NV_ENC_BUFFER_FORMAT_ABGR;
    } else if (view_format == DXGI_FORMAT_B8G8R8A8_UNORM
        || view_format == DXGI_FORMAT_B8G8R8A8_UNORM_SRGB
        || view_format == DXGI_FORMAT_B8G8R8X8_UNORM
        || view_format == DXGI_FORMAT_B8G8R8X8_UNORM_SRGB) {
        g_nvenc.buffer_format = NV_ENC_BUFFER_FORMAT_ARGB;
    } else {
        g_error = "The D3D11 render-target format is not supported by direct NVENC.";
        reset_nvenc(true);
        return false;
    }

    D3D11_TEXTURE2D_DESC source{};
    target->GetDesc(&source);
    D3D11_TEXTURE2D_DESC input = source;
    input.MipLevels = 1;
    input.ArraySize = 1;
    input.SampleDesc.Count = 1;
    input.SampleDesc.Quality = 0;
    input.Usage = D3D11_USAGE_DEFAULT;
    input.BindFlags = D3D11_BIND_SHADER_RESOURCE;
    input.CPUAccessFlags = 0;
    input.MiscFlags = 0;
    for (auto& slot : g_nvenc.slots) {
        if (FAILED(g_device->CreateTexture2D(&input, nullptr, &slot.texture))) {
            g_error = "Unable to create a direct NVENC input texture.";
            reset_nvenc(true);
            return false;
        }
        NV_ENC_REGISTER_RESOURCE registration{};
        registration.version = NV_ENC_REGISTER_RESOURCE_VER;
        registration.resourceType = NV_ENC_INPUT_RESOURCE_TYPE_DIRECTX;
        registration.width = static_cast<uint32_t>(g_width);
        registration.height = static_cast<uint32_t>(g_height);
        registration.resourceToRegister = slot.texture.Get();
        registration.bufferFormat = g_nvenc.buffer_format;
        registration.bufferUsage = NV_ENC_INPUT_IMAGE;
        if (!nvenc_check(g_nvenc.functions.nvEncRegisterResource(g_nvenc.encoder,
            &registration), "NvEncRegisterResource")) {
            reset_nvenc(true);
            return false;
        }
        slot.registered = registration.registeredResource;
        NV_ENC_CREATE_BITSTREAM_BUFFER bitstream{};
        bitstream.version = NV_ENC_CREATE_BITSTREAM_BUFFER_VER;
        if (!nvenc_check(g_nvenc.functions.nvEncCreateBitstreamBuffer(g_nvenc.encoder,
            &bitstream), "NvEncCreateBitstreamBuffer")) {
            reset_nvenc(true);
            return false;
        }
        slot.bitstream = bitstream.bitstreamBuffer;
    }

    g_nvenc.raw_path = utf8_to_wide(g_output_path) + L".nvenc.h264";
    DeleteFileW(g_nvenc.raw_path.c_str());
    g_nvenc.output = CreateFileW(g_nvenc.raw_path.c_str(), GENERIC_WRITE, 0, nullptr,
        CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY | FILE_FLAG_SEQUENTIAL_SCAN, nullptr);
    if (g_nvenc.output == INVALID_HANDLE_VALUE) {
        g_error = "Unable to create the temporary NVENC bitstream.";
        reset_nvenc(true);
        return false;
    }
    g_nvenc.active = true;
    return true;
}

bool submit_zero_copy_nvenc(ID3D11Texture2D* target, DXGI_FORMAT view_format) {
    if (!g_nvenc.active || !target) return false;
    const UINT slot_index = g_nvenc.next_slot;
    auto& slot = g_nvenc.slots[slot_index];
    if (target) {
        D3D11_TEXTURE2D_DESC source{};
        target->GetDesc(&source);
        if (source.SampleDesc.Count > 1) {
            g_context->ResolveSubresource(slot.texture.Get(), 0, target, 0, view_format);
        } else {
            g_context->CopyResource(slot.texture.Get(), target);
        }
    }
    NV_ENC_MAP_INPUT_RESOURCE map{};
    map.version = NV_ENC_MAP_INPUT_RESOURCE_VER;
    map.registeredResource = slot.registered;
    if (!nvenc_check(g_nvenc.functions.nvEncMapInputResource(g_nvenc.encoder, &map),
        "NvEncMapInputResource")) return false;
    slot.mapped = map.mappedResource;
    NV_ENC_PIC_PARAMS picture{};
    picture.version = NV_ENC_PIC_PARAMS_VER;
    picture.inputWidth = static_cast<uint32_t>(g_width);
    picture.inputHeight = static_cast<uint32_t>(g_height);
    picture.frameIdx = static_cast<uint32_t>(g_nvenc.frame_index);
    picture.inputTimeStamp = g_nvenc.frame_index;
    picture.inputDuration = 1;
    picture.inputBuffer = slot.mapped;
    picture.outputBitstream = slot.bitstream;
    picture.bufferFmt = map.mappedBufferFmt;
    picture.pictureStruct = NV_ENC_PIC_STRUCT_FRAME;
    const NVENCSTATUS encoded = g_nvenc.functions.nvEncEncodePicture(g_nvenc.encoder, &picture);
    if (encoded != NV_ENC_SUCCESS && encoded != NV_ENC_ERR_NEED_MORE_INPUT) {
        return nvenc_check(encoded, "NvEncEncodePicture");
    }
    g_nvenc.pending.push_back(slot_index);
    g_nvenc.next_slot = (slot_index + 1) % static_cast<UINT>(g_nvenc.slots.size());
    ++g_nvenc.frame_index;
    ++g_captured_frames;
    if (g_nvenc.pending.size() >= g_nvenc.slots.size()) {
        const UINT ready = g_nvenc.pending.front();
        g_nvenc.pending.pop_front();
        return drain_nvenc_slot(ready);
    }
    return true;
}

bool finish_zero_copy_nvenc() {
    if (!g_nvenc.active) return false;
    NV_ENC_PIC_PARAMS eos{};
    eos.version = NV_ENC_PIC_PARAMS_VER;
    eos.encodePicFlags = NV_ENC_PIC_FLAG_EOS;
    const NVENCSTATUS eos_status = g_nvenc.functions.nvEncEncodePicture(g_nvenc.encoder, &eos);
    if (eos_status != NV_ENC_SUCCESS && eos_status != NV_ENC_ERR_NEED_MORE_INPUT) {
        nvenc_check(eos_status, "NvEncEncodePicture(EOS)");
        reset_nvenc(true);
        return false;
    }
    while (!g_nvenc.pending.empty()) {
        const UINT ready = g_nvenc.pending.front();
        g_nvenc.pending.pop_front();
        if (!drain_nvenc_slot(ready)) {
            reset_nvenc(true);
            return false;
        }
    }
    if (g_nvenc.output != INVALID_HANDLE_VALUE) {
        CloseHandle(g_nvenc.output);
        g_nvenc.output = INVALID_HANDLE_VALUE;
    }
    const std::wstring raw_path = g_nvenc.raw_path;
    reset_nvenc(false);
    const bool muxed = mux_h264_bitstream(raw_path);
    DeleteFileW(raw_path.c_str());
    return muxed;
}

const char* amf_status_name(AMF_RESULT status) {
    switch (status) {
        case AMF_OK: return "AMF_OK";
        case AMF_FAIL: return "AMF_FAIL";
        case AMF_INVALID_ARG: return "AMF_INVALID_ARG";
        case AMF_NOT_SUPPORTED: return "AMF_NOT_SUPPORTED";
        case AMF_NOT_FOUND: return "AMF_NOT_FOUND";
        case AMF_NOT_INITIALIZED: return "AMF_NOT_INITIALIZED";
        case AMF_INVALID_FORMAT: return "AMF_INVALID_FORMAT";
        case AMF_WRONG_STATE: return "AMF_WRONG_STATE";
        case AMF_NO_DEVICE: return "AMF_NO_DEVICE";
        case AMF_DIRECTX_FAILED: return "AMF_DIRECTX_FAILED";
        case AMF_EOF: return "AMF_EOF";
        case AMF_REPEAT: return "AMF_REPEAT";
        case AMF_INPUT_FULL: return "AMF_INPUT_FULL";
        case AMF_NEED_MORE_INPUT: return "AMF_NEED_MORE_INPUT";
        case AMF_SURFACE_FORMAT_NOT_SUPPORTED: return "AMF_SURFACE_FORMAT_NOT_SUPPORTED";
        case AMF_ENCODER_NOT_PRESENT: return "AMF_ENCODER_NOT_PRESENT";
        default: return "AMF error";
    }
}

bool amf_check(AMF_RESULT status, const char* operation) {
    if (status == AMF_OK) return true;
    g_error = std::string(operation) + " failed: " + amf_status_name(status)
        + " (" + std::to_string(static_cast<int>(status)) + ").";
    return false;
}

template<typename T>
void amf_release(T*& value) {
    if (value) value->Release();
    value = nullptr;
}

void reset_amf(bool delete_raw) {
    if (g_amf.converter) g_amf.converter->Terminate();
    amf_release(g_amf.converter);
    if (g_amf.encoder) g_amf.encoder->Terminate();
    amf_release(g_amf.encoder);
    if (g_amf.context) g_amf.context->Terminate();
    amf_release(g_amf.context);
    g_amf.factory = nullptr;
    if (g_amf.output != INVALID_HANDLE_VALUE) CloseHandle(g_amf.output);
    g_amf.output = INVALID_HANDLE_VALUE;
    if (g_amf.library) FreeLibrary(g_amf.library);
    g_amf.library = nullptr;
    if (delete_raw && !g_amf.raw_path.empty()) DeleteFileW(g_amf.raw_path.c_str());
    g_amf.raw_path.clear();
    g_amf.frame_index = 0;
    g_amf.pending_timings.clear();
    g_amf.input_format = amf::AMF_SURFACE_UNKNOWN;
    g_amf.texture_format = DXGI_FORMAT_UNKNOWN;
    g_amf.active = false;
}

bool amf_set(amf::AMFPropertyStorage* storage, const wchar_t* name,
    amf::AMFVariantStruct value, const char* operation) {
    return amf_check(storage->SetProperty(name, value), operation);
}

amf_int64 amf_quality_preset() {
    if (g_preset == "ultrafast" || g_preset == "superfast" || g_preset == "veryfast"
        || g_preset == "faster" || g_preset == "fast") {
        return AMF_VIDEO_ENCODER_QUALITY_PRESET_SPEED;
    }
    if (g_preset == "slow" || g_preset == "slower" || g_preset == "veryslow") {
        return AMF_VIDEO_ENCODER_QUALITY_PRESET_QUALITY;
    }
    return AMF_VIDEO_ENCODER_QUALITY_PRESET_BALANCED;
}

bool pump_amf_encoder(bool& produced, bool& eof, bool draining = false) {
    produced = false;
    eof = false;
    amf::AMFData* data = nullptr;
    const AMF_RESULT status = g_amf.encoder->QueryOutput(&data);
    if (status == AMF_EOF) {
        eof = true;
        return true;
    }
    if (status == AMF_NEED_MORE_INPUT && draining) {
        eof = true;
        return true;
    }
    if (status == AMF_REPEAT || status == AMF_NEED_MORE_INPUT || status == AMF_INPUT_FULL) {
        return true;
    }
    if (!amf_check(status, "AMF encoder QueryOutput")) return false;
    if (!data) return true;

    amf::AMFBuffer* buffer = nullptr;
    const AMF_RESULT queried = data->QueryInterface(amf::AMFBuffer::IID(),
        reinterpret_cast<void**>(&buffer));
    bool success = amf_check(queried, "AMF encoder output QueryInterface(AMFBuffer)");
    if (success) {
        success = write_file_bytes(g_amf.output, buffer->GetNative(), buffer->GetSize());
    }
    amf_release(buffer);
    data->Release();
    produced = success;
    return success;
}

bool submit_amf_encoder(amf::AMFData* data) {
    const bool first_frame = data->GetPts() == 0;
    if (!amf_set(data, AMF_VIDEO_ENCODER_INSERT_AUD, amf::AMFVariantBool(true),
        "AMF surface InsertAUD")
        || (first_frame && !amf_set(data, AMF_VIDEO_ENCODER_INSERT_SPS,
            amf::AMFVariantBool(true), "AMF surface InsertSPS"))
        || (first_frame && !amf_set(data, AMF_VIDEO_ENCODER_INSERT_PPS,
            amf::AMFVariantBool(true), "AMF surface InsertPPS"))) {
        return false;
    }
    for (;;) {
        const AMF_RESULT status = g_amf.encoder->SubmitInput(data);
        if (status == AMF_OK || status == AMF_NEED_MORE_INPUT) return true;
        if (status != AMF_INPUT_FULL && status != AMF_REPEAT) {
            return amf_check(status, "AMF encoder SubmitInput");
        }
        bool produced = false;
        bool eof = false;
        if (!pump_amf_encoder(produced, eof)) return false;
        if (!produced) Sleep(1);
    }
}

bool pump_amf_converter(bool& produced, bool& eof, bool draining = false) {
    produced = false;
    eof = false;
    amf::AMFData* data = nullptr;
    const AMF_RESULT status = g_amf.converter->QueryOutput(&data);
    if (status == AMF_EOF) {
        eof = true;
        return true;
    }
    if (status == AMF_NEED_MORE_INPUT && draining) {
        eof = true;
        return true;
    }
    if (status == AMF_REPEAT || status == AMF_NEED_MORE_INPUT || status == AMF_INPUT_FULL) {
        return true;
    }
    if (!amf_check(status, "AMF converter QueryOutput")) return false;
    if (!data) return true;
    if (g_amf.pending_timings.empty()) {
        data->Release();
        g_error = "AMF converter returned an output without a matching input timestamp.";
        return false;
    }
    const AmfState::Timing timing = g_amf.pending_timings.front();
    g_amf.pending_timings.pop_front();
    data->SetPts(timing.pts);
    data->SetDuration(timing.duration);
    const bool success = submit_amf_encoder(data);
    data->Release();
    produced = success;
    return success;
}

bool initialize_zero_copy_amf(ID3D11Texture2D* target, DXGI_FORMAT view_format) {
    reset_amf(true);
    if (!target || !g_device || !g_context) {
        g_error = "The active D3D11 render target is unavailable for direct AMF.";
        return false;
    }
    const UINT vendor = adapter_vendor_id();
    if (vendor != 0x1002 && vendor != 0x1022) {
        g_error = "The active D3D11 adapter is not an AMD adapter.";
        return false;
    }
    switch (view_format) {
        case DXGI_FORMAT_B8G8R8A8_UNORM:
        case DXGI_FORMAT_B8G8R8A8_UNORM_SRGB:
            g_amf.input_format = amf::AMF_SURFACE_BGRA;
            g_amf.texture_format = DXGI_FORMAT_B8G8R8A8_UNORM;
            break;
        case DXGI_FORMAT_B8G8R8X8_UNORM:
        case DXGI_FORMAT_B8G8R8X8_UNORM_SRGB:
            g_amf.input_format = amf::AMF_SURFACE_BGRA;
            g_amf.texture_format = DXGI_FORMAT_B8G8R8X8_UNORM;
            break;
        case DXGI_FORMAT_R8G8B8A8_UNORM:
        case DXGI_FORMAT_R8G8B8A8_UNORM_SRGB:
            g_amf.input_format = amf::AMF_SURFACE_RGBA;
            g_amf.texture_format = DXGI_FORMAT_R8G8B8A8_UNORM;
            break;
        default:
            g_error = "The D3D11 render-target format is not supported by direct AMF.";
            return false;
    }

    g_amf.library = LoadLibraryW(L"amfrt64.dll");
    if (!g_amf.library) {
        g_error = "amfrt64.dll is unavailable (Win32 error "
            + std::to_string(GetLastError()) + ").";
        reset_amf(true);
        return false;
    }
    const auto query_version = reinterpret_cast<AMFQueryVersion_Fn>(GetProcAddress(
        g_amf.library, "AMFQueryVersion"));
    const auto initialize = reinterpret_cast<AMFInit_Fn>(GetProcAddress(g_amf.library, "AMFInit"));
    amf_uint64 runtime_version = 0;
    if (!query_version || !initialize
        || !amf_check(query_version(&runtime_version), "AMFQueryVersion")) {
        if (g_error.empty()) g_error = "amfrt64.dll does not export the required AMF entry points.";
        reset_amf(true);
        return false;
    }
    const amf_uint64 requested_version = std::min(runtime_version, AMF_FULL_VERSION);
    if (!amf_check(initialize(requested_version, &g_amf.factory), "AMFInit") || !g_amf.factory) {
        reset_amf(true);
        return false;
    }
    if (!amf_check(g_amf.factory->CreateContext(&g_amf.context), "AMF CreateContext")
        || !g_amf.context
        || !amf_check(g_amf.context->InitDX11(g_device.Get()), "AMF InitDX11")) {
        reset_amf(true);
        return false;
    }
    if (!amf_check(g_amf.factory->CreateComponent(g_amf.context, AMFVideoConverter,
        &g_amf.converter), "AMF CreateComponent(VideoConverter)") || !g_amf.converter) {
        reset_amf(true);
        return false;
    }
    if (!amf_set(g_amf.converter, AMF_VIDEO_CONVERTER_OUTPUT_FORMAT,
            amf::AMFVariantInt64(amf::AMF_SURFACE_NV12), "AMF converter OutputFormat")
        || !amf_set(g_amf.converter, AMF_VIDEO_CONVERTER_MEMORY_TYPE,
            amf::AMFVariantInt64(amf::AMF_MEMORY_DX11), "AMF converter MemoryType")
        || !amf_set(g_amf.converter, AMF_VIDEO_CONVERTER_OUTPUT_SIZE,
            amf::AMFVariantSize(g_width, g_height), "AMF converter OutputSize")
        || !amf_check(g_amf.converter->Init(g_amf.input_format, g_width, g_height),
            "AMF converter Init")) {
        reset_amf(true);
        return false;
    }

    if (!amf_check(g_amf.factory->CreateComponent(g_amf.context, AMFVideoEncoderVCE_AVC,
        &g_amf.encoder), "AMF CreateComponent(VCE AVC)") || !g_amf.encoder) {
        reset_amf(true);
        return false;
    }
    const amf_uint32 rate_den = 1000;
    const amf_uint32 rate_num = static_cast<amf_uint32>(std::max(1.0,
        std::round(g_fps * rate_den)));
    const amf_int64 qp = std::clamp(g_crf, 0, 51);
    const amf_int64 idr_period = static_cast<amf_int64>(std::max(1.0, std::round(g_fps * 2.0)));
    if (!amf_set(g_amf.encoder, AMF_VIDEO_ENCODER_USAGE,
            amf::AMFVariantInt64(AMF_VIDEO_ENCODER_USAGE_TRANSCODING), "AMF encoder Usage")
        || !amf_set(g_amf.encoder, AMF_VIDEO_ENCODER_PROFILE,
            amf::AMFVariantInt64(AMF_VIDEO_ENCODER_PROFILE_HIGH), "AMF encoder Profile")
        || !amf_set(g_amf.encoder, AMF_VIDEO_ENCODER_FRAMESIZE,
            amf::AMFVariantSize(g_width, g_height), "AMF encoder FrameSize")
        || !amf_set(g_amf.encoder, AMF_VIDEO_ENCODER_MEMORY_TYPE,
            amf::AMFVariantInt64(amf::AMF_MEMORY_DX11), "AMF encoder MemoryType")
        || !amf_set(g_amf.encoder, AMF_VIDEO_ENCODER_RATE_CONTROL_METHOD,
            amf::AMFVariantInt64(AMF_VIDEO_ENCODER_RATE_CONTROL_METHOD_CONSTANT_QP),
            "AMF encoder RateControlMethod")
        || !amf_set(g_amf.encoder, AMF_VIDEO_ENCODER_QUALITY_PRESET,
            amf::AMFVariantInt64(amf_quality_preset()), "AMF encoder QualityPreset")
        || !amf_set(g_amf.encoder, AMF_VIDEO_ENCODER_FRAMERATE,
            amf::AMFVariantRate(rate_num, rate_den), "AMF encoder FrameRate")
        || !amf_set(g_amf.encoder, AMF_VIDEO_ENCODER_QP_I,
            amf::AMFVariantInt64(qp), "AMF encoder QPI")
        || !amf_set(g_amf.encoder, AMF_VIDEO_ENCODER_QP_P,
            amf::AMFVariantInt64(qp), "AMF encoder QPP")
        || !amf_set(g_amf.encoder, AMF_VIDEO_ENCODER_QP_B,
            amf::AMFVariantInt64(qp), "AMF encoder QPB")
        || !amf_set(g_amf.encoder, AMF_VIDEO_ENCODER_B_PIC_PATTERN,
            amf::AMFVariantInt64(0), "AMF encoder BPicturesPattern")
        || !amf_set(g_amf.encoder, AMF_VIDEO_ENCODER_MAX_CONSECUTIVE_BPICTURES,
            amf::AMFVariantInt64(0), "AMF encoder MaxConsecutiveBPictures")
        || !amf_set(g_amf.encoder, AMF_VIDEO_ENCODER_IDR_PERIOD,
            amf::AMFVariantInt64(idr_period), "AMF encoder IDRPeriod")
        || !amf_check(g_amf.encoder->Init(amf::AMF_SURFACE_NV12, g_width, g_height),
            "AMF encoder Init")) {
        reset_amf(true);
        return false;
    }

    g_amf.raw_path = utf8_to_wide(g_output_path) + L".amf.h264";
    DeleteFileW(g_amf.raw_path.c_str());
    g_amf.output = CreateFileW(g_amf.raw_path.c_str(), GENERIC_WRITE, 0, nullptr,
        CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY | FILE_FLAG_SEQUENTIAL_SCAN, nullptr);
    if (g_amf.output == INVALID_HANDLE_VALUE) {
        g_error = "Unable to create the temporary AMF bitstream.";
        reset_amf(true);
        return false;
    }
    g_amf.active = true;
    return true;
}

bool submit_zero_copy_amf(ID3D11Texture2D* target, DXGI_FORMAT view_format) {
    if (!g_amf.active || !target) return false;
    D3D11_TEXTURE2D_DESC source{};
    target->GetDesc(&source);
    D3D11_TEXTURE2D_DESC input = source;
    input.Format = g_amf.texture_format;
    input.MipLevels = 1;
    input.ArraySize = 1;
    input.SampleDesc.Count = 1;
    input.SampleDesc.Quality = 0;
    input.Usage = D3D11_USAGE_DEFAULT;
    input.BindFlags = D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_RENDER_TARGET;
    input.CPUAccessFlags = 0;
    input.MiscFlags = 0;
    ComPtr<ID3D11Texture2D> texture;
    if (FAILED(g_device->CreateTexture2D(&input, nullptr, &texture))) {
        g_error = "Unable to create a direct AMF input texture.";
        return false;
    }
    if (!amf_check(g_amf.context->LockDX11(), "AMF LockDX11")) return false;
    if (source.SampleDesc.Count > 1) {
        g_context->ResolveSubresource(texture.Get(), 0, target, 0, g_amf.texture_format);
    } else {
        g_context->CopyResource(texture.Get(), target);
    }
    if (!amf_check(g_amf.context->UnlockDX11(), "AMF UnlockDX11")) return false;

    amf::AMFSurface* surface = nullptr;
    if (!amf_check(g_amf.context->CreateSurfaceFromDX11Native(texture.Get(), &surface, nullptr),
        "AMF CreateSurfaceFromDX11Native") || !surface) {
        return false;
    }
    const amf_pts pts = static_cast<amf_pts>(std::llround(
        static_cast<double>(g_amf.frame_index) * AMF_SECOND / g_fps));
    const amf_pts next_pts = static_cast<amf_pts>(std::llround(
        static_cast<double>(g_amf.frame_index + 1) * AMF_SECOND / g_fps));
    surface->SetPts(pts);
    surface->SetDuration(std::max<amf_pts>(1, next_pts - pts));
    surface->SetFrameType(amf::AMF_FRAME_PROGRESSIVE);

    bool accepted = false;
    while (!accepted) {
        const AMF_RESULT status = g_amf.converter->SubmitInput(surface);
        if (status == AMF_OK || status == AMF_NEED_MORE_INPUT) {
            accepted = true;
            break;
        }
        if (status != AMF_INPUT_FULL && status != AMF_REPEAT) {
            amf_check(status, "AMF converter SubmitInput");
            surface->Release();
            return false;
        }
        bool produced = false;
        bool eof = false;
        if (!pump_amf_converter(produced, eof)) {
            surface->Release();
            return false;
        }
        if (!produced) {
            bool encoded = false;
            if (!pump_amf_encoder(encoded, eof)) {
                surface->Release();
                return false;
            }
            if (!encoded) Sleep(1);
        }
    }
    surface->Release();
    g_amf.pending_timings.push_back({pts, std::max<amf_pts>(1, next_pts - pts)});
    ++g_amf.frame_index;
    ++g_captured_frames;

    for (;;) {
        bool produced = false;
        bool eof = false;
        if (!pump_amf_converter(produced, eof)) return false;
        if (!produced) break;
    }
    for (;;) {
        bool produced = false;
        bool eof = false;
        if (!pump_amf_encoder(produced, eof)) return false;
        if (!produced) break;
    }
    return true;
}

bool finish_zero_copy_amf() {
    if (!g_amf.active) return false;
    for (;;) {
        const AMF_RESULT status = g_amf.converter->Drain();
        if (status == AMF_OK || status == AMF_EOF || status == AMF_NEED_MORE_INPUT) break;
        if (status != AMF_INPUT_FULL && status != AMF_REPEAT) {
            amf_check(status, "AMF converter Drain");
            reset_amf(true);
            return false;
        }
        bool produced = false;
        bool eof = false;
        if (!pump_amf_converter(produced, eof, true)) {
            reset_amf(true);
            return false;
        }
        if (!produced) Sleep(1);
    }
    for (;;) {
        bool produced = false;
        bool eof = false;
        if (!pump_amf_converter(produced, eof, true)) {
            reset_amf(true);
            return false;
        }
        if (eof) break;
        if (!produced) Sleep(1);
    }
    if (!g_amf.pending_timings.empty()) {
        g_error = "AMF converter drain completed before all input frames were returned.";
        reset_amf(true);
        return false;
    }

    for (;;) {
        const AMF_RESULT status = g_amf.encoder->Drain();
        if (status == AMF_OK || status == AMF_EOF || status == AMF_NEED_MORE_INPUT) break;
        if (status != AMF_INPUT_FULL && status != AMF_REPEAT) {
            amf_check(status, "AMF encoder Drain");
            reset_amf(true);
            return false;
        }
        bool produced = false;
        bool eof = false;
        if (!pump_amf_encoder(produced, eof, true)) {
            reset_amf(true);
            return false;
        }
        if (!produced) Sleep(1);
    }
    for (;;) {
        bool produced = false;
        bool eof = false;
        if (!pump_amf_encoder(produced, eof, true)) {
            reset_amf(true);
            return false;
        }
        if (eof) break;
        if (!produced) Sleep(1);
    }

    if (g_amf.output != INVALID_HANDLE_VALUE) {
        CloseHandle(g_amf.output);
        g_amf.output = INVALID_HANDLE_VALUE;
    }
    const std::wstring raw_path = g_amf.raw_path;
    reset_amf(false);
    const bool muxed = mux_h264_bitstream(raw_path);
    DeleteFileW(raw_path.c_str());
    return muxed;
}

struct DecodedSound {
    std::wstring path;
    HANDLE file = INVALID_HANDLE_VALUE;
    HANDLE mapping = nullptr;
    const float* samples = nullptr;
    std::uint64_t frame_count = 0;

    DecodedSound() = default;
    DecodedSound(const DecodedSound&) = delete;
    DecodedSound& operator=(const DecodedSound&) = delete;
    DecodedSound(DecodedSound&& other) noexcept {
        *this = std::move(other);
    }
    DecodedSound& operator=(DecodedSound&& other) noexcept {
        if (this == &other) return *this;
        close();
        path = std::move(other.path);
        file = other.file;
        mapping = other.mapping;
        samples = other.samples;
        frame_count = other.frame_count;
        other.file = INVALID_HANDLE_VALUE;
        other.path.clear();
        other.mapping = nullptr;
        other.samples = nullptr;
        other.frame_count = 0;
        return *this;
    }
    ~DecodedSound() {
        close();
        if (!path.empty()) DeleteFileW(path.c_str());
    }

    void close() {
        if (samples) UnmapViewOfFile(samples);
        if (mapping) CloseHandle(mapping);
        if (file != INVALID_HANDLE_VALUE) CloseHandle(file);
        samples = nullptr;
        mapping = nullptr;
        file = INVALID_HANDLE_VALUE;
        frame_count = 0;
    }
};

bool open_decoded_sound(const std::wstring& path, DecodedSound& sound) {
    sound.path = path;
    sound.file = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
        OPEN_EXISTING, FILE_ATTRIBUTE_TEMPORARY | FILE_FLAG_SEQUENTIAL_SCAN, nullptr);
    if (sound.file == INVALID_HANDLE_VALUE) {
        g_error = "Unable to open a decoded hitsound PCM file.";
        return false;
    }
    LARGE_INTEGER size{};
    if (!GetFileSizeEx(sound.file, &size) || size.QuadPart <= 0 || (size.QuadPart % 8) != 0) {
        g_error = "A decoded hitsound PCM file is empty or invalid.";
        return false;
    }
    sound.mapping = CreateFileMappingW(sound.file, nullptr, PAGE_READONLY, 0, 0, nullptr);
    if (!sound.mapping) {
        g_error = "Unable to map a decoded hitsound PCM file.";
        return false;
    }
    sound.samples = static_cast<const float*>(MapViewOfFile(sound.mapping, FILE_MAP_READ, 0, 0, 0));
    if (!sound.samples) {
        g_error = "Unable to read a decoded hitsound PCM file.";
        return false;
    }
    sound.frame_count = static_cast<std::uint64_t>(size.QuadPart / 8);
    return true;
}

bool mix_hitsounds() {
    if (g_hitsounds.empty()) return true;
    if (g_output_path.empty()) {
        g_error = "The renderer output path is unavailable for hitsound mixing.";
        return false;
    }

    struct FailedMixOutputGuard {
        std::wstring path;
        bool committed = false;
        ~FailedMixOutputGuard() {
            if (!committed && !path.empty()) DeleteFileW(path.c_str());
        }
    } output_guard{utf8_to_wide(g_output_path)};

    std::vector<std::string> unique_paths;
    std::unordered_map<std::string, std::size_t> path_indices;
    std::vector<std::size_t> event_path_indices;
    event_path_indices.reserve(g_hitsounds.size());
    for (const auto& event : g_hitsounds) {
        const auto [found, inserted] = path_indices.emplace(event.path, unique_paths.size());
        if (inserted) unique_paths.push_back(event.path);
        event_path_indices.push_back(found->second);
    }
    const auto mix_started = std::chrono::steady_clock::now();
    std::fprintf(stderr, "[Renderer] Hitsound mix: events=%zu, unique_sounds=%zu\n",
        g_hitsounds.size(), unique_paths.size());

    const std::wstring& output = output_guard.path;
    const std::wstring stem_path = output + L".hitsounds.stem.f32le";
    const std::wstring mixed_path = output + L".hitsounds.tmp.mp4";
    DeleteFileW(stem_path.c_str());
    DeleteFileW(mixed_path.c_str());

    std::vector<DecodedSound> sounds;
    sounds.reserve(unique_paths.size());
    for (std::size_t path_index = 0; path_index < unique_paths.size(); ++path_index) {
        const std::wstring decoded_path = output + L".hitsound."
            + std::to_wstring(path_index) + L".f32le";
        DeleteFileW(decoded_path.c_str());
        std::wstring decode_command = quote(utf8_to_wide(g_ffmpeg))
            + L" -hide_banner -loglevel warning -y -i " + quote(utf8_to_wide(unique_paths[path_index]))
            + L" -map 0:a:0 -vn -sn -dn -ac 2 -ar 44100 -c:a pcm_f32le -f f32le "
            + quote(decoded_path);
        if (!run_process(std::move(decode_command))) {
            for (auto& sound : sounds) {
                const std::wstring path = sound.path;
                sound.close();
                DeleteFileW(path.c_str());
                sound.path.clear();
            }
            DeleteFileW(decoded_path.c_str());
            return false;
        }
        DecodedSound sound;
        if (!open_decoded_sound(decoded_path, sound)) {
            DeleteFileW(decoded_path.c_str());
            return false;
        }
        sounds.push_back(std::move(sound));
    }

    struct PreparedEvent {
        std::size_t sound_index = 0;
        std::uint64_t start_frame = 0;
        float volume = 0.7f;
    };
    std::vector<PreparedEvent> events;
    events.reserve(g_hitsounds.size());
    for (std::size_t event_index = 0; event_index < g_hitsounds.size(); ++event_index) {
        events.push_back({event_path_indices[event_index],
            static_cast<std::uint64_t>(std::llround(g_hitsounds[event_index].time * 44100.0)),
            static_cast<float>(g_hitsounds[event_index].volume)});
    }
    std::sort(events.begin(), events.end(), [](const PreparedEvent& left, const PreparedEvent& right) {
        return left.start_frame < right.start_frame;
    });

    const std::uint64_t output_frames = g_fps > 0.0
        ? static_cast<std::uint64_t>(std::ceil(g_captured_frames * 44100.0 / g_fps)) : 0;
    HANDLE stem = CreateFileW(stem_path.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS,
        FILE_ATTRIBUTE_TEMPORARY | FILE_FLAG_SEQUENTIAL_SCAN, nullptr);
    if (stem == INVALID_HANDLE_VALUE || output_frames == 0) {
        if (stem != INVALID_HANDLE_VALUE) CloseHandle(stem);
        g_error = "Unable to create the temporary hitsound PCM track.";
        return false;
    }

    constexpr std::uint64_t block_frames = 8192;
    std::vector<float> block(static_cast<std::size_t>(block_frames * 2));
    std::vector<std::size_t> active;
    std::size_t next_event = 0;
    bool stem_ok = true;
    double stem_square_sum = 0.0;
    float stem_peak = 0.0f;
    std::uint64_t stem_sample_count = 0;
    for (std::uint64_t block_start = 0; block_start < output_frames && stem_ok;
        block_start += block_frames) {
        const std::uint64_t block_count = std::min(block_frames, output_frames - block_start);
        const std::uint64_t block_end = block_start + block_count;
        std::fill(block.begin(), block.begin() + static_cast<std::ptrdiff_t>(block_count * 2), 0.0f);
        while (next_event < events.size() && events[next_event].start_frame < block_end) {
            active.push_back(next_event++);
        }
        for (const std::size_t event_index : active) {
            const auto& event = events[event_index];
            const auto& sound = sounds[event.sound_index];
            const std::uint64_t event_end = event.start_frame + sound.frame_count;
            const std::uint64_t mix_start = std::max(block_start, event.start_frame);
            const std::uint64_t mix_end = std::min(block_end, event_end);
            if (mix_start >= mix_end) continue;
            const std::uint64_t source_start = mix_start - event.start_frame;
            const std::uint64_t destination_start = mix_start - block_start;
            for (std::uint64_t frame = 0; frame < mix_end - mix_start; ++frame) {
                const std::size_t source = static_cast<std::size_t>((source_start + frame) * 2);
                const std::size_t destination = static_cast<std::size_t>((destination_start + frame) * 2);
                block[destination] += sound.samples[source] * event.volume;
                block[destination + 1] += sound.samples[source + 1] * event.volume;
            }
        }
        active.erase(std::remove_if(active.begin(), active.end(), [&](std::size_t event_index) {
            const auto& event = events[event_index];
            return event.start_frame + sounds[event.sound_index].frame_count <= block_end;
        }), active.end());
        for (std::uint64_t sample = 0; sample < block_count * 2; ++sample) {
            const float value = block[static_cast<std::size_t>(sample)];
            stem_peak = std::max(stem_peak, std::abs(value));
            stem_square_sum += static_cast<double>(value) * value;
        }
        stem_sample_count += block_count * 2;
        stem_ok = write_file_bytes(stem, block.data(), static_cast<std::size_t>(block_count * 8));
    }
    CloseHandle(stem);
    for (auto& sound : sounds) {
        const std::wstring path = sound.path;
        sound.close();
        DeleteFileW(path.c_str());
        sound.path.clear();
    }
    if (!stem_ok) {
        DeleteFileW(stem_path.c_str());
        return false;
    }
    if (stem_peak <= 0.000001f || stem_sample_count == 0) {
        DeleteFileW(stem_path.c_str());
        g_error = "The generated hitsound track is silent.";
        return false;
    }
    const auto stem_finished = std::chrono::steady_clock::now();
    const double stem_rms = std::sqrt(stem_square_sum / stem_sample_count);
    std::fprintf(stderr, "[Renderer] Hitsound stem ready in %.2fs (peak=%.4f, rms=%.6f)\n",
        std::chrono::duration<double>(stem_finished - mix_started).count(), stem_peak, stem_rms);

    std::wstring command = quote(utf8_to_wide(g_ffmpeg))
        + L" -hide_banner -loglevel warning -y -i " + quote(output)
        + L" -itsoffset " + std::to_wstring(g_audio_delay_seconds)
        + L" -i " + quote(utf8_to_wide(g_audio_path))
        + L" -f f32le -ar 44100 -ac 2 -i " + quote(stem_path)
        + L" -filter_complex \"[1:a:0]volume=0.82[music];[2:a:0]volume=1.4[hits];"
          L"[music][hits]amix=inputs=2:normalize=0:dropout_transition=0,"
          L"alimiter=limit=0.95[mix]\""
        + L" -map 0:v:0 -map \"[mix]\" -c:v copy -c:a aac -b:a 192k"
        + L" -shortest -movflags +faststart " + quote(mixed_path);

    const bool mixed = run_process(std::move(command));
    DeleteFileW(stem_path.c_str());
    if (!mixed) {
        DeleteFileW(mixed_path.c_str());
        return false;
    }
    if (!MoveFileExW(mixed_path.c_str(), output.c_str(),
        MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
        g_error = "Unable to replace the rendered video with the hitsound mix (Win32 error "
            + std::to_string(GetLastError()) + ").";
        DeleteFileW(mixed_path.c_str());
        return false;
    }
    output_guard.committed = true;
    std::fprintf(stderr, "[Renderer] Hitsound mix complete in %.2fs\n",
        std::chrono::duration<double>(std::chrono::steady_clock::now() - mix_started).count());
    return true;
}
}

extern "C" __declspec(dllexport) double video_renderer_initialize(char* argument_buffer,
    double argument_buffer_length) {
    if (!argument_buffer || argument_buffer_length < 16.0) {
        g_error = "Invalid D3D11 initialization buffer.";
        return 0.0;
    }
    std::uint64_t device_value = 0;
    std::uint64_t context_value = 0;
    std::memcpy(&device_value, argument_buffer, sizeof(device_value));
    std::memcpy(&context_value, argument_buffer + sizeof(device_value), sizeof(context_value));
    auto* device = reinterpret_cast<ID3D11Device*>(static_cast<std::uintptr_t>(device_value));
    auto* context = reinterpret_cast<ID3D11DeviceContext*>(static_cast<std::uintptr_t>(context_value));
    if (!device || !context) {
        g_error = "GameMaker did not provide D3D11 device pointers.";
        return 0.0;
    }
    g_device = device;
    g_context = context;
    reset_capture_resources();
    return 1.0;
}

extern "C" __declspec(dllexport) double video_renderer_configure(double width_value,
    double height_value, double fps_value, double crf_value) {
    g_width = static_cast<int>(width_value);
    g_height = static_cast<int>(height_value);
    g_fps = fps_value;
    g_crf = std::clamp(static_cast<int>(crf_value), 0, 51);
    if (g_width <= 0 || g_height <= 0 || g_fps <= 0.0) {
        g_error = "Invalid renderer configuration.";
        return 0.0;
    }
    return 1.0;
}

extern "C" __declspec(dllexport) double video_renderer_set_ffmpeg(const char* ffmpeg_path) {
    g_ffmpeg = ffmpeg_path && *ffmpeg_path ? ffmpeg_path : "ffmpeg.exe";
    return 1.0;
}

extern "C" __declspec(dllexport) double video_renderer_set_audio_delay(double seconds) {
    if (!std::isfinite(seconds) || seconds < 0.0 || seconds > 60.0) {
        g_error = "Invalid renderer audio delay.";
        return 0.0;
    }
    g_audio_delay_seconds = seconds;
    return 1.0;
}

extern "C" __declspec(dllexport) double video_renderer_set_preset(const char* preset) {
    const std::string value = preset && *preset ? preset : "medium";
    static constexpr std::string_view allowed[] = {
        "ultrafast", "superfast", "veryfast", "faster", "fast",
        "medium", "slow", "slower", "veryslow"
    };
    if (std::find(std::begin(allowed), std::end(allowed), value) == std::end(allowed)) {
        g_error = "Invalid H.264 preset.";
        return 0.0;
    }
    g_preset = value;
    return 1.0;
}

extern "C" __declspec(dllexport) double video_renderer_set_encoder(const char* encoder) {
    const std::string value = encoder && *encoder ? encoder : "auto";
    static constexpr std::string_view allowed[] = {"auto", "nvenc", "amf", "qsv", "x264"};
    if (std::find(std::begin(allowed), std::end(allowed), value) == std::end(allowed)) {
        g_error = "Invalid video encoder.";
        return 0.0;
    }
    g_encoder = value;
    return 1.0;
}

extern "C" __declspec(dllexport) double video_renderer_start(const char* output_path,
    const char* audio_path) {
    finish_process();
    reset_nvenc(true);
    reset_amf(true);
    g_error.clear();
    g_output_path = output_path && *output_path ? output_path : "";
    g_audio_path = audio_path && *audio_path ? audio_path : "";

    const int width = g_width;
    const int height = g_height;
    const double fps = g_fps;
    if (!output_path || !*output_path || !audio_path || !*audio_path || width <= 0
        || height <= 0 || fps <= 0.0) {
        g_error = "Invalid renderer arguments.";
        return 0.0;
    }

    SECURITY_ATTRIBUTES security{sizeof(SECURITY_ATTRIBUTES), nullptr, TRUE};
    HANDLE read_pipe = nullptr;
    HANDLE write_pipe = nullptr;
    if (!CreatePipe(&read_pipe, &write_pipe, &security, 1024 * 1024)) {
        g_error = "CreatePipe failed.";
        return 0.0;
    }
    SetHandleInformation(write_pipe, HANDLE_FLAG_INHERIT, 0);

    const std::wstring executable = utf8_to_wide(g_ffmpeg);
    const std::wstring output = utf8_to_wide(output_path);
    const std::wstring audio = utf8_to_wide(audio_path);
    wchar_t size_text[64]{};
    wchar_t fps_text[64]{};
    swprintf_s(size_text, L"%dx%d", width, height);
    swprintf_s(fps_text, L"%.8g", fps);
    g_pipe_bgra = false;
    select_pipe_format();
    g_active_encoder = g_encoder == "auto" ? preferred_hardware_encoder() : g_encoder;
    if (g_active_encoder != "x264" && g_active_encoder != "amf"
        && !probe_hardware_encoder(g_active_encoder)) {
        std::fprintf(stderr, "[Renderer] Hardware encoder '%s' unavailable; falling back to x264\n",
            g_active_encoder.c_str());
        g_active_encoder = "x264";
    }
    std::fprintf(stderr, "[Renderer] Raw frame pipe: %s, batched writes enabled\n",
        g_pipe_bgra ? "BGRA" : "RGBA");
    std::fprintf(stderr, "[Renderer] Video encoder: %s\n", g_active_encoder.c_str());

    if (g_active_encoder == "nvenc") {
        ComPtr<ID3D11RenderTargetView> target_view;
        ComPtr<ID3D11Resource> resource;
        ComPtr<ID3D11Texture2D> target;
        g_context->OMGetRenderTargets(1, &target_view, nullptr);
        if (target_view) target_view->GetResource(&resource);
        if (resource) resource.As(&target);
        D3D11_RENDER_TARGET_VIEW_DESC view_desc{};
        if (target_view) target_view->GetDesc(&view_desc);
        if (target && initialize_zero_copy_nvenc(target.Get(), view_desc.Format)) {
            CloseHandle(read_pipe);
            CloseHandle(write_pipe);
            g_captured_frames = 0;
            std::fprintf(stderr, "[Renderer] NVIDIA D3D11 zero-copy NVENC enabled\n");
            return 1.0;
        }
        std::fprintf(stderr, "[Renderer] Direct NVENC unavailable (%s); using external NVENC\n",
            g_error.c_str());
        g_error.clear();
    }

    if (g_active_encoder == "amf") {
        ComPtr<ID3D11RenderTargetView> target_view;
        ComPtr<ID3D11Resource> resource;
        ComPtr<ID3D11Texture2D> target;
        g_context->OMGetRenderTargets(1, &target_view, nullptr);
        if (target_view) target_view->GetResource(&resource);
        if (resource) resource.As(&target);
        D3D11_RENDER_TARGET_VIEW_DESC view_desc{};
        if (target_view) target_view->GetDesc(&view_desc);
        if (target && initialize_zero_copy_amf(target.Get(), view_desc.Format)) {
            CloseHandle(read_pipe);
            CloseHandle(write_pipe);
            g_captured_frames = 0;
            std::fprintf(stderr, "[Renderer] AMD D3D11 zero-copy AMF enabled\n");
            return 1.0;
        }
        std::fprintf(stderr, "[Renderer] Direct AMF unavailable (%s); using external h264_amf\n",
            g_error.c_str());
        g_error.clear();
        if (!probe_hardware_encoder("amf")) {
            std::fprintf(stderr, "[Renderer] External h264_amf unavailable; falling back to x264\n");
            g_active_encoder = "x264";
        }
    }

    std::wstring command = quote(executable)
        + L" -hide_banner -loglevel warning -y -f rawvideo -pixel_format "
        + (g_pipe_bgra ? L"bgra" : L"rgba") + L" -video_size "
        + size_text + L" -framerate " + fps_text + L" -i pipe:0 -itsoffset "
        + std::to_wstring(g_audio_delay_seconds) + L" -i " + quote(audio)
        + L" -map 0:v:0 -map 1:a:0?" + hardware_encoder_options()
        + (g_active_encoder == "qsv" ? L" -pix_fmt nv12" : L" -pix_fmt yuv420p")
        + L" -c:a aac -b:a 192k -movflags +faststart "
        + quote(output);

    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    startup.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
    startup.wShowWindow = SW_HIDE;
    startup.hStdInput = read_pipe;
    startup.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
    startup.hStdError = GetStdHandle(STD_ERROR_HANDLE);
    PROCESS_INFORMATION process{};
    const BOOL created = CreateProcessW(nullptr, command.data(), nullptr, nullptr, TRUE,
        CREATE_NO_WINDOW, nullptr, nullptr, &startup, &process);
    CloseHandle(read_pipe);
    if (!created) {
        CloseHandle(write_pipe);
        g_error = "Unable to start FFmpeg (Win32 error " + std::to_string(GetLastError()) + ").";
        return 0.0;
    }

    g_process = process.hProcess;
    g_thread = process.hThread;
    g_stdin = write_pipe;
    g_captured_frames = 0;
    g_next_staging_slot = 0;
    g_pending_staging_slot = kNoStagingSlot;
    return 1.0;
}

extern "C" __declspec(dllexport) double video_renderer_capture() {
    if ((!g_nvenc.active && !g_amf.active && (!g_process || !g_stdin))
        || !g_device || !g_context) {
        g_error = "Renderer is not running.";
        return 0.0;
    }

    ComPtr<ID3D11RenderTargetView> target_view;
    g_context->OMGetRenderTargets(1, &target_view, nullptr);
    if (!target_view) {
        g_error = "No active D3D11 render target.";
        return 0.0;
    }
    ComPtr<ID3D11Resource> resource;
    target_view->GetResource(&resource);
    ComPtr<ID3D11Texture2D> target;
    if (!resource || FAILED(resource.As(&target)) || !target) {
        g_error = "The active render target is not a D3D11 texture.";
        return 0.0;
    }
    D3D11_TEXTURE2D_DESC source{};
    target->GetDesc(&source);
    if (source.Width != static_cast<UINT>(g_width) || source.Height != static_cast<UINT>(g_height)) {
        g_error = "The active render target size does not match the encoder.";
        return 0.0;
    }
    D3D11_RENDER_TARGET_VIEW_DESC view_desc{};
    target_view->GetDesc(&view_desc);
    if (g_nvenc.active) return submit_zero_copy_nvenc(target.Get(), view_desc.Format) ? 1.0 : 0.0;
    if (g_amf.active) return submit_zero_copy_amf(target.Get(), view_desc.Format) ? 1.0 : 0.0;
    if (!ensure_capture_resources(target.Get(), view_desc.Format)) return 0.0;

    const UINT write_slot = g_next_staging_slot;
    if (source.SampleDesc.Count > 1) {
        g_context->ResolveSubresource(g_resolved.Get(), 0, target.Get(), 0, view_desc.Format);
        g_context->CopyResource(g_staging[write_slot].Get(), g_resolved.Get());
    } else {
        g_context->CopyResource(g_staging[write_slot].Get(), target.Get());
    }
    const UINT previous_slot = g_pending_staging_slot;
    g_pending_staging_slot = write_slot;
    g_next_staging_slot = (write_slot + 1) % static_cast<UINT>(g_staging.size());
    ++g_captured_frames;
    const bool success = previous_slot == kNoStagingSlot || write_staging_frame(previous_slot);
    return success ? 1.0 : 0.0;
}

extern "C" __declspec(dllexport) double video_renderer_finish() {
    if (g_nvenc.active || g_amf.active) {
        const bool encoded = g_nvenc.active ? finish_zero_copy_nvenc() : finish_zero_copy_amf();
        if (!encoded) return 0.0;
        const bool mixed = mix_hitsounds();
        g_hitsounds.clear();
        return mixed ? 1.0 : 0.0;
    }
    if (!flush_pending_capture()) {
        finish_process();
        return 0.0;
    }
    if (finish_process() == 0.0) return 0.0;
    const bool mixed = mix_hitsounds();
    g_hitsounds.clear();
    return mixed ? 1.0 : 0.0;
}

extern "C" __declspec(dllexport) double video_renderer_clear_hitsounds() {
    g_hitsounds.clear();
    return 1.0;
}

extern "C" __declspec(dllexport) double video_renderer_add_hitsound(const char* path,
    double time, double volume) {
    if (!path || !*path || time < 0.0) {
        g_error = "Invalid hitsound event.";
        return 0.0;
    }
    g_hitsounds.push_back({path, time + g_audio_delay_seconds, std::clamp(volume, 0.0, 4.0)});
    return 1.0;
}

extern "C" __declspec(dllexport) const char* video_renderer_get_error() {
    return g_error.c_str();
}

extern "C" __declspec(dllexport) double video_renderer_shutdown() {
    if (g_process) {
        TerminateProcess(g_process, 1);
        WaitForSingleObject(g_process, 5000);
    }
    close_handles();
    reset_nvenc(true);
    reset_amf(true);
    g_hitsounds.clear();
    g_output_path.clear();
    g_audio_path.clear();
    g_audio_delay_seconds = 0.0;
    g_captured_frames = 0;
    g_pipe_bgra = false;
    g_active_encoder = "x264";
    reset_capture_resources();
    g_context.Reset();
    g_device.Reset();
    return 1.0;
}
