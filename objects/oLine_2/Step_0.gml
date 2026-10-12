///@desc 步进：求值归一化后的 PEC 事件和速度 floor
// 加载动画或暂停时不推进，除非强制初始化。
if (variable_global_exists("loading_animation_active") && global.loading_animation_active
	&& !chart_force_event_init) then exit;
if (game.paused && !chart_force_event_init) then exit;
line_sec = game.__time[1] - game_2.chart.offsetSeconds;
var current_scale = (variable_global_exists("global_scales") ? global_scales : 1);
// 缩放或视口变了才重算精灵缩放。
if (current_scale != _last_scale || room_height != _last_room_height
	|| chart_view_width != _last_view_width) {
	if (image_id == line) {
		image_xscale = 0.9204 * current_scale;
		image_yscale = 0.52 * current_scale;
	} else {
		var _csv_scale = chart_line_csv_sprite_scale(chart_line_override(line_id), image_id);
		image_xscale = _csv_scale[0];
		image_yscale = _csv_scale[1];
	};
	_last_scale = current_scale;
	_last_room_height = room_height;
	_last_view_width = chart_view_width;
};
image_blend = chart_line_judge_blend();
// 时间回退时游标和当前值全部归零重放。
if (line_sec < _last_line_sec) {
	_move_index = 0; _alpha_index = 0; _rotate_index = 0; _speed_index = 0;
	_move_x = 0; _move_y = 0; _alpha_value = 1; _rotate_value = 0;
};
_last_line_sec = line_sec;

// 吃掉已经结束的位移，再对当前这一条做缓动。
while (_move_index < _move_count && line_sec >= _move_events[_move_index].endSec) {
	_move_x = _move_events[_move_index].endX;
	_move_y = _move_events[_move_index].endY;
	_move_index++;
};
if (_move_index < _move_count && line_sec >= _move_events[_move_index].startSec) {
	var move_event = _move_events[_move_index];
	// 瞬时事件直接取终点。
	if (move_event.instant) {
		_move_x = move_event.endX;
		_move_y = move_event.endY;
	}
	else {
		_move_x = tween_execute(line_sec, move_event.startSec, move_event.endSec, move_event.startX, move_event.endX, move_event.easing);
		_move_y = tween_execute(line_sec, move_event.startSec, move_event.endSec, move_event.startY, move_event.endY, move_event.easing);
	};
};

// 透明度：先落到已结束事件的终点，再插值当前事件。
while (_alpha_index < _alpha_count && line_sec >= _alpha_events[_alpha_index].endSec) {
	_alpha_value = _alpha_events[_alpha_index][$ "end"];
	_alpha_index++;
};
if (_alpha_index < _alpha_count && line_sec >= _alpha_events[_alpha_index].startSec) {
	var alpha_event = _alpha_events[_alpha_index];
	_alpha_value = (alpha_event.instant ? alpha_event[$ "end"] : tween_execute(line_sec, alpha_event.startSec, alpha_event.endSec, alpha_event.start, alpha_event[$ "end"], alpha_event.easing));
};

// 旋转同样先消费已结束事件。
while (_rotate_index < _rotate_count && line_sec >= _rotate_events[_rotate_index].endSec) {
	_rotate_value = _rotate_events[_rotate_index][$ "end"];
	_rotate_index++;
};
if (_rotate_index < _rotate_count && line_sec >= _rotate_events[_rotate_index].startSec) {
	var rotate_event = _rotate_events[_rotate_index];
	_rotate_value = (rotate_event.instant ? rotate_event[$ "end"] : tween_execute(line_sec, rotate_event.startSec, rotate_event.endSec, rotate_event.start, rotate_event[$ "end"], rotate_event.easing));
};

floor_position = pec_floor_at_sec(_speed_events, line_sec);

x = chart_view_left + chart_view_width * _move_x;
y = chart_view_height * _move_y;
_alpha_raw = _alpha_value * 255;
image_alpha = clamp(_alpha_value, 0, 1);
image_angle = _rotate_value;
// 角度没变就不重算正余弦。
if (image_angle != _last_angle) {
	__cos = dcos(image_angle);
	__sin = dsin(image_angle);
	_last_angle = image_angle;
};
