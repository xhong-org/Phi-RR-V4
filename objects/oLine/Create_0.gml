/// @description Cache immutable chart data used by the per-frame hot path.
depth = DEPTH.LINE;
sprite_index = self.image_id;
image_blend = chart_line_judge_blend();

_events = self.events;
delete(self.events);

_move_events = _events.judgeLineMoveEvents;
_rotate_events = _events.judgeLineRotateEvents;
_alpha_events = _events.judgeLineDisappearEvents;
_speed_events = _events.speedEvents;
_event_groups = [_move_events, _rotate_events, _alpha_events, _speed_events];
_event_lengths = [
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

event_user(1);

chart_force_event_init = false;
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then visible = false;

print($"[{self.line_id}] BPM: {_events.bpm}");
