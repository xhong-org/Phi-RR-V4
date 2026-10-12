// 把 PEC 判定线与音符的创建摊到多个加载帧。
// 先建线再放音符（音符按 line_id 绑定），全部初始化后再冻结。

///@desc 判断 PEC 判定线是否仍在分帧创建
///@returns {Bool} 正在创建时为真
function pec_lines_creating() {
	return variable_global_exists("game_2") && is_struct(game_2)
		&& bool(game_2[$ "_chart_lines_creating"] ?? false);
}

///@desc 初始化 PEC 创建任务并隐藏游玩画面
///@param {Struct} _ctx 谱面上下文，缺省为 game_2
///@returns {Undefined} 无
function pec_lines_begin(_ctx = undefined) {
	// 未传入上下文时使用 game_2
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
	// 预加载秒数来自设置，缺省 15
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
	// 创建完成前先隐藏游玩对象
	chart_set_gameplay_visible(false);
}

///@desc 创建一条 PEC 判定线并记入运行时列表
///@param {Real} i 判定线序号
///@returns {Undefined} 无
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

///@desc 对已创建的 PEC 判定线强制执行普通 Step
///@returns {Undefined} 无
function pec_lines_force_init() {
	// 上下文或线组无效则直接退出
	if (!variable_global_exists("game_2") || !is_struct(game_2) || !is_array(game_2.line_group)) then return;
	var lines = game_2.line_group;
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

///@desc 创建一颗 PEC 音符并登记激活时间
///@param {Real} i 音符序号
///@returns {Undefined} 无
function pec_lines_create_note(i) {
	var ctx = game_2;
	var job = ctx._chart_line_job;
	var note = job.source_notes[i];
	// 源数据不是结构体则跳过
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
	// 录像模式为非假音符预约打击音
	if (variable_global_exists("render_mode") && global.render_mode && !note.isFake
		&& instance_exists(note_instance)) {
		var note_hitsound_time = note.startSec;
		if (note.type != 3 && note.type != 4) then note_hitsound_time += note_instance.hit_offset;
		note_hitsound_time += ctx.chart.offsetSeconds;
		note_instance.render_hitsound_scheduled = render_schedule_note_hitsound(
			note_instance, note_hitsound_time);
	};
	if (!note.isFake) then maxcombo++;
	// 实例已不存在则不再登记激活
	if (!instance_exists(note_instance)) then return;
	array_add(ctx._notes, {
		id: note_instance,
		startSec: real(note_instance.startSec),
		endSec: real(note_instance.endSec),
		activateSec: real(note_instance.startSec) - job.note_preload,
		type: real(note_instance.type)
	});
}

///@desc 在时间预算内继续创建 PEC 判定线与音符
///@param {Real} _budget_us 本帧预算，微秒
///@returns {Bool} 本批已全部建完
function pec_lines_pump(_budget_us = CHART_LINE_CREATE_BUDGET_US) {
	// 不在创建中则视为已经完成
	if (!pec_lines_creating()) then return true;
	var ctx = game_2;
	var job = ctx._chart_line_job;
	// 任务丢失则结束创建
	if (!is_struct(job)) {
		ctx._chart_lines_creating = false;
		return true;
	};
	var t0 = get_timer();
	var created = 0;
	// 阶段 0 先建判定线，超时则留到下一帧
	if (job.phase == 0) {
		while (job.next_line < job.line_count) {
			pec_lines_create_line(job.next_line);
			job.next_line++;
			created++;
			if (_budget_us > 0 && (get_timer() - t0) >= _budget_us && created >= 1) then return false;
		};
		// 线建完后强制初始化，再进入音符阶段
		pec_lines_force_init();
		job.phase = 1;
	};
	// 阶段 1 创建音符，超时则留到下一帧
	while (job.next_note < job.note_count) {
		pec_lines_create_note(job.next_note);
		job.next_note++;
		created++;
		if (_budget_us > 0 && (get_timer() - t0) >= _budget_us && created >= 1) then return false;
	};
	ctx._chart_lines_creating = false;
	return true;
}

///@desc 排序并冻结 PEC 音符，结束创建任务
///@returns {Undefined} 无
function pec_lines_finish() {
	var ctx = game_2;
	ctx._chart_lines_creating = false;
	// 按激活时间排序，供之后顺序唤醒
	array_sort(ctx._notes, 
	///@desc 按激活时间比较音符
	///@param {Struct} a 左项
	///@param {Struct} b 右项
	///@returns {Real} 小于为 -1，大于为 1，相等为 0
	function(a, b) {
		if (a.activateSec < b.activateSec) then return -1;
		if (a.activateSec > b.activateSec) then return 1;
		return 0;
	});
	var _preload = 15;
	if (is_struct(ctx._chart_line_job)) then _preload = real(ctx._chart_line_job.note_preload ?? 15);
	// 预加载为 0 时视为音符一开始就全部激活
	ctx._note_activation_enabled = (_preload > 0);
	ctx._note_activation_index = (ctx._note_activation_enabled ? 0 : array_length(ctx._notes));
	for (var _di = 0; _di < array_length(ctx._notes); _di++) {
		instance_deactivate_object(ctx._notes[_di].id);
	};
	ctx._chart_line_job = undefined;
	chart_lines_freeze_object(oLine_2);
}

///@desc 按当前时间唤醒已到激活点的 PEC 音符
///@param {Real} _now_sec 谱面时间，缺省为媒体时间减偏移
///@returns {Undefined} 无
function pec_sync_note_activation(_now_sec = undefined) {
	if (!variable_global_exists("game_2") || !is_struct(game_2)) then return;
	// 未给时间时用媒体时间减去谱面偏移
	if (_now_sec == undefined) {
		var _media = (variable_global_exists("game") && is_struct(game) && is_array(game.__time))
			? real(game.__time[1]) : 0;
		_now_sec = _media - real(game_2.chart.offsetSeconds ?? 0);
	};
	var _enabled = bool(game_2._note_activation_enabled ?? false);
	// 未启用分帧激活时一次唤醒全部音符
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
	// 激活时间已排序，遇到未到点的项即可停止
	while (_index < _count) {
		var _item = _notes[_index];
		if (!is_struct(_item) || real(_item.activateSec ?? infinity) > _now_sec) then break;
		chart_note_activate(_item.id);
		_index++;
	};
	game_2._note_activation_index = _index;
}

///@desc 重试后把尚未到点的 PEC 音符重新停用
///@returns {Undefined} 无
function pec_notes_refreeze_after_retry() {
	if (!variable_global_exists("game_2") || !is_struct(game_2)) then return;
	game_2._note_activation_index = 0;
	if (bool(game_2._note_activation_enabled ?? false) && is_array(game_2._notes)) {
		for (var _i = 0; _i < array_length(game_2._notes); _i++) {
			instance_deactivate_object(game_2._notes[_i].id);
		};
	};
}
