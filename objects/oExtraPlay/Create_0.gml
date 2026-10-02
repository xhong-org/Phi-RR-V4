/// @description Load and normalize RPE extra.json videos and effects.
// In front of oBG_1 so the background video cannot paint over the chart dim.
depth = DEPTH.BG - 2;
videos = [];
video_layers = [];
video_chart_time = 0;
video_last_chart_time = -infinity;
video_backend_ready = false;
video_os_paused = false;
effect_controller = -1;
requests_chart_layers = false;

var extra_path = "";
var extra_allowed = true;
if (variable_global_exists("chart_session") && is_struct(global.chart_session) && global.chart_session.ready) {
	if (is_string(global.chart_session.extra_file) && string_length(global.chart_session.extra_file)) {
		extra_path = chart_path_join(InChartPath, global.chart_session.extra_file);
	} else {
		extra_allowed = false;
	};
};
if (extra_allowed && !string_length(extra_path)) then extra_path = chart_path_join(InChartPath, "extra.json");
var extra_root = string_length(extra_path) ? chart_path_dir(extra_path) : InChartPath;

if (string_length(extra_path) && chart_file_exists_any(extra_path)) {
	if (os_type == os_windows && extension_exists("FFVideos")) {
		var video_d3d_info = os_get_info();
		if (ds_exists(video_d3d_info, ds_type_map)
			&& ds_map_exists(video_d3d_info, "video_d3d11_device")
			&& ds_map_exists(video_d3d_info, "video_d3d11_context")) {
			video_backend_ready = ffvideos_ext_initialize(
				video_d3d_info[? "video_d3d11_device"],
				video_d3d_info[? "video_d3d11_context"]) == 3;
		};
		if (ds_exists(video_d3d_info, ds_type_map)) then ds_map_destroy(video_d3d_info);
	} else if (os_type == os_android) {
		video_backend_ready = ffvideos_ext_initialize(pointer_null, pointer_null) == 3;
		if (video_backend_ready) then print("[FFVideos] Android MediaCodec backend ready");
	} else if (pls_is_gxgames()) {
		video_backend_ready = ffvideos_ext_initialize(pointer_null, pointer_null) == 3;
		print($"[GXVideo] ping={video_backend_ready ? 1 : 0} error={ffvideos_ext_get_error(0)}");
		if (video_backend_ready) then print("[GXVideo] HTMLVideo backend ready");
		else print("[GXVideo] HTMLVideo backend waiting; Step will retry ping");
	};
	if (!video_backend_ready && !pls_is_gxgames()) then print($"[FFVideos] Initialization failed: {ffvideos_ext_get_error(0)}");
};

var read_extra_text = function(path) {
	if (!is_string(path) || !string_length(path)) then return "";
	var native_text = chart_read_text_file(path, -1);
	if (is_string(native_text) && string_length(native_text)) then return native_text;
	var handle = file_text_open_read(chart_file_readable_path(path));
	if (is_undefined(handle) || handle < 0) then return "";
	var temp = buffer_create(65536, buffer_grow, 1);
	while (!file_text_eof(handle)) {
		buffer_write(temp, buffer_text, file_text_readln(handle));
		buffer_write(temp, buffer_text, "\n");
	};
	file_text_close(handle);
	var text = "";
	if (buffer_tell(temp) > 0) {
		buffer_seek(temp, buffer_seek_start, 0);
		text = buffer_read(temp, buffer_text);
	};
	buffer_delete(temp);
	return is_string(text) ? text : "";
};

extra_beat_value = function(value, fallback = 0) {
	if (is_array(value) && array_length(value) >= 3) {
		var denominator = real(value[2]);
		if (denominator != 0) then return real(value[0]) + real(value[1]) / denominator;
	};
	if (is_real(value)) then return value;
	return fallback;
};

var extra_text = "";
if (extra_allowed && string_length(extra_path) && chart_file_exists_any(extra_path)) {
	extra_text = read_extra_text(extra_path);
};
var extra = undefined;
if (string_length(extra_text)) {
	try { extra = json_parse(extra_text); } catch (error) { delete(error); };
};
delete(extra_text);

