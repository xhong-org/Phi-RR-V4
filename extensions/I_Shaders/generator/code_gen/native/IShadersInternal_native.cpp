// ##### extgen :: Auto-generated file do not edit!! #####

#include "IShadersInternal_native.h"
#include "IShadersInternal_exports.h"

using namespace gm_structs;
using namespace gm::wire::codec;

GMEXPORT double __EXT_NATIVE__rpe_hlsl_initialize(char* __arg_buffer, double __arg_buffer_length)
{
    gm::byteio::BufferReader __br{__arg_buffer, static_cast<size_t>(__arg_buffer_length)};

    // field: device, type: Pointer
    void* device = reinterpret_cast<void*>(gm::wire::codec::readValue<std::uint64_t>(__br));

    // field: context, type: Pointer
    void* context = reinterpret_cast<void*>(gm::wire::codec::readValue<std::uint64_t>(__br));

    auto&& __result = rpe_hlsl_initialize(device, context);
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__rpe_hlsl_state()
{
    auto&& __result = rpe_hlsl_state();
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__rpe_hlsl_compile(char* source, char* source_name)
{
    auto&& __result = rpe_hlsl_compile(source, source_name);
    return static_cast<double>(__result);
}

GMEXPORT char* __EXT_NATIVE__rpe_glsl_translate(char* source, char* source_name)
{
    static std::string __result;
    __result = rpe_glsl_translate(source, source_name);
    return (char*)__result.c_str();
}

GMEXPORT double __EXT_NATIVE__rpe_hlsl_set_uniform_component(double handle, char* uniform_name, double component, double value)
{
    auto&& __result = rpe_hlsl_set_uniform_component(static_cast<std::int32_t>(handle), uniform_name, static_cast<std::int32_t>(component), static_cast<float>(value));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__rpe_hlsl_begin(double handle)
{
    auto&& __result = rpe_hlsl_begin(static_cast<std::int32_t>(handle));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__rpe_hlsl_draw(double handle, double uv_left, double uv_top, double uv_right, double uv_bottom)
{
    auto&& __result = rpe_hlsl_draw(static_cast<std::int32_t>(handle), static_cast<float>(uv_left), static_cast<float>(uv_top), static_cast<float>(uv_right), static_cast<float>(uv_bottom));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__rpe_hlsl_target_width()
{
    auto&& __result = rpe_hlsl_target_width();
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__rpe_hlsl_target_height()
{
    auto&& __result = rpe_hlsl_target_height();
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__rpe_hlsl_end()
{
    auto&& __result = rpe_hlsl_end();
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__rpe_hlsl_release(double handle)
{
    auto&& __result = rpe_hlsl_release(static_cast<std::int32_t>(handle));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__rpe_hlsl_shutdown()
{
    rpe_hlsl_shutdown();
    return 0;
}

GMEXPORT char* __EXT_NATIVE__rpe_hlsl_get_error()
{
    static std::string __result;
    __result = rpe_hlsl_get_error();
    return (char*)__result.c_str();
}

