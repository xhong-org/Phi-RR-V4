/// @desc Spread Official line+note construction across loading frames.
/// Lines exist before notes (notes bind by line_id). Freeze after full init.

function official_lines_creating() {
	return variable_global_exists("game") && is_struct(game)
		&& bool(game[$ "_chart_lines_creating"] ?? false);
}

function official_view_metrics() {
	var view_h = (variable_global_exists("chart_view_height") && is_real(chart_view_height) && chart_view_height > 1)
		? chart_view_height : room_height;
	var view_w = (variable_global_exists("chart_view_width") && is_real(chart_view_width) && chart_view_width > 1)
		? chart_view_width : view_h * 16 / 9;
	var view_l = (variable_global_exists("chart_view_left") && is_real(chart_view_left)) ? chart_view_left : 0;
	return {
		view_l: view_l,
		view_w: view_w,
		view_h: view_h,
		view_r: view_l + view_w,
		// 1.25 covers the note sprite and a line sitting on the viewport edge.
		diag: point_distance(0, 0, view_w, view_h) * 1.25,
		scale: max(1, view_h * 0.6)
	};
}

function official_norm_gap(_x_norm, _y_norm, _metrics) {
	var px = _metrics.view_l + _metrics.view_w * _x_norm;
	var py = _metrics.view_h * (1 - _y_norm);
	var dx = 0;
	if (px < _metrics.view_l) then dx = _metrics.view_l - px;
	else if (px > _metrics.view_r) then dx = px - _metrics.view_r;
	var dy = 0;
	if (py < 0) then dy = -py;
	else if (py > _metrics.view_h) then dy = py - _metrics.view_h;
	if (dx == 0 && dy == 0) then return 0;
	return point_distance(0, 0, dx, dy);
}

function official_line_vis_cache(_line_data, _metrics) {
	var bpm = real(_line_data[$ "bpm"] ?? 60);
	if (bpm <= 0) then bpm = 60;
	var spb = 1.875 / bpm;
	var speed_events = is_array(_line_data[$ "speedEvents"]) ? _line_data.speedEvents : [];
	var speed_n = array_length(speed_events);
	var seg_n = 0;
	for (var speed_i = 0; speed_i < speed_n; speed_i++) {
		if (is_struct(speed_events[speed_i])) then seg_n++;
	};
	var t0s = array_create(seg_n, 0);
	var t1s = array_create(seg_n, 0);
	var floors = array_create(seg_n, 0);
	var values = array_create(seg_n, 0);
	var gaps = array_create(seg_n, 0);
	var floor_acc = 0;
	var seg_i = 0;
	for (var speed_j = 0; speed_j < speed_n; speed_j++) {
		var speed_event = speed_events[speed_j];
		if (!is_struct(speed_event)) then continue;
		var event_floor = floor_acc;
		if (is_real(speed_event[$ "floorPosition"])) then event_floor = speed_event.floorPosition;
		var beat0 = real(speed_event.startTime ?? 0);
		var beat1 = real(speed_event.endTime ?? beat0);
		var sec0 = beat0 * spb;
		var sec1 = beat1 * spb;
		if (sec1 < sec0) then sec1 = sec0;
		var speed_value = real(speed_event.value ?? 0);
		floors[seg_i] = event_floor;
		values[seg_i] = speed_value;
		t0s[seg_i] = sec0;
		// The runtime keeps the final speed past its declared end.
		t1s[seg_i] = (seg_i == seg_n - 1) ? max(sec1, 10000000) : sec1;
		floor_acc = event_floor + max(0, sec1 - sec0) * speed_value;
		seg_i++;
	};
	var move_events = is_array(_line_data[$ "judgeLineMoveEvents"]) ? _line_data.judgeLineMoveEvents : [];
	var move_n = array_length(move_events);
	var move_count = 0;
	for (var move_i = 0; move_i < move_n; move_i++) {
		if (is_struct(move_events[move_i])) then move_count++;
	};
	var mt0 = array_create(move_count, 0);
	var mt1 = array_create(move_count, 0);
	var mg0 = array_create(move_count, 0);
	var mg1 = array_create(move_count, 0);
	var move_write = 0;
	for (var move_j = 0; move_j < move_n; move_j++) {
		var move_event = move_events[move_j];
		if (!is_struct(move_event)) then continue;
		var move_t0 = real(move_event.startTime ?? 0) * spb;
		var move_t1 = real(move_event.endTime ?? 0) * spb;
		if (move_t1 < move_t0) then move_t1 = move_t0;
		var x0 = real(move_event.start ?? 0);
		var y0 = real(move_event[$ "start2"] ?? 0);
		var x1 = real(move_event[$ "end"] ?? x0);
		var y1 = real(move_event[$ "end2"] ?? y0);
		mt0[move_write] = move_t0;
		mt1[move_write] = move_t1;
		mg0[move_write] = official_norm_gap(x0, y0, _metrics);
		mg1[move_write] = official_norm_gap(x1, y1, _metrics);
		move_write++;
	};
	var def_gap = official_norm_gap(0, 0, _metrics);
	var cursor = 0;
	for (var gap_i = 0; gap_i < seg_n; gap_i++) {
		var seg_t0 = t0s[gap_i];
		var seg_t1 = t1s[gap_i];
		while (cursor < move_count && mt1[cursor] < seg_t0) cursor++;
		var held = def_gap;
		if (cursor > 0) then held = mg1[cursor - 1];
		var gap = held;
		var look = cursor;
		while (look < move_count && mt0[look] <= seg_t1) {
			if (mt1[look] >= seg_t0) then gap = max(gap, max(mg0[look], mg1[look]));
			look++;
		};
		gaps[gap_i] = gap;
	};
	var lead_sec = (seg_n > 0) ? t0s[0] : 0;
	var lead_gap = def_gap;
	if (lead_sec > 0) {
		for (var lead_i = 0; lead_i < move_count; lead_i++) {
			if (mt0[lead_i] > lead_sec) then break;
			if (mt1[lead_i] >= 0) then lead_gap = max(lead_gap, max(mg0[lead_i], mg1[lead_i]));
		};
	};
	return {
		metrics: _metrics,
		seg_n: seg_n,
		t0s: t0s,
		t1s: t1s,
		floors: floors,
		values: values,
		gaps: gaps,
		lead_sec: lead_sec,
		lead_gap: lead_gap
	};
}

