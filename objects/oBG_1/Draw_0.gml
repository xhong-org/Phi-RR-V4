/// @description Draw background into the active chart surface.
if (variable_global_exists("chart_surface_active") && chart_surface_active) {
	var _old_colour = draw_get_colour();
	var _old_alpha = draw_get_alpha();
	draw_flush();
	gpu_set_blendmode(bm_normal);
	draw_set_colour(c_white);
	draw_set_alpha(1);
	chart_draw_background(true);
	draw_set_colour(_old_colour);
	draw_set_alpha(_old_alpha);
	gpu_set_blendmode(bm_normal);
};
