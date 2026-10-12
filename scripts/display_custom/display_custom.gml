///@desc 判断当前是否处于游玩或渲染
///@returns {Bool} 渲染模式或渲染对象存在时为真
function display_playing() {
	if (variable_global_exists("render_mode") && global.render_mode) then return true;
	return instance_exists(oRender) || instance_exists(oRender_1) || instance_exists(oRender_2);
}

///@desc 按平台设置帧同步方式和垂直同步
///@param {Real} aa 抗锯齿级别
///@param {Bool} enable_vsync 是否开启垂直同步
///@returns {Undefined} 无
function display_custom(aa, enable_vsync) {
	if (pls_is_html5()) then return;
	// display_reset 只适用于桌面。安卓上调用会中断设置保存，面板走不到 instance_destroy。
	var can_reset = (os_type != os_android && os_type != os_ios);
	try {
		if (display_playing()) {
			// 判定需要精确帧节奏，剩余时间用忙等消掉。
			display_set_timing_method(tm_systemtiming);
		} else {
			display_set_timing_method(tm_sleep);
			display_set_sleep_margin(1);
		};
		if (can_reset) then display_reset(aa, enable_vsync);
	} catch (display_err) {
		delete(display_err);
	};
}

///@desc 菜单和加载界面使用 60 帧、睡眠等待且关闭多重采样
///@returns {Undefined} 无
function display_ui_apply() {
	// 网页端不改帧率和垂直同步
	if (pls_is_html5()) then return;
	var s = settings_store();
	game_set_speed(60, gamespeed_fps);
	display_custom(0, bool(s.enableVsync ?? true));
}