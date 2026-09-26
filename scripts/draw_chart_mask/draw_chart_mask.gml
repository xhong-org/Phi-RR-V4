/// @description Shared chart viewport and Phira-style aspect mask helpers.
/// @param {real} room_w
/// @param {real} room_h
function chart_mask_enabled() {
	var s = undefined;
	if (variable_global_exists("game") && is_struct(game) && is_struct(game.settings)) {
		s = game.settings;
	} else if (variable_global_exists("pls_settings") && is_struct(global.pls_settings)) {
		s = global.pls_settings;
	} else {
		s = settings_store();
	};
	return is_struct(s) && bool(s.enableSurface ?? false);
}

function chart_mask_released() {
	if (!chart_mask_enabled() || !instance_exists(oPlayTransition)) then return false;
	var _transition = instance_find(oPlayTransition, 0);
	return variable_instance_exists(_transition, "mask_released") && _transition.mask_released;
}

function chart_play_ending() {
	if (instance_exists(oSettlement)) then return true;
	if (!instance_exists(oPlayTransition)) then return false;
	var _transition = instance_find(oPlayTransition, 0);
	if (!variable_instance_exists(_transition, "state")) then return false;
	return _transition.state >= PLAY_TRANSITION_STATE.OUTRO
		&& _transition.state < PLAY_TRANSITION_STATE.FINISHED;
}

function chart_background_dim_alpha() {
	var _transition_alpha = 1;
	if (instance_exists(oPlayTransition)) {
		var _transition = instance_find(oPlayTransition, 0);
		if (instance_exists(_transition.owner) && variable_instance_exists(_transition.owner, "play_transition_active")
			&& _transition.owner.play_transition_active) {
			_transition_alpha = _transition.owner.play_transition_bg_alpha;
		};
	};
	return 0.6 * _transition_alpha;
}

function chart_view_refresh(_room_w, _room_h) {
	globalvar chart_view_left, chart_view_width, chart_view_height, chart_view_right;
	globalvar chart_aspect_ratio;
	chart_view_height = max(1, _room_h);
	var _aspect = chart_aspect_ratio;
	if (!is_real(_aspect) || !is_finite(_aspect) || _aspect <= 0) {
		_aspect = 16 / 9;
		chart_aspect_ratio = _aspect;
	};
	// Phira keeps the chart inside its aspect even when the mask is off.
	// Line length is square in that viewport, while positions use 1350 by 900.
	// A wider maximized window would stretch X, so the scale events that
	// cancel rotation no longer land on the rectangle corners.
	var _window_aspect = _room_w / chart_view_height;
	if (_window_aspect > _aspect) {
		chart_view_width = chart_view_height * _aspect;
	} else {
		chart_view_width = _room_w;
	};
	chart_view_width = max(1, round(chart_view_width));
	chart_view_left = round((_room_w - chart_view_width) * 0.5);
	chart_view_right = chart_view_left + chart_view_width;
}

function draw_chart_mask(_room_w , _room_h){
	// The aspect mask is the undimmed illustration oBG draws on the full
	// application surface. The chart composite only covers the effective
	// viewport, so the sides stay visible. Do not paint black bars over it.
	return;
};

function chart_background_retry_blur() {
	if (!pls_is_gxgames()) then return;
	if (!variable_global_exists("game") || !is_struct(game)) then return;
	if (!bool(game[$ "bg_blur_pending"] ?? false)) then return;
	var tries = real(game[$ "bg_blur_tries"] ?? 0);
	if (tries >= 8) {
		game.bg_blur_pending = false;
		print("[R-BG] GX deferred path blur gave up.");
		return;
	};
	game.bg_blur_tries = tries + 1;
	var p = string(game[$ "bg_source_path"] ?? "");
	if (!string_length(p)) {
		game.bg_blur_pending = false;
		return;
	};
	// Same call as oLoadAnimator: file path, 10 iterations (GX caps at 4).
	var blurred = kawase_blur_sprite(p, 1, 0, 10, SPRITE_OFFSET.MIDDLE_CENTER, [0, 0]);
	if (!asset_sprite_valid(blurred)) then return;
	if (asset_sprite_valid(game.bg) && game.bg != blurred) then sprite_delete(game.bg);
	game.bg = blurred;
	var _bw = sprite_get_width(game.bg);
	var _bh = sprite_get_height(game.bg);
	if (_bw > 0 && _bh > 0) then sprite_set_offset(game.bg, _bw * 0.5, _bh * 0.5);
	game.bg_blur_pending = false;
	game.bg_blurred = true;
	print($"[R-BG] GX deferred path blur ok size={_bw}x{_bh}");
}

