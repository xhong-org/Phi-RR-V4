///@desc 绘制官谱 HUD，并处理染色模式
if (!chart_hud_ready()) then exit;
draw_set_font(game.font);
event_user(_draw_user_count);
draw_set_valign(fa_center);

//draw_text_transformed_color(5 , 100 , string_format(game.__time[1] , string_length(string(ceil(game.__time[1]))) , 5) , 0.3 , 0.3 , 0 , c_white , c_white , c_white , c_white , 1);
BYD_COLOR_FUNC;
else image_blend = c_white;
