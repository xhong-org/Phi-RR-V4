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
	if (!is_string(_key) || !string_length(_key)) {
		if (is_string(_fallback)) then return _fallback;
		return "";
	};
	if (!is_struct(global.pls_lang.lookup)) then global.pls_lang.lookup = {};
	if (struct_exists(global.pls_lang.lookup, _key)) then return global.pls_lang.lookup[$ _key];
	var v = lang_lookup(global.pls_lang.objects, _key);
	if (!(is_string(v) && string_length(v))) then v = lang_lookup(global.pls_lang.fallback, _key);
	if (!(is_string(v) && string_length(v))) {
		v = is_string(_fallback) ? _fallback : _key;
	};
	global.pls_lang.lookup[$ _key] = v;
	return v;
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
	if (struct_exists(_pack, "label_cached")) {
		var cached = _pack[$ "label_cached"];
		if (is_string(cached) && string_length(cached)) then return cached;
	};
	var label = $"{string(_pack[$ "name"] ?? "")}(v{string(_pack[$ "version"] ?? "")})";
	_pack[$ "label_cached"] = label;
	return label;
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
	global.pls_lang.lookup = {};
	global.pls_lang.field_labels = {};
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

function lang_scan_packs() {
	var files = [];
	lang_collect_json(lang_dir(), files);
	var extras = [lang_dir() + "en-US.json", lang_dir() + "zh-CN.json"];
	for (var e = 0; e < array_length(extras); e++) {
		array_push(files, extras[e]);
	};
	var seen_path = {};
	var seen_id = {};
	var packs = [];
	var loaded = 0;
	var error_n = 0;
	var skipped = 0;
	for (var i = 0; i < array_length(files); i++) {
		var path = files[i];
		if (!is_string(path) || !string_length(path)) then continue;
		if (struct_exists(seen_path, path)) then continue;
		seen_path[$ path] = true;
		var pack = lang_try_load_file(path);
		if (!is_struct(pack)) {
			error_n += 1;
			continue;
		};
		if (struct_exists(seen_id, "id:" + pack.id)) {
			skipped += 1;
			continue;
		};
		seen_id[$ "id:" + pack.id] = true;
		array_push(packs, pack);
		loaded += 1;
	};
	return { packs: packs, loaded: loaded, error: error_n, skipped: skipped };
}

function lang_init() {
	global.pls_lang = {
		id: LANG_DEFAULT,
		packs: [],
		objects: {},
		fallback: {},
		lookup: {},
		field_labels: {}
	};
	var scan = lang_scan_packs();
	global.pls_lang.packs = is_struct(scan) && is_array(scan.packs) ? scan.packs : [];
	var saved = lang_saved_id();
	if (is_struct(lang_find_pack(saved))) then lang_apply(saved);
	else lang_apply(LANG_DEFAULT);
}

function lang_reload() {
	lang_ensure();
	var current = lang_current_id();
	var scan = lang_scan_packs();
	if (!is_struct(scan)) then scan = { packs: [], loaded: 0, error: 0, skipped: 0 };
	if (is_array(scan.packs) && array_length(scan.packs) > 0) {
		global.pls_lang.packs = scan.packs;
		if (is_struct(lang_find_pack(current))) then lang_apply(current);
		else lang_apply(LANG_DEFAULT);
		lang_save_id(global.pls_lang.id);
		lang_refresh_ui();
	};
	return scan;
}

function lang_ensure() {
	if (!variable_global_exists("pls_lang") || !is_struct(global.pls_lang)) then lang_init();
	return global.pls_lang;
}

function lang_flatten_keys(_root, _prefix, _out) {
	if (!is_struct(_root) || !is_array(_out)) then return;
	var names = struct_get_names(_root);
	for (var n = 0; n < array_length(names); n++) {
		var field = names[n];
		var key = string_length(_prefix) ? $"{_prefix}.{field}" : field;
		var val = _root[$ field];
		if (is_struct(val)) then lang_flatten_keys(val, key, _out);
		else array_push(_out, key);
	};
}

