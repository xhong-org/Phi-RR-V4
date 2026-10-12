///@desc 绘制：把背景画进当前激活的谱面表面
// 只有谱面合成表面正在作为绘制目标时才画，并在结束后恢复颜色和透明度。
if (variable_global_exists("chart_surface_active") && chart_surface_active) {
	var _old_colour = draw_get_colour();
	var _old_alpha = draw_get_alpha();
	pls_draw_flush();
	gpu_set_blendmode(bm_normal);
	draw_set_colour(c_white);
	draw_set_alpha(1);
	chart_draw_background(true);
	draw_set_colour(_old_colour);
	draw_set_alpha(_old_alpha);
	gpu_set_blendmode(bm_normal);
};
