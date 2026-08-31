/// @desc I_Compression task statuses returned by unicode_zip_task_status().
enum UNICODE_ZIP_TASK_STATUS {
        UNKNOWN = 0,
        QUEUED = 1,
        RUNNING = 2,
        SUCCEEDED = 3,
        FAILED = 4,
        CANCELLED = 5
};

function unicode_zip_backend_android() {
        return (os_type == os_android);
}

function unicode_zip_wire_string(buf, text) {
        var value = is_string(text) ? text : string(text);
        buffer_write(buf, buffer_u32, string_byte_length(value));
        buffer_write(buf, buffer_string, value);
}

function unicode_zip_wire_bool(buf, value) {
        buffer_write(buf, buffer_u8, value ? 1 : 0);
}

function unicode_zip_wire_call(android_fn, windows_fn, pack) {
        var buf = __ext_core_get_args_buffer();
        pack(buf);
        var address = buffer_get_address(buf);
        var length = buffer_tell(buf);
        if (unicode_zip_backend_android()) then return android_fn(address, length);
        return windows_fn(address, length);
}

function unicode_zip_backend_available() {
        if (unicode_zip_backend_android()) then return unicode_zip_android_available();
        return unicode_zip_available();
}

function unicode_zip_backend_detect(archive_path) {
        if (unicode_zip_backend_android()) then return unicode_zip_android_detect(archive_path);
        return unicode_zip_detect(archive_path);
}

function unicode_zip_backend_extract(archive_path, output_directory, overwrite, clean_output, password = "") {
        if (!string_length(password)) {
                if (unicode_zip_backend_android()) {
                        return unicode_zip_android_extract(archive_path, output_directory, overwrite, clean_output);
                };
                return unicode_zip_extract(archive_path, output_directory, overwrite, clean_output);
        };
        return unicode_zip_wire_call(__unicode_zip_android_extract_password, __unicode_zip_extract_password,
                method({ archive_path, output_directory, overwrite, clean_output, password }, function(buf) {
                        unicode_zip_wire_string(buf, archive_path);
                        unicode_zip_wire_string(buf, output_directory);
                        unicode_zip_wire_bool(buf, overwrite);
                        unicode_zip_wire_bool(buf, clean_output);
                        unicode_zip_wire_string(buf, password);
                }));
}

function unicode_zip_backend_compress(source_path, archive_path, include_root, overwrite, password = "", format = "zip") {
        if (!string_length(password) && (format == "zip" || format == "")) {
                if (unicode_zip_backend_android()) {
                        return unicode_zip_android_compress(source_path, archive_path, include_root, overwrite);
                };
                return unicode_zip_compress(source_path, archive_path, include_root, overwrite);
        };
        return unicode_zip_wire_call(__unicode_zip_android_compress_format, __unicode_zip_compress_format,
                method({ source_path, archive_path, include_root, overwrite, password, format }, function(buf) {
                        unicode_zip_wire_string(buf, source_path);
                        unicode_zip_wire_string(buf, archive_path);
                        unicode_zip_wire_bool(buf, include_root);
                        unicode_zip_wire_bool(buf, overwrite);
                        unicode_zip_wire_string(buf, password);
                        unicode_zip_wire_string(buf, format);
                }));
}

function unicode_zip_backend_extract_async(archive_path, output_directory, overwrite, clean_output, password = "") {
        if (!string_length(password)) {
                if (unicode_zip_backend_android()) {
                        return unicode_zip_android_extract_async(archive_path, output_directory, overwrite, clean_output);
                };
                return unicode_zip_extract_async(archive_path, output_directory, overwrite, clean_output);
        };
        return unicode_zip_wire_call(__unicode_zip_android_extract_async_password, __unicode_zip_extract_async_password,
                method({ archive_path, output_directory, overwrite, clean_output, password }, function(buf) {
                        unicode_zip_wire_string(buf, archive_path);
                        unicode_zip_wire_string(buf, output_directory);
                        unicode_zip_wire_bool(buf, overwrite);
                        unicode_zip_wire_bool(buf, clean_output);
                        unicode_zip_wire_string(buf, password);
                }));
}

