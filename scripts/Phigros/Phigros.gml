// 闂備礁鎼ˇ顖炴偋閸℃稑绠犻幖娣灪閸欏繑銇勮箛鎾搭棏闁稿鎹囬幃鐑藉箥椤旂虎鍞堕梻浣虹帛閻楁洟鎮ユ總绋胯摕?
#macro print LogOutputFile
#macro elif else if
#macro func function
#macro isExists file_exists
#macro InChartPath (variable_global_exists("chart_active_path") && is_string(global.chart_active_path) && string_length(global.chart_active_path) ? global.chart_active_path : (working_directory + "chart/"))
#macro VerReal 40494
#macro VerStr "v.4.0.8"
#macro GAME_NAME "Re: Phi-RR - " + VerStr
#macro HYW_MODE true
#macro BYD_COLOR_MODE true
#macro BYD_COLOR_FUNC if(BYD_COLOR_MODE && PhiTime) then image_blend = (make_colour_hsv( (game.__time[1] * 50) % 255  , 255  , 255 ))


/// @desc YYC-safe sprite validity: accepts numeric ids and modern asset refs
function asset_sprite_valid(_id) {
	if (is_undefined(_id)) then return false;
	if (is_string(_id)) then return false;
	// Failed sprite_add traditionally returns -1
	if (is_real(_id) && _id < 0) then return false;
	return sprite_exists(_id);
}

/// @desc YYC-safe font validity
function asset_font_valid(_id) {
	if (is_undefined(_id)) then return false;
	if (is_string(_id)) then return false;
	if (is_real(_id) && _id < 0) then return false;
	return font_exists(_id);
}



// 濠电姷鏁搁崑鐐差焽濞嗘搩鏁勯柛顐犲劜閸庡﹥銇勯弽銊с€掓い鈺冨厴閺屻劌鈹戦崱妯虹獩闂?闂備浇顕ф绋匡耿闁秴纾婚柕鍫濐槹閸嬫ɑ绻涢崱妯诲碍缂?
//scheduler_resolution_set(800000000000);
//gpu_set_texfilter(true);
gml_release_mode(true);
//gml_pragma("forceinline");

//string_format()
// 闂傚倷鐒﹂幃鍫曞磿閺屻儱纾块柟鎯板Г閸庢垵霉閸忓吋缍戦柛鎴犲У閹便劌顫滈崱妞剧盎濡?
enum DEPTH {
	DEBUG = -15000,
	LINE = -3000,
	NOTE = -7000,
	HEF = -11000,
	BG = -100
};


enum TYPE {
	PREFECT,
	GOOD,
	MISS,
	BAD,
	NONE
};



//display_set_timing_method(tm_systemtiming);
//display_reset(0 , true);



// 婵犵妲呴崑鍡樻櫠濡ゅ啯宕查柛宀€鍊涢崶銊х瘈婵﹩鍓涢悡鎴︽⒑缁嬫寧婀扮紒瀣笒閳?
var cmd_count = (parameter_count());

if(cmd_count){	
	for(var ci = 1 ; ci < cmd_count ; ci ++){
		var _cmd = (parameter_string(ci));
		switch(_cmd){
			case "-debug":
				MsgBox_Info("Enable Debugger." , "Infomation"); //show_message_async("")
			break;
		
			case "-easing":
				if(ci < cmd_count){
					ci ++;
					var _cmd2 = (parameter_string(ci));
					if(!variable_global_exists("easing_type_in_official")) { globalvar easing_type_in_official;  };
					variable_global_set("easing_type_in_official" , _cmd2);
				};
			break;
		};
	};
}else{
	if(!variable_global_exists("easing_type_in_official")) { globalvar easing_type_in_official;  };
	variable_global_set("easing_type_in_official" , 10);
};

//func G_Configs() constructor{
//	static folder_chart = { 
//		"name" : "Unknown",
//		"level" : "SP Lv.?",
//		"music" : "",
//		"chart" : "",
//		"bg" : ""
//	};
	
//	static settings = {
//		"enableBlur" : false,
//		"enableFPS" : true,
//		"enableQuikyStart" : false,
//		"enableCanvasZoom" : false,
//		"enableSurface" : false,
//		"enableNoteHightLight" : false,
//		"enableChartGUI" : true,
//		"enableLineJudge" : false,
//		"showBG" : true,
//		"enableHitEffect" : true
//	};
	
//	///@desc 闂備浇顕х€涒晝绮欓幒妞尖偓鍐醇閵夘喗鏅炴繛杈剧到濠€閬嶅煝閺冨牊鐓犻柤瑙勬緲閻撴劗绱掓笟鍥ф珝闁哄备鍓濋幏鍛村传閵夛附鍠栭梻?//
//	static strToReal = (func(str , default_value = undefined){
//		if(string_lower(str) == "false") then return(0);
//		if(string_lower(str) == "true") then return(1);
//		if(string_lower(str) == "undefined") then return(undefined);
//		try{ return(real(str)) }
//		catch(e){ return(default_value) };
//	});
	
//	static realToStrBool = (func(_real){
//		if(!is_real(_real)) then return("undefined");
//		if(bool(_real) == true) then return("true");
//		else return("false");
//	});
//};

//room_speed = 120;

randomise();
// 缂傚倸鍊风拋鏌ュ磻閹捐绾ч柣鎰綑椤ュ霉?
var sval = "fweasfare",
	eval = "Hel";
show_debug_message(string_copy(sval, 1, string_length(eval))); 

///@desc 闂傚倷娴囧銊╂嚄閸撲焦宕叉繝闈涚墢缁€濠囨倵閿濆骸鏋涚紒鈧崱娑欑厱闁斥晛鍙愰幋婵冩灁闁割偅娲橀悡娑㈡煕椤愶絿绠栭柟顖氱墦閺?
function accCalc(){
	var aoc = (phi_state_list),
		counts = (aoc.prefect + aoc.good + aoc.miss + aoc.bad),
		_acc = (clamp((100 * ((aoc.prefect + (aoc.good * 0.65)) / counts)) , 0 , 100));
	if(is_nan(_acc)) then _acc = 100.0000;
	phi_state_list.acc = _acc;
	
	return(string(_acc));
};


///@desc 闂傚倷绀侀幉锛勬暜閸ヮ剙纾归柡鍥ュ灪閸?
function judgeCalc(oHTime , nHTime , bpm , xx , yy , _type , isFHitEf = true, insCombo = true, timeInSeconds = false, effectColor = undefined){
	var timer = (timeInSeconds ? real(oHTime) : game.Math.realTimer(bpm , oHTime)),
		ntimer = (timeInSeconds ? real(nHTime) : game.Math.realTimer(bpm , nHTime)),
		score_list = [ (max(timer , ntimer)), (min(timer , ntimer)) , (timer > ntimer) ],
		offset = (abs( (score_list[0] - score_list[1]) * 1000 )),
		color = #ffeca0,
		status = TYPE.NONE;
	if(offset >= -80 && offset <= 80){
		
		if(insCombo) then combo ++;
		if(phi_state_list.max_hitcombo < combo) then phi_state_list.max_hitcombo = combo;
		if(insCombo) then phi_state_list.prefect ++;
		color = #ffeca0;
		status = TYPE.PREFECT;
		
	}elif(offset > 80 && offset <= 160){
		
		if(_type == 3 || _type == 1){
			color = (make_colour_rgb(162, 238, 255));
			status = TYPE.GOOD;
			if(insCombo) then phi_state_list.good ++;
		}else{
			color = #ffeca0;
			status = TYPE.PREFECT;
			if(insCombo) then phi_state_list.prefect ++;
		};
		if(insCombo) then combo ++;
		if(phi_state_list.max_hitcombo < combo) then phi_state_list.max_hitcombo = combo;
		
	}elif(offset > 160 && offset <= 200 && (_type == 1 || _type == 3)){
		
		if(phi_state_list.max_hitcombo < combo) then phi_state_list.max_hitcombo = combo;
		if(insCombo) then combo = 0;
		if(_type == 1){
			if(insCombo) then phi_state_list.bad ++;
			status = TYPE.BAD;
		}else{
			if(insCombo) then phi_state_list.miss ++;
			status = TYPE.MISS;
		};
		
	}elif(offset > 200){
		//()
		if(!score_list[2]){
			if(phi_state_list.max_hitcombo < combo) then phi_state_list.max_hitcombo = combo;
			if(insCombo){
				combo = 0;
				phi_state_list.miss ++;
			};
			status = TYPE.MISS;
		}else{
			status = TYPE.NONE;	
		};
		
	};
	
	//print($"offset: 闂備礁鎲￠〃蹇撐ｉ埡鐜set}");
	
	if(isFHitEf && (status == TYPE.GOOD || status == TYPE.PREFECT)) then _eff_c(xx , yy , is_undefined(effectColor) ? color : effectColor);
	
	return(status);
};

function ScoreSystem(_mode = undefined){
	if(maxcombo <= 0) then return(-NaN);
	var mode;
	if(is_undefined(_mode)) then mode = (game.settings.enableComboScore)
	else mode = _mode;
	
	
	var _s,_t;
	var __combo = (phi_state_list);
	if(mode){
		_s = ((int64(900000 * ((__combo.prefect + (__combo.good * 0.65)) / maxcombo))) + (int64(100000 * (__combo.max_hitcombo / maxcombo))));
	}else{	
		_s = (int64(1000000 * ((__combo.prefect + (__combo.good * 0.65)) / maxcombo)));
	};
	
	if (is_finite(_s)) then _s = (_s | 0);
	else _s = (1 << 31);
	
	var _l_scombo_ = (string_length(string(_s))),
		_scmrzero = (7 - _l_scombo_ <= 0 ? 0 : 7 - _l_scombo_),
		_t = "";
	repeat(_scmrzero){
		_t+="0";
	};
	_t += string(_s);
	return(_t);	
};


///@desc 闂傚倷绀侀幖顐﹀磹缁嬫５娲晲閸涱亝鐎婚梺闈涚箚閹冲洭宕戦幘瀛樺闁告劖鍎冲▓顓炩攽閻愰潧甯堕柛鐔告綑閻?
function File_Discoverer(disc_path){
        var return_path = {
                "chart" : [],
                "music" : [],
                "image" : [],
                "text" : [],
                "shader" : [],
                "other" : []
        };
        if(!bool(string_length(disc_path))) then return(return_path);

        var root = string_replace_all(string(disc_path), "/", "\\");
        if(string_length(root) && string_char_at(root, string_length(root)) != "\\") then root += "\\";

        var directory_list = [ root ];
        var file_path_list = [];

        while(array_length(directory_list)){
                var n = array_length(directory_list);
                for(var i = 0; i < n; i++){
                        var path = directory_list[i];

                        // files
                        var file_name = file_find_first(path + "*", fa_none);
                        while(string_length(file_name)){
                                if(file_name != "." && file_name != ".."){
                                        var full_file = path + file_name;
                                        // skip directories accidentally returned without fa_directory
                                        if(file_exists(full_file) && !directory_exists(full_file)){
                                                array_add(file_path_list, string_replace_all(full_file, "\\", "/"));
                                        };
                                };
                                file_name = file_find_next();
                        };
                        file_find_close();

                        // directories
                        var dir_name = file_find_first(path + "*", fa_directory);
                        while(string_length(dir_name)){
                                if(dir_name != "." && dir_name != ".."){
                                        var full_dir = path + dir_name + "\\";
                                        if(directory_exists(path + dir_name)){
                                                array_add(directory_list, full_dir);
                                        };
                                };
                                dir_name = file_find_next();
                        };
                        file_find_close();
                };
                array_delete(directory_list, 0, n);
        };

        for(var l = 0; l < array_length(file_path_list); l++){
                var file = file_path_list[l];
                var point = string_last_pos(".", file);
                var ext = (point > 0) ? string_lower(string_copy(file, point, string_length(file) - point + 1)) : "";
                switch(ext){
                        case ".json":
						if (string_lower(string_copy(file, max(1, string_last_pos("/", file) + 1), string_length(file))) == "extra.json") {
							array_add(return_path[$ "other"], file);
							break;
						};
                        case ".pec":
                        case ".gmc":
                                array_add(return_path.chart, file);
                        break;

                        case ".mp3":
                        case ".flac":
                        case ".ogg":
                        case ".wav":
                                array_add(return_path.music, file);
                        break;

                        case ".txt":
                        case ".yml":
                        case ".yaml":
                        case ".csv":
                                array_add(return_path.text, file);
                        break;

                        case ".fs":
                        case ".glsl":
                        case ".hlsl":
                        case ".vsh":
                        case ".fsh":
                                array_add(return_path.shader, file);
                        break;

                        case ".png":
                        case ".jpg":
                        case ".jpeg":
                        case ".bmp":
                        case ".webp":
                        case ".apng":
                                array_add(return_path.image, file);
                        break;

                        default:
                                array_add(return_path[$ "other"], file);
                        break;
                };
        };

        return(return_path);
};

///@desc 闂備浇宕垫慨鎾敄婢跺顩查悹杞拌閻掍粙鏌熷▓鍨灍闁哥姴妫濋弻銊モ攽閸℃ê娅ｇ紓浣规缁犳牠寮诲☉銏℃櫜閹艰揪绲界敮銊х磽娴ｄ粙鍝洪柣鐔叉櫅閻ｅ嘲螖閸涱喖浜楅柟鍏兼儗閸犳牠寮查敐澶嬧拺闁告繂瀚弫鎶芥煕閳╁啰鎳勬い鏂跨Ч濮婂搫效閸パ呭姶闂佺粯鎸搁ˇ鍗炍ｉ幇顓熺秶闁宠鍎虫禍楣冩煟閻斿搫顣兼繝鈧导瀛樼厸闁糕槅鍘鹃崚浼存婢跺⊕褰掓晲閸稈鍋撻埀顒勬煛鐏炶鈧繈骞冭ぐ鎺戠倞闁冲搫鍊婚崝褰掓⒑?ChartSession闂?
function TrackZ(path) {
        if(!file_exists(path)) then return(false);
        var ok = chart_session_load_zip(path);
        if(!ok) then return(false);
        var session = chart_session_ensure();
        return {
                "name" : session.name,
                "level" : session.level,
                "image" : session.image_file,
                "music" : session.music_file,
                "chart" : session.chart_file,
                "format" : session.format_name,
                "dir" : session.active_dir
        };
};



///@desc line.csv 闂傚倷绀侀幉锛勬暜閸ヮ剙纾归柡鍥ュ灪閸嬧晠鏌涢幘妤€鎳忛敍蹇涙⒑閸忕厧澧柛銊ゅ嵆瀹曞綊鏌嗗鍡欏幈闂侀潧锛忛崘褍顥氭繝鐢靛仜閻°劑鎯勯鐐靛祦?
function load_line_csv(){
	var path = ($"{InChartPath}line.csv");
	if(file_exists(path)){
		var csv_grid = (load_csv(path));
		//print(csv_grid);
		if(!ds_exists(csv_grid , ds_type_grid)) then return({
			"status" : false,
			"result" : undefined,
			"msg" : "Is not ds_grid"
		});
		var csv_result = (ds_grid_to_struct_array(csv_grid));
		ds_grid_destroy(csv_grid);
		return({
			"status" : true,
			"result" : csv_result,
			"msg" : "Done"
		});
	}else return({ 
		"status" : false,
		"result" : undefined,
		"msg" : "File is not exists"
	});
};

///@desc Phigros Official闂備浇宕垫慨鎾敄婢跺顩查悹杞拌閻掍粙鏌ｅΔ鈧悧蹇涘煝閺冨牊鐓犲┑顔藉姇閳ь剚顨呴埢鏃堝閵堝棛鍘?
function official_floor_at_beat(speed_events, beat, seconds_per_beat) {
	var floor_value = 0;
	for (var speed_i = 0; speed_i < array_length(speed_events); speed_i++) {
		var speed_event = speed_events[speed_i];
		if (beat <= speed_event.startTime) then break;
		var covered_end = min(beat, speed_event.endTime);
		floor_value += max(0, covered_end - speed_event.startTime) * seconds_per_beat * speed_event.value;
		if (beat <= speed_event.endTime) then break;
	};
	return floor_value;
}

