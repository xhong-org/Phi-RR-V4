///@desc 用 BPM 锚点把拍数换成秒
///@param {Array} points BPM 锚点，含 beat、second、bpm
///@param {Real} beat 目标拍
///@returns {Real} 对应秒数，无锚点时为 0
function rpe_effect_beat_to_second(points, beat) {
	if (!is_array(points) || array_length(points) <= 0) then return 0;
	var point = points[0];
	for (var point_i = 1; point_i < array_length(points); point_i++) {
		// 锚点按拍递增，越过目标拍就停在上一个
		if (points[point_i].beat > beat) then break;
		point = points[point_i];
	};
	return point.second + (beat - point.beat) * 60 / point.bpm;
}

///@desc 把拍数组或实数读成拍
///@param {Any} value 拍值，可为 [整拍, 分子, 分母]
///@param {Real} fallback 无法解析时的拍
///@returns {Real} 拍数
function rpe_effect_beat_value(value, fallback = 0) {
	if (is_array(value) && array_length(value) >= 3) {
		var denominator = real(value[2]);
		// 分母为 0 时不能做分数拍
		if (denominator != 0) then return real(value[0]) + real(value[1]) / denominator;
	};
	if (is_real(value)) then return value;
	return fallback;
}

///@desc 按种类读取标量或向量
///@param {Any} raw 原始值
///@param {Real} kind 1 为标量，2 为二维，4 为四维
///@param {Bool} normalize_color 四维颜色是否除以 255
///@returns {Any} 实数或数组
function rpe_effect_value(raw, kind, normalize_color = false) {
	// 标量不走数组
	if (kind == 1) then return real(raw ?? 0);
	var count = clamp(kind, 2, 4);
	var result = array_create(count, 0);
	if (is_array(raw)) {
		for (var value_i = 0; value_i < min(count, array_length(raw)); value_i++) {
			result[@ value_i] = real(raw[value_i]);
		};
	};
	// 颜色从 0–255 收成 0–1
	if (normalize_color && kind >= 3) {
		for (var color_i = 0; color_i < count; color_i++) result[@ color_i] /= 255;
	};
	return result;
}

///@desc 做一个不随时间变化的动画值
///@param {Any} value 固定值
///@param {Real} kind 值的种类
///@returns {Struct} 固定动画
function rpe_effect_anim_fixed(value, kind) {
	return { kind:kind, fixed:true, value:value, events:[] };
}

///@desc 把谱面缓动号映射到播放缓动
///@param {Real} value 谱面 easingType
///@returns {Real} 播放缓动号，占位项为线性
function rpe_effect_easing_type(value) {
	static map = [0, 1, 3, 2, 6, 5, 4, 7, 9, 8, 12, 11, 10, 13, 15, 14, -1, 17, 16, -1, 19, 18, 22, 21, 20, 23, 25, 24, -1, 27, 26, 28];
	var index = clamp(floor(real(value)), 0, array_length(map) - 1);
	var mapped = map[index];
	// 表中的 -1 表示该号无对应缓动
	return mapped < 0 ? EASE_TYPE.LINEAR : mapped;
}

///@desc 把原始动画解析成固定值或按秒排序的事件
///@param {Any} raw 原始动画或常量
///@param {Any} fallback 缺省值
///@param {Real} kind 值的种类
///@param {Array} bpm_points BPM 锚点
///@returns {Struct} 动画
function rpe_effect_parse_anim(raw, fallback, kind, bpm_points, normalize_color = false) {
	// 不是事件列表时当成常量；向量长度恰好等于种类也是常量
	if (!is_array(raw) || (kind > 1 && array_length(raw) == kind && (array_length(raw) <= 0 || !is_struct(raw[0])))) {
		return rpe_effect_anim_fixed(rpe_effect_value(raw ?? fallback, kind, normalize_color), kind);
	};
	var result = { kind:kind, fixed:false, value:fallback, events:[] };
	for (var anim_i = 0; anim_i < array_length(raw); anim_i++) {
		var source_event = raw[anim_i];
		if (!is_struct(source_event)) then continue;
		var start_beat = rpe_effect_beat_value(source_event[$ "startTime"], 0);
		var end_beat = rpe_effect_beat_value(source_event[$ "endTime"], start_beat);
		array_add(result.events, {
			startTime:rpe_effect_beat_to_second(bpm_points, start_beat),
			endTime:rpe_effect_beat_to_second(bpm_points, end_beat),
			start:rpe_effect_value(source_event[$ "start"] ?? fallback, kind, normalize_color),
			"end":rpe_effect_value(source_event[$ "end"] ?? fallback, kind, normalize_color),
			easingType:rpe_effect_easing_type(source_event[$ "easingType"] ?? 1),
			easingLeft:real(source_event[$ "easingLeft"] ?? 0),
			easingRight:real(source_event[$ "easingRight"] ?? 1)
		});
	};
	array_sort(result.events, 
	///@desc 按开始秒比较动画事件
	///@param {Struct} a 左事件
	///@param {Struct} b 右事件
	///@returns {Real} 比较符号
	function(a, b) { return sign(a.startTime - b.startTime); });
	// 没有有效事件则退回常量
	if (array_length(result.events) <= 0) then return rpe_effect_anim_fixed(fallback, kind);
	result.value = result.events[0].start;
	return result;
}

///@desc 在一段时间上插值标量或向量
///@param {Real} now 当前秒
///@param {Real} start_time 开始秒
///@param {Real} end_time 结束秒
///@param {Any} start_value 起始值
///@param {Any} end_value 结束值
///@param {Real} kind 值的种类
///@param {Real} easing 缓动号
///@param {Real} left 缓动窗口左端
///@param {Real} right 缓动窗口右端
///@returns {Any} 插值结果
function rpe_effect_tween_value(now, start_time, end_time, start_value, end_value, kind, easing = 1, left = 0, right = 1) {
	// 零时长直接取结束值
	if (end_time <= start_time) then return end_value;
	// 标量一次插值，向量按分量插值
	if (kind == 1) then return tween_execute(now, start_time, end_time, start_value, end_value, easing, left, right);
	var result = array_create(kind, 0);
	for (var component_i = 0; component_i < kind; component_i++) {
		result[@ component_i] = tween_execute(now, start_time, end_time, start_value[component_i], end_value[component_i], easing, left, right);
	};
	return result;
}

