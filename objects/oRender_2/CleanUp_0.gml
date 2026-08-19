/// @description Release PEC and shared chart resources on room exit.
chart_clip_shutdown();
if (variable_global_exists("chart_surface") && !is_undefined(chart_surface) && surface_exists(chart_surface)) then surface_free(chart_surface);
if (variable_global_exists("chart_surface")) then chart_surface = -1;
if (variable_global_exists("chart_background_surface") && !is_undefined(chart_background_surface)
	&& surface_exists(chart_background_surface)) then surface_free(chart_background_surface);
if (variable_global_exists("chart_background_surface")) then chart_background_surface = -1;
if(variable_global_exists("game") && !is_undefined(game)){
	game.Clean(true);
	game = undefined;
};
if(variable_global_exists("game_2") && !is_undefined(game_2)){
	game_2.chart = undefined;
	game_2.line_group = [];
	game_2 = undefined;
};
if(variable_global_exists("_eff_c")) then _eff_c = (function(){ return(false); });
mus_system_clean();
chart_default_resources_unload();
LogUninit();