function Phigros() constructor {
	// 濠电姷鏁告慨宥夊礋椤愩埄娼欐繝娈垮枟鑿ч柛鏃€鍨佃灋?
	static chart = undefined;
	static version = 0;
	static line_list = [];
	// [闂備浇宕垫慨鎾敄婢跺顩查悹杞拌閻掍粙鏌℃径瀣靛劌闁搞倖娲熼弻宥堫檨闁告挻宀搁獮鍫ュΩ瑜夐崑鎾绘晲鎼粹€茬凹闁诲繐楠忕换婵嬪蓟閿熺姴鐒垫い鎺戝閸婇攱銇勯幒宥囪窗婵″樊鍨跺?闂傚倷绀侀幉锟犮€冮崱妞曟椽骞嬮悩鐢殿槸? 闂佽娴烽弫濠氬磻婵犲洤绐楁慨妯款啇缂? , 闂備浇顕ф绋匡耿闁秴纾婚柣鎰▕濞撳鏌涘畝鈧崑娑氱尵瀹ュ鐓曟い鎰剁稻缁€鍐煥?闂傚倷绀侀幉锟犮€冮崱妞曟椽骞嬮悩鐢殿槸? 缂? , 闂佽瀛╅鏍窗閹烘纾婚柟鐐灱閺€鑺ャ亜閺冨倵鎷￠柛搴㈠姈缁绘盯宕煎┑鍫㈩啋閻庤娲橀崹鐢糕€﹂妸鈺佺妞ゆ帒顦拌ⅶ闂?闂傚倷绀侀幉锟犮€冮崱妞曟椽骞嬮悩鐢殿槸? 闂佽娴烽弫濠氬磻婵犲洤绐楁慨妯款啇缂? , 闂備浇顕ф绋匡耿闁秴纾婚柕鍫濇媼閻庤埖銇勯弽顐粶婵鐓￠弻娑氫沪閸撗呭彎缂備緡鍠栭…鐑藉蓟閿熺姴绀冮柕濞у啰鍘芥繝?闂傚倷绀侀幉锟犮€冮崱妞曟椽骞嬮悩鐢殿槸? 闂佽娴烽弫濠氬磻婵犲洤绐楁慨妯款啇缂? , 缂傚倸鍊搁崐鐑芥倿閿曞倸绠伴悹鍥ф▕閻掕姤銇勯幇鍓佺暠婵鐓￠弻娑氫沪閸撗呭彎缂備緡鍠栭…鐑藉蓟閿熺姴绀冮柕濞у啰鍘芥繝?闂傚倷绀侀幉锟犮€冮崱妞曟椽骞嬮悩鐢殿槸? 闂佽娴烽弫濠氬磻婵犲洤绐楁慨妯款啇缂?] 
	__time = array_create(6, 0);
	paused = true;
	_notes = [];
	
	// line.csv
	static TextureGroup = {
		"default" : line_2
	};
	
	// 闂傚倸鍊烽悞锕€顭垮Ο鑲╃煋闁割偅娲橀崑顏堟煕閳╁啰鈯曢柛搴℃捣缁辨帞鈧綆浜炴禒銏㈡喐?
	static notes = ({});
	font_add_enable_aa(true);
	static font = (font_add($"{working_directory}resource/saira.ttf" , 45 , true , false , 32 , 255));
	if(asset_font_valid(font)) then font_enable_sdf(font , true);
	
	static res_path = {};
	static effc = undefined;
	static folder_chart = { 
		"name" : "",
		"level" : "",
		"music" : "",
		"chart" : "",
		"bg" : ""
	};
	static bg = -1;
	
	// 闂備浇宕垫慨宕囩矆娴ｈ娅犲ù鐘差儐閸?
	static settings = {
		"enableBlur" : false,					// 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炴挻鍩冮崑鎾垛偓瑙勬磸閸庣敻銆佸☉姗嗙叆闁告洦鍓氶褰掓⒒娴ｈ鍋犻柛搴ら哺閺呭爼鎳為妷锔界彿闂佸搫绋侀悘娑㈡偄閸忓吋娅栭梺鍛婃处閸?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗛惃顩沞)
		"enableFPS" : true,						// 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炴挻鍩冮崑鎾垛偓娈垮枙閸楀啿鐣峰鍡╂Ч婵炲濮甸幎鐩(婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗙€电se)
		"enableQuikyStart" : true,				// 闂傚倸顭崑鍕归崒鐐茬；濠电姴娲ら悞鍨亜閹烘垵鈧悂寮告惔銊︾厵妞ゆ牗宀搁崣鍕偓?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗛惃顩沞)[闂傚倷绀侀幉锟犮€冮崨鏉戠柈闁冲搫鍟伴崡姘舵煟閹伴潧澧伴柍缁樻⒒閳ь剙绠嶉崕閬嶆偋濠婂厾娲晲閸涱亝顫嶉梺褰掔畺椤ゅ倿宕甸　顪瞫e]
		"enableCanvasZoom" : false,				// 闂傚倷鑳堕、濠偽涢崟顓涘亾濮樼厧澧寸€规洘娲栭～婵嬵敇閻愮數鐛梺璇查叄濞佳囧箺濠婂懏顫曟慨妯垮煐閻撴盯鏌?.5(婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗙€电se)
		"enableSurface" : false,				// 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炴挻鍩冮崑鎾垛偓瑙勬磸閸庣敻銆佸☉姗嗙叆闁告洦鍓氶褰掓⒒娴ｅ憡鍟為柛鏃€娲熼獮濠偽熺拠宸殼?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗙€电se)
		"enableNoteHightLight" : true,			// 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炴挻鍩冮崑鎾垛偓瑙勬磸閸庣敻銆佸☉姗嗙叆闁告洦鍓氶褰掓⒒娴ｅ憡鍟為柣鐔村劦瀵敻顢楁担铏诡啎闂佺鐬奸崑娑氱不閻㈠憡鐓欓梺顓ㄧ畱閺嬫柨霉?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗛惃顩沞)
		"enableChartGUI" : true,				// 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炴挻鍩冮崑鎾垛偓娈垮枙閸楀啿鐣峰鍡╂Ч婵炲濮垫ご宄孖(婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗛惃顩沞)
		"enableLineJudge" : true,				// FC/AP 闂傚倷绀佸﹢閬嶁€﹂崼婢濇椽濡搁埡浣勶附鎱ㄥΟ鎸庣【闂?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗛惃顩沞)
		"showBG" : true,						// 闂傚倷绀侀幖顐も偓姘煎墯閺呰埖绂掔€ｎ€附鎱ㄥΟ鍨厫闁搞倕瀚伴幃姗€鎮欓棃娑楀闂?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗛惃顩沞)
		"enableHitEffect" : true,				// 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炴挻鍩冮崑鎾垛偓瑙勬磸閸庣敻銆佸☉姗嗙叆闁告洦鍓氶褰掓⒒娴ｇ儤鍤€闁诲繑宀搁獮鎰板箹娴ｇ鎯炲銈嗘磵閸嬫捇鏌熼銊ユ噺閸犲棝鏌涢弴銊ュ闁?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗛惃顩沞)
		"refreshFPSCount" : 60,					// 闂傚倷绀侀幉锛勬暜閿熺姴缁╅梺顒€绉撮拑鐔封攽閸屾碍鎲燬婵犵妲呴崑鍡樻櫠濡ゅ懎鍨傞柣鐔煎亰閸?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍?0)
		"enableDebug" : true,					// 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炴挻鍩冮崑鎾垛偓瑙勬磸閸庣敻銆佸☉姗嗙叆闁告洦鍓氶褰掓⒑閼姐倕孝妞ゆ垵鎳樺畷顖炲箮閼恒儱鍓ㄥ銈嗙墬椤曢亶鎮㈤悡搴ｄ紜閻庤娲栧ú銊┿€?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗙€电se)
		"enableDisplayLineID" : false,			// 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炴挻鍩冮崑鎾垛偓娈垮枙閸楀啿鐣峰鍡╂Ч婵炲濮电粙鎾舵閹烘绠氱憸蹇旂閵忋垺鍠?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗙€电se)
		"comboString" : "COMBO",				// combo text
		"enableVsync" : true,					// 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炴挻鍩冮崑鎾垛偓瑙勬磸閸庣敻銆佸☉姗嗙叆闁告洦鍓氶褰掓⒒娴ｈ鍋犻柛鏂跨焸瀹曟劗鎷犵憗浣规そ瀹曠螖閳ь剛鎲撮敃鍌涘€堕柣鎰祷濡炬悂鏌?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗛惃顩沞)
		"aa_level" : 0,							// aa闂傚倷鑳堕、濠囧春閺嶎厹鈧啯绻濋崶褎鐎銈嗘⒒閻℃棃鎮楅弻銉﹀仯闁诡厽甯掓俊鍧楁煙閼规澘浜圭紒?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍?)
		"useOldFX" : false,						// 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炶揪缍€椤鍒婇幘顔藉仯闁诡厽甯掓俊浠嬫煛閸℃绠婚柡宀嬬節瀹曟﹢宕熼銏╀患闂佹剚浜為弫濠氬蓟濞戙垹绠ｉ柨婵嗘噹閹偞绻濋姀锝庢綈閻㈩垪鈧剚鍤?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗙€电se)
		"enableComboScore" : true,				// 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炴挻鍩冮崑鎾垛偓瑙勬磸閸庣敻銆佸☉姗嗙叆闁告洦鍓氶褰掓⒑閸濆嫷妲撮柡鍛箞瀹曟垵鈽夐姀鐘叉優濡炪倖娲嶉崑鎾垛偓?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗙€电se)
		"judgeOffset" : 0,						// AUTO闂傚倷绀侀幉锛勬暜閸ヮ剙纾归柡鍥ュ灪閸嬧晠鏌熼鍡楄嫰濞堟﹢姊虹拠鈥崇仭濠㈢懓妫涚划?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍?)
		"enableAccJudgment" : true,				// 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炴挻鍩冮崑鎾垛偓瑙勬磸閸庣敻銆佸☉姗嗙叆闁告洦鍓氶鐟扳攽閻愭潙鐏﹂柟绋跨埣瀹曟洟骞橀鑲╋紮闂佺鎻粻鎴犵矆閸℃稒鐓忛柛顐ｇ箖閸ｄ粙鏌?婵犳鍠楃敮妤冪矙閹烘せ鈧箓宕奸妷顔芥櫍缂備緡鍋嗛惃顩沞)
		"preventWindowMoveFreeze" : true,		// use non-blocking Windows moving and resizing
		"enableRPEMulticore" : true,			// enable native RPE frame workers
		"rpeWorkerMinLines" : 32,				// minimum line count for native parallel resolve
		"rpeWorkerProfileFrames" : 1800,		// frames averaged between worker timing logs
		"noteUniformScale" : false,				// RPE note size/sizeControl also scale height
		"notePreloadSeconds" : 15,				// note preload seconds (0-60)
		"TEST1" : false							// judge offset jitter test (default false)
	};
	
	
	/// 闂傚倸鍊搁崐鎼佹偋婵犲洦鍋￠柨鏇炲€搁悞鍨亜閹达絾纭舵い锔肩畵閺屾盯濡舵径澶嬪枤閻?	
	///@desc 闂備浇顕х€涒晝绮欓幒妞尖偓鍐醇閵夘喗鏅炴繛杈剧到濠€閬嶅煝閺冨牊鐓犻柤瑙勬緲閻撴劗绱掓笟鍥ф灍缂佺粯鐩獮鏍敇閻愬浜鹃梻浣侯焾椤戞垹绱炴担鍓插殨?
	static strToReal = (func(str , default_value = undefined){
		if(string_lower(str) == "false") then return(0);
		if(string_lower(str) == "true") then return(1);
		if(string_lower(str) == "undefined") then return(undefined);
		try{ return(real(str)) }
		catch(e){ delete(e); return(default_value) };
	});
	
	///@desc 濠电姷鏁搁崑鐐哄箚瀹€鍕獥婵娉涚壕濠氭煥濠靛棭妲搁柡瀣╃窔閺岀喎鐣￠悧鍫熸嫳缂備椒绶￠崳锝夊箖濡も偓閳藉鈻庡Ο鑽ゆ毉婵＄偑鍊栭崹鎶芥倿閿斿墽鐭欏鑸靛姇缁犵敻鏌熼悜妯荤闁绘挸鍊块幃妤€鈻撻崹顔界亪缂備胶绮崝妤冨垝閳哄偆妲归幖瀛樼箘閸撱劑姊洪崫鍕偓鍝ヨ姳闁秴纾?
	static realToStrBool = (func(_real){
		if(!is_real(_real)) then return("undefined");
		if(bool(_real) == true) then return("true");
		else return("false");
	});
	
	///@desc 闂備浇宕垫慨鏉懨洪埡鍜佹晪鐟滄垿濡甸幇鏉跨倞妞ゆ巻鍋撶紒鈧崟顖涚厾闁诡厽甯掗崝婊勭箾?	///@arg Chart {String} 闂備浇宕垫慨鎾敄婢跺顩查悹杞拌閻掕棄霉閸忓吋缍戞俊顐ｏ耿閺屾盯濡烽鐐搭€嶅銈嗗姃缁瑩寮诲☉銏℃櫆闁兼亽鍎抽崙鈥斥攽?
	static Reader = (func(_chart = "" , lmode = 0 , chart_source = undefined){
		// Reader may be called repeatedly when switching charts. Do not retain
		// note references from the previous chart.
		if(instance_exists(oLine)) then with(oLine) instance_destroy();
		// Inactive notes are retained for replay, so explicitly reactivate them
		// before a real chart replacement destroys the old pool.
		instance_activate_object(oNote);
		if(instance_exists(oNote)) then with(oNote) instance_destroy();
		if(instance_exists(oEffectNew)) then with(oEffectNew) effect_events = [];
		self._notes = [];
		self.line_list = [];
		if(lmode == 0){
			var f = (string_length(_chart) ? _chart : ($"{working_directory}chart/Chart_IN.json"));
			var buff = buffer_load(f);
			var r = buffer_read(buff, buffer_string);
			//return(f);
			self.chart = (json_parse(r));
			game.version = (self.chart.formatVersion);
			delete(r);
			buffer_delete(buff);
			delete(chart_source);
		}else{
			delete(_chart);
			self.chart = chart_source;
		}
		
		for(var i = 0 ; i < array_length(self.chart.judgeLineList) ;  i ++){
			//array_push(self._notes , []);
			if(game.version == 1 || game.version == 2){
				for(var m = 0 ; m < array_length(self.chart.judgeLineList[i].judgeLineMoveEvents) ; m ++){
					var l_m = (self.chart.judgeLineList[i].judgeLineMoveEvents[m]);
					var move_source = {
						"start" : l_m.start,
						"end" : l_m[$ "end"],
						"start2" : l_m[$ "start2"] ?? 0,
						"end2" : l_m[$ "end2"] ?? 0
					};
					var r_m = (game.version == 1 ? game.Math.posCovert(move_source) : game.Math.posCovert2(move_source));
					if (!is_struct(r_m)) then continue;
					self.chart.judgeLineList[i].judgeLineMoveEvents[m][$ "start"] = r_m.start;
					self.chart.judgeLineList[i].judgeLineMoveEvents[m][$ "end"] = r_m[$ "end"];
					self.chart.judgeLineList[i].judgeLineMoveEvents[m][$ "start2"] = r_m.start2;
					self.chart.judgeLineList[i].judgeLineMoveEvents[m][$ "end2"] = r_m.end2;
				};
			};
			
			var bpm = (self.chart.judgeLineList[i].bpm);
			var line_speed_events = self.chart.judgeLineList[i].speedEvents;
			array_sort(line_speed_events, function(a, b) { return a.startTime - b.startTime; });
			var line_seconds_per_beat = 1.875 / bpm;
			for(var a = 0 ; a < array_length(self.chart.judgeLineList[i].notesAbove) ; a ++){
				var n = (self.chart.judgeLineList[i].notesAbove[a]);
				var hold_floor_length = 0;
				if (n.type == 3) {
					var hold_beats = max(0, floor(n.holdTime));
					hold_floor_length = official_floor_at_beat(line_speed_events, n.time + hold_beats, line_seconds_per_beat) - n.floorPosition;
					if (hold_floor_length == 0) then hold_floor_length = hold_beats * line_seconds_per_beat * n[$ "speed"];
				};
				array_add(self._notes , { "type" : n.type , "time" : n.time , "holdTime" : (n.type == 3 ? max(0, floor(n.holdTime)) : 0) , "holdFloorLength" : hold_floor_length, "speed" : (n.type == 3 ? 1 : n[$ "speed"]) , "xOffset" : n.positionX , "yOffset" : n.floorPosition , "hl" : false , "isAbove" : true , "id" : i , "bpm" : bpm});
			};
			
			for(var b = 0 ; b < array_length(self.chart.judgeLineList[i].notesBelow) ; b ++){
				var n = (self.chart.judgeLineList[i].notesBelow[b]);
				var hold_floor_length = 0;
				if (n.type == 3) {
					var hold_beats = max(0, floor(n.holdTime));
					hold_floor_length = official_floor_at_beat(line_speed_events, n.time + hold_beats, line_seconds_per_beat) - n.floorPosition;
					if (hold_floor_length == 0) then hold_floor_length = hold_beats * line_seconds_per_beat * n[$ "speed"];
				};
				array_add(self._notes , { "type" : n.type , "time" : n.time , "holdTime" : (n.type == 3 ? max(0, floor(n.holdTime)) : 0) , "holdFloorLength" : hold_floor_length, "speed" : (n.type == 3 ? 1 : n[$ "speed"]) , "xOffset" : n.positionX , "yOffset" : n.floorPosition , "hl" : false , "isAbove" : false , "id" : i , "bpm" : bpm});
			};
			//delete(self.chart.judgeLineList[i].notesAbove);
			//delete(self.chart.judgeLineList[i].notesBelow);
		};
		array_set(game.__time, 5, self.chart.offset * 1000000);
		print("[R-Chart] Done." , game.settings.enableDebug);
		return(true);
	});
	
	///@desc 闂傚倷娴囧銊х矆娓氣偓椤㈡岸顢橀姀鐘电暫婵犵數濮村ú銈囩矆閸曨垱鐓犻柟顓熷笒閸旀粍绻?
	static Sort = (func(){
		//print(array_length(game.__time));
		for(var i = 0 ; i < array_length(self.chart.judgeLineList) ; i ++){
			array_sort(self.chart.judgeLineList[i].judgeLineMoveEvents , func(x1 , x2){
				return(x1.startTime - x2.startTime);
			});	
			array_sort(self.chart.judgeLineList[i].judgeLineRotateEvents , func(x1 , x2){
				return(x1.startTime - x2.startTime);
			});
			array_sort(self.chart.judgeLineList[i].judgeLineDisappearEvents , func(x1 , x2){
				return(x1.startTime - x2.startTime);
			});
			array_sort(self.chart.judgeLineList[i].speedEvents , func(x1 , x2){
				return(x1.startTime - x2.startTime);
			});
			
			//array_sort(self.chart.judgeLineList[i].notesBelow , func(x1 , x2){
			//	if(x1.time == x2.time){
			//		struct_set(x1 , "hl" , true);
			//		struct_set(x2 , "hl" , true);
			//	};
			//	return(x1.time - x2.time);
			//});
		};
		if(game.settings.enableNoteHightLight){
			array_sort(self._notes , func(x1 , x2){
				if(x1.time == x2.time){
					struct_set(x1 , "hl" , true);
					struct_set(x2 , "hl" , true);
				};
				return(x1.time - x2.time);
			});
		};
		print("[S-Sort] Done." , game.settings.enableDebug);
	});
	
	///@desc 闂傚倷绀侀幉鈥愁潖缂佹ɑ鍙忛柟顖ｇ亹瑜版帒鐐婃い鎺嶇濞堟垿鏌ｈ箛鏇炰户闁稿鎹囬幃鐢割敍閻愬鍘?	///@desc Path {String} 闂傚倷鑳堕崢褔宕崸妤€瀚夋い鎺嗗亾闁宠绉撮埢搴ㄥ箻瀹曞洤鈧偤姊虹拠鈥崇€婚柛鏇ㄥ亜閻熷酣姊绘担渚綊闁逞屽墴瀹?
	static Background = (func(custom = ""){
		var p = ((is_string(custom) && string_length(custom)) ? custom : "");
		if(asset_sprite_valid(self.bg)) then sprite_delete(self.bg);
		self.bg = -1;
		if(!is_string(p) || !string_length(p)){
			print("[R-BG] Empty path." , game.settings.enableDebug);
			return;
		};
		p = string_replace_all(p, "\\", "/");
		if(!file_exists(p)){
			print($"[R-BG] Missing file: {p}" , game.settings.enableDebug);
			return;
		};

		// GM 2024+/LTS may return asset refs from sprite_add (not reals).
		// Do NOT require is_real(...); validate with sprite_exists via asset_sprite_valid.
		var base_spr = -1;
		var try_paths = [p];
		array_add(try_paths, string_replace_all(p, "/", "\\"));
		var fname = p;
		var slash = max(string_last_pos("/", p), string_last_pos("\\", p));
		if (slash > 0) then fname = string_copy(p, slash + 1, string_length(p) - slash);
		// Prefer relative path under working_directory (most reliable for sprite_add)
		var wd_bg = working_directory + "bg_cache_" + fname;
		if (file_exists(wd_bg)) then file_delete(wd_bg);
		file_copy(p, wd_bg);
		if (file_exists(wd_bg)) {
			array_add(try_paths, wd_bg);
			array_add(try_paths, "bg_cache_" + fname); // relative
		};
		// Also game_save_id cache
		var local_bg = string_replace_all(game_save_id + "bg_cache_" + fname, "\\", "/");
		if (file_exists(local_bg)) then file_delete(local_bg);
		file_copy(p, local_bg);
		if (file_exists(local_bg)) then array_add(try_paths, local_bg);

		for (var ti = 0; ti < array_length(try_paths); ti++) {
			var tp = try_paths[ti];
			var s0 = sprite_add(tp, 0, false, false, 0, 0);
			if (asset_sprite_valid(s0)) { base_spr = s0; print($"[R-BG] ok try[{ti}] imgnum=0 path={tp} type={typeof(s0)}" , game.settings.enableDebug); break; };
			var s1 = sprite_add(tp, 1, false, false, 0, 0);
			if (asset_sprite_valid(s1)) { base_spr = s1; print($"[R-BG] ok try[{ti}] imgnum=1 path={tp} type={typeof(s1)}" , game.settings.enableDebug); break; };
			print($"[R-BG] sprite_add failed try[{ti}]: {tp} (s0={s0}/{typeof(s0)}, s1={s1}/{typeof(s1)})" , game.settings.enableDebug);
		};

		if(!asset_sprite_valid(base_spr)){
			print($"[R-BG] sprite_add failed all strategies: {p}" , game.settings.enableDebug);
			return;
		};
		// Always center origin on the loaded sprite first.
		//sprite_set_offset(base_spr, sprite_get_width(base_spr) * 0.5, sprite_get_height(base_spr) * 0.5);

		if(is_struct(game.settings) && bool(game.settings.enableBlur)){
			// kawase_blur_sprite recreates sprite; request middle-center origin there.
			var blurred = kawase_blur_sprite(base_spr, 1, 0, 10, SPRITE_OFFSET.MIDDLE_CENTER);
			if(asset_sprite_valid(blurred) && blurred != base_spr){
				sprite_delete(base_spr);
				game.bg = blurred;
			}else{
				game.bg = base_spr;
				print("[R-BG] Blur failed, using raw sprite." , game.settings.enableDebug);
			};
		}else{
			game.bg = base_spr;
		};

		// Final guarantee: whatever sprite is used (raw or blurred) is center-origin.
		//if (asset_sprite_valid(game.bg)) {
			//var _bw = sprite_get_width(game.bg);
			//var _bh = sprite_get_height(game.bg);
			//sprite_set_offset(game.bg, _bw * 0.5, _bh * 0.5);
			//print($"[R-BG] origin=({sprite_get_xoffset(game.bg)}, {sprite_get_yoffset(game.bg)}) size={_bw}x{_bh}" , game.settings.enableDebug);
		//};
		print($"[R-BG] {asset_sprite_valid(game.bg) ? "Done." : "Failed."} path={p} type={typeof(game.bg)}" , game.settings.enableDebug);
	});

	static Configs = (func(){
		var f = $"{working_directory}resource/configs.ini";
		//if(isExists(f)){
		ini_open(f);
		print($"str: {game.settings.comboString}");
		if(!isExists(f)){
			print("[F-Configs] No Found 'configs.ini' file" , game.settings.enableDebug);
			
			// Resource
			ini_write_string("Resource" , "note.tap" , $"{working_directory}resource/note_tap.png");
			ini_write_string("Resource" , "note.flick" , $"{working_directory}resource/note_flick.png");
			ini_write_string("Resource" , "note.drag" , $"{working_directory}resource/note_drag.png");
			ini_write_string("Resource" , "note.hold.head" , $"{working_directory}resource/hold_head.png");
			ini_write_string("Resource" , "note.hold.body" , $"{working_directory}resource/hold_body.png");
			ini_write_string("Resource" , "note.hold.end" , $"{working_directory}resource/hold_end.png");
			ini_write_string("Resource" , "font.ui" , $"{working_directory}resource/saira.ttf");
			ini_write_string("Resource" , "effc.hit" , $"{working_directory}resource/effect.png");
			
			// Settings
			var _name = (struct_get_names(self.settings));
			for(var l = 0 ; l < array_length(_name) ; l ++){
				ini_write_string("Settings" , _name[l] , self.settings[$ _name[l]]);
			};
			
			_name = (struct_get_names(self.folder_chart));
			for(var l = 0 ; l < array_length(_name) ; l ++){
				ini_write_string("Chart" , _name[l] , self.folder_chart[$ _name[l]]);
			};
			delete(self.folder_chart);
			//ini_write_string("Settings" , "enableFPS" , "false");
			//ini_write_string("Settings" , "enableBlur" , "false");
		};
		///
		self.res_path[$ "note.tap"] = (ini_read_string("Resource" , "note.tap" , $"{working_directory}resource/note_tap.png"));
		self.res_path[$ "note.flick"] = (ini_read_string("Resource" , "note.flick" , $"{working_directory}resource/note_flick.png"));
		self.res_path[$ "note.drag"] = (ini_read_string("Resource" , "note.drag" , $"{working_directory}resource/note_drag.png"));
		self.res_path[$ "note.hold.head"] = (ini_read_string("Resource" , "note.hold.head" , $"{working_directory}resource/hold_head.png"));
		self.res_path[$ "note.hold.body"] = (ini_read_string("Resource" , "note.hold.body" , $"{working_directory}resource/hold_body.png"));
		self.res_path[$ "note.hold.end"] = (ini_read_string("Resource" , "note.hold.end" , $"{working_directory}resource/hold_end.png"));
		self.res_path[$ "font.ui"] = (ini_read_string("Resource" , "font.ui" , $"{working_directory}resource/saira.ttf"));
		self.res_path[$ "effc.hit"] = (ini_read_string("Resource" , "effc.hit" , $"{working_directory}resource/effect.png"));
		
		///
		var name = (struct_get_names(self.settings));
		for(var i = 0 ; i < array_length(name) ; i ++){
			if(name[i] != "comboString") then self.settings[$ name[i]] = (self.strToReal(ini_read_string("Settings" , name[i] , self.settings[$ name[i]])));
			else self.settings[$ name[i]] = (ini_read_string("Settings" , name[i] , self.settings[$ name[i]]));
		};
		// Only load Chart section from ini when no custom chart session is active.
		// Otherwise configs.ini defaults (e.g. bg=Illustration.png) overwrite real package metadata.
		if(self.settings.enableQuikyStart){
			var _session_active = (variable_global_exists("chart_session") && is_struct(global.chart_session) && bool(global.chart_session.ready));
			if(!_session_active && is_struct(self.folder_chart)){
				var _name = (struct_get_names(self.folder_chart));
				for(var i = 0 ; i < array_length(_name) ; i ++){
					self.folder_chart[$ _name[i]] = (ini_read_string("Chart" , _name[i] , self.folder_chart[$ _name[i]]));
				};
			};
		}else if(is_struct(self.folder_chart) && !(variable_global_exists("chart_session") && is_struct(global.chart_session) && bool(global.chart_session.ready))){
			delete(self.folder_chart);
		};
		//self.settings[$ "enable"]
		self.settings[$ "refreshFPSCount"] = (clamp(self.settings[$ "refreshFPSCount"] , 1 , 300));
		self.settings[$ "notePreloadSeconds"] = (clamp(self.settings[$ "notePreloadSeconds"] , 0 , 60));
		self.settings[$ "rpeWorkerMinLines"] = clamp(floor(self.settings[$ "rpeWorkerMinLines"]), 1, 1024);
		self.settings[$ "rpeWorkerProfileFrames"] = clamp(floor(self.settings[$ "rpeWorkerProfileFrames"]), 60, 36000);
		ini_close();
		print($"str2: {game.settings.comboString}");
		print("[R-Configs] Done." , self.settings.enableDebug);
	});
	
	//static Img = (func(){
	//	var name = [
	//		"note.tap",
	//		"note.drag",
	//		"note.flick",
	//		"note.hold.head",
	//		"note.hold.body",
	//		"note.hold.end",
	//		"font.ui",
	//		"effc.hit"
	//	];
		
	//	// LLLLLLLOAD
	//	for(
	//var i = 0 ; i < array_length(name) ; i ++){
	//		if(isExists(self.res_path[$ name[i]])){
	//			var type = (string_copy(self.res_path[$ name[i]] , 1 , 4)),
	//				_name = (string_copy(self.res_path[$ name[i]] , 4 , string_length(self.res_path[$ name[i]])));
				
	//			switch(type){
	//				case "note":
	//					if(!struct_exists(self.notes , "hold.head")) then self.notes[$ "note.hold"] = (array_create(3 , undefined));
						
	//					if(_name == "hold.head"){
	//game.notes[$ "note.hold"][0] = (sprite_add(self.res_path[$ name[i]] , 3 , false , false , 0 , 0));
	//						//sprite_set_offset(self.notes[$ "note.hold"][0] , sprite_get_width(self.notes[$ "note.hold"][0]) / 2 , sprite_get_height(self.notes[$ "note.hold"][0]));
	//					}elif(_name == "hold.body"){
	//game.notes[$ "note.hold"][1] = (sprite_add(self.res_path[$ name[i]] , 3 , false , false , 0 , 0));
	//						//sprite_set_offset(self.notes[$ "note.hold"][1] , sprite_get_width(self.notes[$ "note.hold"][1]) / 2 , sprite_get_height(self.notes[$ "note.hold"][1]));
	//					}elif(_name == "hold.end"){
	//game.notes[$ "note.hold"][2] = (sprite_add(self.res_path[$ name[i]] , 3 , false , false , 0 , 0));
	//						//sprite_set_offset(self.notes[$ "note.hold"][2] , sprite_get_width(self.notes[$ "note.hold"][2]) / 2 , sprite_get_height(self.notes[$ "note.hold"][2]));
	//					}else{
	//game.notes[$ name[i]] = (sprite_add(self.res_path[$ name[i]] , 3 , false , false , 0 , 0));
	//						//sprite_set_offset(self.notes[$ name[i]] , sprite_get_width(self.notes[$ name[i]]) / 2 , sprite_get_height(self.notes[$ name[i]]));
	//					};
	//				break;
					
	//				case "font":
	//					game.font = (font_add(self.res_path[$ name[i]] , 25 , false , false , 32, 255));
	//				break;
					
	//				case "effc":
	//					game[$ type] = (sprite_add(self.res_path[$ name[i]] , 30 , false , false , 0 , 0));
	//					//sprite_set_offset(self[$ type] , sprite_get_width(self[$ type]) / 2 , sprite_get_height(self[$ type]));
	//				break;
	//			};
	//			print($"[L-Image] Loaded {name[i]}");
	//		}else print($"[F-Image] No Found '{self.res_path[$ name[i]]}'");
	//	};
	//	print(self.notes);
	//	// Free
	//	delete(self.res_path);
	//});
	
	///@desc 闂傚倷绀侀幉锟犲礉閺囥垹绠犻柟鎵閸嬵亪鏌涢埄鍐噭閻忓繐閰ｉ弻娑㈠即閵娿儱顫梺缁樼墵娴滃爼寮婚悢铏圭當婵炴垶蓱閿涘秹鏌￠埀顒佺鐎ｎ偆鍘?
	static Resource = (func(){
		if(!asset_font_valid(self.font)){
			font_add_enable_aa(true);
			self.font = (font_add($"{working_directory}resource/saira.ttf" , 45 , true , false , 32 , 255));
			if(asset_font_valid(self.font)) then font_enable_sdf(self.font , true);
		};
		self.Configs();
		if (variable_global_exists("render_mode") && global.render_mode) {
			self.settings.aa_level = 8;
			print("[Renderer] Anti-aliasing: 8x MSAA");
		};
		//self.Img();
		// Prefer active chart session image; do not invent missing defaults.
		var _bg_path = "";
		if (variable_global_exists("chart_session") && is_struct(global.chart_session) && bool(global.chart_session.ready) && is_string(global.chart_session.image_file) && string_length(global.chart_session.image_file)) {
			_bg_path = InChartPath + global.chart_session.image_file;
		} else if (is_struct(self.folder_chart) && is_string(self.folder_chart.bg) && string_length(self.folder_chart.bg)) {
			_bg_path = InChartPath + self.folder_chart.bg;
		};
		if (string_length(_bg_path)) {
			self.Background(_bg_path);
		};
		display_custom(game.settings.aa_level , game.settings.enableVsync);
		print("[L-Resource] Done." , game.settings.enableDebug);
	});
	
	///@desc 濠电姷鏁搁崑鐐哄箰閹间礁绠犻柟鐗堟緲缁犳牕鈹戦悩鎻掝仾閻忓繐閰ｉ弻娑㈠即閵娿儱顫梺?	///@arg full {Bool} 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炶揪缍€閵嗏偓闁稿鎹囬幃鐑藉箯鐏炵瓔浼冮梻浣告啞閻熴儳鎹㈤幇鏉课ラ柟鐑橆殔瀹告繃銇勯弽銊р槈闁?
	static Clean = (func(full = false){
		if(asset_sprite_valid(self.bg)){
			sprite_delete(self.bg);	
		};
		self.bg = -1;

		// line.csv textures are created dynamically and are not GameMaker assets.
		var texture_names = (struct_get_names(self.TextureGroup));
		for(var texture_i = 0 ; texture_i < array_length(texture_names) ; texture_i ++){
			if(texture_names[texture_i] == "default") then continue;
			var texture_id = (self.TextureGroup[$ texture_names[texture_i]]);
			if(sprite_exists(texture_id)) then sprite_delete(texture_id);
		};
		self.TextureGroup = { "default" : line_2 };
		
		self.chart = undefined;
		self._notes = [];
		self.line_list = [];
		if(instance_exists(oLine)){
			with(oLine) instance_destroy();
		};
		// Include the inactive replay pool in a full chart/room cleanup.
		instance_activate_object(oNote);
		if(instance_exists(oNote)){
			with(oNote) instance_destroy();
		};
		
		if(full){
			struct_foreach(self.notes , function(name , values){
				if(!is_array(values)){
					if(sprite_exists(values)) then sprite_delete(values);
				}else{
					for(var i = 0 ; i < array_length(values) ; i ++){
						if(sprite_exists(values[i])) then sprite_delete(values[i]);	
					};
				};
			});	
			self.notes = {};
			if(!is_undefined(self.font) && font_exists(self.font)){
				font_delete(self.font);
			};
			self.font = undefined;
			if(sprite_exists(self.effc)){
				sprite_delete(self.effc);	
			};
			self.effc = undefined;
			
		};
		print($"[D-Clean] {full ? "Full Clean Done." : "Done."}" , game.settings.enableDebug);
	});
	
	///@desc 闂備浇宕垫慨鎾敄婢跺顩查悹杞拌閻掕棄霉閸忓吋缍戦柡瀣╃窔閺屸剝寰勭€ｉ潧鍔岄梺鍛婃煥閹虫﹢寮诲☉銏犵闁挎繂鎲涢幘缁樼厸?
	static Math = ({
		
		///@desc beat timer
		timer : (func(bpm , rtime){
			//print($"timer: {array_length(game.__time)}");
			return(rtime / (1.875 / bpm));
		}),
		
		///@desc real timer
		realTimer : (func(bpm , ctime){
			//print($"rtimer: {array_length(game.__time)}");
			return((ctime * 1.875) / bpm);
		}),
		
		///@desc now timer index
		now : (func(index = 1){
			//print($"now : {array_length(game.__time)}");
			var t = (get_timer());
			//game.__time[index] = t;
			array_set(game.__time , index , t);
			return(t);
		}),
		
		///@desc chart current time
		ctime : (func(){
			if (variable_global_exists("render_mode") && global.render_mode) {
				var render_time = global.render_frame / global.render_fps;
				array_set(game.__time, 1, render_time);
				array_set(game.__time, 4, render_time * 1000000);
				return(game.__time[4]);
			};
			//print($"ctimer: {array_length(game.__time)}");
			var t = ((get_timer() - game.__time[3] - game.__time[0])); //  + (game.chart.offset * 1000000)
			//game.__time[1] = t;
			array_set(game.__time, 1 , t / 1000000);
			array_set(game.__time , 4 , t);
			return(t);	
		}),
		
		///@desc delta ratio time
		dtime : (func(_ntime , _stime , _etime){
			var _rdt = ((_ntime- _stime) / (_etime - _stime));
			//print($"dtimer: {array_length(game.__time)}");
			return(_rdt);
		}),
		
		///@desc pause accumulate time
		ptime : (func(){
			var time = (game.__time[4] - game.__time[2]);
			array_set(game.__time , 3 , game.__time[3] + time);	
			return(time);
		}),

		///@desc floorPosition max visible precision helper
		maxVisiblePos : (func(value){
			static float_buffer = (buffer_create(4, buffer_fixed, 1));
			buffer_poke(float_buffer, 0, buffer_f32, value);
			var float_value = (buffer_peek(float_buffer, 0, buffer_f32));
			if(is_nan(float_value) || abs(float_value) == infinity) then return(float_value);

			var magic = 11718.75,
				prime = (float_value >= magic ? power(2, floor(1 + log2(float_value / magic))) : 1),
				candidate = (float_value / prime + 0.001);
			buffer_poke(float_buffer, 0, buffer_f32, candidate);
			var rounded = (buffer_peek(float_buffer, 0, buffer_f32));
			if(rounded <= candidate) then return(rounded * prime);

			var bits = (buffer_peek(float_buffer, 0, buffer_u32));
			buffer_poke(float_buffer, 0, buffer_u32, bits + (rounded <= 0 ? 1 : -1));
			return(buffer_peek(float_buffer, 0, buffer_f32) * prime);
		}),
		
		///@desc formatVersion = 1 -> 3
		posCovert : (func(pos_struct){
			if((!struct_exists(pos_struct , "start")) || (!struct_exists(pos_struct , "end"))) then return(undefined);
			return({
				"start" : (round(pos_struct.start / 1000) / 880),
				"end" : (round(pos_struct[$ "end"] / 1000) / 880),
				"start2" : ((pos_struct.start % 1000) / 520),
				"end2" : ((pos_struct[$ "end"] % 1000) / 520)
			});
		}),
		
		///@desc formatVersion = 2 -> 3
		posCovert2 : (func(pos_struct){
			if(array_length(struct_get_names(pos_struct)) != 4) then return(undefined);
			return({
				"start" : (0.5 + (pos_struct.start / 10)),
				"end" : (0.5 + (pos_struct[$ "end"] / 10)),
				"start2" : (0.5 + (pos_struct.start2 / 10)),
				"end2" : (0.5 + (pos_struct.end2 / 10))
			});
		})
		//pause1 : (function)
	});
	
	///@desc 闂備浇顕х换鎰崲閹邦喗宕查柟閭﹀幖椤曢亶鏌熼悧鍫熺凡缂佲偓?
	static PhiTool = {
		///@desc 婵犵數鍋為崹鍫曞箰鐠囧弬锝夊箳濡炲皷鍋撻崨瀛樻櫇闁稿本鑹惧宄邦渻閵堝棛澧紒瀣笧閻ヮ亪顢涢悙瀵稿幐闂侀€炲苯澧伴柟鍙夋尦瀹曠喖顢曢妶鍡忔瀻闂傚倸鍊烽悞锕傤敄濞嗘挸绐楁慨妯块哺閸嬫牗銇勯幇鍓佺暠闁?		// How to Use? before_type_arr[index] => after_type_arr[index]
		TrasformType : (function(before_type_arr , after_type_arr){
			if(is_array(after_type_arr) && is_array(before_type_arr)) {}
			else return(false);
			var lens = [
				array_length(before_type_arr),
				array_length(after_type_arr)
			];
			if((lens[0] == lens[1])) {}
			else return(false);
			
			var chart = (game.chart);
			for(var l = 0 ; l < array_length(chart.judgeLineList) ; l ++){
				var _line = (chart.judgeLineList[l]);
				var a , b , len;
				for(len = 0 ; len < lens[0] ; len ++){
					for(a = 0 ; a < array_length(_line.notesAbove) ; a ++){
						if(_line.notesAbove[a][$ "type"] == before_type_arr[len]) then game.chart.judgeLineList[l].notesAbove[a][$ "type"] = (after_type_arr[len]);
					};
					for(b = 0 ; b < array_length(_line.notesBelow) ; b ++){
						if(_line.notesBelow[b][$ "type"] == before_type_arr[len]) then game.chart.judgeLineList[l].notesBelow[b][$ "type"] = (after_type_arr[len]);
					};
				};
			};
			//game.chart = chart;
			//delete(chart);
			
			return(true);
		}),
		
		///@desc  婵犵數鍎戠徊钘壝洪敂鐐床闁稿瞼鍋為崑銈夋煏婵炑冨椤忊晠姊绘笟鍥у缂佸娼ч々?		// 闂?, 闂傚倷绀侀幉锟犳偡椤栨稓顩叉繝闈涙焾閿濆绠瑰ù锝囶焾閸嬪秹姊虹紒妯活棃妞ゃ儲鎸搁埢鎾诲础閻愨晜顫嶉梺瑙勫劤绾绢厼鐡┑鐘愁問閸犳帡寮查悩璇茬畾闁告劦鍠栫粈瀣亜韫囨挻顥犳い鏃€妫冮弻?
		SaveTrack : (function(path){
			var js_str = (json_stringify(game.chart , true)),
				buff = (buffer_create(string_byte_length(js_str) , buffer_grow , 1));
			buffer_write(buff , buffer_string , js_str);
			buffer_save(buff , path);
			buffer_delete(buff);
			
			return(true);
		}),
		
		///@desc  闂傚倷绀佺紞濠囁夐幘璇茬獥閹兼番鍔岀粻鏍箹濞ｎ剙濡肩紒鈧崟顖涚厾闁诡厽甯掗崝婊勭箾?
		FitEventsTrack : (function(){
				
		})
	};
	
	
	///@desc 闂傚倷绀侀幉锛勬暜閸ヮ剙纾归柡鍥ュ灪閸嬧晠鏌涢幘妤€鎳忛敍?闂傚倸鍊搁崐鎼佹晝閵堝洤顥氭い鎾卞焺閺?
	static CreateLines = (func(){
		// Release textures and instance references left by a previous chart load.
		var old_texture_names = (struct_get_names(self.TextureGroup));
		for(var texture_i = 0 ; texture_i < array_length(old_texture_names) ; texture_i ++){
			if(old_texture_names[texture_i] == "default") then continue;
			var old_texture = (self.TextureGroup[$ old_texture_names[texture_i]]);
			if(sprite_exists(old_texture)) then sprite_delete(old_texture);
		};
		self.TextureGroup = { "default" : line_2 };
		self.line_list = [];
		var csv = (load_line_csv());
		if(csv.status){
			array_sort(
				csv.result,
				function(x1 , x2){
					return(x1.LineId - x2.LineId);	
				}
			);
			array_foreach(csv.result, function(val , index){
				var struct_img = (sprite_add($"{InChartPath}{val.Image}" , 0 , 0 , 0 , 0 , 0));
				//struct_set(struct_img , string(val.LineId) , );
				if(sprite_exists(struct_img)){
					sprite_set_offset(struct_img , sprite_get_width(struct_img) / 2 , sprite_get_height(struct_img) / 2);
					struct_set(game.TextureGroup , string(val.LineId) , struct_img);
					print($"Line[{string(val.LineId)}] -> Successfully to Load \"{val.Image}\"");
				}else{
					print($"Line[{string(val.LineId)}] -> Failed to Load \"{val.Image}\"");
				};
				
				//array_add(game.TextureGroup , {
				//		string(val.LineId) : sprite_add($"{InChartPath}{val.Image}" , 0 , 0 , 0 , 0 , 0)
				//	}
				//);
				
				//var len = (array_length(game.TextureGroup));
				//if(sprite_exists(game.TextureGroup[len - 1])
			});
		};
		for(var i = 0 , ll = 0 , img , scales = 1; i < array_length(self.chart.judgeLineList) ; i ++){
			if(csv.status && string(i) == csv.result[ll].LineId){
				img = (game.TextureGroup[$ string(i)]);
				scales = (csv.result[ll][$ "Scale"] ?? 1);
				print($"[C-Lines::line.csv][Line {i}] -> Successfully to get line.csv values(\"{csv.result[ll].Image}\")")
				ll = (clamp(ll + 1 , 0 , array_length(csv.result) - 1));
			}
			else {
				img = line_2;
				scales = 1;
			};
			var l = (instance_create_depth(room_width / 2 , room_height / 2 , 0 , oLine , {
				events : self.chart.judgeLineList[i] ,
				line_id : i ,
				image_id : img,
				Scales : (scales)
			}));
			array_add(self.line_list , l);
		};
		//print($"cl: {array_length(game.__time)}");
		// print($"cl: {
		print("[C-Lines] Done." , game.settings.enableDebug);
		for(var i = 0 ; i < array_length(self._notes) ; i ++){
			var na = (self._notes[i]);
			var note_instance = instance_create_depth( -999 , -999 , 0 , oNote , {
				"type" : na.type,
				"isAbove" : na.isAbove,
				"time" : na.time,
				"holdTime" : (na.holdTime),
				"holdFloorLength" : (na[$ "holdFloorLength"] ?? 0),
				"xOffset" : (na.xOffset),
				"yOffset" : (na.yOffset),
				"line_id" : (na[$ "id"]),
				"bpm" : (na.bpm),
				"speed" : (na[$ "speed"]),
				"_hl" : (na[$ "hl"])
			});
			if (variable_global_exists("render_mode") && global.render_mode && instance_exists(note_instance)) {
				var note_hitsound_time = (note_instance.type == 2 || note_instance.type == 4)
					? note_instance.realHitTime : note_instance.judgeRealTime;
				note_instance.render_hitsound_scheduled = render_schedule_hitsound(
					note_instance.sound, note_hitsound_time);
			};
		};
		// Note instances now own the scalar values they need. Drop the temporary
		// flattened array instead of retaining a second copy for the whole song.
		self._notes = [];
		print("[C-Notes] Done." , game.settings.enableDebug);
	});
	
	
	print($"[Initional] Done." , self.settings.enableDebug);
	//});
};

