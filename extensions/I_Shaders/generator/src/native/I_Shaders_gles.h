#pragma once

#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <d3d11.h>

#include <cstdint>
#include <string>
#include <string_view>

// Desktop OpenGL ES 1.00 compile path. D3D11 cannot consume GLSL, and the
// embedded AngleCompiler DLLs are 32-bit, so this context lives in-process.
bool rpe_gles_startup();
void rpe_gles_shutdown();
bool rpe_gles_available();
bool rpe_gles_is_source(std::string_view source);
std::int32_t rpe_gles_compile(std::string_view source, std::string_view sourceName);
bool rpe_gles_set_uniform(std::int32_t handle, std::string_view name, std::int32_t component, float value);
std::int32_t rpe_gles_draw(ID3D11Device* device, ID3D11DeviceContext* context, std::int32_t handle,
    float uvLeft, float uvTop, float uvRight, float uvBottom,
    std::int32_t* targetWidth, std::int32_t* targetHeight);
bool rpe_gles_release(std::int32_t handle);
std::string rpe_gles_last_error();
