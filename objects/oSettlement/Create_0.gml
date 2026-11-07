///@desc 创建结算界面、成绩数据和绘制函数
if (!variable_instance_exists(id, "owner")) then owner = noone;
depth = -12500;

started_at = get_timer();
started_frame = (variable_global_exists("render_frame") && is_real(global.render_frame))
	? global.render_frame : 0;
animation_started = false;
leaving = false;
leave_retry = false;
leave_started_at = 0;
leave_wait_at = -1;
consumed = false;

leave_fade_dur = 500000;
leave_wait_dur = 500000;
hold_dur = render_settlement_hold_seconds() * 1000000;
animation_dur = settlement_animation_seconds() * 1000000;
easing_complete = false;
page_eased = 0;
art_eased = 0;
score_eased = 0;
record_eased = 0;
stats_eased = 0;
judge_eased = [0, 0, 0, 0];
footer_eased = 0;
panel_eased = [0, 0, 0];
edge_eased = 0;
avatar_eased = 0;
player_expanded = false;
player_state_saved = false;
player_reveal = 0;
player_reveal_from = 0;
player_reveal_started = 0;
player_reveal_duration = 530000;
player_hover = false;
player_hit = [0, 0, 0, 0];
player_head_cut = 0;
player_name_width = 0;
sync_state = 0; // 0 无写入，1 等待展开／保存，2 已保存，3 保存失败
sync_reveal = 0;
sync_text_alpha = 0;
sync_pending_caption = false;
sync_attempt_started_at = 1980000;
sync_retrying = false;
sync_save_ready_at = 3213333; // 首次展开400ms后，至少完整播放一轮同步中动画
sync_completed_at = -1;
sync_fully_drawn = false;
score_save_md5 = "";
score_save_attempted = false;
toast_eased = 0;
toast_border_alpha = 0;
toast_text_eased = 0;
settlement_data_bytes = 0;
data_sprite = -1;
score_show = 0;
score_status = "";
score_record_line = "";
rank_alpha = 0;
rank_scale = 1;
rank_flash = 0;
fade_alpha = 0;
input_armed = false;
retry_hover = false;
cont_hover = false;
ui_font = pls_ui_font_add(47);

illustration = -1;
illustration_owned = false;
background_sprite = -1;
background_owned = false;
rank_sprite = -1;
head_sprite = -1;
player_head_name = "default.png";
player_badge_sprite = -1;
player_badge_name = "rainbow";
player_rank_level = 48;
player_rating = 16;
ending_sound = -1;
ending_inst = -1;
ending_fmod = false;
ending_system = -1;
ending_gm_buf = -1;

song_name = "";
song_level = "";
user_name = "";
score_value = 0;
best_prev = 0;
score_delta = 0;
score_gap = 0;
score_autoplay = false;
score_recording = false;
score_is_best = false;
perfect_count = 0;
good_count = 0;
bad_count = 0;
miss_count = 0;
max_combo = 0;
acc_value = 0;
early_count = 0;
late_count = 0;
layout_scale = 1;
layout_x = 0;
layout_y = 0;
layout_width = 1920;
edge_scale = 1;
art_width = 0;
detail_x = 0;
detail_width = 0;
retry_hit = [0, 0, 0, 0];
cont_hit = [0, 0, 0, 0];
colour_panel = c_black;
panel_alpha = 0.66;
button_cut = 30;

///@desc 取结算已经过的微秒，录像模式用帧换算
///@returns {Real} 已经过的微秒
function settlement_elapsed_us() {
	if (!animation_started) then return 0;
	// 录像用渲染帧，交互用墙钟。
	if (variable_global_exists("render_mode") && global.render_mode) {
		return max(0, (global.render_frame - started_frame) / max(1, global.render_fps) * 1000000);
	};
	return max(0, get_timer() - started_at);
}

///@desc 从路径加载一张结算用精灵
///@param {String} _path 图片路径
///@returns {Asset.GMSprite} 精灵资源，失败为 -1
function settlement_sprite_load(_path) {
	// 路径空或文件不存在就失败。
	if (!is_string(_path) || !string_length(_path)) then return -1;
	if (!file_exists(_path) && !isExists(_path)) then return -1;
	var spr = sprite_add(_path, 0, false, false, 0, 0);
	// 单帧加载失败时再按一帧图集试一次。
	if (!asset_sprite_valid(spr)) then spr = sprite_add(_path, 1, false, false, 0, 0);
	if (!asset_sprite_valid(spr)) then return -1;
	return spr;
}

///@desc 按分数和判定选出评级图片名
///@param {Real} _score 分数
///@param {Real} _good Good 数
///@param {Real} _bad Bad 数
///@param {Real} _miss Miss 数
///@returns {String} 评级文件名
function settlement_rank_file(_score, _good, _bad, _miss) {
	// 没有 Bad 和 Miss 但有 Good 是 FC，满分是 phi。
	if (_bad == 0 && _miss == 0 && _good > 0) then return "FC.png";
	if (_score == 1000000) then return "phi.png";
	if (_score < 700000) then return "F.png";
	if (_score >= 700000 && _score < 820000) then return "C.png";
	if (_score >= 820000 && _score < 880000) then return "B.png";
	if (_score >= 880000 && _score < 920000) then return "A.png";
	if (_score >= 920000 && _score < 960000) then return "S.png";
	if (_score >= 960000 && _score < 1000000) then return "V.png";
	return "phi.png";
}

///@desc 按难度取结算音乐序号
///@param {String} _level 难度文字
///@returns {Real} 结算音乐序号
function settlement_ending_index(_level) {
	return chart_ending_index(_level);
}

///@desc 把分数收成非负整数。按位结果是 int64，不能用 is_real 判断
///@param {Any} _value 分数
///@returns {Real} 非负整数，无效时为 0
function settlement_score_int(_value) {
	if (!is_numeric(_value)) then return 0;
	var n = real(_value);
	if (!is_finite(n) || n < 0) then return 0;
	return floor(n);
}

///@desc 读取当前谱面的历史最高分。没有记录时为 0，显示成 0000000
///@returns {Real} 已保存的最高分
function settlement_best_read() {
	return settlement_score_int(chart_score_get(chart_score_md5()));
}

///@desc 仅在本局高于已读取的历史分时写回；由同步板完整显示后调用
///@param {Real} _score 本局分数
///@param {Real} _prev 写之前读到的历史最高分
///@returns {Bool} 本地成绩确实保存成功
function settlement_best_write(_score, _prev) {
	if (score_recording || score_autoplay || chart_autoplay_active()) then return false;
	var now_score = settlement_score_int(_score);
	var prev_score = settlement_score_int(_prev);
	// 平分或更低不覆盖。chart_score_set 还会再比一次已存分数。
	if (now_score <= prev_score) then return false;
	return chart_score_set(score_save_md5, now_score);
}

