/* began */

/// @desc              该函数将尝试将指定值转换为32位整数。其中，该值必须为实数、字符串、int64、int32或ptr之一。其他任何内容都可能导致游戏崩溃并出现错误信息。
/// @arg    {Any}  val 要转换的值
/// @return {Real}
function int32(_val) {
	var _buff = (buffer_create(16, buffer_fixed, 1)); // 生成一个int32的唯一方法是从缓冲区读取它。
	buffer_write(_buff, buffer_s32, _val);
	var _int32 = (buffer_peek(_buff, 0, buffer_s32));
	buffer_delete(_buff);
	return(_int32);
};

/* ended */