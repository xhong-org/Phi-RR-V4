/// @desc Shared RPE line event preprocess. Native speed-fit is optional and
/// can be disabled with RPE_LINE_PREP_NATIVE without deleting the DLL.

#macro RPE_LINE_PREP_NATIVE true

function rpe_map_easing_id(raw) {
	static map = [ 0, 1, 3, 2, 6, 5, 4, 7, 9, 8, 12, 11, 10, 13, 15, 14, -1, 17, 16, -1, 19, 18, 22, 21, 20, 23, 25, 24, -1, 27, 26, 28 ];
	var t = floor(real(raw ?? 1));
	if (!is_real(t) || t <= 1) then return 1;
	var n = array_length(map);
	for (var i = 0; i < n; i++) {
		if (is_real(map[i]) && map[i] == t) {
			if (i <= 1) then return 1;
			if (i >= 32) then return 1;
			return i;
		};
	};
	return 1;
}

function rpe_event_time_cmp(a, b) {
	if (a.startTime < b.startTime) then return -1;
	if (a.startTime > b.startTime) then return 1;
	if (a.endTime < b.endTime) then return -1;
	if (a.endTime > b.endTime) then return 1;
	return 0;
}

function rpe_prep_event_array(arr, is_speed) {
	if (!is_array(arr)) then return [];
	if (is_speed) {
		var truncated = [];
		for (var si = 0; si < array_length(arr); si++) {
			var src = arr[si];
			if (!is_struct(src)) then continue;
			var st = game_1.Math.arrToBeat(src[$ "startTime"] ?? 0);
			var et = game_1.Math.arrToBeat(src[$ "endTime"] ?? st);
			var sv = real(src[$ "start"] ?? 0);
			var end_value = real(src[$ "end"] ?? sv);
			var delta = (et > st ? (end_value - sv) / (et - st) : 0);
			var speed_easing = rpe_map_easing_id(src[$ "easingType"] ?? 1);
			var speed_easing_left = real(src[$ "easingLeft"] ?? 0);
			var speed_easing_right = real(src[$ "easingRight"] ?? 1);
			if (!is_finite(speed_easing_left) || !is_finite(speed_easing_right)) {
				speed_easing_left = 0;
				speed_easing_right = 1;
			};
			speed_easing_left = clamp(speed_easing_left, 0, 1);
			speed_easing_right = clamp(speed_easing_right, 0, 1);
			if (speed_easing_left == speed_easing_right) {
				speed_easing_left = 0;
				speed_easing_right = 1;
			};
			for (var ti = array_length(truncated) - 1; ti >= 0; ti--) {
				var old = truncated[ti];
				var old_end = old.endTime;
				var old_stop = old.stop;
				if (old_end < st) {
					array_set(truncated, ti + 1, {
						startTime: old_end, endTime: st,
						start: old_stop, stop: old_stop, delta: 0,
						easingType:1, easingLeft:0, easingRight:1
					});
					break;
				};
				var old_start = old.startTime;
				if (old_start == st) {
					array_resize(truncated, ti);
					break;
				};
				if (old_start < st) {
					var old_value = old.start;
					var duration = st - old_start;
					var old_duration = old.endTime - old_start;
					var old_easing_left = real(old[$ "easingLeft"] ?? 0);
					var old_easing_right = real(old[$ "easingRight"] ?? 1);
					var cut_progress = (old_duration > 0 ? duration / old_duration : 1);
					old.stop = tween_execute(st, old_start, old.endTime, old_value, old.stop,
						real(old[$ "easingType"] ?? 1), old_easing_left, old_easing_right);
					old.endTime = st;
					old.delta = (old.stop - old_value) / duration;
					old.easingRight = lerp(old_easing_left, old_easing_right, cut_progress);
					array_resize(truncated, ti + 1);
					break;
				};
			};
			if (st >= et) {
				array_add(truncated, { startTime: st, endTime: st, start: end_value, stop: end_value, delta: 0, easingType:1, easingLeft:0, easingRight:1 });
			} else {
				array_add(truncated, {
					startTime:st, endTime:et, start:sv, stop:end_value, delta:delta,
					easingType:speed_easing, easingLeft:speed_easing_left, easingRight:speed_easing_right
				});
			};
		};
		array_sort(truncated, rpe_event_time_cmp);
		return truncated;
	};
	for (var i = 0; i < array_length(arr); i++) {
		var ev = arr[i];
		if (!is_struct(ev)) then continue;
		if (struct_exists(ev, "startTime")) then ev.startTime = game_1.Math.beatToAbsSec(game_1.Math.arrToBeat(ev.startTime));
		if (struct_exists(ev, "endTime")) then ev.endTime = game_1.Math.beatToAbsSec(game_1.Math.arrToBeat(ev.endTime));
		var el = ev[$ "easingLeft"] ?? 0;
		var er = ev[$ "easingRight"] ?? 1;
		if ((el == er) || (el < 0) || (el > 1) || (er < 0) || (er > 1)) {
			el = 0; er = 1;
		};
		ev.easingLeft = el;
		ev.easingRight = er;
		ev.easingType = rpe_map_easing_id(ev[$ "easingType"] ?? 1);
		if (!struct_exists(ev, "bezier")) then ev.bezier = 0;
		if (!struct_exists(ev, "bezierPoints")) then ev.bezierPoints = [0, 0, 0, 0];
		if (!struct_exists(ev, "start")) then ev.start = 0;
		if (!struct_exists(ev, "end")) then ev[$ "end"] = ev.start;
	};
	array_sort(arr, rpe_event_time_cmp);
	return arr;
}

