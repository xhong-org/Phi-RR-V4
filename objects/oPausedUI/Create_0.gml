///@desc 创建暂停界面、倒计时精灵和操作函数
if (!variable_instance_exists(id, "owner")) then owner = noone;
// 绘制结束在 oChartMask（-12000）贴回谱面之后。
depth = -99999999;

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
countdown_shown = -1;
// 这一轮实时 SDF 画出来是空的。关掉 SDF 把 TTF 光栅成普通精灵。
// 设置里的抗锯齿是交换链 MSAA，滤不到精灵内部像素，bm_normal 还会把覆盖度平方。
// 按屏幕字号的 2 倍烘焙，并保存预乘覆盖度。
countdown_em = 47 * 1.4;
countdown_supersample = 2;
countdown_font_size = ceil(countdown_em * countdown_supersample);
countdown_font = pls_ui_font_add(countdown_font_size, true, false, ord("0"), ord("9"), false);
countdown_sprites = [-1, -1, -1, -1];
if (font_exists(countdown_font)) {
    gpu_push_state();
    shader_reset();
    gpu_set_blendenable(true);
    gpu_set_texfilter(true);
    gpu_set_alphatestenable(false);
    draw_set_font(countdown_font);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
    draw_set_alpha(1);
    // 只烘焙倒计时用到的 1、2、3。
    for (var _bake_digit = 1; _bake_digit <= 3; _bake_digit++) {
        var _bake_text = string(_bake_digit);
        var _bake_pad = 16;
        var _bake_tw = max(1, ceil(string_width(_bake_text)));
        var _bake_th = max(1, ceil(string_height(_bake_text)));
        var _bake_w = _bake_tw + _bake_pad * 2;
        var _bake_h = _bake_th + _bake_pad * 2;
        var _bake_surface = surface_create(_bake_w, _bake_h);
        if (!surface_exists(_bake_surface)) then continue;
        surface_set_target(_bake_surface);
        draw_clear_alpha(c_black, 0);
        gpu_set_blendenable(true);
        gpu_set_texfilter(true);
        gpu_set_alphatestenable(false);
        // 直通 alpha：颜色只乘一次覆盖度，alpha 保持线性。
        gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
        draw_set_font(countdown_font);
        draw_set_colour(c_white);
        draw_set_alpha(1);
        draw_text(_bake_pad, _bake_pad, _bake_text);
        surface_reset_target();
        var _bake_sprite = sprite_create_from_surface(_bake_surface, 0, 0, _bake_w, _bake_h, false, true, _bake_w * 0.5, _bake_h * 0.5);
        surface_free(_bake_surface);
        if (sprite_exists(_bake_sprite)) then countdown_sprites[_bake_digit] = _bake_sprite;
    };
    gpu_pop_state();
    print($"[PausedUI] Saira sprites font={countdown_font} size={countdown_font_size} ss={countdown_supersample} 1={sprite_exists(countdown_sprites[1])} 2={sprite_exists(countdown_sprites[2])} 3={sprite_exists(countdown_sprites[3])}");
} else {
    print($"[PausedUI] Saira countdown font missing path={pls_bundled_font_path()}");
};

// 只有 Saira 精灵烘焙失败时才用线段数字。
///@desc 用像素精灵画一段七段数码管
///@param {Real} _x 左上角 X
///@param {Real} _y 左上角 Y
///@param {Real} _w 段宽度
///@param {Real} _h 段高度
///@returns {Undefined} 无
paused_ui_draw_bar = function(_x, _y, _w, _h) {
    var _sw = max(1, sprite_get_width(spr_pixel_2));
    var _sh = max(1, sprite_get_height(spr_pixel_2));
    draw_sprite_ext(spr_pixel_2, 0, _x, _y, max(_w, 1) / _sw, max(_h, 1) / _sh, 0, c_white, 1);
};
///@desc 用七段几何画一个倒计时数字
///@param {Real} _digit 要画的数字，只用 1、2、3
///@param {Real} _cx 中心 X
///@param {Real} _cy 中心 Y
///@param {Real} _height 数字高度
///@returns {Undefined} 无
paused_ui_draw_digit = function(_digit, _cx, _cy, _height) {
    var _h = max(48, _height);
    var _w = _h * 0.62;
    var _t = max(8, _h * 0.16);
    var _left = _cx - _w * 0.5;
    var _right = _cx + _w * 0.5 - _t;
    var _top = _cy - _h * 0.5;
    var _mid_y = _cy - _t * 0.5;
    var _bot = _cy + _h * 0.5 - _t;
    var _vh = (_h - _t) * 0.5;
    // 0 上，1 右上，2 右下，3 下，4 左下，5 左上，6 中。
    var _segs = [false, false, false, false, false, false, false];
    // 按数字点亮对应段。
    if (_digit == 1) {
        _segs[1] = true;
        _segs[2] = true;
    } else if (_digit == 2) {
        _segs[0] = true;
        _segs[1] = true;
        _segs[6] = true;
        _segs[4] = true;
        _segs[3] = true;
    } else {
        _segs[0] = true;
        _segs[1] = true;
        _segs[6] = true;
        _segs[2] = true;
        _segs[3] = true;
    };
    if (_segs[0]) then paused_ui_draw_bar(_left, _top, _w, _t);
    if (_segs[6]) then paused_ui_draw_bar(_left, _mid_y, _w, _t);
    if (_segs[3]) then paused_ui_draw_bar(_left, _bot, _w, _t);
    if (_segs[5]) then paused_ui_draw_bar(_left, _top, _t, _vh);
    if (_segs[1]) then paused_ui_draw_bar(_right, _top, _t, _vh);
    if (_segs[4]) then paused_ui_draw_bar(_left, _cy, _t, _vh);
    if (_segs[2]) then paused_ui_draw_bar(_right, _cy, _t, _vh);
};

