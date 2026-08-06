function rpe_effect_beat_to_second(points, beat) {
	if (!is_array(points) || array_length(points) <= 0) then return 0;
	var point = points[0];
	for (var point_i = 1; point_i < array_length(points); point_i++) {
		if (points[point_i].beat > beat) then break;
		point = points[point_i];
	};
	return point.second + (beat - point.beat) * 60 / point.bpm;
}

function rpe_effect_beat_value(value, fallback = 0) {
	if (is_array(value) && array_length(value) >= 3) {
		var denominator = real(value[2]);
		if (denominator != 0) then return real(value[0]) + real(value[1]) / denominator;
	};
	if (is_real(value)) then return value;
	return fallback;
}

function rpe_effect_value(raw, kind, normalize_color = false) {
	if (kind == 1) then return real(raw ?? 0);
	var count = (kind == 2 ? 2 : 4);
	var result = array_create(count, 0);
	if (is_array(raw)) {
		for (var value_i = 0; value_i < min(count, array_length(raw)); value_i++) {
			result[@ value_i] = real(raw[value_i]);
		};
	};
	if (normalize_color && kind == 4) {
		for (var color_i = 0; color_i < 4; color_i++) result[@ color_i] /= 255;
	};
	return result;
}

function rpe_effect_anim_fixed(value, kind) {
	return { kind:kind, fixed:true, value:value, events:[] };
}

function rpe_effect_easing_type(value) {
	static map = [0, 1, 3, 2, 6, 5, 4, 7, 9, 8, 12, 11, 10, 13, 15, 14, -1, 17, 16, -1, 19, 18, 22, 21, 20, 23, 25, 24, -1, 27, 26, 28];
	var index = clamp(floor(real(value)), 0, array_length(map) - 1);
	var mapped = map[index];
	return mapped < 0 ? EASE_TYPE.LINEAR : mapped;
}

function rpe_effect_parse_anim(raw, fallback, kind, bpm_points) {
	if (!is_array(raw) || (kind > 1 && array_length(raw) == kind && (array_length(raw) <= 0 || !is_struct(raw[0])))) {
		return rpe_effect_anim_fixed(rpe_effect_value(raw ?? fallback, kind, kind == 4), kind);
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
			start:rpe_effect_value(source_event[$ "start"] ?? fallback, kind, kind == 4),
			"end":rpe_effect_value(source_event[$ "end"] ?? fallback, kind, kind == 4),
			easingType:rpe_effect_easing_type(source_event[$ "easingType"] ?? 1),
			easingLeft:real(source_event[$ "easingLeft"] ?? 0),
			easingRight:real(source_event[$ "easingRight"] ?? 1)
		});
	};
	array_sort(result.events, function(a, b) { return sign(a.startTime - b.startTime); });
	if (array_length(result.events) <= 0) then return rpe_effect_anim_fixed(fallback, kind);
	result.value = result.events[0].start;
	return result;
}

function rpe_effect_tween_value(now, start_time, end_time, start_value, end_value, kind, easing = 1, left = 0, right = 1) {
	if (end_time <= start_time) then return end_value;
	if (kind == 1) then return tween_execute(now, start_time, end_time, start_value, end_value, easing, left, right);
	var result = array_create(kind, 0);
	for (var component_i = 0; component_i < kind; component_i++) {
		result[@ component_i] = tween_execute(now, start_time, end_time, start_value[component_i], end_value[component_i], easing, left, right);
	};
	return result;
}

function rpe_effect_sample_anim(anim, chart_time) {
	if (anim.fixed || !is_array(anim.events) || array_length(anim.events) <= 0) then return anim.value;
	var events = anim.events;
	if (chart_time < events[0].startTime) then return events[0].start;
	for (var event_i = 0; event_i < array_length(events); event_i++) {
		var current_event = events[event_i];
		if (chart_time >= current_event.startTime && chart_time < current_event.endTime) {
			return rpe_effect_tween_value(chart_time, current_event.startTime, current_event.endTime,
				current_event.start, current_event[$ "end"], anim.kind,
				current_event.easingType, current_event.easingLeft, current_event.easingRight);
		};
		if (event_i + 1 < array_length(events)) {
			var next_event = events[event_i + 1];
			if (chart_time < next_event.startTime) {
				return rpe_effect_tween_value(chart_time, current_event.endTime, next_event.startTime,
					current_event[$ "end"], next_event.start, anim.kind);
			};
		};
	};
	return events[array_length(events) - 1][$ "end"];
}

