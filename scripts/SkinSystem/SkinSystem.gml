/// @desc 兼容 Phira 的音符皮肤（respacks）。默认使用内置精灵。
/// 打击特效只用皮肤包图集，不用 Phira 额外的方形粒子。

// 空字符串表示内置默认皮肤
#macro SKIN_DEFAULT_ID ""

///@desc 返回皮肤根目录，不存在则创建
///@returns {String} skins 目录路径
function skin_root_dir() {
	var dir = working_directory + "skins/";
	dir = string_replace_all(dir, "\\", "/");
	// 目录不存在时尝试创建
	if (!directory_exists(dir)) {
		try { directory_create(dir); } catch (mkdir_err) { delete(mkdir_err); };
	};
	return dir;
}

///@desc 返回皮肤索引 index.json 的路径
///@returns {String} 索引文件路径
function skin_index_path() {
	return skin_root_dir() + "index.json";
}

///@desc 返回打击音缓存目录
///@returns {String} skin_sfx 目录路径
function skin_sfx_dir() {
	return game_save_id + "skin_sfx/";
}

///@desc 删除打击音缓存目录
///@returns {Undefined} 无
function skin_sfx_cleanup() {
	var dir = skin_sfx_dir();
	// 缓存目录不存在则不用删
	if (!directory_exists(dir)) then return;
	skin_log($"cleanup {dir}");
	skin_folder_rmdir(dir);
}

///@desc 把目录路径规范成正斜杠并以斜杠结尾
///@param {String} _dir 原始目录
///@returns {String} 规范化后的目录
function skin_norm_dir(_dir) {
	var s = string_replace_all(string(_dir ?? ""), "\\", "/");
	// 非空且末尾不是斜杠时补上
	if (string_length(s) && string_char_at(s, string_length(s)) != "/") then s += "/";
	return s;
}

///@desc 把文件名接到规范化目录后面
///@param {String} _dir 目录
///@param {String} _name 文件名
///@returns {String} 拼接后的路径
function skin_join(_dir, _name) {
	return skin_norm_dir(_dir) + string(_name);
}

///@desc 打印皮肤系统日志
///@param {Any} _message 日志内容
///@returns {Undefined} 无
function skin_log(_message) {
	print($"[Skin] {string(_message ?? "")}");
}

///@desc 读取 zip 后端最近一次错误详情
///@returns {String} 错误文本，失败时为空
function skin_zip_last_error() {
	var detail = "";
	// 后端调用失败时忽略异常
	try { detail = string(unicode_zip_backend_last_error() ?? ""); } catch (err_e) { delete(err_e); };
	return detail;
}

