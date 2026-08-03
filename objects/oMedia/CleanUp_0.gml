/// @description Release FMOD resources when the room or game ends.
if(!resources_released){
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
