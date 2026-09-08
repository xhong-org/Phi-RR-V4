/// @description 
window_set_caption($"{GAME_NAME}");

// Draw after the chart composition so the aspect mask is final.
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
game_2 = (new PEC());

// Clear the previous chart before PEC runtime creation schedules its notes.
if (variable_global_exists("render_mode") && global.render_mode) {
	global.render_hitsounds = [];
};

instance_create_depth(0,0,0,oBG);
instance_create_depth(0, 0, -12001, oBG_1);
instance_create_depth(0,0,0,oMedia , { "name" : (string_length(game.folder_chart.music) ? chart_in_path(game.folder_chart.music) : "") });

var pec_path = (string_length(game.folder_chart.chart) ? chart_path_join(InChartPath, game.folder_chart.chart) : "");
if (!pec_reader_load(game_2, pec_path)) {
	show_debug_message($"[PEC] Failed to load: {pec_path}");
	chart_loading_animation_abort();
	room_goto(room_menu);
	exit;
};
skin_gameplay_ensure();
chart_load_flags_reset();
var _pec_render_mode = variable_global_exists("render_mode") && global.render_mode;
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

_eff_c = (function(){ return(false); });
if (game.settings.useOldFX && !pls_is_gxgames() && !skin_active()) {
	instance_create_depth(0, 0, 0, oEffect);
	_eff_c = method(self, function(_x, _y, color = #ffeca0) {
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
// font_scales is the pre-global-scales factor; draw code applies the window
// scale once, just like the other HUD elements.
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
