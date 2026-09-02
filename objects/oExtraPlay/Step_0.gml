/// @description Sync FFVideos playback to the RPE chart clock.
if (!video_backend_ready && pls_is_gxgames() && array_length(videos) > 0) {
	video_backend_ready = gx_video_available();
	if (video_backend_ready) then print("[GXVideo] HTMLVideo backend ready");
};
var chart_offset = chart_extra_offset_seconds();
video_chart_time = game.__time[1] - chart_offset;
if (video_chart_time < video_last_chart_time - 0.01) {
	video_completed = -1;
	if (video_handle >= 0) then ffvideos_ext_close(video_handle);
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
	if (video_handle >= 0) then ffvideos_ext_close(video_handle);
	video_handle = -1;
	video_index = desired_index;
	video_error_logged = false;
};
if (video_backend_ready && video_index >= 0 && video_handle < 0 && !video_error_logged) {
	var video_path = chart_file_readable_path(videos[video_index].path);
	var video_exists = gx_media_source_exists(video_path) || gx_media_source_exists(videos[video_index].path);
	print($"[FFVideos] Open request: path={video_path}, exists={video_exists}, host={gx_media_host_path_for(video_path)}");
	if (video_exists) {
		video_handle = ffvideos_ext_open(video_path);
		print($"[FFVideos] Open result: handle={video_handle}, error={ffvideos_ext_get_error(video_handle)}");
		if (video_handle >= 0) then ffvideos_ext_set_volume(video_handle, 0);
		else video_error_logged = true;
	} else {
		print($"[FFVideos] Video file missing: {video_path}");
		video_error_logged = true;
	};
};

if (video_index < 0 || video_handle < 0) then exit;
videos[video_index].alpha.value = sample_anim(videos[video_index].alpha, video_chart_time);
videos[video_index].dim.value = sample_anim(videos[video_index].dim, video_chart_time);
var status = ffvideos_ext_get_status(video_handle);
if (status == FFVideosStatus.Error) {
	if (!video_error_logged) {
		print($"[FFVideos] Playback failed: {ffvideos_ext_get_error(video_handle)}");
		video_error_logged = true;
	};
	exit;
};
if (status == FFVideosStatus.Closed) then exit;
if (os_is_paused()) {
	if (status == FFVideosStatus.Playing) then ffvideos_ext_pause(video_handle);
	video_os_paused = true;
	exit;
};
if (video_os_paused) {
	video_os_paused = false;
	video_error_logged = false;
};
if (status == FFVideosStatus.Preparing) then exit;

var target_ms = max(0, (video_chart_time - videos[video_index].startTime) * 1000);
if (variable_global_exists("render_mode") && global.render_mode) {
	if (!ffvideos_ext_prepare_frame(video_handle, target_ms, 10000)) {
		if (!video_error_logged) {
			print($"[FFVideos] Offline frame preparation failed: {ffvideos_ext_get_error(video_handle)}");
			video_error_logged = true;
		};
	};
	return;
};
if (game.paused) {
	if (status == FFVideosStatus.Playing) then ffvideos_ext_pause(video_handle);
	if (abs(target_ms - ffvideos_ext_get_position(video_handle)) > 16) then ffvideos_ext_seek(video_handle, target_ms);
	return;
};

if (status == FFVideosStatus.Paused) {
	if (abs(target_ms - ffvideos_ext_get_position(video_handle)) > 50) then ffvideos_ext_seek(video_handle, target_ms);
	ffvideos_ext_play(video_handle);
};
if (status == FFVideosStatus.Playing && abs(target_ms - ffvideos_ext_get_position(video_handle)) > 250) then ffvideos_ext_seek(video_handle, target_ms);
var duration_ms = ffvideos_ext_get_duration(video_handle);
if (duration_ms > 0 && target_ms >= duration_ms) {
	ffvideos_ext_close(video_handle);
	video_handle = -1;
	video_completed = video_index;
	video_index = -1;
};
