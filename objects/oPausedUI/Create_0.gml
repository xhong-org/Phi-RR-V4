/// @description Shared PCR-style pause overlay.
if (!variable_instance_exists(id, "owner")) then owner = noone;
// Draw End must run after oChartMask (-12000), on the final application target.
depth = -99999999//-11999;

opened_at = get_timer();
was_paused = false;
action_queued = false;
draw_logged = false;
print($"[PausedUI] Created owner={owner}");
pause_click_count = 0;
pause_click_deadline = 0;
retry_waiting = false;
retry_ready = false;
retry_mode = 0;
retry_started_at = 0;
retry_delay = 3000000;

paused_ui_draw = function() {
    if (!paused_ui_can_control() || (!game.paused && !retry_waiting)) then exit;
    var _old_colour = draw_get_colour();
    var _old_alpha = draw_get_alpha();
    var _fade = clamp((get_timer() - opened_at) / 100000, 0, 1);
    var _countdown_progress = retry_waiting
        ? clamp((get_timer() - retry_started_at) / retry_delay, 0, 1) : 0;
    var _overlay_alpha = retry_waiting
        ? (retry_mode == 2 ? 0.6 * (1 - _countdown_progress) : 0.6)
        : (0.6 * _fade);

    pls_draw_flush();
    gpu_set_blendmode(bm_normal);
    draw_set_colour(c_white);
    draw_set_alpha(1);
    var _black_scale_x = chart_view_width / max(1, sprite_get_width(spr_black));
    var _black_scale_y = chart_view_height / max(1, sprite_get_height(spr_black));
    draw_sprite_ext(spr_black, 0,
        chart_view_left + chart_view_width * 0.5,
        chart_view_height * 0.5,
        _black_scale_x, _black_scale_y, 0, c_white, _overlay_alpha);

    draw_set_alpha(retry_waiting ? 1 : _fade);
    if (retry_waiting && retry_mode == 2) {
        var _seconds_left = max(1, ceil((retry_delay - (get_timer() - retry_started_at)) / 1000000));
        draw_set_font(game.font);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text_transformed(room_width * 0.5, room_height * 0.5, string(_seconds_left),
            1.4 * ui_scale, 1.4 * ui_scale, 0);
    } else if (!retry_waiting) {
        var _base_scale = 0.9 * ui_scale;
        for (var _i = 0; _i < 3; _i++) {
            var _sprite = button_sprite[_i];
            var _scale = _base_scale * (button_hover[_i] ? 1.1 : 1);
            draw_sprite_ext(_sprite, 0,
                button_x[_i] - sprite_get_width(_sprite) * _scale * 0.5,
                button_y - sprite_get_height(_sprite) * _scale * 0.5,
                _scale, _scale, 0,
                button_hover[_i] ? make_colour_rgb(210, 235, 255) : c_white, _fade);
        };
    };
    draw_set_colour(_old_colour);
    draw_set_alpha(_old_alpha);
    gpu_set_blendmode(bm_normal);
};

gui_width = room_width;
gui_height = room_height;
ui_scale = 1;
button_y = 384;
button_x = [453, 683, 913];
button_sprite = [spr_back, spr_retry, spr_resume];
button_hover = [false, false, false];
pause_button_x = 50;
pause_button_y = 50;
pause_button_radius = 42;
pause_layout_width = -1;
pause_layout_height = -1;

function paused_ui_can_control() {
	if (instance_exists(oPlayTransition) && !retry_waiting) {
		var _transition = instance_find(oPlayTransition, 0);
		if (_transition.state != PLAY_TRANSITION_STATE.PLAYING) then return false;
	};
        return !(variable_global_exists("render_mode") && global.render_mode)
                && instance_exists(owner)
                && variable_global_exists("game") && is_struct(game)
                && variable_struct_exists(game, "paused")
                && is_array(game.__time) && (retry_waiting || game.__time[0] > 0)
                && variable_instance_exists(owner, "chart_exit_started")
                && !owner.chart_exit_started;
}

function paused_ui_refresh_layout() {
	var _width = max(1, room_width);
	var _height = max(1, room_height);
	if (pause_layout_width == _width && pause_layout_height == _height) then return;
	pause_layout_width = _width;
	pause_layout_height = _height;
	var _scale = variable_global_exists("global_scales") ? global_scales : 1;
	pause_button_x = chart_view_left + 50 * _scale;
	pause_button_y = 50 * _scale;
	pause_button_radius = max(36, 42 * _scale);
}

