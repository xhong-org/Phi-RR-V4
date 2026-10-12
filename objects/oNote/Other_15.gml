///@desc 用缓存节拍判定非 Hold 官谱音符
var now_time = _now_beat,
	now_hit_time = judgeTime;

// 非自动播放只处理超时 Miss。
if (!chart_autoplay_active()) {
	if (now_time > self.time + lateHitTime && !isBad && !isJudge) {
		judgeCalc(self.time, now_time, self.bpm, 0, 0, self.type, false);
		instance_deactivate_object(self);
	};
	exit;
};

// 关闭准度判定时，过窗口直接记 Miss。
if(now_time > self.time + lateHitTime && !isBad && !game.settings.enableAccJudgment){
	judgeCalc(self.time, now_time, self.bpm, 0, 0, self.type, false);
	instance_deactivate_object(self);
	exit;
};

// Drag 和 Flick 到点即判，不等 Tap 的击中时刻。
if ((self.type == 2 || self.type == 4) && !isJudge && now_time >= self.time
	&& now_hit_time >= self.time && now_hit_time <= self.time + lateHitTime) {
	event_user(1);
	var line_x = (_line_ref.x),
		local_x = (_note_x - line_x),
		hit_x = (line_x + local_x * _line_ref.__cos),
		hit_y = (_line_ref.y - local_x * _line_ref.__sin);
	hit_status = (judgeCalc(self.time, now_hit_time, self.bpm, hit_x, hit_y, self.type));
	skin_play_note_hitsound();
	isJudge = true;
};

if(now_time >= now_hit_time){
	if(!isJudge && hit_status == TYPE.NONE && self.type == 1){
		event_user(1);
		var line_x = (_line_ref.x),
			local_x = (_note_x - line_x),
			hit_x = (line_x + local_x * _line_ref.__cos),
			hit_y = (_line_ref.y - local_x * _line_ref.__sin);
		hit_status = (judgeCalc(self.time, now_hit_time, self.bpm, hit_x, hit_y, self.type));
		if(hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT) then skin_play_note_hitsound();
		isJudge = true;
	}else if(hit_status == TYPE.BAD && self.type == 1){
		if(!isBad){
			_bad_x = _note_x;
			_bad_y = _note_y;
			_bad_angle = image_angle;
		};
		isBad = true;
		if(image_alpha <= 0) then instance_deactivate_object(self);
	}else if(hit_status != TYPE.NONE && isJudge){
		instance_deactivate_object(self);
	};
};
