/// @description Draw PEC note geometry.
if (!canDraw) then exit;
if (type != 2) {
	draw_sprite_ext(sprite_index, hl, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
} else if (hold_started) {
	draw_hold(hx0, hy0, image_xscale, image_yscale, yscale,
		image_angle, hl, image_blend, image_alpha, false);
} else {
	draw_hold(hx0, hy0, image_xscale, image_yscale, yscale,
		image_angle, hl, image_blend, image_alpha, true);
};
