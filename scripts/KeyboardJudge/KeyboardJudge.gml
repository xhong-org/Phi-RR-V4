// 手动键盘判定采用 sim-phi 的时间规则。Phira/PhiZone 的索引与头尾分离方式
// 用于减少遍历和避免重复计分；不同模拟器的窗口和断连宽限不混用。
#macro KB_PERFECT_SECONDS 0.080
#macro KB_GOOD_SECONDS 0.160
#macro KB_BAD_EARLY_SECONDS 0.200
#macro KB_HOLD_TAIL_SECONDS 0.200

///@desc 释放本局键盘索引；重试、切谱和退出时调用
function chart_kb_reset() {
	if (!variable_global_exists("game") || !is_struct(game)) then return;
	var state = game[$ "keyboard_judge"];
	if (is_struct(state)) {
		if (os_type == os_windows && buffer_exists(state.native_buffer)) __rpe_keyboard_reset();
		if (ds_exists(state.pending, ds_type_priority)) ds_priority_destroy(state.pending);
		if (buffer_exists(state.native_buffer)) buffer_delete(state.native_buffer);
		if (buffer_exists(state.native_args)) buffer_delete(state.native_args);
		state.active = [];
		state.next = undefined;
	}
	game.keyboard_judge = undefined;
}

///@desc 取得本局键盘状态，自动播放不会创建索引
function chart_kb_state_get() {
	var state = game[$ "keyboard_judge"];
	if (!is_struct(state)) {
		state = {
			pending:ds_priority_create(), next:undefined, active:[], prev:array_create(26, false), raw_pending:array_create(26, 0),
			held:0, pressed:0, press_times:[], sample_sec:0, native_buffer:-1, native_args:-1,
			initialized:false, was_active:false
		};
		game.keyboard_judge = state;
	}
	return state;
}

///@desc 桌面键盘可用于无位置判定
function chart_kb_desktop() {
	return os_type == os_windows || os_type == os_linux || os_type == os_macosx;
}

///@desc Windows 直接读取键态，避免输入法吞键
function chart_kb_key_down(key) {
	return os_type == os_windows ? keyboard_check_direct(key) : keyboard_check(key);
}

///@desc 每帧只轮询一次 A 到 Z，按住和新按下分别保存
function chart_kb_poll(state) {
	state.held = 0;
	state.pressed = 0;
	state.sample_sec = game.__time[1];
	array_resize(state.press_times, 0);
	if (os_type == os_windows && extension_exists("I_Pulse")) {
		if (!buffer_exists(state.native_buffer)) {
			state.native_buffer = buffer_create(8 + 1024 * 8, buffer_fixed, 1);
			state.native_args = buffer_create(16, buffer_fixed, 1);
		}
		buffer_seek(state.native_args, buffer_seek_start, 0);
		buffer_write(state.native_args, buffer_u64, int64(window_handle()));
		buffer_write(state.native_args, buffer_u64, int64(buffer_get_address(state.native_buffer)));
		var status = __rpe_keyboard_poll(buffer_get_address(state.native_args), 16);
		if (status > 0) {
			var input_now = (get_timer() - game.__time[3] - game.__time[0]) / 1000000;
			state.sample_sec = input_now;
			var held = buffer_peek(state.native_buffer, 0, buffer_u32);
			for (var index = 0; index < 26; index++) if ((held & (1 << index)) != 0) state.held++;
			state.pressed = buffer_peek(state.native_buffer, 4, buffer_u32);
			for (var index = 0; index < state.pressed; index++) {
				var age = buffer_peek(state.native_buffer, 12 + index * 8, buffer_u32) / 1000;
				array_push(state.press_times, input_now - age);
			}
			return;
		}
	}
	var focused = window_has_focus();
	for (var index = 0; index < 26; index++) {
		var key = 65 + index;
		var down = focused && chart_kb_key_down(key);
		if (down) state.held++;
		// 直接键态可能比消息队列快一帧。已报告的直接按下只确认，不再重复打击。
		var event_down = focused && keyboard_check_pressed(key);
		var pending = state.raw_pending[index];
		var acknowledged = event_down && pending > 0;
		if (acknowledged) pending--;
		if (down && !state.prev[index]) {
			state.pressed++;
			if (!event_down || acknowledged) pending++;
		} else if (event_down && !acknowledged) {
			// 帧间已完成松开和再次按下的纵连仍可由队列补齐。
			state.pressed++;
		}
		state.raw_pending[@ index] = focused ? pending : 0;
		state.prev[@ index] = down;
	}
}

