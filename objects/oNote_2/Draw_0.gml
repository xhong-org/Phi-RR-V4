/// @description Draw PEC note geometry.
if (!canDraw) then exit;
if (type != 2) {
	draw_sprite_ext(sprite_index, hl, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
} else if (hold_started) {
	draw_sprite_ext(note_hold_body, hl, hx0, hy0, image_xscale, yscale, image_angle, image_blend, image_alpha);
	draw_sprite_ext(note_hold_end, hl, hx1, hy1, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
} else {
	draw_sprite_ext(sprite_index, hl, hx0, hy0, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	draw_sprite_ext(note_hold_body, hl, hx1, hy1, image_xscale, yscale, image_angle, image_blend, image_alpha);
	draw_sprite_ext(note_hold_end, hl, hx2, hy2, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
};
