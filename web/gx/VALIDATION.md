GX.Games build 50006 was rebuilt on Windows on 2026-11-12 using the remote
Opera GX YYC target, GameMaker 2026.0.0.23 and emsdk 3.1.47. The Windows and
Android build numbers remain 50005. The gameplay screenshot confirms the
compiled version label `[50006]`.

The final build passed these checks:

| Check | Result | Local evidence |
| --- | --- | --- |
| Remote release and source | Source signature matches the YYC build; release SHA-256 hashes match | `.build/gx-validation/release-50006.json` |
| Chart preflight in Edge | All eight valid, damaged, alternate-chart, empty-music and missing-file fixtures pass | `.build/gx-issues/preflight-results.json` |
| Chart preflight on Windows | The same eight fixtures pass; invalid packages never open video; valid video ends before the full reader starts | `.build/gx-issues/native-results.log` and `native-*.log.stdout` |
| Browser resolution | DPR 2 backing size matches CSS size before/after fullscreen and resize | `.build/gx-issues/display-results.json` |
| Mobile fullscreen recovery | Picker-induced fullscreen exit suspends play and offers a working recovery control | `.build/gx-issues/display-results.json` |
| Simultaneous input | Keyboard Tap/Drag, touch Hold/Flick, Hold handoff, two-finger chords and simultaneous keyboard/touch on one note produce seven Perfect judgements with no duplicate scoring | `.build/gx-issues/manual-hybrid.log` and `manual-result.png` |
| Browser settings and skin | Settings open; imported skin survives reload and loads in gameplay; mobile picker recovery remains available | `.build/gx-validation/runtime.log` and `runtime-logs.json` |
| Shader bridge | 47 samples each on WebGL 1 and WebGL 2 compile and draw with GPU state restored and no GL errors | `.build/gx-validation/results.json` |
| Bridge synchronization | Repeated synchronization preserves the shader bridge and matches Included Files | `node web/gx/test-bridges.mjs` |

The preceding fixes were also exercised with the user's original Designant,
Desultory Signals and Candy packages on Windows Edge using the Intel Iris Xe
renderer. Designant reaches the full RPE reader and plays its extra video;
Desultory plays its audible unlock video before chart loading; Candy's shader
pipeline completes thousands of capture/draw calls. Candy's later solid red
background was compared with the corresponding frame of its own background
video. Evidence is retained in `.build/gx-issues/*-final-logs.json`,
`*-final-probe.json`, screenshots, and the Desultory unlock probe logs.

These checks cover Windows native execution and Windows browser emulation.
They do not establish physical mobile-device or GX.games iframe compatibility.
The native probe also reports an existing unrelated TextProbe font measurement
mismatch; its chart preflight and video ordering assertions pass.

Pages publication was pushed to `xhongdev/xhongdev` main in commit
`74f5eb41f27a2cf7c15986d949ab0801ef3d5fc0`. All eight live release assets,
including WASM, JavaScript, data and the entry page, match the local manifest's
SHA-256 hashes. The existing local README edit was preserved outside the
release commit. Online verification is recorded in
`.build/gx-validation/live-50006/verification.json`.
