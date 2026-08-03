/// @description 完全销毁
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

print("[C-Sound] Full Clean.")
instance_destroy();