///@desc 加载、暂停和过场时不接收打击；暂停期间仍同步键态
function chart_player_keyboard_judge_active() {
	if (game.paused || (variable_global_exists("loading_animation_active") && global.loading_animation_active)) then return false;
	if (instance_exists(oSettlement)) then return false;
	if (instance_exists(oPlayTransition)) {
		var transition = instance_find(oPlayTransition, 0);
		if (transition.state != PLAY_TRANSITION_STATE.PLAYING) then return false;
	}
	return true;
}

///@desc 把音符加入按媒体秒排序的索引，包含休眠音符和延迟创建的官谱音符
function chart_kb_register_note() {
	if (chart_autoplay_active()) then return;
	if (object_index != oNote && object_index != oNote_1 && object_index != oNote_2) then return;
	if (object_index != oNote_2 && !inition) then return;
	if (object_index != oNote && isFake) then return;
	var state = chart_kb_state_get();
	if (variable_instance_exists(id, "kb_record") && is_struct(kb_record) && kb_record.owner == state) then return;
	var hit;
	var tail;
	var kind;
	if (object_index == oNote) {
		hit = realHitTime;
		tail = hit + hold_time_length;
		kind = type;
	} else if (object_index == oNote_1) {
		var offset = real(game_1.chart_info.offset ?? 0) / 1000;
		hit = offset + _line_time_factor * start_sec;
		tail = offset + _line_time_factor * end_sec;
		kind = type;
	} else {
		var offset = real(game_2.chart.offsetSeconds ?? 0);
		hit = offset + startSec;
		tail = offset + endSec;
		kind = judge_type;
	}
	if (!is_finite(hit) || !is_finite(tail)) then return;
	// 中途关闭自动播放时，已经命中的音符不能再次判定。
	var head = TYPE.NONE;
	var scored = false;
	if (kind == 3) {
		var started = object_index == oNote_2 ? hold_started : !notJudge;
		if (started) head = hit_status;
		scored = isMiss;
	} else {
		var done = object_index == oNote_2 ? judged : isJudge;
		if (done) then return;
	}
	kb_record = {
		owner:state, note:id, hit:hit, tail:tail, kind:kind, head:head,
		scored:scored, closed:false, caught:false, early:false, frames:-1,
		effect_at:game.__time[1], head_at:-infinity
	};
	ds_priority_add(state.pending, kb_record, hit);
	state.next = undefined;
}

///@desc sim-phi：Bad 只在 Tap 提前侧；迟到结果按经过的绘制帧补偿
function chart_kb_head_result(delta, frames, hold = false) {
	if (delta > KB_GOOD_SECONDS) {
		return !hold && delta <= KB_BAD_EARLY_SECONDS ? TYPE.BAD : TYPE.NONE;
	}
	if (delta > KB_PERFECT_SECONDS) then return TYPE.GOOD;
	if (delta > -0.040 || frames < 1) then return TYPE.PREFECT;
	if (delta > -KB_PERFECT_SECONDS || frames < 2) then return TYPE.PREFECT;
	return TYPE.GOOD;
}

///@desc 只按已确定的结果计分；Hold 不再用头时间重新推导结果
function chart_kb_score(record, result) {
	if (record.scored) then return;
	record.scored = true;
	if (result == TYPE.PREFECT || result == TYPE.GOOD) {
		combo++;
		if (result == TYPE.PREFECT) phi_state_list.prefect++;
		else {
			phi_state_list.good++;
			if (record.early) phi_state_list.early++;
			else phi_state_list.late++;
		}
		phi_state_list.max_hitcombo = max(phi_state_list.max_hitcombo, combo);
	} else {
		combo = 0;
		if (result == TYPE.BAD) phi_state_list.bad++;
		else phi_state_list.miss++;
	}
}

