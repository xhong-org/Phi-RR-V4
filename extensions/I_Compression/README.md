# I_Compression

Unicode-safe archive compression and extraction for GameMaker.

On Windows it keeps GameMaker UTF-8 paths intact, converts them to UTF-16 in native code, and runs the inbox `tar.exe` process on a worker thread. Extraction supplies `CP936` as the fallback charset for legacy ZIP entries that do not carry the UTF-8 filename flag.

On Android the same GML API is served by `I_Compression_android.cpp` through extgen JNI (`libICompression.so`) and **libarchive**. Format is detected from file headers, not suffixes. UTF-8 ZIP names stay UTF-8; names without the UTF-8 flag fall back through GBK/GB18030 so Chinese chart packages do not mojibake. Supported extract formats include ZIP, RAR, 7z, tar, tar.gz, tar.xz, gzip, xz, and bzip2. Compression can write ZIP, 7z, tar, tar.gz, and tar.xz. RAR is extract-only. Password is supported on Android for ZIP (AES-256 / ZipCrypto) and 7z.

Do not use GameMaker `zip_unzip` on Android; it mangles UTF-8 filenames.

## API

Use the backend wrappers so Windows and Android stay on the correct native file:

```gml
var kind = unicode_zip_backend_detect(archive_path); // "zip", "rar", "7z", "tar.gz", ...
unicode_zip_backend_extract(archive_path, output_dir, true, true);           // sync
unicode_zip_backend_extract(archive_path, output_dir, true, true, "secret"); // sync + password
var extract_task = unicode_zip_backend_extract_async(archive_path, output_dir, true, true);
var compress_task = unicode_zip_backend_compress_async(source_dir, zip_path, false, true, "", "zip");
unicode_zip_backend_compress(source_dir, out_path, false, true, "", "7z");
```

- Sync functions block the caller until the archive is finished.
- Async functions return a positive task ID, or `-1` on immediate failure.
- `clean_output=true` deletes and recreates the extraction directory.
- `include_root=false` stores the contents of a source directory, not the directory itself.
- Archives larger than 1 GiB fail before the output directory is changed.
- Compress `format`: `"zip"` (default), `"7z"`, `"tar"`, `"tar.gz"`, `"tar.xz"`.

Poll async tasks once per Step event:

```gml
var status = unicode_zip_backend_task_status(task_id);
if (status == UNICODE_ZIP_TASK_STATUS.SUCCEEDED) {
    unicode_zip_backend_task_release(task_id);
} else if (status == UNICODE_ZIP_TASK_STATUS.FAILED) {
    show_debug_message(unicode_zip_backend_task_error(task_id));
    unicode_zip_backend_task_release(task_id);
}
```

Status values are declared in `scripts/I_CompressionAPI/I_CompressionAPI.gml`.

## Build

```powershell
extgen --config "config.json"
cmake --preset win-x64-release
cmake --build --preset win-x64-release
$env:ANDROID_NDK_HOME = "<ndk>"
cmake --preset android-arm64-v8a-release
cmake --build --preset android-arm64-v8a-release
```

Run the commands from `extensions/I_Compression/generator`. The Android build fetches libarchive and xz (liblzma) on first configure.
