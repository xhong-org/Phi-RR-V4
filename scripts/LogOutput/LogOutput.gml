///@desc 日志使用的包名
///@returns {String} 应用包名
function LogPackageName() {
	return "com.xthx.pls";
}

///@desc 判断当前是不是安卓原生环境
///@returns {Bool} 系统为安卓时为真
function LogAndroidNative() {
	return os_type == os_android;
}

///@desc 判断日志是否走原生文件接口
///@returns {Bool} 安卓或可用的 HTML5 文件接口时为真
function LogNativeFiles() {
	return LogAndroidNative() || html5_files_available();
}

///@desc 把目录统一成以斜杠结尾的路径
///@param {String} _dir 原始目录
///@returns {String} 规范化后的目录，空目录仍为空
function LogNormalizeDir(_dir) {
	var dir = string_replace_all(string(_dir), "\\", "/");
	if (!string_length(dir)) then return "";
	// 缺结尾斜杠时补上，便于拼接文件名
	if (string_char_at(dir, string_length(dir)) != "/") then dir += "/";
	return dir;
}

///@desc 生成当前时间的日志时间戳
///@returns {String} 方括号包住的日期和时间
function LogStamp() {
	return $"[{current_year}.{current_month}.{current_day} - {current_hour}:{current_minute}:{current_second}]";
}

///@desc 确保日志目录存在
///@param {String} _dir 目标目录
///@returns {String} 可用目录，创建失败时为空串
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

	// 整段创建失败时，再按层级逐级补目录
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

///@desc 列出可尝试写入日志的目录
///@returns {Array} 候选目录
function LogCandidateDirs() {
	var dirs = [];
	// 安卓优先专用日志目录，其次外部和内部存储
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

///@desc 判断日志路径是否已经存在
///@param {String} _path 文件路径
///@returns {Bool} 文件存在时为真
function LogPathExists(_path) {
	if (LogNativeFiles()) then return chart_native_exists(_path);
	return file_exists(_path);
}

///@desc 新建日志文件并写入开头内容
///@param {String} _path 文件路径
///@param {String} _text 初始文本
///@returns {Bool} 写入成功时为真
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

///@desc 向已有日志追加一行
///@param {String} _path 文件路径
///@param {String} _text 要追加的文本
///@returns {Bool} 追加成功时为真
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

///@desc 取得本会话日志路径，没有则创建
///@returns {String} 日志文件路径，没有可写目录时为空串
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
		// 同一秒已有日志时递增后缀
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

///@desc 把消息写到调试输出，并按需要追加进会话日志
///@param {Any} str 要写的消息
///@param {Bool} isOutputFile 是否同时写入会话日志
///@returns {Undefined} 无
function LogOutputFile(str, isOutputFile = true) {
	var _message = string(str);
	show_debug_message(_message);
	if (!isOutputFile) then return;
	// GX 的虚拟文件系统会随着日志变长而越来越慢，因此不写文件。
	if (pls_is_gxgames()) then return;

	var path = LogGetPath();
	if (!string_length(path)) then return;
	LogAppendLine(path, $"{LogStamp()} {_message}\n");
}

///@desc 写上结束标记并清掉当前日志路径
///@returns {Undefined} 无
function LogUninit() {
	// 还没有日志路径时不做收尾
	if (!variable_global_exists("logFilePath")) then return;
	var path = variable_global_get("logFilePath");
	if (is_string(path) && string_length(path)) {
		LogAppendLine(path, $"{LogStamp()} Log ended\n");
	};
	variable_global_set("logFilePath", "");
}
