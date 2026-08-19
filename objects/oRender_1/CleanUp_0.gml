/// @description Release RPE and shared chart resources on room exit.
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
	// Inactive notes are outside normal instance iteration; reactivate for room cleanup.
	instance_activate_object(oNote_1);
	with (oLine_1) {
		if (variable_instance_exists(id, "paint_surface") && surface_exists(paint_surface)) {
			surface_free(paint_surface);
			paint_surface = -1;
		};
	};
	if (struct_exists(game_1, "Texture") && is_struct(game_1.Texture)) {
		var _texture_names = struct_get_names(game_1.Texture);
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
				for (var _gfi = 0; _gfi < array_length(_gif_data.frames); _gfi++) {
					var _gif_sprite = _gif_data.frames[_gfi];
					if (sprite_exists(_gif_sprite)) then sprite_delete(_gif_sprite);
				};
			};
		};
		game_1.Gif = {};
	};
	if (struct_exists(game_1, "HitSounds") && is_struct(game_1.HitSounds)) {
		if (instance_exists(oMedia)) {
			var _media = instance_find(oMedia, 0);
			if (_media.track > 0) then fmod_system_select(_media.track);
		};
		var _hit_names = struct_get_names(game_1.HitSounds);
		for (var _hi = 0; _hi < array_length(_hit_names); _hi++) {
			var _hit_sound = game_1.HitSounds[$ _hit_names[_hi]];
			if (_hit_sound > 0) then fmod_sound_release(_hit_sound);
		};
		game_1.HitSounds = {};
	};
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
if(variable_global_exists("_eff_c")) then _eff_c = (function(){ return(false); });
mus_system_clean();
chart_default_resources_unload();
LogUninit();
