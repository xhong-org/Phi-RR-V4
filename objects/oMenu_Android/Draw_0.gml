/// @description Android menu draw using Camera_View.global_scales
var scale_now = (variable_global_exists("global_scales") ? global_scales : 1.0);
if (layout_w != room_width || layout_h != room_height || layout_scale != scale_now) {
        event_user(0);
};

if (font_exists(ui_font)) then draw_set_font(ui_font);
else draw_set_font(-1);

var s = (variable_global_exists("global_scales") ? global_scales : 1.0);
if (!is_real(s) || s <= 0) then s = 1.0;

var cx = room_width * 0.5;
var title_scale = 1.1 * s;
var subtitle_scale = 0.55 * s;
var body_scale = 0.45 * s;
var small_scale = 0.32 * s;
var btn_text_scale = 0.55 * s;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(c_white);
draw_text_transformed(cx, room_height * 0.18, GAME_NAME, title_scale, title_scale, 0);
draw_set_colour(c_ltgray);
draw_text_transformed(cx, room_height * 0.26, lang("menu.subtitle"), subtitle_scale, subtitle_scale, 0);

menu_draw_button(btn_open, hover_open, btn_text_scale);
menu_draw_button(btn_sample, hover_sample, btn_text_scale);

settings_menu_button_draw(hover_settings, s);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(c_silver);
draw_text_transformed(cx, room_height * 0.78, status_text, body_scale, body_scale, 0);
draw_set_colour(c_gray);
draw_text_transformed(cx, room_height * 0.84, detail_text, body_scale * 0.85, body_scale * 0.85, 0);
if (string_length(last_error)) {
        draw_set_colour(c_red);
        draw_text_transformed(cx, room_height * 0.9, last_error, body_scale * 0.9, body_scale * 0.9, 0);
};

draw_set_colour(c_dkgray);
draw_text_transformed(cx, room_height - max(18, 30 * s), lang("menu.hintTap"), small_scale, small_scale, 0);
