/// @description Update Official Hold geometry using PCR floor semantics.
if(!_is_hold || !inition) then exit;

var line_floor = _line_ref.__value[0];
var position_floor_delta = (yOffset - line_floor);
var time_before = (_now_seconds < realHitTime);
var line_x = _line_ref.x;
var line_y = _line_ref.y;
	var local_x = xOffset * chart_view_width * 0.05625;
	var scale_y = chart_view_height * 0.6;
var rotation = _line_ref.image_angle;
var rotation_cos = _line_ref.__cos;
var rotation_sin = _line_ref.__sin;
var dir = (isAbove ? -1 : 1);
var axis_x = rotation_sin * dir;
var axis_y = rotation_cos * dir;
var base_x = line_x + local_x * rotation_cos;
var base_y = line_y - local_x * rotation_sin;

var hold_floor_length = (variable_instance_exists(id, "holdFloorLength") ? holdFloorLength : hold_time_length);
var head_cover_delta = (max_visible_position - line_floor);
var is_out = (!isHold) && (self.speed < 0 ? (head_cover_delta * self.speed > 0) : (head_cover_delta > 0));
var _skin_hold = skin_active() ? skin_hold_parts(hl) : undefined;
var _head_spr = note_hold_head;
var _compact = false;
if (is_struct(_skin_hold)) {
	if (sprite_exists(_skin_hold.head)) then _head_spr = _skin_hold.head;
	if (sprite_exists(_skin_hold.body)) then _hold_body_height = max(1, sprite_get_height(_skin_hold.body));
	_compact = bool(_skin_hold.compact);
};
var head_offset = (is_out && !_compact ? max(0, sprite_get_yoffset(_head_spr)) * image_yscale : 0);
var hold_units = hold_floor_length + (is_out ? 0 : position_floor_delta);
var hold_length = max(0, hold_units * scale_y - head_offset);
yscale = hold_length / max(1, _hold_body_height);

if (is_out) {
	var head_distance = position_floor_delta * scale_y;
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
var tail_cover_delta = (maximum_visual_length - line_floor);
var is_out_line;
if (time_before) {
	is_out_line = (self.speed < 0 ? (tail_cover_delta * self.speed >= -0.000001) : (line_floor <= maximum_visual_length));
} else {
	is_out_line = true;
};
canDraw = (is_out_line && hold_length > 0);
