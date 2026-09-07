/// @description Locale packs from language/*.json. Default en-US.

#macro LANG_DEFAULT "en-US"

function lang_dir() {
	return $"{working_directory}language/";
}

function lang_norm_dir(_dir) {
	var s = string(_dir ?? "");
	if (!string_length(s)) then return lang_dir();
	var last = string_char_at(s, string_length(s));
	if (last != "/" && last != "\\") then s += "/";
	return s;
}

function lang_lookup(_root, _key) {
	if (!is_struct(_root) || !is_string(_key) || !string_length(_key)) then return undefined;
	var parts = string_split(_key, ".");
	var cur = _root;
	for (var i = 0; i < array_length(parts); i++) {
		if (!is_struct(cur) || !struct_exists(cur, parts[i])) then return undefined;
		cur = cur[$ parts[i]];
	};
	if (is_string(cur)) then return cur;
	return undefined;
}

function lang(_key, _fallback = undefined) {
	lang_ensure();
	var v = lang_lookup(global.pls_lang.objects, _key);
	if (is_string(v) && string_length(v)) then return v;
	v = lang_lookup(global.pls_lang.fallback, _key);
	if (is_string(v) && string_length(v)) then return v;
	if (is_string(_fallback)) then return _fallback;
	return string(_key ?? "");
}

function langf(_key) {
	var s = lang(_key);
	for (var i = 1; i < argument_count; i++) {
		s = string_replace_all(s, "{" + string(i - 1) + "}", string(argument[i]));
	};
	return s;
}

function lang_pack_label(_pack) {
	if (!is_struct(_pack)) then return "";
	return $"{string(_pack.name ?? "")}(v{string(_pack.version ?? "")})";
}

function lang_current_id() {
	lang_ensure();
	return string(global.pls_lang.id ?? LANG_DEFAULT);
}

function lang_current_label() {
	lang_ensure();
	var packs = global.pls_lang.packs;
	var locale_id = lang_current_id();
	for (var i = 0; i < array_length(packs); i++) {
		if (packs[i].id == locale_id) then return lang_pack_label(packs[i]);
	};
	return $"{locale_id}(v)";
}

function lang_packs() {
	lang_ensure();
	return global.pls_lang.packs;
}

function lang_collect_json(_dir, _out) {
	_dir = lang_norm_dir(_dir);
	var found = "";
	try { found = file_find_first(_dir + "*.json", 0); } catch (find_err) { delete(find_err); found = ""; };
	while (is_string(found) && string_length(found)) {
		array_push(_out, _dir + found);
		try { found = file_find_next(); } catch (next_err) { delete(next_err); found = ""; };
	};
	try { file_find_close(); } catch (close_err) { delete(close_err); };
	var sub = [];
	found = "";
	try { found = file_find_first(_dir + "*", fa_directory); } catch (dir_err) { delete(dir_err); found = ""; };
	while (is_string(found) && string_length(found)) {
		if (found != "." && found != ".." && directory_exists(_dir + found)) then array_push(sub, _dir + found);
		try { found = file_find_next(); } catch (dir_next) { delete(dir_next); found = ""; };
	};
	try { file_find_close(); } catch (dir_close) { delete(dir_close); };
	if (chart_use_native_files()) {
		var listed = string(chart_native_list(_dir) ?? "");
		if (string_length(listed)) {
			var rows = string_split(string_replace_all(listed, "\r", "\n"), "\n");
			for (var r = 0; r < array_length(rows); r++) {
				var item = string_trim(rows[r]);
				if (!string_length(item)) then continue;
				var full = _dir + item;
				if (string_lower(filename_ext(item)) == ".json") then array_push(_out, full);
				else if (directory_exists(full) || chart_native_is_dir(full)) then array_push(sub, full);
			};
		};
	};
	for (var s = 0; s < array_length(sub); s++) {
		lang_collect_json(sub[s], _out);
	};
}

function lang_try_load_file(_path) {
	if (!is_string(_path) || !string_length(_path)) then return undefined;
	if (!isExists(_path) && !file_exists(_path)) then return undefined;
	var text = chart_read_text_file(_path, -1);
	if (!is_string(text) || !string_length(text)) then return undefined;
	var data = undefined;
	try { data = json_parse(text); } catch (parse_err) { delete(parse_err); return undefined; };
	if (!is_struct(data)) then return undefined;
	var name = string(data[$ "name"] ?? "");
	if (!string_length(name)) then return undefined;
	var objects = data[$ "objects"];
	if (!is_struct(objects)) then objects = {};
	var locale_id = filename_change_ext(filename_name(_path), "");
	if (!string_length(locale_id)) then locale_id = name;
	return {
		id: locale_id,
		name: name,
		version: string(data[$ "version"] ?? ""),
		objects: objects,
		path: _path
	};
}

