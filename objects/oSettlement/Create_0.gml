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

leave_fade_dur = 500000;
leave_wait_dur = 500000;
hold_dur = 3000000;
animation_dur = settlement_animation_seconds() * 1000000;
easing_complete = false;
page_eased = 0;
art_eased = 0;
score_eased = 0;
record_eased = 0;
stats_eased = 0;
judge_eased = [0, 0, 0, 0];
footer_eased = 0;
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
layout_width = 1366;
art_width = 0;
detail_x = 0;
detail_width = 0;
retry_hit = [0, 0, 0, 0];
cont_hit = [0, 0, 0, 0];
colour_panel = make_colour_rgb(80, 80, 80);
panel_alpha = 0.58;
button_cut = 30;

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
	// 以完整房间适配，结算不再受游玩视口和宽高比遮罩限制。
	layout_scale = max(0.01, min(room_width / 1366, room_height / 768));
	layout_width = min(1600, room_width / layout_scale);
	layout_x = (room_width - layout_width * layout_scale) * 0.5;
	layout_y = (room_height - 768 * layout_scale) * 0.5;
	art_width = layout_width * 0.40;
	detail_x = 52 + art_width + 48;
	detail_width = layout_width - detail_x - 52;
	var s = layout_scale;
	var button_y = layout_y + (674 + 16 * (1 - footer_eased)) * s;
	retry_hit = [layout_x + 52 * s, button_y, layout_x + (52 + art_width) * s, button_y + 66 * s];
	cont_hit = [layout_x + detail_x * s, button_y,
		layout_x + (layout_width - 52) * s, button_y + 66 * s];
}

