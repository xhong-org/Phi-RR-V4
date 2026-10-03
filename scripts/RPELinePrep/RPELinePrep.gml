/// @desc Shared RPE line event preprocess.
/// META.RPEVersion >= 170 uses PhiEdit 1.7 floorPositionAt: each layer
/// integrates eased speed (linear closed form, otherwise 20-step Simpson).
/// Older charts, including files with no RPEVersion, use the pre-170 player
/// table: overlap cut, linear speed between the cuts, then a time trapezoid.
/// Playback divides by 4.5 so note distance stays in the existing floor unit.
/// The old native trapezoid fit does not implement either integral.

#macro RPE_LINE_PREP_NATIVE false

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
		// Keep the chart easing. PhiEdit integrates each event in order and
		// does not retarget overlaps onto a straight line between the cuts.
		var prepared = [];
		for (var si = 0; si < array_length(arr); si++) {
			var src = arr[si];
			if (!is_struct(src)) then continue;
			var st = game_1.Math.arrToBeat(src[$ "startTime"] ?? 0);
			var et = game_1.Math.arrToBeat(src[$ "endTime"] ?? st);
			var sv = real(src[$ "start"] ?? 0);
			var end_value = real(src[$ "end"] ?? sv);
			if (!is_finite(sv)) then sv = 0;
			if (!is_finite(end_value)) then end_value = sv;
			var speed_easing = floor(real(src[$ "easingType"] ?? 1));
			if (!is_finite(speed_easing)) then speed_easing = 1;
			var speed_easing_left = real(src[$ "easingLeft"] ?? 0);
			var speed_easing_right = real(src[$ "easingRight"] ?? 1);
			if (!is_finite(speed_easing_left)) then speed_easing_left = 0;
			if (!is_finite(speed_easing_right)) then speed_easing_right = 1;
			array_add(prepared, {
				startTime:st, endTime:et, start:sv, stop:end_value,
				easingType:speed_easing, easingLeft:speed_easing_left, easingRight:speed_easing_right
			});
		};
		array_sort(prepared, rpe_event_time_cmp);
		return prepared;
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

// PhiEdit Easing.cpp. Type numbers are the chart's easingType, not the
// playback tween table (that table swaps several in/out pairs).
function rpe_ease_pow(base, exp) {
	var n = floor(exp);
	if (n == exp && n >= 0 && n <= 8) {
		var value = 1;
		repeat (n) value *= base;
		return value;
	};
	if (base < 0) then return 0;
	return power(base, exp);
}

function rpe_ease_out_bounce(x) {
	var n1 = 7.5625;
	if (x < 0.36363636363636365) then return n1 * x * x;
	if (x < 0.7272727272727273) {
		x -= 0.5454545454545454;
		return n1 * x * x + 0.75;
	};
	if (x < 0.9090909090909091) {
		x -= 0.8181818181818182;
		return n1 * x * x + 0.9375;
	};
	x -= 0.9545454545454546;
	return n1 * x * x + 0.984375;
}

