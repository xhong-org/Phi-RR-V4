// ##### extgen :: Auto-generated file do not edit!! #####

// #####################################################################
// # Macros
// #####################################################################

// #####################################################################
// # Enums
// #####################################################################

// #####################################################################
// # Constructors
// #####################################################################

// #####################################################################
// # Codecs
// #####################################################################

// #####################################################################
// # Functions
// #####################################################################

enum MSGBOX_KIND { INFO = 1, WARNING = 2, ERROR = 3 };
enum MSGBOX_TASK_STATUS { UNKNOWN = 0, RUNNING = 1, DONE = 2 };
enum MSGBOX_BUTTON_ALIGN { LEFT = 1, CENTER = 2, RIGHT = 3 };

function msgbox_button(text, callback = undefined) {
	return { text:string(text), callback:callback };
}

function msgbox_invoke_callback(callback, task_id, result) {
	if (is_undefined(callback)) then return;
	if (!is_callable(callback)) {
		show_debug_message("MsgBox: button callback is not callable");
		return;
	};
	script_execute(callback, task_id, result);
}

function msgbox_configure_buttons(buttons, alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	MsgBox_ClearButtons();
	MsgBox_SetButtonAlignment(alignment);
	var callbacks = [undefined, undefined, undefined, undefined];
	if (!is_array(buttons)) then return callbacks;
	var count = min(4, array_length(buttons));
	var output_index = 0;
	for (var i = 0; i < count; i++) {
		var button = buttons[i];
		var text = is_struct(button) ? string(button.text ?? "") : string(button);
		if (!string_length(text)) then continue;
		MsgBox_SetButton(output_index + 1, text);
		if (is_struct(button)) then callbacks[output_index] = button.callback ?? undefined;
		output_index++;
	};
	return callbacks;
}

function msgbox_show_sync(_message, _title, _kind = MSGBOX_KIND.INFO, _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	var callbacks = msgbox_configure_buttons(_buttons, _alignment);
	var result = MsgBox_ShowSync(string(_message), string(_title), _kind);
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
	var status = MsgBox_TaskStatus(task_id);
	if (status == MSGBOX_TASK_STATUS.UNKNOWN) {
		struct_remove(global.msgbox_tasks, key);
		return;
	};
	if (status != MSGBOX_TASK_STATUS.DONE) {
		msgbox_schedule_poll(task_id);
		return;
	};
	var task = global.msgbox_tasks[$ key];
	var result = MsgBox_TaskResult(task_id);
	MsgBox_TaskRelease(task_id);
	struct_remove(global.msgbox_tasks, key);
	if (result < 1 || result > 4) then return;
	msgbox_invoke_callback(task.callbacks[result - 1], task_id, result);
}

function msgbox_show_async(_message, _title, _kind = MSGBOX_KIND.INFO, _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	var callbacks = msgbox_configure_buttons(_buttons, _alignment);
	var task_id = MsgBox_ShowAsync(string(_message), string(_title), _kind);
	if (task_id <= 0) then return task_id;
	if (!variable_global_exists("msgbox_tasks") || !is_struct(global.msgbox_tasks)) then global.msgbox_tasks = {};
	global.msgbox_tasks[$ string(task_id)] = { callbacks:callbacks };
	msgbox_schedule_poll(task_id);
	return task_id;
}

function msgbox_info_async(_message, _title = "Information", _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	return msgbox_show_async(_message, _title, MSGBOX_KIND.INFO, _buttons, _alignment);
}

function msgbox_info_sync(_message, _title = "Information", _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	return msgbox_show_sync(_message, _title, MSGBOX_KIND.INFO, _buttons, _alignment);
}

function msgbox_warning_async(_message, _title = "Warning", _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	return msgbox_show_async(_message, _title, MSGBOX_KIND.WARNING, _buttons, _alignment);
}

function msgbox_warning_sync(_message, _title = "Warning", _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	return msgbox_show_sync(_message, _title, MSGBOX_KIND.WARNING, _buttons, _alignment);
}

function msgbox_error_async(_message, _title = "Error", _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	return msgbox_show_async(_message, _title, MSGBOX_KIND.ERROR, _buttons, _alignment);
}

function msgbox_error_sync(_message, _title = "Error", _buttons = [], _alignment = MSGBOX_BUTTON_ALIGN.LEFT) {
	return msgbox_show_sync(_message, _title, MSGBOX_KIND.ERROR, _buttons, _alignment);
}