///@desc 按按钮的实际梯形判断指针，斜边外的空角不响应点击
function settlement_button_contains(_rect, _px, _py, _cut) {
	if (!point_in_rectangle(_px, _py, _rect[0], _rect[1], _rect[2], _rect[3])) then return false;
	var t = clamp((_py - _rect[1]) / max(1, _rect[3] - _rect[1]), 0, 1);
	var cut = _cut * layout_scale;
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
	score_status = "AUTOPLAY";
	score_record_line = "BEST  " + ScoreSystemPad(best_prev);
} else if (score_value > best_prev) {
	// 没有历史记录时 best_prev 为 0，右侧就是 0000000 +本局分数。
	score_is_best = true;
	score_delta = score_value - best_prev;
	score_status = "NEW BEST";
	score_record_line = "BEST  " + ScoreSystemPad(best_prev) + "   +" + string(score_delta);
	settlement_best_write(score_value, best_prev);
} else {
	score_status = "BEST";
	score_gap = best_prev - score_value;
	score_record_line = ScoreSystemPad(best_prev);
	if (score_gap > 0) then score_record_line += "   -" + string(score_gap);
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

var head_path = $"{working_directory}resource/heads/default.png";
head_sprite = settlement_sprite_load(head_path);

settlement_play_ending();

settlement_refresh_layout();

///@desc 取一段动画的线性进度，所有入场动画共用绝对时间轴
///@returns {Real} 0 到 1 的进度
function settlement_phase(_elapsed, _start, _duration) {
	return clamp((_elapsed - _start) / max(1, _duration), 0, 1);
}

///@desc 铺满模糊曲绘并保持退场阶段已经完成的 0.3 黑底
function settlement_draw_background() {
	draw_set_colour(c_black);
	draw_set_alpha(1);
	draw_rectangle(0, 0, chart_frame_width(), chart_frame_height(), false);
	if (asset_sprite_valid(background_sprite)) {
		var sw = max(1, sprite_get_width(background_sprite));
		var sh = max(1, sprite_get_height(background_sprite));
		var fit = max(room_width / sw, room_height / sh);
		draw_sprite_stretched_ext(background_sprite, 0, (room_width - sw * fit) * 0.5,
			(room_height - sh * fit) * 0.5, sw * fit, sh * fit, c_white, 1);
	};
	draw_set_alpha(0.3);
	draw_rectangle(0, 0, chart_frame_width(), chart_frame_height(), false);
}

///@desc 在结算设计坐标中画矩形
function settlement_draw_rect(_x, _y, _w, _h, _colour, _alpha) {
	if (_alpha <= 0 || _w <= 0 || _h <= 0) then return;
	draw_set_colour(_colour);
	draw_set_alpha(_alpha);
	draw_rectangle(layout_x + _x * layout_scale, layout_y + _y * layout_scale,
		layout_x + (_x + _w) * layout_scale, layout_y + (_y + _h) * layout_scale, false);
}

///@desc 绘制灰色半透明梯形，负切角表示左侧倾斜；按钮只描斜边
function settlement_draw_trapezoid(_x, _y, _w, _h, _cut, _alpha, _outline = false) {
	if (_alpha <= 0 || _w <= 0 || _h <= 0) then return;
	var s = layout_scale;
	var x0 = layout_x + _x * s;
	var x1 = x0 + _w * s;
	var y0 = layout_y + _y * s;
	var y1 = y0 + _h * s;
	var cut = min(abs(_cut), _w * 0.5) * s;
	var left_top = x0 + (_cut < 0 ? cut : 0);
	var right_bottom = x1 - (_cut > 0 ? cut : 0);
	draw_primitive_begin(pr_trianglefan);
	draw_vertex_colour(left_top, y0, colour_panel, panel_alpha * _alpha);
	draw_vertex_colour(x1, y0, colour_panel, panel_alpha * _alpha);
	draw_vertex_colour(right_bottom, y1, colour_panel, panel_alpha * _alpha);
	draw_vertex_colour(x0, y1, colour_panel, panel_alpha * _alpha);
	draw_primitive_end();
	if (_outline) {
		draw_set_colour(c_white);
		draw_set_alpha(_alpha);
		if (_cut < 0) then draw_line_width(left_top, y0, x0, y1, max(1, 2 * s));
		else draw_line_width(x1, y0, right_bottom, y1, max(1, 2 * s));
	};
}

///@desc 计算指定字号在设计坐标中的宽度，和文字绘制使用同一缩放
function settlement_label_width(_text, _size) {
	var text = string_replace_all(string_replace_all(string(_text), "\r", " "), "\n", " ");
	return string_width(text) * _size / max(1, string_height("Mg"));
}

///@desc 按文字宽度绘制状态或历史分底纹，最长不超过当前列
function settlement_draw_tag(_text, _x, _y, _alpha, _max_width) {
	var width = min(_max_width, settlement_label_width(_text, 20) + 24);
	settlement_draw_rect(_x, _y, width, 32, colour_panel, panel_alpha * _alpha);
	settlement_draw_label(_text, _x + 12, _y + 16, 20, c_white, _alpha, width - 24);
}

///@desc 按目标字号和最大宽度绘制文字，过长的曲名和玩家名可省略尾部
function settlement_draw_label(_text, _x, _y, _size, _colour, _alpha,
	_max_width = 10000, _align = fa_left, _ellipsize = false) {
	if (_alpha <= 0) then return;
	var text = string_replace_all(string_replace_all(string(_text), "\r", " "), "\n", " ");
	var text_scale = _size / max(1, string_height("Mg"));
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
	draw_text_transformed(layout_x + _x * layout_scale, layout_y + _y * layout_scale,
		text, text_scale, text_scale, 0);
}

///@desc 用局部 UV 等比裁剪曲绘为斜切面板，不额外创建表面
function settlement_draw_art(_x, _y, _w, _h, _cut, _alpha) {
	var s = layout_scale;
	var x0 = layout_x + _x * s;
	var x1 = x0 + _w * s;
	var xb = x1 - _cut * s;
	var y0 = layout_y + _y * s;
	var y1 = y0 + _h * s;
	if (asset_sprite_valid(illustration)) {
		var sw = max(1, sprite_get_width(illustration));
		var sh = max(1, sprite_get_height(illustration));
		var scale_cover = max(_w / sw, _h / sh);
		var uw = _w / scale_cover / sw;
		var vh = _h / scale_cover / sh;
		var u0 = (1 - uw) * 0.5;
		var v0 = (1 - vh) * 0.5;
		// draw_vertex_texture_colour 接收精灵的局部 UV，不能再次映射图集坐标。
		draw_primitive_begin_texture(pr_trianglefan, sprite_get_texture(illustration, 0));
		draw_vertex_texture_colour(x0, y0, u0, v0, c_white, _alpha);
		draw_vertex_texture_colour(x1, y0, u0 + uw, v0, c_white, _alpha);
		draw_vertex_texture_colour(xb, y1, u0 + uw * (1 - _cut / _w), v0 + vh, c_white, _alpha);
		draw_vertex_texture_colour(x0, y1, u0, v0 + vh, c_white, _alpha);
		draw_primitive_end();
	};
	// 下缘加深，缺少曲绘时也保留完整面板和文字。
	draw_primitive_begin(pr_trianglefan);
	draw_vertex_colour(x0, y0, make_colour_rgb(16, 23, 33), 0.12 * _alpha);
	draw_vertex_colour(x1, y0, make_colour_rgb(16, 23, 33), 0.12 * _alpha);
	draw_vertex_colour(xb, y1, make_colour_rgb(6, 10, 17), 0.96 * _alpha);
	draw_vertex_colour(x0, y1, make_colour_rgb(6, 10, 17), 0.96 * _alpha);
	draw_primitive_end();
	draw_set_colour(c_white);
	draw_set_alpha(0.72 * _alpha);
	draw_line_width(x1 + 7 * s, y0, xb + 7 * s, y1, max(1, 2 * s));
}

///@desc 在按钮点击范围中央等比绘制重试或继续贴图
function settlement_draw_button(_rect, _sprite, _cut, _hover) {
	var s = layout_scale;
	var x0 = (_rect[0] - layout_x) / s;
	var y0 = (_rect[1] - layout_y) / s;
	var w = (_rect[2] - _rect[0]) / s;
	var h = (_rect[3] - _rect[1]) / s;
	var a = footer_eased;
	settlement_draw_trapezoid(x0, y0, w, h, _cut, a, true);
	if (_hover) then settlement_draw_trapezoid(x0, y0, w, h, _cut, 0.18 * a);
	if (!asset_sprite_valid(_sprite)) then return;
	var sw = max(1, sprite_get_width(_sprite));
	var sh = max(1, sprite_get_height(_sprite));
	var fit = min((w - abs(_cut) - 32) / sw, (h - 24) / sh) * s;
	var cx = (_rect[0] + _rect[2]) * 0.5 - _cut * s * 0.25;
	var cy = (_rect[1] + _rect[3]) * 0.5;
	draw_sprite_ext(_sprite, 0, cx + (sprite_get_xoffset(_sprite) - sw * 0.5) * fit,
		cy + (sprite_get_yoffset(_sprite) - sh * 0.5) * fit, fit, fit, 0, c_white, a);
}
