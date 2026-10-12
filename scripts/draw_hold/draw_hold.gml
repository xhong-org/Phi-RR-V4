///@desc 从头部参考点绘制长条，并按精灵原点衔接
///@param {Real} x 头部参考点横坐标
///@param {Real} y 头部参考点纵坐标
///@param {Real} scalex 横向缩放
///@param {Real} scaley 纵向缩放
///@param {Real} hold_body_scale 身体长度缩放
///@param {Real} angle 旋转角度
///@param {Real} subimg 子图帧
///@param {Real} colour 混合颜色
///@param {Real} alpha 透明度
///@param {Bool} draw_head 是否绘制头部
///@param {Bool} attach_head 身体是否从头部可见边缘开始
///@param {Real} tail_trim 尾部叠进身体的屏幕像素
///@param {Real} head_attach_scale 头部原点用于衔接的比例
///@param {Any} head_spr 头部精灵，无效时用默认
///@param {Any} body_spr 身体精灵，无效时用默认
///@param {Any} end_spr 尾部精灵，无效时用默认
///@returns {Undefined} 无
function draw_hold(x, y, scalex, scaley, hold_body_scale, angle = 0, subimg = 0,
		colour = c_white, alpha = 1, draw_head = true, attach_head = draw_head,
		tail_trim = 0, head_attach_scale = 0.25, head_spr = -1, body_spr = -1, end_spr = -1) {
	if (!sprite_exists(head_spr)) then head_spr = note_hold_head;
	if (!sprite_exists(body_spr)) then body_spr = note_hold_body;
	if (!sprite_exists(end_spr)) then end_spr = note_hold_end;
	var _head_attach = max(0, sprite_get_yoffset(head_spr));
	var _body_height = max(1, sprite_get_height(body_spr));
	var _frame = sprite_exists(head_spr) ? clamp(real(subimg), 0, max(0, sprite_get_number(head_spr) - 1)) : 0;

	var _xscale = real(scalex);
	var _yscale = abs(real(scaley));
	var _body_scale = max(0, real(hold_body_scale));
	var _body_length = _body_height * _body_scale;
	var _alpha = clamp(real(alpha), 0, 1);
	if (_alpha <= 0 || _xscale == 0) then return;

	// 沿角度的反方向把身体和尾部从头部排开
	var _axis_x = -dsin(angle);
	var _axis_y = -dcos(angle);
	var _head_distance = 0;
	if (attach_head) {
		_head_distance = (_head_attach * 1.35) * _yscale * max(0, real(head_attach_scale));
	};

	var _body_origin_distance = _head_distance;
	var _tail_origin_distance = _head_distance + (_body_length) - max(0, real(tail_trim));

	var _body_x = x + _axis_x * _body_origin_distance;
	var _body_y = y + _axis_y * _body_origin_distance;
	var _tail_x = x + _axis_x * _tail_origin_distance;
	var _tail_y = y + _axis_y * _tail_origin_distance;

	draw_sprite_ext(body_spr, _frame, _body_x, _body_y,
		_xscale, _body_scale, angle, colour, _alpha);
	draw_sprite_ext(end_spr, _frame, _tail_x, _tail_y,
		_xscale, _yscale, angle, colour, _alpha);
	if (draw_head) {
		draw_sprite_ext(head_spr, _frame, x, y,
			_xscale, _yscale, angle, colour, _alpha);
	};
}
