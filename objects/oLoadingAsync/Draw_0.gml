/// @description Loading progress UI using Camera_View.global_scales.
if (font_exists(ui_font)) then draw_set_font(ui_font);
else draw_set_font(-1);

var s = (variable_global_exists("global_scales") ? global_scales : 1.0);
if (!is_real(s) || s <= 0) then s = 1.0;
// The loading UI is drawn into the application surface, which may be
// displayed at a different size after the window is resized. Compensate text
// on each frame without changing the surface or the loading layout.
var text_scale_x = s * room_width / max(1, window_get_width());
var text_scale_y = s * room_height / max(1, window_get_height());
var cx = (room_width) * 0.5;
var cy = (room_height) * 0.5;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(c_white);
draw_text_transformed(cx, room_height * 0.28, "Loading Chart", 0.9 * text_scale_x, 0.9 * text_scale_y, 0);

draw_set_colour(failed ? c_red : c_aqua);
draw_text_transformed(cx, room_height * 0.42, message, 0.55 * text_scale_x, 0.55 * text_scale_y, 0);
draw_set_colour(c_ltgray);
draw_text_transformed(cx, room_height * 0.52, detail, 0.4 * text_scale_x, 0.4 * text_scale_y, 0);

var session = chart_session_ensure();
draw_set_colour(c_gray);
draw_text_transformed(cx, room_height * 0.62, "Status: " + string(session.status), 0.35 * text_scale_x, 0.35 * text_scale_y, 0);
if (string_length(session.detail)) {
        draw_text_transformed(cx, room_height * 0.68, string(session.detail), 0.32 * text_scale_x, 0.32 * text_scale_y, 0);
};

if (failed) {
        draw_set_colour(c_silver);
         draw_text_transformed(cx, room_height * 0.82, "Returning to menu...", 0.35 * text_scale_x, 0.35 * text_scale_y, 0);
} else {
        var p = (phase == 10) ? 0.4 : clamp(phase / 3, 0, 1);
         var bx1 = room_width * 0.25;
         var bx2 = room_width * 0.75;
         var by1 = room_height * 0.78;
        var by2 = by1 + max(8, 12 * s);
        draw_set_colour(make_colour_rgb(40, 40, 48));
        draw_rectangle(bx1, by1, bx2, by2, false);
        draw_set_colour(make_colour_rgb(90, 180, 255));
        draw_rectangle(bx1, by1, lerp(bx1, bx2, p), by2, false);
};
