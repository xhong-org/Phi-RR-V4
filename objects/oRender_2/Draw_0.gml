///@desc 绘制 PEC 界面，并处理染色模式
// HUD 还没准备好就不画。
if (!chart_hud_ready()) then exit;
if (chart_actor_exists(oPlayTransition) && chart_actor_find(oPlayTransition, 0).state == PLAY_TRANSITION_STATE.OUTRO) then exit;
draw_set_font(game.font);
chart_actor_user(_draw_user_count);
draw_set_valign(fa_center);

BYD_COLOR_FUNC;
else image_blend = c_white;
