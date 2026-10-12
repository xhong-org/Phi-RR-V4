///@desc 创建 RPE 播放器、判定线和界面绑定槽
window_set_caption($"{GAME_NAME}");
// 画在谱面合成之后，宽高比遮罩才是最终结果。
depth = DEPTH.HEF + 1;
if (os_browser == browser_not_a_browser) then gml_release_mode(false);
globalvar game , game_1 , _eff_c , combo , maxcombo , rpe_bpm , fpsReal , PhiTime;
bpm_count = 0;
rpe_bpm = 140;
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
};
fpsReal = 0;
show_debug_message("[oRender_1] Creating RPE state");
game_1 = (new RPE());
show_debug_message("[oRender_1] RPE state created");
if (variable_global_exists("render_mode") && global.render_mode) {
	global.render_hitsounds = [];
};
if (!is_struct(game_1.chart_info)) then game_1.chart_info = { name:"", level:"", offset:0, meta_offset:0, info_offset:0, song:"", background:"" };

var _chart_rel = "";
if (is_struct(game) && struct_exists(game, "folder_chart")) {
	var _folder_chart = game.folder_chart;
	if (is_struct(_folder_chart) && struct_exists(_folder_chart, "chart")) {
		var _chart_value = _folder_chart[$ "chart"];
		if (is_string(_chart_value)) then _chart_rel = _chart_value;
	};
};
var _chart_path = string_length(_chart_rel) ? chart_path_join(InChartPath, _chart_rel) : "";
show_debug_message($"[oRender_1] RPE chart path: {_chart_path}");
var _rpe_loaded = game_1.Reader(_chart_path);
// 读谱失败就中止加载并回菜单。
if (!_rpe_loaded) {
	show_debug_message("[oRender_1] RPE chart loading failed");
	chart_loading_animation_abort();
	room_goto(room_menu);
	exit;
};
var _bg = "";
if (is_struct(game) && struct_exists(game, "folder_chart")) {
	var _folder_chart_bg = game.folder_chart;
	if (is_struct(_folder_chart_bg) && struct_exists(_folder_chart_bg, "bg")) {
		var _bg_value = _folder_chart_bg[$ "bg"];
		if (is_string(_bg_value)) then _bg = _bg_value;
	};
};
if ((!is_string(_bg) || !string_length(_bg))
	&& variable_global_exists("chart_session") && is_struct(global.chart_session)
	&& is_string(global.chart_session.image_file) && string_length(global.chart_session.image_file)) {
	_bg = global.chart_session.image_file;
	game.folder_chart.bg = _bg;
};
if (is_string(_bg) && string_length(_bg)) then game.Background(chart_in_path(_bg));

instance_create_depth(0,0,0,oBG);
instance_create_depth(0, 0, -12001, oBG_1);
instance_create_depth(0,0,0,oMedia , { "name" : (string_length(game.folder_chart.music) ? chart_in_path(game.folder_chart.music) : "") });
instance_create_depth(0,0,DEPTH.BG - 1,oExtraPlay);
// 用解析和运行同一条时间轴的第一段 BPM。
var _initial_bpm_timeline = game_1.Math.ensureBpmTimeline();
if (is_array(_initial_bpm_timeline) && array_length(_initial_bpm_timeline) > 0) {
	rpe_bpm = real(_initial_bpm_timeline[0].bpm);
};
if (!struct_exists(game_1, "line_list")) then game_1.line_list = [];
game_1._note_activation_records = {};
game_1._note_spatial_group_map = {};
game_1._note_spatial_groups = [];
game_1._note_spatial_hold_group_map = {};
game_1._note_spatial_hold_groups = [];
skin_gameplay_ensure();
chart_load_flags_reset();
var _rpe_render_mode = variable_global_exists("render_mode") && global.render_mode;
// 录像一次建完判定线，交互模式则分帧创建。
if (_rpe_render_mode) {
	game_1.CreateLines();
	rpe_lines_post_bind();
} else {
	rpe_lines_begin();
	if (rpe_lines_pump()) {
		rpe_lines_finish();
		rpe_lines_post_bind();
	} else {
		_chart_lines_building = true;
	};
};


// 打击特效回调。judgeCalc 会调用 _eff_c，先放一个空实现。
///@desc 特效对象创建前的空打击回调
///@returns {Undefined} 无
_eff_c = (function(){ return; });
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
			_x = floor(_x);
			_y = floor(_y);
			part_particles_create_color(p1, _x, _y, _hitFX, color, 1);
			part_particles_create_color(p1, _x, _y, part, color, 4);
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

// attachUI 槽：[x, y, 颜色, 透明度, 旋转, 缩放 X, 缩放 Y]。
// bindUI_attached 标记哪些界面键正被判定线驱动。
bindUI = {
	"pause" : (array_create(7, 0)),
	"combonumber" : (array_create(7, 0)),
	"combo" : (array_create(7, 0)),
	"score" : (array_create(7, 0)),
	"bar" : (array_create(7, 0)),
	"name" : (array_create(7, 0)),
	"level" : (array_create(7, 0))
};
bindUI_attached = {
	"pause" : false,
	"combonumber" : false,
	"combo" : false,
	"score" : false,
	"bar" : false,
	"name" : false,
	"level" : false
};
play_transition_bound_ui = {
	"pause" : false,
	"combonumber" : false,
	"combo" : false,
	"score" : false,
	"bar" : false,
	"name" : false,
	"level" : false
};
if (!_chart_lines_building) {
	with (oLine_1) {
		if (is_attach_ui && instance_exists(other.id)) then other.play_transition_bound_ui[$ attach_ui_key] = true;
	};
	if (!_rpe_render_mode) {
		rpe_lines_freeze_after_init();
		_chart_lines_frozen = true;
	};
};

// 界面字体和曲名缩放，算法与官谱播放器一致。
draw_set_font(game.font);
var _ui_name_w = game.folder_chart.name;
if ((!is_string(_ui_name_w) || !string_length(_ui_name_w))
	&& is_struct(game_1.chart_info) && is_string(game_1.chart_info.name)) {
	_ui_name_w = game_1.chart_info.name;
};
var _ui_font_size = max(1, font_get_size(draw_get_font()));
var _ui_name_width = max(1, string_width(string(_ui_name_w)));
// font_scales 不含窗口缩放，绘制时再乘一次，和其他界面元素一样。
var _ui_reference_scale = (47 / _ui_font_size);
var _ui_fit_scale = (((room_width / 2) - (80 * global_scales)) / _ui_name_width) / max(0.000001, global_scales);
font_scales = clamp(min(_ui_reference_scale, _ui_fit_scale), 0.2, 0.55);
bak_str_combo = (game.settings.comboString);
image_blend = c_white;

// 默认事件开关，Other_12 会按设置覆盖。
_draw_user_count = 0;
_draw_fps_user_count = 0;
_step_fps_user_count = 0;
_re_fps = 1;
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
if (!instance_exists(oPausedUI)) then instance_create_depth(0, 0, -1000000, oPausedUI, { owner: id });
event_user(2);

if (variable_global_exists("render_mode") && global.render_mode) {
	instance_create_depth(0, 0, -9999999, oVideoRenderer);
};
// 特效先藏到加载层后面。判定线和音符要等初始化完成才冻结。
chart_idle_behind_loading();
if (!_chart_lines_building) {
	global.loading_render_ready = true;
	chart_blur_bind_game(false);
	if (pls_is_gxgames()) {
		chart_loading_animation_finish();
	};
};
