/// @desc Unicode Windows message box wrappers. Strings are packed as UTF-8.

enum MSGBOX_KIND { INFO = 1, WARNING = 2, ERROR = 3 };
enum MSGBOX_TASK_STATUS { UNKNOWN = 0, RUNNING = 1, DONE = 2 };
enum MSGBOX_BUTTON_ALIGN { LEFT = 1, CENTER = 2, RIGHT = 3 };

function i_wbox_native_ready() {
	return (os_type == os_windows) && extension_exists("I_WBOX");
}

function msgbox_gx_escape(_text) {
	var s = string(_text ?? "");
	s = string_replace_all(s, "\\", "\\\\");
	s = string_replace_all(s, "\t", "\\t");
	s = string_replace_all(s, "\r", "\\r");
	s = string_replace_all(s, "\n", "\\n");
	return s;
}

function msgbox_gx_cmd(_cmd) {
	return gx_file_ui_cmd(_cmd);
}

/// GX.games dialogs go through the existing I_HTML5 drop RPC (i_gx_drop_import).
function msgbox_gx_ready() {
	if (!pls_is_gxgames()) then return false;
	if (variable_global_exists("msgbox_gx_ok") && global.msgbox_gx_ok) then return true;
	global.msgbox_gx_ok = (msgbox_gx_cmd("pls-f:msgping") > 0);
	return global.msgbox_gx_ok;
}

/// Android and other non-Windows targets: no I_WBOX and no blocking show_message.
function msgbox_fallback_async(_message, _title) {
	var text = string(_title ?? "");
	if (string_length(text) && string_length(string(_message ?? ""))) then text += "\n\n";
	text += string(_message ?? "");
	return show_message_async(text);
}

function i_wbox_wire_string(buf, text) {
	var value = is_string(text) ? text : string(text);
	buffer_write(buf, buffer_u32, string_byte_length(value));
	buffer_write(buf, buffer_string, value);
}

function i_wbox_wire_call(fn, pack) {
	var buf = __ext_core_get_args_buffer();
	pack(buf);
	return fn(buffer_get_address(buf), buffer_tell(buf));
}

function i_wbox_set_button(index, text) {
	if (!i_wbox_native_ready()) then return false;
	return i_wbox_wire_call(__i_wbox_set_button, method({ index, text }, function(buf) {
		buffer_write(buf, buffer_u32, floor(real(index)));
		i_wbox_wire_string(buf, text);
	})) != 0;
}

function i_wbox_show_packed(_fn, _message, _title, _kind) {
	return i_wbox_wire_call(_fn, method({ _message, _title, _kind }, function(buf) {
		i_wbox_wire_string(buf, _message);
		i_wbox_wire_string(buf, _title);
		buffer_write(buf, buffer_u8, floor(real(_kind)));
	}));
}

function msgbox_button(text, callback = undefined) {
	return { text:string(text), callback:callback };
}

function msgbox_invoke_callback(callback, task_id, result) {
	if (is_undefined(callback)) then return;
	if (!is_callable(callback)) {
		show_debug_message("I_WBOX: button callback is not callable");
		return;
	};
	script_execute(callback, task_id, result);
}

function msgbox_configure_buttons(buttons, alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	if (i_wbox_native_ready()) {
		i_wbox_clear_buttons();
		i_wbox_set_button_alignment(alignment);
	} else if (msgbox_gx_ready()) {
		msgbox_gx_cmd("pls-f:msgclear");
		msgbox_gx_cmd("pls-f:msgalign\t" + string(alignment));
	};
	var callbacks = [undefined, undefined, undefined, undefined];
	if (!is_array(buttons)) then return callbacks;
	var count = min(4, array_length(buttons));
	var output_index = 0;
	for (var i = 0; i < count; i++) {
		var button = buttons[i];
		var text = is_struct(button) ? string(button.text ?? "") : string(button);
		if (!string_length(text)) then continue;
		if (i_wbox_native_ready()) then i_wbox_set_button(output_index + 1, text);
		else if (msgbox_gx_ready()) then msgbox_gx_cmd("pls-f:msgbtn\t" + string(output_index + 1) + "\t" + msgbox_gx_escape(text));
		if (is_struct(button)) then callbacks[output_index] = button.callback ?? undefined;
		output_index++;
	};
	return callbacks;
}

function msgbox_show_sync(_message, _title, _kind = MSGBOX_KIND.INFO, _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	if (!i_wbox_native_ready()) {
		return msgbox_show_async(_message, _title, _kind, _buttons, _alignment);
	};
	var callbacks = msgbox_configure_buttons(_buttons, _alignment);
	var result = i_wbox_show_packed(__i_wbox_show_sync, _message, _title, _kind);
	if (result >= 1 && result <= 4) then msgbox_invoke_callback(callbacks[result - 1], 0, result);
	return result;
}

function msgbox_schedule_poll(task_id) {
	var poll_state = { task_id:task_id };
	call_later(1, time_source_units_frames,
		method(poll_state, function() { msgbox_poll_async(self.task_id); }));
}

