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
    enum class FFVideosStatus : std::int64_t
    {
        Error = -1,
        Closed = 0,
        Preparing = 1,
        Playing = 2,
        Paused = 3,
        Ended = 4
    };

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

std::int32_t ffvideos_initialize(void* device, void* context);
std::int32_t ffvideos_open(std::string_view path);
bool ffvideos_close(std::int32_t handle);
bool ffvideos_play(std::int32_t handle);
bool ffvideos_pause(std::int32_t handle);
bool ffvideos_seek(std::int32_t handle, float position_ms);
bool ffvideos_prepare_frame(std::int32_t handle, float position_ms, float timeout_ms);
bool ffvideos_set_volume(std::int32_t handle, float volume);
bool ffvideos_set_loop(std::int32_t handle, bool enabled);
std::int32_t ffvideos_get_status(std::int32_t handle);
float ffvideos_get_duration(std::int32_t handle);
float ffvideos_get_position(std::int32_t handle);
std::int32_t ffvideos_get_width(std::int32_t handle);
std::int32_t ffvideos_get_height(std::int32_t handle);
std::int32_t ffvideos_draw(std::int32_t handle, float left, float top, float right, float bottom, float alpha, float dim);
std::string ffvideos_get_error(std::int32_t handle);
void ffvideos_shutdown();