///@desc 成绩提示优先级：录像、自动、手动新纪录；等于／低于旧纪录时留空
function settlement_refresh_score_caption() {
    score_status = "";
    score_record_line = "";
    score_is_best = false;
    score_delta = 0;
    score_gap = 0;
    if (score_recording) {
        score_status = "RECORD";
    } else if (score_autoplay) {
        score_status = "AUTOPLAY";
    } else if (score_value > best_prev) {
        score_is_best = true;
        score_delta = score_value - best_prev;
        score_status = "NEW BEST";
        score_record_line = ScoreSystemPad(best_prev) + " +" + ScoreSystemPad(score_delta);
    };
}

///@desc 等同步板与文字完整绘制过一帧后才写入本地成绩，每次同步最多写入一次
function settlement_update_score_save(_now_us) {
    if (sync_state != 1 || score_save_attempted || !sync_fully_drawn || _now_us < sync_save_ready_at) then return;
    if (score_recording || score_autoplay) { sync_state = 0; return; };
    score_save_attempted = true;
    var ok = false;
    try { ok = self.settlement_best_write(score_value, best_prev); } catch (save_error) {
        print("[Settlement] Local score save failed: " + string(save_error.message ?? "unknown"));
        delete(save_error);
    };
    sync_state = ok ? 2 : 3;
    sync_completed_at = _now_us;
}

///@desc 失败后保留展开的底板，只重播同步中动画，再尝试保存
function settlement_retry_score_sync(_now_us) {
    if (leaving || consumed || sync_state != 3 || score_recording || score_autoplay
        || _now_us - sync_completed_at < 400000) then return false;
    sync_state = 1;
    sync_attempt_started_at = _now_us;
    sync_retrying = true;
    sync_save_ready_at = _now_us + 833333;
    sync_completed_at = -1;
    sync_reveal = 1;
    sync_text_alpha = 1;
    sync_pending_caption = true;
    sync_fully_drawn = false;
    score_save_attempted = false;
    return true;
}

///@desc 按窗口缩放重算结算面板位置
///@returns {Undefined} 无
function settlement_refresh_layout() {
	edge_scale = max(0.01, sqrt((room_width / 1920) * (room_height / 1080)));
	// 两份官方录像的主体按宽度同比缩放，4:3 保持较矮并居中。
	// 极宽屏只限制主体高度；屏幕角落的按钮单独锚定。
	// 极宽屏主体收进安全边距：手机录屏的曲绘顶边约121px，头像底边约104px。
	// 同时为伸缩用户名与分数板保留空隙；常规4:3、16:9仍按宽度缩放。
	var safe_scale = (room_height * 0.5 - 140 * edge_scale - max(12, 20 * edge_scale)) / 313;
	layout_scale = max(0.01, min(room_width / 1920, room_height / 940, safe_scale));
	layout_width = 1920;
	layout_x = (room_width - 1920 * layout_scale) * 0.5;
	layout_y = room_height * 0.5 - 540 * layout_scale;
	art_width = 1001;
	detail_x = 1049;
	detail_width = 784;
	// 角落 UI 同时随宽高缩放，几何平均贴合 4:3／16:9 实录。
	// 旧 min() 在宽屏时被高度锁住，头像、徽章和按钮明显偏小。
	var e = edge_scale;
	var retry_x = -180 * e * (1 - edge_eased);
	var continue_x = room_width - 175 * e + 180 * e * (1 - footer_eased);
	retry_hit = [retry_x, 10 * e, retry_x + 173.4 * e, 124.8 * e];
	cont_hit = [continue_x, room_height - 122 * e, continue_x + 175 * e, room_height - 10 * e];
	// 头像和右侧徽章固定，用户名只向头像左边展开。
	var player_dx = 300 * e * (1 - avatar_eased);
	player_head_cut = 29 * e;
	player_hit = [room_width - 300 * e + player_dx, 22 * e,
		room_width - 95 * e + player_dx, 140 * e];
}

///@desc 按按钮的实际梯形判断指针，斜边外的空角不响应点击
function settlement_button_contains(_rect, _px, _py, _cut) {
	if (!point_in_rectangle(_px, _py, _rect[0], _rect[1], _rect[2], _rect[3])) then return false;
	var t = clamp((_py - _rect[1]) / max(1, _rect[3] - _rect[1]), 0, 1);
	var cut = _cut * edge_scale;
	if (cut >= 0) then return _px <= _rect[2] - cut * t;
	return _px >= _rect[0] - cut * (1 - t);
}

///@desc 取当前难度对应的结算音乐路径
///@returns {String} 音乐文件路径
function settlement_ending_path() {
	return chart_ending_path(song_level);
}

///@desc 设置结算音乐音量
///@param {Real} _vol 0 到 1 的音量
///@returns {Undefined} 无
function settlement_set_ending_volume(_vol) {
	_vol = clamp(real(_vol), 0, 1) * settings_store().musicVolume;
	// FMOD 和 GameMaker 音频分开调音量。
	if (ending_fmod) {
		if (ending_inst > 0 && instance_exists(oMedia)) {
			var media = instance_find(oMedia, 0);
			if (media.track == ending_system && skin_fmod_system_live(ending_system)) {
				fmod_system_select(media.track);
				fmod_channel_control_set_volume(ending_inst, _vol);
			};
		};
		return;
	};
	if (ending_inst != -1 && audio_exists(ending_inst)) then audio_sound_gain(ending_inst, _vol, 0);
}

///@desc 停止并释放结算音乐
///@returns {Undefined} 无
function settlement_stop_audio(_closing_system = -1) {
	// FMOD 先停通道再释放声音。
	if (ending_fmod) {
		var live = (_closing_system > 0 && ending_system == _closing_system) || skin_fmod_system_live(ending_system);
		var voice = ending_inst;
		var sound = ending_sound;
		var system = ending_system;
		ending_inst = -1;
		ending_sound = -1;
		ending_system = -1;
		ending_fmod = false;
		if (live) {
			fmod_system_select(system);
			if (voice > 0) then fmod_channel_control_stop(voice);
			if (is_real(sound) && sound > 0) then fmod_sound_release(sound);
		};
		return;
	};
	if (ending_inst != -1) {
		if (audio_exists(ending_inst) && audio_is_playing(ending_inst)) then audio_stop_sound(ending_inst);
		ending_inst = -1;
	};
	if (ending_sound != -1 && audio_exists(ending_sound)) {
		try { audio_free_buffer_sound(ending_sound); } catch (free_err) {
			delete(free_err);
			try { audio_destroy_stream(ending_sound); } catch (stream_err) { delete(stream_err); };
		};
	};
	ending_sound = -1;
	if (ending_gm_buf != -1 && buffer_exists(ending_gm_buf)) then buffer_delete(ending_gm_buf);
	ending_gm_buf = -1;
}

