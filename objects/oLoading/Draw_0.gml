/// @description Loading progress UI using Camera_View.global_scales.
if (font_exists(ui_font)) then draw_set_font(ui_font);
else draw_set_font(-1);

var s = (variable_global_exists("global_scales") ? global_scales : 1.0);
if (!is_real(s) || s <= 0) then s = 1.0;
var cx = room_width * 0.5;
var cy = room_height * 0.5;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_colour(c_white);
draw_text_transformed(cx, room_height * 0.28, lang("loading.title"), 0.9 * s, 0.9 * s, 0);

draw_set_colour(failed ? c_red : c_aqua);
draw_text_transformed(cx, room_height * 0.42, message, 0.55 * s, 0.55 * s, 0);

draw_set_colour(c_ltgray);
draw_text_transformed(cx, room_height * 0.52, detail, 0.4 * s, 0.4 * s, 0);

var session = chart_session_ensure();
draw_set_colour(c_gray);
draw_text_transformed(cx, room_height * 0.62, langf("loading.statusPrefix", string(session.status)), 0.35 * s, 0.35 * s, 0);
if (string_length(session.detail)) {
        draw_text_transformed(cx, room_height * 0.68, string(session.detail), 0.32 * s, 0.32 * s, 0);
};

if (failed) {
        draw_set_colour(c_silver);
         draw_text_transformed(cx, room_height * 0.82, lang("loading.returning"), 0.35 * s, 0.35 * s, 0);
} else {
        var p = clamp(phase / 3, 0, 1);
        var bx1 = room_width * 0.25;
        var bx2 = room_width * 0.75;
        var by1 = room_height * 0.78;
        var by2 = by1 + max(8, 12 * s);
        draw_set_colour(make_colour_rgb(40, 40, 48));
        draw_rectangle(bx1, by1, bx2, by2, false);
        draw_set_colour(make_colour_rgb(90, 180, 255));
        draw_rectangle(bx1, by1, lerp(bx1, bx2, p), by2, false);
};
