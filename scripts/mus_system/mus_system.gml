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

func m_seek_ms(_ms) {
	with (oMedia) {
		if (channel > 0) {
			fmod_channel_set_position(channel, max(0, real(_ms)), FMOD_TIMEUNIT.MS);
			position = max(0, real(_ms));
		};
	};
};

/// @desc Android: freeze the get_timer chart clock while the activity is in
/// the background, then snap FMOD to that frozen chart time on resume.
/// Returns true when the chart clock must not advance this step.
func chart_android_focus_step() {
	static os_suspended = false;
	if (os_type != os_android) then return false;
	if (variable_global_exists("render_mode") && global.render_mode) then return false;
	if (variable_instance_exists(id, "chart_exit_started") && chart_exit_started) then return false;
	if (!variable_global_exists("game") || !is_struct(game) || !is_array(game.__time)) then return false;
	if (real(game.__time[0]) <= 0) then return false;

	if (os_is_paused()) {
		if (!os_suspended) {
			os_suspended = true;
			if (!game.paused) {
				m_pause();
				array_set(game.__time, 2, get_timer());
			};
		};
		return true;
	};

	if (os_suspended) {
		os_suspended = false;
		if (!game.paused) {
			array_set(game.__time, 4, get_timer());
			game.Math.ptime();
			game.Math.ctime();
			m_seek_ms(real(game.__time[1]) * 1000);
			m_resume();
		};
	};
	return false;
};
