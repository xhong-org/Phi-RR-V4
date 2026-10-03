function LogPackageName() {
	return "com.xthx.pls";
}

function LogAndroidNative() {
	return os_type == os_android;
}

function LogNativeFiles() {
	return LogAndroidNative() || html5_files_available();
}

function LogNormalizeDir(_dir) {
	var dir = string_replace_all(string(_dir), "\\", "/");
	if (!string_length(dir)) then return "";
	if (string_char_at(dir, string_length(dir)) != "/") then dir += "/";
	return dir;
}

function LogStamp() {
	return $"[{current_year}.{current_month}.{current_day} - {current_hour}:{current_minute}:{current_second}]";
}

function LogEnsureDir(_dir) {
	var dir = LogNormalizeDir(_dir);
	if (!string_length(dir)) then return "";
	if (LogNativeFiles()) {
		if (chart_native_mkdir(dir)) then return dir;
		show_debug_message($"[Log] Native mkdir failed: {dir} {chart_native_error()}");
		return "";
	};

	if (directory_exists(dir)) then return dir;
	directory_create(dir);
	if (directory_exists(dir)) then return dir;

	var built = (string_char_at(dir, 1) == "/") ? "/" : "";
	var parts = string_split(dir, "/");
	for (var part_i = 0; part_i < array_length(parts); part_i++) {
		var part = parts[part_i];
		if (!string_length(part)) then continue;
		built += part + "/";
		if (!directory_exists(built)) then directory_create(built);
	};
	if (directory_exists(dir)) then return dir;
	return "";
}

function LogCandidateDirs() {
	var dirs = [];
	if (LogAndroidNative()) {
		var logs = i_android_files_logs_dir();
		if (string_length(logs)) then array_add(dirs, LogNormalizeDir(logs));
		var external = i_android_files_external_dir();
		if (string_length(external)) then array_add(dirs, LogNormalizeDir(external) + "logs/");
		var internal = i_android_files_internal_dir();
		if (string_length(internal)) then array_add(dirs, LogNormalizeDir(internal) + "logs/");
		return dirs;
	};
	array_add(dirs, game_save_id + "logs/");
	array_add(dirs, working_directory + "logs/");
	return dirs;
}

function LogPathExists(_path) {
	if (LogNativeFiles()) then return chart_native_exists(_path);
	return file_exists(_path);
}

function LogWriteNew(_path, _text) {
	if (LogNativeFiles()) {
		if (chart_native_write_text(_path, _text)) then return true;
		show_debug_message($"[Log] Native write failed: {_path} {chart_native_error()}");
		return false;
	};
	try {
		var handle = file_text_open_write(_path);
		if (is_undefined(handle) || handle < 0) {
			show_debug_message($"[Log] Open write failed: {_path}");
			return false;
		};
		file_text_write_string(handle, _text);
		file_text_close(handle);
		return file_exists(_path);
	} catch (error) {
		show_debug_message($"[Log] Failed to create {_path}: {error.message}");
		return false;
	};
}

function LogAppendLine(_path, _text) {
	if (LogNativeFiles()) {
		if (chart_native_append_text(_path, _text)) then return true;
		show_debug_message($"[Log] Native append failed: {_path} {chart_native_error()}");
		return false;
	};
	try {
		var handle = file_text_open_append(_path);
		if (is_undefined(handle) || handle < 0) {
			show_debug_message($"[Log] Open append failed: {_path}");
			return false;
		};
		file_text_write_string(handle, _text);
		file_text_close(handle);
		return true;
	} catch (error) {
		show_debug_message($"[Log] Failed to append {_path}: {error.message}");
		return false;
	};
}

function LogGetPath() {
	if (variable_global_exists("logFilePath")) {
		var current_path = variable_global_get("logFilePath");
		if (is_string(current_path) && string_length(current_path)) then return current_path;
	};

	if (LogAndroidNative() && !variable_global_exists("logAndroidProbed")) {
		variable_global_set("logAndroidProbed", true);
		show_debug_message($"[Log] external={i_android_files_external_dir()}");
		show_debug_message($"[Log] internal={i_android_files_internal_dir()}");
		show_debug_message($"[Log] logs={i_android_files_logs_dir()} err={i_android_files_error()}");
		show_debug_message($"[Log] game_save_id={game_save_id} working_directory={working_directory}");
	};

	var directories = LogCandidateDirs();
	for (var directory_index = 0; directory_index < array_length(directories); directory_index++) {
		var log_dir = LogEnsureDir(directories[directory_index]);
		if (!string_length(log_dir)) {
			show_debug_message($"[Log] Directory missing: {directories[directory_index]}");
			continue;
		};

		var prefix = $"{current_year}-{current_month}-{current_day}-{current_hour}-{current_minute}-{current_second}";
		var suffix = 0;
		var path = $"{log_dir}{prefix}-{suffix}.log";
		while (LogPathExists(path)) {
			suffix++;
			path = $"{log_dir}{prefix}-{suffix}.log";
		};

		var header = $"{LogStamp()} Log started\n";
		if (LogAndroidNative()) {
			header += $"{LogStamp()} logs_dir={i_android_files_logs_dir()}\n";
			header += $"{LogStamp()} external_dir={i_android_files_external_dir()}\n";
			header += $"{LogStamp()} internal_dir={i_android_files_internal_dir()}\n";
		};
		if (!LogWriteNew(path, header)) then continue;
		if (!LogPathExists(path)) {
			show_debug_message($"[Log] Write did not create: {path}");
			continue;
		};
		variable_global_set("logFilePath", path);
		show_debug_message($"[Log] File: {path}");
		return path;
	};

	show_debug_message("[Log] No writable log directory");
	return "";
}

/// @param str Message to write.
/// @param isOutputFile Write to the session log as well as the debug console.
function LogOutputFile(str, isOutputFile = true) {
	var _message = string(str);
	show_debug_message(_message);
	if (!isOutputFile) then return;
	// GX IDBFS appends stall more the longer the session log grows.
	if (pls_is_gxgames()) then return;

	var path = LogGetPath();
	if (!string_length(path)) then return;
	LogAppendLine(path, $"{LogStamp()} {_message}\n");
}

function LogUninit() {
	if (!variable_global_exists("logFilePath")) then return;
	var path = variable_global_get("logFilePath");
	if (is_string(path) && string_length(path)) {
		LogAppendLine(path, $"{LogStamp()} Log ended\n");
	};
	variable_global_set("logFilePath", "");
}
