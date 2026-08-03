/// @description 清理并再次初始化(循环利用一下)
event_user(7);
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
print("[C-Sound] Clean.")

event_user(0);
