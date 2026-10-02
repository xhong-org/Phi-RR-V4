/// @description Release post-processing surfaces.
if (variable_instance_exists(id, "effect_boundary_role")) {
	if (effect_boundary_role == "start" && surface_exists(effect_boundary_state.surface)) {
		surface_free(effect_boundary_state.surface);
		effect_boundary_state.surface = -1;
	};
	exit;
};
shader_reset();
if ((extension_exists("I_Shaders") || rpe_ext_shader_gx())
	&& variable_instance_exists(id, "external_hlsl_handles") && is_struct(external_hlsl_handles)) {
	var external_names = struct_get_names(external_hlsl_handles);
	for (var external_i = 0; external_i < array_length(external_names); external_i++) {
		rpe_ext_release(external_hlsl_handles[$ external_names[external_i]]);
	};
	external_hlsl_handles = {};
	if (variable_instance_exists(id, "external_gles_handles") && is_struct(external_gles_handles)) {
		var gles_names = struct_get_names(external_gles_handles);
		for (var gles_i = 0; gles_i < array_length(gles_names); gles_i++) {
			rpe_ext_release(external_gles_handles[$ gles_names[gles_i]]);
		};
		external_gles_handles = {};
	};
	if (variable_instance_exists(id, "builtin_native_handles") && is_struct(builtin_native_handles)) {
		var builtin_names = struct_get_names(builtin_native_handles);
		for (var builtin_i = 0; builtin_i < array_length(builtin_names); builtin_i++) {
			rpe_ext_release(builtin_native_handles[$ builtin_names[builtin_i]]);
		};
		builtin_native_handles = {};
		builtin_native_uniforms = {};
	};
	rpe_ext_shutdown();
};
if (surface_exists(fx_ping)) then surface_free(fx_ping);
if (surface_exists(fx_pong)) then surface_free(fx_pong);
if (variable_instance_exists(id, "fx_sample") && surface_exists(fx_sample)) then surface_free(fx_sample);
if (variable_instance_exists(id, "fx_over") && surface_exists(fx_over)) then surface_free(fx_over);
if (variable_instance_exists(id, "fx_under") && surface_exists(fx_under)) then surface_free(fx_under);
if (variable_instance_exists(id, "fx_compose_buffer") && buffer_exists(fx_compose_buffer)) then buffer_delete(fx_compose_buffer);
fx_ping = -1;
fx_pong = -1;
fx_sample = -1;
fx_over = -1;
fx_under = -1;
fx_compose_buffer = -1;
