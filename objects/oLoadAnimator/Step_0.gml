///@desc 步进：封面、揭开、停留和退出各自推进，不跟加载工作绑在一起
// 回到菜单就拆掉动画。
if (room == room_menu) {
    instance_destroy();
    exit;
};
var _session = chart_session_ensure();
if (mode == "waiting") {
    if (!_session.ready) then exit;
    var _unlock_file = _session.unlock_video_file;
    if (is_string(_unlock_file) && string_length(_unlock_file)) {
        // 加载房间使用黑底，视频留边和后续静默阶段都不显示加载界面。
        var _unlock_background = layer_background_get_id("Background");
        if (_unlock_background != -1) then layer_background_blend(_unlock_background, c_black);
        if (variable_global_exists("render_mode") && global.render_mode) {
            // 录像只加载谱面；解锁视频由编码器在录制完成后拼接。
            mode = "silent";
            global.loading_animation_load_start = true;
            print("[UnlockVideo] Render mode: deferred to export; starting silent chart load");
        } else {
            global.loading_unlock_direct_start = true;
            mode = "unlock";
            var _unlock_path = chart_in_path(_unlock_file);
            if (!gx_media_source_exists(_unlock_path)) {
                unlock_fail("Unlock video file not found: " + _unlock_file);
                exit;
            };
            try { video_open(_unlock_path); } catch (_unlock_exception) {
                var _unlock_reason = _unlock_exception.message;
                delete(_unlock_exception);
                unlock_fail(_unlock_reason);
                exit;
            };
            unlock_open = true;
            unlock_opened_at = get_timer();
            video_enable_loop(false);
            video_set_volume(settings_store().musicVolume);
            print($"[UnlockVideo] Opening: {_unlock_path}");
        };
    } else {
        mode = "normal";
        loading_animation_assets_init();
    };
};
if (mode == "unlock") {
    if (string_length(unlock_error)) {
        unlock_fail(unlock_error);
        exit;
    };
    if (unlock_ended) {
        unlock_finish();
        exit;
    };
    var _video_status = video_get_status();
    if (_video_status == video_status_playing) {
        // 解码器可能在 preparing 之后才创建音频通道，播放中继续同步音量。
        video_set_volume(settings_store().musicVolume);
        unlock_started = true;
    };
    if (os_is_paused()) {
        if (_video_status == video_status_playing) {
            video_pause();
            unlock_os_paused = true;
        };
    } else if (unlock_os_paused) {
        video_resume();
        unlock_os_paused = false;
    };
    if (_video_status == video_status_closed) {
        if (unlock_started) then unlock_finish();
        else unlock_fail("Unable to open unlock video: " + _session.unlock_video_file);
    } else if (!unlock_started && get_timer() - unlock_opened_at > 30000000) {
        unlock_fail("Timed out opening unlock video: " + _session.unlock_video_file);
    };
    exit;
};
if (mode == "silent") {
    if (!silent_released && variable_global_exists("loading_render_ready") && global.loading_render_ready) {
        silent_released = true;
        if (global.loading_unlock_direct_start) {
            // 允许分帧建线解冻，但继续屏蔽绘制，直到媒体就绪并真正开播。
            global.loading_animator_finished = true;
        } else {
            chart_loading_animation_finish();
        };
    };
    exit;
};
// 渲染房间准备好就算谱面就绪。
if (!chart_ready && variable_global_exists("loading_render_ready") && global.loading_render_ready) {
    chart_ready = true;
};
if (!assets_loaded && _session.ready) {
    // 有插图就裁成平行四边形并做模糊底。
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
				// 裁切用完源图就可以删。
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
// 黑幕盖满后进入揭开，并从头开始右下角动画。
if (state == LOAD_ANIM_STATE.COVERING && _elapsed >= cover_duration) {
    state = LOAD_ANIM_STATE.REVEALING;
    started_at = current_time;
    global.loading_animation_load_start = true;
    // 半透明黑幕已经盖满。右下角动画从零宽度重新开始。
    loading_rect_phase = 1;
    loading_rect_elapsed = 0;
    loading_rect_scale = 0;
};
// 揭开结束进入停留。
if (state == LOAD_ANIM_STATE.REVEALING && current_time - started_at >= reveal_duration) {
    state = LOAD_ANIM_STATE.HOLDING;
    started_at = current_time;
};

// 右下角加载条按开合两段循环。
if (loading_rect_phase != 0) {
    // delta_time 是微秒，动画时钟用秒。
    loading_rect_elapsed += max(0, delta_time) / 1000000;
    var _loading_cycle = loading_rect_elapsed mod (loading_rect_duration * 2);
    // 前半段展开，后半段收回。
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

// GX 离开加载房后不再播这段动画。
if (pls_is_gxgames() && room != room_loading && room != room_menu) {
    chart_loading_animation_finish();
    exit;
};

// 谱面就绪并停留够久后开始退出。
if (chart_ready && state == LOAD_ANIM_STATE.HOLDING) {
    if (ready_at < 0) then ready_at = current_time;
    if (current_time - ready_at >= ready_hold_duration) {
        state = LOAD_ANIM_STATE.EXITING;
        exit_started_at = current_time;
    };
};
// 退出滑出后再多等一会儿才真正结束。
if (state == LOAD_ANIM_STATE.EXITING && current_time - exit_started_at >= exit_duration) {
    if (exit_finished_at < 0) then exit_finished_at = exit_started_at + exit_duration;
    if (current_time - exit_finished_at >= exit_wait_duration) {
        chart_loading_animation_finish();
        exit;
    };
};
