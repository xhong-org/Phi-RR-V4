/// @description Auto-judge non-hold RPE note
if (_is_hold || !inition || isFake) then exit;

var now_time = _now_seconds;
var now_hit = judgeTime;

if (now_time > start_sec + lateHitTime && !isBad && !isJudge && !game.settings.enableAccJudgment) {
	if (is_real_note) {
		judgeCalc(start_sec, now_time, 0, _note_x, _note_y, type, false, true, true);
	};
	instance_deactivate_object(self);
	exit;
};

if ((type == 2 || type == 4) && !isJudge && now_time >= start_sec && now_hit >= start_sec - lateHitTime && now_hit <= start_sec + lateHitTime) {
	if (is_real_note) {
		hit_status = judgeCalc(start_sec, now_hit, 0, _x_h, _y_h, type, true, true, true, has_hit_tint ? hit_tint : undefined);
		rpe_play_hitsound(sound, custom_fmod_sound, custom_hitsound_path);
	};
	isJudge = true;
	judgeRealTime = _now_seconds;
	//print($"type={type} time={string_format(start_beat , 0 , 10)} lineID={line_id} line_xy=[{_line_ref.x} , {_line_ref.y}] note_xy=[{x} , {y}] above={isAbove}")
	instance_deactivate_object(self);
	exit;
};

if (now_time >= now_hit) {
	if (!isJudge && hit_status == TYPE.NONE && type == 1) {
		if (is_real_note) {
			hit_status = judgeCalc(start_sec, now_hit, 0, _x_h, _y_h, type, true, true, true, has_hit_tint ? hit_tint : undefined);
			if (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT) then rpe_play_hitsound(sound, custom_fmod_sound, custom_hitsound_path);
		};
		isJudge = true;
		judgeRealTime = _now_seconds;
		if (hit_status == TYPE.BAD) {
			isBad = true;
			_bad_x = x;
			_bad_y = y;
			_bad_angle = image_angle;
		} else {
			instance_deactivate_object(self);
		};
	} else if (hit_status == TYPE.BAD && type == 1) {
		isBad = true;
		if (image_alpha <= 0) then instance_deactivate_object(self);
	} else if (hit_status != TYPE.NONE && isJudge) {
		instance_deactivate_object(self);
	};
};

if (isJudge && !isBad) {
	var fade = clamp(1 - ((_now_seconds - judgeRealTime) * 1000 / 160), 0, 1);
	image_alpha = alpha * fade;
};
