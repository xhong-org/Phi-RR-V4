/// @description Refresh FPS
fps_more += fps_real;
refresh_count ++;
if(refresh_count >= _re_fps) {
	fpsReal	= (fps_more / _re_fps);
	fps_more = 0;
	refresh_count = 0;
};
