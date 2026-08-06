/// @description 
    
if(!game.paused){
	game.Math.ctime();
	event_user(0);
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
if (chart_exit_started) {
	chart_exit_alpha = 1 - clamp((get_timer() - chart_exit_timer) / 500000, 0, 1);
	if (chart_exit_alpha <= 0 && !chart_exit_queued) {
		chart_exit_queued = true;
		m_clean(true);
		chart_session_cleanup(true);
		room_goto(room_menu);
	};
};
event_user(_step_fps_user_count);
