///@desc 更新非 Hold 官谱音符的位置和可见性
if(_is_hold || !inition) then exit;

var line_floor = (_line_ref.__value[0]),
	floor_delta = (self.isAbove ? line_floor - self.yOffset : self.yOffset - line_floor);

var line_x = (_line_ref.x),
	line_y = (_line_ref.y),
	local_x = (self.xOffset * chart_view_width * 0.05625),
	local_y = (floor_delta * self.speed * chart_view_height * 0.6),
	rotation = (_line_ref.image_angle),
	rotation_cos = (_line_ref.__cos),
	rotation_sin = (_line_ref.__sin);

// 未旋转坐标留给判定和特效定位。
_note_x = (line_x + local_x);
_note_y = (line_y + local_y);

x = (line_x + local_x * rotation_cos + local_y * rotation_sin);
y = (line_y - local_x * rotation_sin + local_y * rotation_cos);
image_angle = rotation;

// 判定线地板还没越过 maxVisiblePos 就继续画，过线后才藏。
var is_out_line = true;
if (_now_seconds < realHitTime) then is_out_line = (line_floor <= max_visible_position);
canDraw = is_out_line;
