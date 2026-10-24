///@desc 用缓存节拍判定官谱 Hold，并按节拍刷新尾迹
var now_time = _now_beat,
	now_hit_time = judgeTime;

// 手动判定统一在渲染器 Step End 处理，先接收本帧输入再决定超时。
if (!chart_autoplay_active()) then exit;

// 自动播放在击中时刻判定 Hold 头。
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
	// 到开始时间后钉在判定线上，并按半拍刷新尾迹。
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
