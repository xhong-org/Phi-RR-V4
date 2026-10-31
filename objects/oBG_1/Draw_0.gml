///@desc 绘制：把背景画进当前激活的谱面表面
// 只有谱面合成表面正在作为绘制目标时才画，并在结束后恢复颜色和透明度。
if (variable_global_exists("chart_surface_active") && chart_surface_active) {
	// 普通绘制开始前，运行时仍会写入房间黑底；退场在这里重置透明底。
	// 曲绘留在外层，只让黑底、判定线、音符和视频参与横向压缩。
	if (instance_exists(oPlayTransition) && instance_find(oPlayTransition, 0).state == PLAY_TRANSITION_STATE.OUTRO) {
		draw_clear_alpha(c_black, chart_background_dim_alpha());
		gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
		exit;
	};
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
