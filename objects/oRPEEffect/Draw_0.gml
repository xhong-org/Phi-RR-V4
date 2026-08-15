/// @description Apply chart-local effects before the HUD renderer.
var _transition_allows_shaders = true;
if (instance_exists(oPlayTransition)) {
	var _transition = instance_find(oPlayTransition, 0);
	_transition_allows_shaders = (_transition.state == PLAY_TRANSITION_STATE.PLAYING);
};
if (_transition_allows_shaders) then effect_render(effects_local);
