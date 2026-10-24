// RPE 判定线事件的共用预处理。
// META.RPEVersion >= 170 使用 PhiEdit 1.7 的 floorPositionAt：每层对缓动速度积分
// （线性用闭式，其余用 20 步辛普森）。
// 更旧的谱，以及没有 RPEVersion 的文件，使用 170 之前的播放器表：
// 切开重叠、切点之间按线性速度，再对时间做梯形积分。
// 播放时再除以 4.5，使音符距离仍落在原有 floor 单位。
// 旧的原生梯形拟合没有实现这两种积分。

#macro RPE_LINE_PREP_NATIVE false

///@desc 把谱面缓动号映射到播放用的缓动序号
///@param {Real} raw 谱面 easingType
///@returns {Real} 播放缓动序号，无法识别时为 1
function rpe_map_easing_id(raw) {
	static map = [ 0, 1, 3, 2, 6, 5, 4, 7, 9, 8, 12, 11, 10, 13, 15, 14, -1, 17, 16, -1, 19, 18, 22, 21, 20, 23, 25, 24, -1, 27, 26, 28 ];
	var t = floor(real(raw ?? 1));
	// 线性及更小的号不需要映射
	if (!is_real(t) || t <= 1) then return 1;
	var n = array_length(map);
	for (var i = 0; i < n; i++) {
		if (is_real(map[i]) && map[i] == t) {
			if (i <= 1) then return 1;
			// 表外或占位项退回线性
			if (i >= 32) then return 1;
			return i;
		};
	};
	return 1;
}

///@desc 按开始时间、再按结束时间比较事件
///@param {Struct} a 左事件
///@param {Struct} b 右事件
///@returns {Real} 小于为 -1，大于为 1，相等为 0
function rpe_event_time_cmp(a, b) {
	if (a.startTime < b.startTime) then return -1;
	if (a.startTime > b.startTime) then return 1;
	if (a.endTime < b.endTime) then return -1;
	if (a.endTime > b.endTime) then return 1;
	return 0;
}

///@desc 识别整条数值通道的常量；动态通道返回 undefined
///@param {Array} _events 已整理的事件
///@returns {Any} 常量或 undefined
function rpe_event_constant(_events) {
	if (!is_array(_events) || array_length(_events) <= 0) return 0;
	var value = _events[0].start;
	if (!is_real(value) || !is_finite(value)) return undefined;
	for (var i = 0; i < array_length(_events); i++) {
		if (_events[i].start != value || _events[i][$ "end"] != value) return undefined;
	}
	return value;
}

///@desc 整理事件数组；速度事件保留缓动，其余换成绝对秒
///@param {Array} arr 原始事件
///@param {Bool} is_speed 是否为速度事件
///@returns {Array} 整理后的事件
function rpe_prep_event_array(arr, is_speed) {
	if (!is_array(arr)) then return [];
	if (is_speed) {
		// 保留谱面缓动。PhiEdit 按事件顺序积分，不会把重叠改成切点间的直线。
		var prepared = [];
		for (var si = 0; si < array_length(arr); si++) {
			var src = arr[si];
			if (!is_struct(src)) then continue;
			var st = game_1.Math.arrToBeat(src[$ "startTime"] ?? 0);
			var et = game_1.Math.arrToBeat(src[$ "endTime"] ?? st);
			var sv = real(src[$ "start"] ?? 0);
			var end_value = real(src[$ "end"] ?? sv);
			if (!is_finite(sv)) then sv = 0;
			if (!is_finite(end_value)) then end_value = sv;
			var speed_easing = floor(real(src[$ "easingType"] ?? 1));
			if (!is_finite(speed_easing)) then speed_easing = 1;
			var speed_easing_left = real(src[$ "easingLeft"] ?? 0);
			var speed_easing_right = real(src[$ "easingRight"] ?? 1);
			if (!is_finite(speed_easing_left)) then speed_easing_left = 0;
			if (!is_finite(speed_easing_right)) then speed_easing_right = 1;
			array_add(prepared, {
				startTime:st, endTime:et, start:sv, stop:end_value,
				easingType:speed_easing, easingLeft:speed_easing_left, easingRight:speed_easing_right
			});
		};
		array_sort(prepared, rpe_event_time_cmp);
		return prepared;
	};
	var cleaned = [];
	for (var i = 0; i < array_length(arr); i++) {
		var ev = arr[i];
		if (!is_struct(ev)) then continue;
		if (struct_exists(ev, "startTime")) then ev.startTime = game_1.Math.beatToAbsSec(game_1.Math.arrToBeat(ev.startTime));
		if (struct_exists(ev, "endTime")) then ev.endTime = game_1.Math.beatToAbsSec(game_1.Math.arrToBeat(ev.endTime));
		var el = ev[$ "easingLeft"] ?? 0;
		var er = ev[$ "easingRight"] ?? 1;
		// 窗口非法或左右重合时退回整段缓动
		if ((el == er) || (el < 0) || (el > 1) || (er < 0) || (er > 1)) {
			el = 0; er = 1;
		};
		ev.easingLeft = el;
		ev.easingRight = er;
		ev.easingType = rpe_map_easing_id(ev[$ "easingType"] ?? 1);
		if (!struct_exists(ev, "bezier")) then ev.bezier = 0;
		if (!struct_exists(ev, "bezierPoints")) then ev.bezierPoints = [0, 0, 0, 0];
		if (!struct_exists(ev, "start")) then ev.start = 0;
		if (!struct_exists(ev, "end")) then ev[$ "end"] = ev.start;
		array_push(cleaned, ev);
	};
	array_sort(cleaned, rpe_event_time_cmp);
	return cleaned;
}

