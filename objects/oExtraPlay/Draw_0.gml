/// @description Draw background videos. A zIndex clip is drawn by its own layer.
if (!chart_setting_on("disableChartVideo")) {
	for (var video_i = 0; video_i < array_length(videos); video_i++) {
		if (is_real(videos[video_i].zIndex)) then continue;
		if (is_struct(videos[video_i].attach)) then continue;
		video_draw_index(video_i);
	};
};
chart_viewport_dim_draw();
