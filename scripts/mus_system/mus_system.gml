// 初始化全局音效表
globalvar soundsList;
soundsList = (ds_map_create());

///@desc 按名称登记一条音频流
///@param {String} name 音效名称
///@param {String} file_path 音频文件地址
///@returns {Array} 成功时为真和音频信息，失败时只含假
function mus_system_sound_add(name , file_path ){
	if(!ds_exists(soundsList , ds_type_map)) then soundsList = (ds_map_create());
	// 同名音效已存在则不再创建
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

///@desc 释放动态创建的音频流并销毁音效表
///@returns {Undefined} 无
function mus_system_clean(){
	if(!variable_global_exists("soundsList") || !ds_exists(soundsList , ds_type_map)) then return;
	var sound_keys = (ds_map_keys_to_array(soundsList));
	// 先销毁每条流，再销毁映射
	for(var i = 0 ; i < array_length(sound_keys) ; i ++){
		var stream_id = (ds_map_find_value(soundsList , sound_keys[i]));
		if(audio_exists(stream_id)) then audio_destroy_stream(stream_id);
	};
	ds_map_destroy(soundsList);
	soundsList = -1;
};

///@desc 音频时长就绪后，按仍落在曲内的音符重算最大连击
///@param {Real} _len_us 音频时长，单位微秒
///@returns {Undefined} 无
function chart_media_on_length_ready(_len_us) {
	if (!(is_real(_len_us) && is_finite(_len_us) && _len_us > 0)) then return;
	if (!instance_exists(oNote)) then return;
	var counted = 0;
	// 只统计判定时间仍落在音频长度内的音符
	with (oNote) {
		if (!variable_instance_exists(id, "realHitTime") || !is_real(realHitTime)) then continue;
		if ((realHitTime * 1000000) <= _len_us) then counted++;
	};
	// 计数为 0 时不覆盖已经有效的官谱或 RPE 音符数
	if (counted > 0) then maxcombo = counted;
}

///@desc 通知媒体对象开始播放
///@returns {Undefined} 无
func m_play(){
	with(oMedia){ event_user(2) };
	//event_perform_object( , ev_user2 , 0);
};

///@desc 通知媒体对象暂停
///@returns {Undefined} 无
func m_pause(){
	with(oMedia){ event_user(3) };
	//event_perform_object(oMedia , ev_user3 , 0);
};

///@desc 通知媒体对象继续播放
///@returns {Undefined} 无
func m_resume(){
	with(oMedia){ event_user(4) };
	//event_perform_object(oMedia , ev_user4 , 0);
};

///@desc 通知媒体对象清理，可选完全清理
///@param {Bool} full 为真时做完全清理
///@returns {Undefined} 无
func m_clean(full = false){
	with(oMedia){ event_user(full ? 6 : 5) };
	//event_perform_object(oMedia , (!full ? ev_user5 : ev_user6) , 0);
};

///@desc 通知媒体对象停止
///@returns {Undefined} 无
func m_stop(){
	with(oMedia){ event_user(7) };
	//event_perform_object(oMedia , ev_user7 , 0);
};

///@desc 把媒体跳到指定毫秒
///@param {Real} _ms 目标位置，单位毫秒
///@returns {Undefined} 无
func m_seek_ms(_ms) {
	with (oMedia) {
		// GX 按音频种类定位，否则走 FMOD 声道
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

///@desc 确保 GX 音频在恢复后仍处于播放
///@returns {Undefined} 无
func gx_media_ensure_playing() {
	if (!pls_is_gxgames() || !instance_exists(oMedia)) then return;
	with (oMedia) {
		// 网页音频直接续播，缓冲音频缺实例时重新播放
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

///@desc 安卓或 GX 进后台时冻结核对时钟，回到前台再把音频对齐
///@returns {Bool} 本步谱面时钟不得前进时为真
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
	// 静态计时会跨房间保留。新谱不能把菜单里的时间算进暂停间隔。
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

	// 后台标签会停掉 rAF，但 get_timer 仍在走。若隐藏期间没有 Step，就把这段空档当成暂停。
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