///@desc 循环播放结算音乐，录像模式不播
///@returns {Undefined} 无
function settlement_play_ending() {
	// 录像不在这里播结算音乐。
	if (variable_global_exists("render_mode") && global.render_mode) then return;
	var path = settlement_ending_path();
	// 文件不存在就放弃播放。
	if (!file_exists(path) && !isExists(path)) {
		print($"[Settlement] Ending file missing: {path}");
		return;
	};
	path = chart_file_readable_path(path);
	if (instance_exists(oMedia) && !media_use_gx()) {
		var media = instance_find(oMedia, 0);
		if (skin_fmod_system_live(media.track)) {
			fmod_system_select(media.track);
			var loaded = -1;
			try { loaded = fmod_system_create_sound(path, FMOD_MODE.LOOP_NORMAL); } catch (snd_err) {
				delete(snd_err);
				loaded = -1;
			};
			// 整段加载失败再试流式加载。
			if (!(is_real(loaded) && loaded > 0)) {
				try { loaded = fmod_system_create_stream(path, FMOD_MODE.LOOP_NORMAL); } catch (stream_err) {
					delete(stream_err);
					loaded = -1;
				};
			};
			if (is_real(loaded) && loaded > 0) {
				ending_sound = loaded;
				ending_fmod = true;
				ending_system = media.track;
				ending_inst = fmod_system_play_sound(loaded, false);
				settlement_set_ending_volume(1);
				print($"[Settlement] Ending FMOD loop path={path}");
				return;
			};
			print($"[Settlement] FMOD ending failed result={fmod_last_result()} path={path}");
		};
	};
	var wav = skin_wav_make_sound(path);
	if (is_struct(wav) && audio_exists(wav.snd)) {
		ending_sound = wav.snd;
		ending_gm_buf = wav.buf;
		ending_inst = audio_play_sound(wav.snd, 1, true);
		settlement_set_ending_volume(1);
		print($"[Settlement] Ending GM wav loop path={path}");
		return;
	};
	print($"[Settlement] Ending load failed: {path}");
}

///@desc 离开前只写回用户名展开状态，录制不改用户配置
function settlement_save_player_state() {
	if (player_state_saved || (variable_global_exists("render_mode") && global.render_mode)) then return;
	player_state_saved = settings_save_player_expanded(player_expanded);
}

///@desc 开始离开淡出，并记下是重试还是继续
///@param {Bool} _retry 为真时离开后重试
///@returns {Undefined} 无
function settlement_begin_leave(_retry) {
	// 已经在离开或结算已消费就不再开始。
	if (leaving || consumed) then return;
	settlement_save_player_state();
	leaving = true;
	leave_retry = bool(_retry);
	leave_started_at = settlement_elapsed_us();
	leave_wait_at = -1;
}

///@desc 停掉结算音乐并重新开始本局
///@returns {Undefined} 无
function settlement_do_retry() {
	settlement_save_player_state();
	settlement_stop_audio();
	if (instance_exists(oPausedUI)) {
		with (oPausedUI) {
			action_queued = false;
			retry_waiting = false;
			retry_mode = 0;
			paused_ui_retry_prepare();
		};
	};
	if (instance_exists(oPlayTransition)) {
		with (oPlayTransition) play_transition_restart_intro();
	};
	consumed = true;
	instance_destroy();
}

///@desc 停掉结算音乐并回到入口
///@returns {Undefined} 无
function settlement_do_continue() {
	settlement_save_player_state();
	settlement_stop_audio();
	consumed = true;
	// 有过场就交给它收尾，否则直接拆播放。
	if (instance_exists(oPlayTransition)) {
		with (oPlayTransition) play_transition_finish_exit();
	} else {
		chart_playback_teardown_for_menu();
		pls_return_to_entry();
	};
}

if (variable_global_exists("game") && is_struct(game) && is_struct(game.folder_chart)) {
	song_name = string(game.folder_chart.name ?? "");
	song_level = string(game.folder_chart.level ?? "");
};
if (variable_global_exists("game") && is_struct(game) && is_struct(game.settings)) {
	user_name = string(game.settings.userName ?? "");
	player_head_name = settings_profile_head(game.settings[$ "userHead"] ?? "default.png");
	player_expanded = bool(settings_parse_value(game.settings[$ "userNameExpanded"] ?? false, false));
	// 默认展开时首帧就保持展开，头像仍跟随原来的整体入场。
	player_reveal = player_expanded ? 1 : 0;
	player_reveal_from = player_reveal;
	player_badge_name = settings_profile_badge(game.settings[$ "userRankBadge"] ?? "rainbow");
	var rank_level = game.settings[$ "userRankLevel"] ?? 48;
	if (is_numeric(rank_level) && is_finite(rank_level)) then player_rank_level = max(0, floor(rank_level));
	var rating = game.settings[$ "userRating"] ?? 16;
	if (is_numeric(rating) && is_finite(rating)) then player_rating = max(0, rating);
	settlement_data_bytes = settings_data_bytes(game.settings[$ "settlementDataBytes"] ?? 0);
};
// 没填玩家名时用 Guest。
if (!string_length(string_trim(user_name))) then user_name = "Guest";

accCalc();
score_value = ScoreSystemValue();
if (variable_global_exists("phi_state_list") && is_struct(phi_state_list)) {
	perfect_count = real(phi_state_list.prefect ?? 0);
	good_count = real(phi_state_list.good ?? 0);
	bad_count = real(phi_state_list.bad ?? 0);
	miss_count = real(phi_state_list.miss ?? 0);
	early_count = real(phi_state_list.early ?? 0);
	late_count = real(phi_state_list.late ?? 0);
	max_combo = real(phi_state_list.max_hitcombo ?? 0);
	acc_value = real(phi_state_list.acc ?? 0);
};
score_autoplay = chart_autoplay_active();
score_recording = variable_global_exists("render_mode") && bool(global.render_mode);
// 先读历史分，再用这次读到的值决定文案。写回发生在文案确定之后。
best_prev = settlement_best_read();
score_value = settlement_score_int(score_value);
settlement_refresh_score_caption();
if (score_is_best) {
    score_save_md5 = chart_score_md5();
    sync_state = 1;
};

