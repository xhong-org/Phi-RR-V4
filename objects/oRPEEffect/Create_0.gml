/// @description RPE extra.json post-processing controller.
if (variable_instance_exists(id, "effect_boundary_role")) {
	depth = real(effect_boundary_depth);
	exit;
};
depth = DEPTH.DEBUG + 1;
if (!variable_instance_exists(id, "effects_local") || !is_array(effects_local)) then effects_local = [];
if (!variable_instance_exists(id, "effects_global") || !is_array(effects_global)) then effects_global = [];
fx_ping = -1;
fx_pong = -1;
chart_time = 0;
effect_caller_target = -1;
effect_boundaries_initialized = false;
external_hlsl_ready = false;
external_hlsl_handles = {};
external_hlsl_uniforms = {};
builtin_native_handles = {};
builtin_native_uniforms = {};
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
		var external_init_status = rpe_ext_initialize(
			d3d_info[? "video_d3d11_device"],
			d3d_info[? "video_d3d11_context"]);
		print($"[RPE Effect] External native status: init={external_init_status}, state={rpe_ext_state()}");
		external_hlsl_ready = external_init_status == 3;
		if (external_hlsl_ready) then print("[RPE Effect] External D3D11 backend initialized");
		else print($"[RPE Effect] External D3D11 backend init failed: {rpe_ext_get_error()}");
	};
} else if (os_type == os_android && external_extension_found) {
	var android_init_status = rpe_ext_initialize(pointer_null, pointer_null);
	print($"[RPE Effect] External GLES status: init={android_init_status}, state={rpe_ext_state()}");
	external_hlsl_ready = android_init_status == 3;
	if (external_hlsl_ready) then print("[RPE Effect] External GLES backend initialized");
	else print($"[RPE Effect] External GLES backend init failed: {rpe_ext_get_error()}");
} else if (pls_is_gxgames()) {
	var gx_init_status = rpe_ext_initialize(pointer_null, pointer_null);
	print($"[RPE Effect] External GX status: init={gx_init_status}, state={rpe_ext_state()}");
	external_hlsl_ready = gx_init_status == 3;
	if (external_hlsl_ready) then print("[RPE Effect] External GX WebGL backend initialized");
	else print($"[RPE Effect] External GX backend waiting; Step will retry ping ({rpe_ext_get_error()})");
};

