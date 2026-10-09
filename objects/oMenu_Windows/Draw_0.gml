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

menu_draw_button(btn_open, hover_open, btn_text_scale);
menu_draw_button(btn_sample, hover_sample, btn_text_scale);
menu_draw_button(btn_render, hover_render, btn_text_scale);

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

if (tools_open) {
        var panel_w = min(room_width - 40, 520 * s);
        var panel_h = min(room_height - 40, 400 * s);
        var panel_x0 = (room_width - panel_w) * 0.5;
        var panel_y0 = (room_height - panel_h) * 0.5;
        var row_h = 48 * s;
        var row_w = panel_w - 48 * s;
        tools_export_box = { x: panel_x0 + 24 * s, y: panel_y0 + 78 * s, w: row_w, h: row_h };
        tools_pec_box = { x: panel_x0 + 24 * s, y: panel_y0 + 78 * s + row_h + 14 * s, w: row_w, h: row_h };
        tools_close_box = { x: panel_x0 + 24 * s, y: panel_y0 + panel_h - 24 * s - row_h, w: row_w, h: row_h };
        draw_set_alpha(0.55);
        draw_set_colour(c_black);
        draw_rectangle(0, 0, room_width, room_height, false);
        draw_set_alpha(1);
        var panel_x = tools_export_box.x - 24 * s;
        var panel_r = tools_export_box.x + tools_export_box.w + 24 * s;
        var panel_y = tools_close_box.y + tools_close_box.h + 24 * s;
        var panel_top = tools_export_box.y - 78 * s;
        draw_set_colour(make_colour_rgb(22, 26, 34));
        draw_rectangle(panel_x, panel_top, panel_r, panel_y, false);
        draw_set_colour(c_white);
        draw_rectangle(panel_x, panel_top, panel_r, panel_y, true);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text_transformed((panel_x + panel_r) * 0.5, panel_top + 36 * s, lang("menu.toolsTitle"), subtitle_scale, subtitle_scale, 0);
        menu_draw_button({ x: tools_export_box.x, y: tools_export_box.y, w: tools_export_box.w, h: tools_export_box.h, label: lang("menu.toolsExport") }, hover_tools_export, btn_text_scale);
        menu_draw_button({ x: tools_pec_box.x, y: tools_pec_box.y, w: tools_pec_box.w, h: tools_pec_box.h, label: lang("menu.toolsExportPec") }, hover_tools_pec, btn_text_scale);
        menu_draw_button({ x: tools_close_box.x, y: tools_close_box.y, w: tools_close_box.w, h: tools_close_box.h, label: lang("menu.toolsClose") }, hover_tools_close, btn_text_scale);
        if (string_length(tools_status)) {
                draw_set_colour(c_silver);
                draw_text_transformed((panel_x + panel_r) * 0.5, tools_pec_box.y + tools_pec_box.h + 28 * s, tools_status, small_scale, small_scale, 0);
        };
};
