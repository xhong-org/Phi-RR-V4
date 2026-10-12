///@desc 离开房间时释放 RPE 纹理、字体和共享资源
chart_clip_shutdown();
if (variable_global_exists("chart_surface") && !is_undefined(chart_surface) && surface_exists(chart_surface)) then surface_free(chart_surface);
if (variable_global_exists("chart_surface")) then chart_surface = -1;
if (variable_global_exists("chart_background_surface") && !is_undefined(chart_background_surface)
	&& surface_exists(chart_background_surface)) then surface_free(chart_background_surface);
if (variable_global_exists("chart_background_surface")) then chart_background_surface = -1;
if (os_type == os_windows && extension_exists("I_Parallel")) rpe_worker_shutdown();
if (variable_instance_exists(id, "_rpe_worker_hierarchy") && buffer_exists(_rpe_worker_hierarchy)) buffer_delete(_rpe_worker_hierarchy);
if (variable_instance_exists(id, "_rpe_worker_input") && buffer_exists(_rpe_worker_input)) buffer_delete(_rpe_worker_input);
if (variable_instance_exists(id, "_rpe_worker_output") && buffer_exists(_rpe_worker_output)) buffer_delete(_rpe_worker_output);
_rpe_worker_hierarchy = -1;
_rpe_worker_input = -1;
_rpe_worker_output = -1;
if(variable_global_exists("game") && !is_undefined(game)){
	game.Clean(true);
	game = undefined;
};
if(variable_global_exists("game_1") && !is_undefined(game_1)){
	// 未激活音符不在普通实例迭代里，清理前先重新激活。
	instance_activate_object(oNote_1);
	with (oLine_1) {
		if (variable_instance_exists(id, "paint_surface") && surface_exists(paint_surface)) {
			surface_free(paint_surface);
			paint_surface = -1;
		};
	};
	if (struct_exists(game_1, "Texture") && is_struct(game_1.Texture)) {
		var _texture_names = struct_get_names(game_1.Texture);
		// 删掉本局加载的自定义纹理。
		for (var _ti = 0; _ti < array_length(_texture_names); _ti++) {
			var _texture_sprite = game_1.Texture[$ _texture_names[_ti]];
			if (sprite_exists(_texture_sprite)) then sprite_delete(_texture_sprite);
		};
		game_1.Texture = {};
	};
	if (struct_exists(game_1, "Gif") && is_struct(game_1.Gif)) {
		var _gif_names = struct_get_names(game_1.Gif);
		for (var _gi = 0; _gi < array_length(_gif_names); _gi++) {
			var _gif_data = game_1.Gif[$ _gif_names[_gi]];
			if (is_struct(_gif_data) && is_array(_gif_data.frames)) {
				// 逐帧释放 GIF 精灵。
				for (var _gfi = 0; _gfi < array_length(_gif_data.frames); _gfi++) {
					var _gif_sprite = _gif_data.frames[_gfi];
					if (sprite_exists(_gif_sprite)) then sprite_delete(_gif_sprite);
				};
			};
		};
		game_1.Gif = {};
	};
	chart_playback_release_hitsounds();
	if (struct_exists(game_1, "Fonts") && is_struct(game_1.Fonts)) {
		var _font_names = struct_get_names(game_1.Fonts);
		for (var _fi = 0; _fi < array_length(_font_names); _fi++) {
			var _font = game_1.Fonts[$ _font_names[_fi]];
			if (_font != -1 && font_exists(_font)) then font_delete(_font);
		};
		game_1.Fonts = {};
	};
	game_1.chart = undefined;
	game_1.line_list = [];
	game_1._notes = [];
	game_1 = undefined;
};
///@desc 清掉全局打击特效回调
///@returns {Bool} 恒为假，表示不再生成特效
if(variable_global_exists("_eff_c")) then _eff_c = (function(){ return(false); });
mus_system_clean();
skin_gameplay_unload();
chart_default_resources_unload();
LogUninit();
process_mem_trim_later();
