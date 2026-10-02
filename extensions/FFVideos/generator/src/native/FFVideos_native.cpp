#include "FFVideos_native.h"
#include "FFmpegDecoder.h"

#if defined(OS_WINDOWS)
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <Windows.h>
#include <d3d11.h>
#include <d3dcompiler.h>
#include <wrl/client.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <limits>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>
#include <unordered_map>
#endif

namespace {
#if defined(OS_WINDOWS)
using Microsoft::WRL::ComPtr;

constexpr std::int32_t kStatusClosed = 0;

struct DrawConstants {
    float alpha;
    float dim;
    float padding[2];
    float uvLeft;
    float uvTop;
    float uvRight;
    float uvBottom;
    float yuvOffset[4];
    float yuvRed[4];
    float yuvGreen[4];
    float yuvBlue[4];
};

struct VideoPlayer {
    explicit VideoPlayer(std::string_view path) : decoder(std::make_unique<FFmpegDecoder>(path)) {}

    std::unique_ptr<FFmpegDecoder> decoder;
    ComPtr<ID3D11Texture2D> yTexture;
    ComPtr<ID3D11ShaderResourceView> yView;
    ComPtr<ID3D11Texture2D> uvTexture;
    ComPtr<ID3D11ShaderResourceView> uvView;
    std::uint64_t uploadedGeneration = 0;
};

std::mutex g_mutex;
std::unordered_map<std::int32_t, std::shared_ptr<VideoPlayer>> g_players;
std::int32_t g_nextHandle = 1;
std::string g_globalError;
ComPtr<ID3D11Device> g_device;
ComPtr<ID3D11DeviceContext> g_context;
ComPtr<ID3D11VertexShader> g_vertexShader;
ComPtr<ID3D11PixelShader> g_pixelShader;
ComPtr<ID3D11SamplerState> g_sampler;
ComPtr<ID3D11Buffer> g_drawConstants;
ComPtr<ID3D11RasterizerState> g_rasterizer;
ComPtr<ID3D11RasterizerState> g_rasterizerScissor;
ComPtr<ID3D11DepthStencilState> g_depthStencil;
ComPtr<ID3D11BlendState> g_blend;

void setGlobalError(std::string message) {
    std::lock_guard lock(g_mutex);
    g_globalError = std::move(message);
}

std::string hresultText(const char* operation, HRESULT result) {
    char code[16]{};
    sprintf_s(code, "0x%08lX", static_cast<unsigned long>(result));
    return std::string(operation) + " failed (" + code + ").";
}

std::shared_ptr<VideoPlayer> getPlayer(std::int32_t handle) {
    std::lock_guard lock(g_mutex);
    const auto found = g_players.find(handle);
    return found == g_players.end() ? nullptr : found->second;
}

bool compileShader(const char* source, const char* profile, ComPtr<ID3DBlob>& bytecode) {
    ComPtr<ID3DBlob> errors;
    const HRESULT result = D3DCompile(source, std::strlen(source), "FFVideos", nullptr, nullptr,
        "main", profile, D3DCOMPILE_ENABLE_STRICTNESS | D3DCOMPILE_OPTIMIZATION_LEVEL3,
        0, &bytecode, &errors);
    if (FAILED(result)) {
        std::string message = hresultText("D3DCompile", result);
        if (errors && errors->GetBufferPointer()) {
            message += " ";
            message.append(static_cast<const char*>(errors->GetBufferPointer()), errors->GetBufferSize());
        }
        setGlobalError(std::move(message));
        return false;
    }
    return true;
}

bool createDrawResources() {
    static constexpr char vertexSource[] = R"HLSL(
struct VSOutput { float4 position : SV_Position; float2 uv : TEXCOORD0; };
VSOutput main(uint vertexId : SV_VertexID) {
    static const float2 positions[6] = {
        float2(-1.0, 1.0), float2(1.0, 1.0), float2(-1.0, -1.0),
        float2(-1.0, -1.0), float2(1.0, 1.0), float2(1.0, -1.0)
    };
    static const float2 uvs[6] = {
        float2(0.0, 0.0), float2(1.0, 0.0), float2(0.0, 1.0),
        float2(0.0, 1.0), float2(1.0, 0.0), float2(1.0, 1.0)
    };
    VSOutput output;
    output.position = float4(positions[vertexId], 0.0, 1.0);
    output.uv = uvs[vertexId];
    return output;
}
)HLSL";
    static constexpr char pixelSource[] = R"HLSL(
Texture2D yTexture : register(t0);
Texture2D uvTexture : register(t1);
SamplerState videoSampler : register(s0);
cbuffer DrawConstants : register(b0) {
    float alpha;
    float dim;
    float2 padding;
    float4 uvRect;
    float4 yuvOffset;
    float4 yuvRed;
    float4 yuvGreen;
    float4 yuvBlue;
};
float4 main(float4 position : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    float2 sourceUv = lerp(uvRect.xy, uvRect.zw, uv);
    float3 yuv = float3(yTexture.Sample(videoSampler, sourceUv).r,
        uvTexture.Sample(videoSampler, sourceUv).rg) - yuvOffset.xyz;
    float3 colour = float3(dot(yuv, yuvRed.xyz), dot(yuv, yuvGreen.xyz),
        dot(yuv, yuvBlue.xyz)) * (1.0 - saturate(dim));
    return float4(colour, saturate(alpha));
}
)HLSL";

    ComPtr<ID3DBlob> vertexBytecode;
    ComPtr<ID3DBlob> pixelBytecode;
    if (!compileShader(vertexSource, "vs_4_0", vertexBytecode)
        || !compileShader(pixelSource, "ps_4_0", pixelBytecode)) return false;
    HRESULT result = g_device->CreateVertexShader(vertexBytecode->GetBufferPointer(),
        vertexBytecode->GetBufferSize(), nullptr, &g_vertexShader);
    if (FAILED(result)) {
        setGlobalError(hresultText("CreateVertexShader", result));
        return false;
    }
    result = g_device->CreatePixelShader(pixelBytecode->GetBufferPointer(),
        pixelBytecode->GetBufferSize(), nullptr, &g_pixelShader);
    if (FAILED(result)) {
        setGlobalError(hresultText("CreatePixelShader", result));
        return false;
    }

    D3D11_SAMPLER_DESC sampler{};
    sampler.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
    sampler.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP;
    sampler.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
    sampler.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
    sampler.MaxLOD = D3D11_FLOAT32_MAX;
    if (FAILED(g_device->CreateSamplerState(&sampler, &g_sampler))) return false;

    D3D11_BUFFER_DESC constants{};
    constants.ByteWidth = sizeof(DrawConstants);
    constants.Usage = D3D11_USAGE_DEFAULT;
    constants.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
    if (FAILED(g_device->CreateBuffer(&constants, nullptr, &g_drawConstants))) return false;

    D3D11_RASTERIZER_DESC rasterizer{};
    rasterizer.FillMode = D3D11_FILL_SOLID;
    rasterizer.CullMode = D3D11_CULL_NONE;
    rasterizer.DepthClipEnable = TRUE;
    if (FAILED(g_device->CreateRasterizerState(&rasterizer, &g_rasterizer))) return false;
    rasterizer.ScissorEnable = TRUE;
    if (FAILED(g_device->CreateRasterizerState(&rasterizer, &g_rasterizerScissor))) return false;

    D3D11_DEPTH_STENCIL_DESC depth{};
    depth.DepthEnable = FALSE;
    depth.StencilEnable = FALSE;
    if (FAILED(g_device->CreateDepthStencilState(&depth, &g_depthStencil))) return false;

    D3D11_BLEND_DESC blend{};
    blend.RenderTarget[0].BlendEnable = TRUE;
    blend.RenderTarget[0].SrcBlend = D3D11_BLEND_SRC_ALPHA;
    blend.RenderTarget[0].DestBlend = D3D11_BLEND_INV_SRC_ALPHA;
    blend.RenderTarget[0].BlendOp = D3D11_BLEND_OP_ADD;
    blend.RenderTarget[0].SrcBlendAlpha = D3D11_BLEND_ONE;
    blend.RenderTarget[0].DestBlendAlpha = D3D11_BLEND_INV_SRC_ALPHA;
    blend.RenderTarget[0].BlendOpAlpha = D3D11_BLEND_OP_ADD;
    blend.RenderTarget[0].RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_ALL;
    if (FAILED(g_device->CreateBlendState(&blend, &g_blend))) return false;
    return true;
}

