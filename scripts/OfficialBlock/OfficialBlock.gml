/// 官谱 blockAreaList
/// 位姿、缓动、相减奇偶和材质通道都跟随该渲染器。
/// 着色器在谱面加载完成时编译。一帧只在方块处于 appear 到 disappear，
/// 或被挡住的手指正在淡出时才提交它们。

// 噪声区各渲染目标的槽位编号
#macro BLOCK_RT_ACTIVE_N 0
#macro BLOCK_RT_ACTIVE_H 1
#macro BLOCK_RT_READY_N 2
#macro BLOCK_RT_READY_H 3
#macro BLOCK_RT_OFF_N 4
#macro BLOCK_RT_OFF_H 5
#macro BLOCK_RT_ACTIVE_HP 6
#macro BLOCK_RT_READY_HP 7
#macro BLOCK_RT_ACTIVE_C 8
#macro BLOCK_RT_READY_C 9
#macro BLOCK_RT_OFF_HP 10
#macro BLOCK_RT_GLOW0 11
#macro BLOCK_RT_GLOW1 12
#macro BLOCK_RT_HOVER 13
#macro BLOCK_RT_PACK_M 14
#macro BLOCK_RT_PACK_E 15
#macro BLOCK_RT_SCENE 16
#macro BLOCK_RT_OFF_C 17
#macro BLOCK_RT_COUNT 18
// 超过这个数量就不再为每一块建结构体。百万级噪域会在加载画面结束后把内存吃满并卡住。
#macro OFFICIAL_BLOCK_PACK 48

///@desc 创建噪声区运行状态，含悬停槽和包围盒
///@returns {Struct} 初始状态
function official_block_state_create() {
	// 十个手指各一个悬停槽
	var hovers = array_create(10);
	for (var i = 0; i < 10; i++) hovers[i] = official_block_hover_new();
	return {
			ready: false,
			empty: true,
			loaded_enabled: false,
			preloaded: false,
			gpu_warm: false,
			cleared: false,
			warned: false,
			blocks: [],
			hovers: hovers,
			blocked_ids: [],
			touch_world: [],
			hover_live: false,
			need_gpu: false,
			on_active: false,
			on_ready: false,
			on_disabled: false,
			norm_active: false,
			norm_ready: false,
			norm_disabled: false,
			sub_active: false,
			sub_ready: false,
			sub_disabled: false,
			ok_subtract: false,
			ok_subtract_soft: false,
			ok_compose: false,
			ok_compose_plain: false,
			ok_glow: false,
			ok_disabled: false,
			ok_active: false,
			ok_ready: false,
			ok_pack_m: false,
			ok_pack_e: false,
			ok_hover: false,
			rt: array_create(BLOCK_RT_COUNT, -1),
			white_surf: -1,
			blank_surf: -1,
			noise_spr: -1,
			spark_spr: -1,
			grain_spr: -1,
			touch_spr: -1,
			tex_held: false,
			skipped: false,
			surf_w: 0,
			surf_h: 0,
			fine: false,
			bw: 1,
			bh: 1,
			ew: 1,
			eh: 1,
			sw: 1,
			sh: 1,
			first_appear: 0,
			last_disappear: 0,
			tint_r: 1,
			tint_g: 0,
			tint_b: 0,
			tint_set: false,
			bucket_dt: 0.25,
			bucket_lists: undefined,
			bucket_ends: undefined,
			scan_sorted: false,
			scan_active: undefined,
			scan_active_n: 0,
			scan_cursor: 0,
			scan_now: -infinity,
			pack_tried: false,
			packed: false,
			pack_buf: -1,
			pack_order: undefined,
			pack_plain: true,
			pack_count: 0,
			pack_first: 0,
			pack_last: 0,
			pack_dt: 0.001,
			pack_complex: [],
			pack_phase: 0,
			pack_cursor: 0,
			pack_kept: 0,
			pack_max_appear: 0,
			pack_counts: undefined,
			pack_bucket_n: 0,
			block_n: 0,
			cover_active: official_block_cover_new(),
			cover_disabled: official_block_cover_new()
	};
}

///@desc 返回进程内唯一的噪声区状态
///@returns {Struct} 静态状态
function official_block_state() {
	static state = official_block_state_create();
	return state;
}

///@desc 创建一个空的手指悬停槽
///@returns {Struct} 悬停数据
function official_block_hover_new() {
	return { id: -1, x: 0, y: 0, scale: 0, from: 0, target: 0, elapsed: 0, moving: false };
}

///@desc 创建一个空的屏幕包围盒
///@returns {Struct} 包围盒
function official_block_cover_new() {
	return { minx: 0, miny: 0, maxx: 0, maxy: 0, any: false, bad: false };
}

///@desc 把包围盒重置成尚未包含任何点
///@param {Struct} _cover 包围盒
///@returns {Undefined} 无
function official_block_cover_clear(_cover) {
	_cover.minx = 100000000;
	_cover.miny = 100000000;
	_cover.maxx = -100000000;
	_cover.maxy = -100000000;
	_cover.any = false;
	_cover.bad = false;
}

///@desc 把一个屏幕点并进包围盒，非有限值标为不可裁剪
///@param {Struct} _cover 包围盒
///@param {Real} _x 屏幕横坐标
///@param {Real} _y 屏幕纵坐标
///@returns {Undefined} 无
function official_block_cover_add(_cover, _x, _y) {
	// 非有限坐标整框作废
	if (!is_finite(_x) || !is_finite(_y)) {
		_cover.bad = true;
		return;
	}
	_cover.minx = min(_cover.minx, _x);
	_cover.miny = min(_cover.miny, _y);
	_cover.maxx = max(_cover.maxx, _x);
	_cover.maxy = max(_cover.maxy, _y);
	_cover.any = true;
}

///@desc 释放噪声区表面与纹理，并把状态清回未加载
///@returns {Undefined} 无
function official_blocks_reset() {
	var state = official_block_state();
	official_block_free_rt(state);
	if (surface_exists(state.white_surf)) surface_free(state.white_surf);
	if (surface_exists(state.blank_surf)) surface_free(state.blank_surf);
	state.white_surf = -1;
	state.blank_surf = -1;
	state.cleared = false;
	official_block_textures_release();
	official_block_clear_sprites(state);
	state.tex_held = false;
	state.skipped = false;
	var hovers = state.hovers;
	// 悬停槽逐个归零
	for (var i = 0; i < array_length(hovers); i++) {
		var hover = hovers[i];
		hover.id = -1;
		hover.x = 0;
		hover.y = 0;
		hover.scale = 0;
		hover.from = 0;
		hover.target = 0;
		hover.elapsed = 0;
		hover.moving = false;
	}
	state.blocks = [];
	state.blocked_ids = [];
	state.touch_world = [];
	state.hover_live = false;
	state.need_gpu = false;
	state.ready = false;
	state.empty = true;
	state.loaded_enabled = false;
	state.preloaded = false;
	state.gpu_warm = false;
	state.warned = false;
	state.first_appear = 0;
	state.last_disappear = 0;
	state.tint_r = 1;
	state.tint_g = 0;
	state.tint_b = 0;
	state.tint_set = false;
	state.bucket_lists = undefined;
	state.bucket_ends = undefined;
	state.scan_sorted = false;
	state.scan_active = undefined;
	state.scan_active_n = 0;
	state.scan_cursor = 0;
	state.scan_now = -infinity;
	official_block_pack_free(state);
	shader_reset();
}

///@desc 丢掉状态里的噪声贴图引用
///@param {Struct} _state 噪声区状态
///@returns {Undefined} 无
function official_block_clear_sprites(_state) {
	_state.noise_spr = -1;
	_state.spark_spr = -1;
	_state.grain_spr = -1;
	_state.touch_spr = -1;
}

///@desc 释放全部渲染目标并清掉尺寸记录
///@param {Struct} _state 噪声区状态
///@returns {Undefined} 无
function official_block_free_rt(_state) {
	var rt = _state.rt;
	// 存在的表面才释放
	for (var i = 0; i < array_length(rt); i++) {
		if (surface_exists(rt[i])) surface_free(rt[i]);
		rt[i] = -1;
	}
	_state.surf_w = 0;
	_state.surf_h = 0;
}

///@desc 判断谱面是否正在结束、结算或退出
///@returns {Bool} 是则为真
function official_blocks_ending() {
	// 播放结束、结算或已经开始退出都算
	if (chart_play_ending()) return true;
	if (instance_exists(oSettlement)) return true;
	if (variable_instance_exists(id, "chart_exit_started") && chart_exit_started) return true;
	return false;
}

///@desc 按缓动类型计算未量化的进度
///@param {Real} _type 缓动编号
///@param {Real} _t 0 到 1 的进度
///@returns {Real} 缓动后的进度
function official_block_ease_raw(_type, _t) {
	var progress = clamp(_t, 0, 1);
	var remain = 1 - progress;
	var turned = -2 * progress + 2;
	// 1 到 14 为正弦、多项式和阶跃，其余保持线性
	if (_type == 1) return 1 - cos(progress * pi * 0.5);
	if (_type == 2) return sin(progress * pi * 0.5);
	if (_type == 3) return (1 - cos(pi * progress)) * 0.5;
	if (_type == 4) return progress * progress;
	if (_type == 5) return 1 - remain * remain;
	if (_type == 6) return (progress < 0.5) ? (2 * progress * progress) : (1 - turned * turned * 0.5);
	if (_type == 7) return progress * progress * progress;
	if (_type == 8) return 1 - remain * remain * remain;
	if (_type == 9) return (progress < 0.5) ? (4 * progress * progress * progress) : (1 - turned * turned * turned * 0.5);
	if (_type == 10) return progress * progress * progress * progress;
	if (_type == 11) return 1 - remain * remain * remain * remain;
	if (_type == 12) return (progress < 0.5) ? (8 * progress * progress * progress * progress) : (1 - turned * turned * turned * turned * 0.5);
	if (_type == 13) return 0;
	if (_type == 14) return 1;
	return progress;
}

///@desc 把进度量化到百分之一后再在相邻采样间插值
///@param {Real} _type 缓动编号
///@param {Real} _t 0 到 1 的进度
///@returns {Real} 插值后的进度
function official_block_ease(_type, _t) {
	var p = clamp(_t, 0, 1) * 100;
	var step = floor(p);
	var sample = official_block_ease_raw(_type, step / 100);
	var next_step = min(step + 1, 100);
	return sample + (official_block_ease_raw(_type, next_step / 100) - sample) * (p - step);
}

///@desc 计算时刻在两个关键帧之间的比例
///@param {Real} _t 当前时刻
///@param {Real} _a 起点时刻
///@param {Real} _b 终点时刻
///@returns {Real} 0 到 1，终点不晚于起点时为 1
function official_block_ratio(_t, _a, _b) {
	// 时间区间无效时视为已经走完
	if (_b <= _a) return 1;
	return clamp((_t - _a) / (_b - _a), 0, 1);
}

///@desc 做除法，除数为 0 时返回 1
///@param {Real} _numerator 分子
///@param {Real} _denominator 分母
///@returns {Real} 商，或 1
function official_block_safe_div(_numerator, _denominator) {
	// 除数为 0 时不缩放
	if (_denominator == 0) return 1;
	return _numerator / _denominator;
}

///@desc 把 0 到 1 的百分比坐标换成以中心为原点的世界坐标
///@param {Real} _x 横向百分比
///@param {Real} _y 纵向百分比
///@param {Real} _aspect 宽高比
///@returns {Array} 世界横坐标和纵坐标
function official_block_world(_x, _y, _aspect) {
	return [(_x - 0.5) * 10 * _aspect, (_y - 0.5) * 10];
}

///@desc 把二维向量按弧度旋转
///@param {Real} _x 横坐标
///@param {Real} _y 纵坐标
///@param {Real} _radians 弧度
///@returns {Array} 旋转后的横坐标和纵坐标
function official_block_rotate_vec(_x, _y, _radians) {
	var cosine = cos(_radians);
	var sine = sin(_radians);
	return [cosine * _x - sine * _y, sine * _x + cosine * _y];
}

///@desc 按时间再按文件顺序比较关键帧，供 array_sort 使用
///@param {Struct} _a 关键帧
///@param {Struct} _b 关键帧
///@returns {Real} 小于、等于、大于分别为 -1、0、1
function official_block_sort_time(_a, _b) {
	// array_sort 会把比较结果截成整数，不足一秒的时间差会变成 0，关键帧就会乱序。
	// 时间相等必须保持文件顺序。Phira 的排序是稳定的，同一时刻先 0 再 75 度时必须停在 75。
	if (_a.t != _b.t) return sign(_a.t - _b.t);
	return sign(_a.ord - _b.ord);
}

///@desc 读取 moveEvents 并按时间排序
///@param {Struct} _area 一个 block 区域
///@returns {Array} 位移关键帧
function official_block_read_move(_area) {
	var source = _area[$ "moveEvents"];
	var events = [];
	if (!is_array(source)) return events;
	var count = array_length(source);
	for (var i = 0; i < count; i++) {
		var item = source[i];
		// 缺结构、时间或坐标非有限则跳过
		if (!is_struct(item)) continue;
		var end_position = item[$ "endPosition"];
		var pos_x = 0;
		var pos_y = 0;
		if (is_struct(end_position)) {
			pos_x = real(end_position[$ "x"] ?? 0);
			pos_y = real(end_position[$ "y"] ?? 0);
		}
		if (!is_finite(real(item[$ "time"] ?? 0)) || !is_finite(pos_x) || !is_finite(pos_y)) continue;
		array_add(events, {
			t: real(item[$ "time"] ?? 0),
			x: pos_x,
			y: pos_y,
			ex: floor(real(item[$ "easeTypeX"] ?? 0)),
			ey: floor(real(item[$ "easeTypeY"] ?? 0)),
			ord: array_length(events)
		});
	}
	// 多于一条才排序
	if (array_length(events) > 1) array_sort(events, official_block_sort_time);
	return events;
}

///@desc 读取 scaleEvents 并按时间排序
///@param {Struct} _area 一个 block 区域
///@returns {Array} 缩放关键帧
function official_block_read_scale(_area) {
	var source = _area[$ "scaleEvents"];
	var events = [];
	if (!is_array(source)) return events;
	var count = array_length(source);
	for (var i = 0; i < count; i++) {
		var item = source[i];
		if (!is_struct(item)) continue;
		var anchor = item[$ "anchor"];
		var scale = item[$ "scale"];
		var anchor_x = 0;
		var anchor_y = 0;
		var scale_x = 0;
		var scale_y = 0;
		if (is_struct(anchor)) {
			anchor_x = real(anchor[$ "x"] ?? 0);
			anchor_y = real(anchor[$ "y"] ?? 0);
		}
		if (is_struct(scale)) {
			scale_x = real(scale[$ "x"] ?? 0);
			scale_y = real(scale[$ "y"] ?? 0);
		}
		// 时间或缩放非有限则跳过
		if (!is_finite(real(item[$ "time"] ?? 0)) || !is_finite(scale_x) || !is_finite(scale_y)) continue;
		array_add(events, {
			t: real(item[$ "time"] ?? 0),
			x: scale_x,
			y: scale_y,
			ax: anchor_x,
			ay: anchor_y,
			ex: floor(real(item[$ "easeTypeX"] ?? 0)),
			ey: floor(real(item[$ "easeTypeY"] ?? 0)),
			ord: array_length(events)
		});
	}
	if (array_length(events) > 1) array_sort(events, official_block_sort_time);
	return events;
}