var bg_path = "";
if (variable_global_exists("game") && is_struct(game) && is_struct(game.folder_chart)
	&& is_string(game.folder_chart.bg) && string_length(game.folder_chart.bg)) {
	bg_path = chart_in_path(game.folder_chart.bg);
};
illustration = settlement_sprite_load(bg_path);
if (asset_sprite_valid(illustration)) {
	illustration_owned = true;
} else if (variable_global_exists("game") && is_struct(game) && asset_sprite_valid(game.bg)) {
	illustration = game.bg;
	illustration_owned = false;
};

// 优先复用加载时保留的模糊曲绘。关闭游玩模糊时只为结算生成一份。
background_sprite = chart_blur_kept();
if (!asset_sprite_valid(background_sprite) && bool(game[$ "bg_blurred"] ?? false)
	&& asset_sprite_valid(game.bg)) then background_sprite = game.bg;
if (!asset_sprite_valid(background_sprite) && asset_sprite_valid(illustration)) {
	background_sprite = kawase_blur_sprite(illustration, 1, 0, 10, SPRITE_OFFSET.MIDDLE_CENTER);
	background_owned = asset_sprite_valid(background_sprite) && background_sprite != illustration;
};

var rank_path = $"{working_directory}resource/rank/{settlement_rank_file(score_value, good_count, bad_count, miss_count)}";
rank_sprite = settlement_sprite_load(rank_path);
if (asset_sprite_valid(rank_sprite)) {
	sprite_set_offset(rank_sprite, sprite_get_width(rank_sprite) * 0.5, sprite_get_height(rank_sprite) * 0.5);
};

var head_path = $"{working_directory}resource/heads/{player_head_name}";
head_sprite = settlement_sprite_load(head_path);
if (!asset_sprite_valid(head_sprite) && player_head_name != "default.png") {
	player_head_name = "default.png";
	head_sprite = settlement_sprite_load($"{working_directory}resource/heads/default.png");
};
data_sprite = settlement_sprite_load($"{working_directory}resource/data.png");
if (player_badge_name != "none") {
	player_badge_sprite = settlement_sprite_load($"{working_directory}resource/rank/{player_badge_name}.png");
};



///@desc 单一绝对时间轴，交互和录像使用相同的采样函数
function settlement_phase(_elapsed, _start, _duration) {
    return clamp((_elapsed - _start) / max(1, _duration), 0, 1);
}

///@desc 对录屏运动拟合的三次贝塞尔求时间反解；仅在动画中途迭代
function settlement_bezier(_phase, _x1, _y1, _x2, _y2) {
    if (_phase <= 0) then return 0;
    if (_phase >= 1) then return 1;
    var lo = 0; var hi = 1; var t = _phase;
    repeat (14) {
        var inv = 1 - t;
        var tx = 3 * inv * inv * t * _x1 + 3 * inv * t * t * _x2 + t * t * t;
        if (tx < _phase) then lo = t; else hi = t;
        t = (lo + hi) * 0.5;
    };
    var inv = 1 - t;
    return 3 * inv * inv * t * _y1 + 3 * inv * t * t * _y2 + t * t * t;
}

function settlement_update_animation(_now_us) {
    page_eased = 1;
    art_eased = settlement_bezier(settlement_phase(_now_us, 80000, 1254500), 0.13346, 1, 0.45297, 1);
    for (var i = 0; i < 3; i++) {
        // 前段依次错开，后段归并到曲绘的同一减速尾部。
        var extra = 750 / 1920 * (1 - Easings.OutQuad(settlement_phase(_now_us, 160000 + i * 130000, 420000)));
        panel_eased[@ i] = clamp(art_eased - extra, 0, 1);
    };
    score_eased = Easings.OutCubic(settlement_phase(_now_us, 420000, 350000));
    score_show = score_value;
    record_eased = score_eased;
    stats_eased = Easings.OutCubic(settlement_phase(_now_us, 820000, 380000));
    for (var i = 0; i < 4; i++) {
        judge_eased[@ i] = Easings.OutCubic(settlement_phase(_now_us, 1170000 + i * 30000, 300000));
    };
    edge_eased = Easings.OutQuart(settlement_phase(_now_us, 540000, 480000));
    avatar_eased = Easings.OutQuart(settlement_phase(_now_us, 600000, 480000));
    var player_raw = settlement_phase(_now_us, player_reveal_started, player_reveal_duration);
    var player_phase = player_raw >= 1 ? 1 : 1 - power(2, -10 * player_raw);
    player_reveal = lerp(player_reveal_from, player_expanded ? 1 : 0, player_phase);
    sync_reveal = sync_retrying ? 1 : Easings.OutQuart(settlement_phase(_now_us, sync_attempt_started_at, 400000));
    sync_text_alpha = sync_retrying ? 1 : Easings.OutCubic(settlement_phase(_now_us, sync_attempt_started_at + 200000, 200000));
    sync_pending_caption = sync_state == 1;
    if (sync_state == 3) {
        // 失败文字不交叉叠加：先让同步中消失，再淡入同步失败。
        var failure_age = max(0, _now_us - sync_completed_at);
        sync_pending_caption = failure_age < 180000;
        sync_text_alpha *= sync_pending_caption
            ? 1 - Easings.InOutCubic(settlement_phase(failure_age, 0, 180000))
            : Easings.InOutCubic(settlement_phase(failure_age, 180000, 220000));
    };
    if (sync_state == 2) {
        sync_reveal *= 1 - Easings.InOutCubic(settlement_phase(_now_us, sync_completed_at + 3180000, 550000));
        sync_text_alpha *= 1 - Easings.OutCubic(settlement_phase(_now_us, sync_completed_at + 2900000, 280000));
    };
    footer_eased = Easings.OutQuart(settlement_phase(_now_us, 900000, 520000));
    var rank_raw = settlement_phase(_now_us, 1280000, 600000);
    rank_alpha = Easings.InOutCubic(settlement_phase(_now_us, 1280000, 380000));
    // 官方实录初现约1.5倍，前段保持大轮廓，后段快速收拢到最终尺寸。
    var rank_shrink = settlement_bezier(settlement_phase(_now_us, 1360000, 600000), 1, 0.012, 0.7, 0.286);
    rank_scale = lerp(1.5, 1, rank_shrink);
    rank_flash = sin(rank_raw * pi) * (1 - rank_raw);
    toast_border_alpha = Easings.OutCubic(settlement_phase(_now_us, 2440000, 100000));
    toast_eased = settlement_bezier(settlement_phase(_now_us, 2750000, 500000), 0.4, 0, 0.25, 1);
    toast_text_eased = Easings.InOutCubic(settlement_phase(_now_us, 3040000, 600000));
    easing_complete = _now_us >= animation_dur;
}

