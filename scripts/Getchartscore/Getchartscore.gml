// v2.3.0鐨勮剼鏈祫浜у凡鏇存敼锛岃鍙傝\ n // https://help.yoyogames.com/hc/en-us/articles/360005277377
function Getchartscore(){
	if (!is_real(maxcombo) || !is_finite(maxcombo) || maxcombo <= 0) then return("0000000");
	var _s,_t;
	//_mcombo = (_mcombo <= 0 ? 1 : _mcombo)
	//if(_chart_autoplay){
	var __combo = is_real(combo) && is_finite(combo) ? combo : 0;
	_s = (int64(1000000 * (__combo / maxcombo)));
	if (is_finite(_s)) then _s = (_s | 0);
	else _s = 0;
	//}
	var _l_scombo_ = (string_length(string(_s))),
		_scmrzero = (7 - _l_scombo_ <= 0 ? 0 : 7 - _l_scombo_),
		_t = "";
	repeat(_scmrzero){
		_t+="0";
	};
	_t += string(_s);
	return(_t);
};
/*
getScore = (function() { return(int64(1000000 * ((getCombo()) / _num_of_notes))) });
getFormattedScore = (function() {
	var _score = (getScore());
	_score += 0.5;
	if (is_finite(_score)) then _score = (_score | 0);
	else _score = (1 << 31);
	// if (_score >= 1000000) return("1000000");
	return(string_replace_all((string_format(_score, 7, 0)), " ", "0"));
});
*/
