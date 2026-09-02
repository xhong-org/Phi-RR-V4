/// @description 恢复
if (media_use_gx()) {
	if (gx_audio_kind == "js" && gx_js_handle > 0) {
		try { i_gx_audio_resume(gx_js_handle); } catch (resume_error) { delete(resume_error); };
		exit;
	};
	if (gx_audio_inst != -1) then audio_resume_sound(gx_audio_inst);
	exit;
};
if(channel > 0) then fmod_channel_control_set_paused(channel , false);