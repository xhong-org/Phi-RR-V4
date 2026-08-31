# I_AndroidFiles

Android filesystem helper. GameMaker `directory_create` / `file_text_*` go through the runner sandbox and often never create `/storage/emulated/0/Android/data/<package>/files/`. This extension uses `Context.getExternalFilesDir` / `getFilesDir` and Java `File` APIs instead.

Windows keeps the built-in GML file functions. Call these only on `os_android`.

Generated with `D:\GM-ExtensionGenerator\extgen.exe`. Implementation: `AndroidSource/Java/IAndroidFiles.java`.

```gml
var logs = i_android_files_logs_dir(); // .../Android/data/com.xthx.pls/files/logs/
i_android_files_mkdir(logs);
i_android_files_write_text(logs + "note.txt", "hello");
i_android_files_append_text(logs + "note.txt", "\nworld");
var text = i_android_files_read_text(logs + "note.txt");
i_android_files_copy(logs + "note.txt", logs + "note.bak");
i_android_files_delete(logs + "note.bak");

android_files_write_buffer(logs + "raw.bin", buf);
android_files_append_buffer(logs + "raw.bin", buf, 0, 16);
var loaded = android_files_read_buffer(logs + "raw.bin");
android_files_read_buffer_into(logs + "raw.bin", dest_buf);
```

Java cannot take `buffer_get_address`. Buffer helpers encode through Base64 (32MB cap). Large files should use `i_android_files_copy`.

`i_android_files_error()` returns the last native error string.
