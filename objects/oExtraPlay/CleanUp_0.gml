///@desc 清理：关掉本控制器拥有的视频句柄和图层
if (variable_instance_exists(id, "video_layers") && is_array(video_layers)) {
	// 先拆分层实例。
	for (var _layer_i = 0; _layer_i < array_length(video_layers); _layer_i++) {
		if (instance_exists(video_layers[_layer_i])) then instance_destroy(video_layers[_layer_i]);
	};
	video_layers = [];
};
if (variable_instance_exists(id, "videos") && is_array(videos)) {
	video_close_all();
};
// 后端只在初始化成功时关闭。
if (video_backend_ready) {
	ffvideos_ext_shutdown();
	video_backend_ready = false;
};
if (variable_instance_exists(id, "effect_controller") && instance_exists(effect_controller)) {
	instance_destroy(effect_controller);
	effect_controller = -1;
};