if (is_struct(extra)) {
	extra_bpm_points = [];
	var extra_bpm = extra[$ "bpm"];
	if (is_real(extra_bpm) && extra_bpm > 0) {
		array_add(extra_bpm_points, { beat: 0, second: 0, bpm: extra_bpm });
	} else if (is_array(extra_bpm)) {
		for (var bpm_i = 0; bpm_i < array_length(extra_bpm); bpm_i++) {
			var bpm_item = extra_bpm[bpm_i];
			if (is_struct(bpm_item) && real(bpm_item[$ "bpm"] ?? 0) > 0) {
				array_add(extra_bpm_points, { beat: extra_beat_value(bpm_item[$ "time"], 0), second: 0, bpm: real(bpm_item[$ "bpm"]) });
			};
		};
	};
	if (array_length(extra_bpm_points) <= 0) then array_add(extra_bpm_points, { beat: 0, second: 0, bpm: 120 });
	array_sort(extra_bpm_points, function(a, b) { return sign(a.beat - b.beat); });
	for (var bpm_j = 1; bpm_j < array_length(extra_bpm_points); bpm_j++) {
		var previous_bpm = extra_bpm_points[bpm_j - 1];
		extra_bpm_points[bpm_j].second = previous_bpm.second + (extra_bpm_points[bpm_j].beat - previous_bpm.beat) * 60 / previous_bpm.bpm;
	};
	extra_beat_to_second = function(beat) {
		var point = extra_bpm_points[0];
		for (var point_i = 1; point_i < array_length(extra_bpm_points); point_i++) {
			if (extra_bpm_points[point_i].beat > beat) then break;
			point = extra_bpm_points[point_i];
		};
		return point.second + (beat - point.beat) * 60 / point.bpm;
	};
	extra_parse_anim = function(raw, fallback) {
		if (!is_array(raw)) then return { fixed: true, value: real(raw ?? fallback), events: [] };
		var result = { fixed: false, value: fallback, events: [] };
		for (var anim_i = 0; anim_i < array_length(raw); anim_i++) {
			var event = raw[anim_i];
			if (!is_struct(event)) then continue;
			array_add(result.events, {
				startTime: extra_beat_to_second(extra_beat_value(event[$ "startTime"], 0)),
				endTime: extra_beat_to_second(extra_beat_value(event[$ "endTime"], 0)),
				start: real(event[$ "start"] ?? fallback),
				"end" : real(event[$ "end"] ?? fallback),
				easingType: real(event[$ "easingType"] ?? 1),
				easingLeft: real(event[$ "easingLeft"] ?? 0),
				easingRight: real(event[$ "easingRight"] ?? 1)
			});
		};
		array_sort(result.events, function(a, b) { return sign(a.startTime - b.startTime); });
		return result;
	};
	extra_video_scale = function(raw) {
		var mode = string_lower(string(raw ?? "cropCenter"));
		if (mode == "fit") then return "fit";
		if (mode == "inside") then return "inside";
		return "cropCenter";
	};
	extra_video_attach = function(raw) {
		if (!is_struct(raw)) then return undefined;
		var line_id = floor(real(raw[$ "line"] ?? -1));
		if (line_id < 0) then return undefined;
		// Omitted factors keep the previous behaviour (fully follow the line).
		// An explicit 0 is PhiZone's "do not inherit", which leaves cropCenter
		// centred on the chart view instead of riding the line off the frame.
		var has_x = is_real(raw[$ "positionXFactor"]);
		var has_y = is_real(raw[$ "positionYFactor"]);
		return {
			line: line_id,
			position_x_factor: (has_x ? real(raw[$ "positionXFactor"]) : 1),
			position_y_factor: (has_y ? real(raw[$ "positionYFactor"]) : 1),
			scale_x_mode: floor(real(raw[$ "scaleXMode"] ?? 0)),
			scale_y_mode: floor(real(raw[$ "scaleYMode"] ?? 0))
		};
	};
	sample_anim = function(anim, chart_time) {
		if (anim.fixed || !is_array(anim.events) || array_length(anim.events) <= 0) then return anim.value;
		var sampled = anim.value;
		for (var sample_i = 0; sample_i < array_length(anim.events); sample_i++) {
			var sample_event = anim.events[sample_i];
			if (chart_time < sample_event.startTime) then break;
			if (chart_time <= sample_event.endTime) {
				return tween_execute(chart_time, sample_event.startTime, sample_event.endTime,
					sample_event.start, sample_event[$ "end"], sample_event.easingType,
					sample_event.easingLeft, sample_event.easingRight);
			};
			sampled = sample_event[$ "end"];
		};
		return sampled;
	};
	var raw_videos = (is_array(extra[$ "videos"]) ? extra.videos : []);
	for (var video_i = 0; video_i < array_length(raw_videos); video_i++) {
		var source = raw_videos[video_i];
		if (!is_struct(source) || !is_string(source[$ "path"])) then continue;
		var relative_path = string_replace_all(source.path, "\\", "/");
		if (string_pos("..", relative_path) > 0 || string_char_at(relative_path, 1) == "/") then continue;
		if (is_real(source[$ "zIndex"])) then requests_chart_layers = true;
		array_add(videos, {
			path: chart_file_readable_path(chart_path_join(extra_root, relative_path)),
			startTime: extra_beat_to_second(extra_beat_value(source[$ "time"], 0)),
			endTime: infinity,
			duration_ms: 0,
			scale: extra_video_scale(source[$ "scale"] ?? "cropCenter"),
			zIndex: (is_real(source[$ "zIndex"] ?? undefined) ? real(source[$ "zIndex"]) : undefined),
			attach: extra_video_attach(source[$ "attach"] ?? undefined),
			alpha: extra_parse_anim(source[$ "alpha"], 1),
			dim: extra_parse_anim(source[$ "dim"], 0),
			handle: -1,
			error_logged: false,
			draw_logged: false,
			completed: false,
			clip_surface: -1
	});
	};
	array_sort(videos, function(a, b) { return sign(a.startTime - b.startTime); });
	print($"[FFVideos] Parsed videos={array_length(videos)}, extra={extra_path}");
	for (var video_log_i = 0; video_log_i < array_length(videos); video_log_i++) {
		var video_log_path = videos[video_log_i].path;
		var video_log_host = gx_media_host_path_for(video_log_path);
		print($"[FFVideos] Video[{video_log_i}] path={video_log_path}, exists={gx_media_source_exists(video_log_path)}, host={video_log_host}, start={videos[video_log_i].startTime}");
	};
	if (is_array(extra[$ "effects"])) {
		for (var layer_effect_i = 0; layer_effect_i < array_length(extra.effects); layer_effect_i++) {
			var layer_effect = extra.effects[layer_effect_i];
			if (is_struct(layer_effect) && is_struct(layer_effect[$ "targetRange"])) {
				requests_chart_layers = true;
				break;
			};
		};
	};
	var parsed_effects = rpe_effect_parse(extra, extra_bpm_points);
	print($"[RPE Effect] Parsed shaders: local={array_length(parsed_effects.local)}, global={array_length(parsed_effects.global)}");
	if (array_length(parsed_effects.local) > 0 || array_length(parsed_effects.global) > 0) {
		var effect_depth = requests_chart_layers ? chart_layer_depth(24) : (DEPTH.DEBUG + 1);
		effect_controller = instance_create_depth(0, 0, effect_depth, oRPEEffect, {
			effects_local:parsed_effects.local,
			effects_global:parsed_effects.global
		});
	};
};