function rpe_read_info_offset_ms(root_path) {
	var root = chart_path_norm(root_path);
	if (string_length(root) && string_char_at(root, string_length(root)) != "/") then root += "/";
	var info_path = root + "info.txt";
	if (!file_exists(info_path)) then info_path = root + "info.yml";
	if (!file_exists(info_path)) then info_path = root + "info.yaml";
	if (!file_exists(info_path)) then return 0;

	var handle = file_text_open_read(info_path);
	if (handle < 0) then return 0;
	var result = 0;
	while (!file_text_eof(handle)) {
		var line_text = string_replace_all(file_text_readln(handle), "\r", "");
		if (!string_length(line_text)) then continue;
		var first = string_char_at(line_text, 1);
		if (first == "#" || first == "-" || first == " " || first == "\t") then continue;
		var sep = string_pos(":", line_text);
		if (sep <= 0) then sep = string_pos("=", line_text);
		if (sep <= 0) then continue;
		var key = string_lower(string_replace_all(string_copy(line_text, 1, sep - 1), " ", ""));
		key = string_replace_all(key, "\t", "");
		if (key != "offset") then continue;
		var value = chart_info_trim_value(string_copy(line_text, sep + 1, string_length(line_text) - sep));
		result = number(value, 0);
		break;
	};
	file_text_close(handle);
	return result;
};

