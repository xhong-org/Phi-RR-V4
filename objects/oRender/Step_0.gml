/// @description 
//if(game.settings.enableFPS) then window_set_caption($"{GAME_NAME} - FPS: {fps} / {fps_real}");
if(!game.paused){
	//print(array_length(game.__time));	
	game.Math.ctime();
	//print(game.__time);
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
