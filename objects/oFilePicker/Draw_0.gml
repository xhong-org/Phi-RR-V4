///@desc 绘制：模态文件选择器遮罩与列表面板
var old_font = draw_get_font();
var old_halign = draw_get_halign();
var old_valign = draw_get_valign();
var old_colour = draw_get_colour();
var old_alpha = draw_get_alpha();

if (font_exists(ui_font)) then draw_set_font(ui_font);
else draw_set_font(-1);

var s = layout_s;
if (!is_real(s) || s <= 0) then s = 1.0;
var body_scale = 0.38 * s;
var small_scale = 0.32 * s;

// 半透明底，再画面板和盘符按钮。
draw_set_alpha(0.62);
draw_set_colour(c_black);
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_alpha(1);

draw_set_colour(make_colour_rgb(16, 22, 36));
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);
draw_set_colour(c_white);
draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, true);

var current_letter = gx_fp_drive_letter(current_dir);
for (var ri = 0; ri < array_length(root_rects); ri++) {
        var root_box = root_rects[ri];
        var box_letter = gx_fp_drive_letter(root_box.path);
        if (!string_length(box_letter)) then box_letter = gx_fp_drive_letter(root_box.label);
        var root_hot = gx_fp_hit(mouse_x, mouse_y, root_box)
                || (string_length(current_letter) && string_length(box_letter) && current_letter == box_letter);
        gx_fp_draw_button(root_box, root_hot, !downloading);
};

gx_fp_draw_button(btn_up, hover_up, !downloading);
gx_fp_draw_button(btn_back, hover_back, !downloading && gx_fp_history_can_back());
gx_fp_draw_button(btn_fwd, hover_fwd, !downloading && gx_fp_history_can_fwd());
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_colour(c_ltgray);
var path_draw = current_dir;
// 路径太长就只留末尾。
if (string_width(path_draw) * small_scale > path_w && string_length(path_draw) > 8) {
        path_draw = "..." + string_copy(path_draw, max(1, string_length(path_draw) - 56), 56);
};
draw_text_transformed(path_x, path_y + path_h * 0.5, path_draw, small_scale, small_scale, 0);

draw_set_colour(make_colour_rgb(22, 29, 45));
draw_rectangle(list_x, list_y, list_x + list_w, list_y + list_h, false);
draw_set_colour(make_colour_rgb(70, 80, 96));
draw_rectangle(list_x, list_y, list_x + list_w, list_y + list_h, true);

// 空目录给提示，否则只画当前滚动窗口里的行。
if (array_length(items) <= 0) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_colour(c_gray);
        draw_text_ext_transformed(list_x + list_w * 0.5, list_y + list_h * 0.5, lang("picker.empty"), 22, list_w - 24 * s, body_scale, body_scale, 0);
} else {
        var last = min(array_length(items), scroll + visible_rows);
        for (var i = scroll; i < last; i++) {
                var row_y = list_y + (i - scroll) * row_h;
                var item = items[i];
                if (i == selected) {
                        draw_set_colour(make_colour_rgb(70, 110, 180));
                        draw_rectangle(list_x + 2, row_y, list_x + list_w - 2, row_y + row_h, false);
                };
                draw_set_halign(fa_left);
                draw_set_valign(fa_middle);
                draw_set_colour(item.is_dir ? make_colour_rgb(180, 210, 255) : c_white);
                var label = (item.is_dir ? lang("picker.dirPrefix") : "") + item.name;
                // 名字超出列表宽度就逐字截短。
                while (string_width(label) * body_scale > list_w - 20 * s && string_length(label) > 4) {
                        label = string_copy(label, 1, string_length(label) - 1);
                };
                draw_text_transformed(list_x + 10 * s, row_y + row_h * 0.5, label, body_scale, body_scale, 0);
        };
};

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(string_length(last_error) ? c_red : c_silver);
draw_text_transformed(list_x, status_y, status_text, small_scale, small_scale, 0);

gx_fp_draw_button(btn_folder, hover_folder, !downloading);
gx_fp_draw_button(btn_open, hover_open, !downloading);
gx_fp_draw_button(btn_cancel, hover_cancel, true);

draw_set_font(old_font);
draw_set_halign(old_halign);
draw_set_valign(old_valign);
draw_set_colour(old_colour);
draw_set_alpha(old_alpha);