function rpe_ease_value(type, x) {
	var ease_pi = 3.14159265358979;
	var c1 = 1.70158;
	var c2 = 2.5949095;
	var c3 = 2.70158;
	var c4 = 2.0943951023931935;
	var c5 = 1.3962634015954623;
	switch (type) {
		case 1: return x;
		case 2: return sin(x * ease_pi * 0.5);
		case 3: return 1 - cos(x * ease_pi * 0.5);
		case 4: return 1 - (1 - x) * (1 - x);
		case 5: return x * x;
		case 6: return -(cos(ease_pi * x) - 1) * 0.5;
		case 7: return (x < 0.5) ? (2 * x * x) : (1 - rpe_ease_pow(-2 * x + 2, 2) * 0.5);
		case 8: return 1 - rpe_ease_pow(1 - x, 3);
		case 9: return x * x * x;
		case 10: return 1 - rpe_ease_pow(1 - x, 4);
		case 11: return x * x * x * x;
		case 12: return (x < 0.5) ? (4 * x * x * x) : (1 - rpe_ease_pow(-2 * x + 2, 3) * 0.5);
		case 13: return (x < 0.5) ? (8 * x * x * x * x) : (1 - rpe_ease_pow(-2 * x + 2, 4) * 0.5);
		case 14: return 1 - rpe_ease_pow(1 - x, 5);
		case 15: return x * x * x * x * x;
		case 16: return (x == 1) ? 1 : (1 - power(2, -10 * x));
		case 17: return (x == 0) ? 0 : power(2, 10 * x - 10);
		case 18: return sqrt(1 - rpe_ease_pow(x - 1, 2));
		case 19: return 1 - sqrt(1 - rpe_ease_pow(x, 2));
		case 20: return 1 + c3 * rpe_ease_pow(x - 1, 3) + c1 * rpe_ease_pow(x - 1, 2);
		case 21: return c3 * x * x * x - c1 * x * x;
		case 22: return (x < 0.5) ? ((1 - sqrt(1 - rpe_ease_pow(2 * x, 2))) * 0.5) : ((sqrt(1 - rpe_ease_pow(-2 * x + 2, 2)) + 1) * 0.5);
		case 23: return (x < 0.5)
			? (rpe_ease_pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2) * 0.5)
			: ((rpe_ease_pow(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) * 0.5);
		case 24:
			if (x == 0 || x == 1) then return x;
			return power(2, -10 * x) * sin((x * 10 - 0.75) * c4) + 1;
		case 25:
			if (x == 0 || x == 1) then return x;
			return -power(2, 10 * x - 10) * sin((x * 10 - 10.75) * c4);
		case 26: return rpe_ease_out_bounce(x);
		case 27: return 1 - rpe_ease_out_bounce(1 - x);
		case 28: return (x < 0.5) ? ((1 - rpe_ease_out_bounce(1 - 2 * x)) * 0.5) : ((1 + rpe_ease_out_bounce(2 * x - 1)) * 0.5);
		case 29:
			if (x == 0 || x == 1) then return x;
			var s = sin((20 * x - 11.125) * c5);
			if (x < 0.5) then return -(power(2, 20 * x - 10) * s) * 0.5;
			return power(2, 10 - 20 * x) * s * 0.5 + 1;
	};
	return x;
}

// Charts saved before RPE 1.7 (and files with no RPEVersion) did not integrate
// non-linear speed easings. PhiEdit 1.7 itself always uses floorPositionAt;
// players keep the older fit when META.RPEVersion < 170.
function rpe_speed_uses_legacy() {
	var version = 0;
	if (variable_global_exists("game_1") && is_struct(game_1)) {
		version = real(game_1[$ "version"] ?? 0);
	};
	if (!is_finite(version)) then version = 0;
	return version < 170;
}

// Normalized easeClipped: (ease(left + (right-left)*p) - ease(left)) / (ease(right) - ease(left)).
function rpe_ease_clipped(type, p, left, right) {
	var f0 = rpe_ease_value(type, left);
	var f1 = rpe_ease_value(type, right);
	var denom = f1 - f0;
	if (abs(denom) < 0.000000000000001) then return p;
	var unit_x = clamp(p, 0, 1);
	return (rpe_ease_value(type, left + (right - left) * unit_x) - f0) / denom;
}

function rpe_ease_clipped_derivative(type, p, left, right) {
	var eps = 0.000001;
	var x0 = clamp(p - eps, 0, 1);
	var x1 = clamp(p + eps, 0, 1);
	var span = x1 - x0;
	if (span < 0.0000000001) then return 0;
	return (rpe_ease_clipped(type, x1, left, right) - rpe_ease_clipped(type, x0, left, right)) / span;
}

