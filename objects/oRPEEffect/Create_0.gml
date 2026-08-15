/// @description RPE extra.json post-processing controller.
depth = DEPTH.DEBUG + 1;
if (!variable_instance_exists(id, "effects_local") || !is_array(effects_local)) then effects_local = [];
if (!variable_instance_exists(id, "effects_global") || !is_array(effects_global)) then effects_global = [];
fx_ping = -1;
fx_pong = -1;
chart_time = 0;
external_hlsl_ready = false;
external_hlsl_handles = {};
external_draw_logged = {};
var external_extension_found = extension_exists("I_Shaders");
print($"[RPE Effect] External backend probe: os={os_type}, windows={os_type == os_windows}, extension={external_extension_found}");
var external_dll_path = working_directory + "I_Shaders.dll";
print($"[RPE Effect] External DLL: exists={file_exists(external_dll_path)}, md5={(file_exists(external_dll_path) ? md5_file(external_dll_path) : "missing")}");

if (os_type == os_windows && external_extension_found) {
	var d3d_info = os_get_info();
	var d3d_info_is_map = ds_exists(d3d_info, ds_type_map);
	var d3d_has_device = d3d_info_is_map && ds_map_exists(d3d_info, "video_d3d11_device");
	var d3d_has_context = d3d_info_is_map && ds_map_exists(d3d_info, "video_d3d11_context");
	print($"[RPE Effect] D3D11 info: map={d3d_info_is_map}, device={d3d_has_device}, context={d3d_has_context}");
	if (d3d_has_device && d3d_has_context) {
		var external_init_status = rpe_hlsl_initialize(
			d3d_info[? "video_d3d11_device"],
			d3d_info[? "video_d3d11_context"]);
		print($"[RPE Effect] External native status: init={external_init_status}, state={rpe_hlsl_state()}");
		external_hlsl_ready = external_init_status == 3;
		if (external_hlsl_ready) then print("[RPE Effect] External D3D11 backend initialized");
		else print($"[RPE Effect] External D3D11 backend init failed: {rpe_hlsl_get_error()}");
	};
};

var external_lists = [effects_local, effects_global];
var external_uniforms_parse = function(source) {
	var result = {};
	var source_lines = string_split(source, "\n");
	for (var source_line_i = 0; source_line_i < array_length(source_lines); source_line_i++) {
		var source_line = string_trim(source_lines[source_line_i]);
		if (string_pos("uniform ", source_line) != 1) then continue;
		var declaration = string_replace_all(source_line, ";", "");
		var declaration_parts_raw = string_split(declaration, " ");
		var declaration_parts = [];
		for (var declaration_part_i = 0; declaration_part_i < array_length(declaration_parts_raw); declaration_part_i++) {
			var declaration_part = string_trim(declaration_parts_raw[declaration_part_i]);
			if (string_length(declaration_part)) then array_add(declaration_parts, declaration_part);
		};
		if (array_length(declaration_parts) < 3) then continue;
		var uniform_type = string_trim(declaration_parts[1]);
		var uniform_name = string_trim(declaration_parts[2]);
		if (!string_length(uniform_name)) then continue;
		if (uniform_type == "sampler2D") then continue;
		var component_count = (uniform_type == "vec2" ? 2 : (uniform_type == "vec4" ? 4 : 1));
		result[$ uniform_name] = component_count;
	};
	return result;
};
var external_pass_count = 0;
for (var external_list_i = 0; external_list_i < array_length(external_lists); external_list_i++) {
	var external_list = external_lists[external_list_i];
	for (var external_i = 0; external_i < array_length(external_list); external_i++) {
		var external_pass = external_list[external_i];
		var external_is_hlsl = bool(external_pass[$ "externalHlsl"] ?? false);
		var external_is_glsl = bool(external_pass[$ "externalGlsl"] ?? false);
		if (!external_is_hlsl && !external_is_glsl) then continue;
		external_pass_count++;
		external_pass.externalHandle = -1;
		external_pass.externalUniforms = {};
		if (!external_hlsl_ready) {
			print($"[RPE Effect] External pass skipped; backend unavailable: {external_pass.shaderName}");
			continue;
		};
		var external_relative = string_delete(external_pass.shaderName, 1, 6);
		if (struct_exists(external_hlsl_handles, external_relative)) {
			external_pass.externalHandle = external_hlsl_handles[$ external_relative];
			continue;
		};
		var external_full_path = chart_extra_asset_path(external_relative);
		if (!file_exists(external_full_path)) {
			print($"[RPE Effect] External shader file missing: {external_full_path}");
			continue;
		};
		var external_file = file_text_open_read(external_full_path);
		if (is_undefined(external_file) || external_file < 0) {
			print($"[RPE Effect] External shader open failed: {external_full_path}");
			continue;
		};
		var external_source = "";
		while (!file_text_eof(external_file)) external_source += file_text_readln(external_file) + "\n";
		file_text_close(external_file);
		if (external_is_glsl) {
			external_pass.externalUniforms = external_uniforms_parse(external_source);
			external_source = rpe_glsl_translate(external_source, external_relative);
			if (!string_length(external_source)) {
				print($"[RPE Effect] GLSL translation failed ({external_relative}): {rpe_hlsl_get_error()}");
				continue;
			};
			print($"[RPE Effect] GLSL translated: {external_relative} -> {string_length(external_source)} HLSL chars");
		};
		var external_handle = rpe_hlsl_compile(external_source, external_relative);
		if (external_handle <= 0) {
			print($"[RPE Effect] HLSL compile failed ({external_relative}): {rpe_hlsl_get_error()}");
			continue;
		};
		external_hlsl_handles[$ external_relative] = external_handle;
		external_pass.externalHandle = external_handle;
		print($"[RPE Effect] HLSL compiled: {external_relative}, handle={external_handle}");
	};
};
print($"[RPE Effect] External pass summary: passes={external_pass_count}, compiled={array_length(struct_get_names(external_hlsl_handles))}");

