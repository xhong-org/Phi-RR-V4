/// Official chart blockAreaList, matched to Phira's noise-area path.
/// Pose, easing, subtract parity and the material passes follow that renderer.
/// Shaders are compiled when the chart finishes loading. A frame submits them
/// only while a block is inside appear..disappear, or a blocked finger is fading.

#macro BLOCK_RT_ACTIVE_N 0
#macro BLOCK_RT_ACTIVE_H 1
#macro BLOCK_RT_READY_N 2
#macro BLOCK_RT_READY_H 3
#macro BLOCK_RT_OFF_N 4
#macro BLOCK_RT_OFF_H 5
#macro BLOCK_RT_ACTIVE_HP 6
#macro BLOCK_RT_READY_HP 7
#macro BLOCK_RT_ACTIVE_C 8
#macro BLOCK_RT_READY_C 9
#macro BLOCK_RT_OFF_HP 10
#macro BLOCK_RT_GLOW0 11
#macro BLOCK_RT_GLOW1 12
#macro BLOCK_RT_HOVER 13
#macro BLOCK_RT_PACK_M 14
#macro BLOCK_RT_PACK_E 15
#macro BLOCK_RT_SCENE 16
#macro BLOCK_RT_OFF_C 17
#macro BLOCK_RT_COUNT 18

function official_block_state_create() {
	var hovers = array_create(10);
	for (var i = 0; i < 10; i++) hovers[i] = official_block_hover_new();
	return {
			ready: false,
			empty: true,
			loaded_enabled: false,
			preloaded: false,
			gpu_warm: false,
			cleared: false,
			warned: false,
			blocks: [],
			hovers: hovers,
			blocked_ids: [],
			touch_world: [],
			hover_live: false,
			need_gpu: false,
			on_active: false,
			on_ready: false,
			on_disabled: false,
			norm_active: false,
			norm_ready: false,
			norm_disabled: false,
			sub_active: false,
			sub_ready: false,
			sub_disabled: false,
			ok_subtract: false,
			ok_subtract_soft: false,
			ok_compose: false,
			ok_compose_plain: false,
			ok_glow: false,
			ok_disabled: false,
			ok_active: false,
			ok_ready: false,
			ok_pack_m: false,
			ok_pack_e: false,
			ok_hover: false,
			rt: array_create(BLOCK_RT_COUNT, -1),
			white_surf: -1,
			blank_surf: -1,
			noise_spr: -1,
			spark_spr: -1,
			grain_spr: -1,
			touch_spr: -1,
			surf_w: 0,
			surf_h: 0,
			bw: 1,
			bh: 1,
			ew: 1,
			eh: 1,
			sw: 1,
			sh: 1,
			first_appear: 0,
			last_disappear: 0,
			cover_active: official_block_cover_new(),
			cover_disabled: official_block_cover_new()
	};
}

function official_block_state() {
	static state = official_block_state_create();
	return state;
}

function official_block_hover_new() {
	return { id: -1, x: 0, y: 0, scale: 0, from: 0, target: 0, elapsed: 0, moving: false };
}

function official_block_cover_new() {
	return { minx: 0, miny: 0, maxx: 0, maxy: 0, any: false, bad: false };
}

function official_block_cover_clear(_cover) {
	_cover.minx = 100000000;
	_cover.miny = 100000000;
	_cover.maxx = -100000000;
	_cover.maxy = -100000000;
	_cover.any = false;
	_cover.bad = false;
}

function official_block_cover_add(_cover, _x, _y) {
	if (!is_finite(_x) || !is_finite(_y)) {
		_cover.bad = true;
		return;
	}
	_cover.minx = min(_cover.minx, _x);
	_cover.miny = min(_cover.miny, _y);
	_cover.maxx = max(_cover.maxx, _x);
	_cover.maxy = max(_cover.maxy, _y);
	_cover.any = true;
}

function official_blocks_reset() {
	var state = official_block_state();
	official_block_free_rt(state);
	if (surface_exists(state.white_surf)) surface_free(state.white_surf);
	if (surface_exists(state.blank_surf)) surface_free(state.blank_surf);
	state.white_surf = -1;
	state.blank_surf = -1;
	state.cleared = false;
	official_block_free_sprite(state, "noise_spr");
	official_block_free_sprite(state, "spark_spr");
	official_block_free_sprite(state, "grain_spr");
	official_block_free_sprite(state, "touch_spr");
	var hovers = state.hovers;
	for (var i = 0; i < array_length(hovers); i++) {
		var hover = hovers[i];
		hover.id = -1;
		hover.x = 0;
		hover.y = 0;
		hover.scale = 0;
		hover.from = 0;
		hover.target = 0;
		hover.elapsed = 0;
		hover.moving = false;
	}
	state.blocks = [];
	state.blocked_ids = [];
	state.touch_world = [];
	state.hover_live = false;
	state.need_gpu = false;
	state.ready = false;
	state.empty = true;
	state.loaded_enabled = false;
	state.preloaded = false;
	state.gpu_warm = false;
	state.warned = false;
	state.first_appear = 0;
	state.last_disappear = 0;
	shader_reset();
}

function official_block_free_sprite(_state, _field) {
	var sprite = _state[$ _field];
	if (sprite_exists(sprite)) sprite_delete(sprite);
	_state[$ _field] = -1;
}

function official_block_free_rt(_state) {
	var rt = _state.rt;
	for (var i = 0; i < array_length(rt); i++) {
		if (surface_exists(rt[i])) surface_free(rt[i]);
		rt[i] = -1;
	}
	_state.surf_w = 0;
	_state.surf_h = 0;
}

function official_blocks_ending() {
	if (chart_play_ending()) return true;
	if (instance_exists(oSettlement)) return true;
	if (variable_instance_exists(id, "chart_exit_started") && chart_exit_started) return true;
	return false;
}

function official_block_ease_raw(_type, _t) {
	var progress = clamp(_t, 0, 1);
	var remain = 1 - progress;
	var turned = -2 * progress + 2;
	if (_type == 1) return 1 - cos(progress * pi * 0.5);
	if (_type == 2) return sin(progress * pi * 0.5);
	if (_type == 3) return (1 - cos(pi * progress)) * 0.5;
	if (_type == 4) return progress * progress;
	if (_type == 5) return 1 - remain * remain;
	if (_type == 6) return (progress < 0.5) ? (2 * progress * progress) : (1 - turned * turned * 0.5);
	if (_type == 7) return progress * progress * progress;
	if (_type == 8) return 1 - remain * remain * remain;
	if (_type == 9) return (progress < 0.5) ? (4 * progress * progress * progress) : (1 - turned * turned * turned * 0.5);
	if (_type == 10) return progress * progress * progress * progress;
	if (_type == 11) return 1 - remain * remain * remain * remain;
	if (_type == 12) return (progress < 0.5) ? (8 * progress * progress * progress * progress) : (1 - turned * turned * turned * turned * 0.5);
	if (_type == 13) return 0;
	if (_type == 14) return 1;
	return progress;
}

function official_block_ease(_type, _t) {
	var p = clamp(_t, 0, 1) * 100;
	var step = floor(p);
	var sample = official_block_ease_raw(_type, step / 100);
	var next_step = min(step + 1, 100);
	return sample + (official_block_ease_raw(_type, next_step / 100) - sample) * (p - step);
}

function official_block_ratio(_t, _a, _b) {
	if (_b <= _a) return 1;
	return clamp((_t - _a) / (_b - _a), 0, 1);
}

function official_block_safe_div(_numerator, _denominator) {
	if (_denominator == 0) return 1;
	return _numerator / _denominator;
}

function official_block_world(_x, _y, _aspect) {
	return [(_x - 0.5) * 10 * _aspect, (_y - 0.5) * 10];
}

function official_block_rotate_vec(_x, _y, _radians) {
	var cosine = cos(_radians);
	var sine = sin(_radians);
	return [cosine * _x - sine * _y, sine * _x + cosine * _y];
}

function official_block_sort_time(_a, _b) {
	// array_sort truncates the comparator to an integer. A raw time delta
	// below one second becomes 0, so those keyframes stay unordered and a
	// later sample is treated as already finished.
	return sign(_a.t - _b.t);
}