external_uniforms_parse = function(source) {
	var result = {};
	var source_lines = string_split(source, "\n");
	for (var source_line_i = 0; source_line_i < array_length(source_lines); source_line_i++) {
		var source_line = string_trim(source_lines[source_line_i]);
		if (string_pos("(", source_line) > 0) then continue;
		var is_uniform = (string_pos("uniform ", source_line) == 1);
		var is_hlsl_global = (string_pos("float ", source_line) == 1
			|| string_pos("float2 ", source_line) == 1
			|| string_pos("float3 ", source_line) == 1
			|| string_pos("float4 ", source_line) == 1
			|| string_pos("vec2 ", source_line) == 1
			|| string_pos("vec3 ", source_line) == 1
			|| string_pos("vec4 ", source_line) == 1);
		if (!is_uniform && !is_hlsl_global) then continue;
		var declaration = string_replace_all(source_line, ";", "");
		declaration = string_replace(declaration, "uniform ", "");
		declaration = string_replace(declaration, "static ", "");
		var register_pos = string_pos(":", declaration);
		if (register_pos > 0) then declaration = string_trim(string_copy(declaration, 1, register_pos - 1));
		var declaration_parts_raw = string_split(declaration, " ");
		var declaration_parts = [];
		for (var declaration_part_i = 0; declaration_part_i < array_length(declaration_parts_raw); declaration_part_i++) {
			var declaration_part = string_trim(declaration_parts_raw[declaration_part_i]);
			if (string_length(declaration_part)
				&& declaration_part != "highp"
				&& declaration_part != "mediump"
				&& declaration_part != "lowp") {
				array_add(declaration_parts, declaration_part);
			};
		};
		if (array_length(declaration_parts) < 2) then continue;
		var uniform_type = string_trim(declaration_parts[0]);
		var uniform_name = string_trim(declaration_parts[1]);
		if (!string_length(uniform_name)) then continue;
		if (uniform_type == "sampler2D" || uniform_type == "Texture2D" || uniform_type == "SamplerState") then continue;
		var component_count = 1;
		if (uniform_type == "vec2" || uniform_type == "float2") then component_count = 2;
		else if (uniform_type == "vec3" || uniform_type == "float3") then component_count = 3;
		else if (uniform_type == "vec4" || uniform_type == "float4") then component_count = 4;
		else if (uniform_type != "float") then continue;
		result[$ uniform_name] = component_count;
	};
	return result;
};
effect_compile_externals = function() {
	var compile_pass_count = 0;
	var compile_lists = [effects_local, effects_global];
	for (var external_list_i = 0; external_list_i < array_length(compile_lists); external_list_i++) {
		var external_list = compile_lists[external_list_i];
		for (var external_i = 0; external_i < array_length(external_list); external_i++) {
			var external_pass = external_list[external_i];
			var external_is_hlsl = bool(external_pass[$ "externalHlsl"] ?? false);
			var external_is_glsl = bool(external_pass[$ "externalGlsl"] ?? false);
			if (!external_is_hlsl && !external_is_glsl) then continue;
			compile_pass_count++;
			if (real(external_pass[$ "externalHandle"] ?? -1) > 0) then continue;
			external_pass.externalHandle = -1;
			external_pass.externalUniforms = {};
			if (!external_hlsl_ready) {
				print($"[RPE Effect] External pass skipped; backend unavailable: {external_pass.shaderName}");
				continue;
			};
			var external_relative = string_delete(external_pass.shaderName, 1, 6);
			if (struct_exists(external_hlsl_handles, external_relative)) {
				external_pass.externalHandle = external_hlsl_handles[$ external_relative];
				external_pass.externalUniforms = external_hlsl_uniforms[$ external_relative];
				continue;
			};
			var external_full_path = chart_extra_asset_path(external_relative);
			if (!chart_file_exists_any(external_full_path)) {
				print($"[RPE Effect] External shader file missing: {external_full_path}");
				continue;
			};
			var external_source = chart_read_text_file(external_full_path, -1);
			if (!is_string(external_source) || !string_length(external_source)) {
				var external_file = file_text_open_read(chart_file_readable_path(external_full_path));
				if (is_undefined(external_file) || external_file < 0) {
					print($"[RPE Effect] External shader open failed: {external_full_path}");
					continue;
				};
				external_source = "";
				while (!file_text_eof(external_file)) external_source += file_text_readln(external_file) + "\n";
				file_text_close(external_file);
			};
			if (!is_string(external_source) || !string_length(external_source)) {
				print($"[RPE Effect] External shader empty: {external_full_path}");
				continue;
			};
			external_pass.externalUniforms = external_uniforms_parse(external_source);
			if (external_is_glsl || rpe_ext_shader_android()) {
				external_source = rpe_ext_translate(external_source, external_relative);
				if (!string_length(external_source)) {
					print($"[RPE Effect] Shader translate failed ({external_relative}): {rpe_ext_get_error()}");
					continue;
				};
				var translated_uniforms = external_uniforms_parse(external_source);
				var translated_names = struct_get_names(translated_uniforms);
				for (var translated_i = 0; translated_i < array_length(translated_names); translated_i++) {
					var translated_name = translated_names[translated_i];
					external_pass.externalUniforms[$ translated_name] = translated_uniforms[$ translated_name];
				};
				if (rpe_ext_shader_gx()) {
					print($"[RPE Effect] GLSL queued for WebGL: {external_relative}");
				} else if (rpe_ext_shader_android()) {
					print($"[RPE Effect] {(external_is_hlsl ? "HLSL->GLSL ES" : "GLSL ES")} ready: {external_relative} -> {string_length(external_source)} chars");
				} else {
					print($"[RPE Effect] GLSL translated: {external_relative} -> {string_length(external_source)} HLSL chars");
				};
			};
			var external_handle = rpe_ext_compile(external_source, external_relative);
			if (external_handle <= 0) {
				print($"[RPE Effect] Shader compile failed ({external_relative}): {rpe_ext_get_error()}");
				continue;
			};
			external_hlsl_handles[$ external_relative] = external_handle;
			external_hlsl_uniforms[$ external_relative] = external_pass.externalUniforms;
			external_pass.externalHandle = external_handle;
			print($"[RPE Effect] {(rpe_ext_shader_gx() ? "GX GLSL" : (rpe_ext_shader_android() ? "GLSL ES" : "HLSL"))} compiled: {external_relative}, handle={external_handle}");
		};
	};
	print($"[RPE Effect] External pass summary: passes={compile_pass_count}, compiled={array_length(struct_get_names(external_hlsl_handles))}");
};
effect_compile_externals();

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
	} else if (shader_asset != -1) {
		print($"[RPE Effect] Built-in shader failed to compile: {effect_name}");
	};
	effect_uniforms[$ effect_name] = handles;
	if (os_type == os_android && external_hlsl_ready) {
		var builtin_source = rpe_effect_builtin_glsl(effect_name);
		if (string_length(builtin_source)) {
			var builtin_uniforms = external_uniforms_parse(builtin_source);
			builtin_source = rpe_ext_translate(builtin_source, effect_name);
			if (!string_length(builtin_source)) {
				print($"[RPE Effect] Built-in GLSL ES prepare failed ({effect_name}): {rpe_ext_get_error()}");
			} else {
				var builtin_handle = rpe_ext_compile(builtin_source, "builtin:" + effect_name);
				if (builtin_handle <= 0) {
					print($"[RPE Effect] Built-in GLSL ES compile failed ({effect_name}): {rpe_ext_get_error()}");
				} else {
					builtin_native_handles[$ effect_name] = builtin_handle;
					builtin_native_uniforms[$ effect_name] = builtin_uniforms;
					print($"[RPE Effect] Built-in GLSL ES compiled: {effect_name}, handle={builtin_handle}");
				};
			};
		};
	};
};