// 对应 PhiEdit 的 Easing.cpp。类型号是谱面 easingType，不是播放 tween 表（那张表交换了若干 in/out）。
///@desc 小整数指数用连乘，负底的非整数指数返回 0
///@param {Real} base 底数
///@param {Real} exp 指数
///@returns {Real} 幂
function rpe_ease_pow(base, exp) {
	var n = floor(exp);
	// 0 到 8 的整数指数避免 power 的符号问题
	if (n == exp && n >= 0 && n <= 8) {
		var value = 1;
		repeat (n) value *= base;
		return value;
	};
	if (base < 0) then return 0;
	return power(base, exp);
}

///@desc 计算 ease-out 弹跳曲线
///@param {Real} x 0 到 1 的进度
///@returns {Real} 缓动结果
function rpe_ease_out_bounce(x) {
	var n1 = 7.5625;
	if (x < 0.36363636363636365) then return n1 * x * x;
	if (x < 0.7272727272727273) {
		x -= 0.5454545454545454;
		return n1 * x * x + 0.75;
	};
	if (x < 0.9090909090909091) {
		x -= 0.8181818181818182;
		return n1 * x * x + 0.9375;
	};
	x -= 0.9545454545454546;
	return n1 * x * x + 0.984375;
}

///@desc 按谱面缓动号计算未裁剪的缓动值
///@param {Real} type 谱面 easingType
///@param {Real} x 0 到 1 的进度
///@returns {Real} 缓动结果，未知类型返回 x
function rpe_ease_value(type, x) {
	var ease_pi = 3.14159265358979;
	var c1 = 1.70158;
	var c2 = 2.5949095;
	var c3 = 2.70158;
	var c4 = 2.0943951023931935;
	var c5 = 1.3962634015954623;
	// 未知类型落到函数末尾，按线性返回 x
	switch (type) {
		case 1: return x;
		case 2: return sin(x * ease_pi * 0.5);
		case 3: return 1 - cos(x * ease_pi * 0.5);
		case 4: return 1 - (1 - x) * (1 - x);
		case 5: return x * x;
		case 6: return -(cos(ease_pi * x) - 1) * 0.5;
		case 7: return (x < 0.5) ? (2 * x * x) : (1 - rpe_ease_pow(-2 * x + 2, 2) * 0.5);
		case 8: return 1 - rpe_ease_pow(1 - x, 3);
		case 9: return x * x * x;
		case 10: return 1 - rpe_ease_pow(1 - x, 4);
		case 11: return x * x * x * x;
		case 12: return (x < 0.5) ? (4 * x * x * x) : (1 - rpe_ease_pow(-2 * x + 2, 3) * 0.5);
		case 13: return (x < 0.5) ? (8 * x * x * x * x) : (1 - rpe_ease_pow(-2 * x + 2, 4) * 0.5);
		case 14: return 1 - rpe_ease_pow(1 - x, 5);
		case 15: return x * x * x * x * x;
		case 16: return (x == 1) ? 1 : (1 - power(2, -10 * x));
		case 17: return (x == 0) ? 0 : power(2, 10 * x - 10);
		case 18: return sqrt(1 - rpe_ease_pow(x - 1, 2));
		case 19: return 1 - sqrt(1 - rpe_ease_pow(x, 2));
		case 20: return 1 + c3 * rpe_ease_pow(x - 1, 3) + c1 * rpe_ease_pow(x - 1, 2);
		case 21: return c3 * x * x * x - c1 * x * x;
		case 22: return (x < 0.5) ? ((1 - sqrt(1 - rpe_ease_pow(2 * x, 2))) * 0.5) : ((sqrt(1 - rpe_ease_pow(-2 * x + 2, 2)) + 1) * 0.5);
		case 23: return (x < 0.5)
			? (rpe_ease_pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2) * 0.5)
			: ((rpe_ease_pow(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) * 0.5);
		case 24:
			if (x == 0 || x == 1) then return x;
			return power(2, -10 * x) * sin((x * 10 - 0.75) * c4) + 1;
		case 25:
			if (x == 0 || x == 1) then return x;
			return -power(2, 10 * x - 10) * sin((x * 10 - 10.75) * c4);
		case 26: return rpe_ease_out_bounce(x);
		case 27: return 1 - rpe_ease_out_bounce(1 - x);
		case 28: return (x < 0.5) ? ((1 - rpe_ease_out_bounce(1 - 2 * x)) * 0.5) : ((1 + rpe_ease_out_bounce(2 * x - 1)) * 0.5);
		case 29:
			if (x == 0 || x == 1) then return x;
			var s = sin((20 * x - 11.125) * c5);
			if (x < 0.5) then return -(power(2, 20 * x - 10) * s) * 0.5;
			return power(2, 10 - 20 * x) * s * 0.5 + 1;
	};
	return x;
}

