/// @description Semi-transparent cover and skewed loading layout.
if (pls_is_gxgames() && room != room_loading && room != room_menu) {
    chart_loading_animation_finish();
    exit;
};

var _now = current_time;
var _intro_start = intro_started_at >= 0 ? intro_started_at : started_at;
var _intro_t = clamp((_now - _intro_start) / cover_duration, 0, 1);
var _intro_ease = Easings.OutExpo(_intro_t);
var _cover_right = lerp(-room_width, 0, _intro_ease);
var _ui_alpha = _intro_ease;
var _design_w = 1366;
var _design_h = 768;
var _ui_scale = min(room_width / _design_w, room_height / _design_h);
var _ui_origin_x = (room_width - _design_w * _ui_scale) * 0.5;
var _ui_origin_y = (room_height - _design_h * _ui_scale) * 0.5;
var _exit_pixel_x = 0;
if (state == LOAD_ANIM_STATE.EXITING && exit_started_at >= 0) {
    var _exit_t = clamp((_now - exit_started_at) / exit_duration, 0, 1);
    var _exit_ease = Easings.InExpo(_exit_t);
    // Slide by the full room width so ultrawide leftover UI cannot sit in
    // the side letterbox after a 1366-wide design-space move.
    _exit_pixel_x = room_width * _exit_ease;
};

// 绘制同比例模糊背景，黑色内遮从左向右覆盖。
var _blur_draw = chart_loading_blur_draw_sprite();
if(sprite_exists(_blur_draw)){
	var _scal = (max( room_width / sprite_get_width(_blur_draw) , room_height / sprite_get_height(_blur_draw) ));
	draw_sprite_ext(_blur_draw , 0 , room_width / 2 , room_height / 2 , _scal , _scal , 0 , c_white , 1);
};

draw_sprite_stretched_ext(
    spr_black,
    0,
    _cover_right + _exit_pixel_x,
    0,
    room_width,
    room_height,
    c_white,
    0.6
);

// UI is revealed only inside the covered region and follows the same easing.
gpu_push_state();
var _cover_x = _cover_right + _exit_pixel_x;
var _scissor_x = clamp(_cover_x, 0, room_width);
var _scissor_w = clamp(_cover_x + room_width, 0, room_width) - _scissor_x;
gpu_set_scissor(_scissor_x, 0, max(0, _scissor_w), room_height);
draw_set_alpha(_ui_alpha);

var _ui_cx = _design_w * 0.5;
var _ui_cy = _design_h * 0.5;
// GML anonymous functions do not capture local variables. Keep the current
// transform in globals so these small coordinate helpers remain valid.
global.load_ui_origin_x = _ui_origin_x + _exit_pixel_x;
global.load_ui_origin_y = _ui_origin_y;
global.load_ui_scale = _ui_scale;
var _ux = function(_value) { return global.load_ui_origin_x + _value * global.load_ui_scale; };
var _uy = function(_value) { return global.load_ui_origin_y + _value * global.load_ui_scale; };
var _us = function(_value) { return _value * global.load_ui_scale; };

// name 和 level 的 两平行四边形
draw_parallelogram_fill(_ux(_ui_cx - 600), _uy(_ui_cy - 40), _us(485), _us(120), c_black);
draw_parallelogram_fill(_ux(_ui_cx - 250), _uy(_ui_cy - 40), _us(120), _us(120), c_white);

draw_set_font(ui_font);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_colour(c_white);

var _info = chart_session_ensure();
var _level_raw = string(_info.level);
var _level_num = _level_raw;
var _level_name = "";
var _level_parts = string_split(string_trim(_level_raw), " ");
for (var _level_i = 0; _level_i < array_length(_level_parts); _level_i++) {
    var _level_part = string_trim(string(_level_parts[_level_i]));
    if (!string_length(_level_part)) then continue;
    var _level_lower = string_lower(_level_part);
    if (string_pos("lv", _level_lower) == 1) {
        var _lv_value = string_trim(string_delete(_level_part, 1, 2));
        while (string_length(_lv_value) > 0 && string_char_at(_lv_value, 1) == ".") {
            _lv_value = string_trim(string_delete(_lv_value, 1, 1));
        };
        if (string_length(_lv_value)) then _level_num = _lv_value;
    } else if (is_numeric(_level_part)) then _level_num = _level_part;
    else if (!string_length(_level_name)) then _level_name = _level_part;
};

