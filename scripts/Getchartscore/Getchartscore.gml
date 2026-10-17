// v2.3.0 的脚本资产已更改，请参见
// https://help.yoyogames.com/hc/en-us/articles/360005277377
///@desc 按当前连击占最大连击的比例生成七位分数字符串
///@returns {String} 左侧补零后的七位分数
function Getchartscore(){
	if (!is_real(maxcombo) || !is_finite(maxcombo) || maxcombo <= 0) then return("0000000");
	var _s,_t;
	//_mcombo = (_mcombo <= 0 ? 1 : _mcombo)
	//if(_chart_autoplay){
	var __combo = is_real(combo) && is_finite(combo) ? combo : 0;
	// 分数为连击比例乘以一百万，再截成整数
	_s = (int64(1000000 * (__combo / maxcombo)));
	if (is_finite(_s)) then _s = (_s | 0);
	else _s = 0;
	//}
	var _l_scombo_ = (string_length(string(_s))),
		_scmrzero = (7 - _l_scombo_ <= 0 ? 0 : 7 - _l_scombo_),
		_t = "";
	// 不足七位时在前面补零
	repeat(_scmrzero){
		_t+="0";
	};
	_t += string(_s);
	return(_t);
};

// 故意固定密钥，便于成绩文件在不同安装之间复制
#macro CHART_SCORE_KEY "PhiRR-Score-Migrate-v1"

///@desc 连击标题；自动游玩含渲染模式时不显示默认字样
///@returns {String} 要绘制的连击文字
function chart_combo_caption() {
	var text = "COMBO";
	if (variable_global_exists("game") && is_struct(game) && is_struct(game.settings)) {
		text = string(game.settings.comboString ?? "COMBO");
	};
	text = string_trim(text);
	if (!chart_autoplay_active()) {
		if (!string_length(text)) then return "COMBO";
		return text;
	};
	// 自动游玩时，空标题或默认字样改成自动游玩
	if (!string_length(text) || string_lower(text) == "combo") then return "AUTOPLAY";
	return text;
}

///@desc 成绩簿文件路径
///@returns {String} 工作目录下的成绩文件路径
function chart_score_file() {
	return working_directory + "resource/scores.prr";
}

///@desc 解析当前谱面文件的实际路径
///@returns {String} 谱面路径，找不到时为空串
function chart_score_chart_path() {
	var rel = "";
	if (variable_global_exists("game") && is_struct(game) && is_struct(game.folder_chart)) {
		rel = string(game.folder_chart.chart ?? "");
	};
	// 局内路径为空时改用会话里记录的谱面文件
	if (!string_length(rel) && variable_global_exists("chart_session") && is_struct(global.chart_session)) {
		rel = string(global.chart_session.chart_file ?? "");
	};
	if (!string_length(rel)) then return "";
	return chart_in_path(rel);
}

///@desc 计算谱面文件本身的 MD5
///@returns {String} 三十二位小写摘要，失败时为空串
function chart_score_md5() {
	var session = undefined;
	if (variable_global_exists("chart_session") && is_struct(global.chart_session)) {
		session = global.chart_session;
	};
	var path = chart_score_chart_path();
	if (is_struct(session)) {
		var cached = string_lower(string(session.chart_md5 ?? ""));
		var cached_path = string(session.chart_md5_path ?? "");
		if (string_length(cached) == 32 && cached_path == path) then return cached;
	};
	if (!string_length(path) || !file_exists(path)) then return "";
	var hash = "";
	try {
		hash = string_lower(md5_file(path));
	} catch (hash_err) {
		delete(hash_err);
		hash = "";
	};
	// 直接摘要失败时，再把文件读进缓冲区计算
	if (string_length(hash) != 32) {
		var buf = -1;
		try { buf = buffer_load(path); } catch (load_err) { delete(load_err); buf = -1; };
		if (buf != -1) {
			var nbytes = buffer_get_size(buf);
			if (nbytes > 0) {
				try { hash = string_lower(buffer_md5(buf, 0, nbytes)); }
				catch (buf_err) { delete(buf_err); hash = ""; };
			};
			buffer_delete(buf);
		};
	};
	if (string_length(hash) == 32 && is_struct(session)) {
		session.chart_md5 = hash;
		session.chart_md5_path = path;
	};
	return (string_length(hash) == 32) ? hash : "";
}

///@desc 用固定密钥就地异或成绩缓冲
///@param {Real} _buf 待加密或解密的缓冲
///@returns {Undefined} 无
function chart_score_crypt(_buf) {
	var key = CHART_SCORE_KEY;
	var key_len = string_byte_length(key);
	if (key_len <= 0) then return;
	var count = buffer_get_size(_buf);
	// 密钥字节再混入位置扰码后逐字节异或
	for (var i = 0; i < count; i++) {
		var raw = buffer_peek(_buf, i, buffer_u8);
		var key_byte = string_byte_at(key, i mod key_len);
		var mix = (i * 131 + 17) & 255;
		buffer_poke(_buf, i, buffer_u8, (raw ^ key_byte ^ mix) & 255);
	};
}

///@desc 创建一个空成绩簿
///@returns {Struct} 版本为 1 且记录为空的成绩簿
function chart_score_book_empty() {
	return { v: 1, records: {} };
}

