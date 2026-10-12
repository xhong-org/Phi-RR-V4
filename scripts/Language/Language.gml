// 从 language/*.json 加载语言包，默认语言为 en-US。

#macro LANG_DEFAULT "en-US"

///@desc 返回语言包目录
///@returns {String} 以分隔符结尾的语言目录
function lang_dir() {
	return $"{working_directory}language/";
}

///@desc 把目录规范成以分隔符结尾的路径
///@param {String} _dir 目录，空则用语言目录
///@returns {String} 以 / 或 \ 结尾的目录
function lang_norm_dir(_dir) {
	var s = string(_dir ?? "");
	// 空路径回退到语言目录
	if (!string_length(s)) then return lang_dir();
	var last = string_char_at(s, string_length(s));
	// 缺少结尾分隔符时补上
	if (last != "/" && last != "\\") then s += "/";
	return s;
}

///@desc 按点分键在结构体里查找字符串
///@param {Struct} _root 语言对象树
///@param {String} _key 点分键，例如 menu.open
///@returns {String} 找到的文本，否则为 undefined
function lang_lookup(_root, _key) {
	if (!is_struct(_root) || !is_string(_key) || !string_length(_key)) then return undefined;
	var parts = string_split(_key, ".");
	var cur = _root;
	for (var i = 0; i < array_length(parts); i++) {
		// 中间层缺失则查找失败
		if (!is_struct(cur) || !struct_exists(cur, parts[i])) then return undefined;
		cur = cur[$ parts[i]];
	};
	// 只有字符串才是有效译文
	if (is_string(cur)) then return cur;
	return undefined;
}

///@desc 取当前语言的文本，并写入查找缓存
///@param {String} _key 点分键
///@param {String} _fallback 找不到时的后备文本，缺省用键名
///@returns {String} 译文或后备
function lang(_key, _fallback = undefined) {
	lang_ensure();
	if (!is_string(_key) || !string_length(_key)) {
		if (is_string(_fallback)) then return _fallback;
		return "";
	};
	if (!is_struct(global.pls_lang.lookup)) then global.pls_lang.lookup = {};
	// 命中缓存则不再查找
	if (struct_exists(global.pls_lang.lookup, _key)) then return global.pls_lang.lookup[$ _key];
	var v = lang_lookup(global.pls_lang.objects, _key);
	// 当前包没有时回退到默认语言
	if (!(is_string(v) && string_length(v))) then v = lang_lookup(global.pls_lang.fallback, _key);
	if (!(is_string(v) && string_length(v))) {
		v = is_string(_fallback) ? _fallback : _key;
	};
	global.pls_lang.lookup[$ _key] = v;
	return v;
}

///@desc 取译文并把 {0}、{1} 换成后续实参
///@param {String} _key 点分键
///@returns {String} 替换占位符后的文本
function langf(_key) {
	var s = lang(_key);
	for (var i = 1; i < argument_count; i++) {
		s = string_replace_all(s, "{" + string(i - 1) + "}", string(argument[i]));
	};
	return s;
}

///@desc 生成语言包显示名，并缓存结果
///@param {Struct} _pack 语言包
///@returns {String} 名称加版本，无效包为空串
function lang_pack_label(_pack) {
	if (!is_struct(_pack)) then return "";
	// 已有非空缓存则直接返回
	if (struct_exists(_pack, "label_cached")) {
		var cached = _pack[$ "label_cached"];
		if (is_string(cached) && string_length(cached)) then return cached;
	};
	var label = $"{string(_pack[$ "name"] ?? "")}(v{string(_pack[$ "version"] ?? "")})";
	_pack[$ "label_cached"] = label;
	return label;
}

///@desc 返回当前语言包 id
///@returns {String} 语言 id，缺省为默认语言
function lang_current_id() {
	lang_ensure();
	return string(global.pls_lang.id ?? LANG_DEFAULT);
}

///@desc 返回当前语言包的显示名
///@returns {String} 名称加版本
function lang_current_label() {
	lang_ensure();
	var packs = global.pls_lang.packs;
	var locale_id = lang_current_id();
	for (var i = 0; i < array_length(packs); i++) {
		// 找到当前 id 就用该包的显示名
		if (packs[i].id == locale_id) then return lang_pack_label(packs[i]);
	};
	return $"{locale_id}(v)";
}