// Pre-1.7 speed easing. Fit k, b so k*ease'(0)+b = v0 and k*ease'(1)+b = v1,
// then integrate that speed. A flat derivative falls back to the average speed.
// Constant events (v0 == v1) return v0*p*duration for every easing.
function rpe_speed_legacy_slice(v0, v1, duration, p, easing, left, right) {
	var f0 = rpe_ease_value(easing, left);
	var f1 = rpe_ease_value(easing, right);
	if (abs(f1 - f0) < 0.000000000000001) then return v0 * p * duration;
	var df0 = rpe_ease_clipped_derivative(easing, 0, left, right);
	var df1 = rpe_ease_clipped_derivative(easing, 1, left, right);
	var denom = df1 - df0;
	var k = 0;
	var b = (v0 + v1) * 0.5;
	if (is_finite(denom) && abs(denom) >= 0.00000001) {
		k = (v1 - v0) / denom;
		b = v0 - k * df0;
	};
	if (!is_finite(k) || !is_finite(b)) {
		k = 0;
		b = (v0 + v1) * 0.5;
	};
	return (k * rpe_ease_clipped(easing, p, left, right) + b * p) * duration;
}

// Integral of speed from the event start through progress p (0..1 of the event).
// Easing type 1 is the closed form and ignores the easing window, matching
// floorPositionAt. RPE 1.7 integrates every other easing with Simpson's rule.
// Older charts use the derivative fit above instead of that integral.
function rpe_speed_slice_integral(v0, v1, duration, p, easing, left, right) {
	if (!(p > 0) || !(duration > 0.000000001)) then return 0;
	if (easing == 1) {
		return ((v1 - v0) * p * p * 0.5 + v0 * p) * duration;
	};
	if (rpe_speed_uses_legacy()) {
		return rpe_speed_legacy_slice(v0, v1, duration, p, easing, left, right);
	};
	var h = p / 20;
	var f0 = rpe_ease_value(easing, left);
	var range = right - left;
	var denom = rpe_ease_value(easing, right) - f0;
	var integral = 0;
	if (abs(denom) >= 0.000000000000001) {
		var sum = (rpe_ease_value(easing, range * p + left) - f0) / denom;
		sum += (rpe_ease_value(easing, left) - f0) / denom;
		for (var odd_i = 1; odd_i < 20; odd_i += 2) {
			sum += ((rpe_ease_value(easing, odd_i * h * range + left) - f0) / denom) * 4;
		};
		for (var even_i = 2; even_i < 19; even_i += 2) {
			var sample = (rpe_ease_value(easing, even_i * h * range + left) - f0) / denom;
			sum += sample + sample;
		};
		integral = sum * h / 3;
	};
	return ((v1 - v0) * integral + v0 * p) * duration;
}

