///@desc 用户事件 6：完全销毁
event_user(7);
// 释放后销毁实例。
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

print("[C-Sound] Full Clean.")
instance_destroy();