function paused_ui_pause() {
        if (!paused_ui_can_control() || game.paused || game.__time[0] <= 0) then return;
        print("[PausedUI] Pause");
        with (oNote) {
                if (!_is_hold) {
                        _pause_lock_x = x;
                        _pause_lock_y = y;
                        _pause_lock_angle = image_angle;
                        _pause_lock_bad_x = _bad_x;
                        _pause_lock_bad_y = _bad_y;
                        _pause_lock_bad_angle = _bad_angle;
                        _pause_lock_active = true;
                };
        };
        with (oNote_1) {
                if (!_is_hold) {
                        _pause_lock_x = x;
                        _pause_lock_y = y;
                        _pause_lock_angle = image_angle;
                        _pause_lock_bad_x = _bad_x;
                        _pause_lock_bad_y = _bad_y;
                        _pause_lock_bad_angle = _bad_angle;
                        _pause_lock_active = true;
                };
        };
        with (oNote_2) {
                if (type != 2) {
                        _pause_lock_x = x;
                        _pause_lock_y = y;
                        _pause_lock_angle = image_angle;
                        _pause_lock_active = true;
                };
        };
        m_pause();
        array_set(game.__time, 2, get_timer());
        game.paused = true;
        opened_at = get_timer();
}

function paused_ui_resume() {
        if (!paused_ui_can_control() || !game.paused) then return;
        retry_ready = false;
        retry_waiting = true;
        retry_mode = 2;
        retry_started_at = get_timer();
        draw_logged = false;
        print("[PausedUI] Resume countdown started");
}

function paused_ui_back() {
        if (action_queued) then return;
        print("[PausedUI] Back to menu");
        action_queued = true;
        game.paused = true;
        m_pause();
        owner.chart_exit_started = true;
        owner.chart_exit_timer = get_timer();
        owner.chart_exit_alpha = 1;
}

function paused_ui_reset_score() {
        combo = 0;
        if (variable_global_exists("phi_state_list") && is_struct(phi_state_list)) {
                phi_state_list.prefect = 0;
                phi_state_list.good = 0;
                phi_state_list.bad = 0;
                phi_state_list.miss = 0;
                phi_state_list.acc = 0;
                phi_state_list.max_hitcombo = 0;
        };
        with (oEffectNew) effect_events = [];
        with (oEffect) {
                if (part_system_exists(p1)) then part_particles_clear(p1);
                _timer = get_timer();
        };
}

function paused_ui_reset_official() {
        if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then return;
        instance_activate_object(oNote);
        with (oLine) {
                _counts = [0, 0, 0, 0];
                _last_event_time = 0;
                __x = 0; __y = 0; __a = 0; __r = 0;
                __cos = 1; __sin = 0;
                __value[0] = 0; __value[1] = 0;
        };
        with (oNote) {
                canDraw = false;
                isBad = false;
                isJudge = false;
                hit_status = TYPE.NONE;
                _bad_x = 0; _bad_y = 0; _bad_angle = 0;
                _note_x = 0; _note_y = 0;
                _now_seconds = 0; _now_beat = 0;
                judgeRealTime = 0;
                if (_is_hold) {
                        isHold = false;
                        notJudge = true;
                        isMiss = false;
                        isClickRealTime = realHitTime;
                        _bak_time = realHitTime;
                        _hx0 = 0; _hy0 = 0; _hx1 = 0; _hy1 = 0; _hx2 = 0; _hy2 = 0;
                        yscale = hold_time_length * room_height * 0.6 / max(1, _hold_body_height) * speed;
                };
        };
}

function paused_ui_reset_pec() {
        if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then return;
        instance_activate_object(oNote_2);
        with (oLine_2) {
                _move_index = 0; _alpha_index = 0; _rotate_index = 0; _speed_index = 0;
                _move_value = [0, 0];
                _move_x = 0; _move_y = 0;
		_alpha_value = 1; _rotate_value = 0;
		image_alpha = 1;
                floor_position = 0;
                line_sec = 0;
                _last_line_sec = -infinity;
                __cos = 1; __sin = 0;
                _last_angle = 0;
                if (variable_instance_exists(id, "_counts")) then _counts = [0, 0, 0, 0];
                if (variable_instance_exists(id, "line_time")) then line_time = 0;
        };
        with (oNote_2) {
                canDraw = false;
                judged = false;
                hold_started = false;
                hit_status = TYPE.NONE;
                hold_effect_sec = -infinity;
                hold_bpm_index = 0;
                hold_bpm_last_sec = -infinity;
                hx0 = 0; hy0 = 0; hx1 = 0; hy1 = 0; hx2 = 0; hy2 = 0;
                yscale = 0;
                image_alpha = 1;
        };
        owner.bpm_count = 0;
        owner.pec_bpm_last_sec = -infinity;
}