///@desc 绘制暂停遮罩、倒计时或三个操作按钮
///@returns {Undefined} 无
paused_ui_draw = function() {
    // 不能操作，或既没暂停也没在倒计时，就不画。
    if (!paused_ui_can_control() || (!game.paused && !retry_waiting)) then exit;
    if (!draw_logged) {
        draw_logged = true;
        print($"[PausedUI] Menu draw paused={game.paused} retry={retry_waiting}");
    };
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
    // 继续播放时画倒计时，否则画三个按钮。
    if (retry_waiting && retry_mode == 2) {
        var _seconds_left = max(1, ceil((retry_delay - (get_timer() - retry_started_at)) / 1000000));
        shader_reset();
        draw_set_colour(c_white);
        draw_set_alpha(1);
        // 烘焙尺寸是字号乘超采样，缩回来才是屏幕上的大小。
        var _digit_scale = max(ui_scale, 0.5) / max(1, countdown_supersample);
        var _digit_x = chart_view_left + chart_view_width * 0.5;
        var _digit_y = chart_view_height * 0.5;
        var _digit_sprite = (is_array(countdown_sprites) && _seconds_left < array_length(countdown_sprites))
            ? countdown_sprites[_seconds_left] : -1;
        if (sprite_exists(_digit_sprite)) {
            var _digit_filter = gpu_get_texfilter();
            gpu_set_texfilter(true);
            gpu_set_alphatestenable(false);
            // 精灵颜色已经乘过覆盖度，用预乘混合。
            gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
            draw_sprite_ext(_digit_sprite, 0, _digit_x, _digit_y, _digit_scale, _digit_scale, 0, c_white, 1);
            gpu_set_blendmode(bm_normal);
            gpu_set_texfilter(_digit_filter);
        } else {
            gpu_set_texfilter(false);
            paused_ui_draw_digit(_seconds_left, _digit_x, _digit_y, 47 * 1.4 * max(ui_scale, 0.5));
        };
        pls_draw_flush();
        if (_seconds_left != countdown_shown) {
            countdown_shown = _seconds_left;
            print($"[PausedUI] Countdown draw {_seconds_left} sprite={sprite_exists(_digit_sprite)} at {_digit_x},{_digit_y} scale={_digit_scale}");
        };
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

///@desc 判断当前能否操作暂停界面
///@returns {Bool} 可以操作时为真
function paused_ui_can_control() {
	// 结算界面或非重试过场中禁止操作。
	if (instance_exists(oSettlement)) then return false;
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

///@desc 房间尺寸变化时重算暂停按钮位置
///@returns {Undefined} 无
function paused_ui_refresh_layout() {
	var _width = max(1, room_width);
	var _height = max(1, room_height);
	// 尺寸没变就不用重算。
	if (pause_layout_width == _width && pause_layout_height == _height) then return;
	pause_layout_width = _width;
	pause_layout_height = _height;
	var _scale = variable_global_exists("global_scales") ? global_scales : 1;
	pause_button_x = chart_view_left + 50 * _scale;
	pause_button_y = 50 * _scale;
	pause_button_radius = max(36, 42 * _scale);
}

///@desc 暂停播放并锁住非 Hold 音符坐标
///@returns {Undefined} 无
function paused_ui_pause() {
        // 还没开播或已经暂停就返回。
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

///@desc 从暂停进入继续倒计时
///@returns {Undefined} 无
function paused_ui_resume() {
        // 没在暂停就不开始倒计时。
        if (!paused_ui_can_control() || !game.paused) then return;
        retry_ready = false;
        retry_waiting = true;
        retry_mode = 2;
        retry_started_at = get_timer();
        draw_logged = false;
        countdown_shown = -1;
        print("[PausedUI] Resume countdown started");
}

///@desc 退出谱面并回到入口
///@returns {Undefined} 无
function paused_ui_back() {
        // 已经排队离开就不再重复触发。
        if (action_queued) then return;
        print("[PausedUI] Back to menu");
        action_queued = true;
        game.paused = true;
        m_pause();
        owner.chart_exit_started = true;
        owner.chart_exit_timer = get_timer();
        owner.chart_exit_alpha = 1;
        if (instance_exists(oPlayTransition)) {
                with (oPlayTransition) play_transition_finish_exit();
        } else {
                chart_playback_teardown_for_menu();
                if (variable_global_exists("pls_environment_run") && global.pls_environment_run) then game_end();
                else pls_return_to_entry();
        };
}

///@desc 清空分数、连击和打击特效
///@returns {Undefined} 无
function paused_ui_reset_score() {
        combo = 0;
        if (variable_global_exists("phi_state_list") && is_struct(phi_state_list)) {
                phi_state_list.prefect = 0;
                phi_state_list.good = 0;
                phi_state_list.bad = 0;
                phi_state_list.miss = 0;
                phi_state_list.early = 0;
                phi_state_list.late = 0;
                phi_state_list.acc = 0;
                phi_state_list.max_hitcombo = 0;
        };
        with (oEffectNew) effect_events = [];
        with (oEffect) {
                if (part_system_exists(p1)) then part_particles_clear(p1);
                _timer = get_timer();
        };
}

///@desc 把官谱判定线和音符复位到重试起点
///@returns {Undefined} 无
function paused_ui_reset_official() {
        // 加载动画还在时不复位。
        if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then return;
        instance_activate_object(oLine);
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
                image_alpha = 1;
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
        official_notes_refreeze_after_retry();
}

///@desc 把 PEC 判定线和音符复位到重试起点
///@returns {Undefined} 无
function paused_ui_reset_pec() {
        // 加载动画还在时不复位。
        if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then return;
        instance_activate_object(oLine_2);
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
                isMiss = false;
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
        pec_notes_refreeze_after_retry();
}

///@desc 把 RPE 判定线、音符和视频复位到重试起点
///@returns {Undefined} 无
function paused_ui_reset_rpe() {
        // 加载动画还在时不复位。
        if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then return;
        instance_activate_object(oNote_1);
        with (oLine_1) {
                // 每层事件游标和扩展计数都回到 0。
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
                // Hold 空间查询会把已激活项换出有效前缀，重试时把前缀重建回来。
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
                                                game_1._note_activation_records[$ activation_key].activated = true;
                                        };
                                } else {
                                        instance_deactivate_object(activation_note.id);
                                };
                        };
                };
        };
        with (oExtraPlay) {
                video_close_all();
                for (var _video_i = 0; _video_i < array_length(videos); _video_i++) {
                        videos[_video_i].completed = false;
                        videos[_video_i].error_logged = false;
                        if (videos[_video_i].duration_ms > 0) {
                                videos[_video_i].endTime = videos[_video_i].startTime + videos[_video_i].duration_ms / 1000;
                        } else {
                                videos[_video_i].endTime = infinity;
                        };
                };
                video_chart_time = 0;
                video_last_chart_time = -infinity;
        };
        with (oRPEEffect) chart_time = 0;
}