function rpe_effect_defaults(shader_name) {
	var defaults = {};
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

function rpe_effect_external_mapping(shader_path) {
	var relative_path = string_delete(shader_path, 1, 1);
	relative_path = string_replace_all(relative_path, "\\", "/");
	if (!string_length(relative_path) || string_pos("..", relative_path) > 0 || string_pos(":", relative_path) > 0) then return "";
	var full_path = chart_extra_asset_path(relative_path);
	if (!file_exists(full_path)) {
		print($"[RPE Effect] Missing external shader: {relative_path}");
		return "";
	};
	var lower_path = string_lower(relative_path);
	if (string_copy(lower_path, max(1, string_length(lower_path) - 4), 5) == ".hlsl") {
		return "@hlsl:" + relative_path;
	};
	var is_glsl_path = (string_copy(lower_path, max(1, string_length(lower_path) - 2), 3) == ".fs"
		|| string_copy(lower_path, max(1, string_length(lower_path) - 4), 5) == ".glsl"
		|| string_copy(lower_path, max(1, string_length(lower_path) - 3), 4) == ".fsh");
	if (is_glsl_path) then return "@glsl:" + relative_path;
	var handle = file_text_open_read(full_path);
	if (is_undefined(handle) || handle < 0) then return "";
	var source = "";
	while (!file_text_eof(handle)) source += file_text_readln(handle) + "\n";
	file_text_close(handle);
	var probe = string_lower(relative_path + "\n" + source);
	var compact = string_replace_all(string_replace_all(string_replace_all(string_replace_all(probe, " ", ""), "\t", ""), "\r", ""), "\n", "");
	if ((string_pos("gl_fragcolor=mix(texture2d(screentexture,uv),vec4(1.0,0.0,0.0,1.0),factor)", compact) > 0)
		|| (string_pos("lerp(", compact) > 0 && string_pos("float4(1", compact) > 0 && string_pos("factor", compact) > 0)) return "customTint";
	var names = ["chromatic", "circleBlur", "fisheye", "glitch", "grayscale", "noise", "pixel", "radialBlur", "shockwave", "vignette", "customTint"];
	for (var name_i = 0; name_i < array_length(names); name_i++) {
		var shader_name = names[name_i];
		var lower_name = string_lower(shader_name);
		if (string_pos("@gamemaker-effect " + lower_name, probe) > 0
			|| string_pos("/" + lower_name + ".", probe) > 0
			|| string_pos("/" + string_replace_all(lower_name, "blur", "_blur") + ".", probe) > 0) return shader_name;
	};
	print($"[RPE Effect] GLSL runtime translation is unavailable; use HLSL or add '// @gamemaker-effect <builtin>': {relative_path}");
	return "";
}

function rpe_effect_external_defaults(shader_name) {
	var result = {};
	var separator = string_pos(":", shader_name);
	if (separator <= 0) then return result;
	var relative_path = string_delete(shader_name, 1, separator);
	var full_path = chart_extra_asset_path(relative_path);
	if (!file_exists(full_path)) then return result;
	var handle = file_text_open_read(full_path);
	if (is_undefined(handle) || handle < 0) then return result;
	while (!file_text_eof(handle)) {
		var shader_line = string_trim(string_replace_all(file_text_readln(handle), "\t", " "));
		if (string_pos("uniform ", shader_line) != 1) then continue;
		var semicolon = string_pos(";", shader_line);
		var first_percent = string_pos("%", shader_line);
		if (semicolon <= 0 || first_percent <= semicolon) then continue;
		var default_tail = string_delete(shader_line, 1, first_percent);
		var second_percent = string_pos("%", default_tail);
		if (second_percent <= 0) then continue;
		var declaration = string_trim(string_copy(shader_line, 9, semicolon - 9));
		var declaration_parts_raw = string_split(declaration, " ");
		var declaration_parts = [];
		for (var part_i = 0; part_i < array_length(declaration_parts_raw); part_i++) {
			var part = string_trim(declaration_parts_raw[part_i]);
			if (string_length(part)) array_add(declaration_parts, part);
		};
		if (array_length(declaration_parts) < 2) then continue;
		var uniform_type = declaration_parts[0];
		var uniform_name = declaration_parts[1];
		var default_text = string_trim(string_copy(default_tail, 1, second_percent - 1));
		var kind = 1;
		var value = 0;
		if (uniform_type == "vec2" || uniform_type == "vec4") {
			kind = (uniform_type == "vec2" ? 2 : 4);
			var values = string_split(default_text, ",");
			if (array_length(values) < kind) then continue;
			value = array_create(kind, 0);
			for (var component_i = 0; component_i < kind; component_i++) {
				value[@ component_i] = real(string_trim(values[component_i]));
			};
		} else if (uniform_type == "float") {
			value = real(default_text);
		} else {
			continue;
		};
		result[$ uniform_name] = rpe_effect_anim_fixed(value, kind);
	};
	file_text_close(handle);
	return result;
}

function rpe_effect_parse(extra, bpm_points) {
	var result = { local:[], global:[] };
	if (!is_struct(extra) || !is_array(extra[$ "effects"])) then return result;
	for (var effect_i = 0; effect_i < array_length(extra.effects); effect_i++) {
		var source = extra.effects[effect_i];
		if (!is_struct(source) || !is_string(source[$ "shader"])) then continue;
		var shader_name = source.shader;
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
					else if (is_array(raw_probe) && array_length(raw_probe) == 4) { kind = 4; fallback = [0,0,0,0]; };
				};
				if (is_undefined(raw_uniform)) {
					defaults[$ uniform_name] = rpe_effect_anim_fixed(kind == 1 ? 0 : array_create(kind, 0), kind);
				} else {
					defaults[$ uniform_name] = rpe_effect_parse_anim(raw_uniform, fallback, kind, bpm_points);
				};
			};
		};
		var start_beat = rpe_effect_beat_value(source[$ "start"], 0);
		var end_beat = rpe_effect_beat_value(source[$ "end"], start_beat);
		var effect_record = {
			shaderName:shader_name,
			externalHlsl:is_external_hlsl,
			externalGlsl:is_external_glsl,
			startTime:rpe_effect_beat_to_second(bpm_points, start_beat),
			endTime:rpe_effect_beat_to_second(bpm_points, end_beat),
			vars:defaults
		};
		if (bool(source[$ "global"] ?? false)) array_add(result.global, effect_record);
		else array_add(result.local, effect_record);
	};
	return result;
}

function rpe_effect_shader_asset(shader_name) {
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
