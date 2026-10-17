///@desc 版本号和帧率不走 GUI。遮罩贴回会盖掉这一层。
if (!chart_hud_ready()) then exit;
draw_set_valign(fa_top);
draw_set_halign(fa_left);
draw_set_colour(c_white);
draw_set_alpha(1);
if (variable_global_exists("pls_probe_until") && global.pls_probe_until > 0
	&& variable_global_exists("pls_chromatic_front_logged") && global.pls_chromatic_front_logged
	&& !variable_global_exists("pls_chromatic_screen_shot")
	&& surface_exists(application_surface)) {
	global.pls_probe_screen_time = 0;
	with (oRPEEffect) {
		if (!variable_instance_exists(id, "effect_boundary_role")) then global.pls_probe_screen_time = chart_time;
	};
	var _probe_shot_at = 31;
	if (variable_global_exists("pls_probe_shot") && global.pls_probe_shot > 0) then _probe_shot_at = global.pls_probe_shot;
	// 色差探针到点后保存屏幕和遮罩。
	if (global.pls_probe_screen_time >= _probe_shot_at) {
		global.pls_chromatic_screen_shot = true;
		pls_draw_flush();
		var _screen_path = game_save_id + "chromatic_screen.png";
		var _mask_path = game_save_id + "chromatic_mask.png";
		if (instance_exists(oChartMask)) {
			var _mask = instance_find(oChartMask, 0);
			if (surface_exists(_mask.surface_id)) then surface_save(_mask.surface_id, _mask_path);
		};
		screen_save(_screen_path);
		print($"[RPE Probe] screen time={global.pls_probe_screen_time} path={_screen_path}");
	};
};