// RPE 1.7 之前保存的谱（以及没有 RPEVersion 的文件）不对非线性速度缓动做积分。
// PhiEdit 1.7 本身始终用 floorPositionAt；META.RPEVersion < 170 时播放器仍用旧拟合。
///@desc 判断速度是否走 170 之前的旧表
///@returns {Bool} 版本低于 170 时为真
function rpe_speed_uses_legacy() {
	var version = 0;
	if (variable_global_exists("game_1") && is_struct(game_1)) {
		version = real(game_1[$ "version"] ?? 0);
	};
	// 读不到版本时按旧谱处理
	if (!is_finite(version)) then version = 0;
	return version < 170;
}

// 归一化 easeClipped：(ease(left + (right-left)*p) - ease(left)) / (ease(right) - ease(left))。
///@desc 在缓动窗口内把进度归一化到 0 到 1
///@param {Real} type 缓动号
///@param {Real} p 事件进度
///@param {Real} left 窗口左端
///@param {Real} right 窗口右端
///@returns {Real} 归一化缓动值，窗口无变化时返回 p
function rpe_ease_clipped(type, p, left, right) {
	var f0 = rpe_ease_value(type, left);
	var f1 = rpe_ease_value(type, right);
	var denom = f1 - f0;
	// 窗口两端缓动值相同则无法归一化
	if (abs(denom) < 0.000000000000001) then return p;
	var unit_x = clamp(p, 0, 1);
	return (rpe_ease_value(type, left + (right - left) * unit_x) - f0) / denom;
}

///@desc 用中心差分估计裁剪缓动的导数
///@param {Real} type 缓动号
///@param {Real} p 事件进度
///@param {Real} left 窗口左端
///@param {Real} right 窗口右端
///@returns {Real} 导数值，步长消失时为 0
function rpe_ease_clipped_derivative(type, p, left, right) {
	var eps = 0.000001;
	var x0 = clamp(p - eps, 0, 1);
	var x1 = clamp(p + eps, 0, 1);
	var span = x1 - x0;
	// 进度贴在端点时差分跨度为 0
	if (span < 0.0000000001) then return 0;
	return (rpe_ease_clipped(type, x1, left, right) - rpe_ease_clipped(type, x0, left, right)) / span;
}

// 1.7 之前的速度缓动。拟合 k、b，使 k*ease'(0)+b = v0 且 k*ease'(1)+b = v1，再对速度积分。
// 导数太平则退回平均速度。常量事件（v0 == v1）对任何缓动都返回 v0*p*duration。
///@desc 用导数拟合计算旧版速度事件的位移切片
///@param {Real} v0 起始速度
///@param {Real} v1 结束速度
///@param {Real} duration 时长
///@param {Real} p 进度
///@param {Real} easing 缓动号
///@param {Real} left 窗口左端
///@param {Real} right 窗口右端
///@returns {Real} 该切片的原始积分
function rpe_speed_legacy_slice(v0, v1, duration, p, easing, left, right) {
	var f0 = rpe_ease_value(easing, left);
	var f1 = rpe_ease_value(easing, right);
	// 缓动窗口没有变化时按起始速度匀速
	if (abs(f1 - f0) < 0.000000000000001) then return v0 * p * duration;
	var df0 = rpe_ease_clipped_derivative(easing, 0, left, right);
	var df1 = rpe_ease_clipped_derivative(easing, 1, left, right);
	var denom = df1 - df0;
	var k = 0;
	var b = (v0 + v1) * 0.5;
	if (is_finite(denom) && abs(denom) >= 0.00000001) {
		k = (v1 - v0) / denom;
		b = v0 - k * df0;
	};
	// 拟合出非数时退回平均速度
	if (!is_finite(k) || !is_finite(b)) {
		k = 0;
		b = (v0 + v1) * 0.5;
	};
	return (k * rpe_ease_clipped(easing, p, left, right) + b * p) * duration;
}

