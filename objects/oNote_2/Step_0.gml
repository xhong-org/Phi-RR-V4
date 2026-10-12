///@desc 更新 PEC 音符位置，并处理自动播放或超时判定
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then exit;
// 暂停或判定线丢失时不更新。
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
// 位移是音符速度乘音符地板与判定线地板之差。
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
if (type != 2) {
	image_alpha = chart_note_pass_fade(chart_sec, startSec, late_window_sec);
};

// Hold 单独算头尾，并在自动或手动路径里判定。
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
	// 自动播放到判定秒开始 Hold，超时则记 Miss。
	if (chart_autoplay_active()) {
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
	} else if (!isFake && !hold_started && !isMiss && chart_sec > late_deadline_sec) {
		isMiss = true;
		hold_started = true;
		hit_status = judgeCalc(startSec, chart_sec, 0, base_x, base_y, judge_type, false, true, true);
	};
	if (hold_started && !isFake && !isMiss && (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT)
		&& (chart_autoplay_active() || chart_kb_hold_alive())) {
		var bpm_events = game_2.chart.bpmList;
		if (chart_sec < hold_bpm_last_sec) then hold_bpm_index = pec_bpm_index_at_sec(bpm_events, chart_sec);
		// BPM 事件向前走到当前秒，按间隔刷尾迹。
		while (hold_bpm_index + 1 < array_length(bpm_events) && bpm_events[hold_bpm_index + 1].second <= chart_sec) hold_bpm_index++;
		hold_bpm_last_sec = chart_sec;
		if (chart_sec - hold_effect_sec >= bpm_events[hold_bpm_index].holdTickInterval) {
			var _tick_xy = pec_note_hit_effect_xy();
			if (variable_global_exists("_eff_c")) then _eff_c(_tick_xy[0], _tick_xy[1], hit_status == TYPE.PREFECT ? #ffeca0 : make_colour_rgb(162, 238, 255));
			hold_effect_sec = chart_sec;
		};
	};
	// Hold 结束时补记判定并停用。
	if (chart_sec >= endSec && (hold_started || isMiss || chart_autoplay_active() || chart_sec > late_deadline_sec)) {
		if (!isFake) {
			if (hold_started && (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT) && !isMiss) {
				judgeCalc(startSec, judge_sec, 0, base_x, base_y, judge_type, false, true, true);
			} else if (!isMiss) {
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


canDraw = line_notes_visible && !judged && (chart_sec < startSec ? !behind_line : image_alpha > 0);
// 非 Hold：到触发秒判定，超时则记 Miss。
if (chart_autoplay_active()) {
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
} else if (!judged && chart_sec > late_deadline_sec) {
	judged = true;
	if (!isFake) {
		judgeCalc(startSec, chart_sec, 0, x, y, judge_type, false, true, true);
	};
	canDraw = false;
	instance_deactivate_object(self);
};


