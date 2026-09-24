/// @description Drive the cover, reveal, hold and exit phases independently of loading work.
if (room == room_menu) {
    instance_destroy();
    exit;
};
var _session = chart_session_ensure();
if (!chart_ready && variable_global_exists("loading_render_ready") && global.loading_render_ready) {
    chart_ready = true;
};
if (!assets_loaded && _session.ready) {
    if (string_length(_session.image_file)) {
        var _path = chart_file_readable_path(chart_path_join(InChartPath, _session.image_file));
        if (file_exists(_path) || string_pos("blob:", _path) == 1 || string_pos("data:", _path) == 1
                || chart_file_exists_any(chart_path_join(InChartPath, _session.image_file))) {
            var _source_sprite = sprite_add(_path, 1, false, true, 0, 0);
            if (sprite_exists(_source_sprite)) {
                //var _w = sprite_get_width(clear_sprite);
                //var _h = sprite_get_height(clear_sprite);
                //sprite_set_offset(clear_sprite, _w * 0.5, _h * 0.5);
				clear_sprite = sprite_parallelogram_fixed(_source_sprite);
				// The source is only needed while building the clipped sprite.
				if (sprite_exists(_source_sprite)) then sprite_delete(_source_sprite);
                blur_sprite = kawase_blur_sprite(_path, 1, 0, 10, SPRITE_OFFSET.MIDDLE_CENTER, [0, 0]);
                if (sprite_exists(blur_sprite)) then chart_blur_keep(blur_sprite);
            };
        };
    };
	if (audio_exists(snd_start)) then audio_play_sound(snd_start, 0, 0);
    assets_loaded = true;
    state = LOAD_ANIM_STATE.COVERING;
    started_at = current_time;
    intro_started_at = started_at;
    loading_rect_phase = 0;
    loading_rect_elapsed = 0;
    loading_rect_scale = 0;
};

var _elapsed = current_time - started_at;
if (state == LOAD_ANIM_STATE.COVERING && _elapsed >= cover_duration) {
    state = LOAD_ANIM_STATE.REVEALING;
    started_at = current_time;
    global.loading_animation_load_start = true;
    // The black translucent cover is complete. Start the bottom-right
    // animation from a clean zero-width state only after this point.
    loading_rect_phase = 1;
    loading_rect_elapsed = 0;
    loading_rect_scale = 0;
};
if (state == LOAD_ANIM_STATE.REVEALING && current_time - started_at >= reveal_duration) {
    state = LOAD_ANIM_STATE.HOLDING;
    started_at = current_time;
};

if (loading_rect_phase != 0) {
    // delta_time is microseconds; keep the animation clock in seconds.
    loading_rect_elapsed += max(0, delta_time) / 1000000;
    var _loading_cycle = loading_rect_elapsed mod (loading_rect_duration * 2);
    if (_loading_cycle < loading_rect_duration) {
        loading_rect_phase = 1;
        var _loading_open_t = _loading_cycle / loading_rect_duration;
        loading_rect_scale = Easings.InOutCubic(_loading_open_t);
    } else {
        loading_rect_phase = 3;
        var _loading_close_t = (_loading_cycle - loading_rect_duration) / loading_rect_duration;
        loading_rect_scale = 1 - Easings.InOutCubic(_loading_close_t);
    };
};

if (pls_is_gxgames() && room != room_loading && room != room_menu) {
    chart_loading_animation_finish();
    exit;
};

if (chart_ready && state == LOAD_ANIM_STATE.HOLDING) {
    if (ready_at < 0) then ready_at = current_time;
    if (current_time - ready_at >= ready_hold_duration) {
        state = LOAD_ANIM_STATE.EXITING;
        exit_started_at = current_time;
    };
};
if (state == LOAD_ANIM_STATE.EXITING && current_time - exit_started_at >= exit_duration) {
    if (exit_finished_at < 0) then exit_finished_at = exit_started_at + exit_duration;
    if (current_time - exit_finished_at >= exit_wait_duration) {
        chart_loading_animation_finish();
        exit;
    };
};
