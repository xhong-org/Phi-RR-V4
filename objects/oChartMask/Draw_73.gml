///@desc 绘制结束：把有效谱面视口合成回屏幕
if (chart_loading_silent()) then exit;
// 谱面表面这时还绑着。未刷新就 shader_reset，会丢掉这一帧的音符和打击特效。
// 捕获表面或谱面表面仍是目标时，必须先解开再复位，复位后再绑回去。
// 这处已经反复修过。不要在这里直接 shader_reset，也不要多一次 surface_reset_target。
pls_draw_flush();
var _mask_target = surface_get_target();
var _mask_held = surface_exists(_mask_target) && _mask_target != application_surface;
if (_mask_held) then surface_reset_target();
shader_reset();
if (_mask_held) then surface_set_target(_mask_target);
chart_mask_scissor_clear();
// 噪域要先合成进谱面，才能和音符一起参与全局遮挡、扭曲及发光。
if (!target_active || !surface_exists(surface_id)) then exit;
official_blocks_draw();
chart_mask_scissor_clear();
// 全屏着色器（没有 PhiZone targetRange）必须在贴回之前落到这张表面上。
// 不用 Draw GUI；暂停菜单画在这次贴回之后。
if (target_active && surface_exists(surface_id) && instance_exists(oRPEEffect)
	&& !chart_setting_on("disableChartShader")) {
	var _global_fx = noone;
	with (oRPEEffect) {
		if (!variable_instance_exists(id, "effect_boundary_role")) then _global_fx = id;
	};
	if (_global_fx != noone && is_array(_global_fx.effects_global) && array_length(_global_fx.effects_global) > 0) {
		var _global_allow = true;
		if (instance_exists(oPlayTransition)) {
			var _fx_state = instance_find(oPlayTransition, 0).state;
			_global_allow = (_fx_state == PLAY_TRANSITION_STATE.PLAYING || _fx_state == PLAY_TRANSITION_STATE.OUTRO);
		};
		var _global_stack = _global_fx.effect_capture_stack;
		// 转场允许且没有嵌套效果栈时，才在这里做全局着色器。
		if (_global_allow && (!is_array(_global_stack) || array_length(_global_stack) <= 0)) {
			pls_draw_flush();
			// 弹出绘制开始时绑定的目标。effect_render 不得改这个栈
			// （caller_was_bound = false），然后再绑一次遮罩，
			// 这样下面的 reset 仍然对应这一次 set。
			surface_reset_target();
			with (_global_fx) {
				var _present_key = "global-present";
				if (!struct_exists(external_draw_logged, _present_key)) {
					external_draw_logged[$ _present_key] = true;
					print($"[RPE Effect] Global shader present: count={array_length(effects_global)}, time={chart_time}, surface={surface_get_width(other.surface_id)}x{surface_get_height(other.surface_id)}");
				};
				effect_render(effects_global, other.surface_id, other.surface_id, false);
			};
			surface_set_target(surface_id);
		};
	};
};
// 版本信息留给完成合成后的独立层，不能画进这张会被退场压缩的谱面表面。
pls_draw_flush();
surface_reset_target();
target_active = false;
chart_surface_active = false;
// 开场动画之前表面可能是全新的。用那一帧空画面替换视口，
// 会在 oBG 已经画好的插图上打出一帧黑。这一帧先留着插图。
var _defer_composite = surface_born;
// 加载动画进行中时不要推迟合成。
if (_defer_composite && variable_global_exists("loading_animation_active") && global.loading_animation_active) {
	_defer_composite = false;
}
if (_defer_composite && instance_exists(oPlayTransition)) {
	var _transition_state = instance_find(oPlayTransition, 0).state;
	// 转场已经进入开场及之后，可以正常合成。
	if (_transition_state >= PLAY_TRANSITION_STATE.INTRO) then _defer_composite = false;
}
surface_born = false;
// 推迟时只重画插图并退出，不贴空的合成表面。
if (_defer_composite) {
	chart_draw_background(false);
	gpu_pop_state();
	exit;
}
gpu_set_blendmode(bm_normal);
draw_set_colour(c_white);
draw_set_alpha(1);
// 游玩模式里，绘制开始已经把 oBG 未压暗的插图画到这张表面上。
// 渲染采集在绘制结束读 D3D11 目标，遮罩必须在这里画，否则编码器只拿到压暗后的视口。
if (variable_global_exists("render_mode") && global.render_mode) {
	chart_draw_background(false);
};
gpu_set_blendmode_ext(bm_one, bm_zero);
shader_reset();
draw_set_colour(c_white);
draw_set_alpha(1);
// 噪区呈现可能留下小于成片的裁剪。贴回和后面的抓帧都要整张表面。
gpu_set_scissor(0, 0, max(1, room_width), max(1, room_height));
// 始终合成谱面视口。判定线比 16:9 区域更长；
// 拷整张表面会让超出部分画到两侧遮罩上。
var _copy_left = floor(chart_view_left);
var _copy_right = ceil(chart_view_right);
var _copy_width = max(1, _copy_right - _copy_left);
var _copy_height = max(1, chart_view_height);
var _outro_scale = 1;
var _outro_composite = false;
if (instance_exists(oPlayTransition)) {
	var _outro = instance_find(oPlayTransition, 0);
	_outro_composite = _outro.state == PLAY_TRANSITION_STATE.OUTRO;
	if (_outro.state >= PLAY_TRANSITION_STATE.OUTRO) then _outro_scale = _outro.end_xscale;
};
// 没开遮罩且拷贝宽度几乎等于表面时，改为整张贴回。
if (!chart_mask_enabled() && _copy_width >= surface_get_width(surface_id) - 1) {
	_copy_left = 0;
	_copy_width = max(1, surface_get_width(surface_id));
	_copy_height = max(1, surface_get_height(surface_id));
};
// 退场源里只有黑底和前景，以预乘透明度叠回未压缩的曲绘。
if (_outro_composite) then gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
if (_outro_scale > 0) {
	if (_outro_scale < 1) {
		var _copy_x = _copy_left + _copy_width * (1 - _outro_scale) * 0.5;
		draw_surface_part_ext(surface_id, _copy_left, 0, _copy_width, _copy_height,
			_copy_x, 0, _outro_scale, 1, c_white, 1);
	} else {
		draw_surface_part(surface_id, _copy_left, 0, _copy_width, _copy_height, _copy_left, 0);
	};
};
gpu_set_blendmode(bm_normal);
pls_draw_flush();
gpu_pop_state();
// pop 会把 scaleOnNotes 推进去的线宽剪刀还原。版本信息和帧率由最终叠层再画，这里先放开。
chart_mask_scissor_clear();
// HUD 留在压缩画面之外，继续使用原来的收缩和淡出。
if (instance_exists(oPlayTransition)) {
	var _hud_transition = instance_find(oPlayTransition, 0);
	if (_hud_transition.state == PLAY_TRANSITION_STATE.OUTRO
		&& instance_exists(_hud_transition.owner)) {
		with (_hud_transition.owner) {
			if (chart_hud_ready()) {
				draw_set_font(game.font);
				event_user(_draw_user_count);
			};
		};
	};
};
