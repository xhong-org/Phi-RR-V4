///@desc 创建：缓存每帧热路径要用的不变谱面数据
depth = DEPTH.LINE;
sprite_index = self.image_id;
image_blend = chart_line_judge_blend();

// 拆出四条事件流并记下长度，避免每帧再查结构。
_events = self.events;
delete(self.events);
// 只有收成播放谱后仍带缓动的线才走缓动。v1 和纯线性线保持原来的插值
ease_live = (_events[$ "simEase"] == true);

_move_events = _events.judgeLineMoveEvents;
_rotate_events = _events.judgeLineRotateEvents;
_alpha_events = _events.judgeLineDisappearEvents;
_speed_events = _events.speedEvents;
events_flat = false;
_move_pack = [];
_rotate_pack = [];
_alpha_pack = [];
_speed_pack = [];
// 后门关闭时继续用结构体。打开时热路径只读数组
if (official_array_pack_enabled()) {
	_move_pack = official_pack_move(_move_events);
	_rotate_pack = official_pack_axis(_rotate_events);
	_alpha_pack = official_pack_axis(_alpha_events);
	_speed_pack = official_pack_speed(_speed_events, (1 / (_events.bpm / 1.875)));
	events_flat = true;
};
_event_groups = [_move_events, _rotate_events, _alpha_events, _speed_events];
_event_lengths = events_flat ? [
	array_length(_move_pack) div OFF_EV_MOVE,
	array_length(_rotate_pack) div OFF_EV_AXIS,
	array_length(_alpha_pack) div OFF_EV_AXIS,
	array_length(_speed_pack) div OFF_EV_SPEED
] : [
	array_length(_move_events),
	array_length(_rotate_events),
	array_length(_alpha_events),
	array_length(_speed_events)
];

_counts = [0, 0, 0, 0];
_beat_per_second = (_events.bpm / 1.875);
_seconds_per_beat = (1 / _beat_per_second);
_last_event_time = 0;

__x = 0;
__y = 0;
__a = 0;
__r = 0;
__cos = 1;
__sin = 0;
__value = [0, 0];

// 用户事件 1 预计算速度事件的 floor。
event_user(1);

chart_force_event_init = false;
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then visible = false;

print($"[{self.line_id}] BPM: {_events.bpm}");