function rpe_array_to_beat(_time_array) {
	if (!is_array(_time_array)) then return _time_array;
	if (array_length(_time_array) < 3) then return 0;
	var _denominator = array_get(_time_array, 2);
	if (_denominator == 0) then return array_get(_time_array, 0);
	return array_get(_time_array, 0) + array_get(_time_array, 1) / _denominator;
};

function chart_default_resources_load() {
	if (!variable_global_exists("default_notes_texture_loaded")) {
		global.default_notes_texture_loaded = false;
	};
	if (!global.default_notes_texture_loaded) {
		texturegroup_load("DefaultNotes", true);
		global.default_notes_texture_loaded = true;
		print("[Resources] DefaultNotes texture group loaded");
	};

	if (variable_global_exists("render_mode") && global.render_mode) then return true;
	if (!variable_global_exists("default_hitsounds_load_requested")) {
		global.default_hitsounds_load_requested = false;
	};
	if (!audio_group_is_loaded(audiogroup_hitsounds)
		&& !global.default_hitsounds_load_requested) {
		audio_group_load(audiogroup_hitsounds);
		global.default_hitsounds_load_requested = true;
		print("[Resources] audiogroup_hitsounds loading");
	};
	return true;
};

function chart_default_resources_ready() {
	if (variable_global_exists("render_mode") && global.render_mode) then return true;
	return audio_group_is_loaded(audiogroup_hitsounds);
};

function chart_default_resources_progress() {
	if (variable_global_exists("render_mode") && global.render_mode) then return 1;
	if (audio_group_is_loaded(audiogroup_hitsounds)) then return 1;
	return audio_group_load_progress(audiogroup_hitsounds);
};

function chart_default_resources_unload() {
	if (variable_global_exists("default_notes_texture_loaded")
		&& global.default_notes_texture_loaded) {
		texturegroup_unload("DefaultNotes");
		global.default_notes_texture_loaded = false;
		print("[Resources] DefaultNotes texture group unloaded");
	};
	if (variable_global_exists("default_hitsounds_load_requested")
		&& global.default_hitsounds_load_requested) {
		if (audio_group_is_loaded(audiogroup_hitsounds)) {
			audio_group_stop_all(audiogroup_hitsounds);
			audio_group_unload(audiogroup_hitsounds);
		};
		global.default_hitsounds_load_requested = false;
		print("[Resources] audiogroup_hitsounds unloaded");
	};
};

function render_hitsound_path(_default_sound, _custom_path = "") {
	var _path = _custom_path;
	if (!is_string(_path) || !string_length(_path) || !file_exists(_path)) {
		switch (_default_sound) {
			case snd_note_drag: _path = working_directory + "render_sfx/drag.wav"; break;
			case snd_note_flick: _path = working_directory + "render_sfx/flick.wav"; break;
			default: _path = working_directory + "render_sfx/tap.wav"; break;
		};
	};
	return file_exists(_path) ? _path : "";
};

function render_schedule_hitsound(_default_sound, _event_time, _custom_path = "") {
	if (!(variable_global_exists("render_mode") && global.render_mode)) then return false;
	var _path = render_hitsound_path(_default_sound, _custom_path);
	if (!string_length(_path)) then return false;
	if (!variable_global_exists("render_hitsounds") || !is_array(global.render_hitsounds)) {
		global.render_hitsounds = [];
	};
	array_add(global.render_hitsounds, {
		path: _path,
		time: max(0, real(_event_time)),
		volume: 0.7
	});
	return true;
};

function render_play_hitsound(_default_sound, _custom_path = "") {
	if (variable_global_exists("render_mode") && global.render_mode) {
		if (variable_instance_exists(id, "render_hitsound_scheduled")
			&& bool(variable_instance_get(id, "render_hitsound_scheduled"))) then return true;
		var _path = render_hitsound_path(_default_sound, _custom_path);
		if (string_length(_path)) {
			var _event_time = global.render_frame / max(1, global.render_fps);
			return bool(video_renderer_add_hitsound(_path, _event_time, 0.7));
		};
		return false;
	};
	if (audio_exists(_default_sound)) then audio_play_sound(_default_sound, 0, false);
	return true;
};

function rpe_play_hitsound(_default_sound, _custom_fmod_sound = -1, _custom_path = "") {
	if (variable_global_exists("render_mode") && global.render_mode) {
		return render_play_hitsound(_default_sound, _custom_path);
	};
	if (_custom_fmod_sound > 0 && instance_exists(oMedia)) {
		var _media = instance_find(oMedia, 0);
		if (_media.track > 0) then fmod_system_select(_media.track);
		var _channel = fmod_system_play_sound(_custom_fmod_sound, false);
		if (_channel > 0) then fmod_channel_control_set_volume(_channel, 1);
		return;
	};
	return render_play_hitsound(_default_sound);
};

