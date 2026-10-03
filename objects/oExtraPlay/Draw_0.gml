/// @description Dim the illustration, then draw background videos over it.
// Phira paints background_dim first and the clip after that, using only the
// clip's own dim. Drawing the viewport dim last multiplied that dim again
// (0.6 black on top of a clip already scaled by 1-dim).
chart_viewport_dim_draw();
if (!chart_setting_on("disableChartVideo")) {
	for (var video_i = 0; video_i < array_length(videos); video_i++) {
		if (is_real(videos[video_i].zIndex)) then continue;
		if (is_struct(videos[video_i].attach)) then continue;
		video_draw_index(video_i);
	};
};
