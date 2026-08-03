/* began */

/// 事件。
function CEvents() constructor {
	// 内部数组
	array = (array_create(0));
	
	// 缓存
	index = (int64(0)); // 索引
	value = 0; // 值
	
	/// @desc 新事件
	/// @arg  {Real} startTime d0
	/// @arg  {Real} start d1
	/// @arg  {Real} endTime d2
	/// @arg  {Real} end d3
	/// @arg  {Real} easing i0
	/// @arg  {Real} easeLeft d4
	/// @arg  {Real} easeRight d5
	static add = (function(d0, d1, _d2 = undefined, _d3 = undefined, _i0 = EASE_TYPE.LINEAR, _d4 = 0, _d5 = 1, _sb = undefined) { // d0(startTime), d1(start), [d2(endTime)], [d3(end)]
		var _event = ({ d0, d1 });
		if ((is_numeric(_d2)) && (is_numeric(_d3))) {
			if ((_d2 != d0) && (_d3 != d1)) {
				(_event.d2) = _d2;
				(_event.d3) = _d3;
				if ((_i0 > EASE_TYPE.LINEAR) && (_i0 < EASE_TYPE.__SIZE__)) {
					(_event.i0) = _i0;
					if (_d4 != 0) then (_event.d4) = _d4;
					if (_d5 != 1) then (_event.d5) = _d5;
					// if (_i0 == EASE_TYPE.BEZIER) {}; // TODO
				};
			};
		};
		array_add(array, _event);
	});
	
	/// 重置
	static reset = (function() {
		index = (int64(0));
		value = 0;
	});
	
	/// 排序
	static sort = (function() { array_sort(array, (function(_0, _1) { return(sign((_0.d0) - (_1.d0))); })) });
	
	/// 缓动
	static _get_ease_progress = (function(_easing = EASE_TYPE.LINEAR, _progress = 0) {
		static _ease_infors = (__PCRTWEEN__());
		if (_progress < 0) then return(0);
		elif (_progress > 1) then return(1);
		var _progress_fixed = (100 * _progress), _progress_int = (int32(_progress_fixed));
		var _ease_node_0 = (_ease_infors[_easing][_progress_int]);
		if (_progress_int >= 100) then return(_ease_node_0);
		var _ease_node_1 = (_ease_infors[_easing][_progress_int + 1]);
		return((_ease_node_1 - _ease_node_0) * (_progress_fixed - _progress_int) + _ease_node_0);
	});
	
	/// 计算
	/// @arg {Real} t
	static execute = (function(_t) {
		var _len = (array_length(array));
		if (!_len) then return(value); // 空
		
		// 判断范围
		var _e_f = (array[0]); // 事件0
		if (_t <= (_e_f.d0)) {
			value = (_e_f.d1);
			return(value); // 返回第一个值
		};
		var _e_l = (array_last(array)); // 事件N
		if (_t >= ((_e_l[$ "d2"]) ?? (_e_l.d0))) {
			value = ((_e_l[$ "d3"]) ?? (_e_l.d1));
			return(value); // 返回第N个值
		};
		
		// 主循环
		if (index < _len) {
			// value = _e_f.d1; // Test
			var _i = index; repeat(_len - _i) { var _e = (array[_i ++]);
				// 流程1
				var
					_t0 = (_e.d0), // 起始时间
					_v0 = (_e.d1), // 起始值
					_t1 = ((_e[$ "d2"]) ?? (_t0)), // 终止时间
					_v1 = ((_e[$ "d3"]) ?? (_v0)), // 终止值
					_ei = ((_e[$ "i0"]) ?? (EASE_TYPE.LINEAR)),
					_e0 = ((_e[$ "d4"]) ?? (0)),
					_e1 = ((_e[$ "d5"]) ?? (1)),
					_sb = undefined // TODO
				; 
				if (_t >= _t1) {
					index = _i;
					value = _v1;
					continue;
				}; // 超终止范围
			
				// 流程2
				if (_t >= _t0) {
					if ((_t0 == _t1) || (_v0 == _v1)) {
						value = _v1; // 瞬时事件
					}  else {
						if (_e0 == _e1) {
							if (_ei == EASE_TYPE.LINEAR) then value = (lerp(_v0, _v1, _e0)); // 点
							else value = (lerp(_v0, _v1, (_get_ease_progress(_ei, _e0)))); // 点
						} else {
							var _progress = ((_t - _t0) / (_t1 - _t0));
							if (_ei == EASE_TYPE.LINEAR) {
								value = (lerp(_v0, _v1, _progress)); // 线性事件
							} else {
								var _val_left  = (_get_ease_progress(_ei, _e0)), _val_right = (_get_ease_progress(_ei, _e1));
								if (_val_right == _val_left) {
									value = (lerp(_v0, _v1, _val_left)); // 点
								} else {
									var _mapped = (_e0 + (_e1 - _e0) * _progress);
									var _val = (_get_ease_progress(_ei, _mapped));
									value = (lerp(_v0, _v1, ((_val - _val_left) / (_val_right - _val_left)))); // 缓动事件
								};
							};
						};
					};
				};
			
				// 中断循环
				break;
			};
		};
		
		//
		return(value);
	});
};

/* ended */