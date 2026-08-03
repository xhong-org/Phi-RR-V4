// ##### extgen :: Auto-generated file do not edit!! #####

#pragma once
#include "core/GMExtUtils.h"

GMEXPORT double __EXT_NATIVE__ffvideos_initialize(char* __arg_buffer, double __arg_buffer_length);
GMEXPORT double __EXT_NATIVE__ffvideos_open(char* path);
GMEXPORT double __EXT_NATIVE__ffvideos_close(double handle);
GMEXPORT double __EXT_NATIVE__ffvideos_play(double handle);
GMEXPORT double __EXT_NATIVE__ffvideos_pause(double handle);
GMEXPORT double __EXT_NATIVE__ffvideos_seek(double handle, double position_ms);
GMEXPORT double __EXT_NATIVE__ffvideos_prepare_frame(double handle, double position_ms, double timeout_ms);
GMEXPORT double __EXT_NATIVE__ffvideos_set_volume(double handle, double volume);
GMEXPORT double __EXT_NATIVE__ffvideos_set_loop(double handle, double enabled);
GMEXPORT double __EXT_NATIVE__ffvideos_get_status(double handle);
GMEXPORT double __EXT_NATIVE__ffvideos_get_duration(double handle);
GMEXPORT double __EXT_NATIVE__ffvideos_get_position(double handle);
GMEXPORT double __EXT_NATIVE__ffvideos_get_width(double handle);
GMEXPORT double __EXT_NATIVE__ffvideos_get_height(double handle);
GMEXPORT double __EXT_NATIVE__ffvideos_draw(double handle, double left, double top, double right, double bottom, double alpha, double dim);
GMEXPORT char* __EXT_NATIVE__ffvideos_get_error(double handle);
GMEXPORT double __EXT_NATIVE__ffvideos_shutdown();

