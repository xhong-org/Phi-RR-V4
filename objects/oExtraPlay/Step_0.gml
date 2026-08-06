/// @description Sync FFVideos playback to the RPE chart clock.
var chart_offset = chart_extra_offset_seconds();
video_chart_time = game.__time[1] - chart_offset;
if (video_chart_time < video_last_chart_time - 0.01) {
	video_completed = -1;
	if (video_handle >= 0) then ffvideos_close(video_handle);
	video_handle = -1;
	video_index = -1;
};
video_last_chart_time = video_chart_time;
var desired_index = -1;
for (var video_i = 0; video_i < array_length(videos); video_i++) {
	if (video_chart_time >= videos[video_i].startTime
		&& video_chart_time < videos[video_i].endTime
		&& video_i != video_completed) then desired_index = video_i;
};

if (desired_index != video_index) {
	if (video_handle >= 0) then ffvideos_close(video_handle);
	video_handle = -1;
	video_index = desired_index;
	video_error_logged = false;
	if (video_backend_ready && video_index >= 0 && file_exists(videos[video_index].path)) {
		video_handle = ffvideos_open(videos[video_index].path);
		if (video_handle >= 0) then ffvideos_set_volume(video_handle, 0);
	};
};

if (video_index < 0 || video_handle < 0) then exit;
videos[video_index].alpha.value = sample_anim(videos[video_index].alpha, video_chart_time);
videos[video_index].dim.value = sample_anim(videos[video_index].dim, video_chart_time);
var status = ffvideos_get_status(video_handle);
if (status == FFVideosStatus.Error) {
	if (!video_error_logged) {
		print($"[FFVideos] Playback failed: {ffvideos_get_error(video_handle)}");
		video_error_logged = true;
	};
	exit;
};
if (status == FFVideosStatus.Closed || status == FFVideosStatus.Preparing) then exit;

var target_ms = max(0, (video_chart_time - videos[video_index].startTime) * 1000);
if (variable_global_exists("render_mode") && global.render_mode) {
	if (!ffvideos_prepare_frame(video_handle, target_ms, 10000)) {
		if (!video_error_logged) {
			print($"[FFVideos] Offline frame preparation failed: {ffvideos_get_error(video_handle)}");
			video_error_logged = true;
		};
	};
	return;
};
if (game.paused) {
	if (status == FFVideosStatus.Playing) then ffvideos_pause(video_handle);
	if (abs(target_ms - ffvideos_get_position(video_handle)) > 16) then ffvideos_seek(video_handle, target_ms);
	return;
};

if (status == FFVideosStatus.Paused) {
	if (abs(target_ms - ffvideos_get_position(video_handle)) > 50) then ffvideos_seek(video_handle, target_ms);
	ffvideos_play(video_handle);
};
if (status == FFVideosStatus.Playing && abs(target_ms - ffvideos_get_position(video_handle)) > 250) then ffvideos_seek(video_handle, target_ms);
var duration_ms = ffvideos_get_duration(video_handle);
if (duration_ms > 0 && target_ms >= duration_ms) {
	ffvideos_close(video_handle);
	video_handle = -1;
	video_completed = video_index;
	video_index = -1;
};
