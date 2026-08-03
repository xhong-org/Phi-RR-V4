/// @description Release PEC and shared chart resources on room exit.
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