///@desc 在当前音符作用域中更新命中位置、音效和特效
function chart_kb_feedback(result, sound_on = true) {
	var xy;
	if (object_index == oNote) {
		event_user(_step_user_count);
		var local_x = xOffset * chart_view_width * 0.05625;
		xy = [_line_ref.x + local_x * _line_ref.__cos, _line_ref.y - local_x * _line_ref.__sin];
	} else if (object_index == oNote_1) xy = rpe_note_hit_effect_xy();
	else xy = pec_note_hit_effect_xy();
	var color = result == TYPE.PREFECT ? #ffeca0 : make_colour_rgb(162, 238, 255);
	if (object_index == oNote_1 && has_hit_tint) color = hit_tint;
	var z = object_index == oNote_1 ? hit_effect_z : undefined;
	_eff_c(xy[0], xy[1], color, undefined, z);
	if (sound_on) skin_play_note_hitsound();
}

///@desc 保存头判定；坏判定冻结画面，Hold 头仅播放反馈而不计分
function chart_kb_apply_hit(record, result, now, input_time = undefined) {
	record.head = result;
	record.early = (input_time ?? now) < record.hit;
	record.effect_at = now;
	record.head_at = now;
	with (record.note) {
		hit_status = result;
		var local_now = now;
		if (object_index == oNote_1) local_now = (now - real(game_1.chart_info.offset ?? 0) / 1000) / _line_time_factor;
		else if (object_index == oNote_2) local_now -= real(game_2.chart.offsetSeconds ?? 0);
		judgeRealTime = local_now;
		if (record.kind == 3) {
			if (object_index == oNote_2) {
				hold_started = true;
				judge_sec = local_now;
			} else {
				notJudge = false;
				isHold = true;
				judgeTime = object_index == oNote ? local_now * _beat_per_second : local_now;
				if (object_index == oNote_1) __first__ = true;
			}
		} else {
			if (object_index == oNote_2) judged = true;
			else isJudge = true;
		}
		if (result == TYPE.BAD) {
			isBad = true;
			_bad_x = x;
			_bad_y = y;
			_bad_angle = image_angle;
		} else chart_kb_feedback(result);
	}
	if (record.kind != 3) {
		chart_kb_score(record, result);
		record.closed = true;
		if (result != TYPE.BAD) then instance_deactivate_object(record.note);
	}
}

///@desc 明确记一次 Miss，不再以“加一个谱面拍”伪造超时
function chart_kb_miss(record) {
	chart_kb_score(record, TYPE.MISS);
	with (record.note) {
		hit_status = TYPE.MISS;
		if (record.kind == 3) {
			isMiss = true;
			if (object_index == oNote_2) hold_started = true;
			else {
				notJudge = false;
				isHold = true;
				if (object_index == oNote_1) __first__ = true;
			}
		} else {
			if (object_index == oNote_2) judged = true;
			else isJudge = true;
			instance_deactivate_object(self);
		}
	}
	if (record.kind != 3) record.closed = true;
}

///@desc 按本地 BPM 和时间倍率求 Hold 尾迹间隔，单位为媒体秒
function chart_kb_hold_interval(record, now) {
	var interval = 0.25;
	with (record.note) {
		if (object_index == oNote) interval = 30 / max(1, self.bpm);
		else if (object_index == oNote_1) {
			var local_now = (now - real(game_1.chart_info.offset ?? 0) / 1000) / _line_time_factor;
			interval = _line_time_factor * 30 / max(1, game_1.Math.bpmAtAbsSec(local_now));
		} else {
			var events = game_2.chart.bpmList;
			var index = pec_bpm_index_at_sec(events, now - game_2.chart.offsetSeconds);
			interval = events[index].holdTickInterval;
		}
	}
	return interval;
}

///@desc 只处理时间窗内的候选和正在延续的 Hold，自动播放直接返回
function chart_kb_judge_step() {
	if (chart_autoplay_active()) {
		if (is_struct(game[$ "keyboard_judge"])) chart_kb_reset();
		return;
	}
	var state = chart_kb_state_get();
	if (chart_kb_desktop()) chart_kb_poll(state);
	else {
		state.held = 0;
		state.pressed = 0;
	}
	if (!chart_player_keyboard_judge_active()) {
		state.was_active = false;
		return;
	}
	if (!state.initialized) {
		// 一次性补入中途关闭自动播放时已经存在的音符，后续由创建/激活入口增量登记。
		with (oNote) chart_kb_register_note();
		with (oNote_1) chart_kb_register_note();
		with (oNote_2) chart_kb_register_note();
		state.initialized = true;
	}
	if (!state.was_active) state.pressed = 0;
	state.was_active = true;
	// 使用输入采样时刻，避免恰好跨过判定点的 Drag/Flick 再多等一帧。
	chart_kb_judge_at(state, state.sample_sec);
}

