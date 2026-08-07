/// @description Evaluate the four cached event streams without per-frame arrays.
var now_time = (game.__time[1] * _beat_per_second),
	next_x = __x,
	next_y = __y,
	next_alpha = __a,
	next_rotation = __r;

if(_event_lengths[0] > 0){
	var move_event = (_move_events[_counts[0]]);
	var move_progress = (move_event.startTime == move_event.endTime ? 1 : clamp((now_time - move_event.startTime) / (move_event.endTime - move_event.startTime), 0, 1));
	next_x = (move_event.start == move_event[$ "end"] ? move_event[$ "end"] : lerp(move_event.start, move_event[$ "end"], move_progress));
	next_y = (move_event.start2 == move_event[$ "end2"] ? move_event[$ "end2"] : lerp(move_event.start2, move_event[$ "end2"], move_progress));
};

if(_event_lengths[2] > 0){
	var alpha_event = (_alpha_events[_counts[2]]);
	var alpha_progress = (alpha_event.startTime == alpha_event.endTime ? 1 : clamp((now_time - alpha_event.startTime) / (alpha_event.endTime - alpha_event.startTime), 0, 1));
	next_alpha = (alpha_event.start == alpha_event[$ "end"] ? alpha_event[$ "end"] : lerp(alpha_event.start, alpha_event[$ "end"], alpha_progress));
};

if(_event_lengths[1] > 0){
	var rotate_event = (_rotate_events[_counts[1]]);
	var rotate_progress = (rotate_event.startTime == rotate_event.endTime ? 1 : clamp((now_time - rotate_event.startTime) / (rotate_event.endTime - rotate_event.startTime), 0, 1));
	next_rotation = (rotate_event.start == rotate_event[$ "end"] ? rotate_event[$ "end"] : lerp(rotate_event.start, rotate_event[$ "end"], rotate_progress));
};

if(_event_lengths[3] > 0 && now_time >= _speed_events[0].startTime){
	var speed_event = (_speed_events[_counts[3]]);
	__value[0] = ((game.__time[1] - speed_event.startTime * _seconds_per_beat) * speed_event.value + __value[1]);
};

if(!is_nan(next_x)) then __x = next_x;
if(!is_nan(next_y)) then __y = next_y;
if(!is_nan(next_alpha)) then __a = next_alpha;
if(!is_nan(next_rotation)) then __r = next_rotation;

// The previous scale expression algebraically reduced to these two products.
x = (room_width * __x);
y = (room_height * (1 - __y));
image_alpha = __a;
image_angle = __r;
__cos = dcos(__r);
__sin = dsin(__r);
