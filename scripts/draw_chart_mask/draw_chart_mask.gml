// 谱面视口与 Phira 风格宽高比遮罩
///@desc 判断设置是否启用了谱面遮罩表面
///@returns {Bool} 已启用表面时为真
function chart_mask_enabled() {
	var s = undefined;
	// 优先局内设置，其次全局设置，最后读设置存储
	if (variable_global_exists("game") && is_struct(game) && is_struct(game.settings)) {
		s = game.settings;
	} else if (variable_global_exists("pls_settings") && is_struct(global.pls_settings)) {
		s = global.pls_settings;
	} else {
		s = settings_store();
	};
	return is_struct(s) && bool(s.enableSurface ?? false);
}

///@desc 判断过场是否已经放开遮罩
///@returns {Bool} 遮罩已释放时为真
function chart_mask_released() {
	if (!chart_mask_enabled() || !instance_exists(oPlayTransition)) then return false;
	var _transition = instance_find(oPlayTransition, 0);
	return variable_instance_exists(_transition, "mask_released") && _transition.mask_released;
}

///@desc 判断是否进入结算或离场过场
///@returns {Bool} 正在结束游玩时为真
function chart_play_ending() {
	if (instance_exists(oSettlement)) then return true;
	if (!instance_exists(oPlayTransition)) then return false;
	var _transition = instance_find(oPlayTransition, 0);
	if (!variable_instance_exists(_transition, "state")) then return false;
	// 离场开始到结束之前都算正在收尾
	return _transition.state >= PLAY_TRANSITION_STATE.OUTRO
		&& _transition.state < PLAY_TRANSITION_STATE.FINISHED;
}

///@desc 计算背景压暗透明度
///@returns {Real} 结合过场后的压暗透明度
function chart_background_dim_alpha() {
	var _transition_alpha = 1;
	if (instance_exists(oPlayTransition)) {
		var _transition = instance_find(oPlayTransition, 0);
		if (instance_exists(_transition.owner) && variable_instance_exists(_transition.owner, "play_transition_active")
			&& _transition.owner.play_transition_active) {
			_transition_alpha = _transition.owner.play_transition_bg_alpha;
		};
	};
	// 基础压暗再乘过场透明度
	return 0.6 * _transition_alpha;
}

