// ##### extgen :: Auto-generated file do not edit!! #####

#include "MsgBoxInternal_native.h"
#include "MsgBoxInternal_exports.h"

using namespace gm_structs;
using namespace gm::wire::codec;

GMEXPORT double __EXT_NATIVE__MsgBox_Initialize()
{
    MsgBox_Initialize();
    return 0;
}

GMEXPORT double __EXT_NATIVE__MsgBox_Shutdown()
{
    MsgBox_Shutdown();
    return 0;
}

GMEXPORT double __EXT_NATIVE__MsgBox_ClearButtons()
{
    MsgBox_ClearButtons();
    return 0;
}

GMEXPORT double __EXT_NATIVE__MsgBox_SetButton(double index, char* text)
{
    auto&& __result = MsgBox_SetButton(static_cast<std::int32_t>(index), text);
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__MsgBox_SetButtonAlignment(double alignment)
{
    auto&& __result = MsgBox_SetButtonAlignment(static_cast<std::int32_t>(alignment));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__MsgBox_ShowSync(char* message, char* title, double kind)
{
    auto&& __result = MsgBox_ShowSync(message, title, static_cast<std::int32_t>(kind));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__MsgBox_ShowAsync(char* message, char* title, double kind)
{
    auto&& __result = MsgBox_ShowAsync(message, title, static_cast<std::int32_t>(kind));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__MsgBox_TaskStatus(double task_id)
{
    auto&& __result = MsgBox_TaskStatus(static_cast<std::int32_t>(task_id));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__MsgBox_TaskResult(double task_id)
{
    auto&& __result = MsgBox_TaskResult(static_cast<std::int32_t>(task_id));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__MsgBox_TaskRelease(double task_id)
{
    auto&& __result = MsgBox_TaskRelease(static_cast<std::int32_t>(task_id));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__MsgBox_Info(char* message, char* title)
{
    auto&& __result = MsgBox_Info(message, title);
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__MsgBox_Warning(char* message, char* title)
{
    auto&& __result = MsgBox_Warning(message, title);
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__MsgBox_Error(char* message, char* title)
{
    auto&& __result = MsgBox_Error(message, title);
    return static_cast<double>(__result);
}