function official_block_read_move(_area) {
	var source = _area[$ "moveEvents"];
	var events = [];
	if (!is_array(source)) return events;
	var count = array_length(source);
	for (var i = 0; i < count; i++) {
		var item = source[i];
		if (!is_struct(item)) continue;
		var end_position = item[$ "endPosition"];
		var pos_x = 0;
		var pos_y = 0;
		if (is_struct(end_position)) {
			pos_x = real(end_position[$ "x"] ?? 0);
			pos_y = real(end_position[$ "y"] ?? 0);
		}
		if (!is_finite(real(item[$ "time"] ?? 0)) || !is_finite(pos_x) || !is_finite(pos_y)) continue;
		array_push(events, {
			t: real(item[$ "time"] ?? 0),
			x: pos_x,
			y: pos_y,
			ex: floor(real(item[$ "easeTypeX"] ?? 0)),
			ey: floor(real(item[$ "easeTypeY"] ?? 0))
		});
	}
	if (array_length(events) > 1) array_sort(events, official_block_sort_time);
	return events;
}

function official_block_read_scale(_area) {
	var source = _area[$ "scaleEvents"];
	var events = [];
	if (!is_array(source)) return events;
	var count = array_length(source);
	for (var i = 0; i < count; i++) {
		var item = source[i];
		if (!is_struct(item)) continue;
		var anchor = item[$ "anchor"];
		var scale = item[$ "scale"];
		var anchor_x = 0;
		var anchor_y = 0;
		var scale_x = 0;
		var scale_y = 0;
		if (is_struct(anchor)) {
			anchor_x = real(anchor[$ "x"] ?? 0);
			anchor_y = real(anchor[$ "y"] ?? 0);
		}
		if (is_struct(scale)) {
			scale_x = real(scale[$ "x"] ?? 0);
			scale_y = real(scale[$ "y"] ?? 0);
		}
		if (!is_finite(real(item[$ "time"] ?? 0)) || !is_finite(scale_x) || !is_finite(scale_y)) continue;
		array_push(events, {
			t: real(item[$ "time"] ?? 0),
			x: scale_x,
			y: scale_y,
			ax: anchor_x,
			ay: anchor_y,
			ex: floor(real(item[$ "easeTypeX"] ?? 0)),
			ey: floor(real(item[$ "easeTypeY"] ?? 0))
		});
	}
	if (array_length(events) > 1) array_sort(events, official_block_sort_time);
	return events;
}

function official_block_read_rotate(_area) {
	var source = _area[$ "rotateEvents"];
	var events = [];
	if (!is_array(source)) return events;
	var count = array_length(source);
	for (var i = 0; i < count; i++) {
		var item = source[i];
		if (!is_struct(item)) continue;
		var anchor = item[$ "anchor"];
		var anchor_x = 0;
		var anchor_y = 0;
		if (is_struct(anchor)) {
			anchor_x = real(anchor[$ "x"] ?? 0);
			anchor_y = real(anchor[$ "y"] ?? 0);
		}
		var rotation = real(item[$ "rotation"] ?? 0);
		if (!is_finite(real(item[$ "time"] ?? 0)) || !is_finite(rotation)) continue;
		array_push(events, {
			t: real(item[$ "time"] ?? 0),
			r: rotation,
			ax: anchor_x,
			ay: anchor_y,
			ease: floor(real(item[$ "easeType"] ?? 0))
		});
	}
	if (array_length(events) > 1) array_sort(events, official_block_sort_time);
	return events;
}

function official_blocks_build(_chart) {
	var source = _chart[$ "blockAreaList"];
	if (!is_array(source)) source = _chart[$ "block_area_list"];
	if (!is_array(source)) source = _chart[$ "block_area"];
	var blocks = [];
	if (!is_array(source)) return blocks;
	var count = array_length(source);
	for (var i = 0; i < count; i++) {
		var area = source[i];
		if (!is_struct(area)) continue;
		var bottom_left = area[$ "bottomLeftPercentage"];
		var top_right = area[$ "topRightPercentage"];
		if (!is_struct(bottom_left) || !is_struct(top_right)) continue;
		var left_x = real(bottom_left[$ "x"] ?? 0);
		var left_y = real(bottom_left[$ "y"] ?? 0);
		var right_x = real(top_right[$ "x"] ?? 0);
		var right_y = real(top_right[$ "y"] ?? 0);
		var appear = real(area[$ "appearTime"] ?? 0);
		var enable = real(area[$ "enableTime"] ?? 0);
		var disable = real(area[$ "disableTime"] ?? 0);
		var disappear = real(area[$ "disappearTime"] ?? 0);
		if (!is_finite(left_x) || !is_finite(left_y) || !is_finite(right_x) || !is_finite(right_y)) continue;
		if (!is_finite(appear) || !is_finite(enable) || !is_finite(disable) || !is_finite(disappear)) continue;
		enable = max(enable, appear);
		disable = max(disable, enable);
		disappear = max(disappear, disable);
		array_push(blocks, {
			subtract: bool(area[$ "isSubtract"] ?? false),
			appear: appear,
			enable: enable,
			disable: disable,
			disappear: disappear,
			x0: left_x,
			y0: left_y,
			x1: right_x,
			y1: right_y,
			move: official_block_read_move(area),
			scale: official_block_read_scale(area),
			rotate: official_block_read_rotate(area),
			on: false,
			phase: 2,
			fade: 1,
			cx: 0,
			cy: 0,
			sx: 1,
			sy: 1,
			ang: 0,
			corners: [0, 0, 0, 0, 0, 0, 0, 0]
		});
	}
	return blocks;
}

function official_block_enabled() {
	if (!variable_global_exists("game") || !is_struct(game) || !is_struct(game.settings)) return true;
	return bool(game.settings[$ "enableNoiseArea"] ?? true);
}

function official_blocks_ensure() {
	var state = official_block_state();
	if (!official_block_enabled()) {
		// Leave the chart JSON unread. Rendering also stays off.
		state.blocks = [];
		state.empty = true;
		state.ready = true;
		state.loaded_enabled = false;
		state.need_gpu = false;
		state.hover_live = false;
		state.blocked_ids = [];
		state.touch_world = [];
		return state;
	}
	if (state.ready && state.loaded_enabled) return state;
	state.loaded_enabled = true;
	if (!variable_global_exists("game") || !is_struct(game) || !is_struct(game[$ "chart"])) return state;
	state.blocks = official_blocks_build(game.chart);
	state.ready = true;
	state.empty = array_length(state.blocks) <= 0;
	state.first_appear = infinity;
	state.last_disappear = -infinity;
	var blocks = state.blocks;
	var count = array_length(blocks);
	for (var i = 0; i < count; i++) {
		state.first_appear = min(state.first_appear, blocks[i].appear);
		state.last_disappear = max(state.last_disappear, blocks[i].disappear);
	}
	if (is_struct(game[$ "settings"]) && bool(game.settings[$ "enableDebug"] ?? false)) {
		print($"[R-Chart] blockAreaList {count}");
	}
	return state;
}

function official_block_load_sprite(_file) {
	var path = working_directory + "blockarea/" + _file;
	if (!file_exists(path)) {
		print($"[R-Chart] block texture missing {path}");
		return -1;
	}
	var sprite = sprite_add(path, 1, false, false, 0, 0);
	if (sprite_exists(sprite)) texture_prefetch(sprite_get_texture(sprite, 0));
	return sprite;
}

function official_block_compile(_shader) {
	if (!shader_is_compiled(_shader)) {
		shader_set(_shader);
		shader_reset();
	}
	return shader_is_compiled(_shader);
}

function official_block_refresh_ok(_state) {
	_state.ok_subtract = shader_is_compiled(shd_block_subtract);
	_state.ok_subtract_soft = shader_is_compiled(shd_block_subtract_soft);
	_state.ok_compose = shader_is_compiled(shd_block_compose);
	_state.ok_compose_plain = shader_is_compiled(shd_block_compose_plain);
	_state.ok_glow = shader_is_compiled(shd_block_glow);
	_state.ok_disabled = shader_is_compiled(shd_block_disabled);
	_state.ok_active = shader_is_compiled(shd_block_active);
	_state.ok_ready = shader_is_compiled(shd_block_active_ready);
	_state.ok_pack_m = shader_is_compiled(shd_block_pack_mask);
	_state.ok_pack_e = shader_is_compiled(shd_block_pack_effect);
	_state.ok_hover = shader_is_compiled(shd_block_hover);
	if (!_state.warned && (!_state.ok_active || !_state.ok_disabled || !_state.ok_compose)) {
		_state.warned = true;
		print($"[R-Chart] block shaders active={_state.ok_active} ready={_state.ok_ready} disabled={_state.ok_disabled} compose={_state.ok_compose}");
	}
}

