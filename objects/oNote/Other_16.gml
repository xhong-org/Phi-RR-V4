/// @description Judge a hold note using cached beat/time values.
var now_time = _now_beat,
	now_hit_time = judgeTime;

if (!chart_autoplay_active()) {
	if (now_time > self.time + lateHitTime && !isMiss && notJudge) {
		hit_status = (judgeCalc(self.time, now_time, self.bpm, _hx0, _hy0, self.type, false, true));
		notJudge = false;
		isMiss = true;
		isHold = true;
	};
	if (now_time >= self.time) {
		if (!isHold) {
			isHold = true;
			event_user(2);
		} else if (!notJudge && !isMiss && (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT) && chart_kb_hold_alive()) {
			if (_now_seconds - _bak_time >= (60 / self.bpm) / 2) {
				_eff_c(_hx0, _hy0, hit_status == TYPE.PREFECT ? #ffeca0 : make_colour_rgb(162, 238, 255));
				_bak_time = _now_seconds;
			};
		};
		if (now_time >= self.time + self.holdTime && !notJudge) {
			hit_status = (judgeCalc(self.time, now_hit_time, self.bpm, _hx0, _hy0, self.type, false, !isMiss));
			instance_deactivate_object(self);
		};
	};
	exit;
};

if(now_time >= now_hit_time && !isMiss && notJudge && hit_status == TYPE.NONE){
	event_user(2);
	hit_status = (judgeCalc(self.time, now_hit_time, self.bpm, _hx0, _hy0, self.type, true, false));
	if(hit_status == TYPE.MISS && !isMiss){
		isMiss = true;
		judgeCalc(self.time, now_hit_time, self.bpm, _hx0, _hy0, self.type, true, true);
	}else{
		_bak_time = _now_seconds;
		skin_play_note_hitsound();
	};
	notJudge = false;
};

if(now_time > self.time + lateHitTime && !isMiss && notJudge && !game.settings.enableAccJudgment){
	hit_status = (judgeCalc(self.time, now_time, self.bpm, _hx0, _hy0, self.type, false, false));
	notJudge = false;
};

if(now_time >= self.time){
	if(!isHold){
		isHold = true;
		event_user(2);
	}else if(!notJudge && !isMiss && (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT)){
		if(_now_seconds - _bak_time >= (60 / self.bpm) / 2){
			_eff_c(_hx0, _hy0, hit_status == TYPE.PREFECT ? #ffeca0 : make_colour_rgb(162, 238, 255));
			_bak_time = _now_seconds;
		};
	};

	if(now_time >= self.time + self.holdTime){
		hit_status = (judgeCalc(self.time, now_hit_time, self.bpm, _hx0, _hy0, self.type, false, !isMiss));
		instance_deactivate_object(self);
	};
};
