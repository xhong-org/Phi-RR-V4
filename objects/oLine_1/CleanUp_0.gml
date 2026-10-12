///@desc 清理：释放这条线自己的涂鸦表面，贴图仍留在 game_1
if (variable_instance_exists(id, "paint_surface") && surface_exists(paint_surface)) {
	surface_free(paint_surface);
	paint_surface = -1;
};
