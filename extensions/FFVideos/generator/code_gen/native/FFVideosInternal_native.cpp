// ##### extgen :: Auto-generated file do not edit!! #####

#include "FFVideosInternal_native.h"
#include "FFVideosInternal_exports.h"

using namespace gm_structs;
using namespace gm::wire::codec;

GMEXPORT double __EXT_NATIVE__ffvideos_initialize(char* __arg_buffer, double __arg_buffer_length)
{
    gm::byteio::BufferReader __br{__arg_buffer, static_cast<size_t>(__arg_buffer_length)};

    // field: device, type: Pointer
    void* device = reinterpret_cast<void*>(gm::wire::codec::readValue<std::uint64_t>(__br));

    // field: context, type: Pointer
    void* context = reinterpret_cast<void*>(gm::wire::codec::readValue<std::uint64_t>(__br));

    auto&& __result = ffvideos_initialize(device, context);
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__ffvideos_open(char* path)
{
    auto&& __result = ffvideos_open(path);
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__ffvideos_close(double handle)
{
    auto&& __result = ffvideos_close(static_cast<std::int32_t>(handle));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__ffvideos_play(double handle)
{
    auto&& __result = ffvideos_play(static_cast<std::int32_t>(handle));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__ffvideos_pause(double handle)
{
    auto&& __result = ffvideos_pause(static_cast<std::int32_t>(handle));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__ffvideos_seek(double handle, double position_ms)
{
    auto&& __result = ffvideos_seek(static_cast<std::int32_t>(handle), static_cast<float>(position_ms));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__ffvideos_prepare_frame(double handle, double position_ms, double timeout_ms)
{
    auto&& __result = ffvideos_prepare_frame(static_cast<std::int32_t>(handle), static_cast<float>(position_ms), static_cast<float>(timeout_ms));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__ffvideos_set_volume(double handle, double volume)
{
    auto&& __result = ffvideos_set_volume(static_cast<std::int32_t>(handle), static_cast<float>(volume));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__ffvideos_set_loop(double handle, double enabled)
{
    auto&& __result = ffvideos_set_loop(static_cast<std::int32_t>(handle), static_cast<bool>(enabled));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__ffvideos_get_status(double handle)
{
    auto&& __result = ffvideos_get_status(static_cast<std::int32_t>(handle));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__ffvideos_get_duration(double handle)
{
    auto&& __result = ffvideos_get_duration(static_cast<std::int32_t>(handle));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__ffvideos_get_position(double handle)
{
    auto&& __result = ffvideos_get_position(static_cast<std::int32_t>(handle));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__ffvideos_get_width(double handle)
{
    auto&& __result = ffvideos_get_width(static_cast<std::int32_t>(handle));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__ffvideos_get_height(double handle)
{
    auto&& __result = ffvideos_get_height(static_cast<std::int32_t>(handle));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__ffvideos_draw(double handle, double left, double top, double right, double bottom, double alpha, double dim)
{
    auto&& __result = ffvideos_draw(static_cast<std::int32_t>(handle), static_cast<float>(left), static_cast<float>(top), static_cast<float>(right), static_cast<float>(bottom), static_cast<float>(alpha), static_cast<float>(dim));
    return static_cast<double>(__result);
}

GMEXPORT char* __EXT_NATIVE__ffvideos_get_error(double handle)
{
    static std::string __result;
    __result = ffvideos_get_error(static_cast<std::int32_t>(handle));
    return (char*)__result.c_str();
}

GMEXPORT double __EXT_NATIVE__ffvideos_shutdown()
{
    ffvideos_shutdown();
    return 0;
}

