///@desc 按设定帧数平滑刷新实际帧率
fps_more += fps_real;
refresh_count ++;
// 攒够采样次数再更新显示值。
if(refresh_count >= _re_fps) {
	fpsReal	= (fps_more / _re_fps);
	fps_more = 0;
	refresh_count = 0;
};