/// @description Update hold RPE note (PCR-aligned head/body/tail)
if (!_is_hold || !inition) then exit;
if (!instance_exists(_line_ref)) { canDraw = false; exit; };

var line_floor = real(_line_ref.__value[0]);
var time_before = (_now_seconds < start_sec);
_position_floor_delta = floorPosition - line_floor;
_control_position_speed = speed * _position_floor_delta;

if (time_before) {
	// PCR samples controls with note speed, but moves a Hold head by floor delta.
	_note_position_speed = _position_floor_delta;
} else {
	_note_position_speed = 0;
	isHold = true;
};

// Hold head visibility and body pinning depend on chart time, not judgment state.
_is_out = time_before;
if (time_before) {
	var uncover = variable_instance_exists(_line_ref, "_uncover") ? bool(_line_ref._uncover) : false;
	var tail_floor_distance = speed * (endFloorPosition - line_floor);
	// Keep a crossing Hold visible while either endpoint remains on the visible side.
	_is_out_line = uncover || max(_note_position_speed, tail_floor_distance) >= -0.000001;
} else {
	_is_out_line = true;
};

var scene_w = room_width;
var scene_h = room_height;
var notes_w = scene_w * 0.05625;
var notes_h = scene_h * 0.6;
var posx = (xOffset / 75.375) * notes_w;
var posy = (yorigin * scene_h) + (_note_position_speed * notes_h);
posx *= rpe_sample_control("pos", _control_position_speed, 1);
var control_y = rpe_sample_control("y", _control_position_speed, 1);
posy *= control_y;
var control_size = rpe_sample_control("size", _control_position_speed, 1);
image_xscale = (global_scales / 6) * size * control_size;
var uniform_factor = bool(game.settings.noteUniformScale ?? false) ? size * control_size : 1;
image_yscale = (global_scales / 6) * uniform_factor;

var reversed = (isAbove ? -1 : 1);
var line_x = _line_ref.x;
var line_y = _line_ref.y;
var c = _line_ref.__cos;
var s = _line_ref.__sin;
_ox_v = s * reversed;
_oy_v = c * reversed;

_x_h = line_x + c * posx;
_y_h = line_y - s * posx;
_note_x = _x_h;
_note_y = _y_h;
x = _x_h + _ox_v * posy;
y = _y_h + _oy_v * posy;
_hx0 = x;
_hy0 = y;

_debug_text_x = x//_x_h + _ox_v * posy;
_debug_text_y = ((_y_h + (50 * (global_scales))) + _oy_v * posy);

var length_floor = hold_length_floor;
if (length_floor == 0) then length_floor = (endFloorPosition - floorPosition);
// velocity already includes BPMList and signed judge-line speed integration.
// Uniform mode applies the same vertical factor to the Hold body geometry.
var base_length = notes_h * speed * control_y * uniform_factor;

var head_offset = 0;
if (_is_out && (!compactHold)) {
	var head_yoff = sprite_get_yoffset(sprite_index);
	var head_bbox_top = sprite_get_bbox_top(sprite_index);
	var head_attach = max(1, head_yoff - head_bbox_top);
	head_attach = min(head_attach, max(1, head_yoff * 0.25));
	head_offset = max(0, head_attach * image_yscale - 1);
};

var hold_units = (time_before ? length_floor : endFloorPosition - line_floor);
var signed_hold_px = base_length * hold_units;
var hold_px = max(0, signed_hold_px - head_offset);
if (!variable_instance_exists(id, "_hold_body_height") || _hold_body_height <= 0) {
	_hold_body_height = max(1, sprite_get_height(note_hold_body));
};
if (!variable_instance_exists(id, "_hold_tail_height") || _hold_tail_height <= 0) {
	_hold_tail_height = max(1, sprite_get_height(note_hold_end));
};
yscale = hold_px / max(1, _hold_body_height);

var tail_trim = (compactHold ? image_yscale * (_hold_tail_height * 0.5) : 0);
var tail_offset = max(head_offset, head_offset + hold_px - tail_trim);
var body_ox = _ox_v;
var body_oy = _oy_v;
_hx1 = x + body_ox * head_offset;
_hy1 = y + body_oy * head_offset;
_hx2 = x + body_ox * tail_offset;
_hy2 = y + body_oy * tail_offset;
image_angle = _line_ref.image_angle + (isAbove ? 0 : 180);

var sWH = scene_w * 0.5;
var sHH = scene_h * 0.5;
var dx = x - sWH;
var dy = y - sHH;
var dyn_r = sWH * 1.2365 + sHH + abs(_note_position_speed) * notes_h;
outside = ((dx * dx + dy * dy) >= (dyn_r * dyn_r));
if (outside) {
	var dot = dx * (_x_h - sWH) + dy * (_y_h - sHH);
	if (dot <= 0) {
		canDraw = false;
		exit;
	};
};
if (!(_is_out_line && (hold_px > 0.5 || _is_out || _now_seconds < end_sec))) {
	canDraw = false;
	exit;
};
if (!rpe_note_apply_visibility()) then exit;
canDraw = true;
