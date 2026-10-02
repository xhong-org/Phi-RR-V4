function hold_sprite_is_default_note(_spr) {
	return _spr == note_hold_head || _spr == note_hold_body || _spr == note_hold_end;
}

function hold_sprite_frames_ready(_spr) {
	if (!sprite_exists(_spr)) then return false;
	if (pls_is_html5()) then return true;
	var frames = sprite_get_number(_spr);
	for (var f = 0; f < frames; f++) {
		var tex = sprite_get_texture(_spr, f);
		if (is_undefined(tex) || (is_real(tex) && tex < 0)) then return false;
		if (!texture_is_ready(tex)) then return false;
	};
	return true;
}

/// DefaultNotes is dynamicpages. Baking a hold before its page is fetched copies the fallback page.
function hold_default_notes_prefetch() {
	if (pls_is_html5() || !texturegroup_exists("DefaultNotes")) then return;
	var status = texturegroup_get_status("DefaultNotes");
	if (status == texturegroup_status_unloaded) {
		if (texturegroup_load("DefaultNotes", true) >= 0) {
			global.default_notes_texture_loaded = true;
		};
	} else if (status == texturegroup_status_loaded) {
		texture_prefetch("DefaultNotes");
	};
	if (sprite_exists(note_hold_head)) then sprite_prefetch(note_hold_head);
	if (sprite_exists(note_hold_body)) then sprite_prefetch(note_hold_body);
	if (sprite_exists(note_hold_end)) then sprite_prefetch(note_hold_end);
}

function hold_default_notes_ready() {
	if (pls_is_html5()) then return true;
	return hold_sprite_frames_ready(note_hold_head)
		&& hold_sprite_frames_ready(note_hold_body)
		&& hold_sprite_frames_ready(note_hold_end);
}

function hold_strip_cache() {
	if (!variable_global_exists("__hold_strip_cache") || !is_struct(global.__hold_strip_cache)) {
		global.__hold_strip_cache = {};
	};
	return global.__hold_strip_cache;
}

function hold_strip_key(_head, _body, _tail) {
	return string(_head) + ":" + string(_body) + ":" + string(_tail);
}

function hold_strip_forget(_head, _body, _tail) {
	if (!variable_global_exists("__hold_strip_cache") || !is_struct(global.__hold_strip_cache)) then return;
	var _key = hold_strip_key(_head, _body, _tail);
	var _cache = global.__hold_strip_cache;
	if (!variable_struct_exists(_cache, _key)) then return;
	var _info = _cache[$ _key];
	if (is_struct(_info) && sprite_exists(_info.spr)) {
		try { sprite_delete(_info.spr); } catch (_e) { delete(_e); };
	};
	variable_struct_remove(_cache, _key);
}

function hold_strip_v(_uvs, _y, _h) {
	return lerp(_uvs[1], _uvs[3], clamp(_y / max(1, _h), 0, 1));
}

function hold_strip_emit_quad(_hx, _hy, _c, _s, _left, _right, _d0, _d1, _u0, _v0, _u1, _v1, _col, _alpha) {
	var _x00 = _hx + _left * _c - _d0 * _s;
	var _y00 = _hy - _left * _s - _d0 * _c;
	var _x10 = _hx + _right * _c - _d0 * _s;
	var _y10 = _hy - _right * _s - _d0 * _c;
	var _x01 = _hx + _left * _c - _d1 * _s;
	var _y01 = _hy - _left * _s - _d1 * _c;
	var _x11 = _hx + _right * _c - _d1 * _s;
	var _y11 = _hy - _right * _s - _d1 * _c;
	draw_vertex_texture_colour(_x00, _y00, _u0, _v0, _col, _alpha);
	draw_vertex_texture_colour(_x10, _y10, _u1, _v0, _col, _alpha);
	draw_vertex_texture_colour(_x01, _y01, _u0, _v1, _col, _alpha);
	draw_vertex_texture_colour(_x11, _y11, _u1, _v1, _col, _alpha);
}

