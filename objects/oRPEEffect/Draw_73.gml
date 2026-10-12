///@desc 全屏着色已经跑完后，让录像器抓取呈现帧
// 区间哨兵不负责抓帧。
if (variable_instance_exists(id, "effect_boundary_role")) then exit;
var _transition_allows_shaders = true;
if (instance_exists(oPlayTransition)) {
	var _transition = instance_find(oPlayTransition, 0);
	_transition_allows_shaders = (_transition.state == PLAY_TRANSITION_STATE.PLAYING);
};
// 全屏着色器已经在谱面表面上。oChartMask 会在本事件之前贴回，这里不再着色。
// 等全局内置和外部着色器都合成完再抓帧。
if (variable_global_exists("render_mode") && global.render_mode
	&& instance_exists(oVideoRenderer)) {
	pls_draw_flush();
	with (oVideoRenderer) event_user(0);
};
