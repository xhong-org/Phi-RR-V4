// v2.3.0的脚本资产已更改, 请参见
// https://help.yoyogames.com/hc/en-us/articles/360005277377

/// @desc      判断被传入的参数值是否为一个有限数值
/// @arg {Any} val
function is_finite(_val) {
	var _num = (number(_val));
	if (is_nan(_num)) then return(false);
	var _abs = (abs(_num));
	if (_abs == infinity) then return(false);
	return(true);
};