effect_surfaces_ensure = function() {
	if (!surface_exists(application_surface)) then return false;
	var width = surface_get_width(application_surface);
	var height = surface_get_height(application_surface);
	if (!surface_exists(fx_ping) || abs(surface_get_width(fx_ping) - width) > 2 || abs(surface_get_height(fx_ping) - height) > 2) {
		if (surface_exists(fx_ping)) then surface_free(fx_ping);
		fx_ping = surface_create(width, height);
	};
	if (!surface_exists(fx_pong) || abs(surface_get_width(fx_pong) - width) > 2 || abs(surface_get_height(fx_pong) - height) > 2) {
		if (surface_exists(fx_pong)) then surface_free(fx_pong);
		fx_pong = surface_create(width, height);
	};
	return surface_exists(fx_ping) && surface_exists(fx_pong);
};

effect_render = function(effect_list, input_override = -1) {
	if (!is_array(effect_list) || array_length(effect_list) <= 0) then return;
	var active = [];
	for (var active_i = 0; active_i < array_length(effect_list); active_i++) {
		var active_effect = effect_list[active_i];
		if (chart_time >= active_effect.startTime && chart_time < active_effect.endTime) array_add(active, active_effect);
	};
	if (array_length(active) <= 0) then return;
	if (!effect_surfaces_ensure()) then return;

	// Effects can run while oChartMask owns a render target. Reading from the
	// application surface in that state replaces the in-progress chart with
	// the previous frame, which makes lines/notes/UI disappear.
	// GML closures resolve instance variables, not local variables from the
	// enclosing function. Keep the target on this controller for the restore
	// callback below.
	effect_caller_target = surface_get_target();
	var input_surface = surface_exists(input_override) ? input_override : application_surface;
	if (!surface_exists(input_override)
		&& variable_global_exists("chart_surface_active") && chart_surface_active
		&& instance_exists(oChartMask)) {
		var chart_mask = instance_find(oChartMask, 0);
		if (surface_exists(chart_mask.surface_id)) then input_surface = chart_mask.surface_id;
	};
	var restore_caller_target = function() {
		surface_reset_target();
		if (surface_exists(effect_caller_target)) then surface_set_target(effect_caller_target);
	};

	var previous_colour = draw_get_colour();
	var previous_alpha = draw_get_alpha();
	draw_set_colour(c_white);
	draw_set_alpha(1);
	gpu_push_state();
	gpu_set_blendmode_ext(bm_one, bm_zero);
	// Finish the caller's batch before changing the render target.
	pls_draw_flush();
	if (surface_exists(effect_caller_target)) then surface_reset_target();
	surface_set_target(fx_ping);
	draw_clear_alpha(c_black, 0);
	// The sides of the aspect-masked room are outside the effective chart.
	// Keep them transparent so built-in shaders never process or overwrite
	// pixels outside the chart viewport.
	var effect_left = 0;
	var effect_width = surface_get_width(input_surface);
	var effect_height = surface_get_height(input_surface);
	if (variable_global_exists("chart_view_left") && variable_global_exists("chart_view_width")) {
		effect_left = clamp(floor(chart_view_left), 0, effect_width);
		effect_width = clamp(ceil(chart_view_width), 0, effect_width - effect_left);
		effect_height = clamp(ceil(chart_view_height), 0, surface_get_height(input_surface));
	};
	draw_surface_part(input_surface, effect_left, 0, effect_width, effect_height, effect_left, 0);
	pls_draw_flush();
	if (rpe_ext_shader_gx()) {
		try { draw_flush(); } catch (gx_flush_error) { delete(gx_flush_error); };
	};
	restore_caller_target();

	var source_surface = fx_ping;
	var target_surface = fx_pong;
	for (var pass_i = 0; pass_i < array_length(active); pass_i++) {
		var pass = active[pass_i];
		var is_external = bool(pass[$ "externalHlsl"] ?? false) || bool(pass[$ "externalGlsl"] ?? false);
		var external_handle = is_external ? real(pass[$ "externalHandle"] ?? -1) : -1;
		var external_uniforms = is_external ? pass.externalUniforms : {};
		if (!is_external && os_type == os_android) {
			external_handle = real(builtin_native_handles[$ pass.shaderName] ?? -1);
			if (struct_exists(builtin_native_uniforms, pass.shaderName)) {
				external_uniforms = builtin_native_uniforms[$ pass.shaderName];
			};
		};
		if (is_external || external_handle > 0) {
			if (external_handle <= 0) then continue;
			var external_draw_key = $"{pass.shaderName}@{pass.startTime}";
			pls_draw_flush();
			var external_uniform_total = 0;
			var external_uniform_success = 0;
			if (struct_exists(external_uniforms, "time")) {
				external_uniform_total++;
				external_uniform_success += bool(rpe_ext_set_uniform_component(external_handle, "time", 0, chart_time));
			};
			if (struct_exists(external_uniforms, "screenSize")) {
				external_uniform_total += 2;
				external_uniform_success += bool(rpe_ext_set_uniform_component(external_handle, "screenSize", 0, surface_get_width(source_surface)));
				external_uniform_success += bool(rpe_ext_set_uniform_component(external_handle, "screenSize", 1, surface_get_height(source_surface)));
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
					external_uniform_success += bool(rpe_ext_set_uniform_component(external_handle, external_name, 0, external_value));
				} else if (external_animation.kind == 2) {
					external_uniform_total += 2;
					external_uniform_success += bool(rpe_ext_set_uniform_component(external_handle, external_name, 0, external_value[0]));
					external_uniform_success += bool(rpe_ext_set_uniform_component(external_handle, external_name, 1, external_value[1]));
				} else if (external_animation.kind == 4) {
					for (var external_component = 0; external_component < 4; external_component++) {
						external_uniform_total++;
						external_uniform_success += bool(rpe_ext_set_uniform_component(external_handle, external_name,
							external_component, external_value[external_component]));
					};
				};
			};
			pls_draw_flush();
			if (surface_exists(effect_caller_target)) then surface_reset_target();
			var external_begin_status = 0;
			var external_uvs;
			if (os_type == os_android || rpe_ext_shader_gx()) {
				// Read the source framebuffer directly. Sampling a GM surface
				// texture while it is still an FBO attachment returns black on
				// Mali, and GX WebGL needs the same copyTex capture.
				surface_set_target(source_surface);
				pls_draw_flush();
				external_begin_status = rpe_ext_begin(external_handle);
				surface_reset_target();
				surface_set_target(target_surface);
				draw_clear_alpha(c_black, 0);
				pls_draw_flush();
				var external_target_width = max(surface_get_width(target_surface), 1);
				var external_target_height = max(surface_get_height(target_surface), 1);
				external_uvs = [
					effect_left / external_target_width,
					0,
					(effect_left + effect_width) / external_target_width,
					effect_height / external_target_height
				];
			} else {
				surface_set_target(target_surface);
				draw_clear_alpha(c_black, 0);
				draw_surface_part(source_surface, effect_left, 0, effect_width, effect_height, effect_left, 0);
				pls_draw_flush();
				external_begin_status = rpe_ext_begin(external_handle);
				external_uvs = texture_get_uvs(surface_get_texture(source_surface));
			};
			if (external_begin_status <= 0) {
				if (!struct_exists(external_draw_logged, external_draw_key)) {
					print($"[RPE Effect] External begin failed: shader={pass.shaderName}, status={external_begin_status}, error={rpe_ext_get_error()}");
					external_draw_logged[$ external_draw_key] = true;
				};
				restore_caller_target();
				continue;
			};
			var external_draw_status = rpe_ext_draw(external_handle,
				external_uvs[0], external_uvs[1], external_uvs[2], external_uvs[3]);
			var external_end_status = rpe_ext_end();
			if (!struct_exists(external_draw_logged, external_draw_key)) {
				print($"[RPE Effect] External direct draw: shader={pass.shaderName}, begin={external_begin_status}, draw={external_draw_status}, end={external_end_status}, uniforms={external_uniform_success}/{external_uniform_total}, time={chart_time}, vars={json_stringify(external_sampled_values)}, surface={surface_get_width(source_surface)}x{surface_get_height(source_surface)}, target={rpe_ext_target_width()}x{rpe_ext_target_height()}, uv={external_uvs[0]},{external_uvs[1]},{external_uvs[2]},{external_uvs[3]}, error={rpe_ext_get_error()}");
				external_draw_logged[$ external_draw_key] = true;
			};
			restore_caller_target();
			var external_swap = source_surface;
			source_surface = target_surface;
			target_surface = external_swap;
			continue;
		};
		var pass_shader = rpe_effect_shader_asset(pass.shaderName);
		if (pass_shader == -1 || !shader_is_compiled(pass_shader)) then continue;
		pls_draw_flush();
		if (surface_exists(effect_caller_target)) then surface_reset_target();
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
		draw_surface_part(source_surface, effect_left, 0, effect_width, effect_height, effect_left, 0);
		// Submit while the intended shader and target are still active.
		pls_draw_flush();
		shader_reset();
			restore_caller_target();
		var swap_surface = source_surface;
		source_surface = target_surface;
		target_surface = swap_surface;
	};
	// A targetRange surface contains only the selected zIndex layers. Replacing
	// the parent target would clear every layer outside that range.
	if (surface_exists(input_override)) then gpu_set_blendmode(bm_normal);
	draw_surface_part(source_surface, effect_left, 0, effect_width, effect_height, effect_left, 0);
	pls_draw_flush();
	shader_reset();
	gpu_pop_state();
	draw_set_colour(previous_colour);
	draw_set_alpha(previous_alpha);
};

