/// @description 播放
if (variable_global_exists("render_mode") && global.render_mode) then exit;
if(soundIndex){
	var source = (!is_undefined(playbackIndex) ? playbackIndex : soundIndex);
	channel = (fmod_system_play_sound(source , false));
	fmod_channel_control_set_volume(channel , 1);
};
