/// @description Draw PEC HUD, FPS and version information.
if (!chart_hud_ready()) then exit;
draw_set_font(game.font);
event_user(_draw_user_count);
draw_set_valign(fa_center);

BYD_COLOR_FUNC;
else image_blend = c_white;
