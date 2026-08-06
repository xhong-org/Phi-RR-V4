/// @description Evaluate normalized PEC events and speed floor.
if (game.paused) then exit;
line_sec = game.__time[1] - game_2.chart.offsetSeconds;
var current_scale = (variable_global_exists("global_scales") ? global_scales : 1);
image_xscale = (image_id == line ? 0.9204 : line_csv_scale * room_height / 1080 * 1.35) * current_scale;
image_yscale = (image_id == line ? 0.52 : line_csv_scale * room_height / 1080 * 1.35) * current_scale;
image_blend = c_white;
if (game.settings.enableLineJudge) {
	image_blend = #ffeca0;
	if (phi_state_list.good > 0) then image_blend = make_colour_rgb(162, 238, 255);
	if (phi_state_list.bad + phi_state_list.miss > 0) then image_blend = c_white;
};
if (line_sec < _last_line_sec) {
	_move_index = 0; _alpha_index = 0; _rotate_index = 0; _speed_index = 0;
	_move_value = [0, 0]; _alpha_value = 0; _rotate_value = 0;
};
_last_line_sec = line_sec;

var move_events = events.moveEvents;
while (_move_index < array_length(move_events) && line_sec >= move_events[_move_index].endSec) {
	_move_value = move_events[_move_index][$ "end"];
	_move_index++;
};
if (_move_index < array_length(move_events) && line_sec >= move_events[_move_index].startSec) {
	var move_event = move_events[_move_index];
	if (move_event.startSec == move_event.endSec) _move_value = move_event[$ "end"];
	else {
		_move_value = [
			tween_execute(line_sec, move_event.startSec, move_event.endSec, move_event.start[0], move_event[$ "end"][0], move_event.easing),
			tween_execute(line_sec, move_event.startSec, move_event.endSec, move_event.start[1], move_event[$ "end"][1], move_event.easing)
		];
	};
};

var alpha_events = events.alphaEvents;
while (_alpha_index < array_length(alpha_events) && line_sec >= alpha_events[_alpha_index].endSec) {
	_alpha_value = alpha_events[_alpha_index][$ "end"];
	_alpha_index++;
};
if (_alpha_index < array_length(alpha_events) && line_sec >= alpha_events[_alpha_index].startSec) {
	var alpha_event = alpha_events[_alpha_index];
	_alpha_value = (alpha_event.startSec == alpha_event.endSec ? alpha_event[$ "end"] : tween_execute(line_sec, alpha_event.startSec, alpha_event.endSec, alpha_event.start, alpha_event[$ "end"], alpha_event.easing));
};

var rotate_events = events.rotateEvents;
while (_rotate_index < array_length(rotate_events) && line_sec >= rotate_events[_rotate_index].endSec) {
	_rotate_value = rotate_events[_rotate_index][$ "end"];
	_rotate_index++;
};
if (_rotate_index < array_length(rotate_events) && line_sec >= rotate_events[_rotate_index].startSec) {
	var rotate_event = rotate_events[_rotate_index];
	_rotate_value = (rotate_event.startSec == rotate_event.endSec ? rotate_event[$ "end"] : tween_execute(line_sec, rotate_event.startSec, rotate_event.endSec, rotate_event.start, rotate_event[$ "end"], rotate_event.easing));
};

var speed_events = events.speedEvents;
while (_speed_index + 1 < array_length(speed_events) && speed_events[_speed_index + 1].startSec <= line_sec) _speed_index++;
if (array_length(speed_events) > 0 && line_sec >= speed_events[0].startSec) {
	var speed_event = speed_events[_speed_index];
	floor_position = speed_event.floor + (line_sec-speed_event.startSec)*speed_event.value;
} else floor_position = 0;

x = room_width * _move_value[0];
y = room_height * _move_value[1];
image_alpha = clamp(_alpha_value, 0, 1);
image_angle = _rotate_value;
__cos = dcos(image_angle);
__sin = dsin(image_angle);