function official_blocks_preload() {
	var state = official_blocks_ensure();
	if (!official_block_enabled()) return;
	if (!state.ready || state.preloaded) return;
	if (state.empty) {
		state.preloaded = true;
		return;
	}
	state.noise_spr = official_block_load_sprite("texture_30.png");
	state.spark_spr = official_block_load_sprite("texture_17.png");
	state.grain_spr = official_block_load_sprite("texture_15.png");
	state.touch_spr = official_block_load_sprite("touch.png");
	official_block_compile(shd_block_subtract);
	official_block_compile(shd_block_subtract_soft);
	official_block_compile(shd_block_compose);
	official_block_compile(shd_block_compose_plain);
	official_block_compile(shd_block_glow);
	official_block_compile(shd_block_disabled);
	official_block_compile(shd_block_active);
	official_block_compile(shd_block_active_ready);
	official_block_compile(shd_block_pack_mask);
	official_block_compile(shd_block_pack_effect);
	official_block_compile(shd_block_hover);
	official_block_refresh_ok(state);
	state.preloaded = true;
}

function official_block_aspect() {
	if (variable_global_exists("chart_aspect_ratio") && is_real(chart_aspect_ratio) && is_finite(chart_aspect_ratio) && chart_aspect_ratio > 0.01) {
		return chart_aspect_ratio;
	}
	if (variable_global_exists("chart_view_width") && variable_global_exists("chart_view_height") && chart_view_height > 1) {
		return chart_view_width / chart_view_height;
	}
	return 16 / 9;
}

function official_block_view_ready() {
	return variable_global_exists("chart_view_width") && is_real(chart_view_width) && chart_view_width > 1
		&& variable_global_exists("chart_view_height") && is_real(chart_view_height) && chart_view_height > 1
		&& variable_global_exists("chart_view_left") && is_real(chart_view_left);
}

function official_block_world_to_room(_x, _y, _aspect) {
	var x_ndc = _x / (5 * _aspect);
	var y_chart = -_y / (5 * _aspect);
	var px = chart_view_left + (x_ndc + 1) * 0.5 * chart_view_width;
	var bottom = (1 - y_chart * _aspect) * 0.5;
	return [px, (1 - bottom) * chart_view_height];
}

function official_block_pixel_to_world(_x, _y, _aspect) {
	var px = (_x - chart_view_left) / chart_view_width;
	var py = 1 - (_y / chart_view_height);
	return [(px - 0.5) * 10 * _aspect, (py - 0.5) * 10];
}

function official_block_pose(_block, _now, _aspect) {
	var lo = official_block_world(_block.x0, _block.y0, _aspect);
	var hi = official_block_world(_block.x1, _block.y1, _aspect);
	var base_x = (lo[0] + hi[0]) * 0.5;
	var base_y = (lo[1] + hi[1]) * 0.5;
	var cx = base_x;
	var cy = base_y;
	var sx = 1;
	var sy = 1;
	var scales = _block.scale;
	var scale_count = array_length(scales);
	// FindCurrentEventIndex is -1 before the first key. An empty list stays at
	// 1. A list that has not reached its first key stays at 0, so a lone (1,1)
	// key at the hit does not draw the zone on the way there.
	if (scale_count > 0 && _now < scales[0].t) {
		sx = 0;
		sy = 0;
	} else if (scale_count > 0) {
		sx = scales[0].x;
		sy = scales[0].y;
		for (var si = 0; si < scale_count; si++) {
			if (si + 1 >= scale_count) break;
			var scale_event = scales[si];
			var scale_next = scales[si + 1];
			var scale_done = _now >= scale_next.t;
			var scale_px = scale_done ? 1 : official_block_ease(scale_event.ex, official_block_ratio(_now, scale_event.t, scale_next.t));
			var scale_py = scale_done ? 1 : official_block_ease(scale_event.ey, official_block_ratio(_now, scale_event.t, scale_next.t));
			var vx = scale_event.x + (scale_next.x - scale_event.x) * scale_px;
			var vy = scale_event.y + (scale_next.y - scale_event.y) * scale_py;
			var scale_anchor = official_block_world(scale_event.ax, scale_event.ay, _aspect);
			cx = scale_anchor[0] + (cx - scale_anchor[0]) * official_block_safe_div(vx, scale_event.x);
			cy = scale_anchor[1] + (cy - scale_anchor[1]) * official_block_safe_div(vy, scale_event.y);
			sx = vx;
			sy = vy;
			if (_now < scale_next.t) break;
		}
	}
	var angle = 0;
	var rotates = _block.rotate;
	var rotate_count = array_length(rotates);
	if (rotate_count > 0 && _now >= rotates[0].t) {
		angle = rotates[0].r;
		for (var ri = 0; ri < rotate_count; ri++) {
			if (ri + 1 >= rotate_count) break;
			var rotate_event = rotates[ri];
			var rotate_next = rotates[ri + 1];
			var rotate_p = (_now >= rotate_next.t) ? 1 : official_block_ease(rotate_event.ease, official_block_ratio(_now, rotate_event.t, rotate_next.t));
			var turned_angle = rotate_event.r + (rotate_next.r - rotate_event.r) * rotate_p;
			var rotate_anchor = official_block_world(rotate_event.ax, rotate_event.ay, _aspect);
			var turned = official_block_rotate_vec(cx - rotate_anchor[0], cy - rotate_anchor[1], (turned_angle - rotate_event.r) * pi / 180);
			cx = rotate_anchor[0] + turned[0];
			cy = rotate_anchor[1] + turned[1];
			angle = turned_angle;
			if (_now < rotate_next.t) break;
		}
	}
	var moves = _block.move;
	var move_count = array_length(moves);
	if (move_count > 0 && _now >= moves[0].t) {
		var move_x = moves[0].x;
		var move_y = moves[0].y;
		for (var mi = 0; mi < move_count; mi++) {
			if (mi + 1 >= move_count) break;
			var move_event = moves[mi];
			var move_next = moves[mi + 1];
			var move_done = _now >= move_next.t;
			var move_px = move_done ? 1 : official_block_ease(move_event.ex, official_block_ratio(_now, move_event.t, move_next.t));
			var move_py = move_done ? 1 : official_block_ease(move_event.ey, official_block_ratio(_now, move_event.t, move_next.t));
			move_x = move_event.x + (move_next.x - move_event.x) * move_px;
			move_y = move_event.y + (move_next.y - move_event.y) * move_py;
			if (_now < move_next.t) break;
		}
		var moved = official_block_world(move_x, move_y, _aspect);
		cx += moved[0] - base_x;
		cy += moved[1] - base_y;
	}
	return [cx, cy, abs((hi[0] - lo[0]) * sx), abs((hi[1] - lo[1]) * sy), angle * pi / 180];
}

function official_block_hide(_state) {
	var blocks = _state.blocks;
	var count = array_length(blocks);
	for (var i = 0; i < count; i++) blocks[i].on = false;
	_state.on_active = false;
	_state.on_ready = false;
	_state.on_disabled = false;
	_state.norm_active = false;
	_state.norm_ready = false;
	_state.norm_disabled = false;
	_state.sub_active = false;
	_state.sub_ready = false;
	_state.sub_disabled = false;
	_state.need_gpu = false;
	official_block_cover_clear(_state.cover_active);
	official_block_cover_clear(_state.cover_disabled);
}

function official_block_gather(_state, _now, _aspect) {
	official_block_hide(_state);
	var blocks = _state.blocks;
	var count = array_length(blocks);
	var half = [[-0.5, -0.5], [0.5, -0.5], [0.5, 0.5], [-0.5, 0.5]];
	for (var i = 0; i < count; i++) {
		var block = blocks[i];
		if (_now < block.appear || _now >= block.disappear) continue;
		var phase = 2;
		if (_now >= block.enable && _now < block.disable) phase = 0;
		else if (_now + 0.5 >= block.enable && _now < block.enable) phase = 1;
		var fade = 1;
		if (phase == 2 && _now < block.enable) fade = clamp((_now - block.appear) / 0.5, 0, 1);
		var pose = official_block_pose(block, _now, _aspect);
		if (!is_finite(pose[0]) || !is_finite(pose[1]) || pose[2] < 0.0001 || pose[3] < 0.0001) continue;
		var corners = block.corners;
		var finite = true;
		for (var corner = 0; corner < 4; corner++) {
			var local = official_block_rotate_vec(half[corner][0] * pose[2], half[corner][1] * pose[3], pose[4]);
			var room_point = official_block_world_to_room(pose[0] + local[0], pose[1] + local[1], _aspect);
			if (!is_finite(room_point[0]) || !is_finite(room_point[1])) {
				finite = false;
				break;
			}
			corners[corner * 2] = room_point[0];
			corners[corner * 2 + 1] = room_point[1];
		}
		if (!finite) continue;
		block.on = true;
		block.phase = phase;
		block.fade = fade;
		block.cx = pose[0];
		block.cy = pose[1];
		block.sx = pose[2];
		block.sy = pose[3];
		block.ang = pose[4];
		var cover = (phase == 2) ? _state.cover_disabled : _state.cover_active;
		official_block_cover_add(cover, corners[0], corners[1]);
		official_block_cover_add(cover, corners[2], corners[3]);
		official_block_cover_add(cover, corners[4], corners[5]);
		official_block_cover_add(cover, corners[6], corners[7]);
		if (phase == 0) {
			_state.on_active = true;
			if (block.subtract) _state.sub_active = true;
			else _state.norm_active = true;
		} else if (phase == 1) {
			_state.on_ready = true;
			if (block.subtract) _state.sub_ready = true;
			else _state.norm_ready = true;
		} else {
			_state.on_disabled = true;
			if (block.subtract) _state.sub_disabled = true;
			else _state.norm_disabled = true;
		}
	}
	_state.need_gpu = _state.on_active || _state.on_ready || _state.on_disabled;
}

