/// @description Skip distant notes, then update only the active working set.
_now_seconds = game.__time[1];
_now_beat = (_now_seconds * _beat_per_second);

if(_preload_seconds > 0 && realHitTime - _now_seconds > _preload_seconds){
	var floor_distance = (abs(_line_ref.__value[0] - self.yOffset) * abs(self.speed));
	if(floor_distance > _max_visible_floor_distance){
		canDraw = false;
		exit;
	};
};

if(_last_global_scales != global_scales){
	event_user(7);
	_last_global_scales = global_scales;
};

if(isBad){
	if(_now_seconds - judgeRealTime >= 1) then instance_deactivate_object(self);
	exit;
};

if(!game.paused) then event_user(_judge_user_count);
if(!isBad) then event_user(_step_user_count);
