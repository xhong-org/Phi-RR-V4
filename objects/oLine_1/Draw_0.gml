/// @description Draw RPE judge line (supports extended scale/color/text)
chart_mask_scissor_set();
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then exit;
if (instance_exists(oRender_1)
	&& variable_instance_exists(oRender_1, "_chart_lines_thaw_pending")
	&& oRender_1._chart_lines_thaw_pending) then exit;
var s = (variable_global_exists("global_scales") ? global_scales : 1.0);
if (!is_real(s) || s <= 0) then s = 1.0;
var _room_w = room_width;
var _room_h = room_height;

// No zIndex: the video is painted with this line, and appearanceOnAttach 0
// (the default, including charts that never set it) hides the line. A declared
// video zIndex is drawn by oExtraPlay, so this line stays on its own layer.
// appearanceOnAttach 1/2 keeps the line visible above or under that video.
var line_has_attached_video = false;
var attached_video_owns_depth = false;
if (instance_exists(oExtraPlay)) {
	with (oExtraPlay) {
		var _attached_video = video_line_index(other.id);
		line_has_attached_video = _attached_video >= 0;
		if (line_has_attached_video && is_real(videos[_attached_video].zIndex)) {
			attached_video_owns_depth = true;
		};
		if (line_has_attached_video && !attached_video_owns_depth) then draw_attached_video(_attached_video);
	};
};
var attach_look = 0;
if (variable_instance_exists(id, "appearance_on_attach") && is_real(appearance_on_attach)) {
	attach_look = appearance_on_attach;
};
if (line_has_attached_video && attach_look <= 0 && !has_text_events) then exit;