function RPE() constructor{
	static chart = undefined;
	static Texture = {};
	static Gif = {};
	static HitSounds = {};
	//static BPMList = undefined;
	
	static chart_info = {
		"name" : "",
		"level" : "",
		"offset" : 0,
		"meta_offset" : 0,
		"info_offset" : 0,
		"song" : "",
		"background" : ""
	};
	
	static version = 0;
	
	static line_list = []; // 缂傚倸鍊烽悞锕傚磿閹惰姤鍊舵繝闈涱儐閸嬵亪鏌涢弴銊ュ闁荤喎缍婇幃妤呮晲鎼粹€愁潾闂?
	static attachUI_Group = ["default" , "pause" , "combonumber" , "combo" , "score" , "bar" , "name" , "level"]; // UI缂傚倸鍊搁崐鐑芥倿閿曞倸鍨傞柣銏犳啞閸嬧晠鏌涢幘妤€鎳愰敍?
	static fatherLineList = [];  // 闂傚倷鑳剁划顖炴偋閺囩喐娅犻幖娣妼閸氬綊骞栨潏鍓ф偧濞戞挸绉归弻銊モ槈濡警浠鹃梺绋匡功閸嬬喓妲?
	static Texture = {}; // 缂傚倸鍊烽悞锕傚磿閸愯鑰块梺顒€绉寸粻鏍р攽閻樻彃顏☉鎾崇Ч閺屻劌鈽夊Ο渚痪闂佺锕﹂崑鐔烘?
	static _notes = []; // 闂傚倷绀佸﹢閬嶃€傛禒瀣；闁瑰墽绮悡娑㈡煕椤愶絿绠ユ俊顖楀亾闂備胶绮幐鍛婃櫠鎼达絽鍨濇い鎾卞灪閺呮粓鏌涢幘妤€鎳愰崢?
	static chart_time = [0 , 0]; // chart real time / multi-BPM compensation
	static Reader = (func(_chart){
		var f = (string_length(_chart) ? _chart : ($"{working_directory}chart/Chart_IN.json"));
		show_debug_message($"[R-Chart] Loading: {f}");
		if (!file_exists(f)) {
			show_debug_message($"[R-Chart] Missing file: {f}");
			return false;
		};

		// Keep native buffer reads on the hot path. The assignments must remain
		// separate because YYC can treat a prior local as unset in a comma var.
		var buff = buffer_load(f);
		var r = "";
		var buffer_read_ok = false;
		if (!is_undefined(buff)) {
			try {
				r = buffer_read(buff, buffer_text);
				buffer_read_ok = is_string(r);
			} catch (e) {
				delete(e);
			};
			if (buffer_exists(buff)) then buffer_delete(buff);
		};

		// Fallback for runtimes that cannot read the local buffer handle.
		if (!buffer_read_ok) {
			var text_handle = file_text_open_read(f);
			if (is_undefined(text_handle) || text_handle < 0) {
				show_debug_message($"[R-Chart] Failed to open chart text: {f}");
				return false;
			};
			var text_buffer = buffer_create(65536, buffer_grow, 1);
			while (!file_text_eof(text_handle)) {
				buffer_write(text_buffer, buffer_text, file_text_readln(text_handle));
				buffer_write(text_buffer, buffer_text, "\n");
			};
			file_text_close(text_handle);
			buffer_seek(text_buffer, buffer_seek_start, 0);
			r = buffer_read(text_buffer, buffer_text);
			buffer_delete(text_buffer);
		};
		if (!is_string(r) || !string_length(r)) {
			show_debug_message($"[R-Chart] Empty chart data: {f}");
			return false;
		};

		var parsed_chart = undefined;
		try {
			parsed_chart = json_parse(r);
		} catch (e) {
			show_debug_message($"[R-Chart] JSON parse failed: {e.message}");
			delete(e);
			return false;
		};
		delete(r);
		if (!is_struct(parsed_chart) || !struct_exists(parsed_chart, "META") || !is_struct(parsed_chart.META)) {
			show_debug_message("[R-Chart] Invalid RPE chart: META is missing");
			delete(parsed_chart);
			return false;
		};

		self.chart = parsed_chart;
		self._bpm_timeline = undefined; // rebuild multi-BPM map for this chart
		var meta = self.chart.META;
		self.version = real(meta[$ "RPEVersion"] ?? 0);
		print($"RPEVersion: {self.version}" , game.settings.enableDebug);
		
		self.chart_info.name = string(meta[$ "name"] ?? "");
		self.chart_info.level = string(meta[$ "level"] ?? "");
		self.chart_info.song = string(meta[$ "song"] ?? "");
		self.chart_info.background = string(meta[$ "background"] ?? "");
		if (string_length(self.chart_info.song) && file_exists(InChartPath + self.chart_info.song)) {
			game.folder_chart.music = self.chart_info.song;
		};
		if (string_length(self.chart_info.background) && file_exists(InChartPath + self.chart_info.background)) {
			game.folder_chart.bg = self.chart_info.background;
		};
		var meta_offset = real(meta[$ "offset"] ?? 0);
		var info_offset = rpe_read_info_offset_ms(InChartPath);
		self.chart_info.meta_offset = meta_offset;
		self.chart_info.info_offset = info_offset;
		self.chart_info.offset = meta_offset + info_offset;
		print($"RPE offset(ms): META={meta_offset}, info={info_offset}, total={self.chart_info.offset}", game.settings.enableDebug);
		
		delete(self.chart.META);
		
		print("[R-Chart] Done." , game.settings.enableDebug);
		return true;
	});
	
	///@desc RPE闂傚倷绀侀幉锛勬暜閸ヮ剙纾归柡鍥ュ灪閸嬧晠鏌涢幘妤€鎳忛敍蹇涙⒑閸撹尙鍘涢柛鐘崇墵閹﹢鏁嶉崟銊ヤ壕?
	static CreateLines = (func(){
		// 闂傚倷绀侀幖顐⑽涘▎蹇ｇ劷婵炲棙鍔栭崣蹇涚叓閸ャ劎鈯曢柣鎺曞亹閳ь剙绠嶉崕閬嶅箠鎼淬劌閿ゅ┑鐘叉处閻撴洟鏌熼崫鍕靛剰闁逞屽墯濞茬喖骞冩ィ鍐ㄧ鐟滃繐螞椤栫偞鐓欑紒瀣健椤庢銇勯敐鍡欏弨闁哄矉绻濆畷鐓庘攽閹邦厜锕傛⒑闁偛鑻晶浼存煕濡姴娲ょ粻顖炴煟濡も偓閻楀繘銆呴弻銉﹀€甸柨婵嗗€瑰▍鍡樸亜?
		var judge_lines = game_1.chart[$ "judgeLineList"] ?? [];
		if (!is_array(judge_lines)) then judge_lines = [];
		var line_group_size = array_length(judge_lines);
		print($"Lines Count: {line_group_size}");
		var eff_line_count = 0;
		if(file_exists($"{InChartPath}extra.json")){
			//var e_buff = (buffer_load($"{InChartPath}extra.json")),
			//	e_json = (json_parse(buffer_read(e_buff , buffer_text)));
			//buffer_delete(e_buff);
					
			//eff_line_count = (array_length(e_json.effects));
			//delete(e_json);
			//eff_line_count = 16;
		};
		print(eff_line_count);
		
		// Preserve chart indices even when a line has no usable event layers.
		self.line_list = array_create(line_group_size, noone);
		self._notes = [];
		var _note_preload = real(game.settings.notePreloadSeconds ?? 15);
		var _chart_offset_sec = real(game_1.chart_info.offset ?? 0) / 1000;
		for(var i = 0 ; i < line_group_size - eff_line_count ; i ++){	
			var //,
				events = [];// = l_s[$ "eventLayers"];
			
			// (line)缂傚倸鍊烽悞锕傚磿閸愬樊鐒介柨鐔哄Т绾惧潡鏌熺紒銏犳灈缂佲偓?
			var l_s = judge_lines[i];//,
			if (!is_struct(l_s)) then continue;
			global._id = i;
			if(struct_exists(l_s , "eventLayers")){
				events = l_s[$ "eventLayers"];
				if(!is_array(events)) then events = [];
				
				//global.__line_id = i;
				for(var o = 0 ; o < array_length(events) ; o ++){
					var events_index = (events[o]);
					
					if(!is_struct(events_index)) then continue;
					
					global.__id = o;
					
					struct_foreach(events_index , (func(name , val){//濠德板€楁慨鐑藉磻閻樺樊鍤曢柟鎹愭硾閸ㄦ繈鏌涢銈呮灁闁?
						if(name == "speedEvents") then return;
						if(!is_array(val)) then return;
						// 闂傚倷绀侀幉锛勬暜閹烘嚦娑樷槈濮橆厼浠?						//
						//var _sort = (function(x1 , x2){
						//		//if(is_array(x1.startTime)) {
						//	//	x1.startTime = (game_1.Math.arrToBeat(x1.startTime))	
						//	//};
						//	var x1_time = (game_1.Math.arrToBeat(x1.startTime)),
						//		x2_time = (game_1.Math.arrToBeat(x2.startTime));
						//	x1.startTime = x1_time;
						//	x2.startTime = x2_time;
						//	x1.endTime = (game_1.Math.arrToBeat(x1.endTime));
						//	x2.endTime = (game_1.Math.arrToBeat(x2.endTime));
			
						//	if(x1_time < x2_time) then return(-1);
						//	if(x1_time > x2_time) then return(1);
						//	return(0);
						//});
						
						// easingType remapped once in oLine_1 Create; only sanitize left/right here
						for(var e = 0 ; e < array_length(val) ; e ++){
							var _e_left = (val[e][$ "easingLeft"] ?? 0),
								_e_right = (val[e][$ "easingRight"] ?? 1);
								
							if((_e_left == _e_right) || (_e_left < 0 || _e_left > 1 || _e_right < 0 || _e_right > 1)){
								_e_left = 0;
								_e_right = 1;
							};
							
							struct_set(game_1.chart.judgeLineList[global._id].eventLayers[global.__id][$ name][e] , "easingLeft" , _e_left);
							struct_set(game_1.chart.judgeLineList[global._id].eventLayers[global.__id][$ name][e] , "easingRight" , _e_right);
						};
						//array_sort(val , _sort);
					}));
					if(struct_exists(l_s , "extended") && o == 0){
						//struct_foreach(l_s[$ "extended"] , function(_name , _val){
						//	// 闂傚倷绀侀幉锛勬暜閹烘嚦娑樷槈濮橆厼浠?						//
						//var _sort = (function(x1 , x2){
						//		//if(is_array(x1.startTime)) {
						//		//	x1.startTime = (game_1.Math.arrToBeat(x1.startTime))	
						//		//};
						//		var x1_time = (game_1.Math.arrToBeat(x1.startTime)),
						//			x2_time = (game_1.Math.arrToBeat(x2.startTime));
						//		x1.startTime = x1_time;
						//		x2.startTime = x2_time;
						//		x1.endTime = (game_1.Math.arrToBeat(x1.endTime));
						//		x2.endTime = (game_1.Math.arrToBeat(x2.endTime));
			
						//		if(x1_time < x2_time) then return(-1);
						//		if(x1_time > x2_time) then return(1);
						//		return(0);
						//	});
							
						//	var index = [ 0, 1, 3, 2, 6, 5, 4, 7, 9, 8, 12, 11, 10, 13, 15, 14, pointer_null, 17, 16, pointer_null, 19, 18, 22, 21, 20, 23, 25, 24, pointer_null, 27, 26, 28 ];
						//	for(
						//var e = 0 ; e < array_length(_val) ; e ++){
						//		var type_index = (real( _val[e][$ "easingType"] ));
						//		struct_set(game_1.chart.judgeLineList[global._id].extended[$ _name][e] , "easingType" , ( index[ (type_index > 31 ? 0 : type_index)] ) );
						//		var _e_left = (_val[e][$ "easingLeft"] ?? 0),
						//			_e_right = (_val[e][$ "easingRight"] ?? 1);
								
						//		if((_e_left == _e_right) || (_e_left < 0 || _e_left > 1 || _e_right < 0 || _e_right > 1)){
						//			_e_left = 0;
						//			_e_right = 1;
						//		};
							
						//		struct_set(game_1.chart.judgeLineList[global._id].extended[$ _name][e] , "easingLeft" , _e_left);
						//		struct_set(game_1.chart.judgeLineList[global._id].extended[$ _name][e] , "easingRight" , _e_right);
						//	};
						//	array_sort(_val , _sort);
						//});
					};
				};
			};
			
			var _isFather = (l_s[$ "father"]);
			if (!is_real(_isFather)) then _isFather = -1; 
			print($"Line[{i}]FatherID->{_isFather >= 0 ? _isFather : "undefined"}" , game.settings.enableDebug);
				//enableFatherLine = ()
			var l = (instance_create_depth(room_width / 2 , room_height / 2 , 0 , oLine_1 , {
				"line_id" : i, // 缂傚倸鍊烽悞锕€鐣峰Ο琛℃灃闁哄洨鍋愰弸鏃堟煙鏉堚晝顩?
				"bindUI" : (is_undefined(l_s[$ "attachUI"]) ? 0 : l_s[$ "attachUI"]), // UI缂傚倸鍊搁崐鐑芥倿閿曞倸鍨傞柣銏犳啞閸?闂傚倷绀侀幖顐⑽涘Δ鍛９濡炲娴风粻鏂款熆閼搁潧濮堥柛銈傚亾闂備礁鎲￠崝锕傚储娴犲鏁佹慨妯垮煐閻撴盯鏌嶈閸撶喖銆佸☉妯锋婵☆垰鍚嬪暩)
				"image" : (l_s[$ "Texture"]), // 缂傚倸鍊烽悞锕€鐣峰Ο琛℃灃闁哄洨鍋愰弸鏃堟煙鐎电啸婵☆偒鍨堕弻娑㈡晜鐠囨彃绠洪梺?
				"anchor" : (l_s[$ "anchor"] ?? [0.5, 0.5]),
				"isFather" : (_isFather), // 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炴挻鍩冮崑鎾垛偓瑙勬磸閸庣敻銆佸☉姗嗙叆闁告洦鍓氶褰掓⒒娴ｈ櫣甯涢柣妤佹礃閺呰埖鎯旈妸銉ユ優?-1婵犵數鍋為崹鍫曞箰妤ｅ啫纾块柕鍫濇啒濞戙垹围濠㈣泛顑呮禍顖炴⒑閸涘﹥灏紒鈧担绯曟灁?
				"isGif" : (l_s[$ "isGif"] ?? false), // 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炶揪绲藉﹢閬嶅煝閺冨倻纾奸柍銉ョ－閸楁
				"isCover" : ((l_s[$ "isCover"] ?? true)), // 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炴挻鍩冮崑鎾垛偓瑙勬磸閸庣敻銆佸☉姗嗙叆闁告洦鍓氶褰掓⒒閸屾瑧璐伴柛鎿勭畵瀹曟澘顫濈捄铏癸紳?婵犵數鍋為崹鍫曞箰閸濄儳鐭撻柣鎴ｆ閻掑灚銇勯幒鍡椾壕闂佸摜鍠庨崯鍧椻€栨繝鍐瘈婵﹩鍓涢崫妤€顪冮妶鍡欏缂佸鍨块幆?
				"sizeControl" : (l_s[$ "sizeControl"]), // notes闂傚倷鐒﹂惇褰掑礉瀹€鈧埀顒佸嚬閸撶喐淇婇悽绋跨倞闁宠　鍋撻柣鎺戯躬閻擃偊宕惰閹癸綁鏌ｉ妸锕€鐏ラ棁?婵犵數鍋為崹鍫曞箰閸濄儳鐭撻柣鎴ｆ閻掑灚銇勯幒鍡椾壕闂佸摜鍠庨崯鍧椻€栨繝鍐瘈婵﹩鍓涢崫妤€顪冮妶鍡欏缂佸鍨块幆?
				"alphaControl" : (l_s[$ "alphaControl"]), // notes闂傚倷鐒﹂惇褰掑礉瀹€鈧埀顒佸嚬娴滅偟鍒掗鐔风窞闁归偊鍘鹃崝鐢告椤愩垺澶勬慨濠傜秺閿濈偤寮介鐐殿啇闁哄鐗嗘晶鐣屾閹殿喚纾奸柕濠忕到婵＄晫绱?婵犵數鍋為崹鍫曞箰閸濄儳鐭撻柣鎴ｆ閻掑灚銇勯幒鍡椾壕闂佸摜鍠庨崯鍧椻€栨繝鍐瘈婵﹩鍓涢崫妤€顪冮妶鍡欏缂佸鍨块幆?
				"posControl" : (l_s[$ "posControl"]),
				"yControl" : (l_s[$ "yControl"]),
				"rotFatherLine" : (l_s[$ "rotateWithFather"]), // 闂傚倷绀侀幖顐も偓姘卞厴瀹曡瀵奸弶鎴犵暰婵炶揪缍€濞咃絿澹曢懖鈺傚枑閹兼番鍨婚悵鑸电箾閸℃ɑ灏伴柛瀣樀閺屾盯骞橀懠顒夋М濠电偛鐗忔繛鈧柡宀嬬節瀹曟﹢鈥﹂幋婵嗗婵犵數鍋炲娆徫涘▎鎴犵焿鐎广儱娲犻崑鎾绘晲閸屾稒鐝曞?
				"events" : (events), // 闂傚倷鑳剁涵鍫曞疾濠靛纾块柕鍫濇嫅閼板潡鏌ｅΔ鈧悧蹇涖€呴弻銉﹀€甸柨婵嗗€瑰▍鍡樸亜?
				"extEvents" : (l_s[$ "extended"] ?? {}), // 闂傚倷绀佸﹢閬嶃€傛禒瀣柧婵炴垯鍨洪崕鎾垛偓骞垮劚濡盯銆呴弻銉﹀€甸柨婵嗗€瑰▍鍡樸亜?(闂傚倷绀侀幖顐⑽涘Δ鍛９濡炲娴风粻鏂款熆閼搁潧濮堥柛銈傚亾闂備礁鎲￠崝锕傚储娴犲鏁佹慨妯垮煐閻撴盯鏌嶈閸撶喖銆佸☉妯锋婵☆垰鍚嬪暩)
				"zOrder" : (l_s[$ "zOrder"] ?? 0), // line layer order
				"bpmfactor" : (l_s[$ "bpmfactor"] ?? 1)
			}));
			self.line_list[i] = l;
			
			var line_notes = l_s[$ "notes"] ?? [];
			if (!is_array(line_notes)) then line_notes = [];
			for(var n = 0 ; n < array_length(line_notes) ; n ++){
				var n_s = line_notes[n];
				if (!is_struct(n_s)) then continue;
				var isFake = bool(n_s[$ "isFake"] ?? false);
				if (!isFake) then maxcombo++;

				// RPE note type: 1 tap, 2 hold, 3 flick, 4 drag  -> Official: 1 tap, 2 drag, 3 hold, 4 flick
				var rpe_type = real(n_s[$ "type"] ?? 1);
				var off_type = rpe_type;
				if (rpe_type == 2) then off_type = 3;
				else if (rpe_type == 3) then off_type = 4;
				else if (rpe_type == 4) then off_type = 2;

				var st_beat = game_1.Math.arrToBeat(n_s[$ "startTime"]);
				var et_beat = game_1.Math.arrToBeat(n_s[$ "endTime"]);
				// floorPosition at note time from this line's speed integral (PCR)
				var note_floor = 0;
				var end_floor = 0;
				if (instance_exists(l) && variable_instance_exists(l, "rpe_floor_at_sec")) {
					// PCR: note.floorPosition is precomputed from the same speedEvents as line floor.
					// Runtime: note_pos = speed * (note.floor - line.floor)
					// Both must use the SAME second clock (chart seconds / bpmfactor).
					// Do not bake META.offset here; runtime line_sec already subtracts chart offset.
					// Note times are in line-local chart seconds.
					var st_abs = game_1.Math.beatToAbsSec(st_beat);
					var et_abs = game_1.Math.beatToAbsSec(et_beat);
					note_floor = l.rpe_floor_at_sec(st_abs);
					if (off_type == 3) then end_floor = l.rpe_floor_at_sec(et_abs);
				};
				var note_start_sec = game_1.Math.beatToAbsSec(st_beat);
				var note_end_sec = game_1.Math.beatToAbsSec(et_beat);

				var n_alpha = real(n_s[$ "alpha"] ?? 255);
				var n_size = real(n_s[$ "size"] ?? 1);
				var n_speed = real(n_s[$ "speed"] ?? 1);
				var n_yoff = real(n_s[$ "yOffset"] ?? 0);
				var n_vis = real(n_s[$ "visibleTime"] ?? 999999);
				var n_above_raw = struct_exists(n_s, "above") ? n_s[$ "above"]
					: (struct_exists(n_s, "isAbove") ? n_s[$ "isAbove"] : 1);
				var n_above = is_bool(n_above_raw) ? n_above_raw : (number(n_above_raw, 1) == 1);
				var note_tint = c_white;
				var note_tint_data = n_s[$ "tint"];
				if (!is_array(note_tint_data) || array_length(note_tint_data) < 3) then note_tint_data = n_s[$ "color"];
				if (is_array(note_tint_data) && array_length(note_tint_data) >= 3) {
					note_tint = make_color_rgb(
						clamp(real(note_tint_data[0]), 0, 255),
						clamp(real(note_tint_data[1]), 0, 255),
						clamp(real(note_tint_data[2]), 0, 255)
					);
				};
				var has_hit_tint = false;
				var hit_tint = c_white;
				var hit_tint_data = n_s[$ "tintHitEffects"];
				if (is_array(hit_tint_data) && array_length(hit_tint_data) >= 3) {
					has_hit_tint = true;
					hit_tint = make_color_rgb(
						clamp(real(hit_tint_data[0]), 0, 255),
						clamp(real(hit_tint_data[1]), 0, 255),
						clamp(real(hit_tint_data[2]), 0, 255)
					);
				};
				var custom_sound = -1;
				var custom_fmod_sound = -1;
				var custom_hitsound_path = "";
				var hitsound_name = string(n_s[$ "hitsound"] ?? "");
				if (hitsound_name == "tap.mp3") {
					custom_sound = snd_note_tap;
				} else if (hitsound_name == "drag.mp3") {
					custom_sound = snd_note_drag;
				} else if (hitsound_name == "flick.mp3") {
					custom_sound = snd_note_flick;
				} else if (string_length(hitsound_name)) {
					var hitsound_rel = string_replace_all(hitsound_name, "\\", "/");
					if (string_pos("..", hitsound_rel) <= 0 && string_char_at(hitsound_rel, 1) != "/") {
						var hitsound_path = InChartPath + hitsound_rel;
						if (file_exists(hitsound_path)) {
							custom_hitsound_path = hitsound_path;
						};
						if (file_exists(hitsound_path) && instance_exists(oMedia)
							&& !(variable_global_exists("render_mode") && global.render_mode)) {
							if (!struct_exists(game_1, "HitSounds") || !is_struct(game_1.HitSounds)) then game_1.HitSounds = {};
							if (!struct_exists(game_1.HitSounds, hitsound_rel)) {
								var _media = instance_find(oMedia, 0);
								if (_media.track > 0) then fmod_system_select(_media.track);
								var loaded_hitsound = fmod_system_create_sound(hitsound_path, FMOD_MODE.DEFAULT);
								if (loaded_hitsound > 0) then game_1.HitSounds[$ hitsound_rel] = loaded_hitsound;
							};
							if (struct_exists(game_1.HitSounds, hitsound_rel)) then custom_fmod_sound = game_1.HitSounds[$ hitsound_rel];
						};
					};
				};

				var note_instance = instance_create_depth(-999 , -999 , DEPTH.NOTE , oNote_1 , {
					"type" : off_type,
					"rpe_type" : rpe_type,
					"isAbove" : n_above,
					"alpha" : (n_alpha / 255),
					"start_beat" : st_beat,
					"end_beat" : et_beat,
					"start_sec" : note_start_sec,
					"end_sec" : note_end_sec,
					"hold_beat" : max(0, et_beat - st_beat),
					"xOffset" : real(n_s[$ "positionX"] ?? 0),
					"yOffset" : n_yoff,
					"yorigin" : (n_yoff / 900),
					"floorPosition" : note_floor,
					"endFloorPosition" : end_floor,
					"holdFloorLength" : (end_floor - note_floor),
					"size" : n_size,
					"speed" : n_speed,
					"visibleTime" : n_vis,
					"isFake" : isFake,
					"note_tint" : note_tint,
					"has_hit_tint" : has_hit_tint,
					"hit_tint" : hit_tint,
					"custom_sound" : custom_sound,
					"custom_fmod_sound" : custom_fmod_sound,
					"custom_hitsound_path" : custom_hitsound_path,
					"line_id" : i
				});
				var note_factor = real(l.bpmfactor);
				if (!is_real(note_factor) || note_factor <= 0) then note_factor = 1;
				var note_hit_sec = _chart_offset_sec + note_factor * note_start_sec;
				var note_end_hit_sec = _chart_offset_sec + note_factor * note_end_sec;
				if (variable_global_exists("render_mode") && global.render_mode && !isFake
					&& instance_exists(note_instance)) {
					var note_hitsound_time = note_hit_sec;
					if (off_type != 2 && off_type != 4) {
						note_hitsound_time += note_factor * note_instance.hitTime2 * 0.001;
					};
					note_instance.render_hitsound_scheduled = render_schedule_hitsound(
						note_instance.sound, note_hitsound_time, custom_hitsound_path);
				};
				var note_lead = _note_preload;
				if (is_finite(n_vis) && n_vis >= 0 && n_vis < 999999) then note_lead = min(note_lead, note_factor * n_vis);
				array_add(self._notes, {
					id: note_instance,
					startSec: note_start_sec,
					endSec: note_end_sec,
					activateSec: note_hit_sec - note_lead,
					hitSec: note_hit_sec,
					alwaysActive: (n_speed == 0 || (off_type == 3 && note_hit_sec <= 0 && note_end_hit_sec > 0))
				});
			};
		};
		// PCR multi-highlight groups every note with the same unscaled RPE down time.
		array_sort(self._notes, function(a, b) {
			if (a.startSec < b.startSec) then return -1;
			if (a.startSec > b.startSec) then return 1;
			return 0;
		});
		var _group_start = 0;
		while (_group_start < array_length(self._notes)) {
			var _group_end = _group_start + 1;
			var _group_time = self._notes[_group_start].startSec;
			while (_group_end < array_length(self._notes)
				&& self._notes[_group_end].startSec == _group_time) _group_end++;
			if (_group_end - _group_start > 1) {
				for (var _hi = _group_start; _hi < _group_end; _hi++) {
					var _highlight_note = self._notes[_hi].id;
					if (instance_exists(_highlight_note)) then _highlight_note.hl = 1;
				};
			};
			_group_start = _group_end;
		};
		// Only notes inside the configured local-time preload window remain active.
		array_sort(self._notes, function(a, b) {
			if (a.activateSec < b.activateSec) then return -1;
			if (a.activateSec > b.activateSec) then return 1;
			if (a.hitSec < b.hitSec) then return -1;
			if (a.hitSec > b.hitSec) then return 1;
			return 0;
		});
		self._note_activation_enabled = (_note_preload > 0);
		self._note_activation_index = (self._note_activation_enabled ? 0 : array_length(self._notes));
		self._note_activation_last_time = -infinity;
		if (self._note_activation_enabled) {
			for (var _di = 0; _di < array_length(self._notes); _di++) {
				var _activation_note = self._notes[_di];
				if (_activation_note.alwaysActive) {
					var _activation_key = string(_activation_note.id);
					if (struct_exists(self._note_activation_records, _activation_key)) {
						self._note_activation_records[$ _activation_key].activated = true;
					};
				} else {
					instance_deactivate_object(_activation_note.id);
				};
			};
		};
		// Reject invalid/cyclic father chains before runtime transforms them.
		for (var _fi = 0; _fi < array_length(self.line_list); _fi++) {
			var _fl = self.line_list[_fi];
			if (!instance_exists(_fl)) then continue;
			var _seen = array_create(array_length(self.line_list), false);
			var _parent = _fl.isFather;
			var _valid_parent = true;
			while (is_real(_parent) && _parent >= 0) {
				if (_parent >= array_length(self.line_list) || _parent == _fi || _seen[_parent]
					|| !instance_exists(self.line_list[_parent])) {
					_valid_parent = false;
					break;
				};
				_seen[_parent] = true;
				_parent = self.line_list[_parent].isFather;
			};
			if (!_valid_parent) then _fl.isFather = -1;
		};
		// Resolve line depth from zOrder (PCR-aligned).
		// PCR LEVEL_CONTROLLER sorts obj_judgeline by:
		//   1) z(=zOrder) ascending
		//   2) stable id ascending when z is equal
		// then draws back -> front.  GM depth is inverse of draw order, so we
		// assign decreasing depth after the same sort.
		//
		// zOrder is an ordering key, not an absolute GameMaker depth.
		// Equal keys preserve judgeLineList order, so later lines draw in front.
		if (is_array(self.line_list)) {
			var _n_lines = array_length(self.line_list);
			var _order = array_create(0);
			for (var _zi = 0; _zi < _n_lines; _zi++) {
				var _l0 = self.line_list[_zi];
				if (!instance_exists(_l0)) then continue;
				var _z0 = 0;
				if (variable_instance_exists(_l0, "zOrder") && is_real(_l0.zOrder)) then _z0 = real(_l0.zOrder);
				if (!is_finite(_z0)) then _z0 = 0;
				_l0.zOrder = _z0;
				// PCR alias used by reference project
				_l0.z = _z0;
				if (!variable_instance_exists(_l0, "line_id") || !is_real(_l0.line_id)) then _l0.line_id = _zi;
				array_add(_order, _l0);
			};

			// Insertion sort: zOrder ASC, then line_id ASC (PCR _compare)
			for (var _i = 1; _i < array_length(_order); _i++) {
				var _cur = _order[_i];
				var _j = _i - 1;
				while (_j >= 0) {
					var _prev = _order[_j];
					var _dz = real(_prev.zOrder) - real(_cur.zOrder);
					var _swap = false;
					if (_dz > 0) {
						_swap = true;
					} else if (_dz == 0 && real(_prev.line_id) > real(_cur.line_id)) {
						_swap = true;
					};
					if (!_swap) then break;
					_order[_j + 1] = _prev;
					_j--;
				};
				_order[_j + 1] = _cur;
			};

			// Keep every line behind regular notes and Hold notes (NOTE + 1).
			var _line_count = array_length(_order);
			var _depth_span = DEPTH.LINE - (DEPTH.NOTE + 2);
			var _depth_step = 1;
			if (_line_count > _depth_span + 1) {
				_depth_step = _depth_span / max(1, _line_count - 1);
			};
			for (var _ri = 0; _ri < _line_count; _ri++) {
				_order[_ri].depth = DEPTH.LINE - _ri * _depth_step;
			};
		};
		print("[C-Lines] Done." , game.settings.enableDebug);
		delete(game_1.chart.judgeLineList);
	});
	
	///@desc RPE闂傚倷娴囧銊╂倿閿曗偓椤灝顫滈埀顒勩€佸Δ鍛亜闁绘挸娴烽ˇ褍顪冮妶鍡楀潑闁稿鎸剧槐?(aligned with PCR ArrayToTime / BPM helpers)
	static Math = ({
		///@desc Array -> Beat  [bar, num, den] => bar + num/den
		arrToBeat : rpe_array_to_beat,
		
		///@desc Second -> Beat (single BPM)
		secToBeat : (func(_sec , _bpm){
			if(_bpm == 0) then return(0);
			return(_sec * (_bpm / 60));
		}),
		
		///@desc Beat -> Second (single BPM)
		beatToSec : (func(_beat , _bpm){
			if(_bpm == 0) then return(0);
			return(_beat * (60 / _bpm));
		}),

		///@desc Build multi-BPM timeline once (PCR BpmList)
		// segments: { startBeat, endBeat, bpm, floorSec }
		// floorSec = absolute seconds at startBeat
		ensureBpmTimeline : (func(){
			if (struct_exists(game_1, "_bpm_timeline") && is_array(game_1._bpm_timeline) && array_length(game_1._bpm_timeline) > 0) {
				return game_1._bpm_timeline;
			};
			var tl = [];
			var list = [];
			if (is_struct(game_1.chart) && struct_exists(game_1.chart, "BPMList") && is_array(game_1.chart.BPMList)) {
				list = game_1.chart.BPMList;
			};
			if (!is_array(list) || array_length(list) <= 0) {
				array_add(tl, { startBeat: 0, endBeat: infinity, bpm: 140, floorSec: 0 });
				game_1._bpm_timeline = tl;
				return tl;
			};
			// Normalize like CCBPMList: stable sort, then let the last duplicate win.
			var tmp = [];
			for (var i = 0; i < array_length(list); i++) {
				var e = list[i];
				if (!is_struct(e)) then continue;
				var raw_start_time = e[$ "startTime"] ?? 0;
				var start_part_0 = (is_array(raw_start_time) && array_length(raw_start_time) > 0) ? array_get(raw_start_time, 0) : raw_start_time;
				var start_part_1 = (is_array(raw_start_time) && array_length(raw_start_time) > 1) ? array_get(raw_start_time, 1) : 0;
				var start_part_2 = (is_array(raw_start_time) && array_length(raw_start_time) > 2) ? array_get(raw_start_time, 2) : 1;
				var _rpe_start_beat_value = start_part_0;
				if (start_part_2 != 0) then _rpe_start_beat_value += start_part_1 / start_part_2;
				var bv = real(e[$ "bpm"] ?? 140);
				if (bv <= 0) then bv = 140;
				var item = { startBeat: _rpe_start_beat_value, bpm: bv, sourceIndex: i };
				var insert_at = array_length(tmp);
				while (insert_at > 0) {
					var previous = tmp[insert_at - 1];
					if (previous.startBeat < item.startBeat) then break;
					if (previous.startBeat == item.startBeat && previous.sourceIndex < item.sourceIndex) then break;
					insert_at--;
				};
				array_insert(tmp, insert_at, item);
			};
			var normalized = [];
			for (var ni = 0; ni < array_length(tmp); ni++) {
				var candidate = tmp[ni];
				var normalized_count = array_length(normalized);
				if (normalized_count > 0 && normalized[normalized_count - 1].startBeat == candidate.startBeat) {
					normalized[normalized_count - 1] = candidate;
				} else {
					array_add(normalized, candidate);
				};
			};
			tmp = normalized;
			if (array_length(tmp) <= 0) {
				array_add(tl, { startBeat: 0, endBeat: infinity, bpm: 140, floorSec: 0 });
				game_1._bpm_timeline = tl;
				return tl;
			};
			var floor_sec = 0;
			for (var j = 0; j < array_length(tmp); j++) {
				var st = real(tmp[j].startBeat);
				var bpmv = real(tmp[j].bpm);
				var et = infinity;
				if (j < array_length(tmp) - 1) then et = real(tmp[j + 1].startBeat);
				array_add(tl, {
					startBeat: st,
					endBeat: et,
					bpm: bpmv,
					floorSec: floor_sec
				});
				if (is_finite(et)) {
					floor_sec += game_1.Math.beatToSec(et - st, bpmv);
				};
			};
			game_1._bpm_timeline = tl;
			return tl;
		}),

		segmentIndexAtBeat : (func(_beat){
			var beat = real(_beat);
			var tl = game_1.Math.ensureBpmTimeline();
			if (!is_array(tl) || array_length(tl) <= 0) then return 0;
			var low = 0;
			var high = array_length(tl);
			while (low < high) {
				var mid = (low + high) >> 1;
				if (real(tl[mid].startBeat) <= beat) then low = mid + 1;
				else high = mid;
			};
			return max(0, low - 1);
		}),

		segmentIndexAtAbsSec : (func(_sec){
			var sec = real(_sec);
			var tl = game_1.Math.ensureBpmTimeline();
			if (!is_array(tl) || array_length(tl) <= 0) then return 0;
			var low = 0;
			var high = array_length(tl);
			while (low < high) {
				var mid = (low + high) >> 1;
				if (real(tl[mid].floorSec) <= sec) then low = mid + 1;
				else high = mid;
			};
			return max(0, low - 1);
		}),

		///@desc Beat -> absolute chart seconds through the normalized BPM timeline
		beatToAbsSec : (func(_beat){
			var beat = real(_beat);
			var tl = game_1.Math.ensureBpmTimeline();
			if (!is_array(tl) || array_length(tl) <= 0) then return game_1.Math.beatToSec(beat, 140);
			var seg = tl[game_1.Math.segmentIndexAtBeat(beat)];
			return real(seg.floorSec) + game_1.Math.beatToSec(beat - real(seg.startBeat), real(seg.bpm));
		}),

		///@desc Absolute chart seconds -> continuous beat (inverse of beatToAbsSec)
		absSecToBeat : (func(_sec){
			var sec = real(_sec);
			var tl = game_1.Math.ensureBpmTimeline();
			if (!is_array(tl) || array_length(tl) <= 0) then return game_1.Math.secToBeat(sec, 140);
			var seg = tl[game_1.Math.segmentIndexAtAbsSec(sec)];
			return real(seg.startBeat) + game_1.Math.secToBeat(sec - real(seg.floorSec), real(seg.bpm));
		}),

		bpmAtAbsSec : (func(_sec){
			var tl = game_1.Math.ensureBpmTimeline();
			if (!is_array(tl) || array_length(tl) <= 0) then return 140;
			return real(tl[game_1.Math.segmentIndexAtAbsSec(_sec)].bpm);
		}),
		
		///@desc RPE easingType remap table (PCR parseEasingType)
		parseEasingType : (func(_t){
			static map = [ 0, 1, 3, 2, 6, 5, 4, 7, 9, 8, 12, 11, 10, 13, 15, 14, -1, 17, 16, -1, 19, 18, 22, 21, 20, 23, 25, 24, -1, 27, 26, 28 ];
			var t = clamp(floor(real(_t)), 0, array_length(map) - 1);
			var m = map[t];
			return(m < 0 ? 1 : m);
		})
	});
};


