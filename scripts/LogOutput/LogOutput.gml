function LogGetPath() {
	if (variable_global_exists("logFilePath")) {
		var current_path = variable_global_get("logFilePath");
		if (is_string(current_path) && string_length(current_path)) then return current_path;
	};

	var directories = [game_save_id + "Logs/", working_directory + "Logs/"];
	for (var directory_index = 0; directory_index < array_length(directories); directory_index++) {
		var log_dir = directories[directory_index];
		if (!directory_exists(log_dir)) then directory_create(log_dir);
		if (!directory_exists(log_dir)) then continue;

		var prefix = $"{current_year}-{current_month}-{current_day}-{current_hour}-{current_minute}-{current_second}";
		var suffix = 0;
		var path = $"{log_dir}{prefix}-{suffix}.log";
		while (file_exists(path)) {
			suffix++;
			path = $"{log_dir}{prefix}-{suffix}.log";
		};

		try {
			var handle = file_text_open_write(path);
			file_text_write_string(handle, $"[{current_year}.{current_month}.{current_day} - {current_hour}:{current_minute}:{current_second}] Log started");
			file_text_writeln(handle);
			file_text_close(handle);
			variable_global_set("logFilePath", path);
			show_debug_message($"[Log] File: {path}");
			return path;
		} catch (error) {
			show_debug_message($"[Log] Failed to create {path}: {error.message}");
		};
	};

	return "";
}

/// @param str Message to write.
/// @param isOutputFile Write to the session log as well as the debug console.
function LogOutputFile(str, isOutputFile = true) {
	var message = string(str);
	show_debug_message(message);
	if (!isOutputFile) then return;

	var path = LogGetPath();
	if (!string_length(path)) then return;
	try {
		var handle = file_text_open_append(path);
		file_text_write_string(handle,
			$"[{current_year}.{current_month}.{current_day} - {current_hour}:{current_minute}:{current_second}] {message}");
		file_text_writeln(handle);
		file_text_close(handle);
	} catch (error) {
		show_debug_message($"[Log] Failed to append {path}: {error.message}");
	};
}

function LogUninit() {
	if (!variable_global_exists("logFilePath")) then return;
	var path = variable_global_get("logFilePath");
	if (is_string(path) && string_length(path)) {
		try {
			var handle = file_text_open_append(path);
			file_text_write_string(handle,
				$"[{current_year}.{current_month}.{current_day} - {current_hour}:{current_minute}:{current_second}] Log ended");
			file_text_writeln(handle);
			file_text_close(handle);
		} catch (error) {
			show_debug_message($"[Log] Failed to close {path}: {error.message}");
		};
	};
	variable_global_set("logFilePath", "");
}
