///@desc 初始化 RPE 后期效果控制器和外部着色器后端
// 区间哨兵只记录深度，不初始化控制器。
if (variable_instance_exists(id, "effect_boundary_role")) {
	depth = real(effect_boundary_depth);
	exit;
};
// 全局调色必须等每个深度区间都合成回来之后再跑。
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
// 最外层是谱面遮罩。嵌套区间要合成回上一层捕获，不能信 reset 之后的 surface_get_target。
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

// Windows 走 D3D11，Android 和 GX 走各自的外部后端。
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

///@desc 从着色器源码里解析用户 uniform 的分量数
///@param {String} source 着色器源码
///@returns {Struct} 名字到分量数的映射
external_uniforms_parse = function(source) {
	var result = {};
	var source_lines = string_split(source, "\n");
	for (var source_line_i = 0; source_line_i < array_length(source_lines); source_line_i++) {
		var source_line = string_trim(source_lines[source_line_i]);
		// `uniform float factor;// %1.0%` 在注释前没有空格，不裁掉会把名字收成 factor//。
		var comment_pos = string_pos("//", source_line);
		if (comment_pos > 0) then source_line = string_trim(string_copy(source_line, 1, comment_pos - 1));
		if (!string_length(source_line)) then continue;
		// YoYo 的 HLSL 会写成带 register 的声明。以前一看到括号就整行跳过，动画值就传不上去。
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
		// 类型或名字缺失就跳过这一行。
		if (array_length(declaration_parts) < 2) then continue;
		var uniform_type = string_trim(declaration_parts[0]);
		var uniform_name = string_trim(declaration_parts[1]);
		if (!string_length(uniform_name)) then continue;
		// 采样器不是数值 uniform。
		if (uniform_type == "sampler2D" || uniform_type == "Texture2D" || uniform_type == "SamplerState") then continue;
		var component_count = 1;
		if (uniform_type == "vec2" || uniform_type == "float2") then component_count = 2;
		else if (uniform_type == "vec3" || uniform_type == "float3") then component_count = 3;
		else if (uniform_type == "vec4" || uniform_type == "float4") then component_count = 4;
		else if (uniform_type != "float") then continue;
		result[$ uniform_name] = component_count;
		// 翻译后的 HLSL 会给用户 uniform 加下划线，谱面变量仍用 GLSL 名字。
		if (string_char_at(uniform_name, 1) == "_" && string_length(uniform_name) > 1
			&& string_copy(uniform_name, 1, 4) != "_gm_") {
			var unprefixed = string_delete(uniform_name, 1, 1);
			if (!struct_exists(result, unprefixed)) then result[$ unprefixed] = component_count;
		};
	};
	return result;
};
///@desc 取一个后期通道当前可用的外部着色器句柄
///@param {Struct} pass 后期通道
///@returns {Real} 句柄，没有时为 -1
effect_external_handle = function(pass) {
	var handle = real(pass[$ "externalHandle"] ?? -1);
	// 优先用当前句柄，其次翻译句柄，最后 GLES 句柄。
	if (handle > 0) return handle;
	var translated_handle = real(pass[$ "externalHlslHandle"] ?? -1);
	if (translated_handle > 0) return translated_handle;
	return real(pass[$ "externalGlesHandle"] ?? -1);
};
///@desc 编译谱面自带的外部着色器并缓存句柄
///@returns {Undefined} 无
effect_compile_externals = function() {
	// 关闭谱面着色器时不编译。
	if (chart_setting_on("disableChartShader")) then return;
	var compile_pass_count = 0;
	var compile_lists = [effects_local, effects_global];
	for (var external_list_i = 0; external_list_i < array_length(compile_lists); external_list_i++) {
		var external_list = compile_lists[external_list_i];
		for (var external_i = 0; external_i < array_length(external_list); external_i++) {
			var external_pass = external_list[external_i];
			var external_is_hlsl = bool(external_pass[$ "externalHlsl"] ?? false);
			var external_is_glsl = bool(external_pass[$ "externalGlsl"] ?? false);
			// 内置通道不走外部编译。
			if (!external_is_hlsl && !external_is_glsl) then continue;
			compile_pass_count++;
			// 这一轮已经编译过就复用。
			if (real(external_pass[$ "externalHandle"] ?? -1) > 0) then continue;
			external_pass.externalHandle = -1;
			external_pass.externalUniforms = {};
			// 后端还没就绪就记下并跳过。
			if (!external_hlsl_ready) {
				print($"[RPE Effect] External pass skipped; backend unavailable: {external_pass.shaderName}");
				continue;
			};
			var external_relative = string_delete(external_pass.shaderName, 1, 6);
			// 同一个文件已经编译过，直接挂上缓存句柄。
			if (struct_exists(external_hlsl_handles, external_relative) || struct_exists(external_gles_handles, external_relative)) {
				external_pass.externalHlslHandle = real(external_hlsl_handles[$ external_relative] ?? -1);
				external_pass.externalGlesHandle = real(external_gles_handles[$ external_relative] ?? -1);
				external_pass.externalHandle = effect_external_handle(external_pass);
				external_pass.externalUniforms = external_hlsl_uniforms[$ external_relative] ?? {};
				continue;
			};
			var external_full_path = chart_extra_asset_path(external_relative);
			// 文件不存在或读出来是空的就跳过。
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
				// 二进制读取失败时改用文本行读取。
				while (!file_text_eof(external_file)) external_source += file_text_readln(external_file) + "\n";
				file_text_close(external_file);
			};
			if (!is_string(external_source) || !string_length(external_source)) {
				print($"[RPE Effect] External shader empty: {external_full_path}");
				continue;
			};
			// 这张谱的光束把 uv.y = 0 当顶部。写出的偏移先到屏幕底部，两条 Hold 会向上消失。
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
			// Windows 可以直接编译 GLSL ES，失败就不再翻译。
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
				// 翻译器会丢掉片元没读的声明。只保留翻译后的集合，避免上传用不到的 time。
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
			// 编译失败就留下日志并继续下一个通道。
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
// chromatic_random_rate 用这张谱的着色器画。外部替换通道会采样空拷贝，把音符和打击丢掉。
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
// 早期色差段里 gate 是全屏的。外部替换会在谱面已经被拷走之后去采样后缓冲。
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

///@desc 保证乒乓表面和应用程序表面一样大
///@returns {Bool} 两张表面都可用时为真
effect_surfaces_ensure = function() {
	// 应用程序表面不存在就无法建乒乓缓冲。
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

///@desc 把采样表面调到指定尺寸，尺寸相同则复用
///@param {Id.Surface} _surface 已有表面
///@param {Real} _width 目标宽度
///@param {Real} _height 目标高度
///@returns {Id.Surface} 可采样且不会被当作目标的表面
effect_surface_fit = function(_surface, _width, _height) {
	// 尺寸没变就复用，避免每帧释放整帧纹理卡住 GPU。
	if (surface_exists(_surface)
		&& surface_get_width(_surface) == _width
		&& surface_get_height(_surface) == _height) then return _surface;
	if (surface_exists(_surface)) then surface_free(_surface);
	return surface_create(_width, _height);
};

///@desc 在 GPU 上拷贝表面的一块区域
///@param {Id.Surface} _src 源表面
///@param {Id.Surface} _dest 目标表面
///@param {Real} _x 区域左上角 X
///@param {Real} _y 区域左上角 Y
///@param {Real} _width 区域宽度
///@param {Real} _height 区域高度
///@returns {Bool} 拷贝已提交时为真
effect_gpu_copy_part = function(_src, _dest, _x, _y, _width, _height) {
	// 源或目标无效，或两者相同，就不能拷。
	if (!surface_exists(_src) || !surface_exists(_dest) || _src == _dest) then return false;
	if (_width < 1 || _height < 1) then return false;
	// 先提交绘制再在 GPU 上拷贝。先切目标会冲掉交换链，小窗口也会卡住。
	pls_draw_flush();
	surface_copy_part(_dest, _x, _y, _src, _x, _y, _width, _height);
	return true;
};

///@desc 在 GPU 上整张拷贝表面
///@param {Id.Surface} _src 源表面
///@param {Id.Surface} _dest 目标表面
///@returns {Bool} 拷贝已提交时为真
effect_gpu_copy = function(_src, _dest) {
	// 源表面不存在就无法拷整张。
	if (!surface_exists(_src)) then return false;
	return effect_gpu_copy_part(_src, _dest, 0, 0, surface_get_width(_src), surface_get_height(_src));
};

///@desc 把渲染目标拷进不会被绑定的采样表面
///@param {Id.Surface} _src 要采样的源表面
///@returns {Bool} 采样表面已更新时为真
effect_sample_upload = function(_src) {
	// 源还是当前渲染目标时直接采样会得到空图，所以先拷出来。
	if (!surface_exists(_src)) then return false;
	var _upload_width = surface_get_width(_src);
	var _upload_height = surface_get_height(_src);
	if (_upload_width < 1 || _upload_height < 1) then return false;
	fx_sample = effect_surface_fit(fx_sample, _upload_width, _upload_height);
	if (!surface_exists(fx_sample)) then return false;
	var copied = effect_gpu_copy(_src, fx_sample);
	return copied;
};

///@desc 把源表面拷进上层或下层合成表面
///@param {Id.Surface} _src 源表面
///@param {Real} _slot 0 为上层，其他为下层
///@returns {Bool} 目标表面已更新时为真
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

///@desc 按当前谱面时间渲染一组后期通道
///@param {Array} effect_list 后期通道数组
///@param {Id.Surface} input_override 输入表面，-1 表示用谱面表面
///@param {Id.Surface} composite_target 合成目标，-1 表示用当前目标
///@param {Bool} caller_was_bound 调用时目标是否已经绑定
///@returns {Undefined} 无
effect_render = function(effect_list, input_override = -1, composite_target = -1, caller_was_bound = true) {
	// caller_was_bound 必须显式传入。遮罩弹出后 surface_get_target 仍可能报它，按那个编号 reset 会丢帧。
	effect_left_caller_bound = false;
	effect_caller_pushed = false;
	effect_entry_released = false;
	effect_caller_was_bound = caller_was_bound;
	// 没有通道就不用渲染。
	if (!is_array(effect_list) || array_length(effect_list) <= 0) then return;
	var active = [];
	// 只留下当前时间窗内、且不是空闲的通道。
	for (var active_i = 0; active_i < array_length(effect_list); active_i++) {
		var active_effect = effect_list[active_i];
		if (chart_time >= active_effect.startTime && chart_time < active_effect.endTime
			&& !rpe_effect_pass_idle(active_effect, chart_time)) array_add(active, active_effect);
	};
	// 这一帧没有生效通道。
	if (array_length(active) <= 0) then return;
	// 单独的白遮罩是常数混合，直接叠到当前画面。全屏可以，层捕获不行，父表面在这个深度之外还有像素。
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
	// 乒乓表面建不出来就无法离屏渲染。
	if (!effect_surfaces_ensure()) then return;

	// 效果可能在 oChartMask 占着渲染目标时运行。这时读应用程序表面会用上一帧盖掉正在画的谱面。
	// 闭包看不到外层局部变量，恢复用的目标记在控制器上。
	// 嵌套滤镜必须合成回区间打开时的表面。多一次 reset 之后拿到的是应用程序表面，遮罩贴回会盖掉它。
	// 全屏通道在遮罩绘制结束、贴回之前运行。不要给应用程序表面着色，否则会被贴回盖住。
	if (!surface_exists(composite_target)) then composite_target = surface_get_target();
	effect_caller_target = composite_target;
	// 谱面遮罩可能已经是当前目标。离屏着色在拷贝前要 reset 两次。全屏通道会先解绑，多一次 reset 会丢帧。
	effect_entry_target = surface_get_target();
	effect_entry_released = false;
	effect_caller_pushed = false;
	var _full_frame = surface_exists(input_override) && input_override == effect_caller_target;
	var input_surface = surface_exists(input_override) ? input_override : application_surface;
	if (!surface_exists(input_override) && instance_exists(oChartMask)) {
		var chart_mask = instance_find(oChartMask, 0);
		if (surface_exists(chart_mask.surface_id)) then input_surface = chart_mask.surface_id;
	};
	///@desc 把渲染目标恢复成调用者原来的表面
	///@returns {Undefined} 无
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
	///@desc 离屏绘制前解开调用者的渲染目标
	///@returns {Undefined} 无
	var release_caller_for_offscreen = function() {
		// 自己压过目标就弹一次；否则只在进入时还绑着时弹。
		if (effect_caller_pushed) {
			surface_reset_target();
			effect_caller_pushed = false;
			effect_left_caller_bound = false;
		} else if (effect_caller_was_bound && !effect_entry_released) {
			surface_reset_target();
			effect_entry_released = true;
		};
	};
	///@desc 全屏通道结束时不要留下被压上的谱面目标
	///@returns {Undefined} 无
	var unwind_detached_caller = function() {
		// 全屏通道不能留下被压上的谱面目标。绘制结束会再绑一次给自己的 reset。层通道要保留父表面。
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
	// 宽高比遮罩两侧不在有效谱面里。保持透明，内置着色器才不会改到视口外的像素。
	var effect_left = 0;
	var effect_width = surface_get_width(input_surface);
	var effect_height = surface_get_height(input_surface);
	if (variable_global_exists("chart_view_left") && variable_global_exists("chart_view_width")) {
		effect_left = clamp(floor(chart_view_left), 0, effect_width);
		effect_width = clamp(ceil(chart_view_width), 0, effect_width - effect_left);
		effect_height = clamp(ceil(chart_view_height), 0, surface_get_height(input_surface));
	};
	// 输入表面丢了就恢复状态并返回。
	if (!surface_exists(input_surface)) {
		gpu_pop_state();
		draw_set_colour(previous_colour);
		draw_set_alpha(previous_alpha);
		return;
	};
	// Windows 的 HLSL 可以在 GPU 上就地着色。Android 和 GX 仍需要一张不是当前帧缓冲的表面。
	var _direct_external = (os_type != os_android && !rpe_ext_shader_gx());
	var source_surface = input_surface;
	if (!_direct_external) {
		// 采样拷贝失败就放弃这一帧。
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
	// 叠在一起的白遮罩收成一个系数：1-(1-a)*(1-b)。
	var _pending_white = 0;
	for (var pass_i = 0; pass_i < array_length(active); pass_i++) {
		var _white_pass_early = active[pass_i];
		// 白遮罩先折叠，不单独占一次着色。
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
		// 这两支改走谱面内置着色器，不再当外部通道。
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
			// 外部句柄无效就跳过这个通道。
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
				} else if (external_animation.kind >= 3) {
					for (var external_component = 0; external_component < external_animation.kind; external_component++) {
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
			// Windows 全屏通道直接给当前目标着色。DLL 会先把目标（含 8x MSAA）解析到副本再采样。
			// 不要在快照失败时改采像素着色器槽 0：那个槽常是字体，成片会白屏并出现乱码字。
			// 应用程序表面在录像里是 8x MSAA。旧 DLL 采不到它时会改采字体槽。这种目标改为离屏拷贝再着色。
			// 表面保持绑定，就不用再拷回调用者。这处已经反复修过。
			var _shade_chart = _direct_external && surface_exists(effect_caller_target)
				&& effect_caller_target != application_surface
				&& source_surface == effect_caller_target
				&& (!surface_exists(input_override) || input_override == effect_caller_target);
			if (_shade_chart && effect_caller_was_bound && !effect_entry_released && !effect_caller_pushed) {
				_external_pushed = false;
				_external_result = effect_caller_target;
			} else {
				release_caller_for_offscreen();
			};
			if (os_type == os_android || rpe_ext_shader_gx()) {
				// 直接读源帧缓冲。它还是 FBO 附件时采样 GM 纹理，在 Mali 上是黑的，GX 的 WebGL 也要同样的拷贝。
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
				// 一次绑定里清空、画入谱面再着色。每个通道再切一次目标会冲掉 GPU，小窗口也到不了 60 帧。
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
				// 给谱面本身着色时不能先清空。离屏通道在同一次绑定里先清空再画入谱面。
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
			_presented_direct = (source_surface == effect_caller_target);
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
		// 深度区间的捕获这时已经解绑。shader_reset 之后再拷它会得到黑图，故障效果就会用空层替换音符。直接采样这份捕获。
		var _sample_capture = surface_exists(input_override) && source_surface == input_override
			&& surface_get_target() != source_surface;
		var _native_output = _direct_external && (source_surface == fx_ping || source_surface == fx_pong);
		// 全屏混合链也可能从调用者的原生输出继续。先解绑再采样，不能复制空表面。
		var _sample_parent = _direct_external && source_surface == effect_caller_target;
		if (_sample_parent) then release_caller_for_offscreen();
		if (!_sample_capture && !_native_output && !_sample_parent && source_surface != fx_sample) {
			if (!effect_sample_upload(source_surface)) then continue;
			source_surface = fx_sample;
		};
		// 嵌套的最后一通道在 GPU 上混合。先画到清空的离屏表面，再预乘叠回父表面。直接画到父表面上会拖影。
		var _draw_on_parent = (pass_i == array_length(active) - 1);
		var _compose_parent = _draw_on_parent && surface_exists(effect_caller_target)
			&& (surface_exists(input_override) || _sample_parent);
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
			else if (animation.kind == 3) then shader_set_uniform_f(handle, value[0], value[1], value[2]);
			else if (animation.kind == 4) then shader_set_uniform_f(handle, value[0], value[1], value[2], value[3]);
		};
		draw_surface_part(source_surface, effect_left, 0, effect_width, effect_height, effect_left, 0);
		// 在目标着色器和渲染目标还有效时提交。
		pls_draw_flush();
		if (_compose_parent) {
			// 先解绑再 shader_reset，着色后的音符才会留在这张表面上。调用者已经解开，这一次 reset 会回到它。
			surface_reset_target();
			shader_reset();
			var _copied_full = !_direct_external && _full_frame && surface_exists(effect_caller_target)
				&& effect_gpu_copy_part(target_surface, effect_caller_target, effect_left, 0, effect_width, effect_height);
			if (surface_exists(effect_caller_target)) {
				surface_set_target(effect_caller_target);
				effect_caller_pushed = true;
				effect_left_caller_bound = true;
			};
			if (_copied_full) {
				_presented_direct = true;
			} else {
			// 直接画着色后的表面。拷到 fx_over 会再次读回黑色，把捕获的音符丢掉。
			var _present_surface = target_surface;
			if (!_direct_external && !_sample_capture) {
				if (!effect_upload_into(target_surface, 0)) then _present_surface = -1;
				else _present_surface = fx_over;
			};
			if (surface_exists(_present_surface)) {
				// 全屏通道替换谱面。预乘叠加会丢掉 alpha 为 0 的像素，着色就看不见。层通道必须保持预乘，否则会擦掉深度范围外的音符。
				if (_full_frame) then gpu_set_blendmode_ext(bm_one, bm_zero);
				else gpu_set_blendmode_ext_sepalpha(bm_one, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
				gpu_set_texfilter(false);
				gpu_set_texrepeat(false);
				gpu_set_tex_mip_enable(mip_off);
				draw_surface_part(_present_surface, effect_left, 0, effect_width, effect_height, effect_left, 0);
				pls_draw_flush();
				_presented_direct = true;
			};
			};
		} else if (_draw_on_parent) {
			// 父表面还绑着。先解开再复位，否则这一笔着色后的音符会被丢掉。
			var _parent_target = surface_get_target();
			var _parent_held = surface_exists(_parent_target) && _parent_target != application_surface;
			if (_parent_held) then surface_reset_target();
			shader_reset();
			if (_parent_held) then surface_set_target(_parent_target);
			_presented_direct = true;
		} else {
			shader_reset();
			restore_caller_target();
			effect_caller_pushed = surface_exists(effect_caller_target);
			effect_left_caller_bound = effect_caller_pushed;
			source_surface = target_surface;
			target_surface = (source_surface == fx_ping) ? fx_pong : fx_ping;
			_presented_direct = false;
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
	// 层表面已经预乘。再用 bm_normal 会把 alpha 乘第二次，刚处理过的音符和线会消失。预乘叠加不会动到这个深度之外的像素。全屏通道则是替换。
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
	// 原生直接写出的颜色表面已经可以采样。surface_copy_part 在这条路径会取得空副本，
	// 再把空副本贴回就会丢掉整个音符层。保持解绑，直接提交原输出纹理。
	if (_shaded && !_presented_direct && !_direct_external && (source_surface == fx_ping || source_surface == fx_pong)) {
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
	// 层通道结束时父表面往往还绑着。直接 shader_reset 会让音符和打击特效闪一下再出现。
	// 这处已经反复修过。先刷新，解开，复位，再绑回去。不要改成单次 shader_reset。
	pls_draw_flush();
	var _exit_target = surface_get_target();
	var _exit_held = surface_exists(_exit_target) && _exit_target != application_surface;
	if (_exit_held) then surface_reset_target();
	shader_reset();
	if (_exit_held) then surface_set_target(_exit_target);
	gpu_pop_state();
	draw_set_colour(previous_colour);
	draw_set_alpha(previous_alpha);
};

///@desc 按目标深度区间创建开始和结束哨兵
///@returns {Undefined} 无
effect_boundaries_create = function() {
	// 已经建过，或判定线还没准备好，就不再创建。
	if (effect_boundaries_initialized || !variable_global_exists("game_1")
		|| !is_struct(game_1) || !is_array(game_1.line_list)) then return;
	if (rpe_lines_creating()) then return;
	if (global.chart_layer_mode && (!variable_global_exists("chart_layer_layout") || !is_struct(global.chart_layer_layout))) then return;
	if (global.chart_layer_mode) {
		var layer_depths = global.chart_layer_layout.depth;
		depth = layer_depths[array_length(layer_depths) - 1] - 4 * array_length(effects_local) - 16;
	}
	effect_boundaries_initialized = true;
	var boundary_epsilon = math_get_epsilon();
	math_set_epsilon(0);
	try {
		var ranged = {};
		var unranged = [];
		for (var effect_i = 0; effect_i < array_length(effects_local); effect_i++) {
			var range_effect = effects_local[@ effect_i];
			var range_min = real(range_effect[$ "targetMin"] ?? -infinity);
			var range_max = real(range_effect[$ "targetMax"] ?? infinity);
			// 没有有限深度区间的效果留在全局列表。
			if (!is_finite(range_min) || !is_finite(range_max) || sign(range_max - range_min) <= 0) {
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
		var range_records = [];
		for (var range_i = 0; range_i < array_length(range_names); range_i++) array_push(range_records, ranged[$ range_names[range_i]]);
		for (var range_i = 0; range_i < array_length(range_names); range_i++) {
			var range_name = range_names[@ range_i];
			var range = ranged[$ range_name];
			var first_depth = -infinity;
			var last_depth = infinity;
			var use_layer_span = variable_global_exists("chart_layer_mode") && global.chart_layer_mode;
			if (use_layer_span) {
				// 同一切点先关闭旧区间，再开启新区间，最后绘制该 Z 的对象。
				// 同起点先开外层，同终点先关内层；偏移仅依赖区间数，不依赖 Z 的绝对值。
				var starts_before = 0;
				var ends_before = 0;
				var range_count = array_length(range_records);
				for (var peer_i = 0; peer_i < range_count; peer_i++) {
					var peer = range_records[peer_i];
					if (sign(peer.min - range.min) == 0 && sign(peer.max - range.max) > 0) starts_before++;
					if (sign(peer.max - range.max) == 0 && sign(peer.min - range.min) > 0) ends_before++;
				}
				first_depth = chart_layer_depth(range.min) + range_count + 1 - starts_before;
				last_depth = chart_layer_depth(range.max) + range_count * 3 + 1 - ends_before;
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
				// 这个区间里没有判定线就不建哨兵。
				if (!is_finite(first_depth) || !is_finite(last_depth)) then continue;
				var span_bias = (range.max - range.min) * 0.000000001;
				first_depth += 0.25 + span_bias;
				last_depth -= 0.25 + span_bias;
			};
			var boundary_state = {
				surface:-1, active:false, blend_pushed:false, capture_pushed:false,
				minZ:range.min, maxZ:range.max, startDepth:first_depth, endDepth:last_depth
			};
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
	} finally {
		math_set_epsilon(boundary_epsilon);
	}
};
