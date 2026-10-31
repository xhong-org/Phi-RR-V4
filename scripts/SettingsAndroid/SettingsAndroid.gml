///@desc Android 全屏设置；草稿、保存、语言和皮肤仍由 SettingsGUI 管理
function settings_android_layout() {
	var rw = max(1, room_width);
	var rh = max(1, room_height);
	var s = min(rw / 960, rh / 540);
	var pad = 20 * s;
	var rail = 204 * s;
	layout_s = s;
	layout_w = rw;
	layout_h = rh;
	// 单独记录全局缩放，手机布局本身按屏幕短边计算。
	layout_global_s = variable_global_exists("global_scales") ? global_scales : 1;
	panel_x = 0;
	panel_y = 0;
	panel_w = rw;
	panel_h = rh;
	tab_h = 64 * s;
	tab_y = 94 * s;
	tab_w = rail - pad;
	tab_normal = { x:pad * 0.5, y:tab_y, w:tab_w, h:tab_h };
	tab_lang = { x:pad * 0.5, y:tab_y + tab_h + 12 * s, w:tab_w, h:tab_h };
	tab_skin = { x:pad * 0.5, y:tab_y + (tab_h + 12 * s) * 2, w:tab_w, h:tab_h };
	save_h = 54 * s;
	discard_h = save_h;
	save_w = 148 * s;
	discard_w = 148 * s;
	save_x = rw - pad - save_w;
	discard_x = save_x - 12 * s - discard_w;
	save_y = 16 * s;
	discard_y = save_y;
	footer_h = 72 * s;
	list_x = rail + pad;
	list_y = 90 * s;
	list_w = max(1, rw - list_x - pad);
	list_h = max(1, rh - list_y - footer_h - 12 * s);
	row_h = 82 * s;
	visible_rows = max(1, floor(list_h / row_h));
	clear_x = pad * 0.5;
	clear_w = tab_w;
	clear_h = 54 * s;
	clear_y = rh - clear_h - pad;
	show_clear = true;
	skin_list_w = list_w * 0.38;
	skin_add_h = 54 * s;
	skin_list_h = max(1, list_h - skin_add_h - 12 * s);
	skin_add = { x:list_x, y:list_y + skin_list_h + 12 * s, w:skin_list_w, h:skin_add_h };
	skin_preview_x = list_x + skin_list_w + 16 * s;
	skin_preview_w = list_w - skin_list_w - 16 * s;
	skin_delete = { x:skin_preview_x + skin_preview_w - 130 * s,
		y:list_y + list_h - 54 * s, w:130 * s, h:54 * s };
	slider_hit = undefined;
	slider_dragging = false;
	settings_android_action_layout();
}

///@desc 重置和语言重载放在内容区底部，与保存按钮分开
function settings_android_action_layout() {
	show_action = settings_gui_action_kind() != "";
	action_x = list_x;
	action_y = panel_h - 62 * layout_s;
	action_w = 208 * layout_s;
	action_h = 48 * layout_s;
}

///@desc 有固定上下限的三项设置使用滑块，其余保留数值输入
function settings_android_range(_key) {
	switch (_key) {
		case "noteSize": return { low:0.5, high:4, step:0.05 };
		case "musicVolume":
		case "hitsoundVolume": return { low:0, high:1, step:0.01 };
	};
	return undefined;
}

