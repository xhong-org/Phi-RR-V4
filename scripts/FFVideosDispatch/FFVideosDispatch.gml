/// @desc Platform dispatch for FFVideos (Windows FFmpeg+D3D11 / Android MediaCodec+OES).

function ffvideos_ext_android() {
        return (os_type == os_android);
}

function ffvideos_ext_initialize(_device, _context) {
        if (ffvideos_ext_android()) then return ffvideos_android_initialize();
        return ffvideos_initialize(_device, _context);
}

function ffvideos_ext_open(_path) {
        if (ffvideos_ext_android()) then return ffvideos_android_open(_path);
        return ffvideos_open(_path);
}

function ffvideos_ext_close(_handle) {
        if (ffvideos_ext_android()) then return ffvideos_android_close(_handle);
        return ffvideos_close(_handle);
}

function ffvideos_ext_play(_handle) {
        if (ffvideos_ext_android()) then return ffvideos_android_play(_handle);
        return ffvideos_play(_handle);
}

function ffvideos_ext_pause(_handle) {
        if (ffvideos_ext_android()) then return ffvideos_android_pause(_handle);
        return ffvideos_pause(_handle);
}

function ffvideos_ext_seek(_handle, _position_ms) {
        if (ffvideos_ext_android()) then return ffvideos_android_seek(_handle, _position_ms);
        return ffvideos_seek(_handle, _position_ms);
}

function ffvideos_ext_prepare_frame(_handle, _position_ms, _timeout_ms) {
        if (ffvideos_ext_android()) then return ffvideos_android_prepare_frame(_handle, _position_ms, _timeout_ms);
        return ffvideos_prepare_frame(_handle, _position_ms, _timeout_ms);
}

function ffvideos_ext_set_volume(_handle, _volume) {
        if (ffvideos_ext_android()) then return ffvideos_android_set_volume(_handle, _volume);
        return ffvideos_set_volume(_handle, _volume);
}

function ffvideos_ext_set_loop(_handle, _enabled) {
        if (ffvideos_ext_android()) then return ffvideos_android_set_loop(_handle, _enabled);
        return ffvideos_set_loop(_handle, _enabled);
}

function ffvideos_ext_get_status(_handle) {
        if (ffvideos_ext_android()) then return ffvideos_android_get_status(_handle);
        return ffvideos_get_status(_handle);
}

function ffvideos_ext_get_duration(_handle) {
        if (ffvideos_ext_android()) then return ffvideos_android_get_duration(_handle);
        return ffvideos_get_duration(_handle);
}

function ffvideos_ext_get_position(_handle) {
        if (ffvideos_ext_android()) then return ffvideos_android_get_position(_handle);
        return ffvideos_get_position(_handle);
}

function ffvideos_ext_get_width(_handle) {
        if (ffvideos_ext_android()) then return ffvideos_android_get_width(_handle);
        return ffvideos_get_width(_handle);
}

function ffvideos_ext_get_height(_handle) {
        if (ffvideos_ext_android()) then return ffvideos_android_get_height(_handle);
        return ffvideos_get_height(_handle);
}

function ffvideos_ext_draw(_handle, _left, _top, _right, _bottom, _alpha, _dim) {
        if (ffvideos_ext_android()) then return ffvideos_android_draw(_handle, _left, _top, _right, _bottom, _alpha, _dim);
        return ffvideos_draw(_handle, _left, _top, _right, _bottom, _alpha, _dim);
}

function ffvideos_ext_get_error(_handle) {
        if (ffvideos_ext_android()) then return ffvideos_android_get_error(_handle);
        return ffvideos_get_error(_handle);
}

function ffvideos_ext_shutdown() {
        if (ffvideos_ext_android()) then ffvideos_android_shutdown();
        else ffvideos_shutdown();
}
