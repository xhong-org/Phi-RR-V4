// 把官谱判定线与音符的创建摊到多个加载帧。
// 先建线再放音符（音符按 line_id 绑定），全部初始化后再冻结。

///@desc 判断官谱判定线是否仍在分帧创建
///@returns {Bool} 正在创建时为真
function official_lines_creating() {
	return variable_global_exists("game") && is_struct(game)
		&& bool(game[$ "_chart_lines_creating"] ?? false);
}

///@desc 读取当前谱面视口的宽高与对角线余量
///@returns {Struct} 视口左、宽、高、右、对角线与缩放
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
		// 1.25 覆盖音符精灵，以及贴在视口边缘的判定线
		diag: point_distance(0, 0, view_w, view_h) * 1.25,
		scale: max(1, view_h * 0.6)
	};
}

///@desc 计算归一化坐标到视口外的像素距离
///@param {Real} _x_norm 横向归一化坐标
///@param {Real} _y_norm 纵向归一化坐标，向上为正
///@param {Struct} _metrics 视口度量
///@returns {Real} 视口内为 0，否则为到边界的距离
function official_norm_gap(_x_norm, _y_norm, _metrics) {
	var px = _metrics.view_l + _metrics.view_w * _x_norm;
	var py = _metrics.view_h * (1 - _y_norm);
	var dx = 0;
	if (px < _metrics.view_l) then dx = _metrics.view_l - px;
	else if (px > _metrics.view_r) then dx = px - _metrics.view_r;
	var dy = 0;
	if (py < 0) then dy = -py;
	else if (py > _metrics.view_h) then dy = py - _metrics.view_h;
	// 点在视口内则没有空隙
	if (dx == 0 && dy == 0) then return 0;
	return point_distance(0, 0, dx, dy);
}

