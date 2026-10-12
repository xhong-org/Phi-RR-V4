///@desc 向数组末尾追加一个值；useArr 为真时按元素展开追加
///@param {Array} array 需要追加的目标数组
///@param {Any} value 要追加的值，或待展开的数组
///@param {Bool} useArr 为真且 value 是数组时逐项插入
///@returns {Array} 追加后的原数组
function array_add(array , value , useArr = false){
	var len = (array_length(array));
	if(useArr && is_array(value)){
		// 把 value 的元素依次插到目标数组末尾
		var i = 0,
			_len = (array_length(value));
		do{
			array_insert(array , len + i, value[i]);
			i ++;
		}until(i >= (_len - 1));
	}else array_insert(array , len , value);
	
	return(array);
}