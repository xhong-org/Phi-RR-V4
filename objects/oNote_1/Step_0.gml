/// @description RPE note step: time, position, auto-judge
if (!inition) then exit;
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then exit;
if (variable_global_exists("game") && is_struct(game) && game.paused) then exit;
if (!instance_exists(_line_ref)) { canDraw = false; exit; };

// The bound line owns the local clock, including bpmfactor and cumulative chart offset.
_now_seconds = (variable_instance_exists(_line_ref, "line_sec") ? _line_ref.line_sec : 0);

_line_time = (variable_instance_exists(_line_ref, "line_time") ? _line_ref.line_time : 0);

// Judge windows are seconds so multi-BPM charts use the correct unit.
var late_ms = (_is_hold || type == 2 || type == 4 ? 161 : 201);
lateHitTime = late_ms * 0.001;
judgeTime = start_sec + hitTime2 * 0.001;

// scale refresh
if (_last_global_scales != global_scales) {
	event_user(7);
	_last_global_scales = global_scales;
};

// bad fade cleanup
if (isBad) {
	if (_now_seconds - judgeRealTime >= 1) then instance_deactivate_object(self);
	exit;
};

// far cull by floor distance / max visual (cheap)
if (_preload_seconds > 0) {
	var sec_to_hit = start_sec - _now_seconds;
	if (sec_to_hit > _preload_seconds) {
		var line_floor_pre = real(_line_ref.__value[0]);
		// PCR-style: not visible if line has not entered max visual window yet for distant notes
		if (line_floor_pre + _max_visible_floor_distance < floorPosition
			&& line_floor_pre < maximum_visual_position - _max_visible_floor_distance) {
			canDraw = false;
			exit;
		};
	};
};

// visibleTime is handled in rpe_note_apply_visibility() during position update

// fake note cleanup: PCR removes past notes even when not judged
if (isFake) {
	if (_is_hold) {
		if (_now_seconds >= end_sec) {
			canDraw = false;
			instance_deactivate_object(self);
			exit;
		};
	} else if (_now_seconds >= start_sec) {
		canDraw = false;
		instance_deactivate_object(self);
		exit;
	};
};

// update position
event_user(_step_user_count);

// auto judge path (autoplay style, same as Official)
if (!isFake) then event_user(_judge_user_count);