///@desc 读取 rotateEvents 并按时间排序
///@param {Struct} _area 一个 block 区域
///@returns {Array} 旋转关键帧
function official_block_read_rotate(_area) {
	var source = _area[$ "rotateEvents"];
	var events = [];
	if (!is_array(source)) return events;
	var count = array_length(source);
	for (var i = 0; i < count; i++) {
		var item = source[i];
		if (!is_struct(item)) continue;
		var anchor = item[$ "anchor"];
		var anchor_x = 0;
		var anchor_y = 0;
		if (is_struct(anchor)) {
			anchor_x = real(anchor[$ "x"] ?? 0);
			anchor_y = real(anchor[$ "y"] ?? 0);
		}
		var rotation = real(item[$ "rotation"] ?? 0);
		// 时间或角度非有限则跳过
		if (!is_finite(real(item[$ "time"] ?? 0)) || !is_finite(rotation)) continue;
		array_add(events, {
			t: real(item[$ "time"] ?? 0),
			r: rotation,
			ax: anchor_x,
			ay: anchor_y,
			ease: floor(real(item[$ "easeType"] ?? 0)),
			ord: array_length(events)
		});
	}
	if (array_length(events) > 1) array_sort(events, official_block_sort_time);
	return events;
}

///@desc 把十六进制文本转成整数，遇到非法字符返回 -1
///@param {String} _text 十六进制文本
///@returns {Real} 数值，非法为 -1
function official_block_hex_value(_text) {
	var len = string_length(_text);
	var value = 0;
	for (var i = 1; i <= len; i++) {
		var c = ord(string_char_at(_text, i));
		var n = -1;
		// 支持 0-9 与大小写 A-F，非法立即失败
		if (c >= 48 && c <= 57) n = c - 48;
		else if (c >= 65 && c <= 70) n = c - 55;
		else if (c >= 97 && c <= 102) n = c - 87;
		if (n < 0) return -1;
		value = value * 16 + n;
	}
	return value;
}

///@desc 把三个颜色通道收成 0 到 1，大于 1 时先除以 255
///@param {Any} _r 红
///@param {Any} _g 绿
///@param {Any} _b 蓝
///@returns {Any} 长度为 3 的数组，无法解析则为未定义
function official_block_unit_trio(_r, _g, _b) {
	if (is_string(_r)) _r = real(_r);
	if (is_string(_g)) _g = real(_g);
	if (is_string(_b)) _b = real(_b);
	if (!is_real(_r) || !is_real(_g) || !is_real(_b)) return undefined;
	if (!is_finite(_r) || !is_finite(_g) || !is_finite(_b)) return undefined;
	// 任一通道大于 1 则视为 0 到 255
	if (_r > 1 || _g > 1 || _b > 1) {
		_r /= 255;
		_g /= 255;
		_b /= 255;
	}
	return [clamp(_r, 0, 1), clamp(_g, 0, 1), clamp(_b, 0, 1)];
}

///@desc 读取区域颜色；缺失或无法解析时用红色，这样没有该字段的官谱会保持当前材质
///@param {Struct} _area 一个 block 区域
///@returns {Array} 0 到 1 的红绿蓝
function official_block_read_color(_area) {
	var color = _area[$ "color"];
	if (is_undefined(color)) color = _area[$ "colour"];
	if (is_string(color)) {
		var text = string_replace_all(color, " ", "");
		var lower = string_lower(text);
		// 依次尝试 rgb()、短十六进制、长十六进制，后面还有数组和结构
		if (string_length(lower) >= 4 && string_copy(lower, 1, 4) == "rgb(") {
			var body = string_copy(text, 5, string_length(text) - 5);
			body = string_replace_all(body, ")", "");
			var parts = string_split(body, ",");
			if (array_length(parts) >= 3) {
				var rgb_text = official_block_unit_trio(parts[0], parts[1], parts[2]);
				if (is_array(rgb_text)) return rgb_text;
			}
		}
		if (string_length(text) > 0 && string_char_at(text, 1) == "#") text = string_copy(text, 2, string_length(text) - 1);
		var len = string_length(text);
		if (len == 3 || len == 4) {
			var rs = official_block_hex_value(string_char_at(text, 1));
			var gs = official_block_hex_value(string_char_at(text, 2));
			var bs = official_block_hex_value(string_char_at(text, 3));
			if (rs >= 0 && gs >= 0 && bs >= 0) return [rs / 15, gs / 15, bs / 15];
		} else if (len == 6 || len == 8) {
			var rb = official_block_hex_value(string_copy(text, 1, 2));
			var gb = official_block_hex_value(string_copy(text, 3, 2));
			var bb = official_block_hex_value(string_copy(text, 5, 2));
			if (rb >= 0 && gb >= 0 && bb >= 0) return [rb / 255, gb / 255, bb / 255];
		}
		return [1, 0, 0];
	}
	if (is_array(color) && array_length(color) >= 3) {
		var rgb_array = official_block_unit_trio(color[0], color[1], color[2]);
		if (is_array(rgb_array)) return rgb_array;
		return [1, 0, 0];
	}
	if (is_struct(color)) {
		var cr = color[$ "r"];
		var cg = color[$ "g"];
		var cb = color[$ "b"];
		if (is_undefined(cr)) cr = color[$ "x"];
		if (is_undefined(cg)) cg = color[$ "y"];
		if (is_undefined(cb)) cb = color[$ "z"];
		var rgb_struct = official_block_unit_trio(cr, cg, cb);
		if (is_array(rgb_struct)) return rgb_struct;
	}
	return [1, 0, 0];
}

///@desc 按内置材质的红色加白色抬升重着色，纯红因此保持不变
///@param {Real} _r 原红
///@param {Real} _g 原绿
///@param {Real} _b 原蓝
///@param {Real} _cr 目标红
///@param {Real} _cg 目标绿
///@param {Real} _cb 目标蓝
///@returns {Array} 重着色后的红绿蓝
function official_block_shift_color(_r, _g, _b, _cr, _cg, _cb) {
	// 绿色和蓝色的较小值当作白色抬升
	var white = min(_g, _b);
	var pure = _r - white;
	return [_cr * pure + white, _cg * pure + white, _cb * pure + white];
}

///@desc 释放大噪域的紧凑缓冲
///@param {Struct} _state 噪声区状态
///@returns {Undefined} 无
function official_block_pack_free(_state) {
	if (is_real(_state.pack_buf) && buffer_exists(_state.pack_buf)) buffer_delete(_state.pack_buf);
	if (is_real(_state.pack_order) && buffer_exists(_state.pack_order)) buffer_delete(_state.pack_order);
	_state.pack_buf = -1;
	_state.pack_order = undefined;
	_state.pack_plain = true;
	_state.pack_count = 0;
	_state.packed = false;
	_state.pack_tried = false;
	_state.pack_complex = [];
	_state.pack_phase = 0;
	_state.pack_cursor = 0;
	_state.pack_kept = 0;
	_state.pack_max_appear = 0;
	_state.pack_counts = undefined;
	_state.pack_bucket_n = 0;
	_state.block_n = 0;
	_state.pack_first = 0;
	_state.pack_last = 0;
}

///@desc 没有位移、缩放、旋转的空事件表，所有简单方块共用
///@returns {Array} 空数组
function official_block_empty_events() {
	static empty = [];
	return empty;
}

///@desc 造一个可反复写入的简单方块壳
///@returns {Struct} 方块
function official_block_shell() {
	var empty = official_block_empty_events();
	return {
		subtract: false,
		appear: 0,
		enable: 0,
		disable: 0,
		disappear: 0,
		cr: 1,
		cg: 0,
		cb: 0,
		ord: 0,
		x0: 0,
		y0: 0,
		x1: 0,
		y1: 0,
		move: empty,
		scale: empty,
		rotate: empty,
		on: false,
		phase: 2,
		fade: 1,
		cx: 0,
		cy: 0,
		sx: 1,
		sy: 1,
		ang: 0,
		corners: [0, 0, 0, 0, 0, 0, 0, 0]
	};
}

///@desc 按需要扩容本帧方块池并返回其中一格
///@param {Struct} _state 噪声区状态
///@param {Real} _index 下标
///@returns {Struct} 方块壳
function official_block_pool_at(_state, _index) {
	var pool = _state.blocks;
	var have = array_length(pool);
	if (_index >= have) {
		var grow = max(_index + 1, max(32, have * 2));
		repeat (grow - have) array_push(pool, official_block_shell());
	}
	return pool[_index];
}

///@desc 把紧凑记录写进方块壳。没有动画，事件表保持空。
///@param {Struct} _block 方块壳
///@param {Real} _buf 缓冲
///@param {Real} _base 字节偏移
///@returns {Undefined} 无
function official_block_unpack(_block, _buf, _base) {
	_block.x0 = buffer_peek(_buf, _base, buffer_f32);
	_block.y0 = buffer_peek(_buf, _base + 4, buffer_f32);
	_block.x1 = buffer_peek(_buf, _base + 8, buffer_f32);
	_block.y1 = buffer_peek(_buf, _base + 12, buffer_f32);
	_block.appear = buffer_peek(_buf, _base + 16, buffer_f32);
	_block.enable = buffer_peek(_buf, _base + 20, buffer_f32);
	_block.disable = buffer_peek(_buf, _base + 24, buffer_f32);
	_block.disappear = buffer_peek(_buf, _base + 28, buffer_f32);
	_block.cr = buffer_peek(_buf, _base + 32, buffer_f32);
	_block.cg = buffer_peek(_buf, _base + 36, buffer_f32);
	_block.cb = buffer_peek(_buf, _base + 40, buffer_f32);
	_block.subtract = buffer_peek(_buf, _base + 44, buffer_f32) > 0.5;
	_block.on = false;
}

///@desc 本帧要遍历的方块数。大谱只算当前还活着的那些。
///@param {Struct} _state 噪声区状态
///@returns {Real} 数量
function official_block_iter_count(_state) {
	return max(0, _state.block_n);
}

