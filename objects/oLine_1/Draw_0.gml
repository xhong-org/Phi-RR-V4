///@desc 绘制：RPE 判定线，支持扩展缩放、颜色和文本
chart_mask_scissor_set();
// 加载动画或判定线尚未解冻时不画。
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then exit;
if (instance_exists(oRender_1)
	&& variable_instance_exists(oRender_1, "_chart_lines_thaw_pending")
	&& oRender_1._chart_lines_thaw_pending) then exit;
var s = (variable_global_exists("global_scales") ? global_scales : 1.0);
if (!is_real(s) || s <= 0) then s = 1.0;
var _room_w = room_width;
var _room_h = room_height;

// 没有 zIndex 时视频跟这条线一起画，appearanceOnAttach 为 0
// （默认，包括从没设置过的谱）会藏起线。声明了视频 zIndex 的由 oExtraPlay 画，
// 这条线留在自己的层上。appearanceOnAttach 为 1 或 2 时线仍可见，在视频上方或下方。
var line_has_attached_video = false;
var attached_video_owns_depth = false;
if (instance_exists(oExtraPlay)) {
	with (oExtraPlay) {
		var _attached_video = video_line_index(other.id);
		line_has_attached_video = _attached_video >= 0;
		// 视频自己有 z 时不在这条线里画。
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
// 吸附视频且外观为 0、又没有文本时，线本身不画。
if (line_has_attached_video && attach_look <= 0 && !has_text_events) then exit;

if (has_paint_events) {
	// 涂鸦表面尺寸必须跟房间一致，否则重建并清空。
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
		// 时间回退就清掉已经涂上的内容。
		if (line_time < paint_last_time) {
			surface_set_target(paint_surface);
			draw_clear_alpha(c_black, 0);
			surface_reset_target();
			paint_has_content = false;
			paint_last_valid = false;
		};
		paint_last_time = line_time;
		var paint_radius = real(__paint_radius) * s * sqrt(abs(__scale_x * __scale_y));
		// 半径不大于 0 时清空并停止涂鸦。
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
			// 有透明度才把上一帧到这一帧连成一条带子。
			if (paint_alpha > 0) {
				surface_set_target(paint_surface);
				draw_set_colour(__color);
				draw_set_alpha(paint_alpha);
				if (paint_last_valid) {
					var paint_dx = x - paint_last_x;
					var paint_dy = y - paint_last_y;
					var paint_distance = point_distance(paint_last_x, paint_last_y, x, y);
					// 移动足够远才补中间的两个三角形。
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
	// 涂鸦画完就不再画线精灵。
	exit;
};

// 完全透明就不再画精灵。
if (image_alpha <= 0) then exit;

// 颜色来自扩展 colorEvents，否则是白。
image_blend = __color;

	if (has_text_events) {
		if (string_length(line_text) > 0) {
			if (line_text_font != -1 && font_exists(line_text_font)) then draw_set_font(line_text_font);
			else if (variable_global_exists("game") && is_struct(game) && !is_undefined(game.font) && font_exists(game.font)) then draw_set_font(game.font);
			// PhiEdit 标签字号 100，节点缩放是 (scaleX, scaleY) * 0.5，左对齐。
			// 锚点 (0,0) 是行框左下，(1,1) 是右上。cmdysj 的行框是一个 em
			// （上升 880，下降 -120）。image_angle 已经是取反后的谱面旋转，
			// 在这个 Y 向下的空间里就是 cocos 的顺时针旋转。
			var _old_halign = draw_get_halign();
			var _old_valign = draw_get_valign();
			draw_set_halign(fa_left);
			draw_set_valign(fa_top);
			draw_set_colour(image_blend);
			draw_set_alpha(image_alpha);
			var text_view_w = _room_w;
			if (variable_global_exists("chart_view_width") && is_real(chart_view_width) && chart_view_width > 0) {
				text_view_w = chart_view_width;
			};
			var text_font = draw_get_font();
			if (_text_layout_source != line_text || _text_layout_font != text_font) {
				var text_em_px = string_width("■");
				// 方块测不出宽度时用字号兜底。
				if (text_em_px < 1) then text_em_px = max(1, font_get_size(draw_get_font()));
				var text_body = string_replace_all(line_text, "\r\n", "\n");
				text_body = string_replace_all(text_body, "\r", "");
				var text_rows = string_split(text_body, "\n");
				var text_row_n = array_length(text_rows);
				// 拆不出行时仍画整段。
				if (text_row_n < 1) {
					text_rows = [text_body];
					text_row_n = 1;
				};
				var text_w = 0;
				for (var text_i = 0; text_i < text_row_n; text_i++) {
					var row = text_rows[text_i];
					var row_width = 0;
					// 多行时最后一行去掉尾部空白再量宽。
					if (text_row_n > 1 && text_i == text_row_n - 1) {
						var row_len = string_length(row);
						var trail_n = row_len;
						while (trail_n > 0) {
							var trail_ch = string_char_at(row, trail_n);
							// 遇到非空白就停。
							if (trail_ch != " " && trail_ch != "\t") then break;
							trail_n--;
						};
						if (trail_n > 0) then row_width = string_width(string_copy(row, 1, trail_n));
					} else if (string_length(row) > 0) {
						row_width = string_width(row);
					};
					if (row_width > text_w) then text_w = row_width;
				};
				_text_layout_source = line_text;
				_text_layout_font = text_font;
				_text_layout_em = text_em_px;
				_text_layout_rows = text_rows;
				_text_layout_width = text_w;
			}
			var text_em_px = _text_layout_em;
			var text_rows = _text_layout_rows;
			var text_row_n = array_length(text_rows);
			var text_w = _text_layout_width;
			var text_unit = (50 * (text_view_w / 1350)) / text_em_px;
			var text_scale_x = text_unit * __scale_x;
			var text_scale_y = text_unit * __scale_y;
			var text_h = text_row_n * text_em_px;
			var pen_x = -anchor_x * text_w;
			var pen_top = -(1 - anchor_y) * text_h;
			var text_cos = dcos(image_angle);
			var text_sin = dsin(image_angle);
			for (var text_i = 0; text_i < text_row_n; text_i++) {
				var row = text_rows[text_i];
				// 空行跳过。
				if (string_length(row) <= 0) then continue;
				var text_lx = pen_x * text_scale_x;
				var text_ly = (pen_top + text_i * text_em_px) * text_scale_y;
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
	// GIF 按累计延迟选出当前帧，绘制子图固定为 0。
	if (has_gif_events && is_struct(gif_data) && is_array(gif_data.frames) && array_length(gif_data.frames) > 0) {
		var gif_time = frac(__gif_progress) * max(0.000001, real(gif_data.total));
		var lo = 0;
		var hi = array_length(gif_data.ends);
		while (lo < hi) {
			var mid = (lo + hi) div 2;
			if (gif_data.ends[mid] <= gif_time) lo = mid + 1;
			else hi = mid;
		}
		frame = min(lo, array_length(gif_data.frames) - 1);
		var gif_sprite = gif_data.frames[frame];
		if (sprite_exists(gif_sprite)) then sprite_index = gif_sprite;
		frame = 0;
	};
	var _line_sprite = sprite_index;
	var anchor_width = max(1, sprite_get_width(_line_sprite));
	var anchor_height = max(1, sprite_get_height(_line_sprite));
	var texture_view_w = chart_view_width;
	var sx;
	var sy;
	// 默认线、CSV 覆盖和自定义贴图像素尺寸各算各的缩放。
	if (!is_default_line) {
		var _csv = chart_line_override(line_id);
		if (is_struct(_csv)) {
			var _csv_scale = chart_line_csv_sprite_scale(_csv, _line_sprite);
			sx = _csv_scale[0] * __scale_x;
			sy = _csv_scale[1] * __scale_y;
		} else {
			var texture_px = rpe_custom_texture_pixel_size(__scale_x, __scale_y, anchor_width, anchor_height, texture_view_w);
			sx = texture_px[0] / anchor_width;
			sy = texture_px[1] / anchor_height;
		};
	} else {
		var line_px = rpe_default_line_pixel_size(__scale_x, __scale_y, texture_view_w);
		sx = line_px[0] / anchor_width;
		sy = line_px[1] / anchor_height;
	};
	// Cocos 的锚点 Y 向上。缩放和旋转之后，锚点像素必须仍落在线上。
	// 运行时 sprite_add 的原点是 (0, 0)；1x1 的 Box.png 存不住 0.5 偏移，
	// 于是居中的 4000x4000 背景会从线往右下画。
	var anchor_local_x = anchor_x * anchor_width;
	var anchor_local_y = (1 - anchor_y) * anchor_height;
	if (!is_default_line) {
		sprite_set_offset(_line_sprite, 0, 0);
	} else {
		anchor_local_x -= sprite_get_xoffset(_line_sprite);
		anchor_local_y -= sprite_get_yoffset(_line_sprite);
	};
	// 默认 line.png 用 FC/AP。colorEvents、自定义贴图、GIF、涂鸦、
	// attachUI 和文本保持 __color（常常是白），不采样判定色。
	var texture_blend = __color;
	// appearanceOnAttach 为 1 时保持白色，除非颜色事件已经写了 __color。
	// 为 2 时用 FC/AP 判定色，和普通默认线一样。
	var judge_tint = line_texture_use_judge_color
		&& !(line_has_attached_video && attach_look == 1);
	if (judge_tint && variable_global_exists("game") && is_struct(game)
		&& bool(game.settings.enableLineJudge)) {
		texture_blend = chart_line_judge_blend();
	};
	// draw_sprite_ext 绕精灵原点缩放和旋转。把原点挪开，锚点像素才留在线上。旋转和音符相同。
	var anchor_shift_x = -anchor_local_x * sx;
	var anchor_shift_y = -anchor_local_y * sy;
	var anchor_cos = dcos(image_angle);
	var anchor_sin = dsin(image_angle);
	var sprite_draw_x = x + anchor_shift_x * anchor_cos + anchor_shift_y * anchor_sin;
	var sprite_draw_y = y - anchor_shift_x * anchor_sin + anchor_shift_y * anchor_cos;
	draw_sprite_ext(_line_sprite, frame, sprite_draw_x, sprite_draw_y, sx, sy, image_angle, texture_blend, image_alpha);
};

if (variable_global_exists("game") && is_struct(game) && game.settings.enableDisplayLineID) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_colour(c_white);
        draw_set_alpha(1);
        draw_text_transformed(x, y - 16 * s, string(line_id), 0.32 * s, 0.32 * s, image_angle);
};
