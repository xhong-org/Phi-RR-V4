/// @description 
if (chart_load_step(oLine_2, pec_lines_pump, pec_lines_finish, pec_lines_force_init, pec_sync_note_activation)) then exit;
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) exit;
var chart_os_hold = chart_android_focus_step();
if(!game.paused && !chart_os_hold){
	game.Math.ctime();
	event_user(0);
	if (variable_global_exists("game_2") && is_struct(game_2)
		&& bool(game_2._note_activation_enabled ?? false) && is_array(game_2._notes)) {
		var _pec_now = game.__time[1] - real(game_2.chart.offsetSeconds ?? 0);
		var _pec_notes = game_2._notes;
		var _pec_count = array_length(_pec_notes);
		var _pec_index = clamp(real(game_2._note_activation_index ?? 0), 0, _pec_count);
		while (_pec_index < _pec_count && _pec_notes[_pec_index].activateSec <= _pec_now) {
			chart_note_activate(_pec_notes[_pec_index].id);
			_pec_index++;
		};
		game_2._note_activation_index = _pec_index;
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
event_user(_step_fps_user_count);
