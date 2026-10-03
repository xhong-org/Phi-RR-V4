/// @desc Spread RPE line+note construction across loading frames.
/// Each line and note finishes Create + force-Step init, then freeze.
/// Thaw happens before music; GM activate is deferred one event.

#macro RPE_LINE_CREATE_BUDGET_US 8000

function rpe_lines_creating() {
	return variable_global_exists("game_1") && is_struct(game_1)
		&& bool(game_1[$ "_rpe_lines_creating"] ?? false);
}

function rpe_lines_hide_created(_inst) {
	chart_lines_hide_created(_inst);
}

function rpe_lines_begin() {
	var rpe = game_1;
	var judge_lines = rpe.chart[$ "judgeLineList"] ?? [];
	if (!is_array(judge_lines)) then judge_lines = [];
	// PhiZone zIndex / targetRange share one depth map. Charts that omit both
	// keep the legacy zOrder spacing so Phira line order does not move.
	global.chart_layer_mode = false;
	if (instance_exists(oExtraPlay)
		&& variable_instance_exists(oExtraPlay, "requests_chart_layers")
		&& oExtraPlay.requests_chart_layers) then global.chart_layer_mode = true;
	for (var layer_line_i = 0; layer_line_i < array_length(judge_lines) && !global.chart_layer_mode; layer_line_i++) {
		var layer_line = judge_lines[layer_line_i];
		if (!is_struct(layer_line)) then continue;
		if (is_real(layer_line[$ "zIndex"])) {
			global.chart_layer_mode = true;
			break;
		};
		var layer_notes = layer_line[$ "notes"];
		if (!is_array(layer_notes)) then continue;
		for (var layer_note_i = 0; layer_note_i < array_length(layer_notes); layer_note_i++) {
			var layer_note = layer_notes[layer_note_i];
			if (is_struct(layer_note) && is_real(layer_note[$ "zIndex"])) {
				global.chart_layer_mode = true;
				break;
			};
		};
	};
	if (global.chart_layer_mode && instance_exists(oExtraPlay)
		&& variable_instance_exists(oExtraPlay, "effect_controller")
		&& instance_exists(oExtraPlay.effect_controller)) {
		chart_set_instance_depth(oExtraPlay.effect_controller, chart_layer_depth(24));
	};
	var line_group_size = array_length(judge_lines);
	rpe.fatherLineList = [];
	rpe.line_list = array_create(line_group_size, noone);
	rpe.runtime_line_instances = [];
	rpe.runtime_note_instances = [];
	rpe._notes = [];
	rpe.Fonts = {};
	rpe._rpe_prep_bpm_ready = false;
	rpe_prep_upload_bpm();
	font_add_enable_aa(true);
	for (var font_line_i = 0; font_line_i < line_group_size; font_line_i++) {
		var font_line = judge_lines[font_line_i];
		if (!is_struct(font_line)) then continue;
		var font_extended = font_line[$ "extended"];
		if (!is_struct(font_extended)) then continue;
		var font_events = font_extended[$ "textEvents"];
		if (!is_array(font_events)) then continue;
		for (var font_event_i = 0; font_event_i < array_length(font_events); font_event_i++) {
			var font_event = font_events[font_event_i];
			if (!is_struct(font_event)) then continue;
			var font_name = string(font_event[$ "font"] ?? "cmdysj");
			if (!string_length(font_name) || string_lower(font_name) == "cmdysj"
				|| struct_exists(rpe.Fonts, font_name)) then continue;

			var font_source = font_name;
			var font_relative = string_replace_all(font_name, "\\", "/");
			if (string_pos("..", font_relative) <= 0 && string_char_at(font_relative, 1) != "/"
				&& string_pos(":", font_relative) <= 0) {
				var font_candidates = [font_relative];
				var font_lower = string_lower(font_relative);
				if (string_pos(".ttf", font_lower) <= 0 && string_pos(".otf", font_lower) <= 0
					&& string_pos(".ttc", font_lower) <= 0) {
					array_add(font_candidates, font_relative + ".ttf");
					array_add(font_candidates, font_relative + ".otf");
					array_add(font_candidates, font_relative + ".ttc");
				};
				for (var font_candidate_i = 0; font_candidate_i < array_length(font_candidates); font_candidate_i++) {
					var font_path = chart_path_join(InChartPath, font_candidates[font_candidate_i]);
					if (chart_file_exists_any(font_path)) {
						font_source = chart_file_readable_path(font_path);
						break;
					};
				};
			};

			var loaded_font = pls_font_add(font_source, 47, false, false, -infinity, infinity);
			rpe.Fonts[$ font_name] = loaded_font;
			if (loaded_font == -1) {
				show_debug_message($"[RPEFont] Failed to load font \"{font_name}\" from \"{font_source}\"");
			};
		};
	};
	print($"Lines Count: {line_group_size}");
	var eff_line_count = 0;
	if (chart_file_exists_any(chart_path_join(InChartPath, "extra.json"))) {
		// reserved extra-effect line count
	};
	print(eff_line_count);
	var line_limit = line_group_size - eff_line_count;
	if (line_limit < 0) then line_limit = 0;
	rpe._rpe_line_job = {
		judge_lines: judge_lines,
		line_group_size: line_group_size,
		line_limit: line_limit,
		next_index: 0,
		note_preload: real(game.settings.notePreloadSeconds ?? 15),
		chart_offset_sec: real(rpe.chart_info.offset ?? 0) / 1000
	};
	rpe._rpe_lines_creating = true;
	chart_set_gameplay_visible(false);
}