///@desc 返回已扫描的语言包数组
///@returns {Array} 语言包列表
function lang_packs() {
	lang_ensure();
	return global.pls_lang.packs;
}

///@desc 递归收集目录下的 json 路径
///@param {String} _dir 起始目录
///@param {Array} _out 收集结果
///@returns {Undefined} 无
function lang_collect_json(_dir, _out) {
	_dir = lang_norm_dir(_dir);
	var found = "";
	try { found = file_find_first(_dir + "*.json", 0); } catch (find_err) { delete(find_err); found = ""; };
	while (is_string(found) && string_length(found)) {
		array_add(_out, _dir + found);
		try { found = file_find_next(); } catch (next_err) { delete(next_err); found = ""; };
	};
	// 先收当前层 json，再找子目录
	try { file_find_close(); } catch (close_err) { delete(close_err); };
	var sub = [];
	found = "";
	try { found = file_find_first(_dir + "*", fa_directory); } catch (dir_err) { delete(dir_err); found = ""; };
	while (is_string(found) && string_length(found)) {
		if (found != "." && found != ".." && directory_exists(_dir + found)) then array_add(sub, _dir + found);
		try { found = file_find_next(); } catch (dir_next) { delete(dir_next); found = ""; };
	};
	try { file_find_close(); } catch (dir_close) { delete(dir_close); };
	// 原生文件接口再补一遍目录列表
	if (chart_use_native_files()) {
		var listed = string(chart_native_list(_dir) ?? "");
		if (string_length(listed)) {
			var rows = string_split(string_replace_all(listed, "\r", "\n"), "\n");
			for (var r = 0; r < array_length(rows); r++) {
				var item = string_trim(rows[r]);
				if (!string_length(item)) then continue;
				var full = _dir + item;
				if (string_lower(filename_ext(item)) == ".json") then array_add(_out, full);
				else if (directory_exists(full) || chart_native_is_dir(full)) then array_add(sub, full);
			};
		};
	};
	// 子目录继续递归
	for (var s = 0; s < array_length(sub); s++) {
		lang_collect_json(sub[s], _out);
	};
}

///@desc 尝试把一个 json 读成语言包
///@param {String} _path 文件路径
///@returns {Struct} 语言包，失败为 undefined
function lang_try_load_file(_path) {
	if (!is_string(_path) || !string_length(_path)) then return undefined;
	if (!isExists(_path) && !file_exists(_path)) then return undefined;
	var text = chart_read_text_file(_path, -1);
	if (!is_string(text) || !string_length(text)) then return undefined;
	var data = undefined;
	try { data = json_parse(text); } catch (parse_err) { delete(parse_err); return undefined; };
	if (!is_struct(data)) then return undefined;
	var name = string(data[$ "name"] ?? "");
	// 没有名称的文件不当作语言包
	if (!string_length(name)) then return undefined;
	var objects = data[$ "objects"];
	if (!is_struct(objects)) then objects = {};
	var locale_id = filename_change_ext(filename_name(_path), "");
	// 文件名空则用包内名称当 id
	if (!string_length(locale_id)) then locale_id = name;
	return {
		id: locale_id,
		name: name,
		version: string(data[$ "version"] ?? ""),
		author: string(data[$ "author"] ?? ""),
		objects: objects,
		path: _path
	};
}

///@desc 从设置里读取上次保存的语言 id
///@returns {String} 语言 id，没有则用默认语言
function lang_saved_id() {
	var f = settings_ini_path();
	// 设置文件不存在时用默认语言
	if (!file_exists(f) && !isExists(f)) then return LANG_DEFAULT;
	ini_open(f);
	var locale_id = ini_read_string("Settings", "language", LANG_DEFAULT);
	ini_close();
	if (!string_length(locale_id)) then locale_id = LANG_DEFAULT;
	return locale_id;
}

///@desc 把语言 id 写入设置
///@param {String} _id 语言 id
///@returns {Undefined} 无
function lang_save_id(_id) {
	ini_open(settings_ini_path());
	ini_write_string("Settings", "language", string(_id ?? LANG_DEFAULT));
	ini_close();
}