function lang_required_keys() {
	static keys = undefined;
	if (is_array(keys)) then return keys;
	keys = [
		"common.ok", "common.on", "common.off", "common.close", "common.confirm", "common.warning",
		"common.settings", "common.cancel", "common.open", "common.menu", "common.loading",
		"menu.subtitle", "menu.openPackage", "menu.loadSample", "menu.renderPlaceholder",
		"menu.statusSelect", "menu.detailSupported", "menu.hintKeys", "menu.hintTap",
		"menu.noFile", "menu.cancelled", "menu.openFailed", "menu.filterChart",
		"android.waitingPicker", "android.pickDetail", "android.pickerUnavailable", "android.pickerFailed",
		"gx.clickPick", "gx.browseApi", "gx.apiOffline", "gx.statusClick", "gx.statusClickOrApi",
		"gx.statusClickApiOff", "gx.statusConnecting", "gx.detailRemote", "gx.detailApi",
		"gx.hintRemote", "gx.hintApi", "gx.openedBrowse", "gx.notConnected", "gx.statusApiOffStillClick",
		"gx.statusPopup", "gx.statusReading", "gx.readFailed", "gx.uploadFailed", "gx.importing",
		"gx.writeFailed", "gx.notZip", "gx.fileProtocol", "gx.fileProtocolStatus", "gx.downloadingUrl",
		"gx.notFound", "gx.apiNoResponse", "gx.runServer", "gx.connected", "gx.urlFailed", "gx.downloadMissing",
		"settings.title", "settings.close", "settings.normal", "settings.developer", "settings.clearData",
		"settings.reset", "settings.reloadLanguage",
		"settings.hintNormal", "settings.hintDeveloper", "settings.language", "settings.skin", "settings.hintSkin",
		"settings.developerWarning", "settings.cleared",
		"skin.default", "skin.add", "skin.delete", "skin.filter", "skin.importFailed", "skin.parseFailed",
		"skin.previewFailed", "skin.cantDeleteDefault", "skin.missingFile", "skin.invalidInfo", "skin.errorTitle",
		"fields.enableBlur", "fields.enableFPS", "fields.enableQuikyStart", "fields.enableCanvasZoom",
		"fields.enableSurface", "fields.enableNoteHightLight", "fields.enableChartGUI", "fields.enableLineJudge",
		"fields.showBG", "fields.enableHitEffect", "fields.refreshFPSCount", "fields.enableDebug",
		"fields.enableDisplayLineID", "fields.comboString", "fields.enableVsync", "fields.aa_level",
		"fields.useOldFX", "fields.enableComboScore", "fields.judgeOffset", "fields.enableAccJudgment",
		"fields.preventWindowMoveFreeze", "fields.enableRPEMulticore", "fields.rpeWorkerMinLines",
		"fields.rpeWorkerProfileFrames", "fields.noteUniformScale", "fields.notePreloadSeconds", "fields.TEST1",
		"loading.title", "loading.preparing", "loading.noSource", "loading.backToMenu", "loading.queued",
		"loading.resolving", "loading.sample", "loading.extracting", "loading.scanning", "loading.failed",
		"loading.unsupportedChart", "loading.formatDetected", "loading.preparingRoom", "loading.unsupportedFormat",
		"loading.defaultResources", "loading.hitSounds", "loading.entering", "loading.returning",
		"loading.statusPrefix", "loading.extractingPackage", "loading.unicodeExtract", "loading.extractFailed",
		"loading.loaderTitle",
		"picker.statusBrowse", "picker.up", "picker.back", "picker.fwd", "picker.cancel", "picker.open",
		"picker.useFolder", "picker.empty", "picker.dirPrefix", "picker.listing", "picker.unpacking",
		"picker.downloading", "picker.searching", "picker.pasted", "picker.listFailed", "picker.connecting",
		"picker.importedFiles", "picker.copying", "picker.itemsCount", "picker.downloadCancelled",
		"picker.imported", "picker.downloaded", "picker.downloadProgress", "picker.downloadBytes", "picker.gameFiles",
		"render.title", "render.hint", "render.chartPath", "render.videoOutput", "render.fps", "render.quality",
		"render.aspect", "render.browse", "render.saveAs", "render.resolution", "render.aa", "render.presetRatio",
		"render.start", "render.fpsNumeric", "render.aspectFormat", "render.copied", "render.copyUnavailable",
		"render.pasted", "render.pasteUnavailable", "render.cleared", "render.chartRequired", "render.fpsRange",
		"render.qualityRange", "render.aspectPositive", "render.outputMissing", "render.chartMissing",
		"render.ffmpegMissingTitle", "render.ffmpegMissing",
		"video.title", "video.sample", "video.frame", "video.elapsed", "video.remaining", "video.finalizing",
		"loadAnim.chart", "loadAnim.illustration", "loadAnim.loading", "loadAnim.tipsFallback"
	];
	return keys;
}

function lang_pack_has_key(_pack, _key) {
	if (!is_struct(_pack)) then return false;
	var val = lang_lookup(_pack.objects, _key);
	return is_string(val) && string_length(val) > 0;
}

function lang_validate() {
	lang_ensure();
	var packs = global.pls_lang.packs;
	if (!is_array(packs) || array_length(packs) <= 0) {
		return "No language packs were found in the language folder.\nThe program will now close.";
	};
	var required = lang_required_keys();
	var missing = [];
	for (var k = 0; k < array_length(required); k++) {
		var key = required[k];
		var present = false;
		for (var p = 0; p < array_length(packs); p++) {
			if (lang_pack_has_key(packs[p], key)) { present = true; break; };
		};
		if (!present) then array_push(missing, key);
	};
	if (array_length(missing) <= 0) then return "";
	var shown = min(12, array_length(missing));
	var list = "";
	for (var m = 0; m < shown; m++) {
		if (m > 0) then list += ", ";
		list += missing[m];
	};
	if (array_length(missing) > shown) then list += ", ...";
	return "All language packs are missing required key(s): " + list + ".\nThe program will now close.";
}

function lang_fatal_quit() {
	game_end();
}

function lang_fatal(_message) {
	global.pls_lang_fatal = true;
	var title = "Language Error";
	var text = string(_message ?? "Language pack error.\nThe program will now close.");
	if (i_wbox_native_ready()) {
		msgbox_error_sync(text, title, [msgbox_button("OK")], MSGBOX_BUTTON_ALIGN.RIGHT);
		lang_fatal_quit();
		return;
	};
	if (pls_is_gxgames() && msgbox_gx_ready()) {
		msgbox_error_async(text, title, [msgbox_button("OK", lang_fatal_quit)], MSGBOX_BUTTON_ALIGN.RIGHT);
		return;
	};
	show_message_async(title + "\n\n" + text);
}

function lang_boot_guard() {
	var err = lang_validate();
	if (!string_length(err)) then return true;
	lang_fatal(err);
	return false;
}
