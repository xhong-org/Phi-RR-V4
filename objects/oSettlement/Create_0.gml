///@desc 创建结算界面、成绩数据和绘制函数
if (!variable_instance_exists(id, "owner")) then owner = noone;
depth = -12500;

started_at = get_timer();
started_frame = (variable_global_exists("render_frame") && is_real(global.render_frame))
	? global.render_frame : 0;
leaving = false;
leave_retry = false;
leave_started_at = 0;
leave_wait_at = -1;
consumed = false;

slide_dur = 1000000;
text_dur = 500000;
user_dur = 800000;
btn_dur = 800000;
rank_fade_dur = 300000;
rank_scale_dur = 1000000;
leave_fade_dur = 500000;
leave_wait_dur = 500000;
hold_dur = 3000000;
score_decel_t = 0.2;
hold_at = -1;
easing_complete = false;

slide_eased = 0;
user_alpha = 0;
retry_x = 0;
retry_y = 0;
cont_x = 0;
cont_y = 0;
box_alpha = [0, 0, 0];
score_show = 0;
score_record_line = "";
rank_alpha = 0;
rank_scale = 2;
rank_started = false;
rank_fade_at = -1;
rank_scale_at = -1;
fade_alpha = 0;
score_tween_at = -1;
box1_at = -1;
box2_at = -1;
other_done_at = -1;

illustration = -1;
illustration_owned = false;
rank_sprite = -1;
head_sprite = -1;
ending_sound = -1;
ending_inst = -1;
ending_fmod = false;
ending_gm_buf = -1;

song_name = "";
song_level = "";
user_name = "";
score_value = 0;
best_prev = 0;
score_delta = 0;
score_gap = 0;
score_autoplay = false;
score_is_best = false;
perfect_count = 0;
good_count = 0;
bad_count = 0;
miss_count = 0;
max_combo = 0;
acc_value = 0;
early_count = 0;
late_count = 0;

illus_rest_cx = 0;
illus_rest_cy = 0;
illus_half = 0;
score_rest_x = 0;
score_w = 0;
score_h = 0;
score_bottom = 0;
combo_w = 0;
combo_h = 0;
combo_bottom = 0;
judge_w = 0;
judge_h = 0;
judge_bottom = 0;
box_d = 0;
slide_dist = 0;
retry_rest_x = 0;
cont_rest_x = 0;
user_x = 0;
user_y = 0;
user_w = 0;
user_h = 0;
avatar_s = 0;
rank_cx = 0;
rank_cy = 0;
rank_base_scale = 1;

illus_cx = 0;
score_x = 0;
combo_x = 0;
judge_x = 0;
retry_hit = [0, 0, 0, 0];
cont_hit = [0, 0, 0, 0];