function rpe_speed_layer_value(layer, beat, use_left_limit) {
	if (!is_array(layer) || array_length(layer) <= 0) then return 0;
	var result = real(layer[0][$ "start"] ?? 0);
	for (var i = 0; i < array_length(layer); i++) {
		var ev = layer[i];
		if (beat < ev.startTime) then break;
		if (use_left_limit && beat == ev.startTime) then break;
		if (beat >= ev.endTime) then result = real(ev.stop);
		else {
			var span = ev.endTime - ev.startTime;
			if (span <= 0) then result = real(ev.stop);
			else result = real(ev.start) + (beat - ev.startTime) * ((real(ev.stop) - real(ev.start)) / span);
		};
	};
	return result;
}

function rpe_prep_native_ready() {
	return RPE_LINE_PREP_NATIVE && (os_type == os_windows) && extension_exists("I_RPEPrep");
}

function rpe_prep_upload_bpm() {
	if (!rpe_prep_native_ready()) then return false;
	if (variable_global_exists("game_1") && is_struct(game_1)
		&& bool(game_1[$ "_rpe_prep_bpm_ready"] ?? false)) then return true;
	var tl = game_1.Math.ensureBpmTimeline();
	if (!is_array(tl) || array_length(tl) <= 0) then return false;
	var buf = buffer_create(4 + array_length(tl) * 32, buffer_fixed, 1);
	buffer_write(buf, buffer_u32, array_length(tl));
	for (var i = 0; i < array_length(tl); i++) {
		buffer_write(buf, buffer_f64, real(tl[i].startBeat));
		buffer_write(buf, buffer_f64, real(tl[i].endBeat));
		buffer_write(buf, buffer_f64, real(tl[i].bpm));
		buffer_write(buf, buffer_f64, real(tl[i].floorSec));
	};
	var ok = i_rpe_prep_set_bpm(buffer_get_address(buf), buffer_tell(buf)) != 0;
	buffer_delete(buf);
	if (ok && is_struct(game_1)) then game_1._rpe_prep_bpm_ready = true;
	return ok;
}

function rpe_build_speed_events_gml(speed_layers) {
	var speed_splits = [];
	for (var sli = 0; sli < array_length(speed_layers); sli++) {
		var speed_layer = speed_layers[sli];
		for (var sei = 0; sei < array_length(speed_layer); sei++) {
			array_add(speed_splits, speed_layer[sei].startTime);
			array_add(speed_splits, speed_layer[sei].endTime);
		};
	};
	array_sort(speed_splits, function(a, b) {
		if (a < b) then return -1;
		if (a > b) then return 1;
		return 0;
	});
	var fitted_speed = [];
	for (var ssi = 0; ssi < array_length(speed_splits) - 1; ssi++) {
		var split_start = speed_splits[ssi];
		var split_end = speed_splits[ssi + 1];
		if (split_start == split_end) then continue;
		var value_start = 0;
		var value_end = 0;
		for (var sli2 = 0; sli2 < array_length(speed_layers); sli2++) {
			value_start += rpe_speed_layer_value(speed_layers[sli2], split_start, false);
			value_end += rpe_speed_layer_value(speed_layers[sli2], split_end, true);
		};
		array_add(fitted_speed, {
			startTime: split_start, endTime: split_end,
			start: value_start, stop: value_end
		});
	};
	var out = [];
	var speed_floor = 0;
	var fitted_count = array_length(fitted_speed);
	for (var fsi = 0; fsi < fitted_count; fsi++) {
		var fitted = fitted_speed[fsi];
		var sample_start_sec = game_1.Math.beatToAbsSec(fitted.startTime);
		if (!is_finite(sample_start_sec)) then continue;
		var sample_end_sec = game_1.Math.beatToAbsSec(fitted.endTime);
		if (fsi < fitted_count - 1) {
			var next_start_sec = game_1.Math.beatToAbsSec(fitted_speed[fsi + 1].startTime);
			if (is_finite(next_start_sec) && next_start_sec > sample_start_sec) {
				sample_end_sec = next_start_sec;
			};
		};
		if (!is_finite(sample_end_sec) || sample_end_sec <= sample_start_sec) then continue;
		var v0 = real(fitted.start) / 4.5;
		var v1 = real(fitted.stop) / 4.5;
		array_add(out, {
			startTime: sample_start_sec,
			endTime: sample_end_sec,
			value: v0,
			endValue: v1,
			floorPosition: speed_floor
		});
		speed_floor += (sample_end_sec - sample_start_sec) * (v0 + v1) * 0.5;
	};
	if (array_length(out) > 0) {
		var last_speed_ev = out[array_length(out) - 1];
		var last_end_value = real(last_speed_ev.endValue);
		if (is_finite(last_speed_ev.endTime)) {
			array_add(out, {
				startTime: last_speed_ev.endTime,
				endTime: infinity,
				value: last_end_value,
				endValue: last_end_value,
				floorPosition: speed_floor
			});
		};
	};
	return out;
}