function rpe_lines_create_one(i) {
	var rpe = game_1;
	var job = rpe._rpe_line_job;
	var judge_lines = job.judge_lines;
	var _note_preload = job.note_preload;
	var _chart_offset_sec = job.chart_offset_sec;
	var l_s = judge_lines[i];
	if (!is_struct(l_s)) then return;
	var events = [];
	global._id = i;
	if (struct_exists(l_s, "eventLayers")) {
		events = l_s[$ "eventLayers"];
		if (!is_array(events)) then events = [];
	};

	var _isFather = (l_s[$ "father"] ?? -1);
	if (!is_real(_isFather)) then _isFather = -1;
	print($"Line[{i}]FatherID->{_isFather >= 0 ? _isFather : "undefined"}", game.settings.enableDebug);
	var line_override = chart_line_override(i);
	var line_image = is_struct(line_override) ? line_override.Image : (l_s[$ "Texture"] ?? "line.png");
	var l = (instance_create_depth(room_width / 2, room_height / 2, 0, oLine_1, {
		"line_id": i,
		"bindUI": (is_undefined(l_s[$ "attachUI"]) ? 0 : l_s[$ "attachUI"]),
		"image": line_image,
		"line_csv_scale": (is_struct(line_override) ? real(line_override.Scale ?? 1) : 1),
		"anchor": (l_s[$ "anchor"] ?? [0.5, 0.5]),
		"isFather": (_isFather),
		"isGif": (l_s[$ "isGif"] ?? false),
		"isCover": ((l_s[$ "isCover"] ?? true)),
		"sizeControl": (l_s[$ "sizeControl"] ?? []),
		"alphaControl": (l_s[$ "alphaControl"] ?? []),
		"posControl": (l_s[$ "posControl"] ?? []),
		"yControl": (l_s[$ "yControl"] ?? []),
		"rotFatherLine": (l_s[$ "rotateWithFather"] ?? false),
		"events": (events),
		"extEvents": (l_s[$ "extended"] ?? {}),
		"zOrder": (l_s[$ "zOrder"] ?? 0),
		"z_order_raw": real(l_s[$ "zOrder"] ?? 0),
		"zIndex": (l_s[$ "zIndex"] ?? undefined),
		"appearance_on_attach": (is_real(l_s[$ "appearanceOnAttach"]) ? real(l_s[$ "appearanceOnAttach"]) : 0),
		"scale_on_notes": (is_real(l_s[$ "scaleOnNotes"]) ? real(l_s[$ "scaleOnNotes"]) : 0),
		"bpmfactor": (l_s[$ "bpmfactor"] ?? 1)
	}));
	rpe.line_list[i] = l;
	array_add(rpe.runtime_line_instances, l);
	rpe_lines_hide_created(l);
	// Force Step so event cursors and raw transform exist before freeze.
	if (instance_exists(l)) {
		with (l) {
			rpe_force_event_init = true;
			event_perform(ev_step, ev_step_normal);
			rpe_force_event_init = false;
		};
	};

	var line_notes = l_s[$ "notes"] ?? [];
	if (!is_array(line_notes)) then line_notes = [];
	for (var n = 0; n < array_length(line_notes); n++) {
		var n_s = line_notes[n];
		if (!is_struct(n_s)) then continue;
		var isFake = bool(n_s[$ "isFake"] ?? false);
		if (!isFake) then maxcombo++;

		var rpe_type = real(n_s[$ "type"] ?? 1);
		var off_type = rpe_type;
		if (rpe_type == 2) then off_type = 3;
		else if (rpe_type == 3) then off_type = 4;
		else if (rpe_type == 4) then off_type = 2;

		var st_beat = game_1.Math.arrToBeat(n_s[$ "startTime"]);
		var et_beat = game_1.Math.arrToBeat(n_s[$ "endTime"]);
		var st_abs = game_1.Math.beatToAbsSec(st_beat);
		var et_abs = game_1.Math.beatToAbsSec(et_beat);
		var note_floor = 0;
		var end_floor = 0;
		if (instance_exists(l) && variable_instance_exists(l, "rpe_floor_at_sec")) {
			note_floor = l.rpe_floor_at_sec(st_abs);
			if (off_type == 3) then end_floor = l.rpe_floor_at_sec(et_abs);
		};
		var note_start_sec = st_abs;
		var note_end_sec = et_abs;

		var n_alpha = real(n_s[$ "alpha"] ?? 255);
		var n_size = real(n_s[$ "size"] ?? 1);
		var n_speed = real(n_s[$ "speed"] ?? 1);
		var n_yoff = real(n_s[$ "yOffset"] ?? 0);
		var n_vis = real(n_s[$ "visibleTime"] ?? 999999);
		var n_above_raw = struct_exists(n_s, "above") ? n_s[$ "above"]
			: (struct_exists(n_s, "isAbove") ? n_s[$ "isAbove"] : 1);
		var n_above = is_bool(n_above_raw) ? n_above_raw : (number(n_above_raw, 1) == 1);
		var note_tint = c_white;
		var note_tint_data = n_s[$ "tint"];
		if (!is_array(note_tint_data) || array_length(note_tint_data) < 3) then note_tint_data = n_s[$ "color"];
		if (is_array(note_tint_data) && array_length(note_tint_data) >= 3) {
			note_tint = make_color_rgb(
				clamp(real(note_tint_data[0]), 0, 255),
				clamp(real(note_tint_data[1]), 0, 255),
				clamp(real(note_tint_data[2]), 0, 255)
			);
		};
		var has_hit_tint = false;
		var hit_tint = c_white;
		var hit_tint_data = n_s[$ "tintHitEffects"];
		if (is_array(hit_tint_data) && array_length(hit_tint_data) >= 3) {
			has_hit_tint = true;
			hit_tint = make_color_rgb(
				clamp(real(hit_tint_data[0]), 0, 255),
				clamp(real(hit_tint_data[1]), 0, 255),
				clamp(real(hit_tint_data[2]), 0, 255)
			);
		};
		var custom_sound = -1;
		var custom_fmod_sound = -1;
		var custom_hitsound_path = "";
		var hitsound_name = string(n_s[$ "hitsound"] ?? "");
		if (hitsound_name == "tap.mp3") {
			custom_sound = snd_note_tap;
		} else if (hitsound_name == "drag.mp3") {
			custom_sound = snd_note_drag;
		} else if (hitsound_name == "flick.mp3") {
			custom_sound = snd_note_flick;
		} else if (string_length(hitsound_name)) {
			var hitsound_rel = string_replace_all(hitsound_name, "\\", "/");
			if (string_pos("..", hitsound_rel) <= 0 && string_char_at(hitsound_rel, 1) != "/") {
				var hitsound_path = chart_path_join(InChartPath, hitsound_rel);
				if (chart_file_exists_any(hitsound_path)) {
					custom_hitsound_path = chart_file_readable_path(hitsound_path);
					hitsound_path = custom_hitsound_path;
				};
				if (chart_file_exists_any(chart_path_join(InChartPath, hitsound_rel)) && instance_exists(oMedia)
					&& !(variable_global_exists("render_mode") && global.render_mode)) {
					if (!struct_exists(game_1, "HitSounds") || !is_struct(game_1.HitSounds)) then game_1.HitSounds = {};
					if (!struct_exists(game_1.HitSounds, hitsound_rel)) {
						var _media = instance_find(oMedia, 0);
						if (_media.track > 0) then fmod_system_select(_media.track);
						var loaded_hitsound = fmod_system_create_sound(hitsound_path, FMOD_MODE.DEFAULT);
						if (loaded_hitsound > 0) then game_1.HitSounds[$ hitsound_rel] = loaded_hitsound;
					};
					if (struct_exists(game_1.HitSounds, hitsound_rel)) then custom_fmod_sound = game_1.HitSounds[$ hitsound_rel];
				};
			};
		};

		var note_explicit_z = n_s[$ "zIndex"];
		var note_instance = instance_create_depth(-999, -999, DEPTH.NOTE, oNote_1, {
			"type": off_type,
			"rpe_type": rpe_type,
			"note_layer_z": chart_note_layer_z(rpe_type, is_real(note_explicit_z) ? real(note_explicit_z) : undefined) + n * 0.0000001,
			"isAbove": n_above,
			"alpha": (n_alpha / 255),
			"start_beat": st_beat,
			"end_beat": et_beat,
			"start_sec": note_start_sec,
			"end_sec": note_end_sec,
			"hold_beat": max(0, et_beat - st_beat),
			"xOffset": real(n_s[$ "positionX"] ?? 0),
			"yOffset": n_yoff,
			"yorigin": (n_yoff / 900),
			"floorPosition": note_floor,
			"endFloorPosition": end_floor,
			"holdFloorLength": (end_floor - note_floor),
			"size": n_size,
			"note_speed": n_speed,
			"visibleTime": n_vis,
			"isFake": isFake,
			"note_tint": note_tint,
			"has_hit_tint": has_hit_tint,
			"hit_tint": hit_tint,
			"custom_sound": custom_sound,
			"custom_fmod_sound": custom_fmod_sound,
			"custom_hitsound_path": custom_hitsound_path,
			"line_id": i
		});
		rpe_lines_hide_created(note_instance);
		var note_factor = real(l.bpmfactor);
		if (!is_real(note_factor) || note_factor <= 0) then note_factor = 1;
		var note_hit_sec = _chart_offset_sec + note_factor * note_start_sec;
		var note_end_hit_sec = _chart_offset_sec + note_factor * note_end_sec;
		if (variable_global_exists("render_mode") && global.render_mode && !isFake
			&& instance_exists(note_instance)) {
			var note_hitsound_time = note_hit_sec;
			if (off_type != 2 && off_type != 4) {
				note_hitsound_time += note_factor * note_instance.hitTime2 * 0.001;
			};
			note_instance.render_hitsound_scheduled = render_schedule_note_hitsound(
				note_instance, note_hitsound_time, custom_hitsound_path, isFake);
		};
		var note_lead = _note_preload;
		if (is_finite(n_vis) && n_vis >= 0 && n_vis < 999999) then note_lead = min(note_lead, note_factor * n_vis);
		array_add(rpe._notes, {
			id: note_instance,
			startSec: note_start_sec,
			endSec: note_end_sec,
			activateSec: note_hit_sec - note_lead,
			hitSec: note_hit_sec,
			alwaysActive: (n_speed == 0 || (off_type == 3 && note_hit_sec <= 0 && note_end_hit_sec > 0))
		});
		array_add(rpe.runtime_note_instances, note_instance);
	};
}

