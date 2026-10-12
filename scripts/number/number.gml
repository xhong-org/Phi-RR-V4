// v2.3.0 的脚本资产已更改，请参见
// https://help.yoyogames.com/hc/en-us/articles/360005277377
///@desc 把值转成实数，失败时返回备用值
///@param {Any} _num 待转换的值
///@param {Any} _e_r_num 转换失败时的备用值
///@returns {Any} 实数、布尔，或备用值
function number(_num,_e_r_num = 0){
	try{
		//show_debug_message(_num);
		//if(is_real(real(_num)))
			return(real(_num));	
	}catch(_e){
		// 字符串里的 true 和 false 按布尔返回
		if(is_string(_num)){
			if(_num == "true") then return(true);
			elif(_num == "false") then return(false);
			else return(_e_r_num);
		};
		delete(_e);
		return(_e_r_num);
	};
};