function rpe_build_speed_events_native(speed_layers) {
	if (!rpe_prep_native_ready()) then return undefined;
	if (!rpe_prep_upload_bpm()) then return undefined;
	var in_buf = buffer_create(64, buffer_grow, 1);
	buffer_write(in_buf, buffer_u32, array_length(speed_layers));
	var event_n = 0;
	for (var sli = 0; sli < array_length(speed_layers); sli++) {
		var _layer = speed_layers[sli];
		buffer_write(in_buf, buffer_u32, array_length(_layer));
		event_n += array_length(_layer);
		for (var sei = 0; sei < array_length(_layer); sei++) {
			var ev = _layer[sei];
			buffer_write(in_buf, buffer_f64, real(ev.startTime));
			buffer_write(in_buf, buffer_f64, real(ev.endTime));
			buffer_write(in_buf, buffer_f64, real(ev.start));
			buffer_write(in_buf, buffer_f64, real(ev.stop));
		};
	};
	var out_cap = 4 + (event_n * 2 + 2) * 40;
	if (out_cap < 4096) then out_cap = 4096;
	var out_buf = buffer_create(out_cap, buffer_fixed, 1);
	var written = i_rpe_prep_speed_fit(buffer_get_address(in_buf), buffer_tell(in_buf), buffer_get_address(out_buf), buffer_get_size(out_buf));
	if (!(is_real(written) && written >= 4)) {
		buffer_delete(out_buf);
		out_cap *= 4;
		out_buf = buffer_create(out_cap, buffer_fixed, 1);
		written = i_rpe_prep_speed_fit(buffer_get_address(in_buf), buffer_tell(in_buf), buffer_get_address(out_buf), buffer_get_size(out_buf));
	};
	buffer_delete(in_buf);
	if (!(is_real(written) && written >= 4)) {
		buffer_delete(out_buf);
		return undefined;
	};
	buffer_seek(out_buf, buffer_seek_start, 0);
	var n = buffer_read(out_buf, buffer_u32);
	if (!(is_real(n) && n >= 0 && (4 + n * 40) <= written)) {
		buffer_delete(out_buf);
		return undefined;
	};
	var out = [];
	for (var i = 0; i < n; i++) {
		array_add(out, {
			startTime: buffer_read(out_buf, buffer_f64),
			endTime: buffer_read(out_buf, buffer_f64),
			value: buffer_read(out_buf, buffer_f64),
			endValue: buffer_read(out_buf, buffer_f64),
			floorPosition: buffer_read(out_buf, buffer_f64)
		});
	};
	buffer_delete(out_buf);
	return out;
}

function rpe_build_speed_events(event_layers) {
	var speed_layers = [];
	if (is_array(event_layers)) {
		for (var sli = 0; sli < array_length(event_layers); sli++) {
			var speed_layer = (struct_exists(event_layers[sli], "speedEvents") ? event_layers[sli][$ "speedEvents"] : []);
			if (!is_array(speed_layer) || array_length(speed_layer) <= 0) then continue;
			array_add(speed_layers, speed_layer);
		};
	};
	if (array_length(speed_layers) <= 0) then return [];
	var native_out = rpe_build_speed_events_native(speed_layers);
	if (is_array(native_out)) then return native_out;
	return rpe_build_speed_events_gml(speed_layers);
}