///@desc 在谱面时间上采样一段动画
///@param {Struct} anim 动画
///@param {Real} chart_time 谱面秒
///@returns {Any} 当前值
function rpe_effect_sample_anim(anim, chart_time) {
	// 固定值或没有事件时不再插值
	if (anim.fixed || !is_array(anim.events) || array_length(anim.events) <= 0) then return anim.value;
	var last_time = anim[$ "sampleTime"];
	if (!is_undefined(last_time) && sign(last_time - chart_time) == 0) then return anim.sampleValue;
	var events = anim.events;
	// PhiZone 保持最近一个已经开始的事件，并在结束后钳住。
	// 若用下一段去填空隙，一拍的脉冲会被抹到整段休止，色差和故障就会被拉花。
	var count = array_length(events);
	var chosen = clamp(anim[$ "sampleIndex"] ?? 0, 0, count - 1);
	if (is_undefined(last_time) || chart_time < last_time) {
		var lo = 0;
		var hi = count;
		while (lo < hi) {
			var mid = (lo + hi) div 2;
			if (events[mid].startTime <= chart_time) then lo = mid + 1;
			else hi = mid;
		}
		chosen = max(0, lo - 1);
	} else {
		while (chosen + 1 < count && events[chosen + 1].startTime <= chart_time) chosen++;
	}
	var current_event = events[chosen];
	var value;
	if (chart_time < events[0].startTime) value = events[0].start;
	// 超过本段结束时间则保持结束值，不提前进入下一段
	else if (chart_time >= current_event.endTime) value = current_event[$ "end"];
	else value = rpe_effect_tween_value(chart_time, current_event.startTime, current_event.endTime,
		current_event.start, current_event[$ "end"], anim.kind,
		current_event.easingType, current_event.easingLeft, current_event.easingRight);
	anim.sampleTime = chart_time;
	anim.sampleIndex = chosen;
	anim.sampleValue = value;
	return value;
}

// 本遍不会改变像素时为真，从而可以跳过抓帧和整帧回读。
// Designant 大部分时间 gate 仍开着但 params 为 0；色差和故障只刺一拍然后保持 0。
///@desc 判断这一遍特效当前是否不会改变像素
///@param {Struct} pass 特效遍
///@param {Real} chart_time 谱面秒
///@returns {Bool} 可跳过时为真
function rpe_effect_pass_idle(pass, chart_time) {
	if (!is_struct(pass)) then return true;
	var shader_name = string(pass[$ "shaderName"] ?? "");
	var vars = pass[$ "vars"];
	// 没有参数就无法证明它是空闲的
	if (!is_struct(vars)) then return false;
	if (shader_name == "glitch") {
		var glitch_power_anim = vars[$ "power"];
		var color_anim = vars[$ "colorRate"];
		var glitch_power = is_struct(glitch_power_anim) ? rpe_effect_sample_anim(glitch_power_anim, chart_time) : 0;
		var color_rate = is_struct(color_anim) ? rpe_effect_sample_anim(color_anim, chart_time) : 0;
		return abs(glitch_power) < 0.00005 && abs(color_rate) < 0.00005;
	};
	if (shader_name == "chromatic" || string_pos("chromatic_random_rate", shader_name) > 0) {
		var chromatic_anim = vars[$ "power"];
		var chromatic_power = is_struct(chromatic_anim) ? rpe_effect_sample_anim(chromatic_anim, chart_time) : 0;
		return abs(chromatic_power) < 0.00005;
	};
	if (string_pos("gate.glsl", shader_name) > 0) {
		var params_anim = vars[$ "params"];
		var params = is_struct(params_anim) ? rpe_effect_sample_anim(params_anim, chart_time) : 0;
		return abs(params) < 0.00005;
	};
	// white_overlay 在 Designant 休止（约 94 秒到 138 秒）一直挂着，
	// factor 只离开 0 一拍。不在这里判空闲的话仍会抓帧。
	if (string_pos("white_overlay.glsl", shader_name) > 0) {
		var overlay_anim = vars[$ "factor"];
		var overlay_factor = is_struct(overlay_anim) ? rpe_effect_sample_anim(overlay_anim, chart_time) : 0;
		return abs(overlay_factor) < 0.00005;
	};
	// lum 在跌下一拍之后，整个 Designant 休止保持 0.8 / 0.6。
	// factor 为 1 时图层不变，抓帧可以保持关闭。
	if (string_pos("lum.glsl", shader_name) > 0) {
		var lum_anim = vars[$ "factor"];
		var lum_factor = is_struct(lum_anim) ? rpe_effect_sample_anim(lum_anim, chart_time) : 1;
		return abs(lum_factor - 1) < 0.00005;
	};
	if (string_pos("invis.glsl", shader_name) > 0) {
		var invis_anim = vars[$ "factor"];
		var invis_factor = is_struct(invis_anim) ? rpe_effect_sample_anim(invis_anim, chart_time) : 0;
		return abs(invis_factor) < 0.00005;
	};
	if (shader_name == "grayscale") {
		var gray_anim = vars[$ "factor"];
		var gray_factor = is_struct(gray_anim) ? rpe_effect_sample_anim(gray_anim, chart_time) : 0;
		return abs(gray_factor) < 0.00005;
	};
	// 未识别的着色器不能当作空闲
	return false;
}

///@desc 采样特效遍的 factor
///@param {Struct} pass 特效遍
///@param {Real} chart_time 谱面秒
///@returns {Real} factor，没有则为 0
function rpe_effect_sample_factor(pass, chart_time) {
	if (!is_struct(pass)) then return 0;
	var vars = pass[$ "vars"];
	if (!is_struct(vars)) then return 0;
	var anim = vars[$ "factor"];
	if (!is_struct(anim)) then return 0;
	return rpe_effect_sample_anim(anim, chart_time);
}

