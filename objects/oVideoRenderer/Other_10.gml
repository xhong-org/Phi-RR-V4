/// @description Capture the completed application surface and submit one frame.
if (encoder_finished || !surface_exists(application_surface) || !instance_exists(oMedia)) then exit;

var media = instance_find(oMedia, 0);
if (!bool(media.success ?? false) || media.length <= 0) then exit;

var width = surface_get_width(application_surface);
var height = surface_get_height(application_surface);
if (!gpu_capture_ready) {
    print($"[Renderer] D3D11 capture initialization failed: {video_renderer_get_error()}");
    encoder_finished = true;
		if (global.render_cli) game_end(); else { global.render_mode = false; room_goto(room_menu); };
    exit;
};

// A window resize can briefly recreate the swap-chain surface at the window
// size. Wait for Camera_View's next Pre Draw resize instead of reading a lost
// or incorrectly sized GPU surface into the fixed encoder buffer.
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

if (!encoder_started) {
    frame_width = width;
    frame_height = height;
    total_frames = max(1, ceil((media.length / 1000000) * global.render_fps));
    global.render_chart_frames = total_frames;

    var audio_path = InChartPath + game.folder_chart.music;
    video_renderer_configure(frame_width, frame_height, global.render_fps, global.render_crf);
    video_renderer_set_ffmpeg(global.render_ffmpeg);
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
    for (var hitsound_i = 0; hitsound_i < array_length(scheduled_hitsounds); hitsound_i++) {
        var hitsound_event = scheduled_hitsounds[hitsound_i];
        if (video_renderer_add_hitsound(hitsound_event.path,
            hitsound_event.time, hitsound_event.volume)) submitted_hitsounds++;
    };
    print($"[Renderer] Scheduled hitsounds: {submitted_hitsounds}/{array_length(scheduled_hitsounds)}");
    render_status = "Rendering video";
    print($"[Renderer] Started: {frame_width}x{frame_height}, frames={total_frames}");
};

// Compose the recorded frame as chart (including chart HUD) -> aspect mask.
// The progress overlay is drawn later by Draw End, after capture, so it stays
// visible on the render screen without entering the output video.
// Capture always uses the complete application surface. chart_view_width and
// chart_view_height only describe the chart content inside this full frame.
draw_chart_mask(room_width, room_height);
draw_flush();
if (!video_renderer_capture()) {
    render_status = "GPU capture stopped unexpectedly";
    print($"[Renderer] GPU capture failed: {video_renderer_get_error()}");
    encoder_finished = true;
    video_renderer_finish();
		if (global.render_cli) game_end(); else { global.render_mode = false; room_goto(room_menu); };
    exit;
};
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
if (global.render_frame >= total_frames + global.render_outro_frames) {
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