/// Earliest second this note can be judged or seen.
/// Holds use the whole body span: the head can sit outside the viewport while the body still crosses it.
function official_note_activate_sec(_cache, _floor, _speed, _hit_sec, _hold_len, _is_hold) {
	var judge_at = max(0, _hit_sec - 0.5);
	if (!_is_hold && abs(_speed) < 0.0000001) then return 0;
	if (_is_hold && (_speed == 0 || abs(_hold_len) < 0.0000001)) then return judge_at;
	var metrics = _cache.metrics;
	var unit = metrics.scale;
	if (!_is_hold) then unit *= max(abs(_speed), 0.0000001);
	var note_lo = min(_floor, _floor + _hold_len);
	var note_hi = max(_floor, _floor + _hold_len);
	var diag = metrics.diag;
	var visual = infinity;
	var seg_n = _cache.seg_n;
	if (seg_n <= 0) {
		var pad0 = (diag + _cache.lead_gap) / unit;
		if (0 >= note_lo - pad0 && 0 <= note_hi + pad0) then visual = 0;
	} else if (_cache.lead_sec > 0) {
		var pad_before = (diag + _cache.lead_gap) / unit;
		if (0 >= note_lo - pad_before && 0 <= note_hi + pad_before) then visual = 0;
	};
	var t0s = _cache.t0s;
	var t1s = _cache.t1s;
	var floors = _cache.floors;
	var values = _cache.values;
	var gaps = _cache.gaps;
	for (var seg_i = 0; seg_i < seg_n; seg_i++) {
		var t0 = t0s[seg_i];
		var t1 = t1s[seg_i];
		var speed_value = values[seg_i];
		var floor0 = floors[seg_i];
		var pad = (diag + gaps[seg_i]) / unit;
		var vis_lo = note_lo - pad;
		var vis_hi = note_hi + pad;
		var floor1 = floor0 + (t1 - t0) * speed_value;
		if (max(floor0, floor1) < vis_lo || min(floor0, floor1) > vis_hi) then continue;
		if (abs(speed_value) < 0.0000001 || (floor0 >= vis_lo && floor0 <= vis_hi)) {
			visual = min(visual, max(t0, 0));
			continue;
		};
		var target = (floor0 < vis_lo) ? vis_lo : vis_hi;
		var enter_sec = t0 + (target - floor0) / speed_value;
		if (enter_sec >= t0 && enter_sec <= t1) then visual = min(visual, enter_sec);
	};
	var activate_sec = min(judge_at, visual);
	if (!is_real(activate_sec) || activate_sec < 0) then return 0;
	return activate_sec;
}

