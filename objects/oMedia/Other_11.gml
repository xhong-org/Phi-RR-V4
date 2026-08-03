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

if(use_stream){
	soundIndex = (fmod_system_create_stream(self.name,FMOD_MODE.DEFAULT));	
}else{
	soundIndex = (fmod_system_create_sound(self.name,FMOD_MODE.DEFAULT));
};

if(soundIndex){
	use_stream = true;
	position = 0;
	length = (fmod_sound_get_length(soundIndex,FMOD_TIMEUNIT.MS) * 1000);
	self[$ "success"] = true;
	print("[L-Sound] Done.");
	exit;
};

self[$ "success"] = false;
print("[L-Sound] Failed.");
