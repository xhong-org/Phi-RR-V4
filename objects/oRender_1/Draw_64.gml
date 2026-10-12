///@desc 在谱面遮罩之上绘制帧率、版本和探针截图
// HUD 还没准备好就不画。
if (!chart_hud_ready()) then exit;
shader_reset();
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_font(game.font);
draw_set_valign(fa_center);
if (chart_fps_draw_allowed()) then event_user(_draw_fps_user_count);
draw_set_colour(c_gray);
draw_set_halign(fa_left);
if (!(variable_global_exists("render_mode") && global.render_mode)) {
	draw_text_transformed(chart_view_left + 5 * global_scales, room_height - (10 * global_scales), chart_version_label(), 0.3 * global_scales, 0.3 * global_scales, 0);
}
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
