if (line_progress <= 0 || state == PLAY_TRANSITION_STATE.PLAYING
	|| state == PLAY_TRANSITION_STATE.EXIT_DELAY
	|| state == PLAY_TRANSITION_STATE.SETTLEMENT) then exit;

var _old_colour = draw_get_colour();
var _old_alpha = draw_get_alpha();
draw_set_alpha(1);
var _view_left = variable_global_exists("chart_view_left") ? chart_view_left : 0;
var _view_width = variable_global_exists("chart_view_width") ? chart_view_width : room_width;
if (!is_real(_view_width) || _view_width <= 0) then _view_width = room_width;
var _cx = _view_left + _view_width * 0.5;
var _half_width = _view_width * 0.5 * clamp(line_progress, 0, 1);
var _line_col = chart_line_judge_blend();
draw_line_width_colour(_cx - _half_width, room_height * 0.5,
	_cx + _half_width, room_height * 0.5, max(5 * global_scales, 1), _line_col, _line_col);
draw_set_colour(_old_colour);
draw_set_alpha(_old_alpha);
