/// @description Update PEC note geometry and autoplay judgment.
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then exit;
if (game.paused || !instance_exists(line_ref)) then exit;
var chart_sec = game.__time[1] - game_2.chart.offsetSeconds;
var line_floor = line_ref.floor_position;
var current_scale = (variable_global_exists("global_scales") ? global_scales : 1) / 6;
image_xscale = current_scale * widthScale;
image_yscale = uniform_scale ? image_xscale : current_scale;
var scene_height = chart_view_height * 0.6;
var local_x = localXFactor * chart_view_width;
var axis_x = line_ref.__sin * sideDirection;
var axis_y = line_ref.__cos * sideDirection;
var base_x = line_ref.x + line_ref.__cos * local_x;
var base_y = line_ref.y - line_ref.__sin * local_x;
var before_hold = (type == 2 && chart_sec < startSec);
// Phira: note travel is note.speed * (noteFloor - lineFloor) for taps and holds.
var speed_pos = note_speed * (floorPosition - line_floor);
var distance_units = (type == 2 && !before_hold) ? 0 : speed_pos;
var distance = distance_units * scene_height;
var note_x = base_x + axis_x * distance;
var note_y = base_y + axis_y * distance;
image_angle = line_ref.image_angle + angleOffset;
var pec_alpha_raw = real(line_ref._alpha_raw ?? (line_ref._alpha_value * 255));
var line_notes_visible = pec_note_alpha_visible(pec_alpha_raw, isAbove, startSec - chart_sec, startSec);
var behind_line = (speed_pos < -0.000001);
image_alpha = 1;

if (type == 2) {
	var before = before_hold;
	var _skin_hold = skin_active() ? skin_hold_parts(hl) : undefined;
	if (is_struct(_skin_hold)) {
		if (sprite_exists(_skin_hold.body)) then hold_body_height = max(1, sprite_get_height(_skin_hold.body));
		if (sprite_exists(_skin_hold.head)) then hold_head_attach = max(1, sprite_get_yoffset(_skin_hold.head));
	};
	var head_offset = 0;
	if (before && !(is_struct(_skin_hold) && bool(_skin_hold.compact))) {
		head_offset = max(0, hold_head_attach * image_yscale);
	};
	var units = before ? speedHoldFloorLength : speedFloorEnd - note_speed * line_floor;
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
	canDraw = line_notes_visible && (hold_length > 0 || before) && (before ? !behind_line : true);
	if (!hold_started && chart_sec >= judge_sec) {
		hold_started = true;
		if (!isFake) {
			var hold_sample_sec = (!use_acc_judgment && chart_sec > late_deadline_sec) ? chart_sec : judge_sec;
			var _hold_xy = pec_note_hit_effect_xy();
			hit_status = judgeCalc(startSec, hold_sample_sec, 0, _hold_xy[0], _hold_xy[1], judge_type, true, false, true);
			if (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT) {
				hold_effect_sec = chart_sec;
				skin_play_note_hitsound();
			};
		};
	};
	if (hold_started && !isFake && (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT)) {
		var bpm_events = game_2.chart.bpmList;
		if (chart_sec < hold_bpm_last_sec) then hold_bpm_index = pec_bpm_index_at_sec(bpm_events, chart_sec);
		while (hold_bpm_index + 1 < array_length(bpm_events) && bpm_events[hold_bpm_index + 1].second <= chart_sec) hold_bpm_index++;
		hold_bpm_last_sec = chart_sec;
		if (chart_sec - hold_effect_sec >= bpm_events[hold_bpm_index].holdTickInterval) {
			var _tick_xy = pec_note_hit_effect_xy();
			if (variable_global_exists("_eff_c")) then _eff_c(_tick_xy[0], _tick_xy[1], hit_status == TYPE.PREFECT ? #ffeca0 : make_colour_rgb(162, 238, 255));
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
	//if(line_id == 7 && floor(start_beat) == 32){
	//	print($"Hold State: hitTime={start_beat} line_id={line_id} type={type} x={note_x} y={note_y} rot={image_angle} yscale={yscale} nowTime={chart_sec} lineFP={line_floor} noteFP={floorPosition} speed={note_speed}");
	//};
	exit;
};

x = note_x;
y = note_y;


canDraw = line_notes_visible && !behind_line && !judged && chart_sec < startSec;
if (chart_sec >= trigger_sec && !judged) {
	judged = true;
	if (!isFake) {
		var note_sample_sec = (!use_acc_judgment && chart_sec > late_deadline_sec) ? chart_sec : judge_sec;
		var _hit_xy = pec_note_hit_effect_xy();
		hit_status = judgeCalc(startSec, note_sample_sec, 0, _hit_xy[0], _hit_xy[1], judge_type, true, true, true);
		if (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT) then skin_play_note_hitsound();
	};
	canDraw = false;
	instance_deactivate_object(self);
};