///@desc 按房间尺寸刷新谱面有效视口
///@param {Real} _room_w 房间宽度
///@param {Real} _room_h 房间高度
///@returns {Undefined} 无
function chart_view_refresh(_room_w, _room_h) {
	globalvar chart_view_left, chart_view_width, chart_view_height, chart_view_right;
	globalvar chart_aspect_ratio;
	chart_view_height = max(1, _room_h);
	var _aspect = chart_aspect_ratio;
	if (!is_real(_aspect) || !is_finite(_aspect) || _aspect <= 0) {
		_aspect = 16 / 9;
		chart_aspect_ratio = _aspect;
	};
	// 高度保持窗口高度，只改宽度：更宽时裁到高度乘宽高比。
	// 坐标仍按宽除以 1350、高除以 900，不再额外适配。
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

///@desc 宽高比遮罩入口，两侧留给背景，这里不涂黑边
///@param {Real} _room_w 房间宽度
///@param {Real} _room_h 房间高度
///@returns {Undefined} 无
function draw_chart_mask(_room_w , _room_h){
	// 遮罩是画在整个应用表面上的未压暗插图。谱面只覆盖有效视口，两侧应保持可见。
	return;
};

///@desc 在 GX 上重试尚未完成的背景模糊
///@returns {Undefined} 无
function chart_background_retry_blur() {
	if (!pls_is_gxgames()) then return;
	if (!variable_global_exists("game") || !is_struct(game)) then return;
	if (!bool(game[$ "bg_blur_pending"] ?? false)) then return;
	var tries = real(game[$ "bg_blur_tries"] ?? 0);
	// 多次仍失败就放弃，避免一直重试
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
	// 与加载动画相同：文件路径、10 次迭代，GX 端最多 4 次。
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

///@desc 按视口铺满绘制谱面背景
///@param {Bool} _dim 是否参与压暗流程
///@returns {Undefined} 无
function chart_draw_background(_dim = true) {
	if (pls_is_gxgames()) {
		chart_blur_bind_game(true);
		chart_background_retry_blur();
	} else if (variable_global_exists("game") && is_struct(game) && !asset_sprite_valid(game.bg)) {
		chart_blur_bind_game(false);
	};
	if (!(variable_global_exists("game") && is_struct(game) && is_struct(game.settings) && game.settings.showBG)) then return;
	if (!asset_sprite_valid(game.bg)) then return;
	// 特效和视频可能留下非标准混合。背景必须用普通源透明度混合。
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
	// 铺满整个房间，使两侧黑边和游玩区裁切一致，画面中心仍对准有效区域。
	// 拉伸绘制会忽略精灵原点，运行时加载的精灵不一定遵守原点。
	var _sc = max(room_width / _bw, room_height / _bh);
	var _dw = _bw * _sc;
	var _dh = _bh * _sc;
	var _cx = _area_x + _area_w * 0.5;
	var _cy = _area_h * 0.5;
	draw_sprite_stretched_ext(game.bg, 0, _cx - _dw * 0.5, _cy - _dh * 0.5, _dw, _dh, image_blend, 1);
	gpu_set_texfilter(_old_filter);
	// 视口压暗稍后只画在谱面表面上。这一遍保持未压暗，黑边才是普通模糊图。
	draw_set_alpha(_old_alpha);
	draw_set_colour(_old_colour);
	gpu_set_blendmode(bm_normal);
}

///@desc 提交当前混合模式，避免视口压暗后的混合被错误保存
///@returns {Undefined} 无
function chart_gpu_blend_commit() {
	// 混合模式可能要到下一次绘制才真正提交。视频会保存实际绑定的混合再写回。
	// 视口压暗后若仍保留目标透明度，着色器层被清成全透明，音符就无法进入合成。
	var _inside_capture = false;
	if (instance_exists(oRPEEffect)) {
		with (oRPEEffect) {
			if (!variable_instance_exists(id, "effect_boundary_role")
				&& variable_instance_exists(id, "effect_capture_stack")
				&& is_array(effect_capture_stack)
				&& array_length(effect_capture_stack) > 0) {
				_inside_capture = true;
			};
		};
	};
	var _colour = draw_get_colour();
	var _alpha = draw_get_alpha();
	gpu_set_blendmode_ext(bm_zero, bm_one);
	// 捕获层保留目标透明度，普通绘制则恢复标准混合
	if (_inside_capture) {
		gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
	} else {
		gpu_set_blendmode(bm_normal);
	};
	draw_set_colour(c_black);
	draw_set_alpha(0);
	draw_rectangle(0, 0, 1, 1, false);
	pls_draw_flush();
	draw_set_colour(_colour);
	draw_set_alpha(_alpha);
}

///@desc 只在谱面视口上压暗背景
///@returns {Undefined} 无
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
	// 颜色变暗，透明度保持原样，替换贴回时画面仍不透明。
	// 普通透明混合会写出透明黑，替换贴回后整块视口会变成纯黑。
	gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_zero, bm_one);
	draw_set_colour(c_black);
	draw_set_alpha(_alpha);
	draw_rectangle(chart_view_left, 0, chart_view_right, chart_view_height, false);
	pls_draw_flush();
	draw_set_alpha(_old_alpha);
	draw_set_colour(_old_colour);
	gpu_set_blendmode(bm_normal);
	chart_gpu_blend_commit();
}

///@desc 在谱面两侧绘制离场遮盖
///@returns {Undefined} 无
function chart_mask_side_dim_draw() {
	shader_reset();
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
	// 黑边在 16:9 视口之外。遮盖要按整帧计算，否则两侧盖不住。
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

///@desc 开始谱面表面绘制；当前实现直接跳过
///@returns {Bool} 恒为假，表示没有切入表面
function chart_surface_begin() {
	globalvar chart_surface, chart_surface_active, chart_background_surface;
	chart_surface_active = false;
	return false;
}

///@desc 结束谱面表面并把有效视口贴回
///@returns {Bool} 成功贴回时为真
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
	// 只贴回有效视口，两侧不从这张表面覆盖
	draw_surface_part(chart_surface, chart_view_left, 0, chart_view_width, chart_view_height, chart_view_left, 0);
	pls_draw_flush();
	chart_surface_active = false;
	return true;
}

///@desc 把裁剪区域设成谱面有效视口
///@returns {Undefined} 无
function chart_mask_scissor_set() {
	// 遮罩已放开或仍在加载动画时不裁剪
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

///@desc 取应用表面、窗口和界面宽度中的较大值
///@returns {Real} 当前帧宽度
function chart_frame_width() {
	var _w = max(1, room_width);
	if (application_surface_is_enabled() && surface_exists(application_surface)) {
		_w = max(_w, surface_get_width(application_surface));
	};
	return max(_w, window_get_width(), display_get_gui_width());
}

///@desc 取应用表面、窗口和界面高度中的较大值
///@returns {Real} 当前帧高度
function chart_frame_height() {
	var _h = max(1, room_height);
	if (application_surface_is_enabled() && surface_exists(application_surface)) {
		_h = max(_h, surface_get_height(application_surface));
	};
	return max(_h, window_get_height(), display_get_gui_height());
}

///@desc 把裁剪区域恢复成整帧
///@returns {Undefined} 无
function chart_mask_scissor_clear() {
	gpu_set_scissor(0, 0, chart_frame_width(), chart_frame_height());
}

///@desc 关闭谱面裁剪；当前无额外清理
///@returns {Undefined} 无
function chart_clip_shutdown() {
}
