/// @description Composite effective chart viewport.
if (!target_active || !surface_exists(surface_id)) then exit;
pls_draw_flush();
if (instance_exists(oPausedUI)) {
    var _pause_ui = instance_find(oPausedUI, 0);
    if (variable_instance_exists(_pause_ui, "paused_ui_draw")) then _pause_ui.paused_ui_draw();
};
pls_draw_flush();
surface_reset_target();
target_active = false;
chart_surface_active = false;
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
var _copy_left = floor(chart_view_left);
var _copy_width = max(1, ceil(chart_view_right) - _copy_left);
draw_surface_part(surface_id, _copy_left, 0, _copy_width, chart_view_height, _copy_left, 0);
gpu_set_blendmode(bm_normal);
pls_draw_flush();
gpu_pop_state();
