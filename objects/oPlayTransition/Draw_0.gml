if (line_progress <= 0 || state == PLAY_TRANSITION_STATE.PLAYING
	|| state == PLAY_TRANSITION_STATE.EXIT_DELAY) then exit;

var _old_colour = draw_get_colour();
var _old_alpha = draw_get_alpha();
draw_set_colour(c_white);
draw_set_alpha(1);
var _half_width = room_width * 0.5 * clamp(line_progress, 0, 1);
draw_line_width(room_width * 0.5 - _half_width, room_height * 0.5,
	room_width * 0.5 + _half_width, room_height * 0.5, max(5 * global_scales , 1));
draw_set_colour(_old_colour);
draw_set_alpha(_old_alpha);
