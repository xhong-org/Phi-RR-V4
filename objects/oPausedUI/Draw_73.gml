///@desc 谱面贴回之后，在应用表面绘制暂停菜单
// 不用 GUI。普通绘制会画进谱面表面，遮罩覆盖会盖掉之后画到后缓冲的内容。
// 版本号和帧率放在这次贴回之后。全屏着色器已经结束，遮罩也盖不到这层。
chart_hud_draw_overlay();
if (!variable_instance_exists(id, "paused_ui_draw")) then exit;
if (!variable_global_exists("game") || !is_struct(game)) then exit;
// 没暂停也没在重试倒计时就不画。
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