// A video plays until its own file ends. The next clip does not replace it.
// PhiZone uses start + duration, so a higher layer can cover the one under it.
for (var video_layer_i = 0; video_layer_i < array_length(videos); video_layer_i++) {
	if (!is_real(videos[video_layer_i].zIndex)) then continue;
	array_add(video_layers, instance_create_depth(0, 0, chart_layer_depth(videos[video_layer_i].zIndex), oExtraVideoLayer, {
		video_layer_owner: id,
		video_layer_index: video_layer_i
	}));
};

video_close_all = function() {
	for (var _close_i = 0; _close_i < array_length(videos); _close_i++) {
		if (videos[_close_i].handle >= 0) then ffvideos_ext_close(videos[_close_i].handle);
		videos[_close_i].handle = -1;
	};
};

// Active attachment for this line. A clip without its own z is painted with the
// line; one with z is only reported so the line can stay on its own layer.
video_line_index = function(line_instance) {
	if (chart_setting_on("disableChartVideo") || !instance_exists(line_instance)) then return -1;
	var _layered = -1;
	for (var _line_i = 0; _line_i < array_length(videos); _line_i++) {
		var _line_video = videos[_line_i];
		if (_line_video.handle < 0 || !is_struct(_line_video.attach)) then continue;
		if (_line_video.attach.line != line_instance.line_id) then continue;
		if (!is_real(_line_video.zIndex)) then return _line_i;
		if (_layered < 0) then _layered = _line_i;
	};
	return _layered;
};

