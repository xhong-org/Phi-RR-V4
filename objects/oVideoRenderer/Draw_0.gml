///@desc 把录像进度画到独立表面，避免写进成片
// 编码结束后不再画进度。
if (encoder_finished) exit;

// 进度层跟窗口走。录像时房间保持成片尺寸，用房间尺寸会在拉大窗口后把字放大糊掉。
var surface_width = max(1, window_get_width());
var surface_height = max(1, window_get_height());
if (!surface_exists(overlay_surface)
    || overlay_surface_width != surface_width || overlay_surface_height != surface_height) {
    if (surface_exists(overlay_surface)) surface_free(overlay_surface);
    overlay_surface = surface_create(surface_width, surface_height);
    overlay_surface_width = surface_width;
    overlay_surface_height = surface_height;
};
// 表面创建失败就先不画。
if (!surface_exists(overlay_surface)) exit;
overlay_ready = true;

var scale = min(surface_width / 1366, surface_height / 768);
if (!is_real(scale) || scale <= 0) scale = 1.0;
// 进度表面按窗口画，再经房间表面显示，两层变换抵消。文字只用窗口适配缩放。
var text_scale_x = scale;
var text_scale_y = scale;
var panel_width = min(920 * scale, max(240 * scale, surface_width - 64 * scale));
var panel_left = (surface_width - panel_width) * 0.5;
var panel_top = surface_height * 0.5 - 150 * scale;
var output_frame = global.render_frame + global.render_intro_frames;
var output_total_frames = total_frames + global.render_intro_frames + global.render_outro_frames;
var progress = output_total_frames > 0 ? clamp(output_frame / output_total_frames, 0, 1) : 0;
var elapsed = max(0, (get_timer() - render_started_at) / 1000000);
var eta = progress > 0 ? max(0, elapsed * (1 - progress) / progress) : 0;

surface_set_target(overlay_surface);
draw_clear_alpha(c_black, 0);
draw_set_alpha(1);
draw_set_colour(make_colour_rgb(8, 10, 18));
draw_rectangle(0, 0, surface_width, surface_height, false);
draw_set_colour(make_colour_rgb(17, 22, 36));
draw_roundrect_ext(panel_left, panel_top, panel_left + panel_width,
    panel_top + 300 * scale, 18 * scale, 18 * scale, false);

var render_font = -1;
if (font_exists(ui_font)) render_font = ui_font;
else if (variable_global_exists("game") && is_struct(game)
    && variable_struct_exists(game, "font") && font_exists(game.font)) render_font = game.font;
draw_set_font(render_font);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_text_transformed(panel_left + 42 * scale, panel_top + 34 * scale,
    lang("video.title"), 1.1 * text_scale_x, 1.1 * text_scale_y, 0);
draw_set_colour(make_colour_rgb(139, 151, 178));
draw_text_transformed(panel_left + 42 * scale, panel_top + 88 * scale,
    render_status, 0.55 * text_scale_x, 0.55 * text_scale_y, 0);

var source_name = filename_name(global.render_source);
if (!string_length(source_name) || source_name == "__sample__") source_name = lang("video.sample");
draw_set_colour(make_colour_rgb(211, 218, 234));
draw_text_transformed(panel_left + 42 * scale, panel_top + 126 * scale,
    source_name, 0.45 * text_scale_x, 0.45 * text_scale_y, 0);

var bar_left = panel_left + 42 * scale;
var bar_top = panel_top + 178 * scale;
var bar_width = panel_width - 84 * scale;
var bar_height = 18 * scale;
draw_set_colour(make_colour_rgb(38, 45, 64));
draw_roundrect_ext(bar_left, bar_top, bar_left + bar_width, bar_top + bar_height,
    bar_height, bar_height, false);
// 有进度才画前景条。
if (progress > 0) {
    draw_set_colour(make_colour_rgb(96, 216, 190));
    draw_roundrect_ext(bar_left, bar_top, bar_left + bar_width * progress,
        bar_top + bar_height, bar_height, bar_height, false);
};

draw_set_colour(c_white);
draw_text_transformed(bar_left, bar_top + 38 * scale,
    $"{string_format(progress * 100, 0, 1)}%", 0.55 * text_scale_x, 0.55 * text_scale_y, 0);
draw_set_halign(fa_right);
draw_set_colour(make_colour_rgb(139, 151, 178));
draw_text_transformed(panel_left + panel_width - 42 * scale, bar_top + 40 * scale,
    langf("video.frame", output_frame, output_total_frames), 0.45 * text_scale_x, 0.45 * text_scale_y, 0);
draw_set_halign(fa_left);
draw_text_transformed(bar_left, panel_top + 258 * scale,
    langf("video.elapsed", string_format(elapsed, 0, 1)), 0.45 * text_scale_x, 0.45 * text_scale_y, 0);
draw_set_halign(fa_right);
var eta_text = progress < 1 ? langf("video.remaining", string_format(eta, 0, 1)) : lang("video.finalizing");
draw_text_transformed(panel_left + panel_width - 42 * scale, panel_top + 258 * scale,
    eta_text, 0.45 * text_scale_x, 0.45 * text_scale_y, 0);
surface_reset_target();