function PEC() constructor{
	
	// 闂備礁鎼ˇ閬嶅磿閹版澘绀堟慨姗嗗墰閺嗭箓鏌＄仦璇插姎閻熸瑱绠撻獮鏍ㄦ綇閸撗吷戦梺浼欑秮娴滃爼骞冮崷顓涘亾閿濆骸鏋欓柟鑼亾缁?
	static chart = {
		"version" : 4,
		"offset" : 0,
		"judgeLineList" : [],
		"notes" : [],
        "bpmList" : []
	};
    
    static line_group = [];
	
	
	///@desc 闂備浇宕垫慨鏉懨洪埡鍜佹晪鐟滄垿濡甸幇鏉跨倞闁冲搫鍊搁鈺呮⒒娓氬洤澧紒澶愭涧椤?
	static Reader = (func(_chart){
		var f = (string_length(_chart) ? _chart : ($"{working_directory}chart/Chart_IN.json")),
			handle = (file_text_open_read(f));
		var cl = false;
		
        // idk
		var _pe_chart_func = {
			// Notes 闂傚倸鍊搁崐鎼佹晝閵堝洤顥氭い鎾卞焺閺?            
            // 闂傚倷鐒﹀鎸庣濠婂牜鏁勯柛娑樼摠閸嬧晜銇勯幒宥堝厡闁崇粯姊婚埀顒€绠嶉崕鍗灻洪妸鈺佺疇闁告稑鐡ㄩ悡鐔兼煏婵炲灝鍔氭い蹇ｄ簼娣囧﹪骞撻幒鎾虫殘缂備礁顑呴ˇ鐢搞€侀弮鍫濈闁冲搫鍟花鐐烘⒒?            
            ///@desc Tap
			"n1" : (func(arr_args0 , arr_arg1 , arr_arg2) { 
                return(
                    { 
                        "type" : 1,
                        "speed" : arr_arg1,
                        "line_id" : (real(arr_args0[0])),
                        "time" : (real(arr_args0[1])),
                        "xOffset" : (real(arr_args0[2])),
                        "isAbove" : (bool(real(arr_args0[3]))),
                        "xscale" : arr_arg2,
                        "isFake" : (real(arr_args0[4]))
                    } 
                ); 
            }),
            
            ///@desc Hold
			"n2" : (func(arr_args0 , arr_arg1 , arr_arg2) { 
                var time = (real(arr_args0[1])),
                    holdTime = ((real(arr_args0[2])) - time);
                return(
                    { 
                        "type" : 2,
                        "speed" : arr_arg1,
                        "line_id" : (real(arr_args0[0])),
                        "time" : time,
                        "holdTime" : holdTime,
                        "xOffset" : (real(arr_args0[3])),
                        "isAbove" : (bool(real(arr_args0[4]))),
                        "xscale" : arr_arg2,
                        "isFake" : (real(arr_args0[5]))
                    } 
                ); 
            }),
            
            ///@desc Flick
			"n3" : (func(arr_args0 , arr_arg1 , arr_arg2) { 
                return(
                    { 
                        "type" : 3,
                        "speed" : arr_arg1,
                        "line_id" : (real(arr_args0[0])),
                        "time" : (real(arr_args0[1])),
                        "xOffset" : (real(arr_args0[2])),
                        "isAbove" : (bool(real(arr_args0[3]))),
                        "xscale" : arr_arg2,
                        "isFake" : (real(arr_args0[4]))
                    } 
                ); 
            }),
            
            ///@desc Drag
			"n4" : (func(arr_args0 , arr_arg1 , arr_arg2) { 
                return(
                    { 
                        "type" : 4,
                        "speed" : arr_arg1,
                        "line_id" : (real(arr_args0[0])),
                        "time" : (real(arr_args0[1])),
                        "xOffset" : (real(arr_args0[2])),
                        "isAbove" : (bool(real(arr_args0[3]))),
                        "xscale" : arr_arg2,
                        "isFake" : (real(arr_args0[4]))
                    } 
                ); 
            }),
			//  闂傚倷鐒﹀鍧楀礈閿曞倸绀堟慨姗嗗墻濞撳鏌涚仦鍓с€掓い鈺傜叀閹鏁愰崒娑欑彆濡?
			"cv" : (func(arr_args0) { 
                return([ 
                    { 
                        "time" : [
                            real(arr_args0[1]),
                            real(arr_args0[1])
                        ],
                        "value" : "self",
                        "value2" : (real(arr_args0[2]))
                    } ,
                    real(arr_args0[0]) ,
                    "speedEvents" 
                ]); 
            }),
			"cp" : (func(arr_args0) { 
                return([ 
                    { 
                        "time" : [
                            real(arr_args0[1]),
                            real(arr_args0[1])
                        ],
                        "value" : [
                            "self",
                            "self"
                        ],
                        "value2" : [
                            real(arr_args0[2]),
                            real(arr_args0[3])
                        ],
                        "easingType" : 0
                        
                    } ,
                    (real(arr_args0[0])) ,
                    "moveEvents" 
                ]); 
            }),
			"ca" : (func(arr_args0) { 
                return([ 
                    { 
                        "time" : [
                            real(arr_args0[1]),
                            real(arr_args0[1])
                        ],
                        "value" : "self",
                        "value2" : (real(arr_args0[2])),
                        "easingType" : 0
                        
                    } ,
                    (real(arr_args0[0])) ,
                    "alphaEvents" 
                ]); 
            }),
			"cd" : (func(arr_args0) { 
                return([ 
                    { 
                        "time" : [
                            real(arr_args0[1]),
                            real(arr_args0[1])
                        ],
                        "value" : "self",
                        "value2" : (real(arr_args0[2])),
                        "easingType" : 0
                        
                    } ,
                    (real(arr_args0[0])) ,
                    "rotateEvents" 
                ]); 
            }),
			//  缂傚倸鍊搁崐鎼佸磹瑜版帒绠伴柛娑橈攻閸欏繘鏌嶉崫鍕偓濠氥€呴弻銉﹀€甸柨婵嗗€瑰▍鍡樸亜?
			"cr" : (func(arr_args0) { 
                return([ 
                    { 
                        "time" : [
                            real(arr_args0[1]),
                            real(arr_args0[2])
                        ],
                        "value" : "self",
                        "value2" : (real(arr_args0[3])),
                        "easingType" : (real(arr_args0[4]))
                    } ,
                    (real(arr_args0[0])) ,
                    "rotateEvents" 
                ]); 
            }),
			"cm" : (func(arr_args0) { 
                return([ 
                    { 
                        "time" : [
                            real(arr_args0[1]),
                            real(arr_args0[2])
                        ],
                        "value" : [
                            "self",
                            "self"
                        ],
                        "value2" : [
                            real(arr_args0[3]),
                            real(arr_args0[4])
                        ],
                        "easingType" : (real(arr_args0[5]))
                    } ,
                    (real(arr_args0[0])) ,
                    "moveEvents" 
                ]); 
            }),
			"cf" : (func(arr_args0) { 
                return([ 
                    { 
                        "time" : [
                            real(arr_args0[1]),
                            real(arr_args0[2])
                        ],
                        "value" : "self",
                        "value2" : (real(arr_args0[3])),
                        "easingType" : 0
                    } ,
                    (real(arr_args0[0])) ,
                    "alphaEvents" 
                ]); 
            }),
            "bp" : (func(arr_args0){
                return({
                    "time" : arr_args0[0],
                    "bpm" : arr_args0[1]
                });
            })
		};
		while(!file_text_eof(handle)){
			
			var text = (file_text_readln(handle));
			
			//  闂傚倷绀侀崥瀣磿閹惰棄搴婇柤鑹扮堪娴滃綊鏌涢妷鎴濊嫰濞堟﹢姊虹拠鈥崇仭濠㈢懓妫涚划?
			if(!cl){
				self.chart.offset = (number(text , 0));
				cl = true;
				continue;
			};
			
			// 闂備浇宕垫慨鏉懨洪埡鍜佹晪鐟滄垿濡甸幇鏉跨倞闁冲搫鍟弳妤呮煟閻樺弶绌块悘蹇旂懇閸┾偓?闂傚倷绀侀幉锟犳偡閵夆晛纾圭憸鐗堝笒濮?
			var __t = (string_replace_all(string_copy(text , 1 , 2) , " " , "")),
				args = (string_split_ext(string_copy(text , 3 , string_length(text)) , [" " , "\n" , "\r"] , true));
			
			//  闂傚倷绀侀幉锟犳晪濡炪値鍘奸崲鏌ュ煝瀹ュ棙鍎熼柨婵嗘川閻撴梹淇婇妶蹇涙妞ゆ垶鐟╁?
			if(!array_length(args)) then continue;
			
			//  缂傚倸鍊风粈浣规櫠閻ｅ瞼鍗氱紒?
			var lineID = 0;
			
			// 婵犵數濮烽。浠嬪焵椤掆偓閸熷潡鍩€椤掆偓缂嶅﹪骞冨Ο璇茬窞閻庯綆鍏橀弸鏍倵楠炲灝鍔氶悗姘煎灣缁牊绻濋惉顤篹s闂傚倷绀侀幉锟犳偡閵夆晛纾圭憸鐗堝笒濮?闂傚倷绀侀崥瀣磿閹惰棄搴婇柤鑹扮堪娴滃綊鏌涢妷銏℃珖婵☆偒鍨崇槐鎺楀传閸曨偅鐤?
			if(string_length(__t) == 2) then lineID = (number(args[0] , -1));
			//var lineID = (number(args))
			
			//  婵犵數濮烽。浠嬪焵椤掆偓閸熷潡鍩€椤掆偓缂嶅﹪骞冨Ο璇茬窞鐎光偓閳ь剙螞椤栨粎纾奸柛婵嗗濞堢喎鈹戦悙鏉戠仸闁规瓕顕ч—鍐寠婢舵鍔峰銈呯箰鐎氀囧几閺嶎厽鐓涢柛銉㈡櫅娴滃綊鏌涚€ｎ偅宕岄柟顔瑰墲閹棃鏁嶉崟顏呭煕闂備浇宕垫慨鎾箹椤愶附鍋柛銉㈡櫆瀹?
			if(lineID == -1) then continue;
			
			//  婵犵數濮烽。浠嬪焵椤掆偓閸熷潡鍩€椤掆偓缂嶅﹪骞冨Ο璇茬窞闁归偊鍓涢ˇ顐︽⒑闂堟稓澧曢柟铏姍瀵娊骞嶉鍓э紲闂佺顫夐崝鏍兜閸撲胶纾兼い鏃囧亹鏍￠悗鍨緲鐎氼垶藝閺屻儲鐓熸い顓熷灥婢ф挳鏌℃担鍝バ㈡い顓滃姂瀹曘劑顢橀悢鐑樼€甀D , 闂傚倷绀侀幉锛勬暜濡ゅ懏鍋￠柨鏇炲€搁柨銈呪攽閻樺弶鎼愮紒鈧径鎰厽婵☆垰銇橀崥顐ｃ亜韫囨稐鎲鹃柡灞稿墲瀵板嫬鈽夊鎲嬬吹闂?
			if(array_length(self.chart.judgeLineList) - 1 < lineID) then array_add(self.chart.judgeLineList , {			
				"moveEvents" : [],
				"alphaEvents" : [],
				"rotateEvents" : [],
				"speedEvents" : []
			});
			//print($"{__t} {args}" , game.settings.enableDebug);
            if(!struct_exists(_pe_chart_func , __t)) then continue;
            
			var event;
			if(__t == "n1" || __t == "n2" || __t == "n3" || __t == "n4"){
                var line1 = (file_text_readln(handle)),
                    line2 = (file_text_readln(handle));
				var next_arg = (number(string_copy(line1 , 2 , string_length(line1)))),//((string_split_ext(string_copy(line1 , 2 , string_length(line1)) , [" " , "\n" , "\r"] , true))),
                    next_arg2 = (number(string_copy(line2 , 2 , string_length(line2))));//((string_split_ext(string_copy(line2 , 2 , string_length(line2)) , [" " , "\n" , "\r"] , true)));
                event = (_pe_chart_func[$ __t](args ,  next_arg , next_arg2));
                
                array_add(self.chart.notes , event);
			}else{
                event = (_pe_chart_func[$ __t](args));
                if(__t == "bp"){
                    array_add(self.chart.bpmList , event);
                }else array_add(self.chart.judgeLineList[event[1]][$ event[2]] , event[0]);
            };
			
			
			//if(event[2] != "notes") then 
			//else {
				//array_add(self.chart.notes , event[0]);
			//};
		};
		file_text_close(handle);
		self.chartBuffSave();
		print(array_length(self.chart.judgeLineList));
		print(array_length(self.chart.notes));
	});
	
	///@desc PEC闂傚倷娴囧銊╂倿閿曗偓椤灝顫滈埀顒勩€佸Δ鍛亜闁绘挸娴烽ˇ褍顪冮妶鍡楀潑闁稿鎸剧槐?
	static Math = ({
		///@desc Second 闂?Beat
		secToBeat : (func(_sec , _bpm){
			 return((_sec) * ((_bpm) / 60));	
		}),
		
		///@desc Beat 闂?Second
		beatToSec : (func(_beat , _bpm){
			return(_beat * (60 / _bpm));	
		}),
        
        /// @desc 闂備礁鎼ˇ閬嶅磿閹版澘绀堟慨姗嗗墰閺嗭箓鏌＄仦璇插姎闂佽￥鍊濋弻鐔兼焽閿曗偓楠炴﹢鏌?        /// @param {Real} wx 婵犵數鍋為崹鍫曞箰婵犳碍鍋嬫繝濠傜墕閻ょ偓銇勯幇鍓佺暠闂佽￥鍊濋弻鐔兼焽閿曗偓楠炴﹢鏌涢妸褍浼?
        /// @param {Real} wy 婵犵數鍋為崹鍫曞箰婵犳碍鍋嬫繝濠傜墕閻ょ偓銇勯幇鍓佺暠闂佽￥鍊濋弻鐔兼焽閿曗偓楠炴﹢鏌涢妸褑鍋?
        /// @returns {Array} [闂備浇顕х换鎺楀磻濞戞碍宕查柟閭﹀枤娑撳秶绱? 闂備浇顕х换鎺楀磻濞戞碍宕查柟閭﹀枤娑撳秶绱掔仦绋夸壕]
        pos_to_size : (func(xx , yy){
            // 缂傚倸鍊烽悞锕傚礉閺嶎厹鈧啴宕ㄩ懜顑挎睏濠电偞鍨堕惌顕€鎮炴繝鍥ㄧ厱婵犻潧妫楅鎾煕?
            var sw = 1366;
            var sh = 768;
        
            // 婵犵數鍋為崹鍫曞箰婵犳碍鍋嬫繝濠傜墕閻ょ偓銇勯幇鍫曟闁搞倖鍨块弻娑㈠箛閳轰礁顬夌紓浣鸿檸閸ㄥ爼寮婚妸銉㈡婵☆垳鍘ч。鍝勵渻閵堝棙鈷愭慨濠傜秺楠炲棝寮崼鐔告珖闂侀€炲苯澧存鐐茬箻閹囧醇椤愶絿鏆繝纰樻閸ㄤ即骞栭锔绘晩濠电姴娲﹂悡?
            var world_w = 2048;  // 1024 - (-1024)
            var world_h = 1400;  // 700 - (-700)
        
            // 闂備浇宕垫慨宕囨閵堝洦顫曢柡鍥ュ灪閸嬧晠鏌ゆ慨鎰偓鎾斥柦椤忓牏鍙撻柛銉ｅ妽鐏忓灚銇勯弬鍧楀弰闁哄本绋栭ˇ鎶芥煕閺冣偓閻楃娀骞?
            var sx = (xx + 1024) * (sw / world_w);
            var sy = sh - (yy + 700) * (sh / world_h);
        
            return [sx, sy];
        })
	});
	
    ///@desc 闂傚倷绀侀幉锛勬暜濡ゅ啰鐭欓柟瀵稿Х绾句粙鏌熼幑鎰靛殭缂佲偓閸℃稒鐓忛柛顐ｇ箖閸ｄ粙鏌￠崱妯侯棆缂?
    static CreateLines = (func(){
        var _func = (func(x1 , x2){
                if(x1.time[0] < x2.time[1]) then return(-1); 
                elif(x1.time[0] > x2.time[1]) then return(1);
                return(0);    
            });
        array_sort(self.chart.bpmList , _func);
        for(var i = 0 ; i < array_length(self.chart.judgeLineList) ; i ++){
            var _line = (self.chart.judgeLineList[i])
                
            array_sort(_line.moveEvents , _func);
            array_sort(_line.alphaEvents , _func);
            array_sort(_line.rotateEvents , _func);
            array_sort(_line.speedEvents , _func); 
            
            var l = (instance_create_depth(room_width / 2 , room_height / 2 , 0 , oLine_2 , {
                "line_id" : i,
                "events" : _line
            }));
            
            array_add(self.line_group , l);
            
        };
        array_sort(self.chart.notes , (func(x1 , x2){
            
            if(x1.time < x2.time) then return(-1); 
            elif(x1.time > x2.time) then return(1);
            return(0); 
        }));
    });
    
	///@desc 闂備浇顕уù鐑藉极閹间礁鍌ㄧ憸鏂跨暦閻㈠壊鏁囬柣妯哄暱椤忊晠姊绘笟鍥у缂佸娼ч々?
	static chartBuffSave = (function(){
		var buff = (buffer_create(1 , buffer_grow , 1));
		
		buffer_write(buff , buffer_text , json_stringify(self.chart , true));
		var n = 0,
			chart_dir = ($"{game_save_id}charts/");
		if(!directory_exists(chart_dir)) then directory_create(chart_dir);
		var path = ($"{chart_dir}{current_year}-{current_month}-{current_day}-");
		while(file_exists($"{path}{n}.json")){
			n ++;	
		};
		
		buffer_save(buff , $"{path}{n}.json");
		
		buffer_delete(buff);
		
		return;
	});
};