/**
 * @param {Pointer} _device
 * @param {Pointer} _context
 * @returns {Real} 
 */
function rpe_hlsl_initialize(_device, _context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: Pointer
    if (!is_ptr(_device)) show_error($"{_GMFUNCTION_} :: _device expected ptr", true);
    buffer_write(__args_buffer, buffer_u64, int64(_device));

    // param: _context, type: Pointer
    if (!is_ptr(_context)) show_error($"{_GMFUNCTION_} :: _context expected ptr", true);
    buffer_write(__args_buffer, buffer_u64, int64(_context));

    var _return_value = __rpe_hlsl_initialize(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Pointer} _device
 * @param {Pointer} _context
 * @returns {Real}
 */
function rpe_gles_initialize(_device, _context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    if (!is_ptr(_device)) show_error($"{_GMFUNCTION_} :: _device expected ptr", true);
    buffer_write(__args_buffer, buffer_u64, int64(_device));

    if (!is_ptr(_context)) show_error($"{_GMFUNCTION_} :: _context expected ptr", true);
    buffer_write(__args_buffer, buffer_u64, int64(_context));

    return __rpe_gles_initialize(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));
}

// Skipping function rpe_hlsl_state (no wrapper is required)


// Skipping function rpe_hlsl_compile (no wrapper is required)


// Skipping function rpe_glsl_translate (no wrapper is required)


// Skipping function rpe_hlsl_set_uniform_component (no wrapper is required)


// Skipping function rpe_hlsl_begin (no wrapper is required)


// Skipping function rpe_hlsl_draw (no wrapper is required)


// Skipping function rpe_hlsl_target_width (no wrapper is required)


// Skipping function rpe_hlsl_target_height (no wrapper is required)


/**
 * @param {Pointer} _input
 * @param {Real} _line_count
 * @returns {Bool} 
 */
function rpe_worker_upload_lines(_input, _line_count)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _input, type: Pointer
    if (!is_ptr(_input)) show_error($"{_GMFUNCTION_} :: _input expected ptr", true);
    buffer_write(__args_buffer, buffer_u64, int64(_input));

    // param: _line_count, type: Int32
    if (!is_numeric(_line_count)) show_error($"{_GMFUNCTION_} :: _line_count expected number", true);
    buffer_write(__args_buffer, buffer_s32, _line_count);

    var _return_value = __rpe_worker_upload_lines(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

/**
 * @param {Pointer} _input
 * @param {Real} _line_count
 * @param {Pointer} _output
 * @returns {Real} 
 */
function rpe_worker_resolve_lines(_input, _line_count, _output)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _input, type: Pointer
    if (!is_ptr(_input)) show_error($"{_GMFUNCTION_} :: _input expected ptr", true);
    buffer_write(__args_buffer, buffer_u64, int64(_input));

    // param: _line_count, type: Int32
    if (!is_numeric(_line_count)) show_error($"{_GMFUNCTION_} :: _line_count expected number", true);
    buffer_write(__args_buffer, buffer_s32, _line_count);

    // param: _output, type: Pointer
    if (!is_ptr(_output)) show_error($"{_GMFUNCTION_} :: _output expected ptr", true);
    buffer_write(__args_buffer, buffer_u64, int64(_output));

    var _return_value = __rpe_worker_resolve_lines(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

// Skipping function rpe_worker_shutdown (no wrapper is required)


/**
 * @param {Pointer} _window
 * @returns {Bool} 
 */
function rpe_window_drag_enable(_window)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _window, type: Pointer
    if (!is_ptr(_window)) show_error($"{_GMFUNCTION_} :: _window expected ptr", true);
    buffer_write(__args_buffer, buffer_u64, int64(_window));

    var _return_value = __rpe_window_drag_enable(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

// Skipping function rpe_window_drag_disable (no wrapper is required)


// Skipping function rpe_hlsl_end (no wrapper is required)


// Skipping function rpe_hlsl_release (no wrapper is required)


// Skipping function rpe_hlsl_shutdown (no wrapper is required)


// Skipping function rpe_extension_shutdown (no wrapper is required)


// Skipping function rpe_hlsl_get_error (no wrapper is required)


/// @ignore
function __I_NativeBindings_get_decoders()
{
    static __decoders = [];
    return __decoders;
}