video_attached_to_line = function(line_instance) {
	return video_line_index(line_instance) >= 0;
};

video_draw_index = function(_index) {
	if (chart_setting_on("disableChartVideo")) then return;
	if (_index < 0 || _index >= array_length(videos)) then return;
	var _draw_video = videos[_index];
	if (_draw_video.handle < 0 || _draw_video.completed) then return;
	if (video_chart_time < _draw_video.startTime || video_chart_time >= _draw_video.endTime) then return;
	if (is_struct(_draw_video.attach)) then draw_attached_video(_index);
	else video_draw_fullscreen(_index);
};

draw_attached_video = function(_index) {
	if (chart_setting_on("disableChartVideo")) then return;
	if (_index < 0 || _index >= array_length(videos)) then return;
	var video = videos[_index];
	if (video.handle < 0 || !is_struct(video.attach)) then return;
	var line_instance = noone;
	var attached_id = video.attach.line;
	if (variable_global_exists("game_1") && is_struct(game_1) && is_array(game_1.line_list)
		&& attached_id >= 0 && attached_id < array_length(game_1.line_list)) {
		line_instance = game_1.line_list[attached_id];
	};
	if (!instance_exists(line_instance)) then return;
	var _handle = video.handle;
	var status = ffvideos_ext_get_status(_handle);
	// Render mode prepares an exact frame without entering Playing/Paused.
	// Ended is also valid here because the decoder can retain the prepared
	// final frame; only states without a drawable frame are rejected.
	if (status == FFVideosStatus.Preparing) {
		ffvideos_ext_draw(_handle, 0, 0, 0, 0, 0, 0);
		return;
	};
	if (status == FFVideosStatus.Error || status == FFVideosStatus.Closed) then return;
	var video_width = ffvideos_ext_get_width(_handle);
	var video_height = ffvideos_ext_get_height(_handle);
	if (video_width <= 0 || video_height <= 0) {
		ffvideos_ext_draw(_handle, 0, 0, 0, 0, 0, 0);
		video_width = ffvideos_ext_get_width(_handle);
		video_height = ffvideos_ext_get_height(_handle);
	};
	if (video_width <= 0 || video_height <= 0) then return;

	var sx = chart_view_width / video_width;
	var sy = chart_view_height / video_height;
	var draw_sx = (video.scale == "fit" ? sx : (video.scale == "inside" ? min(sx, sy) : max(sx, sy)));
	var draw_sy = (video.scale == "fit" ? sy : draw_sx);
	// scaleXMode 1 scales. Mode 2/3 clip; they must not shrink the picture.
	if (video.attach.scale_x_mode == 1) then draw_sx *= max(0, real(line_instance.__scale_x));
	if (video.attach.scale_y_mode == 1) then draw_sy *= max(0, real(line_instance.__scale_y));
	var draw_width = video_width * draw_sx;
	var draw_height = video_height * draw_sy;
	var center_x = chart_view_left + chart_view_width * 0.5;
	var center_y = chart_view_height * 0.5;
	var anchor_x = center_x + (line_instance.x - center_x) * video.attach.position_x_factor;
	var anchor_y = center_y + (line_instance.y - center_y) * video.attach.position_y_factor;
	var draw_x = anchor_x - draw_width * 0.5;
	var draw_y = anchor_y - draw_height * 0.5;
	var alpha = clamp(real(video.alpha.value), 0, 1);
	var dim = clamp(real(video.dim.value), 0, 1);
	var clip_w = draw_width;
	var clip_h = draw_height;
	if (video.attach.scale_x_mode == 2) then clip_w = chart_line_pixel_width(line_instance);
	else if (video.attach.scale_x_mode == 3) then clip_w = draw_width * max(0, abs(real(line_instance.__scale_x)));
	if (video.attach.scale_y_mode == 2) then clip_h = draw_height * max(0, abs(real(line_instance.__scale_y)));
	var mask_x = anchor_x - clip_w * 0.5;
	var mask_y = anchor_y - clip_h * 0.5;
	var needs_clip = (clip_w + 0.5 < draw_width) || (clip_h + 0.5 < draw_height);
	pls_draw_flush();
	chart_mask_scissor_clear();
	// scaleXMode 2/3 is a mask, not a scale. FFVideos draws straight into the
	// current D3D target and ignores a nested surface, so the old fallback
	// painted the whole frame and covered the chart. Scissor the line strip
	// on the same target the unclipped draw already uses.
	if (needs_clip && clip_w > 1 && clip_h > 1) {
		var scissor_x = max(0, floor(mask_x));
		var scissor_y = max(0, floor(mask_y));
		var scissor_r = ceil(mask_x + clip_w);
		var scissor_b = ceil(mask_y + clip_h);
		if (variable_global_exists("chart_view_right") && is_real(chart_view_right)) {
			scissor_r = min(scissor_r, ceil(chart_view_right));
		};
		if (variable_global_exists("chart_view_height") && is_real(chart_view_height)) {
			scissor_b = min(scissor_b, ceil(chart_view_height));
		};
		gpu_set_scissor(scissor_x, scissor_y, max(1, scissor_r - scissor_x), max(1, scissor_b - scissor_y));
	};
	if (clip_w > 1 && clip_h > 1) {
		ffvideos_ext_draw(_handle,
			draw_x / room_width, draw_y / room_height,
			(draw_x + draw_width) / room_width, (draw_y + draw_height) / room_height,
			alpha, dim);
	};
	chart_mask_scissor_set();
	rpe_effect_grade_backdrop();
};

