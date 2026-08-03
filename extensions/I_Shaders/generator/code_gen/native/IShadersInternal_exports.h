// ##### extgen :: Auto-generated file do not edit!! #####

#pragma once
#include "core/GMExtUtils.h"

GMEXPORT double __EXT_NATIVE__rpe_hlsl_initialize(char* __arg_buffer, double __arg_buffer_length);
GMEXPORT double __EXT_NATIVE__rpe_hlsl_state();
GMEXPORT double __EXT_NATIVE__rpe_hlsl_compile(char* source, char* source_name);
GMEXPORT char* __EXT_NATIVE__rpe_glsl_translate(char* source, char* source_name);
GMEXPORT double __EXT_NATIVE__rpe_hlsl_set_uniform_component(double handle, char* uniform_name, double component, double value);
GMEXPORT double __EXT_NATIVE__rpe_hlsl_begin(double handle);
GMEXPORT double __EXT_NATIVE__rpe_hlsl_draw(double handle, double uv_left, double uv_top, double uv_right, double uv_bottom);
GMEXPORT double __EXT_NATIVE__rpe_hlsl_target_width();
GMEXPORT double __EXT_NATIVE__rpe_hlsl_target_height();
GMEXPORT double __EXT_NATIVE__rpe_hlsl_end();
GMEXPORT double __EXT_NATIVE__rpe_hlsl_release(double handle);
GMEXPORT double __EXT_NATIVE__rpe_hlsl_shutdown();
GMEXPORT char* __EXT_NATIVE__rpe_hlsl_get_error();