///@desc 记录并弹出皮肤错误对话框
///@param {Any} _message 错误内容
///@returns {Undefined} 无
function skin_error(_message) {
	var title = lang("skin.errorTitle", "Skin");
	var text = string(_message ?? "");
	skin_log($"error: {text}");
	var buttons = [msgbox_button(lang("common.ok", "OK"))];
	// 原生对话框可用时同步弹出，否则异步
	if (i_wbox_native_ready()) {
		msgbox_error_sync(text, title, buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
	} else {
		msgbox_error_async(text, title, buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
	};
}

///@desc 读取文本文件并去掉 UTF-8 BOM
///@param {String} _path 文件路径
///@returns {String} 文件文本，失败时为空
function skin_read_text(_path) {
	// 文件或缓冲无效则返回空
	if (!file_exists(_path)) then return "";
	var buf = buffer_load(_path);
	if (!buffer_exists(buf)) then return "";
	buffer_seek(buf, buffer_seek_start, 0);
	var text = buffer_read(buf, buffer_text);
	buffer_delete(buf);
	// 去掉开头的 UTF-8 BOM
	if (string_length(text) && ord(string_char_at(text, 1)) == 65279) then text = string_delete(text, 1, 1);
	return text;
}

///@desc 去掉 YAML 值两端成对的引号
///@param {String} _s 原始字符串
///@returns {String} 去引号后的文本
function skin_yaml_unquote(_s) {
	var s = string_trim(string(_s ?? ""));
	var n = string_length(s);
	// 两端成对引号才剥掉
	if (n >= 2) {
		var a = string_char_at(s, 1);
		var b = string_char_at(s, n);
		if ((a == "\"" && b == "\"") || (a == "'" && b == "'")) {
			s = string_copy(s, 2, n - 2);
		};
	};
	return s;
}

///@desc 把 YAML 数字或十六进制解析成数值
///@param {String} _s 原始文本
///@returns {Real} 解析结果，失败为 0
function skin_yaml_number(_s) {
	var s = string_trim(string(_s ?? ""));
	if (!string_length(s)) then return 0;
	// 0x 开头按十六进制逐位累加
	if (string_lower(string_copy(s, 1, 2)) == "0x") {
		var hex = string_delete(s, 1, 2);
		var v = 0;
		for (var i = 1; i <= string_length(hex); i++) {
			var ch = string_upper(string_char_at(hex, i));
			var d = string_pos(ch, "0123456789ABCDEF") - 1;
			// 遇到非十六进制字符就停
			if (d < 0) then break;
			v = v * 16 + d;
		};
		return v;
	};
	// 普通数字失败则回退为 0
	try { return real(s); } catch (e) { delete(e); return 0; };
}

///@desc 解析 info.yml 的扁平键值
///@param {String} _text YAML 文本
///@returns {Struct} 皮肤信息结构
function skin_yaml_parse(_text) {
	var info = {
		name: "",
		author: "",
		description: "",
		hitFx: [1, 1],
		hitFxDuration: 0.5,
		hitFxScale: 1,
		hitFxRotate: false,
		hideParticles: false,
		hitFxTinted: true,
		holdAtlas: [50, 50],
		holdAtlasMH: [50, 50],
		holdKeepHead: false,
		holdRepeat: false,
		holdCompact: false,
		colorPerfect: 0xe1ffec9f,
		colorGood: 0xebb4e1ff
	};
	var lines = string_split(string_replace_all(string(_text ?? ""), "\r", ""), "\n");
	for (var i = 0; i < array_length(lines); i++) {
		var yaml_line = string_trim(lines[i]);
		// 空行和注释跳过
		if (!string_length(yaml_line) || string_char_at(yaml_line, 1) == "#") then continue;
		var sep = string_pos(":", yaml_line);
		if (sep <= 0) then continue;
		var key = string_trim(string_copy(yaml_line, 1, sep - 1));
		var raw = string_trim(string_copy(yaml_line, sep + 1, string_length(yaml_line) - sep));
		// 布尔、数组和标量分开写入
		if (string_lower(raw) == "true" || string_lower(raw) == "false") {
			var flag = (string_lower(raw) == "true");
			if (key == "hitFxRotate") then info.hitFxRotate = flag;
			else if (key == "hideParticles") then info.hideParticles = flag;
			else if (key == "hitFxTinted") then info.hitFxTinted = flag;
			else if (key == "holdKeepHead") then info.holdKeepHead = flag;
			else if (key == "holdRepeat") then info.holdRepeat = flag;
			else if (key == "holdCompact") then info.holdCompact = flag;
			continue;
		};
		if (string_char_at(raw, 1) == "[") {
			var inner = string_replace_all(string_replace_all(raw, "[", ""), "]", "");
			var parts = string_split(inner, ",");
			var a = (array_length(parts) > 0) ? skin_yaml_number(parts[0]) : 0;
			var b = (array_length(parts) > 1) ? skin_yaml_number(parts[1]) : a;
			if (key == "hitFx") then info.hitFx = [max(1, floor(a)), max(1, floor(b))];
			else if (key == "holdAtlas") then info.holdAtlas = [max(0, floor(a)), max(0, floor(b))];
			else if (key == "holdAtlasMH") then info.holdAtlasMH = [max(0, floor(a)), max(0, floor(b))];
			continue;
		};
		if (key == "name") then info.name = skin_yaml_unquote(raw);
		else if (key == "author") then info.author = skin_yaml_unquote(raw);
		else if (key == "description") then info.description = skin_yaml_unquote(raw);
		else if (key == "hitFxDuration") then info.hitFxDuration = max(0.05, skin_yaml_number(raw));
		else if (key == "hitFxScale") then info.hitFxScale = max(0.05, skin_yaml_number(raw));
		else if (key == "colorPerfect") then info.colorPerfect = floor(skin_yaml_number(raw));
		else if (key == "colorGood") then info.colorGood = floor(skin_yaml_number(raw));
	};
	return info;
}

///@desc 校验皮肤信息是否合法
///@param {Struct} _info 皮肤信息
///@returns {String} 错误文案，合法时为空
function skin_info_verify(_info) {
	// 名称、描述或打击帧数不合法则返回错误文案
	if (!is_struct(_info)) then return lang("skin.invalidInfo", "Invalid info.yml");
	if (!string_length(string(_info.name ?? ""))) then return lang("skin.invalidInfo", "Invalid info.yml");
	if (string_length(_info.name) > 100) then return lang("skin.invalidInfo", "Invalid info.yml");
	if (string_length(string(_info.description ?? "")) > 1000) then return lang("skin.invalidInfo", "Invalid info.yml");
	var cells = real(_info.hitFx[0]) * real(_info.hitFx[1]);
	if (cells < 1 || cells > 10240) then return lang("skin.invalidInfo", "Invalid info.yml");
	return "";
}

///@desc 把 32 位颜色转成 GameMaker 颜色
///@param {Real} _c 含或不含 alpha 的整数颜色
///@returns {Real} RGB 颜色
function skin_color_from_u32(_c) {
	var c = floor(real(_c));
	// 超过 24 位时丢掉高位 alpha
	if (c > 16777215) {
		var a = (c >> 24) & 255;
		var r = (c >> 16) & 255;
		var g = (c >> 8) & 255;
		var b = c & 255;
		return make_colour_rgb(r, g, b);
	};
	return make_colour_rgb((c >> 16) & 255, (c >> 8) & 255, c & 255);
}

///@desc 生成空的皮肤索引
///@returns {Struct} 默认选中与空包列表
function skin_index_default() {
	return { selected: SKIN_DEFAULT_ID, packs: [] };
}

///@desc 从内存或 index.json 载入皮肤索引
///@returns {Struct} 索引结构
function skin_index_load() {
	// 已有内存缓存则直接返回
	if (variable_global_exists("skin_index_mem") && is_struct(global.skin_index_mem)) then return global.skin_index_mem;
	var path = skin_index_path();
	if (!file_exists(path)) {
		global.skin_index_mem = skin_index_default();
		return global.skin_index_mem;
	};
	var text = skin_read_text(path);
	if (!string_length(text)) {
		global.skin_index_mem = skin_index_default();
		return global.skin_index_mem;
	};
	try {
		var data = json_parse(text);
		if (!is_struct(data)) then data = skin_index_default();
		if (!is_array(data[$ "packs"])) then data.packs = [];
		if (!is_string(data[$ "selected"])) then data.selected = SKIN_DEFAULT_ID;
		global.skin_index_mem = data;
		return data;
	} catch (parse_err) {
		delete(parse_err);
		// 解析失败时退回空索引
		global.skin_index_mem = skin_index_default();
		return global.skin_index_mem;
	};
}

///@desc 从皮肤包提取索引用的摘要字段
///@param {Struct} _pack 皮肤包
///@returns {Any} 摘要结构，包无效时为 undefined
function skin_index_entry(_pack) {
	// 包无效时不写入索引
	if (!is_struct(_pack)) then return undefined;
	var pack_id = string(_pack[$ "skin_id"] ?? _pack[$ "id"] ?? "");
	return {
		skin_id: pack_id,
		folder: string(_pack[$ "folder"] ?? pack_id),
		name: string(_pack[$ "name"] ?? ""),
		author: string(_pack[$ "author"] ?? ""),
		description: string(_pack[$ "description"] ?? "")
	};
}

///@desc 把皮肤索引写回 index.json 并更新内存
///@param {Struct} _index 索引
///@returns {Undefined} 无
function skin_index_save(_index) {
	if (!is_struct(_index)) then return;
	var packs = [];
	if (is_array(_index.packs)) {
		for (var i = 0; i < array_length(_index.packs); i++) {
			var entry = skin_index_entry(_index.packs[i]);
			// 只保留带有效 id 的包
			if (is_struct(entry) && string_length(entry.skin_id)) then array_add(packs, entry);
		};
	};
	var data = { selected: string(_index.selected ?? SKIN_DEFAULT_ID), packs: packs };
	global.skin_index_mem = data;
	global.skin_list_ok = true;
	var path = skin_index_path();
	var text = json_stringify(data, true);
	var buf = buffer_create(string_byte_length(text) + 1, buffer_fixed, 1);
	buffer_write(buf, buffer_text, text);
	buffer_save(buf, path);
	buffer_delete(buf);
}

///@desc 在根目录或其一级子目录中查找 info.yml
///@param {String} _root 解压根目录
///@returns {String} 含 info.yml 的目录，找不到为空
function skin_find_info_dir(_root) {
	var root = skin_norm_dir(_root);
	// 根目录已有 info.yml 则不用再扫子目录
	if (file_exists(root + "info.yml")) then return root;
	var found = "";
	try { found = file_find_first(root + "*", fa_directory); } catch (e) { delete(e); found = ""; };
	var dirs = [];
	while (string_length(found)) {
		if (found != "." && found != "..") then array_add(dirs, found);
		found = file_find_next();
	};
	file_find_close();
	for (var i = 0; i < array_length(dirs); i++) {
		var nested = skin_join(root, dirs[i]);
		// 只看一级子目录
		if (file_exists(nested + "info.yml")) then return nested;
	};
	return "";
}

///@desc 返回皮肤包必需文件名列表
///@returns {Array} 文件名数组
function skin_required_files() {
	return ["info.yml", "click.png", "click_mh.png", "drag.png", "drag_mh.png",
		"flick.png", "flick_mh.png", "hold.png", "hold_mh.png", "hit_fx.png"];
}

///@desc 检查目录是否缺必需文件
///@param {String} _dir 皮肤目录
///@returns {String} 缺失文件名，齐全时为空
function skin_missing_file(_dir) {
	var files = skin_required_files();
	for (var i = 0; i < array_length(files); i++) {
		// 返回第一个缺失文件
		if (!file_exists(skin_join(_dir, files[i]))) then return files[i];
	};
	return "";
}

///@desc 把名称收成可用的文件夹 id
///@param {String} _name 原始名称
///@returns {String} 仅含字母数字和 _- 的 id
function skin_sanitize_id(_name) {
	var s = string(_name ?? "skin");
	var out = "";
	for (var i = 1; i <= string_length(s); i++) {
		var ch = string_char_at(s, i);
		// 非法字符换成下划线
		var ok = (ch == "_") || (ch == "-")
			|| (ch >= "0" && ch <= "9")
			|| (ch >= "a" && ch <= "z")
			|| (ch >= "A" && ch <= "Z");
		out += ok ? ch : "_";
	};
	// 空结果用 skin，并截断到 40 字符
	if (!string_length(out)) then out = "skin";
	if (string_length(out) > 40) then out = string_copy(out, 1, 40);
	return out;
}

///@desc 在皮肤根目录下生成不冲突的文件夹名
///@param {String} _base 名称前缀
///@returns {String} 未占用的文件夹名
function skin_unique_folder(_base) {
	var root = skin_root_dir();
	var skin_id = _base + "_" + string(irandom_range(10000, 99999));
	var guard = 0;
	// 已存在则换随机后缀，最多试 32 次
	while (directory_exists(root + skin_id) && guard < 32) {
		skin_id = _base + "_" + string(irandom_range(10000, 99999));
		guard++;
	};
	return skin_id;
}

///@desc 列出仍存在的皮肤包并修正当前选中项
///@returns {Struct} 过滤后的索引
function skin_list() {
	var index = skin_index_load();
	// 本会话已过滤过则直接返回
	if (variable_global_exists("skin_list_ok") && global.skin_list_ok) then return index;
	var packs = is_array(index.packs) ? index.packs : [];
	var live = [];
	for (var i = 0; i < array_length(packs); i++) {
		var pack = packs[i];
		if (!is_struct(pack)) then continue;
		var folder = skin_join(skin_root_dir(), string(pack[$ "folder"] ?? pack[$ "skin_id"] ?? pack[$ "id"] ?? ""));
		var info_dir = skin_find_info_dir(folder);
		// 磁盘上已没有 info.yml 的包丢掉
		if (!string_length(info_dir)) then continue;
		array_add(live, skin_index_entry(pack));
	};
	index.packs = live;
	var still = (string(index.selected) == SKIN_DEFAULT_ID);
	for (var j = 0; j < array_length(live); j++) {
		if (string(live[j].skin_id) == string(index.selected)) then still = true;
	};
	// 选中项已不在列表时回到默认皮肤
	if (!still) then index.selected = SKIN_DEFAULT_ID;
	global.skin_list_ok = true;
	if (array_length(live) != array_length(packs) || !still) then skin_index_save(index);
	else global.skin_index_mem = index;
	return index;
}

///@desc 返回当前选中的皮肤 id
///@returns {String} 皮肤 id，默认时为空串
function skin_selected_id() {
	return string(skin_list().selected ?? SKIN_DEFAULT_ID);
}

///@desc 把选中皮肤写入索引
///@param {String} _id 皮肤 id
///@returns {Undefined} 无
function skin_set_selected(_id) {
	var index = skin_list();
	index.selected = string(_id ?? SKIN_DEFAULT_ID);
	skin_index_save(index);
}

///@desc 组装设置菜单用的皮肤列表，首位为默认皮肤
///@returns {Array} 菜单项数组
function skin_menu_items() {
	var items = [{ skin_id: SKIN_DEFAULT_ID, name: lang("skin.default", "Default"), author: "", description: "" }];
	var index = skin_list();
	// 默认皮肤固定在第一项，后面接已安装的包
	for (var i = 0; i < array_length(index.packs); i++) {
		array_add(items, index.packs[i]);
	};
	return items;
}

///@desc 删除皮肤精灵，内置音符精灵除外
///@param {Real} _spr 精灵资源
///@returns {Undefined} 无
function skin_destroy_sprite(_spr) {
	// 内置音符和打击特效不删
	if (sprite_exists(_spr) && _spr != note_tap && _spr != note_drag && _spr != note_flick
		&& _spr != note_hold_head && _spr != note_hold_body && _spr != note_hold_end
		&& _spr != effect) {
		try { sprite_delete(_spr); } catch (e) { delete(e); };
	};
}

///@desc 释放皮肤音效及其缓冲，内置音效除外
///@param {Any} _snd 音效资源
///@param {Real} _buf 关联缓冲，没有则为 -1
///@returns {Undefined} 无
function skin_destroy_sound(_snd, _buf = -1) {
	// 内置打击音直接返回
	if (is_undefined(_snd) || _snd == snd_note_tap || _snd == snd_note_drag || _snd == snd_note_flick) then return;
	// 有缓冲则释放缓冲音，否则销毁流
	if (buffer_exists(_buf)) {
		if (audio_exists(_snd)) {
			try { audio_free_buffer_sound(_snd); } catch (e) { delete(e); };
		};
		try { buffer_delete(_buf); } catch (e2) { delete(e2); };
		return;
	};
	if (audio_exists(_snd)) {
		try { audio_destroy_stream(_snd); } catch (e3) { delete(e3); };
	};
}

///@desc 释放皮肤的 FMOD 音效
///@param {Real} _snd FMOD 声音句柄
///@returns {Undefined} 无
function skin_destroy_fmod(_snd) {
	// 句柄无效或没有 FMOD 扩展则返回
	if (!is_real(_snd) || _snd <= 0) then return;
	if (!extension_exists("FMOD")) then return;
	try { fmod_sound_release(_snd); } catch (e) { delete(e); };
}

///@desc 卸载皮肤包的精灵、打击音和 FMOD 资源
///@param {Struct} _pack 皮肤包
///@returns {Undefined} 无
function skin_pack_unload(_pack) {
	if (!is_struct(_pack)) then return;
	// 先忘掉长条切片，再逐个释放精灵和音效
	if (struct_exists(_pack, "hold_head") && struct_exists(_pack, "hold_body") && struct_exists(_pack, "hold_tail")) {
		hold_strip_forget(_pack.hold_head, _pack.hold_body, _pack.hold_tail);
	};
	if (struct_exists(_pack, "hold_head_mh") && struct_exists(_pack, "hold_body_mh") && struct_exists(_pack, "hold_tail_mh")) {
		hold_strip_forget(_pack.hold_head_mh, _pack.hold_body_mh, _pack.hold_tail_mh);
	};
	var names = ["click", "click_mh", "drag", "drag_mh", "flick", "flick_mh",
		"hold", "hold_mh", "hit_fx", "hold_head", "hold_body", "hold_tail",
		"hold_head_mh", "hold_body_mh", "hold_tail_mh"];
	for (var i = 0; i < array_length(names); i++) {
		if (struct_exists(_pack, names[i])) then skin_destroy_sprite(_pack[$ names[i]]);
	};
	var sounds = ["click", "drag", "flick"];
	for (var s = 0; s < array_length(sounds); s++) {
		var stem = sounds[s];
		skin_destroy_sound(_pack[$ "sfx_" + stem], _pack[$ "sfx_buf_" + stem] ?? -1);
	};
	var fmods = ["fmod_click", "fmod_drag", "fmod_flick"];
	for (var f = 0; f < array_length(fmods); f++) {
		if (struct_exists(_pack, fmods[f])) then skin_destroy_fmod(_pack[$ fmods[f]]);
	};
}

///@desc 设置拷贝表面时的混合与颜色写入
///@returns {Undefined} 无
function skin_copy_surface_begin() {
	gpu_set_blendenable(true);
	gpu_set_colourwriteenable(true, true, true, true);
	gpu_set_blendmode_ext(bm_one, bm_zero);
}

///@desc 把混合模式恢复为正常
///@param {Bool} _pushed 保留参数，当前未使用
///@returns {Undefined} 无
function skin_copy_surface_end(_pushed = false) {
	gpu_set_blendmode(bm_normal);
}

///@desc 从文件加载精灵并把原点设到中心
///@param {String} _path 图片路径
///@returns {Real} 精灵 id，失败为 -1
function skin_add_centered(_path) {
	// 文件不存在或精灵无效则返回 -1
	if (!file_exists(_path)) then return -1;
	var spr = sprite_add(_path, 1, false, false, 0, 0);
	if (!asset_sprite_valid(spr)) then return -1;
	sprite_set_offset(spr, sprite_get_width(spr) * 0.5, sprite_get_height(spr) * 0.5);
	return spr;
}

///@desc 从源精灵裁出矩形并指定原点
///@param {Real} _src 源精灵
///@param {Real} _x0 源矩形左
///@param {Real} _y0 源矩形上
///@param {Real} _cw 宽度
///@param {Real} _ch 高度
///@param {Real} _ox 原点 x
///@param {Real} _oy 原点 y
///@returns {Real} 新精灵 id，失败为 -1
function skin_crop_rect(_src, _x0, _y0, _cw, _ch, _ox, _oy) {
	// 源无效或尺寸不足则放弃裁切
	if (!sprite_exists(_src) || _cw < 1 || _ch < 1) then return -1;
	var surf = surface_create(_cw, _ch);
	if (!surface_exists(surf)) then return -1;
	var pushed = skin_copy_surface_begin();
	surface_set_target(surf);
	draw_clear_alpha(c_black, 0);
	draw_sprite_part(_src, 0, _x0, _y0, _cw, _ch, 0, 0);
	surface_reset_target();
	skin_copy_surface_end(pushed);
	var spr = sprite_create_from_surface(surf, 0, 0, _cw, _ch, false, false, _ox, _oy);
	surface_free(surf);
	if (!asset_sprite_valid(spr)) then return -1;
	skin_sprite_keep(spr);
	return spr;
}

///@desc 保留精灵引用的空钩子
///@param {Real} _spr 精灵资源
///@returns {Undefined} 无
function skin_sprite_keep(_spr) {
}

///@desc 按整宽横条裁切精灵
///@param {Real} _src 源精灵
///@param {Real} _y0 起始 y
///@param {Real} _h 高度
///@param {Real} _ox 原点 x
///@param {Real} _oy 原点 y
///@returns {Real} 新精灵 id，失败为 -1
function skin_crop_band(_src, _y0, _h, _ox, _oy) {
	// 高度不足则不裁
	if (!sprite_exists(_src) || _h < 1) then return -1;
	return skin_crop_rect(_src, 0, _y0, sprite_get_width(_src), _h, _ox, _oy);
}

///@desc 扫描精灵不透明像素的包围盒
///@param {Real} _spr 精灵资源
///@returns {Any} 包围盒结构，精灵无效时为 undefined
function skin_sprite_opaque_rect(_spr) {
	if (!sprite_exists(_spr)) then return undefined;
	var w = sprite_get_width(_spr);
	var h = sprite_get_height(_spr);
	if (w < 1 || h < 1) then return undefined;
	var surf = surface_create(w, h);
	// 表面创建失败时退回整图范围
	if (!surface_exists(surf)) then return { x0: 0, y0: 0, x1: w - 1, y1: h - 1 };
	skin_copy_surface_begin();
	surface_set_target(surf);
	draw_clear_alpha(c_black, 0);
	draw_sprite_part(_spr, 0, 0, 0, w, h, 0, 0);
	surface_reset_target();
	skin_copy_surface_end();
	var buf = buffer_create(w * h * 4, buffer_fixed, 1);
	buffer_get_surface(buf, surf, 0);
	surface_free(surf);
	var px0 = w, py0 = h, px1 = -1, py1 = -1;
	var pitch = w * 4;
	for (var py = 0; py < h; py++) {
		var row = py * pitch;
		for (var px = 0; px < w; px++) {
			// 只统计 alpha 大于 0 的像素
			if (buffer_peek(buf, row + px * 4 + 3, buffer_u8) > 0) {
				if (px < px0) then px0 = px;
				if (py < py0) then py0 = py;
				if (px > px1) then px1 = px;
				if (py > py1) then py1 = py;
			}
		}
	};
	buffer_delete(buf);
	// 全透明则退回整图
	if (px1 < 0) then return { x0: 0, y0: 0, x1: w - 1, y1: h - 1 };
	return { x0: px0, y0: py0, x1: px1, y1: py1 };
}

///@desc 裁掉精灵四周空白并按原点模式重设偏移
///@param {Real} _spr 精灵资源
///@param {String} _origin 原点模式，bottom 为底边中心，否则为中心
///@returns {Real} 裁切后的精灵，失败时仍为原精灵
function skin_sprite_trim_empty(_spr, _origin = "center") {
	if (!sprite_exists(_spr)) then return _spr;
	var w = sprite_get_width(_spr);
	var h = sprite_get_height(_spr);
	var rect = skin_sprite_opaque_rect(_spr);
	// 没有不透明区域时只改偏移
	if (!is_struct(rect)) {
		sprite_set_offset(_spr, w * 0.5, (_origin == "bottom") ? h : h * 0.5);
		return _spr;
	};
	var cw = max(1, rect.x1 - rect.x0 + 1);
	var ch = max(1, rect.y1 - rect.y0 + 1);
	var ox = cw * 0.5;
	var oy = (_origin == "bottom") ? ch : ch * 0.5;
	// 尺寸未变则不重新裁切
	if (cw == w && ch == h && rect.x0 == 0 && rect.y0 == 0) {
		sprite_set_offset(_spr, ox, oy);
		skin_log($"trim keep {w}x{h} origin=({ox},{oy})");
		return _spr;
	};
	var cropped = skin_crop_rect(_spr, rect.x0, rect.y0, cw, ch, ox, oy);
	// 裁切失败则保留原精灵
	if (!asset_sprite_valid(cropped)) {
		sprite_set_offset(_spr, ox, oy);
		return _spr;
	};
	skin_log($"trim {w}x{h} -> {cw}x{ch} from ({rect.x0},{rect.y0}) origin=({ox},{oy})");
	skin_destroy_sprite(_spr);
	return cropped;
}

///@desc 按图集高度把长条切成尾、身、头
///@param {Real} _src 长条精灵
///@param {Array} _atlas 尾高与头高
///@returns {Struct} tail、body、head 精灵，无法切时为 -1
function skin_split_hold(_src, _atlas) {
	if (!sprite_exists(_src)) then return { tail: -1, body: -1, head: -1 };
	var h = sprite_get_height(_src);
	var w = sprite_get_width(_src);
	var tail_h = max(0, floor(real(_atlas[0])));
	var head_h = max(0, floor(real(_atlas[1])));
	// 头尾高度占满或超过整图则放弃
	if (tail_h + head_h >= h) {
		return { tail: -1, body: -1, head: -1 };
	};
	tail_h = max(1, tail_h);
	head_h = max(1, head_h);
	if (tail_h + head_h >= h) {
		return { tail: -1, body: -1, head: -1 };
	};
	var body_h = h - tail_h - head_h;
	return {
		tail: skin_crop_band(_src, 0, tail_h, w * 0.5, tail_h),
		body: skin_crop_band(_src, tail_h, body_h, w * 0.5, body_h),
		head: skin_crop_band(_src, h - head_h, head_h, w * 0.5, head_h * 0.5)
	};
}

///@desc 确保默认打击音音频组已加载
///@returns {Undefined} 无
function skin_hitsounds_ensure_default() {
	// 渲染模式或已加载则不再请求
	if (variable_global_exists("render_mode") && global.render_mode) then return;
	if (!audio_group_is_loaded(audiogroup_hitsounds)) {
		audio_group_load(audiogroup_hitsounds);
		global.default_hitsounds_load_requested = true;
	};
}

///@desc 按扩展名查找某个音效文件
///@param {String} _dir 皮肤目录
///@param {String} _stem 文件主名
///@returns {String} 找到的路径，没有则为空
function skin_sound_path(_dir, _stem) {
	var exts = [".ogg", ".oga", ".opus", ".wav", ".wave", ".mp3", ".mpga",
		".m4a", ".mp4", ".aac", ".m4b", ".flac", ".aiff", ".aif", ".aifc", ".caf"];
	for (var i = 0; i < array_length(exts); i++) {
		var path = skin_join(_dir, _stem + exts[i]);
		// 按扩展名顺序返回第一个存在的文件
		if (file_exists(path)) then return path;
	};
	return "";
}

///@desc 读取缓冲中的一个无符号字节
///@param {Real} _buf 缓冲
///@param {Real} _off 偏移
///@returns {Real} 字节值，越界为 -1
function skin_buf_u8(_buf, _off) {
	// 越界返回 -1
	if (_off < 0 || _off >= buffer_get_size(_buf)) then return -1;
	buffer_seek(_buf, buffer_seek_start, _off);
	return buffer_read(_buf, buffer_u8);
}

///@desc 把缓冲中连续字节读成标签字符串
///@param {Real} _buf 缓冲
///@param {Real} _off 起始偏移
///@param {Real} _n 字节数
///@returns {String} 标签文本
function skin_buf_tag(_buf, _off, _n = 4) {
	var s = "";
	for (var i = 0; i < _n; i++) {
		var b = skin_buf_u8(_buf, _off + i);
		// 中途越界则返回已读部分
		if (b < 0) then return s;
		s += chr(b);
	};
	return s;
}

///@desc 跳过 ID3 头，返回音频负载偏移
///@param {Real} _buf 缓冲
///@param {Real} _off 起始偏移
///@param {Real} _size 缓冲大小
///@returns {Real} 负载起始偏移
function skin_id3_payload_off(_buf, _off, _size) {
	if (_off + 10 > _size) then return _off;
	// 不是 ID3 则原样返回偏移
	if (skin_buf_tag(_buf, _off, 3) != "ID3") then return _off;
	var flags = skin_buf_u8(_buf, _off + 5);
	var tag = ((skin_buf_u8(_buf, _off + 6) & 127) << 21)
		| ((skin_buf_u8(_buf, _off + 7) & 127) << 14)
		| ((skin_buf_u8(_buf, _off + 8) & 127) << 7)
		| (skin_buf_u8(_buf, _off + 9) & 127);
	var start = _off + 10 + tag;
	// 带 footer 标志时再跳过 10 字节
	if ((flags & 16) != 0) then start += 10;
	return clamp(start, _off + 10, _size);
}

///@desc 判断 Ogg 页里是 Opus、Vorbis、FLAC 还是普通 ogg
///@param {Real} _buf 缓冲
///@param {Real} _off OggS 偏移
///@param {Real} _size 缓冲大小
///@returns {String} 格式名
function skin_sound_ogg_kind(_buf, _off, _size) {
	// 页头不够时当作普通 ogg
	if (_off + 28 > _size) then return "ogg";
	var nsegs = skin_buf_u8(_buf, _off + 26);
	if (nsegs < 0) then return "ogg";
	var payload = _off + 27 + nsegs;
	if (payload + 8 > _size) then return "ogg";
	var head8 = skin_buf_tag(_buf, payload, 8);
	if (string_copy(head8, 1, 8) == "OpusHead") then return "opus";
	if (string_copy(head8, 1, 5) == "Speex") then return "ogg";
	if (skin_buf_u8(_buf, payload) == 1 && skin_buf_tag(_buf, payload + 1, 6) == "vorbis") then return "ogg";
	if (skin_buf_u8(_buf, payload) == 127 && skin_buf_tag(_buf, payload + 1, 4) == "FLAC") then return "flac";
	return "ogg";
}

///@desc 根据 MPEG 同步字判断是 aac 还是 mp3
///@param {Real} _b0 第一字节
///@param {Real} _b1 第二字节
///@returns {String} 格式名，不是同步字则为空
function skin_sound_mpeg_kind(_b0, _b1) {
	if (_b0 != 255 || (_b1 & 224) != 224) then return "";
	var _layer = (_b1 >> 1) & 3;
	// layer 为 0 视为 aac，否则是 mp3
	if (_layer == 0) then return "aac";
	return "mp3";
}

///@desc 在指定偏移识别音频容器格式
///@param {Real} _buf 缓冲
///@param {Real} _off 起始偏移
///@param {Real} _size 缓冲大小
///@returns {String} 格式名，无法识别则为空
function skin_sound_format_at(_buf, _off, _size) {
	if (_off < 0 || _off + 4 > _size) then return "";
	// 跳过前导零和 UTF-8 BOM，再按魔数识别
	while (_off + 4 <= _size && _off < 64 && skin_buf_u8(_buf, _off) == 0) _off++;
	if (_off + 3 <= _size && skin_buf_u8(_buf, _off) == 239
		&& skin_buf_u8(_buf, _off + 1) == 187 && skin_buf_u8(_buf, _off + 2) == 191) {
		_off += 3;
	};
	var tag4 = skin_buf_tag(_buf, _off, 4);
	if (tag4 == "OggS") then return skin_sound_ogg_kind(_buf, _off, _size);
	if (tag4 == "RIFF" || tag4 == "RF64") {
		if (skin_buf_tag(_buf, _off + 8, 4) == "WAVE") then return "wav";
		return "";
	};
	if (tag4 == "FORM") {
		var form = skin_buf_tag(_buf, _off + 8, 4);
		if (form == "AIFF" || form == "AIFC") then return "aiff";
		return "";
	};
	if (tag4 == "fLaC") then return "flac";
	if (tag4 == "caff") then return "caf";
	if (skin_buf_tag(_buf, _off, 3) == "ID3") then return "id3";
	var search = min(_size, _off + 64);
	for (var ft = _off; ft + 8 <= search; ft++) {
		if (skin_buf_tag(_buf, ft, 4) == "ftyp") then return "m4a";
	};
	var mpeg = skin_sound_mpeg_kind(skin_buf_u8(_buf, _off), skin_buf_u8(_buf, _off + 1));
	if (string_length(mpeg)) then return mpeg;
	return "";
}

///@desc 跳过 BOM 和 ID3 后扫描音频格式
///@param {Real} _buf 缓冲
///@param {Real} _size 缓冲大小
///@returns {String} 格式名，无法识别则为空
function skin_sound_format_scan(_buf, _size) {
	var off = 0;
	if (_size >= 3 && skin_buf_u8(_buf, 0) == 239 && skin_buf_u8(_buf, 1) == 187 && skin_buf_u8(_buf, 2) == 191) {
		off = 3;
	};
	repeat (3) {
		var next = skin_id3_payload_off(_buf, off, _size);
		// 最多剥三层 ID3，位置不再前进就停
		if (next == off) then break;
		off = next;
	};
	var fmt = skin_sound_format_at(_buf, off, _size);
	// 当前位置已是有效格式则不用再扫
	if (string_length(fmt) && fmt != "id3") then return fmt;
	var lim = min(_size - 4, 1024);
	for (var i = off; i <= lim; i++) {
		var mag = skin_buf_tag(_buf, i, 4);
		if (mag == "OggS") then return skin_sound_ogg_kind(_buf, i, _size);
		if (mag == "RIFF" || mag == "RF64") {
			if (skin_buf_tag(_buf, i + 8, 4) == "WAVE") then return "wav";
		};
		if (mag == "fLaC") then return "flac";
		if (mag == "FORM") {
			var form = skin_buf_tag(_buf, i + 8, 4);
			if (form == "AIFF" || form == "AIFC") then return "aiff";
		};
		if (mag == "caff") then return "caf";
		if (mag == "ftyp") then return "m4a";
		var mpeg = skin_sound_mpeg_kind(skin_buf_u8(_buf, i), skin_buf_u8(_buf, i + 1));
		if (string_length(mpeg)) then return mpeg;
	};
	return "";
}

///@desc 读取文件并识别音频格式
///@param {String} _path 文件路径
///@returns {String} 格式名，失败为空
function skin_sound_format(_path) {
	// 读不进来就当无法识别
	if (!file_exists(_path)) then return "";
	var buf = -1;
	try { buf = buffer_load(_path); } catch (e) { delete(e); return ""; };
	if (!buffer_exists(buf)) then return "";
	var fmt = skin_sound_format_scan(buf, buffer_get_size(buf));
	buffer_delete(buf);
	return fmt;
}

///@desc 判断扩展名是否与识别出的格式相符
///@param {String} _fmt 格式名
///@param {String} _ext 带点的扩展名
///@returns {Bool} 是否匹配
function skin_sound_ext_matches(_fmt, _ext) {
	// 按识别出的格式对照允许的扩展名
	switch (string(_fmt)) {
		case "ogg": return (_ext == ".ogg" || _ext == ".oga");
		case "opus": return (_ext == ".opus" || _ext == ".ogg");
		case "wav": return (_ext == ".wav" || _ext == ".wave");
		case "mp3": return (_ext == ".mp3" || _ext == ".mpga");
		case "m4a": return (_ext == ".m4a" || _ext == ".mp4" || _ext == ".aac" || _ext == ".m4b");
		case "aac": return (_ext == ".aac" || _ext == ".adts");
		case "flac": return (_ext == ".flac");
		case "aiff": return (_ext == ".aiff" || _ext == ".aif" || _ext == ".aifc");
		case "caf": return (_ext == ".caf");
		default: return (_ext == "." + string(_fmt));
	};
}

///@desc 必要时把音效拷到缓存并剥掉 ID3
///@param {String} _path 源路径
///@param {Bool} _force_cache 是否强制写入缓存
///@returns {String} 可播放路径
function skin_sound_prepared_path(_path, _force_cache = false) {
	var src = string(_path ?? "");
	if (!string_length(src) || !file_exists(src)) then return src;
	var fmt = skin_sound_format(src);
	if (fmt == "id3") then fmt = "mp3";
	// 格式未知且不强制缓存则用原路径
	if (!string_length(fmt)) {
		skin_log($"sfx format unknown path={src}");
		if (!_force_cache) then return src;
		fmt = string_delete(string_lower(filename_ext(src)), 1, 1);
		if (!string_length(fmt)) then fmt = "wav";
	};
	var ext = string_lower(filename_ext(src));
	// 扩展名已匹配则不必拷贝
	if (skin_sound_ext_matches(fmt, ext) && !_force_cache) then return src;
	var dir = skin_sfx_dir();
	if (!directory_exists(dir)) {
		try { directory_create(dir); } catch (mkdir_err) { delete(mkdir_err); };
	};
	var dest = dir + md5_string_utf8(src) + "." + fmt;
	// 缓存已存在则直接复用
	if (file_exists(dest)) then return dest;
	var buf = -1;
	try { buf = buffer_load(src); } catch (load_err) { delete(load_err); buf = -1; };
	if (!buffer_exists(buf)) then return src;
	var size = buffer_get_size(buf);
	var start = 0;
	if (size >= 10) {
		buffer_seek(buf, buffer_seek_start, 0);
		// 有 ID3 时只拷音频负载
		if (buffer_read(buf, buffer_u8) == 73 && buffer_read(buf, buffer_u8) == 68 && buffer_read(buf, buffer_u8) == 51) {
			buffer_seek(buf, buffer_seek_start, 6);
			var tag = ((buffer_read(buf, buffer_u8) & 127) << 21)
				| ((buffer_read(buf, buffer_u8) & 127) << 14)
				| ((buffer_read(buf, buffer_u8) & 127) << 7)
				| (buffer_read(buf, buffer_u8) & 127);
			start = clamp(10 + tag, 0, size);
		};
	};
	if (start <= 0) {
		try { buffer_save(buf, dest); } catch (save_err) { delete(save_err); };
	} else {
		var out = buffer_create(max(1, size - start), buffer_fixed, 1);
		buffer_copy(buf, start, size - start, out, 0);
		try { buffer_save(out, dest); } catch (save2) { delete(save2); };
		buffer_delete(out);
	};
	buffer_delete(buf);
	skin_log($"sfx prepared fmt={fmt} src={src} dest={dest} ok={file_exists(dest)}");
	return file_exists(dest) ? dest : src;
}

///@desc 从 WAV 的 PCM 数据创建缓冲音效
///@param {String} _path WAV 路径
///@returns {Struct} snd 与 buf，失败时均为 -1
function skin_wav_make_sound(_path) {
	var src = -1;
	try { src = buffer_load(_path); } catch (e) { delete(e); return { snd: -1, buf: -1 }; };
	if (!buffer_exists(src)) then return { snd: -1, buf: -1 };
	var size = buffer_get_size(src);
	// 不是 WAVE 则失败
	if (size < 44 || skin_buf_tag(src, 8, 4) != "WAVE") {
		buffer_delete(src);
		return { snd: -1, buf: -1 };
	};
	var pos = 12;
	var fmt_code = 0;
	var channels = 0;
	var rate = 0;
	var bits = 0;
	var data_off = -1;
	var data_size = 0;
	while (pos + 8 <= size) {
		var ckid = skin_buf_tag(src, pos, 4);
		buffer_seek(src, buffer_seek_start, pos + 4);
		var cksize = buffer_read(src, buffer_u32);
		if (cksize < 0) then break;
		var payload = pos + 8;
		// 遍历块，记下 fmt 和 data
		if (ckid == "fmt " && payload + 16 <= size) {
			buffer_seek(src, buffer_seek_start, payload);
			fmt_code = buffer_read(src, buffer_u16);
			channels = buffer_read(src, buffer_u16);
			rate = buffer_read(src, buffer_u32);
			buffer_read(src, buffer_u32);
			buffer_read(src, buffer_u16);
			bits = buffer_read(src, buffer_u16);
		} else if (ckid == "data") {
			data_off = payload;
			data_size = min(cksize, size - payload);
			break;
		};
		pos = payload + cksize;
		// RIFF 块按偶数字节对齐
		if ((cksize mod 2) == 1) then pos++;
	};
	if (data_off < 0 || data_size < 1 || channels < 1 || rate < 1) {
		buffer_delete(src);
		return { snd: -1, buf: -1 };
	};
	var gm_fmt = -1;
	if (fmt_code == 1 && bits == 8) then gm_fmt = buffer_u8;
	else if (fmt_code == 1 && bits == 16) then gm_fmt = buffer_s16;
	else if ((fmt_code == 3 || fmt_code == 1) && bits == 32) then gm_fmt = buffer_f32;
	// 只接受 8/16/32 位 PCM
	if (gm_fmt < 0) {
		skin_log($"wav unsupported format={fmt_code} bits={bits} path={_path}");
		buffer_delete(src);
		return { snd: -1, buf: -1 };
	};
	var align = (gm_fmt == buffer_u8) ? 1 : ((gm_fmt == buffer_s16) ? 2 : 4);
	var pcm = buffer_create(max(align, data_size), buffer_fixed, align);
	buffer_copy(src, data_off, data_size, pcm, 0);
	buffer_delete(src);
	var ch = (channels >= 2) ? audio_stereo : audio_mono;
	var snd = -1;
	try { snd = audio_create_buffer_sound(pcm, gm_fmt, rate, 0, data_size, ch); } catch (make_e) {
		delete(make_e);
		snd = -1;
	};
	if (is_undefined(snd) || !audio_exists(snd)) {
		buffer_delete(pcm);
		return { snd: -1, buf: -1 };
	};
	return { snd: snd, buf: pcm };
}

///@desc 尝试把音效载成缓冲音或音频流
///@param {String} _path 文件路径
///@param {String} _stem 日志用的音效名
///@returns {Struct} snd 与 buf，失败时均为 -1
function skin_try_sound(_path, _stem) {
	// 路径为空则继续用默认音
	if (!is_string(_path) || !string_length(_path)) {
		skin_log($"sfx {_stem} missing, using default");
		return { snd: -1, buf: -1 };
	};
	var fmt = skin_sound_format(_path);
	if (fmt == "wav") {
		var wav = skin_wav_make_sound(_path);
		if (audio_exists(wav.snd)) {
			skin_log($"sfx {_stem} wav buffer ok path={_path}");
			return wav;
		};
		skin_log($"sfx {_stem} wav buffer failed path={_path}");
		return { snd: -1, buf: -1 };
	};
	// wav 已在上面处理，其余非 ogg 不建流
	if (fmt != "ogg") {
		skin_log($"sfx {_stem} skip gm stream fmt={fmt} path={_path}");
		return { snd: -1, buf: -1 };
	};
	var snd = -1;
	try { snd = audio_create_stream(_path); } catch (e) { delete(e); snd = -1; };
	if (!is_undefined(snd) && audio_exists(snd)) {
		skin_log($"sfx {_stem} stream ok path={_path}");
		return { snd: snd, buf: -1 };
	};
	skin_log($"sfx {_stem} stream failed path={_path} exists={file_exists(_path)}");
	return { snd: -1, buf: -1 };
}

///@desc 在 FMOD 系统上加载皮肤包的打击音
///@param {Struct} _pack 皮肤包
///@returns {Bool} 是否已准备好
function skin_pack_fmod_ensure(_pack) {
	if (!is_struct(_pack)) then return false;
	// 已就绪、无扩展、渲染模式或媒体未就绪则返回
	if (variable_struct_exists(_pack, "fmod_ready") && _pack.fmod_ready) then return true;
	if (!extension_exists("FMOD")) then return false;
	if (variable_global_exists("render_mode") && global.render_mode) then return false;
	if (media_use_gx()) then return false;
	if (!instance_exists(oMedia)) then return false;
	var media = instance_find(oMedia, 0);
	if (!instance_exists(media) || !is_real(media.track) || media.track <= 0) then return false;
	fmod_system_select(media.track);
	_pack.fmod_ready = true;
	var stems = ["click", "drag", "flick"];
	for (var i = 0; i < array_length(stems); i++) {
		var stem = stems[i];
		var path = string(_pack[$ "sfx_path_" + stem] ?? "");
		if (!string_length(path)) then continue;
		path = skin_sound_prepared_path(chart_file_readable_path(path));
		var loaded = -1;
		try { loaded = fmod_system_create_sound(path, FMOD_MODE.DEFAULT); } catch (e) {
			delete(e);
			loaded = -1;
		};
		if (is_real(loaded) && loaded > 0) {
			_pack[$ "fmod_" + stem] = loaded;
			skin_log($"sfx {stem} fmod ok path={path}");
		} else {
			skin_log($"sfx {stem} fmod failed path={path}");
		};
	};
	return true;
}

///@desc 加载皮肤目录里的精灵和打击音路径
///@param {String} _root 皮肤目录
///@param {Struct} _info 已解析的 info
///@returns {Struct} ok 与 pack 或 error
function skin_pack_load(_root, _info) {
	var dir = skin_norm_dir(_root);
	skin_log($"pack load dir={dir}");
	var missing = skin_missing_file(dir);
	// 缺必需文件则直接失败
	if (string_length(missing)) {
		skin_log($"pack load missing {missing}");
		return { ok: false, error: langf("skin.missingFile", missing) };
	};
	var pack = { info: _info, root: dir };
	var keys = [
		["click", "click.png"], ["click_mh", "click_mh.png"],
		["drag", "drag.png"], ["drag_mh", "drag_mh.png"],
		["flick", "flick.png"], ["flick_mh", "flick_mh.png"],
		["hold", "hold.png"], ["hold_mh", "hold_mh.png"],
		["hit_fx", "hit_fx.png"]
	];
	for (var i = 0; i < array_length(keys); i++) {
		var spr_path = skin_join(dir, keys[i][1]);
		var spr = skin_add_centered(spr_path);
		// 任一精灵加载失败就卸载已加载的部分
		if (!asset_sprite_valid(spr)) {
			skin_log($"sprite_add failed {keys[i][1]} path={spr_path} exists={file_exists(spr_path)}");
			skin_pack_unload(pack);
			return { ok: false, error: langf("skin.missingFile", keys[i][1]) };
		};
		skin_log($"sprite {keys[i][1]} {sprite_get_width(spr)}x{sprite_get_height(spr)}");
		pack[$ keys[i][0]] = spr;
	};
	// 长条图集头尾高于图片则视为非法 info
	if (real(_info.holdAtlas[0]) + real(_info.holdAtlas[1]) >= sprite_get_height(pack.hold)
		|| real(_info.holdAtlasMH[0]) + real(_info.holdAtlasMH[1]) >= sprite_get_height(pack.hold_mh)) {
		skin_log($"hold atlas taller than strip n={_info.holdAtlas[0]}+{_info.holdAtlas[1]}/{sprite_get_height(pack.hold)} mh={_info.holdAtlasMH[0]}+{_info.holdAtlasMH[1]}/{sprite_get_height(pack.hold_mh)}");
		skin_pack_unload(pack);
		return { ok: false, error: lang("skin.invalidInfo", "Invalid info.yml") };
	};
	pack.sfx_path_click = skin_sound_path(dir, "click");
	pack.sfx_path_drag = skin_sound_path(dir, "drag");
	pack.sfx_path_flick = skin_sound_path(dir, "flick");
	if (string_length(pack.sfx_path_click)) {
		skin_log($"sfx click raw={pack.sfx_path_click} fmt={skin_sound_format(pack.sfx_path_click)}");
		pack.sfx_path_click = skin_sound_prepared_path(pack.sfx_path_click);
	};
	if (string_length(pack.sfx_path_drag)) {
		skin_log($"sfx drag raw={pack.sfx_path_drag} fmt={skin_sound_format(pack.sfx_path_drag)}");
		pack.sfx_path_drag = skin_sound_prepared_path(pack.sfx_path_drag);
	};
	if (string_length(pack.sfx_path_flick)) {
		skin_log($"sfx flick raw={pack.sfx_path_flick} fmt={skin_sound_format(pack.sfx_path_flick)}");
		pack.sfx_path_flick = skin_sound_prepared_path(pack.sfx_path_flick);
	};
	var gm_click = skin_try_sound(pack.sfx_path_click, "click");
	var gm_drag = skin_try_sound(pack.sfx_path_drag, "drag");
	var gm_flick = skin_try_sound(pack.sfx_path_flick, "flick");
	pack.sfx_click = gm_click.snd;
	pack.sfx_drag = gm_drag.snd;
	pack.sfx_flick = gm_flick.snd;
	pack.sfx_buf_click = gm_click.buf;
	pack.sfx_buf_drag = gm_drag.buf;
	pack.sfx_buf_flick = gm_flick.buf;
	pack.fmod_click = -1;
	pack.fmod_drag = -1;
	pack.fmod_flick = -1;
	pack.fmod_ready = false;
	pack.hit_cols = max(1, floor(real(_info.hitFx[0])));
	pack.hit_rows = max(1, floor(real(_info.hitFx[1])));
	pack.hit_frames = pack.hit_cols * pack.hit_rows;
	pack.note_ref_w = sprite_exists(note_tap) ? max(1, sprite_get_width(note_tap)) : 1089;
	pack.preview_row_ratio = 0;
	pack.gpu_ready = false;
	skin_log($"pack load ok hit_fx={pack.hit_cols}x{pack.hit_rows} frames={pack.hit_frames} ref_w={pack.note_ref_w}");
	return { ok: true, pack: pack };
}

///@desc 在 GPU 上裁切音符并切分长条
///@param {Struct} _pack 皮肤包
///@param {Bool} _measure 是否测量预览行高比
///@returns {Bool} 是否切分成功
function skin_pack_gpu_ensure(_pack, _measure = false) {
	if (!is_struct(_pack)) then return false;
	// 已经切分过则直接返回
	if (variable_struct_exists(_pack, "gpu_ready") && _pack.gpu_ready) then return true;
	_pack.gpu_ready = true;
	skin_log($"gpu ensure start measure={_measure}");
	var note_keys = ["click", "click_mh", "drag", "drag_mh", "flick", "flick_mh"];
	var preview_ratio = 0;
	for (var nk = 0; nk < array_length(note_keys); nk++) {
		var note_spr = _pack[$ note_keys[nk]];
		if (!sprite_exists(note_spr)) then continue;
		note_spr = skin_sprite_trim_empty(note_spr, "center");
		_pack[$ note_keys[nk]] = note_spr;
		if (sprite_exists(note_spr) && _measure) {
			var tw = sprite_get_width(note_spr);
			var th = sprite_get_height(note_spr);
			preview_ratio = max(preview_ratio, th / max(1, max(tw, th)));
		};
	};
	// 长条缺失时仍标记就绪，避免反复重试
	if (!sprite_exists(_pack.hold) || !sprite_exists(_pack.hold_mh)) {
		skin_log("gpu ensure missing hold atlas");
		_pack.gpu_ready = true;
		_pack.preview_row_ratio = preview_ratio;
		return false;
	};
	skin_log($"split hold atlas gpu hold={sprite_get_width(_pack.hold)}x{sprite_get_height(_pack.hold)}");
	var hold_n = skin_split_hold(_pack.hold, _pack.info.holdAtlas);
	var hold_mh = skin_split_hold(_pack.hold_mh, _pack.info.holdAtlasMH);
	if (!asset_sprite_valid(hold_n.head) || !asset_sprite_valid(hold_n.body) || !asset_sprite_valid(hold_n.tail)
		|| !asset_sprite_valid(hold_mh.head) || !asset_sprite_valid(hold_mh.body) || !asset_sprite_valid(hold_mh.tail)) {
		skin_log($"hold split failed n=({hold_n.head},{hold_n.body},{hold_n.tail}) mh=({hold_mh.head},{hold_mh.body},{hold_mh.tail})");
		skin_pack_unload({ hold_head: hold_n.head, hold_body: hold_n.body, hold_tail: hold_n.tail,
			hold_head_mh: hold_mh.head, hold_body_mh: hold_mh.body, hold_tail_mh: hold_mh.tail });
		_pack.gpu_ready = true;
		_pack.preview_row_ratio = preview_ratio;
		return false;
	};
	hold_n.head = skin_sprite_trim_empty(hold_n.head, "center");
	hold_n.body = skin_sprite_trim_empty(hold_n.body, "bottom");
	hold_n.tail = skin_sprite_trim_empty(hold_n.tail, "bottom");
	hold_mh.head = skin_sprite_trim_empty(hold_mh.head, "center");
	hold_mh.body = skin_sprite_trim_empty(hold_mh.body, "bottom");
	hold_mh.tail = skin_sprite_trim_empty(hold_mh.tail, "bottom");
	_pack.hold_head = hold_n.head;
	_pack.hold_body = hold_n.body;
	_pack.hold_tail = hold_n.tail;
	_pack.hold_head_mh = hold_mh.head;
	_pack.hold_body_mh = hold_mh.body;
	_pack.hold_tail_mh = hold_mh.tail;
	_pack.parts_n = { head: hold_n.head, body: hold_n.body, tail: hold_n.tail,
		compact: bool(_pack.info.holdCompact), keep_head: bool(_pack.info.holdKeepHead) };
	_pack.parts_mh = { head: hold_mh.head, body: hold_mh.body, tail: hold_mh.tail,
		compact: bool(_pack.info.holdCompact), keep_head: bool(_pack.info.holdKeepHead) };
	var hold_n_canvas = max(1, max(sprite_get_width(_pack.hold_head), sprite_get_height(_pack.hold_head)));
	var hold_mh_canvas = max(1, max(sprite_get_width(_pack.hold_head_mh), sprite_get_height(_pack.hold_head_mh)));
	preview_ratio = max(preview_ratio, sprite_get_height(_pack.hold_head) / hold_n_canvas);
	preview_ratio = max(preview_ratio, sprite_get_height(_pack.hold_head_mh) / hold_mh_canvas);
	_pack.preview_row_ratio = preview_ratio;
	// 切片已生成，释放整张长条
	skin_destroy_sprite(_pack.hold);
	skin_destroy_sprite(_pack.hold_mh);
	_pack.hold = -1;
	_pack.hold_mh = -1;
	_pack.gpu_ready = true;
	skin_log($"gpu ensure ok preview_row_ratio={preview_ratio}");
	return true;
}

///@desc 确保对局皮肤已完成 GPU 切分和 FMOD 加载
///@returns {Undefined} 无
function skin_runtime_gpu_ensure() {
	// 未启用皮肤则不用准备 GPU
	if (!variable_global_exists("skin_on") || !global.skin_on) then return;
	var pack = skin_runtime();
	// 包无效时关掉皮肤
	if (!is_struct(pack)) {
		global.skin_on = false;
		global.skin_gpu_done = true;
		return;
	};
	if (!(variable_global_exists("skin_gpu_done") && global.skin_gpu_done)) {
		skin_pack_gpu_ensure(pack);
		global.skin_gpu_done = true;
	};
	skin_pack_fmod_ensure(pack);
}

///@desc 返回精灵纹理是否就绪的短标记
///@param {Any} _spr 精灵或无效值
///@returns {String} -、NO、NT、DYN 或 OK
function skin_tex_flag(_spr) {
	// 无效、不存在、无纹理、动态纹理分别给短标记
	if (is_undefined(_spr) || is_string(_spr)) then return "-";
	if (is_real(_spr) && _spr < 0) then return "-";
	if (!sprite_exists(_spr)) then return "NO";
	var tex = sprite_get_texture(_spr, 0);
	if (is_undefined(tex) || (is_real(tex) && tex < 0)) then return "NT";
	if (!texture_is_ready(tex)) then return "DYN";
	return "OK";
}

///@desc 把纹理组状态转成名称
///@param {Real} _st 纹理组状态
///@returns {String} 状态名
function skin_tex_group_name(_st) {
	// 未知状态则返回原值字符串
	if (_st == texturegroup_status_unloaded) then return "unloaded";
	if (_st == texturegroup_status_loading) then return "loading";
	if (_st == texturegroup_status_loaded) then return "loaded";
	if (_st == texturegroup_status_fetched) then return "fetched";
	return string(_st);
}

///@desc 统计当前帧音符与默认音符纹理组状态
///@returns {Undefined} 无
function skin_tex_diag_frame() {
	if (!variable_global_exists("skin_tex_diag_f")) then global.skin_tex_diag_f = 0;
	global.skin_tex_diag_f += 1;
	//if (global.skin_tex_diag_f == 1) {
		//print($"[Skin] tex typeof tap={typeof(note_tap)} str={string(note_tap)} exists={sprite_exists(note_tap)}");
	//};
	var on = skin_active() ? 1 : 0;
	var grp = skin_tex_group_name(texturegroup_get_status("DefaultNotes"));
	var loaded = (variable_global_exists("default_notes_texture_loaded") && global.default_notes_texture_loaded) ? 1 : 0;
	var note_n = 0;
	var draw_n = 0;
	var vis_n = 0;
	if (instance_exists(oNote)) {
		note_n += instance_number(oNote);
		// 累加可见且允许绘制的音符数量
		with (oNote) {
			if (visible) then vis_n++;
			if (canDraw) then draw_n++;
		};
	};
	if (instance_exists(oNote_1)) {
		note_n += instance_number(oNote_1);
		with (oNote_1) {
			if (visible) then vis_n++;
			if (canDraw) then draw_n++;
		};
	};
	if (instance_exists(oNote_2)) {
		note_n += instance_number(oNote_2);
		with (oNote_2) {
			if (visible) then vis_n++;
			if (canDraw) then draw_n++;
		};
	};
	//var msg = $"[Skin] tex f={global.skin_tex_diag_f} on={on} grp={grp} loaded={loaded} notes={note_n} draw={draw_n} vis={vis_n} tap={skin_tex_flag(note_tap)} drag={skin_tex_flag(note_drag)} flick={skin_tex_flag(note_flick)} hh={skin_tex_flag(note_hold_head)} hb={skin_tex_flag(note_hold_body)} he={skin_tex_flag(note_hold_end)} fx={skin_tex_flag(effect)} px={skin_tex_flag(spr_pixel_1)}";
	//if (on) {
	//	var pack = skin_runtime();
	//	if (!is_struct(pack)) {
	//		msg += " pack=NONE";
	//	} else {
	//		msg += $" click={skin_tex_flag(pack[$ "click"])} click_mh={skin_tex_flag(pack[$ "click_mh"])} dragp={skin_tex_flag(pack[$ "drag"])} drag_mh={skin_tex_flag(pack[$ "drag_mh"])} flickp={skin_tex_flag(pack[$ "flick"])} flick_mh={skin_tex_flag(pack[$ "flick_mh"])} hold={skin_tex_flag(pack[$ "hold"])} hold_mh={skin_tex_flag(pack[$ "hold_mh"])} hit={skin_tex_flag(pack[$ "hit_fx"])} shh={skin_tex_flag(pack[$ "hold_head"])} shb={skin_tex_flag(pack[$ "hold_body"])} sht={skin_tex_flag(pack[$ "hold_tail"])} shh_mh={skin_tex_flag(pack[$ "hold_head_mh"])} shb_mh={skin_tex_flag(pack[$ "hold_body_mh"])} sht_mh={skin_tex_flag(pack[$ "hold_tail_mh"])}";
	//	};
	//};
	//print(msg);
}

///@desc 返回当前对局正在使用的皮肤包
///@returns {Any} 皮肤包，没有时为 undefined
function skin_runtime() {
	if (variable_global_exists("skin_gameplay") && is_struct(global.skin_gameplay)) then return global.skin_gameplay;
	return undefined;
}

///@desc 返回设置界面预览中的皮肤包
///@returns {Any} 预览包，没有时为 undefined
function skin_preview_runtime() {
	if (variable_global_exists("skin_preview") && is_struct(global.skin_preview)) then return global.skin_preview;
	return undefined;
}

///@desc 当前对局是否启用了自定义皮肤
///@returns {Bool} 是否启用
function skin_active() {
	return variable_global_exists("skin_on") && global.skin_on;
}

///@desc 卸载预览皮肤包
///@returns {Undefined} 无
function skin_preview_unload() {
	if (variable_global_exists("skin_preview")) {
		skin_pack_unload(global.skin_preview);
		global.skin_preview = undefined;
	};
	global.skin_preview_id = undefined;
}

///@desc 卸载对局皮肤并关闭皮肤开关
///@returns {Undefined} 无
function skin_gameplay_unload() {
	if (variable_global_exists("skin_gameplay")) {
		skin_pack_unload(global.skin_gameplay);
		global.skin_gameplay = undefined;
	};
	global.skin_gameplay_id = undefined;
	global.skin_on = false;
	global.skin_gpu_done = true;
}

///@desc 按 id 读取并加载一个皮肤包
///@param {String} _id 皮肤 id
///@returns {Struct} ok 与 pack 或 error
function skin_load_id(_id) {
	var skin_id = string(_id ?? SKIN_DEFAULT_ID);
	skin_log($"load id={skin_id}");
	// 默认皮肤不加载资源
	if (skin_id == SKIN_DEFAULT_ID) then return { ok: true, pack: undefined };
	var index = skin_list();
	var entry = undefined;
	for (var i = 0; i < array_length(index.packs); i++) {
		if (string(index.packs[i].skin_id) == skin_id) {
			entry = index.packs[i];
			break;
		};
	};
	// 索引、info.yml 或校验失败则返回错误
	if (!is_struct(entry)) {
		skin_log($"load missing index entry id={skin_id}");
		return { ok: false, error: lang("skin.parseFailed", "Failed to parse skin.") };
	};
	var root = skin_find_info_dir(skin_join(skin_root_dir(), string(entry[$ "folder"] ?? skin_id)));
	if (!string_length(root)) {
		skin_log($"load info.yml not found folder={entry[$ "folder"] ?? skin_id}");
		return { ok: false, error: lang("skin.parseFailed", "Failed to parse skin.") };
	};
	var text = skin_read_text(root + "info.yml");
	if (!string_length(text)) {
		skin_log($"load empty info.yml root={root}");
		return { ok: false, error: lang("skin.parseFailed", "Failed to parse skin.") };
	};
	var info = skin_yaml_parse(text);
	var bad = skin_info_verify(info);
	if (string_length(bad)) {
		skin_log($"load info verify failed: {bad}");
		return { ok: false, error: bad };
	};
	return skin_pack_load(root, info);
}

///@desc 切换设置界面正在预览的皮肤
///@param {String} _id 皮肤 id
///@returns {Bool} 是否切换成功
function skin_preview_set(_id) {
	var skin_id = string(_id ?? SKIN_DEFAULT_ID);
	skin_log($"preview set id={skin_id}");
	// 已经是该预览则直接成功
	if (variable_global_exists("skin_preview_id") && global.skin_preview_id == skin_id && (skin_id == SKIN_DEFAULT_ID || is_struct(skin_preview_runtime()))) {
		return true;
	};
	var prev_id = variable_global_exists("skin_preview_id") ? string(global.skin_preview_id ?? SKIN_DEFAULT_ID) : SKIN_DEFAULT_ID;
	skin_preview_unload();
	if (skin_id == SKIN_DEFAULT_ID) {
		global.skin_preview_id = skin_id;
		hold_default_notes_prefetch();
		if (instance_exists(oSettings)) then skin_preview_cycle_reset();
		return true;
	};
	var loaded = skin_load_id(skin_id);
	// 加载失败时尝试回到上一个预览
	if (!loaded.ok) {
		skin_log($"preview load failed id={skin_id} error={loaded.error}");
		skin_error(loaded.error);
		if (prev_id != skin_id) {
			if (prev_id == SKIN_DEFAULT_ID) {
				global.skin_preview_id = prev_id;
			} else {
				var again = skin_load_id(prev_id);
				if (again.ok) {
					global.skin_preview = again.pack;
					global.skin_preview_id = prev_id;
				} else {
					global.skin_preview_id = SKIN_DEFAULT_ID;
				};
			};
		};
		return false;
	};
	global.skin_preview = loaded.pack;
	global.skin_preview_id = skin_id;
	if (variable_global_exists("skin_gameplay_failed_id") && global.skin_gameplay_failed_id == skin_id) {
		global.skin_gameplay_failed_id = undefined;
	};
	if (instance_exists(oSettings)) then skin_preview_cycle_reset();
	skin_log($"preview ready id={skin_id}");
	return true;
}

///@desc 按当前选中项准备对局皮肤
///@returns {Bool} 是否可用
function skin_gameplay_ensure() {
	skin_preview_unload();
	var skin_id = skin_selected_id();
	skin_log($"gameplay ensure selected={skin_id}");
	// 默认皮肤只卸载自定义包
	if (skin_id == SKIN_DEFAULT_ID) {
		skin_gameplay_unload();
		global.skin_gameplay_id = skin_id;
		return true;
	};
	if (variable_global_exists("skin_gameplay_id") && global.skin_gameplay_id == skin_id && is_struct(skin_runtime())) {
		global.skin_on = true;
		return true;
	};
	// 上次失败的 id 不再重试
	if (variable_global_exists("skin_gameplay_failed_id") && global.skin_gameplay_failed_id == skin_id) {
		global.skin_gameplay_id = SKIN_DEFAULT_ID;
		global.skin_on = false;
		return false;
	};
	skin_gameplay_unload();
	var loaded = skin_load_id(skin_id);
	if (!loaded.ok) {
		skin_log($"gameplay load failed id={skin_id} error={loaded.error}");
		skin_error(loaded.error);
		global.skin_gameplay_failed_id = skin_id;
		global.skin_gameplay_id = SKIN_DEFAULT_ID;
		global.skin_on = false;
		return false;
	};
	global.skin_gameplay_failed_id = undefined;
	global.skin_gameplay = loaded.pack;
	global.skin_gameplay_id = skin_id;
	global.skin_on = true;
	global.skin_gpu_done = false;
	skin_pack_fmod_ensure(loaded.pack);
	skin_log($"gameplay ready id={skin_id}");
	return true;
}

///@desc 递归删除目录中的文件和子目录
///@param {String} _path 目录路径
///@returns {Undefined} 无
function skin_folder_rmdir(_path) {
	var path = skin_norm_dir(_path);
	if (!string_length(path) || !directory_exists(path)) then return;
	var names = [];
	var found = "";
	try { found = file_find_first(path + "*", fa_none); } catch (e) { delete(e); found = ""; };
	while (string_length(found)) {
		if (found != "." && found != "..") then array_add(names, found);
		found = file_find_next();
	};
	try { file_find_close(); } catch (fc) { delete(fc); };
	for (var i = 0; i < array_length(names); i++) {
		var full = path + names[i];
		// 子目录递归删除，文件直接删
		if (directory_exists(full)) then skin_folder_rmdir(full);
		else {
			try { file_delete(full); } catch (df) { delete(df); };
		};
	};
	try { directory_destroy(path); } catch (rm) { delete(rm); };
}

///@desc 先走会话删除，再递归清掉目录
///@param {String} _path 目录路径
///@returns {Undefined} 无
function skin_folder_remove(_path) {
	var path = string(_path ?? "");
	// 空路径不用删
	if (!string_length(path)) then return;
	try { chart_session_remove_dir(path); } catch (rm) { delete(rm); };
	skin_folder_rmdir(path);
}

///@desc 让设置界面重新计算皮肤命中区
///@returns {Undefined} 无
function skin_ui_refresh() {
	if (instance_exists(oSettings)) then oSettings.hits_tab = -1;
}

///@desc 记录导入失败并弹出错误
///@param {String} _message 失败原因
///@returns {Undefined} 无
function skin_import_fail(_message) {
	var text = string(_message ?? lang("skin.importFailed", "Failed to import skin."));
	var detail = skin_zip_last_error();
	// 附上尚未包含的 zip 后端错误
	if (string_length(detail) && string_pos(detail, text) <= 0) then text += "\n" + detail;
	skin_log($"import fail: {text}");
	skin_error(text);
}

///@desc 用缓冲把文件复制到目标路径
///@param {String} _src 源路径
///@param {String} _dst 目标路径
///@returns {Bool} 目标文件是否存在
function skin_copy_file(_src, _dst) {
	// 源缺失则复制失败
	if (!file_exists(_src)) {
		skin_log($"copy missing src={_src}");
		return false;
	};
	var buf = -1;
	try { buf = buffer_load(_src); } catch (load_err) { delete(load_err); buf = -1; };
	if (!buffer_exists(buf)) {
		skin_log($"copy buffer_load failed src={_src}");
		return false;
	};
	try { buffer_save(buf, _dst); } catch (save_err) { delete(save_err); };
	buffer_delete(buf);
	var ok = file_exists(_dst);
	skin_log($"copy {_src} -> {_dst} ok={ok}");
	return ok;
}

///@desc 把 zip 交给设置界面，或立即开始导入
///@param {String} _zip_path zip 路径
///@returns {Bool} 是否已排队或已开始
function skin_import_queue(_zip_path) {
	var zip = string(_zip_path ?? "");
	skin_log($"queue zip={zip} len={string_length(zip)} file_exists={file_exists(zip)}");
	if (!string_length(zip)) then return false;
	// 设置界面存在时延到下一步，避免在回调里解压
	if (instance_exists(oSettings)) {
		oSettings.skin_import_path = zip;
		skin_log("queued for next settings step");
		return true;
	};
	return skin_import_zip(zip);
}

///@desc 是否已有皮肤解压任务在跑
///@returns {Bool} 是否忙碌
function skin_import_busy() {
	return instance_exists(oSettings) && is_real(oSettings.skin_zip_task) && oSettings.skin_zip_task >= 0;
}

///@desc 取消并释放正在进行的皮肤解压
///@returns {Undefined} 无
function skin_import_cancel() {
	// 没有设置界面就没有进行中的任务
	if (!instance_exists(oSettings)) then return;
	with (oSettings) {
		if (is_real(skin_zip_task) && skin_zip_task >= 0) {
			skin_log($"cancel extract task={skin_zip_task}");
			try { unicode_zip_backend_task_cancel(skin_zip_task); } catch (cancel_err) { delete(cancel_err); };
			try { unicode_zip_backend_task_release(skin_zip_task); } catch (rel_err) { delete(rel_err); };
			skin_zip_task = -1;
		};
		// 同时删掉暂存的 zip 副本
		if (is_string(skin_zip_copy) && string_length(skin_zip_copy) && file_exists(skin_zip_copy)) {
			try { file_delete(skin_zip_copy); } catch (del_err) { delete(del_err); };
		};
		skin_zip_copy = "";
		skin_zip_dest = "";
		skin_zip_folder = "";
	};
}

///@desc 校验解压结果并写入索引、刷新预览
///@param {String} _dest 解压目录
///@param {String} _folder 文件夹名
///@returns {Bool} 预览是否成功
function skin_import_finish(_dest, _folder) {
	var dest = string(_dest ?? "");
	var folder = string(_folder ?? "");
	var info_dir = skin_find_info_dir(dest);
	skin_log($"finish dest={dest} dest_exists={directory_exists(dest)} info_dir={info_dir}");
	// 找不到 info 则删目录并报错
	if (!string_length(info_dir)) {
		skin_folder_remove(dest);
		skin_error(lang("skin.parseFailed", "Failed to parse skin."));
		return false;
	};
	var missing = skin_missing_file(info_dir);
	// 缺文件则删掉解压目录
	if (string_length(missing)) {
		skin_log($"missing file={missing} in {info_dir}");
		skin_folder_remove(dest);
		skin_error(langf("skin.missingFile", missing));
		return false;
	};
	var info = skin_yaml_parse(skin_read_text(info_dir + "info.yml"));
	skin_log($"parsed name={info.name} author={info.author} hitFx={info.hitFx[0]}x{info.hitFx[1]} holdAtlas={info.holdAtlas[0]},{info.holdAtlas[1]} holdAtlasMH={info.holdAtlasMH[0]},{info.holdAtlasMH[1]}");
	var bad = skin_info_verify(info);
	if (string_length(bad)) {
		skin_log($"info verify failed: {bad}");
		skin_folder_remove(dest);
		skin_error(bad);
		return false;
	};
	var index = skin_list();
	var entry = {
		skin_id: folder,
		folder: folder,
		name: info.name,
		author: info.author,
		description: info.description
	};
	array_add(index.packs, entry);
	index.selected = folder;
	skin_index_save(index);
	skin_ui_refresh();
	skin_log($"index saved selected={folder} packs={array_length(index.packs)}");
	var preview_ok = skin_preview_set(folder);
	skin_log($"preview after import ok={preview_ok}");
	return preview_ok;
}

///@desc 轮询解压任务，结束后收尾或报错
///@returns {Undefined} 无
function skin_import_poll() {
	// 没有设置界面或没有任务则不用轮询
	if (!instance_exists(oSettings)) then return;
	if (!is_real(oSettings.skin_zip_task) || oSettings.skin_zip_task < 0) then return;
	var task = oSettings.skin_zip_task;
	var status = unicode_zip_backend_task_status(task);
	// 仍在排队或运行则下次再查
	if (status == UNICODE_ZIP_TASK_STATUS.QUEUED || status == UNICODE_ZIP_TASK_STATUS.RUNNING) then return;
	var task_err = string(unicode_zip_backend_task_error(task) ?? "");
	var exit_code = unicode_zip_backend_task_exit_code(task);
	var last_err = skin_zip_last_error();
	skin_log($"extract task={task} status={status} exit={exit_code} task_error={task_err} last={last_err}");
	var dest = string(oSettings.skin_zip_dest ?? "");
	var folder = string(oSettings.skin_zip_folder ?? "");
	var copy_path = string(oSettings.skin_zip_copy ?? "");
	try { unicode_zip_backend_task_release(task); } catch (rel_err) { delete(rel_err); };
	oSettings.skin_zip_task = -1;
	oSettings.skin_zip_dest = "";
	oSettings.skin_zip_folder = "";
	oSettings.skin_zip_copy = "";
	if (string_length(copy_path) && file_exists(copy_path)) {
		try { file_delete(copy_path); } catch (del_copy) { delete(del_copy); };
	};
	// 解压失败时删目录并报错
	if (status != UNICODE_ZIP_TASK_STATUS.SUCCEEDED) {
		skin_folder_remove(dest);
		var fail = lang("skin.importFailed", "Failed to import skin.");
		if (string_length(task_err)) then fail += "\n" + task_err;
		else if (string_length(last_err)) then fail += "\n" + last_err;
		skin_import_fail(fail);
		return;
	};
	skin_import_finish(dest, folder);
}

///@desc 异步解压皮肤 zip 到新目录
///@param {String} _zip_path zip 路径
///@returns {Bool} 是否成功提交任务
function skin_import_zip(_zip_path) {
	var zip = string(_zip_path ?? "");
	skin_log($"import begin zip={zip} exists={file_exists(zip)} backend={unicode_zip_backend_available()} root={skin_root_dir()}");
	if (!string_length(zip)) {
		skin_import_fail(lang("skin.importFailed", "Failed to import skin."));
		return false;
	};
	// 无后端则无法解压
	if (!unicode_zip_backend_available()) {
		skin_log("unicode zip backend unavailable");
		skin_import_fail(lang("skin.importFailed", "Failed to import skin."));
		return false;
	};
	// 异步解压需要设置实例保存任务号
	if (!instance_exists(oSettings)) {
		skin_log("import requires settings instance for async extract");
		skin_import_fail(lang("skin.importFailed", "Failed to import skin."));
		return false;
	};
	// 已有任务则不再提交
	if (skin_import_busy()) {
		skin_log("import already running");
		return false;
	};
	var tmp_id = skin_unique_folder("import");
	var dest = skin_join(skin_root_dir(), tmp_id);
	try { directory_create(dest); } catch (mkdir_err) { delete(mkdir_err); };
	var staged = skin_join(skin_root_dir(), tmp_id + ".zip");
	var archive = zip;
	if (skin_copy_file(zip, staged)) {
		archive = staged;
	} else {
		// 复制失败则直接解压原路径
		skin_log("staging copy failed, extracting original path");
		staged = "";
	};
	skin_log($"extract async dest={dest} archive={archive} folder={tmp_id}");
	var task = -1;
	try { task = unicode_zip_backend_extract_async(archive, dest, true, true); } catch (ex) {
		skin_log($"extract_async threw: {string(ex)}");
		delete(ex);
		task = -1;
	};
	skin_log($"extract_async task={task} last={skin_zip_last_error()} dest_exists={directory_exists(dest)}");
	if (!is_real(task) || task < 0) {
		if (string_length(staged) && file_exists(staged)) then file_delete(staged);
		skin_folder_remove(dest);
		skin_import_fail(lang("skin.importFailed", "Failed to import skin."));
		return false;
	};
	oSettings.skin_zip_task = task;
	oSettings.skin_zip_dest = dest;
	oSettings.skin_zip_folder = tmp_id;
	oSettings.skin_zip_copy = staged;
	return true;
}

///@desc 删除指定皮肤的目录和索引项
///@param {String} _id 皮肤 id
///@returns {Bool} 是否删除成功
function skin_delete_id(_id) {
	var skin_id = string(_id ?? "");
	skin_log($"delete id={skin_id}");
	// 空 id 视为不能删默认皮肤
	if (!string_length(skin_id)) {
		skin_error(lang("skin.cantDeleteDefault", "The default skin cannot be deleted."));
		return false;
	};
	var index = skin_list();
	var folder = "";
	var next = [];
	for (var i = 0; i < array_length(index.packs); i++) {
		if (string(index.packs[i].skin_id) == skin_id) {
			folder = string(index.packs[i][$ "folder"] ?? skin_id);
		} else {
			array_add(next, index.packs[i]);
		};
	};
	// 索引里找不到该包则返回假
	if (!string_length(folder)) then return false;
	if (variable_global_exists("skin_preview_id") && global.skin_preview_id == skin_id) then skin_preview_unload();
	if (variable_global_exists("skin_gameplay_id") && global.skin_gameplay_id == skin_id) then skin_gameplay_unload();
	if (variable_global_exists("skin_gameplay_failed_id") && global.skin_gameplay_failed_id == skin_id) then global.skin_gameplay_failed_id = undefined;
	skin_folder_remove(skin_join(skin_root_dir(), folder));
	index.packs = next;
	if (string(index.selected) == skin_id) then index.selected = SKIN_DEFAULT_ID;
	skin_index_save(index);
	skin_ui_refresh();
	skin_preview_set(index.selected);
	return true;
}

///@desc 按平台打开皮肤包文件选择器
///@returns {Undefined} 无
function skin_pick_file() {
	skin_log($"pick file os={os_type} gx={pls_is_gxgames()}");
	// GX 与 Android 走各自选择器，其他平台用系统对话框
	if (pls_is_gxgames()) {
		///@desc 把选中的压缩包路径加入导入队列
		///@param {String} path 所选文件路径
		///@returns {Undefined} 无
		gx_file_picker_open(function(path) { skin_import_queue(path); });
		return;
	};
	if (os_type == os_android) {
		if (!extension_exists("I_AndroidOpen")) {
			skin_error(lang("android.pickerUnavailable", "File picker is not available."));
			return;
		};
		if (instance_exists(oSettings)) {
			oSettings.skin_picking = true;
			if (!i_android_open_pick("application/zip")) {
				oSettings.skin_picking = false;
				skin_error(lang("android.pickerFailed", "Failed to open the system picker."));
			} else {
				skin_log("android picker opened");
			};
		};
		return;
	};
	var path = get_open_filename(lang("skin.filter", "Skin package|*.zip|All files|*.*"), "");
	skin_log($"picker returned type={typeof(path)} len={is_string(path) ? string_length(path) : -1} path={path}");
	if (is_string(path) && string_length(path)) then skin_import_queue(path);
	else skin_log("picker cancelled or empty path");
}

///@desc 多押缩放时改用对应的 _mh 精灵作基准
///@param {Real} _spr 当前音符精灵
///@returns {Real} 用于量宽度的基准精灵
function skin_note_scale_base(_spr) {
	if (!sprite_exists(_spr)) then return _spr;
	var pack = skin_runtime();
	if (!is_struct(pack)) then pack = skin_preview_runtime();
	// 没有皮肤包则保持原精灵
	if (!is_struct(pack)) then return _spr;
	if ((_spr == pack.click || _spr == pack.click_mh) && sprite_exists(pack.click_mh)) then return pack.click_mh;
	if ((_spr == pack.drag || _spr == pack.drag_mh) && sprite_exists(pack.drag_mh)) then return pack.drag_mh;
	if ((_spr == pack.flick || _spr == pack.flick_mh) && sprite_exists(pack.flick_mh)) then return pack.flick_mh;
	if ((_spr == pack.hold_head || _spr == pack.hold_head_mh) && sprite_exists(pack.hold_head_mh)) then return pack.hold_head_mh;
	if ((_spr == pack.hold_body || _spr == pack.hold_body_mh) && sprite_exists(pack.hold_body_mh)) then return pack.hold_body_mh;
	if ((_spr == pack.hold_tail || _spr == pack.hold_tail_mh) && sprite_exists(pack.hold_tail_mh)) then return pack.hold_tail_mh;
	return _spr;
}

///@desc 计算皮肤音符相对参考宽度的缩放比
///@param {Real} _spr 音符精灵
///@returns {Real} 宽度缩放系数
function skin_note_scale_k(_spr) {
	if (!sprite_exists(_spr)) then return 1;
	var ref_w = 1089;
	var pack = skin_runtime();
	// 参考宽优先用皮肤包记录，否则用默认 tap
	if (is_struct(pack) && is_real(pack.note_ref_w) && pack.note_ref_w > 1) then ref_w = pack.note_ref_w;
	else if (sprite_exists(note_tap)) then ref_w = max(1, sprite_get_width(note_tap));
	var src = skin_note_scale_base(_spr);
	return ref_w / max(1, sprite_get_width(sprite_exists(src) ? src : _spr));
}

///@desc 按默认特效尺寸换算皮肤打击图集的缩放
///@param {Struct} _pack 皮肤包
///@returns {Real} 乘上全局缩放后的系数
function skin_hitfx_game_scale(_pack) {
	var gs = variable_global_exists("global_scales") ? global_scales : 1;
	// 没有图集时只返回全局缩放
	if (!is_struct(_pack) || !sprite_exists(_pack.hit_fx)) then return gs;
	var cols = max(1, real(_pack.hit_cols));
	var rows = max(1, real(_pack.hit_rows));
	var cell = max(1, max(sprite_get_width(_pack.hit_fx) / cols, sprite_get_height(_pack.hit_fx) / rows));
	var ref = sprite_exists(effect) ? max(1, max(sprite_get_width(effect), sprite_get_height(effect))) : 248;
	return gs * ref / cell;
}

///@desc 按音符种类和多押状态取皮肤精灵
///@param {String} _kind tap、drag 或 flick
///@param {Real} _hl 是否多押，1 为多押
///@returns {Real} 精灵 id，无皮肤时为 -1
function skin_note_sprite(_kind, _hl) {
	var pack = skin_runtime();
	// 没有对局皮肤则交给调用方用默认精灵
	if (!is_struct(pack)) then return -1;
	var mh = (_hl == 1);
	// 多押用 _mh 精灵
	switch (string(_kind)) {
		case "tap": return mh ? pack.click_mh : pack.click;
		case "drag": return mh ? pack.drag_mh : pack.drag;
		case "flick": return mh ? pack.flick_mh : pack.flick;
		default: return -1;
	};
}

///@desc 按音符种类取皮肤音效，没有则用回退音
///@param {String} _kind tap、drag 或 flick
///@param {Any} _fallback 默认音效
///@returns {Any} 实际播放的音效
function skin_note_sound(_kind, _fallback) {
	var pack = skin_runtime();
	if (!is_struct(pack)) then return _fallback;
	var snd = -1;
	switch (string(_kind)) {
		case "tap": snd = pack.sfx_click; break;
		case "drag": snd = pack.sfx_drag; break;
		case "flick": snd = pack.sfx_flick; break;
	};
	// 皮肤音效不存在则用回退音
	if (!is_undefined(snd) && audio_exists(snd)) then return snd;
	return _fallback;
}

///@desc 按音符种类返回皮肤打击音文件路径
///@param {String} _kind 音符种类
///@returns {String} 路径，没有则为空
function skin_hitsound_path_for_kind(_kind) {
	var pack = skin_runtime();
	if (!is_struct(pack)) then return "";
	// 未识别的种类回退到 click
	switch (string(_kind)) {
		case "drag": return string(pack[$ "sfx_path_drag"] ?? "");
		case "flick": return string(pack[$ "sfx_path_flick"] ?? "");
		default: return string(pack[$ "sfx_path_click"] ?? "");
	};
}

///@desc 根据音符实例类型返回打击音路径
///@param {Id.Instance} _note 音符实例
///@returns {String} 路径，实例不存在则为空
function skin_hitsound_path_for_note(_note) {
	// 实例不存在则没有自定义路径
	if (!instance_exists(_note)) then return "";
	var kind = "tap";
	with (_note) kind = skin_note_kind_from_instance();
	return skin_hitsound_path_for_kind(kind);
}

///@desc 根据当前实例的对象和 type 判断音符种类
///@returns {String} tap、drag 或 flick
function skin_note_kind_from_instance() {
	var t = variable_instance_exists(id, "type") ? real(type) : 1;
	// oNote_2 与普通音符的 type 编号不同
	if (object_index == oNote_2) {
		if (t == 4) then return "drag";
		if (t == 3) then return "flick";
		return "tap";
	};
	if (t == 2) then return "drag";
	if (t == 4) then return "flick";
	return "tap";
}

///@desc 用 FMOD、缓冲音或默认音播放打击音
///@param {String} _kind 音符种类
///@param {Any} _fallback 默认音效
///@returns {Bool} 是否已交给播放
function skin_play_hitsound(_kind, _fallback) {
	var pack = skin_runtime();
	var path = "";
	var fmod_snd = -1;
	var gm_snd = -1;
	if (is_struct(pack)) {
		skin_pack_fmod_ensure(pack);
		switch (string(_kind)) {
			case "drag":
				path = string(pack[$ "sfx_path_drag"] ?? "");
				fmod_snd = pack[$ "fmod_drag"] ?? -1;
				gm_snd = pack[$ "sfx_drag"] ?? -1;
				break;
			case "flick":
				path = string(pack[$ "sfx_path_flick"] ?? "");
				fmod_snd = pack[$ "fmod_flick"] ?? -1;
				gm_snd = pack[$ "sfx_flick"] ?? -1;
				break;
			default:
				path = string(pack[$ "sfx_path_click"] ?? "");
				fmod_snd = pack[$ "fmod_click"] ?? -1;
				gm_snd = pack[$ "sfx_click"] ?? -1;
				break;
		};
	};
	// 渲染模式只记录，不走实时 FMOD
	if (variable_global_exists("render_mode") && global.render_mode) {
		return render_play_hitsound(_fallback, path);
	};
	// 有 FMOD 句柄优先用它
	if (is_real(fmod_snd) && fmod_snd > 0) {
		rpe_play_hitsound(_fallback, fmod_snd, path);
		return true;
	};
	if (!is_undefined(gm_snd) && audio_exists(gm_snd)) {
		return render_play_hitsound(gm_snd, path);
	};
	return render_play_hitsound(_fallback, path);
}

///@desc 为当前音符实例播放打击音
///@returns {Bool} 是否已播放
function skin_play_note_hitsound() {
	// 假音符不播放
	if (variable_instance_exists(id, "isFake") && bool(isFake)) then return false;
	var fallback = snd_note_tap;
	if (variable_instance_exists(id, "sound") && audio_exists(sound)) then fallback = sound;
	var custom_fmod = -1;
	var custom_path = "";
	if (variable_instance_exists(id, "custom_fmod_sound")) then custom_fmod = custom_fmod_sound;
	if (variable_instance_exists(id, "custom_hitsound_path")) then custom_path = string(custom_hitsound_path ?? "");
	// 谱面自带音效优先于皮肤音
	if ((is_real(custom_fmod) && custom_fmod > 0) || string_length(custom_path)) {
		return rpe_play_hitsound(fallback, custom_fmod, custom_path);
	};
	return skin_play_hitsound(skin_note_kind_from_instance(), fallback);
}

///@desc 返回长条的头身尾切片
///@param {Real} _hl 是否多押，1 为多押
///@returns {Any} 切片结构，未就绪时为 undefined
function skin_hold_parts(_hl) {
	var pack = skin_runtime();
	// GPU 切片未就绪则不能画长条
	if (!is_struct(pack) || !(variable_struct_exists(pack, "gpu_ready") && pack.gpu_ready)) then return undefined;
	if (_hl == 1) then return pack.parts_mh;
	return pack.parts_n;
}

///@desc 按皮肤染色设置替换打击颜色
///@param {Struct} _pack 皮肤包
///@param {Real} _col 原始颜色
///@returns {Real} 实际绘制颜色
function skin_hitfx_color(_pack, _col) {
	// 未开启染色时用白色
	if (!is_struct(_pack) || !bool(_pack.info.hitFxTinted)) then return c_white;
	if (_col == make_colour_rgb(162, 238, 255)) then return skin_color_from_u32(_pack.info.colorGood);
	if (_col == #ffeca0) then return skin_color_from_u32(_pack.info.colorPerfect);
	return _col;
}

///@desc 按时间从打击图集切出一帧并绘制
///@param {Struct} _pack 皮肤包
///@param {Real} _x 中心 x
///@param {Real} _y 中心 y
///@param {Real} _age 已播放秒数
///@param {Real} _col 染色
///@param {Real} _scale 缩放
///@returns {Bool} 是否画出
function skin_draw_hitfx(_pack, _x, _y, _age, _col, _scale) {
	if (!is_struct(_pack) || !sprite_exists(_pack.hit_fx)) then return false;
	var dur = max(0.05, real(_pack.info.hitFxDuration));
	// 超出持续时间则不画
	if (_age < 0 || _age >= dur) then return false;
	var frames = max(1, real(_pack.hit_frames));
	var frame = clamp(floor(_age / dur * frames), 0, frames - 1);
	var cols = max(1, real(_pack.hit_cols));
	var rows = max(1, real(_pack.hit_rows));
	var cw = sprite_get_width(_pack.hit_fx) / cols;
	var ch = sprite_get_height(_pack.hit_fx) / rows;
	var col = frame mod cols;
	var row = frame div cols;
	var sc = real(_scale) * real(_pack.info.hitFxScale);
	var dx = _x - cw * sc * 0.5;
	var dy = _y - ch * sc * 0.5;
	var blend = _col;
	if (!bool(_pack.info.hitFxTinted)) then blend = c_white;
	draw_sprite_part_ext(_pack.hit_fx, 0, col * cw, row * ch, cw, ch, dx, dy, sc, sc, blend, 1);
	return true;
}

///@desc 把打击特效缩放到给定盒子后再绘制
///@param {Struct} _pack 皮肤包
///@param {Real} _x 中心 x
///@param {Real} _y 中心 y
///@param {Real} _age 已播放秒数
///@param {Real} _col 染色
///@param {Real} _box 目标边长
///@returns {Bool} 是否画出
function skin_draw_hitfx_fitted(_pack, _x, _y, _age, _col, _box) {
	if (!is_struct(_pack) || !sprite_exists(_pack.hit_fx)) then return false;
	var cols = max(1, real(_pack.hit_cols));
	var rows = max(1, real(_pack.hit_rows));
	var cw = sprite_get_width(_pack.hit_fx) / cols;
	var ch = sprite_get_height(_pack.hit_fx) / rows;
	var box = max(8, real(_box));
	var hit_sc = max(0.05, real(_pack.info.hitFxScale));
	var fit = box / max(1, max(cw, ch));
	// 抵消 info 里的 hitFxScale，只按盒子适配
	return skin_draw_hitfx(_pack, _x, _y, _age, _col, fit / hit_sc);
}

///@desc 用内置 effect 精灵画默认打击特效
///@param {Real} _x 中心 x
///@param {Real} _y 中心 y
///@param {Real} _age 已播放秒数
///@param {Real} _col 染色
///@param {Real} _box 目标边长
///@returns {Bool} 是否画出
function skin_draw_default_hitfx(_x, _y, _age, _col, _box) {
	// 0.5 秒内按 60 帧取子图
	if (_age < 0 || _age >= 0.5) then return false;
	if (!sprite_exists(effect)) then return false;
	var sub = clamp(floor(_age * 60), 0, 29);
	var box = max(8, real(_box));
	var k = box / max(1, max(sprite_get_width(effect), sprite_get_height(effect)));
	draw_sprite_ext(effect, sub, _x, _y, k, k, 0, _col, 1);
	return true;
}

///@desc 计算预览里音符在盒子中的显示宽度
///@param {Real} _spr 音符精灵
///@param {Real} _box 目标边长
///@returns {Real} 显示宽度
function skin_preview_note_disp_w(_spr, _box) {
	// 精灵无效时用盒子边长当作显示宽
	if (!sprite_exists(_spr)) then return max(8, real(_box));
	var nw = sprite_get_width(_spr);
	var nh = sprite_get_height(_spr);
	return nw * (real(_box) / max(1, max(nw, nh)));
}

///@desc 按音符显示宽度绘制预览打击特效
///@param {Any} _pack 皮肤包，可无
///@param {Real} _x 中心 x
///@param {Real} _y 中心 y
///@param {Real} _age 已播放秒数
///@param {Real} _col 染色
///@param {Real} _note_w 音符显示宽度
///@returns {Bool} 是否画出
function skin_draw_preview_hitfx(_pack, _x, _y, _age, _col, _note_w) {
	var note_w = max(8, real(_note_w));
	// 有皮肤图集时按格子宽适配，否则用内置 effect
	if (is_struct(_pack) && sprite_exists(_pack.hit_fx)) {
		var cw = sprite_get_width(_pack.hit_fx) / max(1, real(_pack.hit_cols));
		var hit_sc = max(0.05, real(_pack.info.hitFxScale));
		return skin_draw_hitfx(_pack, _x, _y, _age, _col, (note_w / max(1, cw)) / hit_sc);
	};
	if (_age < 0 || _age >= 0.5) then return false;
	if (!sprite_exists(effect)) then return false;
	var sub = clamp(floor(_age * 60), 0, 29);
	var k = note_w / max(1, sprite_get_width(effect));
	draw_sprite_ext(effect, sub, _x, _y, k, k, 0, _col, 1);
	return true;
}

///@desc 预览循环里播放一次对应种类的打击音
///@param {Real} _kind_i 0 为 tap，1 为 drag，2 为 flick
///@returns {Undefined} 无
function skin_preview_play_hitsound(_kind_i = 0) {
	skin_hitsounds_ensure_default();
	var pack = skin_preview_runtime();
	var kind_i = floor(real(_kind_i)) mod 3;
	// 负数取模后仍落在 0 到 2
	if (kind_i < 0) then kind_i += 3;
	var snd = snd_note_tap;
	if (kind_i == 1) then snd = snd_note_drag;
	if (kind_i == 2) then snd = snd_note_flick;
	if (is_struct(pack)) {
		// 有皮肤音效则替换默认音
		if (kind_i == 0 && audio_exists(pack.sfx_click)) then snd = pack.sfx_click;
		else if (kind_i == 1 && audio_exists(pack.sfx_drag)) then snd = pack.sfx_drag;
		else if (kind_i == 2 && audio_exists(pack.sfx_flick)) then snd = pack.sfx_flick;
	};
	if (audio_exists(snd)) then audio_play_sound(snd, 0, false);
}

///@desc 重置预览里的打击循环计时和粒子参数
///@returns {Undefined} 无
function skin_preview_cycle_reset() {
	// 没有设置界面就没有预览状态可重置
	if (!instance_exists(oSettings)) then return;
	oSettings.skin_fx_cycle_t0 = current_time;
	oSettings.skin_fx_last_hit = -1;
	oSettings.skin_fx_rot = [];
	oSettings.skin_fx_scales = [];
}

///@desc 推进预览循环：亮音符、出特效并在切换时出声
///@returns {Struct} kind、showing 与 fx_age
function skin_preview_cycle() {
	var now = current_time;
	if (!variable_instance_exists(id, "skin_fx_cycle_t0") || !is_real(skin_fx_cycle_t0) || skin_fx_cycle_t0 < 0) {
		skin_fx_cycle_t0 = now;
		skin_fx_last_hit = -1;
	};
	var elapsed = max(0, now - skin_fx_cycle_t0);
	// 每 2 秒一轮，前 1 秒显示音符
	var period = 2000;
	var slot = floor(elapsed / period);
	var phase = elapsed - slot * period;
	var kind_i = slot mod 3;
	var showing = (phase < 1000);
	var fx_age = showing ? -1 : ((phase - 1000) * 0.001);
	// 进入特效阶段时只触发一次音效和随机粒子
	if (!showing && (!variable_instance_exists(id, "skin_fx_last_hit") || skin_fx_last_hit != slot)) {
		skin_fx_last_hit = slot;
		skin_fx_rot = [];
		skin_fx_scales = [];
		repeat (4) {
			array_add(skin_fx_rot, random_range(0, 360));
			array_add(skin_fx_scales, random_range(17, 19));
		};
		skin_fx_rx = random_range(225, 350);
		skin_fx_ry = random_range(225, 350);
		skin_preview_play_hitsound(kind_i);
	};
	return { kind: kind_i, showing: showing, fx_age: fx_age };
}

///@desc 绘制预览用的方形打击粒子
///@param {Real} _x 中心 x
///@param {Real} _y 中心 y
///@param {Real} _age 0 到 1 的进度
///@param {Real} _col 颜色
///@param {Real} _gs 全局缩放
///@param {Array} _rot 各粒子角度
///@param {Array} _scales 各粒子尺寸
///@param {Real} _rx 水平散布
///@param {Real} _ry 垂直散布
///@returns {Undefined} 无
function skin_draw_preview_particles(_x, _y, _age, _col, _gs, _rot, _scales, _rx, _ry) {
	// 超出 0 到 1 则不画粒子
	if (_age < 0 || _age > 1) then return;
	if (!is_array(_rot) || !is_array(_scales) || !sprite_exists(spr_pixel_1)) then return;
	var progress = clamp(_age, 0, 1);
	var subimage = clamp(_age * 60, 0, 30);
	var gs = real(_gs);
	if (gs <= 0) then gs = 1;
	var n = min(4, min(array_length(_rot), array_length(_scales)));
	for (var port = 0; port < n; port++) {
		// 距离和尺寸用固定多项式，透明度随帧下降
		var dist = (((850.3997391752 * progress + 6236.3848902154) * progress + 80.3542231806) * progress)
			/ ((6570.5817658876 * progress + 495.7977913926) * progress + 1.0);
		var size_t = (progress >= 0.25 ? (0.25 - progress * 0.29999) : progress);
		var draw_scale = (((0.20783014 * size_t - 1.65243926) * size_t + 1.6398785) * size_t + 0.49884492);
		var particle_scale = (real(_scales[port]) * gs * draw_scale);
		draw_sprite_ext(
			spr_pixel_1,
			0,
			_x + dist * dcos(_rot[port]) * real(_rx) * gs,
			_y + dist * dsin(_rot[port]) * real(_ry) * gs,
			particle_scale,
			particle_scale,
			0,
			_col,
			(30 - subimage) / 30
		);
	};
}
