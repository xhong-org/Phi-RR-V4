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