function rpe_lines_pump(_budget_us = CHART_LINE_CREATE_BUDGET_US) {
	if (!rpe_lines_creating()) then return true;
	var rpe = game_1;
	var job = rpe._rpe_line_job;
	if (!is_struct(job)) {
		rpe._rpe_lines_creating = false;
		return true;
	};
	var t0 = get_timer();
	var created = 0;
	while (job.next_index < job.line_limit) {
		rpe_lines_create_one(job.next_index);
		job.next_index++;
		created++;
		if (_budget_us > 0 && (get_timer() - t0) >= _budget_us && created >= 1) then break;
	};
	if (job.next_index >= job.line_limit) {
		rpe._rpe_lines_creating = false;
		return true;
	};
	return false;
}

function rpe_lines_finish() {
	var rpe = game_1;
	rpe._rpe_lines_creating = false;
	array_sort(rpe._notes, function(a, b) {
		if (a.startSec < b.startSec) then return -1;
		if (a.startSec > b.startSec) then return 1;
		return 0;
	});
	var _group_start = 0;
	while (_group_start < array_length(rpe._notes)) {
		var _group_end = _group_start + 1;
		var _group_time = rpe._notes[_group_start].startSec;
		while (_group_end < array_length(rpe._notes)
			&& rpe._notes[_group_end].startSec == _group_time) _group_end++;
		if (_group_end - _group_start > 1) {
			for (var _hi = _group_start; _hi < _group_end; _hi++) {
				var _highlight_note = rpe._notes[_hi].id;
				if (instance_exists(_highlight_note)) then _highlight_note.hl = 1;
			};
		};
		_group_start = _group_end;
	};
	array_sort(rpe._notes, function(a, b) {
		if (a.activateSec < b.activateSec) then return -1;
		if (a.activateSec > b.activateSec) then return 1;
		if (a.hitSec < b.hitSec) then return -1;
		if (a.hitSec > b.hitSec) then return 1;
		return 0;
	});
	var _note_preload = 15;
	if (is_struct(rpe._rpe_line_job)) then _note_preload = real(rpe._rpe_line_job.note_preload ?? 15);
	rpe._note_activation_enabled = (_note_preload > 0);
	rpe._note_activation_index = (rpe._note_activation_enabled ? 0 : array_length(rpe._notes));
	rpe._note_activation_last_time = -infinity;
	// Freeze every note only after Create + spatial records finished.
	for (var _di = 0; _di < array_length(rpe._notes); _di++) {
		instance_deactivate_object(rpe._notes[_di].id);
	};

	for (var _fi = 0; _fi < array_length(rpe.line_list); _fi++) {
		var _fl = rpe.line_list[_fi];
		if (!instance_exists(_fl)) then continue;
		var _seen = array_create(array_length(rpe.line_list), false);
		var _parent = _fl.isFather;
		var _valid_parent = true;
		while (is_real(_parent) && _parent >= 0) {
			if (_parent >= array_length(rpe.line_list) || _parent == _fi || _seen[_parent]
				|| !instance_exists(rpe.line_list[_parent])) {
				_valid_parent = false;
				break;
			};
			_seen[_parent] = true;
			_parent = rpe.line_list[_parent].isFather;
		};
		if (!_valid_parent) then _fl.isFather = -1;
		_fl._father_chain = [];
		_parent = _fl.isFather;
		var _chain_guard = 0;
		while (is_real(_parent) && _parent >= 0 && _chain_guard < 16) {
			var _parent_line = rpe.line_list[_parent];
			if (!instance_exists(_parent_line)) then break;
			array_add(_fl._father_chain, _parent_line);
			_parent = _parent_line.isFather;
			_chain_guard++;
		};
	};

	if (is_array(rpe.line_list)) {
		var _n_lines = array_length(rpe.line_list);
		var _order = array_create(0);
		for (var _zi = 0; _zi < _n_lines; _zi++) {
			var _l0 = rpe.line_list[_zi];
			if (!instance_exists(_l0)) then continue;
			var _z0 = 0;
			if (variable_instance_exists(_l0, "zIndex") && is_real(_l0.zIndex)) then _z0 = real(_l0.zIndex)
			else if (variable_instance_exists(_l0, "zOrder") && is_real(_l0.zOrder)) then _z0 = real(_l0.zOrder);
			if (!is_finite(_z0)) then _z0 = 0;
			_l0.zOrder = _z0;
			_l0.z = _z0;
			if (!variable_instance_exists(_l0, "line_id") || !is_real(_l0.line_id)) then _l0.line_id = _zi;
			array_add(_order, _l0);
		};

		for (var _i = 1; _i < array_length(_order); _i++) {
			var _cur = _order[_i];
			var _j = _i - 1;
			while (_j >= 0) {
				var _prev = _order[_j];
				var _dz = real(_prev.zOrder) - real(_cur.zOrder);
				var _swap = false;
				if (_dz > 0) {
					_swap = true;
				} else if (_dz == 0 && real(_prev.line_id) > real(_cur.line_id)) {
					_swap = true;
				};
				if (!_swap) then break;
				_order[_j + 1] = _prev;
				_j--;
			};
			_order[_j + 1] = _cur;
		};

		var _line_count = array_length(_order);
		if (variable_global_exists("chart_layer_mode") && global.chart_layer_mode) {
			var unique_orders = [];
			for (var _ui = 0; _ui < _line_count; _ui++) {
				var _unique_line = _order[_ui];
				if (variable_instance_exists(_unique_line, "zIndex") && is_real(_unique_line.zIndex)) then continue;
				var _raw_order = real(_unique_line.z_order_raw ?? _unique_line.zOrder);
				var _raw_seen = false;
				for (var _uj = 0; _uj < array_length(unique_orders); _uj++) {
					if (unique_orders[_uj] == _raw_order) {
						_raw_seen = true;
						break;
					};
				};
				if (!_raw_seen) then array_add(unique_orders, _raw_order);
			};
			array_sort(unique_orders, function(a, b) { return sign(a - b); });
			var precedence_step = 1 / max(1, array_length(unique_orders));
			for (var _ri = 0; _ri < _line_count; _ri++) {
				var _layer_line = _order[_ri];
				var _layer_z;
				if (variable_instance_exists(_layer_line, "zIndex") && is_real(_layer_line.zIndex)) {
					_layer_z = real(_layer_line.zIndex);
				} else {
					var _raw_order = real(_layer_line.z_order_raw ?? _layer_line.zOrder);
					var _prec_index = 0;
					for (var _pj = 0; _pj < array_length(unique_orders); _pj++) {
						if (unique_orders[_pj] == _raw_order) {
							_prec_index = _pj;
							break;
						};
					};
					_layer_z = 2 + _prec_index * precedence_step;
				};
				_layer_z += real(_layer_line.line_id) * 0.0000001;
				_layer_line.layer_z = _layer_z;
				chart_set_instance_depth(_layer_line, chart_layer_depth(_layer_z));
			};
			if (is_array(rpe.runtime_note_instances)) {
				for (var _note_depth_i = 0; _note_depth_i < array_length(rpe.runtime_note_instances); _note_depth_i++) {
					var _note_depth = rpe.runtime_note_instances[_note_depth_i];
					if (!instance_exists(_note_depth)) then continue;
					if (variable_instance_exists(_note_depth, "note_layer_z") && is_real(_note_depth.note_layer_z)) {
						chart_set_instance_depth(_note_depth, chart_layer_depth(_note_depth.note_layer_z));
					};
				};
			};
		} else {
			var _depth_span = DEPTH.LINE - (DEPTH.NOTE + 2);
			var _depth_step = 1;
			if (_line_count > _depth_span + 1) {
				_depth_step = _depth_span / max(1, _line_count - 1);
			};
			for (var _ri = 0; _ri < _line_count; _ri++) {
				chart_set_instance_depth(_order[_ri], DEPTH.LINE - _ri * _depth_step);
			};
		};
	};

	for (var _initial_line_i = 0; _initial_line_i < array_length(rpe.line_list); _initial_line_i++) {
		var _initial_line = rpe.line_list[_initial_line_i];
		if (instance_exists(_initial_line)) {
			with (_initial_line) {
				rpe_force_event_init = true;
				event_perform(ev_step, ev_step_end);
				rpe_force_event_init = false;
			};
		};
	};
	print("[C-Lines] Done.", game.settings.enableDebug);
	if (is_struct(rpe.chart) && struct_exists(rpe.chart, "judgeLineList")) {
		delete(rpe.chart.judgeLineList);
	};
	rpe._rpe_line_job = undefined;
}

