/// @description Auto-judge hold RPE note
if (!_is_hold || !inition || isFake) then exit;

var now_time = _now_seconds;
var now_hit = judgeTime;
var bpm_use = game_1.Math.bpmAtAbsSec(_now_seconds);

if (now_time >= now_hit && !isMiss && notJudge && hit_status == TYPE.NONE) {
	if (is_real_note) {
		var _hold_xy = rpe_note_hit_effect_xy();
		hit_status = judgeCalc(start_sec, now_hit, 0, _hold_xy[0], _hold_xy[1], type, true, false, true, has_hit_tint ? hit_tint : undefined);
		if (hit_status == TYPE.MISS && !isMiss) {
			isMiss = true;
			judgeCalc(start_sec, now_hit, 0, _hold_xy[0], _hold_xy[1], type, true, true, true);
		} else {
			_bak_time = _now_seconds;
			rpe_play_hitsound(sound, custom_fmod_sound, custom_hitsound_path);
		};
	};
	notJudge = false;
	isHold = true;
	__first__ = true;
	judgeRealTime = _now_seconds;
};

if (now_time > start_sec + lateHitTime && !isMiss && notJudge) {
	if (is_real_note) {
		hit_status = judgeCalc(start_sec, now_time, 0, _hx0, _hy0, type, false, true, true);
	};
	notJudge = false;
	isMiss = true;
	__first__ = true;
	isHold = true;
};

if (now_time >= start_sec) {
	if (!isHold) then isHold = true;
	if (!__first__ && !notJudge) then __first__ = true;

	if (!notJudge && !isMiss && (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT)) {
		if (_now_seconds - _bak_time >= (60 / max(1, bpm_use)) / 2) {
			var _tick_xy = rpe_note_hit_effect_xy();
			if (variable_global_exists("_eff_c")) then _eff_c(_tick_xy[0], _tick_xy[1], has_hit_tint ? hit_tint : (hit_status == TYPE.PREFECT ? #ffeca0 : make_colour_rgb(162, 238, 255)));
			_bak_time = _now_seconds;
		};
	};

	if (now_time >= end_sec) {
		if (is_real_note) {
			hit_status = judgeCalc(start_sec, now_hit, 0, _hx0, _hy0, type, false, !isMiss, true);
		};
		instance_deactivate_object(self);
	};
};
