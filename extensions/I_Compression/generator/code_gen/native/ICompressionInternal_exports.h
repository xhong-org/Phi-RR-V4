// ##### extgen :: Auto-generated file do not edit!! #####

#pragma once
#include "core/GMExtUtils.h"

GMEXPORT double __EXT_NATIVE__unicode_zip_initialize();
GMEXPORT double __EXT_NATIVE__unicode_zip_available();
GMEXPORT double __EXT_NATIVE__unicode_zip_extract_async(char* archive_path, char* output_directory, double overwrite, double clean_output);
GMEXPORT double __EXT_NATIVE__unicode_zip_compress_async(char* source_path, char* archive_path, double include_root, double overwrite);
GMEXPORT double __EXT_NATIVE__unicode_zip_task_status(double task_id);
GMEXPORT double __EXT_NATIVE__unicode_zip_task_exit_code(double task_id);
GMEXPORT char* __EXT_NATIVE__unicode_zip_task_error(double task_id);
GMEXPORT double __EXT_NATIVE__unicode_zip_task_cancel(double task_id);
GMEXPORT double __EXT_NATIVE__unicode_zip_task_release(double task_id);
GMEXPORT char* __EXT_NATIVE__unicode_zip_last_error();
GMEXPORT double __EXT_NATIVE__unicode_zip_shutdown();

