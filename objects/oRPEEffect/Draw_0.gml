/// @description Apply chart-local effects before the HUD renderer.
if (variable_instance_exists(id, "effect_boundary_role")) {
	var _boundary_state = effect_boundary_state;
	if (effect_boundary_role == "start") {
		_boundary_state.active = false;
		if (instance_exists(effect_boundary_controller)) {
			var _boundary_time = effect_boundary_controller.chart_time;
			for (var _boundary_i = 0; _boundary_i < array_length(effect_boundary_effects); _boundary_i++) {
				var _boundary_effect = effect_boundary_effects[@ _boundary_i];
				if (_boundary_time >= _boundary_effect.startTime
					&& _boundary_time < _boundary_effect.endTime) {
					_boundary_state.active = true;
					break;
				};
			};
		};
		if (!_boundary_state.active) then exit;
		var boundary_width = surface_get_width(application_surface);
		var boundary_height = surface_get_height(application_surface);
		if (!surface_exists(_boundary_state.surface)
			|| abs(surface_get_width(_boundary_state.surface) - boundary_width) > 2
			|| abs(surface_get_height(_boundary_state.surface) - boundary_height) > 2) {
			if (surface_exists(_boundary_state.surface)) then surface_free(_boundary_state.surface);
			_boundary_state.surface = surface_create(boundary_width, boundary_height);
		};
		if (surface_exists(_boundary_state.surface)) {
			pls_draw_flush();
			_boundary_state.caller = surface_get_target();
			surface_set_target(_boundary_state.surface);
			draw_clear_alpha(c_black, 0);
		};
	} else if (_boundary_state.active && surface_exists(_boundary_state.surface)) {
		pls_draw_flush();
		surface_reset_target();
		if (instance_exists(effect_boundary_controller)) {
			effect_boundary_controller.boundary_render_effects = effect_boundary_effects;
			effect_boundary_controller.boundary_render_surface = _boundary_state.surface;
			with (effect_boundary_controller) effect_render(boundary_render_effects, boundary_render_surface);
		};
		_boundary_state.active = false;
	};
	exit;
};
var _transition_allows_shaders = true;
if (instance_exists(oPlayTransition)) {
	var _transition = instance_find(oPlayTransition, 0);
	_transition_allows_shaders = (_transition.state == PLAY_TRANSITION_STATE.PLAYING);
};
if (_transition_allows_shaders) then effect_render(effects_local);
