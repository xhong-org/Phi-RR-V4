/// @description 
window_set_caption($"{GAME_NAME}");

depth = DEPTH.DEBUG;

gml_release_mode(true);

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
                game.Background(InChartPath + _bg);
        };
};
game_2 = (new PEC());

instance_create_depth(0,0,0,oBG);
instance_create_depth(0,0,0,oMedia , { "name" : (string_length(game.folder_chart.music) ? (InChartPath + game.folder_chart.music) : "") });

var pec_path = (string_length(game.folder_chart.chart) ? (InChartPath + game.folder_chart.chart) : "");
if (!pec_reader_load(game_2, pec_path)) {
	show_debug_message($"[PEC] Failed to load: {pec_path}");
	room_goto(room_menu);
	exit;
};
pec_create_runtime(game_2);
instance_create_depth(0,0,DEPTH.BG - 1,oExtraPlay);
//game_2.CreateLines();

_eff_c = (function(){ return(false); });
if (game.settings.useOldFX) {
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
chart_exit_started = false;
chart_exit_timer = 0;
chart_exit_alpha = 1;
chart_exit_queued = false;
font_scales = clamp(0.6*((room_width/2)/(string_width(string(game.folder_chart.name))*0.6+40)), 0.2, 0.55);

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
	instance_create_depth(0, 0, -2000000000, oVideoRenderer);
} else {
	alarm[0] = 300;
};
