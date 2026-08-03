/// @description Apply global effects after chart UI rendering.
effect_render(effects_global);

// Capture only after every global built-in/external shader has composited.
if (variable_global_exists("render_mode") && global.render_mode
	&& instance_exists(oVideoRenderer)) {
	draw_flush();
	with (oVideoRenderer) event_user(0);
};
