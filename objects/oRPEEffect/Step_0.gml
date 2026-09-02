/// @description Track absolute RPE chart seconds.
if (variable_instance_exists(id, "effect_boundary_role")) then exit;
if (pls_is_gxgames() && !external_hlsl_ready) {
	if (rpe_ext_initialize(pointer_null, pointer_null) == 3) {
		external_hlsl_ready = true;
		print("[RPE Effect] External GX WebGL backend ready");
		effect_compile_externals();
	};
};
var chart_offset = chart_extra_offset_seconds();
chart_time = max(0, game.__time[1] - chart_offset);
effect_boundaries_create();
