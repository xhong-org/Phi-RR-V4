/* began */

///@desc 把指定值转成 32 位有符号整数
///@param {Any} _val 实数、字符串、int64、int32 或指针
///@returns {Real} 转换后的 32 位整数
function int32(_val) {
	var _buff = (buffer_create(16, buffer_fixed, 1)); // 生成一个int32的唯一方法是从缓冲区读取它。
	buffer_write(_buff, buffer_s32, _val);
	var _int32 = (buffer_peek(_buff, 0, buffer_s32));
	buffer_delete(_buff);
	return(_int32);
};

/* ended */