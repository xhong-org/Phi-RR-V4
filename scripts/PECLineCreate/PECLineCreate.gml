/// @desc Spread PEC line+note construction across loading frames.
/// Lines exist before notes (notes bind by line_id). Freeze after full init.

function pec_lines_creating() {
	return variable_global_exists("game_2") && is_struct(game_2)
		&& bool(game_2[$ "_chart_lines_creating"] ?? false);
}

function pec_lines_begin(_ctx = undefined) {
	var ctx = is_struct(_ctx) ? _ctx : game_2;
	ctx.line_group = [];
	ctx.runtime_line_instances = [];
	ctx.runtime_note_instances = [];
	ctx._notes = [];
	ctx._note_activation_index = 0;
	ctx._note_activation_enabled = false;
	var judge_lines = ctx.chart[$ "judgeLineList"] ?? [];
	if (!is_array(judge_lines)) then judge_lines = [];
	var source_notes = ctx.chart[$ "notes"] ?? [];
	if (!is_array(source_notes)) then source_notes = [];
	var line_count = array_length(judge_lines);
	ctx.line_group = array_create(line_count, noone);
	var _preload = 15;
	if (variable_global_exists("game") && is_struct(game) && is_struct(game.settings)) {
		_preload = real(game.settings.notePreloadSeconds ?? 15);
	};
	ctx._chart_line_job = {
		judge_lines: judge_lines,
		source_notes: source_notes,
		line_count: line_count,
		note_count: array_length(source_notes),
		next_line: 0,
		next_note: 0,
		phase: 0,
		note_preload: _preload
	};
	ctx._chart_lines_creating = true;
	chart_set_gameplay_visible(false);
}

function pec_lines_create_line(i) {
	var ctx = game_2;
	var job = ctx._chart_line_job;
	var line_override = chart_line_override(i);
	var line_sprite = chart_line_override_sprite(i);
	var pec_line_instance = instance_create_depth(room_width / 2, room_height / 2, DEPTH.LINE, oLine_2, {
		line_id: i,
		events: job.judge_lines[i],
		image_id: (sprite_exists(line_sprite) ? line_sprite : line),
		line_csv_scale: (is_struct(line_override) ? real(line_override.Scale ?? 1) : 1)
	});
	ctx.line_group[i] = pec_line_instance;
	array_add(ctx.runtime_line_instances, pec_line_instance);
	chart_lines_hide_created(pec_line_instance);
}

