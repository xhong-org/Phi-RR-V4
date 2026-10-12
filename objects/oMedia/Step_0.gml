///@desc 步进：刷新播放位置和时长
if (media_use_gx()) {
	// js 音频用毫秒位置；读到时长后通知谱面。
	if (gx_audio_kind == "js" && gx_js_handle > 0) {
		var js_ms = 0;
		try { js_ms = real(i_gx_audio_get_position_ms(gx_js_handle)); } catch (pos_error) { delete(pos_error); js_ms = 0; };
		position = js_ms;
		var js_len = 0;
		try { js_len = real(i_gx_audio_get_length_ms(gx_js_handle)); } catch (len_error) { delete(len_error); js_len = 0; };
		// 时长单位从毫秒换成与 FMOD 一致的微秒量级。
		if (js_len > 0) {
			length = js_len * 1000;
			if (is_undefined(self[$ "success"]) || !bool(self[$ "success"])) {
				self[$ "success"] = true;
				chart_media_on_length_ready(length);
			};
		};
		exit;
	};
	// 缓冲区或资源播放用秒再换成毫秒。
	if (variable_instance_exists(id, "gx_audio_inst") && gx_audio_inst != -1) {
		position = audio_sound_get_track_position(gx_audio_inst) * 1000;
		var src = (gx_audio_kind == "buffer") ? gx_buffer_sound : gx_audio_asset;
		if (src != -1 && audio_exists(src)) {
			var gx_len = audio_sound_length(src);
			if (gx_len > 0) then length = gx_len * 1000000;
		};
	};
	exit;
};
if (variable_instance_exists(id, "track") && track > 0) {
	fmod_system_select(track);
	fmod_system_update();
};
// FMOD 频道存在时读取毫秒位置。
if(channel > 0 && soundIndex){
	position = (fmod_channel_get_position(channel,FMOD_TIMEUNIT.MS));	
};