function lang_saved_id() {
	var f = settings_ini_path();
	if (!file_exists(f) && !isExists(f)) then return LANG_DEFAULT;
	ini_open(f);
	var locale_id = ini_read_string("Settings", "language", LANG_DEFAULT);
	ini_close();
	if (!string_length(locale_id)) then locale_id = LANG_DEFAULT;
	return locale_id;
}

function lang_save_id(_id) {
	ini_open(settings_ini_path());
	ini_write_string("Settings", "language", string(_id ?? LANG_DEFAULT));
	ini_close();
}

function lang_find_pack(_id) {
	lang_ensure();
	var packs = global.pls_lang.packs;
	for (var i = 0; i < array_length(packs); i++) {
		if (packs[i].id == _id) then return packs[i];
	};
	return undefined;
}

function lang_apply(_id) {
	lang_ensure();
	var wanted = string(_id ?? LANG_DEFAULT);
	var pack = lang_find_pack(wanted);
	if (!is_struct(pack)) then pack = lang_find_pack(LANG_DEFAULT);
	if (!is_struct(pack) && array_length(global.pls_lang.packs) > 0) then pack = global.pls_lang.packs[0];
	var en = lang_find_pack(LANG_DEFAULT);
	global.pls_lang.fallback = is_struct(en) ? en.objects : {};
	if (is_struct(pack)) {
		global.pls_lang.id = pack.id;
		global.pls_lang.objects = pack.objects;
	} else {
		global.pls_lang.id = LANG_DEFAULT;
		global.pls_lang.objects = global.pls_lang.fallback;
	};
}

function lang_refresh_ui() {
	if (instance_exists(oMenu_Windows)) {
		with (oMenu_Windows) {
			if (is_struct(btn_open)) then btn_open.label = lang("menu.openPackage");
			if (is_struct(btn_sample)) then btn_sample.label = lang("menu.loadSample");
			if (is_struct(btn_render)) then btn_render.label = lang("menu.renderPlaceholder");
			settings_menu_button_layout();
			window_set_caption(GAME_NAME + " - " + lang("common.menu"));
		};
	};
	if (instance_exists(oMenu_Android)) {
		with (oMenu_Android) {
			if (is_struct(btn_open)) then btn_open.label = lang("menu.openPackage");
			if (is_struct(btn_sample)) then btn_sample.label = lang("menu.loadSample");
			settings_menu_button_layout();
		};
	};
	if (instance_exists(oMenu_GX)) {
		with (oMenu_GX) {
			settings_menu_button_layout();
			window_set_caption(GAME_NAME + " - " + lang("common.menu"));
			if (!variable_instance_exists(id, "last_error") || !string_length(last_error)) {
				if (pls_is_gx_remote()) then status_text = lang("gx.statusClick");
				else if (variable_instance_exists(id, "api_online") && api_online) then status_text = lang("gx.statusClickOrApi");
				else status_text = lang("gx.statusClickApiOff");
			};
		};
	};
	if (instance_exists(oSettings)) {
		with (oSettings) settings_gui_layout();
	};
}

function lang_set(_id) {
	lang_ensure();
	lang_apply(_id);
	lang_save_id(global.pls_lang.id);
	lang_refresh_ui();
}

function lang_cycle(_dir) {
	lang_ensure();
	var packs = global.pls_lang.packs;
	var n = array_length(packs);
	if (n <= 0) then return;
	var idx = 0;
	var locale_id = lang_current_id();
	for (var i = 0; i < n; i++) {
		if (packs[i].id == locale_id) { idx = i; break; };
	};
	idx = (idx + _dir) mod n;
	if (idx < 0) then idx += n;
	lang_set(packs[idx].id);
}

function lang_init() {
	global.pls_lang = {
		id: LANG_DEFAULT,
		packs: [],
		objects: {},
		fallback: {}
	};
	var files = [];
	lang_collect_json(lang_dir(), files);
	var extras = [lang_dir() + "en-US.json", lang_dir() + "zh-CN.json"];
	for (var e = 0; e < array_length(extras); e++) {
		array_push(files, extras[e]);
	};
	var seen = {};
	var packs = [];
	for (var i = 0; i < array_length(files); i++) {
		var path = files[i];
		if (!is_string(path) || struct_exists(seen, path)) then continue;
		seen[$ path] = true;
		var pack = lang_try_load_file(path);
		if (!is_struct(pack)) then continue;
		if (struct_exists(seen, "id:" + pack.id)) then continue;
		seen[$ "id:" + pack.id] = true;
		array_push(packs, pack);
	};
	global.pls_lang.packs = packs;
	var saved = lang_saved_id();
	if (is_struct(lang_find_pack(saved))) then lang_apply(saved);
	else lang_apply(LANG_DEFAULT);
}

function lang_ensure() {
	if (!variable_global_exists("pls_lang") || !is_struct(global.pls_lang)) then lang_init();
	return global.pls_lang;
}
