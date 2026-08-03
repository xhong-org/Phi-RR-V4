///@desc
///@param array {Array} 需要添加值的数组
///@param value {Any} Any

function array_add(array , value , useArr = false){
	var len = (array_length(array));
	if(useArr && is_array(value)){
		var i = 0,
			_len = (array_length(value));
		do{
			array_insert(array , len + i, value[i]);
			i ++;
		}until(i >= (_len - 1));
	}else array_insert(array , len , value);
	
	return(array);
}