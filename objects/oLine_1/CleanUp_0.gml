/// @description Release per-line paint surface. Textures stay on game_1.
if (variable_instance_exists(id, "paint_surface") && surface_exists(paint_surface)) {
	surface_free(paint_surface);
	paint_surface = -1;
};
