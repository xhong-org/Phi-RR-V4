/// @description Capture the presented frame. Fullscreen shaders already ran.
if (variable_instance_exists(id, "effect_boundary_role")) then exit;
var _transition_allows_shaders = true;
if (instance_exists(oPlayTransition)) {
	var _transition = instance_find(oPlayTransition, 0);
	_transition_allows_shaders = (_transition.state == PLAY_TRANSITION_STATE.PLAYING);
};
// Fullscreen shaders are already on the chart surface. oChartMask blits that
// image before this event. Do not shade again here.

// Capture only after every global built-in/external shader has composited.
if (variable_global_exists("render_mode") && global.render_mode
	&& instance_exists(oVideoRenderer)) {
	pls_draw_flush();
	with (oVideoRenderer) event_user(0);
};