///@desc 分帧把超大噪域收成缓冲。本帧没做完返回假，调用方要下帧再来。
///@param {Struct} _chart 谱面
///@returns {Bool} 已经结束（含不需要压缩）时为真
function official_blocks_pack_large(_chart) {
	var state = official_block_state();
	if (state.packed || state.pack_phase == 4) return true;
	var source = _chart[$ "blockAreaList"];
	if (!is_array(source)) source = _chart[$ "block_area_list"];
	if (!is_array(source)) source = _chart[$ "block_area"];
	if (!is_array(source)) {
		state.packed = true;
		state.pack_phase = 4;
		state.pack_count = 0;
		state.pack_complex = [];
		return true;
	}
	var count = array_length(source);
	var stride = OFFICIAL_BLOCK_PACK;
	if (state.pack_phase == 0) {
		var created = buffer_create(max(1, count * stride), buffer_fixed, 1);
		if (!buffer_exists(created)) {
			struct_remove(_chart, "blockAreaList");
			struct_remove(_chart, "block_area_list");
			struct_remove(_chart, "block_area");
			state.packed = true;
			state.pack_phase = 4;
			state.pack_count = 0;
			gc_collect();
			return true;
		}
		state.pack_buf = created;
		state.pack_complex = [];
		state.pack_cursor = 0;
		state.pack_kept = 0;
		state.pack_first = infinity;
		state.pack_last = -infinity;
		state.pack_max_appear = 0;
		state.pack_plain = true;
		if (is_struct(source[0])) {
			var sample = source[0];
			state.pack_plain = !(is_array(sample[$ "moveEvents"]) || is_array(sample[$ "scaleEvents"]) || is_array(sample[$ "rotateEvents"]));
		}
		state.pack_phase = 1;
	}
	var buf = state.pack_buf;
	var complex = state.pack_complex;
	var kept = state.pack_kept;
	var first_t = state.pack_first;
	var last_t = state.pack_last;
	var max_appear = state.pack_max_appear;
	if (state.pack_phase == 1) {
	// 固定批量，避免 4 毫秒预算把百万块拖过整首歌
	var fill_end = min(count, state.pack_cursor + 8000);
	var plain = state.pack_plain;
	for (var i = state.pack_cursor; i < fill_end; i++) {
		var area = source[i];
		if (!is_struct(area)) continue;
		var bottom_left = area[$ "bottomLeftPercentage"];
		var top_right = area[$ "topRightPercentage"];
		if (!is_struct(bottom_left) || !is_struct(top_right)) continue;
		var left_x = real(bottom_left[$ "x"] ?? 0);
		var left_y = real(bottom_left[$ "y"] ?? 0);
		var right_x = real(top_right[$ "x"] ?? 0);
		var right_y = real(top_right[$ "y"] ?? 0);
		var appear = real(area[$ "appearTime"] ?? 0);
		var enable = real(area[$ "enableTime"] ?? 0);
		var disable = real(area[$ "disableTime"] ?? 0);
		var disappear = real(area[$ "disappearTime"] ?? 0);
		if (!is_finite(left_x) || !is_finite(left_y) || !is_finite(right_x) || !is_finite(right_y)) continue;
		if (!is_finite(appear) || !is_finite(enable) || !is_finite(disable) || !is_finite(disappear)) continue;
		enable = max(enable, appear);
		disable = max(disable, enable);
		disappear = max(disappear, disable);
		var animated = false;
		if (!plain) {
			var move = area[$ "moveEvents"];
			var scale = area[$ "scaleEvents"];
			var rotate = area[$ "rotateEvents"];
			animated = (is_array(move) && array_length(move) > 0)
				|| (is_array(scale) && array_length(scale) > 0)
				|| (is_array(rotate) && array_length(rotate) > 0);
		}
		if (animated) {
			var rgb_complex = official_block_read_color(area);
			array_push(complex, {
				subtract: bool(area[$ "isSubtract"] ?? false),
				appear: appear,
				enable: enable,
				disable: disable,
				disappear: disappear,
				cr: rgb_complex[0],
				cg: rgb_complex[1],
				cb: rgb_complex[2],
				ord: array_length(complex),
				x0: left_x,
				y0: left_y,
				x1: right_x,
				y1: right_y,
				move: official_block_read_move(area),
				scale: official_block_read_scale(area),
				rotate: official_block_read_rotate(area),
				on: false,
				phase: 2,
				fade: 1,
				cx: 0,
				cy: 0,
				sx: 1,
				sy: 1,
				ang: 0,
				corners: [0, 0, 0, 0, 0, 0, 0, 0]
			});
		} else {
			var cr = 1;
			var cg = 0;
			var cb = 0;
			var color = area[$ "color"];
			if (is_undefined(color)) color = area[$ "colour"];
			// 这批栅格几乎都是纯红，跳过逐块解析
			if (!is_undefined(color) && color != "#FF0000" && color != "#ff0000") {
				var rgb = official_block_read_color(area);
				cr = rgb[0];
				cg = rgb[1];
				cb = rgb[2];
			}
			var at = kept * stride;
			buffer_seek(buf, buffer_seek_start, at);
			buffer_write(buf, buffer_f32, left_x);
			buffer_write(buf, buffer_f32, left_y);
			buffer_write(buf, buffer_f32, right_x);
			buffer_write(buf, buffer_f32, right_y);
			buffer_write(buf, buffer_f32, appear);
			buffer_write(buf, buffer_f32, enable);
			buffer_write(buf, buffer_f32, disable);
			buffer_write(buf, buffer_f32, disappear);
			buffer_write(buf, buffer_f32, cr);
			buffer_write(buf, buffer_f32, cg);
			buffer_write(buf, buffer_f32, cb);
			var subtract = bool(area[$ "isSubtract"] ?? false);
			buffer_write(buf, buffer_f32, subtract ? 1 : 0);
			kept++;
		}
		first_t = min(first_t, appear);
		last_t = max(last_t, disappear);
		max_appear = max(max_appear, appear);
	}
	state.pack_cursor = fill_end;
	state.pack_kept = kept;
	state.pack_first = first_t;
	state.pack_last = last_t;
	state.pack_max_appear = max_appear;
	if (fill_end < count) return false;
	state.pack_kept = kept;
	state.pack_first = first_t;
	state.pack_last = last_t;
	state.pack_max_appear = max_appear;
	state.pack_phase = 2;
	state.pack_cursor = 0;
	}
	kept = state.pack_kept;
	max_appear = state.pack_max_appear;
	buf = state.pack_buf;
	// 按出现时间分桶，避免对百万结构做脚本排序
	var buckets = 100000;
	var dt = max(0.0005, max_appear / buckets);
	var bucket_n = floor(max_appear / dt) + 2;
	if (bucket_n < 2) bucket_n = 2;
	if (bucket_n > buckets + 2) bucket_n = buckets + 2;
	if (state.pack_phase == 2) {
		state.pack_dt = dt;
		state.pack_bucket_n = bucket_n;
		state.pack_counts = array_create(bucket_n, 0);
		state.pack_phase = 3;
		state.pack_cursor = 0;
	}
	var counts = state.pack_counts;
	bucket_n = state.pack_bucket_n;
	dt = state.pack_dt;
	if (state.pack_phase == 3) {
	var count_end = min(kept, state.pack_cursor + 40000);
	for (var ci = state.pack_cursor; ci < count_end; ci++) {
		var appear_i = buffer_peek(buf, ci * stride + 16, buffer_f32);
		var bucket = floor(appear_i / dt);
		if (bucket < 0) bucket = 0;
		if (bucket >= bucket_n) bucket = bucket_n - 1;
		counts[bucket] += 1;
	}
	state.pack_cursor = count_end;
	if (count_end < kept) return false;
	var cursor_sum = 0;
	for (var bi = 0; bi < bucket_n; bi++) {
		var bucket_count = counts[bi];
		counts[bi] = cursor_sum;
		cursor_sum += bucket_count;
	}
	state.pack_order = array_create(max(1, kept), 0);
	state.pack_phase = 5;
	state.pack_cursor = 0;
	}
	var order = state.pack_order;
	counts = state.pack_counts;
	bucket_n = state.pack_bucket_n;
	dt = state.pack_dt;
	buf = state.pack_buf;
	kept = state.pack_kept;
	var place_end = min(kept, state.pack_cursor + 40000);
	for (var oi = state.pack_cursor; oi < place_end; oi++) {
		var appear_o = buffer_peek(buf, oi * stride + 16, buffer_f32);
		var place_bucket = floor(appear_o / dt);
		if (place_bucket < 0) place_bucket = 0;
		if (place_bucket >= bucket_n) place_bucket = bucket_n - 1;
		var place = counts[place_bucket];
		counts[place_bucket] = place + 1;
		order[place] = oi;
	}
	state.pack_cursor = place_end;
	if (place_end < kept) return false;
	state.pack_buf = buf;
	state.pack_order = order;
	state.pack_count = kept;
	state.pack_dt = dt;
	state.pack_complex = complex;
	state.packed = true;
	state.pack_first = is_finite(first_t) ? first_t : 0;
	state.pack_last = is_finite(last_t) ? last_t : 0;
	state.block_n = 0;
	state.blocks = [];
	state.scan_cursor = 0;
	state.scan_active_n = 0;
	state.scan_now = -infinity;
	state.scan_active = [];
	// 原数组留在谱面上会一直占着那几百万个结构
	struct_remove(_chart, "blockAreaList");
	struct_remove(_chart, "block_area_list");
	struct_remove(_chart, "block_area");
	source = undefined;
	state.pack_counts = undefined;
	state.pack_phase = 4;
	gc_collect();
	return true;
}

///@desc 大噪域还没收完。普通谱或已经收完时为假
///@returns {Bool} 还要等时为真
function official_block_pack_pending() {
	var state = official_block_state();
	if (state.packed || state.pack_phase == 4) return false;
	if (state.pack_phase == 1 || state.pack_phase == 2 || state.pack_phase == 3 || state.pack_phase == 5) return true;
	if (state.pack_tried) return false;
	if (!variable_global_exists("game") || !is_struct(game) || !is_struct(game[$ "chart"])) return false;
	var source = game.chart[$ "blockAreaList"];
	if (!is_array(source)) source = game.chart[$ "block_area_list"];
	if (!is_array(source)) source = game.chart[$ "block_area"];
	return is_array(source) && array_length(source) > 0;
}

///@desc 判定线和噪域都就绪后，才允许加载界面播放离场动画
///@returns {Undefined} 无
function official_block_notify_load_ready() {
	if (official_block_pack_pending()) return;
	if (variable_global_exists("loading_render_ready") && global.loading_render_ready) return;
	if (instance_exists(oRender)
		&& variable_instance_exists(oRender, "_chart_lines_building")
		&& oRender._chart_lines_building) return;
	global.loading_render_ready = true;
	chart_blur_bind_game(false);
	if (pls_is_gxgames()) then chart_loading_animation_finish();
}

///@desc 趁加载界面还停着，继续收一批噪域
///@returns {Undefined} 无
function official_blocks_pack_pump() {
	var state = official_block_state();
	if (state.packed || state.pack_phase == 4 || state.pack_tried) return;
	if (!variable_global_exists("game") || !is_struct(game) || !is_struct(game[$ "chart"])) return;
	if (!official_blocks_pack_large(game.chart)) return;
	state.pack_tried = true;
	official_block_notify_load_ready();
}

///@desc 读取设置里是否启用噪声区
///@returns {Bool} 未写设置时默认为真
function official_block_enabled() {
	// 没有设置时默认开启
	if (!variable_global_exists("game") || !is_struct(game) || !is_struct(game.settings)) return true;
	return bool(game.settings[$ "enableNoiseArea"] ?? true);
}

///@desc 读取设置里是否使用精细噪声区
///@returns {Bool} 未写设置时为假
function official_block_fine() {
	// 没有设置时默认不用精细模式
	if (!variable_global_exists("game") || !is_struct(game) || !is_struct(game.settings)) return false;
	return bool(game.settings[$ "enableNoiseAreaFine"] ?? false);
}

///@desc 边缘波动倍率：1 保留原幅度，减弱时约为两轴的六分之一，内部像素扭曲不变
///@returns {Real} 1 或 0.15
function official_block_edge_wave() {
	// 没有设置时保持原幅度
	if (!variable_global_exists("game") || !is_struct(game) || !is_struct(game.settings)) return 1;
	return bool(game.settings[$ "reduceNoiseAreaWave"] ?? false) ? 0.15 : 1;
}

///@desc 卸载 BlockAreaGroup，组不存在时直接返回
///@returns {Undefined} 无
function official_block_textures_release() {
	if (!texturegroup_exists("BlockAreaGroup")) return;
	try {
		var status = texturegroup_get_status("BlockAreaGroup");
		if (status != texturegroup_status_unloaded) texturegroup_unload("BlockAreaGroup");
	// 卸载失败不影响后续播放
	} catch (release_err) {
		delete release_err;
	}
}

///@desc 判断噪声区要用的四张精灵资源是否都存在
///@returns {Bool} 都存在时为真
function official_block_sprites_present() {
	return sprite_exists(block_texture_15)
		&& sprite_exists(block_texture_17)
		&& sprite_exists(block_texture_30)
		&& sprite_exists(block_touch);
}

///@desc 判断四张噪声贴图的纹理是否已经可采样
///@returns {Bool} 都就绪时为真
function official_block_sprites_ready() {
	var sprites = [block_texture_15, block_texture_17, block_texture_30, block_touch];
	for (var i = 0; i < 4; i++) {
		var tex = sprite_get_texture(sprites[i], 0);
		// 任一张纹理未就绪则整组不算好
		if (is_undefined(tex) || (is_real(tex) && tex < 0)) return false;
		if (!texture_is_ready(tex)) return false;
	}
	return true;
}

///@desc 准备 BlockAreaGroup，返回 ready、pending 或 missing；缺组不能打断谱面播放
///@param {Struct} _state 噪声区状态
///@returns {String} ready、pending 或 missing
function official_block_textures_prepare(_state) {
	if (!texturegroup_exists("BlockAreaGroup") || !official_block_sprites_present()) return "missing";
	try {
		var status = texturegroup_get_status("BlockAreaGroup");
		// 未加载则异步拉取，仍在加载就继续等
		if (status == texturegroup_status_unloaded) {
			if (!_state.tex_held) {
				texturegroup_load("BlockAreaGroup", true);
				_state.tex_held = true;
				status = texturegroup_get_status("BlockAreaGroup");
			}
			if (status == texturegroup_status_loading || status == texturegroup_status_unloaded) return "pending";
		}
		if (status == texturegroup_status_loading) return "pending";
		if (status != texturegroup_status_loaded && status != texturegroup_status_fetched) return "missing";
		_state.tex_held = true;
		// 组已在内存但精灵未就绪时预取
		if (!official_block_sprites_ready()) {
			texture_prefetch("BlockAreaGroup");
			return "pending";
		}
		return "ready";
	} catch (prepare_err) {
		delete prepare_err;
		return "missing";
	}
}

///@desc 贴图缺失时跳过噪声区，并记一条日志
///@param {Struct} _state 噪声区状态
///@returns {Undefined} 无
function official_block_skip(_state) {
	// 只在第一次跳过时打印
	if (!_state.skipped) print("[R-Chart] BlockAreaGroup missing, noise areas skipped");
	if (_state.tex_held) official_block_textures_release();
	official_block_clear_sprites(_state);
	_state.blocks = [];
	_state.block_n = 0;
	_state.blocked_ids = [];
	_state.touch_world = [];
	_state.empty = true;
	_state.ready = true;
	_state.loaded_enabled = false;
	_state.need_gpu = false;
	_state.hover_live = false;
	_state.tex_held = false;
	_state.skipped = true;
	_state.preloaded = true;
}

///@desc 设置关闭噪声区时卸掉贴图并标成空
///@param {Struct} _state 噪声区状态
///@returns {Undefined} 无
function official_block_disable(_state) {
	// 贴图还拿着就先卸载
	if (_state.tex_held) official_block_textures_release();
	official_block_clear_sprites(_state);
	_state.blocks = [];
	_state.block_n = 0;
	_state.blocked_ids = [];
	_state.touch_world = [];
	_state.empty = true;
	_state.ready = true;
	_state.loaded_enabled = false;
	_state.need_gpu = false;
	_state.hover_live = false;
	_state.tex_held = false;
	_state.skipped = false;
	_state.preloaded = false;
}

///@desc 按设置加载噪声区、编译着色器，并返回状态
///@returns {Struct} 噪声区状态
function official_blocks_ensure() {
	var state = official_block_state();
	// 关闭、已跳过或已预载则直接返回
	if (!official_block_enabled()) {
		official_block_disable(state);
		return state;
	}
	// 贴图还没好也先把超大列表收掉，避免加载画面结束后才开始扩内存
	if (!state.pack_tried && variable_global_exists("game") && is_struct(game) && is_struct(game[$ "chart"])) {
		if (!official_blocks_pack_large(game.chart)) return state;
		state.pack_tried = true;
	}
	if (state.skipped) return state;
	if (state.ready && state.preloaded) return state;
	if (!texturegroup_exists("BlockAreaGroup") || !official_block_sprites_present()) {
		official_block_skip(state);
		return state;
	}
	var phase = official_block_textures_prepare(state);
	if (phase == "missing") {
		official_block_skip(state);
		return state;
	}
	// 贴图未就绪时先不建方块
	if (phase != "ready") return state;
	if (!state.loaded_enabled) {
		if (!variable_global_exists("game") || !is_struct(game) || !is_struct(game[$ "chart"])) return state;
		if (!state.pack_tried) {
			if (!official_blocks_pack_large(game.chart)) return state;
			state.pack_tried = true;
		}
		state.blocks = [];
		state.block_n = 0;
		state.empty = state.pack_count <= 0 && array_length(state.pack_complex) <= 0;
		state.first_appear = state.pack_first;
		state.last_disappear = state.pack_last;
		official_block_index(state);
		state.loaded_enabled = true;
		var count = state.pack_count;
		// 没有方块就卸贴图
		if (state.empty) {
			official_block_textures_release();
			official_block_clear_sprites(state);
			state.tex_held = false;
			state.ready = true;
			state.preloaded = true;
			return state;
		}
		state.noise_spr = block_texture_30;
		state.spark_spr = block_texture_17;
		state.grain_spr = block_texture_15;
		state.touch_spr = block_touch;
		if (is_struct(game[$ "settings"]) && bool(game.settings[$ "enableDebug"] ?? false)) {
			print($"[R-Chart] blockAreaList {count}");
		}
	}
	// 首次就绪时编译全部通道着色器
	if (!state.preloaded) {
		official_block_compile(shd_block_subtract);
		official_block_compile(shd_block_subtract_soft);
		official_block_compile(shd_block_compose);
		official_block_compile(shd_block_compose_plain);
		official_block_compile(shd_block_glow);
		official_block_compile(shd_block_disabled);
		official_block_compile(shd_block_active);
		official_block_compile(shd_block_active_ready);
		official_block_compile(shd_block_pack_mask);
		official_block_compile(shd_block_pack_effect);
		official_block_compile(shd_block_hover);
		official_block_refresh_ok(state);
		state.preloaded = true;
	}
	state.ready = true;
	return state;
}