// 从事件起点积到进度 p（事件的 0 到 1）。
// 缓动 1 用闭式并忽略窗口，与 floorPositionAt 一致。RPE 1.7 对其余缓动用辛普森公式。
// 更旧的谱改用上面的导数拟合，而不是这个积分。
///@desc 计算速度事件从起点到进度 p 的积分
///@param {Real} v0 起始速度
///@param {Real} v1 结束速度
///@param {Real} duration 时长
///@param {Real} p 进度
///@param {Real} easing 缓动号
///@param {Real} left 窗口左端
///@param {Real} right 窗口右端
///@param {Any} integrate 逐线积分开关，undefined 按谱面版本选择
///@returns {Real} 原始积分，无效进度为 0
function rpe_speed_slice_integral(v0, v1, duration, p, easing, left, right, integrate = undefined) {
	// 非正进度或零时长没有位移
	if (!(p > 0) || !(duration > 0.000000001)) then return 0;
	// 线性缓动用闭式，不看窗口
	if (easing == 1) {
		return ((v1 - v0) * p * p * 0.5 + v0 * p) * duration;
	};
	// 旧谱不走辛普森积分
	if (is_undefined(integrate) ? rpe_speed_uses_legacy() : !integrate) {
		return rpe_speed_legacy_slice(v0, v1, duration, p, easing, left, right);
	};
	var h = p / 20;
	var f0 = rpe_ease_value(easing, left);
	var range = right - left;
	var denom = rpe_ease_value(easing, right) - f0;
	var integral = 0;
	if (abs(denom) >= 0.000000000000001) {
		var sum = (rpe_ease_value(easing, range * p + left) - f0) / denom;
		sum += (rpe_ease_value(easing, left) - f0) / denom;
		for (var odd_i = 1; odd_i < 20; odd_i += 2) {
			sum += ((rpe_ease_value(easing, odd_i * h * range + left) - f0) / denom) * 4;
		};
		for (var even_i = 2; even_i < 19; even_i += 2) {
			var sample = (rpe_ease_value(easing, even_i * h * range + left) - f0) / denom;
			sum += sample + sample;
		};
		integral = sum * h / 3;
	};
	return ((v1 - v0) * integral + v0 * p) * duration;
}

///@desc 把原始速度积分换成播放用的 floor 单位
///@param {Real} raw_integral 原始积分
///@returns {Real} 除以 4.5 后的地板增量
function rpe_speed_player_floor(raw_integral) {
	return raw_integral / 4.5;
}

///@desc 判断原生速度预处理扩展是否可用
///@returns {Bool} Windows 且扩展存在、宏开启时为真
function rpe_prep_native_ready() {
	return RPE_LINE_PREP_NATIVE && (os_type == os_windows) && extension_exists("I_RPEPrep");
}

///@desc 把 BPM 时间轴上传给原生预处理
///@returns {Bool} 已就绪或上传成功
function rpe_prep_upload_bpm() {
	if (!rpe_prep_native_ready()) then return false;
	if (variable_global_exists("game_1") && is_struct(game_1)
		// 本局已经上传过则不再写缓冲
		&& bool(game_1[$ "_rpe_prep_bpm_ready"] ?? false)) then return true;
	var tl = game_1.Math.ensureBpmTimeline();
	if (!is_array(tl) || array_length(tl) <= 0) then return false;
	var buf = buffer_create(4 + array_length(tl) * 32, buffer_fixed, 1);
	buffer_write(buf, buffer_u32, array_length(tl));
	for (var i = 0; i < array_length(tl); i++) {
		buffer_write(buf, buffer_f64, real(tl[i].startBeat));
		buffer_write(buf, buffer_f64, real(tl[i].endBeat));
		buffer_write(buf, buffer_f64, real(tl[i].bpm));
		buffer_write(buf, buffer_f64, real(tl[i].floorSec));
	};
	var ok = i_rpe_prep_set_bpm(buffer_get_address(buf), buffer_tell(buf)) != 0;
	buffer_delete(buf);
	if (ok && is_struct(game_1)) then game_1._rpe_prep_bpm_ready = true;
	return ok;
}