///@desc 滚动以行的实数偏移保存；命中盒只包含列表内的可见部分
function settings_android_refresh_hits() {
	var fold = settings_gui_fold_sig();
	if (hits_tab == tab && hits_scroll == scroll && hits_w == layout_w
		&& hits_h == layout_h && hits_fold == fold) then return;
	hits_tab = tab;
	hits_scroll = scroll;
	hits_w = layout_w;
	hits_h = layout_h;
	hits_fold = fold;
	row_hits = [];
	lang_hits = [];
	skin_hits = [];
	var rows = (tab == 0) ? settings_gui_rows() : lang_packs();
	var first = floor(scroll);
	var last = min(array_length(rows), ceil(scroll + list_h / row_h));
	var s = layout_s;
	for (var i = first; i < last; i++) {
		var ry = list_y + (i - scroll) * row_h;
		var top = max(list_y, ry);
		var bottom = min(list_y + list_h, ry + row_h);
		var box = { x:list_x, y:top, w:list_w, h:bottom - top };
		if (tab == 1) {
			array_add(lang_hits, { locale:string(rows[i].id ?? ""), y:ry, box:box });
			continue;
		};
		var entry = rows[i];
		if (entry.type == "group") {
			array_add(row_hits, { row_type:"group", group_id:entry.id, y:ry, box:box });
			continue;
		};
		var key = entry.item.key;
		var ctrl_w = list_w * 0.42;
		var ctrl_x = list_x + list_w - ctrl_w - 18 * s;
		var ctrl_y = ry + 14 * s;
		var ctrl_h = row_h - 28 * s;
		var kind = settings_kind(key);
		var hit = { row_type:"field", key:key, kind:kind, y:ry, box:box,
			enabled:settings_platform_enabled(key), minus:undefined, plus:undefined,
			toggle:undefined, field:undefined, slider:undefined };
		var range = settings_android_range(key);
		if (!hit.enabled || kind == "string") {
			hit.field = { x:ctrl_x, y:ctrl_y, w:ctrl_w, h:ctrl_h };
		} else if (kind == "bool") {
			// 整行切换，绘制仍是右侧的大开关。
			hit.toggle = box;
		} else if (is_struct(range)) {
			hit.slider = { x:ctrl_x + 12 * s, y:ry + row_h * 0.68, w:ctrl_w - 24 * s, h:32 * s };
			hit.range = range;
		} else {
			var btn_w = ctrl_h;
			hit.minus = { x:ctrl_x, y:ctrl_y, w:btn_w, h:ctrl_h };
			hit.plus = { x:ctrl_x + ctrl_w - btn_w, y:ctrl_y, w:btn_w, h:ctrl_h };
			hit.field = { x:ctrl_x + btn_w + 6 * s, y:ctrl_y, w:ctrl_w - btn_w * 2 - 12 * s, h:ctrl_h };
		};
		array_add(row_hits, hit);
	};
}

///@desc 水平拖动滑块，纵向手势继续交给列表；取消触摸不产生点击
function settings_android_slider_step(_pointer) {
	if (_pointer.pressed) {
		slider_hit = undefined;
		slider_dragging = false;
		for (var i = 0; i < array_length(row_hits); i++) {
			var hit = row_hits[i];
			if (hit.row_type != "field" || !is_struct(hit.slider)) then continue;
			var bar = hit.slider;
			if (settings_gui_hit(hit.box, _pointer.x, _pointer.y)
				&& abs(_pointer.y - bar.y) <= bar.h * 0.65
				&& _pointer.x >= bar.x - bar.h * 0.5 && _pointer.x <= bar.x + bar.w + bar.h * 0.5) {
				slider_hit = hit;
				slider_start_x = _pointer.x;
				slider_start_y = _pointer.y;
				break;
			};
		};
	};
	if (!is_struct(slider_hit)) then return false;
	var dx = abs(_pointer.x - slider_start_x);
	var dy = abs(_pointer.y - slider_start_y);
	var threshold = 10 * layout_s;
	if (!slider_dragging && dy > threshold && dy >= dx) {
		slider_hit = undefined;
		return false;
	};
	if (!slider_dragging && dx > threshold && dx > dy * 1.2) {
		settings_gui_commit_edit();
		slider_dragging = true;
		dragging = false;
		drag_moved = true;
	};
	var active = slider_dragging;
	var tapped = _pointer.released && dx <= threshold && dy <= threshold;
	if ((active && _pointer.held) || tapped || (active && _pointer.released)) {
		settings_gui_commit_edit();
		var bar = slider_hit.slider;
		var range = slider_hit.range;
		var ratio = clamp((_pointer.x - bar.x) / max(1, bar.w), 0, 1);
		var value = range.low + ratio * (range.high - range.low);
		value = range.low + round((value - range.low) / range.step) * range.step;
		settings_gui_draft_set(slider_hit.key, value);
	};
	if (!_pointer.held) {
		slider_hit = undefined;
		slider_dragging = false;
		dragging = false;
	};
	return active || tapped;
}

///@desc 按统一字号绘制按钮文字，长翻译只在确实放不下时缩小
function settings_android_text(_label, _box, _height, _colour = c_white, _align = fa_center) {
	draw_set_colour(_colour);
	draw_set_halign(_align);
	draw_set_valign(fa_middle);
	var scale = min(_height / max(1, string_height("Ag")),
		settings_fit_text_scale(_label, max(1, _box.w), _height));
	var tx = _box.x + ((_align == fa_center) ? _box.w * 0.5 : ((_align == fa_right) ? _box.w : 0));
	draw_text_transformed(tx, _box.y + _box.h * 0.5, _label, scale, scale, 0);
}

