///@desc 推进 RPE 音符时间、裁剪、位移和自动判定
if (!inition) then exit;
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then exit;
if (variable_global_exists("game") && is_struct(game) && game.paused) then exit;
// 判定线不在就停止绘制。
if (!instance_exists(_line_ref)) { canDraw = false; exit; };

// 绑定的判定线自带本地时钟，含 bpmfactor 和累计偏移。
_now_seconds = (variable_instance_exists(_line_ref, "line_sec") ? _line_ref.line_sec : 0);

_line_time = (variable_instance_exists(_line_ref, "line_time") ? _line_ref.line_time : 0);

// 判定窗口用秒，多 BPM 谱面才不会用错单位。
var late_ms = _is_hold ? 161 : ((type == 2 || type == 4) ? 160 : 201);
lateHitTime = late_ms * 0.001;
judgeTime = start_sec + hitTime2 * 0.001;

// 窗口缩放变了才刷新尺寸。
if (_last_global_scales != global_scales) {
	event_user(7);
	_last_global_scales = global_scales;
};

// Bad 淡出结束后停用。
if (isBad) {
	if (_now_seconds - judgeRealTime >= 1) then instance_deactivate_object(self);
	exit;
};

// 预加载窗口外按地板距离提前裁掉。
if (_preload_seconds > 0) {
	var sec_to_hit = start_sec - _now_seconds;
	if (sec_to_hit > _preload_seconds) {
		var line_floor_pre = real(_line_ref.__value[0]);
		// 判定线还没进入最远可见窗口时，远处音符不画。
		if (line_floor_pre + _max_visible_floor_distance < floorPosition
			&& line_floor_pre < maximum_visual_position - _max_visible_floor_distance) {
			canDraw = false;
			exit;
		};
	};
};

// 假音符即使未判定，过了结束时间也要清掉。
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

// 更新位置。
event_user(_step_user_count);

// 真音符走和官谱相同的自动判定。
if (!isFake) then event_user(_judge_user_count);