var _fit_scale = function(_text, _base_scale, _max_width) {
    var _width = string_width(_text) * _base_scale;
    return _width > _max_width ? _base_scale * _max_width / max(1, _width) : _base_scale;
};
var _name_scale = _fit_scale(string(_info.name), 1, 270);
var _composer_scale = _fit_scale(string(_info.composer), 0.35, 270);
draw_text_transformed_color(_ux(_ui_cx - 540), _uy(_ui_cy - 110), string(_info.name), _us(_name_scale), _us(_name_scale), 0, c_white, c_white, c_white, c_white, 1);
draw_text_transformed_color(_ux(_ui_cx - 540), _uy(_ui_cy - 70), string(_info.composer), _us(_composer_scale), _us(_composer_scale), 0, c_white, c_white, c_white, c_white, 1);
// 绘制等级 , 等级是可自定义的 , 可为数字也可为字母 , 比如 AT Lv.17 , 那么level num为17 , 而剩下来的"AT"为level name(按空格分割 , 忽略"Lv."). 假如level的字符串没有空格，比如就写一个0 , 那么level name为空 , level num为0 ; 如果是纯字母的 , 那么level name依旧为空字符串 , level num为这个字母(单词)
draw_set_halign(fa_center);
var _level_num_scale = _fit_scale(_level_num, 1.1, 75);
var _level_name_scale = _fit_scale(_level_name, 0.5, 75);
draw_text_transformed_color(_ux(_ui_cx - 170), _uy(_ui_cy - 100), _level_num, _us(_level_num_scale), _us(_level_num_scale), 0, c_black, c_black, c_black, c_black, 1);
draw_text_transformed_color(_ux(_ui_cx - 180), _uy(_ui_cy - 65), _level_name, _us(_level_name_scale), _us(_level_name_scale), 0, c_black, c_black, c_black, c_black, 1);

// 绘制Charter 和 Illustrator
draw_set_halign(fa_left);
// Charter
draw_text_transformed_color(_ux(_ui_cx - 500), _uy(_ui_cy + 10), lang("loadAnim.chart"), _us(0.3), _us(0.3), 0, c_white, c_white, c_white, c_white, 1);
draw_text_transformed_color(_ux(_ui_cx - 500), _uy(_ui_cy + 30), string(_info.charter), _us(0.4), _us(0.4), 0, c_white, c_white, c_white, c_white, 1);
// Illustrator
draw_text_transformed_color(_ux(_ui_cx - 510), _uy(_ui_cy + 60), lang("loadAnim.illustration"), _us(0.3), _us(0.3), 0, c_white, c_white, c_white, c_white, 1);
draw_text_transformed_color(_ux(_ui_cx - 510), _uy(_ui_cy + 80), string(_info.illustrator), _us(0.4), _us(0.4), 0, c_white, c_white, c_white, c_white, 1);


// tips
draw_text_transformed_color(_ux(55), _uy(_design_h - 40), tips[tip_index], _us(0.5), _us(0.5), 0, c_white, c_white, c_white, c_white, 1);

// Preview size is window/2 by window/2. Origin is the sprite center, so
// the name-aligned point is the draw position. One scale avoids squash.
if (sprite_exists(clear_sprite)) {
    var _win_w = max(1, window_get_width());
    var _win_h = max(1, window_get_height());
    var _spr_w = max(1, sprite_get_width(clear_sprite));
    var _spr_h = max(1, sprite_get_height(clear_sprite));
    var _art_w = (_win_w * 0.5) * (room_width / _win_w);
    var _art_h = (_win_h * 0.5) * (room_height / _win_h);
    var _art_scale = min(_art_w / _spr_w, _art_h / _spr_h);
    draw_sprite_ext(clear_sprite, 0, _ux(_ui_cx + 250), _uy(_ui_cy - 55),
        _art_scale, _art_scale, 0, c_white, 1);
};

// The loading label loops independently of the cover animation.
var _loading_text = lang("loadAnim.loading");
var _loading_scale = _us(0.5);
var _loading_x = _ux(_design_w - 105);
var _loading_y = _uy(_design_h - 40);
var _loading_rect_width = _us(loading_rect_width_design + 20);
var _loading_rect_height = _us(loading_rect_height_design - 20);
var _loading_rect_left_full = _loading_x - _loading_rect_width * 0.5;
var _loading_rect_right_full = _loading_x + _loading_rect_width * 0.5;
var _loading_rect_scale = clamp(loading_rect_scale, 0, 1);
var _loading_rect_width_scaled = _loading_rect_width * _loading_rect_scale;
var _loading_rect_left_scaled = loading_rect_phase == 3
    ? _loading_rect_right_full - _loading_rect_width_scaled
    : _loading_rect_left_full;
