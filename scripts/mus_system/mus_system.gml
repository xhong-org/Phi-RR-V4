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

function chart_media_on_length_ready(_len_us) {
	if (!(is_real(_len_us) && is_finite(_len_us) && _len_us > 0)) then return;
	if (!instance_exists(oNote)) then return;
	var counted = 0;
	with (oNote) {
		if (!variable_instance_exists(id, "realHitTime") || !is_real(realHitTime)) then continue;
		if ((realHitTime * 1000000) <= _len_us) then counted++;
	};
	// Never clobber a already-valid official/RPE count with 0 (inactive notes).
	if (counted > 0) then maxcombo = counted;
}

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
		if (media_use_gx()) {
			if (gx_audio_kind == "js" && gx_js_handle > 0) {
				try { i_gx_audio_set_position_ms(gx_js_handle, max(0, real(_ms))); } catch (seek_error) { delete(seek_error); };
				position = max(0, real(_ms));
			} else if (gx_audio_kind == "buffer" && gx_buffer_sound != -1 && audio_exists(gx_buffer_sound)) {
				if (gx_audio_inst == -1 || !audio_exists(gx_audio_inst) || !audio_is_playing(gx_audio_inst)) {
					gx_audio_inst = audio_play_sound(gx_buffer_sound, 0, false);
				};
				if (gx_audio_inst != -1) then audio_sound_set_track_position(gx_audio_inst, max(0, real(_ms)) / 1000);
				position = max(0, real(_ms));
			} else if (gx_audio_inst != -1) {
				audio_sound_set_track_position(gx_audio_inst, max(0, real(_ms)) / 1000);
				position = max(0, real(_ms));
			};
		} else if (channel > 0) {
			fmod_channel_set_position(channel, max(0, real(_ms)), FMOD_TIMEUNIT.MS);
			position = max(0, real(_ms));
		};
	};
};

func gx_media_ensure_playing() {
	if (!pls_is_gxgames() || !instance_exists(oMedia)) then return;
	with (oMedia) {
		if (gx_audio_kind == "js" && gx_js_handle > 0) {
			try { i_gx_audio_resume(gx_js_handle); } catch (resume_error) { delete(resume_error); };
		} else if (gx_audio_kind == "buffer" && gx_buffer_sound != -1 && audio_exists(gx_buffer_sound)) {
			if (gx_audio_inst == -1 || !audio_exists(gx_audio_inst) || !audio_is_playing(gx_audio_inst)) {
				gx_audio_inst = audio_play_sound(gx_buffer_sound, 0, false);
			} else {
				audio_resume_sound(gx_audio_inst);
			};
		} else if (gx_audio_inst != -1) {
			audio_resume_sound(gx_audio_inst);
		};
	};
};

/// @desc Freeze the get_timer chart clock while Android/GX is in the
/// background, then snap audio to that frozen chart time on resume.
/// Returns true when the chart clock must not advance this step.
func chart_android_focus_step() {
	static os_suspended = false;
	static last_tick = -1;
	static last_chart_start = 0;
	var is_gx = pls_is_gxgames();
	if (os_type != os_android && !is_gx) then return false;
	if (variable_global_exists("render_mode") && global.render_mode) then return false;
	if (variable_instance_exists(id, "chart_exit_started") && chart_exit_started) then return false;
	if (!variable_global_exists("game") || !is_struct(game) || !is_array(game.__time)) then return false;
	if (real(game.__time[0]) <= 0) {
		last_tick = -1;
		os_suspended = false;
		last_chart_start = 0;
		return false;
	};

	var now = get_timer();
	// static last_tick survives room changes. A new chart must not absorb
	// minutes of menu time into __time[3].
	if (last_chart_start != game.__time[0]) {
		last_chart_start = game.__time[0];
		last_tick = now;
		os_suspended = false;
		return false;
	};
	if (last_tick < 0) then last_tick = now;
	var gap = now - last_tick;
	last_tick = now;

	var page_hidden = false;
	if (is_gx) {
		try { page_hidden = real(i_gx_page_hidden()) > 0; } catch (hidden_error) { delete(hidden_error); page_hidden = false; };
	};

	if (os_is_paused() || page_hidden) {
		if (!os_suspended) {
			os_suspended = true;
			if (!game.paused) {
				m_pause();
				array_set(game.__time, 2, now);
			};
		};
		return true;
	};

	// rAF stops in a background tab but get_timer() (performance.now) does not.
	// If Step never ran while hidden, recover the freeze as a pause gap.
	var resumed_gap = is_gx && !game.paused && gap > 400000;
	if (os_suspended || resumed_gap) {
		if (!os_suspended && resumed_gap) {
			array_set(game.__time, 2, now - gap);
		};
		os_suspended = false;
		if (!game.paused) {
			array_set(game.__time, 4, now);
			game.Math.ptime();
			game.Math.ctime();
			m_seek_ms(real(game.__time[1]) * 1000);
			gx_media_ensure_playing();
			m_resume();
		};
		last_tick = get_timer();
	};
	return false;
};
