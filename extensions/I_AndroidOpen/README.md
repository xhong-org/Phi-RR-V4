# I_AndroidOpen

Android replacement for `get_open_filename`. Windows keeps the built-in dialog; this extension is only implemented in `AndroidSource/Java/IAndroidOpen.java`.

It opens `ACTION_OPEN_DOCUMENT`, copies the chosen `.zip` / `.pez` into `files/imports/`, and returns a real filesystem path that `I_Compression` can unzip.

Generated with `D:\GM-ExtensionGenerator\extgen.exe`.

```gml
if (i_android_open_pick("application/zip")) {
    // poll i_android_open_status() each Step
}
```

Statuses are in `scripts/I_AndroidOpenAPI/I_AndroidOpenAPI.gml`.