function msgbox_poll_async(task_id) {
	if (!variable_global_exists("msgbox_tasks") || !is_struct(global.msgbox_tasks)) then return;
	var key = string(task_id);
	if (!struct_exists(global.msgbox_tasks, key)) then return;
	var gx = msgbox_gx_ready();
	if (!i_wbox_native_ready() && !gx) {
		struct_remove(global.msgbox_tasks, key);
		return;
	};
	var status = gx ? msgbox_gx_cmd("pls-f:msgstatus\t" + string(task_id)) : i_wbox_task_status(task_id);
	if (status == MSGBOX_TASK_STATUS.UNKNOWN) {
		struct_remove(global.msgbox_tasks, key);
		return;
	};
	if (status != MSGBOX_TASK_STATUS.DONE) {
		msgbox_schedule_poll(task_id);
		return;
	};
	var task = global.msgbox_tasks[$ key];
	var result = gx ? msgbox_gx_cmd("pls-f:msgresult\t" + string(task_id)) : i_wbox_task_result(task_id);
	if (gx) then msgbox_gx_cmd("pls-f:msgrelease\t" + string(task_id));
	else i_wbox_task_release(task_id);
	struct_remove(global.msgbox_tasks, key);
	if (result < 1 || result > 4) then return;
	msgbox_invoke_callback(task.callbacks[result - 1], task_id, result);
}

function msgbox_show_async(_message, _title, _kind = MSGBOX_KIND.INFO, _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	var callbacks = msgbox_configure_buttons(_buttons, _alignment);
	var task_id = 0;
	if (i_wbox_native_ready()) {
		task_id = i_wbox_show_packed(__i_wbox_show_async, _message, _title, _kind);
	} else if (msgbox_gx_ready()) {
		task_id = msgbox_gx_cmd("pls-f:alert\t" + msgbox_gx_escape(_message) + "\t" + msgbox_gx_escape(_title) + "\t" + string(_kind));
	} else {
		msgbox_fallback_async(_message, _title);
		if (array_length(callbacks) > 0) then msgbox_invoke_callback(callbacks[0], 1, 1);
		return 1;
	};
	if (!(is_real(task_id) && task_id > 0)) {
		if (!i_wbox_native_ready()) {
			msgbox_fallback_async(_message, _title);
			if (array_length(callbacks) > 0) then msgbox_invoke_callback(callbacks[0], 1, 1);
			return 1;
		};
		return task_id;
	};
	if (!variable_global_exists("msgbox_tasks") || !is_struct(global.msgbox_tasks)) then global.msgbox_tasks = {};
	global.msgbox_tasks[$ string(task_id)] = { callbacks:callbacks };
	msgbox_schedule_poll(task_id);
	return task_id;
}

function msgbox_info_async(_message, _title = "Information", _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	return msgbox_show_async(_message, _title, MSGBOX_KIND.INFO, _buttons, _alignment);
}

function msgbox_info_sync(_message, _title = "Information", _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	if (!i_wbox_native_ready()) then return msgbox_info_async(_message, _title, _buttons, _alignment);
	return msgbox_show_sync(_message, _title, MSGBOX_KIND.INFO, _buttons, _alignment);
}

function msgbox_warning_async(_message, _title = "Warning", _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	return msgbox_show_async(_message, _title, MSGBOX_KIND.WARNING, _buttons, _alignment);
}

function msgbox_warning_sync(_message, _title = "Warning", _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	if (!i_wbox_native_ready()) then return msgbox_warning_async(_message, _title, _buttons, _alignment);
	return msgbox_show_sync(_message, _title, MSGBOX_KIND.WARNING, _buttons, _alignment);
}

function msgbox_error_async(_message, _title = "Error", _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	return msgbox_show_async(_message, _title, MSGBOX_KIND.ERROR, _buttons, _alignment);
}

function msgbox_error_sync(_message, _title = "Error", _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	if (!i_wbox_native_ready()) then return msgbox_error_async(_message, _title, _buttons, _alignment);
	return msgbox_show_sync(_message, _title, MSGBOX_KIND.ERROR, _buttons, _alignment);
}

function i_wbox_info(_message, _title = "Information") {
	if (!i_wbox_native_ready()) then return msgbox_info_async(_message, _title);
	return i_wbox_show_packed(__i_wbox_info, _message, _title, MSGBOX_KIND.INFO);
}

function i_wbox_warning(_message, _title = "Warning") {
	if (!i_wbox_native_ready()) then return msgbox_warning_async(_message, _title);
	return i_wbox_show_packed(__i_wbox_warning, _message, _title, MSGBOX_KIND.WARNING);
}

function i_wbox_error(_message, _title = "Error") {
	if (!i_wbox_native_ready()) then return msgbox_error_async(_message, _title);
	return i_wbox_show_packed(__i_wbox_error, _message, _title, MSGBOX_KIND.ERROR);
}

function MsgBox_ClearButtons() { return i_wbox_native_ready() ? i_wbox_clear_buttons() : 0; }
function MsgBox_SetButtonAlignment(alignment) { return i_wbox_native_ready() ? i_wbox_set_button_alignment(alignment) : 0; }
function MsgBox_SetButton(index, text) { return i_wbox_set_button(index, text); }
function MsgBox_ShowSync(message, title, kind) { return msgbox_show_sync(message, title, kind); }
function MsgBox_ShowAsync(message, title, kind) { return msgbox_show_async(message, title, kind); }
function MsgBox_TaskStatus(task_id) { return i_wbox_native_ready() ? i_wbox_task_status(task_id) : 0; }
function MsgBox_TaskResult(task_id) { return i_wbox_native_ready() ? i_wbox_task_result(task_id) : 0; }
function MsgBox_TaskRelease(task_id) { return i_wbox_native_ready() ? i_wbox_task_release(task_id) : 0; }
function MsgBox_Info(message, title) { return i_wbox_info(message, title); }
function MsgBox_Warning(message, title) { return i_wbox_warning(message, title); }
function MsgBox_Error(message, title) { return i_wbox_error(message, title); }
