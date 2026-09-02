# I_GXGames (formerly I_HTML5)

HTML5 was retired. This project now targets **GX.games** (`os_gxgames`).

GX.games is not the HTML5 JavaScript runner, so `I_HTML5.js` is not shipped. Compatibility is GML:

- ZIP extract: built-in `zip_unzip`
- Files: GameMaker sandbox (`working_directory` / `game_save_id`)
- Audio: `audio_create_stream` (FMOD is Windows/Android only)
- Dialogs: `show_message` / `show_message_async` (async dialogs block on GX.games)
- Chart picker: Windows-style `get_open_filename` on GX.games

Native DLLs (`I_Compression`, `FMOD`, `MsgBox`, `I_Shaders`, `I_Pulse`, `I_Parallel`, `FFVideos`) stay Windows/Android.

Build with Opera GX / GX.games export, or:

```powershell
gm-cli compile "PhigrosLoader-sample.yyp" --target=operagx --runtime=vm
```
