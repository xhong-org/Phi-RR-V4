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

void unicode_zip_initialize();
bool unicode_zip_available();
std::int32_t unicode_zip_extract_async(std::string_view archive_path, std::string_view output_directory, bool overwrite, bool clean_output);
std::int32_t unicode_zip_compress_async(std::string_view source_path, std::string_view archive_path, bool include_root, bool overwrite);
std::int32_t unicode_zip_task_status(std::int32_t task_id);
std::int32_t unicode_zip_task_exit_code(std::int32_t task_id);
std::string unicode_zip_task_error(std::int32_t task_id);
bool unicode_zip_task_cancel(std::int32_t task_id);
bool unicode_zip_task_release(std::int32_t task_id);
std::string unicode_zip_last_error();
void unicode_zip_shutdown();
