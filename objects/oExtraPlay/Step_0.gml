/// @description Sync every FFVideos clip to the RPE chart clock.
if (chart_setting_on("disableChartVideo")) {
	video_close_all();
	exit;
};
if (!video_backend_ready && pls_is_gxgames() && array_length(videos) > 0) {
	video_backend_ready = gx_video_available();
	if (video_backend_ready) then print("[GXVideo] HTMLVideo backend ready");
};
var chart_offset = chart_extra_offset_seconds();
video_chart_time = game.__time[1] - chart_offset;
if (video_chart_time < video_last_chart_time - 0.01) {
	for (var _rewind_i = 0; _rewind_i < array_length(videos); _rewind_i++) {
		videos[_rewind_i].completed = false;
		videos[_rewind_i].error_logged = false;
		if (videos[_rewind_i].duration_ms > 0) {
			videos[_rewind_i].endTime = videos[_rewind_i].startTime + videos[_rewind_i].duration_ms / 1000;
		};
	};
	video_close_all();
};
video_last_chart_time = video_chart_time;

video_sync = function(_index) {
	var video = videos[_index];
	if (video.completed) then return;
	var inside = video_chart_time >= video.startTime && video_chart_time < video.endTime;
	if (!inside) {
		if (video.handle >= 0) {
			ffvideos_ext_close(video.handle);
			video.handle = -1;
		};
		return;
	};
	if (video_backend_ready && video.handle < 0 && !video.error_logged) {
		var video_path = chart_file_readable_path(video.path);
		var video_exists = gx_media_source_exists(video_path) || gx_media_source_exists(video.path);
		print($"[FFVideos] Open request: path={video_path}, exists={video_exists}, host={gx_media_host_path_for(video_path)}");
		if (video_exists) {
			video.handle = ffvideos_ext_open(video_path);
			print($"[FFVideos] Open result: handle={video.handle}, error={ffvideos_ext_get_error(video.handle)}");
			if (video.handle >= 0) then ffvideos_ext_set_volume(video.handle, 0);
			else video.error_logged = true;
		} else {
			print($"[FFVideos] Video file missing: {video_path}");
			video.error_logged = true;
		};
		if (video.handle >= 0) {
			var _live = 0;
			for (var _live_i = 0; _live_i < array_length(videos); _live_i++) {
				if (videos[_live_i].handle >= 0) then _live += 1;
			};
			if (_live > 1) then print($"[FFVideos] Simultaneous playback count={_live}");
		};
	};
	if (video.handle < 0) then return;
	video.alpha.value = sample_anim(video.alpha, video_chart_time);
	video.dim.value = sample_anim(video.dim, video_chart_time);
	var status = ffvideos_ext_get_status(video.handle);
	if (status == FFVideosStatus.Error) {
		if (!video.error_logged) {
			print($"[FFVideos] Playback failed: {ffvideos_ext_get_error(video.handle)}");
			video.error_logged = true;
		};
		return;
	};
	if (status == FFVideosStatus.Closed) then return;
	if (os_is_paused()) {
		if (status == FFVideosStatus.Playing) then ffvideos_ext_pause(video.handle);
		return;
	};
	if (status == FFVideosStatus.Preparing) then return;
	var target_ms = max(0, (video_chart_time - video.startTime) * 1000);
	if (variable_global_exists("render_mode") && global.render_mode) {
		if (!ffvideos_ext_prepare_frame(video.handle, target_ms, 10000)) {
			if (!video.error_logged) {
				print($"[FFVideos] Offline frame preparation failed: {ffvideos_ext_get_error(video.handle)}");
				video.error_logged = true;
			};
		};
		return;
	};
	if (game.paused) {
		if (status == FFVideosStatus.Playing) then ffvideos_ext_pause(video.handle);
		if (abs(target_ms - ffvideos_ext_get_position(video.handle)) > 16) then ffvideos_ext_seek(video.handle, target_ms);
		return;
	};
	if (status == FFVideosStatus.Paused) {
		if (abs(target_ms - ffvideos_ext_get_position(video.handle)) > 50) then ffvideos_ext_seek(video.handle, target_ms);
		ffvideos_ext_play(video.handle);
	};
	if (status == FFVideosStatus.Playing && abs(target_ms - ffvideos_ext_get_position(video.handle)) > 250) {
		ffvideos_ext_seek(video.handle, target_ms);
	};
	var duration_ms = ffvideos_ext_get_duration(video.handle);
	if (duration_ms > 0) {
		video.duration_ms = duration_ms;
		video.endTime = video.startTime + duration_ms / 1000;
	};
	if (video.duration_ms > 0 && target_ms >= video.duration_ms) {
		ffvideos_ext_close(video.handle);
		video.handle = -1;
		video.completed = true;
		print($"[FFVideos] Finished: index={_index}, time={video_chart_time}");
	};
};

if (os_is_paused()) then video_os_paused = true;
else if (video_os_paused) {
	video_os_paused = false;
};
for (var video_i = 0; video_i < array_length(videos); video_i++) {
	video_sync(video_i);
};
