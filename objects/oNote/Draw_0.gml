/// @description Draw directly, avoiding an event dispatch for every visible note.
if(!canDraw) then exit;

if(!_is_hold){
	if(isBad){
		var alpha = ((1 - (_now_seconds - judgeRealTime)) * 0.5);
		draw_sprite_ext(sprite_index, 2, _bad_x, _bad_y, image_xscale, image_yscale, _bad_angle, c_red, alpha);
		exit;
	};

	image_alpha = (clamp(realHitTime <= _now_seconds ? 1 - ((_now_seconds - realHitTime) * 1000 / 160) : 1, 0, 1));
	draw_sprite_ext(sprite_index, hl, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
}else if(isHold){
	draw_sprite_ext(note_hold_body, hl, _hx0, _hy0, image_xscale, yscale, image_angle, image_blend, isMiss ? 0.5 : image_alpha);
	draw_sprite_ext(note_hold_end, hl, _hx1, _hy1, image_xscale, image_yscale, image_angle, image_blend, isMiss ? 0.5 : image_alpha);
}else{
	draw_sprite_ext(sprite_index, hl, _hx0, _hy0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	draw_sprite_ext(note_hold_body, hl, _hx1, _hy1, image_xscale, yscale, image_angle, image_blend, image_alpha);
	draw_sprite_ext(note_hold_end, hl, _hx2, _hy2, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
};
