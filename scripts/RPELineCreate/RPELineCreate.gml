// 把 RPE 判定线与音符的创建摊到多个加载帧。
// 每条线和每个音符完成 Create 与强制 Step 初始化后再冻结。
// 音乐开始前解冻；GameMaker 的激活推迟一个事件。

#macro RPE_LINE_CREATE_BUDGET_US 8000

///@desc 判断 RPE 判定线是否仍在分帧创建
///@returns {Bool} 正在创建时为真
function rpe_lines_creating() {
	return variable_global_exists("game_1") && is_struct(game_1)
		&& bool(game_1[$ "_rpe_lines_creating"] ?? false);
}

///@desc 隐藏刚创建、尚未参与播放的实例
///@param {Id.Instance} _inst 实例
///@returns {Undefined} 无
function rpe_lines_hide_created(_inst) {
	chart_lines_hide_created(_inst);
}

///@desc 准备 RPE 创建任务、字体与 BPM，并隐藏游玩画面
///@returns {Undefined} 无
function rpe_lines_begin() {
	var rpe = game_1;
	var judge_lines = rpe.chart[$ "judgeLineList"] ?? [];
	if (!is_array(judge_lines)) then judge_lines = [];
	// PhiZone 的 zIndex 与 targetRange 共用一张深度表。两者都没有的谱
	// 仍用旧的 zOrder 间距，避免 Phira 判定线顺序被挪动。
	global.chart_layer_mode = false;
	global.chart_layer_layout = undefined;
	if (instance_exists(oExtraPlay)
		&& variable_instance_exists(oExtraPlay, "requests_chart_layers")
		&& oExtraPlay.requests_chart_layers) then global.chart_layer_mode = true;
	for (var layer_line_i = 0; layer_line_i < array_length(judge_lines) && !global.chart_layer_mode; layer_line_i++) {
		var layer_line = judge_lines[layer_line_i];
		if (!is_struct(layer_line)) then continue;
		// 线或音符带 zIndex 就启用图层深度
		if (is_real(layer_line[$ "zIndex"])) {
			global.chart_layer_mode = true;
			break;
		};
		var layer_notes = layer_line[$ "notes"];
		if (!is_array(layer_notes)) then continue;
		for (var layer_note_i = 0; layer_note_i < array_length(layer_notes); layer_note_i++) {
			var layer_note = layer_notes[layer_note_i];
			if (is_struct(layer_note) && (is_real(layer_note[$ "zIndex"]) || is_real(layer_note[$ "zIndexHitEffects"]))) {
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
	rpe._pose_epoch = 0;
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
			// 默认字体和已经加载过的字体不再读文件
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
		// 预留给额外特效的判定线数量
	};
	print(eff_line_count);
	var line_limit = line_group_size - eff_line_count;
	// 特效线占满时不再创建普通线
	if (line_limit < 0) then line_limit = 0;
	rpe._rpe_line_job = {
		judge_lines: judge_lines,
		line_group_size: line_group_size,
		line_limit: line_limit,
		next_index: 0,
		next_note: 0,
		line_ready: false,
		note_preload: real(game.settings.notePreloadSeconds ?? 15),
		chart_offset_sec: real(rpe.chart_info.offset ?? 0) / 1000
	};
	rpe._rpe_lines_creating = true;
	chart_set_gameplay_visible(false);
}

///@desc 创建一条 RPE 判定线；音符由独立游标分批创建
///@param {Real} i 判定线序号
///@returns {Undefined} 无
function rpe_lines_create_one(i) {
	var rpe = game_1;
	var job = rpe._rpe_line_job;
	var judge_lines = job.judge_lines;
	var _note_preload = job.note_preload;
	var _chart_offset_sec = job.chart_offset_sec;
	var l_s = judge_lines[i];
	// 空槽不创建实例
	if (!is_struct(l_s)) then return;
	var events = [];
	global._id = i;
	if (struct_exists(l_s, "eventLayers")) {
		events = l_s[$ "eventLayers"];
		if (!is_array(events)) then events = [];
	};

	var _isFather = (l_s[$ "father"] ?? -1);
	// 父线 id 非法时视为没有父线
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
		"integrate_speed_easings": l_s[$ "integrateSpeedEasings"],
		"skewControl": (l_s[$ "skewControl"] ?? []),
		"bpmfactor": (l_s[$ "bpmfactor"] ?? 1)
	}));
	rpe.line_list[i] = l;
	array_add(rpe.runtime_line_instances, l);
	rpe_lines_hide_created(l);
	// 冻结前强制 Step，让事件游标和原始变换先存在。
	if (instance_exists(l)) {
		with (l) {
			rpe_force_event_init = true;
			event_perform(ev_step, ev_step_normal);
			rpe_force_event_init = false;
		};
	};

	return l;
}