// 返回 [lum, gray, invis]。"heavy" 表示仍有遍必须走采样着色器。
// 灰度按 1-(1-a)*(1-b) 混合。lum 相乘。invis 用同样的混合；
// 1 表示抓到的图层完全透明。
///@desc 把只含亮度、灰度和透明的层折成三个系数
///@param {Array} effects 特效遍
///@param {Real} chart_time 谱面秒
///@returns {Any} 三元数组，或字符串 heavy
function rpe_effect_layer_fast(effects, chart_time) {
	if (!is_array(effects)) then return "heavy";
	var any_pass = false;
	var lum_factor = 1;
	var gray_factor = 0;
	var invis_factor = 0;
	for (var fast_i = 0; fast_i < array_length(effects); fast_i++) {
		var fast_pass = effects[fast_i];
		if (!is_struct(fast_pass)) then continue;
		// 不在本遍时间范围内
		if (chart_time < fast_pass.startTime || chart_time >= fast_pass.endTime) then continue;
		// 当前不会改像素的遍不参与混合
		if (rpe_effect_pass_idle(fast_pass, chart_time)) then continue;
		any_pass = true;
		var fast_name = string(fast_pass[$ "shaderName"] ?? "");
		if (string_pos("lum.glsl", fast_name) > 0) {
			lum_factor *= clamp(rpe_effect_sample_factor(fast_pass, chart_time), 0, 1);
		} else if (fast_name == "grayscale") {
			var gray_sample = clamp(rpe_effect_sample_factor(fast_pass, chart_time), 0, 1);
			gray_factor = 1 - (1 - gray_factor) * (1 - gray_sample);
		} else if (string_pos("invis.glsl", fast_name) > 0) {
			var invis_sample = clamp(rpe_effect_sample_factor(fast_pass, chart_time), 0, 1);
			invis_factor = 1 - (1 - invis_factor) * (1 - invis_sample);
		} else {
			// 其余着色器不能折成这三个系数
			return "heavy";
		};
	};
	// 没有任何有效遍时仍走原来的重路径
	if (!any_pass) then return "heavy";
	return [lum_factor, gray_factor, invis_factor];
}

///@desc 取当前时刻各效果边界里最大的灰度
///@returns {Real} 灰度系数
function rpe_effect_active_gray() {
	var when = 0;
	var found_time = false;
	with (oRPEEffect) {
		// 边界实例不提供谱面时间
		if (variable_instance_exists(id, "effect_boundary_role")) then continue;
		when = chart_time;
		found_time = true;
		break;
	};
	if (!found_time) then return 0;
	var gray = 0;
	with (oRPEEffect) {
		if (!variable_instance_exists(id, "effect_boundary_effects")) then continue;
		var fast = rpe_effect_layer_fast(effect_boundary_effects, when);
		// 多个边界取最大灰度
		if (is_array(fast) && fast[1] > gray) then gray = fast[1];
	};
	return gray;
}

// 视频 2 在 z 1.5，位于灰度带下面，而且 FFVideos 忽略精灵着色器。
// 复制当前目标、给副本上灰度再画回去。这里若走原生全屏遍会换掉谱面目标，音符就画不上去。
///@desc 把当前绘制目标复制后按灰度再画回
///@returns {Undefined} 无
function rpe_effect_grade_backdrop() {
	static gray_copy = -1;
	static gray_logged = false;
	var gray = rpe_effect_active_gray();
	// 灰度几乎为 0 或着色器不可用时不抓帧
	if (gray < 0.00005 || !shader_is_compiled(shd_rpe_grayscale)) then return;
	var parent = surface_get_target();
	if (!surface_exists(parent)) then return;
	var parent_w = surface_get_width(parent);
	var parent_h = surface_get_height(parent);
	if (parent_w < 1 || parent_h < 1) then return;
	if (!surface_exists(gray_copy)
		|| abs(surface_get_width(gray_copy) - parent_w) > 2
		|| abs(surface_get_height(gray_copy) - parent_h) > 2) {
		if (surface_exists(gray_copy)) then surface_free(gray_copy);
		gray_copy = surface_create(parent_w, parent_h);
	};
	if (!surface_exists(gray_copy)) then return;
	pls_draw_flush();
	gpu_push_state();
	gpu_set_blendmode_ext(bm_one, bm_zero);
	surface_reset_target();
	surface_set_target(gray_copy);
	draw_clear_alpha(c_black, 0);
	draw_surface(parent, 0, 0);
	pls_draw_flush();
	surface_reset_target();
	surface_set_target(parent);
	shader_set(shd_rpe_grayscale);
	var gray_uniform = shader_get_uniform(shd_rpe_grayscale, "factor");
	if (gray_uniform != -1) then shader_set_uniform_f(gray_uniform, gray);
	draw_surface(gray_copy, 0, 0);
	pls_draw_flush();
	// 父表面还绑着时不能 shader_reset，否则这一帧刚画上的音符和打击特效会消失，下一帧才回来。
	// Designant 的视频 2 在 z 1.5，每帧都会走到这里。这处已经反复修过。
	// 先解开，复位，再绑回父表面。不要改成直接 shader_reset，也不要再多一次 reset。
	var _grade_target = surface_get_target();
	var _grade_held = surface_exists(_grade_target) && _grade_target != application_surface;
	if (_grade_held) then surface_reset_target();
	shader_reset();
	if (_grade_held) then surface_set_target(_grade_target);
	gpu_pop_state();
	if (!gray_logged) {
		gray_logged = true;
		print($"[RPE Effect] Gray backdrop: factor={gray}");
	};
}

// 不采样画面，直接 mix(像素, 白, factor)。源是 alpha 等于 factor 的直白，
// 所以颜色项必须乘源 alpha。
///@desc 用混合模式画一块白色遮罩
///@param {Real} _factor 混合强度
///@param {Real} _left 左
///@param {Real} _top 上
///@param {Real} _width 宽
///@param {Real} _height 高
///@returns {Undefined} 无
function rpe_effect_draw_white_overlay(_factor, _left, _top, _width, _height) {
	if (_width < 1 || _height < 1) then return;
	_factor = clamp(_factor, 0, 1);
	// 强度过小则不画
	if (_factor < 0.00005) then return;
	gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
	draw_set_colour(c_white);
	draw_set_alpha(_factor);
	draw_rectangle(_left, _top, _left + _width, _top + _height, false);
	pls_draw_flush();
	draw_set_colour(c_white);
	draw_set_alpha(1);
	gpu_set_blendmode_ext(bm_one, bm_zero);
}