///@desc 预计算判定线速度段与位移空隙，供可见性判断
///@param {Struct} _line_data 判定线数据
///@param {Struct} _metrics 视口度量
///@returns {Struct} 分段时间、地板、速度与空隙
function official_line_vis_cache(_line_data, _metrics) {
	var bpm = real(_line_data[$ "bpm"] ?? 60);
	// 无效 BPM 按 60 处理
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
		// 首事件之前沿用该事件，并回溯到时间 0
		if (seg_i == 0 && sec0 > 0) {
			event_floor -= sec0 * speed_value;
			sec0 = 0;
		};
		floors[seg_i] = event_floor;
		values[seg_i] = speed_value;
		t0s[seg_i] = sec0;
		// 空隙算到下一事件；只有最后一段速度会越过结束时间
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
		// 跳过在本速度段开始前已经结束的位移
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

// 长条用整段身体跨度：头部在视口外时，身体仍可能穿过视口。
///@desc 计算音符最早可判定或进入视野的秒
///@param {Struct} _cache 判定线可见性缓存
///@param {Real} _floor 音符地板位置
///@param {Real} _speed 音符速度
///@param {Real} _hit_sec 打击时刻
///@param {Real} _hold_len 长条地板长度
///@param {Bool} _is_hold 是否为长条
///@returns {Real} 激活秒，不早于 0
function official_note_activate_sec(_cache, _floor, _speed, _hit_sec, _hold_len, _is_hold) {
	var judge_at = max(0, _hit_sec - 0.5);
	// 静止短音立即可见；零长度长条只按判定时刻
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
		// 本段地板区间碰不到可见带则跳过
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
	// 无穷或负值都钳到 0
	if (!is_real(activate_sec) || activate_sec < 0) then return 0;
	return activate_sec;
}

///@desc 清空旧纹理并开始官谱分帧创建
///@returns {Undefined} 无
function official_lines_begin() {
	var owner = game;
	var old_texture_names = (struct_get_names(owner.TextureGroup));
	for (var texture_i = 0; texture_i < array_length(old_texture_names); texture_i++) {
		// 默认线贴图保留，其余纹理释放
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

///@desc 创建一条官谱判定线并缓存其可见性
///@param {Real} i 判定线序号
///@returns {Undefined} 无
function official_lines_create_line(i) {
	var owner = game;
	var job = owner._chart_line_job;
	var line_override = chart_line_override(i);
	var img = chart_line_override_sprite(i);
	// 覆盖贴图无效时用默认判定线
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

///@desc 对已创建的官谱判定线强制执行普通 Step
///@returns {Undefined} 无
function official_lines_force_init() {
	if (!variable_global_exists("game") || !is_struct(game) || !is_array(game.line_list)) then return;
	var lines = game.line_list;
	for (var i = 0; i < array_length(lines); i++) {
		var l = lines[i];
		if (!instance_exists(l)) then continue;
		with (l) {
			// 强制跑一遍普通 Step，初始化事件游标
			chart_force_event_init = true;
			event_perform(ev_step, ev_step_normal);
			chart_force_event_init = false;
		};
	};
}

///@desc 创建一颗官谱音符并计算其激活秒
///@param {Real} i 音符序号
///@returns {Undefined} 无
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
		"bodySpeed": (na[$ "bodySpeed"] ?? 1),
		"_hl": (na[$ "hl"])
	});
	chart_lines_hide_created(note_instance);
	array_add(owner.runtime_note_instances, note_instance);
	// 录像模式按音符类型预约打击音
	if (variable_global_exists("render_mode") && global.render_mode && instance_exists(note_instance)) {
		var note_hitsound_time = (note_instance.type == 2 || note_instance.type == 4)
			? note_instance.realHitTime : note_instance.judgeRealTime;
		note_instance.render_hitsound_scheduled = render_schedule_note_hitsound(
			note_instance, note_hitsound_time);
	};
	// 实例已不存在则不再计算激活时间
	if (!instance_exists(note_instance)) then return;
	var line_index = real(na[$ "id"] ?? 0);
	var line_cache = undefined;
	if (line_index >= 0 && line_index < array_length(job.line_vis)) {
		line_cache = job.line_vis[line_index];
		// 该线还没有可见性缓存时补算一份
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

///@desc 在时间预算内继续创建官谱判定线与音符
///@param {Real} _budget_us 本帧预算，微秒
///@returns {Bool} 本批已全部建完
function official_lines_pump(_budget_us = CHART_LINE_CREATE_BUDGET_US) {
	if (!official_lines_creating()) then return true;
	var owner = game;
	var job = owner._chart_line_job;
	// 任务丢失则结束创建
	if (!is_struct(job)) {
		owner._chart_lines_creating = false;
		return true;
	};
	var t0 = get_timer();
	var created = 0;
	// 阶段 0 先建判定线，超时则留到下一帧
	if (job.phase == 0) {
		while (job.next_line < job.line_count) {
			official_lines_create_line(job.next_line);
			job.next_line++;
			created++;
			if (_budget_us > 0 && (get_timer() - t0) >= _budget_us && created >= 1) then return false;
		};
		// 线建完后强制初始化，再进入音符阶段
		official_lines_force_init();
		job.phase = 1;
	};
	// 阶段 1 创建音符，超时则留到下一帧
	while (job.next_note < job.note_count) {
		official_lines_create_note(job.next_note);
		job.next_note++;
		created++;
		if (_budget_us > 0 && (get_timer() - t0) >= _budget_us && created >= 1) then return false;
	};
	owner._chart_lines_creating = false;
	return true;
}

///@desc 排序并冻结官谱音符，预加载方块后结束任务
///@returns {Undefined} 无
function official_lines_finish() {
	var owner = game;
	owner._chart_lines_creating = false;
	array_sort(owner._notes, 
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
	// 官谱忽略 notePreloadSeconds，音符在本体可能进入视野时唤醒
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

///@desc 按当前时间唤醒已到激活点的官谱音符
///@param {Real} _now_sec 谱面时间，缺省为媒体时间
///@returns {Undefined} 无
function official_sync_note_activation(_now_sec = undefined) {
	if (!variable_global_exists("game") || !is_struct(game)) then return;
	if (_now_sec == undefined) {
		_now_sec = is_array(game.__time) ? real(game.__time[1]) : 0;
	};
	var _enabled = bool(game._note_activation_enabled ?? false);
	// 未启用分帧激活时一次唤醒全部音符
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
	// 激活时间已排序，遇到未到点的项即可停止
	while (_index < _count) {
		var _item = _notes[_index];
		if (!is_struct(_item) || real(_item.activateSec ?? infinity) > _now_sec) then break;
		chart_note_activate(_item.id);
		_index++;
	};
	game._note_activation_index = _index;
}

///@desc 重试后把尚未到点的官谱音符重新停用
///@returns {Undefined} 无
function official_notes_refreeze_after_retry() {
	if (!variable_global_exists("game") || !is_struct(game)) then return;
	game._note_activation_index = 0;
	if (bool(game._note_activation_enabled ?? false) && is_array(game._notes)) {
		for (var _i = 0; _i < array_length(game._notes); _i++) {
			instance_deactivate_object(game._notes[_i].id);
		};
	};
}