///@desc 创建一颗 RPE 音符；加载游标保留原始线号和音符顺序
///@param {Real} i 判定线序号
///@param {Real} n 音符序号
///@returns {Undefined} 无
function rpe_lines_create_note(i, n) {
	var rpe = game_1;
	var job = rpe._rpe_line_job;
	var l = rpe.line_list[i];
	var l_s = job.judge_lines[i];
	var line_notes = l_s.notes;
	var _note_preload = job.note_preload;
	var _chart_offset_sec = job.chart_offset_sec;
	var n_s = line_notes[n];
	// 坏音符数据跳过
	if (!is_struct(n_s)) then return;
	var isFake = bool(n_s[$ "isFake"] ?? false);
	if (!isFake) then maxcombo++;

	var rpe_type = real(n_s[$ "type"] ?? 1);
	var off_type = rpe_type;
	// RPE 类型 2/3/4 换成播放端的 Hold/Flick/Drag
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
	// 内置打击音名直接用资源，其余尝试从谱面目录加载
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
		"note_layer_z": chart_note_layer_z(rpe_type, is_real(note_explicit_z) ? real(note_explicit_z) : undefined),
		"note_layer_bias": n * 0.0001,
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
		"hit_effect_z": is_real(n_s[$ "zIndexHitEffects"]) && is_finite(n_s.zIndexHitEffects) ? real(n_s.zIndexHitEffects) : 7,
		"custom_sound": custom_sound,
		"custom_fmod_sound": custom_fmod_sound,
		"custom_hitsound_path": custom_hitsound_path,
		"line_id": i
	});
	rpe_lines_hide_created(note_instance);
	var note_factor = real(l.bpmfactor);
	// 线的 BPM 倍率无效时按 1
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
	// 谱面写了可见时间时，提前量不能超过它
	if (is_finite(n_vis) && n_vis >= 0 && n_vis < 999999) then note_lead = min(note_lead, note_factor * n_vis);
	array_add(rpe._notes, {
		id: note_instance,
		layerZ: note_instance.note_layer_z,
		hitZ: note_instance.hit_effect_z,
		startSec: note_start_sec,
		endSec: note_end_sec,
		activateSec: note_hit_sec - note_lead,
		hitSec: note_hit_sec,
		alwaysActive: (n_speed == 0 || (off_type == 3 && note_hit_sec <= 0 && note_end_hit_sec > 0))
	});
	array_add(rpe.runtime_note_instances, note_instance);
}

///@desc 在时间预算内继续创建 RPE 判定线
///@param {Real} _budget_us 本帧预算，微秒
///@returns {Bool} 本批已全部建完
function rpe_lines_pump(_budget_us = CHART_LINE_CREATE_BUDGET_US) {
	if (!rpe_lines_creating()) then return true;
	var rpe = game_1;
	var job = rpe._rpe_line_job;
	// 任务丢失则结束创建
	if (!is_struct(job)) {
		rpe._rpe_lines_creating = false;
		return true;
	};
	var t0 = get_timer();
	var created = 0;
	while (job.next_index < job.line_limit) {
		var line_index = job.next_index;
		if (!job.line_ready) {
			rpe_lines_create_one(line_index);
			job.line_ready = true;
			created++;
		} else {
			var source_line = job.judge_lines[line_index];
			var notes = is_struct(source_line) ? source_line[$ "notes"] : undefined;
			var note_count = is_array(notes) ? array_length(notes) : 0;
			if (instance_exists(rpe.line_list[line_index]) && job.next_note < note_count) {
				rpe_lines_create_note(line_index, job.next_note);
				job.next_note++;
				created++;
			} else {
				job.next_index++;
				job.next_note = 0;
				job.line_ready = false;
			};
		};
		// 检查到音符粒度；一条密集线不能独占整个加载帧。
		if (_budget_us > 0 && created > 0 && (get_timer() - t0) >= _budget_us) then break;
	};
	if (job.next_index >= job.line_limit) {
		rpe._rpe_lines_creating = false;
		return true;
	};
	return false;
}

