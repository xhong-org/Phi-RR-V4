/// @description Composite effective chart viewport.
if (!target_active || !surface_exists(surface_id)) then exit;
draw_flush();
if (instance_exists(oPausedUI)) {
    var _pause_ui = instance_find(oPausedUI, 0);
    if (variable_instance_exists(_pause_ui, "paused_ui_draw")) then _pause_ui.paused_ui_draw();
};
draw_flush();
surface_reset_target();
target_active = false;
chart_surface_active = false;
// The chart surface already contains the complete effective viewport. Copy
// its RGB directly instead of applying the surface alpha a second time. The
// old source-alpha composite made notes, antialiased edges and hit effects
// darker whenever the accumulated surface alpha was below one.
gpu_set_blendmode_ext(bm_one, bm_zero);
draw_set_colour(c_white);
draw_set_alpha(1);
draw_surface_part(surface_id, chart_view_left, 0, chart_view_width, chart_view_height, chart_view_left, 0);
gpu_set_blendmode(bm_normal);
draw_flush();
gpu_pop_state();
