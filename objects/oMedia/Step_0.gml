/// @description 
if (variable_instance_exists(id, "track") && track > 0) {
	fmod_system_select(track);
	fmod_system_update();
};
if(channel > 0 && soundIndex){
	position = (fmod_channel_get_position(channel,FMOD_TIMEUNIT.MS));	
};
