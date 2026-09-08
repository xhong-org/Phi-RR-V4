/// @desc Spread Official line+note construction across loading frames.
/// Lines exist before notes (notes bind by line_id). Freeze after full init.

function official_lines_creating() {
	return variable_global_exists("game") && is_struct(game)
		&& bool(game[$ "_chart_lines_creating"] ?? false);
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
		note_preload: real(owner.settings.notePreloadSeconds ?? 15)
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
		note_instance.render_hitsound_scheduled = render_schedule_hitsound(
			note_instance.sound, note_hitsound_time);
	};
	if (!instance_exists(note_instance)) then return;
	var hit_sec = real(note_instance.realHitTime);
	array_add(owner._notes, {
		id: note_instance,
		activateSec: hit_sec - job.note_preload,
		hitSec: hit_sec
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
	var _preload = 15;
	if (is_struct(owner._chart_line_job)) then _preload = real(owner._chart_line_job.note_preload ?? 15);
	owner._note_activation_enabled = (_preload > 0);
	owner._note_activation_index = (owner._note_activation_enabled ? 0 : array_length(owner._notes));
	for (var _di = 0; _di < array_length(owner._notes); _di++) {
		instance_deactivate_object(owner._notes[_di].id);
	};
	print("[C-Lines] Done.", owner.settings.enableDebug);
	print("[C-Notes] Done.", owner.settings.enableDebug);
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