function official_block_contains(_block, _x, _y, _adjusted) {
	var sx = _block.sx;
	var sy = _block.sy;
	if (abs(sx) < 0.0001 || abs(sy) < 0.0001) return false;
	var local = official_block_rotate_vec(_x - _block.cx, _y - _block.cy, -_block.ang);
	var lx = local[0] / sx;
	var ly = local[1] / sy;
	var hx = 0.5;
	var hy = 0.5;
	if (_adjusted) {
		var inset_sign = _block.subtract ? 1 : -1;
		hx += min(0.3 / abs(sx), 0.25) * inset_sign;
		hy += min(0.3 / abs(sy), 0.25) * inset_sign;
	}
	return abs(lx) <= hx && abs(ly) <= hy;
}

function official_block_hits(_state, _x, _y) {
	var inside = false;
	var hole = false;
	var inside_edge = false;
	var hole_edge = false;
	var blocks = _state.blocks;
	var count = array_length(blocks);
	for (var i = 0; i < count; i++) {
		var block = blocks[i];
		if (!block.on || block.phase != 0) continue;
		if (official_block_contains(block, _x, _y, false)) {
			if (block.subtract) hole = !hole;
			else inside = true;
		}
		if (official_block_contains(block, _x, _y, true)) {
			if (block.subtract) hole_edge = !hole_edge;
			else inside_edge = true;
		}
	}
	return (inside ^ hole) && (inside_edge ^ hole_edge);
}

function official_block_has_id(_ids, _id) {
	var count = array_length(_ids);
	for (var i = 0; i < count; i++) {
		if (_ids[i] == _id) return true;
	}
	return false;
}

function official_block_hover_go(_hover, _target, _show) {
	_hover.from = _show ? 0 : _hover.scale;
	_hover.scale = _hover.from;
	_hover.target = _target;
	_hover.elapsed = 0;
	_hover.moving = true;
}

function official_block_hover_tick(_hover, _dt) {
	if (!_hover.moving) return;
	var progress = clamp(_hover.elapsed / 0.1, 0, 1);
	_hover.scale = _hover.from + (_hover.target - _hover.from) * progress;
	_hover.elapsed += max(0, _dt);
	if (progress >= 1) _hover.moving = false;
}

function official_block_input(_state, _aspect, _dt) {
	var touches = [];
	for (var device = 0; device < 4; device++) {
		if (!device_mouse_check_button(device, mb_left)) continue;
		var world = official_block_pixel_to_world(device_mouse_x(device), device_mouse_y(device), _aspect);
		array_push(touches, { id: device, x: world[0], y: world[1] });
	}
	var still = [];
	var worlds = [];
	var seen = array_create(10, false);
	var touch_count = array_length(touches);
	var hovers = _state.hovers;
	for (var t = 0; t < touch_count; t++) {
		var touch = touches[t];
		var blocked = official_block_has_id(_state.blocked_ids, touch.id) || official_block_hits(_state, touch.x, touch.y);
		if (!blocked) continue;
		array_push(still, touch.id);
		array_push(worlds, [touch.x, touch.y]);
		var slot = -1;
		for (var h = 0; h < 10; h++) {
			if (hovers[h].id == touch.id) {
				slot = h;
				break;
			}
		}
		if (slot < 0) {
			for (var empty = 0; empty < 10; empty++) {
				if (hovers[empty].id == -1) {
					slot = empty;
					break;
				}
			}
		}
		if (slot >= 0) {
			var hover = hovers[slot];
			if (hover.id != touch.id) {
				hover.id = touch.id;
				official_block_hover_go(hover, 11.5, true);
			}
			hover.x = touch.x;
			hover.y = touch.y;
			seen[slot] = true;
		}
	}
	_state.blocked_ids = still;
	_state.touch_world = worlds;
	var live = false;
	for (var i = 0; i < 10; i++) {
		var hover_slot = hovers[i];
		if (hover_slot.id != -1 && !seen[i]) {
			hover_slot.id = -1;
			official_block_hover_go(hover_slot, 0, false);
		}
		official_block_hover_tick(hover_slot, _dt);
		if (hover_slot.scale > 0) {
			live = true;
			var reach = 0.22 * hover_slot.scale;
			var hx = hover_slot.x;
			var hy = hover_slot.y;
			var p0 = official_block_world_to_room(hx - reach, hy - reach, _aspect);
			var p1 = official_block_world_to_room(hx - reach, hy + reach, _aspect);
			var p2 = official_block_world_to_room(hx + reach, hy - reach, _aspect);
			var p3 = official_block_world_to_room(hx + reach, hy + reach, _aspect);
			official_block_cover_add(_state.cover_active, p0[0], p0[1]);
			official_block_cover_add(_state.cover_active, p1[0], p1[1]);
			official_block_cover_add(_state.cover_active, p2[0], p2[1]);
			official_block_cover_add(_state.cover_active, p3[0], p3[1]);
		}
	}
	_state.hover_live = live;
}

function official_block_slot(_shader, _name, _sampler) {
	static cache = {};
	var key = string(_shader) + (_sampler ? "#" : ":") + _name;
	if (variable_struct_exists(cache, key)) return cache[$ key];
	if (!shader_is_compiled(_shader)) return -1;
	var handle = _sampler ? shader_get_sampler_index(_shader, _name) : shader_get_uniform(_shader, _name);
	if (is_real(handle) && handle >= 0) cache[$ key] = handle;
	return is_real(handle) ? handle : -1;
}

function official_block_u1(_shader, _name, _value) {
	var handle = official_block_slot(_shader, _name, false);
	if (handle >= 0) shader_set_uniform_f(handle, _value);
}

function official_block_u2(_shader, _name, _x, _y) {
	var handle = official_block_slot(_shader, _name, false);
	if (handle >= 0) shader_set_uniform_f(handle, _x, _y);
}

function official_block_u3(_shader, _name, _x, _y, _z) {
	var handle = official_block_slot(_shader, _name, false);
	if (handle >= 0) shader_set_uniform_f(handle, _x, _y, _z);
}

function official_block_u4(_shader, _name, _x, _y, _z, _w) {
	var handle = official_block_slot(_shader, _name, false);
	if (handle >= 0) shader_set_uniform_f(handle, _x, _y, _z, _w);
}

function official_block_ui(_shader, _name, _value) {
	var handle = official_block_slot(_shader, _name, false);
	if (handle >= 0) shader_set_uniform_i(handle, _value);
}

function official_block_tex(_shader, _name, _texture, _linear, _repeat) {
	var stage = official_block_slot(_shader, _name, true);
	if (stage < 0 || _texture == -1) return;
	texture_set_stage(stage, _texture);
	gpu_set_texfilter_ext(stage, _linear);
	gpu_set_texrepeat_ext(stage, _repeat);
}

function official_block_image(_state, _sprite) {
	if (sprite_exists(_sprite)) return sprite_get_texture(_sprite, 0);
	if (surface_exists(_state.white_surf)) return surface_get_texture(_state.white_surf);
	return -1;
}

function official_block_surf_tex(_state, _index) {
	if (_index >= 0 && _index < BLOCK_RT_COUNT && surface_exists(_state.rt[_index])) return surface_get_texture(_state.rt[_index]);
	if (surface_exists(_state.blank_surf)) return surface_get_texture(_state.blank_surf);
	return -1;
}

