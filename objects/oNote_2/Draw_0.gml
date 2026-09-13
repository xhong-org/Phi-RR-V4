/// @description Draw PEC note geometry.
if (!canDraw) then exit;

if (skin_active()) {
	var _skin_kind = (type == 4 ? "drag" : (type == 3 ? "flick" : "tap"));
	var _skin_spr = skin_note_sprite(_skin_kind, hl);
	var _skin_hold = (type == 2) ? skin_hold_parts(hl) : undefined;
	var _keep_head = is_struct(_skin_hold) && bool(_skin_hold.keep_head);
	var _compact = is_struct(_skin_hold) && bool(_skin_hold.compact);
	var _tail_trim = _compact ? image_yscale * sprite_get_height(_skin_hold.tail) * 0.5 : 1;
	var sk = sprite_exists(_skin_spr) ? skin_note_scale_k(_skin_spr) : 1;
	var hk = (is_struct(_skin_hold) && sprite_exists(_skin_hold.head)) ? skin_note_scale_k(_skin_hold.head) : 1;
	if (type != 2) {
		if (sprite_exists(_skin_spr)) then draw_sprite_ext(_skin_spr, 0, x, y, image_xscale * sk, image_yscale * sk, image_angle, image_blend, image_alpha);
		else draw_sprite_ext(sprite_index, hl, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	} else if (hold_started) {
		var hold_a = isMiss ? 0.5 : image_alpha;
		if (is_struct(_skin_hold)) {
			draw_hold_fit(hx0, hy0, image_xscale * hk, image_yscale * hk, yscale,
				image_angle, 0, image_blend, hold_a, _keep_head, false, _compact ? _tail_trim * hk : 0, 1,
				_skin_hold.head, _skin_hold.body, _skin_hold.tail);
		} else {
			draw_hold_fit(hx0, hy0, image_xscale, image_yscale, yscale,
				image_angle, hl, image_blend, hold_a, false);
		};
	} else {
		if (is_struct(_skin_hold)) {
			draw_hold_fit(hx0, hy0, image_xscale * hk, image_yscale * hk, yscale,
				image_angle, 0, image_blend, image_alpha, true, !_compact, _tail_trim * hk, 1,
				_skin_hold.head, _skin_hold.body, _skin_hold.tail);
		} else {
			draw_hold_fit(hx0, hy0, image_xscale, image_yscale, yscale,
				image_angle, hl, image_blend, image_alpha, true, false, 1);
		};
	};
	exit;
};

if (type != 2) {
	draw_sprite_ext(sprite_index, hl, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
} else if (hold_started) {
	draw_hold_fit(hx0, hy0, image_xscale, image_yscale, yscale,
		image_angle, hl, image_blend, isMiss ? 0.5 : image_alpha, false);
} else {
	draw_hold_fit(hx0, hy0, image_xscale, image_yscale, yscale,
		image_angle, hl, image_blend, image_alpha, true, false, 1);
};