///@desc 必要时编译着色器并返回是否成功
///@param {Real} _shader 着色器资源号
///@returns {Bool} 已编译时为真
function official_block_compile(_shader) {
	// 未编译时绑一次再复位，促使编译
	if (!shader_is_compiled(_shader)) {
		shader_set(_shader);
		shader_reset();
	}
	return shader_is_compiled(_shader);
}

///@desc 刷新各通道着色器是否可用，关键通道失败时警告一次
///@param {Struct} _state 噪声区状态
///@returns {Undefined} 无
function official_block_refresh_ok(_state) {
	_state.ok_subtract = shader_is_compiled(shd_block_subtract);
	_state.ok_subtract_soft = shader_is_compiled(shd_block_subtract_soft);
	_state.ok_compose = shader_is_compiled(shd_block_compose);
	_state.ok_compose_plain = shader_is_compiled(shd_block_compose_plain);
	_state.ok_glow = shader_is_compiled(shd_block_glow);
	_state.ok_disabled = shader_is_compiled(shd_block_disabled);
	_state.ok_active = shader_is_compiled(shd_block_active);
	_state.ok_ready = shader_is_compiled(shd_block_active_ready);
	_state.ok_pack_m = shader_is_compiled(shd_block_pack_mask);
	_state.ok_pack_e = shader_is_compiled(shd_block_pack_effect);
	_state.ok_hover = shader_is_compiled(shd_block_hover);
	// 激活、未启用或合成任一失败时只警告一次
	if (!_state.warned && (!_state.ok_active || !_state.ok_disabled || !_state.ok_compose)) {
		_state.warned = true;
		print($"[R-Chart] block shaders active={_state.ok_active} ready={_state.ok_ready} disabled={_state.ok_disabled} compose={_state.ok_compose}");
	}
}

///@desc 提前确保噪声区资源已加载
///@returns {Undefined} 无
function official_blocks_preload() {
	official_blocks_ensure();
}

///@desc 取谱面宽高比，缺失时用视口或 16:9
///@returns {Real} 宽高比
function official_block_aspect() {
	// 全局比优先，其次视口，最后 16:9
	if (variable_global_exists("chart_aspect_ratio") && is_real(chart_aspect_ratio) && is_finite(chart_aspect_ratio) && chart_aspect_ratio > 0.01) {
		return chart_aspect_ratio;
	}
	if (variable_global_exists("chart_view_width") && variable_global_exists("chart_view_height") && chart_view_height > 1) {
		return chart_view_width / chart_view_height;
	}
	return 16 / 9;
}

///@desc 判断谱面视口宽高和左边距是否可用
///@returns {Bool} 可用时为真
function official_block_view_ready() {
	return variable_global_exists("chart_view_width") && is_real(chart_view_width) && chart_view_width > 1
		&& variable_global_exists("chart_view_height") && is_real(chart_view_height) && chart_view_height > 1
		&& variable_global_exists("chart_view_left") && is_real(chart_view_left);
}

///@desc 把噪声区世界坐标换成房间像素
///@param {Real} _x 世界横坐标
///@param {Real} _y 世界纵坐标
///@param {Real} _aspect 宽高比
///@returns {Array} 房间横坐标和纵坐标
function official_block_world_to_room(_x, _y, _aspect) {
	var x_ndc = _x / (5 * _aspect);
	var y_chart = -_y / (5 * _aspect);
	var px = chart_view_left + (x_ndc + 1) * 0.5 * chart_view_width;
	var bottom = (1 - y_chart * _aspect) * 0.5;
	return [px, (1 - bottom) * chart_view_height];
}

///@desc 把房间像素换成噪声区世界坐标
///@param {Real} _x 房间横坐标
///@param {Real} _y 房间纵坐标
///@param {Real} _aspect 宽高比
///@returns {Array} 世界横坐标和纵坐标
function official_block_pixel_to_world(_x, _y, _aspect) {
	var px = (_x - chart_view_left) / chart_view_width;
	var py = 1 - (_y / chart_view_height);
	return [(px - 0.5) * 10 * _aspect, (py - 0.5) * 10];
}

///@desc 按缩放、旋转和位移关键帧算出当前位姿
///@param {Struct} _block 方块
///@param {Real} _now 当前谱面时间
///@param {Real} _aspect 宽高比
///@returns {Array} 中心、宽高和弧度
function official_block_pose(_block, _now, _aspect) {
	var lo = official_block_world(_block.x0, _block.y0, _aspect);
	var hi = official_block_world(_block.x1, _block.y1, _aspect);
	var base_x = (lo[0] + hi[0]) * 0.5;
	var base_y = (lo[1] + hi[1]) * 0.5;
	var cx = base_x;
	var cy = base_y;
	var sx = 1;
	var sy = 1;
	var scales = _block.scale;
	var scale_count = array_length(scales);
	// Phira 在第一个关键帧之前整段都保持该帧，缩放也一样。空列表保持 1。
	// 把第一帧清成 0 会藏住区域，并让后面的锚点链从错误尺寸开始。
	if (scale_count > 0) {
		sx = scales[0].x;
		sy = scales[0].y;
		for (var si = 0; si < scale_count; si++) {
			if (si + 1 >= scale_count) break;
			var scale_event = scales[si];
			var scale_next = scales[si + 1];
			var scale_done = _now >= scale_next.t;
			var scale_px = scale_done ? 1 : official_block_ease(scale_event.ex, official_block_ratio(_now, scale_event.t, scale_next.t));
			var scale_py = scale_done ? 1 : official_block_ease(scale_event.ey, official_block_ratio(_now, scale_event.t, scale_next.t));
			var vx = scale_event.x + (scale_next.x - scale_event.x) * scale_px;
			var vy = scale_event.y + (scale_next.y - scale_event.y) * scale_py;
			var scale_anchor = official_block_world(scale_event.ax, scale_event.ay, _aspect);
			cx = scale_anchor[0] + (cx - scale_anchor[0]) * official_block_safe_div(vx, scale_event.x);
			cy = scale_anchor[1] + (cy - scale_anchor[1]) * official_block_safe_div(vy, scale_event.y);
			sx = vx;
			sy = vy;
			// 还没到下一段就停；旋转和位移同样处理
			if (_now < scale_next.t) break;
		}
	}
	var angle = 0;
	var rotates = _block.rotate;
	var rotate_count = array_length(rotates);
	if (rotate_count > 0) {
		angle = rotates[0].r;
		for (var ri = 0; ri < rotate_count; ri++) {
			if (ri + 1 >= rotate_count) break;
			var rotate_event = rotates[ri];
			var rotate_next = rotates[ri + 1];
			var rotate_p = (_now >= rotate_next.t) ? 1 : official_block_ease(rotate_event.ease, official_block_ratio(_now, rotate_event.t, rotate_next.t));
			var turned_angle = rotate_event.r + (rotate_next.r - rotate_event.r) * rotate_p;
			var rotate_anchor = official_block_world(rotate_event.ax, rotate_event.ay, _aspect);
			// 只把相对上一关键帧多出来的角度绕锚点转上去
			var turned = official_block_rotate_vec(cx - rotate_anchor[0], cy - rotate_anchor[1], (turned_angle - rotate_event.r) * pi / 180);
			cx = rotate_anchor[0] + turned[0];
			cy = rotate_anchor[1] + turned[1];
			angle = turned_angle;
			if (_now < rotate_next.t) break;
		}
	}
	var moves = _block.move;
	var move_count = array_length(moves);
	if (move_count > 0) {
		var move_x = moves[0].x;
		var move_y = moves[0].y;
		for (var mi = 0; mi < move_count; mi++) {
			if (mi + 1 >= move_count) break;
			var move_event = moves[mi];
			var move_next = moves[mi + 1];
			var move_done = _now >= move_next.t;
			var move_px = move_done ? 1 : official_block_ease(move_event.ex, official_block_ratio(_now, move_event.t, move_next.t));
			var move_py = move_done ? 1 : official_block_ease(move_event.ey, official_block_ratio(_now, move_event.t, move_next.t));
			move_x = move_event.x + (move_next.x - move_event.x) * move_px;
			move_y = move_event.y + (move_next.y - move_event.y) * move_py;
			if (_now < move_next.t) break;
		}
		var moved = official_block_world(move_x, move_y, _aspect);
		cx += moved[0] - base_x;
		cy += moved[1] - base_y;
	}
	return [cx, cy, abs((hi[0] - lo[0]) * sx), abs((hi[1] - lo[1]) * sy), angle * pi / 180];
}

///@desc 重置紧凑列表的扫描游标。出现顺序已在打包时排好
///@param {Struct} _state 噪声区状态
///@returns {Undefined} 无
function official_block_index(_state) {
	_state.bucket_lists = undefined;
	_state.bucket_ends = undefined;
	_state.scan_sorted = false;
	_state.scan_active_n = 0;
	_state.scan_cursor = 0;
	_state.scan_now = -infinity;
	if (!is_array(_state.scan_active)) _state.scan_active = [];
}

///@desc 关掉当前存活方块并清空阶段标记和包围盒
///@param {Struct} _state 噪声区状态
///@returns {Undefined} 无
function official_block_hide(_state) {
	var blocks = _state.blocks;
	var packed_n = official_block_iter_count(_state);
	var hide_i = 0;
	while (hide_i < packed_n) {
		blocks[hide_i].on = false;
		hide_i += 1;
	}
	var complex = _state.pack_complex;
	var ci = 0;
	var complex_n = array_length(complex);
	while (ci < complex_n) {
		complex[ci].on = false;
		ci += 1;
	}
	_state.on_active = false;
	_state.on_ready = false;
	_state.on_disabled = false;
	_state.norm_active = false;
	_state.norm_ready = false;
	_state.norm_disabled = false;
	_state.sub_active = false;
	_state.sub_ready = false;
	_state.sub_disabled = false;
	_state.need_gpu = false;
	official_block_cover_clear(_state.cover_active);
	official_block_cover_clear(_state.cover_disabled);
}

///@desc 若方块处于显示区间，则写入相位、淡入和四个角
///@param {Struct} _state 噪声区状态
///@param {Struct} _block 方块
///@param {Real} _now 当前谱面时间
///@param {Real} _aspect 宽高比
///@param {Array} _half 四个半宽半高局部角
///@returns {Undefined} 无
function official_block_activate(_state, _block, _now, _aspect, _half) {
	// 显示区间外直接退出
	if (_now < _block.appear || _now >= _block.disappear) return;
	var phase = 2;
	// 0 激活，1 预备，2 未启用
	if (_now >= _block.enable && _now < _block.disable) phase = 0;
	else if (_now + 0.5 >= _block.enable && _now < _block.enable) phase = 1;
	var fade = 1;
	if (phase == 2 && _now < _block.enable) fade = clamp((_now - _block.appear) / 0.5, 0, 1);
	var pose = official_block_pose(_block, _now, _aspect);
	if (!is_finite(pose[0]) || !is_finite(pose[1]) || pose[2] < 0.0001 || pose[3] < 0.0001) return;
	var corners = _block.corners;
	var finite = true;
	for (var corner = 0; corner < 4; corner++) {
		var local = official_block_rotate_vec(_half[corner][0] * pose[2], _half[corner][1] * pose[3], pose[4]);
		var room_point = official_block_world_to_room(pose[0] + local[0], pose[1] + local[1], _aspect);
		// 任一角不是有限值则整块不算
		if (!is_finite(room_point[0]) || !is_finite(room_point[1])) {
			finite = false;
			break;
		}
		corners[corner * 2] = room_point[0];
		corners[corner * 2 + 1] = room_point[1];
	}
	if (!finite) return;
	_block.on = true;
	_block.phase = phase;
	_block.fade = fade;
	_block.cx = pose[0];
	_block.cy = pose[1];
	_block.sx = pose[2];
	_block.sy = pose[3];
	_block.ang = pose[4];
	if (!_state.tint_set) {
		_state.tint_r = _block.cr;
		_state.tint_g = _block.cg;
		_state.tint_b = _block.cb;
		_state.tint_set = true;
	}
	var cover = (phase == 2) ? _state.cover_disabled : _state.cover_active;
	official_block_cover_add(cover, corners[0], corners[1]);
	official_block_cover_add(cover, corners[2], corners[3]);
	official_block_cover_add(cover, corners[4], corners[5]);
	official_block_cover_add(cover, corners[6], corners[7]);
	if (phase == 0) {
		_state.on_active = true;
		if (_block.subtract) _state.sub_active = true;
		else _state.norm_active = true;
	} else if (phase == 1) {
		_state.on_ready = true;
		if (_block.subtract) _state.sub_ready = true;
		else _state.norm_ready = true;
	} else {
		_state.on_disabled = true;
		if (_block.subtract) _state.sub_disabled = true;
		else _state.norm_disabled = true;
	}
}

///@desc 从紧凑缓冲里取出当前还显示的方块，只实例化这一批
///@param {Struct} _state 噪声区状态
///@param {Real} _now 当前谱面时间
///@param {Real} _aspect 宽高比
///@param {Array} _half 四个半宽半高局部角
///@returns {Undefined} 无
function official_block_gather_packed(_state, _now, _aspect, _half) {
	var buf = _state.pack_buf;
	var order = _state.pack_order;
	var count = _state.pack_count;
	var stride = OFFICIAL_BLOCK_PACK;
	if (_now < _state.scan_now) {
		_state.scan_cursor = 0;
		_state.scan_active_n = 0;
	}
	_state.scan_now = _now;
	var active = _state.scan_active;
	if (!is_array(active)) {
		active = [];
		_state.scan_active = active;
	}
	var live = _state.scan_active_n;
	var cursor = _state.scan_cursor;
	// 游标只向前。一帧最多收一批，避免时间跳变时把窗口卡死
	if (buffer_exists(buf) && is_array(order)) {
		var admit = 0;
		while (cursor < count && admit < 16000) {
			var packed_index = order[cursor];
			var appear = buffer_peek(buf, packed_index * stride + 16, buffer_f32);
			if (appear > _now) break;
			if (live >= array_length(active)) array_push(active, packed_index);
			else active[live] = packed_index;
			live++;
			cursor++;
			admit++;
		}
	}
	_state.scan_cursor = cursor;
	var write = 0;
	var pool_i = 0;
	if (buffer_exists(buf)) {
		for (var si = 0; si < live; si++) {
			var idx = active[si];
			var base = idx * stride;
			if (buffer_peek(buf, base + 28, buffer_f32) <= _now) continue;
			active[write] = idx;
			write++;
			var block = official_block_pool_at(_state, pool_i);
			pool_i++;
			official_block_unpack(block, buf, base);
			official_block_activate(_state, block, _now, _aspect, _half);
		}
	}
	_state.scan_active_n = write;
	_state.block_n = pool_i;
	var complex = _state.pack_complex;
	for (var ci = 0; ci < array_length(complex); ci++) {
		official_block_activate(_state, complex[ci], _now, _aspect, _half);
	}
}

