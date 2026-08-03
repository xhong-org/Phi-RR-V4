/// @description Update non-hold RPE note position (PCR-aligned)
if (_is_hold || !inition) then exit;
if (!instance_exists(_line_ref)) { canDraw = false; exit; };

var line_floor = real(_line_ref.__value[0]);
_position_floor_delta = floorPosition - line_floor;
_note_position_speed = speed * _position_floor_delta;
_control_position_speed = _note_position_speed;

var notes_w = room_width * 0.05625;
var notes_h = room_height * 0.6;
var posx = (xOffset / 75.375) * notes_w;
if (variable_instance_exists(_line_ref, "__incline_sin")) {
	var incline_y = _note_position_speed + (2 * yOffset / 900 * speed);
	posx *= 1 - real(_line_ref.__incline_sin) * incline_y * 1.25;
};
var posy = (yorigin * room_height) + (_note_position_speed * notes_h);
posx *= rpe_sample_control("pos", _note_position_speed, 1);
posy *= rpe_sample_control("y", _note_position_speed, 1);
var control_size = rpe_sample_control("size", _note_position_speed, 1);
image_xscale = (global_scales / 6) * size * control_size;
var uniform_scale = bool(game.settings.noteUniformScale ?? false);
image_yscale = uniform_scale ? image_xscale : (global_scales / 6);

var reversed = (isAbove ? -1 : 1);
var c = _line_ref.__cos;
var s = _line_ref.__sin;
_ox_v = s * reversed;
_oy_v = c * reversed;

_x_h = _line_ref.x + c * posx;
_y_h = _line_ref.y - s * posx;
_note_x = _x_h;
_note_y = _y_h;

x = _x_h + _ox_v * posy;
y = _y_h + _oy_v * posy;

// Debug
_debug_text_x = x//_x_h + _ox_v * posy;
_debug_text_y = ((_y_h + (50 * (global_scales))) + _oy_v * posy);

image_angle = _line_ref.image_angle + (isAbove ? 0 : 180);

var uncover = variable_instance_exists(_line_ref, "_uncover") ? bool(_line_ref._uncover) : false;
if (_now_seconds < start_sec) {
	// isCover masks notes that are fully behind the judge line, using signed distance.
	_is_out_line = uncover || _note_position_speed >= -0.000001;
} else {
	_is_out_line = true;
};

var sWH = room_width * 0.5;
var sHH = room_height * 0.5;
var dx = x - sWH;
var dy = y - sHH;
var radius = sWH * 1.2365 + sHH;
outside = ((dx * dx + dy * dy) >= (radius * radius));

if (isJudge || isBad) {
	canDraw = true;
	if (!isBad) then image_alpha = alpha;
	exit;
};
if (outside) {
	canDraw = false;
	exit;
};
if (!rpe_note_apply_visibility()) then exit;
canDraw = true;
