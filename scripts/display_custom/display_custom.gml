function display_custom(aa , enable_vsync){
	if (pls_is_html5()) then return;
	display_set_timing_method(tm_systemtiming);
	//game_set_speed(60 , gamespeed_fps);
	display_reset(aa , enable_vsync);
};