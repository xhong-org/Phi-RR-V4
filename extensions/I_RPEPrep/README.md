# I_RPEPrep

Windows-only native preprocess for RPE judge-line speed events: split-fit in beat space, then BPM beat→second conversion and trapezoid floor.

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
