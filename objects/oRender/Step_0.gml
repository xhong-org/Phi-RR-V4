/// @description 
if (chart_load_step(oLine, official_lines_pump, official_lines_finish, official_lines_force_init, official_sync_note_activation)) then exit;
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) exit;
//if(game.settings.enableFPS) then window_set_caption($"{GAME_NAME} - FPS: {fps} / {fps_real}");
var chart_os_hold = chart_android_focus_step();
if(!game.paused && !chart_os_hold){
	game.Math.ctime();
	if (is_struct(game) && bool(game._note_activation_enabled ?? false) && is_array(game._notes)) {
		var _off_now = game.__time[1];
		var _off_notes = game._notes;
		var _off_count = array_length(_off_notes);
		var _off_index = clamp(real(game._note_activation_index ?? 0), 0, _off_count);
		while (_off_index < _off_count && _off_notes[_off_index].activateSec <= _off_now) {
			chart_note_activate(_off_notes[_off_index].id);
			_off_index++;
		};
		game._note_activation_index = _off_index;
	};
}elif(game.paused && game.__time[0] > 0){
		
};
if (!(variable_global_exists("render_mode") && global.render_mode)
	&& !chart_exit_started && game.__time[0] > 0 && instance_exists(oMedia)) {
	var exit_media = instance_find(oMedia, 0);
	if (exit_media.length > 0 && game.__time[4] >= exit_media.length) {
		chart_exit_started = true;
		chart_exit_timer = get_timer();
		chart_exit_alpha = 1;
		game.paused = true;
		m_pause();
	};
};
//if(game.__time[1] >= 97.20 && game.__time[1] <= 121.00){
//	PhiTime = true;
//	game.settings.comboString = "PhiTime!!!";
//}
//else {
//	PhiTime = false;
//	game.settings.comboString = bak_str_combo;
//}

event_user(_step_fps_user_count);
//print(delta_time);
