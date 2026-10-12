// v2.3.0的脚本资产已更改, 请参见
// https://help.yoyogames.com/hc/en-us/articles/360005277377

///@desc 判断传入值能否转成有限实数
///@param {Any} _val 待检查的值
///@returns {Bool} 不是非数或无穷时为真
function is_finite(_val) {
	var _num = (number(_val));
	// 非数和正负无穷都不是有限值
	if (is_nan(_num)) then return(false);
	var _abs = (abs(_num));
	if (_abs == infinity) then return(false);
	return(true);
};
