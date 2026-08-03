/// @description 中止播放
if(channel > 0){
	fmod_channel_control_stop(channel);
	channel = -1;
};
