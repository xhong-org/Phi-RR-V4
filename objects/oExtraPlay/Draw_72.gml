///@desc 绘制开始：在 GL 线程上创建 MediaCodec 输出表面
if (chart_setting_on("disableChartVideo")) then exit;
for (var video_i = 0; video_i < array_length(videos); video_i++) {
	// 没打开或已经出错的片段跳过。
	if (videos[video_i].handle < 0) then continue;
	var setup_status = ffvideos_ext_get_status(videos[video_i].handle);
	// 零尺寸绘制只为在 GL 线程上建输出表面。
	if (setup_status == FFVideosStatus.Error || setup_status == FFVideosStatus.Closed) then continue;
	ffvideos_ext_draw(videos[video_i].handle, 0, 0, 0, 0, 0, 0);
};
