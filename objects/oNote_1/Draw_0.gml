/// @description Draw RPE note
if (!canDraw) then exit;

var _sprite = sprite_index;
var _frame = hl;
var _xscale = image_xscale;
var _yscale = image_yscale;
var _angle = image_angle;
var _blend = image_blend;
var _alpha = image_alpha;

if (skin_active()) {
	var _skin_kind = (type == 2 ? "drag" : (type == 4 ? "flick" : "tap"));
	var _skin_spr = skin_note_sprite(_skin_kind, isBad ? 0 : _frame);
	var _skin_hold = _is_hold ? skin_hold_parts(_frame) : undefined;
	var sk = sprite_exists(_skin_spr) ? skin_note_scale_k(_skin_spr) : 1;
	var hk = (is_struct(_skin_hold) && sprite_exists(_skin_hold.head)) ? skin_note_scale_k(_skin_hold.head) : 1;
	if (!_is_hold) {
		if (isBad) {
			var a = ((1 - (_now_seconds - judgeRealTime)) * 0.5);
			if (sprite_exists(_skin_spr)) then draw_sprite_ext(_skin_spr, 0, _bad_x, _bad_y, _xscale * sk, _yscale * sk, _bad_angle, c_red, a);
			else draw_sprite_ext(_sprite, 2, _bad_x, _bad_y, _xscale, _yscale, _bad_angle, c_red, a);
			exit;
		};
		if (sprite_exists(_skin_spr)) then draw_sprite_ext(_skin_spr, 0, x, y, _xscale * sk, _yscale * sk, _angle, _blend, _alpha);
		else draw_sprite_ext(_sprite, _frame, x, y, _xscale, _yscale, _angle, _blend, _alpha);
	} else {
		var a = (isMiss ? 0.5 : _alpha);
		var _use_compact = compactHold || (is_struct(_skin_hold) && bool(_skin_hold.compact));
		var _keep_head = is_struct(_skin_hold) && bool(_skin_hold.keep_head);
		var _tail_trim = (_use_compact ? _yscale * (_hold_tail_height * 0.5) : 0);
		if (is_struct(_skin_hold)) {
			draw_hold_fit(_hx0, _hy0, _xscale * hk, _yscale * hk, yscale,
				_angle, 0, _blend, a, _is_out || _keep_head, _is_out && !_use_compact, _tail_trim * hk, 1,
				_skin_hold.head, _skin_hold.body, _skin_hold.tail);
		} else {
			draw_hold_fit(_hx0, _hy0, _xscale, _yscale, yscale,
				_angle, _frame, _blend, a, _is_out, _is_out && !compactHold, _tail_trim);
		};
	};
	exit;
};

if (!_is_hold) {
	if (isBad) {
		var a = ((1 - (_now_seconds - judgeRealTime)) * 0.5);
		draw_sprite_ext(_sprite, 2, _bad_x, _bad_y, _xscale, _yscale, _bad_angle, c_red, a);
		exit;
	};
	draw_sprite_ext(_sprite, _frame, x, y, _xscale, _yscale, _angle, _blend, _alpha);
} else {
	var a = (isMiss ? 0.5 : _alpha);
	var _tail_trim = (compactHold ? _yscale * (_hold_tail_height * 0.5) : 0);
	draw_hold_fit(_hx0, _hy0, _xscale, _yscale, yscale,
		_angle, _frame, _blend, a, _is_out, _is_out && !compactHold, _tail_trim);
};
