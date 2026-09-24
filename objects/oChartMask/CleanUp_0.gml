if (target_active) {
	surface_reset_target();
	target_active = false;
};
chart_surface_active = false;
if (surface_exists(surface_id)) surface_free(surface_id);
surface_id = -1;
chart_mask_scissor_clear();
if (variable_global_exists("chart_video_mask_surface") && surface_exists(chart_video_mask_surface)) {
	surface_free(chart_video_mask_surface);
	chart_video_mask_surface = -1;
};