var _loading_rect_top = _loading_y - _loading_rect_height * 0.5;

draw_set_halign(fa_center);
draw_text_transformed_color(_loading_x, _loading_y, _loading_text,
    _loading_scale, _loading_scale, 0, c_white, c_white, c_white, c_white, 1);
if (_loading_rect_width_scaled > 0) {
    draw_set_colour(c_white);
    draw_rectangle(_loading_rect_left_scaled, _loading_rect_top,
        _loading_rect_left_scaled + _loading_rect_width_scaled,
        _loading_rect_top + _loading_rect_height, false);

    // The second draw uses the right-middle text origin, so the rectangle's
    // right edge stays fixed when its horizontal scale shrinks.
    gpu_set_scissor(_loading_rect_left_scaled, _loading_rect_top,
        _loading_rect_width_scaled, _loading_rect_height);
    draw_text_transformed_color(_loading_x, _loading_y, _loading_text,
        _loading_scale, _loading_scale, 0, c_black, c_black, c_black, c_black, 1);
    gpu_set_scissor(_scissor_x, 0, max(0, _scissor_w), room_height);
};
draw_set_alpha(1);
gpu_pop_state();
/*
var _old_colour = draw_get_colour();
var _old_alpha = draw_get_alpha();
var _old_font = draw_get_font();
var _old_halign = draw_get_halign();
var _old_valign = draw_get_valign();

var _now = current_time;
var _cover_p = clamp((_now - started_at) / cover_duration, 0, 1);
var _cover_x = -room_width;
if (state == LOAD_ANIM_STATE.COVERING) {
    _cover_x = lerp(-room_width, 0, _cover_p * _cover_p * (3 - 2 * _cover_p));
} else if (state != LOAD_ANIM_STATE.PREPARING) {
    _cover_x = 0;
};

var _tip_alpha = 0;
if (state == LOAD_ANIM_STATE.REVEALING) _tip_alpha = clamp((_now - started_at) / reveal_duration, 0, 1);
if (state == LOAD_ANIM_STATE.HOLDING || state == LOAD_ANIM_STATE.EXITING) _tip_alpha = 1;

var _exit_x = 0;
if (state == LOAD_ANIM_STATE.EXITING) {
    var _exit_p = clamp((_now - exit_started_at) / exit_duration, 0, 1);
    _exit_x = room_width * (_exit_p * _exit_p * (3 - 2 * _exit_p));
};

// The blurred artwork is always a proportional crop covering the whole room.
if (sprite_exists(blur_sprite)) {
    var _bw = sprite_get_width(blur_sprite);
    var _bh = sprite_get_height(blur_sprite);
    var _bg_scale = max(room_width / _bw, room_height / _bh);
    draw_sprite_ext(blur_sprite, 0, room_width * 0.5, room_height * 0.5, _bg_scale, _bg_scale, 0, c_white, 1);
} else {
    draw_set_colour(c_black);
    draw_set_alpha(1);
    draw_rectangle(0, 0, room_width, room_height, true);
};

// Inner black cover. Its right edge is the reveal boundary.
draw_set_colour(c_black);
draw_set_alpha(0.6);
draw_rectangle(_cover_x + _exit_x, 0, _cover_x + _exit_x + room_width, room_height, false);

var _design_w = 1366;
var _design_h = 768;
var _sx = room_width / _design_w;
var _sy = room_height / _design_h;
var _x = _exit_x;
var _scale = min(_sx, _sy);
var _mask_width = state == LOAD_ANIM_STATE.COVERING
    ? clamp(_cover_x + room_width, 0, room_width)
    : (state == LOAD_ANIM_STATE.PREPARING ? 0 : room_width);
gpu_push_state();
gpu_set_scissor(0, 0, _mask_width, room_height);
var _panel_left = 50 * _sx + _x;
var _panel_top = 144 * _sy;
var _panel_w = 334 * _sx;
var _panel_h = 92 * _sy;

draw_set_alpha(1);
draw_set_colour(c_black);
if (sprite_exists(panel_sprite)) {
    // This runtime has no draw_sprite_nineslice API; the authored nine-slice
    // metadata remains on the high-resolution sprite for editor/runtime use.
    draw_sprite_stretched_ext(panel_sprite, 0, _panel_left, _panel_top, _panel_w, _panel_h, c_black, 1);
};

var _info = chart_session_ensure();
var _level_raw = string(_info.level);
var _level_num = _level_raw;
var _level_name = "";
var _level_parts = string_split(string_trim(_level_raw), " ");
for (var _level_i = 0; _level_i < array_length(_level_parts); _level_i++) {
    var _level_part = string_trim(string(_level_parts[_level_i]));
    if (!string_length(_level_part)) then continue;
    if (string_lower(_level_part) == "lv" || string_lower(_level_part) == "lv.") then continue;
    if (is_real(real(_level_part))) then _level_num = _level_part;
    else if (!string_length(_level_name)) then _level_name = _level_part;
};
if (font_exists(ui_font)) then draw_set_font(ui_font);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_colour(c_white);
draw_text_transformed(_panel_left + 40 * _sx, _panel_top + 30 * _sy, string(_info.name), 0.75 * _scale, 0.75 * _scale, 0);
draw_text_transformed(_panel_left + 36 * _sx, _panel_top + 57 * _sy, lang("loadAnim.chart"), 0.42 * _scale, 0.42 * _scale, 0);
draw_text_transformed(_panel_left + 36 * _sx, _panel_top + 78 * _sy, string(_info.format_name), 0.55 * _scale, 0.55 * _scale, 0);

var _diff_left = 265 * _sx + _x;
var _diff_top = 144 * _sy;
var _diff_w = 90 * _sx;
var _diff_h = 92 * _sy;
var _diff_skew = _diff_h;
draw_set_colour(c_white);
draw_sprite_pos(spr_pixel_1, 0,
	room_width / 2 - 40 , room_height / 2 - 40,
	room_width / 2 - 50 , room_height / 2 - 10,
	room_width / 2 + 50 , room_height / 2 - 40,
	room_width / 2 + 40 , room_height / 2 - 10,
	1
);
draw_set_colour(c_black);
draw_set_halign(fa_center);
draw_text_transformed(_diff_left + _diff_w * 0.5, _diff_top + 36 * _sy, string(_info.level), 0.7 * _scale, 0.7 * _scale, 0);
draw_text_transformed(_diff_left + _diff_w * 0.5, _diff_top + 68 * _sy, string(_info.format_name), 0.3 * _scale, 0.3 * _scale, 0);

draw_set_halign(fa_left);
draw_set_colour(c_white);
draw_text_transformed(105 * _sx + _x, 250 * _sy, lang("loadAnim.chart"), 0.5 * _scale, 0.5 * _scale, 0);
draw_text_transformed(105 * _sx + _x, 270 * _sy, string(_info.name), 0.65 * _scale, 0.65 * _scale, 0);
draw_text_transformed(90 * _sx + _x, 300 * _sy, lang("loadAnim.illustration"), 0.5 * _scale, 0.5 * _scale, 0);
draw_text_transformed(90 * _sx + _x, 320 * _sy, "Phigros", 0.65 * _scale, 0.65 * _scale, 0);

// The clear image uses a 45-degree parallelogram and stays above the illustration label.
if (sprite_exists(clear_sprite)) {
    var _right_left = 430 * _sx + _x;
    var _right_top = 32 * _sy;
    var _right_w = room_width * 0.52;
    var _right_h = 288 * _sy;
    var _right_skew = _right_h;
    draw_sprite_pos(clear_sprite, 0,
        _right_left + _right_skew, _right_top,
        _right_left + _right_w + _right_skew, _right_top,
        _right_left + _right_w, _right_top + _right_h,
        _right_left, _right_top + _right_h, 1);
};
gpu_pop_state();

if (_tip_alpha > 0) {
    draw_set_alpha(_tip_alpha);
    draw_set_halign(fa_left);
    draw_set_colour(c_white);
    draw_text_transformed(30 * _sx + _x, room_height - 30 * _sy, tips[tip_index], 0.75 * _scale, 0.75 * _scale, 0);

    var _dots = floor(_now / 260) mod 4;
    var _loading = lang("common.loading");
    for (var _i = 0; _i < _dots; _i++) _loading += ".";
    draw_set_halign(fa_right);
    draw_text_transformed(room_width - 30 * _sx + _x, room_height - 30 * _sy, _loading, 0.65 * _scale, 0.65 * _scale, 0);
};

draw_set_colour(_old_colour);
draw_set_alpha(_old_alpha);
draw_set_font(_old_font);
draw_set_halign(_old_halign);
draw_set_valign(_old_valign);
