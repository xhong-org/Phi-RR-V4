// 清理：解绑绘制目标，释放谱面合成表面并清掉裁剪
if (target_active) {
	surface_reset_target();
	target_active = false;
};
chart_surface_active = false;
if (surface_exists(surface_id)) surface_free(surface_id);
surface_id = -1;
chart_mask_scissor_clear();