///@desc 收集当前时刻要画的方块，并标出是否需要 GPU
///@param {Struct} _state 噪声区状态
///@param {Real} _now 当前谱面时间
///@param {Real} _aspect 宽高比
///@returns {Undefined} 无
function official_block_gather(_state, _now, _aspect) {
	official_block_hide(_state);
	_state.tint_r = 1;
	_state.tint_g = 0;
	_state.tint_b = 0;
	_state.tint_set = false;
	var half = [[-0.5, -0.5], [0.5, -0.5], [0.5, 0.5], [-0.5, 0.5]];
	official_block_gather_packed(_state, _now, _aspect, half);
	_state.need_gpu = _state.on_active || _state.on_ready || _state.on_disabled;
}

///@desc 判断世界坐标是否落在方块里，可按相减内外收边
///@param {Struct} _block 方块
///@param {Real} _x 世界横坐标
///@param {Real} _y 世界纵坐标
///@param {Bool} _adjusted 是否使用收边后的半宽
///@returns {Bool} 在范围内时为真
function official_block_contains(_block, _x, _y, _adjusted) {
	var sx = _block.sx;
	var sy = _block.sy;
	// 宽或高接近 0 时不算命中
	if (abs(sx) < 0.0001 || abs(sy) < 0.0001) return false;
	var local = official_block_rotate_vec(_x - _block.cx, _y - _block.cy, -_block.ang);
	var lx = local[0] / sx;
	var ly = local[1] / sy;
	var hx = 0.5;
	var hy = 0.5;
	if (_adjusted) {
		// 相减区向外扩，普通区向内收
		var inset_sign = _block.subtract ? 1 : -1;
		hx += min(0.3 / abs(sx), 0.25) * inset_sign;
		hy += min(0.3 / abs(sy), 0.25) * inset_sign;
	}
	return abs(lx) <= hx && abs(ly) <= hy;
}

///@desc 用普通区与相减区的奇偶判断该点是否被挡住
///@param {Struct} _state 噪声区状态
///@param {Real} _x 世界横坐标
///@param {Real} _y 世界纵坐标
///@returns {Bool} 本体和收边都算挡住时为真
function official_block_hits(_state, _x, _y) {
	var inside = false;
	var hole = false;
	var inside_edge = false;
	var hole_edge = false;
	var blocks = _state.blocks;
	var count = official_block_iter_count(_state);
	for (var i = 0; i < count; i++) {
		var block = blocks[i];
		// 只看激活相位；相减区翻转洞的奇偶
		if (!block.on || block.phase != 0) continue;
		if (official_block_contains(block, _x, _y, false)) {
			if (block.subtract) hole = !hole;
			else inside = true;
		}
		if (official_block_contains(block, _x, _y, true)) {
			if (block.subtract) hole_edge = !hole_edge;
			else inside_edge = true;
		}
	}
	var complex = _state.pack_complex;
	for (var ci = 0; ci < array_length(complex); ci++) {
		var extra = complex[ci];
		if (!extra.on || extra.phase != 0) continue;
		if (official_block_contains(extra, _x, _y, false)) {
			if (extra.subtract) hole = !hole;
			else inside = true;
		}
		if (official_block_contains(extra, _x, _y, true)) {
			if (extra.subtract) hole_edge = !hole_edge;
			else inside_edge = true;
		}
	}
	return (inside ^ hole) && (inside_edge ^ hole_edge);
}

///@desc 判断标识是否已在列表里
///@param {Array} _ids 标识列表
///@param {Real} _id 标识
///@returns {Bool} 找到时为真
function official_block_has_id(_ids, _id) {
	var count = array_length(_ids);
	// 找到即返回
	for (var i = 0; i < count; i++) {
		if (_ids[i] == _id) return true;
	}
	return false;
}

///@desc 开始一次悬停缩放动画
///@param {Struct} _hover 悬停槽
///@param {Real} _target 目标缩放
///@param {Bool} _show 为真时从 0 出现，否则从当前缩放收回
///@returns {Undefined} 无
function official_block_hover_go(_hover, _target, _show) {
	_hover.from = _show ? 0 : _hover.scale;
	_hover.scale = _hover.from;
	_hover.target = _target;
	_hover.elapsed = 0;
	_hover.moving = true;
}

///@desc 推进悬停缩放，0.1 秒内走完
///@param {Struct} _hover 悬停槽
///@param {Real} _dt 帧秒数
///@returns {Undefined} 无
function official_block_hover_tick(_hover, _dt) {
	// 未在动画中则不动
	if (!_hover.moving) return;
	var progress = clamp(_hover.elapsed / 0.1, 0, 1);
	_hover.scale = _hover.from + (_hover.target - _hover.from) * progress;
	_hover.elapsed += max(0, _dt);
	if (progress >= 1) _hover.moving = false;
}

///@desc 采集被噪声区挡住的触摸，并更新悬停槽
///@param {Struct} _state 噪声区状态
///@param {Real} _aspect 宽高比
///@param {Real} _dt 帧秒数
///@returns {Undefined} 无
function official_block_input(_state, _aspect, _dt) {
	var touches = [];
	for (var device = 0; device < 4; device++) {
		// 只采集按下的设备
		if (!device_mouse_check_button(device, mb_left)) continue;
		var world = official_block_pixel_to_world(device_mouse_x(device), device_mouse_y(device), _aspect);
		array_add(touches, { id: device, x: world[0], y: world[1] });
	}
	var still = [];
	var worlds = [];
	var seen = array_create(10, false);
	var touch_count = array_length(touches);
	var hovers = _state.hovers;
	for (var t = 0; t < touch_count; t++) {
		var touch = touches[t];
		var blocked = official_block_has_id(_state.blocked_ids, touch.id) || official_block_hits(_state, touch.x, touch.y);
		// 只保留仍被挡住的触点
		if (!blocked) continue;
		array_add(still, touch.id);
		array_add(worlds, [touch.x, touch.y]);
		var slot = -1;
		for (var h = 0; h < 10; h++) {
			if (hovers[h].id == touch.id) {
				slot = h;
				break;
			}
		}
		// 先复用同一标识的槽，否则找空槽
		if (slot < 0) {
			for (var empty = 0; empty < 10; empty++) {
				if (hovers[empty].id == -1) {
					slot = empty;
					break;
				}
			}
		}
		if (slot >= 0) {
			var hover = hovers[slot];
			if (hover.id != touch.id) {
				hover.id = touch.id;
				official_block_hover_go(hover, 11.5, true);
			}
			hover.x = touch.x;
			hover.y = touch.y;
			seen[slot] = true;
		}
	}
	_state.blocked_ids = still;
	_state.touch_world = worlds;
	var live = false;
	for (var i = 0; i < 10; i++) {
		var hover_slot = hovers[i];
		// 本帧没再见到的槽收回去
		if (hover_slot.id != -1 && !seen[i]) {
			hover_slot.id = -1;
			official_block_hover_go(hover_slot, 0, false);
		}
		official_block_hover_tick(hover_slot, _dt);
		if (hover_slot.scale > 0) {
			live = true;
			var reach = 0.22 * hover_slot.scale;
			var hx = hover_slot.x;
			var hy = hover_slot.y;
			var p0 = official_block_world_to_room(hx - reach, hy - reach, _aspect);
			var p1 = official_block_world_to_room(hx - reach, hy + reach, _aspect);
			var p2 = official_block_world_to_room(hx + reach, hy - reach, _aspect);
			var p3 = official_block_world_to_room(hx + reach, hy + reach, _aspect);
			official_block_cover_add(_state.cover_active, p0[0], p0[1]);
			official_block_cover_add(_state.cover_active, p1[0], p1[1]);
			official_block_cover_add(_state.cover_active, p2[0], p2[1]);
			official_block_cover_add(_state.cover_active, p3[0], p3[1]);
		}
	}
	_state.hover_live = live;
}

///@desc 取着色器 uniform 或采样器槽位，并缓存
///@param {Real} _shader 着色器
///@param {String} _name uniform 名
///@param {Bool} _sampler 为真时取采样器
///@returns {Real} 槽位，失败为 -1
function official_block_slot(_shader, _name, _sampler) {
	static cache = {};
	var key = string(_shader) + (_sampler ? "#" : ":") + _name;
	if (variable_struct_exists(cache, key)) return cache[$ key];
	// 编译前不查询，避免无效句柄进缓存
	if (!shader_is_compiled(_shader)) return -1;
	var handle = _sampler ? shader_get_sampler_index(_shader, _name) : shader_get_uniform(_shader, _name);
	if (is_real(handle) && handle >= 0) cache[$ key] = handle;
	return is_real(handle) ? handle : -1;
}

///@desc 写一个浮点 uniform
///@param {Real} _shader 着色器
///@param {String} _name uniform 名
///@param {Real} _value 数值
///@returns {Undefined} 无
function official_block_u1(_shader, _name, _value) {
	var handle = official_block_slot(_shader, _name, false);
	// 槽位无效则跳过
	if (handle >= 0) shader_set_uniform_f(handle, _value);
}

///@desc 写两个浮点 uniform
///@param {Real} _shader 着色器
///@param {String} _name uniform 名
///@param {Real} _x 第一分量
///@param {Real} _y 第二分量
///@returns {Undefined} 无
function official_block_u2(_shader, _name, _x, _y) {
	var handle = official_block_slot(_shader, _name, false);
	// 槽位无效则跳过
	if (handle >= 0) shader_set_uniform_f(handle, _x, _y);
}

///@desc 写三个浮点 uniform
///@param {Real} _shader 着色器
///@param {String} _name uniform 名
///@param {Real} _x 第一分量
///@param {Real} _y 第二分量
///@param {Real} _z 第三分量
///@returns {Undefined} 无
function official_block_u3(_shader, _name, _x, _y, _z) {
	var handle = official_block_slot(_shader, _name, false);
	// 槽位无效则跳过
	if (handle >= 0) shader_set_uniform_f(handle, _x, _y, _z);
}

///@desc 写四个浮点 uniform
///@param {Real} _shader 着色器
///@param {String} _name uniform 名
///@param {Real} _x 第一分量
///@param {Real} _y 第二分量
///@param {Real} _z 第三分量
///@param {Real} _w 第四分量
///@returns {Undefined} 无
function official_block_u4(_shader, _name, _x, _y, _z, _w) {
	var handle = official_block_slot(_shader, _name, false);
	// 槽位无效则跳过
	if (handle >= 0) shader_set_uniform_f(handle, _x, _y, _z, _w);
}

///@desc 写一个整数 uniform
///@param {Real} _shader 着色器
///@param {String} _name uniform 名
///@param {Real} _value 整数
///@returns {Undefined} 无
function official_block_ui(_shader, _name, _value) {
	var handle = official_block_slot(_shader, _name, false);
	// 槽位无效则跳过
	if (handle >= 0) shader_set_uniform_i(handle, _value);
}

///@desc 绑定一张纹理并设置过滤与重复
///@param {Real} _shader 着色器
///@param {String} _name 采样器名
///@param {Real} _texture 纹理
///@param {Bool} _linear 是否线性过滤
///@param {Bool} _repeat 是否重复
///@returns {Undefined} 无
function official_block_tex(_shader, _name, _texture, _linear, _repeat) {
	var stage = official_block_slot(_shader, _name, true);
	// 槽位或纹理无效则不绑
	if (stage < 0 || _texture == -1) return;
	texture_set_stage(stage, _texture);
	gpu_set_texfilter_ext(stage, _linear);
	gpu_set_texrepeat_ext(stage, _repeat);
}

///@desc 把图集里的单张 UV 写成矩形；BlockAreaGroup 的页在一张精灵内重复，而不是跨图集
///@param {Real} _shader 着色器
///@param {String} _name 矩形 uniform 名
///@param {Real} _texture 纹理，-1 表示整张 0 到 1
///@returns {Undefined} 无
function official_block_map_rect(_shader, _name, _texture) {
	// 没有纹理时用整张 0 到 1
	if (_texture == -1) {
		official_block_u4(_shader, _name, 0, 0, 1, 1);
		return;
	}
	var uvs = texture_get_uvs(_texture);
	// 内缩半个纹素，避开图集接缝
	var pad_x = texture_get_texel_width(_texture) * 0.5;
	var pad_y = texture_get_texel_height(_texture) * 0.5;
	official_block_u4(_shader, _name, uvs[0] + pad_x, uvs[1] + pad_y, uvs[2] - pad_x, uvs[3] - pad_y);
}

///@desc 取精灵纹理，没有则用白色表面
///@param {Struct} _state 噪声区状态
///@param {Real} _sprite 精灵
///@returns {Real} 纹理，都没有则为 -1
function official_block_image(_state, _sprite) {
	// 精灵没有就退回白面
	if (sprite_exists(_sprite)) return sprite_get_texture(_sprite, 0);
	if (surface_exists(_state.white_surf)) return surface_get_texture(_state.white_surf);
	return -1;
}

///@desc 取渲染目标纹理，没有则用空白表面
///@param {Struct} _state 噪声区状态
///@param {Real} _index 槽位下标
///@returns {Real} 纹理，都没有则为 -1
function official_block_surf_tex(_state, _index) {
	// 槽位无效或表面不在就退回空白面
	if (_index >= 0 && _index < BLOCK_RT_COUNT && surface_exists(_state.rt[_index])) return surface_get_texture(_state.rt[_index]);
	if (surface_exists(_state.blank_surf)) return surface_get_texture(_state.blank_surf);
	return -1;
}

///@desc 确保 1x1 的白面和透明黑面已建好并清过
///@param {Struct} _state 噪声区状态
///@returns {Bool} 两张表面都可用时为真
function official_block_pixels(_state) {
	if (!surface_exists(_state.white_surf)) {
		_state.white_surf = surface_create(1, 1);
		_state.cleared = false;
	}
	if (!surface_exists(_state.blank_surf)) {
		_state.blank_surf = surface_create(1, 1);
		_state.cleared = false;
	}
	// 只在第一次把白面涂白、黑面涂透明
	if (!_state.cleared && surface_exists(_state.white_surf) && surface_exists(_state.blank_surf)) {
		surface_set_target(_state.white_surf);
		draw_clear_alpha(c_white, 1);
		surface_reset_target();
		surface_set_target(_state.blank_surf);
		draw_clear_alpha(c_black, 0);
		surface_reset_target();
		_state.cleared = true;
	}
	return surface_exists(_state.white_surf) && surface_exists(_state.blank_surf) && _state.cleared;
}

