///@desc 创建 PEC 播放器、运行时和打击特效
window_set_caption($"{GAME_NAME}");

// 画在谱面合成之后，宽高比遮罩才是最终结果。
depth = DEPTH.HEF + 1;

if (os_browser == browser_not_a_browser) then gml_release_mode(true);

globalvar game , game_2 , _eff_c , combo , maxcombo , pec_bpm , fpsReal , PhiTime;

var time = get_timer();
bpm_count = 0;
offset_time = 0;


pec_bpm = 120;
fpsReal = 0;
combo = 0;
maxcombo = 0;
PhiTime = false;


game = (new Phigros());
chart_session_ensure();
chart_session_bind_paths();
if (chart_session_has_track()) {
        chart_session_apply_folder(game);
} else {
        // 没有选中谱面时退回示例。
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
game_2 = (new PEC());

// 创建 PEC 运行时并登记音符之前，先清掉上一局的打击音表。
if (variable_global_exists("render_mode") && global.render_mode) {
	global.render_hitsounds = [];
};

instance_create_depth(0,0,0,oBG);
instance_create_depth(0, 0, -12001, oBG_1);
instance_create_depth(0,0,0,oMedia , { "name" : (string_length(game.folder_chart.music) ? chart_in_path(game.folder_chart.music) : "") });

var pec_path = (string_length(game.folder_chart.chart) ? chart_path_join(InChartPath, game.folder_chart.chart) : "");
// 读谱失败就中止加载并回菜单。
if (!pec_reader_load(game_2, pec_path)) {
	show_debug_message($"[PEC] Failed to load: {pec_path}");
	chart_loading_animation_abort();
	room_goto(room_menu);
	exit;
};
skin_gameplay_ensure();
chart_load_flags_reset();
var _pec_render_mode = variable_global_exists("render_mode") && global.render_mode;
// 录像一次建完运行时，交互模式则分帧创建。
if (_pec_render_mode) {
	pec_create_runtime(game_2);
} else {
	pec_lines_begin(game_2);
	if (pec_lines_pump()) {
		pec_lines_finish();
		_chart_lines_frozen = true;
	} else {
		_chart_lines_building = true;
	};
};
instance_create_depth(0,0,DEPTH.BG - 1,oExtraPlay);

///@desc 特效对象创建前的空打击回调
///@returns {Bool} 恒为假，表示还没接上特效
_eff_c = (function(){ return(false); });
if (game.settings.useOldFX && !pls_is_gxgames() && !skin_active()) {
	instance_create_depth(0, 0, 0, oEffect);
	///@desc 在旧粒子系统上生成打击特效
	///@param {Real} _x 世界坐标 X
	///@param {Real} _y 世界坐标 Y
	///@param {Real} color 粒子颜色，默认浅金
	///@returns {Undefined} 无
	_eff_c = method(self, function(_x, _y, color = #ffeca0) {
		// 关闭打击特效时直接返回。
		if (!game.settings.enableHitEffect) then return;
		with (oEffect) {
			part_particles_create_color(p1, floor(_x), floor(_y), _hitFX, color, 1);
			part_particles_create_color(p1, floor(_x), floor(_y), part, color, 4);
		};
	});
} else {
	instance_create_depth(0, 0, 0, oEffectNew);
	_eff_c = eff_create;
};
if (variable_global_exists("chart_layer_mode") && global.chart_layer_mode) {
	if (instance_exists(oEffect)) then chart_set_instance_depth(oEffect, chart_layer_depth(7));
	if (instance_exists(oEffectNew)) then chart_set_instance_depth(oEffectNew, chart_layer_depth(7));
};

cameraZoom = false;
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
draw_set_font(game.font);
var _ui_font_size = max(1, font_get_size(draw_get_font()));
var _ui_name_width = max(1, string_width(string(game.folder_chart.name)));
// font_scales 不含窗口缩放，绘制时再乘一次，和其他界面元素一样。
var _ui_reference_scale = (47 / _ui_font_size);
var _ui_fit_scale = (((room_width / 2) - (80 * global_scales)) / _ui_name_width) / max(0.000001, global_scales);
font_scales = clamp(min(_ui_reference_scale, _ui_fit_scale), 0.2, 0.55);

_draw_user_count = 0;
_draw_fps_user_count = 0;
_step_fps_user_count = 0;
_re_fps = 1;
fps_more = 0;
refresh_count = 0;
if (!instance_exists(oPausedUI)) then instance_create_depth(0, 0, -1000000, oPausedUI, { owner: id });
event_user(2);

print($"Usage Times: {(get_timer() - time) / 1000}ms");

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