effect_uniforms = {};
var uniform_names = ["time", "screenSize", "sampleCount", "power", "size", "rate", "speed", "blockCount", "colorRate", "factor", "seed", "centerX", "centerY", "progress", "width", "distortion", "expand", "color", "extend", "radius"];
var effect_names = ["chromatic", "circleBlur", "fisheye", "glitch", "grayscale", "noise", "pixel", "radialBlur", "shockwave", "vignette", "customTint"];
for (var effect_name_i = 0; effect_name_i < array_length(effect_names); effect_name_i++) {
	var effect_name = effect_names[effect_name_i];
	var shader_asset = rpe_effect_shader_asset(effect_name);
	var handles = {};
	if (shader_asset != -1 && shader_is_compiled(shader_asset)) {
		for (var uniform_i = 0; uniform_i < array_length(uniform_names); uniform_i++) {
			var uniform_name = uniform_names[uniform_i];
			var uniform_handle = shader_get_uniform(shader_asset, uniform_name);
			if (uniform_handle != -1) then handles[$ uniform_name] = uniform_handle;
		};
	};
	effect_uniforms[$ effect_name] = handles;
};

effect_surfaces_ensure = function() {
	if (!surface_exists(application_surface)) then return false;
	var width = surface_get_width(application_surface);
	var height = surface_get_height(application_surface);
	if (!surface_exists(fx_ping) || surface_get_width(fx_ping) != width || surface_get_height(fx_ping) != height) {
		if (surface_exists(fx_ping)) then surface_free(fx_ping);
		fx_ping = surface_create(width, height);
	};
	if (!surface_exists(fx_pong) || surface_get_width(fx_pong) != width || surface_get_height(fx_pong) != height) {
		if (surface_exists(fx_pong)) then surface_free(fx_pong);
		fx_pong = surface_create(width, height);
	};
	return surface_exists(fx_ping) && surface_exists(fx_pong);
};