///@desc 使用本帧输入处理媒体时间窗；输入采样与各格式的局部时钟分开
function chart_kb_judge_at(state, now) {
	while (!ds_priority_empty(state.pending)) {
		// GameMaker 的最小项查询在大队列中并非免费；没有新登记时复用下一项。
		if (!is_struct(state.next)) state.next = ds_priority_find_min(state.pending);
		var next_record = state.next;
		if (next_record.hit > now + KB_BAD_EARLY_SECONDS) then break;
		var record = ds_priority_delete_min(state.pending);
		state.next = undefined;
		chart_note_activate(record.note);
		if (instance_exists(record.note)) array_push(state.active, record);
	}
	var active = state.active;
	var count = array_length(active);
	var prevent_bad = false;
	// 先处理 Drag/Flick 的预接住，防止同一次键盘输入误伤提前侧 Tap。
	for (var index = 0; index < count; index++) {
		var record = active[index];
		if (record.closed) then continue;
		if (!instance_exists(record.note)) {
			record.closed = true;
			continue;
		}
		if (now >= record.hit) record.frames++;
		if (!record.scored && record.head == TYPE.NONE && now > record.hit + KB_GOOD_SECONDS && record.frames > 4) {
			chart_kb_miss(record);
			continue;
		}
		if (record.kind != 2 && record.kind != 4) then continue;
		if (now < record.hit - KB_GOOD_SECONDS) then continue;
		if (now < record.hit || (record.kind == 4 && !record.caught)) prevent_bad = true;
		if (state.held > 0 || (record.kind == 4 && state.pressed > 0)) record.caught = true;
		if (record.caught && now >= record.hit) chart_kb_apply_hit(record, TYPE.PREFECT, now);
	}
	var pressed = state.pressed;
	while (pressed > 0) {
		var input_index = state.pressed - pressed;
		var input_time = input_index < array_length(state.press_times) ? state.press_times[input_index] : now;
		var best = undefined;
		var best_time = infinity;
		var best_result = TYPE.NONE;
		for (var index = 0; index < count; index++) {
			var record = active[index];
			if (record.closed || record.scored || record.head != TYPE.NONE || (record.kind != 1 && record.kind != 3)) then continue;
			var result = chart_kb_head_result(record.hit - input_time, record.frames, record.kind == 3);
			if (result == TYPE.NONE || (result == TYPE.BAD && prevent_bad)) then continue;
			// 无位置键盘按时间先后消耗音符，与 sim-phi/Phira 的键盘匹配一致。
			if (record.hit < best_time) {
				best = record;
				best_time = record.hit;
				best_result = result;
			}
		}
		if (!is_struct(best)) then break;
		chart_kb_apply_hit(best, best_result, now, input_time);
		pressed--;
	}
	// Hold 的最终结果只取头判定。进入末尾 200ms 后结算，不再要求持续按住。
	var kept = 0;
	for (var index = 0; index < count; index++) {
		var record = active[index];
		if (record.kind == 3 && !record.closed) {
			if (record.head != TYPE.NONE && !record.scored) {
				if (now > record.tail - KB_HOLD_TAIL_SECONDS) chart_kb_score(record, record.head);
				// 头判定这一帧不立即断连，与 sim-phi 的 holdBroken 初始化一致。
				else if (state.held == 0 && now > record.head_at) chart_kb_miss(record);
			}
			if (record.head != TYPE.NONE && record.note.hit_status != TYPE.MISS && now < record.tail
				&& now - record.effect_at >= chart_kb_hold_interval(record, now)) {
				with (record.note) chart_kb_feedback(record.head, false);
				record.effect_at = now;
			}
			if (now >= record.tail && record.scored) {
				record.closed = true;
				instance_deactivate_object(record.note);
			}
		}
		if (!record.closed) {
			active[@ kept] = record;
			kept++;
		}
	}
	array_resize(active, kept);
	state.active = active;
}
