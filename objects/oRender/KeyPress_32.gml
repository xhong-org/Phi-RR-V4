/// @description 
if (chart_exit_started) then exit;
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
}else{
	alarm[0] = 1;	
};
