// ##### extgen :: Auto-generated file do not edit!! #####

// #####################################################################
// # Macros
// #####################################################################

// #####################################################################
// # Enums
// #####################################################################

enum FFVideosStatus
{
    Error = -1,
    Closed = 0,
    Preparing = 1,
    Playing = 2,
    Paused = 3,
    Ended = 4
}

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
function ffvideos_initialize(_device, _context)
{
    var __args_buffer = __ext_core_get_args_buffer();

    // param: _device, type: Pointer
    if (!is_ptr(_device)) show_error($"{_GMFUNCTION_} :: _device expected ptr", true);
    buffer_write(__args_buffer, buffer_u64, int64(_device));

    // param: _context, type: Pointer
    if (!is_ptr(_context)) show_error($"{_GMFUNCTION_} :: _context expected ptr", true);
    buffer_write(__args_buffer, buffer_u64, int64(_context));

    var _return_value = __ffvideos_initialize(buffer_get_address(__args_buffer), buffer_tell(__args_buffer));

    return _return_value;
}

// Skipping function ffvideos_open (no wrapper is required)


// Skipping function ffvideos_close (no wrapper is required)


// Skipping function ffvideos_play (no wrapper is required)


// Skipping function ffvideos_pause (no wrapper is required)


// Skipping function ffvideos_seek (no wrapper is required)


// Skipping function ffvideos_prepare_frame (no wrapper is required)


// Skipping function ffvideos_set_volume (no wrapper is required)


// Skipping function ffvideos_set_loop (no wrapper is required)


// Skipping function ffvideos_get_status (no wrapper is required)


// Skipping function ffvideos_get_duration (no wrapper is required)


// Skipping function ffvideos_get_position (no wrapper is required)


// Skipping function ffvideos_get_width (no wrapper is required)


// Skipping function ffvideos_get_height (no wrapper is required)


// Skipping function ffvideos_draw (no wrapper is required)


// Skipping function ffvideos_get_error (no wrapper is required)


// Skipping function ffvideos_shutdown (no wrapper is required)


/// @ignore
function __FFVideos_get_decoders()
{
    static __decoders = [];
    return __decoders;
}