function pec_line_data() {
	return { moveEvents: [], alphaEvents: [], rotateEvents: [], speedEvents: [] };
}

function pec_beat_to_sec(timeline, beat) {
	if (!is_array(timeline) || array_length(timeline) <= 0) then return 0;
	var point = timeline[0];
	if (beat < point.beat) then return 0;
	for (var i = 1; i < array_length(timeline); i++) {
		if (timeline[i].beat > beat) then break;
		point = timeline[i];
	};
	return point.second + (beat - point.beat) * 60 / point.bpm;
}

function pec_bpm_at_sec(timeline, sec) {
	if (!is_array(timeline) || array_length(timeline) <= 0) then return 60;
	var point = timeline[0];
	for (var i = 1; i < array_length(timeline); i++) {
		if (timeline[i].second > sec) then break;
		point = timeline[i];
	};
	return point.bpm;
}

function pec_floor_at_sec(speed_events, sec) {
	if (!is_array(speed_events) || array_length(speed_events) <= 0) then return 0;
	var event = speed_events[0];
	if (sec < event.startSec) then return 0;
	for (var i = 1; i < array_length(speed_events); i++) {
		if (speed_events[i].startSec > sec) then break;
		event = speed_events[i];
	};
	return event.floor + (sec - event.startSec) * event.value;
}