///@desc 用同一张纹理把常见采样器都绑一遍以预热
///@param {Real} _shader 着色器
///@param {Real} _texture 纹理
///@returns {Undefined} 无
function official_block_warm_bind(_shader, _texture) {
	static names = ["_MainTex", "_DisplaceMap", "_NormalBlockRT", "_SubtractBlockRT", "_DisabledNormalBlockRT", "_DisabledSubtractBlockRT", "_ComposeRT", "_SparkMap", "_EffectRT", "_SceneColor", "_NoiseMap", "_MaskRT", "Active", "Ready", "Normal", "Subtract", "Glow", "Hover"];
	var count = array_length(names);
	// 名字对不上的采样器由 tex 自己跳过
	for (var i = 0; i < count; i++) official_block_tex(_shader, names[i], _texture, true, true);
}

///@desc 对每个噪声着色器画一次小表面，促使驱动编译
///@param {Struct} _state 噪声区状态
///@returns {Undefined} 无
function official_block_gpu_warm(_state) {
	// 已预热或没有白面则退出
	if (_state.gpu_warm || !surface_exists(_state.white_surf)) return;
	var warm = surface_create(2, 2);
	if (!surface_exists(warm)) return;
	var shaders = [
		shd_block_subtract, shd_block_subtract_soft, shd_block_compose, shd_block_compose_plain,
		shd_block_glow, shd_block_disabled, shd_block_active, shd_block_active_ready,
		shd_block_pack_mask, shd_block_pack_effect, shd_block_hover, shd_block_warp
	];
	var white = surface_get_texture(_state.white_surf);
	var count = array_length(shaders);
	for (var i = 0; i < count; i++) {
		var shader = shaders[i];
		// 按着色器种类补最少的 uniform
		if (!shader_is_compiled(shader)) continue;
		surface_set_target(warm);
		draw_clear_alpha(c_black, 0);
		shader_set(shader);
		if (shader == shd_block_active || shader == shd_block_active_ready) official_block_active_uniforms(shader, _state, 0, 2, 2);
		else if (shader == shd_block_disabled) official_block_disabled_uniforms(shader, _state, 0);
		else if (shader == shd_block_compose) official_block_compose_uniforms(shader, 0);
		else if (shader == shd_block_glow) official_block_u4(shader, "_DilateTexelSize", 0.5, 0.5, 2, 2);
		else if (shader == shd_block_subtract || shader == shd_block_subtract_soft) {
			official_block_u1(shader, "_ClampThresholdLow", 0.09);
			official_block_u1(shader, "_ClampThresholdHigh", 0.12);
		}
		official_block_warm_bind(shader, white);
		draw_set_colour(c_white);
		draw_set_alpha(1);
		draw_surface_stretched(_state.white_surf, 0, 0, 2, 2);
		shader_reset();
		surface_reset_target();
	}
	surface_free(warm);
	_state.gpu_warm = true;
	official_block_refresh_ok(_state);
}

///@desc 按分辨率和精细模式重建全套渲染目标
///@param {Struct} _state 噪声区状态
///@param {Real} _w 屏幕宽
///@param {Real} _h 屏幕高
///@returns {Bool} 全部创建成功时为真
function official_block_rt_ensure(_state, _w, _h) {
	var fine = official_block_fine();
	// 尺寸和精细开关都没变则复用
	if (_state.surf_w == _w && _state.surf_h == _h && bool(_state.fine) == fine && surface_exists(_state.rt[0])) return true;
	official_block_free_rt(_state);
	// 默认遮罩是八个屏幕像素一个纹素，外框因此较粗。精细模式用两个屏幕像素。
	// 效果缓冲保持同一尺寸；下面的辉光步仍用原来的四像素环。
	var grid = fine ? 2 : 8;
	var bw = max(1, _w div grid);
	var bh = max(1, _h div grid);
	var ew = fine ? bw : max(1, bw * 2);
	var eh = fine ? bh : max(1, bh * 2);
	var sw = max(1, _w div 6);
	var sh = max(1, _h div 6);
	_state.fine = fine;
	_state.bw = bw;
	_state.bh = bh;
	_state.ew = ew;
	_state.eh = eh;
	_state.sw = sw;
	_state.sh = sh;
	// 场景拷贝是全分辨率。1:1 的 draw_surface 对齐谱面级拷贝。
	// 激活着色器仍按六个屏幕像素取点，精细模式则是两个。
	var widths = [bw, bw, bw, bw, bw, bw, bw, bw, bw, bw, bw, ew, ew, bw, bw, ew, _w, bw];
	var heights = [bh, bh, bh, bh, bh, bh, bh, bh, bh, bh, bh, eh, eh, bh, bh, eh, _h, bh];
	for (var i = 0; i < BLOCK_RT_COUNT; i++) {
		_state.rt[i] = surface_create(widths[i], heights[i]);
		// 任一表面创建失败则整套不算就绪
		if (!surface_exists(_state.rt[i])) return false;
	}
	_state.surf_w = _w;
	_state.surf_h = _h;
	return true;
}

///@desc 把目标表面清成透明并开始一次替换混合的全屏着色器
///@param {Real} _dest 目标表面
///@param {Real} _shader 着色器
///@returns {Undefined} 无
function official_block_fullscreen_begin(_dest, _shader) {
	surface_set_target(_dest);
	draw_clear_alpha(c_black, 0);
	gpu_set_blendmode_ext(bm_one, bm_zero);
	shader_set(_shader);
	draw_set_colour(c_white);
	draw_set_alpha(1);
	gpu_set_texfilter(false);
}

///@desc 用白面铺满目标并结束着色器
///@param {Struct} _state 噪声区状态
///@param {Real} _dest 目标表面
///@returns {Undefined} 无
function official_block_fullscreen_end(_state, _dest) {
	draw_surface_stretched(_state.white_surf, 0, 0, surface_get_width(_dest), surface_get_height(_dest));
	shader_reset();
	surface_reset_target();
}

///@desc 用两个三角形画出四个角构成的四边形
///@param {Array} _corners 八个屏幕坐标
///@param {Real} _sx 横向缩放到目标纹素
///@param {Real} _sy 纵向缩放到目标纹素
///@returns {Undefined} 无
function official_block_draw_quad(_corners, _sx, _sy) {
	var x0 = _corners[0] * _sx;
	var y0 = _corners[1] * _sy;
	var x1 = _corners[2] * _sx;
	var y1 = _corners[3] * _sy;
	var x2 = _corners[4] * _sx;
	var y2 = _corners[5] * _sy;
	var x3 = _corners[6] * _sx;
	var y3 = _corners[7] * _sy;
	draw_primitive_begin(pr_trianglelist);
	draw_vertex(x0, y0);
	draw_vertex(x1, y1);
	draw_vertex(x2, y2);
	draw_vertex(x0, y0);
	draw_vertex(x2, y2);
	draw_vertex(x3, y3);
	draw_primitive_end();
}

///@desc 把同一相位、同一相减属性的方块画进一张遮罩
///@param {Struct} _state 噪声区状态
///@param {Real} _index 目标槽位
///@param {Real} _phase 相位
///@param {Bool} _subtract 是否相减
///@param {Real} _sx 横向缩放
///@param {Real} _sy 纵向缩放
///@returns {Undefined} 无
function official_block_paint_group(_state, _index, _phase, _subtract, _sx, _sy) {
	var dest = _state.rt[_index];
	if (!surface_exists(dest)) return;
	surface_set_target(dest);
	draw_clear_alpha(c_black, 0);
	gpu_set_blendmode_ext(bm_src_alpha, bm_one);
	shader_reset();
	var blocks = _state.blocks;
	var count = official_block_iter_count(_state);
	for (var i = 0; i < count; i++) {
		var block = blocks[i];
		// 相减区用低透明度着色，普通区用淡入透明度
		if (!block.on || block.phase != _phase || block.subtract != _subtract) continue;
		if (_subtract) {
			draw_set_colour(make_colour_rgb(255, floor(clamp(block.fade, 0, 1) * 255), 255));
			draw_set_alpha(0.1);
		} else {
			draw_set_colour(c_white);
			draw_set_alpha(block.fade);
		}
		official_block_draw_quad(block.corners, _sx, _sy);
	}
	var complex = _state.pack_complex;
	for (var ci = 0; ci < array_length(complex); ci++) {
		var extra = complex[ci];
		if (!extra.on || extra.phase != _phase || extra.subtract != _subtract) continue;
		if (_subtract) {
			draw_set_colour(make_colour_rgb(255, floor(clamp(extra.fade, 0, 1) * 255), 255));
			draw_set_alpha(0.1);
		} else {
			draw_set_colour(c_white);
			draw_set_alpha(extra.fade);
		}
		official_block_draw_quad(extra.corners, _sx, _sy);
	}
	draw_set_alpha(1);
	surface_reset_target();
}

///@desc 用阈值着色器把相减遮罩收成硬边或软边
///@param {Struct} _state 噪声区状态
///@param {Real} _shader 相减着色器
///@param {Real} _dest_index 目标槽位
///@param {Real} _source_index 源槽位
///@returns {Undefined} 无
function official_block_subtract_pass(_state, _shader, _dest_index, _source_index) {
	var dest = _state.rt[_dest_index];
	official_block_fullscreen_begin(dest, _shader);
	official_block_u1(_shader, "_ClampThresholdLow", 0.09);
	official_block_u1(_shader, "_ClampThresholdHigh", 0.12);
	official_block_tex(_shader, "_MainTex", official_block_surf_tex(_state, _source_index), false, false);
	official_block_fullscreen_end(_state, dest);
}

///@desc 写入合成通道共用的时间与位移参数
///@param {Real} _shader 着色器
///@param {Real} _now 当前谱面时间
///@returns {Undefined} 无
function official_block_compose_uniforms(_shader, _now) {
	official_block_u4(_shader, "_BlockTime", _now / 20, _now, _now * 2, _now * 3);
	official_block_u1(_shader, "_DisplaceSpeed", 2.5899999141693115);
	official_block_u1(_shader, "_DisplaceStrength", 0.10000000149011612);
	official_block_u1(_shader, "_EdgeWave", official_block_edge_wave());
	official_block_u4(_shader, "_DisplaceDirection", 0.5, 0.5, 0, 0);
	official_block_u4(_shader, "_DisplaceMap_ST", 2.130000114440918, 1.0199999809265137, 0, 0);
}

///@desc 把激活的普通遮罩和相减遮罩合成一张
///@param {Struct} _state 噪声区状态
///@param {Real} _now 当前谱面时间
///@returns {Undefined} 无
function official_block_compose_active(_state, _now) {
	var shader = shd_block_compose;
	var dest = _state.rt[BLOCK_RT_ACTIVE_C];
	official_block_fullscreen_begin(dest, shader);
	official_block_compose_uniforms(shader, _now);
	var displace_tex = official_block_image(_state, _state.noise_spr);
	official_block_tex(shader, "_DisplaceMap", displace_tex, true, false);
	official_block_map_rect(shader, "_DisplaceMap_Rect", displace_tex);
	official_block_tex(shader, "_NormalBlockRT", official_block_surf_tex(_state, _state.norm_active ? BLOCK_RT_ACTIVE_N : -1), false, false);
	official_block_tex(shader, "_SubtractBlockRT", official_block_surf_tex(_state, _state.sub_active ? BLOCK_RT_ACTIVE_HP : -1), false, false);
	official_block_fullscreen_end(_state, dest);
}

///@desc 不做位移，只把未启用或预备的两张遮罩合成
///@param {Struct} _state 噪声区状态
///@param {Real} _dest_index 目标槽位
///@param {Real} _normal_index 普通遮罩槽位
///@param {Real} _subtract_index 相减遮罩槽位
///@returns {Undefined} 无
function official_block_compose_plain(_state, _dest_index, _normal_index, _subtract_index) {
	var shader = shd_block_compose_plain;
	var dest = _state.rt[_dest_index];
	official_block_fullscreen_begin(dest, shader);
	official_block_tex(shader, "_DisabledNormalBlockRT", official_block_surf_tex(_state, _normal_index), false, false);
	official_block_tex(shader, "_DisabledSubtractBlockRT", official_block_surf_tex(_state, _subtract_index), false, false);
	official_block_fullscreen_end(_state, dest);
}

///@desc 对激活合成图做五次交替膨胀，得到辉光
///@param {Struct} _state 噪声区状态
///@returns {Undefined} 无
function official_block_glow(_state) {
	var shader = shd_block_glow;
	var weights = [0.45856798, 0.28286123, 0.15658922, 0.07305908, 0.02494781];
	var source = BLOCK_RT_ACTIVE_C;
	var ew = _state.ew;
	var eh = _state.eh;
	var step_x = 1 / ew;
	var step_y = 1 / eh;
	// 精细模式的步进按全屏四像素，而不是效果缓冲纹素
	if (_state.fine) {
		step_x = 4 / max(1, _state.surf_w);
		step_y = 4 / max(1, _state.surf_h);
	}
	// 奇偶两张目标来回写
	for (var pass = 0; pass < 5; pass++) {
		var dest_index = (pass mod 2) == 0 ? BLOCK_RT_GLOW0 : BLOCK_RT_GLOW1;
		var dest = _state.rt[dest_index];
		official_block_fullscreen_begin(dest, shader);
		official_block_u4(shader, "_DilateTexelSize", step_x, step_y, ew, eh);
		official_block_u1(shader, "_PassWeight", weights[pass]);
		official_block_u1(shader, "_GlowFirstPass", pass == 0 ? 1 : 0);
		official_block_tex(shader, "_MainTex", official_block_surf_tex(_state, source), false, false);
		official_block_tex(shader, "_ComposeRT", official_block_surf_tex(_state, BLOCK_RT_ACTIVE_C), false, false);
		official_block_fullscreen_end(_state, dest);
		source = dest_index;
	}
}

///@desc 把仍有缩放的手指悬停画成触摸高光
///@param {Struct} _state 噪声区状态
///@returns {Undefined} 无
function official_block_paint_hover(_state) {
	var dest = _state.rt[BLOCK_RT_HOVER];
	if (!surface_exists(dest) || !sprite_exists(_state.touch_spr)) return;
	surface_set_target(dest);
	draw_clear_alpha(c_black, 0);
	gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
	shader_set(shd_block_hover);
	draw_set_colour(c_white);
	draw_set_alpha(1);
	var texture = sprite_get_texture(_state.touch_spr, 0);
	var uvs = texture_get_uvs(texture);
	var sx = _state.bw / _state.surf_w;
	var sy = _state.bh / _state.surf_h;
	var aspect = official_block_aspect();
	static local_x = [-0.14000000059604645, 0.2199999988079071, 0.2199999988079071, -0.1599999964237213, -0.2199999988079071, -0.2199999988079071];
	static local_y = [0.2199999988079071, -0.2199999988079071, 0.2199999988079071, -0.2199999988079071, 0.15000000596046448, -0.10999999940395355];
	static index = [5, 4, 3, 0, 3, 4, 1, 3, 0, 2, 1, 0];
	var hovers = _state.hovers;
	for (var h = 0; h < 10; h++) {
		var hover = hovers[h];
		// 六个局部点变到房间后再缩到遮罩分辨率
		if (hover.scale <= 0) continue;
		var pos = array_create(12, 0);
		for (var k = 0; k < 6; k++) {
			var room_point = official_block_world_to_room(hover.x + local_x[k] * hover.scale, hover.y + local_y[k] * hover.scale, aspect);
			pos[k * 2] = room_point[0] * sx;
			pos[k * 2 + 1] = room_point[1] * sy;
		}
		draw_primitive_begin_texture(pr_trianglelist, texture);
		for (var v = 0; v < 12; v++) {
			var point = index[v];
			var uu = local_x[point] / 0.44 + 0.5;
			var vv = local_y[point] / 0.44 + 0.5;
			draw_vertex_texture(pos[point * 2], pos[point * 2 + 1], uvs[0] + uu * (uvs[2] - uvs[0]), uvs[1] + vv * (uvs[3] - uvs[1]));
		}
		draw_primitive_end();
	}
	shader_reset();
	surface_reset_target();
}

