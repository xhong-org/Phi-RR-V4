/// @description Update PEC note geometry and autoplay judgment.
if (game.paused || !instance_exists(line_ref)) then exit;
var chart_sec = game.__time[1] - game_2.chart.offsetSeconds;
var line_floor = line_ref.floor_position;
var current_scale = (variable_global_exists("global_scales") ? global_scales : 1) / 6;
image_xscale = current_scale * widthScale;
image_yscale = uniform_scale ? image_xscale : current_scale;
var scene_height = room_height * 0.6;
var local_x = localXFactor * room_width;
var axis_x = line_ref.__sin * sideDirection;
var axis_y = line_ref.__cos * sideDirection;
var base_x = line_ref.x + line_ref.__cos * local_x;
var base_y = line_ref.y - line_ref.__sin * local_x;
var distance = (speedFloorStart - speed * line_floor) * scene_height;
var note_x = base_x + axis_x * distance;
var note_y = base_y + axis_y * distance;
image_angle = line_ref.image_angle + angleOffset;

if (type == 2) {
	var before = (chart_sec < startSec);
	var head_offset = 0;
	if (before) {
		head_offset = max(0, hold_head_attach * image_yscale);
	};
	var units = before ? speedHoldFloorLength : speedFloorEnd - speed * line_floor;
	var hold_length = max(0, units * scene_height - head_offset);
	var body_scale = hold_length / hold_body_height;
	if (before) {
		hx0 = note_x; hy0 = note_y;
		hx1 = note_x + axis_x * head_offset; hy1 = note_y + axis_y * head_offset;
		hx2 = note_x + axis_x * (head_offset + hold_length); hy2 = note_y + axis_y * (head_offset + hold_length);
	} else {
		hx0 = base_x; hy0 = base_y;
		hx1 = base_x + axis_x * hold_length; hy1 = base_y + axis_y * hold_length;
	};
	yscale = body_scale;
	canDraw = (hold_length > 0 || before);
	if (!hold_started && chart_sec >= judge_sec) {
		hold_started = true;
		if (!isFake) {
			var hold_sample_sec = (!use_acc_judgment && chart_sec > late_deadline_sec) ? chart_sec : judge_sec;
			hit_status = judgeCalc(startSec, hold_sample_sec, 0, base_x, base_y, judge_type, true, false, true);
			if (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT) {
				hold_effect_sec = chart_sec;
				render_play_hitsound(sound);
			};
		};
	};
	if (hold_started && !isFake && (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT)) {
		var bpm_events = game_2.chart.bpmList;
		if (chart_sec < hold_bpm_last_sec) then hold_bpm_index = pec_bpm_index_at_sec(bpm_events, chart_sec);
		while (hold_bpm_index + 1 < array_length(bpm_events) && bpm_events[hold_bpm_index + 1].second <= chart_sec) hold_bpm_index++;
		hold_bpm_last_sec = chart_sec;
		if (chart_sec - hold_effect_sec >= bpm_events[hold_bpm_index].holdTickInterval) {
			if (variable_global_exists("_eff_c")) then _eff_c(base_x, base_y, hit_status == TYPE.PREFECT ? #ffeca0 : make_colour_rgb(162, 238, 255));
			hold_effect_sec = chart_sec;
		};
	};
	if (chart_sec >= endSec) {
		if (!isFake) {
			if (hold_started && (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT)) {
				judgeCalc(startSec, judge_sec, 0, base_x, base_y, judge_type, false, true, true);
			} else {
				judgeCalc(startSec, endSec + 1, 0, base_x, base_y, judge_type, false, true, true);
			};
		};
		canDraw = false;
		instance_deactivate_object(self);
	};
	exit;
};

x = note_x;
y = note_y;
canDraw = (chart_sec < startSec);
if (chart_sec >= trigger_sec && !judged) {
	judged = true;
	if (!isFake) {
		var note_sample_sec = (!use_acc_judgment && chart_sec > late_deadline_sec) ? chart_sec : judge_sec;
		hit_status = judgeCalc(startSec, note_sample_sec, 0, base_x, base_y, judge_type, true, true, true);
		if (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT) then render_play_hitsound(sound);
	};
	canDraw = false;
	instance_deactivate_object(self);
};