function official_block_pixels(_state) {
	if (!surface_exists(_state.white_surf)) {
		_state.white_surf = surface_create(1, 1);
		_state.cleared = false;
	}
	if (!surface_exists(_state.blank_surf)) {
		_state.blank_surf = surface_create(1, 1);
		_state.cleared = false;
	}
	if (!_state.cleared && surface_exists(_state.white_surf) && surface_exists(_state.blank_surf)) {
		surface_set_target(_state.white_surf);
		draw_clear_alpha(c_white, 1);
		surface_reset_target();
		surface_set_target(_state.blank_surf);
		draw_clear_alpha(c_black, 0);
		surface_reset_target();
		_state.cleared = true;
	}
	return surface_exists(_state.white_surf) && surface_exists(_state.blank_surf) && _state.cleared;
}

function official_block_warm_bind(_shader, _texture) {
	static names = ["_MainTex", "_DisplaceMap", "_NormalBlockRT", "_SubtractBlockRT", "_DisabledNormalBlockRT", "_DisabledSubtractBlockRT", "_ComposeRT", "_SparkMap", "_EffectRT", "_SceneColor", "_NoiseMap", "_MaskRT", "Active", "Ready", "Normal", "Subtract", "Glow", "Hover"];
	var count = array_length(names);
	for (var i = 0; i < count; i++) official_block_tex(_shader, names[i], _texture, true, true);
}

function official_block_gpu_warm(_state) {
	if (_state.gpu_warm || !surface_exists(_state.white_surf)) return;
	var warm = surface_create(2, 2);
	if (!surface_exists(warm)) return;
	var shaders = [
		shd_block_subtract, shd_block_subtract_soft, shd_block_compose, shd_block_compose_plain,
		shd_block_glow, shd_block_disabled, shd_block_active, shd_block_active_ready,
		shd_block_pack_mask, shd_block_pack_effect, shd_block_hover, shd_block_warp
	];
	var white = surface_get_texture(_state.white_surf);
	var count = array_length(shaders);
	for (var i = 0; i < count; i++) {
		var shader = shaders[i];
		if (!shader_is_compiled(shader)) continue;
		surface_set_target(warm);
		draw_clear_alpha(c_black, 0);
		shader_set(shader);
		if (shader == shd_block_active || shader == shd_block_active_ready) official_block_active_uniforms(shader, _state, 0, 2, 2);
		else if (shader == shd_block_disabled) official_block_disabled_uniforms(shader, 0);
		else if (shader == shd_block_compose) official_block_compose_uniforms(shader, 0);
		else if (shader == shd_block_glow) official_block_u4(shader, "_DilateTexelSize", 0.5, 0.5, 2, 2);
		else if (shader == shd_block_subtract || shader == shd_block_subtract_soft) {
			official_block_u1(shader, "_ClampThresholdLow", 0.09);
			official_block_u1(shader, "_ClampThresholdHigh", 0.12);
		}
		official_block_warm_bind(shader, white);
		draw_set_colour(c_white);
		draw_set_alpha(1);
		draw_surface_stretched(_state.white_surf, 0, 0, 2, 2);
		shader_reset();
		surface_reset_target();
	}
	surface_free(warm);
	_state.gpu_warm = true;
	official_block_refresh_ok(_state);
}

function official_block_rt_ensure(_state, _w, _h) {
	if (_state.surf_w == _w && _state.surf_h == _h && surface_exists(_state.rt[0])) return true;
	official_block_free_rt(_state);
	var bw = max(1, _w div 8);
	var bh = max(1, _h div 8);
	var ew = max(1, bw * 2);
	var eh = max(1, bh * 2);
	var sw = max(1, _w div 6);
	var sh = max(1, _h div 6);
	_state.bw = bw;
	_state.bh = bh;
	_state.ew = ew;
	_state.eh = eh;
	_state.sw = sw;
	_state.sh = sh;
	// Scene copy is full resolution. A 1:1 draw_surface matches the chart-grade
	// blit; the active shader still snaps samples to 6 screen pixels.
	var widths = [bw, bw, bw, bw, bw, bw, bw, bw, bw, bw, bw, ew, ew, bw, bw, ew, _w, bw];
	var heights = [bh, bh, bh, bh, bh, bh, bh, bh, bh, bh, bh, eh, eh, bh, bh, eh, _h, bh];
	for (var i = 0; i < BLOCK_RT_COUNT; i++) {
		_state.rt[i] = surface_create(widths[i], heights[i]);
		if (!surface_exists(_state.rt[i])) return false;
	}
	_state.surf_w = _w;
	_state.surf_h = _h;
	return true;
}

function official_block_fullscreen_begin(_dest, _shader) {
	surface_set_target(_dest);
	draw_clear_alpha(c_black, 0);
	gpu_set_blendmode_ext(bm_one, bm_zero);
	shader_set(_shader);
	draw_set_colour(c_white);
	draw_set_alpha(1);
	gpu_set_texfilter(false);
}

function official_block_fullscreen_end(_state, _dest) {
	draw_surface_stretched(_state.white_surf, 0, 0, surface_get_width(_dest), surface_get_height(_dest));
	shader_reset();
	surface_reset_target();
}

function official_block_draw_quad(_corners, _sx, _sy) {
	var x0 = _corners[0] * _sx;
	var y0 = _corners[1] * _sy;
	var x1 = _corners[2] * _sx;
	var y1 = _corners[3] * _sy;
	var x2 = _corners[4] * _sx;
	var y2 = _corners[5] * _sy;
	var x3 = _corners[6] * _sx;
	var y3 = _corners[7] * _sy;
	draw_primitive_begin(pr_trianglelist);
	draw_vertex(x0, y0);
	draw_vertex(x1, y1);
	draw_vertex(x2, y2);
	draw_vertex(x0, y0);
	draw_vertex(x2, y2);
	draw_vertex(x3, y3);
	draw_primitive_end();
}

function official_block_paint_group(_state, _index, _phase, _subtract, _sx, _sy) {
	var dest = _state.rt[_index];
	if (!surface_exists(dest)) return;
	surface_set_target(dest);
	draw_clear_alpha(c_black, 0);
	gpu_set_blendmode_ext(bm_src_alpha, bm_one);
	shader_reset();
	var blocks = _state.blocks;
	var count = array_length(blocks);
	for (var i = 0; i < count; i++) {
		var block = blocks[i];
		if (!block.on || block.phase != _phase || block.subtract != _subtract) continue;
		if (_subtract) {
			draw_set_colour(make_colour_rgb(255, floor(clamp(block.fade, 0, 1) * 255), 255));
			draw_set_alpha(0.1);
		} else {
			draw_set_colour(c_white);
			draw_set_alpha(block.fade);
		}
		official_block_draw_quad(block.corners, _sx, _sy);
	}
	draw_set_alpha(1);
	surface_reset_target();
}

function official_block_subtract_pass(_state, _shader, _dest_index, _source_index) {
	var dest = _state.rt[_dest_index];
	official_block_fullscreen_begin(dest, _shader);
	official_block_u1(_shader, "_ClampThresholdLow", 0.09);
	official_block_u1(_shader, "_ClampThresholdHigh", 0.12);
	official_block_tex(_shader, "_MainTex", official_block_surf_tex(_state, _source_index), false, false);
	official_block_fullscreen_end(_state, dest);
}

function official_block_compose_uniforms(_shader, _now) {
	official_block_u4(_shader, "_BlockTime", _now / 20, _now, _now * 2, _now * 3);
	official_block_u1(_shader, "_DisplaceSpeed", 2.5899999141693115);
	official_block_u1(_shader, "_DisplaceStrength", 0.10000000149011612);
	official_block_u4(_shader, "_DisplaceDirection", 0.5, 0.5, 0, 0);
	official_block_u4(_shader, "_DisplaceMap_ST", 2.130000114440918, 1.0199999809265137, 0, 0);
}

function official_block_compose_active(_state, _now) {
	var shader = shd_block_compose;
	var dest = _state.rt[BLOCK_RT_ACTIVE_C];
	official_block_fullscreen_begin(dest, shader);
	official_block_compose_uniforms(shader, _now);
	official_block_tex(shader, "_DisplaceMap", official_block_image(_state, _state.noise_spr), true, true);
	official_block_tex(shader, "_NormalBlockRT", official_block_surf_tex(_state, _state.norm_active ? BLOCK_RT_ACTIVE_N : -1), false, false);
	official_block_tex(shader, "_SubtractBlockRT", official_block_surf_tex(_state, _state.sub_active ? BLOCK_RT_ACTIVE_HP : -1), false, false);
	official_block_fullscreen_end(_state, dest);
}

