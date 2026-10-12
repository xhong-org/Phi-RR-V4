///@desc 按设置决定要不要画界面和刷新帧率
_draw_user_count = (game.settings.enableChartGUI ? 1 : 0);
var _show_fps = game.settings.enableFPS
	&& !(variable_global_exists("render_mode") && global.render_mode);
_draw_fps_user_count = (_show_fps ? 3 : 0);
_step_fps_user_count = (_show_fps ? 4 : 0);
_re_fps = max(1, game.settings.refreshFPSCount);
