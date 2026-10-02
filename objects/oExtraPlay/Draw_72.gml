/// @description Create the MediaCodec output surface on the GL thread.
if (chart_setting_on("disableChartVideo")) then exit;
for (var video_i = 0; video_i < array_length(videos); video_i++) {
	if (videos[video_i].handle < 0) then continue;
	var setup_status = ffvideos_ext_get_status(videos[video_i].handle);
	if (setup_status == FFVideosStatus.Error || setup_status == FFVideosStatus.Closed) then continue;
	ffvideos_ext_draw(videos[video_i].handle, 0, 0, 0, 0, 0, 0);
};