///@desc 等到首帧资源齐备再起表，资源加载耗时不计入动画
function settlement_start_animation() {
    if (animation_started) then return;
    settlement_play_ending();
    started_at = get_timer();
    started_frame = (variable_global_exists("render_frame") && is_real(global.render_frame))
        ? global.render_frame : 0;
    animation_started = true;
    settlement_update_animation(0);
    settlement_refresh_layout();
}

function settlement_draw_background() {
    draw_set_colour(c_black);
    draw_set_alpha(1);
    draw_rectangle(0, 0, chart_frame_width(), chart_frame_height(), false);
    if (asset_sprite_valid(background_sprite)) {
        var sw = max(1, sprite_get_width(background_sprite));
        var sh = max(1, sprite_get_height(background_sprite));
        var fit = max(room_width / sw, room_height / sh);
        // 动态模糊精灵可能使用中心原点，显式抵消，避免画面偏移。
        draw_sprite_ext(background_sprite, 0, (room_width - sw * fit) * 0.5
            + sprite_get_xoffset(background_sprite) * fit, (room_height - sh * fit) * 0.5
            + sprite_get_yoffset(background_sprite) * fit, fit, fit, 0, c_white, 1);
    };
    draw_set_colour(c_black);
    draw_set_alpha(0.3);
    draw_rectangle(0, 0, chart_frame_width(), chart_frame_height(), false);
}

///@desc 设计坐标中的平行四边形，顶边向右平移 cut，文字不旋转
function settlement_draw_panel(_x, _y, _w, _h, _cut, _alpha) {
    if (_alpha <= 0) then return;
    var s = layout_scale;
    var x0 = layout_x + _x * s;
    var y0 = layout_y + _y * s;
    var x1 = x0 + _w * s;
    var y1 = y0 + _h * s;
    var cut = _cut * s;
    draw_primitive_begin(pr_trianglefan);
    draw_vertex_colour(x0 + cut, y0, colour_panel, panel_alpha * _alpha);
    draw_vertex_colour(x1, y0, colour_panel, panel_alpha * _alpha);
    draw_vertex_colour(x1 - cut, y1, colour_panel, panel_alpha * _alpha);
    draw_vertex_colour(x0, y1, colour_panel, panel_alpha * _alpha);
    draw_primitive_end();
}

function settlement_label_width(_text, _size) {
    var text = string_replace_all(string_replace_all(string(_text), "\r", " "), "\n", " " );
    return string_width(text) * _size / max(1, string_width("■"));
}

function settlement_draw_label(_text, _x, _y, _size, _colour, _alpha,
    _max_width = 10000, _align = fa_left, _ellipsize = false) {
    if (_alpha <= 0) then return;
    var text = string_replace_all(string_replace_all(string(_text), "\r", " "), "\n", " " );
    // Saira 的行框约为 em 的 1.49 倍，不能当作字身高度。
    var em = max(1, string_width("■"));
    var text_scale = _size / em;
    var fit_scale = _max_width / max(1, string_width(text));
    if (_ellipsize && fit_scale < text_scale * 0.8) {
        text_scale *= 0.8;
        var lo = 0;
        var hi = string_length(text);
        while (lo < hi) {
            var mid = ceil((lo + hi) * 0.5);
            if (string_width(string_copy(text, 1, mid) + "...") * text_scale <= _max_width) then lo = mid;
            else hi = mid - 1;
        };
        text = string_copy(text, 1, lo) + "...";
    } else {
        text_scale = min(text_scale, fit_scale);
    };
    text_scale *= layout_scale;
    draw_set_colour(_colour);
    draw_set_alpha(_alpha);
    draw_set_halign(_align);
    draw_set_valign(fa_middle);
    var baseline_fix = (string_height("Mg") - em * 0.90) * 0.5 * text_scale;
    draw_text_transformed(layout_x + _x * layout_scale, layout_y + _y * layout_scale + baseline_fix,
        text, text_scale, text_scale, 0);
}

///@desc 曲绘等比 cover，再以真实纹理页 UV 裁成 15 度斜切面板
function settlement_draw_art(_x, _y, _w, _h, _cut, _alpha) {
    if (_alpha <= 0) then return;
    var s = layout_scale;
    var x0 = layout_x + _x * s;
    var x1 = x0 + _w * s;
    var y0 = layout_y + _y * s;
    var y1 = y0 + _h * s;
    var cut = _cut * s;
    if (asset_sprite_valid(illustration)) {
        var sw = max(1, sprite_get_width(illustration));
        var sh = max(1, sprite_get_height(illustration));
        var cover = max(_w / sw, _h / sh);
        var uw = _w / cover / sw;
        var vh = _h / cover / sh;
        var u0 = (1 - uw) * 0.5;
        var v0 = (1 - vh) * 0.5;
        var uv = sprite_get_uvs(illustration, 0);
        var du = uv[2] - uv[0];
        var dv = uv[3] - uv[1];
        draw_primitive_begin_texture(pr_trianglefan, sprite_get_texture(illustration, 0));
        draw_vertex_texture_colour(x0 + cut, y0, uv[0] + (u0 + uw * _cut / _w) * du, uv[1] + v0 * dv, c_white, _alpha);
        draw_vertex_texture_colour(x1, y0, uv[0] + (u0 + uw) * du, uv[1] + v0 * dv, c_white, _alpha);
        draw_vertex_texture_colour(x1 - cut, y1, uv[0] + (u0 + uw * (1 - _cut / _w)) * du, uv[1] + (v0 + vh) * dv, c_white, _alpha);
        draw_vertex_texture_colour(x0, y1, uv[0] + u0 * du, uv[1] + (v0 + vh) * dv, c_white, _alpha);
        draw_primitive_end();
    } else {
        settlement_draw_panel(_x, _y, _w, _h, _cut, _alpha);
    };
    // 仅给标题所在下缘加渐变，保留曲绘主体亮度。
    var strip = 128;
    var top_y = y1 - strip * s;
    var top_cut = cut * strip / _h;
    draw_primitive_begin(pr_trianglefan);
    draw_vertex_colour(x0 + top_cut, top_y, c_black, 0);
    draw_vertex_colour(x1 - cut + top_cut, top_y, c_black, 0);
    draw_vertex_colour(x1 - cut, y1, c_black, 0.65 * _alpha);
    draw_vertex_colour(x0, y1, c_black, 0.65 * _alpha);
    draw_primitive_end();
}

