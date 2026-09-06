# I_WBOX

Unicode Windows message box. Replaces `MsgBox`.

Strings are packed as UTF-8 from GML (`string_byte_length` + `buffer_string`) and converted to UTF-16 in native code. Do not pass GameMaker `char*` strings into the DLL; those can arrive as the active Windows code page.

## Features

- Unicode titles, body text, and button labels
- Up to four custom buttons
- Left / center / right button alignment
- Sync (`msgbox_show_sync`) and async (`msgbox_show_async`) with task poll/release
- Info / warning / error icons
- Owner window, DPI scaling, word wrap, Escape to close, Ctrl+C to copy
- GX.games uses the I_HTML5 drop RPC (`pls-f:alert`) to show a DOM overlay (`I_GXDrop.js` / `gx_drop.js`)
- Android / other targets use `show_message_async` (no I_WBOX, no blocking `show_message`)

## GML

```gml
msgbox_warning_async("谱面加载失败", "Chart Loader", [ msgbox_button("确认") ], MSGBOX_BUTTON_ALIGN.RIGHT);

var result = msgbox_show_sync("覆盖存档？", "确认", MSGBOX_KIND.WARNING, [
    msgbox_button("是"),
    msgbox_button("否")
], MSGBOX_BUTTON_ALIGN.RIGHT);
```

Button results are 1-based indexes. Async callbacks receive `(task_id, result)`.

Old `MsgBox_*` names still forward to I_WBOX.

## Build

```powershell
cmake -S native -B native/out -G "Visual Studio 17 2022" -A x64
cmake --build native/out --config Release
```

The DLL is written to `extensions/I_WBOX/I_WBOX.dll`.
