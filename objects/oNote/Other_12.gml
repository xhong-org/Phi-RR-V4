/// @description Update Official Hold geometry using PCR floor semantics.
if(!_is_hold || !inition) then exit;

var line_floor = _line_ref.__value[0];
var floor_delta = (isAbove ? line_floor - yOffset : yOffset - line_floor);
var passed_line = (!isHold && line_floor > maximum_visual_length);
var line_x = _line_ref.x;
var line_y = _line_ref.y;
var local_x = xOffset * room_width * 0.05625;
var scale_y = room_height * 0.6;
var rotation = _line_ref.image_angle;
var rotation_cos = _line_ref.__cos;
var rotation_sin = _line_ref.__sin;
var dir = (isAbove ? -1 : 1);
var axis_x = rotation_sin * dir;
var axis_y = rotation_cos * dir;
var base_x = line_x + local_x * rotation_cos;
var base_y = line_y - local_x * rotation_sin;

var hold_floor_length = (variable_instance_exists(id, "holdFloorLength") ? holdFloorLength : hold_time_length);
var is_out = (!isHold && max_visible_position > line_floor);
var head_offset = (is_out ? max(0, sprite_get_yoffset(note_hold_head)) * image_yscale : 0);
var hold_units = hold_floor_length + (is_out ? 0 : yOffset - line_floor);
var hold_length = max(0, hold_units * scale_y - head_offset);
yscale = hold_length / max(1, _hold_body_height);

if (is_out) {
	var head_distance = abs(yOffset - line_floor) * scale_y;
	var head_x = base_x + axis_x * head_distance;
	var head_y = base_y + axis_y * head_distance;
	_hx0 = head_x;
	_hy0 = head_y;
	_hx1 = head_x + axis_x * head_offset;
	_hy1 = head_y + axis_y * head_offset;
	_hx2 = head_x + axis_x * (head_offset + hold_length);
	_hy2 = head_y + axis_y * (head_offset + hold_length);
} else {
	_hx0 = base_x;
	_hy0 = base_y;
	_hx1 = base_x + axis_x * hold_length;
	_hy1 = base_y + axis_y * hold_length;
};

image_angle = (-180 * (!isAbove) + rotation);
canDraw = (!passed_line && hold_length > 0);