///@desc 返回内置特效的默认动画参数
///@param {String} shader_name 着色器名
///@returns {Struct} 参数名到固定动画
function rpe_effect_defaults(shader_name) {
	var defaults = {};
	// 未知名保持空结构
	switch (shader_name) {
		case "chromatic": defaults = { sampleCount:rpe_effect_anim_fixed(3,1), power:rpe_effect_anim_fixed(0.01,1) }; break;
		case "circleBlur": defaults = { size:rpe_effect_anim_fixed(10,1) }; break;
		case "fisheye": defaults = { power:rpe_effect_anim_fixed(-0.1,1) }; break;
		case "glitch": defaults = { power:rpe_effect_anim_fixed(0.03,1), rate:rpe_effect_anim_fixed(0.6,1), speed:rpe_effect_anim_fixed(5,1), blockCount:rpe_effect_anim_fixed(30.5,1), colorRate:rpe_effect_anim_fixed(0.01,1) }; break;
		case "grayscale": defaults = { factor:rpe_effect_anim_fixed(1,1) }; break;
		case "noise": defaults = { seed:rpe_effect_anim_fixed(81,1), power:rpe_effect_anim_fixed(0.03,1) }; break;
		case "pixel": defaults = { size:rpe_effect_anim_fixed(10,1) }; break;
		case "radialBlur": defaults = { centerX:rpe_effect_anim_fixed(0.5,1), centerY:rpe_effect_anim_fixed(0.5,1), power:rpe_effect_anim_fixed(0.01,1), sampleCount:rpe_effect_anim_fixed(6,1) }; break;
		case "shockwave": defaults = { progress:rpe_effect_anim_fixed(0.2,1), centerX:rpe_effect_anim_fixed(0.5,1), centerY:rpe_effect_anim_fixed(0.5,1), width:rpe_effect_anim_fixed(0.1,1), distortion:rpe_effect_anim_fixed(0.8,1), expand:rpe_effect_anim_fixed(10,1) }; break;
		case "vignette": defaults = { color:rpe_effect_anim_fixed([0,0,0,1],4), extend:rpe_effect_anim_fixed(0.25,1), radius:rpe_effect_anim_fixed(15,1) }; break;
		case "customTint": defaults = { factor:rpe_effect_anim_fixed(0.5,1) }; break;
	};
	return defaults;
}

///@desc 把谱面里的外部着色器路径映射到内置名或源码标记
///@param {String} shader_path 以 / 开头的相对路径
///@returns {String} 内置名、@glsl: 或 @hlsl: 路径，无法使用时为空串
function rpe_effect_external_mapping(shader_path) {
	var relative_path = string_delete(shader_path, 1, 1);
	relative_path = string_replace_all(relative_path, "\\", "/");
	// 拒绝空路径、上级目录和盘符
	if (!string_length(relative_path) || string_pos("..", relative_path) > 0 || string_pos(":", relative_path) > 0) then return "";
	var full_path = chart_extra_asset_path(relative_path);
	if (!chart_file_exists_any(full_path)) {
		print($"[RPE Effect] Missing external shader: {relative_path}");
		return "";
	};
	var lower_path = string_lower(relative_path);
	// 扩展名已经能确定语言时不再读全文
	if (string_copy(lower_path, max(1, string_length(lower_path) - 4), 5) == ".hlsl") {
		return "@hlsl:" + relative_path;
	};
	var is_glsl_path = (string_copy(lower_path, max(1, string_length(lower_path) - 2), 3) == ".fs"
		|| string_copy(lower_path, max(1, string_length(lower_path) - 4), 5) == ".glsl"
		|| string_copy(lower_path, max(1, string_length(lower_path) - 3), 4) == ".fsh");
	if (is_glsl_path) then return "@glsl:" + relative_path;
	var source = chart_read_text_file(full_path, -1);
	if (!is_string(source) || !string_length(source)) then return "";
	var probe = string_lower(relative_path + "\n" + source);
	var compact = string_replace_all(string_replace_all(string_replace_all(string_replace_all(probe, " ", ""), "\t", ""), "\r", ""), "\n", "");
	if ((string_pos("gl_fragcolor=mix(texture2d(screentexture,uv),vec4(1.0,0.0,0.0,1.0),factor)", compact) > 0)
		// 红染或白染一类的混合当成 customTint
		|| (string_pos("lerp(", compact) > 0 && string_pos("float4(1", compact) > 0 && string_pos("factor", compact) > 0)) return "customTint";
	var names = ["chromatic", "circleBlur", "fisheye", "glitch", "grayscale", "noise", "pixel", "radialBlur", "shockwave", "vignette", "customTint"];
	for (var name_i = 0; name_i < array_length(names); name_i++) {
		var shader_name = names[name_i];
		var lower_name = string_lower(shader_name);
		if (string_pos("@gamemaker-effect " + lower_name, probe) > 0
			|| string_pos("/" + lower_name + ".", probe) > 0
			|| string_pos("/" + string_replace_all(lower_name, "blur", "_blur") + ".", probe) > 0) return shader_name;
	};
	// GX 与 Android 可以直接编译这类 GLSL
	if (string_pos("gl_fragcolor", probe) > 0 || string_pos("gl_fragcoord", probe) > 0) {
		if (rpe_ext_shader_gx() || rpe_ext_shader_android()) {
			return "@glsl:" + relative_path;
		};
	};
	if (string_pos("float4", probe) > 0 || string_pos("sv_target", probe) > 0
		|| string_pos("samplerstate", probe) > 0 || string_pos("texture2d", probe) > 0
		|| string_pos("tex2d(", probe) > 0 || string_pos("cbuffer ", probe) > 0) {
		return "@hlsl:" + relative_path;
	};
	if (rpe_ext_shader_gx()) {
		print($"[RPE Effect] Unrecognized shader; GX compiles GLSL .fs / .glsl / .fsh: {relative_path}");
	} else if (os_type == os_android) {
		print($"[RPE Effect] Unrecognized shader; Android needs GLSL ES, HLSL, or '// @gamemaker-effect <builtin>': {relative_path}");
	} else {
		print($"[RPE Effect] GLSL runtime translation is unavailable; use HLSL or add '// @gamemaker-effect <builtin>': {relative_path}");
	};
	return "";
}

