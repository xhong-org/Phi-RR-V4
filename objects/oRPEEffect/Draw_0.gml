/// @description Apply chart-local effects before the HUD renderer.
if (chart_setting_on("disableChartShader")) then exit;
chart_mask_scissor_set();
if (variable_instance_exists(id, "effect_boundary_role")) {
	var _boundary_state = effect_boundary_state;
	if (effect_boundary_role == "start") {
		_boundary_state.active = false;
		if (instance_exists(effect_boundary_controller)) {
			var _boundary_time = effect_boundary_controller.chart_time;
			for (var _boundary_i = 0; _boundary_i < array_length(effect_boundary_effects); _boundary_i++) {
				var _boundary_effect = effect_boundary_effects[@ _boundary_i];
				if (_boundary_time >= _boundary_effect.startTime
					&& _boundary_time < _boundary_effect.endTime
					&& !rpe_effect_pass_idle(_boundary_effect, _boundary_time)) {
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
			// Nested ranges must return to the outer capture. surface_get_target
			// can report the chart mask while that outer capture is current, and
			// the mask blit then covers the inner result.
			var _capture_parent = surface_get_target();
			if (instance_exists(effect_boundary_controller)) {
				var _capture_stack = effect_boundary_controller.effect_capture_stack;
				if (is_array(_capture_stack) && array_length(_capture_stack) > 0) {
					var _capture_outer = _capture_stack[array_length(_capture_stack) - 1];
					if (surface_exists(_capture_outer)) then _capture_parent = _capture_outer;
				};
				if (!is_array(_capture_stack)) {
					_capture_stack = [];
					effect_boundary_controller.effect_capture_stack = _capture_stack;
				};
				array_push(_capture_stack, _boundary_state.surface);
				_boundary_state.capture_pushed = true;
			};
			_boundary_state.caller = _capture_parent;
			surface_set_target(_boundary_state.surface);
			draw_clear_alpha(c_black, 0);
			// Sprites must land as premultiplied colour with a single alpha.
			// bm_normal squares alpha, so note edges darken and thin lines vanish;
			// shaders that test coverage (the beam wipe) then see nothing to draw.
			gpu_push_state();
			gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
			chart_gpu_blend_commit();
			_boundary_state.blend_pushed = true;
		};
	} else if (_boundary_state.active && surface_exists(_boundary_state.surface)) {
		pls_draw_flush();
		// Unbind before shader_reset. Resetting while this capture is still the
		// target drops the notes that were flushed into it (video 2 glitch).
		var _boundary_parent = _boundary_state.caller;
		surface_reset_target();
		shader_reset();
		// One reset for the set in the start sentinel.
		if (_boundary_state.capture_pushed && instance_exists(effect_boundary_controller)) {
			var _capture_stack = effect_boundary_controller.effect_capture_stack;
			if (is_array(_capture_stack)) {
				for (var _pop_i = array_length(_capture_stack) - 1; _pop_i >= 0; _pop_i--) {
					if (_capture_stack[_pop_i] == _boundary_state.surface) {
						array_delete(_capture_stack, _pop_i, 1);
						break;
					};
				};
			};
			_boundary_state.capture_pushed = false;
		};
		var _layer_fast = "heavy";
		if (instance_exists(effect_boundary_controller)) {
			_layer_fast = rpe_effect_layer_fast(effect_boundary_effects, effect_boundary_controller.chart_time);
		};
		if (is_array(_layer_fast)) {
			var _fast_lum = clamp(real(_layer_fast[0]), 0, 1);
			var _fast_gray = clamp(real(_layer_fast[1]), 0, 1);
			var _fast_invis = clamp(real(_layer_fast[2]), 0, 1);
			// The notes sit outside this z range and are already on the parent.
			// A fully invisible layer (the HUD band) must not be blitted back.
			if (_fast_invis < 0.999) {
				var _lum_byte = round(_fast_lum * 255);
				draw_set_colour(c_white);
				draw_set_alpha(1);
				gpu_set_blendmode_ext_sepalpha(bm_one, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
				gpu_set_texfilter(false);
				gpu_set_texrepeat(false);
				gpu_set_tex_mip_enable(mip_off);
				var _blit_graded = false;
				if (_fast_gray > 0.00005 && shader_is_compiled(shd_rpe_grayscale)) {
					shader_set(shd_rpe_grayscale);
					var _blit_uniform = shader_get_uniform(shd_rpe_grayscale, "factor");
					if (_blit_uniform != -1) then shader_set_uniform_f(_blit_uniform, _fast_gray);
					_blit_graded = true;
				};
				draw_surface_ext(_boundary_state.surface, 0, 0, 1, 1, 0, make_colour_rgb(_lum_byte, _lum_byte, _lum_byte), 1 - _fast_invis);
				pls_draw_flush();
				if (_blit_graded) {
					// shader_reset on a still-bound outer capture (video 2 glitch
					// around this grayscale band) drops the notes just blitted.
					var _graded_target = surface_get_target();
					var _graded_capture = surface_exists(_graded_target) && _graded_target != application_surface;
					if (_graded_capture) then surface_reset_target();
					shader_reset();
					if (_graded_capture) then surface_set_target(_graded_target);
				};
			};
			if (instance_exists(effect_boundary_controller)) {
				var _grade_key = $"layer-blit@{_layer_fast[0]}@{_layer_fast[1]}@{_layer_fast[2]}";
				with (effect_boundary_controller) {
					if (!struct_exists(external_draw_logged, _grade_key)) {
						external_draw_logged[$ _grade_key] = true;
						print($"[RPE Effect] Layer blit: gray={_layer_fast[1]}, lum={_layer_fast[0]}, invis={_layer_fast[2]}, time={chart_time}");
					};
				};
			};
		} else if (instance_exists(effect_boundary_controller)) {
			effect_boundary_controller.boundary_render_effects = effect_boundary_effects;
			effect_boundary_controller.boundary_render_surface = _boundary_state.surface;
			effect_boundary_controller.boundary_render_parent = _boundary_parent;
			with (effect_boundary_controller) effect_render(boundary_render_effects, boundary_render_surface, boundary_render_parent);
		};
		if (_boundary_state.blend_pushed) {
			gpu_pop_state();
			_boundary_state.blend_pushed = false;
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
if (_transition_allows_shaders
	&& (!is_array(effect_capture_stack) || array_length(effect_capture_stack) <= 0)) {
	effect_render(effects_local);
	// Shaders without targetRange are fullscreen. oChartMask presents them
	// after every Draw, immediately before the chart blit. Shading here would
	// miss later layers, and shading after the blit never reaches the screen.
	if (!(variable_global_exists("chart_surface_active") && chart_surface_active && instance_exists(oChartMask))) {
		effect_render(effects_global);
	};
};
