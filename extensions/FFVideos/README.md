# FFVideos

`FFVideos.dll` is the Windows video backend for PhigrosLoader. It uses FFmpeg for
asynchronous demuxing, decoding and seeking, converts frames to NV12, then uploads
the Y and UV planes directly to D3D11. Frames never pass through GML buffers or
GameMaker surfaces.

## API

- `ffvideos_initialize(device, context)` initializes the FFmpeg/D3D11 backend.
- `ffvideos_open(path)` opens a local video and returns a player handle.
- `ffvideos_close(handle)` destroys one player.
- `ffvideos_play(handle)` and `ffvideos_pause(handle)` control playback.
- `ffvideos_seek(handle, position_ms)` seeks using milliseconds.
- `ffvideos_set_volume(handle, volume)` accepts a value from `0` to `1`.
- `ffvideos_set_loop(handle, enabled)` controls looping.
- `ffvideos_get_status(handle)` returns an `FFVideosStatus` value.
- `ffvideos_get_duration(handle)` and `ffvideos_get_position(handle)` return milliseconds.
- `ffvideos_get_width(handle)` and `ffvideos_get_height(handle)` return native dimensions.
- `ffvideos_draw(handle, left, top, right, bottom, alpha, dim)` draws to the active
  D3D11 render target. Coordinates are normalized against the current viewport.
- `ffvideos_get_error(handle)` returns the player error, or the initialization error
  when `handle` is invalid (conventionally `0`).
- `ffvideos_shutdown()` releases all native players and graphics resources.

## Status

- `FFVideosStatus.Error = -1`
- `FFVideosStatus.Closed = 0`
- `FFVideosStatus.Preparing = 1`
- `FFVideosStatus.Playing = 2`
- `FFVideosStatus.Paused = 3`
- `FFVideosStatus.Ended = 4`

## Build

Run from `extensions/FFVideos/generator`:

```powershell
extgen --config "config.json"
cmake --preset win-x64-release
cmake --build --preset win-x64-release
```

The build copies `FFVideos.dll` to `extensions/FFVideos`.

The development build uses `FFVIDEOS_FFMPEG_ROOT` and currently copies the shared
FFmpeg runtime DLLs beside `FFVideos.dll`. The installed general-purpose FFmpeg
package is GPL-enabled and is only suitable for local development.

The release build must use the minimal LGPL static FFmpeg configuration under
`ffmpeg-minimal/`, then link those static libraries into the single extension
DLL. The current playback path decodes video only; `ffvideos_set_volume` retains
the API value but audio output is intentionally disabled until the audio backend
is added.