// 谱面色差着色器只写 gl_FragColor.rgb。权重和为 0 时得到 NaN，
// 混合就会丢掉抓取层的每个像素，包括音符。
// 把带计数中断的循环展开。这块 GPU 上的动态 HLSL 循环可能让整次采样失败，
// 连本应原样复制抓取结果的分支也不走。
///@desc 把采样计数循环展开成固定次数的条件块
///@param {String} source 着色器源码
///@returns {String} 展开后的源码，形状不符则原样返回
function rpe_effect_unroll_sample_loop(source) {
	var header = "for(int i=0;i<64;++i){";
	var guard = "if(i>=sample_count)break;";
	var header_at = string_pos(header, source);
	// 找不到固定循环头就不改源码
	if (header_at <= 0) then return source;
	var guard_at = string_pos(guard, source);
	if (guard_at <= header_at) then return source;
	var scan = header_at + string_length(header);
	var _depth = 1;
	var end_at = 0;
	var length = string_length(source);
	while (scan <= length && _depth > 0) {
		var ch = string_char_at(source, scan);
		// 用花括号深度找循环结束
		if (ch == "{") then _depth += 1;
		else if (ch == "}") then _depth -= 1;
		if (_depth == 0) then end_at = scan;
		scan += 1;
	};
	if (end_at <= guard_at) then return source;
	var body_at = guard_at + string_length(guard);
	var body = string_copy(source, body_at, end_at - body_at);
	var unrolled = "";
	for (var sample_index = 0; sample_index < 64; sample_index++) {
		var sample_body = string_replace(body, "float(i)", "float(" + string(sample_index) + ")");
		unrolled += "if(" + string(sample_index) + "<sample_count){" + sample_body + "}";
	};
	source = string_delete(source, header_at, end_at - header_at + 1);
	source = string_insert(unrolled, source, header_at);
	source = string_replace(source, "precision mediump float;", "precision highp float;");
	return source;
}

///@desc 让色差输出保留原像素 alpha，并钳住覆盖范围
///@param {String} source 着色器源码
///@returns {String} 改写后的源码
function rpe_effect_preserve_frag_alpha(source) {
	// 没有屏幕采样就不是这类色差着色器
	if (!is_string(source) || string_pos("screenTexture", source) <= 0) then return source;
	source = rpe_effect_unroll_sample_loop(source);
	var replacement = "{vec4 _rpeBase=texture2D(screenTexture,uv);float _rpeW=sum.x+sum.y+sum.z;gl_FragColor=(_rpeW>0.001)?vec4(c/max(sum,vec3(0.0001)),_rpeBase.a):_rpeBase;}";
	source = string_replace_all(source, "gl_FragColor.rgb=c/sum;", replacement);
	source = string_replace_all(source, "gl_FragColor.rgb = c/sum;", replacement);
	// 位移、相机和模糊可以把非透明像素移到原位置之外，不能按原像素的 alpha 裁剪。
	return source;
}

// 谱面暗角用 uv*(1-uv)。打在打击精灵上时这些 UV 是图集矩形，软盘会被再染一次。
// 改为按像素在屏幕上的位置衰减。
///@desc 把暗角从纹理 UV 改成屏幕像素衰减
///@param {String} source 着色器源码
///@returns {String} 改写后的源码
function rpe_effect_vignette_screen_falloff(source) {
	if (!is_string(source)) then return source;
	var shaped = string_pos("uv.yx", source) > 0;
	// 没有 uv.yx 形状就不是这套暗角
	if (!shaped) then return source;
	if (string_pos("uniform vec2 screenSize", source) <= 0) {
		source = "uniform vec2 screenSize;\n" + source;
	};
	source = string_replace_all(source, "uv * (1.0 - uv.yx)", "(_rpeVigUv * (1.0 - _rpeVigUv.yx))");
	source = string_replace_all(source, "uv*(1.0-uv.yx)", "(_rpeVigUv*(1.0-_rpeVigUv.yx))");
	var main_at = string_pos("void main", source);
	if (main_at <= 0) then return source;
	var brace_scan = string_pos("{", string_delete(source, 1, main_at - 1));
	if (brace_scan <= 0) then return source;
	var brace_at = main_at + brace_scan - 1;
	return string_insert("vec2 _rpeVigUv=(screenSize.x>1.0)?(gl_FragCoord.xy/screenSize):uv;", source, brace_at + 1);
}

// patch、暗角一类会混向不透明颜色，空白抓取像素就会变实。
///@desc 为所有实际 Z 和效果边界预留有序深度槽，极窄范围也能正确开闭
///@returns {Undefined} 无
function rpe_effect_layer_layout_prepare() {
	var epsilon = math_get_epsilon();
	math_set_epsilon(0);
	try {
		var z_values = [0, 1, 2, 3, 4, 5, 6, 7, 8, 24, 64];
		var rpe = game_1;
		var lines = rpe.line_list;
		for (var li = 0; li < array_length(lines); li++) {
			if (instance_exists(lines[li])) array_push(z_values, lines[li].layer_z);
		}
		// 音符此时已休眠，使用创建记录，不能依赖 instance_exists。
		for (var ni = 0; ni < array_length(rpe._notes); ni++) {
			array_push(z_values, rpe._notes[ni].layerZ, rpe._notes[ni].hitZ);
		}
		var range_count = 0;
		var controller = noone;
		var passes = [];
		if (instance_exists(oExtraPlay)) {
			var extra = instance_find(oExtraPlay, 0);
			controller = extra.effect_controller;
			passes = extra.effect_layer_passes;
			for (var vi = 0; vi < array_length(extra.videos); vi++) {
				var video_z = extra.videos[vi].zIndex;
				if (is_real(video_z) && is_finite(video_z)) array_push(z_values, video_z);
			}
		}
		range_count = array_length(passes);
		for (var pass_i = 0; pass_i < range_count; pass_i++) {
			if (is_finite(passes[pass_i].targetMin)) array_push(z_values, passes[pass_i].targetMin);
			if (is_finite(passes[pass_i].targetMax)) array_push(z_values, passes[pass_i].targetMax);
		}
		array_sort(z_values, function(a, b) { return sign(a - b); });
		var unique_z = [];
		var depths = [];
		var spacing = 4 * range_count + 16;
		var previous_z = undefined;
		var previous_depth = 0;
		for (var zi = 0; zi < array_length(z_values); zi++) {
			var current_z = z_values[zi];
			if (!is_finite(current_z)) continue;
			if (!is_undefined(previous_z) && sign(current_z - previous_z) == 0) continue;
			var next_depth = -1000 * current_z;
			if (!is_undefined(previous_z)) next_depth = previous_depth - max(spacing, 1000 * (current_z - previous_z));
			array_push(unique_z, current_z);
			array_push(depths, next_depth);
			previous_z = current_z;
			previous_depth = next_depth;
		}
		global.chart_layer_layout = { z:unique_z, depth:depths };
		for (var li = 0; li < array_length(lines); li++) {
			var line_instance = lines[li];
			if (instance_exists(line_instance)) chart_set_instance_depth(line_instance,
				chart_layer_depth(line_instance.layer_z) - line_instance.line_id * 0.0001);
		}
		if (instance_exists(oExtraPlay)) {
			var extra = instance_find(oExtraPlay, 0);
			for (var vi = 0; vi < array_length(extra.video_layers); vi++) {
				var video_layer = extra.video_layers[vi];
				if (!instance_exists(video_layer)) continue;
				chart_set_instance_depth(video_layer, chart_layer_depth(extra.videos[video_layer.video_layer_index].zIndex));
			}
		}
		// 无范围通道也必须在所有图层画完之后运行。
		if (instance_exists(controller)) chart_set_instance_depth(controller, previous_depth - spacing);
	} finally {
		math_set_epsilon(epsilon);
	}
}