function chart_draw_background(_dim = true) {
	if (pls_is_gxgames()) {
		chart_blur_bind_game(true);
		chart_background_retry_blur();
	} else if (variable_global_exists("game") && is_struct(game) && !asset_sprite_valid(game.bg)) {
		chart_blur_bind_game(false);
	};
	if (!(variable_global_exists("game") && is_struct(game) && is_struct(game.settings) && game.settings.showBG)) then return;
	if (!asset_sprite_valid(game.bg)) then return;
	// Effects and video extensions may leave a non-standard blend mode active.
	// The background dim must use ordinary source-alpha blending.
	var _old_colour = draw_get_colour();
	var _old_alpha = draw_get_alpha();
	var _old_filter = gpu_get_texfilter();
	pls_draw_flush();
	gpu_set_blendmode(bm_normal);
	gpu_set_texfilter(true);
	draw_set_alpha(1);
	draw_set_colour(c_white);
	BYD_COLOR_FUNC;
	else image_blend = c_white;
	var _bw = sprite_get_width(game.bg);
	var _bh = sprite_get_height(game.bg);
	if (_bw <= 0 || _bh <= 0) {
		gpu_set_texfilter(_old_filter);
		draw_set_alpha(_old_alpha);
		draw_set_colour(_old_colour);
		gpu_set_blendmode(bm_normal);
		return;
	};
	var _area_w = room_width;
	var _area_h = room_height;
	var _area_x = 0;
	if (variable_global_exists("chart_view_width") && is_real(chart_view_width) && chart_view_width > 0) then _area_w = chart_view_width;
	if (variable_global_exists("chart_view_height") && is_real(chart_view_height) && chart_view_height > 0) then _area_h = chart_view_height;
	if (variable_global_exists("chart_view_left") && is_real(chart_view_left)) then _area_x = chart_view_left;
	// Cover the full room so letterbox sides match the play-area crop, but
	// keep the image center on the valid play area. Stretched draw ignores
	// sprite origin, which GX/runtime sprite_add sprites may not honor.
	var _sc = max(room_width / _bw, room_height / _bh);
	var _dw = _bw * _sc;
	var _dh = _bh * _sc;
	var _cx = _area_x + _area_w * 0.5;
	var _cy = _area_h * 0.5;
	draw_sprite_stretched_ext(game.bg, 0, _cx - _dw * 0.5, _cy - _dh * 0.5, _dw, _dh, image_blend, 1);
	gpu_set_texfilter(_old_filter);
	// Viewport dim is drawn later, on the chart surface only. This pass stays
	// the undimmed illustration so the letterbox keeps the plain blurred art.
	draw_set_alpha(_old_alpha);
	draw_set_colour(_old_colour);
	gpu_set_blendmode(bm_normal);
}

function chart_viewport_dim_draw() {
	if (!variable_global_exists("chart_surface_active") || !chart_surface_active) then return;
	if (!variable_global_exists("chart_view_left") || !is_real(chart_view_left)) then return;
	if (!variable_global_exists("chart_view_right") || !is_real(chart_view_right)) then return;
	if (!variable_global_exists("chart_view_height") || !is_real(chart_view_height)) then return;
	if (chart_mask_released()) then return;
	var _alpha = chart_background_dim_alpha();
	if (_alpha <= 0) then return;
	pls_draw_flush();
	chart_mask_scissor_set();
	var _old_colour = draw_get_colour();
	var _old_alpha = draw_get_alpha();
	// Colour darkens. Alpha stays as it is, so the viewport replace blit keeps
	// an opaque picture. Ordinary alpha blending writes a transparent black
	// layer, and that replace blit turns the whole viewport solid black.
	gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_zero, bm_one);
	draw_set_colour(c_black);
	draw_set_alpha(_alpha);
	draw_rectangle(chart_view_left, 0, chart_view_right, chart_view_height, false);
	pls_draw_flush();
	draw_set_alpha(_old_alpha);
	draw_set_colour(_old_colour);
	gpu_set_blendmode(bm_normal);
}