if (has_paint_events) {
	if (!surface_exists(paint_surface)
		|| surface_get_width(paint_surface) != _room_w
		|| surface_get_height(paint_surface) != _room_h) {
		if (surface_exists(paint_surface)) then surface_free(paint_surface);
		paint_surface = surface_create(_room_w, _room_h);
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

// Phira renders the chart inside a viewport whose aspect is limited by the
// chart aspect. Narrow windows keep their full height; wide windows crop the
// sides. Use that viewport for texture dimensions.
var texture_view_w = chart_view_width;
var sx;
var sy;
if (is_default_line) {
	// line.png is a geometric line. scaleX is halved only with no text events and
	// no attachUI. Phira's lineLength (6 on this chart) is the unscaled half-length
	// in world units, so event scale 1 reaches 2025 RPE and ends meet at every
	// viewport size. An absent scaleY reads as 0 for the thickness probe (0.0076)
	// and 1 for the transform; an explicit 1 uses thickness 0.01.
	var line_scale_x = __scale_x;
	if (!has_text_events && !is_attach_ui) then line_scale_x *= 0.5;
	var line_length = 6;
	if (variable_global_exists("game_1") && is_struct(game_1) && is_struct(game_1.chart_info)) {
		var info_line_length = real(game_1.chart_info[$ "line_length"] ?? 6);
		if (is_finite(info_line_length) && info_line_length > 0) then line_length = info_line_length;
	};
	var scale_y_events = extEvents[$ "scaleYEvents"];
	var line_thick = 0.0076;
	if (is_array(scale_y_events) && array_length(scale_y_events) > 0 && abs(__scale_y - 1) <= 0.0001) then line_thick = 0.01;
	var line_sprite_w = max(1, sprite_get_width(sprite_index));
	var line_sprite_h = max(1, sprite_get_height(sprite_index));
	sx = (line_scale_x * line_length * texture_view_w) / line_sprite_w;
	sy = (line_thick * __scale_y * texture_view_w * 0.5) / line_sprite_h;
} else {
	// Custom textures keep native pixels inside Phira's scale (event * 2/1350).
	// Screen size = native * event * view_w/1350, so both axes share one factor.
	var _csv = chart_line_override(line_id);
	if (is_struct(_csv)) {
		var _csv_scale = chart_line_csv_sprite_scale(_csv, sprite_index);
		sx = _csv_scale[0] * __scale_x;
		sy = _csv_scale[1] * __scale_y;
	} else {
		var texture_scale = texture_view_w / 1350;
		sx = texture_scale * __scale_x;
		sy = texture_scale * __scale_y;
	};
};

// Apply color from extended colorEvents (or default white)
image_blend = __color;

	if (has_text_events) {
		if (string_length(line_text) > 0) {
			if (line_text_font != -1 && font_exists(line_text_font)) then draw_set_font(line_text_font);
			else if (variable_global_exists("game") && is_struct(game) && !is_undefined(game.font) && font_exists(game.font)) then draw_set_font(game.font);
			// Raster origin is top-left. RPE anchor is (0,0) bottom-left, (1,1) top-right.
			// Offset from string_width/height; do not use fa_center/fa_middle.
			var _old_halign = draw_get_halign();
			var _old_valign = draw_get_valign();
			draw_set_halign(fa_left);
			draw_set_valign(fa_top);
			draw_set_colour(image_blend);
			draw_set_alpha(image_alpha);
			// Phira draws line text at size 1. One em is 4% of the chart viewport
			// width, on both axes, then the line scale is applied around the anchor.
			// The anchor sits 0.44em below the ascender. A "\n" advances 50 RPE Y,
			// then the line scale. Ink ignores leading and trailing spaces.
			var text_view_w = _room_w;
			var text_view_h = _room_h;
			if (variable_global_exists("chart_view_width") && is_real(chart_view_width) && chart_view_width > 0) {
				text_view_w = chart_view_width;
			};
			if (variable_global_exists("chart_view_height") && is_real(chart_view_height) && chart_view_height > 0) {
				text_view_h = chart_view_height;
			};
			// font_get_size is not the em. U+25A0 advances one em in this font.
			// Scale that measured em to 4% of the chart viewport, not by global_scales.
			var text_em_px = string_width("■");
			if (text_em_px < 1) then text_em_px = max(1, font_get_size(draw_get_font()));
			var text_unit = (0.04 * text_view_w) / text_em_px;
			var text_scale_x = text_unit * __scale_x;
			var text_scale_y = text_unit * __scale_y;
			var text_asc_px = 0.88 * text_em_px;
			var text_line_px = text_em_px;
			if (abs(text_scale_y) > 0.000001) then text_line_px = (50 * (text_view_h / 900)) / text_unit;
			var text_rows = string_split(string_replace_all(line_text, "\r\n", "\n"), "\n");
			var text_row_n = array_length(text_rows);
			if (text_row_n < 1) {
				text_rows = [line_text];
				text_row_n = 1;
			};
			var ink_left = 0;
			var ink_right = 0;
			var have_ink = false;
			for (var text_i = 0; text_i < text_row_n; text_i++) {
				var row = text_rows[text_i];
				var row_len = string_length(row);
				var lead_n = 0;
				while (lead_n < row_len) {
					var lead_ch = string_char_at(row, lead_n + 1);
					if (lead_ch != " " && lead_ch != "\t") then break;
					lead_n++;
				};
				var trail_n = row_len;
				while (trail_n > lead_n) {
					var trail_ch = string_char_at(row, trail_n);
					if (trail_ch != " " && trail_ch != "\t") then break;
					trail_n--;
				};
				if (trail_n <= lead_n) then continue;
				var row_left = (lead_n > 0) ? string_width(string_copy(row, 1, lead_n)) : 0;
				var row_right = string_width(string_copy(row, 1, trail_n));
				if (!have_ink) {
					ink_left = row_left;
					ink_right = row_right;
					have_ink = true;
				} else {
					ink_left = min(ink_left, row_left);
					ink_right = max(ink_right, row_right);
				};
			};
			var text_w = have_ink ? max(0, ink_right - ink_left) : 0;
			var pen_x = have_ink ? -(ink_left + anchor_x * text_w) : 0;
			var layout_h = (text_row_n - 1) * text_line_px + text_asc_px;
			var anchor_from_top = (1 - anchor_y) * layout_h;
			var text_cos = dcos(image_angle);
			var text_sin = dsin(image_angle);
			for (var text_i = 0; text_i < text_row_n; text_i++) {
				var row = text_rows[text_i];
				if (string_length(row) <= 0) then continue;
				var pen_y = -anchor_from_top + text_i * text_line_px;
				var text_lx = pen_x * text_scale_x;
				var text_ly = pen_y * text_scale_y;
				var text_draw_x = x + text_lx * text_cos + text_ly * text_sin;
				var text_draw_y = y - text_lx * text_sin + text_ly * text_cos;
				draw_text_transformed(text_draw_x, text_draw_y, row, text_scale_x, text_scale_y, image_angle);
			};
			draw_set_halign(_old_halign);
			draw_set_valign(_old_valign);
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
	var _line_sprite = sprite_index;
	var anchor_width = sprite_get_width(_line_sprite);
	var anchor_height = sprite_get_height(_line_sprite);
	var sprite_local_x = (0.5 - anchor_x) * anchor_width * sx;
	var sprite_local_y = (anchor_y - 0.5) * anchor_height * sy;
	var sprite_cos = dcos(image_angle);
	var sprite_sin = dsin(image_angle);
	var sprite_draw_x = x + sprite_local_x * sprite_cos + sprite_local_y * sprite_sin;
	var sprite_draw_y = y - sprite_local_x * sprite_sin + sprite_local_y * sprite_cos;
	// Default line.png uses FC/AP. colorEvents, custom textures, GIF, paint,
	// attachUI, and text keep __color (often white) and are not sampled.
	var texture_blend = __color;
	// appearanceOnAttach 1 stays white unless color events already set __color.
	// 2 uses the FC/AP judge tint, same as an ordinary default line.
	var judge_tint = line_texture_use_judge_color
		&& !(line_has_attached_video && attach_look == 1);
	if (judge_tint && variable_global_exists("game") && is_struct(game)
		&& bool(game.settings.enableLineJudge)) {
		texture_blend = chart_line_judge_blend();
	};
	draw_sprite_ext(_line_sprite, frame, sprite_draw_x, sprite_draw_y, sx , sy, image_angle, texture_blend, image_alpha);
};

if (variable_global_exists("game") && is_struct(game) && game.settings.enableDisplayLineID) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_colour(c_white);
        draw_set_alpha(1);
        draw_text_transformed(x, y - 16 * s, string(line_id), 0.32 * s, 0.32 * s, image_angle);
};