///@desc 按 id 查找已加载的语言包
///@param {String} _id 语言 id
///@returns {Struct} 语言包，没有则为 undefined
function lang_find_pack(_id) {
	lang_ensure();
	var packs = global.pls_lang.packs;
	for (var i = 0; i < array_length(packs); i++) {
		if (packs[i].id == _id) then return packs[i];
	};
	return undefined;
}

///@desc 切换当前语言，并清空译文缓存
///@param {String} _id 目标语言 id
///@returns {Undefined} 无
function lang_apply(_id) {
	lang_ensure();
	var wanted = string(_id ?? LANG_DEFAULT);
	var pack = lang_find_pack(wanted);
	// 目标不存在时先试默认语言，再退到第一包
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
	// 换语言后查找缓存必须清空
	global.pls_lang.lookup = {};
	global.pls_lang.field_labels = {};
}

///@desc 若静态文本等于某个语言包里的旧译文，则换成当前语言
///@param {String} _text 界面上已有的文本
///@param {Array} _keys 候选点分键
///@returns {String} 当前译文或原文
function lang_retranslate_static(_text, _keys) {
	if (!is_string(_text) || !string_length(_text) || !is_array(_keys)) then return _text;
	lang_ensure();
	var packs = global.pls_lang.packs;
	if (!is_array(packs)) then return _text;
	for (var k = 0; k < array_length(_keys); k++) {
		var key = _keys[k];
		for (var i = 0; i < array_length(packs); i++) {
			var pack = packs[i];
			if (!is_struct(pack)) then continue;
			var v = lang_lookup(pack.objects, key);
			// 文本对上任一语言包的该键，就按当前语言重取
			if (is_string(v) && v == _text) then return lang(key);
		};
	};
	return _text;
}

///@desc 按当前语言重写菜单状态、详情与错误文本
///@returns {Undefined} 无
function lang_refresh_menu_status() {
	var status_keys = [
		"menu.statusSelect", "menu.cancelled", "menu.openFailed", "android.waitingPicker",
		"gx.statusClick", "gx.statusClickOrApi", "gx.statusClickApiOff", "gx.statusConnecting",
		"gx.fileProtocolStatus", "gx.downloadingUrl", "gx.openedBrowse", "gx.statusApiOffStillClick",
		"gx.statusPopup", "gx.statusReading", "gx.uploadFailed"
	];
	var detail_keys = [
		"menu.detailSupported", "menu.noFile", "android.pickDetail", "android.pickerUnavailable", "android.pickerFailed",
		"gx.detailRemote", "gx.detailApi", "gx.runServer", "gx.apiNoResponse"
	];
	var error_keys = [
		"menu.noFile", "android.pickerUnavailable", "android.pickerFailed",
		"gx.fileProtocol", "gx.notConnected", "gx.readFailed", "gx.writeFailed", "gx.notZip",
		"gx.urlFailed", "gx.downloadMissing"
	];
	if (variable_instance_exists(id, "status_text")) then status_text = lang_retranslate_static(status_text, status_keys);
	if (variable_instance_exists(id, "detail_text")) then detail_text = lang_retranslate_static(detail_text, detail_keys);
	if (variable_instance_exists(id, "last_error")) then last_error = lang_retranslate_static(last_error, error_keys);
	var picking_now = variable_instance_exists(id, "picking") && picking;
	var busy_now = variable_instance_exists(id, "busy") && busy;
	var has_error = variable_instance_exists(id, "last_error") && string_length(last_error);
	// 空闲且无错误时恢复各菜单的默认状态文案
	if (!picking_now && !busy_now && !has_error) {
		if (object_index == oMenu_GX) {
			// 远程、弹层、连接中、接口在线分别用不同文案
			if (pls_is_gx_remote()) {
				status_text = (variable_instance_exists(id, "drop_panel_open") && drop_panel_open) ? lang("gx.statusPopup") : lang("gx.statusClick");
				detail_text = lang("gx.detailRemote");
			} else if (variable_instance_exists(id, "drop_panel_open") && drop_panel_open) {
				status_text = lang("gx.statusPopup");
			} else if (variable_instance_exists(id, "health_id") && health_id >= 0) {
				status_text = lang("gx.statusConnecting");
				detail_text = lang("gx.detailApi");
			} else if (variable_instance_exists(id, "api_online") && api_online) {
				status_text = lang("gx.statusClickOrApi");
				detail_text = langf("gx.connected", gx_fs_api_base());
			} else {
				status_text = lang("gx.statusClickApiOff");
			};
		} else {
			status_text = lang("menu.statusSelect");
			detail_text = lang("menu.detailSupported");
		};
	};
}

