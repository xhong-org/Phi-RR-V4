///@desc 初始化
globalvar soundsList;
soundsList = (ds_map_create());

///@desc OGG 音频读取 (因为Android端的FMOD寄了 , 不得不写)
///@params name {String} 请输入文本
///@params file_path {String} 音频文件地址
// Return {Array}
function mus_system_sound_add(name , file_path ){
	if(!ds_exists(soundsList , ds_type_map)) then soundsList = (ds_map_create());
	if(ds_map_exists(soundsList , name)){
		show_debug_message($"[F-Sound] {name}(name) exists.");
		return([false]);
	};
	ds_map_add(soundsList , name , audio_create_stream(file_path));
	var s = (ds_map_find_value(soundsList , name));
	if(!s) { show_debug_message("[L-Sound] Failed."); return([false])};
	var length = (audio_sound_length(s));
	return([true , {mus_length : length , mus_id : s}]);
};

///@desc Release dynamically-created GameMaker audio streams and their map.
function mus_system_clean(){
	if(!variable_global_exists("soundsList") || !ds_exists(soundsList , ds_type_map)) then return;
	var sound_keys = (ds_map_keys_to_array(soundsList));
	for(var i = 0 ; i < array_length(sound_keys) ; i ++){
		var stream_id = (ds_map_find_value(soundsList , sound_keys[i]));
		if(audio_exists(stream_id)) then audio_destroy_stream(stream_id);
	};
	ds_map_destroy(soundsList);
	soundsList = -1;
};

func m_play(){
	with(oMedia){ event_user(2) };
	//event_perform_object( , ev_user2 , 0);
};

func m_pause(){
	with(oMedia){ event_user(3) };
	//event_perform_object(oMedia , ev_user3 , 0);
};

func m_resume(){
	with(oMedia){ event_user(4) };
	//event_perform_object(oMedia , ev_user4 , 0);
};

func m_clean(full = false){
	with(oMedia){ event_user(full ? 6 : 5) };
	//event_perform_object(oMedia , (!full ? ev_user5 : ev_user6) , 0);
};

func m_stop(){
	with(oMedia){ event_user(7) };
	//event_perform_object(oMedia , ev_user7 , 0);
};
