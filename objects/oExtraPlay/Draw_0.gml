///@desc 绘制：先压暗插图，再把背景视频画在上面
// Phira 先画 background_dim，再画片段，只用片段自己的 dim。
// 若最后再画一次视口压暗，会把已经乘过 1-dim 的画面再压一层（例如再盖 0.6 的黑）。
chart_viewport_dim_draw();
if (!chart_setting_on("disableChartVideo")) {
	for (var video_i = 0; video_i < array_length(videos); video_i++) {
		// 有 z 或吸附判定线的视频不在这里画。
		if (is_real(videos[video_i].zIndex)) then continue;
		if (is_struct(videos[video_i].attach)) then continue;
		video_draw_index(video_i);
	};
};