///@desc 从磁盘读取并解密成绩簿
///@returns {Struct} 成绩簿，文件无效时为空簿
function chart_score_book_load() {
	var empty = chart_score_book_empty();
	var path = chart_score_file();
	if (!file_exists(path)) then return empty;
	var file_buf = -1;
	try { file_buf = buffer_load(path); } catch (load_err) { delete(load_err); return empty; };
	if (file_buf == -1) then return empty;
	var total = buffer_get_size(file_buf);
	if (total < 8) {
		buffer_delete(file_buf);
		return empty;
	};
	var magic = chr(buffer_peek(file_buf, 0, buffer_u8))
		+ chr(buffer_peek(file_buf, 1, buffer_u8))
		+ chr(buffer_peek(file_buf, 2, buffer_u8))
		+ chr(buffer_peek(file_buf, 3, buffer_u8));
	// 文件头不符则放弃，避免把损坏数据当成绩
	if (magic != "PRR1") {
		buffer_delete(file_buf);
		return empty;
	};
	var body_len = total - 4;
	var body = buffer_create(body_len, buffer_fixed, 1);
	buffer_copy(file_buf, 4, body_len, body, 0);
	buffer_delete(file_buf);
	chart_score_crypt(body);
	buffer_seek(body, buffer_seek_start, 0);
	var text = "";
	try { text = buffer_read(body, buffer_string); } catch (read_err) { delete(read_err); text = ""; };
	buffer_delete(body);
	var data = undefined;
	try { data = json_parse(text); } catch (parse_err) { delete(parse_err); data = undefined; };
	if (!is_struct(data) || !is_struct(data[$ "records"])) then return empty;
	return data;
}

///@desc 返回已载入的全局成绩簿，没有则先读取
///@returns {Struct} 全局成绩簿
function chart_score_book() {
	if (variable_global_exists("chart_score_book") && is_struct(global.chart_score_book)
		&& is_struct(global.chart_score_book[$ "records"])) {
		return global.chart_score_book;
	};
	global.chart_score_book = chart_score_book_load();
	return global.chart_score_book;
}

///@desc 把成绩簿加密后写入磁盘
///@param {Struct} _book 成绩簿
///@returns {Bool} 写入后文件存在时为真
function chart_score_book_save(_book) {
	if (!is_struct(_book)) then return false;
	var folder = working_directory + "resource";
	if (!directory_exists(folder)) then directory_create(folder);
	var text = "";
	try { text = json_stringify(_book); } catch (json_err) { delete(json_err); return false; };
	var raw = buffer_create(1, buffer_grow, 1);
	buffer_write(raw, buffer_string, text);
	var used = buffer_tell(raw);
	var packed = buffer_create(used, buffer_fixed, 1);
	buffer_copy(raw, 0, used, packed, 0);
	buffer_delete(raw);
	// 先异或正文，再在前面加上文件头
	chart_score_crypt(packed);
	var out = buffer_create(used + 4, buffer_fixed, 1);
	buffer_write(out, buffer_u8, ord("P"));
	buffer_write(out, buffer_u8, ord("R"));
	buffer_write(out, buffer_u8, ord("R"));
	buffer_write(out, buffer_u8, ord("1"));
	buffer_copy(packed, 0, used, out, 4);
	buffer_delete(packed);
	var path = chart_score_file();
	buffer_save(out, path);
	buffer_delete(out);
	return file_exists(path);
}

///@desc 按谱面摘要读取已保存的最高分
///@param {Any} _md5 谱面摘要，省略时用当前谱面
///@returns {Real} 已保存分数，没有或非法时为 0
function chart_score_get(_md5 = undefined) {
	var score_key = string_lower(string(is_undefined(_md5) ? chart_score_md5() : _md5));
	if (string_length(score_key) != 32) then return 0;
	var book = chart_score_book();
	if (!struct_exists(book.records, score_key)) then return 0;
	var value = real(book.records[$ score_key]);
	if (!is_finite(value) || value < 0) then return 0;
	return floor(value);
}

///@desc 仅在新分数更高时写回成绩簿
///@param {String} _md5 谱面摘要
///@param {Real} _score 新分数
///@returns {Bool} 确实写入了更高分时为真
function chart_score_set(_md5, _score) {
	var score_key = string_lower(string(_md5));
	if (string_length(score_key) != 32) then return false;
	var stored_score = is_numeric(_score) ? floor(real(_score)) : 0;
	if (!is_finite(stored_score) || stored_score < 0) then stored_score = 0;
	var prev = chart_score_get(score_key);
	// 不覆盖已经更高的记录
	if (stored_score <= prev) then return false;
	var book = chart_score_book();
	book.records[$ score_key] = stored_score;
	return chart_score_book_save(book);
}
/*
getScore = (function() { return(int64(1000000 * ((getCombo()) / _num_of_notes))) });
getFormattedScore = (function() {
	var _score = (getScore());
	_score += 0.5;
	if (is_finite(_score)) then _score = (_score | 0);
	else _score = (1 << 31);
	// if (_score >= 1000000) return("1000000");
	return(string_replace_all((string_format(_score, 7, 0)), " ", "0"));
});
*/