function rpe_speed_player_floor(raw_integral) {
	return raw_integral / 4.5;
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

function rpe_build_speed_layer(events) {
	var built = [];
	var acc = 0;
	var prev_end = 0;
	var prev_value = real(events[0].start);
	var count = array_length(events);
	for (var ei = 0; ei < count; ei++) {
		var src = events[ei];
		var start_sec = game_1.Math.beatToAbsSec(src.startTime);
		var end_sec = game_1.Math.beatToAbsSec(src.endTime);
		if (!is_finite(start_sec) || !is_finite(end_sec)) then continue;
		var v0 = real(src.start);
		var v1 = real(src.stop);
		array_add(built, {
			startSec: start_sec,
			endSec: end_sec,
			v0: v0,
			v1: v1,
			easingType: real(src.easingType),
			easingLeft: real(src.easingLeft),
			easingRight: real(src.easingRight),
			prevEnd: prev_end,
			prevValue: prev_value,
			floorBefore: acc
		});
		if (start_sec > prev_end) then acc += rpe_speed_player_floor((start_sec - prev_end) * prev_value);
		var duration = end_sec - start_sec;
		if (duration > 0.000000001) {
			acc += rpe_speed_player_floor(rpe_speed_slice_integral(v0, v1, duration, 1, real(src.easingType), real(src.easingLeft), real(src.easingRight)));
		};
		prev_value = v1;
		prev_end = end_sec;
	};
	return {
		events: built,
		tailEnd: prev_end,
		tailSpeed: prev_value,
		tailFloor: acc
	};
}

function rpe_layer_floor_at(layer, t) {
	if (!is_struct(layer)) then return 0;
	var events = layer.events;
	if (!is_array(events)) then return 0;
	var n = array_length(events);
	if (n <= 0) then return 0;
	if (!is_finite(t)) then return 0;
	// The source walks events in order and stops at the first one that has not
	// ended. A later event can finish earlier, so this cannot be a binary search.
	var lo = 0;
	while (lo < n && events[lo].startSec < t && events[lo].endSec < t) lo++;
	if (lo >= n) {
		return layer.tailFloor + rpe_speed_player_floor((t - layer.tailEnd) * layer.tailSpeed);
	};
	var ev = events[lo];
	var acc = ev.floorBefore;
	if (ev.startSec > ev.prevEnd) {
		var gap_end = min(ev.startSec, t);
		if (gap_end > ev.prevEnd) then acc += rpe_speed_player_floor((gap_end - ev.prevEnd) * ev.prevValue);
	};
	if (ev.startSec >= t) then return acc;
	var duration = ev.endSec - ev.startSec;
	if (duration > 0.000000001) {
		var p = (min(ev.endSec, t) - ev.startSec) / duration;
		acc += rpe_speed_player_floor(rpe_speed_slice_integral(ev.v0, ev.v1, duration, p, ev.easingType, ev.easingLeft, ev.easingRight));
	};
	return acc;
}

function rpe_build_speed_events_gml(speed_layers) {
	var out = [];
	for (var sli = 0; sli < array_length(speed_layers); sli++) {
		var speed_layer = speed_layers[sli];
		if (!is_array(speed_layer) || array_length(speed_layer) <= 0) then continue;
		array_add(out, rpe_build_speed_layer(speed_layer));
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

// Pre-170 speed table. Cuts overlaps, samples each layer linearly in beats
// (speed easing is not integrated), sums the layers, then trapezoid-integrates
// in seconds. Values stored on the segments are already divided by 4.5.
function rpe_legacy_speed_value(layer, beat, use_left_limit) {
	if (!is_array(layer) || array_length(layer) <= 0) then return 0;
	var result = real(layer[0][$ "start"] ?? 0);
	var count = array_length(layer);
	for (var i = 0; i < count; i++) {
		var ev = layer[i];
		if (beat < ev.startTime) then break;
		if (use_left_limit && beat == ev.startTime) then break;
		if (beat >= ev.endTime) {
			result = real(ev.stop);
		} else {
			var span = ev.endTime - ev.startTime;
			if (span <= 0) then result = real(ev.stop);
			else result = real(ev.start) + (beat - ev.startTime) * ((real(ev.stop) - real(ev.start)) / span);
		};
	};
	return result;
}

function rpe_legacy_truncate_speed(arr) {
	var truncated = [];
	if (!is_array(arr)) then return truncated;
	var count = array_length(arr);
	for (var si = 0; si < count; si++) {
		var src = arr[si];
		if (!is_struct(src)) then continue;
		var st = real(src.startTime);
		var et = real(src.endTime);
		var sv = real(src.start);
		var end_value = real(src.stop);
		if (!is_finite(sv)) then sv = 0;
		if (!is_finite(end_value)) then end_value = sv;
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
					easingType: 1, easingLeft: 0, easingRight: 1
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
				old.delta = (duration > 0 ? (old.stop - old_value) / duration : 0);
				old.easingRight = lerp(old_easing_left, old_easing_right, cut_progress);
				array_resize(truncated, ti + 1);
				break;
			};
		};

		if (st >= et) {
			array_add(truncated, {
				startTime: st, endTime: st, start: end_value, stop: end_value, delta: 0,
				easingType: 1, easingLeft: 0, easingRight: 1
			});
		} else {
			array_add(truncated, {
				startTime: st, endTime: et, start: sv, stop: end_value, delta: delta,
				easingType: speed_easing, easingLeft: speed_easing_left, easingRight: speed_easing_right
			});
		};
	};
	array_sort(truncated, rpe_event_time_cmp);
	return truncated;
}

function rpe_build_legacy_speed_table(event_layers) {
	var speed_layers = [];
	var speed_splits = [];
	if (is_array(event_layers)) {
		for (var sli = 0; sli < array_length(event_layers); sli++) {
			var raw_layer = (struct_exists(event_layers[sli], "speedEvents") ? event_layers[sli][$ "speedEvents"] : []);
			if (!is_array(raw_layer) || array_length(raw_layer) <= 0) then continue;
			var speed_layer = rpe_legacy_truncate_speed(raw_layer);
			if (array_length(speed_layer) <= 0) then continue;
			array_add(speed_layers, speed_layer);
			for (var sei = 0; sei < array_length(speed_layer); sei++) {
				array_add(speed_splits, speed_layer[sei].startTime);
				array_add(speed_splits, speed_layer[sei].endTime);
			};
		};
	};
	if (array_length(speed_splits) <= 0) then return [];
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
			value_start += rpe_legacy_speed_value(speed_layers[sli2], split_start, false);
			value_end += rpe_legacy_speed_value(speed_layers[sli2], split_end, true);
		};
		array_add(fitted_speed, {
			startTime: split_start, endTime: split_end,
			start: value_start, stop: value_end
		});
	};

	var segments = [];
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
		array_add(segments, {
			startTime: sample_start_sec,
			endTime: sample_end_sec,
			value: v0,
			endValue: v1,
			floorPosition: speed_floor
		});
		speed_floor += (sample_end_sec - sample_start_sec) * (v0 + v1) * 0.5;
	};
	if (array_length(segments) > 0) {
		var last_speed_ev = segments[array_length(segments) - 1];
		var last_end_value = real(last_speed_ev.endValue);
		if (is_finite(last_speed_ev.endTime)) {
			array_add(segments, {
				startTime: last_speed_ev.endTime,
				endTime: infinity,
				value: last_end_value,
				endValue: last_end_value,
				floorPosition: speed_floor
			});
		};
	};
	return segments;
}