/// @description Bake tail+body+head (all hl frames) into one strip so joins are interior texels.
function hold_strip_compose(_head, _body, _tail) {
	if (!sprite_exists(_head) || !sprite_exists(_body) || !sprite_exists(_tail)) then return undefined;
	if ((hold_sprite_is_default_note(_head) || hold_sprite_is_default_note(_body) || hold_sprite_is_default_note(_tail))
		&& !hold_default_notes_ready()) {
		hold_default_notes_prefetch();
		return undefined;
	};
	var _frames = min(sprite_get_number(_head), min(sprite_get_number(_body), sprite_get_number(_tail)));
	_frames = max(1, _frames);
	var _hw = sprite_get_width(_head);
	var _bw = sprite_get_width(_body);
	var _tw = sprite_get_width(_tail);
	var _h_top = sprite_get_bbox_top(_head);
	var _h_part = max(1, sprite_get_bbox_bottom(_head) - _h_top + 1);
	var _b_top = sprite_get_bbox_top(_body);
	var _b_part = max(1, sprite_get_bbox_bottom(_body) - _b_top + 1);
	var _t_top = sprite_get_bbox_top(_tail);
	var _t_part = max(1, sprite_get_bbox_bottom(_tail) - _t_top + 1);
	var _w = max(_hw, max(_bw, _tw));
	var _h = _t_part + _b_part + _h_part;
	if (_w < 1 || _h < 1) then return undefined;
	var _ox = _w * 0.5;
	var _oy = _t_part + _b_part + (sprite_get_yoffset(_head) - _h_top);
	var _surf = surface_create(_w, _h);
	if (!surface_exists(_surf)) then return undefined;
	var _spr = -1;
	// Baking must not inherit a note clip shader. Uniforms stay on that shader.
	var _prev_shader = shader_current();
	if (_prev_shader != -1) then shader_reset();
	skin_copy_surface_begin();
	for (var _f = 0; _f < _frames; _f++) {
		surface_set_target(_surf);
		draw_clear_alpha(c_black, 0);
		draw_sprite_part(_tail, _f, 0, _t_top, _tw, _t_part, _ox - sprite_get_xoffset(_tail), 0);
		draw_sprite_part(_body, _f, 0, _b_top, _bw, _b_part, _ox - sprite_get_xoffset(_body), _t_part);
		draw_sprite_part(_head, _f, 0, _h_top, _hw, _h_part, _ox - sprite_get_xoffset(_head), _t_part + _b_part);
		surface_reset_target();
		if (_f == 0) {
			_spr = sprite_create_from_surface(_surf, 0, 0, _w, _h, false, false, _ox, _oy);
			if (!asset_sprite_valid(_spr)) then break;
		} else {
			sprite_add_from_surface(_spr, _surf, 0, 0, _w, _h, false, false);
		};
	};
	skin_copy_surface_end();
	surface_free(_surf);
	if (_prev_shader != -1 && shader_is_compiled(_prev_shader)) then shader_set(_prev_shader);
	if (!asset_sprite_valid(_spr)) then return undefined;
	sprite_set_offset(_spr, _ox, _oy);
	return {
		spr: _spr,
		w: _w,
		h: _h,
		ox: _ox,
		oy: _oy,
		tail_h: _t_part,
		body_h: _b_part,
		head_h: _h_part,
		frames: _frames
	};
}

function hold_strip_get(_head, _body, _tail) {
	var _cache = hold_strip_cache();
	var _key = hold_strip_key(_head, _body, _tail);
	if (variable_struct_exists(_cache, _key)) {
		var _cached = _cache[$ _key];
		if (is_struct(_cached) && sprite_exists(_cached.spr)) then return _cached;
	};
	var _info = hold_strip_compose(_head, _body, _tail);
	if (is_struct(_info)) then _cache[$ _key] = _info;
	return _info;
}

function hold_strip_draw(_info, _x, _y, _xscale, _yscale, _body_len, _angle, _subimg, _colour, _alpha, _draw_head, _attach_head, _tail_trim) {
	if (!is_struct(_info) || !sprite_exists(_info.spr)) then return false;
	var _frame = clamp(real(_subimg), 0, max(0, sprite_get_number(_info.spr) - 1));
	var _tex = sprite_get_texture(_info.spr, _frame);
	var _uvs = sprite_get_uvs(_info.spr, _frame);
	if (!is_array(_uvs) || array_length(_uvs) < 4) then return false;
	var _c = dcos(_angle);
	var _s = dsin(_angle);
	var _left = -_info.ox * _xscale;
	var _right = (_info.w - _info.ox) * _xscale;
	var _u0 = _uvs[0];
	var _u1 = _uvs[2];
	var _y_tail0 = 0;
	var _y_body0 = _info.tail_h;
	var _y_head0 = _info.tail_h + _info.body_h;
	var _y_head1 = _info.h;
	var _d_join = (_info.oy - _y_head0) * _yscale;
	var _d_head_back = (_info.oy - _y_head1) * _yscale;
	var _d_body0 = _attach_head ? _d_join : 0;
	var _d_body1 = _d_body0 + max(0, real(_body_len)) - max(0, real(_tail_trim));
	if (_d_body1 < _d_body0) then _d_body1 = _d_body0;
	var _d_tail1 = _d_body1 + _info.tail_h * _yscale;
	var _v_head0 = hold_strip_v(_uvs, _y_head0, _info.h);
	var _v_head1 = hold_strip_v(_uvs, _y_head1, _info.h);
	var _v_body0 = hold_strip_v(_uvs, _y_body0, _info.h);
	var _v_body1 = hold_strip_v(_uvs, _y_head0, _info.h);
	var _v_tail0 = hold_strip_v(_uvs, _y_tail0, _info.h);
	var _v_tail1 = hold_strip_v(_uvs, _y_body0, _info.h);

	draw_primitive_begin_texture(pr_trianglestrip, _tex);
	hold_strip_emit_quad(_x, _y, _c, _s, _left, _right, _d_body0, _d_body1, _u0, _v_body1, _u1, _v_body0, _colour, _alpha);
	draw_primitive_end();
	draw_primitive_begin_texture(pr_trianglestrip, _tex);
	hold_strip_emit_quad(_x, _y, _c, _s, _left, _right, _d_body1, _d_tail1, _u0, _v_tail1, _u1, _v_tail0, _colour, _alpha);
	draw_primitive_end();
	if (_draw_head) {
		draw_primitive_begin_texture(pr_trianglestrip, _tex);
		hold_strip_emit_quad(_x, _y, _c, _s, _left, _right, _d_head_back, _d_join, _u0, _v_head1, _u1, _v_head0, _colour, _alpha);
		draw_primitive_end();
	};
	return true;
}