function official_block_compose_plain(_state, _dest_index, _normal_index, _subtract_index) {
	var shader = shd_block_compose_plain;
	var dest = _state.rt[_dest_index];
	official_block_fullscreen_begin(dest, shader);
	official_block_tex(shader, "_DisabledNormalBlockRT", official_block_surf_tex(_state, _normal_index), false, false);
	official_block_tex(shader, "_DisabledSubtractBlockRT", official_block_surf_tex(_state, _subtract_index), false, false);
	official_block_fullscreen_end(_state, dest);
}

function official_block_glow(_state) {
	var shader = shd_block_glow;
	var weights = [0.45856798, 0.28286123, 0.15658922, 0.07305908, 0.02494781];
	var source = BLOCK_RT_ACTIVE_C;
	var ew = _state.ew;
	var eh = _state.eh;
	for (var pass = 0; pass < 5; pass++) {
		var dest_index = (pass mod 2) == 0 ? BLOCK_RT_GLOW0 : BLOCK_RT_GLOW1;
		var dest = _state.rt[dest_index];
		official_block_fullscreen_begin(dest, shader);
		official_block_u4(shader, "_DilateTexelSize", 1 / ew, 1 / eh, ew, eh);
		official_block_u1(shader, "_PassWeight", weights[pass]);
		official_block_u1(shader, "_GlowFirstPass", pass == 0 ? 1 : 0);
		official_block_tex(shader, "_MainTex", official_block_surf_tex(_state, source), false, false);
		official_block_tex(shader, "_ComposeRT", official_block_surf_tex(_state, BLOCK_RT_ACTIVE_C), false, false);
		official_block_fullscreen_end(_state, dest);
		source = dest_index;
	}
}

function official_block_paint_hover(_state) {
	var dest = _state.rt[BLOCK_RT_HOVER];
	if (!surface_exists(dest) || !sprite_exists(_state.touch_spr)) return;
	surface_set_target(dest);
	draw_clear_alpha(c_black, 0);
	gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
	shader_set(shd_block_hover);
	draw_set_colour(c_white);
	draw_set_alpha(1);
	var texture = sprite_get_texture(_state.touch_spr, 0);
	var uvs = texture_get_uvs(texture);
	var sx = _state.bw / _state.surf_w;
	var sy = _state.bh / _state.surf_h;
	var aspect = official_block_aspect();
	static local_x = [-0.14000000059604645, 0.2199999988079071, 0.2199999988079071, -0.1599999964237213, -0.2199999988079071, -0.2199999988079071];
	static local_y = [0.2199999988079071, -0.2199999988079071, 0.2199999988079071, -0.2199999988079071, 0.15000000596046448, -0.10999999940395355];
	static index = [5, 4, 3, 0, 3, 4, 1, 3, 0, 2, 1, 0];
	var hovers = _state.hovers;
	for (var h = 0; h < 10; h++) {
		var hover = hovers[h];
		if (hover.scale <= 0) continue;
		var pos = array_create(12, 0);
		for (var k = 0; k < 6; k++) {
			var room_point = official_block_world_to_room(hover.x + local_x[k] * hover.scale, hover.y + local_y[k] * hover.scale, aspect);
			pos[k * 2] = room_point[0] * sx;
			pos[k * 2 + 1] = room_point[1] * sy;
		}
		draw_primitive_begin_texture(pr_trianglelist, texture);
		for (var v = 0; v < 12; v++) {
			var point = index[v];
			var uu = local_x[point] / 0.44 + 0.5;
			var vv = local_y[point] / 0.44 + 0.5;
			draw_vertex_texture(pos[point * 2], pos[point * 2 + 1], uvs[0] + uu * (uvs[2] - uvs[0]), uvs[1] + vv * (uvs[3] - uvs[1]));
		}
		draw_primitive_end();
	}
	shader_reset();
	surface_reset_target();
}

function official_block_pack(_state) {
	var ready_tex = -1;
	if (_state.sub_ready && _state.ok_compose_plain) ready_tex = BLOCK_RT_READY_C;
	else if (_state.norm_ready) ready_tex = BLOCK_RT_READY_N;
	var active_tex = (_state.on_active && _state.ok_compose) ? BLOCK_RT_ACTIVE_C : -1;
	var glow_tex = (_state.on_active && _state.ok_compose && _state.ok_glow) ? BLOCK_RT_GLOW0 : -1;
	var mask = shd_block_pack_mask;
	var mask_dest = _state.rt[BLOCK_RT_PACK_M];
	official_block_fullscreen_begin(mask_dest, mask);
	official_block_tex(mask, "Active", official_block_surf_tex(_state, active_tex), false, false);
	official_block_tex(mask, "Ready", official_block_surf_tex(_state, ready_tex), false, false);
	official_block_tex(mask, "Normal", official_block_surf_tex(_state, _state.norm_ready ? BLOCK_RT_READY_N : -1), false, false);
	official_block_tex(mask, "Subtract", official_block_surf_tex(_state, _state.sub_ready ? BLOCK_RT_READY_HP : -1), false, false);
	official_block_fullscreen_end(_state, mask_dest);

	var pack_shader = shd_block_pack_effect;
	var effect_dest = _state.rt[BLOCK_RT_PACK_E];
	official_block_fullscreen_begin(effect_dest, pack_shader);
	official_block_tex(pack_shader, "Glow", official_block_surf_tex(_state, glow_tex), false, false);
	official_block_tex(pack_shader, "Hover", official_block_surf_tex(_state, _state.hover_live ? BLOCK_RT_HOVER : -1), false, false);
	official_block_fullscreen_end(_state, effect_dest);
}

function official_block_copy_scene(_state, _chart) {
	var dest = _state.rt[BLOCK_RT_SCENE];
	if (!surface_exists(dest) || !surface_exists(_chart)) return;
	var dest_w = surface_get_width(dest);
	var dest_h = surface_get_height(dest);
	var src_w = surface_get_width(_chart);
	var src_h = surface_get_height(_chart);
	// Same sequence as the chart grayscale copy. The view scissor is in
	// full-frame pixels and would otherwise clip this target.
	pls_draw_flush();
	surface_set_target(dest);
	gpu_set_scissor(0, 0, dest_w, dest_h);
	gpu_set_colourwriteenable(true, true, true, true);
	gpu_set_alphatestenable(false);
	gpu_set_blendenable(true);
	gpu_set_blendequation(bm_eq_add);
	gpu_set_blendmode_ext(bm_one, bm_zero);
	gpu_set_cullmode(cull_noculling);
	shader_reset();
	draw_set_colour(c_white);
	draw_set_alpha(1);
	draw_clear_alpha(c_black, 1);
	if (dest_w == src_w && dest_h == src_h) draw_surface(_chart, 0, 0);
	else draw_surface_stretched(_chart, 0, 0, dest_w, dest_h);
	pls_draw_flush();
	surface_reset_target();
}

function official_block_disabled_uniforms(_shader, _now) {
	official_block_u4(_shader, "_BlockTime", _now / 20, _now, _now * 2, _now * 3);
	official_block_u4(_shader, "_FillColor", 0.4970000088214874, 0.13766898214817047, 0.13766898214817047, 1);
	official_block_u1(_shader, "_FillOpacity", 0.4000000059604645);
	official_block_u3(_shader, "_SparkTint", 0.31132078170776367, 0.07783019542694092, 0.07783019542694092);
	official_block_u1(_shader, "_SparkMapOpacity", 3.5);
	official_block_u1(_shader, "_SparkDisplaceIntensity", 2.2899999618530273);
	official_block_u1(_shader, "_DisplaceSpeed", 0.30000001192092896);
	official_block_u4(_shader, "_DisplaceDirection", 1, 1, 0, 0);
	official_block_u4(_shader, "_DisplaceMap_ST", 0.5, 0.20000000298023224, 0, 0);
	official_block_u4(_shader, "_SparkMap_ST", 3, 1.2000000476837158, 0, 0);
}

