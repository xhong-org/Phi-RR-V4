/// @description Draw the Phira-style chart aspect mask in room coordinates.
/// @param {real} room_w
/// @param {real} room_h
function draw_chart_mask(_room_w , _room_h){
	var _chart_w = min(_room_w, _room_h * (16 / 9));
	if (_chart_w >= _room_w) then exit;

	var _left = (_room_w - _chart_w) * 0.5;
	draw_set_colour(c_black);
	draw_set_alpha(1);
	draw_rectangle(0, 0, _left, _room_h, true);
	draw_rectangle(_left + _chart_w, 0, _room_w, _room_h, true);
};