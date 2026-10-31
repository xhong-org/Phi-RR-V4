///@desc 判断当前是否处于游玩或渲染
///@returns {Bool} 渲染模式或渲染对象存在时为真
function display_playing() {
	if (variable_global_exists("render_mode") && global.render_mode) then return true;
	return instance_exists(oRender) || instance_exists(oRender_1) || instance_exists(oRender_2);
}

///@desc Android 帧率上限跟随当前分辨率支持的最高刷新率，录像仍按导出设置计时
function display_android_update(force = false) {
	if (os_type != os_android) then return;
	if (variable_global_exists("render_mode") && global.render_mode) then return;
	static next_check = 0;
	static applied_target = 0;
	var now = get_timer();
	if (!force && now < next_check) then return;
	next_check = now + 1000000;
	// 当前刷新率可能已被 Runtime 的 60 FPS 目标降下来，不能直接用它作上限。
	var rate = extension_exists("I_AndroidTouch") ? i_android_display_refresh_rate() : 0;
	if (!is_real(rate) || !is_finite(rate) || rate <= 0) then rate = display_get_frequency();
	if (!is_real(rate) || !is_finite(rate) || rate <= 0) then rate = 60;
	var target = max(1, round(rate));
	// Android 的 game_get_speed 可能读回实际帧节奏，不能据此反复重置帧计时器。
	if (force || applied_target != target) {
		game_set_speed(target, gamespeed_fps);
		applied_target = target;
		print($"[Display] Android FPS limit: {target}");
	};
}

///@desc 按平台设置帧同步方式和垂直同步
///@param {Real} aa 抗锯齿级别
///@param {Bool} enable_vsync 是否开启垂直同步
///@returns {Undefined} 无
function display_custom(aa, enable_vsync) {
	if (pls_is_html5()) then return;
	display_android_update(true);
	try {
		if (display_playing()) {
			// 判定需要精确帧节奏，剩余时间用忙等消掉。
			display_set_timing_method(tm_systemtiming);
		} else {
			display_set_timing_method(tm_sleep);
			display_set_sleep_margin(1);
		};
		// Android 支持 Runtime 的帧同步开关，但 SetMultiSample 是空实现。
		if (os_type != os_ios) then display_reset(os_type == os_android ? 0 : aa, enable_vsync);
	} catch (display_err) {
		delete(display_err);
	};
}

///@desc 菜单和加载界面使用睡眠等待；Android 跟随设备刷新率，其余平台使用 60 帧
///@returns {Undefined} 无
function display_ui_apply() {
	// 网页端不改帧率和垂直同步
	if (pls_is_html5()) then return;
	var s = settings_store();
	if (os_type != os_android) then game_set_speed(60, gamespeed_fps);
	display_custom(0, bool(s.enableVsync ?? true));
}
