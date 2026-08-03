/// @description RPE judge-line event runtime (PCR-aligned)
// Multi-layer values are summed in RPE editor space.
// Parent/screen transform is applied in End Step so parents evaluate first.
// Extended special events (scale/color/text) live under extEvents once.

if (variable_global_exists("game") && is_struct(game) && game.paused) then exit;
if ((!is_array(events) || array_length(events) <= 0) && (!is_struct(extEvents))) then exit;

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

if (is_array(events)) {
        for (var i = 0; i < array_length(events); i++) {
                if (!is_struct(events[i])) then continue;
                sum_x += rpe_eval_events(i, "moveXEvents", 0);
                sum_y += rpe_eval_events(i, "moveYEvents", 0);
                sum_a += rpe_eval_events(i, "alphaEvents", 0);
                sum_r += rpe_eval_events(i, "rotateEvents", 0);
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
	if (is_array(_gif_events) && array_length(_gif_events) > 0) {
		var _gif_last_end_time = 0;
		var _gif_last_end_value = 0;
		var _gif_has_previous = false;
		for (var _gi = 0; _gi < array_length(_gif_events); _gi++) {
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
