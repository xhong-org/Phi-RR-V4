# I_RPEPrep

Windows-only native preprocess. The speed fitter still implements the old straight-line trapezoid. Playback no longer calls it: PhiEdit 1.7 integrates each speed layer with its easing (closed form for linear, 20-step Simpson otherwise) in `scripts/RPELinePrep/RPELinePrep.gml`.

The DLL entry points remain for the previous fit. Do not turn `RPE_LINE_PREP_NATIVE` back on until the native integral matches that script.

Disable without deleting the DLL:

```gml
#macro RPE_LINE_PREP_NATIVE false
```

GML fallback in `scripts/RPELinePrep/RPELinePrep.gml` is used when the macro is off, the OS is not Windows, or the DLL is missing.

## Build

```powershell
cmake -S native -B native/out -G "Visual Studio 17 2022" -A x64
cmake --build native/out --config Release
```

The DLL is written to `extensions/I_RPEPrep/I_RPEPrep.dll`.