///@desc 把一层速度事件积分成带地板的秒时间段
///@param {Array} events 已整理的速度事件
///@returns {Struct} 事件段、尾部时间、尾速与尾地板
function rpe_build_speed_layer(events) {
	var built = [];
	var search_ends = [];
	var search_end = -infinity;
	var acc = 0;
	var prev_end = 0;
	var prev_value = real(events[0].start);
	var count = array_length(events);
	for (var ei = 0; ei < count; ei++) {
		var src = events[ei];
		var start_sec = game_1.Math.beatToAbsSec(src.startTime);
		var end_sec = game_1.Math.beatToAbsSec(src.endTime);
		// 时间无效的事件不参与积分
		if (!is_finite(start_sec) || !is_finite(end_sec)) then continue;
		// 前缀最大值单调；即使事件重叠，也能保留原来首个未结束项的选择。
		search_end = max(search_end, start_sec, end_sec);
		array_push(search_ends, search_end);
		var v0 = real(src.start);
		var v1 = real(src.stop);
		array_add(built, {
			startSec: start_sec,
			endSec: end_sec,
			v0: v0,
			v1: v1,
			easingType: real(src.easingType),
			easingLeft: real(src.easingLeft),
			easingRight: real(src.easingRight),
			prevEnd: prev_end,
			prevValue: prev_value,
			floorBefore: acc
		});
		// 事件之间的空隙沿用上一段结束速度
		if (start_sec > prev_end) then acc += rpe_speed_player_floor((start_sec - prev_end) * prev_value);
		var duration = end_sec - start_sec;
		if (duration > 0.000000001) {
			acc += rpe_speed_player_floor(rpe_speed_slice_integral(v0, v1, duration, 1, real(src.easingType), real(src.easingLeft), real(src.easingRight), true));
		};
		prev_value = v1;
		prev_end = end_sec;
	};
	return {
		events: built,
		searchEnds: search_ends,
		tailEnd: prev_end,
		tailSpeed: prev_value,
		tailFloor: acc
	};
}

///@desc 求一层速度在绝对秒 t 处的地板
///@param {Struct} layer rpe_build_speed_layer 的结果
///@param {Real} t 绝对秒
///@returns {Real} 地板位置
function rpe_layer_floor_at(layer, t) {
	if (!is_struct(layer)) then return 0;
	var events = layer.events;
	if (!is_array(events)) then return 0;
	var n = array_length(events);
	if (n <= 0) then return 0;
	if (!is_finite(t)) then return 0;
	// 原循环跳过的前缀满足 startSec < t 且 endSec < t。
	// 对两者的前缀最大值取 lower_bound，边界和重叠顺序都不变。
	var lo = 0;
	var hi = n;
	var search_ends = layer.searchEnds;
	while (lo < hi) {
		var mid = (lo + hi) div 2;
		if (search_ends[mid] < t) then lo = mid + 1;
		else hi = mid;
	}
	// 全部事件都已结束，用尾速外推
	if (lo >= n) {
		return layer.tailFloor + rpe_speed_player_floor((t - layer.tailEnd) * layer.tailSpeed);
	};
	var ev = events[lo];
	var acc = ev.floorBefore;
	if (ev.startSec > ev.prevEnd) {
		var gap_end = min(ev.startSec, t);
		if (gap_end > ev.prevEnd) then acc += rpe_speed_player_floor((gap_end - ev.prevEnd) * ev.prevValue);
	};
	// 还没进入本事件，只含空隙位移
	if (ev.startSec >= t) then return acc;
	var duration = ev.endSec - ev.startSec;
	if (duration > 0.000000001) {
		var p = (min(ev.endSec, t) - ev.startSec) / duration;
		acc += rpe_speed_player_floor(rpe_speed_slice_integral(ev.v0, ev.v1, duration, p, ev.easingType, ev.easingLeft, ev.easingRight, true));
	};
	return acc;
}

///@desc 用 GML 把各速度层积分成播放层
///@param {Array} speed_layers 每层的速度事件
///@returns {Array} 积分后的速度层
function rpe_build_speed_events_gml(speed_layers) {
	var out = [];
	for (var sli = 0; sli < array_length(speed_layers); sli++) {
		var speed_layer = speed_layers[sli];
		// 空层不生成积分
		if (!is_array(speed_layer) || array_length(speed_layer) <= 0) then continue;
		array_add(out, rpe_build_speed_layer(speed_layer));
	};
	return out;
}

