/// @description Shared chart viewport and Phira-style aspect mask helpers.
/// @param {real} room_w
/// @param {real} room_h
function chart_view_refresh(_room_w, _room_h) {
	globalvar chart_view_left, chart_view_width, chart_view_height, chart_view_right;
	globalvar chart_aspect_ratio;
	var _aspect = chart_aspect_ratio;
	if (!is_real(_aspect) || !is_finite(_aspect) || _aspect <= 0) {
		_aspect = 16 / 9;
		chart_aspect_ratio = _aspect;
	};
	chart_view_height = max(1, _room_h);
	chart_view_width = min(max(1, _room_w), chart_view_height * _aspect);
	// Pixel-align the effective viewport so composition, clipping and the
	// aspect mask share the same edge. Fractional coordinates leave a dark
	// seam under MSAA in render mode.
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

function chart_draw_background(_dim = true) {
	if (!(variable_global_exists("game") && is_struct(game) && is_struct(game.settings) && game.settings.showBG)) then return;
	if (!asset_sprite_valid(game.bg)) then return;
	// Effects and video extensions may leave a non-standard blend mode active.
	// The background dim must use ordinary source-alpha blending.
	var _old_colour = draw_get_colour();
	var _old_alpha = draw_get_alpha();
	draw_flush();
	gpu_set_blendmode(bm_normal);
	draw_set_alpha(1);
	draw_set_colour(c_white);
	BYD_COLOR_FUNC;
	else image_blend = c_white;
	var _bw = sprite_get_width(game.bg);
	var _bh = sprite_get_height(game.bg);
	if (_bw <= 0 || _bh <= 0) {
		draw_set_alpha(_old_alpha);
		draw_set_colour(_old_colour);
		gpu_set_blendmode(bm_normal);
		return;
	};
	var _sx = room_width / _bw;
	var _sy = room_height / _bh;
	var _sc = max(_sx, _sy);
	var _transition_alpha = 1;
	if (instance_exists(oPlayTransition)) {
		var _transition = instance_find(oPlayTransition, 0);
		if (instance_exists(_transition.owner) && _transition.owner.play_transition_active) {
			_transition_alpha = _transition.owner.play_transition_bg_alpha;
		};
	};
	draw_sprite_ext(game.bg, 0, room_width * 0.5, room_height * 0.5, _sc, _sc, 0, image_blend, 1);
	// Dim only the valid chart viewport, never the full room. The final
	// application-surface background pass skips this so the chart surface's
	// single dim pass is not compounded.
	if (_dim) {
		draw_set_colour(c_black);
		draw_set_alpha(0.6 * _transition_alpha);
		draw_rectangle(chart_view_left, 0, chart_view_right, chart_view_height, false);
	};
	draw_set_alpha(_old_alpha);
	draw_set_colour(_old_colour);
	gpu_set_blendmode(bm_normal);
}

function chart_clip_init() {
	globalvar chart_clip_ready, chart_clip_context, chart_clip_original_state, chart_clip_state;
	if (chart_clip_ready) then return true;
	if (os_type != os_windows || !extension_exists("ID3D11")) then return false;
	var _info = os_get_info();
	if (!ds_map_exists(_info, "video_d3d11_device") || !ds_map_exists(_info, "video_d3d11_context") || !ds_map_exists(_info, "video_d3d11_swapchain")) then return false;
	if (!id3d11_is_initialized()) {
		if (!__id3d11_bootstrap_raw(
			string(_info[? "video_d3d11_device"]),
			string(_info[? "video_d3d11_context"]),
			string(_info[? "video_d3d11_swapchain"]))) then return false;
	};

	chart_clip_context = id3d11_get_context_handle();
	var _device = id3d11_get_device_handle();
	if (chart_clip_context == 0 || _device == 0) then return false;

	chart_clip_original_state = id3d11_device_context_rs_get_state(chart_clip_context);
	var _desc;
	if (chart_clip_original_state != 0) {
		_desc = id3d11_rasterizer_state_get_desc(chart_clip_original_state);
	} else {
		_desc = new ID3D11RasterizerDesc();
		_desc.fillMode = ID3D11FillMode.Solid;
		_desc.cullMode = ID3D11CullMode.Back;
		_desc.depthClipEnable = true;
	};
	_desc.scissorEnable = true;
	var _created = id3d11_device_create_rasterizer_state(_device, _desc);
	id3d11_handle_release(_device);
	if (_created.hresult < 0 || _created.handle == 0) then return false;
	chart_clip_state = _created.handle;
	chart_clip_ready = true;
	return true;
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
	draw_flush();
	surface_reset_target();
	gpu_set_blendmode(bm_normal);
	draw_set_colour(c_white);
	draw_set_alpha(1);
	draw_surface_part(chart_surface, chart_view_left, 0, chart_view_width, chart_view_height, chart_view_left, 0);
	draw_flush();
	chart_surface_active = false;
	return true;
}

function chart_clip_begin() {
	globalvar chart_clip_ready, chart_clip_context, chart_clip_state;
	if (!chart_clip_init()) then return false;
	draw_flush();
	var _rect = new ID3D11Rect();
	_rect.left = floor(chart_view_left);
	_rect.top = 0;
	_rect.right = ceil(chart_view_right);
	_rect.bottom = ceil(chart_view_height);
	id3d11_device_context_rs_set_state(chart_clip_context, chart_clip_state);
	id3d11_device_context_rs_set_scissor_rects(chart_clip_context, [_rect]);
	return true;
}

function chart_clip_end() {
	globalvar chart_clip_ready, chart_clip_context, chart_clip_original_state;
	if (!chart_clip_ready) then return false;
	draw_flush();
	id3d11_device_context_rs_set_state(chart_clip_context, chart_clip_original_state);
	return true;
}

function chart_clip_shutdown() {
	globalvar chart_clip_ready, chart_clip_context, chart_clip_original_state, chart_clip_state;
	if (!chart_clip_ready) then return;
	chart_clip_end();
	if (chart_clip_state != 0) then id3d11_handle_release(chart_clip_state);
	if (chart_clip_original_state != 0) then id3d11_handle_release(chart_clip_original_state);
	if (chart_clip_context != 0) then id3d11_handle_release(chart_clip_context);
	chart_clip_state = 0;
	chart_clip_original_state = 0;
	chart_clip_context = 0;
	chart_clip_ready = false;
}
