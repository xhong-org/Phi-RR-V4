/// @desc I_Compression task statuses returned by unicode_zip_task_status().
enum UNICODE_ZIP_TASK_STATUS {
        UNKNOWN = 0,
        QUEUED = 1,
        RUNNING = 2,
        SUCCEEDED = 3,
        FAILED = 4,
        CANCELLED = 5
};

function unicode_zip_task_pending(task_id) {
        var status = unicode_zip_task_status(task_id);
        return (status == UNICODE_ZIP_TASK_STATUS.QUEUED || status == UNICODE_ZIP_TASK_STATUS.RUNNING);
}

function unicode_zip_task_finished(task_id) {
        var status = unicode_zip_task_status(task_id);
        return (status == UNICODE_ZIP_TASK_STATUS.SUCCEEDED
                || status == UNICODE_ZIP_TASK_STATUS.FAILED
                || status == UNICODE_ZIP_TASK_STATUS.CANCELLED);
}

function chart_session_zip_begin(zip_path) {
        var session = chart_session_ensure();
        session.ready = false;
        session.error = "";
        session.source_path = zip_path;
        session.from_zip = true;

        if (!file_exists(zip_path)) {
                return chart_session_fail("Zip file does not exist.");
        };
        if (!unicode_zip_available()) {
                return chart_session_fail("Unicode ZIP backend is unavailable on this Windows system.");
        };

        var track_path = chart_path_norm(game_save_id + "track/");
        session.extract_dir = track_path;
        session.zip_task = unicode_zip_extract_async(zip_path, track_path, true, true);
        if (session.zip_task < 0) {
                var start_error = unicode_zip_last_error();
                if (!string_length(start_error)) then start_error = "Failed to start ZIP extraction.";
                return chart_session_fail(start_error);
        };

        chart_session_set_status("Unzipping", chart_path_file_name(zip_path));
        return true;
}

function chart_session_zip_finish(zip_path, track_path) {
        var discovered_root = File_Discoverer(track_path);
        var root = track_path;
        if (array_length(discovered_root.chart) <= 0) {
                var probe = file_find_first(track_path + "*", fa_directory);
                var first_dir = "";
                while (string_length(probe)) {
                        if (probe != "." && probe != "..") {
                                var full = chart_path_join(track_path, probe);
                                if (directory_exists(full)) {
                                        first_dir = full;
                                        break;
                                };
                        };
                        probe = file_find_next();
                };
                file_find_close();
                if (string_length(first_dir)) {
                        var nested = File_Discoverer(first_dir);
                        if (array_length(nested.chart) > 0 || array_length(nested.music) > 0) {
                                root = first_dir;
                        };
                };
        };
        return chart_session_build_from_dir(root, zip_path, true);
}

/// @returns 0 while pending, 1 when ready, -1 on failure.
function chart_session_zip_poll() {
        var session = chart_session_ensure();
        if (!variable_struct_exists(session, "zip_task") || session.zip_task < 0) {
                return session.ready ? 1 : -1;
        };

        var task_id = session.zip_task;
        var status = unicode_zip_task_status(task_id);
        if (status == UNICODE_ZIP_TASK_STATUS.QUEUED || status == UNICODE_ZIP_TASK_STATUS.RUNNING) {
                return 0;
        };
        if (status == UNICODE_ZIP_TASK_STATUS.SUCCEEDED) {
                unicode_zip_task_release(task_id);
                session.zip_task = -1;
                return chart_session_zip_finish(session.source_path, session.extract_dir) ? 1 : -1;
        };

        var task_error = unicode_zip_task_error(task_id);
        var exit_code = unicode_zip_task_exit_code(task_id);
        unicode_zip_task_release(task_id);
        session.zip_task = -1;
        if (!string_length(task_error)) {
                task_error = (status == UNICODE_ZIP_TASK_STATUS.CANCELLED)
                        ? "ZIP extraction was cancelled."
                        : $"ZIP extraction failed (exit code {exit_code}).";
        };
        session.ready = false;
        session.error = task_error;
        session.status = "Failed";
        session.detail = task_error;
        print($"[ChartSession][Error] {task_error}");
        return -1;
}
