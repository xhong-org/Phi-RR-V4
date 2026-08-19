/// @description 
draw_set_font(game.font);
event_user(_draw_user_count);
draw_set_valign(fa_center);
event_user(_draw_fps_user_count);
draw_set_colour(c_gray);
draw_set_halign(fa_left);
draw_text_transformed(chart_view_left + 5 * global_scales , room_height - (10 * global_scales) , $"@{VerStr}[{VerReal}] - Code By XTHX(PGRVersion->{game.version})" , 0.3 * global_scales , 0.3 * global_scales , 0);

//draw_text_transformed_color(5 , 100 , string_format(game.__time[1] , string_length(string(ceil(game.__time[1]))) , 5) , 0.3 , 0.3 , 0 , c_white , c_white , c_white , c_white , 1);
BYD_COLOR_FUNC;
else image_blend = c_white;
