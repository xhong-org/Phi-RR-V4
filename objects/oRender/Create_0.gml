/// @description
window_set_caption($"{GAME_NAME}");
if (os_browser == browser_not_a_browser) then gml_release_mode(true);
globalvar game , _eff_c , combo , maxcombo , fpsReal , PhiTime;
fpsReal = fps_real;
combo = 0;
maxcombo = 0;
game = (new Phigros());
PhiTime = false;
chart_session_ensure();
chart_session_bind_paths();
if (chart_session_has_track()) {
        chart_session_apply_folder(game);
} else {
        // fallback to sample/config path
        chart_session_load_sample();
        chart_session_bind_paths();
        chart_session_apply_folder(game);
};
game.Resource();
// Configs() may overwrite folder_chart from ini; re-apply selected chart session.
if (chart_session_has_track()) {
        chart_session_apply_folder(game);
        chart_session_bind_paths();
        var _bg = game.folder_chart.bg;
        if ((!is_string(_bg) || !string_length(_bg))
                && variable_global_exists("chart_session") && is_struct(global.chart_session)
                && is_string(global.chart_session.image_file) && string_length(global.chart_session.image_file)) {
                _bg = global.chart_session.image_file;
                game.folder_chart.bg = _bg;
        };
        if (is_string(_bg) && string_length(_bg)) {
                game.Background(chart_in_path(_bg));
        };
};
print(game.folder_chart , game.settings.enableDebug);
var chart_path = (string_length(game.folder_chart.chart) ? chart_path_join(InChartPath, game.folder_chart.chart) : "");
// Start each render with an empty schedule. CreateLines populates it for this chart.
if (variable_global_exists("render_mode") && global.render_mode) {
	global.render_hitsounds = [];
};
if (!game.Reader(chart_path)) {
	show_debug_message($"[Official] Failed to load chart: {chart_path}");
	chart_loading_animation_abort();
	room_goto(room_menu);
	exit;
};

//var success = (game.PhiTool.TrasformType([2 , 4] , [1 , 1]));
//if(success) then game.PhiTool.SaveTrack($"{game_save_id}123.json");

//game.background()
// Draw after the chart composition so the aspect mask is final.
depth = DEPTH.HEF + 1;
if(game.settings.showBG) then instance_create_depth(0,0,0,oBG);
instance_create_depth(0, 0, -12001, oBG_1);

instance_create_depth(0,0,0,oMedia , { "name" : (string_length(game.folder_chart.music) ? chart_in_path(game.folder_chart.music) : "") });
instance_create_depth(0,0,DEPTH.BG - 1,oExtraPlay);

game.Sort();
skin_gameplay_ensure();
chart_load_flags_reset();
var _official_render_mode = variable_global_exists("render_mode") && global.render_mode;
if (_official_render_mode) {
	game.CreateLines();
} else {
	official_lines_begin();
	if (official_lines_pump()) {
		official_lines_finish();
		_chart_lines_frozen = true;
	} else {
		_chart_lines_building = true;
	};
};

draw_set_font(game.font);
font_scales = clamp(0.6 * ((room_width / 2) / (string_width(game.folder_chart.name) * 0.6 + 40)) , 0.2 , 0.55);

if (game.settings.useOldFX && !pls_is_gxgames() && !skin_active()) {
	instance_create_depth(0 , 0 , 0 , oEffect);
	_eff_c = (method(self , function(_x , _y  , color = #ffeca0){
		if(!game.settings.enableHitEffect) then return;
		//var color = ();
		with(oEffect){
			_x = (floor(_x));
			_y = (floor(_y));
			part_particles_create_color(p1,_x,_y,_hitFX,color,1);
			part_particles_create_color(p1,_x,_y,part,color,4);
		};
	}));
}else{
	instance_create_depth(0 , 0 , 0 , oEffectNew);
	_eff_c = eff_create;	
};
//print(array_length(game.__time));
//print($"Time: {game.math.dtime(game.time[1] , 0 , 0)}")
//print(struct_get_names(game.settings))
//maxcombo = (instance_number(oNote));
print(game.notes , game.settings.enableDebug);
event_user(2);
//game_set_speed(60 , gamespeed_fps);
fps_more = 0;
refresh_count = 0;
chart_playback_teardown_reset();
chart_exit_started = false;
chart_exit_timer = 0;
chart_exit_alpha = 1;
chart_exit_queued = false;
play_transition_active = false;
play_transition_pause_y = 0;
play_transition_name_y = 0;
play_transition_level_y = 0;
play_transition_score_y = 0;
play_transition_ui_alpha = 1;
play_transition_bar_alpha = 1;
play_transition_bg_alpha = 1;
bak_str_combo = (game.settings.comboString);
print($"str3: {game.settings.comboString}");

image_blend = c_white;
if (!instance_exists(oPausedUI)) then instance_create_depth(0, 0, -1000000, oPausedUI, { owner: id });
if (variable_global_exists("render_mode") && global.render_mode) {
	instance_create_depth(0, 0, -9999999, oVideoRenderer);
};
chart_idle_behind_loading();
if (!_chart_lines_building) {
	global.loading_render_ready = true;
	chart_blur_bind_game(false);
	if (pls_is_gxgames()) {
		chart_loading_animation_finish();
	};
};

//print(load_line_csv());
//var arr = [0 , 1 , 2];
//array_add(arr , [ 1 , 2 , 3 , 4 , 5 , 8] , true);
//print(arr);
