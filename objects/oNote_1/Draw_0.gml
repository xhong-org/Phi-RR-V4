/// @description Draw RPE note
if (!canDraw) then exit;

if (!_is_hold) {
	if (isBad) {
		var a = ((1 - (_now_seconds - judgeRealTime)) * 0.5);
		draw_sprite_ext(sprite_index, 2, _bad_x, _bad_y, image_xscale, image_yscale, _bad_angle, c_red, a);
		exit;
	};
	draw_sprite_ext(sprite_index, hl, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	
	
	//type={type} time={string_format(start_beat , 0 , 10)} lineID={line_id} line_xy=[{_line_ref.x} , {_line_ref.y}] note_xy=[{x} , {y}] above={isAbove}
	
} else {
	// PCR order: body, tail, then head if still out
	var a = (isMiss ? 0.5 : image_alpha);
	// body at body-start (_hx1,_hy1), scaled by yscale (body stretch)
	draw_sprite_ext(note_hold_body, hl, _hx1, _hy1, image_xscale, yscale, image_angle, image_blend, a);
	// tail at end
	draw_sprite_ext(note_hold_end, hl, _hx2, _hy2, image_xscale, image_yscale, image_angle, image_blend, a);
	// head only while still approaching (PCR _is_out)
	if (_is_out) {
		draw_sprite_ext(sprite_index, hl, _hx0, _hy0, image_xscale, image_yscale, image_angle, image_blend, a);
	};
};

//draw_set_font(game.font);
//draw_set_halign(fa_middle);
//draw_text_transformed_colour(_debug_text_x , _debug_text_y , $"[{type},[{string_format(start_beat , 0 , 5)},{string_format(end_beat , 0 , 5)}],{line_id},[{_line_ref.x},{_line_ref.y}],[{x},{y}],{isAbove}]" , 0.3 , 0.3 , image_angle , c_white , c_white , c_white , c_white , 1);