function unicode_zip_backend_compress_async(source_path, archive_path, include_root, overwrite, password = "", format = "zip") {
        if (!string_length(password) && (format == "zip" || format == "")) {
                if (unicode_zip_backend_android()) {
                        return unicode_zip_android_compress_async(source_path, archive_path, include_root, overwrite);
                };
                return unicode_zip_compress_async(source_path, archive_path, include_root, overwrite);
        };
        return unicode_zip_wire_call(__unicode_zip_android_compress_async_format, __unicode_zip_compress_async_format,
                method({ source_path, archive_path, include_root, overwrite, password, format }, function(buf) {
                        unicode_zip_wire_string(buf, source_path);
                        unicode_zip_wire_string(buf, archive_path);
                        unicode_zip_wire_bool(buf, include_root);
                        unicode_zip_wire_bool(buf, overwrite);
                        unicode_zip_wire_string(buf, password);
                        unicode_zip_wire_string(buf, format);
                }));
}

function unicode_zip_backend_task_status(task_id) {
        if (unicode_zip_backend_android()) then return unicode_zip_android_task_status(task_id);
        return unicode_zip_task_status(task_id);
}

function unicode_zip_backend_task_exit_code(task_id) {
        if (unicode_zip_backend_android()) then return unicode_zip_android_task_exit_code(task_id);
        return unicode_zip_task_exit_code(task_id);
}

function unicode_zip_backend_task_error(task_id) {
        if (unicode_zip_backend_android()) then return unicode_zip_android_task_error(task_id);
        return unicode_zip_task_error(task_id);
}

function unicode_zip_backend_task_cancel(task_id) {
        if (unicode_zip_backend_android()) then return unicode_zip_android_task_cancel(task_id);
        return unicode_zip_task_cancel(task_id);
}

function unicode_zip_backend_task_release(task_id) {
        if (unicode_zip_backend_android()) then return unicode_zip_android_task_release(task_id);
        return unicode_zip_task_release(task_id);
}

function unicode_zip_backend_last_error() {
        if (unicode_zip_backend_android()) then return unicode_zip_android_last_error();
        return unicode_zip_last_error();
}

function unicode_zip_task_pending(task_id) {
        var status = unicode_zip_backend_task_status(task_id);
        return (status == UNICODE_ZIP_TASK_STATUS.QUEUED || status == UNICODE_ZIP_TASK_STATUS.RUNNING);
}

function unicode_zip_task_finished(task_id) {
        var status = unicode_zip_backend_task_status(task_id);
        return (status == UNICODE_ZIP_TASK_STATUS.SUCCEEDED
                || status == UNICODE_ZIP_TASK_STATUS.FAILED
                || status == UNICODE_ZIP_TASK_STATUS.CANCELLED);
}

function chart_archive_size_bytes(path) {
        if (os_type == os_android && android_files_available()) {
                var native_size = android_files_size(path);
                if (native_size >= 0) then return native_size;
        };
        if (!file_exists(path)) then return -1;
        var bin = file_bin_open(path, 0);
        if (bin < 0) then return -1;
        var bytes = file_bin_size(bin);
        file_bin_close(bin);
        return bytes;
}

function chart_path_exists_any(path) {
        if (file_exists(path) || directory_exists(path)) then return true;
        if (os_type == os_android && android_files_available()) {
                return android_files_exists(path) || android_files_is_dir(path);
        };
        return false;
}

function chart_session_zip_debug(tag, extra = "") {
        var session = chart_session_ensure();
        var archive = string(session.source_path);
        var output = string(session.extract_dir);
        var last_error = unicode_zip_backend_last_error();
        var size = chart_archive_size_bytes(archive);
        var kind = "";
        if (string_length(archive) && unicode_zip_backend_available()) {
                kind = unicode_zip_backend_detect(archive);
        };
        print($"[ChartSession][Unzip][{tag}] archive={archive}");
        print($"[ChartSession][Unzip][{tag}] filename={chart_path_file_name(archive)} size={size} kind={kind}");
        print($"[ChartSession][Unzip][{tag}] output={output} output_exists={chart_path_exists_any(output)}");
        print($"[ChartSession][Unzip][{tag}] gm_exists={file_exists(archive)} native_available={unicode_zip_backend_available()} os={os_type}");
        if (os_type == os_android && android_files_available()) {
                print($"[ChartSession][Unzip][{tag}] native_exists={android_files_exists(archive)} native_is_dir={android_files_is_dir(output)}");
                print($"[ChartSession][Unzip][{tag}] external={android_files_external_dir()} internal={android_files_internal_dir()}");
        };
        print($"[ChartSession][Unzip][{tag}] game_save_id={game_save_id} working_directory={working_directory}");
        if (string_length(last_error)) then print($"[ChartSession][Unzip][{tag}] last_error={last_error}");
        if (string_length(extra)) then print($"[ChartSession][Unzip][{tag}] {extra}");
}