function rpe_legacy_event_floor(ev, t) {
	var elapsed = max(0, real(t) - real(ev.startTime));
	var v0 = real(ev.value);
	var v1 = real(ev[$ "endValue"] ?? v0);
	var duration = real(ev.endTime) - real(ev.startTime);
	if (!is_finite(duration) || duration <= 0) {
		return real(ev.floorPosition) + elapsed * v0;
	};
	var portion = min(1, elapsed / duration);
	var vt = v0 + (v1 - v0) * portion;
	return real(ev.floorPosition) + elapsed * (v0 + vt) * 0.5;
}

function rpe_legacy_floor_at(segments, t) {
	if (!is_array(segments)) then return 0;
	var n = array_length(segments);
	if (n <= 0 || !is_real(t)) then return 0;
	if (t < segments[0].startTime) then return 0;
	var idx = 0;
	while (idx < n - 1 && t > segments[idx].endTime) idx++;
	return rpe_legacy_event_floor(segments[idx], t);
}

function rpe_build_speed_events(event_layers) {
	if (rpe_speed_uses_legacy()) then return rpe_build_legacy_speed_table(event_layers);
	var speed_layers = [];
	if (is_array(event_layers)) {
		for (var sli = 0; sli < array_length(event_layers); sli++) {
			var speed_layer = (struct_exists(event_layers[sli], "speedEvents") ? event_layers[sli][$ "speedEvents"] : []);
			if (!is_array(speed_layer) || array_length(speed_layer) <= 0) then continue;
			array_add(speed_layers, speed_layer);
		};
	};
	if (array_length(speed_layers) <= 0) then return [];
	return rpe_build_speed_events_gml(speed_layers);
}
