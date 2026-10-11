/// @description Draw directly, avoiding an event dispatch for every visible note.
if(!canDraw) then exit;

if (skin_active()) {
	var _skin_kind = (type == 2 ? "drag" : (type == 4 ? "flick" : "tap"));
	var _skin_spr = skin_note_sprite(_skin_kind, isBad ? 0 : hl);
	var _skin_hold = (!_is_hold) ? undefined : skin_hold_parts(hl);
	var _compact = is_struct(_skin_hold) && bool(_skin_hold.compact);
	var _tail_trim = (_compact && is_struct(_skin_hold)) ? image_yscale * sprite_get_height(_skin_hold.tail) * 0.5 : 0;
	var sk = sprite_exists(_skin_spr) ? skin_note_scale_k(_skin_spr) : 1;
	var hk = (is_struct(_skin_hold) && sprite_exists(_skin_hold.head)) ? skin_note_scale_k(_skin_hold.head) : 1;
	if(!_is_hold){
		if(isBad){
			var alpha = ((1 - (_now_seconds - judgeRealTime)) * 0.5);
			if (sprite_exists(_skin_spr)) then draw_sprite_ext(_skin_spr, 0, _bad_x, _bad_y, image_xscale * sk, image_yscale * sk, _bad_angle, c_red, alpha);
			else draw_sprite_ext(sprite_index, 2, _bad_x, _bad_y, image_xscale, image_yscale, _bad_angle, c_red, alpha);
			exit;
		};
		image_alpha = chart_note_pass_fade(_now_seconds, realHitTime, chart_note_miss_window_sec(self.type, false));
		if (sprite_exists(_skin_spr)) then draw_sprite_ext(_skin_spr, 0, x, y, image_xscale * sk, image_yscale * sk, image_angle, image_blend, image_alpha);
		else draw_sprite_ext(sprite_index, hl, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}else if(isHold){
		if (is_struct(_skin_hold)) {
			draw_hold_fit(_hx0, _hy0, image_xscale * hk, image_yscale * hk, yscale,
				image_angle, 0, image_blend, isMiss ? 0.45 : image_alpha, false, false, _tail_trim * hk, 1,
				_skin_hold.head, _skin_hold.body, _skin_hold.tail);
		} else {
			draw_hold_fit(_hx0, _hy0, image_xscale, image_yscale, yscale,
				image_angle, hl, image_blend, isMiss ? 0.45 : image_alpha, false);
		};
	}else{
		if (is_struct(_skin_hold)) {
			draw_hold_fit(_hx0, _hy0, image_xscale * hk, image_yscale * hk, yscale,
				image_angle, 0, image_blend, image_alpha, true, !_compact, _tail_trim * hk, 1,
				_skin_hold.head, _skin_hold.body, _skin_hold.tail);
		} else {
			draw_hold_fit(_hx0, _hy0, image_xscale, image_yscale, yscale,
				image_angle, hl, image_blend, image_alpha, true);
		};
	};
	exit;
};

if(!_is_hold){
	if(isBad){
		var alpha = ((1 - (_now_seconds - judgeRealTime)) * 0.5);
		draw_sprite_ext(sprite_index, 2, _bad_x, _bad_y, image_xscale, image_yscale, _bad_angle, c_red, alpha);
		exit;
	};
	image_alpha = chart_note_pass_fade(_now_seconds, realHitTime, chart_note_miss_window_sec(self.type, false));
	draw_sprite_ext(sprite_index, hl, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
}else if(isHold){
	draw_hold_fit(_hx0, _hy0, image_xscale, image_yscale, yscale,
		image_angle, hl, image_blend, isMiss ? 0.45 : image_alpha, false);
}else{
	draw_hold_fit(_hx0, _hy0, image_xscale, image_yscale, yscale,
		image_angle, hl, image_blend, image_alpha, true);
};
