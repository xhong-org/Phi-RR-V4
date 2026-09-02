/// @description Start chart composition.
if (!application_surface_is_enabled() || !surface_exists(application_surface)) then exit;
chart_view_refresh(room_width, room_height);
if (!chart_mask_surface_ensure()) then exit;
pls_draw_flush();
gpu_push_state();
surface_set_target(surface_id);
target_active = true;
chart_surface_active = true;
gpu_set_blendmode(bm_normal);
draw_set_colour(c_white);
draw_set_alpha(1);
draw_clear_alpha(c_black, 0);
