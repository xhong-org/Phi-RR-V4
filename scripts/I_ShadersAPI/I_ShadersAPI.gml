/// @desc Platform dispatch for I_Shaders (Windows rpe_hlsl_* / Android rpe_gles_* / GX WebGL).

function rpe_ext_shader_android() {
        return (os_type == os_android);
}

function rpe_ext_shader_gx() {
        return pls_is_gxgames();
}

function rpe_ext_initialize(_device, _context) {
        if (rpe_ext_shader_gx()) then return gx_shader_initialize();
        if (rpe_ext_shader_android()) then return rpe_gles_initialize(_device, _context);
        return rpe_hlsl_initialize(_device, _context);
}

function rpe_ext_state() {
        if (rpe_ext_shader_gx()) then return gx_shader_state();
        if (rpe_ext_shader_android()) then return rpe_gles_state();
        return rpe_hlsl_state();
}

function rpe_ext_compile(_source, _source_name) {
        if (rpe_ext_shader_gx()) then return gx_shader_compile(_source, _source_name);
        if (rpe_ext_shader_android()) then return rpe_gles_compile(_source, _source_name);
        return rpe_hlsl_compile(_source, _source_name);
}

function rpe_ext_translate(_source, _source_name) {
        if (rpe_ext_shader_gx()) then return _source;
        if (rpe_ext_shader_android()) then return rpe_gles_translate(_source, _source_name);
        return rpe_glsl_translate(_source, _source_name);
}

function rpe_ext_set_uniform_component(_handle, _name, _component, _value) {
        if (rpe_ext_shader_gx()) then return gx_shader_set_uniform_component(_handle, _name, _component, _value);
        if (rpe_ext_shader_android()) then return rpe_gles_set_uniform_component(_handle, _name, _component, _value);
        return rpe_hlsl_set_uniform_component(_handle, _name, _component, _value);
}

function rpe_ext_begin(_handle) {
        if (rpe_ext_shader_gx()) then return gx_shader_begin(_handle);
        if (rpe_ext_shader_android()) then return rpe_gles_begin(_handle);
        return rpe_hlsl_begin(_handle);
}

function rpe_ext_draw(_handle, _uv_left, _uv_top, _uv_right, _uv_bottom) {
        if (rpe_ext_shader_gx()) then return gx_shader_draw(_handle, _uv_left, _uv_top, _uv_right, _uv_bottom);
        if (rpe_ext_shader_android()) then return rpe_gles_draw(_handle, _uv_left, _uv_top, _uv_right, _uv_bottom);
        return rpe_hlsl_draw(_handle, _uv_left, _uv_top, _uv_right, _uv_bottom);
}

function rpe_ext_target_width() {
        if (rpe_ext_shader_gx()) then return gx_shader_target_width();
        if (rpe_ext_shader_android()) then return rpe_gles_target_width();
        return rpe_hlsl_target_width();
}

function rpe_ext_target_height() {
        if (rpe_ext_shader_gx()) then return gx_shader_target_height();
        if (rpe_ext_shader_android()) then return rpe_gles_target_height();
        return rpe_hlsl_target_height();
}

function rpe_ext_end() {
        if (rpe_ext_shader_gx()) then return gx_shader_end();
        if (rpe_ext_shader_android()) then return rpe_gles_end();
        return rpe_hlsl_end();
}

function rpe_ext_release(_handle) {
        if (rpe_ext_shader_gx()) then return gx_shader_release(_handle);
        if (rpe_ext_shader_android()) then return rpe_gles_release(_handle);
        return rpe_hlsl_release(_handle);
}

function rpe_ext_shutdown() {
        if (rpe_ext_shader_gx()) then gx_shader_shutdown();
        else if (rpe_ext_shader_android()) then rpe_gles_shutdown();
        else rpe_hlsl_shutdown();
}

function rpe_ext_get_error() {
        if (rpe_ext_shader_gx()) then return gx_shader_last_error();
        if (rpe_ext_shader_android()) then return rpe_gles_get_error();
        return rpe_hlsl_get_error();
}
