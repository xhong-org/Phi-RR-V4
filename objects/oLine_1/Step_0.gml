///@desc 步进：RPE 判定线事件运行时，对齐 PCR
if (!is_array(events)) then events = [];
if (!is_array(events_count)) then events_count = [];
if (!is_array(events_hold)) then events_hold = [];
if (!is_array(events_recall)) then events_recall = [];
// 谱面构建被推迟后，线可能被重新激活。
// 在第一个有效帧求值前，补上缺失的事件游标。
if (!variable_instance_exists(id, "rpe_events_initialized") || !rpe_events_initialized
	|| array_length(events_count) != array_length(events)
	|| array_length(events_hold) != array_length(events)
	|| array_length(events_recall) != array_length(events)) {
    events_count = [];
    events_hold = [];
    events_recall = [];
    for (var _init_layer = 0; _init_layer < array_length(events); _init_layer++) {
        var _init_events = events[_init_layer];
        var _init_counts = {};
        var _init_hold = {};
        var _init_recall = {};
        if (is_struct(_init_events)) {
            if (!struct_exists(_init_events, "moveXEvents")) then _init_events.moveXEvents = [];
            if (!struct_exists(_init_events, "moveYEvents")) then _init_events.moveYEvents = [];
            if (!struct_exists(_init_events, "alphaEvents")) then _init_events.alphaEvents = [];
            if (!struct_exists(_init_events, "rotateEvents")) then _init_events.rotateEvents = [];
            if (!struct_exists(_init_events, "speedEvents")) then _init_events.speedEvents = [];
            var _init_names = struct_get_names(_init_events);
            for (var _init_name_i = 0; _init_name_i < array_length(_init_names); _init_name_i++) {
                var _init_name = _init_names[_init_name_i];
                var _init_array = _init_events[$ _init_name];
                _init_counts[$ _init_name] = 0;
                // 有事件时用第一条起点初始化保持值。
                if (is_array(_init_array) && array_length(_init_array) > 0) {
                    var _init_value = _init_array[0][$ "start"] ?? 0;
                    _init_hold[$ _init_name] = _init_value;
                    _init_recall[$ _init_name] = _init_value;
                } else {
                    _init_hold[$ _init_name] = 0;
                    _init_recall[$ _init_name] = 0;
                };
            };
        };
        array_add(events_count, _init_counts);
        array_add(events_hold, _init_hold);
        array_add(events_recall, _init_recall);
    };
    rpe_events_initialized = true;
};
// 多层数值在 RPE 编辑器空间里相加。
// 父级和屏幕变换放在步进结束，好让父线先求值。
// 扩展事件（缩放、颜色、文本）只在 extEvents 里存一份。

// 加载动画或暂停时不求值，除非强制初始化或转场还在更新。
if (variable_global_exists("loading_animation_active") && global.loading_animation_active
	&& !rpe_force_event_init) then exit;
var _transition_updates = instance_exists(oRender_1)
	&& variable_instance_exists(oRender_1, "play_transition_active")
	&& bool(oRender_1.play_transition_active);
if (variable_global_exists("game") && is_struct(game) && game.paused
	&& !_transition_updates && !rpe_force_event_init) then exit;
var _events = events;
var _event_layer_count = (is_array(_events) ? array_length(_events) : 0);
// 既没有事件层也没有扩展事件。
if (_event_layer_count <= 0 && !is_struct(extEvents)) then exit;

// 当前谱面时间，单位是拍
var now_sec = 0;
if (variable_global_exists("game") && is_struct(game) && is_array(game.__time)) {
        now_sec = game.__time[1];
};

var chart_offset_sec = 0;
if (variable_global_exists("game_1") && is_struct(game_1) && is_struct(game_1.chart_info)) {
        chart_offset_sec = real(game_1.chart_info.offset ?? 0) / 1000;
};

var tf = ((!is_real(bpmfactor) || bpmfactor <= 0) ? 1 : bpmfactor);
// PCR 的绝对谱面秒 = 媒体秒 -（META.offset + 外部信息偏移）。
var chart_sec = now_sec - chart_offset_sec;
// PCR：selftime = chart_time / timeFactor(bpmfactor)，速度 floor 用它。
line_sec = chart_sec / tf;
// RPE 解析器把运行时事件时间都存成累计 BPM 秒。
line_time = line_sec;

