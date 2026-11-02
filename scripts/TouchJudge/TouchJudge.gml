// 时间窗和计分复用手动键盘路径。触控采用 sim-phi 的旋转判定带，
// 同时音符按沿线/垂线距离选择；Flick 消费独立手势，Hold 可换指续接。
#macro TOUCH_HOLD_GRACE_SECONDS 0.050

///@desc 当前帧的判定线投影，每个候选只算一次，不受皮肤宽度影响
function chart_touch_geometry(record) {
	record.touch_valid = false;
	with (record.note) {
		var xy;
		var judge_line = object_index == oNote_2 ? line_ref : _line_ref;
		if (!chart_actor_exists(judge_line)) then return;
		if (object_index == oNote) {
			chart_actor_user(_step_user_count);
			var local_x = xOffset * chart_view_width * 0.05625;
			xy = [judge_line.x + local_x * judge_line.__cos, judge_line.y - local_x * judge_line.__sin];
		} else if (object_index == oNote_1) {
			xy = rpe_note_hit_effect_xy();
		} else {
			xy = pec_note_hit_effect_xy();
		}
		record.touch_x = xy[0];
		record.touch_y = xy[1];
		record.touch_cos = judge_line.__cos;
		record.touch_sin = judge_line.__sin;
		record.touch_valid = true;
	}
}

///@desc 判定只限制沿线距离；垂线距离用于多条线同时出现时选最近的音符
function chart_touch_metric_xy(record, px, py) {
	if (!record.touch_valid) then return infinity;
	var dx = px - record.touch_x;
	var dy = py - record.touch_y;
	var along = abs(dx * record.touch_cos - dy * record.touch_sin);
	if (along > chart_view_width * 0.118125) then return infinity;
	return along + abs(dx * record.touch_sin + dy * record.touch_cos) / 2.2;
}

function chart_touch_metric(record, sample) {
	return chart_touch_metric_xy(record, sample.x, sample.y);
}

///@desc 暂停按钮上的手指只操作界面，不参与打击或续 Hold
function chart_touch_in_playfield(sample) {
	if (sample.finger.blocked) then return false;
	if (sample.x < chart_view_left || sample.x > chart_view_right || sample.y < 0 || sample.y > chart_view_height) then return false;
	if (chart_actor_exists(oPausedUI)) {
		var ui = chart_actor_find(oPausedUI, 0);
		if (point_in_rectangle(sample.x, sample.y,
			ui.pause_button_x - ui.pause_button_radius, ui.pause_button_y - ui.pause_button_radius,
			ui.pause_button_x + ui.pause_button_radius, ui.pause_button_y + ui.pause_button_radius)) then return false;
	}
	return true;
}

function chart_touch_event_time(sample) {
	return (sample.stamp - game.__time[3] - game.__time[0]) / 1000000;
}

///@desc 在原始输入时间内寻找位置匹配；Drag 和续 Hold 不消费触点
function chart_touch_contact(record, input) {
	var samples = input.samples;
	var best = undefined;
	var distance = infinity;
	for (var index = 0; index < array_length(samples); index++) {
		var sample = samples[index];
		if (!chart_touch_in_playfield(sample)) then continue;
		var stamp = chart_touch_event_time(sample);
		if (stamp < record.hit - KB_GOOD_SECONDS || stamp > record.hit + KB_GOOD_SECONDS) then continue;
		var metric = chart_touch_metric(record, sample);
		if (metric < distance) { best = sample; distance = metric; }
	}
	return best;
}

