// ##### extgen :: Auto-generated file do not edit!! #####

#pragma once
#include <cstdint>
#include <string_view>
#include <vector>
#include <array>
#include <optional>
#include "core/GMExtWire.h"

namespace gm_consts
{
}


namespace gm_enums
{
}


namespace gm_structs
{

}

namespace gm::wire::codec
{
}

namespace gm::wire::details
{
}

std::int32_t rpe_hlsl_initialize(void* device, void* context);
std::int32_t rpe_hlsl_state();
std::int32_t rpe_hlsl_compile(std::string_view source, std::string_view source_name);
std::string rpe_glsl_translate(std::string_view source, std::string_view source_name);
bool rpe_hlsl_set_uniform_component(std::int32_t handle, std::string_view uniform_name, std::int32_t component, float value);
bool rpe_hlsl_begin(std::int32_t handle);
std::int32_t rpe_hlsl_draw(std::int32_t handle, float uv_left, float uv_top, float uv_right, float uv_bottom);
std::int32_t rpe_hlsl_target_width();
std::int32_t rpe_hlsl_target_height();
bool rpe_hlsl_end();
bool rpe_hlsl_release(std::int32_t handle);
void rpe_hlsl_shutdown();
std::string rpe_hlsl_get_error();
