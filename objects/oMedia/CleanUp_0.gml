///@desc 清理：房间或游戏结束时释放音频资源
if(!resources_released){
	// GX 走自己的释放，不再动 FMOD。
	if (media_use_gx()) {
		gx_media_release(id);
		resources_released = true;
		exit;
	};
	if(channel > 0){
		fmod_channel_control_stop(channel);
		channel = -1;
	};
	if(soundIndex){
		fmod_sound_release(soundIndex);
		soundIndex = undefined;
	};
	if(track > 0){
		fmod_system_close(track);
		fmod_system_release(track);
		track = -1;
	};
	resources_released = true;
};