///@desc 排序音符、校验父线并按层级设置深度
///@returns {Undefined} 无
function rpe_lines_finish() {
	var rpe = game_1;
	rpe._rpe_lines_creating = false;
	array_sort(rpe._notes, 
	///@desc 按全局打击秒比较音符，包含 bpmfactor 和偏移
	///@param {Struct} a 左项
	///@param {Struct} b 右项
	///@returns {Real} 小于为 -1，大于为 1，相等为 0
	function(a, b) {
		if (a.hitSec < b.hitSec) then return -1;
		if (a.hitSec > b.hitSec) then return 1;
		return 0;
	});
	var _group_start = 0;
	while (_group_start < array_length(rpe._notes)) {
		var _group_end = _group_start + 1;
		var _group_time = rpe._notes[_group_start].hitSec;
		while (_group_end < array_length(rpe._notes)
			&& rpe._notes[_group_end].hitSec == _group_time) _group_end++;
		// 同一时刻多于一颗时打开同时音高亮
		if (_group_end - _group_start > 1 && bool(game.settings.enableNoteHightLight)) {
			for (var _hi = _group_start; _hi < _group_end; _hi++) {
				var _highlight_note = rpe._notes[_hi].id;
				if (instance_exists(_highlight_note)) then _highlight_note.hl = 1;
			};
		};
		_group_start = _group_end;
	};
	array_sort(rpe._notes, 
	///@desc 先按激活时间、再按打击时间比较音符
	///@param {Struct} a 左项
	///@param {Struct} b 右项
	///@returns {Real} 小于为 -1，大于为 1，相等为 0
	function(a, b) {
		if (a.activateSec < b.activateSec) then return -1;
		if (a.activateSec > b.activateSec) then return 1;
		if (a.hitSec < b.hitSec) then return -1;
		if (a.hitSec > b.hitSec) then return 1;
		return 0;
	});
	var _note_preload = 15;
	if (is_struct(rpe._rpe_line_job)) then _note_preload = real(rpe._rpe_line_job.note_preload ?? 15);
	// 预加载为 0 时视为音符一开始就全部激活
	rpe._note_activation_enabled = (_note_preload > 0);
	rpe._note_activation_index = (rpe._note_activation_enabled ? 0 : array_length(rpe._notes));
	rpe._note_activation_last_time = -infinity;
	// 创建和空间记录都完成后才冻结每个音符。
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
				// 父链越界、自环或断掉则这条线不再挂父线
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
		// 父图已经校验；上限取线数，与原生后端保持一致。
		while (is_real(_parent) && _parent >= 0 && _chain_guard < array_length(rpe.line_list)) {
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
				// 已按 zOrder、再按 line_id 排好则停止插入
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
				// 已有 zIndex 的线不参与旧 zOrder 均分
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
			array_sort(unique_orders, 
			///@desc 按原始层级数值升序
			///@param {Real} a 左值
			///@param {Real} b 右值
			///@returns {Real} 比较符号
			function(a, b) { return sign(a - b); });
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
				_layer_line.layer_z = _layer_z;
				chart_set_instance_depth(_layer_line, chart_layer_depth(_layer_z));
			};
			rpe_effect_layer_layout_prepare();
			if (is_array(rpe.runtime_note_instances)) {
				for (var _note_depth_i = 0; _note_depth_i < array_length(rpe.runtime_note_instances); _note_depth_i++) {
					var _note_depth = rpe.runtime_note_instances[_note_depth_i];
					if (!instance_exists(_note_depth)) then continue;
					if (variable_instance_exists(_note_depth, "note_layer_z") && is_real(_note_depth.note_layer_z)) {
						chart_set_instance_depth(_note_depth, chart_layer_depth(_note_depth.note_layer_z) - _note_depth.note_layer_bias);
					};
				};
			};
		} else {
			var _depth_span = DEPTH.LINE - (DEPTH.NOTE + 2);
			var _depth_step = 1;
			// 线比深度槽多时压缩间距，避免盖住音符
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

///@desc 排序空间分组并补登记绑定到界面的判定线
///@returns {Undefined} 无
function rpe_lines_post_bind() {
	var rpe = game_1;
	var _spatial_groups = rpe._note_spatial_groups;
	if (is_array(_spatial_groups)) {
		var _spatial_group_count = array_length(_spatial_groups);
		for (var _spatial_i = 0; _spatial_i < _spatial_group_count; _spatial_i++) {
			array_sort(_spatial_groups[_spatial_i].notes, 
			///@desc 按空间地板比较音符
			///@param {Struct} a 左项
			///@param {Struct} b 右项
			///@returns {Real} 小于为 -1，大于为 1，相等为 0
			function(a, b) {
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
			// 区间头排序和尾端前缀最大值，能跳过尚未进入视口的长 Hold。
			array_sort(_hold_group.notes, function(a, b) {
				return sign(min(a.spatialFloor, a.endSpatialFloor) - min(b.spatialFloor, b.endSpatialFloor));
			});
			var tail_max = -infinity;
			_hold_group.tailMax = [];
			for (var hold_i = 0; hold_i < array_length(_hold_group.notes); hold_i++) {
				var hold = _hold_group.notes[hold_i];
				tail_max = max(tail_max, hold.spatialFloor, hold.endSpatialFloor);
				array_push(_hold_group.tailMax, tail_max);
			}
			_hold_group.count = array_length(_hold_group.notes);
			_hold_group.originalNotes = array_create(_hold_group.count);
			array_copy(_hold_group.originalNotes, 0, _hold_group.notes, 0, _hold_group.count);
		};
	};
	rpe_note_queries_reset();
	// 线表缺失时从仍存在的实例重新收集
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

///@desc 初始化结束后冻结 RPE 判定线对象
///@returns {Undefined} 无
function rpe_lines_freeze_after_init() {
	chart_lines_freeze_object(oLine_1);
}

///@desc 完成收尾、绑定并冻结 RPE 判定线
///@returns {Undefined} 无
function rpe_lines_complete() {
	rpe_lines_finish();
	rpe_lines_post_bind();
	rpe_lines_freeze_after_init();
}

///@desc 解冻后对 RPE 判定线再强制跑普通 Step 与 Step End
///@returns {Undefined} 无
function rpe_lines_thaw_force_init() {
	if (!variable_global_exists("game_1") || !is_struct(game_1) || !is_array(game_1.line_list)) then return;
	var lines = game_1.line_list;
	// 第一轮补普通 Step
	for (var i = 0; i < array_length(lines); i++) {
		var l = lines[i];
		if (!instance_exists(l)) then continue;
		with (l) {
			rpe_force_event_init = true;
			event_perform(ev_step, ev_step_normal);
			rpe_force_event_init = false;
		};
	};
	// 第二轮补 Step End，父子变换才完整
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

///@desc 在全部世界姿态就绪后刷新活动音符，暂停时只响应布局变化
///@param {Bool} _layout_changed 视口是否改变
///@returns {Undefined} 无
function rpe_notes_refresh_geometry(_layout_changed) {
	if (game.paused && !_layout_changed) return;
	with (oNote_1) {
		if (inition && instance_exists(_line_ref)) event_user(_step_user_count);
	}
}

///@desc 字符串键只用于粗分组；再用原始数值区分同键的速度和 Y 偏移
///@param {Any} _first 同键的首组
///@param {Real} _speed 音符速度
///@param {Any} _y_origin Hold 的 Y 偏移；普通音符省略
///@returns {Any} 匹配的组或 undefined
function rpe_note_group_find(_first, _speed, _y_origin = undefined) {
	var group = _first;
	// GML 默认的浮点比较也有容差。这里只在加载时比较分组原值，随后恢复全局设置。
	var epsilon = math_get_epsilon();
	math_set_epsilon(0);
	try {
		while (is_struct(group)) {
			if (group.speed == _speed && group[$ "yOrigin"] == _y_origin) return group;
			group = group.nextWithKey;
		}
	} finally {
		math_set_epsilon(epsilon);
	}
	return undefined;
}

///@desc 重建查询块的剩余计数；音符顺序和绘制深度不变
///@returns {Undefined} 无
function rpe_note_queries_reset() {
	var groups_by_kind = [game_1._note_spatial_groups, game_1._note_spatial_hold_groups];
	for (var kind = 0; kind < 2; kind++) {
		var groups = groups_by_kind[kind];
		for (var gi = 0; gi < array_length(groups); gi++) {
			var group = groups[gi];
			var notes = group.notes;
			var count = array_length(notes);
			group.blockLive = array_create(ceil(count / 64), 0);
			group.remaining = 0;
			for (var ni = 0; ni < count; ni++) {
				var record = notes[ni];
				record.queryKind = kind;
				record.queryGroup = gi;
				record.queryBlock = ni div 64;
				if (record.activated) continue;
				group.blockLive[ni div 64]++;
				group.remaining++;
			}
		}
	}
}

///@desc 标记已激活的空间记录，使后续查询跳过空块
///@param {Struct} _record 音符空间记录
///@returns {Undefined} 无
function rpe_note_mark_active(_record) {
	if (_record.activated) return;
	_record.activated = true;
	if (is_undefined(_record[$ "queryKind"])) return;
	var groups = _record.queryKind == 0 ? game_1._note_spatial_groups : game_1._note_spatial_hold_groups;
	var group = groups[_record.queryGroup];
	group.blockLive[_record.queryBlock]--;
	group.remaining--;
}
