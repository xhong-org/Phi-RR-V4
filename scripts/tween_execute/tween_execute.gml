/* ended */

///@desc 按时间区间和缓动类型插值
///@param {Real} _t 当前时间
///@param {Real} _t0 开始时间
///@param {Real} _t1 结束时间
///@param {Real} _v0 开始值
///@param {Real} _v1 结束值
///@param {Real} _ei 缓动类型
///@param {Real} _e0 缓动区间左端
///@param {Real} _e1 缓动区间右端
///@returns {Real} 插值结果
function tween_execute(_t, _t0, _t1, _v0, _v1, _ei = EASE.LINEAR, _e0 = 0, _e1 = 1) {
	///@desc 把归一化进度查进预采样缓动表
	///@param {Real} _easing 缓动类型
	///@param {Real} _progress 归一化进度
	///@returns {Real} 缓动后的进度
	static _get_ease_progress = (function(_easing = EASE_TYPE.LINEAR, _progress = 0) {
		static _ease_infors = (__PCRTWEEN__());
		if (_progress < 0) then return(0);
		elif (_progress > 1) then return(1);
		// 线性、越界或缺失的表按原进度取样，这些项在 __PCRTWEEN__ 里是 undefined。
		if (!is_real(_easing) || _easing <= EASE_TYPE.LINEAR || _easing >= array_length(_ease_infors) || !is_array(_ease_infors[_easing])) {
			return(_progress);
		};
		var _progress_fixed = (100 * _progress), _progress_int = (int32(_progress_fixed));
		if (_progress_int < 0) then _progress_int = 0;
		if (_progress_int > 100) then _progress_int = 100;
		var _ease_node_0 = (_ease_infors[_easing][_progress_int]);
		if (_progress_int >= 100) then return(_ease_node_0);
		var _ease_node_1 = (_ease_infors[_easing][_progress_int + 1]);
		return((_ease_node_1 - _ease_node_0) * (_progress_fixed - _progress_int) + _ease_node_0);
	});
	
	if ((_t0 == _t1) || (_v0 == _v1)) {
		return(_v1); // 起止相同则直接取终值
	}  else {
		if (_e0 == _e1) {
			if (_ei == EASE_TYPE.LINEAR) then return(lerp(_v0, _v1, _e0)); // 端点重合时按该点线性取样
			else return(lerp(_v0, _v1, (_get_ease_progress(_ei, _e0)))); // 端点重合时按该点缓动取样
		} else {
			var _progress = ((_t - _t0) / (_t1 - _t0));
			if (_ei == EASE_TYPE.LINEAR) {
				return(lerp(_v0, _v1, _progress)); // 线性插值
			} else {
				var _val_left  = (_get_ease_progress(_ei, _e0)), _val_right = (_get_ease_progress(_ei, _e1));
				if (_val_right == _val_left) {
					return(lerp(_v0, _v1, _val_left)); // 缓动两端相同
				} else {
					var _mapped = (_e0 + (_e1 - _e0) * _progress);
					var _val = (_get_ease_progress(_ei, _mapped));
					return(lerp(_v0, _v1, ((_val - _val_left) / (_val_right - _val_left)))); // 把进度重映射到缓动区间
				};
			};
		};
	};
};

/* began */