///@desc 刷新已存在菜单与设置界面的语言文本
///@returns {Undefined} 无
function lang_refresh_ui() {
	if (instance_exists(oMenu_Windows)) {
		with (oMenu_Windows) {
			if (is_struct(btn_open)) then btn_open.label = lang("menu.openPackage");
			if (is_struct(btn_sample)) then btn_sample.label = lang("menu.loadSample");
			if (is_struct(btn_render)) then btn_render.label = lang("menu.renderPlaceholder");
			settings_menu_button_layout();
			window_set_caption(GAME_NAME + " - " + lang("common.menu"));
			lang_refresh_menu_status();
		};
	};
	if (instance_exists(oMenu_Android)) {
		with (oMenu_Android) {
			if (is_struct(btn_open)) then btn_open.label = lang("menu.openPackage");
			if (is_struct(btn_sample)) then btn_sample.label = lang("menu.loadSample");
			settings_menu_button_layout();
			lang_refresh_menu_status();
		};
	};
	if (instance_exists(oMenu_GX)) {
		with (oMenu_GX) {
			settings_menu_button_layout();
			window_set_caption(GAME_NAME + " - " + lang("common.menu"));
			lang_refresh_menu_status();
		};
	};
	if (instance_exists(oSettings)) {
		with (oSettings) settings_gui_layout();
	};
}

///@desc 应用语言、保存并刷新界面
///@param {String} _id 语言 id
///@returns {Undefined} 无
function lang_set(_id) {
	lang_ensure();
	lang_apply(_id);
	lang_save_id(global.pls_lang.id);
	lang_refresh_ui();
}

///@desc 按方向切换到相邻语言包
///@param {Real} _dir 步进，正数为下一个
///@returns {Undefined} 无
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
	// GML 的 mod 对负数仍可能为负
	if (idx < 0) then idx += n;
	lang_set(packs[idx].id);
}

///@desc 扫描语言目录并去重加载语言包
///@returns {Struct} packs、loaded、error、skipped
function lang_scan_packs() {
	var files = [];
	lang_collect_json(lang_dir(), files);
	var extras = [lang_dir() + "en-US.json", lang_dir() + "zh-CN.json"];
	for (var e = 0; e < array_length(extras); e++) {
		array_add(files, extras[e]);
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
		// 同一路径只读一次
		if (struct_exists(seen_path, path)) then continue;
		seen_path[$ path] = true;
		var pack = lang_try_load_file(path);
		if (!is_struct(pack)) {
			error_n += 1;
			continue;
		};
		// 相同 id 的后到文件跳过
		if (struct_exists(seen_id, "id:" + pack.id)) {
			skipped += 1;
			continue;
		};
		seen_id[$ "id:" + pack.id] = true;
		array_add(packs, pack);
		loaded += 1;
	};
	return { packs: packs, loaded: loaded, error: error_n, skipped: skipped };
}

///@desc 建立全局语言状态并应用已保存的语言
///@returns {Undefined} 无
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
	// 保存的 id 不在包列表里则用默认语言
	if (is_struct(lang_find_pack(saved))) then lang_apply(saved);
	else lang_apply(LANG_DEFAULT);
}