effect_boundaries_create = function() {
	if (effect_boundaries_initialized || !variable_global_exists("game_1")
		|| !is_struct(game_1) || !is_array(game_1.line_list)) then return;
	effect_boundaries_initialized = true;
	var ranged = {};
	var unranged = [];
	for (var effect_i = 0; effect_i < array_length(effects_local); effect_i++) {
		var range_effect = effects_local[@ effect_i];
		var range_min = real(range_effect[$ "targetMin"] ?? -infinity);
		var range_max = real(range_effect[$ "targetMax"] ?? infinity);
		if (!is_finite(range_min) || !is_finite(range_max) || range_max <= range_min) {
			array_add(unranged, range_effect);
			continue;
		};
		var range_key = $"{range_min}:{range_max}";
		if (!struct_exists(ranged, range_key)) {
			ranged[$ range_key] = { min:range_min, max:range_max, effects:[] };
		};
		var range_record = ranged[$ range_key];
		array_add(range_record.effects, range_effect);
	};
	effects_local = unranged;
	var range_names = struct_get_names(ranged);
	for (var range_i = 0; range_i < array_length(range_names); range_i++) {
		var range_name = range_names[@ range_i];
		var range = ranged[$ range_name];
		var first_depth = -infinity;
		var last_depth = infinity;
		for (var line_i = 0; line_i < array_length(game_1.line_list); line_i++) {
			var line_instance = game_1.line_list[@ line_i];
			if (!instance_exists(line_instance)) then continue;
			var line_z = real(line_instance.zOrder);
			if (variable_instance_exists(line_instance, "zIndex")
				&& is_real(line_instance.zIndex)) then line_z = real(line_instance.zIndex);
			if (line_z < range.min || line_z >= range.max) then continue;
			first_depth = max(first_depth, line_instance.depth);
			last_depth = min(last_depth, line_instance.depth);
		};
		if (!is_finite(first_depth) || !is_finite(last_depth)) then continue;
		var boundary_state = { surface:-1, active:false };
		var span_bias = (range.max - range.min) * 0.000000001;
		instance_create_depth(0, 0, first_depth + 0.25 + span_bias, oRPEEffect, {
			effect_boundary_role:"start",
			effect_boundary_depth:first_depth + 0.25 + span_bias,
			effect_boundary_state:boundary_state,
			effect_boundary_controller:id,
			effect_boundary_effects:range.effects
		});
		instance_create_depth(0, 0, last_depth - 0.25 - span_bias, oRPEEffect, {
			effect_boundary_role:"end",
			effect_boundary_depth:last_depth - 0.25 - span_bias,
			effect_boundary_state:boundary_state,
			effect_boundary_controller:id,
			effect_boundary_effects:range.effects
		});
	};
};
