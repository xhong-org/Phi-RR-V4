// ##### extgen :: Auto-generated file do not edit!! #####

#pragma once
#include "core/GMExtUtils.h"

GMEXPORT double __EXT_NATIVE__MsgBox_Initialize();
GMEXPORT double __EXT_NATIVE__MsgBox_Shutdown();
GMEXPORT double __EXT_NATIVE__MsgBox_ClearButtons();
GMEXPORT double __EXT_NATIVE__MsgBox_SetButton(double index, char* text);
GMEXPORT double __EXT_NATIVE__MsgBox_SetButtonAlignment(double alignment);
GMEXPORT double __EXT_NATIVE__MsgBox_ShowSync(char* message, char* title, double kind);
GMEXPORT double __EXT_NATIVE__MsgBox_ShowAsync(char* message, char* title, double kind);
GMEXPORT double __EXT_NATIVE__MsgBox_TaskStatus(double task_id);
GMEXPORT double __EXT_NATIVE__MsgBox_TaskResult(double task_id);
GMEXPORT double __EXT_NATIVE__MsgBox_TaskRelease(double task_id);
GMEXPORT double __EXT_NATIVE__MsgBox_Info(char* message, char* title);
GMEXPORT double __EXT_NATIVE__MsgBox_Warning(char* message, char* title);
GMEXPORT double __EXT_NATIVE__MsgBox_Error(char* message, char* title);