bool uploadFrame(VideoPlayer& player, const FFmpegVideoFrame& frame) {
    if (!frame.pixels || frame.width <= 0 || frame.height <= 0
        || frame.yStride <= 0 || frame.uvStride <= 0) return false;
    const std::size_t yBytes = static_cast<std::size_t>(frame.yStride)
        * static_cast<std::size_t>(frame.height);
    const std::size_t uvRows = static_cast<std::size_t>((frame.height + 1) / 2);
    const std::size_t uvBytes = static_cast<std::size_t>(frame.uvStride) * uvRows;
    if (frame.uvOffset < yBytes || frame.uvOffset > frame.pixels->size()
        || uvBytes > frame.pixels->size() - frame.uvOffset) {
        setGlobalError("The decoded frame buffer is invalid.");
        return false;
    }
    bool recreate = !player.yTexture || !player.uvTexture;
    if (player.yTexture) {
        D3D11_TEXTURE2D_DESC current{};
        player.yTexture->GetDesc(&current);
        recreate = current.Width != static_cast<UINT>(frame.width)
            || current.Height != static_cast<UINT>(frame.height);
    }
    if (recreate) {
        player.yView.Reset();
        player.yTexture.Reset();
        player.uvView.Reset();
        player.uvTexture.Reset();
        D3D11_TEXTURE2D_DESC texture{};
        texture.Width = static_cast<UINT>(frame.width);
        texture.Height = static_cast<UINT>(frame.height);
        texture.MipLevels = 1;
        texture.ArraySize = 1;
        texture.Format = DXGI_FORMAT_R8_UNORM;
        texture.SampleDesc.Count = 1;
        texture.Usage = D3D11_USAGE_DEFAULT;
        texture.BindFlags = D3D11_BIND_SHADER_RESOURCE;
        HRESULT result = g_device->CreateTexture2D(&texture, nullptr, &player.yTexture);
        if (FAILED(result)) {
            setGlobalError(hresultText("CreateTexture2D", result));
            return false;
        }
        result = g_device->CreateShaderResourceView(player.yTexture.Get(), nullptr, &player.yView);
        if (FAILED(result)) {
            setGlobalError(hresultText("CreateShaderResourceView(Y)", result));
            return false;
        }
        texture.Width = static_cast<UINT>((frame.width + 1) / 2);
        texture.Height = static_cast<UINT>((frame.height + 1) / 2);
        texture.Format = DXGI_FORMAT_R8G8_UNORM;
        result = g_device->CreateTexture2D(&texture, nullptr, &player.uvTexture);
        if (FAILED(result)) {
            setGlobalError(hresultText("CreateTexture2D(UV)", result));
            return false;
        }
        result = g_device->CreateShaderResourceView(player.uvTexture.Get(), nullptr, &player.uvView);
        if (FAILED(result)) {
            setGlobalError(hresultText("CreateShaderResourceView(UV)", result));
            return false;
        }
        player.uploadedGeneration = 0;
    }
    if (player.uploadedGeneration != frame.generation) {
        g_context->UpdateSubresource(player.yTexture.Get(), 0, nullptr,
            frame.pixels->data(), static_cast<UINT>(frame.yStride), 0);
        g_context->UpdateSubresource(player.uvTexture.Get(), 0, nullptr,
            frame.pixels->data() + frame.uvOffset, static_cast<UINT>(frame.uvStride), 0);
        player.uploadedGeneration = frame.generation;
    }
    return true;
}

