# I_Compression

Windows-only asynchronous ZIP extension for GameMaker. It keeps GameMaker UTF-8 paths intact, converts them to UTF-16 in native code, and runs the Windows inbox `tar.exe` process on a worker thread.

Extraction supplies `CP936` as the fallback charset for legacy ZIP entries that do not carry the UTF-8 filename flag. Explicitly flagged UTF-8 entries remain UTF-8.

## API

```gml
var extract_task = unicode_zip_extract_async(zip_path, output_dir, true, true);
var compress_task = unicode_zip_compress_async(source_dir, zip_path, false, true);
```

Arguments:

- `unicode_zip_extract_async(archive_path, output_directory, overwrite, clean_output)`
- `unicode_zip_compress_async(source_path, archive_path, include_root, overwrite)`
- Both start functions return a positive task ID, or `-1` on immediate failure.
- `clean_output=true` deletes and recreates the extraction directory on the worker thread.
- `include_root=false` stores the contents of a source directory, not the source directory itself.

Poll tasks once per Step event:

```gml
var status = unicode_zip_task_status(task_id);
if (status == UNICODE_ZIP_TASK_STATUS.SUCCEEDED) {
    unicode_zip_task_release(task_id);
} else if (status == UNICODE_ZIP_TASK_STATUS.FAILED) {
    show_debug_message(unicode_zip_task_error(task_id));
    unicode_zip_task_release(task_id);
}
```

Status values are declared in `scripts/I_CompressionAPI/I_CompressionAPI.gml`:

- `UNKNOWN = 0`
- `QUEUED = 1`
- `RUNNING = 2`
- `SUCCEEDED = 3`
- `FAILED = 4`
- `CANCELLED = 5`

Call `unicode_zip_task_cancel(task_id)` to request cancellation. Finished tasks must be released with `unicode_zip_task_release(task_id)`.

## Build

```powershell
extgen --config "config.json"
cmake --preset win-x64-release
cmake --build --preset win-x64-release
```

Run the commands from `extensions/I_Compression/generator`. On this machine, CMake is invoked through the installed Visual Studio CMake executable because `cmake` is not on `PATH`.