function pec_lines_force_init() {
	if (!variable_global_exists("game_2") || !is_struct(game_2) || !is_array(game_2.line_group)) then return;
	var lines = game_2.line_group;
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

function pec_lines_create_note(i) {
	var ctx = game_2;
	var job = ctx._chart_line_job;
	var note = job.source_notes[i];
	if (!is_struct(note)) then return;
	var note_instance = instance_create_depth(-999, -999, DEPTH.NOTE, oNote_2, {
		type: note.type, line_id: note.line_id,
		start_beat: note.startBeat, end_beat: note.endBeat,
		startSec: note.startSec, endSec: note.endSec,
		floorPosition: note.floorPosition, endFloorPosition: note.endFloorPosition,
		xOffset: note.xOffset, isAbove: note.isAbove, isFake: note.isFake,
		note_speed: note.speed, widthScale: note.xscale, _hl: note.hl,
		localXFactor: note.localXFactor, sideDirection: note.sideDirection,
		angleOffset: note.angleOffset, speedFloorStart: note.speedFloorStart,
		speedFloorEnd: note.speedFloorEnd, speedHoldFloorLength: note.speedHoldFloorLength
	});
	chart_lines_hide_created(note_instance);
	array_add(ctx.runtime_note_instances, note_instance);
	if (variable_global_exists("render_mode") && global.render_mode && !note.isFake
		&& instance_exists(note_instance)) {
		var note_hitsound_time = note.startSec;
		if (note.type != 3 && note.type != 4) then note_hitsound_time += note_instance.hit_offset;
		note_hitsound_time += ctx.chart.offsetSeconds;
		note_instance.render_hitsound_scheduled = render_schedule_hitsound(
			note_instance.sound, note_hitsound_time);
	};
	if (!note.isFake) then maxcombo++;
	if (!instance_exists(note_instance)) then return;
	array_add(ctx._notes, {
		id: note_instance,
		startSec: real(note_instance.startSec),
		endSec: real(note_instance.endSec),
		activateSec: real(note_instance.startSec) - job.note_preload,
		type: real(note_instance.type)
	});
}

function pec_lines_pump(_budget_us = CHART_LINE_CREATE_BUDGET_US) {
	if (!pec_lines_creating()) then return true;
	var ctx = game_2;
	var job = ctx._chart_line_job;
	if (!is_struct(job)) {
		ctx._chart_lines_creating = false;
		return true;
	};
	var t0 = get_timer();
	var created = 0;
	if (job.phase == 0) {
		while (job.next_line < job.line_count) {
			pec_lines_create_line(job.next_line);
			job.next_line++;
			created++;
			if (_budget_us > 0 && (get_timer() - t0) >= _budget_us && created >= 1) then return false;
		};
		pec_lines_force_init();
		job.phase = 1;
	};
	while (job.next_note < job.note_count) {
		pec_lines_create_note(job.next_note);
		job.next_note++;
		created++;
		if (_budget_us > 0 && (get_timer() - t0) >= _budget_us && created >= 1) then return false;
	};
	ctx._chart_lines_creating = false;
	return true;
}

function pec_lines_finish() {
	var ctx = game_2;
	ctx._chart_lines_creating = false;
	array_sort(ctx._notes, function(a, b) {
		if (a.activateSec < b.activateSec) then return -1;
		if (a.activateSec > b.activateSec) then return 1;
		return 0;
	});
	var _preload = 15;
	if (is_struct(ctx._chart_line_job)) then _preload = real(ctx._chart_line_job.note_preload ?? 15);
	ctx._note_activation_enabled = (_preload > 0);
	ctx._note_activation_index = (ctx._note_activation_enabled ? 0 : array_length(ctx._notes));
	for (var _di = 0; _di < array_length(ctx._notes); _di++) {
		instance_deactivate_object(ctx._notes[_di].id);
	};
	ctx._chart_line_job = undefined;
	chart_lines_freeze_object(oLine_2);
}

function pec_sync_note_activation(_now_sec = undefined) {
	if (!variable_global_exists("game_2") || !is_struct(game_2)) then return;
	if (_now_sec == undefined) {
		var _media = (variable_global_exists("game") && is_struct(game) && is_array(game.__time))
			? real(game.__time[1]) : 0;
		_now_sec = _media - real(game_2.chart.offsetSeconds ?? 0);
	};
	var _enabled = bool(game_2._note_activation_enabled ?? false);
	if (!_enabled) {
		if (is_array(game_2.runtime_note_instances)) {
			for (var _i = 0; _i < array_length(game_2.runtime_note_instances); _i++) {
				chart_note_activate(game_2.runtime_note_instances[_i]);
			};
		};
		game_2._note_activation_index = is_array(game_2._notes) ? array_length(game_2._notes) : 0;
		return;
	};
	var _notes = game_2._notes;
	if (!is_array(_notes)) then return;
	var _index = 0;
	var _count = array_length(_notes);
	while (_index < _count) {
		var _item = _notes[_index];
		if (!is_struct(_item) || real(_item.activateSec ?? infinity) > _now_sec) then break;
		chart_note_activate(_item.id);
		_index++;
	};
	game_2._note_activation_index = _index;
}

function pec_notes_refreeze_after_retry() {
	if (!variable_global_exists("game_2") || !is_struct(game_2)) then return;
	game_2._note_activation_index = 0;
	if (bool(game_2._note_activation_enabled ?? false) && is_array(game_2._notes)) {
		for (var _i = 0; _i < array_length(game_2._notes); _i++) {
			instance_deactivate_object(game_2._notes[_i].id);
		};
	};
}
