/// @description Update cursors and evaluate events in one Step phase.
if (variable_global_exists("loading_animation_active") && global.loading_animation_active
	&& !chart_force_event_init) then exit;
if(game.paused && !chart_force_event_init) then exit;
event_user(3);
event_user(2);