///@desc 用原生扩展拟合速度事件
///@param {Array} speed_layers 每层的速度事件
///@returns {Array} 拟合段，失败为 undefined
function rpe_build_speed_events_native(speed_layers) {
	if (!rpe_prep_native_ready()) then return undefined;
	if (!rpe_prep_upload_bpm()) then return undefined;
	var in_buf = buffer_create(64, buffer_grow, 1);
	buffer_write(in_buf, buffer_u32, array_length(speed_layers));
	var event_n = 0;
	for (var sli = 0; sli < array_length(speed_layers); sli++) {
		var _layer = speed_layers[sli];
		buffer_write(in_buf, buffer_u32, array_length(_layer));
		event_n += array_length(_layer);
		for (var sei = 0; sei < array_length(_layer); sei++) {
			var ev = _layer[sei];
			buffer_write(in_buf, buffer_f64, real(ev.startTime));
			buffer_write(in_buf, buffer_f64, real(ev.endTime));
			buffer_write(in_buf, buffer_f64, real(ev.start));
			buffer_write(in_buf, buffer_f64, real(ev.stop));
		};
	};
	var out_cap = 4 + (event_n * 2 + 2) * 40;
	if (out_cap < 4096) then out_cap = 4096;
	var out_buf = buffer_create(out_cap, buffer_fixed, 1);
	var written = i_rpe_prep_speed_fit(buffer_get_address(in_buf), buffer_tell(in_buf), buffer_get_address(out_buf), buffer_get_size(out_buf));
	// 输出缓冲不够时放大一次再试
	if (!(is_real(written) && written >= 4)) {
		buffer_delete(out_buf);
		out_cap *= 4;
		out_buf = buffer_create(out_cap, buffer_fixed, 1);
		written = i_rpe_prep_speed_fit(buffer_get_address(in_buf), buffer_tell(in_buf), buffer_get_address(out_buf), buffer_get_size(out_buf));
	};
	buffer_delete(in_buf);
	if (!(is_real(written) && written >= 4)) {
		buffer_delete(out_buf);
		return undefined;
	};
	buffer_seek(out_buf, buffer_seek_start, 0);
	var n = buffer_read(out_buf, buffer_u32);
	// 声明的段数和实际写入长度对不上则放弃
	if (!(is_real(n) && n >= 0 && (4 + n * 40) <= written)) {
		buffer_delete(out_buf);
		return undefined;
	};
	var out = [];
	for (var i = 0; i < n; i++) {
		array_add(out, {
			startTime: buffer_read(out_buf, buffer_f64),
			endTime: buffer_read(out_buf, buffer_f64),
			value: buffer_read(out_buf, buffer_f64),
			endValue: buffer_read(out_buf, buffer_f64),
			floorPosition: buffer_read(out_buf, buffer_f64)
		});
	};
	buffer_delete(out_buf);
	return out;
}

// 170 之前的速度表。切开重叠，按拍在每层上线性取样（不积分速度缓动），
// 各层相加，再按秒做梯形积分。段上保存的值已经除以 4.5。
///@desc 在给定拍上线性取样一层旧速度
///@param {Array} layer 已截断的速度事件
///@param {Real} beat 拍
///@param {Bool} use_left_limit 恰好在起点时是否取左极限
///@returns {Real} 该层速度
function rpe_legacy_speed_value(layer, beat, use_left_limit) {
	if (!is_array(layer) || array_length(layer) <= 0) then return 0;
	var result = real(layer[0][$ "start"] ?? 0);
	var count = array_length(layer);
	for (var i = 0; i < count; i++) {
		var ev = layer[i];
		// 事件已按时间排序，更晚的不会再覆盖
		if (beat < ev.startTime) then break;
		// 左极限停在本事件开始之前
		if (use_left_limit && beat == ev.startTime) then break;
		if (beat >= ev.endTime) {
			result = real(ev.stop);
		} else {
			var span = ev.endTime - ev.startTime;
			if (span <= 0) then result = real(ev.stop);
			else result = real(ev.start) + (beat - ev.startTime) * ((real(ev.stop) - real(ev.start)) / span);
		};
	};
	return result;
}

