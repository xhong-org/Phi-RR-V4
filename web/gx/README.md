# GX.Games and GitHub Pages

The static release is built from a **remote Opera GX YYC package** with the
GameMaker-pinned emsdk 3.1.47. Local GX runner exports are rejected because they
do not contain the project's Emscripten `.wasm` and `.data` files.

On Windows, install and activate emsdk 3.1.47 under `.build/gx-emsdk`, then run
from the repository root:

```powershell
node web/gx/build.mjs
```

The output is `.build/gx-pages`. To choose another installed SDK or output
directory, pass them as the first and second arguments. The script uses the
existing global gm-cli and cached GameMaker runtime; it does not run Git.

The prepared output can be overlaid onto the GitHub Pages repository root. Keep
that repository's `.git`, `CNAME`, license and unrelated files. Publish the
compiled `.wasm`, `.data`, `.js`, the generated `index.html`, and runtime support
files together. The `gx-build.json` manifest identifies the remote YYC build
and records SHA-256 hashes.

On mobile, the page requests document fullscreen at startup. Browsers can deny
fullscreen without a user gesture; in that case the game remains paused behind
a tap-to-enter prompt. A file picker may exit fullscreen, so the game, audio,
and video suspend and the page presents a tap-to-restore prompt when necessary.
Browsers that do not offer the Fullscreen API cannot be forced into fullscreen.
Desktop users get an optional fullscreen button.

The canvas backing resolution follows its displayed size and device pixel
ratio, including fullscreen and window resizing. Keyboard A–Z and multiple
touch contacts are sampled together on GX. They share the same judgement
queue, and a Hold can continue across keyboard and touch input. Changing focus,
opening a file picker, and leaving mobile fullscreen clear queued input.

On every platform, packages declaring `unlockVideo` first undergo chart format
and source data validation, then checks for the declared chart, music,
illustration and video files. Invalid packages never open the video. Successful
packages play the video before the full chart reader and gameplay resources
load. Browser video playback retains audio; a browser requiring activation
presents a play button. Other chart videos remain muted.

`sync-bridges.mjs` keeps the extension's embedded video fallback and Included
Files synchronized before packaging, so their playback and lifecycle APIs agree.

Validation is Windows-only. The remote package was exercised in Windows Edge
with mobile fullscreen emulation, imported chart and skin fixtures, and WebGL
shader tests. Emulation does not replace testing on physical mobile devices or
inside the GX.games host.