// ---- multi-layer sum (local RPE space only this step) ----
var sum_x = 0;
var sum_y = 0;
var sum_a = 0;
var sum_r = 0;

if (_event_layer_count > 0) {
        for (var i = 0; i < _event_layer_count; i++) {
                // 坏层跳过。
                if (!is_struct(_events[i])) then continue;
                // RPE 层可以省略没用到的通道。层仍然有效，
                // 求值器用默认值，避免第一帧去索引不存在的键。
                if (struct_exists(_events[i], "moveXEvents")) then sum_x += rpe_eval_events(i, "moveXEvents", 0);
                if (struct_exists(_events[i], "moveYEvents")) then sum_y += rpe_eval_events(i, "moveYEvents", 0);
                if (struct_exists(_events[i], "alphaEvents")) then sum_a += rpe_eval_events(i, "alphaEvents", 0);
                if (struct_exists(_events[i], "rotateEvents")) then sum_r += rpe_eval_events(i, "rotateEvents", 0);
        };
};
var speed_floor = rpe_speed_floor();

__raw_x = sum_x;
__raw_y = sum_y;
__raw_r = sum_r;
// attachUI 把真实透明度留给界面写入；线本身在步进结束和绘制里隐藏。
__raw_a = sum_a;
// PCR 的 _alpha_decimal 是未夹取的 RPE 透明度之和，可以是负数或大于 255。
_alpha_decimal = sum_a;
__value[0] = speed_floor; // 速度预处理里已经除过 4.5（PCR）
__value[1] = speed_floor;
__a = sum_a;

if (!rpe_events_test_logged && line_id == 0
        && variable_global_exists("pls_archive_test") && global.pls_archive_test) {
    print($"[RPE Events][INIT] line=0 initialized={rpe_events_initialized} layers={_event_layer_count} cursors={array_length(events_count)} x={sum_x} y={sum_y} alpha={sum_a} rot={sum_r} speedLayers={array_length(rpe_speed_events)}");
    rpe_events_test_logged = true;
};

// 扩展特殊事件
__scale_x = rpe_eval_ext_events("scaleXEvents", 1);
__scale_y = rpe_eval_ext_events("scaleYEvents", 1);
__incline = rpe_eval_ext_events("inclineEvents", 0);
__incline_sin = dsin(__incline);
if (has_color_events) {
        __color = rpe_eval_color_events(c_white);
} else {
        // 没有颜色事件就用白。
        __color = c_white;
};
if (has_text_events) {
        line_text = rpe_eval_text_events("");
} else {
        line_text = "";
};
__paint_radius = (has_paint_events ? rpe_eval_ext_events("paintEvents", -1) : -1);
if (has_gif_events && is_struct(gif_data) && real(gif_data.total) > 0) {
	var _gif_duration = real(gif_data.total);
	__gif_progress = frac(max(0, line_time) / _gif_duration);
	var _gif_events = extEvents[$ "gifEvents"];
	var _gif_event_count = (is_array(_gif_events) ? array_length(_gif_events) : 0);
	// 有 gif 事件时按事件覆盖进度，空隙里沿用上一个终点往后走。
	if (_gif_event_count > 0) {
		var _gif_last_end_time = 0;
		var _gif_last_end_value = 0;
		var _gif_has_previous = false;
		for (var _gi = 0; _gi < _gif_event_count; _gi++) {
			var _gev = _gif_events[_gi];
			if (!is_struct(_gev)) then continue;
			// 还没到这条就开始，后面更晚。
			if (line_time < _gev.startTime) then break;
			// 落在区间内就插值。
			if (line_time <= _gev.endTime) {
				__gif_progress = lerp(real(_gev.start), real(_gev[$ "end"]), rpe_event_progress(_gev, _gev.startTime, _gev.endTime));
				_gif_has_previous = false;
				break;
			};
			_gif_last_end_time = _gev.endTime;
			_gif_last_end_value = real(_gev[$ "end"]);
			_gif_has_previous = true;
		};
		if (_gif_has_previous) then __gif_progress = frac(_gif_last_end_value + (line_time - _gif_last_end_time) / _gif_duration);
	};
};
