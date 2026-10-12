///@desc 推进官谱音符时间，并分发缩放、判定和位移
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then exit;
_now_seconds = game.__time[1];
_now_beat = (_now_seconds * _beat_per_second);

// 缩放变了才刷新贴图尺寸。
if(_last_global_scales != global_scales){
	event_user(7);
	_last_global_scales = global_scales;
};

// Bad 闪完一秒后停用。
if(isBad){
	if(_now_seconds - judgeRealTime >= 1) then instance_deactivate_object(self);
	exit;
};

if(!game.paused) then event_user(_judge_user_count);
if(!isBad) then event_user(_step_user_count);