///@desc 重新扫描语言包并尽量保持当前语言
///@returns {Struct} 扫描统计
function lang_reload() {
	lang_ensure();
	var current = lang_current_id();
	var scan = lang_scan_packs();
	if (!is_struct(scan)) then scan = { packs: [], loaded: 0, error: 0, skipped: 0 };
	// 扫到包才替换列表，避免把界面语言清空
	if (is_array(scan.packs) && array_length(scan.packs) > 0) {
		global.pls_lang.packs = scan.packs;
		if (is_struct(lang_find_pack(current))) then lang_apply(current);
		else lang_apply(LANG_DEFAULT);
		lang_save_id(global.pls_lang.id);
		lang_refresh_ui();
	};
	return scan;
}

///@desc 保证全局语言状态已初始化
///@returns {Struct} global.pls_lang
function lang_ensure() {
	if (!variable_global_exists("pls_lang") || !is_struct(global.pls_lang)) then lang_init();
	return global.pls_lang;
}

///@desc 把嵌套语言对象摊成点分键列表
///@param {Struct} _root 当前层
///@param {String} _prefix 已有前缀
///@param {Array} _out 输出键名
///@returns {Undefined} 无
function lang_flatten_keys(_root, _prefix, _out) {
	if (!is_struct(_root) || !is_array(_out)) then return;
	var names = struct_get_names(_root);
	for (var n = 0; n < array_length(names); n++) {
		var field = names[n];
		var key = string_length(_prefix) ? $"{_prefix}.{field}" : field;
		var val = _root[$ field];
		// 子结构继续下钻，叶子才记入键名
		if (is_struct(val)) then lang_flatten_keys(val, key, _out);
		else array_add(_out, key);
	};
}

///@desc 返回启动时必须存在的语言键
///@returns {Array} 点分键列表
function lang_required_keys() {
	static keys = undefined;
	// 列表只构建一次
	if (is_array(keys)) then return keys;
	keys = [
		"common.ok", "common.on", "common.off", "common.close", "common.confirm", "common.warning",
		"common.settings", "common.cancel", "common.open", "common.menu", "common.loading",
		"menu.subtitle", "menu.openPackage", "menu.loadSample", "menu.renderPlaceholder",
		"menu.statusSelect", "menu.detailSupported", "menu.hintKeys", "menu.hintTap",
		"menu.toolsTitle", "menu.toolsExport", "menu.toolsExportPec", "menu.toolsExportRpeOfficial",
		"menu.toolsClose", "menu.toolsPick", "menu.toolsDone", "menu.toolsFail", "menu.toolsFailPec", "menu.toolsFailRpe",
		"menu.toolsNoPec", "menu.toolsNoRpe", "menu.toolsPecRead", "menu.toolsRpeRead", "menu.toolsConvert",
		"menu.toolsSaveTitle", "menu.toolsSaveZip", "menu.toolsSavePez",
		"menu.noFile", "menu.cancelled", "menu.openFailed", "menu.filterChart",
		"android.waitingPicker", "android.pickDetail", "android.pickerUnavailable", "android.pickerFailed",
		"gx.clickPick", "gx.browseApi", "gx.apiOffline", "gx.statusClick", "gx.statusClickOrApi",
		"gx.statusClickApiOff", "gx.statusConnecting", "gx.detailRemote", "gx.detailApi",
		"gx.hintRemote", "gx.hintApi", "gx.openedBrowse", "gx.notConnected", "gx.statusApiOffStillClick",
		"gx.statusPopup", "gx.statusReading", "gx.readFailed", "gx.uploadFailed", "gx.importing",
		"gx.writeFailed", "gx.notZip", "gx.fileProtocol", "gx.fileProtocolStatus", "gx.downloadingUrl",
		"gx.notFound", "gx.apiNoResponse", "gx.runServer", "gx.connected", "gx.urlFailed", "gx.downloadMissing",
		"settings.title", "settings.close", "settings.save", "settings.discardClose", "settings.normal", "settings.developer", "settings.clearData",
		"settings.reset", "settings.reloadLanguage",
		"settings.hintNormal", "settings.hintDeveloper", "settings.language", "settings.skin", "settings.hintSkin",
		"settings.groupDisplay", "settings.groupDebug", "settings.groupChart", "settings.groupDeprecated",
		"settings.developerWarning", "settings.cleared",
		"skin.default", "skin.add", "skin.delete", "skin.filter", "skin.importFailed", "skin.parseFailed",
		"skin.previewFailed", "skin.cantDeleteDefault", "skin.missingFile", "skin.invalidInfo", "skin.errorTitle",
		"fields.enableBlur", "fields.enableFPS", "fields.enableQuikyStart", "fields.enableCanvasZoom",
		"fields.enableSurface", "fields.enableNoteHightLight", "fields.enableChartGUI", "fields.enableLineJudge",
		"fields.showBG", "fields.enableHitEffect", "fields.refreshFPSCount", "fields.enableDebug",
		"fields.enableDisplayLineID", "fields.comboString", "fields.userName", "fields.enableVsync", "fields.aa_level",
		"fields.useOldFX", "fields.enableComboScore", "fields.enableAutoPlay", "fields.judgeOffset", "fields.enableAccJudgment",
		"fields.preventWindowMoveFreeze", "fields.enableRPEMulticore", "fields.rpeWorkerMinLines",
		"fields.rpeWorkerProfileFrames", "fields.noteUniformScale", "fields.notePreloadSeconds",
		"fields.disableChartShader", "fields.directGlslEs", "fields.disableChartVideo", "fields.enableNoiseAreaFine", "fields.reduceNoiseAreaWave", "fields.TEST1",
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
		"render.ffmpegMissingTitle", "render.ffmpegMissing", "render.recordSettlement",
		"video.title", "video.sample", "video.frame", "video.elapsed", "video.remaining", "video.finalizing",
		"loadAnim.chart", "loadAnim.illustration", "loadAnim.loading", "loadAnim.tipsFallback",
		"result.recorder", "result.maxCombo", "result.accuracy", "result.perfect", "result.good",
		"result.bad", "result.miss", "result.early", "result.late", "result.guest"
	];
	return keys;
}