///@desc 把激活、预备遮罩和辉光、悬停打成两张打包图
///@param {Struct} _state 噪声区状态
///@returns {Undefined} 无
function official_block_pack(_state) {
	var ready_tex = -1;
	// 有相减预备时用合成图，否则用普通预备遮罩
	if (_state.sub_ready && _state.ok_compose_plain) ready_tex = BLOCK_RT_READY_C;
	else if (_state.norm_ready) ready_tex = BLOCK_RT_READY_N;
	var active_tex = (_state.on_active && _state.ok_compose) ? BLOCK_RT_ACTIVE_C : -1;
	var glow_tex = (_state.on_active && _state.ok_compose && _state.ok_glow) ? BLOCK_RT_GLOW0 : -1;
	var mask = shd_block_pack_mask;
	var mask_dest = _state.rt[BLOCK_RT_PACK_M];
	official_block_fullscreen_begin(mask_dest, mask);
	official_block_tex(mask, "Active", official_block_surf_tex(_state, active_tex), false, false);
	official_block_tex(mask, "Ready", official_block_surf_tex(_state, ready_tex), false, false);
	official_block_tex(mask, "Normal", official_block_surf_tex(_state, _state.norm_ready ? BLOCK_RT_READY_N : -1), false, false);
	official_block_tex(mask, "Subtract", official_block_surf_tex(_state, _state.sub_ready ? BLOCK_RT_READY_HP : -1), false, false);
	official_block_fullscreen_end(_state, mask_dest);

	var pack_shader = shd_block_pack_effect;
	var effect_dest = _state.rt[BLOCK_RT_PACK_E];
	official_block_fullscreen_begin(effect_dest, pack_shader);
	official_block_tex(pack_shader, "Glow", official_block_surf_tex(_state, glow_tex), false, false);
	official_block_tex(pack_shader, "Hover", official_block_surf_tex(_state, _state.hover_live ? BLOCK_RT_HOVER : -1), false, false);
	official_block_fullscreen_end(_state, effect_dest);
}

///@desc 把谱面表面拷进全分辨率场景目标
///@param {Struct} _state 噪声区状态
///@param {Real} _chart 谱面表面
///@returns {Undefined} 无
function official_block_copy_scene(_state, _chart) {
	var dest = _state.rt[BLOCK_RT_SCENE];
	if (!surface_exists(dest) || !surface_exists(_chart)) return;
	var dest_w = surface_get_width(dest);
	var dest_h = surface_get_height(dest);
	var src_w = surface_get_width(_chart);
	var src_h = surface_get_height(_chart);
	// 与谱面灰度拷贝同一套顺序。视口裁剪是全帧像素，不先改掉就会裁到这张目标。
	pls_draw_flush();
	surface_set_target(dest);
	gpu_set_scissor(0, 0, dest_w, dest_h);
	gpu_set_colourwriteenable(true, true, true, true);
	gpu_set_alphatestenable(false);
	gpu_set_blendenable(true);
	gpu_set_blendequation(bm_eq_add);
	gpu_set_blendmode_ext(bm_one, bm_zero);
	gpu_set_cullmode(cull_noculling);
	shader_reset();
	draw_set_colour(c_white);
	draw_set_alpha(1);
	draw_clear_alpha(c_black, 1);
	// 尺寸一致时 1:1 拷贝，否则拉伸
	if (dest_w == src_w && dest_h == src_h) draw_surface(_chart, 0, 0);
	else draw_surface_stretched(_chart, 0, 0, dest_w, dest_h);
	pls_draw_flush();
	surface_reset_target();
}

///@desc 按当前染色写未启用材质的填充与火花参数
///@param {Real} _shader 着色器
///@param {Struct} _state 噪声区状态
///@param {Real} _now 当前谱面时间
///@returns {Undefined} 无
function official_block_disabled_uniforms(_shader, _state, _now) {
	var cr = _state.tint_r;
	var cg = _state.tint_g;
	var cb = _state.tint_b;
	var fill = official_block_shift_color(0.4970000088214874, 0.13766898214817047, 0.13766898214817047, cr, cg, cb);
	var spark = official_block_shift_color(0.31132078170776367, 0.07783019542694092, 0.07783019542694092, cr, cg, cb);
	official_block_u4(_shader, "_BlockTime", _now / 20, _now, _now * 2, _now * 3);
	official_block_u4(_shader, "_FillColor", fill[0], fill[1], fill[2], 1);
	official_block_u1(_shader, "_FillOpacity", 0.4000000059604645);
	official_block_u3(_shader, "_SparkTint", spark[0], spark[1], spark[2]);
	official_block_u1(_shader, "_SparkMapOpacity", 3.5);
	official_block_u1(_shader, "_SparkDisplaceIntensity", 2.2899999618530273);
	official_block_u1(_shader, "_DisplaceSpeed", 0.30000001192092896);
	official_block_u4(_shader, "_DisplaceDirection", 1, 1, 0, 0);
	official_block_u4(_shader, "_DisplaceMap_ST", 0.5, 0.20000000298023224, 0, 0);
	official_block_u4(_shader, "_SparkMap_ST", 3, 1.2000000476837158, 0, 0);
}

///@desc 按当前染色和触摸点写激活或预备材质参数
///@param {Real} _shader 着色器
///@param {Struct} _state 噪声区状态
///@param {Real} _now 当前谱面时间
///@param {Real} _w 屏幕宽
///@param {Real} _h 屏幕高
///@returns {Undefined} 无
function official_block_active_uniforms(_shader, _state, _now, _w, _h) {
	var cr = _state.tint_r;
	var cg = _state.tint_g;
	var cb = _state.tint_b;
	var edge = official_block_shift_color(1, 0.3301885724067688, 0.3301885724067688, cr, cg, cb);
	var fill = official_block_shift_color(0.713207483291626, 0.23549295961856842, 0.23549295961856842, cr, cg, cb);
	var glow = official_block_shift_color(1, 0.17924517393112183, 0.17924517393112183, cr, cg, cb);
	var spark = official_block_shift_color(1, 0.28490567207336426, 0.28490567207336426, cr, cg, cb);
	official_block_u4(_shader, "_BlockTime", _now / 20, _now, _now * 2, _now * 3);
	official_block_u4(_shader, "_ScreenParams", _w, _h, 1 + 1 / _w, 1 + 1 / _h);
	official_block_u4(_shader, "_EffectRT_TexelSize", 1 / _state.ew, 1 / _state.eh, _state.ew, _state.eh);
	official_block_u4(_shader, "_EdgeColor", edge[0], edge[1], edge[2], 1);
	official_block_u1(_shader, "_EdgeOpacity", 0.800000011920929);
	official_block_u4(_shader, "_FillColor", fill[0], fill[1], fill[2], 1);
	official_block_u1(_shader, "_FillStrength", 0.6669999957084656);
	official_block_u1(_shader, "_FillOpacity", 0.6669999957084656);
	official_block_u4(_shader, "_GlowColor", glow[0], glow[1], glow[2], 1);
	official_block_u1(_shader, "_GlowIntensity", 0.800000011920929);
	official_block_u3(_shader, "_SparkTint", spark[0], spark[1], spark[2]);
	official_block_u1(_shader, "_SparkMapOpacity", 5.690000057220459);
	official_block_u1(_shader, "_SparkHueShiftAmount", 0.20000000298023224);
	official_block_u1(_shader, "_SparkDisplaceIntensity", 2.390000104904175);
	official_block_u1(_shader, "_DisplaceBlendIntensity", 0.41100001335144043);
	official_block_u1(_shader, "_DisplaceSpeed", 1.5);
	official_block_u1(_shader, "_DisplaceStrength", 0.15000000596046448);
	official_block_u4(_shader, "_DisplaceDirection", 1, 1, 0, 0);
	official_block_u1(_shader, "_TouchPosShine", 1);
	official_block_u1(_shader, "_TouchPosRadius", 0.5);
	official_block_u1(_shader, "_TouchPosSDFSmoothness", 0.4699999988079071);
	official_block_u1(_shader, "_TouchPosSDFFalloff", 0.4099999964237213);
	official_block_u1(_shader, "_BackgroundPixelScale", official_block_fine() ? 2 : 6);
	official_block_u1(_shader, "_ShineSpeed", 37.900001525878906);
	official_block_u1(_shader, "_ShineBrightness", 0.11999999731779099);
	official_block_u4(_shader, "_ShineColor", 1, 1, 1, 1);
	official_block_u1(_shader, "_TouchDisplaceSpeed", 2.9000000953674316);
	official_block_u1(_shader, "_TouchDisplaceStrength", 0.07999999821186066);
	official_block_u4(_shader, "_TouchDisplaceDirection", 1, 1, 0, 0);
	official_block_u4(_shader, "_NoiseTint", cr, cg, cb, 1);
	official_block_u1(_shader, "_NoiseEvoSpeed", 0.029999999329447746);
	official_block_u1(_shader, "_NoiseDirChangeSpeed", 60);
	official_block_u1(_shader, "_NoiseDisplaceStrength", 1);
	official_block_u1(_shader, "_NoiseRadius", 0.47999998927116394);
	official_block_u1(_shader, "_NoiseSmoothness", 1);
	official_block_u1(_shader, "_SDFCellSize", 0.10999999940395355);
	official_block_u1(_shader, "_SDFFalloff", 0.3400000035762787);
	official_block_u1(_shader, "_SDFSmoothness", 0.6299999952316284);
	official_block_u1(_shader, "_SDFMoveSpeed", 9.300000190734863);
	official_block_u4(_shader, "_TouchGlowColor", cr, cg, cb, 1);
	official_block_u1(_shader, "_TouchBackgroundPixelScale", 8);
	official_block_u4(_shader, "_DisplaceMap_ST", 0.800000011920929, 0.30000001192092896, 0, 0);
	official_block_u4(_shader, "_SparkMap_ST", 3, 1.2000000476837158, 0, 0);
	official_block_u4(_shader, "_TouchDisplaceMap_ST", 0.550000011920929, 0.30000001192092896, 0, 0);
	official_block_u4(_shader, "_NoiseMap_ST", 1.5, 1.4600000381469727, 0, 0);
	official_block_u2(_shader, "_HoverSize", _state.bw, _state.bh);
	official_block_u1(_shader, "_RemoveDistortion", 0);
	static touch_names = ["_TouchPos0", "_TouchPos1", "_TouchPos2", "_TouchPos3", "_TouchPos4", "_TouchPos5", "_TouchPos6", "_TouchPos7", "_TouchPos8", "_TouchPos9"];
	var worlds = _state.touch_world;
	var touch_count = min(10, array_length(worlds));
	// 预备着色器不上传触摸点
	official_block_ui(_shader, "_TouchPosCount", (_shader == shd_block_active) ? touch_count : 0);
	var aspect = official_block_aspect();
	for (var i = 0; i < 10; i++) {
		var tx = 0;
		var ty = 0;
		if (i < touch_count && _shader == shd_block_active) {
			var room_point = official_block_world_to_room(worlds[i][0], worlds[i][1], aspect);
			// 触摸点换成相对高度的屏幕坐标
			tx = (room_point[0] / _w) * _w / _h;
			ty = room_point[1] / _h;
		}
		official_block_u2(_shader, touch_names[i], tx, ty);
	}
}

///@desc 按包围盒加边距设置裁剪，坏框则不裁
///@param {Struct} _cover 包围盒
///@param {Real} _margin 外扩像素
///@param {Real} _w 屏幕宽
///@param {Real} _h 屏幕高
///@returns {Bool} 应该继续绘制时为真
function official_block_scissor(_cover, _margin, _w, _h) {
	// 坐标坏了就整屏画；没有点或面积过小则跳过
	if (_cover.bad) return true;
	if (!_cover.any) return false;
	var x0 = clamp(floor(_cover.minx - _margin), 0, _w);
	var y0 = clamp(floor(_cover.miny - _margin), 0, _h);
	var x1 = clamp(ceil(_cover.maxx + _margin), 0, _w);
	var y1 = clamp(ceil(_cover.maxy + _margin), 0, _h);
	if (x1 - x0 < 1 || y1 - y0 < 1) return false;
	gpu_set_scissor(x0, y0, x1 - x0, y1 - y0);
	return true;
}

