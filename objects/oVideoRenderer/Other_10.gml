///@desc 抓取完成的应用程序表面并提交一帧
// 编码结束、表面丢失或没有媒体时不抓。
if (encoder_finished || !surface_exists(application_surface) || !instance_exists(oMedia)) then exit;

var media = instance_find(oMedia, 0);
// 音频还没成功或长度为 0 时不开始。
if (!bool(media.success ?? false) || media.length <= 0) then exit;

var width = surface_get_width(application_surface);
var height = surface_get_height(application_surface);
// GPU 抓帧初始化失败就结束并离开。
if (!gpu_capture_ready) {
    print($"[Renderer] D3D11 capture initialization failed: {video_renderer_get_error()}");
    encoder_finished = true;
		if (global.render_cli) game_end(); else { global.render_mode = false; room_goto(room_menu); };
    exit;
};

// 改窗口会短暂把交换链表面变成窗口尺寸。等 Camera_View 下一次预绘制改回来，不要把错误尺寸送进编码器。
if (width != global.render_width || height != global.render_height) {
    render_status = "Restoring render surface";
    if (!surface_recovery_logged) {
        print($"[Renderer] Surface recovery: {width}x{height} -> {global.render_width}x{global.render_height}");
        surface_recovery_logged = true;
    };
    exit;
};
if (surface_recovery_logged) {
    print($"[Renderer] Surface restored: {width}x{height}");
    surface_recovery_logged = false;
    render_status = encoder_started ? "Rendering video" : "Preparing chart and encoder";
};

// 不录加载帧和动画前等待。开头多出来的帧会让延迟的谱面音频在片头里就开始。
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then exit;
// 噪域还没收完就不要推进录像帧，否则成片开头是空的，后面时间又对不齐。
if (official_block_pack_pending()) then exit;
if (!instance_exists(oPlayTransition)) then exit;
var _transition = instance_find(oPlayTransition, 0);
if (!variable_instance_exists(_transition, "state")
    || _transition.state < PLAY_TRANSITION_STATE.INTRO) then exit;

if (!encoder_started) {
    frame_width = width;
    frame_height = height;
    total_frames = max(1, ceil((media.length / 1000000) * global.render_fps));
    global.render_chart_frames = total_frames;

    var audio_path = chart_in_path(game.folder_chart.music);
    // 第一帧有效画面才配置编码器。
    video_renderer_configure(frame_width, frame_height, global.render_fps, global.render_crf);
    video_renderer_set_ffmpeg(global.render_ffmpeg);
    // 延迟、预设或编码器非法就退出。
    if (!video_renderer_set_audio_delay(global.render_intro_seconds)) {
        print($"[Renderer] Invalid audio delay: {video_renderer_get_error()}");
        encoder_finished = true;
		if (global.render_cli) game_end(); else { global.render_mode = false; room_goto(room_menu); };
        exit;
    };
    if (!video_renderer_set_preset(global.render_preset)) {
        print($"[Renderer] Invalid preset: {global.render_preset}");
        encoder_finished = true;
		if (global.render_cli) game_end(); else { global.render_mode = false; room_goto(room_menu); };
        exit;
    };
    if (!video_renderer_set_encoder(global.render_encoder)) {
        print($"[Renderer] Invalid encoder: {global.render_encoder}");
        encoder_finished = true;
		if (global.render_cli) game_end(); else { global.render_mode = false; room_goto(room_menu); };
        exit;
    };
    encoder_started = bool(video_renderer_start(global.render_output, audio_path));
    if (!encoder_started) {
        render_status = "Unable to start encoder";
        print($"[Renderer] Start failed: {video_renderer_get_error()}");
        encoder_finished = true;
		if (global.render_cli) game_end(); else { global.render_mode = false; room_goto(room_menu); };
        exit;
    };
    var scheduled_hitsounds = (variable_global_exists("render_hitsounds")
        && is_array(global.render_hitsounds)) ? global.render_hitsounds : [];
    var submitted_hitsounds = 0;
    // 把排好的打击音交给编码器。
    for (var hitsound_i = 0; hitsound_i < array_length(scheduled_hitsounds); hitsound_i++) {
        var hitsound_event = scheduled_hitsounds[hitsound_i];
        if (video_renderer_add_hitsound(hitsound_event.path,
            hitsound_event.time, hitsound_event.volume)) submitted_hitsounds++;
    };
    print($"[Renderer] Scheduled hitsounds: {submitted_hitsounds}/{array_length(scheduled_hitsounds)}");
    if (render_wants_settlement()) {
        var ending_loops = render_schedule_settlement_ending(media.length / 1000000);
        print($"[Renderer] Settlement ending events: {ending_loops}");
    };
    render_status = "Rendering video";
    print($"[Renderer] Started: {frame_width}x{frame_height}, frames={total_frames}");
};

