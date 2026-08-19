if (target_active) {
	surface_reset_target();
	target_active = false;
};
chart_surface_active = false;
if (surface_exists(surface_id)) surface_free(surface_id);
surface_id = -1;
