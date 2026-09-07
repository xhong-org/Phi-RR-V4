/// @description Menu draw using Camera_View.global_scales
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

var buttons = [btn_open, btn_sample, btn_render];
var hovers = [hover_open, hover_sample, hover_render];
for (var i = 0; i < array_length(buttons); i++) {
        var b = buttons[i];
        var hot = hovers[i];
        draw_set_colour(hot ? make_colour_rgb(70, 110, 180) : make_colour_rgb(40, 48, 64));
        draw_rectangle(b.x, b.y, b.x + b.w, b.y + b.h, false);
        draw_set_colour(c_white);
        draw_rectangle(b.x, b.y, b.x + b.w, b.y + b.h, true);
        draw_text_transformed(b.x + b.w * 0.5, b.y + b.h * 0.5, b.label, btn_text_scale, btn_text_scale, 0);
};

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
draw_text_transformed(cx, room_height - max(18, 30 * s), lang("menu.hintKeys"), small_scale, small_scale, 0);