effect_render = function(effect_list) {
	if (!is_array(effect_list) || array_length(effect_list) <= 0) then return;
	var active = [];
	for (var active_i = 0; active_i < array_length(effect_list); active_i++) {
		var active_effect = effect_list[active_i];
		if (chart_time >= active_effect.startTime && chart_time < active_effect.endTime) array_add(active, active_effect);
	};
	if (array_length(active) <= 0) then return;
	if (!effect_surfaces_ensure()) then return;

	var previous_colour = draw_get_colour();
	var previous_alpha = draw_get_alpha();
	draw_set_colour(c_white);
	draw_set_alpha(1);
	gpu_push_state();
	gpu_set_blendmode_ext(bm_one, bm_zero);
	// Finish the caller's batch before changing the render target.
	draw_flush();
	surface_set_target(fx_ping);
	draw_clear_alpha(c_black, 0);
	draw_surface(application_surface, 0, 0);
	draw_flush();
	surface_reset_target();

	var source_surface = fx_ping;
	var target_surface = fx_pong;
	for (var pass_i = 0; pass_i < array_length(active); pass_i++) {
		var pass = active[pass_i];
		if (bool(pass[$ "externalHlsl"] ?? false) || bool(pass[$ "externalGlsl"] ?? false)) {
			var external_handle = real(pass[$ "externalHandle"] ?? -1);
			if (external_handle <= 0) then continue;
			draw_flush();
			surface_set_target(target_surface);
			draw_clear_alpha(c_black, 0);
			var external_uniforms = pass.externalUniforms;
			var external_uniform_total = 0;
			var external_uniform_success = 0;
			if (struct_exists(external_uniforms, "time")) {
				external_uniform_total++;
				external_uniform_success += bool(rpe_hlsl_set_uniform_component(external_handle, "time", 0, chart_time));
			};
			if (struct_exists(external_uniforms, "screenSize")) {
				external_uniform_total += 2;
				external_uniform_success += bool(rpe_hlsl_set_uniform_component(external_handle, "screenSize", 0, surface_get_width(source_surface)));
				external_uniform_success += bool(rpe_hlsl_set_uniform_component(external_handle, "screenSize", 1, surface_get_height(source_surface)));
			};
			var external_names = struct_get_names(pass.vars);
			var external_sampled_values = {};
			for (var external_var_i = 0; external_var_i < array_length(external_names); external_var_i++) {
				var external_name = external_names[external_var_i];
				var external_animation = pass.vars[$ external_name];
				var external_value = rpe_effect_sample_anim(external_animation, chart_time);
				external_sampled_values[$ external_name] = external_value;
				if (!struct_exists(external_uniforms, external_name)) then continue;
				if (external_animation.kind == 1) {
					external_uniform_total++;
					external_uniform_success += bool(rpe_hlsl_set_uniform_component(external_handle, external_name, 0, external_value));
				} else if (external_animation.kind == 2) {
					external_uniform_total += 2;
					external_uniform_success += bool(rpe_hlsl_set_uniform_component(external_handle, external_name, 0, external_value[0]));
					external_uniform_success += bool(rpe_hlsl_set_uniform_component(external_handle, external_name, 1, external_value[1]));
				} else if (external_animation.kind == 4) {
					for (var external_component = 0; external_component < 4; external_component++) {
						external_uniform_total++;
						external_uniform_success += bool(rpe_hlsl_set_uniform_component(external_handle, external_name,
							external_component, external_value[external_component]));
					};
				};
			};
			draw_surface(source_surface, 0, 0);
			draw_flush();
			// Set uniforms before begin: begin uploads the native constant buffer.
			// Setting them afterward leaves the GPU with the previous pass values.
			var external_begin_status = rpe_hlsl_begin(external_handle);
			if (external_begin_status < 0) {
				if (!struct_exists(external_draw_logged, pass.shaderName)) {
					print($"[RPE Effect] External begin failed: shader={pass.shaderName}, status={external_begin_status}, error={rpe_hlsl_get_error()}");
					external_draw_logged[$ pass.shaderName] = true;
				};
				surface_reset_target();
				continue;
			};
			var external_uvs = texture_get_uvs(surface_get_texture(source_surface));
			var external_draw_status = rpe_hlsl_draw(external_handle,
				external_uvs[0], external_uvs[1], external_uvs[2], external_uvs[3]);
			var external_end_status = rpe_hlsl_end();
			if (!struct_exists(external_draw_logged, pass.shaderName)) {
				print($"[RPE Effect] External direct draw: shader={pass.shaderName}, begin={external_begin_status}, draw={external_draw_status}, end={external_end_status}, uniforms={external_uniform_success}/{external_uniform_total}, time={chart_time}, vars={json_stringify(external_sampled_values)}, surface={surface_get_width(source_surface)}x{surface_get_height(source_surface)}, target={rpe_hlsl_target_width()}x{rpe_hlsl_target_height()}, uv={external_uvs[0]},{external_uvs[1]},{external_uvs[2]},{external_uvs[3]}");
				external_draw_logged[$ pass.shaderName] = true;
			};
			surface_reset_target();
			var external_swap = source_surface;
			source_surface = target_surface;
			target_surface = external_swap;
			continue;
		};
		var pass_shader = rpe_effect_shader_asset(pass.shaderName);
		if (pass_shader == -1 || !shader_is_compiled(pass_shader)) then continue;
		draw_flush();
		surface_set_target(target_surface);
		draw_clear_alpha(c_black, 0);
		shader_set(pass_shader);
		var handles = effect_uniforms[$ pass.shaderName];
		if (struct_exists(handles, "time")) then shader_set_uniform_f(handles.time, chart_time);
		if (struct_exists(handles, "screenSize")) then shader_set_uniform_f(handles.screenSize, surface_get_width(source_surface), surface_get_height(source_surface));
		var variable_names = struct_get_names(pass.vars);
		for (var variable_i = 0; variable_i < array_length(variable_names); variable_i++) {
			var variable_name = variable_names[variable_i];
			if (!struct_exists(handles, variable_name)) then continue;
			var animation = pass.vars[$ variable_name];
			var value = rpe_effect_sample_anim(animation, chart_time);
			var handle = handles[$ variable_name];
			if (animation.kind == 1) then shader_set_uniform_f(handle, value);
			else if (animation.kind == 2) then shader_set_uniform_f(handle, value[0], value[1]);
			else if (animation.kind == 4) then shader_set_uniform_f(handle, value[0], value[1], value[2], value[3]);
		};
		draw_surface(source_surface, 0, 0);
		// Submit while the intended shader and target are still active.
		draw_flush();
		shader_reset();
		surface_reset_target();
		var swap_surface = source_surface;
		source_surface = target_surface;
		target_surface = swap_surface;
	};
	draw_surface(source_surface, 0, 0);
	draw_flush();
	shader_reset();
	gpu_pop_state();
	draw_set_colour(previous_colour);
	draw_set_alpha(previous_alpha);
};