void resetGlobals() {
    g_blend.Reset();
    g_depthStencil.Reset();
    g_rasterizer.Reset();
    g_rasterizerScissor.Reset();
    g_drawConstants.Reset();
    g_sampler.Reset();
    g_pixelShader.Reset();
    g_vertexShader.Reset();
    g_context.Reset();
    g_device.Reset();
}
#endif
}

std::int32_t ffvideos_initialize(void* device, void* context) {
#if defined(OS_WINDOWS)
    ffvideos_shutdown();
    if (!device || !context) {
        setGlobalError("Invalid D3D11 device or context pointer.");
        return 0;
    }
    auto* nativeDevice = static_cast<ID3D11Device*>(device);
    auto* nativeContext = static_cast<ID3D11DeviceContext*>(context);
    ComPtr<ID3D11Device> contextDevice;
    nativeContext->GetDevice(&contextDevice);
    if (contextDevice.Get() != nativeDevice) {
        setGlobalError("The D3D11 device and context do not belong together.");
        return 0;
    }
    nativeDevice->AddRef();
    g_device.Attach(nativeDevice);
    nativeContext->AddRef();
    g_context.Attach(nativeContext);
    if (!createDrawResources()) {
        resetGlobals();
        return 0;
    }
    setGlobalError({});
    return 3;
#else
    (void)device;
    (void)context;
    return 0;
#endif
}

