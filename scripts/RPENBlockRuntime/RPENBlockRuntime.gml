/// RPEN geometry/state adapter. Materials remain the existing Official shaders.
/// Reference: Phira-Pro prpr/src/core/{rpe_next_block,block_next_mask}.rs.

/// RPE's playback clock is media time; beat events use chart time.
function rpen_noise_chart_time(_media_time) {
	if (variable_global_exists("game_1") && is_struct(game_1) && is_struct(game_1.chart_info)) {
		return _media_time - real(game_1.chart_info.offset ?? 0) / 1000;
	}
	return _media_time;
}

/// Parse once, separate layers so inverse regions never cancel across layers.
function rpen_blocks_load(_chart) {
	var areas = rpen_blocks_parse(_chart);
	official_blocks_reset();
	var state = official_block_state();
	state.rpen_session = true;
	var native = [];
	var source = _chart[$ "blockAreaList"] ?? (_chart[$ "BlockAreaList"] ?? []);
	for (var si = 0; si < array_length(source); si++) {
		if (is_struct(source[si]) && !is_undefined(source[si][$ "bottomLeftPercentage"])) array_push(native, source[si]);
	}
	// The Official packer owns/removes this temporary source; no actor references.
	game.chart = { blockAreaList: native };
	while (!official_blocks_pack_large(game.chart)) {}
	state.pack_tried = true;
	var layers = state.rpen_layers;
	for (var ai = 0; ai < array_length(areas); ai++) {
		var area = areas[ai];
		var layer_index = area.layer;
		while (array_length(layers) <= layer_index) {
			var rpen_layer_state = official_block_state_create();
			rpen_layer_state.rpen_layer = true;
			rpen_layer_state.packed = true;
			rpen_layer_state.pack_phase = 4;
			rpen_layer_state.pack_tried = true;
			rpen_layer_state.pack_first = infinity;
			rpen_layer_state.pack_last = -infinity;
			rpen_layer_state.scan_active = [];
			array_push(layers, rpen_layer_state);
		}
		var owner = layers[layer_index];
		owner.single_inversion = area.single_inversion;
		array_push(owner.pack_complex, area);
		owner.pack_first = min(owner.pack_first, area.appear);
		owner.pack_last = max(owner.pack_last, area.disappear);
	}
	for (var li = 0; li < array_length(layers); li++) {
		var rpen_layer_state = layers[li];
		rpen_layer_state.empty = array_length(rpen_layer_state.pack_complex) == 0;
		rpen_layer_state.first_appear = rpen_layer_state.pack_first;
		rpen_layer_state.last_disappear = rpen_layer_state.pack_last;
		official_block_complex_index(rpen_layer_state);
	}
	// Raw JSON is no longer needed by the renderer. Parsed tracks keep values only.
	struct_remove(_chart, "blockAreaList");
	struct_remove(_chart, "BlockAreaList");
}

/// Convert in canvas space before nonuniform viewport mapping.
function rpen_block_activate(_state, _block, _now, _aspect, _half) {
	_block.on = false;
	if (_now + 0.000000001 < _block.appear || _now + 0.000000001 >= _block.disappear) return;
	var pose = rpen_block_pose(_block, _now, _aspect);
	if (!is_finite(pose[0]) || !is_finite(pose[1]) || !is_finite(pose[2])
		|| !is_finite(pose[3]) || !is_finite(pose[4]) || pose[2] <= 0 || pose[3] <= 0) return;
	var phase = rpen_block_phase(_block, _now);
	var cosine = cos(pose[4]);
	var sine = sin(pose[4]);
	var corners = _block.corners;
	for (var ci = 0; ci < 4; ci++) {
		var lx = _half[ci][0] * pose[2];
		var ly = _half[ci][1] * pose[3];
		var px = pose[0] + cosine * lx + sine * ly;
		var py = pose[1] - sine * lx + cosine * ly;
		corners[ci * 2] = chart_view_left + (px / 1350 + 0.5) * chart_view_width;
		corners[ci * 2 + 1] = (0.5 - py / 900) * chart_view_height;
	}
	_block.on = true;
	_block.phase = phase;
	_block.cx = pose[0];
	_block.cy = pose[1];
	_block.sx = pose[2];
	_block.sy = pose[3];
	_block.ang = pose[4];
	_block.cosine = cosine;
	_block.sine = sine;
	_block.rpen_aspect = _aspect;
	var cover = phase == 2 ? _state.cover_disabled : _state.cover_active;
	for (var ci = 0; ci < 4; ci++) official_block_cover_add(cover, corners[ci * 2], corners[ci * 2 + 1]);
	if (phase == 0) {
		_state.on_active = true;
		if (_block.subtract) _state.sub_active = true; else _state.norm_active = true;
	} else if (phase == 1) {
		_state.on_ready = true;
		if (_block.subtract) _state.sub_ready = true; else _state.norm_ready = true;
	} else _state.on_disabled = true;
	if (phase == 2) {
		_state.on_disabled = true;
		if (_block.subtract) _state.sub_disabled = true; else _state.norm_disabled = true;
		for (var ci = 0; ci < 4; ci++) official_block_cover_add(_state.cover_disabled, corners[ci * 2], corners[ci * 2 + 1]);
	}
}