///@desc 判断语言包是否含有非空译文
///@param {Struct} _pack 语言包
///@param {String} _key 点分键
///@returns {Bool} 有非空字符串时为真
function lang_pack_has_key(_pack, _key) {
	if (!is_struct(_pack)) then return false;
	var val = lang_lookup(_pack.objects, _key);
	return is_string(val) && string_length(val) > 0;
}

///@desc 检查语言包是否齐全且覆盖必需键
///@returns {String} 错误说明，通过时为空串
function lang_validate() {
	lang_ensure();
	var packs = global.pls_lang.packs;
	// 一个包都没有则无法继续
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
		// 任一语言包有该键即可
		if (!present) then array_add(missing, key);
	};
	if (array_length(missing) <= 0) then return "";
	var shown = min(12, array_length(missing));
	var list = "";
	for (var m = 0; m < shown; m++) {
		if (m > 0) then list += ", ";
		list += missing[m];
	};
	// 错误信息只列出前若干个缺失键
	if (array_length(missing) > shown) then list += ", ...";
	return "All language packs are missing required key(s): " + list + ".\nThe program will now close.";
}

///@desc 语言错误后结束程序
///@returns {Undefined} 无
function lang_fatal_quit() {
	game_end();
}

///@desc 显示语言致命错误并按平台退出或异步确认
///@param {String} _message 错误正文
///@returns {Undefined} 无
function lang_fatal(_message) {
	global.pls_lang_fatal = true;
	var title = "Language Error";
	var text = string(_message ?? "Language pack error.\nThe program will now close.");
	// 原生对话框可同步确认后立即退出
	if (i_wbox_native_ready()) {
		msgbox_error_sync(text, title, [msgbox_button("OK")], MSGBOX_BUTTON_ALIGN.RIGHT);
		lang_fatal_quit();
		return;
	};
	// GX 只能异步弹窗，确认回调里再退出
	if (pls_is_gxgames() && msgbox_gx_ready()) {
		msgbox_error_async(text, title, [msgbox_button("OK", lang_fatal_quit)], MSGBOX_BUTTON_ALIGN.RIGHT);
		return;
	};
	show_message_async(title + "\n\n" + text);
}

///@desc 启动时校验语言包，失败则进入致命错误
///@returns {Bool} 通过为真
function lang_boot_guard() {
	var err = lang_validate();
	if (!string_length(err)) then return true;
	lang_fatal(err);
	return false;
}