///@desc 从外部着色器注释里读取 uniform 默认值
///@param {String} shader_name 带 @hlsl: 或 @glsl: 前缀的名字
///@returns {Struct} uniform 名到固定动画
function rpe_effect_external_defaults(shader_name) {
	var result = {};
	var separator = string_pos(":", shader_name);
	// 没有前缀冒号就不是外部源码标记
	if (separator <= 0) then return result;
	var relative_path = string_delete(shader_name, 1, separator);
	var full_path = chart_extra_asset_path(relative_path);
	if (!chart_file_exists_any(full_path)) then return result;
	var handle = file_text_open_read(chart_file_readable_path(full_path));
	if (is_undefined(handle) || handle < 0) then return result;
	while (!file_text_eof(handle)) {
		var shader_line = string_trim(string_replace_all(file_text_readln(handle), "\t", " "));
		// 函数行不是 uniform 声明
		if (string_pos("(", shader_line) > 0) then continue;
		var semicolon = string_pos(";", shader_line);
		var first_percent = string_pos("%", shader_line);
		// 默认值写在分号后的成对百分号里
		if (semicolon <= 0 || first_percent <= semicolon) then continue;
		var default_tail = string_delete(shader_line, 1, first_percent);
		var second_percent = string_pos("%", default_tail);
		if (second_percent <= 0) then continue;
		var declaration = string_trim(string_copy(shader_line, 1, semicolon - 1));
		declaration = string_replace(declaration, "uniform ", "");
		declaration = string_replace(declaration, "static ", "");
		var register_pos = string_pos(":", declaration);
		if (register_pos > 0) then declaration = string_trim(string_copy(declaration, 1, register_pos - 1));
		var declaration_parts_raw = string_split(declaration, " ");
		var declaration_parts = [];
		for (var part_i = 0; part_i < array_length(declaration_parts_raw); part_i++) {
			var part = string_trim(declaration_parts_raw[part_i]);
			if (string_length(part) && part != "highp" && part != "mediump" && part != "lowp") {
				array_add(declaration_parts, part);
			};
		};
		if (array_length(declaration_parts) < 2) then continue;
		var uniform_type = declaration_parts[0];
		var uniform_name = declaration_parts[1];
		var default_text = string_trim(string_copy(default_tail, 1, second_percent - 1));
		var kind = 1;
		var value = 0;
		if (uniform_type == "vec2" || uniform_type == "float2") {
			kind = 2;
			var values = string_split(default_text, ",");
			if (array_length(values) < kind) then continue;
			value = array_create(kind, 0);
			for (var component_i = 0; component_i < kind; component_i++) {
				value[@ component_i] = real(string_trim(values[component_i]));
			};
		} else if (uniform_type == "vec3" || uniform_type == "float3" || uniform_type == "vec4" || uniform_type == "float4") {
			kind = (uniform_type == "vec3" || uniform_type == "float3") ? 3 : 4;
			var values = string_split(default_text, ",");
			if (array_length(values) < kind) then continue;
			value = array_create(kind, 0);
			for (var component_i = 0; component_i < kind; component_i++) {
				value[@ component_i] = real(string_trim(values[component_i]));
			};
		} else if (uniform_type == "float") {
			value = real(default_text);
		} else {
			// 只认 float、vec2/float2、vec4/float4
			continue;
		};
		result[$ uniform_name] = rpe_effect_anim_fixed(value, kind);
	};
	file_text_close(handle);
	return result;
}

