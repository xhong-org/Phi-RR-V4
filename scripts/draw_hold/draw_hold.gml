/// @function draw_hold(x, y, scalex, scaley, hold_body_scale, angle, subimg, colour, alpha, draw_head, attach_head, tail_trim, head_attach_scale)
/// @description Draws a Hold from its head reference point with sprite-origin joins.
/// @param {Real} x
/// @param {Real} y
/// @param {Real} scalex
/// @param {Real} scaley
/// @param {Real} hold_body_scale
/// @param {Real} angle
/// @param {Real} subimg
/// @param {Colour} colour
/// @param {Real} alpha
/// @param {Bool} draw_head
/// @param {Bool} attach_head Whether the body starts at the head's visible edge.
/// @param {Real} tail_trim Distance in screen pixels that the tail overlaps the body.
/// @param {Real} head_attach_scale Fraction of the head origin used for attachment.
function draw_hold(x, y, scalex, scaley, hold_body_scale, angle = 0, subimg = 0,
		colour = c_white, alpha = 1, draw_head = true, attach_head = draw_head,
		tail_trim = 0, head_attach_scale = 0.25) {
	static _head_attach = max(0, sprite_get_yoffset(note_hold_head));
	static _body_height = max(1, sprite_get_height(note_hold_body));

	var _xscale = real(scalex);
	var _yscale = abs(real(scaley));
	var _body_scale = max(0, real(hold_body_scale));
	var _body_length = _body_height * _body_scale;
	var _alpha = clamp(real(alpha), 0, 1);
	if (_alpha <= 0 || _xscale == 0) then return;

	var _axis_x = -dsin(angle);
	var _axis_y = -dcos(angle);
	var _head_distance = 0;
	if (attach_head) {
		_head_distance = (_head_attach * 1.35) * _yscale * max(0, real(head_attach_scale));
	};

	// The body scale is calculated from the complete sprite height. Keeping the
	// same origin convention for every frame is required by the highlight frame.
	var _body_origin_distance = _head_distance;
	var _tail_origin_distance = _head_distance + (_body_length) - max(0, real(tail_trim));

	var _body_x = x + _axis_x * _body_origin_distance;
	var _body_y = y + _axis_y * _body_origin_distance;
	var _tail_x = x + _axis_x * _tail_origin_distance;
	var _tail_y = y + _axis_y * _tail_origin_distance;

	draw_sprite_ext(note_hold_body, subimg, _body_x, _body_y,
		_xscale, _body_scale, angle, colour, _alpha);
	draw_sprite_ext(note_hold_end, subimg, _tail_x, _tail_y,
		_xscale, _yscale, angle, colour, _alpha);
	if (draw_head) {
		draw_sprite_ext(note_hold_head, subimg, x, y,
			_xscale, _yscale, angle, colour, _alpha);
	};
}