function paused_ui_reset_rpe() {
        if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then return;
        instance_activate_object(oNote_1);
        with (oLine_1) {
                for (var layer_index = 0; layer_index < array_length(events_count); layer_index++) {
                        if (!is_struct(events_count[layer_index])) then continue;
                        var event_names = struct_get_names(events_count[layer_index]);
                        for (var event_i = 0; event_i < array_length(event_names); event_i++) {
                                events_count[layer_index][$ event_names[event_i]] = 0;
                        };
                };
                var ext_names = struct_get_names(ext_count);
                for (var ext_i = 0; ext_i < array_length(ext_names); ext_i++) {
                        ext_count[$ ext_names[ext_i]] = 0;
                };
                for (var event_layer_i = 0; event_layer_i < array_length(events_hold); event_layer_i++) {
                        var event_layer_hold = events_hold[event_layer_i];
                        if (!is_struct(event_layer_hold) || !is_struct(events_recall[event_layer_i])) then continue;
                        var event_layer_hold_names = struct_get_names(event_layer_hold);
                        for (var event_layer_hold_i = 0; event_layer_hold_i < array_length(event_layer_hold_names); event_layer_hold_i++) {
                                var event_name = event_layer_hold_names[event_layer_hold_i];
                                var event_values = events[event_layer_i][$ event_name];
                                if (is_array(event_values) && array_length(event_values) > 0) {
                                        event_layer_hold[$ event_name] = event_values[0].start;
                                        events_recall[event_layer_i][$ event_name] = event_values[0].start;
                                };
                        };
                };
                var ext_hold_names = struct_get_names(ext_hold);
                for (var ext_hold_i = 0; ext_hold_i < array_length(ext_hold_names); ext_hold_i++) {
                        var ext_hold_name = ext_hold_names[ext_hold_i];
                        if (is_array(extEvents[$ ext_hold_name]) && array_length(extEvents[$ ext_hold_name]) > 0) {
                                ext_hold[$ ext_hold_name] = extEvents[$ ext_hold_name][0].start;
                                ext_recall[$ ext_hold_name] = extEvents[$ ext_hold_name][0].start;
                        };
                };
                speed_event_index = 0;
                line_time = 0; line_sec = 0;
                __raw_x = 0; __raw_y = 0; __raw_r = 0; __raw_a = 0;
                __x = 0; __y = 0; __a = 0; __r = 0;
                __cos = 1; __sin = 0;
                __value[0] = 0; __value[1] = 0;
                __scale_x = 1; __scale_y = 1;
                __incline = 0; __incline_sin = 0;
                __paint_radius = -1; __gif_progress = 0;
                __color = c_white; line_text = "";
                line_text_font = game.font;
                image_blend = c_white; image_alpha = 1;
                paint_has_content = false;
                paint_last_valid = false;
                paint_last_time = -infinity;
        };
        with (oNote_1) { // TODO: Retry之后部分音符变滚木,等会修)))))))
                canDraw = false;
                isHold = false;
                notJudge = true;
                isMiss = false;
                isBad = false;
                isJudge = false;
                hit_status = TYPE.NONE;
                judgeRealTime = 0;
                _bad_x = 0; _bad_y = 0; _bad_angle = 0;
                _note_x = 0; _note_y = 0; _x_h = 0; _y_h = 0;
                _now_seconds = 0; _now_beat = 0; _line_time = 0;
                _is_out = true; _is_out_line = true;
                _position_floor_delta = 0;
                _note_position_speed = 0;
                _control_position_speed = 0;
                outside = false;
                __first__ = false;
                rpe_control_cursors = [0, 0, 0, 0];
                _pause_lock_active = false;
                image_alpha = alpha;
                image_blend = note_tint;
                image_xscale = (global_scales / 6) * size;
                image_yscale = bool(game.settings.noteUniformScale ?? false) ? image_xscale : (global_scales / 6);
                yscale = 0;
                if (_is_hold) {
                        _bak_time = 0;
                        _hx0 = 0; _hy0 = 0; _hx1 = 0; _hy1 = 0; _hx2 = 0; _hy2 = 0;
                        yscale = 0;
                };
        };
        owner.bpm_count = 0;
        if (variable_global_exists("game_1") && is_struct(game_1)) {
                game_1._note_activation_index = 0;
                game_1._note_activation_last_time = -infinity;
                if (is_struct(game_1._note_activation_records)) {
                        var record_names = struct_get_names(game_1._note_activation_records);
                        for (var record_i = 0; record_i < array_length(record_names); record_i++) {
                                var record = game_1._note_activation_records[$ record_names[record_i]];
                                if (is_struct(record)) then record.activated = false;
                        };
                };
                if (is_array(game_1._note_spatial_groups)) {
                        for (var spatial_reset_i = 0; spatial_reset_i < array_length(game_1._note_spatial_groups); spatial_reset_i++) {
                                var spatial_group = game_1._note_spatial_groups[spatial_reset_i];
                                if (is_struct(spatial_group) && is_array(spatial_group.notes)) {
                                        spatial_group.remain = array_length(spatial_group.notes);
                                };
                        };
                };
                // Hold spatial queries remove activated entries by swapping them
                // out of the active prefix. Rebuild that prefix for a retry.
                if (is_array(game_1._note_spatial_hold_groups)) {
                        for (var hold_group_i = 0; hold_group_i < array_length(game_1._note_spatial_hold_groups); hold_group_i++) {
                                var hold_group = game_1._note_spatial_hold_groups[hold_group_i];
                                if (!is_struct(hold_group) || !is_array(hold_group.notes)) then continue;
                                if (is_array(hold_group.originalNotes)) {
                                        hold_group.count = array_length(hold_group.originalNotes);
                                        hold_group.notes = array_create(hold_group.count);
                                        array_copy(hold_group.notes, 0, hold_group.originalNotes, 0, hold_group.count);
                                } else {
                                        hold_group.count = array_length(hold_group.notes);
                                };
                                for (var hold_note_i = 0; hold_note_i < hold_group.count; hold_note_i++) {
                                        var hold_record = hold_group.notes[hold_note_i];
                                        if (is_struct(hold_record)) then hold_record.activated = false;
                                };
                        };
                };
                if (bool(game_1._note_activation_enabled ?? false) && is_array(game_1._notes)) {
                        for (var activation_i = 0; activation_i < array_length(game_1._notes); activation_i++) {
                                var activation_note = game_1._notes[activation_i];
                                if (!is_struct(activation_note)) then continue;
                                if (bool(activation_note.alwaysActive ?? false)) {
                                        var activation_key = string(activation_note.id);
                                        if (is_struct(game_1._note_activation_records)
                                                && struct_exists(game_1._note_activation_records, activation_key)) {
                                                rpe_note_mark_activated(game_1._note_activation_records[$ activation_key]);
                                        };
                                } else {
                                        instance_deactivate_object(activation_note.id);
                                };
                        };
                };
        };
        with (oExtraPlay) {
                if (video_handle >= 0) then ffvideos_ext_close(video_handle);
                video_handle = -1;
                video_index = -1;
                video_completed = -1;
                video_chart_time = 0;
                video_last_chart_time = -infinity;
        };
        with (oRPEEffect) chart_time = 0;
}

function paused_ui_retry() {
        if (action_queued) then return;
        print("[PausedUI] Retry chart");
        action_queued = true;
        game.paused = true;
        m_pause();
        m_stop();
        with (oMedia) position = 0;
        paused_ui_reset_score();
        if (owner.object_index == oRender_1) then paused_ui_reset_rpe();
        else if (owner.object_index == oRender_2) then paused_ui_reset_pec();
        else paused_ui_reset_official();

        owner.chart_exit_started = false;
        owner.chart_exit_timer = 0;
        owner.chart_exit_alpha = 1;
        owner.chart_exit_queued = false;

        var retained_offset = game.__time[5];
        game.__time = [0, 0, 0, 0, 0, retained_offset];
        retry_ready = false;
        retry_waiting = true;
        retry_mode = 1;
        retry_started_at = get_timer();
        draw_logged = false;
}
