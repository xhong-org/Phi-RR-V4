/* ended */

/// @desc                       兼容
/// @arg    {Real}              nowTime   当前时间
/// @arg    {Real}              startTime 开始时间
/// @arg    {Real}              endTime   结束时间
/// @arg    {Real}              start     开始值
/// @arg    {Real}              end       结束值
/// @arg    {Constant.EaseType} easeType  缓动类型
/// @arg    {Real}              easeHead  缓动头偏移
/// @arg    {Real}              easeTail  缓动尾偏移
/// @return {Real}
function tween_execute(_t, _t0, _t1, _v0, _v1, _ei = EASE.LINEAR, _e0 = 0, _e1 = 1) {
	static _get_ease_progress = (function(_easing = EASE_TYPE.LINEAR, _progress = 0) {
		static _ease_infors = (__PCRTWEEN__());
		if (_progress < 0) then return(0);
		elif (_progress > 1) then return(1);
		// 0/1 and missing tables are LINEAR samples (undefined in __PCRTWEEN__).
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
		return(_v1); // 
	}  else {
		if (_e0 == _e1) {
			if (_ei == EASE_TYPE.LINEAR) then return(lerp(_v0, _v1, _e0)); // 
			else return(lerp(_v0, _v1, (_get_ease_progress(_ei, _e0)))); // 
		} else {
			var _progress = ((_t - _t0) / (_t1 - _t0));
			if (_ei == EASE_TYPE.LINEAR) {
				return(lerp(_v0, _v1, _progress)); // 
			} else {
				var _val_left  = (_get_ease_progress(_ei, _e0)), _val_right = (_get_ease_progress(_ei, _e1));
				if (_val_right == _val_left) {
					return(lerp(_v0, _v1, _val_left)); // 
				} else {
					var _mapped = (_e0 + (_e1 - _e0) * _progress);
					var _val = (_get_ease_progress(_ei, _mapped));
					return(lerp(_v0, _v1, ((_val - _val_left) / (_val_right - _val_left)))); // 
				};
			};
		};
	};
};

/* began */