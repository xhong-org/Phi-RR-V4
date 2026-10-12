/// @description Phigros().settings 设置界面。普通列表是注释里不含已废弃或已弃用的项。

///@desc 返回设置 ini 的路径
///@returns {String} configs.ini 路径
function settings_ini_path() {
	return $"{working_directory}resource/configs.ini";
}

///@desc 判断字段注释是否标成已废弃或已弃用
///@param {String} _comment 字段注释
///@returns {Bool} 是否废弃
function settings_comment_is_deprecated(_comment) {
	var s = string(_comment ?? "");
	// 注释里出现任一标记即视为废弃
	return (string_pos("已废弃", s) > 0) || (string_pos("已弃用", s) > 0);
}

///@desc 从字段注释里去掉废弃标记和默认值，留下显示名
///@param {String} _comment 字段注释
///@returns {String} 修剪后的标签
function settings_comment_label(_comment) {
	var s = string(_comment ?? "");
	s = string_replace_all(s, "(已弃用)", "");
	s = string_replace_all(s, "(已废弃)", "");
	// 从默认值标记处截断
	var p = string_pos("(default:", s);
	if (p > 0) then s = string_copy(s, 1, p - 1);
	return string_trim(s);
}

///@desc 返回设置项目录，注释来自 Phigros.settings，含已废弃或已弃用则算废弃
///@returns {Array} 键与注释列表
function settings_catalog() {
	static cat = undefined;
	// 静态目录只建一次
	if (!is_undefined(cat)) then return cat;
	cat = [
		{ key:"enableBlur", comment:"是否启用背景模糊(default:true)" },
		{ key:"enableFPS", comment:"是否显示FPS(default:true)" },
		{ key:"enableQuikyStart", comment:"是否启用快速启动(已弃用)(default:true)" },
		{ key:"enableCanvasZoom", comment:"是否启用摄像头缩放(已弃用)(default:false)" },
		{ key:"enableSurface", comment:"是否启用遮罩(default:true)" },
		{ key:"enableNoteHightLight", comment:"是否启用音符多押高亮(default:true)" },
		{ key:"enableChartGUI", comment:"是否启用UI(default:true)" },
		{ key:"enableLineJudge", comment:"是否启用FC/AP指示器(default:true)" },
		{ key:"showBG", comment:"是否显示背景(default:true)" },
		{ key:"enableHitEffect", comment:"是否显示打击特效(default:true)" },
		{ key:"refreshFPSCount", comment:"刷新FPS计量次数(default:60)" },
		{ key:"enableDebug", comment:"是否启用Debug(default:true)" },
		{ key:"enableDisplayLineID", comment:"是否显示线ID(已弃用)(default:false)" },
		{ key:"comboString", comment:"combo text(default:\"COMBO\")" },
		{ key:"userName", comment:"player name(default:\"Guest\")" },
		{ key:"enableVsync", comment:"是否启用垂直同步(default:true)" },
		{ key:"aa_level", comment:"aa_level等级(default:0)" },
		{ key:"useOldFX", comment:"是否使用旧版打击特效(default:false)" },
		{ key:"enableComboScore", comment:"是否启用打击分(default:true)" },
		{ key:"enableAutoPlay", comment:"是否启用自动游玩(default:true)" },
		{ key:"judgeOffset", comment:"自动打击偏移延迟(default:0)" },
		{ key:"enableAccJudgment", comment:"是否启用Auto严肃判定(可能对其他格式的谱面无效)(default:true)" },
		{ key:"preventWindowMoveFreeze", comment:"use non-blocking Windows moving and resizing" },
		{ key:"enableRPEMulticore", comment:"enable native RPE frame workers" },
		{ key:"rpeWorkerMinLines", comment:"minimum line count for native parallel resolve" },
		{ key:"rpeWorkerProfileFrames", comment:"frames averaged between worker timing logs" },
		{ key:"noteUniformScale", comment:"RPE note size/sizeControl also scale height" },
		{ key:"notePreloadSeconds", comment:"RPE/PEC note preload seconds (0-60). Official ignores this." },
		{ key:"disableChartShader", comment:"禁用谱面 Shader(default:false)" },
		{ key:"directGlslEs", comment:"Windows 直接编译 GLSL ES，不经 HLSL 翻译(default:false)" },
		{ key:"disableChartVideo", comment:"禁用谱面视频(default:false)" },
		{ key:"enableNoiseArea", comment:"是否启用噪区(default:true)" },
		{ key:"enableNoiseAreaFine", comment:"是否开启噪区精细(default:false)" },
		{ key:"reduceNoiseAreaWave", comment:"减少噪区起伏幅度(default:false)" },
		{ key:"TEST1", comment:"judge offset jitter test (default false)" }
	];
	return cat;
}

///@desc 创建设置界面用的光栅字体
///@returns {Real} 字体资源
function settings_ui_font() {
	// 设置面板缩放小于 1 时，部分 GPU 上 SDF 会看不见，光栅字体仍可读。
	return pls_ui_font_add(24, false, false, 32, 65535, false);
}

///@desc 求能把文字放进盒子的最大统一缩放，调用前须已设置字体
///@param {String} _text 文本
///@param {Real} _max_w 最大宽度
///@param {Real} _max_h 最大高度
///@returns {Real} 缩放系数，空文本为 1
function settings_fit_text_scale(_text, _max_w, _max_h) {
	var label = string(_text ?? "");
	// 空文本不缩放；宽高至少按 1，避免除零
	if (!string_length(label)) then return 1;
	var gw = string_width(label);
	var gh = string_height(label);
	if (gw < 1) then gw = 1;
	if (gh < 1) then gh = 1;
	return max(0.05, min(max(1, _max_w) / gw, max(1, _max_h) / gh));
}

///@desc 返回应用 configs.ini 之前的 Phigros.settings 默认值
///@returns {Struct} 默认设置，基线无效时为空结构
function settings_defaults() {
	// 基线不存在时新建一次 Phigros 来生成它
	if (!variable_global_exists("phigros_settings_baseline") || !is_struct(global.phigros_settings_baseline)) {
		var _probe = new Phigros();
		delete _probe;
	};
	if (!variable_global_exists("phigros_settings_baseline") || !is_struct(global.phigros_settings_baseline)) {
		// 探测后仍没有基线则返回空结构
		return {};
	};
	return global.phigros_settings_baseline;
}

///@desc 浅拷贝结构体的一层字段
///@param {Struct} _src 源结构
///@returns {Struct} 新结构，源无效时为空
function settings_clone(_src) {
	var out = {};
	// 源不是结构则返回空拷贝
	if (!is_struct(_src)) then return out;
	var names = struct_get_names(_src);
	for (var i = 0; i < array_length(names); i++) {
		out[$ names[i]] = _src[$ names[i]];
	};
	return out;
}

///@desc 读取当前对局设置里的布尔项
///@param {String} _key 设置键
///@returns {Bool} 是否开启，没有对局时为假
function chart_setting_on(_key) {
	// 没有对局设置时视为关闭
	if (!variable_global_exists("game") || !is_struct(game) || !is_struct(game.settings)) then return false;
	return bool(game.settings[$ _key] ?? false);
}

///@desc 按默认值判断设置项是字符串、布尔还是数字
///@param {String} _key 设置键
///@returns {String} string、bool 或 number
function settings_kind(_key) {
	var d = settings_defaults();
	// 默认值里没有该键时当作数字
	if (!struct_exists(d, _key)) then return "number";
	var v = d[$ _key];
	if (is_string(v)) then return "string";
	if (is_bool(v)) then return "bool";
	return "number";
}

///@desc 把 ini 文本解析成布尔或数字
///@param {String} _str 原始文本
///@param {Any} _default 解析失败时的默认值
///@returns {Any} 0、1、数值或默认值
function settings_parse_value(_str, _default) {
	if (is_undefined(_str)) then return _default;
	var s = string_lower(string(_str));
	// true 和 false 变成 1 和 0，非数字退回默认值
	if (s == "false") then return 0;
	if (s == "true") then return 1;
	if (s == "undefined") then return _default;
	try { return real(_str); }
	catch (e) { delete(e); return _default; };
}

///@desc 把设置值格式化成写入 ini 的字符串
///@param {String} _key 设置键
///@param {Any} _value 当前值
///@returns {String} ini 文本
function settings_format_ini(_key, _value) {
	// 布尔写成 true 或 false，其余转成字符串
	if (settings_kind(_key) == "bool") then return (bool(_value) ? "true" : "false");
	if (is_string(_value)) then return _value;
	return string(_value);
}

///@desc 把存储里的数值项钳到允许范围
///@param {Struct} _store 设置存储
///@returns {Undefined} 无
function settings_clamp_store(_store) {
	if (!is_struct(_store)) then return;
	// 只钳制存在的键，帧数和抗锯齿取整
	if (struct_exists(_store, "refreshFPSCount")) then _store.refreshFPSCount = clamp(real(_store.refreshFPSCount), 1, 300);
	if (struct_exists(_store, "notePreloadSeconds")) then _store.notePreloadSeconds = clamp(real(_store.notePreloadSeconds), 0, 60);
	if (struct_exists(_store, "rpeWorkerMinLines")) then _store.rpeWorkerMinLines = clamp(floor(real(_store.rpeWorkerMinLines)), 1, 1024);
	if (struct_exists(_store, "rpeWorkerProfileFrames")) then _store.rpeWorkerProfileFrames = clamp(floor(real(_store.rpeWorkerProfileFrames)), 60, 36000);
	if (struct_exists(_store, "aa_level")) then _store.aa_level = clamp(floor(real(_store.aa_level)), 0, 8);
	if (struct_exists(_store, "judgeOffset")) then _store.judgeOffset = clamp(real(_store.judgeOffset), -5000, 5000);
}

