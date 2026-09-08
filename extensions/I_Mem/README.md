# I_Mem

Windows-only helper that returns unused pages in **this process** to the OS. GameMaker `sprite_delete` / `surface_free` / `font_delete` free runner objects, but the process working set in Task Manager often stays large until Windows is told to trim it.

This extension does **not** touch other processes and does **not** purge the system standby list.

## GML

```gml
process_mem_trim();
```

Called after chart / room cleanup. Safe no-op on Android and GX.games.

## Build

```powershell
cmake -S native -B native/out -G "Visual Studio 17 2022" -A x64
cmake --build native/out --config Release
```

The DLL is written to `extensions/I_Mem/I_Mem.dll`.