std::int32_t ffvideos_open(std::string_view path) {
#if defined(OS_WINDOWS)
    if (!g_device || !g_context || path.empty()) {
        setGlobalError("FFVideos is not initialized or the path is empty.");
        return -1;
    }
    try {
        auto player = std::make_shared<VideoPlayer>(path);
        std::lock_guard lock(g_mutex);
        const std::int32_t firstCandidate = g_nextHandle;
        while (g_players.find(g_nextHandle) != g_players.end()) {
            g_nextHandle = g_nextHandle == std::numeric_limits<std::int32_t>::max()
                ? 1 : g_nextHandle + 1;
            if (g_nextHandle == firstCandidate) {
                g_globalError = "No video handles are available.";
                return -1;
            }
        }
        const std::int32_t handle = g_nextHandle;
        g_nextHandle = g_nextHandle == std::numeric_limits<std::int32_t>::max()
            ? 1 : g_nextHandle + 1;
        g_players.emplace(handle, std::move(player));
        g_globalError.clear();
        return handle;
    } catch (...) {
        setGlobalError("Unexpected failure while opening the video.");
        return -1;
    }
#else
    (void)path;
    return -1;
#endif
}

bool ffvideos_close(std::int32_t handle) {
#if defined(OS_WINDOWS)
    std::shared_ptr<VideoPlayer> removed;
    {
        std::lock_guard lock(g_mutex);
        const auto found = g_players.find(handle);
        if (found == g_players.end()) return false;
        removed = std::move(found->second);
        g_players.erase(found);
    }
    return true;
#else
    (void)handle;
    return false;
#endif
}

bool ffvideos_play(std::int32_t handle) {
#if defined(OS_WINDOWS)
    const auto player = getPlayer(handle);
    return player && player->decoder->play();
#else
    (void)handle;
    return false;
#endif
}

bool ffvideos_pause(std::int32_t handle) {
#if defined(OS_WINDOWS)
    const auto player = getPlayer(handle);
    return player && player->decoder->pause();
#else
    (void)handle;
    return false;
#endif
}

bool ffvideos_seek(std::int32_t handle, float positionMs) {
#if defined(OS_WINDOWS)
    const auto player = getPlayer(handle);
    return player && player->decoder->seek(positionMs);
#else
    (void)handle;
    (void)positionMs;
    return false;
#endif
}

bool ffvideos_prepare_frame(std::int32_t handle, float positionMs, float timeoutMs) {
#if defined(OS_WINDOWS)
    const auto player = getPlayer(handle);
    return player && player->decoder->prepareFrame(positionMs, timeoutMs);
#else
    (void)handle;
    (void)positionMs;
    (void)timeoutMs;
    return false;
#endif
}

bool ffvideos_set_volume(std::int32_t handle, float volume) {
#if defined(OS_WINDOWS)
    const auto player = getPlayer(handle);
    return player && player->decoder->setVolume(volume);
#else
    (void)handle;
    (void)volume;
    return false;
#endif
}

