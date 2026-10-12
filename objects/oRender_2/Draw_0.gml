///@desc 绘制 PEC 界面，并处理染色模式
// HUD 还没准备好就不画。
if (!chart_hud_ready()) then exit;
draw_set_font(game.font);
event_user(_draw_user_count);
draw_set_valign(fa_center);

BYD_COLOR_FUNC;
else image_blend = c_white;
