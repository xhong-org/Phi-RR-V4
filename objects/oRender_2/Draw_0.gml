/// @description Draw PEC HUD, FPS and version information.
if (!chart_hud_ready()) then exit;
draw_set_font(game.font);
event_user(_draw_user_count);
draw_set_valign(fa_center);
event_user(_draw_fps_user_count);
draw_set_colour(c_gray);
draw_set_halign(fa_left);
draw_text_transformed(chart_view_left + 5 * global_scales, room_height - (10 * global_scales), $"@{VerStr}[{ver_real()}] - Code By XTHX(PECVersion->{game_2.chart.version})", 0.3 * global_scales, 0.3 * global_scales, 0);

BYD_COLOR_FUNC;
else image_blend = c_white;
