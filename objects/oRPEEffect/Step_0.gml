/// @description Track absolute RPE chart seconds.
if (variable_instance_exists(id, "effect_boundary_role")) then exit;
if (pls_is_gxgames() && !external_hlsl_ready && !chart_setting_on("disableChartShader")) {
	if (rpe_ext_initialize(pointer_null, pointer_null) == 3) {
		external_hlsl_ready = true;
		print("[RPE Effect] External GX WebGL backend ready");
		effect_compile_externals();
	};
};
var chart_offset = chart_extra_offset_seconds();
chart_time = max(0, game.__time[1] - chart_offset);
effect_boundaries_create();
if (variable_global_exists("pls_probe_until") && global.pls_probe_until > 0
	&& !(variable_global_exists("pls_probe_exit_sent") && global.pls_probe_exit_sent)) {
	var _probe_front = variable_global_exists("pls_chromatic_front_logged") && global.pls_chromatic_front_logged;
	var _probe_wall = variable_global_exists("pls_probe_t0") && (get_timer() - global.pls_probe_t0) >= 240000000;
	if ((_probe_front && chart_time >= global.pls_probe_until) || chart_time >= global.pls_probe_until + 8 || _probe_wall) {
		global.pls_probe_exit_sent = true;
		print($"[RPE Probe] exit time={chart_time} chromatic_front={_probe_front} wall={_probe_wall}");
		game_end();
	};
};
