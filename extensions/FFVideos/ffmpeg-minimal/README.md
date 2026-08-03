# Minimal FFmpeg Build

The generic development package is about 121 MB for the DLLs needed by
`FFVideos`, and it was configured with GPL components. Do not redistribute that
package with a closed-source build.

The release layout uses an LGPL-only static FFmpeg build and links it into
`FFVideos.dll`. Run `configure-msvc.sh` from an MSYS2 shell launched after the
Visual Studio x64 developer environment has placed `cl.exe`, `lib.exe` and
`link.exe` on `PATH`. `nasm` and `make` must also be available.

Example:

```bash
./configure-msvc.sh /c/src/ffmpeg /c/build/ffvideos-ffmpeg
```

Then configure the extension with:

```powershell
cmake --preset win-x64-release `
  -DFFVIDEOS_FFMPEG_ROOT="C:/build/ffvideos-ffmpeg" `
  -DFFVIDEOS_FFMPEG_STATIC=ON
cmake --build --preset win-x64-release
```

The selected feature set contains local-file playback, common game-video
containers, H.264, HEVC, MPEG-4, VP8, VP9, AV1, MJPEG, Theora, VC-1/WMV and the
pixel conversion library. It intentionally excludes encoders, filters,
devices, network protocols, command-line programs and external GPL libraries.

Keep FFmpeg's LGPL notices and provide the required relinking/source offer for
the exact FFmpeg version distributed with the game.