function official_lines_begin() {
	var owner = game;
	var old_texture_names = (struct_get_names(owner.TextureGroup));
	for (var texture_i = 0; texture_i < array_length(old_texture_names); texture_i++) {
		if (old_texture_names[texture_i] == "default") then continue;
		var old_texture = (owner.TextureGroup[$ old_texture_names[texture_i]]);
		if (sprite_exists(old_texture)) then sprite_delete(old_texture);
	};
	owner.TextureGroup = { "default": line_2 };
	var judge_lines = owner.chart[$ "judgeLineList"] ?? [];
	if (!is_array(judge_lines)) then judge_lines = [];
	var source_notes = is_array(owner._notes) ? owner._notes : [];
	var line_count = array_length(judge_lines);
	owner.line_list = array_create(line_count, noone);
	owner.runtime_line_instances = [];
	owner.runtime_note_instances = [];
	owner._notes = [];
	owner._note_activation_enabled = false;
	owner._note_activation_index = 0;
	owner._chart_line_job = {
		judge_lines: judge_lines,
		source_notes: source_notes,
		line_count: line_count,
		note_count: array_length(source_notes),
		next_line: 0,
		next_note: 0,
		phase: 0,
		view: official_view_metrics(),
		line_vis: array_create(line_count, undefined)
	};
	owner._chart_lines_creating = true;
	chart_set_gameplay_visible(false);
}

function official_lines_create_line(i) {
	var owner = game;
	var job = owner._chart_line_job;
	var line_override = chart_line_override(i);
	var img = chart_line_override_sprite(i);
	if (!sprite_exists(img)) then img = line_2;
	var scales = is_struct(line_override) ? real(line_override.Scale ?? 1) : 1;
	var l = (instance_create_depth(room_width / 2, room_height / 2, 0, oLine, {
		events: job.judge_lines[i],
		line_id: i,
		image_id: img,
		Scales: (scales)
	}));
	owner.line_list[i] = l;
	array_add(owner.runtime_line_instances, l);
	chart_lines_hide_created(l);
	var line_data = job.judge_lines[i];
	job.line_vis[i] = official_line_vis_cache(is_struct(line_data) ? line_data : {}, job.view);
}

function official_lines_force_init() {
	if (!variable_global_exists("game") || !is_struct(game) || !is_array(game.line_list)) then return;
	var lines = game.line_list;
	for (var i = 0; i < array_length(lines); i++) {
		var l = lines[i];
		if (!instance_exists(l)) then continue;
		with (l) {
			chart_force_event_init = true;
			event_perform(ev_step, ev_step_normal);
			chart_force_event_init = false;
		};
	};
}

function official_lines_create_note(i) {
	var owner = game;
	var job = owner._chart_line_job;
	var na = job.source_notes[i];
	if (!is_struct(na)) then return;
	var note_instance = instance_create_depth(-999, -999, 0, oNote, {
		"type": na.type,
		"isAbove": na.isAbove,
		"time": na.time,
		"holdTime": (na.holdTime),
		"holdFloorLength": (na[$ "holdFloorLength"] ?? 0),
		"xOffset": (na.xOffset),
		"yOffset": (na.yOffset),
		"line_id": (na[$ "id"]),
		"bpm": (na.bpm),
		"speed": (na[$ "speed"]),
		"_hl": (na[$ "hl"])
	});
	chart_lines_hide_created(note_instance);
	array_add(owner.runtime_note_instances, note_instance);
	if (variable_global_exists("render_mode") && global.render_mode && instance_exists(note_instance)) {
		var note_hitsound_time = (note_instance.type == 2 || note_instance.type == 4)
			? note_instance.realHitTime : note_instance.judgeRealTime;
		note_instance.render_hitsound_scheduled = render_schedule_note_hitsound(
			note_instance, note_hitsound_time);
	};
	if (!instance_exists(note_instance)) then return;
	var line_index = real(na[$ "id"] ?? 0);
	var line_cache = undefined;
	if (line_index >= 0 && line_index < array_length(job.line_vis)) {
		line_cache = job.line_vis[line_index];
		if (!is_struct(line_cache)) {
			var line_data = (is_array(job.judge_lines) && line_index < array_length(job.judge_lines))
				? job.judge_lines[line_index] : {};
			line_cache = official_line_vis_cache(is_struct(line_data) ? line_data : {}, job.view);
			job.line_vis[line_index] = line_cache;
		};
	};
	if (!is_struct(line_cache)) then line_cache = official_line_vis_cache({}, job.view);
	var is_hold = (real(na.type ?? 0) == 3);
	var hold_len = is_hold ? real(na[$ "holdFloorLength"] ?? 0) : 0;
	var activate_sec = official_note_activate_sec(
		line_cache,
		real(na.yOffset ?? 0),
		real(na[$ "speed"] ?? 1),
		real(note_instance.realHitTime),
		hold_len,
		is_hold
	);
	array_add(owner._notes, {
		id: note_instance,
		activateSec: activate_sec,
		hitSec: real(note_instance.realHitTime)
	});
}

