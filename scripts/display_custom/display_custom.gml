function display_playing() {
	if (variable_global_exists("render_mode") && global.render_mode) then return true;
	return instance_exists(oRender) || instance_exists(oRender_1) || instance_exists(oRender_2);
}

function display_custom(aa, enable_vsync) {
	if (pls_is_html5()) then return;
	if (display_playing()) {
		// Precise frame pacing for judgment. This busy-waits leftover time.
		display_set_timing_method(tm_systemtiming);
	} else {
		display_set_timing_method(tm_sleep);
		display_set_sleep_margin(1);
	};
	display_reset(aa, enable_vsync);
}

/// Menu / loader: 60fps, sleep instead of spin, no MSAA.
function display_ui_apply() {
	if (pls_is_html5()) then return;
	var s = settings_store();
	game_set_speed(60, gamespeed_fps);
	display_custom(0, bool(s.enableVsync ?? true));
}