///@desc 判断该键是否应忽略；随包的 configs.ini 只有少量键，不算用户存档
///@param {String} _key 设置键
///@returns {Bool} 为真表示不要从 ini 读入
function settings_saved_key_ignored(_key) {
	// 没有 Settings 段，或缺少界面才会写的键，则整段视为旧档
	if (!ini_section_exists("Settings")) then return true;
	var legacy = !ini_key_exists("Settings", "userName")
		&& !ini_key_exists("Settings", "aa_level")
		&& !ini_key_exists("Settings", "comboString");
	if (legacy) then return true;
	return !ini_key_exists("Settings", _key);
}

///@desc 把 ini 里的有效键读入存储并钳制
///@param {Struct} _store 设置存储
///@returns {Undefined} 无
function settings_load_into(_store) {
	if (!is_struct(_store)) then return;
	var f = settings_ini_path();
	ini_open(f);
	var names = struct_get_names(_store);
	for (var i = 0; i < array_length(names); i++) {
		var key = names[i];
		// 被忽略的键不从 ini 覆盖
		if (settings_saved_key_ignored(key)) then continue;
		var cur = _store[$ key];
		// 字符串原样读，其他键再解析成数值
		if (settings_kind(key) == "string") {
			_store[$ key] = ini_read_string("Settings", key, string(cur ?? ""));
		} else {
			_store[$ key] = settings_parse_value(ini_read_string("Settings", key, string(cur)), cur);
		};
	};
	ini_close();
	settings_clamp_store(_store);
}

///@desc 把存储和当前语言写回 ini
///@param {Struct} _store 设置存储
///@returns {Undefined} 无
function settings_save_store(_store) {
	if (!is_struct(_store)) then return;
	settings_clamp_store(_store);
	ini_open(settings_ini_path());
	var names = struct_get_names(_store);
	for (var i = 0; i < array_length(names); i++) {
		var key = names[i];
		ini_write_string("Settings", key, settings_format_ini(key, _store[$ key]));
	};
	// 语言不在设置结构里，单独写入
	ini_write_string("Settings", "language", lang_current_id());
	ini_close();
}

///@desc 返回对局设置，否则返回已加载的全局设置
///@returns {Struct} 设置结构
function settings_store() {
	// 对局进行中优先用 game.settings
	if (variable_global_exists("game") && is_struct(game) && is_struct(game.settings)) {
		return game.settings;
	};
	if (!variable_global_exists("pls_settings") || !is_struct(global.pls_settings)) {
		// 还没有全局副本时从默认值克隆并读 ini
		global.pls_settings = settings_clone(settings_defaults());
		settings_load_into(global.pls_settings);
	};
	return global.pls_settings;
}

///@desc 把抗锯齿和垂直同步立刻应用到显示
///@param {Any} _key 刚改的键，省略表示全部相关项
///@returns {Undefined} 无
function settings_apply_live(_key) {
	var s = settings_store();
	// 只在改这两项或未指定键时刷新显示
	if (_key == "aa_level" || _key == "enableVsync" || is_undefined(_key)) {
		display_custom(real(s.aa_level ?? 8), bool(s.enableVsync ?? true));
	};
}

///@desc 修改一项设置、钳制、保存并尝试立即生效
///@param {String} _key 设置键
///@param {Any} _value 新值
///@returns {Undefined} 无
function settings_set(_key, _value) {
	var s = settings_store();
	// 布尔项先归一化再写入
	if (settings_kind(_key) == "bool") then _value = bool(_value);
	s[$ _key] = _value;
	settings_clamp_store(s);
	settings_save_store(s);
	settings_apply_live(_key);
}

