/// @description Pause menu on the application surface, after the chart blit.
/// Draw GUI is not used. Drawing during Draw lands on the chart surface and the
/// mask replace-blit covers anything drawn to the back buffer after that.
if (!variable_instance_exists(id, "paused_ui_draw")) then exit;
if (!variable_global_exists("game") || !is_struct(game)) then exit;
if (!game.paused && !retry_waiting) {
	draw_logged = false;
	exit;
};
chart_mask_scissor_clear();
shader_reset();
gpu_set_blendmode(bm_normal);
draw_set_colour(c_white);
draw_set_alpha(1);
paused_ui_draw();