function chart_mask_side_dim_draw() {
	if (!instance_exists(oPlayTransition)) then return;
	var _transition = instance_find(oPlayTransition, 0);
	if (!variable_instance_exists(_transition, "end_cover_alpha")) then return;
	var _alpha = _transition.end_cover_alpha;
	if (_alpha <= 0) then return;
	if (!variable_global_exists("chart_view_left") || !is_real(chart_view_left)) then return;
	if (!variable_global_exists("chart_view_right") || !is_real(chart_view_right)) then return;
	var _span = clamp(real(_transition.end_cover_span ?? 0), 0, 1);
	var _frame_w = chart_frame_width();
	var _frame_h = chart_frame_height();
	// The letterbox lives outside the 16:9 chart view. Size the black to the
	// whole frame, not to chart_view, or the bars stay uncovered.
	var _left = lerp(chart_view_left, 0, _span);
	var _right = lerp(chart_view_right, _frame_w, _span);
	if (_right - _left <= 1) then return;
	pls_draw_flush();
	gpu_set_scissor(0, 0, _frame_w, _frame_h);
	var _old_colour = draw_get_colour();
	var _old_alpha = draw_get_alpha();
	gpu_set_blendmode(bm_normal);
	draw_set_colour(c_black);
	draw_set_alpha(_alpha);
	draw_rectangle(_left, 0, _right, _frame_h, false);
	pls_draw_flush();
	draw_set_alpha(_old_alpha);
	draw_set_colour(_old_colour);
	gpu_set_blendmode(bm_normal);
}

function chart_surface_begin() {
	globalvar chart_surface, chart_surface_active, chart_background_surface;
	chart_surface_active = false;
	return false;
}

function chart_surface_end() {
	globalvar chart_surface, chart_surface_active;
	if (!variable_global_exists("chart_surface_active") || !chart_surface_active) then return false;
	if (!variable_global_exists("chart_surface") || is_undefined(chart_surface) || !surface_exists(chart_surface)) {
		chart_surface_active = false;
		return false;
	};
	pls_draw_flush();
	surface_reset_target();
	gpu_set_blendmode(bm_normal);
	draw_set_colour(c_white);
	draw_set_alpha(1);
	draw_surface_part(chart_surface, chart_view_left, 0, chart_view_width, chart_view_height, chart_view_left, 0);
	pls_draw_flush();
	chart_surface_active = false;
	return true;
}

function chart_mask_scissor_set() {
	if (chart_mask_released()) then return;
	if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then return;
	if (!variable_global_exists("chart_view_width") || !is_real(chart_view_width) || chart_view_width <= 0) then return;
	if (!variable_global_exists("chart_view_left") || !is_real(chart_view_left)) then return;
	if (!variable_global_exists("chart_view_right") || !is_real(chart_view_right)) then return;
	if (!variable_global_exists("chart_view_height") || !is_real(chart_view_height) || chart_view_height <= 0) then return;
	var _left = floor(chart_view_left);
	var _width = max(1, ceil(chart_view_right) - _left);
	var _height = max(1, ceil(chart_view_height));
	gpu_set_scissor(_left, 0, _width, _height);
}

function chart_frame_width() {
	var _w = max(1, room_width);
	if (application_surface_is_enabled() && surface_exists(application_surface)) {
		_w = max(_w, surface_get_width(application_surface));
	};
	return max(_w, window_get_width(), display_get_gui_width());
}

function chart_frame_height() {
	var _h = max(1, room_height);
	if (application_surface_is_enabled() && surface_exists(application_surface)) {
		_h = max(_h, surface_get_height(application_surface));
	};
	return max(_h, window_get_height(), display_get_gui_height());
}

function chart_mask_scissor_clear() {
	gpu_set_scissor(0, 0, chart_frame_width(), chart_frame_height());
}

function chart_clip_shutdown() {
}