///@desc 删除设置文件并恢复默认后再保存
///@returns {Undefined} 无
function settings_clear_data() {
	var f = settings_ini_path();
	try {
		// 普通删除失败时再试原生文件删除
		if (file_exists(f)) then file_delete(f);
		else if (chart_use_native_files() && chart_native_exists(f)) then chart_native_delete(f);
	} catch (del_err) { delete(del_err); };
	var fresh = settings_clone(settings_defaults());
	// 对局内则把默认值写回 game.settings
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

///@desc 不删文件，把内存和存档都恢复成默认值
///@returns {Undefined} 无
function settings_reset_defaults() {
	var fresh = settings_clone(settings_defaults());
	// 对局内同步写回 game.settings，再保存
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

///@desc 弹出确认框，同意后重置设置
///@returns {Undefined} 无
function settings_confirm_reset() {
	var buttons = [
		msgbox_button("Yes", settings_gui_reset_and_sync),
		msgbox_button("No")
	];
	msgbox_warning_async("Do you want to reset settings?", "Warning", buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
}

///@desc 返回普通或废弃设置项列表
///@param {Bool} _deprecated 为真时返回废弃列表
///@returns {Array} 设置项目数组
function settings_list(_deprecated) {
	static lists = undefined;
	// 普通和废弃两份列表只建一次
	if (!is_array(lists)) {
		lists = [[], []];
		var cat = settings_catalog();
		var seen = {};
		for (var i = 0; i < array_length(cat); i++) {
			var item = cat[i];
			seen[$ item.key] = true;
			array_add(lists[settings_comment_is_deprecated(item.comment) ? 1 : 0], item);
		};
		var store = settings_store();
		var names = struct_get_names(store);
		for (var n = 0; n < array_length(names); n++) {
			// 目录里没有、且不是 language 或 skinId 的键补进普通列表
			if (struct_exists(seen, names[n])) then continue;
			if (names[n] == "language" || names[n] == "skinId") then continue;
			array_add(lists[0], { key:names[n], comment:names[n] });
		};
	};
	return lists[_deprecated ? 1 : 0];
}

///@desc 返回常规页可折叠分组，废弃键是旧的开发者列表
///@returns {Array} 分组定义
function settings_group_defs() {
	static groups = [
		{ id:"display", keys:["enableBlur", "enableSurface", "enableLineJudge", "showBG", "enableHitEffect", "enableNoteHightLight", "enableChartGUI", "aa_level", "useOldFX", "enableVsync"] },
		{ id:"debug", keys:["enableFPS", "refreshFPSCount", "enableDebug", "preventWindowMoveFreeze", "enableRPEMulticore", "rpeWorkerMinLines", "rpeWorkerProfileFrames", "TEST1"] },
		{ id:"chart", keys:["comboString", "userName", "enableAutoPlay", "enableComboScore", "judgeOffset", "enableAccJudgment", "notePreloadSeconds", "noteUniformScale", "disableChartShader", "directGlslEs", "disableChartVideo", "enableNoiseArea", "enableNoiseAreaFine", "reduceNoiseAreaWave"] },
		{ id:"deprecated", keys:["enableQuikyStart", "enableCanvasZoom", "enableDisplayLineID"] }
	];
	return groups;
}

///@desc 返回分组的本地化标题
///@param {String} _id 分组 id
///@returns {String} 标题，未知 id 则原样返回
function settings_group_title(_id) {
	// 未知分组 id 原样返回
	switch (_id) {
		case "display": return lang("settings.groupDisplay", "Display");
		case "debug": return lang("settings.groupDebug", "Debug");
		case "chart": return lang("settings.groupChart", "Chart");
		case "deprecated": return lang("settings.groupDeprecated", "Deprecated");
	};
	return string(_id);
}

///@desc 按键建立设置目录索引
///@returns {Struct} 键到目录项的映射
function settings_catalog_index() {
	static index = undefined;
	// 索引只建一次
	if (is_struct(index)) then return index;
	index = {};
	var cat = settings_catalog();
	for (var i = 0; i < array_length(cat); i++) {
		index[$ cat[i].key] = cat[i];
	};
	return index;
}

///@desc 把目录和默认值里的键分进各个分组
///@returns {Struct} 分组 id 到键数组
function settings_grouped_keys() {
	static built = undefined;
	// 分组结果只算一次
	if (is_struct(built)) then return built;
	var groups = settings_group_defs();
	var explicit = {};
	built = {};
	for (var g = 0; g < array_length(groups); g++) {
		var keys = [];
		var src = groups[g].keys;
		for (var k = 0; k < array_length(src); k++) {
			array_add(keys, src[k]);
			explicit[$ src[k]] = true;
		};
		built[$ groups[g].id] = keys;
	};
	var cat = settings_catalog();
	for (var i = 0; i < array_length(cat); i++) {
		var key = cat[i].key;
		// 目录中多出的键，废弃的进 deprecated，其余进 chart
		if (struct_exists(explicit, key)) then continue;
		var bucket = settings_comment_is_deprecated(cat[i].comment) ? "deprecated" : "chart";
		array_add(built[$ bucket], key);
		explicit[$ key] = true;
	};
	var defaults = settings_defaults();
	var names = struct_get_names(defaults);
	for (var n = 0; n < array_length(names); n++) {
		var extra = names[n];
		// language 和 skinId 不进分组
		if (struct_exists(explicit, extra) || extra == "language" || extra == "skinId") then continue;
		array_add(built[$ "chart"], extra);
	};
	return built;
}

///@desc 取得或初始化各分组的展开状态
///@returns {Struct} 分组开关
function settings_gui_group_state() {
	// 首次使用时四个分组都收起
	if (!variable_instance_exists(id, "group_open") || !is_struct(group_open)) {
		group_open = { display:false, debug:false, chart:false, deprecated:false };
	};
	return group_open;
}

///@desc 把四个分组的展开状态拼成签名
///@returns {String} 用于判断折叠是否变化
function settings_gui_fold_sig() {
	var state = settings_gui_group_state();
	return string(bool(state[$ "display"])) + string(bool(state[$ "debug"])) + string(bool(state[$ "chart"])) + string(bool(state[$ "deprecated"]));
}

///@desc 按展开状态生成当前可见的分组和字段行
///@returns {Array} 行描述
function settings_gui_visible_rows() {
	var index = settings_catalog_index();
	var grouped = settings_grouped_keys();
	var state = settings_gui_group_state();
	var groups = settings_group_defs();
	var rows = [];
	for (var g = 0; g < array_length(groups); g++) {
		var group_id = groups[g].id;
		array_add(rows, { type:"group", id:group_id });
		// 分组收起时不加入其字段
		if (!bool(state[$ group_id])) then continue;
		var keys = grouped[$ group_id];
		if (!is_array(keys)) then continue;
		for (var k = 0; k < array_length(keys); k++) {
			var item = index[$ keys[k]];
			if (!is_struct(item)) then item = { key:keys[k], comment:keys[k] };
			array_add(rows, { type:"field", item:item });
		};
	};
	return rows;
}

///@desc 取得界面草稿，没有则从当前设置克隆
///@returns {Struct} 未保存的草稿
function settings_gui_draft() {
	// 没有草稿时从当前设置克隆一份
	if (!variable_instance_exists(id, "draft") || !is_struct(draft)) {
		draft = settings_clone(settings_store());
		draft_saved = settings_clone(draft);
	};
	return draft;
}

///@desc 写入草稿中的一项并钳制数值
///@param {String} _key 设置键
///@param {Any} _value 新值
///@returns {Undefined} 无
function settings_gui_draft_set(_key, _value) {
	var editing = settings_gui_draft();
	// 布尔项先归一化再写入草稿
	if (settings_kind(_key) == "bool") then _value = bool(_value);
	editing[$ _key] = _value;
	settings_clamp_store(editing);
}

///@desc 按设置类型比较两个值是否相同
///@param {String} _key 设置键
///@param {Any} _a 左值
///@param {Any} _b 右值
///@returns {Bool} 是否相等
function settings_values_equal(_key, _a, _b) {
	var kind = settings_kind(_key);
	// 布尔和字符串各自规范化，数字直接比
	if (kind == "bool") then return bool(_a ?? false) == bool(_b ?? false);
	if (kind == "string") then return string(_a ?? "") == string(_b ?? "");
	if (is_real(_a) && is_real(_b)) then return _a == _b;
	return string(_a ?? "") == string(_b ?? "");
}

///@desc 检查废弃项相对已保存草稿是否有改动
///@returns {Bool} 是否有未保存的废弃项改动
function settings_gui_deprecated_dirty() {
	var editing = settings_gui_draft();
	var saved = variable_instance_exists(id, "draft_saved") ? draft_saved : undefined;
	if (!is_struct(saved)) then return false;
	var keys = settings_grouped_keys()[$ "deprecated"];
	if (!is_array(keys)) then return false;
	for (var i = 0; i < array_length(keys); i++) {
		var key = keys[i];
		// 任一废弃键不同即视为有改动
		if (!settings_values_equal(key, editing[$ key], saved[$ key])) then return true;
	};
	return false;
}

///@desc 把草稿写入设置存储并保存，可跳过废弃项
///@param {Bool} _include_deprecated 是否包含废弃项
///@returns {Undefined} 无
function settings_gui_commit_to_store(_include_deprecated) {
	var editing = settings_gui_draft();
	var saved = is_struct(draft_saved) ? draft_saved : settings_clone(settings_store());
	var dest = settings_store();
	var skip = {};
	// 不包含废弃项时，用已保存值盖回这些键
	if (!_include_deprecated) {
		var deprecated_keys = settings_grouped_keys()[$ "deprecated"];
		if (is_array(deprecated_keys)) {
			for (var d = 0; d < array_length(deprecated_keys); d++) skip[$ deprecated_keys[d]] = true;
		};
	};
	var names = struct_get_names(editing);
	for (var i = 0; i < array_length(names); i++) {
		var key = names[i];
		var value = editing[$ key];
		// 跳过的键不采用草稿里的新值
		if (struct_exists(skip, key)) {
			value = struct_exists(saved, key) ? saved[$ key] : dest[$ key];
			editing[$ key] = value;
		};
		dest[$ key] = value;
	};
	settings_clamp_store(dest);
	settings_clamp_store(editing);
	try {
		settings_save_store(dest);
	} catch (save_err) {
		// 保存失败只丢掉异常，界面仍关闭
		delete(save_err);
	};
	try {
		settings_apply_live(undefined);
	} catch (apply_err) {
		delete(apply_err);
	};
	draft_saved = settings_clone(dest);
	settings_gui_close();
}

///@desc 用当前存储重设设置界面的草稿
///@returns {Undefined} 无
function settings_gui_sync_draft() {
	// 设置界面不存在则不用同步
	if (!instance_exists(oSettings)) then return;
	with (oSettings) {
		draft = settings_clone(settings_store());
		draft_saved = settings_clone(draft);
	};
}

///@desc 恢复默认设置并同步界面草稿
///@returns {Undefined} 无
function settings_gui_reset_and_sync() {
	settings_reset_defaults();
	settings_gui_sync_draft();
}

///@desc 确认后连废弃项一起保存
///@returns {Undefined} 无
function settings_gui_save_yes() {
	if (!instance_exists(oSettings)) then return;
	with (oSettings) settings_gui_commit_to_store(true);
}

///@desc 只保存非废弃项
///@returns {Undefined} 无
function settings_gui_save_normal_only() {
	if (!instance_exists(oSettings)) then return;
	with (oSettings) settings_gui_commit_to_store(false);
}

///@desc 返回保存废弃项时的警告文案
///@returns {String} 警告文本
function settings_deprecated_save_warning_text() {
	return "The settings you changed include deprecated options. Saving may cause Phi-RR to crash. Are you sure you want to save?";
}

///@desc 提交正在编辑的字段，废弃项有改动时先警告
///@returns {Undefined} 无
function settings_gui_request_save() {
	settings_gui_commit_edit();
	// 没有废弃项改动则直接保存
	if (!settings_gui_deprecated_dirty()) {
		settings_gui_commit_to_store(true);
		return;
	};
	var buttons = [
		msgbox_button("Yes", settings_gui_save_yes),
		msgbox_button("Cancel"),
		msgbox_button("Only normal", settings_gui_save_normal_only)
	];
	var msg = settings_deprecated_save_warning_text();
	// 原生对话框可用时用同步警告
	if (i_wbox_native_ready()) {
		msgbox_warning_sync(msg, "Warning", buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
	} else {
		msgbox_warning_async(msg, "Warning", buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
	};
}

///@desc 放弃编辑并关闭设置界面
///@returns {Undefined} 无
function settings_gui_discard_close() {
	if (variable_instance_exists(id, "editing_key")) then editing_key = "";
	// Android 上先藏起虚拟键盘
	if (os_type == os_android) {
		try { keyboard_virtual_hide(); } catch (hide_err) { delete(hide_err); };
	};
	settings_gui_close();
}

///@desc 按标签文字测量按钮宽度，不小于给定最小值
///@param {String} _label 按钮文字
///@param {Real} _min_w 最小宽度
///@param {Real} _h 按钮高度
///@returns {Real} 按钮宽度
function settings_gui_button_width(_label, _min_w, _h) {
	var text_w = 0;
	if (string_length(_label)) {
		var measure_font = settings_ui_font();
		if (font_exists(measure_font)) {
			var old_font = draw_get_font();
			draw_set_font(measure_font);
			var text_scale = settings_fit_text_scale(_label, 100000, _h * 0.62);
			text_w = string_width(_label) * text_scale;
			draw_set_font(old_font);
		} else {
			// 字体不存在时用字数粗略估算
			text_w = string_length(_label) * _h * 0.45;
		};
	};
	return max(_min_w, ceil(text_w + _h * 0.7));
}

///@desc 取设置字段的显示名并缓存
///@param {String} _key 设置键
///@param {String} _comment 目录注释
///@returns {String} 显示标签
function settings_field_label(_key, _comment) {
	lang_ensure();
	if (!is_struct(global.pls_lang.field_labels)) then global.pls_lang.field_labels = {};
	// 已缓存则直接返回
	if (struct_exists(global.pls_lang.field_labels, _key)) then return global.pls_lang.field_labels[$ _key];
	var label = lang("fields." + string(_key), settings_comment_label(_comment));
	// 翻译为空时退回键名
	if (!string_length(label)) then label = string(_key);
	global.pls_lang.field_labels[$ _key] = label;
	return label;
}

///@desc 绘制一个菜单按钮
///@param {Struct} _btn 含 x、y、w、h、label 的按钮
///@param {Bool} _hot 是否悬停
///@param {Real} _text_scale 文字缩放
///@returns {Undefined} 无
function menu_draw_button(_btn, _hot, _text_scale) {
	// 按钮结构无效则不画
	if (!is_struct(_btn)) then return;
	draw_set_colour(_hot ? make_colour_rgb(70, 110, 180) : make_colour_rgb(40, 48, 64));
	draw_rectangle(_btn.x, _btn.y, _btn.x + _btn.w, _btn.y + _btn.h, false);
	draw_set_colour(c_white);
	draw_rectangle(_btn.x, _btn.y, _btn.x + _btn.w, _btn.y + _btn.h, true);
	draw_text_transformed(_btn.x + _btn.w * 0.5, _btn.y + _btn.h * 0.5, _btn.label, _text_scale, _text_scale, 0);
}

///@desc 取得或重建皮肤预览表面
///@param {Real} _w 宽度
///@param {Real} _h 高度
///@returns {Real} 表面 id
function settings_skin_preview_surface(_w, _h) {
	_w = max(1, floor(_w));
	_h = max(1, floor(_h));
	if (!variable_instance_exists(id, "skin_preview_surf") || !surface_exists(skin_preview_surf)
		|| surface_get_width(skin_preview_surf) != _w || surface_get_height(skin_preview_surf) != _h) {
		// 尺寸变化时先释放旧表面
		if (variable_instance_exists(id, "skin_preview_surf") && surface_exists(skin_preview_surf)) {
			surface_free(skin_preview_surf);
		};
		skin_preview_surf = surface_create(_w, _h);
	};
	return skin_preview_surf;
}

///@desc 释放皮肤预览表面
///@returns {Undefined} 无
function settings_skin_preview_surface_free() {
	if (variable_instance_exists(id, "skin_preview_surf") && surface_exists(skin_preview_surf)) {
		surface_free(skin_preview_surf);
		skin_preview_surf = -1;
	};
}

///@desc 绘制皮肤列表、添加按钮和预览
///@param {Real} _s 界面缩放
///@param {Real} _body 正文缩放
///@param {Real} _small 小字缩放
///@param {Real} _fill_idle 普通填充色
///@param {Real} _fill_hot 悬停填充色
///@param {Real} _fill_on 选中填充色
///@returns {Undefined} 无
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
		// 选中行高亮，奇数行加底
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
		draw_text_transformed(list_x + 10 * _s, row_y + row_h * 0.32, string(item.name ?? ""), _body, _body, 0);
		draw_set_colour(make_colour_rgb(150, 160, 180));
		draw_text_transformed(list_x + 10 * _s, row_y + row_h * 0.74, string(item.author ?? ""), _small, _small, 0);
	};
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_colour(hover_skin_add ? _fill_hot : _fill_idle);
	draw_rectangle(skin_add.x, skin_add.y, skin_add.x + skin_add.w, skin_add.y + skin_add.h, false);
	draw_set_colour(c_white);
	draw_rectangle(skin_add.x, skin_add.y, skin_add.x + skin_add.w, skin_add.y + skin_add.h, true);
	var add_label = lang("skin.add", "Add skin");
	var add_scale = settings_fit_text_scale(add_label, skin_add.w * 0.84, skin_add.h * 0.62);
	draw_text_transformed(skin_add.x + skin_add.w * 0.5, skin_add.y + skin_add.h * 0.5, add_label, add_scale, add_scale, 0);

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
			// 找到当前选中项后停止
			break;
		};
	};

	var inset = 2;
	var clip_w = max(1, floor(skin_preview_w - inset * 2));
	var clip_h = max(1, floor(list_h - inset * 2));
	var surf = settings_skin_preview_surface(clip_w, clip_h);
	var used_surf = surface_exists(surf);
	// 表面可用时画到表面，否则直接画到界面
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
	// 按标题、作者、说明和删除按钮挤出音符区高度
	if (string_length(desc)) then title_h = max(title_h, 54 * _s + desc_h + 10 * _s);
	var delete_h = (selected != SKIN_DEFAULT_ID) ? 48 * _s : 8 * _s;
	var fx_min = 96 * _s;
	var note_want = 180 * _s;
	var note_box = min(note_want, inner_w / 4 * 0.9, max(48 * _s, clip_h - title_h - fx_min - delete_h));
	var gap = inner_w / 4;
	var cx = ox + inner_pad + gap * 0.5;
	///@desc 按盒子估算精灵内容高度
	///@param {Real} _spr 精灵
	///@param {Real} _box 目标边长
	///@returns {Real} 包围盒缩放后的高度
	var note_disp_h = function(_spr, _box) {
		// 用包围盒高度而不是整张画布
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
		// 没有预览行高比时用各音符包围盒高度
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
	///@desc 把精灵内容中心对齐到给定点再绘制
	///@param {Real} _spr 精灵
	///@param {Real} _x 中心 x
	///@param {Real} _y 中心 y
	///@param {Real} _k 缩放
	///@param {Real} _frame 帧
	///@returns {Undefined} 无
	var draw_one = function(_spr, _x, _y, _k, _frame) {
		if (!sprite_exists(_spr)) then return;
		// 用包围盒中心修正原点偏移
		var k = real(_k);
		var frame = clamp(real(_frame), 0, max(0, sprite_get_number(_spr) - 1));
		var content_cy = (sprite_get_bbox_top(_spr) + sprite_get_bbox_bottom(_spr)) * 0.5;
		var dy = (sprite_get_yoffset(_spr) - content_cy) * k;
		draw_sprite_ext(_spr, frame, _x, _y + dy, k, k, 0, c_white, 1);
	};
	///@desc 求把精灵长边放进盒子的缩放
	///@param {Real} _spr 精灵
	///@param {Real} _box 目标边长
	///@returns {Real} 缩放系数
	var fit_k = function(_spr, _box) {
		// 精灵无效时不缩放
		if (!sprite_exists(_spr)) then return 1;
		return real(_box) / max(1, max(sprite_get_width(_spr), sprite_get_height(_spr)));
	};
	///@desc 用头身尾绘制一条预览长条
	///@param {Real} _hx 中心 x
	///@param {Real} _hy 中心 y
	///@param {Real} _head 头精灵
	///@param {Real} _body 身精灵
	///@param {Real} _tail 尾精灵
	///@param {Real} _k 头尾缩放
	///@param {Real} _body_scale 身的纵向缩放
	///@param {Real} _frame 帧
	///@returns {Undefined} 无
	var draw_hold_preview = function(_hx, _hy, _head, _body, _tail, _k, _body_scale, _frame) {
		// 缺切片时回退到内置长条
		if (!sprite_exists(_head)) then _head = note_hold_head;
		if (!sprite_exists(_body)) then _body = note_hold_body;
		if (!sprite_exists(_tail)) then _tail = note_hold_end;
		draw_hold_fit(_hx, _hy, _k, _k, _body_scale, 0, _frame, c_white, 1, true, true, 0, 1, _head, _body, _tail);
	};
	// 有皮肤包时画普通与多押两行，否则用内置精灵的两帧
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
	// 特效阶段再画打击和粒子
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

	// 非默认皮肤才画删除按钮
	if (selected != SKIN_DEFAULT_ID) {
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		var del_x = (used_surf ? 0 : (skin_preview_x + inset)) + (skin_delete.x - skin_preview_x - inset);
		var del_y = (used_surf ? 0 : (list_y + inset)) + (skin_delete.y - list_y - inset);
		draw_set_colour(hover_skin_delete ? make_colour_rgb(140, 60, 60) : make_colour_rgb(96, 48, 48));
		draw_rectangle(del_x, del_y, del_x + skin_delete.w, del_y + skin_delete.h, false);
		draw_set_colour(c_white);
		draw_rectangle(del_x, del_y, del_x + skin_delete.w, del_y + skin_delete.h, true);
		var del_label = lang("skin.delete", "Delete");
		var del_scale = settings_fit_text_scale(del_label, skin_delete.w * 0.84, skin_delete.h * 0.62);
		draw_text_transformed(del_x + skin_delete.w * 0.5, del_y + skin_delete.h * 0.5, del_label, del_scale, del_scale, 0);
	};

	// 画完把表面贴回预览区
	if (used_surf) {
		surface_reset_target();
		draw_surface(surf, skin_preview_x + inset, list_y + inset);
	};
	draw_set_colour(make_colour_rgb(70, 80, 96));
	draw_rectangle(skin_preview_x, list_y, skin_preview_x + skin_preview_w, list_y + list_h, true);
}

///@desc 绘制一个设置页签
///@param {Struct} _box 页签矩形
///@param {Bool} _hot 是否悬停
///@param {Bool} _on 是否选中
///@param {String} _label 标题
///@param {Real} _scale 备用文字缩放，实际按盒子重算
///@param {Real} _fill_on 选中色
///@param {Real} _fill_idle 普通色
///@returns {Undefined} 无
function settings_gui_draw_tab(_box, _hot, _on, _label, _scale, _fill_on, _fill_idle) {
	// 页签矩形无效则不画
	if (!is_struct(_box)) then return;
	draw_set_colour(_on ? _fill_on : (_hot ? make_colour_rgb(52, 64, 88) : _fill_idle));
	draw_rectangle(_box.x, _box.y, _box.x + _box.w, _box.y + _box.h, false);
	draw_set_colour(c_white);
	draw_rectangle(_box.x, _box.y, _box.x + _box.w, _box.y + _box.h, true);
	var text_scale = settings_fit_text_scale(_label, _box.w * 0.84, _box.h * 0.62);
	draw_text_transformed(_box.x + _box.w * 0.5, _box.y + _box.h * 0.5, _label, text_scale, text_scale, 0);
}

///@desc 设置界面是否正挡住操作
///@returns {Bool} oSettings 是否存在
function settings_gui_blocking() {
	return instance_exists(oSettings);
}

///@desc 打开设置界面，避免刚关闭又被同一次点击打开
///@returns {Undefined} 无
function settings_gui_open() {
	// 已经打开或正在选文件时不再创建
	if (instance_exists(oSettings) || instance_exists(oFilePicker)) then return;
	// 关掉面板的那一下在下一步仍是按下。手机上菜单按钮就在这根手指下面，松手前会把面板再次打开。
	if (variable_global_exists("settings_closed_at") && is_real(global.settings_closed_at)) {
		if (current_time - global.settings_closed_at < 400) then return;
	};
	instance_create_depth(0, 0, -2000000, oSettings);
}

///@desc 记录关闭时间并销毁设置界面
///@returns {Undefined} 无
function settings_gui_close() {
	global.settings_closed_at = current_time;
	if (!instance_exists(oSettings)) then return;
	with (oSettings) {
		// 先取消导入、卸预览并释放表面
		try { skin_import_cancel(); } catch (cancel_err) { delete(cancel_err); };
		try { skin_preview_unload(); } catch (unload_err) { delete(unload_err); };
		try { settings_skin_preview_surface_free(); } catch (surf_err) { delete(surf_err); };
		if (os_type == os_android) {
			try { keyboard_virtual_hide(); } catch (hide_err) { delete(hide_err); };
		};
		instance_destroy();
	};
}

///@desc 返回进入开发者设置时的警告文案
///@returns {String} 警告文本
function settings_developer_warning_text() {
	return "You have entered developer settings. Changing these options may prevent the simulator from starting. If it cannot start, delete resource/config.ini. On other platforms, tap Clear data to reset.";
}

///@desc 每个设置实例只警告一次开发者选项风险
///@returns {Undefined} 无
function settings_warn_developer() {
	// 已经警告过则返回
	if (variable_instance_exists(id, "developer_warned") && developer_warned) then return;
	developer_warned = true;
	var msg = settings_developer_warning_text();
	var buttons = [msgbox_button("OK")];
	// 原生对话框可用时同步弹出
	if (i_wbox_native_ready()) {
		msgbox_warning_sync(msg, "Warning", buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
	} else {
		msgbox_warning_async(msg, "Warning", buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
	};
}

///@desc 把菜单上的设置按钮摆到右上角
///@returns {Undefined} 无
function settings_menu_button_layout() {
	var s = variable_global_exists("global_scales") ? global_scales : 1.0;
	// 全局缩放无效时按 1 处理
	if (!is_real(s) || s <= 0) then s = 1.0;
	var rw = max(1, room_width);
	var pad = max(12, 20 * s);
	if (!variable_instance_exists(id, "btn_settings") || !is_struct(btn_settings)) {
		btn_settings = { label:lang("common.settings"), x:0, y:0, w:1, h:1 };
	};
	btn_settings.label = lang("common.settings");
	btn_settings.w = 140 * s;
	btn_settings.h = 44 * s;
	btn_settings.x = rw - btn_settings.w - pad;
	btn_settings.y = pad;
}

///@desc 判断指针是否点中菜单设置按钮
///@param {Real} _mx 指针 x
///@param {Real} _my 指针 y
///@returns {Bool} 是否命中
function settings_menu_button_hit(_mx, _my) {
	// 按钮还没摆好则不算命中
	if (!variable_instance_exists(id, "btn_settings") || !is_struct(btn_settings)) then return false;
	return point_in_rectangle(_mx, _my, btn_settings.x, btn_settings.y, btn_settings.x + btn_settings.w, btn_settings.y + btn_settings.h);
}

///@desc 绘制菜单上的设置按钮并恢复绘制状态
///@param {Bool} _hover 是否悬停
///@param {Real} _s 界面缩放，当前未使用
///@returns {Undefined} 无
function settings_menu_button_draw(_hover, _s) {
	// 按钮不存在则不画
	if (!variable_instance_exists(id, "btn_settings") || !is_struct(btn_settings)) then return;
	var b = btn_settings;
	var old_font = draw_get_font();
	var old_halign = draw_get_halign();
	var old_valign = draw_get_valign();
	var old_colour = draw_get_colour();
	var button_font = settings_ui_font();
	if (font_exists(button_font)) then draw_set_font(button_font);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_colour(_hover ? make_colour_rgb(70, 110, 180) : make_colour_rgb(40, 48, 64));
	draw_rectangle(b.x, b.y, b.x + b.w, b.y + b.h, false);
	draw_set_colour(c_white);
	draw_rectangle(b.x, b.y, b.x + b.w, b.y + b.h, true);
	var text_scale = settings_fit_text_scale(b.label, b.w * 0.76, b.h * 0.64);
	draw_text_transformed(b.x + b.w * 0.5, b.y + b.h * 0.5, b.label, text_scale, text_scale, 0);
	draw_set_font(old_font);
	draw_set_halign(old_halign);
	draw_set_valign(old_valign);
	draw_set_colour(old_colour);
}

///@desc 在抗锯齿档位 0、2、4、8 之间按方向切换
///@param {Real} _current 当前值
///@param {Real} _dir 方向，负为上一档
///@returns {Real} 新的抗锯齿等级
function settings_aa_cycle(_current, _dir) {
	var vals = [0, 2, 4, 8];
	var idx = 0;
	var best = 999;
	for (var i = 0; i < array_length(vals); i++) {
		var d = abs(vals[i] - _current);
		// 先吸附到最近档位再加减
		if (d < best) { best = d; idx = i; };
	};
	idx = clamp(idx + _dir, 0, array_length(vals) - 1);
	return vals[idx];
}

///@desc 返回数字项每次加减的步长
///@param {String} _key 设置键
///@returns {Real} 步长
function settings_number_step(_key) {
	switch (_key) {
		// 大步长的项单独指定，其余每次 1
		case "rpeWorkerProfileFrames": return 60;
		case "refreshFPSCount": return 5;
		default: return 1;
	};
}

///@desc 把正在编辑的键盘文本写回草稿
///@returns {Undefined} 无
function settings_gui_commit_edit() {
	// 没有编辑中的键则返回
	if (!is_string(editing_key) || !string_length(editing_key)) then return;
	var key = editing_key;
	var text = string(keyboard_string);
	editing_key = "";
	if (os_type == os_android) {
		try { keyboard_virtual_hide(); } catch (hide_err) { delete(hide_err); };
	};
	// 字符串原样保存，其他键先解析
	if (settings_kind(key) == "string") {
		settings_gui_draft_set(key, text);
	} else {
		var parsed = settings_parse_value(text, settings_gui_draft()[$ key]);
		settings_gui_draft_set(key, parsed);
	};
}

///@desc 结束上一项编辑并开始编辑指定键
///@param {String} _key 设置键
///@returns {Undefined} 无
function settings_gui_begin_edit(_key) {
	settings_gui_commit_edit();
	editing_key = _key;
	keyboard_string = string(settings_gui_draft()[$ _key] ?? "");
	// Android 上弹出虚拟键盘
	if (os_type == os_android) {
		try { keyboard_virtual_show(0, 0, 0, false); }
		catch (show_err) { delete(show_err); };
	};
}

///@desc 按房间尺寸计算设置面板、页签、列表和皮肤区布局
///@returns {Undefined} 无
function settings_gui_layout() {
	var s = variable_global_exists("global_scales") ? global_scales : 1.0;
	// 全局缩放无效时按 1 处理
	if (!is_real(s) || s <= 0) then s = 1.0;
	layout_s = s;
	var rw = max(1, room_width);
	var rh = max(1, room_height);
	panel_w = min(rw - 40 * s, 980 * s);
	panel_h = min(rh - 36 * s, 680 * s);
	// 面板不超过房间并居中
	panel_x = (rw - panel_w) * 0.5;
	panel_y = (rh - panel_h) * 0.5;
	var pad = 18 * s;
	tab_h = 46 * s;
	tab_y = panel_y + 58 * s;
	tab_w = (panel_w - pad * 4) / 3;
	tab_normal = { x:panel_x + pad, y:tab_y, w:tab_w, h:tab_h };
	tab_lang = { x:panel_x + pad * 2 + tab_w, y:tab_y, w:tab_w, h:tab_h };
	tab_skin = { x:panel_x + pad * 3 + tab_w * 2, y:tab_y, w:tab_w, h:tab_h };
	var header_h = 36 * s;
	save_h = header_h;
	discard_h = header_h;
	save_y = panel_y + 12 * s;
	discard_y = save_y;
	save_w = settings_gui_button_width(lang("settings.save", "Save"), 90 * s, header_h);
	discard_w = settings_gui_button_width(lang("settings.discardClose", "Don't save and close"), 90 * s, header_h);
	save_x = panel_x + panel_w - pad - save_w;
	discard_x = save_x - 8 * s - discard_w;
	settings_gui_action_layout();
	footer_h = 52 * s;
	list_x = panel_x + pad;
	list_w = panel_w - pad * 2;
	list_y = tab_y + tab_h + 12 * s;
	list_h = panel_h - (list_y - panel_y) - footer_h - pad;
	row_h = 58 * s;
	visible_rows = max(1, floor(list_h / row_h));
	clear_w = 160 * s;
	clear_h = 40 * s;
	clear_x = panel_x + pad;
	clear_y = panel_y + panel_h - pad - clear_h;
	// 非 Windows 才显示清除数据
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

///@desc 按当前页签决定右上角动作是重置、重载还是没有
///@returns {String} reset、reload 或空串
function settings_gui_action_kind() {
	if (!variable_instance_exists(id, "tab")) then return "";
	// 常规页是重置，语言页是重载，皮肤页没有动作
	if (tab == 0) then return "reset";
	if (tab == 1) then return "reload";
	return "";
}

///@desc 返回右上角动作按钮的文字
///@returns {String} 按钮文字，无动作时为空
function settings_gui_action_label() {
	var kind = settings_gui_action_kind();
	// 没有动作种类时返回空文字
	if (kind == "reset") then return lang("settings.reset");
	if (kind == "reload") then return lang("settings.reloadLanguage");
	return "";
}

///@desc 按文字测量右上角动作按钮并排在丢弃按钮左侧
///@returns {Undefined} 无
function settings_gui_action_layout() {
	var s = layout_s;
	if (!is_real(s) || s <= 0) then s = 1.0;
	var kind = settings_gui_action_kind();
	show_action = (kind != "");
	action_h = discard_h;
	action_y = discard_y;
	// 没有动作时宽度为 0 并提前返回
	if (!show_action) {
		action_w = 0;
		action_x = discard_x;
		return;
	};
	var label = settings_gui_action_label();
	var text_w = 0;
	if (string_length(label)) {
		var measure_font = settings_ui_font();
		if (font_exists(measure_font)) {
			var old_font = draw_get_font();
			draw_set_font(measure_font);
			var text_scale = settings_fit_text_scale(label, 100000, action_h * 0.62);
			text_w = string_width(label) * text_scale;
			draw_set_font(old_font);
		} else {
			// 字体不存在时用字数粗略估算
			text_w = string_length(label) * action_h * 0.45;
		};
	};
	action_w = max(discard_h * 2.5, ceil(text_w + discard_h * 0.7));
	action_x = discard_x - 8 * s - action_w;
}

///@desc 返回当前可见的设置行
///@returns {Array} 行描述
function settings_gui_rows() {
	return settings_gui_visible_rows();
}

///@desc 判断指针是否在矩形盒子内
///@param {Struct} _box 含 x、y、w、h 的矩形
///@param {Real} _mx 指针 x
///@param {Real} _my 指针 y
///@returns {Bool} 是否命中
function settings_gui_hit(_box, _mx, _my) {
	// 矩形无效则不算命中
	if (!is_struct(_box)) then return false;
	return point_in_rectangle(_mx, _my, _box.x, _box.y, _box.x + _box.w, _box.y + _box.h);
}

///@desc 初始化设置界面的页签、草稿、皮肤导入和命中缓存
///@returns {Undefined} 无
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
	hover_save = false;
	// Android 忽略打开瞬间的那次松开
	ignore_release = (os_type == os_android);
	hover_discard = false;
	hover_action = false;
	group_open = { display:false, debug:false, chart:false, deprecated:false };
	draft = settings_clone(settings_store());
	draft_saved = settings_clone(draft);
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
	hits_fold = "";
	ui_font = settings_ui_font();
	settings_store();
	settings_gui_layout();
}

///@desc 在布局或折叠变化时重建各页签的点击区域
///@returns {Undefined} 无
function settings_gui_refresh_hits() {
	var rows = (tab == 0) ? settings_gui_rows() : [];
	var lang_rows = lang_packs();
	var skin_rows = skin_menu_items();
	var skin_visible = max(1, floor(skin_list_h / row_h));
	var fold = settings_gui_fold_sig();
	// 签名没变则沿用旧命中区
	if (hits_tab == tab && hits_scroll == scroll && hits_visible == visible_rows
		&& hits_w == layout_w && hits_h == layout_h && hits_s == layout_s && hits_fold == fold) then return;
	hits_tab = tab;
	hits_scroll = scroll;
	hits_visible = visible_rows;
	hits_w = layout_w;
	hits_h = layout_h;
	hits_s = layout_s;
	hits_fold = fold;
	row_hits = [];
	lang_hits = [];
	skin_hits = [];
	// 皮肤、语言和设置页分别生成命中盒
	if (tab == 2) {
		var skin_last = min(array_length(skin_rows), scroll + skin_visible);
		for (var si = scroll; si < skin_last; si++) {
			var skin_item = skin_rows[si];
			if (!is_struct(skin_item)) then continue;
			var skin_row_y = list_y + (si - scroll) * row_h;
			array_add(skin_hits, {
				skin_id: string(skin_item.skin_id ?? ""),
				box: { x:list_x, y:skin_row_y, w:skin_list_w, h:row_h }
			});
		};
	} else if (tab == 1) {
		var lang_last = min(array_length(lang_rows), scroll + visible_rows);
		for (var li = scroll; li < lang_last; li++) {
			var pack = lang_rows[li];
			if (!is_struct(pack)) then continue;
			var lang_row_y = list_y + (li - scroll) * row_h;
			array_add(lang_hits, {
				locale: string(pack.id ?? ""),
				y: lang_row_y,
				box: { x:list_x, y:lang_row_y, w:list_w, h:row_h }
			});
		};
	} else {
		var last = min(array_length(rows), scroll + visible_rows);
		for (var i = scroll; i < last; i++) {
			var entry = rows[i];
			var row_y = list_y + (i - scroll) * row_h;
			// 分组行整行可点，用来展开或收起
			if (entry.type == "group") {
				array_add(row_hits, {
					row_type:"group",
					group_id:entry.id,
					box:{ x:list_x, y:row_y, w:list_w, h:row_h }
				});
				continue;
			};
			var item = entry.item;
			var ctrl_h = max(8, row_h * 0.62);
			var ctrl_w = min(list_w * 0.42, max(220 * layout_s, ctrl_h * 3.4));
			var ctrl_x = list_x + list_w - ctrl_w - 8 * layout_s;
			var ctrl_y = row_y + (row_h - ctrl_h) * 0.5;
			var kind = settings_kind(item.key);
			var hit = { row_type:"field", key:item.key, kind:kind, row:i, y:row_y, minus:undefined, plus:undefined, toggle:undefined, field:undefined };
			// 布尔是整条开关，数字拆成减号、输入和加号
			if (kind == "bool") {
				hit.toggle = { x:ctrl_x, y:ctrl_y, w:ctrl_w, h:ctrl_h };
			} else if (kind == "number") {
				var btn_w = ctrl_h;
				hit.minus = { x:ctrl_x, y:ctrl_y, w:btn_w, h:ctrl_h };
				hit.plus = { x:ctrl_x + ctrl_w - btn_w, y:ctrl_y, w:btn_w, h:ctrl_h };
				hit.field = { x:ctrl_x + btn_w + 4 * layout_s, y:ctrl_y, w:ctrl_w - btn_w * 2 - 8 * layout_s, h:ctrl_h };
			} else {
				hit.field = { x:ctrl_x, y:ctrl_y, w:ctrl_w, h:ctrl_h };
			};
			array_add(row_hits, hit);
		};
	};
}

///@desc 读取指针坐标和按键边沿，Android 上合并多指
///@returns {Struct} x、y、pressed、released、held
function settings_gui_pointer() {
	var px = mouse_x;
	var py = mouse_y;
	var pressed = mouse_check_button_pressed(mb_left);
	var released = mouse_check_button_released(mb_left);
	var held = mouse_check_button(mb_left);
	// 非 Android 直接用鼠标
	if (os_type != os_android) {
		return { x: px, y: py, pressed: pressed, released: released, held: held };
	};
	// mouse_x 停在打开面板的那根手指上。之后的点击是另一个触摸序号，保存和丢弃因此收不到。
	pressed = false;
	released = false;
	held = false;
	var found = false;
	for (var device = 0; device < 4; device++) {
		var edge = device_mouse_check_button_pressed(device, mb_left);
		var up = device_mouse_check_button_released(device, mb_left);
		var down = device_mouse_check_button(device, mb_left);
		if (!edge && !up && !down) then continue;
		// 优先采用刚按下的那根手指
		if (!found || edge) {
			px = device_mouse_x(device);
			py = device_mouse_y(device);
			found = true;
		};
		if (edge) then pressed = true;
		if (up) then released = true;
		if (down) then held = true;
	};
	if (!found) {
		px = mouse_x;
		py = mouse_y;
		pressed = mouse_check_button_pressed(mb_left);
		released = mouse_check_button_released(mb_left);
		held = mouse_check_button(mb_left);
	};
	return { x: px, y: py, pressed: pressed, released: released, held: held };
}

///@desc 处理设置界面的布局、导入、拖动和点击
///@returns {Undefined} 无
function settings_gui_step() {
	var scale_now = variable_global_exists("global_scales") ? global_scales : 1.0;
	// 房间或缩放变了就重算布局
	if (layout_w != room_width || layout_h != room_height || layout_s != scale_now) {
		settings_gui_layout();
	};
	var pointer = settings_gui_pointer();
	if (!armed) {
		// Android 松手后 mb_left 可能仍为按住。一直等这次松开，面板就永远不会武装，两个关闭按钮都不会执行。
		if (os_type == os_android || !pointer.held) then armed = true;
	};
	// 文件选择器打开时不处理点击
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

	var rows = (tab == 0) ? settings_gui_rows() : [];
	var lang_rows = lang_packs();
	var skin_rows = skin_menu_items();
	var list_count = array_length(rows);
	if (tab == 1) then list_count = array_length(lang_rows);
	else if (tab == 2) then list_count = array_length(skin_rows);
	var skin_visible = max(1, floor(skin_list_h / row_h));
	var max_scroll = max(0, list_count - ((tab == 2) ? skin_visible : visible_rows));
	scroll = clamp(scroll, 0, max_scroll);

	if (is_string(editing_key) && string_length(editing_key)) {
		// 回车提交；Esc 先还原再提交
		if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_escape)) {
			if (keyboard_check_pressed(vk_escape)) then keyboard_string = string(settings_gui_draft()[$ editing_key] ?? "");
			settings_gui_commit_edit();
			exit;
		};
	// 没在编辑时 Esc 直接丢弃并关闭
	} else if (keyboard_check_pressed(vk_escape)) {
		settings_gui_discard_close();
		exit;
	};

	var mx = pointer.x;
	var my = pointer.y;
	settings_gui_action_layout();
	hover_save = point_in_rectangle(mx, my, save_x, save_y, save_x + save_w, save_y + save_h);
	hover_discard = point_in_rectangle(mx, my, discard_x, discard_y, discard_x + discard_w, discard_y + discard_h);
	hover_action = show_action && point_in_rectangle(mx, my, action_x, action_y, action_x + action_w, action_y + action_h);
	hover_tab_normal = settings_gui_hit(tab_normal, mx, my);
	hover_tab_lang = settings_gui_hit(tab_lang, mx, my);
	hover_tab_skin = settings_gui_hit(tab_skin, mx, my);
	hover_skin_add = (tab == 2) && settings_gui_hit(skin_add, mx, my);
	hover_skin_delete = (tab == 2) && (skin_selected_id() != SKIN_DEFAULT_ID) && settings_gui_hit(skin_delete, mx, my);
	hover_clear = show_clear && point_in_rectangle(mx, my, clear_x, clear_y, clear_x + clear_w, clear_y + clear_h);

	if (mouse_wheel_up()) then scroll = max(0, scroll - 1);
	if (mouse_wheel_down()) then scroll = min(max_scroll, scroll + 1);

	var in_list = (tab == 2)
		? point_in_rectangle(mx, my, list_x, list_y, list_x + skin_list_w, list_y + skin_list_h)
		: point_in_rectangle(mx, my, list_x, list_y, list_x + list_w, list_y + list_h);
	if (pointer.pressed) {
		if (in_list) {
			dragging = true;
			drag_moved = false;
			drag_start_y = my;
			drag_start_scroll = scroll;
		} else {
			// 列表拖动曾一直保持已移动，从而吞掉下一次保存点击。
			dragging = false;
			drag_moved = false;
		};
	};
	if (dragging && pointer.held) {
		var dy = drag_start_y - my;
		// 拖动超过阈值才滚动，避免把点击当成拖动
		if (abs(dy) > max(8, 10 * layout_s)) then drag_moved = true;
		if (drag_moved) {
			scroll = clamp(drag_start_scroll + dy / row_h, 0, max_scroll);
		};
	};
	if (!pointer.held) then dragging = false;

	settings_gui_refresh_hits();

	// Android 在松开时才给出点击位置。按下那一帧仍是上一根手指的坐标，顶栏按钮会对不准。
	// 打开面板的那次松手不算点了保存或丢弃。
	if (ignore_release) {
		if (pointer.released || !pointer.held) then ignore_release = false;
		if (pointer.released) then exit;
	};
	var activate = pointer.pressed;
	// Android 用松开作为点击
	if (os_type == os_android) then activate = pointer.released;
	if (!armed || !activate) then exit;
	// 这次是拖动列表，不触发按钮
	if (drag_moved) then exit;

	if (hover_save) {
		settings_gui_request_save();
		exit;
	};
	if (hover_discard) {
		settings_gui_discard_close();
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
	if (hover_tab_lang && tab != 1) {
		settings_gui_commit_edit();
		tab = 1;
		scroll = 0;
		exit;
	};
	if (hover_tab_skin && tab != 2) {
		settings_gui_commit_edit();
		tab = 2;
		scroll = 0;
		skin_preview_set(skin_selected_id());
		exit;
	};
	// 皮肤页只处理添加、删除和选择
	if (tab == 2) {
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
		settings_gui_sync_draft();
		scroll = 0;
		if (!pls_is_gx_remote()) {
			msgbox_info_async("Data cleared and defaults restored.", "Settings", [msgbox_button("OK")], MSGBOX_BUTTON_ALIGN.RIGHT);
		};
		exit;
	};
	if (tab == 1) {
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
		if (rh.row_type == "group") {
			if (settings_gui_hit(rh.box, mx, my)) {
				var state = settings_gui_group_state();
				state[$ rh.group_id] = !bool(state[$ rh.group_id]);
				var shown = array_length(settings_gui_rows());
				scroll = clamp(scroll, 0, max(0, shown - visible_rows));
				hits_fold = "";
				exit;
			};
			continue;
		};
		var key = rh.key;
		var cur = settings_gui_draft()[$ key];
		if (is_struct(rh.toggle) && settings_gui_hit(rh.toggle, mx, my)) {
			settings_gui_commit_edit();
			settings_gui_draft_set(key, !bool(cur));
			exit;
		};
		if (is_struct(rh.minus) && settings_gui_hit(rh.minus, mx, my)) {
			settings_gui_commit_edit();
			if (key == "aa_level") then settings_gui_draft_set(key, settings_aa_cycle(real(cur), -1));
			else settings_gui_draft_set(key, real(cur) - settings_number_step(key));
			exit;
		};
		if (is_struct(rh.plus) && settings_gui_hit(rh.plus, mx, my)) {
			settings_gui_commit_edit();
			if (key == "aa_level") then settings_gui_draft_set(key, settings_aa_cycle(real(cur), 1));
			else settings_gui_draft_set(key, real(cur) + settings_number_step(key));
			exit;
		};
		if (is_struct(rh.field) && settings_gui_hit(rh.field, mx, my)) {
			settings_gui_begin_edit(key);
			exit;
		};
	};

	if (is_string(editing_key) && string_length(editing_key)) then settings_gui_commit_edit();
}

///@desc 绘制设置面板、页签、列表和底部提示
///@returns {Undefined} 无
function settings_gui_draw() {
	var old_font = draw_get_font();
	var old_halign = draw_get_halign();
	var old_valign = draw_get_valign();
	var old_colour = draw_get_colour();
	var old_alpha = draw_get_alpha();
	shader_reset();
	gpu_set_blendmode(bm_normal);
	var draw_font = settings_ui_font();
	if (!font_exists(draw_font) && variable_instance_exists(id, "ui_font")) then draw_font = ui_font;
	if (font_exists(draw_font)) then draw_set_font(draw_font);
	else draw_set_font(-1);
	settings_gui_refresh_hits();
	settings_gui_action_layout();

	var s = layout_s;
	if (!is_real(s) || s <= 0) then s = 1.0;
	var font_h = max(1, string_height("Ag"));
	var title_scale = max(0.05, (34 * s) / font_h);
	var tab_scale = max(0.05, (tab_h * 0.62) / font_h);
	var body_scale = max(0.05, (row_h * 0.36) / font_h);
	var small_scale = max(0.05, (row_h * 0.30) / font_h);
	var fill_idle = make_colour_rgb(40, 48, 64);
	var fill_hot = make_colour_rgb(70, 110, 180);
	var fill_tab = make_colour_rgb(28, 34, 48);
	var fill_on = make_colour_rgb(46, 120, 92);

	// 先铺暗底，再画面板
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
	draw_set_colour(hover_save ? fill_hot : fill_idle);
	draw_rectangle(save_x, save_y, save_x + save_w, save_y + save_h, false);
	draw_set_colour(c_white);
	draw_rectangle(save_x, save_y, save_x + save_w, save_y + save_h, true);
	var save_label = lang("settings.save", "Save");
	var save_scale = settings_fit_text_scale(save_label, save_w * 0.84, save_h * 0.62);
	draw_text_transformed(save_x + save_w * 0.5, save_y + save_h * 0.5, save_label, save_scale, save_scale, 0);
	draw_set_colour(hover_discard ? fill_hot : fill_idle);
	draw_rectangle(discard_x, discard_y, discard_x + discard_w, discard_y + discard_h, false);
	draw_set_colour(c_white);
	draw_rectangle(discard_x, discard_y, discard_x + discard_w, discard_y + discard_h, true);
	var discard_label = lang("settings.discardClose", "Don't save and close");
	var discard_scale = settings_fit_text_scale(discard_label, discard_w * 0.86, discard_h * 0.62);
	draw_text_transformed(discard_x + discard_w * 0.5, discard_y + discard_h * 0.5, discard_label, discard_scale, discard_scale, 0);

	if (show_action) {
		var action_label = settings_gui_action_label();
		draw_set_colour(hover_action ? fill_hot : fill_idle);
		draw_rectangle(action_x, action_y, action_x + action_w, action_y + action_h, false);
		draw_set_colour(c_white);
		draw_rectangle(action_x, action_y, action_x + action_w, action_y + action_h, true);
		var action_scale = settings_fit_text_scale(action_label, action_w * 0.86, action_h * 0.62);
		draw_text_transformed(action_x + action_w * 0.5, action_y + action_h * 0.5, action_label, action_scale, action_scale, 0);
	};

	settings_gui_draw_tab(tab_normal, hover_tab_normal, tab == 0, lang("settings.normal"), tab_scale, fill_hot, fill_tab);
	settings_gui_draw_tab(tab_lang, hover_tab_lang, tab == 1, lang("settings.language"), tab_scale, fill_hot, fill_tab);
	settings_gui_draw_tab(tab_skin, hover_tab_skin, tab == 2, lang("settings.skin", "Skin"), tab_scale, fill_hot, fill_tab);

	// 皮肤页单独画，语言页画语言包，否则画分组和字段
	if (tab == 2) {
		settings_gui_draw_skins(s, body_scale, small_scale, fill_idle, fill_hot, fill_on);
	} else {
	draw_set_colour(make_colour_rgb(22, 29, 45));
	draw_rectangle(list_x, list_y, list_x + list_w, list_y + list_h, false);
	draw_set_colour(make_colour_rgb(70, 80, 96));
	draw_rectangle(list_x, list_y, list_x + list_w, list_y + list_h, true);

	if (tab == 1) {
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
			var author = string(pack[$ "author"] ?? "");
			var name_w = string_length(author) ? list_w * 0.58 : list_w * 0.9;
			var pack_label = lang_pack_label(pack);
			var pack_scale = min(body_scale, settings_fit_text_scale(pack_label, name_w, row_h * 0.40));
			draw_set_halign(fa_left);
			draw_set_valign(fa_middle);
			draw_set_colour(c_white);
			draw_text_transformed(list_x + 12 * s, pack_y + row_h * 0.32, pack_label, pack_scale, pack_scale, 0);
			draw_set_colour(make_colour_rgb(150, 160, 180));
			var id_scale = min(small_scale, settings_fit_text_scale(string(pack.id ?? ""), name_w, row_h * 0.30));
			draw_text_transformed(list_x + 12 * s, pack_y + row_h * 0.74, string(pack.id ?? ""), id_scale, id_scale, 0);
			if (string_length(author)) {
				draw_set_halign(fa_right);
				draw_set_colour(c_white);
				var author_scale = min(body_scale, settings_fit_text_scale(author, list_w * 0.34, row_h * 0.62));
				draw_text_transformed(list_x + list_w - 12 * s, pack_y + row_h * 0.5, author, author_scale, author_scale, 0);
			};
		};
	} else {
	var rows = settings_gui_rows();
	var store = settings_gui_draft();
	var fold = settings_gui_group_state();
	var last = min(array_length(rows), scroll + visible_rows);
	for (var i = scroll; i < last; i++) {
		var entry = rows[i];
		var row_y = list_y + (i - scroll) * row_h;
		// 分组行用加减号表示展开
		if (entry.type == "group") {
			var group_open_now = bool(fold[$ entry.id]);
			draw_set_colour(entry.id == "deprecated" ? make_colour_rgb(64, 40, 48) : make_colour_rgb(32, 44, 68));
			draw_rectangle(list_x + 2, row_y, list_x + list_w - 2, row_y + row_h, false);
			var mark = group_open_now ? "-  " : "+  ";
			var group_label = mark + settings_group_title(entry.id);
			var group_scale = min(body_scale, settings_fit_text_scale(group_label, list_w * 0.9, row_h * 0.62));
			draw_set_halign(fa_left);
			draw_set_valign(fa_middle);
			draw_set_colour(c_white);
			draw_text_transformed(list_x + 16 * s, row_y + row_h * 0.5, group_label, group_scale, group_scale, 0);
			continue;
		};
		var item = entry.item;
		if ((i - scroll) mod 2 == 1) {
			draw_set_colour(make_colour_rgb(20, 26, 40));
			draw_rectangle(list_x + 2, row_y, list_x + list_w - 2, row_y + row_h, false);
		};
		var label = settings_field_label(item.key, item.comment);
		var label_w = max(40, list_w * 0.52);
		var label_scale = min(body_scale, settings_fit_text_scale(label, label_w, row_h * 0.40));
		var key_scale = min(small_scale, settings_fit_text_scale(item.key, label_w, row_h * 0.30));
		draw_set_halign(fa_left);
		draw_set_valign(fa_middle);
		draw_set_colour(c_white);
		draw_text_transformed(list_x + 28 * s, row_y + row_h * 0.32, label, label_scale, label_scale, 0);
		draw_set_colour(make_colour_rgb(150, 160, 180));
		draw_text_transformed(list_x + 28 * s, row_y + row_h * 0.74, item.key, key_scale, key_scale, 0);
	};

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	for (var h = 0; h < array_length(row_hits); h++) {
		var rh = row_hits[h];
		if (rh.row_type == "group") then continue;
		var cur = store[$ rh.key];
		// 按控件种类画开关、加减或文本框
		if (rh.kind == "bool" && is_struct(rh.toggle)) {
			var on = bool(cur);
			draw_set_colour(on ? fill_on : fill_idle);
			draw_rectangle(rh.toggle.x, rh.toggle.y, rh.toggle.x + rh.toggle.w, rh.toggle.y + rh.toggle.h, false);
			draw_set_colour(c_white);
			draw_rectangle(rh.toggle.x, rh.toggle.y, rh.toggle.x + rh.toggle.w, rh.toggle.y + rh.toggle.h, true);
			var toggle_label = on ? lang("common.on") : lang("common.off");
			var toggle_scale = settings_fit_text_scale(toggle_label, rh.toggle.w * 0.78, rh.toggle.h * 0.64);
			draw_text_transformed(rh.toggle.x + rh.toggle.w * 0.5, rh.toggle.y + rh.toggle.h * 0.5, toggle_label, toggle_scale, toggle_scale, 0);
		} else if (rh.kind == "number") {
			var shown = (editing_key == rh.key) ? keyboard_string : string(cur);
			if (is_struct(rh.minus)) {
				draw_set_colour(fill_idle);
				draw_rectangle(rh.minus.x, rh.minus.y, rh.minus.x + rh.minus.w, rh.minus.y + rh.minus.h, false);
				draw_set_colour(c_white);
				draw_rectangle(rh.minus.x, rh.minus.y, rh.minus.x + rh.minus.w, rh.minus.y + rh.minus.h, true);
				var minus_scale = settings_fit_text_scale("-", rh.minus.w * 0.6, rh.minus.h * 0.64);
				draw_text_transformed(rh.minus.x + rh.minus.w * 0.5, rh.minus.y + rh.minus.h * 0.5, "-", minus_scale, minus_scale, 0);
			};
			if (is_struct(rh.plus)) {
				draw_set_colour(fill_idle);
				draw_rectangle(rh.plus.x, rh.plus.y, rh.plus.x + rh.plus.w, rh.plus.y + rh.plus.h, false);
				draw_set_colour(c_white);
				draw_rectangle(rh.plus.x, rh.plus.y, rh.plus.x + rh.plus.w, rh.plus.y + rh.plus.h, true);
				var plus_scale = settings_fit_text_scale("+", rh.plus.w * 0.6, rh.plus.h * 0.64);
				draw_text_transformed(rh.plus.x + rh.plus.w * 0.5, rh.plus.y + rh.plus.h * 0.5, "+", plus_scale, plus_scale, 0);
			};
			if (is_struct(rh.field)) {
				draw_set_colour(editing_key == rh.key ? make_colour_rgb(38, 75, 104) : make_colour_rgb(22, 29, 45));
				draw_rectangle(rh.field.x, rh.field.y, rh.field.x + rh.field.w, rh.field.y + rh.field.h, false);
				draw_set_colour(c_white);
				draw_rectangle(rh.field.x, rh.field.y, rh.field.x + rh.field.w, rh.field.y + rh.field.h, true);
				var shown_scale = settings_fit_text_scale(shown, rh.field.w * 0.84, rh.field.h * 0.64);
				draw_text_transformed(rh.field.x + rh.field.w * 0.5, rh.field.y + rh.field.h * 0.5, shown, shown_scale, shown_scale, 0);
			};
		} else if (is_struct(rh.field)) {
			var text = (editing_key == rh.key) ? keyboard_string : string(cur ?? "");
			draw_set_colour(editing_key == rh.key ? make_colour_rgb(38, 75, 104) : make_colour_rgb(22, 29, 45));
			draw_rectangle(rh.field.x, rh.field.y, rh.field.x + rh.field.w, rh.field.y + rh.field.h, false);
			draw_set_colour(c_white);
			draw_rectangle(rh.field.x, rh.field.y, rh.field.x + rh.field.w, rh.field.y + rh.field.h, true);
			var text_scale = settings_fit_text_scale(text, rh.field.w * 0.84, rh.field.h * 0.64);
			draw_text_transformed(rh.field.x + rh.field.w * 0.5, rh.field.y + rh.field.h * 0.5, text, text_scale, text_scale, 0);
		};
	};
	};
	};

	if (show_clear) {
		draw_set_colour(hover_clear ? make_colour_rgb(140, 60, 60) : make_colour_rgb(96, 48, 48));
		draw_rectangle(clear_x, clear_y, clear_x + clear_w, clear_y + clear_h, false);
		draw_set_colour(c_white);
		draw_rectangle(clear_x, clear_y, clear_x + clear_w, clear_y + clear_h, true);
		var clear_label = lang("settings.clearData");
		var clear_scale = settings_fit_text_scale(clear_label, clear_w * 0.84, clear_h * 0.62);
		draw_text_transformed(clear_x + clear_w * 0.5, clear_y + clear_h * 0.5, clear_label, clear_scale, clear_scale, 0);
	};

	draw_set_halign(fa_right);
	draw_set_colour(c_gray);
	var hint = lang("settings.hintNormal");
	// 底部提示随页签切换
	if (tab == 1) then hint = lang_current_label();
	else if (tab == 2) then hint = lang("settings.hintSkin", "Add a resource pack, then select it. It applies when you enter a chart.");
	var hint_left = panel_x + 18 * s;
	if (show_clear) then hint_left = clear_x + clear_w + 12 * s;
	var hint_w = max(40, panel_x + panel_w - 18 * s - hint_left);
	var hint_scale = min(small_scale, settings_fit_text_scale(hint, hint_w, row_h * 0.30));
	draw_text_transformed(panel_x + panel_w - 18 * s, panel_y + panel_h - 26 * s, hint, hint_scale, hint_scale, 0);

	draw_set_font(old_font);
	draw_set_halign(old_halign);
	draw_set_valign(old_valign);
	draw_set_colour(old_colour);
	draw_set_alpha(old_alpha);
}
