/// @description 播放
if (variable_global_exists("render_mode") && global.render_mode) then exit;
if (media_use_gx()) {
	if (gx_audio_kind == "js" && gx_js_handle > 0) {
		try { i_gx_audio_play(gx_js_handle); } catch (play_error) { delete(play_error); };
		exit;
	};
	if (gx_audio_kind == "buffer" && gx_buffer_sound != -1 && audio_exists(gx_buffer_sound)) {
		gx_audio_inst = audio_play_sound(gx_buffer_sound, 0, false);
		exit;
	};
	if (gx_audio_asset != -1 && audio_exists(gx_audio_asset)) then gx_audio_inst = audio_play_sound(gx_audio_asset, 0, false);
	exit;
};
if(soundIndex){
	var source = (!is_undefined(playbackIndex) ? playbackIndex : soundIndex);
	channel = (fmod_system_play_sound(source , false));
	fmod_channel_control_set_volume(channel , 1);
};
