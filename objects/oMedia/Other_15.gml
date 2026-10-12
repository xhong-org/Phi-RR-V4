///@desc 用户事件 5：清理并再次初始化，便于循环利用
event_user(7);
// 先停播再按平台释放，然后重新初始化。
if (media_use_gx()) {
	gx_media_release(id);
} else {
	if(soundIndex){
		fmod_sound_release(soundIndex);
		soundIndex = undefined;
	};
	if(track > 0){
		fmod_system_close(track);
		fmod_system_release(track);
		track = -1;
	};
};
resources_released = true;
print("[C-Sound] Clean.")

event_user(0);