/// @function draw_hold_fit(x, y, scalex, scaley, hold_body_scale, angle, subimg, colour, alpha, draw_head, attach_head, tail_trim, head_attach_scale, head_spr, body_spr, end_spr)
/// @description Hold draw from one baked strip (default + custom skin, including hl frames).
function draw_hold_fit(x, y, scalex, scaley, hold_body_scale, angle = 0, subimg = 0,
		colour = c_white, alpha = 1, draw_head = true, attach_head = draw_head,
		tail_trim = 0, head_attach_scale = 1, head_spr = -1, body_spr = -1, end_spr = -1) {
	if (!sprite_exists(head_spr)) then head_spr = note_hold_head;
	if (!sprite_exists(body_spr)) then body_spr = note_hold_body;
	if (!sprite_exists(end_spr)) then end_spr = note_hold_end;

	var _xscale = real(scalex);
	var _yscale = abs(real(scaley));
	var _body_scale = max(0, real(hold_body_scale));
	var _alpha = clamp(real(alpha), 0, 1);
	if (_alpha <= 0 || _xscale == 0) then return;

	if ((hold_sprite_is_default_note(head_spr) || hold_sprite_is_default_note(body_spr) || hold_sprite_is_default_note(end_spr))
		&& !hold_default_notes_ready()) {
		hold_default_notes_prefetch();
		return;
	};

	var _body_len = _body_scale * max(1, sprite_get_height(body_spr));
	var _info = hold_strip_get(head_spr, body_spr, end_spr);
	if (hold_strip_draw(_info, x, y, _xscale, _yscale, _body_len, angle, subimg, colour, _alpha, draw_head, attach_head, tail_trim)) {
		return;
	};

	var _frame = sprite_exists(head_spr) ? clamp(real(subimg), 0, max(0, sprite_get_number(head_spr) - 1)) : 0;
	var _axis_x = -dsin(angle);
	var _axis_y = -dcos(angle);
	var _head_distance = 0;
	if (attach_head) {
		_head_distance = (sprite_get_yoffset(head_spr) - sprite_get_bbox_top(head_spr)) * _yscale;
	};
	var _body_from_bot = ((sprite_get_bbox_bottom(body_spr) + 1) - sprite_get_yoffset(body_spr)) * _body_scale;
	var _body_visual_h = ((sprite_get_bbox_bottom(body_spr) + 1) - sprite_get_bbox_top(body_spr)) * _body_scale;
	var _body_origin_distance = _head_distance + _body_from_bot;
	var _far_distance = _head_distance + _body_visual_h - max(0, real(tail_trim));
	var _tail_from_bot = ((sprite_get_bbox_bottom(end_spr) + 1) - sprite_get_yoffset(end_spr)) * _yscale;
	var _tail_origin_distance = _far_distance + _tail_from_bot;
	draw_sprite_ext(body_spr, _frame, x + _axis_x * _body_origin_distance, y + _axis_y * _body_origin_distance,
		_xscale, _body_scale, angle, colour, _alpha);
	draw_sprite_ext(end_spr, _frame, x + _axis_x * _tail_origin_distance, y + _axis_y * _tail_origin_distance,
		_xscale, _yscale, angle, colour, _alpha);
	if (draw_head) {
		draw_sprite_ext(head_spr, _frame, x, y, _xscale, _yscale, angle, colour, _alpha);
	};
}
