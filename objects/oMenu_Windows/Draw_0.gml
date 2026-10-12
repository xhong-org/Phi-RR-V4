///@desc 按 global_scales 绘制 Windows 菜单和工具面板
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

// 工具面板盖住菜单，并画出转换任务按钮。
if (tools_open) {
        var tools_panel = phi_tools_panel_metrics(room_width, room_height, s);
        tools_export_box = tools_panel.buttons[0];
        tools_pec_box = tools_panel.buttons[1];
        tools_close_box = tools_panel.close;
        draw_set_alpha(0.55);
        draw_set_colour(c_black);
        draw_rectangle(0, 0, room_width, room_height, false);
        draw_set_alpha(1);
        var panel_x = tools_panel.panel_x;
        var panel_r = tools_panel.panel_x + tools_panel.panel_w;
        var panel_top = tools_panel.panel_y;
        var panel_y = tools_panel.panel_y + tools_panel.panel_h;
        draw_set_colour(make_colour_rgb(22, 26, 34));
        draw_rectangle(panel_x, panel_top, panel_r, panel_y, false);
        draw_set_colour(c_white);
        draw_rectangle(panel_x, panel_top, panel_r, panel_y, true);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text_transformed((panel_x + panel_r) * 0.5, panel_top + 32 * s, lang("menu.toolsTitle"), subtitle_scale, subtitle_scale, 0);
        var tool_jobs = phi_tools_jobs();
        var tool_n = min(array_length(tools_panel.buttons), array_length(tool_jobs));
        for (var tool_i = 0; tool_i < tool_n; tool_i++) {
                var tool_box = tools_panel.buttons[tool_i];
                menu_draw_button({ x: tool_box.x, y: tool_box.y, w: tool_box.w, h: tool_box.h, label: lang(tool_jobs[tool_i].label) }, tools_hover == tool_i, btn_text_scale);
        };
        menu_draw_button({ x: tools_close_box.x, y: tools_close_box.y, w: tools_close_box.w, h: tools_close_box.h, label: lang("menu.toolsClose") }, hover_tools_close, btn_text_scale);
        if (string_length(tools_status)) {
                draw_set_colour(c_silver);
                draw_text_transformed((panel_x + panel_r) * 0.5, tools_panel.status_y, tools_status, small_scale, small_scale, 0);
        };
};
