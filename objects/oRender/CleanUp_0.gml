/// @description Release chart-owned dynamic resources on room exit.
if(variable_global_exists("game") && !is_undefined(game)){
	game.Clean(true);
	game = undefined;
};
if(variable_global_exists("_eff_c")) then _eff_c = (function(){ return(false); });
mus_system_clean();
chart_default_resources_unload();
LogUninit();