///@desc 屏幕边缘按钮，实际点击形状与斜边同步移动
function settlement_draw_button(_rect, _sprite, _cut, _hover, _alpha) {
    if (_alpha <= 0) then return;
    var e = edge_scale;
    var x0 = _rect[0];
    var y0 = _rect[1];
    var x1 = _rect[2];
    var y1 = _rect[3];
    var cut = abs(_cut) * e;
    var lt = x0 + (_cut < 0 ? cut : 0);
    var rb = x1 - (_cut > 0 ? cut : 0);
    draw_primitive_begin(pr_trianglefan);
    draw_vertex_colour(lt, y0, c_black, (0.88 + 0.12 * _hover) * _alpha);
    draw_vertex_colour(x1, y0, c_black, (0.88 + 0.12 * _hover) * _alpha);
    draw_vertex_colour(rb, y1, c_black, (0.88 + 0.12 * _hover) * _alpha);
    draw_vertex_colour(x0, y1, c_black, (0.88 + 0.12 * _hover) * _alpha);
    draw_primitive_end();
    draw_set_colour(c_white);
    draw_set_alpha(_alpha);
    var sx0 = _cut < 0 ? lt : x1;
    var sx1 = _cut < 0 ? x0 : rb;
    // 白条端面与按钮上下边保持水平，不使用会沿法线伸出的宽线段。
    var strip_half = 5 * e;
    draw_primitive_begin(pr_trianglefan);
    draw_vertex_colour(sx0 - strip_half, y0, c_white, _alpha);
    draw_vertex_colour(sx0 + strip_half, y0, c_white, _alpha);
    draw_vertex_colour(sx1 + strip_half, y1, c_white, _alpha);
    draw_vertex_colour(sx1 - strip_half, y1, c_white, _alpha);
    draw_primitive_end();
    // 与参考相同的细线图标；不依赖暂停界面的实心图标比例。
    var cx = (lt + rb) * 0.5;
    var cy = (y0 + y1) * 0.5;
    var line_w = max(1, 2 * e);
    if (_cut > 0) {
        // 十二点起顺时针绕到底部／左侧，箭头在左上并指向右上。
        cx = x0 + 72 * e;
        var radius = 24 * e;
        var old_x = cx + lengthdir_x(radius, 90);
        var old_y = cy + lengthdir_y(radius, 90);
        for (var i = 1; i <= 48; i++) {
            var ang = 90 - i * 315 / 48;
            var nx = cx + lengthdir_x(radius, ang);
            var ny = cy + lengthdir_y(radius, ang);
            draw_line_width(old_x, old_y, nx, ny, line_w);
            old_x = nx; old_y = ny;
        };
        draw_line_width(old_x, old_y, old_x - 10 * e, old_y + 1 * e, line_w);
        draw_line_width(old_x, old_y, old_x + 1 * e, old_y + 10 * e, line_w);
    } else {
        draw_line_width(cx - 20 * e, cy, cx + 20 * e, cy, line_w);
        draw_line_width(cx + 20 * e, cy, cx + 2 * e, cy - 18 * e, line_w);
        draw_line_width(cx + 20 * e, cy, cx + 2 * e, cy + 18 * e, line_w);
    };
}

///@desc 点击头像展开／收回；中途反向从当前进度续接，避免跳变
function settlement_toggle_player(_now_us) {
    if (leaving || consumed) then return;
    player_reveal_from = player_reveal;
    player_expanded = !player_expanded;
    player_reveal_started = _now_us;
}

///@desc 头像平行四边形的精确命中，排除两侧透明角
function settlement_player_contains(_px, _py) {
    if (!point_in_rectangle(_px, _py, player_hit[0], player_hit[1], player_hit[2], player_hit[3])) then return false;
    var t = clamp((_py - player_hit[1]) / max(1, player_hit[3] - player_hit[1]), 0, 1);
    var cut = player_head_cut;
    return _px >= player_hit[0] + cut * (1 - t) && _px <= player_hit[2] - cut * t;
}

///@desc 头像独立消耗本次按下，不把点击传给结算离开按钮
function settlement_player_input(_pointer, _now_us) {
    player_hover = input_armed && avatar_eased >= 0.95 && settlement_player_contains(_pointer.x, _pointer.y);
    if (!_pointer.pressed || !player_hover) then return false;
    settlement_toggle_player(_now_us);
    return true;
}

///@desc 同步板的绘制与点击共用当前伸缩后的斜切几何
function settlement_sync_geometry() {
    var e = room_width / 1920;
    var w = 182 * e * sync_reveal;
    var x0 = room_width * 0.5 - w * 0.5;
    return {x0: x0, x1: x0 + w, y0: 51 * e, y1: 91 * e, cut: min(11 * e, w * 0.3)};
}

function settlement_sync_contains(_px, _py) {
    if (sync_reveal <= 0) then return false;
    var rect = settlement_sync_geometry();
    if (!point_in_rectangle(_px, _py, rect.x0, rect.y0, rect.x1, rect.y1)) then return false;
    var t = clamp((_py - rect.y0) / max(1, rect.y1 - rect.y0), 0, 1);
    return _px >= rect.x0 + rect.cut * (1 - t) && _px <= rect.x1 - rect.cut * t;
}

///@desc 点击失败文案重试，独立消耗本次按下以免传给离开按钮
function settlement_sync_input(_pointer, _now_us) {
    if (!input_armed || !_pointer.pressed || sync_state != 3
        || !settlement_sync_contains(_pointer.x, _pointer.y)) then return false;
    return settlement_retry_score_sync(_now_us);
}