bool ffvideos_set_loop(std::int32_t handle, bool enabled) {
#if defined(OS_WINDOWS)
    const auto player = getPlayer(handle);
    return player && player->decoder->setLoop(enabled);
#else
    (void)handle;
    (void)enabled;
    return false;
#endif
}

std::int32_t ffvideos_get_status(std::int32_t handle) {
#if defined(OS_WINDOWS)
    const auto player = getPlayer(handle);
    return player ? player->decoder->status() : kStatusClosed;
#else
    (void)handle;
    return kStatusClosed;
#endif
}

float ffvideos_get_duration(std::int32_t handle) {
#if defined(OS_WINDOWS)
    const auto player = getPlayer(handle);
    return player ? player->decoder->durationMs() : 0.0f;
#else
    (void)handle;
    return 0.0f;
#endif
}

float ffvideos_get_position(std::int32_t handle) {
#if defined(OS_WINDOWS)
    const auto player = getPlayer(handle);
    return player ? player->decoder->positionMs() : 0.0f;
#else
    (void)handle;
    return 0.0f;
#endif
}

std::int32_t ffvideos_get_width(std::int32_t handle) {
#if defined(OS_WINDOWS)
    const auto player = getPlayer(handle);
    return player ? player->decoder->width() : 0;
#else
    (void)handle;
    return 0;
#endif
}

std::int32_t ffvideos_get_height(std::int32_t handle) {
#if defined(OS_WINDOWS)
    const auto player = getPlayer(handle);
    return player ? player->decoder->height() : 0;
#else
    (void)handle;
    return 0;
#endif
}