///@desc 按时间切开重叠的旧速度事件
///@param {Array} arr 一层速度事件
///@returns {Array} 截断后的事件
function rpe_legacy_truncate_speed(arr) {
	var truncated = [];
	if (!is_array(arr)) then return truncated;
	var count = array_length(arr);
	for (var si = 0; si < count; si++) {
		var src = arr[si];
		if (!is_struct(src)) then continue;
		var st = real(src.startTime);
		var et = real(src.endTime);
		var sv = real(src.start);
		var end_value = real(src.stop);
		if (!is_finite(sv)) then sv = 0;
		if (!is_finite(end_value)) then end_value = sv;
		var delta = (et > st ? (end_value - sv) / (et - st) : 0);
		var speed_easing = rpe_map_easing_id(src[$ "easingType"] ?? 1);
		var speed_easing_left = real(src[$ "easingLeft"] ?? 0);
		var speed_easing_right = real(src[$ "easingRight"] ?? 1);
		if (!is_finite(speed_easing_left) || !is_finite(speed_easing_right)) {
			speed_easing_left = 0;
			speed_easing_right = 1;
		};
		speed_easing_left = clamp(speed_easing_left, 0, 1);
		speed_easing_right = clamp(speed_easing_right, 0, 1);
		if (speed_easing_left == speed_easing_right) {
			speed_easing_left = 0;
			speed_easing_right = 1;
		};

		for (var ti = array_length(truncated) - 1; ti >= 0; ti--) {
			var old = truncated[ti];
			var old_end = old.endTime;
			var old_stop = old.stop;
			// 旧段在新起点之前结束，补一段匀速空隙
			if (old_end < st) {
				array_set(truncated, ti + 1, {
					startTime: old_end, endTime: st,
					start: old_stop, stop: old_stop, delta: 0,
					easingType: 1, easingLeft: 0, easingRight: 1
				});
				break;
			};
			var old_start = old.startTime;
			// 起点重合则丢掉这条旧段
			if (old_start == st) {
				array_resize(truncated, ti);
				break;
			};
			// 新事件从旧段中部开始，把旧段截到该点
			if (old_start < st) {
				var old_value = old.start;
				var duration = st - old_start;
				var old_duration = old.endTime - old_start;
				var old_easing_left = real(old[$ "easingLeft"] ?? 0);
				var old_easing_right = real(old[$ "easingRight"] ?? 1);
				var cut_progress = (old_duration > 0 ? duration / old_duration : 1);
				old.stop = tween_execute(st, old_start, old.endTime, old_value, old.stop,
					real(old[$ "easingType"] ?? 1), old_easing_left, old_easing_right);
				old.endTime = st;
				old.delta = (duration > 0 ? (old.stop - old_value) / duration : 0);
				old.easingRight = lerp(old_easing_left, old_easing_right, cut_progress);
				array_resize(truncated, ti + 1);
				break;
			};
		};

		// 零长度事件记成瞬时速度
		if (st >= et) {
			array_add(truncated, {
				startTime: st, endTime: st, start: end_value, stop: end_value, delta: 0,
				easingType: 1, easingLeft: 0, easingRight: 1
			});
		} else {
			array_add(truncated, {
				startTime: st, endTime: et, start: sv, stop: end_value, delta: delta,
				easingType: speed_easing, easingLeft: speed_easing_left, easingRight: speed_easing_right
			});
		};
	};
	array_sort(truncated, rpe_event_time_cmp);
	return truncated;
}

///@desc 把多层旧速度合成梯形积分后的播放段
///@param {Array} event_layers 含 speedEvents 的事件层
///@returns {Array} 已除以 4.5 的速度段
function rpe_build_legacy_speed_table(event_layers) {
	var speed_layers = [];
	var speed_splits = [];
	if (is_array(event_layers)) {
		for (var sli = 0; sli < array_length(event_layers); sli++) {
			var raw_layer = (struct_exists(event_layers[sli], "speedEvents") ? event_layers[sli][$ "speedEvents"] : []);
			if (!is_array(raw_layer) || array_length(raw_layer) <= 0) then continue;
			var speed_layer = rpe_legacy_truncate_speed(raw_layer);
			if (array_length(speed_layer) <= 0) then continue;
			array_add(speed_layers, speed_layer);
			for (var sei = 0; sei < array_length(speed_layer); sei++) {
				array_add(speed_splits, speed_layer[sei].startTime);
				array_add(speed_splits, speed_layer[sei].endTime);
			};
		};
	};
	if (array_length(speed_splits) <= 0) then return [];
	array_sort(speed_splits, 
	///@desc 按拍比较切点
	///@param {Real} a 左切点
	///@param {Real} b 右切点
	///@returns {Real} 小于为 -1，大于为 1，相等为 0
	function(a, b) {
		if (a < b) then return -1;
		if (a > b) then return 1;
		return 0;
	});

	var fitted_speed = [];
	for (var ssi = 0; ssi < array_length(speed_splits) - 1; ssi++) {
		var split_start = speed_splits[ssi];
		var split_end = speed_splits[ssi + 1];
		// 重合切点不构成一段
		if (split_start == split_end) then continue;
		var value_start = 0;
		var value_end = 0;
		for (var sli2 = 0; sli2 < array_length(speed_layers); sli2++) {
			value_start += rpe_legacy_speed_value(speed_layers[sli2], split_start, false);
			value_end += rpe_legacy_speed_value(speed_layers[sli2], split_end, true);
		};
		array_add(fitted_speed, {
			startTime: split_start, endTime: split_end,
			start: value_start, stop: value_end
		});
	};

	var segments = [];
	var speed_floor = 0;
	var fitted_count = array_length(fitted_speed);
	for (var fsi = 0; fsi < fitted_count; fsi++) {
		var fitted = fitted_speed[fsi];
		var sample_start_sec = game_1.Math.beatToAbsSec(fitted.startTime);
		if (!is_finite(sample_start_sec)) then continue;
		var sample_end_sec = game_1.Math.beatToAbsSec(fitted.endTime);
		if (fsi < fitted_count - 1) {
			var next_start_sec = game_1.Math.beatToAbsSec(fitted_speed[fsi + 1].startTime);
			if (is_finite(next_start_sec) && next_start_sec > sample_start_sec) {
				sample_end_sec = next_start_sec;
			};
		};
		// 秒时间无效或倒退的段丢掉
		if (!is_finite(sample_end_sec) || sample_end_sec <= sample_start_sec) then continue;
		var v0 = real(fitted.start) / 4.5;
		var v1 = real(fitted.stop) / 4.5;
		array_add(segments, {
			startTime: sample_start_sec,
			endTime: sample_end_sec,
			value: v0,
			endValue: v1,
			floorPosition: speed_floor
		});
		// 梯形积分：时间乘两端速度的平均
		speed_floor += (sample_end_sec - sample_start_sec) * (v0 + v1) * 0.5;
	};
	if (array_length(segments) > 0) {
		var last_speed_ev = segments[array_length(segments) - 1];
		var last_end_value = real(last_speed_ev.endValue);
		if (is_finite(last_speed_ev.endTime)) {
			array_add(segments, {
				startTime: last_speed_ev.endTime,
				// 末段之后用结束速度一直延伸
				endTime: infinity,
				value: last_end_value,
				endValue: last_end_value,
				floorPosition: speed_floor
			});
		};
	};
	return segments;
}

