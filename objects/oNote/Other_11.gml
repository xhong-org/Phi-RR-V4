/// @description Update a non-hold note without temporary arrays.
if(_is_hold || !inition) then exit;

var line_floor = (_line_ref.__value[0]),
	floor_delta = (self.isAbove ? line_floor - self.yOffset : self.yOffset - line_floor),
	_c_y = (!self.isAbove ? floor_delta < -0.001 : floor_delta > 0.001);

var line_x = (_line_ref.x),
	line_y = (_line_ref.y),
	local_x = (self.xOffset * room_width * 0.05625),
	local_y = (floor_delta * self.speed * room_height * 0.6),
	rotation = (_line_ref.image_angle),
	rotation_cos = (_line_ref.__cos),
	rotation_sin = (_line_ref.__sin);

// Keep the unrotated coordinates for the judgement/effect position.
_note_x = (line_x + local_x);
_note_y = (line_y + local_y);

x = (line_x + local_x * rotation_cos + local_y * rotation_sin);
y = (line_y - local_x * rotation_sin + local_y * rotation_cos);
image_angle = rotation;

canDraw = (!_c_y);
