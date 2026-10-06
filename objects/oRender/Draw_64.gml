/// @description FPS and version, above the chart mask and every z-range shader.
if (!chart_hud_ready()) then exit;
shader_reset();
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_font(game.font);
draw_set_valign(fa_center);
if (chart_fps_draw_allowed()) then event_user(_draw_fps_user_count);
draw_set_colour(c_gray);
draw_set_halign(fa_left);
if (!(variable_global_exists("render_mode") && global.render_mode)) {
	draw_text_transformed(chart_view_left + 5 * global_scales, room_height - (10 * global_scales), $"@{VerStr}[{ver_real()}] - Code By XTHX(PGRVersion->{game.version})", 0.3 * global_scales, 0.3 * global_scales, 0);
}
draw_set_valign(fa_top);
draw_set_halign(fa_left);
draw_set_colour(c_white);
draw_set_alpha(1);