std::int32_t ffvideos_draw(std::int32_t handle, float left, float top, float right,
    float bottom, float alpha, float dim) {
#if defined(OS_WINDOWS)
    const auto player = getPlayer(handle);
    if (!player || !g_context || !(right > left && bottom > top)) return 0;
    const FFmpegVideoFrame frame = player->decoder->frame();
    if (!frame.pixels) return 0;
    if (!uploadFrame(*player, frame)) return -1;

    UINT viewportCount = D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE;
    D3D11_VIEWPORT previousViewports[D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE]{};
    g_context->RSGetViewports(&viewportCount, previousViewports);
    if (viewportCount == 0) return 0;

    ComPtr<ID3D11RenderTargetView> targetView;
    g_context->OMGetRenderTargets(1, &targetView, nullptr);
    float targetWidth = previousViewports[0].Width;
    float targetHeight = previousViewports[0].Height;
    if (targetView) {
        ComPtr<ID3D11Resource> targetResource;
        targetView->GetResource(&targetResource);
        ComPtr<ID3D11Texture2D> targetTexture;
        if (targetResource && SUCCEEDED(targetResource.As(&targetTexture)) && targetTexture) {
            D3D11_TEXTURE2D_DESC targetDesc{};
            targetTexture->GetDesc(&targetDesc);
            targetWidth = static_cast<float>(targetDesc.Width);
            targetHeight = static_cast<float>(targetDesc.Height);
        }
    }

    const float clippedLeft = std::clamp(left, 0.0f, 1.0f);
    const float clippedTop = std::clamp(top, 0.0f, 1.0f);
    const float clippedRight = std::clamp(right, 0.0f, 1.0f);
    const float clippedBottom = std::clamp(bottom, 0.0f, 1.0f);
    D3D11_VIEWPORT viewport{};
    viewport.TopLeftX = clippedLeft * targetWidth;
    viewport.TopLeftY = clippedTop * targetHeight;
    viewport.Width = (clippedRight - clippedLeft) * targetWidth;
    viewport.Height = (clippedBottom - clippedTop) * targetHeight;
    viewport.MinDepth = 0.0f;
    viewport.MaxDepth = 1.0f;
    if (viewport.Width <= 0.0f || viewport.Height <= 0.0f) return 0;

    ComPtr<ID3D11VertexShader> previousVertexShader;
    ComPtr<ID3D11PixelShader> previousPixelShader;
    ComPtr<ID3D11InputLayout> previousInputLayout;
    ComPtr<ID3D11Buffer> previousVertexBuffer;
    ID3D11ShaderResourceView* previousViews[2]{};
    ComPtr<ID3D11SamplerState> previousSampler;
    ComPtr<ID3D11Buffer> previousConstants;
    ComPtr<ID3D11RasterizerState> previousRasterizer;
    ComPtr<ID3D11DepthStencilState> previousDepthStencil;
    ComPtr<ID3D11BlendState> previousBlend;
    UINT previousStride = 0;
    UINT previousOffset = 0;
    UINT previousStencilRef = 0;
    UINT previousSampleMask = 0;
    FLOAT previousBlendFactor[4]{};
    D3D11_PRIMITIVE_TOPOLOGY previousTopology{};
    g_context->VSGetShader(&previousVertexShader, nullptr, nullptr);
    g_context->PSGetShader(&previousPixelShader, nullptr, nullptr);
    g_context->IAGetInputLayout(&previousInputLayout);
    g_context->IAGetPrimitiveTopology(&previousTopology);
    g_context->IAGetVertexBuffers(0, 1, &previousVertexBuffer, &previousStride, &previousOffset);
    g_context->PSGetShaderResources(0, 2, previousViews);
    g_context->PSGetSamplers(0, 1, &previousSampler);
    g_context->PSGetConstantBuffers(0, 1, &previousConstants);
    g_context->RSGetState(&previousRasterizer);
    g_context->OMGetDepthStencilState(&previousDepthStencil, &previousStencilRef);
    g_context->OMGetBlendState(&previousBlend, previousBlendFactor, &previousSampleMask);

    const float normalizedWidth = right - left;
    const float normalizedHeight = bottom - top;
    const bool bt2020 = frame.colourSpace == 9 || frame.colourSpace == 10;
    const bool bt709 = frame.colourSpace == 1 || (!bt2020 && frame.height >= 720);
    float yScale = frame.fullRange ? 1.0f : 1.16438356f;
    float redV = 0.0f;
    float greenU = 0.0f;
    float greenV = 0.0f;
    float blueU = 0.0f;
    if (bt2020) {
        redV = frame.fullRange ? 1.4746f : 1.67867f;
        greenU = frame.fullRange ? -0.164553f : -0.187326f;
        greenV = frame.fullRange ? -0.571353f : -0.650424f;
        blueU = frame.fullRange ? 1.8814f : 2.14177f;
    } else if (bt709) {
        redV = frame.fullRange ? 1.5748f : 1.792741f;
        greenU = frame.fullRange ? -0.187324f : -0.213249f;
        greenV = frame.fullRange ? -0.468124f : -0.532909f;
        blueU = frame.fullRange ? 1.8556f : 2.112402f;
    } else {
        redV = frame.fullRange ? 1.402f : 1.596027f;
        greenU = frame.fullRange ? -0.344136f : -0.391762f;
        greenV = frame.fullRange ? -0.714136f : -0.812968f;
        blueU = frame.fullRange ? 1.772f : 2.017232f;
    }
    const DrawConstants constants{
        std::clamp(alpha, 0.0f, 1.0f),
        std::clamp(dim, 0.0f, 1.0f),
        {0.0f, 0.0f},
        (clippedLeft - left) / normalizedWidth,
        (clippedTop - top) / normalizedHeight,
        (clippedRight - left) / normalizedWidth,
        (clippedBottom - top) / normalizedHeight,
        {frame.fullRange ? 0.0f : 16.0f / 255.0f, 0.5f, 0.5f, 0.0f},
        {yScale, 0.0f, redV, 0.0f},
        {yScale, greenU, greenV, 0.0f},
        {yScale, blueU, 0.0f, 0.0f}
    };
    g_context->UpdateSubresource(g_drawConstants.Get(), 0, nullptr, &constants, 0, 0);
    ID3D11Buffer* noVertexBuffer = nullptr;
    const UINT zero = 0;
    ID3D11ShaderResourceView* frameViews[2] = {player->yView.Get(), player->uvView.Get()};
    ID3D11SamplerState* sampler = g_sampler.Get();
    ID3D11Buffer* constantsBuffer = g_drawConstants.Get();
    UINT scissorCount = 0;
    g_context->RSGetScissorRects(&scissorCount, nullptr);
    D3D11_RECT scissors[D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE]{};
    if (scissorCount > D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE) {
        scissorCount = D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE;
    }
    if (scissorCount > 0) g_context->RSGetScissorRects(&scissorCount, scissors);
    bool scissorEnabled = false;
    for (UINT scissorIndex = 0; scissorIndex < scissorCount; ++scissorIndex) {
        if (scissors[scissorIndex].right > scissors[scissorIndex].left
            && scissors[scissorIndex].bottom > scissors[scissorIndex].top) {
            scissorEnabled = true;
            break;
        }
    }
    g_context->RSSetViewports(1, &viewport);
    g_context->IASetInputLayout(nullptr);
    g_context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    g_context->IASetVertexBuffers(0, 1, &noVertexBuffer, &zero, &zero);
    g_context->RSSetState(scissorEnabled ? g_rasterizerScissor.Get() : g_rasterizer.Get());
    g_context->OMSetDepthStencilState(g_depthStencil.Get(), 0);
    const FLOAT blendFactor[4]{};
    g_context->OMSetBlendState(g_blend.Get(), blendFactor, 0xffffffffu);
    g_context->VSSetShader(g_vertexShader.Get(), nullptr, 0);
    g_context->PSSetShader(g_pixelShader.Get(), nullptr, 0);
    g_context->PSSetShaderResources(0, 2, frameViews);
    g_context->PSSetSamplers(0, 1, &sampler);
    g_context->PSSetConstantBuffers(0, 1, &constantsBuffer);
    g_context->Draw(6, 0);

    ID3D11ShaderResourceView* nullViews[2]{};
    g_context->PSSetShaderResources(0, 2, nullViews);
    ID3D11Buffer* oldVertexBuffer = previousVertexBuffer.Get();
    ID3D11SamplerState* oldSampler = previousSampler.Get();
    ID3D11Buffer* oldConstants = previousConstants.Get();
    g_context->VSSetShader(previousVertexShader.Get(), nullptr, 0);
    g_context->PSSetShader(previousPixelShader.Get(), nullptr, 0);
    g_context->IASetInputLayout(previousInputLayout.Get());
    g_context->IASetPrimitiveTopology(previousTopology);
    g_context->IASetVertexBuffers(0, 1, &oldVertexBuffer, &previousStride, &previousOffset);
    g_context->PSSetShaderResources(0, 2, previousViews);
    g_context->PSSetSamplers(0, 1, &oldSampler);
    g_context->PSSetConstantBuffers(0, 1, &oldConstants);
    g_context->RSSetState(previousRasterizer.Get());
    g_context->OMSetDepthStencilState(previousDepthStencil.Get(), previousStencilRef);
    g_context->OMSetBlendState(previousBlend.Get(), previousBlendFactor, previousSampleMask);
    g_context->RSSetViewports(viewportCount, previousViewports);
    if (previousViews[0]) previousViews[0]->Release();
    if (previousViews[1]) previousViews[1]->Release();
    return 7;
#else
    (void)handle; (void)left; (void)top; (void)right; (void)bottom; (void)alpha; (void)dim;
    return 0;
#endif
}

std::string ffvideos_get_error(std::int32_t handle) {
#if defined(OS_WINDOWS)
    if (const auto player = getPlayer(handle)) return player->decoder->error();
    std::lock_guard lock(g_mutex);
    return g_globalError;
#else
    (void)handle;
    return "FFVideos is only available on Windows.";
#endif
}

void ffvideos_shutdown() {
#if defined(OS_WINDOWS)
    std::unordered_map<std::int32_t, std::shared_ptr<VideoPlayer>> players;
    {
        std::lock_guard lock(g_mutex);
        players.swap(g_players);
        g_nextHandle = 1;
    }
    players.clear();
    resetGlobals();
#endif
}
