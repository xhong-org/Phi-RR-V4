/// @description 
if (variable_global_exists("render_mode") && global.render_mode) exit;
if (chart_exit_started) then exit;
// The pause overlay resumes through its countdown. Do not let the same
// key event run a second resume/ptime compensation during that transition.
if (instance_exists(oPausedUI)) {
	var pause_ui = instance_find(oPausedUI, 0);
	if (variable_instance_exists(pause_ui, "retry_waiting") && pause_ui.retry_waiting) then exit;
};
print(game.__time[1]);
if(game.__time[0] > 0){
	if(game.paused){
		//audio_resume_sound(music);
		m_resume();
		array_set(game.__time , 4 , get_timer());
		game.Math.ptime();
	}else{
		//audio_pause_sound(music);
		m_pause();
		array_set(game.__time , 2 , get_timer());
	};
	
	game.paused = (!(game.paused));
};