function official_lines_pump(_budget_us = CHART_LINE_CREATE_BUDGET_US) {
	if (!official_lines_creating()) then return true;
	var owner = game;
	var job = owner._chart_line_job;
	if (!is_struct(job)) {
		owner._chart_lines_creating = false;
		return true;
	};
	var t0 = get_timer();
	var created = 0;
	if (job.phase == 0) {
		while (job.next_line < job.line_count) {
			official_lines_create_line(job.next_line);
			job.next_line++;
			created++;
			if (_budget_us > 0 && (get_timer() - t0) >= _budget_us && created >= 1) then return false;
		};
		official_lines_force_init();
		job.phase = 1;
	};
	while (job.next_note < job.note_count) {
		official_lines_create_note(job.next_note);
		job.next_note++;
		created++;
		if (_budget_us > 0 && (get_timer() - t0) >= _budget_us && created >= 1) then return false;
	};
	owner._chart_lines_creating = false;
	return true;
}

function official_lines_finish() {
	var owner = game;
	owner._chart_lines_creating = false;
	array_sort(owner._notes, function(a, b) {
		if (a.activateSec < b.activateSec) then return -1;
		if (a.activateSec > b.activateSec) then return 1;
		if (a.hitSec < b.hitSec) then return -1;
		if (a.hitSec > b.hitSec) then return 1;
		return 0;
	});
	// Official ignores notePreloadSeconds. Notes wake when their body can meet the view.
	owner._note_activation_enabled = true;
	owner._note_activation_index = 0;
	for (var _di = 0; _di < array_length(owner._notes); _di++) {
		instance_deactivate_object(owner._notes[_di].id);
	};
	print("[C-Lines] Done.", owner.settings.enableDebug);
	print("[C-Notes] Done.", owner.settings.enableDebug);
	official_blocks_preload();
	owner._chart_line_job = undefined;
	chart_lines_freeze_object(oLine);
}

function official_sync_note_activation(_now_sec = undefined) {
	if (!variable_global_exists("game") || !is_struct(game)) then return;
	if (_now_sec == undefined) {
		_now_sec = is_array(game.__time) ? real(game.__time[1]) : 0;
	};
	var _enabled = bool(game._note_activation_enabled ?? false);
	if (!_enabled) {
		if (is_array(game.runtime_note_instances)) {
			for (var _i = 0; _i < array_length(game.runtime_note_instances); _i++) {
				chart_note_activate(game.runtime_note_instances[_i]);
			};
		};
		game._note_activation_index = is_array(game._notes) ? array_length(game._notes) : 0;
		return;
	};
	var _notes = game._notes;
	if (!is_array(_notes)) then return;
	var _index = 0;
	var _count = array_length(_notes);
	while (_index < _count) {
		var _item = _notes[_index];
		if (!is_struct(_item) || real(_item.activateSec ?? infinity) > _now_sec) then break;
		chart_note_activate(_item.id);
		_index++;
	};
	game._note_activation_index = _index;
}

function official_notes_refreeze_after_retry() {
	if (!variable_global_exists("game") || !is_struct(game)) then return;
	game._note_activation_index = 0;
	if (bool(game._note_activation_enabled ?? false) && is_array(game._notes)) {
		for (var _i = 0; _i < array_length(game._notes); _i++) {
			instance_deactivate_object(game._notes[_i].id);
		};
	};
}
