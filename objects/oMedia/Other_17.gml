/// @description 中止播放
if (media_use_gx()) {
	if (gx_audio_kind == "js" && gx_js_handle > 0) {
		try { i_gx_audio_stop(gx_js_handle); } catch (stop_error) { delete(stop_error); };
		exit;
	};
	if (gx_audio_inst != -1) then audio_stop_sound(gx_audio_inst);
	gx_audio_inst = -1;
	exit;
};
if(channel > 0){
	fmod_channel_control_stop(channel);
	channel = -1;
};
