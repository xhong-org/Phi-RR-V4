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

bool rpe_worker_upload_lines(void* input, std::int32_t line_count);
std::int32_t rpe_worker_resolve_lines(void* input, std::int32_t line_count, void* output);
void rpe_worker_shutdown();
