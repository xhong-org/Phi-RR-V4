/// @description Composite effective chart viewport.
chart_mask_scissor_clear();
// Fullscreen shaders (no PhiZone targetRange) must land on this surface before
// the blit. Draw GUI is not used; the pause menu is drawn after this blit.
if (target_active && surface_exists(surface_id) && instance_exists(oRPEEffect)
	&& !chart_setting_on("disableChartShader")) {
	var _global_fx = noone;
	with (oRPEEffect) {
		if (!variable_instance_exists(id, "effect_boundary_role")) then _global_fx = id;
	};
	if (_global_fx != noone && is_array(_global_fx.effects_global) && array_length(_global_fx.effects_global) > 0) {
		var _global_allow = true;
		if (instance_exists(oPlayTransition)) {
			_global_allow = (instance_find(oPlayTransition, 0).state == PLAY_TRANSITION_STATE.PLAYING);
		};
		var _global_stack = _global_fx.effect_capture_stack;
		if (_global_allow && (!is_array(_global_stack) || array_length(_global_stack) <= 0)) {
			pls_draw_flush();
			// Pop the Draw Begin target. effect_render must leave this stack
			// unchanged (caller_was_bound = false), then we bind the mask once
			// so the reset below still matches that single set.
			surface_reset_target();
			with (_global_fx) {
				var _present_key = "global-present";
				if (!struct_exists(external_draw_logged, _present_key)) {
					external_draw_logged[$ _present_key] = true;
					print($"[RPE Effect] Global shader present: count={array_length(effects_global)}, time={chart_time}, surface={surface_get_width(other.surface_id)}x{surface_get_height(other.surface_id)}");
				};
				effect_render(effects_global, other.surface_id, other.surface_id, false);
			};
			surface_set_target(surface_id);
		};
	};
};
if (!target_active || !surface_exists(surface_id)) then exit;
pls_draw_flush();
surface_reset_target();
target_active = false;
chart_surface_active = false;
// Before the start animation, the surface may be brand new. Replacing the
// viewport with that empty frame punches one frame of black over the
// illustration oBG already drew. Keep the illustration this frame.
var _defer_composite = surface_born;
if (_defer_composite && variable_global_exists("loading_animation_active") && global.loading_animation_active) {
	_defer_composite = false;
}
if (_defer_composite && instance_exists(oPlayTransition)) {
	var _transition_state = instance_find(oPlayTransition, 0).state;
	if (_transition_state >= PLAY_TRANSITION_STATE.INTRO) then _defer_composite = false;
}
surface_born = false;
if (_defer_composite) {
	chart_draw_background(false);
	gpu_pop_state();
	exit;
}
gpu_set_blendmode(bm_normal);
draw_set_colour(c_white);
draw_set_alpha(1);
// Play mode already has oBG's undimmed illustration on this surface from
// Draw Begin. Render capture reads the D3D11 target at Draw End, so the
// mask must be drawn here or the encoder only gets the dimmed viewport.
if (variable_global_exists("render_mode") && global.render_mode) {
	chart_draw_background(false);
};
gpu_set_blendmode_ext(bm_one, bm_zero);
draw_set_colour(c_white);
draw_set_alpha(1);
// Always composite the chart viewport. Lines are longer than the 16:9 area;
// copying the whole surface lets that overflow paint over the side mask.
var _copy_left = floor(chart_view_left);
var _copy_right = ceil(chart_view_right);
var _copy_width = max(1, _copy_right - _copy_left);
var _copy_height = max(1, chart_view_height);
if (!chart_mask_enabled() && _copy_width >= surface_get_width(surface_id) - 1) {
	_copy_left = 0;
	_copy_width = max(1, surface_get_width(surface_id));
	_copy_height = max(1, surface_get_height(surface_id));
};
draw_surface_part(surface_id, _copy_left, 0, _copy_width, _copy_height, _copy_left, 0);
gpu_set_blendmode(bm_normal);
pls_draw_flush();
gpu_pop_state();