///@desc 同步提示采用独立斜板；失败保持可重试，成功停留后文字先淡出再收板
function settlement_draw_score_sync() {
    if (sync_state <= 0 || sync_reveal <= 0) then return;
    var now = settlement_elapsed_us();
    var e = room_width / 1920;
    var rect = settlement_sync_geometry();
    var x0 = rect.x0; var x1 = rect.x1;
    var y0 = rect.y0; var y1 = rect.y1; var cut = rect.cut;
    var flash = sync_state == 2 ? 1 - settlement_phase(now, sync_completed_at, 300000) : 0;
    draw_primitive_begin(pr_trianglefan);
    draw_vertex_colour(x0 + cut, y0, merge_colour(c_black, c_white, flash), 0.65 + 0.30 * flash);
    draw_vertex_colour(x1, y0, merge_colour(c_black, c_white, flash), 0.65 + 0.30 * flash);
    draw_vertex_colour(x1 - cut, y1, merge_colour(c_black, c_white, flash), 0.65 + 0.30 * flash);
    draw_vertex_colour(x0, y1, merge_colour(c_black, c_white, flash), 0.65 + 0.30 * flash);
    draw_primitive_end();
    if (sync_text_alpha <= 0) then return;
    var pending_caption = sync_state == 1 || (sync_state == 3 && sync_pending_caption);
    var caption = pending_caption ? "同步中" : (sync_state == 2 ? "同步成功" : "同步失败");
    var text_x = pending_caption ? x0 + 21 * e : (x0 + x1) * 0.5;
    settlement_draw_label(caption, (text_x - layout_x) / layout_scale,
        ((y0 + y1) * 0.5 - layout_y) / layout_scale, 22 * e / layout_scale, c_white,
        sync_text_alpha, (pending_caption ? 90 : 138) * e / layout_scale,
        pending_caption ? fa_left : fa_center);
    if (pending_caption) {
        var cycle = frac(max(0, now - sync_attempt_started_at - (sync_retrying ? 0 : 400000)) / 833333);
        for (var i = 0; i < 3; i++) {
            var age = cycle - i * 0.055;
            var alpha = age < 0 ? 0 : clamp(1 - age / 0.40, 0, 1);
            var bx = x0 + (116 + i * 14) * e;
            draw_primitive_begin(pr_trianglefan);
            draw_vertex_colour(bx + 2 * e, y0 + 17 * e, c_white, alpha * sync_text_alpha);
            draw_vertex_colour(bx + 11 * e, y0 + 17 * e, c_white, alpha * sync_text_alpha);
            draw_vertex_colour(bx + 9 * e, y0 + 23 * e, c_white, alpha * sync_text_alpha);
            draw_vertex_colour(bx, y0 + 23 * e, c_white, alpha * sync_text_alpha);
            draw_primitive_end();
        };
        // 写入只在后续 Step 执行，确保这次完整画面已经真正绘制。
        if (sync_state == 1 && sync_reveal >= 1 && sync_text_alpha >= 1) then sync_fully_drawn = true;
    };
}

///@desc 无表面的斜切头像，等比 cover，使用精灵真实纹理页 UV
function settlement_draw_player_head(_rect, _alpha) {
    var x0 = _rect[0]; var y0 = _rect[1];
    var x1 = _rect[2]; var y1 = _rect[3];
    var cut = player_head_cut;
    if (!asset_sprite_valid(head_sprite)) {
        draw_primitive_begin(pr_trianglefan);
        draw_vertex_colour(x0 + cut, y0, c_white, _alpha);
        draw_vertex_colour(x1, y0, c_white, _alpha);
        draw_vertex_colour(x1 - cut, y1, c_white, _alpha);
        draw_vertex_colour(x0, y1, c_white, _alpha);
        draw_primitive_end();
        return;
    };
    var sw = max(1, sprite_get_width(head_sprite));
    var sh = max(1, sprite_get_height(head_sprite));
    var cover = max((x1 - x0) / sw, (y1 - y0) / sh);
    var uw = (x1 - x0) / cover / sw;
    var vh = (y1 - y0) / cover / sh;
    var u0 = (1 - uw) * 0.5; var v0 = (1 - vh) * 0.5;
    var uv = sprite_get_uvs(head_sprite, 0);
    var du = uv[2] - uv[0]; var dv = uv[3] - uv[1];
    var uc = uw * cut / max(1, x1 - x0);
    draw_primitive_begin_texture(pr_trianglefan, sprite_get_texture(head_sprite, 0));
    draw_vertex_texture_colour(x0 + cut, y0, uv[0] + (u0 + uc) * du, uv[1] + v0 * dv, c_white, _alpha);
    draw_vertex_texture_colour(x1, y0, uv[0] + (u0 + uw) * du, uv[1] + v0 * dv, c_white, _alpha);
    draw_vertex_texture_colour(x1 - cut, y1, uv[0] + (u0 + uw - uc) * du, uv[1] + (v0 + vh) * dv, c_white, _alpha);
    draw_vertex_texture_colour(x0, y1, uv[0] + u0 * du, uv[1] + (v0 + vh) * dv, c_white, _alpha);
    draw_primitive_end();
}

///@desc 默认只显示头像与徽章；按名字实测宽度向左展开斜切底板
function settlement_draw_player() {
    if (avatar_eased <= 0) then return;
    var e = edge_scale;
    var dx = 300 * e * (1 - avatar_eased);
    var y0 = 30 * e; var y1 = 132 * e; var cut = player_head_cut;
    var available = max(1, room_width / e - 543);
    player_name_width = min(settlement_label_width(user_name, 46), available);
    var plate_left = player_hit[0] - 20 * e;
    // 固定黑底穿过头像后方到右屏缘，收起名字时左侧仍露出一小截斜边。
    draw_primitive_begin(pr_trianglefan);
    draw_vertex_colour(plate_left + cut, y0, c_black, avatar_eased);
    draw_vertex_colour(room_width + dx, y0, c_black, avatar_eased);
    draw_vertex_colour(room_width + dx, y1, c_black, avatar_eased);
    draw_vertex_colour(plate_left, y1, c_black, avatar_eased);
    draw_primitive_end();
    if (player_reveal > 0) {
        var width = (player_name_width + 64) * e;
        var x0 = plate_left - width * player_reveal;
        var x1 = player_hit[0] + cut;
        draw_primitive_begin(pr_trianglefan);
        draw_vertex_colour(x0 + cut, y0, c_black, avatar_eased);
        draw_vertex_colour(x1, y0, c_black, avatar_eased);
        draw_vertex_colour(x1 - cut, y1, c_black, avatar_eased);
        draw_vertex_colour(x0, y1, c_black, avatar_eased);
        draw_primitive_end();
        // 文字随左缘滑动，展开后在底板与头像之间居中；头像遮住未露出的右段。
        var clip_left = ceil(x0 + cut + 8 * e);
        var clip_right = ceil(player_hit[0] + cut);
        if (clip_right > clip_left) {
            pls_draw_flush();
            gpu_set_scissor(max(0, clip_left), max(0, floor(y0)),
                max(1, clip_right - max(0, clip_left)), max(1, ceil(y1 - y0)));
            var name_center = x0 + cut * 0.5 + (width + 20 * e) * 0.5;
            settlement_draw_label(user_name, (name_center - layout_x) / layout_scale,
                ((y0 + y1) * 0.5 - layout_y) / layout_scale, 46 * e / layout_scale,
                c_white, avatar_eased, player_name_width * e / layout_scale, fa_center, true);
            pls_draw_flush();
            chart_mask_scissor_clear();
        };
    };
    settlement_draw_player_head(player_hit, avatar_eased);
    // 小徽章贴图内已有斜边；none 时连同徽章内数字一起隐藏。
    if (player_badge_name != "none" && asset_sprite_valid(player_badge_sprite)) {
        // 发光贴图是 79×38，核心为 (9,9)..(70,29)；无光晕贴图为 61×20。
        // 对齐可见核心并等比缩放，不能把整张透明边距当作徽章主体拉伸。
        var badge_scale = 66 / 61 * e;
        var badge_glow = sprite_get_width(player_badge_sprite) > 70 ? 9 : 0;
        var badge_x = room_width - 89 * e + dx - badge_glow * badge_scale;
        var badge_y = 53 * e - badge_glow * badge_scale;
        draw_sprite_ext(player_badge_sprite, 0, badge_x, badge_y, badge_scale, badge_scale,
            0, c_white, avatar_eased);
        var badge_cx = badge_x + (badge_glow + 61 * 0.5) * badge_scale;
        // 把斜切徽章看作裁去两侧三角形的矩形，只按核心矩形中心校正X。
        settlement_draw_label(string(player_rank_level), (badge_cx - layout_x) / layout_scale,
            (55 * e - layout_y) / layout_scale, 32 * e / layout_scale, c_white, avatar_eased,
            54 * e / layout_scale, fa_center);
    };
    var rx0 = room_width - 116 * e + dx; var rx1 = room_width - 5 * e + dx;
    draw_primitive_begin(pr_trianglefan);
    draw_vertex_colour(rx0 + 8 * e, 92.5 * e, c_white, avatar_eased);
    draw_vertex_colour(rx1, 92.5 * e, c_white, avatar_eased);
    draw_vertex_colour(rx1 - 8 * e, 123.5 * e, c_white, avatar_eased);
    draw_vertex_colour(rx0, 123.5 * e, c_white, avatar_eased);
    draw_primitive_end();
    var rating_text = string_replace_all(string_format(player_rating, 1, 2), " ", "");
    settlement_draw_label(rating_text, ((rx0 + rx1) * 0.5 + e - layout_x) / layout_scale,
        (106 * e - layout_y) / layout_scale, 29 * e / layout_scale, c_black, avatar_eased,
        94 * e / layout_scale, fa_center);
}