///@desc 把 extra.json 的特效拆成本地层和全局层
///@param {Struct} extra 额外数据
///@param {Array} bpm_points BPM 锚点
///@returns {Struct} local 与 global 两组特效
function rpe_effect_parse(extra, bpm_points) {
	var result = { local:[], global:[] };
	if (!is_struct(extra) || !is_array(extra[$ "effects"])) then return result;
	for (var effect_i = 0; effect_i < array_length(extra.effects); effect_i++) {
		var source = extra.effects[effect_i];
		if (!is_struct(source) || !is_string(source[$ "shader"])) then continue;
		var shader_name = source.shader;
		// 以 / 开头的是谱面内着色器文件
		if (string_char_at(shader_name, 1) == "/") then shader_name = rpe_effect_external_mapping(shader_name);
		var defaults = rpe_effect_defaults(shader_name);
		var is_external_hlsl = (string_pos("@hlsl:", shader_name) == 1);
		var is_external_glsl = (string_pos("@glsl:", shader_name) == 1);
		if (is_external_hlsl || is_external_glsl) defaults = rpe_effect_external_defaults(shader_name);
		if (!string_length(shader_name) || (!is_external_hlsl && !is_external_glsl && array_length(struct_get_names(defaults)) <= 0)) {
			print($"[RPE Effect] Unsupported shader at effect {effect_i}: {source.shader}");
			continue;
		};
		if (is_struct(source[$ "vars"])) {
			var names = struct_get_names(source.vars);
			for (var var_i = 0; var_i < array_length(names); var_i++) {
				var uniform_name = names[var_i];
				var raw_uniform = source.vars[$ uniform_name];
				var fallback = 0;
				var kind = 1;
				if (struct_exists(defaults, uniform_name)) {
					fallback = defaults[$ uniform_name].value;
					kind = defaults[$ uniform_name].kind;
				} else {
					var raw_probe = raw_uniform;
					if (is_array(raw_probe) && array_length(raw_probe) > 0 && is_struct(raw_probe[0])) raw_probe = raw_probe[0][$ "start"];
					if (is_array(raw_probe) && array_length(raw_probe) == 2) { kind = 2; fallback = [0,0]; }
					else if (is_array(raw_probe) && array_length(raw_probe) == 3) { kind = 3; fallback = [0,0,0]; }
					else if (is_array(raw_probe) && array_length(raw_probe) == 4) { kind = 4; fallback = [0,0,0,0]; };
				};
				if (is_undefined(raw_uniform)) {
					defaults[$ uniform_name] = rpe_effect_anim_fixed(kind == 1 ? 0 : array_create(kind, 0), kind);
				} else {
					var normalize_color = false;
					var lower_name = string_lower(uniform_name);
					if (kind >= 3 && is_array(raw_uniform)
						&& (string_pos("color", lower_name) > 0 || string_pos("tint", lower_name) > 0 || string_pos("rgb", lower_name) > 0)) {
						var color_values = raw_uniform;
						if (array_length(raw_uniform) > 0 && is_struct(raw_uniform[0])) {
							color_values = [];
							for (var ei = 0; ei < array_length(raw_uniform); ei++) {
								if (!is_struct(raw_uniform[ei])) continue;
								array_push(color_values, raw_uniform[ei].start, raw_uniform[ei][$ "end"]);
							}
						} else color_values = [raw_uniform];
						for (var vi = 0; vi < array_length(color_values); vi++) {
							var color_value = color_values[vi];
							if (!is_array(color_value)) continue;
							for (var ci = 0; ci < min(kind, array_length(color_value)); ci++) normalize_color = normalize_color || color_value[ci] > 1;
						}
					}
					defaults[$ uniform_name] = rpe_effect_parse_anim(raw_uniform, fallback, kind, bpm_points, normalize_color);
				};
			};
		};
		var start_beat = rpe_effect_beat_value(source[$ "start"], 0);
		var end_beat = rpe_effect_beat_value(source[$ "end"], start_beat);
		// PhiZone 显式声明局部效果但省略范围时使用 [0, 8)。
		// Phira 省略 global 和 targetRange 的文件仍走原来的全屏效果。
		var default_layer_range = !is_undefined(source[$ "global"]) && source[$ "global"] == false;
		var has_layer_range = is_struct(source[$ "targetRange"]) || default_layer_range;
		var target_min = -infinity;
		var target_max = infinity;
		if (is_struct(source[$ "targetRange"])) {
			target_min = real(source.targetRange[$ "minZIndex"] ?? -infinity);
			target_max = real(source.targetRange[$ "maxZIndex"] ?? infinity);
		} else if (default_layer_range) {
			target_min = 0;
			target_max = 8;
		};
		var effect_record = {
			shaderName:shader_name,
			externalHlsl:is_external_hlsl,
			externalGlsl:is_external_glsl,
			startTime:rpe_effect_beat_to_second(bpm_points, start_beat),
			endTime:rpe_effect_beat_to_second(bpm_points, end_beat),
			targetMin:target_min,
			targetMax:target_max,
			vars:defaults
		};
		// 显式 global，或没有图层范围，都进全局列表
		var render_global = bool(source[$ "global"] ?? false) || !has_layer_range;
		if (render_global) array_add(result.global, effect_record);
		else array_add(result.local, effect_record);
	};
	return result;
}

///@desc 按内置名返回 GameMaker 着色器资源
///@param {String} shader_name 着色器名
///@returns {Real} 着色器资源，未知为 -1
function rpe_effect_shader_asset(shader_name) {
	// 未知名落到末尾返回 -1
	switch (shader_name) {
		case "chromatic": return shd_rpe_chromatic;
		case "circleBlur": return shd_rpe_circle_blur;
		case "fisheye": return shd_rpe_fisheye;
		case "glitch": return shd_rpe_glitch;
		case "grayscale": return shd_rpe_grayscale;
		case "noise": return shd_rpe_noise;
		case "pixel": return shd_rpe_pixel;
		case "radialBlur": return shd_rpe_radial_blur;
		case "shockwave": return shd_rpe_shockwave;
		case "vignette": return shd_rpe_vignette;
		case "customTint": return shd_rpe_custom_tint;
	};
	return -1;
}

