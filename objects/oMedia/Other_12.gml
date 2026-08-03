/// @description 播放
if (variable_global_exists("render_mode") && global.render_mode) then exit;
if(soundIndex){
	channel = (fmod_system_play_sound(soundIndex , false));
	fmod_channel_control_set_volume(channel , 1);
};
