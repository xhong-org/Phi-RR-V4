/// @description Close every video handle owned by this extra controller.
if (variable_instance_exists(id, "video_layers") && is_array(video_layers)) {
	for (var _layer_i = 0; _layer_i < array_length(video_layers); _layer_i++) {
		if (instance_exists(video_layers[_layer_i])) then instance_destroy(video_layers[_layer_i]);
	};
	video_layers = [];
};
if (variable_instance_exists(id, "videos") && is_array(videos)) {
	for (var _video_i = 0; _video_i < array_length(videos); _video_i++) {
		if (surface_exists(videos[_video_i].clip_surface)) then surface_free(videos[_video_i].clip_surface);
		videos[_video_i].clip_surface = -1;
		if (videos[_video_i].handle >= 0) then ffvideos_ext_close(videos[_video_i].handle);
		videos[_video_i].handle = -1;
	};
};
if (video_backend_ready) {
	ffvideos_ext_shutdown();
	video_backend_ready = false;
};
if (variable_instance_exists(id, "effect_controller") && instance_exists(effect_controller)) {
	instance_destroy(effect_controller);
	effect_controller = -1;
};