///@desc 停掉播放并把当前谱面和分数复位
///@returns {Undefined} 无
function paused_ui_retry_prepare() {
        game.paused = true;
        m_pause();
        m_stop();
        with (oMedia) position = 0;
        paused_ui_reset_score();
        // 按当前渲染器选择对应的复位路径。
        if (owner.object_index == oRender_1) then paused_ui_reset_rpe();
        else if (owner.object_index == oRender_2) then paused_ui_reset_pec();
        else paused_ui_reset_official();

        owner.chart_exit_started = false;
        owner.chart_exit_timer = 0;
        owner.chart_exit_alpha = 1;
        owner.chart_exit_queued = false;

        var retained_offset = game.__time[5];
        game.__time = [0, 0, 0, 0, 0, retained_offset];
}

///@desc 准备重试并重新播放开场
///@returns {Undefined} 无
function paused_ui_retry() {
        // 已经在离开流程里就不再重试。
        if (action_queued) then return;
        print("[PausedUI] Retry chart");
        action_queued = true;
        paused_ui_retry_prepare();
        retry_ready = false;
        retry_waiting = false;
        retry_mode = 0;
        action_queued = false;
        draw_logged = false;
        if (instance_exists(oPlayTransition)) {
                with (oPlayTransition) play_transition_restart_intro();
                print("[PausedUI] Retry prepare animation started");
        } else {
                m_play();
                game.Math.now(0);
                game.paused = false;
        };
}