function rpe_lines_post_bind() {
	var rpe = game_1;
	var _spatial_groups = rpe._note_spatial_groups;
	if (is_array(_spatial_groups)) {
		var _spatial_group_count = array_length(_spatial_groups);
		for (var _spatial_i = 0; _spatial_i < _spatial_group_count; _spatial_i++) {
			array_sort(_spatial_groups[_spatial_i].notes, function(a, b) {
				if (a.spatialFloor < b.spatialFloor) then return -1;
				if (a.spatialFloor > b.spatialFloor) then return 1;
				return 0;
			});
		};
	};
	var _hold_groups = rpe._note_spatial_hold_groups;
	if (is_array(_hold_groups)) {
		var _hold_group_count = array_length(_hold_groups);
		for (var _hold_group_i = 0; _hold_group_i < _hold_group_count; _hold_group_i++) {
			var _hold_group = _hold_groups[_hold_group_i];
			_hold_group.count = array_length(_hold_group.notes);
			_hold_group.originalNotes = array_create(_hold_group.count);
			array_copy(_hold_group.originalNotes, 0, _hold_group.notes, 0, _hold_group.count);
		};
	};
	if (!struct_exists(rpe, "line_list") || !is_array(rpe.line_list)) {
		rpe.line_list = [];
		with (oLine_1) array_add(rpe.line_list, id);
	};
	if (instance_exists(oRender_1)) {
		var _render = instance_find(oRender_1, 0);
		if (instance_exists(_render) && variable_instance_exists(_render, "play_transition_bound_ui")
			&& is_struct(_render.play_transition_bound_ui)) {
			with (oLine_1) {
				if (is_attach_ui && instance_exists(_render)) then _render.play_transition_bound_ui[$ attach_ui_key] = true;
			};
		};
	};
}

function rpe_lines_freeze_after_init() {
	chart_lines_freeze_object(oLine_1);
}

function rpe_lines_complete() {
	rpe_lines_finish();
	rpe_lines_post_bind();
	rpe_lines_freeze_after_init();
}

function rpe_lines_thaw_force_init() {
	if (!variable_global_exists("game_1") || !is_struct(game_1) || !is_array(game_1.line_list)) then return;
	var lines = game_1.line_list;
	for (var i = 0; i < array_length(lines); i++) {
		var l = lines[i];
		if (!instance_exists(l)) then continue;
		with (l) {
			rpe_force_event_init = true;
			event_perform(ev_step, ev_step_normal);
			rpe_force_event_init = false;
		};
	};
	for (var j = 0; j < array_length(lines); j++) {
		var line_end = lines[j];
		if (!instance_exists(line_end)) then continue;
		with (line_end) {
			rpe_force_event_init = true;
			event_perform(ev_step, ev_step_end);
			rpe_force_event_init = false;
		};
	};
}
