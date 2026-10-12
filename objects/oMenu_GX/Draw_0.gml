///@desc 绘制 GX 菜单标题、选文件按钮和 API 状态
var scale_now = (variable_global_exists("global_scales") ? global_scales : 1.0);
if (layout_w != room_width || layout_h != room_height || layout_scale != scale_now) {
        pls_gx_menu_layout();
};

if (font_exists(ui_font)) then draw_set_font(ui_font);
else draw_set_font(-1);

var s = (variable_global_exists("global_scales") ? global_scales : 1.0);
if (!is_real(s) || s <= 0) then s = 1.0;

var cx = room_width * 0.5;
var title_scale = 1.1 * s;
var subtitle_scale = 0.55 * s;
var body_scale = 0.5 * s;
var small_scale = 0.32 * s;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(c_white);
draw_text_transformed(cx, room_height * 0.18, GAME_NAME, title_scale, title_scale, 0);
draw_set_colour(c_ltgray);
draw_text_transformed(cx, room_height * 0.26, lang("menu.subtitle"), subtitle_scale, subtitle_scale, 0);

var fill_idle = make_colour_rgb(40, 48, 64);
var fill_hot = make_colour_rgb(70, 110, 180);
var fill_dim = make_colour_rgb(28, 32, 44);

draw_set_colour(hover_pick ? fill_hot : fill_idle);
draw_rectangle(pick_x, pick_y, pick_x + pick_w, pick_y + pick_h, false);
draw_set_colour(c_white);
draw_rectangle(pick_x, pick_y, pick_x + pick_w, pick_y + pick_h, true);
draw_text_transformed(pick_x + pick_w * 0.5, pick_y + pick_h * 0.5, lang("gx.clickPick"), body_scale, body_scale, 0);

// 远程模式没有 API 按钮，宽度为 0 时不画。
if (api_btn_w > 0) {
        var api_dim = !api_online;
        draw_set_colour(hover_api ? fill_hot : (api_dim ? fill_dim : fill_idle));
        draw_rectangle(api_btn_x, api_btn_y, api_btn_x + api_btn_w, api_btn_y + api_btn_h, false);
        draw_set_colour(api_dim ? c_gray : c_white);
        draw_rectangle(api_btn_x, api_btn_y, api_btn_x + api_btn_w, api_btn_y + api_btn_h, true);
        draw_text_transformed(api_btn_x + api_btn_w * 0.5, api_btn_y + api_btn_h * 0.5, api_online ? lang("gx.browseApi") : lang("gx.apiOffline"), body_scale * 0.9, body_scale * 0.9, 0);
};

settings_menu_button_draw(hover_settings, s);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(c_silver);
draw_text_transformed(cx, room_height * 0.78, status_text, body_scale * 0.85, body_scale * 0.85, 0);
draw_set_colour(c_gray);
draw_text_transformed(cx, room_height * 0.84, detail_text, body_scale * 0.7, body_scale * 0.7, 0);
if (string_length(last_error)) {
        draw_set_colour(c_red);
        draw_text_transformed(cx, room_height * 0.9, last_error, body_scale * 0.75, body_scale * 0.75, 0);
};

draw_set_colour(c_dkgray);
if (pls_is_gx_remote()) {
        draw_text_transformed(cx, room_height - max(18, 30 * s), lang("gx.hintRemote"), small_scale, small_scale, 0);
} else {
        draw_text_transformed(cx, room_height - max(18, 30 * s), lang("gx.hintApi"), small_scale, small_scale, 0);
};
