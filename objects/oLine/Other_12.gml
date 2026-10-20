///@desc 用户事件 2：求值四条已缓存的事件流，不每帧分配数组
if (events_flat) {
	official_line_eval_flat();
	exit;
};
var now_time = (game.__time[1] * _beat_per_second),
	next_x = __x,
	next_y = __y,
	next_alpha = __a,
	next_rotation = __r;

// 位移、透明度、旋转各自按当前事件插值。带缓动的线用 RPE 缓动号折进度
if(_event_lengths[0] > 0){
	var move_event = (_move_events[_counts[0]]);
	var move_progress = (move_event.startTime == move_event.endTime ? 1 : clamp((now_time - move_event.startTime) / (move_event.endTime - move_event.startTime), 0, 1));
	var move_x = move_progress;
	var move_y = move_progress;
	if (ease_live) {
		var ease_x = move_event[$ "easeType"];
		var ease_y = move_event[$ "easeType2"];
		if ((is_real(ease_x) && ease_x > 1) || is_real(move_event[$ "easeLeft"])) then move_x = official_sim_progress(move_event, move_progress, 0);
		if ((is_real(ease_y) && ease_y > 1) || is_real(move_event[$ "easeLeft2"])) then move_y = official_sim_progress(move_event, move_progress, 1);
	};
	next_x = (move_event.start == move_event[$ "end"] ? move_event[$ "end"] : lerp(move_event.start, move_event[$ "end"], move_x));
	next_y = (move_event.start2 == move_event[$ "end2"] ? move_event[$ "end2"] : lerp(move_event.start2, move_event[$ "end2"], move_y));
};

if(_event_lengths[2] > 0){
	var alpha_event = (_alpha_events[_counts[2]]);
	var alpha_progress = (alpha_event.startTime == alpha_event.endTime ? 1 : clamp((now_time - alpha_event.startTime) / (alpha_event.endTime - alpha_event.startTime), 0, 1));
	if (ease_live) {
		var ease_a = alpha_event[$ "easeType"];
		if ((is_real(ease_a) && ease_a > 1) || is_real(alpha_event[$ "easeLeft"])) then alpha_progress = official_sim_progress(alpha_event, alpha_progress, 0);
	};
	next_alpha = (alpha_event.start == alpha_event[$ "end"] ? alpha_event[$ "end"] : lerp(alpha_event.start, alpha_event[$ "end"], alpha_progress));
};

if(_event_lengths[1] > 0){
	var rotate_event = (_rotate_events[_counts[1]]);
	var rotate_progress = (rotate_event.startTime == rotate_event.endTime ? 1 : clamp((now_time - rotate_event.startTime) / (rotate_event.endTime - rotate_event.startTime), 0, 1));
	if (ease_live) {
		var ease_r = rotate_event[$ "easeType"];
		if ((is_real(ease_r) && ease_r > 1) || is_real(rotate_event[$ "easeLeft"])) then rotate_progress = official_sim_progress(rotate_event, rotate_progress, 0);
	};
	next_rotation = (rotate_event.start == rotate_event[$ "end"] ? rotate_event[$ "end"] : lerp(rotate_event.start, rotate_event[$ "end"], rotate_progress));
};

if(_event_lengths[3] > 0){
	// floorPosition 是该事件起点的 float32 基准。开始前用下一条向前延伸。
	// 超过最后一条的结束时间后，沿用最后一个值。
	var speed_event = (_speed_events[_counts[3]]);
	__value[0] = ((game.__time[1] - speed_event.startTime * _seconds_per_beat) * speed_event.value + __value[1]);
};

// NaN 不写回，避免坏事件把线坐标打飞。
if(!is_nan(next_x)) then __x = next_x;
if(!is_nan(next_y)) then __y = next_y;
if(!is_nan(next_alpha)) then __a = next_alpha;
if(!is_nan(next_rotation)) then __r = next_rotation;

// 原先的缩放式子化简后就是这两个乘积。
x = (chart_view_left + chart_view_width * __x);
y = (chart_view_height * (1 - __y));
image_alpha = __a;
image_angle = __r;
__cos = dcos(__r);
__sin = dsin(__r);
