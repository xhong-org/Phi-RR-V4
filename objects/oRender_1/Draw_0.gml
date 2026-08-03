/// @description
draw_set_font(game.font);
event_user(_draw_user_count);
draw_set_valign(fa_center);
event_user(_draw_fps_user_count);
draw_set_colour(c_gray);
draw_set_halign(fa_left);
draw_text_transformed(5 * global_scales, room_height - (10 * global_scales), $"@{VerStr}[{VerReal}] - Code By XTHX(RPEVersion->{game_1.version})", 0.3 * global_scales, 0.3 * global_scales, 0);

BYD_COLOR_FUNC;
else image_blend = c_white;