function settings_android_button(_box, _label, _fill, _hot = false) {
	draw_set_colour(_hot ? make_colour_rgb(59, 103, 146) : _fill);
	draw_roundrect(_box.x, _box.y, _box.x + _box.w, _box.y + _box.h, false);
	settings_android_text(_label, { x:_box.x + 10 * layout_s, y:_box.y,
		w:_box.w - 20 * layout_s, h:_box.h }, 21 * layout_s);
}

///@desc 绘制全屏导航、设置行和大触控控件；仅 Android 调用
function settings_android_draw() {
	var old_font = draw_get_font();
	var old_halign = draw_get_halign();
	var old_valign = draw_get_valign();
	var old_colour = draw_get_colour();
	var old_alpha = draw_get_alpha();
	gpu_push_state();
	shader_reset();
	gpu_set_blendmode(bm_normal);
	draw_set_alpha(1);
	var font = settings_ui_font();
	draw_set_font(font_exists(font) ? font : -1);
	settings_gui_refresh_hits();
	settings_android_action_layout();
	var s = layout_s;
	var idle = make_colour_rgb(31, 45, 62);
	var accent = make_colour_rgb(49, 126, 152);
	var muted = make_colour_rgb(162, 179, 196);
	draw_set_colour(make_colour_rgb(12, 20, 31));
	draw_rectangle(0, 0, panel_w, panel_h, false);
	draw_set_colour(make_colour_rgb(19, 31, 46));
	draw_rectangle(0, 0, list_x - 20 * s, panel_h, false);
	settings_android_text(lang("settings.title"), { x:24 * s, y:16 * s, w:156 * s, h:54 * s }, 30 * s, c_white, fa_left);
	settings_android_button(tab_normal, lang("settings.normal"), tab == 0 ? accent : idle, hover_tab_normal);
	settings_android_button(tab_lang, lang("settings.language"), tab == 1 ? accent : idle, hover_tab_lang);
	settings_android_button(tab_skin, lang("settings.skin"), tab == 2 ? accent : idle, hover_tab_skin);
	settings_android_button({ x:save_x, y:save_y, w:save_w, h:save_h }, lang("settings.saveClose", "Save and return"), accent, hover_save);
	settings_android_button({ x:discard_x, y:discard_y, w:discard_w, h:discard_h }, lang("settings.discardShort", "Discard"), idle, hover_discard);
	settings_android_button({ x:clear_x, y:clear_y, w:clear_w, h:clear_h }, lang("settings.clearData"), make_colour_rgb(76, 38, 47), hover_clear);
	if (show_action) settings_android_button({ x:action_x, y:action_y, w:action_w, h:action_h }, settings_gui_action_label(), idle, hover_action);
	var hint = lang((tab == 2) ? "settings.hintSkin" : "settings.hintTouch");
	var hint_x = show_action ? action_x + action_w + 20 * s : list_x;
	settings_android_text(hint, { x:hint_x, y:panel_h - 62 * s, w:panel_w - hint_x - 20 * s, h:48 * s }, 17 * s, muted, fa_right);
	if (tab == 2) {
		var font_h = max(1, string_height("Ag"));
		settings_gui_draw_skins(s, 23 * s / font_h, 17 * s / font_h, idle, accent, accent);
	} else {
		// 内容裁剪与 GPU 状态成对恢复，滑到半行时不会盖住导航或保存。
		gpu_set_scissor(floor(list_x), floor(list_y), ceil(list_w), floor(list_h));
		settings_android_draw_rows(idle, accent, muted);
	};
	shader_reset();
	gpu_pop_state();
	draw_set_font(old_font);
	draw_set_halign(old_halign);
	draw_set_valign(old_valign);
	draw_set_colour(old_colour);
	draw_set_alpha(old_alpha);
}