function pec_easing(easing_id) {
	static map = [0, 1, 3, 2, 6, 5, 4, 7, 9, 8, 12, 11, 10, 13, 15, 14, 1, 17, 16, 1, 19, 18, 22, 21, 20, 23, 25, 24, 29, 27, 26, 28];
	var _id = clamp(floor(real(easing_id)), 0, array_length(map) - 1);
	return map[_id];
}

function pec_finalize_property(raw_events, timeline, kind) {
	array_sort(raw_events, function(a, b) {
		if (a.startBeat < b.startBeat) then return -1;
		if (a.startBeat > b.startBeat) then return 1;
		if (a.endBeat < b.endBeat) then return -1;
		if (a.endBeat > b.endBeat) then return 1;
		return 0;
	});
	var result = [];
	var previous = (kind == "move" ? [0, 0] : 0);
	for (var i = 0; i < array_length(raw_events); i++) {
		var source = raw_events[i];
		array_add(result, {
			startSec: pec_beat_to_sec(timeline, source.startBeat),
			endSec: pec_beat_to_sec(timeline, source.endBeat),
			start: previous,
			"end": source.target,
			easing: pec_easing(source.easing)
		});
		previous = source.target;
	};
	return result;
}

function pec_reader_load(ctx, chart_path) {
	ctx.chart = { version: 4, offsetSeconds: 0, judgeLineList: [], notes: [], bpmList: [] };
	ctx.line_group = [];
	if (!file_exists(chart_path)) then return false;
	var handle = file_text_open_read(chart_path);
	if (is_undefined(handle) || handle < 0) then return false;
	if (file_text_eof(handle)) { file_text_close(handle); return false; };
	ctx.chart.offsetSeconds = number(file_text_readln(handle), 0) / 1000 - 0.175;
	var lines = [];
	while (!file_text_eof(handle)) array_add(lines, file_text_readln(handle));
	file_text_close(handle);

	for (var row = 0; row < array_length(lines); row++) {
		var tokens = string_split_ext(lines[row], [" ", "\t", "\r", "\n"], true);
		if (array_length(tokens) <= 0) then continue;
		var command = string_lower(tokens[0]);
		if (command == "bp" && array_length(tokens) >= 3) {
			array_add(ctx.chart.bpmList, { beat: number(tokens[1], 0), bpm: max(0.0001, number(tokens[2], 60)), second: 0 });
			continue;
		};
		var is_note = (command == "n1" || command == "n2" || command == "n3" || command == "n4");
		var is_line = (command == "cv" || command == "cp" || command == "cm" || command == "cd" || command == "cr" || command == "ca" || command == "cf");
		if (!is_note && !is_line) then continue;
		if (array_length(tokens) < 2) then continue;
		var line_id = max(0, floor(number(tokens[1], 0)));
		while (array_length(ctx.chart.judgeLineList) <= line_id) array_add(ctx.chart.judgeLineList, pec_line_data());
		var _l = ctx.chart.judgeLineList[line_id];

		if (is_note) {
			var _speed = 1;
			var width_scale = 1;
			if (row + 1 < array_length(lines)) {
				var speed_modifier = string_split_ext(lines[row + 1], [" ", "\t", "\r", "\n"], true);
				if (array_length(speed_modifier) >= 2 && speed_modifier[0] == "#") { _speed = number(speed_modifier[1], 1); row++; };
			};
			if (row + 1 < array_length(lines)) {
				var scale_modifier = string_split_ext(lines[row + 1], [" ", "\t", "\r", "\n"], true);
				if (array_length(scale_modifier) >= 2 && scale_modifier[0] == "&") { width_scale = number(scale_modifier[1], 1); row++; };
			};
			var hold = (command == "n2");
			var minimum = (hold ? 7 : 6);
			if (array_length(tokens) < minimum) then continue;
			var start_beat = number(tokens[2], 0);
			var end_beat = (hold ? number(tokens[3], start_beat) : start_beat);
			var x_index = (hold ? 4 : 3);
			var side_index = (hold ? 5 : 4);
			var fake_index = (hold ? 6 : 5);
			array_add(ctx.chart.notes, {
				type: (command == "n1" ? 1 : (command == "n2" ? 2 : (command == "n3" ? 3 : 4))),
				line_id: line_id,
				startBeat: start_beat,
				endBeat: end_beat,
				xOffset: number(tokens[x_index], 0) / 115.2,
				isAbove: (number(tokens[side_index], 1) == 1),
				isFake: (number(tokens[fake_index], 0) != 0),
				speed: _speed,
				xscale: width_scale
			});
			continue;
		};

		switch (command) {
			case "cv": if (array_length(tokens) >= 4) array_add(_l.speedEvents, { beat: number(tokens[2], 0), value: number(tokens[3], 0) / 7 }); break;
			case "cp": if (array_length(tokens) >= 5) array_add(_l.moveEvents, { startBeat:number(tokens[2],0), endBeat:number(tokens[2],0), target:[number(tokens[3],0)/2048, 1-number(tokens[4],0)/1400], easing:1 }); break;
			case "cm": if (array_length(tokens) >= 7) array_add(_l.moveEvents, { startBeat:number(tokens[2],0), endBeat:number(tokens[3],0), target:[number(tokens[4],0)/2048, 1-number(tokens[5],0)/1400], easing:number(tokens[6],1) }); break;
			case "cd": if (array_length(tokens) >= 4) array_add(_l.rotateEvents, { startBeat:number(tokens[2],0), endBeat:number(tokens[2],0), target:-number(tokens[3],0), easing:1 }); break;
			case "cr": if (array_length(tokens) >= 6) array_add(_l.rotateEvents, { startBeat:number(tokens[2],0), endBeat:number(tokens[3],0), target:-number(tokens[4],0), easing:number(tokens[5],1) }); break;
			case "ca": if (array_length(tokens) >= 4) array_add(_l.alphaEvents, { startBeat:number(tokens[2],0), endBeat:number(tokens[2],0), target:number(tokens[3],0)/255, easing:1 }); break;
			case "cf": if (array_length(tokens) >= 5) array_add(_l.alphaEvents, { startBeat:number(tokens[2],0), endBeat:number(tokens[3],0), target:number(tokens[4],0)/255, easing:1 }); break;
		};
	};

	if (array_length(ctx.chart.bpmList) <= 0) then array_add(ctx.chart.bpmList, { beat:0, bpm:60, second:0 });
	array_sort(ctx.chart.bpmList, function(a,b) { return a.beat-b.beat; });
	for (var bpm_i = 1; bpm_i < array_length(ctx.chart.bpmList); bpm_i++) {
		var previous = ctx.chart.bpmList[bpm_i-1];
		ctx.chart.bpmList[bpm_i].second = previous.second + (ctx.chart.bpmList[bpm_i].beat-previous.beat)*60/previous.bpm;
	};
	for (var line_i = 0; line_i < array_length(ctx.chart.judgeLineList); line_i++) {
		var item = ctx.chart.judgeLineList[line_i];
		item.moveEvents = pec_finalize_property(item.moveEvents, ctx.chart.bpmList, "move");
		item.alphaEvents = pec_finalize_property(item.alphaEvents, ctx.chart.bpmList, "alpha");
		item.rotateEvents = pec_finalize_property(item.rotateEvents, ctx.chart.bpmList, "rotate");
		array_sort(item.speedEvents, function(a,b) { return a.beat-b.beat; });
		var floor_value = 0;
		for (var speed_i = 0; speed_i < array_length(item.speedEvents); speed_i++) {
			var speed_item = item.speedEvents[speed_i];
			speed_item.startSec = pec_beat_to_sec(ctx.chart.bpmList, speed_item.beat);
			if (speed_i > 0) {
				var previous_speed = item.speedEvents[speed_i-1];
				floor_value += (speed_item.startSec-previous_speed.startSec)*previous_speed.value;
			};
			speed_item.floor = floor_value;
		};
	};
	for (var note_i = 0; note_i < array_length(ctx.chart.notes); note_i++) {
		var note = ctx.chart.notes[note_i];
		var speed_events = ctx.chart.judgeLineList[note.line_id].speedEvents;
		note.startSec = pec_beat_to_sec(ctx.chart.bpmList, note.startBeat);
		note.endSec = pec_beat_to_sec(ctx.chart.bpmList, note.endBeat);
		note.floorPosition = pec_floor_at_sec(speed_events, note.startSec);
		note.endFloorPosition = pec_floor_at_sec(speed_events, note.endSec);
	};
	array_sort(ctx.chart.notes, function(a,b) { return a.startSec-b.startSec; });
	for (var highlight_i = 0; highlight_i < array_length(ctx.chart.notes); highlight_i++) ctx.chart.notes[highlight_i].hl = 0;
	if (bool(game.settings.enableNoteHightLight ?? true)) {
		var group_start = 0;
		while (group_start < array_length(ctx.chart.notes)) {
			var group_end = group_start + 1;
			var group_sec = ctx.chart.notes[group_start].startSec;
			while (group_end < array_length(ctx.chart.notes) && ctx.chart.notes[group_end].startSec == group_sec) group_end++;
			if (group_end - group_start > 1) {
				for (var group_i = group_start; group_i < group_end; group_i++) ctx.chart.notes[group_i].hl = 1;
			};
			group_start = group_end;
		};
	};
	return true;
}

function pec_create_runtime(ctx) {
	ctx.line_group = [];
	for (var line_i = 0; line_i < array_length(ctx.chart.judgeLineList); line_i++) {
		array_add(ctx.line_group, instance_create_depth(room_width/2, room_height/2, DEPTH.LINE, oLine_2, { line_id:line_i, events:ctx.chart.judgeLineList[line_i] }));
	};
	for (var note_i = 0; note_i < array_length(ctx.chart.notes); note_i++) {
		var note = ctx.chart.notes[note_i];
		var note_instance = instance_create_depth(-999, -999, DEPTH.NOTE, oNote_2, {
			type:note.type, line_id:note.line_id, startSec:note.startSec, endSec:note.endSec,
			floorPosition:note.floorPosition, endFloorPosition:note.endFloorPosition,
			xOffset:note.xOffset, isAbove:note.isAbove, isFake:note.isFake,
			speed:note.speed, widthScale:note.xscale, _hl:note.hl
		});
		if (variable_global_exists("render_mode") && global.render_mode && !note.isFake
			&& instance_exists(note_instance)) {
			var note_hitsound_time = note.startSec;
			if (note.type != 3 && note.type != 4) then note_hitsound_time += note_instance.hit_offset;
			note_hitsound_time += ctx.chart.offsetSeconds;
			note_instance.render_hitsound_scheduled = render_schedule_hitsound(
				note_instance.sound, note_hitsound_time);
		};
		if (!note.isFake) then maxcombo++;
	};
}

var EventLayers = [ // Length: Four 
    {
        "moveXEvents" : [
            {
                "startTime" : [0,0,1],
                "endTime" : [1,0,1],
                "easingType" : 1,
                "bezier" : false,
                "bezierPoints" : [0,0,0,0],
                "start" : 1,
                "end" : 10
            },
        ]
    },
    {
        "moveXEvents" : [
            {
                "startTime" : [0,0,1],
                "endTime" : [1,0,1],
                "easingType" : 1,
                "bezier" : false,
                "bezierPoints" : [0,0,0,0],
                "start" : 5,
                "end" : 2
            },
        ]
    },
    {
        "moveXEvents" : [
            {
                "startTime" : [0,0,1],
                "endTime" : [1,0,1],
                "easingType" : 1,
                "bezier" : false,
                "bezierPoints" : [0,0,0,0],
                "start" : 4,
                "end" : -10
            },
        ]
    },
    {
        "moveXEvents" : [
            {
                "startTime" : [0,0,1],
                "endTime" : [1,0,1],
                "easingType" : 1,
                "bezier" : false,
                "bezierPoints" : [0,0,0,0],
                "start" : 3,
                "end" : 14
            },
        ]
    }
]