///@desc 触控与键盘使用相同索引；自动播放不进入此分支
function chart_touch_judge_at(state, input, now) {
	// 官谱噪区必须先于四种音符和 Hold 续接过滤，不能等 Draw 才更新。
	if (chart_actor_exists(oRender) || chart_actor_exists(oRender_1)) then official_blocks_touch_step(input);
	while (!ds_priority_empty(state.pending)) {
		if (!is_struct(state.next)) state.next = ds_priority_find_min(state.pending);
		if (state.next.hit > now + KB_BAD_EARLY_SECONDS) then break;
		var record = ds_priority_delete_min(state.pending);
		state.next = undefined;
		chart_note_activate(record.note);
		if (chart_actor_exists(record.note)) array_push(state.active, record);
	}
	var active = state.active;
	var count = array_length(active);
	var has_input = array_length(input.samples) > 0;
	for (var index = 0; index < count; index++) {
		var record = active[index];
		if (record.closed) then continue;
		if (!chart_actor_exists(record.note)) { record.closed = true; continue; }
		if (now >= record.hit) record.frames++;
		if (has_input) chart_touch_geometry(record);
	}
	// 同一包里的输入先匹配，再检查超时，保留卡帧期间的有效按下。
	for (var index = 0; index < count; index++) {
		var record = active[index];
		if (record.closed || record.scored || record.kind != 2) then continue;
		if (!record.caught) {
			var contact = chart_touch_contact(record, input);
			if (is_struct(contact)) record.caught = true;
		}
		if (record.caught && now >= record.hit) chart_kb_apply_hit(record, TYPE.PREFECT, now);
	}
	// 每次划动选择位置最近的同时 Flick，不受优先队列同时间项的顺序影响。
	for (var fi = 0; fi < array_length(input.flicks); fi++) {
		var sample = input.flicks[fi];
		if (sample.gesture.consumed || !chart_touch_in_playfield(sample)) then continue;
		var input_time = chart_touch_event_time(sample);
		var best = undefined;
		var best_time = infinity;
		var best_metric = infinity;
		for (var index = 0; index < count; index++) {
			var record = active[index];
			if (record.closed || record.scored || record.caught || record.kind != 4) then continue;
			if (abs(record.hit - input_time) > KB_GOOD_SECONDS) then continue;
			var metric = chart_touch_metric(record, sample);
			if (metric == infinity) then continue;
			if (record.hit < best_time - 0.001 || (abs(record.hit - best_time) <= 0.001 && metric < best_metric)) {
				best = record; best_time = record.hit; best_metric = metric;
			}
		}
		if (is_struct(best)) {
			best.caught = true;
			sample.gesture.consumed = true;
		}
	}
	for (var index = 0; index < count; index++) {
		var record = active[index];
		if (!record.closed && record.kind == 4 && record.caught && now >= record.hit) chart_kb_apply_hit(record, TYPE.PREFECT, now);
	}
	for (var tap_index = 0; tap_index < array_length(input.taps); tap_index++) {
		var tap = input.taps[tap_index];
		if (!chart_touch_in_playfield(tap)) then continue;
		var input_time = chart_touch_event_time(tap);
		var prevent_bad = false;
		for (var index = 0; index < count; index++) {
			var record = active[index];
			if (record.closed || (record.kind != 2 && record.kind != 4)) then continue;
			if (abs(record.hit - input_time) <= KB_GOOD_SECONDS && chart_touch_metric(record, tap) < infinity) prevent_bad = true;
		}
		var best = undefined;
		var best_time = infinity;
		var best_metric = infinity;
		var best_result = TYPE.NONE;
		for (var index = 0; index < count; index++) {
			var record = active[index];
			if (record.closed || record.scored || record.head != TYPE.NONE || (record.kind != 1 && record.kind != 3)) then continue;
			if (input_time < record.hit - KB_BAD_EARLY_SECONDS || input_time > record.hit + KB_GOOD_SECONDS) then continue;
			var result = chart_kb_head_result(record.hit - input_time, record.frames, record.kind == 3);
			if (result == TYPE.NONE || (result == TYPE.BAD && prevent_bad)) then continue;
			var metric = chart_touch_metric(record, tap);
			if (metric == infinity) then continue;
			if (record.hit < best_time - 0.001 || (abs(record.hit - best_time) <= 0.001 && metric < best_metric)) {
				best = record; best_time = record.hit; best_metric = metric; best_result = result;
			}
		}
		if (is_struct(best)) {
			chart_kb_apply_hit(best, best_result, now, input_time);
			best.touch_contact_at = input_time;
		}
	}
	var kept = 0;
	for (var index = 0; index < count; index++) {
		var record = active[index];
		if (record.closed) then continue;
		if (!record.scored && record.head == TYPE.NONE && now > record.hit + KB_GOOD_SECONDS && record.frames > 4) chart_kb_miss(record);
		if (record.kind == 3 && !record.closed) {
			if (record.head != TYPE.NONE && !record.scored) {
				var last_contact = record[$ "touch_contact_at"] ?? now;
				for (var si = 0; si < array_length(input.samples); si++) {
					var sample = input.samples[si];
					if (!chart_touch_in_playfield(sample) || chart_touch_metric(record, sample) == infinity) then continue;
					var stamp = chart_touch_event_time(sample);
					var since = (sample.since - game.__time[3] - game.__time[0]) / 1000000;
					// 静止按住期间没有 MOVE；只有连续接触能跨过较长采样间隔。
					var continuous = since <= last_contact + TOUCH_HOLD_GRACE_SECONDS
						&& chart_touch_metric_xy(record, sample.from_x, sample.from_y) < infinity;
					if (continuous || stamp <= last_contact + TOUCH_HOLD_GRACE_SECONDS) last_contact = max(last_contact, stamp);
				}
				record.touch_contact_at = last_contact;
				var required_until = min(now, record.tail - KB_HOLD_TAIL_SECONDS);
				if (required_until - last_contact > TOUCH_HOLD_GRACE_SECONDS) chart_kb_miss(record);
				else if (now >= record.tail - KB_HOLD_TAIL_SECONDS) chart_kb_score(record, record.head);
			}
			if (record.head != TYPE.NONE && record.note.hit_status != TYPE.MISS && now < record.tail
				&& now - record.effect_at >= chart_kb_hold_interval(record, now)) {
				with (record.note) chart_kb_feedback(record.head, false);
				record.effect_at = now;
			}
			if (now >= record.tail && record.scored) {
				record.closed = true;
				chart_actor_deactivate(record.note);
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
