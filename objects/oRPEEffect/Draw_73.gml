/// @description Apply global effects after chart UI rendering.
var _transition_allows_shaders = true;
if (instance_exists(oPlayTransition)) {
	var _transition = instance_find(oPlayTransition, 0);
	_transition_allows_shaders = (_transition.state == PLAY_TRANSITION_STATE.PLAYING);
};
if (_transition_allows_shaders) then effect_render(effects_global);

// Capture only after every global built-in/external shader has composited.
if (variable_global_exists("render_mode") && global.render_mode
	&& instance_exists(oVideoRenderer)) {
	draw_flush();
	with (oVideoRenderer) event_user(0);
};