// Android 原生后端用的 Phira 风格 GLSL ES。Windows 仍用 GameMaker 着色器资源；
// 这段源码只在 Android 上经 I_Shaders 编译。
///@desc 返回内置特效在 Android 上使用的 GLSL ES 源码
///@param {String} shader_name 着色器名
///@returns {String} 源码，未知为空串
function rpe_effect_builtin_glsl(shader_name) {
	// 每个分支返回一段完整片元着色器，未知名字落到函数末尾的空串
	switch (shader_name) {
		case "chromatic": return @"
precision mediump float;
varying vec2 uv;
uniform sampler2D screenTexture;
uniform float sampleCount;
uniform float power;
void main() {
    float count = max(2.0, min(64.0, floor(sampleCount + 0.5)));
    vec3 sum = vec3(0.0);
    vec3 c = vec3(0.0);
    vec2 offset = (uv - vec2(0.5)) * vec2(1.0, -1.0);
    for (int i = 0; i < 64; i++) {
        if (float(i) < count) {
            float t = 2.0 * float(i) / max(count - 1.0, 1.0);
            vec3 slice = max(vec3(1.0 - t, 1.0 - abs(t - 1.0), t - 1.0), 0.0);
            sum += slice;
            c += slice * texture2D(screenTexture, uv + (t - 1.0) * power * offset).rgb;
        }
    }
    float alpha = texture2D(screenTexture, uv).a;
    gl_FragColor = vec4(c / max(sum, vec3(0.0001)), alpha);
}
";
		case "circleBlur": return @"
precision mediump float;
varying vec2 uv;
uniform vec2 screenSize;
uniform sampler2D screenTexture;
uniform float size;
void main() {
    float radius = clamp(size, 0.0, 12.0);
    vec4 c = texture2D(screenTexture, uv);
    float best = dot(c, c);
    vec2 pixelSize = 1.0 / max(screenSize, vec2(1.0));
    for (int x = -12; x <= 12; x++) {
        for (int y = -12; y <= 12; y++) {
            float dist2 = float(x * x + y * y);
            if (dist2 <= radius * radius) {
                vec4 candidate = texture2D(screenTexture, uv + pixelSize * vec2(float(x), float(y)));
                float value = dot(candidate, candidate);
                if (value > best) { best = value; c = candidate; }
            }
        }
    }
    gl_FragColor = c;
}
";
		case "fisheye": return @"
precision mediump float;
varying vec2 uv;
uniform vec2 screenSize;
uniform sampler2D screenTexture;
uniform float power;
void main() {
    float aspect = screenSize.x / max(screenSize.y, 1.0);
    vec2 p = vec2(uv.x, uv.y / aspect);
    vec2 centre = vec2(0.5, 0.5 / aspect);
    vec2 delta = p - centre;
    float radius = length(delta);
    vec2 newUv = uv;
    if (radius > 0.000001 && abs(power) > 0.000001) {
        float strength = (6.283184 / (2.0 * length(centre))) * power;
        float bind = strength > 0.0 ? length(centre) : (aspect < 1.0 ? centre.x : centre.y);
        vec2 warped;
        if (strength > 0.0) warped = centre + normalize(delta) * tan(radius * strength) * bind / tan(bind * strength);
        else warped = centre + normalize(delta) * atan(radius * -strength * 10.0) * bind / atan(-strength * bind * 10.0);
        newUv = vec2(warped.x, warped.y * aspect);
    }
    gl_FragColor = texture2D(screenTexture, newUv);
}
";
		case "glitch": return @"
precision highp float;
varying vec2 uv;
uniform sampler2D screenTexture;
uniform float time;
uniform float power;
uniform float rate;
uniform float speed;
uniform float blockCount;
uniform float colorRate;
float truncValue(float value) { return value < 0.0 ? -floor(-value) : floor(value); }
float randomValue(float seed) {
    return fract(543.2543 * sin(dot(vec2(seed), vec2(3525.46, -54.3415))));
}
void main() {
    float enabled = randomValue(truncValue(time * speed)) < rate ? 1.0 : 0.0;
    vec2 fixedUv = uv;
    fixedUv.x += (randomValue((truncValue(uv.y * blockCount) / max(blockCount, 0.001)) + time) - 0.5) * power * enabled;
    vec4 colour = texture2D(screenTexture, fixedUv);
    colour.r = mix(colour.r, texture2D(screenTexture, fixedUv + vec2(colorRate, 0.0)).r, enabled);
    colour.b = mix(colour.b, texture2D(screenTexture, fixedUv - vec2(colorRate, 0.0)).b, enabled);
    gl_FragColor = colour;
}
";
		case "grayscale": return @"
precision mediump float;
varying vec2 uv;
uniform sampler2D screenTexture;
uniform float factor;
void main() {
    vec4 source = texture2D(screenTexture, uv);
    float luminance = dot(vec3(0.299, 0.587, 0.114), source.rgb);
    gl_FragColor = vec4(mix(source.rgb, vec3(luminance), factor), source.a);
}
";
		case "noise": return @"
precision highp float;
varying vec2 uv;
uniform sampler2D screenTexture;
uniform float seed;
uniform float power;
vec2 randomValue(vec2 pos) {
    return fract(sin(vec2(dot(pos, vec2(12.9898, 78.233)), dot(pos, vec2(-148.998, -65.233)))) * 43758.5453);
}
void main() {
    vec2 newUv = uv + (randomValue(uv + vec2(seed, 0.0)) - vec2(0.5)) * power;
    gl_FragColor = texture2D(screenTexture, newUv);
}
";
		case "pixel": return @"
precision mediump float;
varying vec2 uv;
uniform vec2 screenSize;
uniform sampler2D screenTexture;
uniform float size;
void main() {
    vec2 factor = screenSize / max(size, 1.0);
    vec2 pixelUv = floor(uv * factor + vec2(0.5)) / factor;
    gl_FragColor = texture2D(screenTexture, pixelUv);
}
";
		case "radialBlur": return @"
precision mediump float;
varying vec2 uv;
uniform sampler2D screenTexture;
uniform float centerX;
uniform float centerY;
uniform float power;
uniform float sampleCount;
void main() {
    float count = max(1.0, min(64.0, floor(sampleCount + 0.5)));
    vec2 direction = uv - vec2(centerX, centerY);
    vec3 c = vec3(0.0);
    for (int i = 0; i < 64; i++) {
        if (float(i) < count) {
            c += texture2D(screenTexture, uv - power * direction * float(i)).rgb / count;
        }
    }
    float alpha = texture2D(screenTexture, uv).a;
    gl_FragColor = vec4(c, alpha);
}
";
		case "shockwave": return @"
precision mediump float;
varying vec2 uv;
uniform vec2 screenSize;
uniform sampler2D screenTexture;
uniform float progress;
uniform float centerX;
uniform float centerY;
uniform float width;
uniform float distortion;
uniform float expand;
void main() {
    float aspect = screenSize.y / max(screenSize.x, 1.0);
    vec2 centre = vec2(centerX, (centerY - 0.5) * aspect + 0.5);
    vec2 coord = vec2(uv.x, (uv.y - 0.5) * aspect + 0.5);
    float dist = distance(coord, centre);
    vec2 sampleUv = uv;
    float glow = 0.0;
    if (progress > 0.0001 && dist > 0.0001 && progress - width <= dist && dist <= progress + width) {
        float diff = dist - progress;
        float scaleDiff = 1.0 - pow(abs(diff * expand), distortion);
        float denom = max(progress * dist * 40.0, 0.0001);
        coord += normalize(coord - centre) * diff * scaleDiff / denom;
        sampleUv = vec2(coord.x, (coord.y - 0.5) / max(aspect, 0.0001) + 0.5);
        glow = scaleDiff / denom;
    }
    vec4 colour = texture2D(screenTexture, sampleUv);
    gl_FragColor = colour + colour * glow;
}
";
		case "vignette": return @"
precision mediump float;
varying vec2 uv;
uniform sampler2D screenTexture;
uniform vec2 screenSize;
uniform vec4 color;
uniform float extend;
uniform float radius;
void main() {
    vec4 src = texture2D(screenTexture, uv);
    vec2 suv = (screenSize.x > 1.0) ? (gl_FragCoord.xy / screenSize) : uv;
    vec2 value = suv * (1.0 - suv.yx);
    float vig = clamp(pow(max(value.x * value.y * radius, 0.0), extend), 0.0, 1.0);
    vec3 rgb = mix(color.rgb * src.a, src.rgb, vig);
    gl_FragColor = vec4(rgb, src.a);
}
";
		case "customTint": return @"
precision mediump float;
varying vec2 uv;
uniform sampler2D screenTexture;
uniform float factor;
void main() {
    vec4 source = texture2D(screenTexture, uv);
    gl_FragColor = mix(source, vec4(1.0, 0.0, 0.0, 1.0), factor);
}
";
	};
	return "";
}
