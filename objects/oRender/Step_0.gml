/// @description 
if (variable_global_exists("loading_animator_finished") && global.loading_animator_finished) {
    if (!instance_exists(oChartMask)) then instance_create_depth(0, 0, -12000, oChartMask);
    instance_activate_object(oRPEEffect);
    instance_activate_object(oEffect);
    instance_activate_object(oEffectNew);
    if (!instance_exists(oPlayTransition)) then instance_create_depth(0, 0, -999999, oPlayTransition, { owner:id });
    global.loading_animator_finished = false;
};
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) exit;
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
