/// @description 读取
if(start){
	self[$ "success"] = undefined;
	event_user(8);
	if(!self[$ "isExists"]){
		//print("[F-Sound] No Exists.");	
		exit;
	};
};

track = -1;
track = (fmod_system_create());
resources_released = false;
fmod_system_select(track);
fmod_system_init(128 , FMOD_MODE.DEFAULT);

var audio_path = chart_file_readable_path(self.name);
if(use_stream){
	soundIndex = (fmod_system_create_stream(audio_path,FMOD_MODE.ACCURATETIME));	
}else{
	soundIndex = (fmod_system_create_sound(audio_path,FMOD_MODE.ACCURATETIME));
};

if(soundIndex){
	use_stream = true;
	position = 0;
	var length_sound = soundIndex;
	if (fmod_sound_get_num_sub_sounds(soundIndex) > 0) {
		var sub_sound = fmod_sound_get_sub_sound(soundIndex, 0);
		if (sub_sound) then length_sound = sub_sound;
	};
	playbackIndex = length_sound;
	length = (fmod_sound_get_length(length_sound,FMOD_TIMEUNIT.MS) * 1000);
	self[$ "success"] = true;
	print("[L-Sound] Done.");
	exit;
};

self[$ "success"] = false;
print("[L-Sound] Failed.");
