/// @description Release post-processing surfaces.
shader_reset();
if (extension_exists("I_Shaders")
	&& variable_instance_exists(id, "external_hlsl_handles") && is_struct(external_hlsl_handles)) {
	var external_names = struct_get_names(external_hlsl_handles);
	for (var external_i = 0; external_i < array_length(external_names); external_i++) {
		rpe_hlsl_release(external_hlsl_handles[$ external_names[external_i]]);
	};
	external_hlsl_handles = {};
	rpe_hlsl_shutdown();
};
if (surface_exists(fx_ping)) then surface_free(fx_ping);
if (surface_exists(fx_pong)) then surface_free(fx_pong);
fx_ping = -1;
fx_pong = -1;
