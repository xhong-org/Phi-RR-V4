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

void MsgBox_Initialize();
void MsgBox_Shutdown();
void MsgBox_ClearButtons();
bool MsgBox_SetButton(std::int32_t index, std::string_view text);
bool MsgBox_SetButtonAlignment(std::int32_t alignment);
std::int32_t MsgBox_ShowSync(std::string_view message, std::string_view title, std::int32_t kind);
std::int32_t MsgBox_ShowAsync(std::string_view message, std::string_view title, std::int32_t kind);
std::int32_t MsgBox_TaskStatus(std::int32_t task_id);
std::int32_t MsgBox_TaskResult(std::int32_t task_id);
bool MsgBox_TaskRelease(std::int32_t task_id);
std::int32_t MsgBox_Info(std::string_view message, std::string_view title);
std::int32_t MsgBox_Warning(std::string_view message, std::string_view title);
std::int32_t MsgBox_Error(std::string_view message, std::string_view title);
