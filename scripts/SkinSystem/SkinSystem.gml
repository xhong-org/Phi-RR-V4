/// @desc Phira-compatible note skins (respacks). Default = built-in sprites.
/// Hit FX uses the pack atlas only; Phira's extra square particles are not used.

#macro SKIN_DEFAULT_ID ""

function skin_root_dir() {
	var dir = working_directory + "skins/";
	dir = string_replace_all(dir, "\\", "/");
	if (!directory_exists(dir)) {
		try { directory_create(dir); } catch (mkdir_err) { delete(mkdir_err); };
	};
	return dir;
}

function skin_index_path() {
	return skin_root_dir() + "index.json";
}

function skin_norm_dir(_dir) {
	var s = string_replace_all(string(_dir ?? ""), "\\", "/");
	if (string_length(s) && string_char_at(s, string_length(s)) != "/") then s += "/";
	return s;
}

function skin_join(_dir, _name) {
	return skin_norm_dir(_dir) + string(_name);
}

function skin_log(_message) {
	print($"[Skin] {string(_message ?? "")}");
}

function skin_zip_last_error() {
	var detail = "";
	try { detail = string(unicode_zip_backend_last_error() ?? ""); } catch (err_e) { delete(err_e); };
	return detail;
}

function skin_error(_message) {
	var title = lang("skin.errorTitle", "Skin");
	var text = string(_message ?? "");
	skin_log($"error: {text}");
	var buttons = [msgbox_button(lang("common.ok", "OK"))];
	if (i_wbox_native_ready()) {
		msgbox_error_sync(text, title, buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
	} else {
		msgbox_error_async(text, title, buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
	};
}

function skin_read_text(_path) {
	if (!file_exists(_path)) then return "";
	var buf = buffer_load(_path);
	if (!buffer_exists(buf)) then return "";
	buffer_seek(buf, buffer_seek_start, 0);
	var text = buffer_read(buf, buffer_text);
	buffer_delete(buf);
	if (string_length(text) && ord(string_char_at(text, 1)) == 65279) then text = string_delete(text, 1, 1);
	return text;
}

function skin_yaml_unquote(_s) {
	var s = string_trim(string(_s ?? ""));
	var n = string_length(s);
	if (n >= 2) {
		var a = string_char_at(s, 1);
		var b = string_char_at(s, n);
		if ((a == "\"" && b == "\"") || (a == "'" && b == "'")) {
			s = string_copy(s, 2, n - 2);
		};
	};
	return s;
}

function skin_yaml_number(_s) {
	var s = string_trim(string(_s ?? ""));
	if (!string_length(s)) then return 0;
	if (string_lower(string_copy(s, 1, 2)) == "0x") {
		var hex = string_delete(s, 1, 2);
		var v = 0;
		for (var i = 1; i <= string_length(hex); i++) {
			var ch = string_upper(string_char_at(hex, i));
			var d = string_pos(ch, "0123456789ABCDEF") - 1;
			if (d < 0) then break;
			v = v * 16 + d;
		};
		return v;
	};
	try { return real(s); } catch (e) { delete(e); return 0; };
}

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
		if (!string_length(yaml_line) || string_char_at(yaml_line, 1) == "#") then continue;
		var sep = string_pos(":", yaml_line);
		if (sep <= 0) then continue;
		var key = string_trim(string_copy(yaml_line, 1, sep - 1));
		var raw = string_trim(string_copy(yaml_line, sep + 1, string_length(yaml_line) - sep));
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

function skin_info_verify(_info) {
	if (!is_struct(_info)) then return lang("skin.invalidInfo", "Invalid info.yml");
	if (!string_length(string(_info.name ?? ""))) then return lang("skin.invalidInfo", "Invalid info.yml");
	if (string_length(_info.name) > 100) then return lang("skin.invalidInfo", "Invalid info.yml");
	if (string_length(string(_info.description ?? "")) > 1000) then return lang("skin.invalidInfo", "Invalid info.yml");
	var cells = real(_info.hitFx[0]) * real(_info.hitFx[1]);
	if (cells < 1 || cells > 10240) then return lang("skin.invalidInfo", "Invalid info.yml");
	return "";
}

function skin_color_from_u32(_c) {
	var c = floor(real(_c));
	if (c > 16777215) {
		var a = (c >> 24) & 255;
		var r = (c >> 16) & 255;
		var g = (c >> 8) & 255;
		var b = c & 255;
		return make_colour_rgb(r, g, b);
	};
	return make_colour_rgb((c >> 16) & 255, (c >> 8) & 255, c & 255);
}

function skin_index_default() {
	return { selected: SKIN_DEFAULT_ID, packs: [] };
}

function skin_index_load() {
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
		global.skin_index_mem = skin_index_default();
		return global.skin_index_mem;
	};
}

function skin_index_entry(_pack) {
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

function skin_index_save(_index) {
	if (!is_struct(_index)) then return;
	var packs = [];
	if (is_array(_index.packs)) {
		for (var i = 0; i < array_length(_index.packs); i++) {
			var entry = skin_index_entry(_index.packs[i]);
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

function skin_find_info_dir(_root) {
	var root = skin_norm_dir(_root);
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
		if (file_exists(nested + "info.yml")) then return nested;
	};
	return "";
}

function skin_required_files() {
	return ["info.yml", "click.png", "click_mh.png", "drag.png", "drag_mh.png",
		"flick.png", "flick_mh.png", "hold.png", "hold_mh.png", "hit_fx.png"];
}

function skin_missing_file(_dir) {
	var files = skin_required_files();
	for (var i = 0; i < array_length(files); i++) {
		if (!file_exists(skin_join(_dir, files[i]))) then return files[i];
	};
	return "";
}

function skin_sanitize_id(_name) {
	var s = string(_name ?? "skin");
	var out = "";
	for (var i = 1; i <= string_length(s); i++) {
		var ch = string_char_at(s, i);
		var ok = (ch == "_") || (ch == "-")
			|| (ch >= "0" && ch <= "9")
			|| (ch >= "a" && ch <= "z")
			|| (ch >= "A" && ch <= "Z");
		out += ok ? ch : "_";
	};
	if (!string_length(out)) then out = "skin";
	if (string_length(out) > 40) then out = string_copy(out, 1, 40);
	return out;
}

function skin_unique_folder(_base) {
	var root = skin_root_dir();
	var skin_id = _base + "_" + string(irandom_range(10000, 99999));
	var guard = 0;
	while (directory_exists(root + skin_id) && guard < 32) {
		skin_id = _base + "_" + string(irandom_range(10000, 99999));
		guard++;
	};
	return skin_id;
}

function skin_list() {
	var index = skin_index_load();
	if (variable_global_exists("skin_list_ok") && global.skin_list_ok) then return index;
	var packs = is_array(index.packs) ? index.packs : [];
	var live = [];
	for (var i = 0; i < array_length(packs); i++) {
		var pack = packs[i];
		if (!is_struct(pack)) then continue;
		var folder = skin_join(skin_root_dir(), string(pack[$ "folder"] ?? pack[$ "skin_id"] ?? pack[$ "id"] ?? ""));
		var info_dir = skin_find_info_dir(folder);
		if (!string_length(info_dir)) then continue;
		array_add(live, skin_index_entry(pack));
	};
	index.packs = live;
	var still = (string(index.selected) == SKIN_DEFAULT_ID);
	for (var j = 0; j < array_length(live); j++) {
		if (string(live[j].skin_id) == string(index.selected)) then still = true;
	};
	if (!still) then index.selected = SKIN_DEFAULT_ID;
	global.skin_list_ok = true;
	if (array_length(live) != array_length(packs) || !still) then skin_index_save(index);
	else global.skin_index_mem = index;
	return index;
}

function skin_selected_id() {
	return string(skin_list().selected ?? SKIN_DEFAULT_ID);
}

function skin_set_selected(_id) {
	var index = skin_list();
	index.selected = string(_id ?? SKIN_DEFAULT_ID);
	skin_index_save(index);
}

function skin_menu_items() {
	var items = [{ skin_id: SKIN_DEFAULT_ID, name: lang("skin.default", "Default"), author: "", description: "" }];
	var index = skin_list();
	for (var i = 0; i < array_length(index.packs); i++) {
		array_add(items, index.packs[i]);
	};
	return items;
}

function skin_destroy_sprite(_spr) {
	if (sprite_exists(_spr) && _spr != note_tap && _spr != note_drag && _spr != note_flick
		&& _spr != note_hold_head && _spr != note_hold_body && _spr != note_hold_end
		&& _spr != effect) {
		try { sprite_delete(_spr); } catch (e) { delete(e); };
	};
}

function skin_destroy_sound(_snd, _buf = -1) {
	if (is_undefined(_snd) || _snd == snd_note_tap || _snd == snd_note_drag || _snd == snd_note_flick) then return;
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

function skin_destroy_fmod(_snd) {
	if (!is_real(_snd) || _snd <= 0) then return;
	if (!extension_exists("FMOD")) then return;
	try { fmod_sound_release(_snd); } catch (e) { delete(e); };
}

function skin_pack_unload(_pack) {
	if (!is_struct(_pack)) then return;
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

function skin_copy_surface_begin() {
	gpu_set_blendenable(true);
	gpu_set_colourwriteenable(true, true, true, true);
	gpu_set_blendmode_ext(bm_one, bm_zero);
}

function skin_copy_surface_end(_pushed = false) {
	gpu_set_blendmode(bm_normal);
}

function skin_add_centered(_path) {
	if (!file_exists(_path)) then return -1;
	var spr = sprite_add(_path, 1, false, false, 0, 0);
	if (!asset_sprite_valid(spr)) then return -1;
	sprite_set_offset(spr, sprite_get_width(spr) * 0.5, sprite_get_height(spr) * 0.5);
	return spr;
}

function skin_crop_rect(_src, _x0, _y0, _cw, _ch, _ox, _oy) {
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

function skin_sprite_keep(_spr) {
}

function skin_crop_band(_src, _y0, _h, _ox, _oy) {
	if (!sprite_exists(_src) || _h < 1) then return -1;
	return skin_crop_rect(_src, 0, _y0, sprite_get_width(_src), _h, _ox, _oy);
}

function skin_sprite_opaque_rect(_spr) {
	if (!sprite_exists(_spr)) then return undefined;
	var w = sprite_get_width(_spr);
	var h = sprite_get_height(_spr);
	if (w < 1 || h < 1) then return undefined;
	var surf = surface_create(w, h);
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
			if (buffer_peek(buf, row + px * 4 + 3, buffer_u8) > 0) {
				if (px < px0) then px0 = px;
				if (py < py0) then py0 = py;
				if (px > px1) then px1 = px;
				if (py > py1) then py1 = py;
			}
		}
	};
	buffer_delete(buf);
	if (px1 < 0) then return { x0: 0, y0: 0, x1: w - 1, y1: h - 1 };
	return { x0: px0, y0: py0, x1: px1, y1: py1 };
}

function skin_sprite_trim_empty(_spr, _origin = "center") {
	if (!sprite_exists(_spr)) then return _spr;
	var w = sprite_get_width(_spr);
	var h = sprite_get_height(_spr);
	var rect = skin_sprite_opaque_rect(_spr);
	if (!is_struct(rect)) {
		sprite_set_offset(_spr, w * 0.5, (_origin == "bottom") ? h : h * 0.5);
		return _spr;
	};
	var cw = max(1, rect.x1 - rect.x0 + 1);
	var ch = max(1, rect.y1 - rect.y0 + 1);
	var ox = cw * 0.5;
	var oy = (_origin == "bottom") ? ch : ch * 0.5;
	if (cw == w && ch == h && rect.x0 == 0 && rect.y0 == 0) {
		sprite_set_offset(_spr, ox, oy);
		skin_log($"trim keep {w}x{h} origin=({ox},{oy})");
		return _spr;
	};
	var cropped = skin_crop_rect(_spr, rect.x0, rect.y0, cw, ch, ox, oy);
	if (!asset_sprite_valid(cropped)) {
		sprite_set_offset(_spr, ox, oy);
		return _spr;
	};
	skin_log($"trim {w}x{h} -> {cw}x{ch} from ({rect.x0},{rect.y0}) origin=({ox},{oy})");
	skin_destroy_sprite(_spr);
	return cropped;
}

function skin_split_hold(_src, _atlas) {
	if (!sprite_exists(_src)) then return { tail: -1, body: -1, head: -1 };
	var h = sprite_get_height(_src);
	var w = sprite_get_width(_src);
	var tail_h = max(0, floor(real(_atlas[0])));
	var head_h = max(0, floor(real(_atlas[1])));
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

function skin_hitsounds_ensure_default() {
	if (variable_global_exists("render_mode") && global.render_mode) then return;
	if (!audio_group_is_loaded(audiogroup_hitsounds)) {
		audio_group_load(audiogroup_hitsounds);
		global.default_hitsounds_load_requested = true;
	};
}

function skin_sound_path(_dir, _stem) {
	var exts = [".ogg", ".oga", ".opus", ".wav", ".wave", ".mp3", ".mpga",
		".m4a", ".mp4", ".aac", ".m4b", ".flac", ".aiff", ".aif", ".aifc", ".caf"];
	for (var i = 0; i < array_length(exts); i++) {
		var path = skin_join(_dir, _stem + exts[i]);
		if (file_exists(path)) then return path;
	};
	return "";
}

function skin_buf_u8(_buf, _off) {
	if (_off < 0 || _off >= buffer_get_size(_buf)) then return -1;
	buffer_seek(_buf, buffer_seek_start, _off);
	return buffer_read(_buf, buffer_u8);
}

function skin_buf_tag(_buf, _off, _n = 4) {
	var s = "";
	for (var i = 0; i < _n; i++) {
		var b = skin_buf_u8(_buf, _off + i);
		if (b < 0) then return s;
		s += chr(b);
	};
	return s;
}

function skin_id3_payload_off(_buf, _off, _size) {
	if (_off + 10 > _size) then return _off;
	if (skin_buf_tag(_buf, _off, 3) != "ID3") then return _off;
	var flags = skin_buf_u8(_buf, _off + 5);
	var tag = ((skin_buf_u8(_buf, _off + 6) & 127) << 21)
		| ((skin_buf_u8(_buf, _off + 7) & 127) << 14)
		| ((skin_buf_u8(_buf, _off + 8) & 127) << 7)
		| (skin_buf_u8(_buf, _off + 9) & 127);
	var start = _off + 10 + tag;
	if ((flags & 16) != 0) then start += 10;
	return clamp(start, _off + 10, _size);
}

function skin_sound_ogg_kind(_buf, _off, _size) {
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

function skin_sound_mpeg_kind(_b0, _b1) {
	if (_b0 != 255 || (_b1 & 224) != 224) then return "";
	var _layer = (_b1 >> 1) & 3;
	if (_layer == 0) then return "aac";
	return "mp3";
}

function skin_sound_format_at(_buf, _off, _size) {
	if (_off < 0 || _off + 4 > _size) then return "";
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

function skin_sound_format_scan(_buf, _size) {
	var off = 0;
	if (_size >= 3 && skin_buf_u8(_buf, 0) == 239 && skin_buf_u8(_buf, 1) == 187 && skin_buf_u8(_buf, 2) == 191) {
		off = 3;
	};
	repeat (3) {
		var next = skin_id3_payload_off(_buf, off, _size);
		if (next == off) then break;
		off = next;
	};
	var fmt = skin_sound_format_at(_buf, off, _size);
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

function skin_sound_format(_path) {
	if (!file_exists(_path)) then return "";
	var buf = -1;
	try { buf = buffer_load(_path); } catch (e) { delete(e); return ""; };
	if (!buffer_exists(buf)) then return "";
	var fmt = skin_sound_format_scan(buf, buffer_get_size(buf));
	buffer_delete(buf);
	return fmt;
}

function skin_sound_ext_matches(_fmt, _ext) {
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

function skin_sound_prepared_path(_path) {
	var src = string(_path ?? "");
	if (!string_length(src) || !file_exists(src)) then return src;
	var fmt = skin_sound_format(src);
	if (fmt == "id3") then fmt = "mp3";
	if (!string_length(fmt)) {
		skin_log($"sfx format unknown path={src}");
		return src;
	};
	var ext = string_lower(filename_ext(src));
	if (skin_sound_ext_matches(fmt, ext)) then return src;
	var dir = game_save_id + "skin_sfx/";
	if (!directory_exists(dir)) {
		try { directory_create(dir); } catch (mkdir_err) { delete(mkdir_err); };
	};
	var dest = dir + md5_string_utf8(src) + "." + fmt;
	if (file_exists(dest)) then return dest;
	var buf = -1;
	try { buf = buffer_load(src); } catch (load_err) { delete(load_err); buf = -1; };
	if (!buffer_exists(buf)) then return src;
	var size = buffer_get_size(buf);
	var start = 0;
	if (size >= 10) {
		buffer_seek(buf, buffer_seek_start, 0);
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

function skin_wav_make_sound(_path) {
	var src = -1;
	try { src = buffer_load(_path); } catch (e) { delete(e); return { snd: -1, buf: -1 }; };
	if (!buffer_exists(src)) then return { snd: -1, buf: -1 };
	var size = buffer_get_size(src);
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

function skin_try_sound(_path, _stem) {
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

function skin_pack_fmod_ensure(_pack) {
	if (!is_struct(_pack)) then return false;
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

function skin_pack_load(_root, _info) {
	var dir = skin_norm_dir(_root);
	skin_log($"pack load dir={dir}");
	var missing = skin_missing_file(dir);
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
		if (!asset_sprite_valid(spr)) {
			skin_log($"sprite_add failed {keys[i][1]} path={spr_path} exists={file_exists(spr_path)}");
			skin_pack_unload(pack);
			return { ok: false, error: langf("skin.missingFile", keys[i][1]) };
		};
		skin_log($"sprite {keys[i][1]} {sprite_get_width(spr)}x{sprite_get_height(spr)}");
		pack[$ keys[i][0]] = spr;
	};
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

function skin_pack_gpu_ensure(_pack, _measure = false) {
	if (!is_struct(_pack)) then return false;
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
	skin_destroy_sprite(_pack.hold);
	skin_destroy_sprite(_pack.hold_mh);
	_pack.hold = -1;
	_pack.hold_mh = -1;
	_pack.gpu_ready = true;
	skin_log($"gpu ensure ok preview_row_ratio={preview_ratio}");
	return true;
}

function skin_runtime_gpu_ensure() {
	if (!variable_global_exists("skin_on") || !global.skin_on) then return;
	var pack = skin_runtime();
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

function skin_tex_flag(_spr) {
	if (is_undefined(_spr) || is_string(_spr)) then return "-";
	if (is_real(_spr) && _spr < 0) then return "-";
	if (!sprite_exists(_spr)) then return "NO";
	var tex = sprite_get_texture(_spr, 0);
	if (is_undefined(tex) || (is_real(tex) && tex < 0)) then return "NT";
	if (!texture_is_ready(tex)) then return "DYN";
	return "OK";
}

function skin_tex_group_name(_st) {
	if (_st == texturegroup_status_unloaded) then return "unloaded";
	if (_st == texturegroup_status_loading) then return "loading";
	if (_st == texturegroup_status_loaded) then return "loaded";
	if (_st == texturegroup_status_fetched) then return "fetched";
	return string(_st);
}

function skin_tex_diag_frame() {
	if (!variable_global_exists("skin_tex_diag_f")) then global.skin_tex_diag_f = 0;
	global.skin_tex_diag_f += 1;
	if (global.skin_tex_diag_f == 1) {
		print($"[Skin] tex typeof tap={typeof(note_tap)} str={string(note_tap)} exists={sprite_exists(note_tap)}");
	};
	var on = skin_active() ? 1 : 0;
	var grp = skin_tex_group_name(texturegroup_get_status("DefaultNotes"));
	var loaded = (variable_global_exists("default_notes_texture_loaded") && global.default_notes_texture_loaded) ? 1 : 0;
	var note_n = 0;
	var draw_n = 0;
	var vis_n = 0;
	if (instance_exists(oNote)) {
		note_n += instance_number(oNote);
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
	var msg = $"[Skin] tex f={global.skin_tex_diag_f} on={on} grp={grp} loaded={loaded} notes={note_n} draw={draw_n} vis={vis_n} tap={skin_tex_flag(note_tap)} drag={skin_tex_flag(note_drag)} flick={skin_tex_flag(note_flick)} hh={skin_tex_flag(note_hold_head)} hb={skin_tex_flag(note_hold_body)} he={skin_tex_flag(note_hold_end)} fx={skin_tex_flag(effect)} px={skin_tex_flag(spr_pixel_1)}";
	if (on) {
		var pack = skin_runtime();
		if (!is_struct(pack)) {
			msg += " pack=NONE";
		} else {
			msg += $" click={skin_tex_flag(pack[$ "click"])} click_mh={skin_tex_flag(pack[$ "click_mh"])} dragp={skin_tex_flag(pack[$ "drag"])} drag_mh={skin_tex_flag(pack[$ "drag_mh"])} flickp={skin_tex_flag(pack[$ "flick"])} flick_mh={skin_tex_flag(pack[$ "flick_mh"])} hold={skin_tex_flag(pack[$ "hold"])} hold_mh={skin_tex_flag(pack[$ "hold_mh"])} hit={skin_tex_flag(pack[$ "hit_fx"])} shh={skin_tex_flag(pack[$ "hold_head"])} shb={skin_tex_flag(pack[$ "hold_body"])} sht={skin_tex_flag(pack[$ "hold_tail"])} shh_mh={skin_tex_flag(pack[$ "hold_head_mh"])} shb_mh={skin_tex_flag(pack[$ "hold_body_mh"])} sht_mh={skin_tex_flag(pack[$ "hold_tail_mh"])}";
		};
	};
	print(msg);
}

function skin_runtime() {
	if (variable_global_exists("skin_gameplay") && is_struct(global.skin_gameplay)) then return global.skin_gameplay;
	return undefined;
}

function skin_preview_runtime() {
	if (variable_global_exists("skin_preview") && is_struct(global.skin_preview)) then return global.skin_preview;
	return undefined;
}

function skin_active() {
	return variable_global_exists("skin_on") && global.skin_on;
}

function skin_preview_unload() {
	if (variable_global_exists("skin_preview")) {
		skin_pack_unload(global.skin_preview);
		global.skin_preview = undefined;
	};
	global.skin_preview_id = undefined;
}

function skin_gameplay_unload() {
	if (variable_global_exists("skin_gameplay")) {
		skin_pack_unload(global.skin_gameplay);
		global.skin_gameplay = undefined;
	};
	global.skin_gameplay_id = undefined;
	global.skin_on = false;
	global.skin_gpu_done = true;
}

function skin_load_id(_id) {
	var skin_id = string(_id ?? SKIN_DEFAULT_ID);
	skin_log($"load id={skin_id}");
	if (skin_id == SKIN_DEFAULT_ID) then return { ok: true, pack: undefined };
	var index = skin_list();
	var entry = undefined;
	for (var i = 0; i < array_length(index.packs); i++) {
		if (string(index.packs[i].skin_id) == skin_id) {
			entry = index.packs[i];
			break;
		};
	};
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

function skin_preview_set(_id) {
	var skin_id = string(_id ?? SKIN_DEFAULT_ID);
	skin_log($"preview set id={skin_id}");
	if (variable_global_exists("skin_preview_id") && global.skin_preview_id == skin_id && (skin_id == SKIN_DEFAULT_ID || is_struct(skin_preview_runtime()))) {
		return true;
	};
	var prev_id = variable_global_exists("skin_preview_id") ? string(global.skin_preview_id ?? SKIN_DEFAULT_ID) : SKIN_DEFAULT_ID;
	skin_preview_unload();
	if (skin_id == SKIN_DEFAULT_ID) {
		global.skin_preview_id = skin_id;
		if (instance_exists(oSettings)) then skin_preview_cycle_reset();
		return true;
	};
	var loaded = skin_load_id(skin_id);
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

function skin_gameplay_ensure() {
	skin_preview_unload();
	var skin_id = skin_selected_id();
	skin_log($"gameplay ensure selected={skin_id}");
	if (skin_id == SKIN_DEFAULT_ID) {
		skin_gameplay_unload();
		global.skin_gameplay_id = skin_id;
		return true;
	};
	if (variable_global_exists("skin_gameplay_id") && global.skin_gameplay_id == skin_id && is_struct(skin_runtime())) {
		global.skin_on = true;
		return true;
	};
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
		if (directory_exists(full)) then skin_folder_rmdir(full);
		else {
			try { file_delete(full); } catch (df) { delete(df); };
		};
	};
	try { directory_destroy(path); } catch (rm) { delete(rm); };
}

function skin_folder_remove(_path) {
	var path = string(_path ?? "");
	if (!string_length(path)) then return;
	try { chart_session_remove_dir(path); } catch (rm) { delete(rm); };
	skin_folder_rmdir(path);
}

function skin_ui_refresh() {
	if (instance_exists(oSettings)) then oSettings.hits_tab = -1;
}

function skin_import_fail(_message) {
	var text = string(_message ?? lang("skin.importFailed", "Failed to import skin."));
	var detail = skin_zip_last_error();
	if (string_length(detail) && string_pos(detail, text) <= 0) then text += "\n" + detail;
	skin_log($"import fail: {text}");
	skin_error(text);
}

function skin_copy_file(_src, _dst) {
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

function skin_import_queue(_zip_path) {
	var zip = string(_zip_path ?? "");
	skin_log($"queue zip={zip} len={string_length(zip)} file_exists={file_exists(zip)}");
	if (!string_length(zip)) then return false;
	if (instance_exists(oSettings)) {
		oSettings.skin_import_path = zip;
		skin_log("queued for next settings step");
		return true;
	};
	return skin_import_zip(zip);
}

function skin_import_busy() {
	return instance_exists(oSettings) && is_real(oSettings.skin_zip_task) && oSettings.skin_zip_task >= 0;
}

function skin_import_cancel() {
	if (!instance_exists(oSettings)) then return;
	with (oSettings) {
		if (is_real(skin_zip_task) && skin_zip_task >= 0) {
			skin_log($"cancel extract task={skin_zip_task}");
			try { unicode_zip_backend_task_cancel(skin_zip_task); } catch (cancel_err) { delete(cancel_err); };
			try { unicode_zip_backend_task_release(skin_zip_task); } catch (rel_err) { delete(rel_err); };
			skin_zip_task = -1;
		};
		if (is_string(skin_zip_copy) && string_length(skin_zip_copy) && file_exists(skin_zip_copy)) {
			try { file_delete(skin_zip_copy); } catch (del_err) { delete(del_err); };
		};
		skin_zip_copy = "";
		skin_zip_dest = "";
		skin_zip_folder = "";
	};
}

function skin_import_finish(_dest, _folder) {
	var dest = string(_dest ?? "");
	var folder = string(_folder ?? "");
	var info_dir = skin_find_info_dir(dest);
	skin_log($"finish dest={dest} dest_exists={directory_exists(dest)} info_dir={info_dir}");
	if (!string_length(info_dir)) {
		skin_folder_remove(dest);
		skin_error(lang("skin.parseFailed", "Failed to parse skin."));
		return false;
	};
	var missing = skin_missing_file(info_dir);
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

function skin_import_poll() {
	if (!instance_exists(oSettings)) then return;
	if (!is_real(oSettings.skin_zip_task) || oSettings.skin_zip_task < 0) then return;
	var task = oSettings.skin_zip_task;
	var status = unicode_zip_backend_task_status(task);
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

function skin_import_zip(_zip_path) {
	var zip = string(_zip_path ?? "");
	skin_log($"import begin zip={zip} exists={file_exists(zip)} backend={unicode_zip_backend_available()} root={skin_root_dir()}");
	if (!string_length(zip)) {
		skin_import_fail(lang("skin.importFailed", "Failed to import skin."));
		return false;
	};
	if (!unicode_zip_backend_available()) {
		skin_log("unicode zip backend unavailable");
		skin_import_fail(lang("skin.importFailed", "Failed to import skin."));
		return false;
	};
	if (!instance_exists(oSettings)) {
		skin_log("import requires settings instance for async extract");
		skin_import_fail(lang("skin.importFailed", "Failed to import skin."));
		return false;
	};
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

function skin_delete_id(_id) {
	var skin_id = string(_id ?? "");
	skin_log($"delete id={skin_id}");
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

function skin_pick_file() {
	skin_log($"pick file os={os_type} gx={pls_is_gxgames()}");
	if (pls_is_gxgames()) {
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

function skin_note_scale_base(_spr) {
	if (!sprite_exists(_spr)) then return _spr;
	var pack = skin_runtime();
	if (!is_struct(pack)) then pack = skin_preview_runtime();
	if (!is_struct(pack)) then return _spr;
	if ((_spr == pack.click || _spr == pack.click_mh) && sprite_exists(pack.click_mh)) then return pack.click_mh;
	if ((_spr == pack.drag || _spr == pack.drag_mh) && sprite_exists(pack.drag_mh)) then return pack.drag_mh;
	if ((_spr == pack.flick || _spr == pack.flick_mh) && sprite_exists(pack.flick_mh)) then return pack.flick_mh;
	if ((_spr == pack.hold_head || _spr == pack.hold_head_mh) && sprite_exists(pack.hold_head_mh)) then return pack.hold_head_mh;
	if ((_spr == pack.hold_body || _spr == pack.hold_body_mh) && sprite_exists(pack.hold_body_mh)) then return pack.hold_body_mh;
	if ((_spr == pack.hold_tail || _spr == pack.hold_tail_mh) && sprite_exists(pack.hold_tail_mh)) then return pack.hold_tail_mh;
	return _spr;
}

function skin_note_scale_k(_spr) {
	if (!sprite_exists(_spr)) then return 1;
	var ref_w = 1089;
	var pack = skin_runtime();
	if (is_struct(pack) && is_real(pack.note_ref_w) && pack.note_ref_w > 1) then ref_w = pack.note_ref_w;
	else if (sprite_exists(note_tap)) then ref_w = max(1, sprite_get_width(note_tap));
	var src = skin_note_scale_base(_spr);
	return ref_w / max(1, sprite_get_width(sprite_exists(src) ? src : _spr));
}

function skin_hitfx_game_scale(_pack) {
	var gs = variable_global_exists("global_scales") ? global_scales : 1;
	if (!is_struct(_pack) || !sprite_exists(_pack.hit_fx)) then return gs;
	var cols = max(1, real(_pack.hit_cols));
	var rows = max(1, real(_pack.hit_rows));
	var cell = max(1, max(sprite_get_width(_pack.hit_fx) / cols, sprite_get_height(_pack.hit_fx) / rows));
	var ref = sprite_exists(effect) ? max(1, max(sprite_get_width(effect), sprite_get_height(effect))) : 248;
	return gs * ref / cell;
}

function skin_note_sprite(_kind, _hl) {
	var pack = skin_runtime();
	if (!is_struct(pack)) then return -1;
	var mh = (_hl == 1);
	switch (string(_kind)) {
		case "tap": return mh ? pack.click_mh : pack.click;
		case "drag": return mh ? pack.drag_mh : pack.drag;
		case "flick": return mh ? pack.flick_mh : pack.flick;
		default: return -1;
	};
}

function skin_note_sound(_kind, _fallback) {
	var pack = skin_runtime();
	if (!is_struct(pack)) then return _fallback;
	var snd = -1;
	switch (string(_kind)) {
		case "tap": snd = pack.sfx_click; break;
		case "drag": snd = pack.sfx_drag; break;
		case "flick": snd = pack.sfx_flick; break;
	};
	if (!is_undefined(snd) && audio_exists(snd)) then return snd;
	return _fallback;
}

function skin_note_kind_from_instance() {
	var t = variable_instance_exists(id, "type") ? real(type) : 1;
	if (object_index == oNote_2) {
		if (t == 4) then return "drag";
		if (t == 3) then return "flick";
		return "tap";
	};
	if (t == 2) then return "drag";
	if (t == 4) then return "flick";
	return "tap";
}

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
	if (variable_global_exists("render_mode") && global.render_mode) {
		return render_play_hitsound(_fallback, path);
	};
	if (is_real(fmod_snd) && fmod_snd > 0) {
		rpe_play_hitsound(_fallback, fmod_snd, path);
		return true;
	};
	if (!is_undefined(gm_snd) && audio_exists(gm_snd)) {
		return render_play_hitsound(gm_snd, path);
	};
	return render_play_hitsound(_fallback, path);
}

function skin_play_note_hitsound() {
	if (variable_instance_exists(id, "isFake") && bool(isFake)) then return false;
	var fallback = snd_note_tap;
	if (variable_instance_exists(id, "sound") && audio_exists(sound)) then fallback = sound;
	var custom_fmod = -1;
	var custom_path = "";
	if (variable_instance_exists(id, "custom_fmod_sound")) then custom_fmod = custom_fmod_sound;
	if (variable_instance_exists(id, "custom_hitsound_path")) then custom_path = string(custom_hitsound_path ?? "");
	if ((is_real(custom_fmod) && custom_fmod > 0) || string_length(custom_path)) {
		return rpe_play_hitsound(fallback, custom_fmod, custom_path);
	};
	return skin_play_hitsound(skin_note_kind_from_instance(), fallback);
}

function skin_hold_parts(_hl) {
	var pack = skin_runtime();
	if (!is_struct(pack) || !(variable_struct_exists(pack, "gpu_ready") && pack.gpu_ready)) then return undefined;
	if (_hl == 1) then return pack.parts_mh;
	return pack.parts_n;
}

function skin_hitfx_color(_pack, _col) {
	if (!is_struct(_pack) || !bool(_pack.info.hitFxTinted)) then return c_white;
	if (_col == make_colour_rgb(162, 238, 255)) then return skin_color_from_u32(_pack.info.colorGood);
	if (_col == #ffeca0) then return skin_color_from_u32(_pack.info.colorPerfect);
	return _col;
}

function skin_draw_hitfx(_pack, _x, _y, _age, _col, _scale) {
	if (!is_struct(_pack) || !sprite_exists(_pack.hit_fx)) then return false;
	var dur = max(0.05, real(_pack.info.hitFxDuration));
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

function skin_draw_hitfx_fitted(_pack, _x, _y, _age, _col, _box) {
	if (!is_struct(_pack) || !sprite_exists(_pack.hit_fx)) then return false;
	var cols = max(1, real(_pack.hit_cols));
	var rows = max(1, real(_pack.hit_rows));
	var cw = sprite_get_width(_pack.hit_fx) / cols;
	var ch = sprite_get_height(_pack.hit_fx) / rows;
	var box = max(8, real(_box));
	var hit_sc = max(0.05, real(_pack.info.hitFxScale));
	var fit = box / max(1, max(cw, ch));
	return skin_draw_hitfx(_pack, _x, _y, _age, _col, fit / hit_sc);
}

function skin_draw_default_hitfx(_x, _y, _age, _col, _box) {
	if (_age < 0 || _age >= 0.5) then return false;
	if (!sprite_exists(effect)) then return false;
	var sub = clamp(floor(_age * 60), 0, 29);
	var box = max(8, real(_box));
	var k = box / max(1, max(sprite_get_width(effect), sprite_get_height(effect)));
	draw_sprite_ext(effect, sub, _x, _y, k, k, 0, _col, 1);
	return true;
}

function skin_preview_note_disp_w(_spr, _box) {
	if (!sprite_exists(_spr)) then return max(8, real(_box));
	var nw = sprite_get_width(_spr);
	var nh = sprite_get_height(_spr);
	return nw * (real(_box) / max(1, max(nw, nh)));
}

function skin_draw_preview_hitfx(_pack, _x, _y, _age, _col, _note_w) {
	var note_w = max(8, real(_note_w));
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

function skin_preview_play_hitsound(_kind_i = 0) {
	skin_hitsounds_ensure_default();
	var pack = skin_preview_runtime();
	var kind_i = floor(real(_kind_i)) mod 3;
	if (kind_i < 0) then kind_i += 3;
	var snd = snd_note_tap;
	if (kind_i == 1) then snd = snd_note_drag;
	if (kind_i == 2) then snd = snd_note_flick;
	if (is_struct(pack)) {
		if (kind_i == 0 && audio_exists(pack.sfx_click)) then snd = pack.sfx_click;
		else if (kind_i == 1 && audio_exists(pack.sfx_drag)) then snd = pack.sfx_drag;
		else if (kind_i == 2 && audio_exists(pack.sfx_flick)) then snd = pack.sfx_flick;
	};
	if (audio_exists(snd)) then audio_play_sound(snd, 0, false);
}

function skin_preview_cycle_reset() {
	if (!instance_exists(oSettings)) then return;
	oSettings.skin_fx_cycle_t0 = current_time;
	oSettings.skin_fx_last_hit = -1;
	oSettings.skin_fx_rot = [];
	oSettings.skin_fx_scales = [];
}

function skin_preview_cycle() {
	var now = current_time;
	if (!variable_instance_exists(id, "skin_fx_cycle_t0") || !is_real(skin_fx_cycle_t0) || skin_fx_cycle_t0 < 0) {
		skin_fx_cycle_t0 = now;
		skin_fx_last_hit = -1;
	};
	var elapsed = max(0, now - skin_fx_cycle_t0);
	var period = 2000;
	var slot = floor(elapsed / period);
	var phase = elapsed - slot * period;
	var kind_i = slot mod 3;
	var showing = (phase < 1000);
	var fx_age = showing ? -1 : ((phase - 1000) * 0.001);
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

function skin_draw_preview_particles(_x, _y, _age, _col, _gs, _rot, _scales, _rx, _ry) {
	if (_age < 0 || _age > 1) then return;
	if (!is_array(_rot) || !is_array(_scales) || !sprite_exists(spr_pixel_1)) then return;
	var progress = clamp(_age, 0, 1);
	var subimage = clamp(_age * 60, 0, 30);
	var gs = real(_gs);
	if (gs <= 0) then gs = 1;
	var n = min(4, min(array_length(_rot), array_length(_scales)));
	for (var port = 0; port < n; port++) {
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
