/// @description Release frame and encoder resources.
if (encoder_started && !encoder_finished) video_renderer_finish();
audio_master_gain(1);