///@desc 用像素对齐的扭曲着色器盖住噪声区内部
///@param {Struct} _state 噪声区状态
///@param {Real} _w 屏幕宽
///@param {Real} _h 屏幕高
///@param {Real} _now 当前谱面时间
///@returns {Undefined} 无
function official_block_warp_present(_state, _w, _h, _now) {
	// 着色器或场景表面缺失则不画
	if (!shader_is_compiled(shd_block_warp)) return;
	if (!surface_exists(_state.rt[BLOCK_RT_SCENE])) return;
	var scene_tex = surface_get_texture(_state.rt[BLOCK_RT_SCENE]);
	var mask_tex = official_block_surf_tex(_state, BLOCK_RT_PACK_M);
	var noise_tex = official_block_image(_state, _state.noise_spr);
	var spark_tex = -1;
	var spark_w = 1;
	var spark_h = 1;
	if (sprite_exists(_state.spark_spr)) {
		spark_tex = sprite_get_texture(_state.spark_spr, 0);
		spark_w = max(1, sprite_get_width(_state.spark_spr));
		spark_h = max(1, sprite_get_height(_state.spark_spr));
	} else if (surface_exists(_state.blank_surf)) {
		spark_tex = surface_get_texture(_state.blank_surf);
	}
	// 缺任何一张纹理就不画
	if (scene_tex == -1 || mask_tex == -1 || noise_tex == -1 || spark_tex == -1) return;
	shader_set(shd_block_warp);
	var screen_handle = shader_get_uniform(shd_block_warp, "u_screen");
	var scene_handle = shader_get_uniform(shd_block_warp, "u_scene");
	var noise_uv_handle = shader_get_uniform(shd_block_warp, "u_noise_uv");
	var spark_uv_handle = shader_get_uniform(shd_block_warp, "u_spark_uv");
	var spark_px_handle = shader_get_uniform(shd_block_warp, "u_spark_px");
	var fill_handle = shader_get_uniform(shd_block_warp, "u_fill");
	var scene_uvs = texture_get_uvs(scene_tex);
	var noise_uvs = texture_get_uvs(noise_tex);
	var spark_uvs = texture_get_uvs(spark_tex);
	// w 是 texture_17 的一种排布保持不动的谱面秒数。
	if (screen_handle >= 0) shader_set_uniform_f(screen_handle, _w, _h, _now, 0.18);
	var fine_handle = shader_get_uniform(shd_block_warp, "u_fine");
	if (fine_handle >= 0) shader_set_uniform_f(fine_handle, official_block_fine() ? 1 : 0);
	if (scene_handle >= 0) shader_set_uniform_f(scene_handle, scene_uvs[0], scene_uvs[1], scene_uvs[2], scene_uvs[3]);
	if (noise_uv_handle >= 0) shader_set_uniform_f(noise_uv_handle, noise_uvs[0], noise_uvs[1], noise_uvs[2], noise_uvs[3]);
	if (spark_uv_handle >= 0) shader_set_uniform_f(spark_uv_handle, spark_uvs[0], spark_uvs[1], spark_uvs[2], spark_uvs[3]);
	if (spark_px_handle >= 0) shader_set_uniform_f(spark_px_handle, spark_w, spark_h);
	if (fill_handle >= 0) shader_set_uniform_f(fill_handle, 0.713207483291626, 0.23549295961856842, 0.23549295961856842);
	var mask_stage = shader_get_sampler_index(shd_block_warp, "u_mask");
	var noise_stage = shader_get_sampler_index(shd_block_warp, "u_noise");
	var edge_stage = shader_get_sampler_index(shd_block_warp, "u_edge");
	var spark_stage = shader_get_sampler_index(shd_block_warp, "u_spark");
	var edge_tex = official_block_surf_tex(_state, BLOCK_RT_PACK_E);
	if (mask_stage > 0) {
		texture_set_stage(mask_stage, mask_tex);
		gpu_set_texfilter_ext(mask_stage, false);
		gpu_set_texrepeat_ext(mask_stage, false);
	}
	if (edge_stage > 0 && edge_tex != -1) {
		texture_set_stage(edge_stage, edge_tex);
		gpu_set_texfilter_ext(edge_stage, true);
		gpu_set_texrepeat_ext(edge_stage, false);
	}
	if (noise_stage > 0) {
		texture_set_stage(noise_stage, noise_tex);
		gpu_set_texfilter_ext(noise_stage, true);
		gpu_set_texrepeat_ext(noise_stage, true);
	}
	if (spark_stage > 0) {
		texture_set_stage(spark_stage, spark_tex);
		gpu_set_texfilter_ext(spark_stage, false);
		gpu_set_texrepeat_ext(spark_stage, false);
	}
	// 0 号槽是谱面拷贝。放在其它采样器之后设置，避免上一通道的白四边形还绑在上面。
	texture_set_stage(0, scene_tex);
	gpu_set_texfilter(false);
	gpu_set_texrepeat(false);
	gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
	draw_set_colour(c_white);
	draw_set_alpha(1);
	draw_primitive_begin_texture(pr_trianglelist, scene_tex);
	draw_vertex_texture(0, 0, 0, 0);
	draw_vertex_texture(_w, 0, 1, 0);
	draw_vertex_texture(_w, _h, 1, 1);
	draw_vertex_texture(0, 0, 0, 0);
	draw_vertex_texture(_w, _h, 1, 1);
	draw_vertex_texture(0, _h, 0, 1);
	draw_primitive_end();
	shader_reset();
}

///@desc 铺一张表面或默认白面，然后复位着色器
///@param {Struct} _state 噪声区状态
///@param {Real} _w 宽
///@param {Real} _h 高
///@param {Any} _surface 要画的表面，缺省为未定义则用白面
///@returns {Undefined} 无
function official_block_present_quad(_state, _w, _h, _surface = undefined) {
	var source = _state.white_surf;
	// 传入有效表面就用它，否则用 1x1 白面
	if (is_real(_surface) && surface_exists(_surface)) then source = _surface;
	draw_surface_stretched(source, 0, 0, _w, _h);
	shader_reset();
}

///@desc 把未启用材质和激活或预备材质画回谱面表面
///@param {Struct} _state 噪声区状态
///@param {Real} _now 当前谱面时间
///@param {Real} _w 屏幕宽
///@param {Real} _h 屏幕高
///@returns {Undefined} 无
function official_block_present(_state, _now, _w, _h) {
	var displace_tex = official_block_image(_state, _state.noise_spr);
	var spark_tex = official_block_image(_state, _state.spark_spr);
	var grain_tex = official_block_image(_state, _state.grain_spr);
	gpu_set_alphatestenable(false);
	draw_set_colour(c_white);
	draw_set_alpha(1);
	// 未启用与激活分两次裁剪绘制
	if (_state.on_disabled && _state.ok_disabled && official_block_scissor(_state.cover_disabled, 16, _w, _h)) {
		var shader = shd_block_disabled;
		var compose = -1;
		if (_state.sub_disabled && _state.ok_compose_plain) compose = BLOCK_RT_OFF_C;
		else if (_state.norm_disabled) compose = BLOCK_RT_OFF_N;
		if (compose >= 0) {
			gpu_set_blendmode_ext(bm_one, bm_one);
			shader_set(shader);
			official_block_disabled_uniforms(shader, _state, _now);
			official_block_tex(shader, "_ComposeRT", official_block_surf_tex(_state, compose), false, false);
			official_block_tex(shader, "_DisplaceMap", displace_tex, true, false);
			official_block_map_rect(shader, "_DisplaceMap_Rect", displace_tex);
			official_block_tex(shader, "_SparkMap", spark_tex, true, false);
			official_block_map_rect(shader, "_SparkMap_Rect", spark_tex);
			official_block_present_quad(_state, _w, _h);
		}
		gpu_set_scissor(0, 0, _w, _h);
	}
	// 有激活或悬停时用激活着色器，否则用预备着色器
	var active_shader = (_state.on_active || _state.hover_live) ? shd_block_active : shd_block_active_ready;
	var active_ok = (active_shader == shd_block_active) ? _state.ok_active : _state.ok_ready;
	if ((_state.on_active || _state.on_ready || _state.hover_live) && active_ok) {
		var margin = 0.11 * max(_w, _h) + 8;
		if (official_block_scissor(_state.cover_active, margin, _w, _h)) {
			gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
			shader_set(active_shader);
			official_block_active_uniforms(active_shader, _state, _now, _w, _h);
			official_block_tex(active_shader, "_MaskRT", official_block_surf_tex(_state, BLOCK_RT_PACK_M), false, false);
			official_block_tex(active_shader, "_EffectRT", official_block_surf_tex(_state, BLOCK_RT_PACK_E), false, false);
			official_block_tex(active_shader, "_DisplaceMap", displace_tex, true, false);
			official_block_map_rect(active_shader, "_DisplaceMap_Rect", displace_tex);
			official_block_tex(active_shader, "_SparkMap", spark_tex, true, false);
			official_block_map_rect(active_shader, "_SparkMap_Rect", spark_tex);
			official_block_tex(active_shader, "_NoiseMap", grain_tex, true, false);
			official_block_map_rect(active_shader, "_NoiseMap_Rect", grain_tex);
			// 四边形本身保持 1x1 白面，UV 才仍是遮罩所用的 0 到 1 屏幕坐标。
			// 若把谱面拷贝当成这个四边形，gm_BaseTexture 会是白的，因为 texture_set_stage 先执行。
			// _SceneColor 是更后面的采样器。
			var scene_index = (active_shader == shd_block_active) ? BLOCK_RT_SCENE : -1;
			official_block_tex(active_shader, "_SceneColor", official_block_surf_tex(_state, scene_index), false, false);
			official_block_present_quad(_state, _w, _h);
			// 材质通道会让区域内仍看见清晰谱面。这里改成像素对齐并带位移的拷贝。
			if (active_shader == shd_block_active) official_block_warp_present(_state, _w, _h, _now);
			gpu_set_scissor(0, 0, _w, _h);
		}
	}
}

///@desc 按当前有哪些相位，离屏画出遮罩、合成、辉光和场景拷贝
///@param {Struct} _state 噪声区状态
///@param {Real} _chart 谱面表面
///@param {Real} _now 当前谱面时间
///@returns {Undefined} 无
function official_block_offscreen(_state, _chart, _now) {
	var sx = _state.bw / _state.surf_w;
	var sy = _state.bh / _state.surf_h;
	gpu_set_alphatestenable(false);
	gpu_set_blendenable(true);
	gpu_set_cullmode(cull_noculling);
	gpu_set_zwriteenable(false);
	gpu_set_ztestenable(false);
	// 先画各组遮罩，再做相减、合成、辉光、悬停和打包
	if (_state.norm_active) official_block_paint_group(_state, BLOCK_RT_ACTIVE_N, 0, false, sx, sy);
	if (_state.sub_active) official_block_paint_group(_state, BLOCK_RT_ACTIVE_H, 0, true, sx, sy);
	if (_state.norm_ready) official_block_paint_group(_state, BLOCK_RT_READY_N, 1, false, sx, sy);
	if (_state.sub_ready) official_block_paint_group(_state, BLOCK_RT_READY_H, 1, true, sx, sy);
	if (_state.norm_disabled) official_block_paint_group(_state, BLOCK_RT_OFF_N, 2, false, sx, sy);
	if (_state.sub_disabled) official_block_paint_group(_state, BLOCK_RT_OFF_H, 2, true, sx, sy);
	if (_state.sub_active && _state.ok_subtract) official_block_subtract_pass(_state, shd_block_subtract, BLOCK_RT_ACTIVE_HP, BLOCK_RT_ACTIVE_H);
	if (_state.sub_ready && _state.ok_subtract_soft) official_block_subtract_pass(_state, shd_block_subtract_soft, BLOCK_RT_READY_HP, BLOCK_RT_READY_H);
	if (_state.sub_disabled && _state.ok_subtract_soft) official_block_subtract_pass(_state, shd_block_subtract_soft, BLOCK_RT_OFF_HP, BLOCK_RT_OFF_H);
	if (_state.on_active && _state.ok_compose) official_block_compose_active(_state, _now);
	if (_state.on_ready && _state.sub_ready && _state.ok_compose_plain) {
		official_block_compose_plain(_state, BLOCK_RT_READY_C, _state.norm_ready ? BLOCK_RT_READY_N : -1, BLOCK_RT_READY_HP);
	}
	if (_state.on_disabled && _state.sub_disabled && _state.ok_compose_plain) {
		official_block_compose_plain(_state, BLOCK_RT_OFF_C, _state.norm_disabled ? BLOCK_RT_OFF_N : -1, BLOCK_RT_OFF_HP);
	}
	if (_state.on_active && _state.ok_compose && _state.ok_glow) official_block_glow(_state);
	if (_state.hover_live && _state.ok_hover) official_block_paint_hover(_state);
	if ((_state.on_active || _state.on_ready || _state.hover_live) && _state.ok_pack_m && _state.ok_pack_e) {
		official_block_pack(_state);
	}
	if ((_state.on_active || _state.hover_live) && surface_exists(_chart)) official_block_copy_scene(_state, _chart);
}

///@desc 取谱面遮罩物体上的表面
///@returns {Real} 表面资源号，没有则为 -1
function official_block_chart_id() {
	// 物体或表面不在则无法绘制
	if (!instance_exists(oChartMask)) return -1;
	if (!surface_exists(oChartMask.surface_id)) return -1;
	return oChartMask.surface_id;
}

///@desc 在谱面表面上绘制本帧噪声区
///@returns {Undefined} 无
function official_blocks_draw() {
	// 结束阶段只复位着色器
	if (official_blocks_ending()) {
		shader_reset();
		return;
	}
	var state = official_blocks_ensure();
	// 跳过、未启用、未就绪或没有方块则不画
	if (state.skipped || !official_block_enabled() || !state.ready || state.empty || !state.preloaded) return;
	var loading = variable_global_exists("loading_animation_active") && global.loading_animation_active;
	var wants = false;
	var now = 0;
	var aspect = official_block_aspect();
	if (!loading && official_block_view_ready() && variable_global_exists("game") && is_struct(game) && is_array(game[$ "__time"]) && array_length(game.__time) >= 2 && is_real(game.__time[1])) {
		now = game.__time[1];
		// 加载中、视口未好或完全在显示区间外则不收集
		var outside = now < state.first_appear || now >= state.last_disappear;
		if (!(outside && !state.hover_live && array_length(state.blocked_ids) == 0)) {
			if (outside) official_block_hide(state);
			else official_block_gather(state, now, aspect);
			var frame_dt = delta_time / 1000000;
			// 录像按固定帧长走，不跟这一帧的真实耗时。
			if (variable_global_exists("render_mode") && global.render_mode
				&& variable_global_exists("render_fps") && is_real(global.render_fps) && global.render_fps > 0) {
				frame_dt = 1 / global.render_fps;
			}
			if (!is_real(frame_dt) || frame_dt < 0) frame_dt = 0;
			// 帧间隔限制在 0.05 秒内，避免悬停跳变
			if (frame_dt > 0.05) frame_dt = 0.05;
			official_block_input(state, aspect, frame_dt);
			wants = state.need_gpu || state.hover_live;
		}
	}
	// 这一帧不需要画且已经预热过则返回
	if (!wants && state.gpu_warm) return;
	if (!variable_global_exists("chart_surface_active") || !chart_surface_active) return;
	var chart_id = official_block_chart_id();
	if (chart_id == -1) return;
	pls_draw_flush();
	surface_reset_target();
	var restored = false;
	gpu_push_state();
	try {
		if (!official_block_pixels(state)) {
			// 这一帧表面不可用
		} else {
			if (!state.gpu_warm) official_block_gpu_warm(state);
			if (wants && state.gpu_warm) {
				var full_w = surface_get_width(chart_id);
				var full_h = surface_get_height(chart_id);
				if (full_w > 1 && full_h > 1 && official_block_rt_ensure(state, full_w, full_h)) {
					official_block_offscreen(state, chart_id, now);
					surface_set_target(chart_id);
					restored = true;
					official_block_present(state, now, full_w, full_h);
				}
			}
		}
	} finally {
		// 离开这段时若表面还没绑回去，这里补绑
		if (!restored && surface_exists(chart_id)) surface_set_target(chart_id);
		shader_reset();
		gpu_pop_state();
		shader_reset();
	}
}