function official_block_active_uniforms(_shader, _state, _now, _w, _h) {
	official_block_u4(_shader, "_BlockTime", _now / 20, _now, _now * 2, _now * 3);
	official_block_u4(_shader, "_ScreenParams", _w, _h, 1 + 1 / _w, 1 + 1 / _h);
	official_block_u4(_shader, "_EffectRT_TexelSize", 1 / _state.ew, 1 / _state.eh, _state.ew, _state.eh);
	official_block_u4(_shader, "_EdgeColor", 1, 0.3301885724067688, 0.3301885724067688, 1);
	official_block_u1(_shader, "_EdgeOpacity", 0.800000011920929);
	official_block_u4(_shader, "_FillColor", 0.713207483291626, 0.23549295961856842, 0.23549295961856842, 1);
	official_block_u1(_shader, "_FillStrength", 0.6669999957084656);
	official_block_u1(_shader, "_FillOpacity", 0.6669999957084656);
	official_block_u4(_shader, "_GlowColor", 1, 0.17924517393112183, 0.17924517393112183, 1);
	official_block_u1(_shader, "_GlowIntensity", 0.800000011920929);
	official_block_u3(_shader, "_SparkTint", 1, 0.28490567207336426, 0.28490567207336426);
	official_block_u1(_shader, "_SparkMapOpacity", 5.690000057220459);
	official_block_u1(_shader, "_SparkHueShiftAmount", 0.20000000298023224);
	official_block_u1(_shader, "_SparkDisplaceIntensity", 2.390000104904175);
	official_block_u1(_shader, "_DisplaceBlendIntensity", 0.41100001335144043);
	official_block_u1(_shader, "_DisplaceSpeed", 1.5);
	official_block_u1(_shader, "_DisplaceStrength", 0.15000000596046448);
	official_block_u4(_shader, "_DisplaceDirection", 1, 1, 0, 0);
	official_block_u1(_shader, "_TouchPosShine", 1);
	official_block_u1(_shader, "_TouchPosRadius", 0.5);
	official_block_u1(_shader, "_TouchPosSDFSmoothness", 0.4699999988079071);
	official_block_u1(_shader, "_TouchPosSDFFalloff", 0.4099999964237213);
	official_block_u1(_shader, "_BackgroundPixelScale", 6);
	official_block_u1(_shader, "_ShineSpeed", 37.900001525878906);
	official_block_u1(_shader, "_ShineBrightness", 0.11999999731779099);
	official_block_u4(_shader, "_ShineColor", 1, 1, 1, 1);
	official_block_u1(_shader, "_TouchDisplaceSpeed", 2.9000000953674316);
	official_block_u1(_shader, "_TouchDisplaceStrength", 0.07999999821186066);
	official_block_u4(_shader, "_TouchDisplaceDirection", 1, 1, 0, 0);
	official_block_u4(_shader, "_NoiseTint", 1, 0, 0, 1);
	official_block_u1(_shader, "_NoiseEvoSpeed", 0.029999999329447746);
	official_block_u1(_shader, "_NoiseDirChangeSpeed", 60);
	official_block_u1(_shader, "_NoiseDisplaceStrength", 1);
	official_block_u1(_shader, "_NoiseRadius", 0.47999998927116394);
	official_block_u1(_shader, "_NoiseSmoothness", 1);
	official_block_u1(_shader, "_SDFCellSize", 0.10999999940395355);
	official_block_u1(_shader, "_SDFFalloff", 0.3400000035762787);
	official_block_u1(_shader, "_SDFSmoothness", 0.6299999952316284);
	official_block_u1(_shader, "_SDFMoveSpeed", 9.300000190734863);
	official_block_u4(_shader, "_TouchGlowColor", 1, 0, 0, 1);
	official_block_u1(_shader, "_TouchBackgroundPixelScale", 8);
	official_block_u4(_shader, "_DisplaceMap_ST", 0.800000011920929, 0.30000001192092896, 0, 0);
	official_block_u4(_shader, "_SparkMap_ST", 3, 1.2000000476837158, 0, 0);
	official_block_u4(_shader, "_TouchDisplaceMap_ST", 0.550000011920929, 0.30000001192092896, 0, 0);
	official_block_u4(_shader, "_NoiseMap_ST", 1.5, 1.4600000381469727, 0, 0);
	official_block_u2(_shader, "_HoverSize", _state.bw, _state.bh);
	official_block_u1(_shader, "_RemoveDistortion", 0);
	static touch_names = ["_TouchPos0", "_TouchPos1", "_TouchPos2", "_TouchPos3", "_TouchPos4", "_TouchPos5", "_TouchPos6", "_TouchPos7", "_TouchPos8", "_TouchPos9"];
	var worlds = _state.touch_world;
	var touch_count = min(10, array_length(worlds));
	official_block_ui(_shader, "_TouchPosCount", (_shader == shd_block_active) ? touch_count : 0);
	var aspect = official_block_aspect();
	for (var i = 0; i < 10; i++) {
		var tx = 0;
		var ty = 0;
		if (i < touch_count && _shader == shd_block_active) {
			var room_point = official_block_world_to_room(worlds[i][0], worlds[i][1], aspect);
			tx = (room_point[0] / _w) * _w / _h;
			ty = room_point[1] / _h;
		}
		official_block_u2(_shader, touch_names[i], tx, ty);
	}
}

function official_block_scissor(_cover, _margin, _w, _h) {
	if (_cover.bad) return true;
	if (!_cover.any) return false;
	var x0 = clamp(floor(_cover.minx - _margin), 0, _w);
	var y0 = clamp(floor(_cover.miny - _margin), 0, _h);
	var x1 = clamp(ceil(_cover.maxx + _margin), 0, _w);
	var y1 = clamp(ceil(_cover.maxy + _margin), 0, _h);
	if (x1 - x0 < 1 || y1 - y0 < 1) return false;
	gpu_set_scissor(x0, y0, x1 - x0, y1 - y0);
	return true;
}

function official_block_warp_present(_state, _w, _h, _now) {
	if (!shader_is_compiled(shd_block_warp)) return;
	if (!surface_exists(_state.rt[BLOCK_RT_SCENE])) return;
	var scene_tex = surface_get_texture(_state.rt[BLOCK_RT_SCENE]);
	var mask_tex = official_block_surf_tex(_state, BLOCK_RT_PACK_M);
	var noise_tex = official_block_image(_state, _state.noise_spr);
	if (scene_tex == -1 || mask_tex == -1 || noise_tex == -1) return;
	shader_set(shd_block_warp);
	var screen_handle = shader_get_uniform(shd_block_warp, "u_screen");
	var scene_handle = shader_get_uniform(shd_block_warp, "u_scene");
	var noise_uv_handle = shader_get_uniform(shd_block_warp, "u_noise_uv");
	var fill_handle = shader_get_uniform(shd_block_warp, "u_fill");
	var scene_uvs = texture_get_uvs(scene_tex);
	var noise_uvs = texture_get_uvs(noise_tex);
	// w is how long one red-speck arrangement stays put, in chart seconds.
	if (screen_handle >= 0) shader_set_uniform_f(screen_handle, _w, _h, _now, 0.18);
	if (scene_handle >= 0) shader_set_uniform_f(scene_handle, scene_uvs[0], scene_uvs[1], scene_uvs[2], scene_uvs[3]);
	if (noise_uv_handle >= 0) shader_set_uniform_f(noise_uv_handle, noise_uvs[0], noise_uvs[1], noise_uvs[2], noise_uvs[3]);
	if (fill_handle >= 0) shader_set_uniform_f(fill_handle, 0.713207483291626, 0.23549295961856842, 0.23549295961856842);
	var mask_stage = shader_get_sampler_index(shd_block_warp, "u_mask");
	var noise_stage = shader_get_sampler_index(shd_block_warp, "u_noise");
	var edge_stage = shader_get_sampler_index(shd_block_warp, "u_edge");
	var edge_tex = official_block_surf_tex(_state, BLOCK_RT_PACK_E);
	if (mask_stage > 0) {
		texture_set_stage(mask_stage, mask_tex);
		gpu_set_texfilter_ext(mask_stage, false);
		gpu_set_texrepeat_ext(mask_stage, false);
	}
	if (edge_stage > 0 && edge_tex != -1) {
		texture_set_stage(edge_stage, edge_tex);
		gpu_set_texfilter_ext(edge_stage, true);
		gpu_set_texrepeat_ext(edge_stage, false);
	}
	if (noise_stage > 0) {
		texture_set_stage(noise_stage, noise_tex);
		gpu_set_texfilter_ext(noise_stage, true);
		gpu_set_texrepeat_ext(noise_stage, true);
	}
	// Stage 0 is the chart copy. Set it after the other samplers so the white
	// quad from the pass above cannot remain bound.
	texture_set_stage(0, scene_tex);
	gpu_set_texfilter(false);
	gpu_set_texrepeat(false);
	gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
	draw_set_colour(c_white);
	draw_set_alpha(1);
	draw_primitive_begin_texture(pr_trianglelist, scene_tex);
	draw_vertex_texture(0, 0, 0, 0);
	draw_vertex_texture(_w, 0, 1, 0);
	draw_vertex_texture(_w, _h, 1, 1);
	draw_vertex_texture(0, 0, 0, 0);
	draw_vertex_texture(_w, _h, 1, 1);
	draw_vertex_texture(0, _h, 0, 1);
	draw_primitive_end();
	shader_reset();
}

