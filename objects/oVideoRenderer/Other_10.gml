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

draw_flush();
if (!video_renderer_capture()) {
    render_status = "GPU capture stopped unexpectedly";
    print($"[Renderer] GPU capture failed: {video_renderer_get_error()}");
    encoder_finished = true;
    video_renderer_finish();
		if (global.render_cli) game_end(); else { global.render_mode = false; room_goto(room_menu); };
    exit;
};

// The frame has already been copied above, so this opaque panel is visible in
// the window without becoming part of the encoded video.
var gui_width = max(1, room_width);
var gui_height = max(1, room_height);
var scale = min(gui_width / 1366, gui_height / 768);
var panel_width = min(gui_width - 64 * scale, 920 * scale);
var panel_left = (gui_width - panel_width) * 0.5;
var panel_top = gui_height * 0.5 - 150 * scale;
var output_frame = global.render_frame + global.render_intro_frames;
var output_total_frames = total_frames + global.render_intro_frames;
var progress = output_total_frames > 0 ? clamp(output_frame / output_total_frames, 0, 1) : 0;
var elapsed = max(0, (get_timer() - render_started_at) / 1000000);
var eta = progress > 0 ? max(0, elapsed * (1 - progress) / progress) : 0;

draw_set_alpha(1);
draw_set_colour(make_colour_rgb(8, 10, 18));
draw_rectangle(0, 0, gui_width, gui_height, false);
draw_set_colour(make_colour_rgb(17, 22, 36));
draw_roundrect_ext(panel_left, panel_top, panel_left + panel_width,
    panel_top + 300 * scale, 18 * scale, 18 * scale, false);

draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_text_transformed(panel_left + 42 * scale, panel_top + 34 * scale,
    "VIDEO RENDER", 2.5 * scale, 2.5 * scale, 0);
draw_set_colour(make_colour_rgb(139, 151, 178));
draw_text_transformed(panel_left + 42 * scale, panel_top + 88 * scale,
    render_status, 1.15 * scale, 1.15 * scale, 0);

var source_name = filename_name(global.render_source);
if (!string_length(source_name) || source_name == "__sample__") source_name = "Bundled sample chart";
draw_set_colour(make_colour_rgb(211, 218, 234));
draw_text_transformed(panel_left + 42 * scale, panel_top + 126 * scale,
    source_name, 1.0 * scale, 1.0 * scale, 0);

var bar_left = panel_left + 42 * scale;
var bar_top = panel_top + 178 * scale;
var bar_width = panel_width - 84 * scale;
var bar_height = 18 * scale;
draw_set_colour(make_colour_rgb(38, 45, 64));
draw_roundrect_ext(bar_left, bar_top, bar_left + bar_width, bar_top + bar_height,
    bar_height, bar_height, false);
if (progress > 0) {
    draw_set_colour(make_colour_rgb(96, 216, 190));
    draw_roundrect_ext(bar_left, bar_top, bar_left + bar_width * progress,
        bar_top + bar_height, bar_height, bar_height, false);
};

draw_set_colour(c_white);
draw_text_transformed(bar_left, bar_top + 38 * scale,
    $"{string_format(progress * 100, 0, 1)}%", 1.3 * scale, 1.3 * scale, 0);
draw_set_halign(fa_right);
draw_set_colour(make_colour_rgb(139, 151, 178));
draw_text_transformed(panel_left + panel_width - 42 * scale, bar_top + 40 * scale,
    $"Frame {output_frame} / {output_total_frames}", 0.9 * scale, 0.9 * scale, 0);
draw_set_halign(fa_left);
draw_text_transformed(bar_left, panel_top + 258 * scale,
    $"Elapsed  {string_format(elapsed, 0, 1)}s", 0.9 * scale, 0.9 * scale, 0);
draw_set_halign(fa_right);
var eta_text = progress < 1
    ? $"Remaining  {string_format(eta, 0, 1)}s"
    : "Finalizing";
draw_text_transformed(panel_left + panel_width - 42 * scale, panel_top + 258 * scale,
    eta_text, 0.9 * scale, 0.9 * scale, 0);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);

global.render_frame++;
if ((output_frame mod max(1, round(global.render_fps * 5))) == 0) {
    print($"[Renderer] {output_frame}/{output_total_frames}");
};

if (global.render_frame >= total_frames) {
    encoder_finished = true;
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
