/// @description
window_set_caption($"{GAME_NAME}");
// Draw after the chart composition so the aspect mask is final.
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
	chart_session_load_sample();
	chart_session_bind_paths();
	chart_session_apply_folder(game);
};
game.Resource();
// Configs() may overwrite folder_chart from ini; re-apply selected chart session.
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
// Seed BPM from the same normalized timeline used by parser and runtime.
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
game_1.CreateLines();
var _spatial_groups = game_1._note_spatial_groups;
var _spatial_group_count = array_length(_spatial_groups);
for (var _spatial_i = 0; _spatial_i < _spatial_group_count; _spatial_i++) {
	array_sort(_spatial_groups[_spatial_i].notes, function(a, b) {
		if (a.spatialFloor < b.spatialFloor) then return -1;
		if (a.spatialFloor > b.spatialFloor) then return 1;
		return 0;
	});
};
var _hold_groups = game_1._note_spatial_hold_groups;
var _hold_group_count = array_length(_hold_groups);
for (var _hold_group_i = 0; _hold_group_i < _hold_group_count; _hold_group_i++) {
	var _hold_group = _hold_groups[_hold_group_i];
	_hold_group.count = array_length(_hold_group.notes);
	_hold_group.originalNotes = array_create(_hold_group.count);
	array_copy(_hold_group.originalNotes, 0, _hold_group.notes, 0, _hold_group.count);
};
// Expose created RPE lines for note binding later.
if (!struct_exists(game_1, "line_list") || !is_array(game_1.line_list)) {
	game_1.line_list = [];
	with (oLine_1) array_add(game_1.line_list, id);
};


// Hit effect manager (same as oRender; required by judgeCalc -> _eff_c)
_eff_c = (function(){ return; });
if (game.settings.useOldFX && !pls_is_gxgames()) {
	instance_create_depth(0, 0, 0, oEffect);
	_eff_c = method(self, function(_x, _y, color = #ffeca0) {
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
cameraZoom = false;

// attachUI target slots: [x, y, color, alpha, rot, scaleX, scaleY]
// bindUI_attached marks which HUD keys are currently driven by a judge line
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
with (oLine_1) {
	if (is_attach_ui && instance_exists(other.id)) then other.play_transition_bound_ui[$ attach_ui_key] = true;
};

// UI draw prep (mirrors oRender)
draw_set_font(game.font);
var _ui_name_w = game.folder_chart.name;
if ((!is_string(_ui_name_w) || !string_length(_ui_name_w))
	&& is_struct(game_1.chart_info) && is_string(game_1.chart_info.name)) {
	_ui_name_w = game_1.chart_info.name;
};
var _ui_font_size = max(1, font_get_size(draw_get_font()));
var _ui_name_width = max(1, string_width(string(_ui_name_w)));
// font_scales is the pre-global-scales factor; draw code applies the window
// scale once, just like the other HUD elements.
var _ui_reference_scale = (47 / _ui_font_size);
var _ui_fit_scale = (((room_width / 2) - (80 * global_scales)) / _ui_name_width) / max(0.000001, global_scales);
font_scales = clamp(min(_ui_reference_scale, _ui_fit_scale), 0.2, 0.55);
bak_str_combo = (game.settings.comboString);
image_blend = c_white;

// default event enable flags (Other_12 will overwrite from settings)
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
// Hide chart objects behind the loading overlay. Do not deactivate judge
// lines: activate is deferred and would skip the next event_perform / Step.
chart_idle_behind_loading();
global.loading_render_ready = true;
chart_blur_bind_game(false);
if (pls_is_gxgames()) {
	chart_loading_animation_finish();
};
