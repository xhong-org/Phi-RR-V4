# Chart video rendering

The Windows build supports deterministic chart-to-MP4 rendering through the
`VideoRenderer` extension. The selected chart package may be a ZIP/PEZ archive,
a chart directory, or an individual supported chart file.

```powershell
.\pcr.exe -render "D:\Charts\MyChart.zip" -output "D:\Videos\MyChart.mp4"

# An already extracted chart directory is accepted directly.
.\pcr.exe -render "D:\Charts\MyChart" -output "D:\Videos\MyChart.mp4"
```

Optional arguments:

```text
-fps <1..240>          Output frame rate (default: 60)
-resolution <label>    Output size: native, 720p, 1080p, 2k, or 4k
-res <label>           Short alias for -resolution
-ar <width:height>     Output aspect ratio (default: 16:9)
-crf <0..51>           H.264 quality; lower is better/larger (default: 18)
-preset <name>         H.264 speed/compression preset (default: medium)
-encoder <name>        auto, nvenc, amf, qsv, or x264 (default: auto)
-ffmpeg <path>         FFmpeg executable (default: ffmpeg.exe from PATH)
-render-seed <number>  Deterministic effect random seed (default: 0)
-settlement [on|off]   Record the settlement screen after the chart (default: off)
```

`-settlement` records the play-end animation and results screen after the
chart. After every settlement easing finishes, three extra seconds are written
and encoding stops. The matching `resource/ending/endingN.wav` loop is mixed
into the output from the settlement start (chart end + 2s). Omit the flag, or
pass `off`/`false`/`0`, to keep the original chart-only tail.

The renderer writes H.264 video and AAC chart music to an MP4 file. Default
Tap/Drag/Flick sounds and RPE custom hit sounds are mixed into the final audio
at 70% volume after video encoding. FFmpeg must be installed and contain the
`libx264` and AAC encoders. Existing output files are overwritten.

`auto` selects the hardware encoder matching the active D3D11 adapter: NVIDIA
NVENC, AMD AMF, or Intel Quick Sync. If the selected encoder cannot initialize,
the renderer logs the failure and falls back to `libx264`.

On NVIDIA adapters the native extension first attempts direct D3D11 NVENC. The
resolved render texture is registered with `nvEncodeAPI64.dll` and encoded
without GPU-to-CPU frame readback or an RGBA pipe. FFmpeg then copies the H.264
stream into MP4 and adds audio without re-encoding the video. If direct resource
registration is unsupported by the driver or texture format, rendering falls
back to external `h264_nvenc`, then to `libx264` if NVENC itself is unavailable.

On AMD adapters the native extension dynamically loads the driver-provided
`amfrt64.dll` and initializes AMF on GameMaker's existing D3D11 device. The
active BGRA/RGBA render target is resolved or copied on the GPU, converted to
NV12 by the AMF Video Converter in D3D11 memory, and submitted directly to
`AMFVideoEncoderVCE_AVC`. This converter stage is used for RX 590 compatibility
as well as newer AMD adapters. The encoder uses H.264 constant-QP quality from
`-crf`, maps `-preset` to AMF speed/balanced/quality modes, and disables B
frames. AMF writes a temporary Annex-B H.264 stream; FFmpeg copy-muxes it with
chart audio before the existing hit-sound mix. If direct AMF initialization
fails, the renderer logs the AMF reason and falls back to external `h264_amf`,
then to `libx264` if that encoder is unavailable. AMF is loaded only at runtime,
so `VideoRenderer.dll` has no static AMF DLL dependency.

During rendering the window shows only a progress panel. The chart playback
screen is hidden, and no music or hit sounds are played through the local audio
device. The chart music is read directly by FFmpeg and written only to the
output file. Hit-sound events are recorded as a small time/path list. Each unique
sound is decoded once, then a sparse temporary PCM track is generated in small
streaming blocks and mixed with the music. This does not record local playback
or retain a full PCM track in memory. Render mode also forces the highest
GameMaker anti-aliasing level, 8x MSAA, regardless of the interactive
configuration.

Hit-sound events are precomputed from the parsed Official, RPE, or PEC note data
before encoding starts. This keeps the audio deterministic even when a note is
dormant, culled, or skips a runtime autoplay judgment branch. Runtime judgment
reporting remains available only as a fallback for note types that were not
precomputed. The renderer logs the submitted and expected event counts when the
encoder starts.

The six built-in note sprites are stored in the on-demand `DefaultNotes` texture
group. It is loaded before entering a play room and unloaded when that room is
cleaned up. Interactive play similarly loads the `audiogroup_hitsounds` audio
group and unloads it on exit. Render mode skips that audio group because final
hit sounds come from the included `render_sfx` WAV files, while still loading the
note texture group required to draw frames.

Video frames are captured directly from the active D3D11 render target by the
native extension. The native BGRA/RGBA layout is passed directly to FFmpeg,
frame data is written in large batches, and two staging textures overlap GPU
readback with the next rendered frame. The renderer does not keep a full RGBA
frame in a GML buffer or retain the complete video in memory.
For RPE charts, capture is dispatched after local, global, built-in, and
external HLSL shader passes have been flushed to the final render target.

Common quality examples:

```powershell
# High quality, slower encoding
.\pcr.exe -render "D:\Charts\MyChart.zip" -output "D:\Videos\HQ.mp4" -crf 14 -preset slow

# Smaller file, faster encoding
.\pcr.exe -render "D:\Charts\MyChart.zip" -output "D:\Videos\Small.mp4" -crf 24 -preset veryfast
```

Supported presets are `ultrafast`, `superfast`, `veryfast`, `faster`, `fast`,
`medium`, `slow`, `slower`, and `veryslow`.

Resolution labels select the output height. The width is calculated from `-ar`
and rounded to the nearest even number for H.264 encoder compatibility. The
default aspect ratio is `16:9`, so omitting `-ar` preserves the original output
sizes. `-ar` accepts any positive numeric `width:height` pair, such as `4:3`,
`1:1`, `9:16`, or `21:9`. Invalid values produce a warning and fall back to
`16:9`. The order of `-ar` and `-resolution`/`-res` does not affect the result.

Resolution labels at the default `16:9` ratio:

```text
native   1366x768
720p     1280x720
1080p    1920x1080
2k       2560x1440 (1440p is also accepted)
4k       3840x2160 (2160p is also accepted)
```

Common `1080p` aspect-ratio outputs:

```text
16:9     1920x1080
4:3      1440x1080
1:1      1080x1080
9:16      608x1080 (rounded from 607.5 to an even width)
21:9     2520x1080
```

The interactive render settings screen provides `16:9`, `4:3`, `1:1`, and
`9:16` presets. Click the Size value to cycle through them. Command-line
rendering is not limited to these presets.

Example:

```powershell
.\pcr.exe -render "D:\Charts\MyChart.zip" -output "D:\Videos\MyChart-4K.mp4" -resolution 4k -fps 60 -crf 18 -preset slow

# Vertical 1080p render (608x1080)
.\pcr.exe -render "D:\Charts\MyChart.zip" -output "D:\Videos\MyChart-Vertical.mp4" -res 1080p -ar 9:16
```