// 抓应用程序表面。进度层在绘制结束才贴，所以不会进成片。
// 只在视口外补未压暗的插图，编码器和交互看到同一块宽高比遮罩。
// 这里不要 surface_reset_target，oChartMask 已经弹过目标。
var _mask_left = floor(chart_view_left);
var _mask_right = ceil(chart_view_right);
var _mask_height = max(1, ceil(chart_view_height));
if (!chart_mask_released()) {
	// 视口左右两侧补背景，中间留给已经画好的谱面。
	if (_mask_left > 0) {
	    gpu_set_scissor(0, 0, _mask_left, _mask_height);
	    chart_draw_background(false);
	};
	if (_mask_right < room_width) {
	    gpu_set_scissor(_mask_right, 0, max(1, room_width - _mask_right), _mask_height);
	    chart_draw_background(false);
	};
};
gpu_set_scissor(0, 0, max(1, global.render_width), max(1, global.render_height));
// 官谱已经把版本画进谱面贴回。RPE 在更晚的全屏着色之后再盖一次。录像时关掉 GUI，避免进度层再出现一份。
if (instance_exists(oRPEEffect)) then chart_draw_recorded_version();
if (!variable_instance_exists(id, "version_logged")) {
	version_logged = true;
	print($"[Renderer] Version watermark: {chart_version_label()}");
};
// 不要在这里 shader_reset，也不要 surface_reset_target。
// oChartMask 已经贴回并刷新。surface_get_target 可能仍报谱面遮罩，多一次 reset 会把成片目标弹掉。
// 捕获表面还绑着时 shader_reset 会丢掉刚提交的音符，成片变成白屏、黑屏，或只剩乱码水印。
// 这处已经反复修过。抓帧前只允许补视口外背景、把裁剪铺满成片尺寸，以及 pls_draw_flush。
pls_draw_flush();
// 偶发绑错目标时先跳过这一帧，不要立刻毁掉整段编码。
if (!video_renderer_capture()) {
	if (!variable_instance_exists(id, "capture_fail_count")) then capture_fail_count = 0;
	capture_fail_count++;
	print($"[Renderer] GPU capture failed ({capture_fail_count}): {video_renderer_get_error()}");
	// 连续失败才放弃。单帧目标还没绑回时，下一帧再抓。
	if (capture_fail_count < 8) then exit;
    render_status = "GPU capture stopped unexpectedly";
    encoder_finished = true;
    video_renderer_finish();
		if (global.render_cli) game_end(); else { global.render_mode = false; room_goto(room_menu); };
    exit;
};
capture_fail_count = 0;
overlay_ready = true;
if (!encoder_finished && surface_exists(overlay_surface)) {
    draw_surface_stretched(overlay_surface, 0, 0, room_width, room_height);
};
global.render_frame++;
var output_frame = global.render_frame + global.render_intro_frames;
var output_total_frames = total_frames + global.render_intro_frames + global.render_outro_frames;
if ((output_frame mod max(1, round(global.render_fps * 5))) == 0) {
    print($"[Renderer] {output_frame}/{output_total_frames}");
};
var render_should_finish = (global.render_frame >= total_frames + global.render_outro_frames);
// 要录结算时等结算标记，否则按片尾帧数结束。
if (render_wants_settlement()) {
	var settlement_fallback = total_frames + global.render_outro_frames + ceil(2 * max(1, global.render_fps));
	render_should_finish = bool(global.render_settlement_finished)
		|| (global.render_frame >= settlement_fallback);
};
if (render_should_finish) {
    encoder_finished = true;
    overlay_ready = false;
    render_status = "Finalizing video file";
    var success = bool(video_renderer_finish());
    if (success) print($"[Renderer] Complete: {global.render_output}");
    else print($"[Renderer] FFmpeg failed: {video_renderer_get_error()}");
    if (global.render_cli) game_end(); else {
        global.render_mode = false;
        global.render_source = "";
        global.render_gui_returning = true;
        room_goto(room_menu);
    };
};