/// Reverse the same canvas mapping as the four rendered corners.
function rpen_block_contains(_block, _x, _y, _adjusted) {
	if (_block.sx <= 0 || _block.sy <= 0) return false;
	var dx = _x * 1350 / (10 * _block.rpen_aspect) - _block.cx;
	var dy = _y * 90 - _block.cy;
	var lx = _block.cosine * dx - _block.sine * dy;
	var ly = _block.sine * dx + _block.cosine * dy;
	var hx = _block.sx * 0.5;
	var hy = _block.sy * 0.5;
	if (_adjusted) {
		var ax = 10 * _block.rpen_aspect / 1350;
		var ay = 10 / 900;
		var cs = _block.cosine;
		var sn = _block.sine;
		var nx = sqrt(sqr(cs * ax) + sqr(sn * ay));
		var ny = sqrt(sqr(sn * ax) + sqr(cs * ay));
		var inset_direction = _block.subtract ? 1 : -1;
		// Preserve the Official input margin, expressed in this canvas mapping.
		hx += min(0.3 / max(0.000000001, nx), hx * 0.5) * inset_direction;
		hy += min(0.3 / max(0.000000001, ny), hy * 0.5) * inset_direction;
	}
	return abs(lx) <= hx && abs(ly) <= hy;
}

/// Each rpen_layer_state uses its own inversion count; final blocking is their union.
function rpen_layer_hits(_state, _x, _y) {
	var normal = false, normal_edge = false, inverse = 0, inverse_edge = 0;
	var areas = _state.complex_live;
	for (var ai = 0; ai < array_length(areas); ai++) {
		var area = areas[ai];
		if (!area.on || area.phase != 0) continue;
		if (rpen_block_contains(area, _x, _y, false)) {
			if (area.subtract) inverse++; else normal = true;
		}
		if (rpen_block_contains(area, _x, _y, true)) {
			if (area.subtract) inverse_edge++; else normal_edge = true;
		}
	}
	var hole = _state.single_inversion ? inverse == 1 : (inverse mod 2) == 1;
	var hole_edge = _state.single_inversion ? inverse_edge == 1 : (inverse_edge mod 2) == 1;
	return (normal ^^ hole) && (normal_edge ^^ hole_edge);
}

/// Borrow packaged textures; each rpen_layer_state retains its own volatile render targets.
function rpen_block_layer_resources(_layer, _root) {
	_layer.noise_spr = _root.noise_spr;
	_layer.spark_spr = _root.spark_spr;
	_layer.grain_spr = _root.grain_spr;
	_layer.touch_spr = _root.touch_spr;
	official_block_refresh_ok(_layer);
	return official_block_pixels(_layer);
}

/// Resolve shape coverage/priority before feeding the Official materials.
function rpen_block_resolve_masks(_state) {
	var shader = shd_rpen_block_resolve;
	var normal = [BLOCK_RT_ACTIVE_N, BLOCK_RT_READY_N, BLOCK_RT_OFF_N];
	var inverse = [BLOCK_RT_ACTIVE_HP, BLOCK_RT_READY_HP, BLOCK_RT_OFF_HP];
	var dests = [BLOCK_RT_RPEN_ACTIVE, BLOCK_RT_RPEN_READY, BLOCK_RT_RPEN_OFF];
	var normals = [_state.norm_active, _state.norm_ready, _state.norm_disabled];
	var inverses = [_state.sub_active, _state.sub_ready, _state.sub_disabled];
	var enabled = [_state.on_active, _state.on_ready, _state.on_disabled];
	for (var phase = 0; phase < 3; phase++) {
		if (!enabled[phase]) continue;
		var dest = _state.rt[dests[phase]];
		official_block_fullscreen_begin(dest, shader);
		official_block_u1(shader, "u_phase", phase);
		official_block_tex(shader, "u_normal", official_block_surf_tex(_state, normals[phase] ? normal[phase] : -1), false, false);
		official_block_tex(shader, "u_inverse", official_block_surf_tex(_state, inverses[phase] ? inverse[phase] : -1), false, false);
		official_block_tex(shader, "u_active", official_block_surf_tex(_state, _state.on_active && phase > 0 ? BLOCK_RT_RPEN_ACTIVE : -1), false, false);
		official_block_tex(shader, "u_ready", official_block_surf_tex(_state, _state.on_ready && phase > 1 ? BLOCK_RT_RPEN_READY : -1), false, false);
		official_block_fullscreen_end(_state, dest);
	}
}
