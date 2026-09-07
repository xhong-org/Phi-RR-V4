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

function settings_list(_deprecated) {
	var cat = settings_catalog();
	var store = settings_store();
	var out = [];
	var seen = {};
	for (var i = 0; i < array_length(cat); i++) {
		var item = cat[i];
		seen[$ item.key] = true;
		if (settings_comment_is_deprecated(item.comment) == bool(_deprecated)) {
			array_push(out, item);
		};
	};
	if (!_deprecated) {
		var names = struct_get_names(store);
		for (var n = 0; n < array_length(names); n++) {
			if (struct_exists(seen, names[n])) then continue;
			array_push(out, { key:names[n], comment:names[n] });
		};
	};
	return out;
}

function settings_gui_blocking() {
	return instance_exists(oSettings);
}

function settings_gui_open() {
	if (instance_exists(oSettings) || instance_exists(oFilePicker)) then return;
	instance_create_depth(0, 0, -2000000, oSettings);
}

function settings_gui_close() {
	if (instance_exists(oSettings)) then with (oSettings) instance_destroy();
}

function settings_developer_warning_text() {
	return lang("settings.developerWarning");
}

function settings_warn_developer() {
	var msg = settings_developer_warning_text();
	var buttons = [msgbox_button(lang("common.confirm"))];
	if (i_wbox_native_ready()) {
		msgbox_warning_sync(msg, lang("common.warning"), buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
	} else {
		msgbox_warning_async(msg, lang("common.warning"), buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
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
	tab_w = (panel_w - pad * 4) / 3;
	tab_normal = { x:panel_x + pad, y:tab_y, w:tab_w, h:tab_h };
	tab_dev = { x:panel_x + pad * 2 + tab_w, y:tab_y, w:tab_w, h:tab_h };
	tab_lang = { x:panel_x + pad * 3 + tab_w * 2, y:tab_y, w:tab_w, h:tab_h };
	close_w = 90 * s;
	close_h = 36 * s;
	close_x = panel_x + panel_w - pad - close_w;
	close_y = panel_y + 12 * s;
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
	scroll = 0;
	armed = false;
	dragging = false;
	drag_moved = false;
	drag_start_y = 0;
	drag_start_scroll = 0;
	editing_key = "";
	hover_close = false;
	hover_tab_normal = false;
	hover_tab_dev = false;
	hover_tab_lang = false;
	hover_clear = false;
	row_hits = [];
	lang_hits = [];
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

	var rows = settings_gui_rows();
	var lang_rows = lang_packs();
	var list_count = (tab == 2) ? array_length(lang_rows) : array_length(rows);
	var max_scroll = max(0, list_count - visible_rows);
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
	hover_close = point_in_rectangle(mx, my, close_x, close_y, close_x + close_w, close_y + close_h);
	hover_tab_normal = settings_gui_hit(tab_normal, mx, my);
	hover_tab_dev = settings_gui_hit(tab_dev, mx, my);
	hover_tab_lang = settings_gui_hit(tab_lang, mx, my);
	hover_clear = show_clear && point_in_rectangle(mx, my, clear_x, clear_y, clear_x + clear_w, clear_y + clear_h);

	if (mouse_wheel_up()) then scroll = max(0, scroll - 1);
	if (mouse_wheel_down()) then scroll = min(max_scroll, scroll + 1);

	var in_list = point_in_rectangle(mx, my, list_x, list_y, list_x + list_w, list_y + list_h);
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

	row_hits = [];
	lang_hits = [];
	if (tab == 2) {
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

	if (!armed || !mouse_check_button_pressed(mb_left)) then exit;
	if (drag_moved) then exit;

	if (hover_close) {
		settings_gui_commit_edit();
		settings_gui_close();
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
	if (hover_clear) {
		settings_gui_commit_edit();
		settings_clear_data();
		scroll = 0;
		if (!pls_is_gx_remote()) {
			msgbox_info_async(lang("settings.cleared"), lang("common.settings"), [msgbox_button(lang("common.confirm"))], MSGBOX_BUTTON_ALIGN.RIGHT);
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

	var tabs = [
		[tab_normal, hover_tab_normal, tab == 0, lang("settings.normal")],
		[tab_dev, hover_tab_dev, tab == 1, lang("settings.developer")],
		[tab_lang, hover_tab_lang, tab == 2, lang("settings.language")]
	];
	for (var t = 0; t < 3; t++) {
		var box = tabs[t][0];
		var hot = tabs[t][1];
		var on = tabs[t][2];
		draw_set_colour(on ? fill_hot : (hot ? make_colour_rgb(52, 64, 88) : fill_tab));
		draw_rectangle(box.x, box.y, box.x + box.w, box.y + box.h, false);
		draw_set_colour(c_white);
		draw_rectangle(box.x, box.y, box.x + box.w, box.y + box.h, true);
		draw_text_transformed(box.x + box.w * 0.5, box.y + box.h * 0.5, tabs[t][3], tab_scale, tab_scale, 0);
	};

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
		var label = lang($"fields.{item.key}", settings_comment_label(item.comment));
		if (!string_length(label)) then label = item.key;
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
	draw_text_transformed(panel_x + panel_w - 18 * s, panel_y + panel_h - 26 * s, hint, small_scale, small_scale, 0);

	draw_set_font(old_font);
	draw_set_halign(old_halign);
	draw_set_valign(old_valign);
	draw_set_colour(old_colour);
	draw_set_alpha(old_alpha);
}
