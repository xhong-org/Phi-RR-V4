/// @description Update cursors and evaluate events in one Step phase.
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then exit;
if(game.paused) then exit;
event_user(3);
event_user(2);
