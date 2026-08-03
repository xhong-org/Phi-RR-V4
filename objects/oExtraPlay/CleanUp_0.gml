/// @description Close the global video handle owned by this extra controller.
if (video_handle >= 0) then ffvideos_close(video_handle);
video_handle = -1;
if (video_backend_ready) {
	ffvideos_shutdown();
	video_backend_ready = false;
};
if (variable_instance_exists(id, "effect_controller") && instance_exists(effect_controller)) {
	instance_destroy(effect_controller);
	effect_controller = -1;
};