function settlement_draw_rank(_x, _y) {
    if (rank_alpha <= 0 || !asset_sprite_valid(rank_sprite)) then return;
    var fit = min(190 / max(1, sprite_get_width(rank_sprite)), 200 / max(1, sprite_get_height(rank_sprite)));
    var size = fit * rank_scale * layout_scale;
    var px = layout_x + _x * layout_scale;
    var py = layout_y + _y * layout_scale;
    // 参考的光晕来自评级贴图，去掉额外圆环和弹跳。
    if (rank_flash > 0) {
        gpu_set_blendmode(bm_add);
        draw_sprite_ext(rank_sprite, 0, px, py, size * 1.12, size * 1.12, 0, c_white, rank_flash * 0.24 * rank_alpha);
        gpu_set_blendmode(bm_normal);
    };
    draw_sprite_ext(rank_sprite, 0, px, py, size, size, 0, c_white, rank_alpha);
}

///@desc 以字节为基础按1024换算，负数按绝对值选择单位并保留符号
function settlement_format_bytes(_bytes) {
    if (!is_numeric(_bytes) || !is_finite(_bytes)) then _bytes = 0;
    var units = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var value = abs(real(_bytes));
    var unit = 0;
    while (value >= 1024 && unit < array_length(units) - 1) { value /= 1024; unit++; };
    // 舍入后恰好达到下一档时继续换算，避免出现1024.00 KB。
    if (round(value * 100) / 100 >= 1024 && unit < array_length(units) - 1) { value /= 1024; unit++; };
    var sign_text = _bytes < 0 && round(value * 100) > 0 ? "-" : "";
    return sign_text + string_replace_all(string_format(value, 1, 2), " ", "") + " " + units[unit];
}

function settlement_draw_toast() {
    if (toast_border_alpha <= 0) then return;
    var e = edge_scale;
    var caption = lang("settlement.collected", "Collected");
    var value_text = settlement_format_bytes(settlement_data_bytes);
    var english = lang_current_id() == "en-US";
    // 中文沿用原来的固定三栏；英文只校正提示起点，并稍缩短消息框。
    var full_w = (english ? 560 : 584) * e;
    var w = full_w * toast_eased;
    var cut = 24 * e;
    var x0 = room_width * 0.5 - (w + cut) * 0.5;
    var y0 = room_height - 125 * e;
    var y1 = room_height - 38 * e;
    var x1 = x0 + w + cut;
    draw_primitive_begin(pr_trianglefan);
    draw_vertex_colour(x0 + cut, y0, c_black, 0.68 * toast_eased);
    draw_vertex_colour(x1, y0, c_black, 0.68 * toast_eased);
    draw_vertex_colour(x1 - cut, y1, c_black, 0.68 * toast_eased);
    draw_vertex_colour(x0, y1, c_black, 0.68 * toast_eased);
    draw_primitive_end();
    // 零宽时两条边重合为一根斜线；先淡入、短暂停留，再向两侧展开。
    for (var i = 0; i < (toast_eased <= 0 ? 1 : 2); i++) {
        var bx = i == 0 ? x0 : x1 - cut;
        draw_primitive_begin(pr_trianglefan);
        draw_vertex_colour(bx + cut - 3 * e, y0, c_white, toast_border_alpha);
        draw_vertex_colour(bx + cut + 3 * e, y0, c_white, toast_border_alpha);
        draw_vertex_colour(bx + 3 * e, y1, c_white, toast_border_alpha);
        draw_vertex_colour(bx - 3 * e, y1, c_white, toast_border_alpha);
        draw_primitive_end();
    };
    // 英文从中文提示的左缘起排，图标和数值保持中文的原有位置。
    var cy = (y0 + y1) * 0.5;
    var cx = room_width * 0.5;
    var chinese_width = min(settlement_label_width("已获得", 36), 156) * e;
    var caption_x = english ? cx - 134 * e - chinese_width : cx - 134 * e;
    settlement_draw_label(caption,
        (caption_x - layout_x) / layout_scale, (cy - layout_y) / layout_scale,
        36 * e / layout_scale, c_white, toast_text_eased, 156 * e / layout_scale, english ? fa_left : fa_right);
    if (toast_text_eased > 0 && asset_sprite_valid(data_sprite)) {
        var icon_scale = 36 * e / max(1, sprite_get_width(data_sprite));
        draw_sprite_ext(data_sprite, 0, cx - 68 * e, cy - sprite_get_height(data_sprite) * icon_scale * 0.5,
            icon_scale, icon_scale, 0, c_white, toast_text_eased);
    };
    settlement_draw_label(value_text,
        (cx - 15 * e - layout_x) / layout_scale, (cy - layout_y) / layout_scale,
        27 * e / layout_scale, c_white, toast_text_eased, 255 * e / layout_scale, fa_left);
}

settlement_update_animation(0);
settlement_refresh_layout();
