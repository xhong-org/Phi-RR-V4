// v2.3.0的脚本资产已更改，请参见\ n // https://help.yoyogames.com/hc/en-us/articles/360005277377
function number(_num,_e_r_num = 0){
	try{
		//show_debug_message(_num);
		//if(is_real(real(_num)))
			return(real(_num));	
	}catch(_e){
		if(is_string(_num)){
			if(_num == "true") then return(true);
			elif(_num == "false") then return(false);
			else return(_e_r_num);
		};
		delete(_e);
		return(_e_r_num);
	};
};