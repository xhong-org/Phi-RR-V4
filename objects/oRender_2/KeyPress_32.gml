/// @description Pause or resume PEC playback.
if (chart_exit_started) then exit;
// The pause overlay owns the delayed resume transition.
if (instance_exists(oPausedUI)) {
	var pause_ui = instance_find(oPausedUI, 0);
	if (variable_instance_exists(pause_ui, "retry_waiting") && pause_ui.retry_waiting) then exit;
};
if (game.__time[0] > 0) {
	if (game.paused) {
		m_resume();
		array_set(game.__time, 4, get_timer());
		game.Math.ptime();
	} else {
		m_pause();
		array_set(game.__time, 2, get_timer());
	};
	game.paused = !game.paused;
};
