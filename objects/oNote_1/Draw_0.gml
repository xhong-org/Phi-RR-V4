/// @description Draw RPE note
if (!canDraw) then exit;

var _sprite = sprite_index;
var _frame = hl;
var _xscale = image_xscale;
var _yscale = image_yscale;
var _angle = image_angle;
var _blend = image_blend;
var _alpha = image_alpha;

if (!_is_hold) {
	if (isBad) {
		var a = ((1 - (_now_seconds - judgeRealTime)) * 0.5);
		draw_sprite_ext(_sprite, 2, _bad_x, _bad_y, _xscale, _yscale, _bad_angle, c_red, a);
		exit;
	};
	draw_sprite_ext(_sprite, _frame, x, y, _xscale, _yscale, _angle, _blend, _alpha);
	
	
	//type={type} time={string_format(start_beat , 0 , 10)} lineID={line_id} line_xy=[{_line_ref.x} , {_line_ref.y}] note_xy=[{x} , {y}] above={isAbove}
	
} else {
	var a = (isMiss ? 0.5 : _alpha);
	var _tail_trim = (compactHold ? _yscale * (_hold_tail_height * 0.5) : 0);
	draw_hold(_hx0, _hy0, _xscale, _yscale, yscale,
		_angle, _frame, _blend, a, _is_out, _is_out && !compactHold, _tail_trim);
};

//draw_set_font(game.font);
//draw_set_halign(fa_middle);
//draw_text_transformed_colour(_debug_text_x , _debug_text_y , $"[{type},[{string_format(start_beat , 0 , 5)},{string_format(end_beat , 0 , 5)}],{line_id},[{_line_ref.x},{_line_ref.y}],[{x},{y}],{isAbove}]" , 0.3 , 0.3 , image_angle , c_white , c_white , c_white , c_white , 1);
