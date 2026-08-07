/// @description Evaluate normalized PEC events and speed floor.
if (game.paused) then exit;
line_sec = game.__time[1] - game_2.chart.offsetSeconds;
var current_scale = (variable_global_exists("global_scales") ? global_scales : 1);
if (current_scale != _last_scale || room_height != _last_room_height) {
	if (image_id == line) {
		image_xscale = 0.9204 * current_scale;
		image_yscale = 0.52 * current_scale;
	} else {
		var custom_scale = _custom_scale_factor * room_height * current_scale;
		image_xscale = custom_scale;
		image_yscale = custom_scale;
	};
	_last_scale = current_scale;
	_last_room_height = room_height;
};
image_blend = c_white;
if (game.settings.enableLineJudge) {
	image_blend = #ffeca0;
	if (phi_state_list.good > 0) then image_blend = make_colour_rgb(162, 238, 255);
	if (phi_state_list.bad + phi_state_list.miss > 0) then image_blend = c_white;
};
if (line_sec < _last_line_sec) {
	_move_index = 0; _alpha_index = 0; _rotate_index = 0; _speed_index = 0;
	_move_x = 0; _move_y = 0; _alpha_value = 0; _rotate_value = 0;
};
_last_line_sec = line_sec;

while (_move_index < _move_count && line_sec >= _move_events[_move_index].endSec) {
	_move_x = _move_events[_move_index].endX;
	_move_y = _move_events[_move_index].endY;
	_move_index++;
};
if (_move_index < _move_count && line_sec >= _move_events[_move_index].startSec) {
	var move_event = _move_events[_move_index];
	if (move_event.instant) {
		_move_x = move_event.endX;
		_move_y = move_event.endY;
	}
	else {
		_move_x = tween_execute(line_sec, move_event.startSec, move_event.endSec, move_event.startX, move_event.endX, move_event.easing);
		_move_y = tween_execute(line_sec, move_event.startSec, move_event.endSec, move_event.startY, move_event.endY, move_event.easing);
	};
};

while (_alpha_index < _alpha_count && line_sec >= _alpha_events[_alpha_index].endSec) {
	_alpha_value = _alpha_events[_alpha_index][$ "end"];
	_alpha_index++;
};
if (_alpha_index < _alpha_count && line_sec >= _alpha_events[_alpha_index].startSec) {
	var alpha_event = _alpha_events[_alpha_index];
	_alpha_value = (alpha_event.instant ? alpha_event[$ "end"] : tween_execute(line_sec, alpha_event.startSec, alpha_event.endSec, alpha_event.start, alpha_event[$ "end"], alpha_event.easing));
};

while (_rotate_index < _rotate_count && line_sec >= _rotate_events[_rotate_index].endSec) {
	_rotate_value = _rotate_events[_rotate_index][$ "end"];
	_rotate_index++;
};
if (_rotate_index < _rotate_count && line_sec >= _rotate_events[_rotate_index].startSec) {
	var rotate_event = _rotate_events[_rotate_index];
	_rotate_value = (rotate_event.instant ? rotate_event[$ "end"] : tween_execute(line_sec, rotate_event.startSec, rotate_event.endSec, rotate_event.start, rotate_event[$ "end"], rotate_event.easing));
};

while (_speed_index + 1 < _speed_count && _speed_events[_speed_index + 1].startSec <= line_sec) _speed_index++;
if (_speed_count > 0 && line_sec >= _speed_events[0].startSec) {
	var speed_event = _speed_events[_speed_index];
	floor_position = speed_event.floor + (line_sec-speed_event.startSec)*speed_event.value;
} else floor_position = 0;

x = room_width * _move_x;
y = room_height * _move_y;
image_alpha = clamp(_alpha_value, 0, 1);
image_angle = _rotate_value;
if (image_angle != _last_angle) {
	__cos = dcos(image_angle);
	__sin = dsin(image_angle);
	_last_angle = image_angle;
};