video_draw_fullscreen = function(_index) {
	if (_index < 0 || _index >= array_length(videos)) then return;
	var video = videos[_index];
	if (video.handle < 0) then return;
	var _handle = video.handle;
	var status = ffvideos_ext_get_status(_handle);
	if (status == FFVideosStatus.Preparing || ffvideos_ext_get_width(_handle) <= 0) {
		var surface_status = ffvideos_ext_draw(_handle, 0, 0, 0, 0, 0, 0);
		if (surface_status < 0 && !video.error_logged) {
			print($"[FFVideos] Surface/draw setup: status={surface_status}, error={ffvideos_ext_get_error(_handle)}");
		};
		status = ffvideos_ext_get_status(_handle);
	};
	if (status != FFVideosStatus.Playing && status != FFVideosStatus.Paused) then return;
	var video_width = ffvideos_ext_get_width(_handle);
	var video_height = ffvideos_ext_get_height(_handle);
	if (video_width <= 0 || video_height <= 0) {
		ffvideos_ext_draw(_handle, 0, 0, 0, 0, 0, 0);
		video_width = ffvideos_ext_get_width(_handle);
		video_height = ffvideos_ext_get_height(_handle);
	};
	if (video_width <= 0 || video_height <= 0) then return;
	var scale_mode = video.scale;
	var sx = chart_view_width / video_width;
	var sy = chart_view_height / video_height;
	var draw_sx;
	var draw_sy;
	switch (scale_mode) {
		case "fit":
			draw_sx = sx;
			draw_sy = sy;
		break;
		case "inside":
			draw_sx = min(sx, sy);
			draw_sy = draw_sx;
		break;
		default:
			draw_sx = max(sx, sy);
			draw_sy = draw_sx;
		break;
	};
	var draw_width = video_width * draw_sx;
	var draw_height = video_height * draw_sy;
	var draw_x = chart_view_left + (chart_view_width - draw_width) * 0.5;
	var draw_y = (chart_view_height - draw_height) * 0.5;
	var alpha = clamp(real(video.alpha.value), 0, 1);
	var dim = clamp(real(video.dim.value), 0, 1);
	pls_draw_flush();
	// FFVideos reads the raw D3D11 target and viewport. A nested mask surface
	// leaves that viewport empty, so the draw returns 0 and the later mask blit
	// covers the missing frame. Draw straight into the chart surface; the mask
	// composite keeps only the viewport.
	chart_mask_scissor_clear();
	var video_draw_status = ffvideos_ext_draw(_handle,
		draw_x / room_width,
		draw_y / room_height,
		(draw_x + draw_width) / room_width,
		(draw_y + draw_height) / room_height,
		alpha,
		dim);
	chart_mask_scissor_set();
	if (video_draw_status < 0) {
		if (!video.error_logged) {
			print($"[FFVideos] Draw failed: status={status}, size={video_width}x{video_height}, error={ffvideos_ext_get_error(_handle)}");
			video.error_logged = true;
		};
	} else if (!video.draw_logged) {
		print($"[FFVideos] Draw: status={status}, size={video_width}x{video_height}, draw={video_draw_status}, error={ffvideos_ext_get_error(_handle)}");
		video.draw_logged = true;
	};
};
