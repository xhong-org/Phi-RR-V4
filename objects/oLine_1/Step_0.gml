/// @description RPE judge-line event runtime (PCR-aligned)
if (!is_array(events)) then events = [];
if (!is_array(events_count)) then events_count = [];
if (!is_array(events_hold)) then events_hold = [];
if (!is_array(events_recall)) then events_recall = [];
// A line can be reactivated after chart construction has been deferred.
// Rebuild missing event cursors before evaluating the first active frame.
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
// Multi-layer values are summed in RPE editor space.
// Parent/screen transform is applied in End Step so parents evaluate first.
// Extended special events (scale/color/text) live under extEvents once.

if (variable_global_exists("loading_animation_active") && global.loading_animation_active
	&& !rpe_force_event_init) then exit;
var _transition_updates = instance_exists(oRender_1)
	&& variable_instance_exists(oRender_1, "play_transition_active")
	&& bool(oRender_1.play_transition_active);
if (variable_global_exists("game") && is_struct(game) && game.paused
	&& !_transition_updates && !rpe_force_event_init) then exit;
var _events = events;
var _event_layer_count = (is_array(_events) ? array_length(_events) : 0);
if (_event_layer_count <= 0 && !is_struct(extEvents)) then exit;

// ---- current chart beat time ----
var now_sec = 0;
if (variable_global_exists("game") && is_struct(game) && is_array(game.__time)) {
        now_sec = game.__time[1];
};

var chart_offset_sec = 0;
if (variable_global_exists("game_1") && is_struct(game_1) && is_struct(game_1.chart_info)) {
        chart_offset_sec = real(game_1.chart_info.offset ?? 0) / 1000;
};

var tf = ((!is_real(bpmfactor) || bpmfactor <= 0) ? 1 : bpmfactor);
// PCR absolute chart seconds = media seconds - (META.offset + external info offset)
var chart_sec = now_sec - chart_offset_sec;
// PCR: selftime = chart_time / timeFactor(bpmfactor)  -- used by speed floor
line_sec = chart_sec / tf;
// RPE parser stores all runtime event times in cumulative BPM seconds.
line_time = line_sec;

// ---- multi-layer sum (local RPE space only this step) ----
var sum_x = 0;
var sum_y = 0;
var sum_a = 0;
var sum_r = 0;

if (_event_layer_count > 0) {
        for (var i = 0; i < _event_layer_count; i++) {
                if (!is_struct(_events[i])) then continue;
                // RPE layers may omit unused channels. Keep the layer valid
                // and let the evaluator use its default instead of indexing a
                // missing struct key during the first frame.
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
// attachUI keeps real alpha for HUD write; line itself is hidden in End Step/Draw.
__raw_a = sum_a;
// PCR _alpha_decimal is the unclamped RPE alpha sum (can be negative / >255)
_alpha_decimal = sum_a;
__value[0] = speed_floor; // already /4.5 in speed prep (PCR)
__value[1] = speed_floor;
__a = sum_a;

if (!rpe_events_test_logged && line_id == 0
        && variable_global_exists("pls_archive_test") && global.pls_archive_test) {
    print($"[RPE Events][INIT] line=0 initialized={rpe_events_initialized} layers={_event_layer_count} cursors={array_length(events_count)} x={sum_x} y={sum_y} alpha={sum_a} rot={sum_r} speedSegments={array_length(rpe_speed_events)}");
    rpe_events_test_logged = true;
};

// ---- extended special events ----
__scale_x = rpe_eval_ext_events("scaleXEvents", 1);
__scale_y = rpe_eval_ext_events("scaleYEvents", 1);
__incline = rpe_eval_ext_events("inclineEvents", 0);
__incline_sin = dsin(__incline);
if (has_color_events) {
        __color = rpe_eval_color_events(c_white);
} else {
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
	if (_gif_event_count > 0) {
		var _gif_last_end_time = 0;
		var _gif_last_end_value = 0;
		var _gif_has_previous = false;
		for (var _gi = 0; _gi < _gif_event_count; _gi++) {
			var _gev = _gif_events[_gi];
			if (!is_struct(_gev)) then continue;
			if (line_time < _gev.startTime) then break;
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
