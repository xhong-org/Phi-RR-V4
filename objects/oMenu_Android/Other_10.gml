/// @description Rebuild Android menu layout from Camera_View.global_scales
if (!variable_global_exists("global_scales")) {
        globalvar global_scales;
        global_scales = 1.0;
};

var s = global_scales;
if (!is_real(s) || s <= 0) then s = 1.0;

var rw = max(1, room_width);
var rh = max(1, room_height);
var btn_w = 440 * s;
var btn_h = 56 * s;
var gap = 20 * s;

btn_open.w = btn_w;
btn_open.h = btn_h;
btn_open.x = (rw - btn_w) * 0.5;
btn_open.y = rh * 0.42;

btn_sample.w = btn_w;
btn_sample.h = btn_h;
btn_sample.x = (rw - btn_w) * 0.5;
btn_sample.y = btn_open.y + btn_h + gap;

layout_w = rw;
layout_h = rh;
layout_scale = s;
settings_menu_button_layout();
