/// @description Draw RPE judge line (supports extended scale/color/text)
var s = (variable_global_exists("global_scales") ? global_scales : 1.0);
if (!is_real(s) || s <= 0) then s = 1.0;

if (has_paint_events) {
	if (!surface_exists(paint_surface)
		|| surface_get_width(paint_surface) != room_width
		|| surface_get_height(paint_surface) != room_height) {
		if (surface_exists(paint_surface)) then surface_free(paint_surface);
		paint_surface = surface_create(room_width, room_height);
		if (surface_exists(paint_surface)) {
			surface_set_target(paint_surface);
			draw_clear_alpha(c_black, 0);
			surface_reset_target();
		};
		paint_has_content = false;
		paint_last_valid = false;
	};
	if (surface_exists(paint_surface)) {
		if (line_time < paint_last_time) {
			surface_set_target(paint_surface);
			draw_clear_alpha(c_black, 0);
			surface_reset_target();
			paint_has_content = false;
			paint_last_valid = false;
		};
		paint_last_time = line_time;
		var paint_radius = real(__paint_radius) * s * sqrt(abs(__scale_x * __scale_y));
		if (paint_radius <= 0) {
			if (paint_has_content) {
				surface_set_target(paint_surface);
				draw_clear_alpha(c_black, 0);
				surface_reset_target();
			};
			paint_has_content = false;
			paint_last_valid = false;
		} else {
			var paint_alpha = clamp(max(0, __raw_a) / 255, 0, 1);
			if (paint_alpha > 0) {
				surface_set_target(paint_surface);
				draw_set_colour(__color);
				draw_set_alpha(paint_alpha);
				if (paint_last_valid) {
					var paint_dx = x - paint_last_x;
					var paint_dy = y - paint_last_y;
					var paint_distance = point_distance(paint_last_x, paint_last_y, x, y);
					if (paint_distance > 0.001) {
						var paint_normal_x = -paint_dy / paint_distance;
						var paint_normal_y = paint_dx / paint_distance;
						var last_ax = paint_last_x + paint_normal_x * paint_last_radius;
						var last_ay = paint_last_y + paint_normal_y * paint_last_radius;
						var last_bx = paint_last_x - paint_normal_x * paint_last_radius;
						var last_by = paint_last_y - paint_normal_y * paint_last_radius;
						var now_ax = x + paint_normal_x * paint_radius;
						var now_ay = y + paint_normal_y * paint_radius;
						var now_bx = x - paint_normal_x * paint_radius;
						var now_by = y - paint_normal_y * paint_radius;
						draw_triangle(last_ax, last_ay, last_bx, last_by, now_ax, now_ay, false);
						draw_triangle(last_bx, last_by, now_bx, now_by, now_ax, now_ay, false);
					};
				};
				draw_circle(x, y, paint_radius, false);
				draw_set_alpha(1);
				surface_reset_target();
				paint_has_content = true;
				paint_last_valid = true;
				paint_last_x = x;
				paint_last_y = y;
				paint_last_radius = paint_radius;
			} else {
				paint_last_valid = false;
			};
		};
		draw_surface(paint_surface, 0, 0);
	};
	exit;
};

if (image_alpha <= 0) then exit;
if ((__scale_x == 0) || (__scale_y == 0)) then exit;

var line_canvas_scale = (room_width > room_height * 0.75
	? room_height / 1080 : room_width / 810);
var sx;
var sy;
if (is_default_line) {
	sx = 0.78 * s * 1.18 * __scale_x;
	sy = 0.80 * s * 0.65 * __scale_y;
} else {
	var line_base_scale = line_canvas_scale * 1.2;
	sx = line_base_scale * __scale_x;
	sy = line_base_scale * __scale_y;
};

// Apply color from extended colorEvents (or default white)
image_blend = __color;

if (has_text_events) {
        if (string_length(line_text) > 0) {
                if (variable_global_exists("game") && is_struct(game) && !is_undefined(game.font) && font_exists(game.font)) {
                        draw_set_font(game.font);
                };
                draw_set_halign(fa_center);
                draw_set_valign(fa_middle);
                draw_set_colour(image_blend);
                draw_set_alpha(image_alpha);
				// Match PCR's 47px line-text size on its 1080px reference canvas.
				var text_font_size = max(1, font_get_size(draw_get_font()));
				var line_canvas_scale = (room_width > room_height * 0.75
					? room_height / 1080
					: room_width / 810);
				var tscale = line_canvas_scale * (47 / text_font_size);
				var text_scale_x = tscale * __scale_x;
				var text_scale_y = tscale * __scale_y;
				var text_local_x = (0.5 - anchor_x) * string_width(line_text) * text_scale_x;
				var text_local_y = (anchor_y - 0.5) * string_height(line_text) * text_scale_y;
				var text_cos = dcos(image_angle);
				var text_sin = dsin(image_angle);
				var text_draw_x = x + text_local_x * text_cos + text_local_y * text_sin;
				var text_draw_y = y - text_local_x * text_sin + text_local_y * text_cos;
                draw_text_transformed(text_draw_x, text_draw_y, line_text, text_scale_x, text_scale_y, image_angle);
                draw_set_alpha(1);
        };
} else {
	var frame = 0;
	if (has_gif_events && is_struct(gif_data) && is_array(gif_data.frames) && array_length(gif_data.frames) > 0) {
		var gif_time = frac(__gif_progress) * max(0.000001, real(gif_data.total));
		var gif_accum = 0;
		for (var gif_i = 0; gif_i < array_length(gif_data.frames); gif_i++) {
			gif_accum += max(0.000001, real(gif_data.delays[gif_i]));
			frame = gif_i;
			if (gif_time < gif_accum) then break;
		};
		var gif_sprite = gif_data.frames[frame];
		if (sprite_exists(gif_sprite)) then sprite_index = gif_sprite;
		frame = 0;
	};
	var sprite_local_x = (0.5 - anchor_x) * sprite_get_width(sprite_index) * sx;
	var sprite_local_y = (anchor_y - 0.5) * sprite_get_height(sprite_index) * sy;
	var sprite_cos = dcos(image_angle);
	var sprite_sin = dsin(image_angle);
	var sprite_draw_x = x + sprite_local_x * sprite_cos + sprite_local_y * sprite_sin;
	var sprite_draw_y = y - sprite_local_x * sprite_sin + sprite_local_y * sprite_cos;
        draw_sprite_ext(sprite_index, frame, sprite_draw_x, sprite_draw_y, sx, sy, image_angle, image_blend, image_alpha);
};

if (variable_global_exists("game") && is_struct(game) && game.settings.enableDisplayLineID) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_colour(c_white);
        draw_set_alpha(1);
        draw_text_transformed(x, y - 16 * s, string(line_id), 0.32 * s, 0.32 * s, image_angle);
};
