///@desc 创建官谱播放器、谱面对象和打击特效
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
        // 没有选中谱面时退回示例配置。
        chart_session_load_sample();
        chart_session_bind_paths();
        chart_session_apply_folder(game);
};
game.Resource();
// Configs 可能用 ini 覆盖 folder_chart，这里再写回选中的会话。
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
// 每次渲染从空的打击音表开始，CreateLines 再填这一局。
if (variable_global_exists("render_mode") && global.render_mode) {
	global.render_hitsounds = [];
};
// 读谱失败就中止加载并回菜单。
if (!game.Reader(chart_path)) {
	show_debug_message($"[Official] Failed to load chart: {chart_path}");
	chart_loading_animation_abort();
	room_goto(room_menu);
	exit;
};

//var success = (game.PhiTool.TrasformType([2 , 4] , [1 , 1]));
//if(success) then game.PhiTool.SaveTrack($"{game_save_id}123.json");

//game.background()
// 画在谱面合成之后，宽高比遮罩才是最终结果。
depth = DEPTH.HEF + 1;
if(game.settings.showBG) then instance_create_depth(0,0,0,oBG);
instance_create_depth(0, 0, -12001, oBG_1);

instance_create_depth(0,0,0,oMedia , { "name" : (string_length(game.folder_chart.music) ? chart_in_path(game.folder_chart.music) : "") });
instance_create_depth(0,0,DEPTH.BG - 1,oExtraPlay);

game.Sort();
skin_gameplay_ensure();
chart_load_flags_reset();
var _official_render_mode = variable_global_exists("render_mode") && global.render_mode;
// 录像一次建完判定线，交互模式则分帧创建。
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
	///@desc 在旧粒子系统上生成打击特效
	///@param {Real} _x 世界坐标 X
	///@param {Real} _y 世界坐标 Y
	///@param {Real} color 粒子颜色，默认浅金
	///@returns {Undefined} 无
	_eff_c = (method(self , function(_x , _y  , color = #ffeca0){
		// 关闭打击特效时直接返回。
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
// 判定线已经建完，但超大噪域还没收完时，先不让加载界面离场。
if (!_chart_lines_building) then official_block_notify_load_ready();

//print(load_line_csv());
//var arr = [0 , 1 , 2];
//array_add(arr , [ 1 , 2 , 3 , 4 , 5 , 8] , true);
//print(arr);