///@desc 用梯形公式求旧速度段在时刻 t 的地板
///@param {Struct} ev 速度段
///@param {Real} t 绝对秒
///@returns {Real} 地板位置
function rpe_legacy_event_floor(ev, t) {
	var elapsed = max(0, real(t) - real(ev.startTime));
	var v0 = real(ev.value);
	var v1 = real(ev[$ "endValue"] ?? v0);
	var duration = real(ev.endTime) - real(ev.startTime);
	// 无时长时按起点速度外推
	if (!is_finite(duration) || duration <= 0) {
		return real(ev.floorPosition) + elapsed * v0;
	};
	var portion = min(1, elapsed / duration);
	var vt = v0 + (v1 - v0) * portion;
	return real(ev.floorPosition) + elapsed * (v0 + vt) * 0.5;
}

///@desc 在旧速度段表上求时刻 t 的地板
///@param {Array} segments 速度段
///@param {Real} t 绝对秒
///@returns {Real} 地板位置，早于首段为 0
function rpe_legacy_floor_at(segments, t) {
	if (!is_array(segments)) then return 0;
	var n = array_length(segments);
	if (n <= 0 || !is_real(t)) then return 0;
	// 首段之前没有地板
	if (t < segments[0].startTime) then return 0;
	var idx = 0;
	var hi = n - 1;
	// 旧表由已排序的切点生成，结束时间单调；等于终点仍选前一段。
	while (idx < hi) {
		var mid = (idx + hi) div 2;
		if (segments[mid].endTime < t) then idx = mid + 1;
		else hi = mid;
	}
	return rpe_legacy_event_floor(segments[idx], t);
}

///@desc 按逐线开关或谱面版本选择旧表或积分速度层
///@param {Array} event_layers 含 speedEvents 的事件层
///@param {Any} integrate PhiZone 逐线开关，省略时按版本选择
///@returns {Array} 播放用速度数据
function rpe_build_speed_events(event_layers, integrate = undefined) {
	// 旧谱走梯形表，新谱走每层积分
	var use_legacy = is_undefined(integrate) ? rpe_speed_uses_legacy() : !integrate;
	if (use_legacy) then return rpe_build_legacy_speed_table(event_layers);
	var speed_layers = [];
	if (is_array(event_layers)) {
		for (var sli = 0; sli < array_length(event_layers); sli++) {
			var speed_layer = (struct_exists(event_layers[sli], "speedEvents") ? event_layers[sli][$ "speedEvents"] : []);
			if (!is_array(speed_layer) || array_length(speed_layer) <= 0) then continue;
			array_add(speed_layers, speed_layer);
		};
	};
	if (array_length(speed_layers) <= 0) then return [];
	return rpe_build_speed_events_gml(speed_layers);
}
