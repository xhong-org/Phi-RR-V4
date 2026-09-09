/// @description Phigros().settings GUI. Normal list = comments without 已废弃/已弃用.

function settings_ini_path() {
	return $"{working_directory}resource/configs.ini";
}

function settings_comment_is_deprecated(_comment) {
	var s = string(_comment ?? "");
	return (string_pos("已废弃", s) > 0) || (string_pos("已弃用", s) > 0);
}

function settings_comment_label(_comment) {
	var s = string(_comment ?? "");
	s = string_replace_all(s, "(已弃用)", "");
	s = string_replace_all(s, "(已废弃)", "");
	var p = string_pos("(default:", s);
	if (p > 0) then s = string_copy(s, 1, p - 1);
	return string_trim(s);
}

/// Comments copied from Phigros.settings field comments. Deprecated = line contains 已废弃/已弃用.
function settings_catalog() {
	static cat = undefined;
	if (!is_undefined(cat)) then return cat;
	cat = [
		{ key:"enableBlur", comment:"是否启用背景模糊(default:true)" },
		{ key:"enableFPS", comment:"是否显示FPS(default:true)" },
		{ key:"enableQuikyStart", comment:"是否启用快速启动(已弃用)(default:true)" },
		{ key:"enableCanvasZoom", comment:"是否启用摄像头缩放(已弃用)(default:false)" },
		{ key:"enableSurface", comment:"是否启用遮罩(default:false)" },
		{ key:"enableNoteHightLight", comment:"是否启用音符多押高亮(default:true)" },
		{ key:"enableChartGUI", comment:"是否启用UI(default:true)" },
		{ key:"enableLineJudge", comment:"是否启用FC/AP指示器(default:true)" },
		{ key:"showBG", comment:"是否显示背景(default:true)" },
		{ key:"enableHitEffect", comment:"是否显示打击特效(default:true)" },
		{ key:"refreshFPSCount", comment:"刷新FPS计量次数(default:60)" },
		{ key:"enableDebug", comment:"是否启用Debug(default:true)" },
		{ key:"enableDisplayLineID", comment:"是否显示线ID(已弃用)(default:false)" },
		{ key:"comboString", comment:"combo text(default:\"COMBO\")" },
		{ key:"enableVsync", comment:"是否启用垂直同步(default:true)" },
		{ key:"aa_level", comment:"aa_level等级(default:0)" },
		{ key:"useOldFX", comment:"是否使用旧版打击特效(default:false)" },
		{ key:"enableComboScore", comment:"是否启用打击分(default:true)" },
		{ key:"judgeOffset", comment:"自动打击偏移延迟(default:0)" },
		{ key:"enableAccJudgment", comment:"是否启用Auto严肃判定(可能对其他格式的谱面无效)(default:true)" },
		{ key:"preventWindowMoveFreeze", comment:"use non-blocking Windows moving and resizing" },
		{ key:"enableRPEMulticore", comment:"enable native RPE frame workers" },
		{ key:"rpeWorkerMinLines", comment:"minimum line count for native parallel resolve" },
		{ key:"rpeWorkerProfileFrames", comment:"frames averaged between worker timing logs" },
		{ key:"noteUniformScale", comment:"RPE note size/sizeControl also scale height" },
		{ key:"notePreloadSeconds", comment:"note preload seconds (0-60)" },
		{ key:"TEST1", comment:"judge offset jitter test (default false)" }
	];
	return cat;
}

function settings_defaults() {
	static d = undefined;
	if (!is_undefined(d)) then return d;
	d = {
		enableBlur: true,
		enableFPS: true,
		enableQuikyStart: true,
		enableCanvasZoom: false,
		enableSurface: false,
		enableNoteHightLight: true,
		enableChartGUI: true,
		enableLineJudge: true,
		showBG: true,
		enableHitEffect: true,
		refreshFPSCount: 60,
		enableDebug: true,
		enableDisplayLineID: false,
		comboString: "COMBO",
		enableVsync: true,
		aa_level: 8,
		useOldFX: false,
		enableComboScore: true,
		judgeOffset: 0,
		enableAccJudgment: true,
		preventWindowMoveFreeze: true,
		enableRPEMulticore: true,
		rpeWorkerMinLines: 32,
		rpeWorkerProfileFrames: 1800,
		noteUniformScale: false,
		notePreloadSeconds: 15,
		TEST1: false
	};
	return d;
}

function settings_clone(_src) {
	var out = {};
	if (!is_struct(_src)) then return out;
	var names = struct_get_names(_src);
	for (var i = 0; i < array_length(names); i++) {
		out[$ names[i]] = _src[$ names[i]];
	};
	return out;
}

function settings_kind(_key) {
	var d = settings_defaults();
	if (!struct_exists(d, _key)) then return "number";
	var v = d[$ _key];
	if (is_string(v)) then return "string";
	if (is_bool(v)) then return "bool";
	return "number";
}

function settings_parse_value(_str, _default) {
	if (is_undefined(_str)) then return _default;
	var s = string_lower(string(_str));
	if (s == "false") then return 0;
	if (s == "true") then return 1;
	if (s == "undefined") then return _default;
	try { return real(_str); }
	catch (e) { delete(e); return _default; };
}

function settings_format_ini(_key, _value) {
	if (settings_kind(_key) == "bool") then return (bool(_value) ? "true" : "false");
	if (is_string(_value)) then return _value;
	return string(_value);
}

function settings_clamp_store(_store) {
	if (!is_struct(_store)) then return;
	if (struct_exists(_store, "refreshFPSCount")) then _store.refreshFPSCount = clamp(real(_store.refreshFPSCount), 1, 300);
	if (struct_exists(_store, "notePreloadSeconds")) then _store.notePreloadSeconds = clamp(real(_store.notePreloadSeconds), 0, 60);
	if (struct_exists(_store, "rpeWorkerMinLines")) then _store.rpeWorkerMinLines = clamp(floor(real(_store.rpeWorkerMinLines)), 1, 1024);
	if (struct_exists(_store, "rpeWorkerProfileFrames")) then _store.rpeWorkerProfileFrames = clamp(floor(real(_store.rpeWorkerProfileFrames)), 60, 36000);
	if (struct_exists(_store, "aa_level")) then _store.aa_level = clamp(floor(real(_store.aa_level)), 0, 8);
	if (struct_exists(_store, "judgeOffset")) then _store.judgeOffset = clamp(real(_store.judgeOffset), -5000, 5000);
}

function settings_load_into(_store) {
	if (!is_struct(_store)) then return;
	var f = settings_ini_path();
	ini_open(f);
	var names = struct_get_names(_store);
	for (var i = 0; i < array_length(names); i++) {
		var key = names[i];
		var cur = _store[$ key];
		if (settings_kind(key) == "string") {
			_store[$ key] = ini_read_string("Settings", key, string(cur ?? ""));
		} else {
			_store[$ key] = settings_parse_value(ini_read_string("Settings", key, string(cur)), cur);
		};
	};
	ini_close();
	settings_clamp_store(_store);
}

function settings_save_store(_store) {
	if (!is_struct(_store)) then return;
	settings_clamp_store(_store);
	ini_open(settings_ini_path());
	var names = struct_get_names(_store);
	for (var i = 0; i < array_length(names); i++) {
		var key = names[i];
		ini_write_string("Settings", key, settings_format_ini(key, _store[$ key]));
	};
	ini_write_string("Settings", "language", lang_current_id());
	ini_close();
}

