/// @description RPE extra.json post-processing controller.
if (variable_instance_exists(id, "effect_boundary_role")) {
	depth = real(effect_boundary_depth);
	exit;
};
// Global grades must run after every z-range has composited back.
depth = chart_layer_depth(64);
if (!variable_instance_exists(id, "effects_local") || !is_array(effects_local)) then effects_local = [];
if (!variable_instance_exists(id, "effects_global") || !is_array(effects_global)) then effects_global = [];
fx_ping = -1;
fx_pong = -1;
fx_sample = -1;
fx_over = -1;
fx_under = -1;
fx_copy_hold = -1;
fx_compose_buffer = -1;
fx_under_sampler = -1;
// Outermost entry is the chart mask. Nested ranges must composite onto the
// previous capture, not whatever surface_get_target reports after a reset.
effect_capture_stack = [];
chart_time = 0;
effect_caller_target = -1;
effect_entry_target = -1;
effect_entry_released = false;
effect_caller_pushed = false;
effect_caller_was_bound = false;
effect_left_caller_bound = false;
effect_boundaries_initialized = false;
external_hlsl_ready = false;
external_hlsl_handles = {};
external_gles_handles = {};
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
		if (external_hlsl_ready) {
			var direct_glsl_ready = ((rpe_ext_state() - 202607257) & 4) != 0;
			print($"[RPE Effect] External D3D11 backend initialized; direct GLSL ES={(direct_glsl_ready ? "ready" : "unavailable")}");
		} else print($"[RPE Effect] External D3D11 backend init failed: {rpe_ext_get_error()}");
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
		// `uniform float factor;// %1.0%` has no space before the comment, so the
		// name would otherwise become "factor//" and never match the chart var.
		var comment_pos = string_pos("//", source_line);
		if (comment_pos > 0) then source_line = string_trim(string_copy(source_line, 1, comment_pos - 1));
		if (!string_length(source_line)) then continue;
		// YoYo's HLSL writes `uniform float _factor : register(c3);`. The '(' used
		// to skip the whole declaration, so the animated value never uploaded.
		var register_pos = string_pos(":", source_line);
		if (register_pos > 0) then source_line = string_trim(string_copy(source_line, 1, register_pos - 1));
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
		// Translated HLSL prefixes user uniforms with '_'. Chart vars keep the GLSL name.
		if (string_char_at(uniform_name, 1) == "_" && string_length(uniform_name) > 1
			&& string_copy(uniform_name, 1, 4) != "_gm_") {
			var unprefixed = string_delete(uniform_name, 1, 1);
			if (!struct_exists(result, unprefixed)) then result[$ unprefixed] = component_count;
		};
	};
	return result;
};
effect_external_handle = function(pass) {
	var handle = real(pass[$ "externalHandle"] ?? -1);
	if (handle > 0) return handle;
	var translated_handle = real(pass[$ "externalHlslHandle"] ?? -1);
	if (translated_handle > 0) return translated_handle;
	return real(pass[$ "externalGlesHandle"] ?? -1);
};
effect_compile_externals = function() {
	if (chart_setting_on("disableChartShader")) then return;
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
			if (struct_exists(external_hlsl_handles, external_relative) || struct_exists(external_gles_handles, external_relative)) {
				external_pass.externalHlslHandle = real(external_hlsl_handles[$ external_relative] ?? -1);
				external_pass.externalGlesHandle = real(external_gles_handles[$ external_relative] ?? -1);
				external_pass.externalHandle = effect_external_handle(external_pass);
				external_pass.externalUniforms = external_hlsl_uniforms[$ external_relative] ?? {};
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
			// This chart's beam uses uv.y = 0 as the top. The written offset
			// reaches the bottom first, so the two holds vanish upward.
			if (string_pos("scene_beam_transition", external_relative) > 0
				&& string_pos("float y=uv.y;", external_source) > 0) {
				external_source = string_replace(external_source, "float y=uv.y;", "float y=1.0-uv.y;");
				print("[RPE Effect] scene_beam sweeps from the top downward");
			};
			if (string_pos("vignette", string_lower(external_relative)) > 0) {
				external_source = rpe_effect_vignette_screen_falloff(external_source);
			};
			external_pass.externalUniforms = external_uniforms_parse(external_source);
			external_source = rpe_effect_preserve_frag_alpha(external_source);
			external_pass.externalGlesHandle = -1;
			external_pass.externalHlslHandle = -1;
			var use_direct_glsl = external_is_glsl && os_type == os_windows && chart_setting_on("directGlslEs");
			if (use_direct_glsl) {
				var direct_handle = rpe_ext_compile(external_source, external_relative);
				if (direct_handle <= 0) {
					print($"[RPE Effect] GLSL ES direct compile failed ({external_relative}): {rpe_ext_get_error()}");
					continue;
				};
				external_pass.externalGlesHandle = direct_handle;
				external_pass.externalHandle = direct_handle;
				external_gles_handles[$ external_relative] = direct_handle;
				external_hlsl_uniforms[$ external_relative] = external_pass.externalUniforms;
				print($"[RPE Effect] GLSL ES direct compiled: {external_relative}, handle={direct_handle}");
				continue;
			};
			if (external_is_glsl || rpe_ext_shader_android()) {
				external_source = rpe_ext_translate(external_source, external_relative);
				if (!string_length(external_source)) {
					print($"[RPE Effect] Shader translate failed ({external_relative}): {rpe_ext_get_error()}");
					continue;
				};
				var translated_uniforms = external_uniforms_parse(external_source);
				// The translator drops declarations the fragment never reads.
				// CHAOS keeps `uniform float time` on MoveCamera, Bloom and
				// CameraRot, but those shaders do not sample it, so uploading
				// the GLSL declaration fails. Keep the translated set only.
				if (array_length(struct_get_names(translated_uniforms)) > 0) {
					external_pass.externalUniforms = translated_uniforms;
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
			external_pass.externalHlslHandle = external_handle;
			external_hlsl_handles[$ external_relative] = external_handle;
			external_hlsl_uniforms[$ external_relative] = external_pass.externalUniforms;
			external_pass.externalHandle = effect_external_handle(external_pass);
			print($"[RPE Effect] {(rpe_ext_shader_gx() ? "GX GLSL" : (rpe_ext_shader_android() ? "GLSL ES" : "HLSL"))} compiled: {external_relative}, handle={external_handle}");
		};
	};
	print($"[RPE Effect] External pass summary: passes={compile_pass_count}, hlsl={array_length(struct_get_names(external_hlsl_handles))}, direct={array_length(struct_get_names(external_gles_handles))}");
};
effect_compile_externals();

effect_uniforms = {};
var uniform_names = ["time", "screenSize", "sampleCount", "power", "size", "rate", "speed", "blockCount", "colorRate", "factor", "seed", "centerX", "centerY", "progress", "width", "distortion", "expand", "color", "extend", "radius"];
var effect_names = ["chromatic", "circleBlur", "fisheye", "glitch", "grayscale", "noise", "pixel", "radialBlur", "shockwave", "vignette", "customTint"];
if (!chart_setting_on("disableChartShader")) {
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
};
// chromatic_random_rate is drawn with this chart shader. The external replace
// pass was sampling an empty copy and dropping the captured notes and hits.
if (shader_is_compiled(shd_rpe_chromatic_rate)) {
	var chromatic_rate_handles = {};
	var chromatic_rate_names = ["time", "sampleCount", "power", "rate", "speed"];
	for (var chromatic_rate_i = 0; chromatic_rate_i < array_length(chromatic_rate_names); chromatic_rate_i++) {
		var chromatic_rate_name = chromatic_rate_names[chromatic_rate_i];
		var chromatic_rate_handle = shader_get_uniform(shd_rpe_chromatic_rate, chromatic_rate_name);
		if (chromatic_rate_handle != -1) then chromatic_rate_handles[$ chromatic_rate_name] = chromatic_rate_handle;
	};
	effect_uniforms[$ "@glsl:chromatic_random_rate.glsl"] = chromatic_rate_handles;
	print($"[RPE Effect] chromatic_random_rate uses chart shader, uniforms={array_length(struct_get_names(chromatic_rate_handles))}");
} else {
	print("[RPE Effect] chromatic_random_rate chart shader failed to compile");
};
// gate is fullscreen during the early chromatic section. The external replace
// was sampling the back buffer after the chart had already been copied away.
if (shader_is_compiled(shd_rpe_gate)) {
	var gate_handles = {};
	var gate_names = ["time", "params"];
	for (var gate_i = 0; gate_i < array_length(gate_names); gate_i++) {
		var gate_name = gate_names[gate_i];
		var gate_handle = shader_get_uniform(shd_rpe_gate, gate_name);
		if (gate_handle != -1) then gate_handles[$ gate_name] = gate_handle;
	};
	effect_uniforms[$ "@glsl:gate.glsl"] = gate_handles;
	print($"[RPE Effect] gate uses chart shader, uniforms={array_length(struct_get_names(gate_handles))}");
} else {
	print("[RPE Effect] gate chart shader failed to compile");
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

// Keep a sample surface that is never the bound target. Reuse it: freeing a
// full-frame texture every draw waits on the GPU.
effect_surface_fit = function(_surface, _width, _height) {
	if (surface_exists(_surface)
		&& surface_get_width(_surface) == _width
		&& surface_get_height(_surface) == _height) then return _surface;
	if (surface_exists(_surface)) then surface_free(_surface);
	return surface_create(_width, _height);
};

// GPU copy. surface_getpixel / buffer_get_surface map a staging texture on the
// same context that presents the swap chain. With vsync that waits out the
// queued presents, so a 60 Hz display locks at 20 fps and the GPU sits idle.
// A bound source or destination is unbound by pushing a tiny hold target and
// popping it again, so the caller's stack depth does not change.
effect_gpu_copy_part = function(_src, _dest, _x, _y, _width, _height) {
	if (!surface_exists(_src) || !surface_exists(_dest) || _src == _dest) then return false;
	if (_width < 1 || _height < 1) then return false;
	// Submit the draws, then copy on the GPU. Do not switch to another target
	// first: that flushes the swap chain and the frame waits even at 500x400.
	pls_draw_flush();
	surface_copy_part(_dest, _x, _y, _src, _x, _y, _width, _height);
	return true;
};

effect_gpu_copy = function(_src, _dest) {
	if (!surface_exists(_src)) then return false;
	return effect_gpu_copy_part(_src, _dest, 0, 0, surface_get_width(_src), surface_get_height(_src));
};

// Copy a render target into fx_sample, which is never bound as a target.
// Shaders sample this copy. Sampling the surface that was just drawn is empty
// on this device while that surface is still the render target.
effect_sample_upload = function(_src) {
	if (!surface_exists(_src)) then return false;
	var _upload_width = surface_get_width(_src);
	var _upload_height = surface_get_height(_src);
	if (_upload_width < 1 || _upload_height < 1) then return false;
	fx_sample = effect_surface_fit(fx_sample, _upload_width, _upload_height);
	if (!surface_exists(fx_sample)) then return false;
	return effect_gpu_copy(_src, fx_sample);
};

// Copy _src into fx_over (_slot 0) or fx_under (_slot 1). The destination is
// never bound as a target. Do not free fx_sample here.
effect_upload_into = function(_src, _slot) {
	if (!surface_exists(_src)) then return false;
	var _upload_width = surface_get_width(_src);
	var _upload_height = surface_get_height(_src);
	if (_upload_width < 1 || _upload_height < 1) then return false;
	var _dest = effect_surface_fit((_slot == 0) ? fx_over : fx_under, _upload_width, _upload_height);
	if (_slot == 0) then fx_over = _dest;
	else fx_under = _dest;
	if (!surface_exists(_dest)) then return false;
	return effect_gpu_copy(_src, _dest);
};

effect_render = function(effect_list, input_override = -1, composite_target = -1, caller_was_bound = true) {
	// caller_was_bound is explicit. surface_get_target() still reports the chart
	// mask after it has been popped, and a reset based on that id drops a frame
	// or leaves one extra set. The next event then aborts with stack {1}.
	effect_left_caller_bound = false;
	effect_caller_pushed = false;
	effect_entry_released = false;
	effect_caller_was_bound = caller_was_bound;
	if (!is_array(effect_list) || array_length(effect_list) <= 0) then return;
	var active = [];
	for (var active_i = 0; active_i < array_length(effect_list); active_i++) {
		var active_effect = effect_list[active_i];
		if (chart_time >= active_effect.startTime && chart_time < active_effect.endTime
			&& !rpe_effect_pass_idle(active_effect, chart_time)) array_add(active, active_effect);
	};
	if (array_length(active) <= 0) then return;
	// A lone white overlay is a constant mix. Blit it onto the frame already
	// on screen. The external path would read the whole surface back twice.
	// Fullscreen passes use the chart surface as both input and output. A lone
	// white overlay still blends onto that surface. A layer capture must not:
	// its parent has pixels outside this z range.
	var _white_only = !surface_exists(input_override)
		|| (surface_exists(composite_target) && input_override == composite_target);
	if (_white_only) {
		for (var _white_only_i = 0; _white_only_i < array_length(active); _white_only_i++) {
			if (string_pos("white_overlay.glsl", string(active[_white_only_i].shaderName)) <= 0) {
				_white_only = false;
				break;
			};
		};
	};
	if (_white_only) {
		if (!surface_exists(composite_target)) then composite_target = surface_get_target();
		var _white_bound_w = surface_exists(application_surface) ? surface_get_width(application_surface) : room_width;
		var _white_bound_h = surface_exists(application_surface) ? surface_get_height(application_surface) : room_height;
		var _white_left = 0;
		var _white_width = _white_bound_w;
		var _white_height = _white_bound_h;
		if (variable_global_exists("chart_view_left") && variable_global_exists("chart_view_width")) {
			_white_left = clamp(floor(chart_view_left), 0, _white_bound_w);
			_white_width = clamp(ceil(chart_view_width), 0, _white_bound_w - _white_left);
			_white_height = clamp(ceil(chart_view_height), 0, _white_bound_h);
		};
		var _white_colour = draw_get_colour();
		var _white_alpha = draw_get_alpha();
		gpu_push_state();
		var _white_pushed = false;
		if (surface_exists(composite_target)) {
			surface_set_target(composite_target);
			_white_pushed = true;
		};
		for (var _white_i = 0; _white_i < array_length(active); _white_i++) {
			var _white_pass = active[_white_i];
			var _white_factor = 0;
			var _white_anim = _white_pass.vars[$ "factor"];
			if (is_struct(_white_anim)) then _white_factor = rpe_effect_sample_anim(_white_anim, chart_time);
			rpe_effect_draw_white_overlay(_white_factor, _white_left, 0, _white_width, _white_height);
			var _white_key = $"{_white_pass.shaderName}@{_white_pass.startTime}@blend";
			if (!struct_exists(external_draw_logged, _white_key)) {
				external_draw_logged[$ _white_key] = true;
				print($"[RPE Effect] White overlay blend: time={chart_time}, factor={_white_factor}, rect={_white_left}+{_white_width}x{_white_height}");
			};
		};
		if (_white_pushed) then surface_reset_target();
		gpu_pop_state();
		draw_set_colour(_white_colour);
		draw_set_alpha(_white_alpha);
		return;
	};
	if (!effect_surfaces_ensure()) then return;

	// Effects can run while oChartMask owns a render target. Reading from the
	// application surface in that state replaces the in-progress chart with
	// the previous frame, which makes lines/notes/UI disappear.
	// GML closures resolve instance variables, not local variables from the
	// enclosing function. Keep the target on this controller for the restore
	// callback below.
	// Nested filters must composite back onto the surface that was current when
	// the range opened (the outer capture, or the chart mask). surface_get_target
	// after an extra reset is the application surface, which the mask blit then
	// covers — lines captured only by the outer range never reappear.
	// Fullscreen passes run in oChartMask Draw End, after every Draw and before
	// the blit. The chart pixels are on the unbound mask. Do not shade the
	// application surface: the blit would cover that shade.
	if (!surface_exists(composite_target)) then composite_target = surface_get_target();
	effect_caller_target = composite_target;
	// The chart mask may already be the current target. The offscreen shade then
	// needs two resets before the offscreen copy. A global pass unbinds first, so the
	// caller is not on the stack and a second reset would drop the frame.
	// Instance state: the restore closure cannot see locals. A fullscreen pass
	// unbinds the chart first, so the caller is not on the stack. Resetting
	// just because the surface exists would drop the application target.
	effect_entry_target = surface_get_target();
	effect_entry_released = false;
	effect_caller_pushed = false;
	var _full_frame = surface_exists(input_override) && input_override == effect_caller_target;
	var input_surface = surface_exists(input_override) ? input_override : application_surface;
	if (!surface_exists(input_override) && instance_exists(oChartMask)) {
		var chart_mask = instance_find(oChartMask, 0);
		if (surface_exists(chart_mask.surface_id)) then input_surface = chart_mask.surface_id;
	};
	// One reset for every set. Do not branch on surface_get_target(): a missed
	// comparison leaves the stack at {N} and the next event aborts.
	var restore_caller_target = function() {
		surface_reset_target();
		if (surface_exists(effect_caller_target)) {
			surface_set_target(effect_caller_target);
			effect_caller_pushed = true;
			effect_left_caller_bound = true;
		} else {
			effect_caller_pushed = false;
			effect_left_caller_bound = false;
		};
	};
	var release_caller_for_offscreen = function() {
		if (effect_caller_pushed) {
			surface_reset_target();
			effect_caller_pushed = false;
			effect_left_caller_bound = false;
		} else if (effect_caller_was_bound && !effect_entry_released) {
			surface_reset_target();
			effect_entry_released = true;
		};
	};
	var unwind_detached_caller = function() {
		// A fullscreen pass must not leave the chart target pushed. Draw End
		// binds it once more for its own reset. A layer pass keeps the parent.
		if (effect_caller_pushed && !effect_caller_was_bound) {
			surface_reset_target();
			effect_caller_pushed = false;
			effect_left_caller_bound = false;
		};
	};

	var previous_colour = draw_get_colour();
	var previous_alpha = draw_get_alpha();
	draw_set_colour(c_white);
	draw_set_alpha(1);
	gpu_push_state();
	gpu_set_blendmode_ext(bm_one, bm_zero);
	pls_draw_flush();
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
	if (!surface_exists(input_surface)) {
		gpu_pop_state();
		draw_set_colour(previous_colour);
		draw_set_alpha(previous_alpha);
		return;
	};
	// Windows HLSL can copy the chart on the GPU and shade that copy in place.
	// Android and GX still need a surface that is not the live framebuffer.
	var _direct_external = (os_type != os_android && !rpe_ext_shader_gx());
	var source_surface = input_surface;
	if (!_direct_external) {
		if (!effect_sample_upload(input_surface)) {
			gpu_pop_state();
			draw_set_colour(previous_colour);
			draw_set_alpha(previous_alpha);
			return;
		};
		source_surface = fx_sample;
	};
	var target_surface = fx_pong;
	var _presented_direct = false;
	var _shaded = false;
	// Fold stacked white mixes into one factor: 1-(1-a)*(1-b).
	var _pending_white = 0;
	for (var pass_i = 0; pass_i < array_length(active); pass_i++) {
		var _white_pass_early = active[pass_i];
		if (string_pos("white_overlay.glsl", _white_pass_early.shaderName) > 0) {
			var _stack_factor = 0;
			var _stack_anim = _white_pass_early.vars[$ "factor"];
			if (is_struct(_stack_anim)) then _stack_factor = clamp(rpe_effect_sample_anim(_stack_anim, chart_time), 0, 1);
			_pending_white = 1 - (1 - _pending_white) * (1 - _stack_factor);
			var _stack_key = $"{_white_pass_early.shaderName}@{_white_pass_early.startTime}@blend";
			if (!struct_exists(external_draw_logged, _stack_key)) {
				external_draw_logged[$ _stack_key] = true;
				print($"[RPE Effect] White overlay blend: time={chart_time}, factor={_stack_factor}, stacked=1");
			};
			continue;
		};
		if (!_direct_external && (source_surface == fx_ping || source_surface == fx_pong)) {
			if (!effect_sample_upload(source_surface)) then continue;
			source_surface = fx_sample;
		};
		var pass = active[pass_i];
		var is_external = bool(pass[$ "externalHlsl"] ?? false) || bool(pass[$ "externalGlsl"] ?? false);
		var external_handle = is_external ? effect_external_handle(pass) : -1;
		var _chart_chromatic = string_pos("chromatic_random_rate", pass.shaderName) > 0
			&& shader_is_compiled(shd_rpe_chromatic_rate)
			&& is_struct(effect_uniforms[$ "@glsl:chromatic_random_rate.glsl"]);
		var _chart_gate = string_pos("gate.glsl", pass.shaderName) > 0
			&& shader_is_compiled(shd_rpe_gate)
			&& is_struct(effect_uniforms[$ "@glsl:gate.glsl"]);
		if (_chart_chromatic || _chart_gate) {
			is_external = false;
			external_handle = -1;
		};
		var external_uniforms = is_external ? pass.externalUniforms : {};
		if (!is_external && os_type == os_android) {
			external_handle = real(builtin_native_handles[$ pass.shaderName] ?? -1);
			if (struct_exists(builtin_native_uniforms, pass.shaderName)) {
				external_uniforms = builtin_native_uniforms[$ pass.shaderName];
			};
		};
		if (is_external || external_handle > 0) {
			if (external_handle <= 0) then continue;
			var external_draw_key = $"{pass.shaderName}@{pass.startTime}@{external_handle}";
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
			var external_begin_status = 0;
			var external_uvs;
			var _external_result = target_surface;
			var _external_pushed = true;
			// Fullscreen Windows passes shade the chart surface itself. A scissor
			// keeps the letterbox. Leaving the surface bound avoids a target
			// switch, and there is no second copy back onto the caller.
			var _shade_chart = _direct_external && surface_exists(effect_caller_target)
				&& source_surface == effect_caller_target
				&& (!surface_exists(input_override) || input_override == effect_caller_target);
			if (_shade_chart && effect_caller_was_bound && !effect_entry_released && !effect_caller_pushed) {
				_external_pushed = false;
				_external_result = effect_caller_target;
			} else {
				release_caller_for_offscreen();
			};
			if (os_type == os_android || rpe_ext_shader_gx()) {
				// Read the source framebuffer directly. Sampling a GM surface
				// texture while it is still an FBO attachment returns black on
				// Mali, and GX WebGL needs the same copyTex capture.
				surface_set_target(source_surface);
				if (_pending_white > 0.00005) {
					rpe_effect_draw_white_overlay(_pending_white, effect_left, 0, effect_width, effect_height);
					_pending_white = 0;
				};
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
			} else if (_shade_chart && !_external_pushed) {
				if (!effect_caller_was_bound) chart_mask_scissor_set();
				if (_pending_white > 0.00005) {
					rpe_effect_draw_white_overlay(_pending_white, effect_left, 0, effect_width, effect_height);
					_pending_white = 0;
				};
				pls_draw_flush();
				external_begin_status = rpe_ext_begin(external_handle);
				external_uvs = texture_get_uvs(surface_get_texture(effect_caller_target));
				_presented_direct = true;
			} else {
				// One bind: clear, draw the chart into it, then shade that image.
				// A second target switch per pass flushes the GPU and the frame
				// misses 60 Hz even when the window is only 500x400.
				var _inplace = (source_surface == fx_ping || source_surface == fx_pong);
				var _dest = _shade_chart ? effect_caller_target : (_inplace ? source_surface : target_surface);
				if (!surface_exists(_dest) || (_dest == source_surface && !_inplace && !_shade_chart)) {
					if (effect_caller_was_bound && surface_exists(effect_caller_target)) {
						surface_set_target(effect_caller_target);
						effect_caller_pushed = true;
						effect_left_caller_bound = true;
					};
					continue;
				};
				gpu_set_blendmode_ext(bm_one, bm_zero);
				surface_set_target(_dest);
				// Shading the chart itself must not clear it first. Offscreen
				// passes clear, then draw the chart in, all inside this one bind.
				if (!_inplace && !_shade_chart) {
					draw_clear_alpha(c_black, 0);
					if (source_surface != _dest) {
						draw_surface_part(source_surface, effect_left, 0, effect_width, effect_height, effect_left, 0);
					};
				};
				if (_pending_white > 0.00005) {
					rpe_effect_draw_white_overlay(_pending_white, effect_left, 0, effect_width, effect_height);
					_pending_white = 0;
				};
				if (!effect_caller_was_bound) chart_mask_scissor_set();
				pls_draw_flush();
				external_begin_status = rpe_ext_begin(external_handle);
				external_uvs = texture_get_uvs(surface_get_texture(_dest));
				_external_result = _dest;
				if (_shade_chart) _presented_direct = true;
			};
			if (external_begin_status <= 0) {
				if (!struct_exists(external_draw_logged, external_draw_key)) {
					print($"[RPE Effect] External begin failed: shader={pass.shaderName}, status={external_begin_status}, error={rpe_ext_get_error()}");
					external_draw_logged[$ external_draw_key] = true;
				};
				if (_external_pushed) restore_caller_target();
				else if (effect_caller_was_bound && surface_exists(effect_caller_target)) {
					effect_left_caller_bound = true;
				};
				effect_caller_pushed = surface_exists(effect_caller_target) && _external_pushed;
				effect_left_caller_bound = effect_caller_pushed || effect_left_caller_bound;
				continue;
			};
			var external_draw_status = rpe_ext_draw(external_handle,
				external_uvs[0], external_uvs[1], external_uvs[2], external_uvs[3]);
			var external_end_status = rpe_ext_end();

			if (!struct_exists(external_draw_logged, external_draw_key)) {
				var backend_label = (external_handle == real(pass[$ "externalGlesHandle"] ?? -2)) ? "GLSL ES" : "HLSL";
				print($"[RPE Effect] External direct draw: backend={backend_label}, shader={pass.shaderName}, begin={external_begin_status}, draw={external_draw_status}, end={external_end_status}, uniforms={external_uniform_success}/{external_uniform_total}, time={chart_time}, vars={json_stringify(external_sampled_values)}, surface={surface_get_width(source_surface)}x{surface_get_height(source_surface)}, target={rpe_ext_target_width()}x{rpe_ext_target_height()}, uv={external_uvs[0]},{external_uvs[1]},{external_uvs[2]},{external_uvs[3]}, error={rpe_ext_get_error()}");
				external_draw_logged[$ external_draw_key] = true;
				if (string_pos("chromatic_random_rate", pass.shaderName) > 0) then global.pls_chromatic_front_logged = true;
			};
			if (!effect_caller_was_bound) chart_mask_scissor_clear();
			if (_external_pushed) {
				restore_caller_target();
				effect_caller_pushed = surface_exists(effect_caller_target);
				effect_left_caller_bound = effect_caller_pushed;
			} else {
				effect_caller_pushed = false;
				effect_left_caller_bound = surface_exists(effect_caller_target);
			};
			source_surface = _external_result;
			if (target_surface == source_surface) {
				target_surface = (source_surface == fx_ping) ? fx_pong : fx_ping;
			};
			_shaded = true;
			continue;
		};
		var pass_shader = rpe_effect_shader_asset(pass.shaderName);
		var uniform_key = pass.shaderName;
		if (_chart_chromatic) {
			pass_shader = shd_rpe_chromatic_rate;
			uniform_key = "@glsl:chromatic_random_rate.glsl";
		} else if (_chart_gate) {
			pass_shader = shd_rpe_gate;
			uniform_key = "@glsl:gate.glsl";
		};
		if (pass_shader == -1 || !shader_is_compiled(pass_shader)) then continue;
		if (source_surface != fx_sample) {
			if (!effect_sample_upload(source_surface)) then continue;
			source_surface = fx_sample;
		};
		// Nested last passes blend on the GPU. Draw the effect into a cleared
		// offscreen surface, then premul-over it onto the parent. Drawing that
		// shader onto the parent smears the frame. Do not walk pixels on the CPU.
		var _draw_on_parent = (pass_i == array_length(active) - 1);
		var _compose_parent = _draw_on_parent && surface_exists(input_override) && surface_exists(effect_caller_target);
		pls_draw_flush();
		if (_compose_parent) {
			gpu_set_blendmode_ext(bm_one, bm_zero);
			release_caller_for_offscreen();
			surface_set_target(target_surface);
			draw_clear_alpha(c_black, 0);
		} else if (_draw_on_parent) {
			gpu_set_blendmode_ext(bm_one, bm_zero);
		} else {
			gpu_set_blendmode_ext(bm_one, bm_zero);
			release_caller_for_offscreen();
			surface_set_target(target_surface);
			draw_clear_alpha(c_black, 0);
		};
		shader_set(pass_shader);
		var handles = effect_uniforms[$ uniform_key];
		if (!is_struct(handles)) then handles = {};
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
		if (_compose_parent) {
			// One reset for the offscreen set above. The caller was already
			// released, so a second reset would pop the frame under it.
			surface_reset_target();
			var _copied_full = _full_frame && surface_exists(effect_caller_target)
				&& effect_gpu_copy_part(target_surface, effect_caller_target, effect_left, 0, effect_width, effect_height);
			if (surface_exists(effect_caller_target)) {
				surface_set_target(effect_caller_target);
				effect_caller_pushed = true;
				effect_left_caller_bound = true;
			};
			if (_copied_full) {
				_presented_direct = true;
			} else {
			var _over_ok = effect_upload_into(target_surface, 0);
			if (_over_ok) {
				// A fullscreen pass replaces the chart. Premul-over drops pixels
				// whose alpha is 0, so the shade never shows. A layer pass must
				// stay premul or it wipes notes outside the z range.
				if (_full_frame) then gpu_set_blendmode_ext(bm_one, bm_zero);
				else gpu_set_blendmode_ext_sepalpha(bm_one, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
				gpu_set_texfilter(false);
				gpu_set_texrepeat(false);
				gpu_set_tex_mip_enable(mip_off);
				draw_surface_part(fx_over, effect_left, 0, effect_width, effect_height, effect_left, 0);
				pls_draw_flush();
				_presented_direct = true;
			};
			};
		} else if (_draw_on_parent) {
			_presented_direct = true;
		} else {
			restore_caller_target();
			effect_caller_pushed = surface_exists(effect_caller_target);
			effect_left_caller_bound = effect_caller_pushed;
			source_surface = target_surface;
			target_surface = (source_surface == fx_ping) ? fx_pong : fx_ping;
		};
		_shaded = true;
		var _builtin_draw_key = $"builtin@{pass.shaderName}@{pass.startTime}";
		if (!struct_exists(external_draw_logged, _builtin_draw_key)) {
			external_draw_logged[$ _builtin_draw_key] = true;
			if (_chart_chromatic) then global.pls_chromatic_front_logged = true;
			var _builtin_span = surface_exists(source_surface) ? $"{surface_get_width(source_surface)}x{surface_get_height(source_surface)}" : "none";
			var _builtin_scope = _full_frame ? "global" : "layer";
			print($"[RPE Effect] Built-in shader draw: shader={pass.shaderName}, time={chart_time}, surface={_builtin_span}, scope={_builtin_scope}");
		};
	};
	// The layer surface is premultiplied. bm_normal would multiply alpha again and
	// erase the notes and lines the shader just processed. Premultiplied over
	// leaves pixels outside this z range untouched. A fullscreen pass replaces.
	if (_full_frame && !effect_left_caller_bound && surface_exists(effect_caller_target)) {
		surface_set_target(effect_caller_target);
		effect_caller_pushed = true;
		effect_left_caller_bound = true;
	};
	if (_pending_white > 0.00005) {
		if (!_presented_direct && (source_surface == fx_ping || source_surface == fx_pong)) {
			surface_set_target(source_surface);
			rpe_effect_draw_white_overlay(_pending_white, effect_left, 0, effect_width, effect_height);
			surface_reset_target();
		} else {
			rpe_effect_draw_white_overlay(_pending_white, effect_left, 0, effect_width, effect_height);
		};
		_pending_white = 0;
	};
	if (_shaded && !_presented_direct && _full_frame && _direct_external
		&& (source_surface == fx_ping || source_surface == fx_pong)
		&& surface_exists(effect_caller_target)
		&& effect_gpu_copy_part(source_surface, effect_caller_target, effect_left, 0, effect_width, effect_height)) {
		_presented_direct = true;
	};
	if (_shaded && !_presented_direct && (source_surface == fx_ping || source_surface == fx_pong)) {
		if (!effect_sample_upload(source_surface)) {
			unwind_detached_caller();
			gpu_pop_state();
			draw_set_colour(previous_colour);
			draw_set_alpha(previous_alpha);
			return;
		};
		source_surface = fx_sample;
	};
	if (_shaded && !_presented_direct) {
		shader_reset();
		var _composite_width = max(1, surface_get_width(source_surface));
		var _composite_height = max(1, surface_get_height(source_surface));
		gpu_set_scissor(0, 0, _composite_width, _composite_height);
		if (_full_frame) then gpu_set_blendmode_ext(bm_one, bm_zero);
		else if (surface_exists(input_override)) {
			gpu_set_blendmode_ext_sepalpha(bm_one, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
		};
		draw_surface_part(source_surface, effect_left, 0, effect_width, effect_height, effect_left, 0);
		pls_draw_flush();
	};
	unwind_detached_caller();
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
		var use_layer_span = variable_global_exists("chart_layer_mode") && global.chart_layer_mode;
		if (use_layer_span) {
			// Start pad keeps an outer min (glitch z=2) behind an inner min (chromatic z=3).
			// End pad must differ by a whole depth unit. A 0.01 gap was tied, so glitch
			// closed first and composited the lines before the notes were on them.
			var span_bias = clamp((range.max - range.min) * 0.01, 0, 0.2);
			first_depth = chart_layer_depth(range.min) + 0.2 + span_bias;
			last_depth = chart_layer_depth(range.max) + 1 + range.min;
		} else {
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
			var span_bias = (range.max - range.min) * 0.000000001;
			first_depth += 0.25 + span_bias;
			last_depth -= 0.25 + span_bias;
		};
		var boundary_state = { surface:-1, active:false, blend_pushed:false, capture_pushed:false };
		instance_create_depth(0, 0, first_depth, oRPEEffect, {
			effect_boundary_role:"start",
			effect_boundary_depth:first_depth,
			effect_boundary_state:boundary_state,
			effect_boundary_controller:id,
			effect_boundary_effects:range.effects
		});
		instance_create_depth(0, 0, last_depth, oRPEEffect, {
			effect_boundary_role:"end",
			effect_boundary_depth:last_depth,
			effect_boundary_state:boundary_state,
			effect_boundary_controller:id,
			effect_boundary_effects:range.effects
		});
	};
};
