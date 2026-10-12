///@desc 更新官谱 Hold：头速为 1，身体按 bodySpeed 乘时长伸缩
if(!_is_hold || !inition) then exit;

var line_floor = _line_ref.__value[0];
var time_before = (_now_seconds < realHitTime);
var body_speed = variable_instance_exists(id, "bodySpeed") ? real(bodySpeed) : 1;
if (!is_finite(body_speed)) then body_speed = 1;
var hold_sec = hold_time_length;
// 速度为 0 或空 Hold 不画。
if (abs(body_speed) <= 0.0000001 || hold_sec <= 0) {
	canDraw = false;
	exit;
};
// 和 Tap 一样，判定线地板越过 maxVisiblePos 才隐藏。
if (time_before && line_floor > max_visible_position) {
	canDraw = false;
	exit;
};

var position_floor_delta = (yOffset - line_floor);
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

var full_px = body_speed * hold_sec * scale_y;
if (full_px < 0) then full_px = 0;
var remain_px = full_px;
var show_head = time_before;
// 击中后按已过时间缩短身体。
if (!time_before) {
	var gone = clamp((_now_seconds - realHitTime) / hold_sec, 0, 1);
	remain_px = full_px * (1 - gone);
};
var _skin_hold = skin_active() ? skin_hold_parts(hl) : undefined;
var _head_spr = note_hold_head;
var _compact = false;
if (is_struct(_skin_hold)) {
	if (sprite_exists(_skin_hold.head)) then _head_spr = _skin_hold.head;
	if (sprite_exists(_skin_hold.body)) then _hold_body_height = max(1, sprite_get_height(_skin_hold.body));
	_compact = bool(_skin_hold.compact);
};
var head_offset = 0;
if (show_head && !_compact) {
	head_offset = max(0, sprite_get_yoffset(_head_spr)) * image_yscale;
	if (head_offset > remain_px) then head_offset = remain_px;
};
var hold_length = max(0, remain_px - head_offset);
yscale = hold_length / max(1, _hold_body_height);

if (show_head) {
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
	_hx2 = _hx1;
	_hy2 = _hy1;
};

image_angle = (-180 * (!isAbove) + rotation);
canDraw = (show_head || hold_length > 0);
if (isMiss) then image_alpha = 0.45;
