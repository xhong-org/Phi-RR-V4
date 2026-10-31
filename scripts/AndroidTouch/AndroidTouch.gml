// Android 原始触点只在 Begin Step 采样一次，界面和判定共用同一包。
#macro ANDROID_TOUCH_CAPACITY 4096

function android_touch_state() {
	if (!variable_global_exists("android_touch") || !is_struct(global.android_touch)) {
		global.android_touch = {
			packet:buffer_create(20 + ANDROID_TOUCH_CAPACITY * 20, buffer_fixed, 1),
			generation:-1, focused:true, available:false, fingers:[], taps:[], samples:[], flicks:[],
			primary:-1, sample_us:0, suspended_at:-1, width:room_width, height:room_height,
			pointer:{ x:0, y:0, pressed:false, released:false, held:false }
		};
	}
	return global.android_touch;
}

///@desc 新房间丢弃旧手势，不能把菜单的那次按下带进谱面
function android_touch_reset() {
	if (os_type != os_android) then return;
	var state = android_touch_state();
	i_android_touch_reset();
	state.fingers = [];
	state.taps = [];
	state.samples = [];
	state.flicks = [];
	state.primary = -1;
	state.suspended_at = -1;
	state.pointer = { x:0, y:0, pressed:false, released:false, held:false };
}

function android_touch_shutdown() {
	if (os_type != os_android || !variable_global_exists("android_touch") || !is_struct(global.android_touch)) then return;
	i_android_touch_reset();
	if (buffer_exists(global.android_touch.packet)) buffer_delete(global.android_touch.packet);
	global.android_touch = undefined;
}

///@desc 基于原始事件时间识别划动；同一次手势只消费一次 Flick
function android_touch_move(state, finger, px, py, stamp) {
	var from_x = finger.x;
	var from_y = finger.y;
	var since = finger.stamp;
	if (stamp - finger.moved_at > 80000) {
		finger.flicking = false;
		finger.travel = 0;
		finger.dx = 0;
		finger.dy = 0;
	}
	var elapsed = (stamp - finger.stamp) / 1000000;
	var dx = px - finger.x;
	var dy = py - finger.y;
	if (elapsed > 0 && (dx != 0 || dy != 0)) {
		var distance = sqrt(dx * dx + dy * dy);
		var previous = sqrt(finger.dx * finger.dx + finger.dy * finger.dy);
		var projection = previous > 0 ? (dx * finger.dx + dy * finger.dy) / previous : distance;
		var flick_speed = projection / elapsed;
		var unit = max(1, room_height) / 900;
		if (finger.flicking && flick_speed < 500 * unit) {
			finger.flicking = false;
		}
		if (flick_speed > 1000 * unit) finger.travel += distance;
		else if (flick_speed < 500 * unit) finger.travel = 0;
		if (!finger.flicking && flick_speed > 1000 * unit && finger.travel >= 6 * unit) {
			finger.flicking = true;
			finger.gesture = { consumed:false };
		}
		finger.dx = dx;
		finger.dy = dy;
		finger.moved_at = stamp;
	}
	finger.x = px;
	finger.y = py;
	finger.stamp = stamp;
	var sample = { x:px, y:py, stamp:stamp, since:since, from_x:from_x, from_y:from_y,
		finger:finger, gesture:finger.gesture };
	array_push(state.samples, sample);
	if (finger.flicking && !finger.gesture.consumed) array_push(state.flicks, sample);
}

///@desc 独立于 GMS 触控状态，保留同一帧内的按下、移动和抬起
function android_touch_poll() {
	if (os_type != os_android) then return;
	var state = android_touch_state();
	state.pointer.pressed = false;
	state.pointer.released = false;
	state.taps = [];
	state.samples = [];
	state.flicks = [];
	if (state.width != room_width || state.height != room_height) {
		var sx = room_width / max(1, state.width);
		var sy = room_height / max(1, state.height);
		for (var fi = 0; fi < array_length(state.fingers); fi++) {
			var finger = state.fingers[fi];
			finger.x *= sx; finger.y *= sy;
			finger.dx *= sx; finger.dy *= sy;
		}
		state.pointer.x *= sx; state.pointer.y *= sy;
		state.width = room_width; state.height = room_height;
	}
	var result = i_android_touch_poll(buffer_get_address(state.packet), buffer_get_size(state.packet));
	state.sample_us = get_timer();
	state.available = result > 0 && buffer_peek(state.packet, 0, buffer_u32) == 2;
	state.suspended_at = -1;
	if (!state.available) {
		state.fingers = [];
		state.pointer.held = false;
		return;
	}
	var generation = buffer_peek(state.packet, 8, buffer_u32);
	state.focused = buffer_peek(state.packet, 12, buffer_u32) != 0;
	var suspend_age = buffer_peek(state.packet, 16, buffer_u32);
	if (suspend_age != 4294967295) state.suspended_at = state.sample_us - suspend_age * 1000;
	if (generation != state.generation || !state.focused) {
		state.fingers = [];
		state.primary = -1;
		state.pointer.held = false;
		state.generation = generation;
	}
	var count = min(ANDROID_TOUCH_CAPACITY, buffer_peek(state.packet, 4, buffer_u32));
	for (var index = 0; index < count; index++) {
		var offset = 20 + index * 20;
		var kind = buffer_peek(state.packet, offset, buffer_u32);
		var token = buffer_peek(state.packet, offset + 4, buffer_u32);
		var px = buffer_peek(state.packet, offset + 8, buffer_f32) * room_width;
		var py = buffer_peek(state.packet, offset + 12, buffer_f32) * room_height;
		var stamp = state.sample_us - buffer_peek(state.packet, offset + 16, buffer_u32) * 1000;
		var finger = undefined;
		for (var fi = 0; fi < array_length(state.fingers); fi++) {
			if (state.fingers[fi].token == token) { finger = state.fingers[fi]; break; }
		}
		if (kind == 1) {
			finger = { token:token, x:px, y:py, stamp:stamp, moved_at:stamp,
				dx:0, dy:0, travel:0, active:true, blocked:false, flicking:false, gesture:{ consumed:false } };
			array_push(state.fingers, finger);
			array_push(state.taps, { x:px, y:py, stamp:stamp, finger:finger });
			if (state.primary < 0) {
				state.primary = token;
				state.pointer.pressed = true;
			}
		}
		if (!is_struct(finger)) then continue;
		android_touch_move(state, finger, px, py, stamp);
		if (kind == 3) finger.active = false;
		if (state.primary == token) {
			state.pointer.x = px;
			state.pointer.y = py;
			state.pointer.held = kind != 3;
			if (kind == 3) {
				state.pointer.released = true;
				state.primary = -1;
			}
		}
	}
	var kept = 0;
	for (var fi = 0; fi < array_length(state.fingers); fi++) {
		var finger = state.fingers[fi];
		if (!finger.active) then continue;
		if (state.sample_us - finger.moved_at > 80000) {
			finger.flicking = false;
		}
		var sample = { x:finger.x, y:finger.y, stamp:state.sample_us, since:finger.stamp,
			from_x:finger.x, from_y:finger.y, finger:finger, gesture:finger.gesture };
		array_push(state.samples, sample);
		if (finger.flicking && !finger.gesture.consumed) array_push(state.flicks, sample);
		state.fingers[@ kept] = finger;
		kept++;
	}
	array_resize(state.fingers, kept);
}

///@desc 界面采用稳定的主触点，松开后仍保留本次点击位置
function android_touch_pointer() {
	return android_touch_state().pointer;
}
