/// @description Load and normalize RPE extra.json videos and effects.
depth = DEPTH.BG - 1;
videos = [];
video_index = -1;
video_completed = -1;
video_chart_time = 0;
video_last_chart_time = -infinity;
video_handle = -1;
video_backend_ready = false;
video_error_logged = false;
effect_controller = -1;

if (os_type == os_windows && extension_exists("FFVideos")) {
	var video_d3d_info = os_get_info();
	if (ds_exists(video_d3d_info, ds_type_map)
		&& ds_map_exists(video_d3d_info, "video_d3d11_device")
		&& ds_map_exists(video_d3d_info, "video_d3d11_context")) {
		video_backend_ready = ffvideos_initialize(
			video_d3d_info[? "video_d3d11_device"],
			video_d3d_info[? "video_d3d11_context"]) == 3;
	};
	if (ds_exists(video_d3d_info, ds_type_map)) then ds_map_destroy(video_d3d_info);
	if (!video_backend_ready) then print($"[FFVideos] Initialization failed: {ffvideos_get_error(0)}");
};

var read_extra_text = function(path) {
	var handle = file_text_open_read(path);
	if (is_undefined(handle) || handle < 0) then return "";
	var temp = buffer_create(65536, buffer_grow, 1);
	while (!file_text_eof(handle)) {
		buffer_write(temp, buffer_text, file_text_readln(handle));
		buffer_write(temp, buffer_text, "\n");
	};
	file_text_close(handle);
	buffer_seek(temp, buffer_seek_start, 0);
	var text = buffer_read(temp, buffer_text);
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

var extra_text = read_extra_text(InChartPath + "extra.json");
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
		array_add(videos, {
			path: InChartPath + relative_path,
			startTime: extra_beat_to_second(extra_beat_value(source[$ "time"], 0)),
			scale: string(source[$ "scale"] ?? "cropCenter"),
			alpha: extra_parse_anim(source[$ "alpha"], 1),
			dim: extra_parse_anim(source[$ "dim"], 0)
		});
	};
	array_sort(videos, function(a, b) { return sign(a.startTime - b.startTime); });
	var parsed_effects = rpe_effect_parse(extra, extra_bpm_points);
	if (array_length(parsed_effects.local) > 0 || array_length(parsed_effects.global) > 0) {
		effect_controller = instance_create_depth(0, 0, DEPTH.DEBUG + 1, oRPEEffect, {
			effects_local:parsed_effects.local,
			effects_global:parsed_effects.global
		});
	};
};

for (var video_end_i = 0; video_end_i < array_length(videos); video_end_i++) {
	videos[video_end_i].endTime = (video_end_i + 1 < array_length(videos) ? videos[video_end_i + 1].startTime : infinity);
};