///@desc 取结算已经过的微秒，录像模式用帧换算
///@returns {Real} 已经过的微秒
function settlement_elapsed_us() {
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

///@desc 仅在本局高于已读取的历史分时写回。自动播放不记
///@param {Real} _score 本局分数
///@param {Real} _prev 写之前读到的历史最高分
///@returns {Undefined} 无
function settlement_best_write(_score, _prev) {
	if (chart_autoplay_active()) then return;
	var now_score = settlement_score_int(_score);
	var prev_score = settlement_score_int(_prev);
	// 平分或更低不覆盖。chart_score_set 还会再比一次已存分数。
	if (now_score <= prev_score) then return;
	chart_score_set(chart_score_md5(), now_score);
}

///@desc 按窗口缩放重算结算面板位置
///@returns {Undefined} 无
function settlement_refresh_layout() {
	var s = variable_global_exists("global_scales") ? global_scales : 1;
	if (!is_real(s) || s <= 0) then s = 1;
	// 结束遮罩放开后铺满窗口。用房间宽度，不用会跟着谱面宽高比滑动的 chart_view。
	var vw = room_width;
	if (!is_real(vw) || vw <= 0) then vw = 1366;
	illus_half = 210 * s;
	illus_rest_cx = 300 * s;
	illus_rest_cy = 390 * s;
	score_w = 560 * s;
	score_h = 150 * s;
	score_rest_x = 620 * s;
	score_bottom = 360 * s;
	combo_w = score_w;
	combo_h = 100 * s;
	combo_bottom = score_bottom + 16 * s + combo_h;
	judge_w = score_w;
	judge_h = 88 * s;
	judge_bottom = combo_bottom + 16 * s + judge_h;
	box_d = 100 * s;
	slide_dist = max(420 * s, vw * 0.42);
	retry_rest_x = 0;
	retry_y = 0;
	cont_rest_x = 0;
	cont_y = room_height;
	avatar_s = 72 * s;
	user_h = avatar_s;
	user_w = 360 * s;
	user_x = room_width - 12 * s - avatar_s;
	user_y = 10 * s;
	rank_base_scale = 1;
	if (asset_sprite_valid(rank_sprite)) {
		var rh = sprite_get_height(rank_sprite);
		if (rh > 0) then rank_base_scale = (score_h * 0.72) / rh;
	};
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
	_vol = clamp(real(_vol), 0, 1);
	// FMOD 和 GameMaker 音频分开调音量。
	if (ending_fmod) {
		if (ending_inst > 0 && instance_exists(oMedia)) {
			var media = instance_find(oMedia, 0);
			if (is_real(media.track) && media.track > 0) {
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
function settlement_stop_audio() {
	// FMOD 先停通道再释放声音。
	if (ending_fmod) {
		if (ending_inst > 0) {
			try {
				if (instance_exists(oMedia)) {
					var media = instance_find(oMedia, 0);
					if (is_real(media.track) && media.track > 0) then fmod_system_select(media.track);
				};
				fmod_channel_control_stop(ending_inst);
			} catch (stop_err) { delete(stop_err); };
			ending_inst = -1;
		};
		if (is_real(ending_sound) && ending_sound > 0 && extension_exists("FMOD")) {
			try { fmod_sound_release(ending_sound); } catch (rel_err) { delete(rel_err); };
		};
		ending_sound = -1;
		ending_fmod = false;
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
	if (extension_exists("FMOD") && instance_exists(oMedia) && !media_use_gx()) {
		var media = instance_find(oMedia, 0);
		if (is_real(media.track) && media.track > 0) {
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
				ending_inst = fmod_system_play_sound(loaded, false);
				if (ending_inst > 0) then fmod_channel_control_set_volume(ending_inst, 1);
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
		if (ending_inst != -1) then audio_sound_gain(ending_inst, 1, 0);
		print($"[Settlement] Ending GM wav loop path={path}");
		return;
	};
	print($"[Settlement] Ending load failed: {path}");
}

///@desc 开始离开淡出，并记下是重试还是继续
///@param {Bool} _retry 为真时离开后重试
///@returns {Undefined} 无
function settlement_begin_leave(_retry) {
	// 已经在离开或结算已消费就不再开始。
	if (leaving || consumed) then return;
	leaving = true;
	leave_retry = bool(_retry);
	leave_started_at = settlement_elapsed_us();
	leave_wait_at = -1;
}

///@desc 停掉结算音乐并重新开始本局
///@returns {Undefined} 无
function settlement_do_retry() {
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
// 先读历史分，再用这次读到的值决定文案。写回发生在文案确定之后。
best_prev = settlement_best_read();
score_value = settlement_score_int(score_value);
score_is_best = false;
score_delta = 0;
score_gap = 0;
score_record_line = "";
if (score_autoplay) {
	score_record_line = "AUTOPLAY";
} else if (score_value > best_prev) {
	// 没有历史记录时 best_prev 为 0，右侧就是 0000000 +本局分数。
	score_is_best = true;
	score_delta = score_value - best_prev;
	score_record_line = "NEW BEST " + ScoreSystemPad(best_prev) + " +" + ScoreSystemPad(score_delta);
	settlement_best_write(score_value, best_prev);
} else if (score_value < best_prev) {
	score_gap = best_prev - score_value;
	score_record_line = "BEST " + ScoreSystemPad(best_prev) + " -" + ScoreSystemPad(score_gap);
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

var rank_path = $"{working_directory}resource/rank/{settlement_rank_file(score_value, good_count, bad_count, miss_count)}";
rank_sprite = settlement_sprite_load(rank_path);
if (asset_sprite_valid(rank_sprite)) {
	sprite_set_offset(rank_sprite, sprite_get_width(rank_sprite) * 0.5, sprite_get_height(rank_sprite) * 0.5);
};

var head_path = $"{working_directory}resource/heads/default.png";
head_sprite = settlement_sprite_load(head_path);

settlement_play_ending();

settlement_refresh_layout();
score_x = score_rest_x + slide_dist;
combo_x = score_x + box_d;
judge_x = score_x + 2 * box_d;
illus_cx = illus_rest_cx + slide_dist;
retry_x = retry_rest_x - 240 * (variable_global_exists("global_scales") ? global_scales : 1);
cont_x = cont_rest_x + 240 * (variable_global_exists("global_scales") ? global_scales : 1);

///@desc 画一块斜切的结算面板
///@param {Real} _x 左下角 X
///@param {Real} _bottom 底边 Y
///@param {Real} _w 宽度
///@param {Real} _h 高度
///@param {Real} _skew 顶边右移量
///@param {Real} _a 透明度
///@returns {Undefined} 无
function settlement_draw_panel(_x, _bottom, _w, _h, _skew, _a) {
	var y1 = _bottom;
	var y0 = _bottom - _h;
	draw_primitive_begin(pr_trianglefan);
	draw_vertex_color(_x, y1, c_black, _a);
	draw_vertex_color(_x + _w, y1, c_black, _a);
	draw_vertex_color(_x + _w + _skew, y0, c_black, _a);
	draw_vertex_color(_x + _skew, y0, c_black, _a);
	draw_primitive_end();
}

///@desc 用精灵纹理画一颗菱形封面
///@param {Real} _cx 中心 X
///@param {Real} _cy 中心 Y
///@param {Real} _half 中心到顶点的距离
///@param {Asset.GMSprite} _spr 封面精灵
///@param {Real} _col 染色
///@param {Real} _a 透明度
///@returns {Undefined} 无
function settlement_draw_textured_diamond(_cx, _cy, _half, _spr, _col, _a) {
	// 没有精灵或完全透明就不画。
	if (!asset_sprite_valid(_spr) || _a <= 0) then return;
	var tex = sprite_get_texture(_spr, 0);
	var uvs = sprite_get_uvs(_spr, 0);
	var sw = max(1, sprite_get_width(_spr));
	var sh = max(1, sprite_get_height(_spr));
	var sc = max((2 * _half) / sw, (2 * _half) / sh);
	var dw = sw * sc;
	var dh = sh * sc;
	var uc = (uvs[0] + uvs[2]) * 0.5;
	var vc = (uvs[1] + uvs[3]) * 0.5;
	var us = (uvs[2] - uvs[0]);
	var vs = (uvs[3] - uvs[1]);
	var u_l = uc - (_half / dw) * us;
	var u_r = uc + (_half / dw) * us;
	var v_t = vc - (_half / dh) * vs;
	var v_b = vc + (_half / dh) * vs;
	draw_primitive_begin_texture(pr_trianglefan, tex);
	draw_vertex_texture_colour(_cx, _cy - _half, uc, v_t, _col, _a);
	draw_vertex_texture_colour(_cx + _half, _cy, u_r, vc, _col, _a);
	draw_vertex_texture_colour(_cx, _cy + _half, uc, v_b, _col, _a);
	draw_vertex_texture_colour(_cx - _half, _cy, u_l, vc, _col, _a);
	draw_primitive_end();
}

///@desc 画一颗纯色菱形底
///@param {Real} _cx 中心 X
///@param {Real} _cy 中心 Y
///@param {Real} _half 中心到顶点的距离
///@param {Real} _col 颜色
///@param {Real} _a 透明度
///@returns {Undefined} 无
function settlement_draw_diamond_frame(_cx, _cy, _half, _col, _a) {
	draw_primitive_begin(pr_trianglefan);
	draw_vertex_color(_cx, _cy - _half, _col, _a);
	draw_vertex_color(_cx + _half, _cy, _col, _a);
	draw_vertex_color(_cx, _cy + _half, _col, _a);
	draw_vertex_color(_cx - _half, _cy, _col, _a);
	draw_primitive_end();
}

///@desc 画菱形封面的四边框
///@param {Real} _cx 中心 X
///@param {Real} _cy 中心 Y
///@param {Real} _half 中心到顶点的距离
///@param {Real} _col 颜色
///@param {Real} _a 透明度
///@returns {Undefined} 无
function settlement_draw_diamond_ring(_cx, _cy, _half, _col, _a) {
	var lw = max(1, 2 * (variable_global_exists("global_scales") ? global_scales : 1));
	draw_set_colour(_col);
	draw_set_alpha(_a);
	draw_line_width(_cx, _cy - _half, _cx + _half, _cy, lw);
	draw_line_width(_cx + _half, _cy, _cx, _cy + _half, lw);
	draw_line_width(_cx, _cy + _half, _cx - _half, _cy, lw);
	draw_line_width(_cx - _half, _cy, _cx, _cy - _half, lw);
}

///@desc 画右上角玩家名和头像
///@param {Real} _s 界面缩放
///@returns {Undefined} 无
function settlement_draw_user(_s) {
	draw_set_alpha(user_alpha);
	var ax = user_x;
	var ay = user_y;
	var ah = user_h;
	var aw = user_w;
	draw_primitive_begin(pr_trianglefan);
	draw_vertex_color(ax - aw, ay + ah, c_black, 0.78 * user_alpha);
	draw_vertex_color(ax, ay + ah, c_black, 0.78 * user_alpha);
	draw_vertex_color(ax + 16 * _s, ay, c_black, 0.78 * user_alpha);
	draw_vertex_color(ax - aw + 16 * _s, ay, c_black, 0.78 * user_alpha);
	draw_primitive_end();
	if (asset_sprite_valid(head_sprite)) {
		draw_sprite_stretched_ext(head_sprite, 0, ax, ay, avatar_s, avatar_s, c_white, user_alpha);
	} else {
		draw_set_colour(c_white);
		draw_rectangle(ax, ay, ax + avatar_s, ay + avatar_s, false);
	};
	draw_set_colour(c_white);
	draw_set_halign(fa_right);
	draw_set_valign(fa_middle);
	draw_set_alpha(user_alpha);
	draw_text_transformed(ax - 12 * _s, ay + ah * 0.5, user_name, 0.32 * _s, 0.32 * _s, 0);
}

///@desc 画左上角重试按钮
///@param {Real} _s 界面缩放
///@returns {Undefined} 无
function settlement_draw_retry(_s) {
	var bar_h = 72 * _s;
	var x0 = retry_x;
	draw_primitive_begin(pr_trianglefan);
	draw_vertex_color(x0, 0, c_black, 0.92);
	draw_vertex_color(x0 + 168 * _s, 0, c_black, 0.92);
	draw_vertex_color(x0 + 118 * _s, bar_h, c_black, 0.92);
	draw_vertex_color(x0, bar_h, c_black, 0.92);
	draw_primitive_end();
	var sc = 0.55 * _s;
	draw_sprite_ext(spr_retry, 0,
		x0 + 38 * _s - sprite_get_width(spr_retry) * sc * 0.5,
		bar_h * 0.5 - sprite_get_height(spr_retry) * sc * 0.5,
		sc, sc, 0, c_white, 1);
}

///@desc 画右下角继续按钮
///@param {Real} _s 界面缩放
///@returns {Undefined} 无
function settlement_draw_continue(_s) {
	var bar_h = 72 * _s;
	var x1 = room_width + cont_x;
	draw_primitive_begin(pr_trianglefan);
	draw_vertex_color(x1 - 168 * _s, room_height - bar_h, c_black, 0.92);
	draw_vertex_color(x1, room_height - bar_h, c_black, 0.92);
	draw_vertex_color(x1, room_height, c_black, 0.92);
	draw_vertex_color(x1 - 118 * _s, room_height, c_black, 0.92);
	draw_primitive_end();
	var sc = 0.5 * _s;
	draw_sprite_ext(spr_resume, 0,
		x1 - 48 * _s - sprite_get_width(spr_resume) * sc * 0.5,
		room_height - bar_h * 0.5 - sprite_get_height(spr_resume) * sc * 0.5,
		sc, sc, 0, c_white, 1);
}