function official_block_present_quad(_state, _w, _h, _surface) {
	var source = _state.white_surf;
	if (is_real(_surface) && surface_exists(_surface)) source = _surface;
	draw_surface_stretched(source, 0, 0, _w, _h);
	shader_reset();
}

function official_block_present(_state, _now, _w, _h) {
	gpu_set_alphatestenable(false);
	draw_set_colour(c_white);
	draw_set_alpha(1);
	if (_state.on_disabled && _state.ok_disabled && official_block_scissor(_state.cover_disabled, 16, _w, _h)) {
		var shader = shd_block_disabled;
		var compose = -1;
		if (_state.sub_disabled && _state.ok_compose_plain) compose = BLOCK_RT_OFF_C;
		else if (_state.norm_disabled) compose = BLOCK_RT_OFF_N;
		if (compose >= 0) {
			gpu_set_blendmode_ext(bm_one, bm_one);
			shader_set(shader);
			official_block_disabled_uniforms(shader, _now);
			official_block_tex(shader, "_ComposeRT", official_block_surf_tex(_state, compose), false, false);
			official_block_tex(shader, "_DisplaceMap", official_block_image(_state, _state.noise_spr), true, true);
			official_block_tex(shader, "_SparkMap", official_block_image(_state, _state.spark_spr), true, true);
			official_block_present_quad(_state, _w, _h);
		}
		gpu_set_scissor(0, 0, _w, _h);
	}
	var active_shader = (_state.on_active || _state.hover_live) ? shd_block_active : shd_block_active_ready;
	var active_ok = (active_shader == shd_block_active) ? _state.ok_active : _state.ok_ready;
	if ((_state.on_active || _state.on_ready || _state.hover_live) && active_ok) {
		var margin = 0.11 * max(_w, _h) + 8;
		if (official_block_scissor(_state.cover_active, margin, _w, _h)) {
			gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
			shader_set(active_shader);
			official_block_active_uniforms(active_shader, _state, _now, _w, _h);
			official_block_tex(active_shader, "_MaskRT", official_block_surf_tex(_state, BLOCK_RT_PACK_M), false, false);
			official_block_tex(active_shader, "_EffectRT", official_block_surf_tex(_state, BLOCK_RT_PACK_E), false, false);
			official_block_tex(active_shader, "_DisplaceMap", official_block_image(_state, _state.noise_spr), true, true);
			official_block_tex(active_shader, "_SparkMap", official_block_image(_state, _state.spark_spr), true, true);
			official_block_tex(active_shader, "_NoiseMap", official_block_image(_state, _state.grain_spr), true, true);
			// The quad itself stays the 1x1 white surface so its UVs remain
			// the 0..1 screen coordinates the mask was built for. Drawing the
			// chart copy as that quad leaves gm_BaseTexture white, because
			// texture_set_stage runs first. _SceneColor is a later sampler.
			var scene_index = (active_shader == shd_block_active) ? BLOCK_RT_SCENE : -1;
			official_block_tex(active_shader, "_SceneColor", official_block_surf_tex(_state, scene_index), false, false);
			official_block_present_quad(_state, _w, _h);
			// The material pass leaves the sharp chart visible inside the zone.
			// Replace that interior with the pixel-snapped, displaced copy.
			if (active_shader == shd_block_active) official_block_warp_present(_state, _w, _h, _now);
			gpu_set_scissor(0, 0, _w, _h);
		}
	}
}

function official_block_offscreen(_state, _chart, _now) {
	var sx = _state.bw / _state.surf_w;
	var sy = _state.bh / _state.surf_h;
	gpu_set_alphatestenable(false);
	gpu_set_blendenable(true);
	gpu_set_cullmode(cull_noculling);
	gpu_set_zwriteenable(false);
	gpu_set_ztestenable(false);
	if (_state.norm_active) official_block_paint_group(_state, BLOCK_RT_ACTIVE_N, 0, false, sx, sy);
	if (_state.sub_active) official_block_paint_group(_state, BLOCK_RT_ACTIVE_H, 0, true, sx, sy);
	if (_state.norm_ready) official_block_paint_group(_state, BLOCK_RT_READY_N, 1, false, sx, sy);
	if (_state.sub_ready) official_block_paint_group(_state, BLOCK_RT_READY_H, 1, true, sx, sy);
	if (_state.norm_disabled) official_block_paint_group(_state, BLOCK_RT_OFF_N, 2, false, sx, sy);
	if (_state.sub_disabled) official_block_paint_group(_state, BLOCK_RT_OFF_H, 2, true, sx, sy);
	if (_state.sub_active && _state.ok_subtract) official_block_subtract_pass(_state, shd_block_subtract, BLOCK_RT_ACTIVE_HP, BLOCK_RT_ACTIVE_H);
	if (_state.sub_ready && _state.ok_subtract_soft) official_block_subtract_pass(_state, shd_block_subtract_soft, BLOCK_RT_READY_HP, BLOCK_RT_READY_H);
	if (_state.sub_disabled && _state.ok_subtract_soft) official_block_subtract_pass(_state, shd_block_subtract_soft, BLOCK_RT_OFF_HP, BLOCK_RT_OFF_H);
	if (_state.on_active && _state.ok_compose) official_block_compose_active(_state, _now);
	if (_state.on_ready && _state.sub_ready && _state.ok_compose_plain) {
		official_block_compose_plain(_state, BLOCK_RT_READY_C, _state.norm_ready ? BLOCK_RT_READY_N : -1, BLOCK_RT_READY_HP);
	}
	if (_state.on_disabled && _state.sub_disabled && _state.ok_compose_plain) {
		official_block_compose_plain(_state, BLOCK_RT_OFF_C, _state.norm_disabled ? BLOCK_RT_OFF_N : -1, BLOCK_RT_OFF_HP);
	}
	if (_state.on_active && _state.ok_compose && _state.ok_glow) official_block_glow(_state);
	if (_state.hover_live && _state.ok_hover) official_block_paint_hover(_state);
	if ((_state.on_active || _state.on_ready || _state.hover_live) && _state.ok_pack_m && _state.ok_pack_e) {
		official_block_pack(_state);
	}
	if ((_state.on_active || _state.hover_live) && surface_exists(_chart)) official_block_copy_scene(_state, _chart);
}

function official_block_chart_id() {
	if (!instance_exists(oChartMask)) return -1;
	if (!surface_exists(oChartMask.surface_id)) return -1;
	return oChartMask.surface_id;
}

function official_blocks_draw() {
	if (official_blocks_ending()) {
		shader_reset();
		return;
	}
	var state = official_blocks_ensure();
	if (!official_block_enabled() || !state.ready || state.empty) return;
	if (!state.preloaded) official_blocks_preload();
	var loading = variable_global_exists("loading_animation_active") && global.loading_animation_active;
	var wants = false;
	var now = 0;
	var aspect = official_block_aspect();
	if (!loading && official_block_view_ready() && variable_global_exists("game") && is_struct(game) && is_array(game[$ "__time"]) && array_length(game.__time) >= 2 && is_real(game.__time[1])) {
		now = game.__time[1];
		var outside = now < state.first_appear || now >= state.last_disappear;
		if (!(outside && !state.hover_live && array_length(state.blocked_ids) == 0)) {
			if (outside) official_block_hide(state);
			else official_block_gather(state, now, aspect);
			var frame_dt = delta_time / 1000000;
			if (!is_real(frame_dt) || frame_dt < 0) frame_dt = 0;
			if (frame_dt > 0.05) frame_dt = 0.05;
			official_block_input(state, aspect, frame_dt);
			wants = state.need_gpu || state.hover_live;
		}
	}
	if (!wants && state.gpu_warm) return;
	if (!variable_global_exists("chart_surface_active") || !chart_surface_active) return;
	var chart_id = official_block_chart_id();
	if (chart_id == -1) return;
	pls_draw_flush();
	surface_reset_target();
	var restored = false;
	gpu_push_state();
	try {
		if (!official_block_pixels(state)) {
			// Surfaces are unavailable this frame.
		} else {
			if (!state.gpu_warm) official_block_gpu_warm(state);
			if (wants && state.gpu_warm) {
				var full_w = surface_get_width(chart_id);
				var full_h = surface_get_height(chart_id);
				if (full_w > 1 && full_h > 1 && official_block_rt_ensure(state, full_w, full_h)) {
					official_block_offscreen(state, chart_id, now);
					surface_set_target(chart_id);
					restored = true;
					official_block_present(state, now, full_w, full_h);
				}
			}
		}
	} finally {
		if (!restored && surface_exists(chart_id)) surface_set_target(chart_id);
		shader_reset();
		gpu_pop_state();
		shader_reset();
	}
}
