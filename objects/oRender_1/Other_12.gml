/// @description Event enable flags
_draw_user_count = (game.settings.enableChartGUI ? 1 : 0); // draw GUI
var _show_fps = game.settings.enableFPS
	&& !(variable_global_exists("render_mode") && global.render_mode);
_draw_fps_user_count = (_show_fps ? 3 : 0); // draw FPS
_step_fps_user_count = (_show_fps ? 4 : 0); // refresh real FPS

_re_fps = (game.settings[$ "refreshFPSCount"]);