function chart_session_zip_begin(zip_path) {
        var session = chart_session_ensure();
        session.ready = false;
        session.error = "";
        session.source_path = zip_path;
        session.from_zip = true;

        var track_path = chart_session_track_dir();
        session.extract_dir = track_path;
        chart_session_zip_debug("begin");

        if (!file_exists(zip_path) && !(os_type == os_android && android_files_available() && android_files_exists(zip_path))) {
                print($"[ChartSession][Unzip][begin] FAIL archive missing: {zip_path}");
                return chart_session_fail("Zip file does not exist.");
        };
        if (!unicode_zip_backend_available()) {
                print("[ChartSession][Unzip][begin] FAIL unicode backend unavailable");
                return chart_session_fail("Unicode ZIP backend is unavailable on this system.");
        };

        session.zip_task = unicode_zip_backend_extract_async(zip_path, track_path, true, true);
        if (session.zip_task < 0) {
                var start_error = unicode_zip_backend_last_error();
                if (!string_length(start_error)) then start_error = "Failed to start ZIP extraction.";
                print($"[ChartSession][Unzip][begin] FAIL start task={session.zip_task} error={start_error}");
                return chart_session_fail(start_error);
        };

        print($"[ChartSession][Unzip][begin] started task={session.zip_task}");
        chart_session_set_status("Unzipping", chart_path_file_name(zip_path));
        return true;
}

function chart_session_zip_finish(zip_path, track_path) {
        var root = chart_session_resolve_extract_root(track_path);
        print($"[ChartSession][Unzip][finish] using root={root}");
        return chart_session_build_from_dir(root, zip_path, true);
}

/// @returns 0 while pending, 1 when ready, -1 on failure.
function chart_session_zip_poll() {
        var session = chart_session_ensure();
        if (!variable_struct_exists(session, "zip_task") || session.zip_task < 0) {
                return session.ready ? 1 : -1;
        };

        var task_id = session.zip_task;
        var status = unicode_zip_backend_task_status(task_id);
        if (status == UNICODE_ZIP_TASK_STATUS.QUEUED || status == UNICODE_ZIP_TASK_STATUS.RUNNING) {
                return 0;
        };
        if (status == UNICODE_ZIP_TASK_STATUS.SUCCEEDED) {
                var ok_error = unicode_zip_backend_task_error(task_id);
                unicode_zip_backend_task_release(task_id);
                session.zip_task = -1;
                chart_session_zip_debug("success", $"task={task_id} task_error={ok_error}");
                print("[ChartSession][Unzip][success] extract reported OK");
                return chart_session_zip_finish(session.source_path, session.extract_dir) ? 1 : -1;
        };

        var task_error = unicode_zip_backend_task_error(task_id);
        var exit_code = unicode_zip_backend_task_exit_code(task_id);
        unicode_zip_backend_task_release(task_id);
        session.zip_task = -1;
        if (!string_length(task_error)) {
                task_error = (status == UNICODE_ZIP_TASK_STATUS.CANCELLED)
                        ? "ZIP extraction was cancelled."
                        : $"ZIP extraction failed (exit code {exit_code}).";
        };
        chart_session_zip_debug("fail", $"task={task_id} status={status} exit={exit_code} error={task_error}");
        session.ready = false;
        session.error = task_error;
        session.status = "Failed";
        session.detail = task_error;
        print($"[ChartSession][Error] {task_error}");
        return -1;
}