function settings_store() {
	if (variable_global_exists("game") && is_struct(game) && is_struct(game.settings)) {
		return game.settings;
	};
	if (!variable_global_exists("pls_settings") || !is_struct(global.pls_settings)) {
		global.pls_settings = settings_clone(settings_defaults());
		settings_load_into(global.pls_settings);
	};
	return global.pls_settings;
}

function settings_apply_live(_key) {
	var s = settings_store();
	if (_key == "aa_level" || _key == "enableVsync" || is_undefined(_key)) {
		display_custom(real(s.aa_level ?? 8), bool(s.enableVsync ?? true));
	};
}

function settings_set(_key, _value) {
	var s = settings_store();
	if (settings_kind(_key) == "bool") then _value = bool(_value);
	s[$ _key] = _value;
	settings_clamp_store(s);
	settings_save_store(s);
	settings_apply_live(_key);
}

function settings_clear_data() {
	var f = settings_ini_path();
	try {
		if (file_exists(f)) then file_delete(f);
		else if (chart_use_native_files() && chart_native_exists(f)) then chart_native_delete(f);
	} catch (del_err) { delete(del_err); };
	var fresh = settings_clone(settings_defaults());
	if (variable_global_exists("game") && is_struct(game) && is_struct(game.settings)) {
		var names = struct_get_names(fresh);
		for (var i = 0; i < array_length(names); i++) {
			game.settings[$ names[i]] = fresh[$ names[i]];
		};
	};
	global.pls_settings = settings_clone(fresh);
	settings_save_store(settings_store());
	settings_apply_live(undefined);
}

function settings_reset_defaults() {
	var fresh = settings_clone(settings_defaults());
	if (variable_global_exists("game") && is_struct(game) && is_struct(game.settings)) {
		var names = struct_get_names(fresh);
		for (var i = 0; i < array_length(names); i++) {
			game.settings[$ names[i]] = fresh[$ names[i]];
		};
	};
	global.pls_settings = settings_clone(fresh);
	settings_save_store(settings_store());
	settings_apply_live(undefined);
}

