/// @description Initialize deterministic chart rendering.
depth = -20000000000000000;
encoder_started = false;
encoder_finished = false;
frame_width = 0;
frame_height = 0;
total_frames = 0;
surface_recovery_logged = false;
render_started_at = get_timer();
render_status = "Preparing chart and encoder";
gpu_capture_ready = false;
overlay_ready = false;
overlay_surface = -1;
overlay_surface_width = 0;
overlay_surface_height = 0;
ui_font = pls_ui_font_add(28, true, false, -infinity, infinity, false);

if (os_type == os_windows) {
    var d3d_info = os_get_info();
    if (ds_exists(d3d_info, ds_type_map)
        && ds_map_exists(d3d_info, "video_d3d11_device")
        && ds_map_exists(d3d_info, "video_d3d11_context")) {
        var d3d_args = buffer_create(16, buffer_fixed, 1);
        buffer_write(d3d_args, buffer_u64, int64(d3d_info[? "video_d3d11_device"]));
        buffer_write(d3d_args, buffer_u64, int64(d3d_info[? "video_d3d11_context"]));
        gpu_capture_ready = bool(__video_renderer_initialize(
            buffer_get_address(d3d_args), buffer_tell(d3d_args)));
        buffer_delete(d3d_args);
    };
};

// Record from the chart start animation. The 0.1s pre-animation wait is not
// written to the file, so audio delay is animation + start delay only.
global.render_intro_animation_seconds = 1.0;
global.render_intro_start_delay_seconds = 0.5;
global.render_intro_seconds = global.render_intro_animation_seconds + global.render_intro_start_delay_seconds;
global.render_intro_frames = ceil(global.render_intro_seconds * global.render_fps);
global.render_intro_seconds = global.render_intro_frames / max(1, global.render_fps);
global.render_outro_seconds = 1.5;
global.render_outro_frames = ceil(global.render_outro_seconds * global.render_fps);
global.render_outro_seconds = global.render_outro_frames / max(1, global.render_fps);
global.render_chart_frames = 0;
global.render_frame = -global.render_intro_frames;
video_renderer_clear_hitsounds();
random_set_seed(global.render_seed);
game_set_speed(global.render_fps, gamespeed_fps);
audio_master_gain(0);

with (oPausedUI) visible = false;

if (variable_global_exists("game") && is_struct(game)) {
    game.paused = true;
    game.__time[0] = 0;
    game.__time[1] = 0;
    game.__time[3] = 0;
    game.__time[4] = 0;
    game.settings.enableRPEMulticore = false;
};

window_set_caption($"Rendering: {global.render_output}");
print($"[Renderer] Output: {global.render_output}, resolution={global.render_resolution} ({global.render_width}x{global.render_height}), aspect={global.render_aspect_ratio}, fps={global.render_fps}, crf={global.render_crf}, preset={global.render_preset}, encoder={global.render_encoder}");
