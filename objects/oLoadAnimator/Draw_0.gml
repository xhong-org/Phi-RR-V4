///@desc 绘制：半透明遮罩和倾斜的加载排版
// 谱面视口裁剪不能切掉这张全屏遮罩。
chart_mask_scissor_clear();
// GX 离开加载房后结束动画。
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
// 退出时整屏滑出，避免超宽屏两侧留下界面。
if (state == LOAD_ANIM_STATE.EXITING && exit_started_at >= 0) {
    var _exit_t = clamp((_now - exit_started_at) / exit_duration, 0, 1);
    var _exit_ease = Easings.InExpo(_exit_t);
    // 按整个房间宽度滑出。只按 1366 设计宽度移动时，超宽屏两侧黑边里还会残留界面。
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

// 界面只在已被遮罩盖住的区域里出现，缓动和遮罩一致。
gpu_push_state();
var _cover_x = _cover_right + _exit_pixel_x;
var _scissor_x = clamp(_cover_x, 0, room_width);
var _scissor_w = clamp(_cover_x + room_width, 0, room_width) - _scissor_x;
gpu_set_scissor(_scissor_x, 0, max(0, _scissor_w), room_height);
draw_set_alpha(_ui_alpha);

var _ui_cx = _design_w * 0.5;
var _ui_cy = _design_h * 0.5;
// GML 匿名函数抓不到局部变量。把当前变换放进全局，这些坐标小函数才仍然有效。
global.load_ui_origin_x = _ui_origin_x + _exit_pixel_x;
global.load_ui_origin_y = _ui_origin_y;
global.load_ui_scale = _ui_scale;
///@desc 把设计坐标 x 换成房间坐标
///@param {Real} _value 设计宽度上的 x
///@returns {Real} 房间坐标 x
var _ux = function(_value) { return global.load_ui_origin_x + _value * global.load_ui_scale; };
///@desc 把设计坐标 y 换成房间坐标
///@param {Real} _value 设计高度上的 y
///@returns {Real} 房间坐标 y
var _uy = function(_value) { return global.load_ui_origin_y + _value * global.load_ui_scale; };
///@desc 把设计尺寸乘上界面缩放
///@param {Real} _value 设计尺寸
///@returns {Real} 缩放后的尺寸
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
// 按空格拆等级：Lv. 后面是数字，其余第一段是名称。
for (var _level_i = 0; _level_i < array_length(_level_parts); _level_i++) {
    var _level_part = string_trim(string(_level_parts[_level_i]));
    if (!string_length(_level_part)) then continue;
    var _level_lower = string_lower(_level_part);
    if (string_pos("lv", _level_lower) == 1) {
        var _lv_value = string_trim(string_delete(_level_part, 1, 2));
        // 去掉 Lv. 后面多余的点。
        while (string_length(_lv_value) > 0 && string_char_at(_lv_value, 1) == ".") {
            _lv_value = string_trim(string_delete(_lv_value, 1, 1));
        };
        if (string_length(_lv_value)) then _level_num = _lv_value;
    } else if (is_numeric(_level_part)) then _level_num = _level_part;
    else if (!string_length(_level_name)) then _level_name = _level_part;
};

///@desc 文字超出最大宽度时缩小字号
///@param {String} _text 要测量的文字
///@param {Real} _base_scale 基础缩放
///@param {Real} _max_width 允许的最大宽度
///@returns {Real} 实际使用的缩放
var _fit_scale = function(_text, _base_scale, _max_width) {
    var _width = string_width(_text) * _base_scale;
    // 超宽才按比例缩小，避免除以 0。
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

// 绘制谱师和画师
draw_set_halign(fa_left);
// 谱师
draw_text_transformed_color(_ux(_ui_cx - 500), _uy(_ui_cy + 10), lang("loadAnim.chart"), _us(0.3), _us(0.3), 0, c_white, c_white, c_white, c_white, 1);
draw_text_transformed_color(_ux(_ui_cx - 500), _uy(_ui_cy + 30), string(_info.charter), _us(0.4), _us(0.4), 0, c_white, c_white, c_white, c_white, 1);
// 画师
draw_text_transformed_color(_ux(_ui_cx - 510), _uy(_ui_cy + 60), lang("loadAnim.illustration"), _us(0.3), _us(0.3), 0, c_white, c_white, c_white, c_white, 1);
draw_text_transformed_color(_ux(_ui_cx - 510), _uy(_ui_cy + 80), string(_info.illustrator), _us(0.4), _us(0.4), 0, c_white, c_white, c_white, c_white, 1);


// 提示
draw_text_transformed_color(_ux(55), _uy(_design_h - 40), tips[tip_index], _us(0.5), _us(0.5), 0, c_white, c_white, c_white, c_white, 1);

// 预览尺寸是窗口的一半乘一半。原点在精灵中心，所以对齐名字的点就是绘制位置。单一缩放避免压扁。
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

// 加载字样的开合不跟遮罩动画绑在一起。
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
// 收回阶段从右缘缩短，展开阶段从左缘长出。
var _loading_rect_left_scaled = loading_rect_phase == 3
    ? _loading_rect_right_full - _loading_rect_width_scaled
    : _loading_rect_left_full;
var _loading_rect_top = _loading_y - _loading_rect_height * 0.5;

draw_set_halign(fa_center);
draw_text_transformed_color(_loading_x, _loading_y, _loading_text,
    _loading_scale, _loading_scale, 0, c_white, c_white, c_white, c_white, 1);
// 宽度为 0 时不画白条。
if (_loading_rect_width_scaled > 0) {
    draw_set_colour(c_white);
    draw_rectangle(_loading_rect_left_scaled, _loading_rect_top,
        _loading_rect_left_scaled + _loading_rect_width_scaled,
        _loading_rect_top + _loading_rect_height, false);

    // 第二次绘制用右中对齐，横向缩小时右缘保持不动。
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

// 模糊图始终按比例铺满整个房间。
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

// 内层黑遮，右边缘是揭开边界。
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
    // 当前运行时没有九宫格拉伸接口。
    // 九宫格数据仍留在高分辨率精灵上，供编辑器和运行时使用。
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

// 清晰图用 45 度平行四边形，画在插画标签上面。
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