function settings_confirm_reset() {
	var buttons = [
		msgbox_button("Yes", settings_reset_defaults),
		msgbox_button("No")
	];
	msgbox_warning_async("Do you want to reset settings?", "Warning", buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
}

function settings_list(_deprecated) {
	static lists = undefined;
	if (!is_array(lists)) {
		lists = [[], []];
		var cat = settings_catalog();
		var seen = {};
		for (var i = 0; i < array_length(cat); i++) {
			var item = cat[i];
			seen[$ item.key] = true;
			array_push(lists[settings_comment_is_deprecated(item.comment) ? 1 : 0], item);
		};
		var store = settings_store();
		var names = struct_get_names(store);
		for (var n = 0; n < array_length(names); n++) {
			if (struct_exists(seen, names[n])) then continue;
			if (names[n] == "language" || names[n] == "skinId") then continue;
			array_push(lists[0], { key:names[n], comment:names[n] });
		};
	};
	return lists[_deprecated ? 1 : 0];
}

function settings_field_label(_key, _comment) {
	lang_ensure();
	if (!is_struct(global.pls_lang.field_labels)) then global.pls_lang.field_labels = {};
	if (struct_exists(global.pls_lang.field_labels, _key)) then return global.pls_lang.field_labels[$ _key];
	var label = lang("fields." + string(_key), settings_comment_label(_comment));
	if (!string_length(label)) then label = string(_key);
	global.pls_lang.field_labels[$ _key] = label;
	return label;
}

function menu_draw_button(_btn, _hot, _text_scale) {
	if (!is_struct(_btn)) then return;
	draw_set_colour(_hot ? make_colour_rgb(70, 110, 180) : make_colour_rgb(40, 48, 64));
	draw_rectangle(_btn.x, _btn.y, _btn.x + _btn.w, _btn.y + _btn.h, false);
	draw_set_colour(c_white);
	draw_rectangle(_btn.x, _btn.y, _btn.x + _btn.w, _btn.y + _btn.h, true);
	draw_text_transformed(_btn.x + _btn.w * 0.5, _btn.y + _btn.h * 0.5, _btn.label, _text_scale, _text_scale, 0);
}

function settings_skin_preview_surface(_w, _h) {
	_w = max(1, floor(_w));
	_h = max(1, floor(_h));
	if (!variable_instance_exists(id, "skin_preview_surf") || !surface_exists(skin_preview_surf)
		|| surface_get_width(skin_preview_surf) != _w || surface_get_height(skin_preview_surf) != _h) {
		if (variable_instance_exists(id, "skin_preview_surf") && surface_exists(skin_preview_surf)) {
			surface_free(skin_preview_surf);
		};
		skin_preview_surf = surface_create(_w, _h);
	};
	return skin_preview_surf;
}

function settings_skin_preview_surface_free() {
	if (variable_instance_exists(id, "skin_preview_surf") && surface_exists(skin_preview_surf)) {
		surface_free(skin_preview_surf);
		skin_preview_surf = -1;
	};
}

function settings_gui_draw_skins(_s, _body, _small, _fill_idle, _fill_hot, _fill_on) {
	var items = skin_menu_items();
	var selected = skin_selected_id();
	var vis = max(1, floor(skin_list_h / row_h));
	var last = min(array_length(items), scroll + vis);
	draw_set_colour(make_colour_rgb(18, 24, 38));
	draw_rectangle(list_x, list_y, list_x + skin_list_w, list_y + skin_list_h, false);
	draw_set_colour(make_colour_rgb(70, 80, 96));
	draw_rectangle(list_x, list_y, list_x + skin_list_w, list_y + skin_list_h, true);
	for (var i = scroll; i < last; i++) {
		var item = items[i];
		if (!is_struct(item)) then continue;
		var row_y = list_y + (i - scroll) * row_h;
		var on = (string(item.skin_id ?? "") == selected);
		if (on) {
			draw_set_colour(make_colour_rgb(70, 110, 180));
			draw_rectangle(list_x + 2, row_y, list_x + skin_list_w - 2, row_y + row_h, false);
		} else if ((i - scroll) mod 2 == 1) {
			draw_set_colour(make_colour_rgb(20, 26, 40));
			draw_rectangle(list_x + 2, row_y, list_x + skin_list_w - 2, row_y + row_h, false);
		};
		draw_set_halign(fa_left);
		draw_set_valign(fa_middle);
		draw_set_colour(c_white);
		draw_text_transformed(list_x + 10 * _s, row_y + row_h * 0.38, string(item.name ?? ""), _body, _body, 0);
		draw_set_colour(make_colour_rgb(150, 160, 180));
		draw_text_transformed(list_x + 10 * _s, row_y + row_h * 0.72, string(item.author ?? ""), _small, _small, 0);
	};
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_colour(hover_skin_add ? _fill_hot : _fill_idle);
	draw_rectangle(skin_add.x, skin_add.y, skin_add.x + skin_add.w, skin_add.y + skin_add.h, false);
	draw_set_colour(c_white);
	draw_rectangle(skin_add.x, skin_add.y, skin_add.x + skin_add.w, skin_add.y + skin_add.h, true);
	draw_text_transformed(skin_add.x + skin_add.w * 0.5, skin_add.y + skin_add.h * 0.5, lang("skin.add", "Add skin"), _body, _body, 0);

	var pack = skin_preview_runtime();
	if (is_struct(pack)) then skin_pack_gpu_ensure(pack, true);
	var title = lang("skin.default", "Default");
	var author = "";
	var desc = "";
	for (var n = 0; n < array_length(items); n++) {
		if (string(items[n].skin_id ?? "") == selected) {
			title = string(items[n].name ?? title);
			author = string(items[n].author ?? "");
			desc = string(items[n].description ?? "");
			break;
		};
	};

	var inset = 2;
	var clip_w = max(1, floor(skin_preview_w - inset * 2));
	var clip_h = max(1, floor(list_h - inset * 2));
	var surf = settings_skin_preview_surface(clip_w, clip_h);
	var used_surf = surface_exists(surf);
	if (used_surf) {
		surface_set_target(surf);
		draw_clear_alpha(make_colour_rgb(18, 24, 38), 1);
	} else {
		draw_set_colour(make_colour_rgb(18, 24, 38));
		draw_rectangle(skin_preview_x, list_y, skin_preview_x + skin_preview_w, list_y + list_h, false);
	};
	var ox = used_surf ? 0 : (skin_preview_x + inset);
	var oy = used_surf ? 0 : (list_y + inset);

	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_colour(c_white);
	draw_text_transformed(ox + 12 * _s, oy + 10 * _s, title, _body + 0.06 * _s, _body + 0.06 * _s, 0);
	draw_set_colour(make_colour_rgb(150, 160, 180));
	if (string_length(author)) then draw_text_transformed(ox + 12 * _s, oy + 36 * _s, author, _small, _small, 0);
	var desc_w = max(40, clip_w - 24 * _s);
	var desc_sep = max(24, ceil(string_height("A") * 1.5));
	var desc_h = 0;
	if (string_length(desc)) {
		desc_h = string_height_ext(desc, desc_sep, desc_w) * _small;
		draw_text_ext_transformed(ox + 12 * _s, oy + 54 * _s, desc, desc_sep, desc_w, _small, _small, 0);
	};

	var inner_pad = 10 * _s;
	var inner_w = max(40, clip_w - inner_pad * 2);
	var title_h = 34 * _s;
	if (string_length(author)) then title_h = 50 * _s;
	if (string_length(desc)) then title_h = max(title_h, 54 * _s + desc_h + 10 * _s);
	var delete_h = (selected != SKIN_DEFAULT_ID) ? 48 * _s : 8 * _s;
	var fx_min = 96 * _s;
	var note_want = 180 * _s;
	var note_box = min(note_want, inner_w / 4 * 0.9, max(48 * _s, clip_h - title_h - fx_min - delete_h));
	var gap = inner_w / 4;
	var cx = ox + inner_pad + gap * 0.5;
	var note_disp_h = function(_spr, _box) {
		if (!sprite_exists(_spr)) then return 0;
		var nw = sprite_get_width(_spr);
		var nh = sprite_get_height(_spr);
		var k = real(_box) / max(1, max(nw, nh));
		var bh = sprite_get_bbox_bottom(_spr) - sprite_get_bbox_top(_spr) + 1;
		if (bh < 1) then bh = nh;
		return bh * k;
	};
	var note_row_h = 1;
	if (is_struct(pack) && is_real(pack.preview_row_ratio) && pack.preview_row_ratio > 0) {
		note_row_h = pack.preview_row_ratio * note_box;
	} else if (is_struct(pack)) {
		note_row_h = max(note_disp_h(pack.click, note_box), max(note_disp_h(pack.click_mh, note_box),
			max(note_disp_h(pack.drag, note_box), max(note_disp_h(pack.drag_mh, note_box),
			max(note_disp_h(pack.flick, note_box), max(note_disp_h(pack.flick_mh, note_box),
			max(note_disp_h(pack.hold_head, note_box), note_disp_h(pack.hold_head_mh, note_box))))))));
	} else {
		note_row_h = max(note_disp_h(note_tap, note_box), max(note_disp_h(note_drag, note_box),
			max(note_disp_h(note_flick, note_box), note_disp_h(note_hold_head, note_box))));
	};
	if (note_row_h < 1) then note_row_h = max(8 * _s, note_box * 0.2);
	var hold_head_spr = note_hold_head;
	var hold_tail_spr = note_hold_end;
	if (is_struct(pack) && sprite_exists(pack.hold_head)) then hold_head_spr = pack.hold_head;
	if (is_struct(pack) && sprite_exists(pack.hold_tail)) then hold_tail_spr = pack.hold_tail;
	var hk = real(note_box) / max(1, max(sprite_get_width(hold_head_spr), sprite_get_height(hold_head_spr)));
	var hold_attach = sprite_get_yoffset(hold_head_spr) * 1.35 * hk * 0.25;
	var tail_off = sprite_get_yoffset(hold_tail_spr);
	var tail_hgt = sprite_get_height(hold_tail_spr);
	var hold_tail_up = (tail_off > tail_hgt * 0.1) ? (tail_off * hk) : 0;
	var hold_want = min(16 * _s, max(8 * _s, note_row_h * 0.35));
	var hold_up = hold_attach + hold_want + hold_tail_up;
	var preview_y = oy + title_h + max(note_row_h * 0.5, hold_up) + 2 * _s;
	var note_row = note_row_h + 4 * _s;
	var hold_body_px = hold_want;
	var draw_one = function(_spr, _x, _y, _k, _frame) {
		if (!sprite_exists(_spr)) then return;
		var k = real(_k);
		var frame = clamp(real(_frame), 0, max(0, sprite_get_number(_spr) - 1));
		var content_cy = (sprite_get_bbox_top(_spr) + sprite_get_bbox_bottom(_spr)) * 0.5;
		var dy = (sprite_get_yoffset(_spr) - content_cy) * k;
		draw_sprite_ext(_spr, frame, _x, _y + dy, k, k, 0, c_white, 1);
	};
	var fit_k = function(_spr, _box) {
		if (!sprite_exists(_spr)) then return 1;
		return real(_box) / max(1, max(sprite_get_width(_spr), sprite_get_height(_spr)));
	};
	var draw_hold_preview = function(_hx, _hy, _head, _body, _tail, _k, _body_scale, _frame) {
		if (!sprite_exists(_head)) then _head = note_hold_head;
		if (!sprite_exists(_body)) then _body = note_hold_body;
		if (!sprite_exists(_tail)) then _tail = note_hold_end;
		draw_hold(_hx, _hy, _k, _k, _body_scale, 0, _frame, c_white, 1, true, true, 0, 0.25, _head, _body, _tail);
	};
	if (is_struct(pack)) {
		var k_click = fit_k(sprite_exists(pack.click_mh) ? pack.click_mh : pack.click, note_box);
		var k_drag = fit_k(sprite_exists(pack.drag_mh) ? pack.drag_mh : pack.drag, note_box);
		var k_flick = fit_k(sprite_exists(pack.flick_mh) ? pack.flick_mh : pack.flick, note_box);
		var k_hold = fit_k(sprite_exists(pack.hold_head_mh) ? pack.hold_head_mh : pack.hold_head, note_box);
		var hold_body_ref = sprite_exists(pack.hold_body_mh) ? pack.hold_body_mh : pack.hold_body;
		var body_scale = real(hold_body_px) / max(1, sprite_get_height(hold_body_ref));
		draw_one(pack.click, cx, preview_y, k_click, 0);
		draw_one(pack.click_mh, cx, preview_y + note_row, k_click, 0);
		draw_one(pack.drag, cx + gap, preview_y, k_drag, 0);
		draw_one(pack.drag_mh, cx + gap, preview_y + note_row, k_drag, 0);
		draw_one(pack.flick, cx + gap * 2, preview_y, k_flick, 0);
		draw_one(pack.flick_mh, cx + gap * 2, preview_y + note_row, k_flick, 0);
		draw_hold_preview(cx + gap * 3, preview_y, pack.hold_head, pack.hold_body, pack.hold_tail, k_hold, body_scale, 0);
		draw_hold_preview(cx + gap * 3, preview_y + note_row, pack.hold_head_mh, pack.hold_body_mh, pack.hold_tail_mh, k_hold, body_scale, 0);
	} else {
		var k_tap = fit_k(note_tap, note_box);
		var k_drag_d = fit_k(note_drag, note_box);
		var k_flick_d = fit_k(note_flick, note_box);
		var k_hold_d = fit_k(note_hold_head, note_box);
		var body_scale_d = real(hold_body_px) / max(1, sprite_get_height(note_hold_body));
		draw_one(note_tap, cx, preview_y, k_tap, 0);
		draw_one(note_tap, cx, preview_y + note_row, k_tap, 1);
		draw_one(note_drag, cx + gap, preview_y, k_drag_d, 0);
		draw_one(note_drag, cx + gap, preview_y + note_row, k_drag_d, 1);
		draw_one(note_flick, cx + gap * 2, preview_y, k_flick_d, 0);
		draw_one(note_flick, cx + gap * 2, preview_y + note_row, k_flick_d, 1);
		draw_hold_preview(cx + gap * 3, preview_y, note_hold_head, note_hold_body, note_hold_end, k_hold_d, body_scale_d, 0);
		draw_hold_preview(cx + gap * 3, preview_y + note_row, note_hold_head, note_hold_body, note_hold_end, k_hold_d, body_scale_d, 1);
	};

	var cycle = skin_preview_cycle();
	var kind_i = cycle.kind;
	var demo_box = note_box;
	var demo_x = ox + clip_w * 0.5;
	var demo_y = oy + clip_h * 0.75;
	var demo_spr = note_tap;
	var demo_frame = 0;
	if (is_struct(pack)) {
		if (kind_i == 1) then demo_spr = pack.drag;
		else if (kind_i == 2) then demo_spr = pack.flick;
		else demo_spr = pack.click;
	} else {
		if (kind_i == 1) then demo_spr = note_drag;
		else if (kind_i == 2) then demo_spr = note_flick;
		else demo_spr = note_tap;
	};
	if (cycle.showing) then draw_one(demo_spr, demo_x, demo_y, fit_k(demo_spr, demo_box), demo_frame);
	var fx_age = cycle.fx_age;
	if (fx_age >= 0) {
		var fx_col = #ffeca0;
		if (is_struct(pack)) then fx_col = skin_hitfx_color(pack, #ffeca0);
		var hide_particles = is_struct(pack) && bool(pack.info.hideParticles);
		var note_disp_w = skin_preview_note_disp_w(demo_spr, demo_box);
		var part_gs = note_disp_w / 280;
		skin_draw_preview_hitfx(is_struct(pack) ? pack : undefined, demo_x, demo_y, fx_age, fx_col, note_disp_w);
		if (!hide_particles) {
			skin_draw_preview_particles(demo_x, demo_y, fx_age, fx_col, part_gs, skin_fx_rot, skin_fx_scales, skin_fx_rx, skin_fx_ry);
		};
	};

	if (selected != SKIN_DEFAULT_ID) {
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		var del_x = (used_surf ? 0 : (skin_preview_x + inset)) + (skin_delete.x - skin_preview_x - inset);
		var del_y = (used_surf ? 0 : (list_y + inset)) + (skin_delete.y - list_y - inset);
		draw_set_colour(hover_skin_delete ? make_colour_rgb(140, 60, 60) : make_colour_rgb(96, 48, 48));
		draw_rectangle(del_x, del_y, del_x + skin_delete.w, del_y + skin_delete.h, false);
		draw_set_colour(c_white);
		draw_rectangle(del_x, del_y, del_x + skin_delete.w, del_y + skin_delete.h, true);
		draw_text_transformed(del_x + skin_delete.w * 0.5, del_y + skin_delete.h * 0.5, lang("skin.delete", "Delete"), _body, _body, 0);
	};

	if (used_surf) {
		surface_reset_target();
		draw_surface(surf, skin_preview_x + inset, list_y + inset);
	};
	draw_set_colour(make_colour_rgb(70, 80, 96));
	draw_rectangle(skin_preview_x, list_y, skin_preview_x + skin_preview_w, list_y + list_h, true);
}

function settings_gui_draw_tab(_box, _hot, _on, _label, _scale, _fill_on, _fill_idle) {
	if (!is_struct(_box)) then return;
	draw_set_colour(_on ? _fill_on : (_hot ? make_colour_rgb(52, 64, 88) : _fill_idle));
	draw_rectangle(_box.x, _box.y, _box.x + _box.w, _box.y + _box.h, false);
	draw_set_colour(c_white);
	draw_rectangle(_box.x, _box.y, _box.x + _box.w, _box.y + _box.h, true);
	draw_text_transformed(_box.x + _box.w * 0.5, _box.y + _box.h * 0.5, _label, _scale, _scale, 0);
}

function settings_gui_blocking() {
	return instance_exists(oSettings);
}

function settings_gui_open() {
	if (instance_exists(oSettings) || instance_exists(oFilePicker)) then return;
	instance_create_depth(0, 0, -2000000, oSettings);
}

function settings_gui_close() {
	skin_import_cancel();
	skin_preview_unload();
	if (instance_exists(oSettings)) then with (oSettings) {
		settings_skin_preview_surface_free();
		instance_destroy();
	};
}

function settings_developer_warning_text() {
	return "You have entered developer settings. Changing these options may prevent the simulator from starting. If it cannot start, delete resource/config.ini. On other platforms, tap Clear data to reset.";
}

function settings_warn_developer() {
	if (variable_instance_exists(id, "developer_warned") && developer_warned) then return;
	developer_warned = true;
	var msg = settings_developer_warning_text();
	var buttons = [msgbox_button("OK")];
	if (i_wbox_native_ready()) {
		msgbox_warning_sync(msg, "Warning", buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
	} else {
		msgbox_warning_async(msg, "Warning", buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
	};
}

function settings_menu_button_layout() {
	var s = variable_global_exists("global_scales") ? global_scales : 1.0;
	if (!is_real(s) || s <= 0) then s = 1.0;
	var rw = max(1, room_width);
	var pad = max(12, 20 * s);
	if (!variable_instance_exists(id, "btn_settings") || !is_struct(btn_settings)) {
		btn_settings = { label:lang("common.settings"), x:0, y:0, w:1, h:1 };
	};
	btn_settings.label = lang("common.settings");
	btn_settings.w = max(110, 140 * s);
	btn_settings.h = max(36, 44 * s);
	btn_settings.x = rw - btn_settings.w - pad;
	btn_settings.y = pad;
}

function settings_menu_button_hit(_mx, _my) {
	if (!variable_instance_exists(id, "btn_settings") || !is_struct(btn_settings)) then return false;
	return point_in_rectangle(_mx, _my, btn_settings.x, btn_settings.y, btn_settings.x + btn_settings.w, btn_settings.y + btn_settings.h);
}

function settings_menu_button_draw(_hover, _s) {
	if (!variable_instance_exists(id, "btn_settings") || !is_struct(btn_settings)) then return;
	var b = btn_settings;
	var scale = (is_real(_s) && _s > 0) ? _s : 1.0;
	var old_halign = draw_get_halign();
	var old_valign = draw_get_valign();
	var old_colour = draw_get_colour();
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_colour(_hover ? make_colour_rgb(70, 110, 180) : make_colour_rgb(40, 48, 64));
	draw_rectangle(b.x, b.y, b.x + b.w, b.y + b.h, false);
	draw_set_colour(c_white);
	draw_rectangle(b.x, b.y, b.x + b.w, b.y + b.h, true);
	draw_text_transformed(b.x + b.w * 0.5, b.y + b.h * 0.5, b.label, 0.48 * scale, 0.48 * scale, 0);
	draw_set_halign(old_halign);
	draw_set_valign(old_valign);
	draw_set_colour(old_colour);
}

function settings_aa_cycle(_current, _dir) {
	var vals = [0, 2, 4, 8];
	var idx = 0;
	var best = 999;
	for (var i = 0; i < array_length(vals); i++) {
		var d = abs(vals[i] - _current);
		if (d < best) { best = d; idx = i; };
	};
	idx = clamp(idx + _dir, 0, array_length(vals) - 1);
	return vals[idx];
}

function settings_number_step(_key) {
	switch (_key) {
		case "rpeWorkerProfileFrames": return 60;
		case "refreshFPSCount": return 5;
		default: return 1;
	};
}

function settings_gui_commit_edit() {
	if (!is_string(editing_key) || !string_length(editing_key)) then return;
	var key = editing_key;
	var text = string(keyboard_string);
	editing_key = "";
	if (os_type == os_android) {
		try { keyboard_virtual_hide(); } catch (hide_err) { delete(hide_err); };
	};
	if (settings_kind(key) == "string") {
		settings_set(key, text);
	} else {
		var parsed = settings_parse_value(text, settings_store()[$ key]);
		settings_set(key, parsed);
	};
}

function settings_gui_begin_edit(_key) {
	settings_gui_commit_edit();
	editing_key = _key;
	keyboard_string = string(settings_store()[$ _key] ?? "");
	if (os_type == os_android) {
		try { keyboard_virtual_show(0, 0, 0, false); }
		catch (show_err) { delete(show_err); };
	};
}

function settings_gui_layout() {
	var s = variable_global_exists("global_scales") ? global_scales : 1.0;
	if (!is_real(s) || s <= 0) then s = 1.0;
	layout_s = s;
	var rw = max(1, room_width);
	var rh = max(1, room_height);
	panel_w = min(rw - 40 * s, 980 * s);
	panel_h = min(rh - 36 * s, 680 * s);
	panel_x = (rw - panel_w) * 0.5;
	panel_y = (rh - panel_h) * 0.5;
	var pad = 18 * s;
	tab_h = 46 * s;
	tab_y = panel_y + 58 * s;
	tab_w = (panel_w - pad * 5) / 4;
	tab_normal = { x:panel_x + pad, y:tab_y, w:tab_w, h:tab_h };
	tab_dev = { x:panel_x + pad * 2 + tab_w, y:tab_y, w:tab_w, h:tab_h };
	tab_lang = { x:panel_x + pad * 3 + tab_w * 2, y:tab_y, w:tab_w, h:tab_h };
	tab_skin = { x:panel_x + pad * 4 + tab_w * 3, y:tab_y, w:tab_w, h:tab_h };
	close_w = 90 * s;
	close_h = 36 * s;
	close_x = panel_x + panel_w - pad - close_w;
	close_y = panel_y + 12 * s;
	settings_gui_action_layout();
	footer_h = 52 * s;
	list_x = panel_x + pad;
	list_w = panel_w - pad * 2;
	list_y = tab_y + tab_h + 12 * s;
	list_h = panel_h - (list_y - panel_y) - footer_h - pad;
	row_h = max(48, 58 * s);
	visible_rows = max(1, floor(list_h / row_h));
	clear_w = 160 * s;
	clear_h = 40 * s;
	clear_x = panel_x + pad;
	clear_y = panel_y + panel_h - pad - clear_h;
	show_clear = (os_type != os_windows);
	layout_w = rw;
	layout_h = rh;
	skin_list_w = min(300 * s, list_w * 0.38);
	skin_add_h = 44 * s;
	skin_list_h = max(80 * s, list_h - skin_add_h - 8 * s);
	skin_add = { x:list_x, y:list_y + skin_list_h + 8 * s, w:skin_list_w, h:skin_add_h };
	skin_preview_x = list_x + skin_list_w + 14 * s;
	skin_preview_w = list_w - skin_list_w - 14 * s;
	skin_delete = { x:skin_preview_x + skin_preview_w - 140 * s, y:list_y + list_h - 40 * s, w:140 * s, h:40 * s };
}

function settings_gui_action_kind() {
	if (!variable_instance_exists(id, "tab")) then return "";
	if (tab == 0 || tab == 1) then return "reset";
	if (tab == 2) then return "reload";
	return "";
}

function settings_gui_action_label() {
	var kind = settings_gui_action_kind();
	if (kind == "reset") then return lang("settings.reset");
	if (kind == "reload") then return lang("settings.reloadLanguage");
	return "";
}

function settings_gui_action_layout() {
	var s = layout_s;
	if (!is_real(s) || s <= 0) then s = 1.0;
	var kind = settings_gui_action_kind();
	show_action = (kind != "");
	action_h = close_h;
	action_y = close_y;
	if (!show_action) {
		action_w = 0;
		action_x = close_x;
		return;
	};
	var label = settings_gui_action_label();
	var text_scale = 0.4 * s;
	var text_w = 0;
	if (string_length(label)) {
		if (variable_instance_exists(id, "ui_font") && font_exists(ui_font)) {
			var old_font = draw_get_font();
			draw_set_font(ui_font);
			text_w = string_width(label) * text_scale;
			draw_set_font(old_font);
		} else {
			text_w = string_length(label) * 8 * s;
		};
	};
	action_w = max(close_w, ceil(text_w + 24 * s));
	action_x = close_x - 8 * s - action_w;
}

function settings_gui_rows() {
	return settings_list(tab == 1);
}

function settings_gui_hit(_box, _mx, _my) {
	if (!is_struct(_box)) then return false;
	return point_in_rectangle(_mx, _my, _box.x, _box.y, _box.x + _box.w, _box.y + _box.h);
}

function settings_gui_init() {
	depth = -2000000;
	tab = 0;
	developer_warned = false;
	scroll = 0;
	armed = false;
	dragging = false;
	drag_moved = false;
	drag_start_y = 0;
	drag_start_scroll = 0;
	editing_key = "";
	hover_close = false;
	hover_action = false;
	show_action = false;
	action_x = 0;
	action_y = 0;
	action_w = 0;
	action_h = 0;
	hover_tab_normal = false;
	hover_tab_dev = false;
	hover_tab_lang = false;
	hover_tab_skin = false;
	hover_clear = false;
	hover_skin_add = false;
	hover_skin_delete = false;
	skin_picking = false;
	skin_import_path = "";
	skin_zip_task = -1;
	skin_zip_dest = "";
	skin_zip_folder = "";
	skin_zip_copy = "";
	skin_fx_cycle_t0 = -1;
	skin_fx_last_hit = -1;
	skin_hitsounds_ensure_default();
	skin_fx_rot = [];
	skin_fx_scales = [];
	skin_fx_rx = 280;
	skin_fx_ry = 280;
	skin_hits = [];
	row_hits = [];
	lang_hits = [];
	hits_tab = -1;
	hits_scroll = -1;
	hits_visible = -1;
	hits_w = -1;
	hits_h = -1;
	hits_s = -1;
	ui_font = pls_ui_font_add(24);
	settings_store();
	settings_gui_layout();
}

function settings_gui_step() {
	var scale_now = variable_global_exists("global_scales") ? global_scales : 1.0;
	if (layout_w != room_width || layout_h != room_height || layout_s != scale_now) {
		settings_gui_layout();
	};
	if (!armed && !mouse_check_button(mb_left)) then armed = true;
	if (instance_exists(oFilePicker)) then exit;
	skin_import_poll();
	if (is_string(skin_import_path ?? "") && string_length(skin_import_path)) {
		var queued_zip = skin_import_path;
		skin_import_path = "";
		skin_log($"settings step import {queued_zip}");
		skin_import_zip(queued_zip);
		exit;
	};
	if (bool(skin_picking ?? false) && os_type == os_android && extension_exists("I_AndroidOpen")) {
		var pick_status = i_android_open_status();
		if (pick_status == ANDROID_OPEN_STATUS.OK) {
			skin_picking = false;
			var path = i_android_open_path();
			i_android_open_reset();
			if (string_length(path)) then skin_import_queue(path);
			exit;
		} else if (pick_status == ANDROID_OPEN_STATUS.CANCELLED || pick_status == ANDROID_OPEN_STATUS.ERROR) {
			skin_picking = false;
			i_android_open_reset();
			if (pick_status == ANDROID_OPEN_STATUS.ERROR) then skin_error(lang("menu.openFailed", "Open failed."));
			exit;
		};
		exit;
	};

	var rows = settings_gui_rows();
	var lang_rows = lang_packs();
	var skin_rows = skin_menu_items();
	var list_count = array_length(rows);
	if (tab == 2) then list_count = array_length(lang_rows);
	else if (tab == 3) then list_count = array_length(skin_rows);
	var skin_visible = max(1, floor(skin_list_h / row_h));
	var max_scroll = max(0, list_count - ((tab == 3) ? skin_visible : visible_rows));
	scroll = clamp(scroll, 0, max_scroll);

	if (is_string(editing_key) && string_length(editing_key)) {
		if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_escape)) {
			if (keyboard_check_pressed(vk_escape)) then keyboard_string = string(settings_store()[$ editing_key] ?? "");
			settings_gui_commit_edit();
			exit;
		};
	} else if (keyboard_check_pressed(vk_escape)) {
		settings_gui_close();
		exit;
	};

	var mx = mouse_x;
	var my = mouse_y;
	settings_gui_action_layout();
	hover_close = point_in_rectangle(mx, my, close_x, close_y, close_x + close_w, close_y + close_h);
	hover_action = show_action && point_in_rectangle(mx, my, action_x, action_y, action_x + action_w, action_y + action_h);
	hover_tab_normal = settings_gui_hit(tab_normal, mx, my);
	hover_tab_dev = settings_gui_hit(tab_dev, mx, my);
	hover_tab_lang = settings_gui_hit(tab_lang, mx, my);
	hover_tab_skin = settings_gui_hit(tab_skin, mx, my);
	hover_skin_add = (tab == 3) && settings_gui_hit(skin_add, mx, my);
	hover_skin_delete = (tab == 3) && (skin_selected_id() != SKIN_DEFAULT_ID) && settings_gui_hit(skin_delete, mx, my);
	hover_clear = show_clear && point_in_rectangle(mx, my, clear_x, clear_y, clear_x + clear_w, clear_y + clear_h);

	if (mouse_wheel_up()) then scroll = max(0, scroll - 1);
	if (mouse_wheel_down()) then scroll = min(max_scroll, scroll + 1);

	var in_list = (tab == 3)
		? point_in_rectangle(mx, my, list_x, list_y, list_x + skin_list_w, list_y + skin_list_h)
		: point_in_rectangle(mx, my, list_x, list_y, list_x + list_w, list_y + list_h);
	if (mouse_check_button_pressed(mb_left) && in_list) {
		dragging = true;
		drag_moved = false;
		drag_start_y = my;
		drag_start_scroll = scroll;
	};
	if (dragging && mouse_check_button(mb_left)) {
		var dy = drag_start_y - my;
		if (abs(dy) > max(8, 10 * layout_s)) then drag_moved = true;
		if (drag_moved) {
			scroll = clamp(drag_start_scroll + dy / row_h, 0, max_scroll);
		};
	};
	if (!mouse_check_button(mb_left)) then dragging = false;

	if (hits_tab != tab || hits_scroll != scroll || hits_visible != visible_rows
		|| hits_w != layout_w || hits_h != layout_h || hits_s != layout_s) {
		hits_tab = tab;
		hits_scroll = scroll;
		hits_visible = visible_rows;
		hits_w = layout_w;
		hits_h = layout_h;
		hits_s = layout_s;
		row_hits = [];
		lang_hits = [];
		skin_hits = [];
		if (tab == 3) {
			var skin_last = min(array_length(skin_rows), scroll + skin_visible);
			for (var si = scroll; si < skin_last; si++) {
				var skin_item = skin_rows[si];
				if (!is_struct(skin_item)) then continue;
				var skin_row_y = list_y + (si - scroll) * row_h;
				array_push(skin_hits, {
					skin_id: string(skin_item.skin_id ?? ""),
					box: { x:list_x, y:skin_row_y, w:skin_list_w, h:row_h }
				});
			};
		} else if (tab == 2) {
			var lang_last = min(array_length(lang_rows), scroll + visible_rows);
			for (var li = scroll; li < lang_last; li++) {
				var pack = lang_rows[li];
				if (!is_struct(pack)) then continue;
				var lang_row_y = list_y + (li - scroll) * row_h;
				array_push(lang_hits, {
					locale: string(pack.id ?? ""),
					y: lang_row_y,
					box: { x:list_x, y:lang_row_y, w:list_w, h:row_h }
				});
			};
		} else {
			var last = min(array_length(rows), scroll + visible_rows);
			for (var i = scroll; i < last; i++) {
				var item = rows[i];
				var row_y = list_y + (i - scroll) * row_h;
				var ctrl_w = min(220 * layout_s, list_w * 0.38);
				var ctrl_x = list_x + list_w - ctrl_w - 8 * layout_s;
				var ctrl_h = min(36 * layout_s, row_h - 10 * layout_s);
				var ctrl_y = row_y + (row_h - ctrl_h) * 0.5;
				var kind = settings_kind(item.key);
				var hit = { key:item.key, kind:kind, row:i, y:row_y, minus:undefined, plus:undefined, toggle:undefined, field:undefined };
				if (kind == "bool") {
					hit.toggle = { x:ctrl_x, y:ctrl_y, w:ctrl_w, h:ctrl_h };
				} else if (kind == "number") {
					var btn_w = 40 * layout_s;
					hit.minus = { x:ctrl_x, y:ctrl_y, w:btn_w, h:ctrl_h };
					hit.plus = { x:ctrl_x + ctrl_w - btn_w, y:ctrl_y, w:btn_w, h:ctrl_h };
					hit.field = { x:ctrl_x + btn_w + 4 * layout_s, y:ctrl_y, w:ctrl_w - btn_w * 2 - 8 * layout_s, h:ctrl_h };
				} else {
					hit.field = { x:ctrl_x, y:ctrl_y, w:ctrl_w, h:ctrl_h };
				};
				array_push(row_hits, hit);
			};
		};
	};

	if (!armed || !mouse_check_button_pressed(mb_left)) then exit;
	if (drag_moved) then exit;

	if (hover_close) {
		settings_gui_commit_edit();
		settings_gui_close();
		exit;
	};
	if (hover_action) {
		settings_gui_commit_edit();
		var action_kind = settings_gui_action_kind();
		if (action_kind == "reset") {
			settings_confirm_reset();
		} else if (action_kind == "reload") {
			var scan = lang_reload();
			hits_tab = -1;
			scroll = 0;
			var loaded_n = is_struct(scan) ? real(scan.loaded ?? 0) : 0;
			var error_n = is_struct(scan) ? real(scan.error ?? 0) : 0;
			var skipped_n = is_struct(scan) ? real(scan.skipped ?? 0) : 0;
			msgbox_info_async(
				msgbox_join_lines(
					"- Loaded: " + string(loaded_n),
					"- Failed: " + string(error_n),
					"- Skipped: " + string(skipped_n)
				),
				"Information",
				[msgbox_button("OK")],
				MSGBOX_BUTTON_ALIGN.RIGHT
			);
		};
		exit;
	};
	if (hover_tab_normal && tab != 0) {
		settings_gui_commit_edit();
		tab = 0;
		scroll = 0;
		exit;
	};
	if (hover_tab_dev && tab != 1) {
		settings_gui_commit_edit();
		tab = 1;
		scroll = 0;
		settings_warn_developer();
		exit;
	};
	if (hover_tab_lang && tab != 2) {
		settings_gui_commit_edit();
		tab = 2;
		scroll = 0;
		exit;
	};
	if (hover_tab_skin && tab != 3) {
		settings_gui_commit_edit();
		tab = 3;
		scroll = 0;
		skin_preview_set(skin_selected_id());
		exit;
	};
	if (tab == 3) {
		if (hover_skin_add) {
			skin_log("add button clicked");
			skin_pick_file();
			exit;
		};
		if (hover_skin_delete) {
			skin_delete_id(skin_selected_id());
			exit;
		};
		for (var sk = 0; sk < array_length(skin_hits); sk++) {
			var skin_hit = skin_hits[sk];
			if (!settings_gui_hit(skin_hit.box, mx, my)) then continue;
			if (skin_preview_set(skin_hit.skin_id)) then skin_set_selected(skin_hit.skin_id);
			exit;
		};
		exit;
	};
	if (hover_clear) {
		settings_gui_commit_edit();
		settings_clear_data();
		scroll = 0;
		if (!pls_is_gx_remote()) {
			msgbox_info_async("Data cleared and defaults restored.", "Settings", [msgbox_button("OK")], MSGBOX_BUTTON_ALIGN.RIGHT);
		};
		exit;
	};
	if (tab == 2) {
		var current_locale = lang_current_id();
		for (var lp = 0; lp < array_length(lang_hits); lp++) {
			var lang_hit = lang_hits[lp];
			if (!settings_gui_hit(lang_hit.box, mx, my)) then continue;
			if (string(lang_hit.locale) != current_locale) then lang_set(lang_hit.locale);
			exit;
		};
		exit;
	};

	for (var h = 0; h < array_length(row_hits); h++) {
		var rh = row_hits[h];
		var key = rh.key;
		var store = settings_store();
		var cur = store[$ key];
		if (is_struct(rh.toggle) && settings_gui_hit(rh.toggle, mx, my)) {
			settings_gui_commit_edit();
			settings_set(key, !bool(cur));
			exit;
		};
		if (is_struct(rh.minus) && settings_gui_hit(rh.minus, mx, my)) {
			settings_gui_commit_edit();
			if (key == "aa_level") then settings_set(key, settings_aa_cycle(real(cur), -1));
			else settings_set(key, real(cur) - settings_number_step(key));
			exit;
		};
		if (is_struct(rh.plus) && settings_gui_hit(rh.plus, mx, my)) {
			settings_gui_commit_edit();
			if (key == "aa_level") then settings_set(key, settings_aa_cycle(real(cur), 1));
			else settings_set(key, real(cur) + settings_number_step(key));
			exit;
		};
		if (is_struct(rh.field) && settings_gui_hit(rh.field, mx, my)) {
			settings_gui_begin_edit(key);
			exit;
		};
	};

	if (is_string(editing_key) && string_length(editing_key)) then settings_gui_commit_edit();
}

function settings_gui_draw() {
	var old_font = draw_get_font();
	var old_halign = draw_get_halign();
	var old_valign = draw_get_valign();
	var old_colour = draw_get_colour();
	var old_alpha = draw_get_alpha();
	if (font_exists(ui_font)) then draw_set_font(ui_font);
	else draw_set_font(-1);
	settings_gui_action_layout();

	var s = layout_s;
	if (!is_real(s) || s <= 0) then s = 1.0;
	var title_scale = 0.7 * s;
	var tab_scale = 0.48 * s;
	var body_scale = 0.42 * s;
	var small_scale = 0.32 * s;
	var fill_idle = make_colour_rgb(40, 48, 64);
	var fill_hot = make_colour_rgb(70, 110, 180);
	var fill_tab = make_colour_rgb(28, 34, 48);
	var fill_on = make_colour_rgb(46, 120, 92);

	draw_set_alpha(0.62);
	draw_set_colour(c_black);
	draw_rectangle(0, 0, room_width, room_height, false);
	draw_set_alpha(1);
	draw_set_colour(make_colour_rgb(16, 22, 36));
	draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);
	draw_set_colour(c_white);
	draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, true);

	draw_set_halign(fa_left);
	draw_set_valign(fa_middle);
	draw_set_colour(c_white);
	draw_text_transformed(panel_x + 18 * s, panel_y + 30 * s, lang("settings.title"), title_scale, title_scale, 0);

	draw_set_halign(fa_center);
	draw_set_colour(hover_close ? fill_hot : fill_idle);
	draw_rectangle(close_x, close_y, close_x + close_w, close_y + close_h, false);
	draw_set_colour(c_white);
	draw_rectangle(close_x, close_y, close_x + close_w, close_y + close_h, true);
	draw_text_transformed(close_x + close_w * 0.5, close_y + close_h * 0.5, lang("settings.close"), small_scale + 0.08 * s, small_scale + 0.08 * s, 0);

	if (show_action) {
		var action_label = settings_gui_action_label();
		draw_set_colour(hover_action ? fill_hot : fill_idle);
		draw_rectangle(action_x, action_y, action_x + action_w, action_y + action_h, false);
		draw_set_colour(c_white);
		draw_rectangle(action_x, action_y, action_x + action_w, action_y + action_h, true);
		draw_text_transformed(action_x + action_w * 0.5, action_y + action_h * 0.5, action_label, small_scale + 0.08 * s, small_scale + 0.08 * s, 0);
	};

	settings_gui_draw_tab(tab_normal, hover_tab_normal, tab == 0, lang("settings.normal"), tab_scale, fill_hot, fill_tab);
	settings_gui_draw_tab(tab_dev, hover_tab_dev, tab == 1, lang("settings.developer"), tab_scale, fill_hot, fill_tab);
	settings_gui_draw_tab(tab_lang, hover_tab_lang, tab == 2, lang("settings.language"), tab_scale, fill_hot, fill_tab);
	settings_gui_draw_tab(tab_skin, hover_tab_skin, tab == 3, lang("settings.skin", "Skin"), tab_scale, fill_hot, fill_tab);

	if (tab == 3) {
		settings_gui_draw_skins(s, body_scale, small_scale, fill_idle, fill_hot, fill_on);
	} else {
	draw_set_colour(make_colour_rgb(22, 29, 45));
	draw_rectangle(list_x, list_y, list_x + list_w, list_y + list_h, false);
	draw_set_colour(make_colour_rgb(70, 80, 96));
	draw_rectangle(list_x, list_y, list_x + list_w, list_y + list_h, true);

	if (tab == 2) {
		var packs = lang_packs();
		var current_locale = lang_current_id();
		var lang_last = min(array_length(packs), scroll + visible_rows);
		for (var _pi = scroll; _pi < lang_last; _pi++) {
			var pack = packs[_pi];
			if (!is_struct(pack)) then continue;
			var pack_y = list_y + (_pi - scroll) * row_h;
			var selected = (string(pack.id ?? "") == current_locale);
			if (selected) {
				draw_set_colour(make_colour_rgb(70, 110, 180));
				draw_rectangle(list_x + 2, pack_y, list_x + list_w - 2, pack_y + row_h, false);
			} else if ((_pi - scroll) mod 2 == 1) {
				draw_set_colour(make_colour_rgb(20, 26, 40));
				draw_rectangle(list_x + 2, pack_y, list_x + list_w - 2, pack_y + row_h, false);
			};
			draw_set_halign(fa_left);
			draw_set_valign(fa_middle);
			draw_set_colour(c_white);
			draw_text_transformed(list_x + 12 * s, pack_y + row_h * 0.38, lang_pack_label(pack), body_scale, body_scale, 0);
			draw_set_colour(make_colour_rgb(150, 160, 180));
			draw_text_transformed(list_x + 12 * s, pack_y + row_h * 0.72, string(pack.id ?? ""), small_scale, small_scale, 0);
		};
	} else {
	var rows = settings_gui_rows();
	var store = settings_store();
	var last = min(array_length(rows), scroll + visible_rows);
	for (var i = scroll; i < last; i++) {
		var item = rows[i];
		var row_y = list_y + (i - scroll) * row_h;
		if ((i - scroll) mod 2 == 1) {
			draw_set_colour(make_colour_rgb(20, 26, 40));
			draw_rectangle(list_x + 2, row_y, list_x + list_w - 2, row_y + row_h, false);
		};
		var label = settings_field_label(item.key, item.comment);
		draw_set_halign(fa_left);
		draw_set_valign(fa_middle);
		draw_set_colour(c_white);
		draw_text_transformed(list_x + 12 * s, row_y + row_h * 0.38, label, body_scale, body_scale, 0);
		draw_set_colour(make_colour_rgb(150, 160, 180));
		draw_text_transformed(list_x + 12 * s, row_y + row_h * 0.72, item.key, small_scale, small_scale, 0);
	};

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	for (var h = 0; h < array_length(row_hits); h++) {
		var rh = row_hits[h];
		var cur = store[$ rh.key];
		if (rh.kind == "bool" && is_struct(rh.toggle)) {
			var on = bool(cur);
			draw_set_colour(on ? fill_on : fill_idle);
			draw_rectangle(rh.toggle.x, rh.toggle.y, rh.toggle.x + rh.toggle.w, rh.toggle.y + rh.toggle.h, false);
			draw_set_colour(c_white);
			draw_rectangle(rh.toggle.x, rh.toggle.y, rh.toggle.x + rh.toggle.w, rh.toggle.y + rh.toggle.h, true);
			draw_text_transformed(rh.toggle.x + rh.toggle.w * 0.5, rh.toggle.y + rh.toggle.h * 0.5, on ? lang("common.on") : lang("common.off"), body_scale, body_scale, 0);
		} else if (rh.kind == "number") {
			var shown = (editing_key == rh.key) ? keyboard_string : string(cur);
			if (is_struct(rh.minus)) {
				draw_set_colour(fill_idle);
				draw_rectangle(rh.minus.x, rh.minus.y, rh.minus.x + rh.minus.w, rh.minus.y + rh.minus.h, false);
				draw_set_colour(c_white);
				draw_rectangle(rh.minus.x, rh.minus.y, rh.minus.x + rh.minus.w, rh.minus.y + rh.minus.h, true);
				draw_text_transformed(rh.minus.x + rh.minus.w * 0.5, rh.minus.y + rh.minus.h * 0.5, "-", body_scale, body_scale, 0);
			};
			if (is_struct(rh.plus)) {
				draw_set_colour(fill_idle);
				draw_rectangle(rh.plus.x, rh.plus.y, rh.plus.x + rh.plus.w, rh.plus.y + rh.plus.h, false);
				draw_set_colour(c_white);
				draw_rectangle(rh.plus.x, rh.plus.y, rh.plus.x + rh.plus.w, rh.plus.y + rh.plus.h, true);
				draw_text_transformed(rh.plus.x + rh.plus.w * 0.5, rh.plus.y + rh.plus.h * 0.5, "+", body_scale, body_scale, 0);
			};
			if (is_struct(rh.field)) {
				draw_set_colour(editing_key == rh.key ? make_colour_rgb(38, 75, 104) : make_colour_rgb(22, 29, 45));
				draw_rectangle(rh.field.x, rh.field.y, rh.field.x + rh.field.w, rh.field.y + rh.field.h, false);
				draw_set_colour(c_white);
				draw_rectangle(rh.field.x, rh.field.y, rh.field.x + rh.field.w, rh.field.y + rh.field.h, true);
				draw_text_transformed(rh.field.x + rh.field.w * 0.5, rh.field.y + rh.field.h * 0.5, shown, body_scale, body_scale, 0);
			};
		} else if (is_struct(rh.field)) {
			var text = (editing_key == rh.key) ? keyboard_string : string(cur ?? "");
			draw_set_colour(editing_key == rh.key ? make_colour_rgb(38, 75, 104) : make_colour_rgb(22, 29, 45));
			draw_rectangle(rh.field.x, rh.field.y, rh.field.x + rh.field.w, rh.field.y + rh.field.h, false);
			draw_set_colour(c_white);
			draw_rectangle(rh.field.x, rh.field.y, rh.field.x + rh.field.w, rh.field.y + rh.field.h, true);
			draw_text_transformed(rh.field.x + rh.field.w * 0.5, rh.field.y + rh.field.h * 0.5, text, body_scale, body_scale, 0);
		};
	};
	};
	};

	if (show_clear) {
		draw_set_colour(hover_clear ? make_colour_rgb(140, 60, 60) : make_colour_rgb(96, 48, 48));
		draw_rectangle(clear_x, clear_y, clear_x + clear_w, clear_y + clear_h, false);
		draw_set_colour(c_white);
		draw_rectangle(clear_x, clear_y, clear_x + clear_w, clear_y + clear_h, true);
		draw_text_transformed(clear_x + clear_w * 0.5, clear_y + clear_h * 0.5, lang("settings.clearData"), body_scale, body_scale, 0);
	};

	draw_set_halign(fa_right);
	draw_set_colour(c_gray);
	var hint = lang("settings.hintNormal");
	if (tab == 1) then hint = lang("settings.hintDeveloper");
	else if (tab == 2) then hint = lang_current_label();
	else if (tab == 3) then hint = lang("settings.hintSkin", "Add a resource pack, then select it. It applies when you enter a chart.");
	draw_text_transformed(panel_x + panel_w - 18 * s, panel_y + panel_h - 26 * s, hint, small_scale, small_scale, 0);

	draw_set_font(old_font);
	draw_set_halign(old_halign);
	draw_set_valign(old_valign);
	draw_set_colour(old_colour);
	draw_set_alpha(old_alpha);
}