function settings_android_draw_rows(_idle, _accent, _muted) {
	var s = layout_s;
	var rows = (tab == 0) ? settings_gui_rows() : lang_packs();
	var first = floor(scroll);
	var last = min(array_length(rows), ceil(scroll + list_h / row_h));
	var store = settings_gui_draft();
	var fold = settings_gui_group_state();
	for (var i = first; i < last; i++) {
		var ry = list_y + (i - scroll) * row_h;
		var box = { x:list_x + 18 * s, y:ry, w:list_w - 36 * s, h:row_h - 6 * s };
		draw_set_colour(make_colour_rgb(22, 34, 49));
		draw_roundrect(list_x, ry, list_x + list_w, ry + row_h - 6 * s, false);
		if (tab == 1) {
			var pack = rows[i];
			if (string(pack.id ?? "") == lang_current_id()) {
				draw_set_colour(_accent);
				draw_roundrect(list_x, ry, list_x + list_w, ry + row_h - 6 * s, false);
			};
			settings_android_text(lang_pack_label(pack), { x:box.x, y:ry + 6 * s, w:box.w * 0.67, h:36 * s }, 25 * s, c_white, fa_left);
			settings_android_text(string(pack.id ?? ""), { x:box.x, y:ry + 43 * s, w:box.w * 0.67, h:25 * s }, 17 * s, _muted, fa_left);
			settings_android_text(string(pack[$ "author"] ?? ""), { x:box.x + box.w * 0.7, y:ry, w:box.w * 0.3, h:box.h }, 20 * s, c_white, fa_right);
			continue;
		};
		var entry = rows[i];
		if (entry.type == "group") {
			draw_set_colour(entry.id == "deprecated" ? make_colour_rgb(57, 35, 43) : make_colour_rgb(29, 48, 65));
			draw_roundrect(list_x, ry, list_x + list_w, ry + row_h - 6 * s, false);
			settings_android_text(settings_group_title(entry.id), box, 26 * s, c_white, fa_left);
			settings_android_text(bool(fold[$ entry.id]) ? "-" : "+", box, 28 * s, _muted, fa_right);
			continue;
		};
		var label = settings_field_label(entry.item.key, entry.item.comment);
		// 长标签用两行统一字号；这里不显示面向开发者的字段名。
		var label_w = list_w * 0.51;
		var text_scale = 23 * s / max(1, string_height("Ag"));
		var label_h = string_height_ext(label, -1, label_w / text_scale) * text_scale;
		text_scale *= min(1, 60 * s / max(1, label_h));
		label_h = string_height_ext(label, -1, label_w / text_scale) * text_scale;
		draw_set_colour(c_white);
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		draw_text_ext_transformed(box.x, ry + (row_h - label_h) * 0.5, label, -1, label_w / text_scale, text_scale, text_scale, 0);
	};
	for (var h = 0; h < array_length(row_hits); h++) {
		var hit = row_hits[h];
		if (hit.row_type == "group") then continue;
		var value = store[$ hit.key];
		if (!hit.enabled) {
			settings_android_text(lang("settings.unsupportedMSAA"), hit.field, 18 * s, _muted);
		} else if (is_struct(hit.slider)) {
			var bar = hit.slider;
			var range = hit.range;
			var ratio = clamp((value - range.low) / (range.high - range.low), 0, 1);
			var shown = (hit.key == "noteSize") ? string_format(value, 0, 2) + "x" : string(round(value * 100)) + "%";
			settings_android_text(shown, { x:bar.x, y:hit.y + 5 * s, w:bar.w, h:32 * s }, 23 * s);
			draw_set_colour(_idle);
			draw_roundrect(bar.x, bar.y - 4 * s, bar.x + bar.w, bar.y + 4 * s, false);
			draw_set_colour(_accent);
			draw_roundrect(bar.x, bar.y - 4 * s, bar.x + max(1, bar.w * ratio), bar.y + 4 * s, false);
			draw_set_colour(c_white);
			draw_circle(bar.x + bar.w * ratio, bar.y, 11 * s, false);
		} else if (hit.kind == "bool") {
			var on = bool(value);
			var toggle = { x:list_x + list_w - 112 * s, y:hit.y + 19 * s, w:88 * s, h:40 * s };
			draw_set_colour(on ? _accent : _idle);
			draw_roundrect(toggle.x, toggle.y, toggle.x + toggle.w, toggle.y + toggle.h, false);
			draw_set_colour(c_white);
			draw_circle(toggle.x + (on ? toggle.w - 20 * s : 20 * s), toggle.y + toggle.h * 0.5, 14 * s, false);
		} else {
			if (is_struct(hit.minus)) settings_android_button(hit.minus, "-", _idle);
			if (is_struct(hit.plus)) settings_android_button(hit.plus, "+", _idle);
			if (is_struct(hit.field)) {
				var shown = (editing_key == hit.key) ? keyboard_string + "|" : string(value);
				settings_android_button(hit.field, shown, _idle);
			};
		};
	};
	if (array_length(rows) > list_h / row_h) {
		var total = array_length(rows);
		var thumb_h = max(24 * s, list_h * list_h / (total * row_h));
		var thumb_y = list_y + (list_h - thumb_h) * scroll / (total - list_h / row_h);
		draw_set_colour(_muted);
		draw_rectangle(list_x + list_w - 4 * s, thumb_y, list_x + list_w, thumb_y + thumb_h, false);
	};
}
