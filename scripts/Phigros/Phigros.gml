// 石库水
#macro print LogOutputFile
#macro elif else if
#macro func function
#macro isExists chart_file_exists_any
#macro InChartPath (variable_global_exists("chart_active_path") && is_string(global.chart_active_path) && string_length(global.chart_active_path) ? global.chart_active_path : (working_directory + "chart/"))
#macro VerReal { "windows": 40526, "android": 40521, "gxgames": 40526 } // 各平台版本号(独立)
#macro VerStr "v.4.0.9"

function ver_real() {
	var platform = "other";
	if (os_type == os_gxgames) then platform = "gxgames";
	else if (os_type == os_windows) then platform = "windows";
	else if (os_type == os_android) then platform = "android";
	var names = struct_get_names(VerReal);
	for (var i = 0; i < array_length(names); i++) {
		if (string_lower(names[i]) == platform) then return (struct_get(VerReal , names[i]))//VerReal[$ names[i]];
	};
	return 40500;
}
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

/// @desc YYC-safe buffer validity: accepts numeric ids and modern buffer refs
function asset_buffer_valid(_id) {
	if (is_undefined(_id)) then return false;
	if (is_string(_id)) then return false;
	if (is_real(_id) && _id < 0) then return false;
	return buffer_exists(_id);
}



// 实验性内容
//scheduler_resolution_set(800000000000);
//gpu_set_texfilter(true);
if (os_browser == browser_not_a_browser) then gml_release_mode(true);
//gml_pragma("forceinline");

//string_format()
// 憋憋枚举
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

/// FC/AP color for the default judge line and play start/end bar.
/// Does not read RPE colorEvents, custom textures, or line text.
function chart_line_judge_blend() {
	if (!(variable_global_exists("game") && is_struct(game) && is_struct(game.settings)
		&& bool(game.settings.enableLineJudge ?? false))) then return c_white;
	var blend = #ffeca0;
	if (variable_global_exists("phi_state_list") && is_struct(phi_state_list)) {
		if (real(phi_state_list.good ?? 0) > 0) then blend = make_colour_rgb(162, 238, 255);
		if (real(phi_state_list.bad ?? 0) + real(phi_state_list.miss ?? 0) > 0) then blend = c_white;
	};
	return blend;
}



//display_set_timing_method(tm_systemtiming);
//display_reset(0 , true);



// cmd命令调用参数
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
	
//	///@desc 字符串转数字
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
// 测试
var sval = "fweasfare",
	eval = "Hel";
show_debug_message(string_copy(sval, 1, string_length(eval))); 

///@desc 计算ACC
function accCalc(){
	var aoc = (phi_state_list),
		counts = (aoc.prefect + aoc.good + aoc.miss + aoc.bad),
		_acc = (clamp((100 * ((aoc.prefect + (aoc.good * 0.65)) / counts)) , 0 , 100));
	if(is_nan(_acc)) then _acc = 100.0000;
	phi_state_list.acc = _acc;
	
	return(string(_acc));
};


///@desc 计算打击offset
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
			if(insCombo) {
				phi_state_list.good ++;
				if (score_list[2]) then phi_state_list.early ++;
				else phi_state_list.late ++;
			};
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
		
	}elif(offset > 160){
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
	
	if(isFHitEf && (status == TYPE.GOOD || status == TYPE.PREFECT)) then _eff_c(xx , yy , is_undefined(effectColor) ? color : effectColor);
	
	return(status);
};

/// @desc Recalculate the on-line hit-effect position for an RPE note.
/// Official notes refresh geometry then project local X with the line's
/// current transform immediately before spawning the effect.
function rpe_note_hit_effect_xy() {
	if (instance_exists(_line_ref)) {
		with (_line_ref) event_perform(ev_step, ev_step_end);
		event_user(_step_user_count);
	};
	return [_x_h, _y_h];
};

/// @desc Non-hold fade after hit: 1 - ((now - hit) / miss). Holds do not use this.
function chart_note_pass_fade(_now_sec, _hit_sec, _miss_sec) {
	if (!is_real(_now_sec) || !is_real(_hit_sec) || !is_real(_miss_sec) || _miss_sec <= 0) then return 1;
	if (_now_sec <= _hit_sec) then return 1;
	return clamp(1 - ((_now_sec - _hit_sec) / _miss_sec), 0, 1);
}

function chart_note_miss_window_sec(_jtype, _is_hold) {
	if (_is_hold || _jtype == 3) then return 0.161;
	if (_jtype == 2 || _jtype == 4) then return 0.160;
	return 0.201;
}

/// @desc True when RPE alphaControl actually changes note alpha (not a constant 1 / 255).
function rpe_alpha_control_is_identity(_raw) {
	if (!is_array(_raw) || array_length(_raw) < 2) then return true;
	for (var i = 0; i < array_length(_raw); i++) {
		var ce = _raw[i];
		if (!is_struct(ce)) then continue;
		var v = ce[$ "alpha"];
		if (is_undefined(v)) then v = ce[$ "y"];
		if (is_undefined(v)) then continue;
		var rv = real(v);
		if (!is_finite(rv)) then continue;
		if (rv > 1.5) then rv = rv / 255;
		if (abs(rv - 1) > 0.001) then return false;
	};
	return true;
}

/// @desc Recalculate the on-line hit-effect position for a PEC note.
function pec_note_hit_effect_xy() {
	if (!instance_exists(line_ref)) then return [x, y];
	var _local_x = localXFactor * chart_view_width;
	var _c = line_ref.__cos;
	var _s = line_ref.__sin;
	return [line_ref.x + _c * _local_x, line_ref.y - _s * _local_x];
};

/// @desc Autoplay, including render-mode recording which has no player input.
function chart_autoplay_active() {
	if (variable_global_exists("render_mode") && global.render_mode) then return true;
	if (!(variable_global_exists("game") && is_struct(game) && is_struct(game.settings))) then return true;
	return bool(game.settings.enableAutoPlay ?? true);
}

/// @desc Auto-hit offset in milliseconds. Drag/Flick is clamped to +0..+160 (no early, no Bad/Miss band).
function chart_auto_hit_offset_ms(_jtype = undefined) {
	if (!(variable_global_exists("game") && is_struct(game) && is_struct(game.settings))) then return 0;
	var off = real(game.settings.judgeOffset ?? 0);
	if (bool(game.settings.TEST1 ?? false)) {
		off = choose(choose(random_range(-95, 0), random_range(0, 95), choose(1, 2, 5, -1, -6, choose(200, 10))), 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
	} else if (abs(off) >= 30000) {
		off = random_range(-201, 201);
	};
	if (!is_undefined(_jtype) && (_jtype == 2 || _jtype == 4)) then return clamp(off, 0, 160);
	return off;
}

function chart_kb_desktop() {
	return (os_type == os_windows || os_type == os_linux || os_type == os_macosx);
}

function chart_kb_state_get() {
	static st = undefined;
	if (is_undefined(st)) then st = { grace_until: -1, held: 0, pressed: 0, prev: array_create(26, false) };
	return st;
}

function chart_kb_key_down(_vk) {
	if (os_type == os_windows) then return keyboard_check_direct(_vk);
	return keyboard_check(_vk);
}

/// @desc Poll A-Z via raw key state so 10+ simultaneous keys register.
function chart_kb_poll() {
	var st = chart_kb_state_get();
	st.held = 0;
	st.pressed = 0;
	for (var i = 0; i < 26; i++) {
		var down = chart_kb_key_down(65 + i);
		if (down) then st.held++;
		if (down && !st.prev[i]) then st.pressed++;
		st.prev[i] = down;
	};
	return st;
}

function chart_kb_any_down() {
	for (var i = 0; i < 26; i++) {
		if (chart_kb_key_down(65 + i)) then return true;
	};
	return false;
}

/// @desc Headed holds stay alive while any A-Z key is down, or for 80ms after release.
function chart_kb_hold_alive() {
	if (chart_kb_any_down()) then return true;
	var st = chart_kb_state_get();
	if (st.grace_until < 0) then return false;
	if (!(variable_global_exists("game") && is_struct(game))) then return false;
	return (game.__time[1] < st.grace_until);
}

function chart_player_keyboard_judge_active() {
	if (chart_autoplay_active()) then return false;
	if (!chart_kb_desktop()) then return false;
	if (!(variable_global_exists("game") && is_struct(game)) || game.paused) then return false;
	if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then return false;
	if (instance_exists(oSettlement)) then return false;
	if (instance_exists(oPlayTransition)) {
		var _transition = instance_find(oPlayTransition, 0);
		if (variable_instance_exists(_transition, "state")
			&& _transition.state != PLAY_TRANSITION_STATE.PLAYING) then return false;
	};
	return true;
}

function chart_kb_note_hit_sec() {
	if (object_index == oNote) then return realHitTime;
	if (object_index == oNote_1) then return start_sec;
	return startSec;
}

function chart_kb_note_now_sec() {
	if (object_index == oNote || object_index == oNote_1) then return _now_seconds;
	var _off = 0;
	if (variable_global_exists("game_2") && is_struct(game_2) && is_struct(game_2.chart)) {
		_off = real(game_2.chart.offsetSeconds ?? 0);
	};
	return game.__time[1] - _off;
}

function chart_kb_note_judge_type() {
	if (object_index == oNote_2) then return judge_type;
	return type;
}

function chart_kb_note_is_hold() {
	if (object_index == oNote_2) then return (type == 2);
	return (type == 3);
}

function chart_kb_note_in_window(_now, _hit, _jtype, _hold) {
	// Drag/Flick: no early hit; latest is the Perfect band (≤160ms), not Bad/Miss.
	if (!_hold && (_jtype == 2 || _jtype == 4)) {
		return (_now >= _hit && _now <= _hit + 0.160);
	};
	var early = 0.200;
	var late = _hold ? 0.161 : 0.201;
	return (_now >= _hit - early && _now <= _hit + late);
}

function chart_kb_note_eligible(_mode) {
	if (variable_instance_exists(id, "kb_ignore") && kb_ignore) then return false;
	if (object_index == oNote && !inition) then return false;
	if (object_index == oNote_1 && (!inition || isFake)) then return false;
	if (object_index == oNote_2 && isFake) then return false;
	var jtype = chart_kb_note_judge_type();
	var hold = chart_kb_note_is_hold();
	if (!chart_kb_note_in_window(chart_kb_note_now_sec(), chart_kb_note_hit_sec(), jtype, hold)) then return false;
	if (_mode == 0) {
		if (hold) {
			if (object_index == oNote_2) then return !hold_started;
			return (notJudge && hit_status == TYPE.NONE);
		};
		if (jtype != 1) then return false;
		if (object_index == oNote_2) then return !judged;
		return (!isJudge && !isBad && hit_status == TYPE.NONE);
	};
	if (hold || (jtype != 2 && jtype != 4)) then return false;
	if (object_index == oNote_2) then return !judged;
	return !isJudge;
}

function chart_kb_hold_active() {
	if (!chart_kb_note_is_hold()) then return false;
	if (object_index == oNote_1 && isFake) then return false;
	if (object_index == oNote_2 && isFake) then return false;
	var now = chart_kb_note_now_sec();
	if (!(hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT)) then return false;
	if (object_index == oNote) {
		return (!notJudge && !isMiss && now < realHitTime + hold_time_length);
	};
	if (object_index == oNote_1) {
		return (!notJudge && !isMiss && now < end_sec);
	};
	return (hold_started && !isMiss && now < endSec);
}

function chart_kb_pick(_obj, _mode) {
	var best_note = noone;
	var best_dt = infinity;
	var best_hit = infinity;
	with (_obj) {
		if (!chart_kb_note_eligible(_mode)) then continue;
		var hit = chart_kb_note_hit_sec();
		var dt = abs(chart_kb_note_now_sec() - hit);
		if (dt < best_dt || (dt == best_dt && hit < best_hit)) {
			best_dt = dt;
			best_hit = hit;
			best_note = id;
		};
	};
	return best_note;
}

function chart_kb_apply_hit(_note) {
	if (_note == noone || !instance_exists(_note)) then return TYPE.NONE;
	var status = TYPE.NONE;
	with (_note) status = chart_kb_apply_hit_self();
	return status;
}

function chart_kb_apply_hit_self() {
	var hold = chart_kb_note_is_hold();
	if (object_index == oNote) {
		if (hold) {
			event_user(2);
			var status_h = judgeCalc(self.time, _now_beat, self.bpm, _hx0, _hy0, self.type, true, false);
			if (status_h == TYPE.NONE) then return TYPE.NONE;
			hit_status = status_h;
			notJudge = false;
			isHold = true;
			judgeTime = _now_beat;
			judgeRealTime = _now_seconds;
			if (status_h == TYPE.MISS) {
				isMiss = true;
				judgeCalc(self.time, _now_beat, self.bpm, _hx0, _hy0, self.type, true, true);
			} else {
				_bak_time = _now_seconds;
				skin_play_note_hitsound();
			};
			return status_h;
		};
		event_user(1);
		var line_x = _line_ref.x;
		var local_x = (_note_x - line_x);
		var hit_x = (line_x + local_x * _line_ref.__cos);
		var hit_y = (_line_ref.y - local_x * _line_ref.__sin);
		var status_n = judgeCalc(self.time, _now_beat, self.bpm, hit_x, hit_y, self.type);
		if (status_n == TYPE.NONE) then return TYPE.NONE;
		hit_status = status_n;
		isJudge = true;
		judgeRealTime = _now_seconds;
		if (status_n == TYPE.GOOD || status_n == TYPE.PREFECT) then skin_play_note_hitsound();
		if (status_n == TYPE.BAD && type == 1) {
			isBad = true;
			_bad_x = _note_x;
			_bad_y = _note_y;
			_bad_angle = image_angle;
		} else {
			instance_deactivate_object(self);
		};
		return status_n;
	};
	if (object_index == oNote_1) {
		var tint = has_hit_tint ? hit_tint : undefined;
		if (hold) {
			var hold_xy = rpe_note_hit_effect_xy();
			var status_rh = judgeCalc(start_sec, _now_seconds, 0, hold_xy[0], hold_xy[1], type, true, false, true, tint);
			if (status_rh == TYPE.NONE) then return TYPE.NONE;
			hit_status = status_rh;
			notJudge = false;
			isHold = true;
			__first__ = true;
			judgeTime = _now_seconds;
			judgeRealTime = _now_seconds;
			if (status_rh == TYPE.MISS) {
				isMiss = true;
				judgeCalc(start_sec, _now_seconds, 0, hold_xy[0], hold_xy[1], type, true, true, true);
			} else if (is_real_note) {
				_bak_time = _now_seconds;
				skin_play_note_hitsound();
			};
			return status_rh;
		};
		var tap_xy = rpe_note_hit_effect_xy();
		var status_rn = judgeCalc(start_sec, _now_seconds, 0, tap_xy[0], tap_xy[1], type, true, true, true, tint);
		if (status_rn == TYPE.NONE) then return TYPE.NONE;
		hit_status = status_rn;
		isJudge = true;
		judgeRealTime = _now_seconds;
		if (is_real_note && (status_rn == TYPE.GOOD || status_rn == TYPE.PREFECT)) then skin_play_note_hitsound();
		if (status_rn == TYPE.BAD && type == 1) {
			isBad = true;
			_bad_x = x;
			_bad_y = y;
			_bad_angle = image_angle;
		} else {
			instance_deactivate_object(self);
		};
		return status_rn;
	};
	var pec_now = chart_kb_note_now_sec();
	var pec_xy = pec_note_hit_effect_xy();
	if (hold) {
		var status_ph = judgeCalc(startSec, pec_now, 0, pec_xy[0], pec_xy[1], judge_type, true, false, true);
		if (status_ph == TYPE.NONE) then return TYPE.NONE;
		hit_status = status_ph;
		hold_started = true;
		judge_sec = pec_now;
		if (status_ph == TYPE.MISS) {
			isMiss = true;
			judgeCalc(startSec, pec_now, 0, pec_xy[0], pec_xy[1], judge_type, true, true, true);
		} else {
			hold_effect_sec = pec_now;
			skin_play_note_hitsound();
		};
		return status_ph;
	};
	var status_pn = judgeCalc(startSec, pec_now, 0, pec_xy[0], pec_xy[1], judge_type, true, true, true);
	if (status_pn == TYPE.NONE) then return TYPE.NONE;
	hit_status = status_pn;
	judged = true;
	if (status_pn == TYPE.GOOD || status_pn == TYPE.PREFECT) then skin_play_note_hitsound();
	canDraw = false;
	instance_deactivate_object(self);
	return status_pn;
}

function chart_kb_force_miss_hold() {
	if (!chart_kb_hold_active()) then return;
	isMiss = true;
	hit_status = TYPE.MISS;
	if (object_index == oNote) {
		judgeCalc(self.time, self.time + 1, self.bpm, _hx0, _hy0, self.type, false, true);
	} else if (object_index == oNote_1) {
		if (is_real_note) then judgeCalc(start_sec, start_sec + 1, 0, _hx0, _hy0, type, false, true, true);
	} else {
		judgeCalc(startSec, startSec + 1, 0, hx0, hy0, judge_type, false, true, true);
	};
}

/// @desc Desktop A-Z fullscreen judgment. One click per Tap/Hold; Drag/Flick while any key is held.
function chart_kb_judge_step() {
	var st = chart_kb_poll();
	if (!chart_player_keyboard_judge_active()) {
		st.grace_until = -1;
		exit;
	};
	var note_obj = noone;
	if (instance_exists(oNote)) then note_obj = oNote;
	else if (instance_exists(oNote_1)) then note_obj = oNote_1;
	else if (instance_exists(oNote_2)) then note_obj = oNote_2;
	else exit;
	with (note_obj) kb_ignore = false;
	var pressed = st.pressed;
	var held = st.held;
	var now = game.__time[1];
	var guard = 32;
	while (pressed > 0 && guard > 0) {
		guard--;
		var click_note = chart_kb_pick(note_obj, 0);
		if (click_note == noone) then break;
		if (chart_kb_apply_hit(click_note) == TYPE.NONE) {
			click_note.kb_ignore = true;
			continue;
		};
		pressed--;
	};
	if (held > 0) {
		st.grace_until = -1;
		guard = instance_number(note_obj);
		while (guard > 0) {
			guard--;
			var catch_note = chart_kb_pick(note_obj, 1);
			if (catch_note == noone) then break;
			if (chart_kb_apply_hit(catch_note) == TYPE.NONE) {
				catch_note.kb_ignore = true;
				continue;
			};
		};
	} else {
		var has_hold = false;
		with (note_obj) {
			if (chart_kb_hold_active()) {
				has_hold = true;
				break;
			};
		};
		if (has_hold) {
			if (st.grace_until < 0) then st.grace_until = now + 0.080;
			if (now >= st.grace_until) {
				with (note_obj) chart_kb_force_miss_hold();
				st.grace_until = -1;
			};
		} else {
			st.grace_until = -1;
		};
	};
}

///@desc 分数系统
///@param _mode {Real} 
function ScoreSystem(_mode = undefined){
	if (!is_real(maxcombo) || !is_finite(maxcombo) || maxcombo <= 0) then return("0000000");
	var mode;
	if(is_undefined(_mode)) then mode = (game.settings.enableComboScore)
	else mode = _mode;
	
	
	var _s,_t;
	var __combo = (phi_state_list);
	var prefect = is_struct(__combo) ? real(__combo.prefect ?? 0) : 0;
	var good = is_struct(__combo) ? real(__combo.good ?? 0) : 0;
	var max_hit = is_struct(__combo) ? real(__combo.max_hitcombo ?? 0) : 0;
	if (!is_finite(prefect)) then prefect = 0;
	if (!is_finite(good)) then good = 0;
	if (!is_finite(max_hit)) then max_hit = 0;
	if(mode){
		_s = ((int64(900000 * ((prefect + (good * 0.65)) / maxcombo))) + (int64(100000 * (max_hit / maxcombo))));
	}else{	
		_s = (int64(1000000 * ((prefect + (good * 0.65)) / maxcombo)));
	};
	
	if (is_finite(_s)) then _s = (_s | 0);
	else _s = 0;
	
	var _l_scombo_ = (string_length(string(_s))),
		_scmrzero = (7 - _l_scombo_ <= 0 ? 0 : 7 - _l_scombo_),
		_t = "";
	repeat(_scmrzero){
		_t+="0";
	};
	_t += string(_s);
	return(_t);	
};

///@desc Numeric score used by settlement (same rules as ScoreSystem).
function ScoreSystemValue(_mode = undefined) {
	if (!is_real(maxcombo) || !is_finite(maxcombo) || maxcombo <= 0) then return 0;
	var mode;
	if (is_undefined(_mode)) then mode = (game.settings.enableComboScore);
	else mode = _mode;
	var __combo = (phi_state_list);
	var prefect = is_struct(__combo) ? real(__combo.prefect ?? 0) : 0;
	var good = is_struct(__combo) ? real(__combo.good ?? 0) : 0;
	var max_hit = is_struct(__combo) ? real(__combo.max_hitcombo ?? 0) : 0;
	if (!is_finite(prefect)) then prefect = 0;
	if (!is_finite(good)) then good = 0;
	if (!is_finite(max_hit)) then max_hit = 0;
	var _s;
	if (mode) {
		_s = ((int64(900000 * ((prefect + (good * 0.65)) / maxcombo))) + (int64(100000 * (max_hit / maxcombo))));
	} else {
		_s = (int64(1000000 * ((prefect + (good * 0.65)) / maxcombo)));
	};
	if (is_finite(_s)) then _s = (_s | 0);
	else _s = 0;
	return _s;
};

function ScoreSystemPad(_value) {
	var _s = is_real(_value) && is_finite(_value) ? (_value | 0) : 0;
	if (_s < 0) then _s = 0;
	var _t = string(_s);
	while (string_length(_t) < 7) {
		_t = "0" + _t;
	};
	return _t;
};

///@desc 文件寻找系统(Windows / Android / HTML5)
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

        var file_path_list = [];
        if (pls_is_gxgames()) {
                file_path_list = gx_fs_list_files(disc_path);
                print($"[ChartSession] GX list {disc_path} files={array_length(file_path_list)}");
        };
        if (array_length(file_path_list) <= 0 && chart_use_native_files()) {
                var listing = chart_native_list(disc_path);
                print($"[ChartSession] Native list {disc_path} err={chart_native_error()} bytes={string_length(listing)}");
                var parts = string_split(string_replace_all(listing, "\r", ""), "\n");
                for (var list_i = 0; list_i < array_length(parts); list_i++) {
                        var listed = string_replace_all(string_trim(parts[list_i]), "\\", "/");
                        if (!string_length(listed)) then continue;
                        var listed_name = string_lower(chart_path_file_name(listed));
                        if (listed_name == "_extract_log.txt") then continue;
                        array_add(file_path_list, listed);
                };
        };
        if (array_length(file_path_list) <= 0) {
                var gx = pls_is_gxgames();
                var sep = gx ? "/" : "\\";
                var root = gx ? chart_path_norm(disc_path) : string_replace_all(string(disc_path), "/", "\\");
                if(string_length(root) && string_char_at(root, string_length(root)) != sep) then root += sep;

                var directory_list = [ root ];

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
                                                var full_dir = path + dir_name + sep;
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
        };

        for(var l = 0; l < array_length(file_path_list); l++){
                var file = file_path_list[l];
                var point = string_last_pos(".", file);
                var ext = (point > 0) ? string_lower(string_copy(file, point, string_length(file) - point + 1)) : "";
                switch(ext){
                        case ".json":
						if (string_lower(chart_path_file_name(file)) == "extra.json") {
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

        print($"[ChartSession] Discover {disc_path} files={array_length(file_path_list)} chart={array_length(return_path.chart)} music={array_length(return_path.music)} image={array_length(return_path.image)} text={array_length(return_path.text)} other={array_length(return_path[$ "other"])}");
        var preview_n = min(8, array_length(file_path_list));
        for (var preview_i = 0; preview_i < preview_n; preview_i++) {
                print($"[ChartSession] Discover file[{preview_i}]={file_path_list[preview_i]}");
        };
        return(return_path);
};

///@desc 
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



///@desc 读取line.csy
function load_line_csv(){
	var path = chart_path_join(InChartPath, "line.csv");
	if (variable_global_exists("chart_session") && is_struct(global.chart_session)
		&& is_string(global.chart_session.line_file) && string_length(global.chart_session.line_file)) {
		path = chart_path_join(InChartPath, global.chart_session.line_file);
	};
	if(chart_file_exists_any(path)){
		path = chart_file_readable_path(path);
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

///@desc Phigros Official的floorPosition计算
function official_floor_at_beat(speed_events, beat, seconds_per_beat) {
	var floor_value = 0;
	for (var speed_i = 0; speed_i < array_length(speed_events); speed_i++) {
		var speed_event = speed_events[speed_i];
		if (beat <= speed_event.startTime) then break;
		var event_start = speed_event.startTime;
		if (speed_i == 0 && event_start < 0) then event_start = 0;
		var event_floor = floor_value;
		if (struct_exists(speed_event, "floorPosition") && is_real(speed_event.floorPosition)) {
			event_floor = speed_event.floorPosition;
		};
		// Runtime keeps the final speed after its declared endTime. Use the
		// same continuation rule when precomputing Hold floor length.
		var event_end = speed_event.endTime;
		if (speed_i == array_length(speed_events) - 1 && beat > event_end) then event_end = beat;
		var covered_end = min(beat, event_end);
		floor_value = event_floor + max(0, covered_end - event_start) * seconds_per_beat * speed_event.value;
		if (beat <= speed_event.endTime) then break;
	};
	return floor_value;
}

function Phigros() constructor { // 仅仅结构
	// 谱面&信息
	static chart = undefined;
	static version = 0;
	static line_list = [];
	// 
	__time = array_create(6, 0);
	paused = true;
	_notes = [];
	
	// line.csv
	static TextureGroup = {
		"default" : line_2
	};
	
	// 音符&字体
	static notes = ({});
	static font = (pls_ui_font_add(47));
	
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
	
	// 设置
	static settings = {
		"enableBlur" : true,					// 是否启用背景模糊(default:true)
		"enableFPS" : true,						// 是否显示FPS(default:true)
		"enableQuikyStart" : true,				// 是否启用快速启动(已弃用)(default:true)
		"enableCanvasZoom" : false,				// 是否启用摄像头缩放(已弃用)(default:false)
		"enableSurface" : true,					// 是否启用遮罩(default:true)
		"enableNoteHightLight" : true,			// 是否启用音符多押高亮(default:true)
		"enableChartGUI" : true,				// 是否启用UI(default:true)
		"enableLineJudge" : true,				// 是否启用FC/AP指示器(default:true)
		"showBG" : true,						// 是否显示背景(default:true)
		"enableHitEffect" : true,				// 是否显示打击特效(default:true)
		"refreshFPSCount" : 60,					// 刷新FPS计量次数(default:60)
		"enableDebug" : true,					// 是否启用Debug(default:true)
		"enableDisplayLineID" : false,			// 是否显示线ID(已弃用)(default:false)
		"comboString" : "COMBO",				// combo text(default:"COMBO")
		"userName" : "Guest",					// settlement player name(default:"Guest")
		"enableVsync" : true,					// 是否启用垂直同步(default:true)
		"aa_level" : 8,							// aa_level等级(default:0)
		"useOldFX" : false,						// 是否使用旧版打击特效(default:false)
		"enableComboScore" : true,				// 是否启用打击分(default:true)
		"enableAutoPlay" : true,				// 是否启用自动游玩(default:true)
		"judgeOffset" : 0,						// 自动打击偏移延迟(default:0)
		"enableAccJudgment" : true,				// 是否启用Auto严肃判定(可能对其他格式的谱面无效)(default:true)
		"preventWindowMoveFreeze" : true,		// use non-blocking Windows moving and resizing
		"enableRPEMulticore" : true,			// enable native RPE frame workers
		"rpeWorkerMinLines" : 32,				// minimum line count for native parallel resolve
		"rpeWorkerProfileFrames" : 1800,		// frames averaged between worker timing logs
		"noteUniformScale" : false,				// RPE note size/sizeControl also scale height
		"notePreloadSeconds" : 15,				// note preload seconds (0-60)
		"TEST1" : false							// judge offset jitter test (default false)
	};
	
	
	/// 必要的函数
	///@desc String->Real
	static strToReal = (func(str , default_value = undefined){
		if(string_lower(str) == "false") then return(0);
		if(string_lower(str) == "true") then return(1);
		if(string_lower(str) == "undefined") then return(undefined);
		try{ return(real(str)) }
		catch(e){ delete(e); return(default_value) };
	});
	
	///@desc Real->String
	static realToStrBool = (func(_real){
		if(!is_real(_real)) then return("undefined");
		if(bool(_real) == true) then return("true");
		else return("false");
	});
	
	///@desc 读取器
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
		self.runtime_line_instances = [];
		self.runtime_note_instances = [];
		if(lmode == 0){
			var f = (string_length(_chart) ? _chart : ($"{working_directory}chart/Chart_IN.json"));
			if (!chart_file_exists_any(f)) {
				show_debug_message($"[R-Chart] File not found: {f}");
				return(false);
			};
			var r = chart_read_text_file(f, -1);
			if (!string_length(r)) {
				show_debug_message($"[R-Chart] Empty chart data: {f}");
				return(false);
			};
			var parsed_chart = undefined;
			try {
				parsed_chart = json_parse(r);
			} catch (parse_error) {
				delete(parse_error);
				delete(r);
				show_debug_message($"[R-Chart] Invalid JSON: {f}");
				return(false);
			};
			self.chart = parsed_chart;
			delete(r);
			delete(chart_source);
		}else{
			delete(_chart);
			self.chart = chart_source;
		}
		if (!is_struct(self.chart) || !struct_exists(self.chart, "formatVersion")
			|| !is_real(self.chart.formatVersion)) {
			show_debug_message("[R-Chart] Missing or invalid formatVersion.");
			return(false);
		};
		game.version = real(self.chart.formatVersion);
		if (game.version != floor(game.version) || game.version < 1 || game.version > 3) {
			show_debug_message($"[R-Chart] Unsupported Official formatVersion: {game.version}");
			return(false);
		};
		if (!struct_exists(self.chart, "offset") || !is_real(self.chart.offset)) then self.chart.offset = 0;
		if (!struct_exists(self.chart, "judgeLineList") || !is_array(self.chart.judgeLineList)) {
			show_debug_message("[R-Chart] judgeLineList is missing or invalid.");
			return(false);
		};
		
		for(var i = 0 ; i < array_length(self.chart.judgeLineList) ;  i ++){
			var line_data = self.chart.judgeLineList[i];
			if (!is_struct(line_data)) {
				show_debug_message($"[R-Chart] Invalid judge line at index {i}.");
				return(false);
			};
			if (!struct_exists(line_data, "judgeLineMoveEvents") || !is_array(line_data.judgeLineMoveEvents)) then line_data.judgeLineMoveEvents = [];
			if (!struct_exists(line_data, "judgeLineRotateEvents") || !is_array(line_data.judgeLineRotateEvents)) then line_data.judgeLineRotateEvents = [];
			if (!struct_exists(line_data, "judgeLineDisappearEvents") || !is_array(line_data.judgeLineDisappearEvents)) then line_data.judgeLineDisappearEvents = [];
			if (!struct_exists(line_data, "speedEvents") || !is_array(line_data.speedEvents)) then line_data.speedEvents = [];
			if (!struct_exists(line_data, "notesAbove") || !is_array(line_data.notesAbove)) then line_data.notesAbove = [];
			if (!struct_exists(line_data, "notesBelow") || !is_array(line_data.notesBelow)) then line_data.notesBelow = [];
			if (!is_real(line_data.bpm) || line_data.bpm <= 0) then line_data.bpm = 60;

			// v1 and v2 store movement coordinates in legacy packed/centered form.
			// v3 already uses normalized values; its Y inversion happens in oLine.
			if(game.version == 1 || game.version == 2){
				for(var m = 0 ; m < array_length(line_data.judgeLineMoveEvents) ; m ++){
					var l_m = line_data.judgeLineMoveEvents[m];
					if (!is_struct(l_m) || !struct_exists(l_m, "start") || !struct_exists(l_m, "end")) then continue;
					var move_source = {
						"start" : l_m.start,
						"end" : l_m[$ "end"],
						"start2" : l_m[$ "start2"],
						"end2" : l_m[$ "end2"]
					};
					if (game.version == 2 && (!is_real(move_source.start2) || !is_real(move_source.end2))) then continue;
					var r_m = (game.version == 1 ? game.Math.posCovert(move_source) : game.Math.posCovert2(move_source));
					if (!is_struct(r_m)) then continue;
					line_data.judgeLineMoveEvents[m][$ "start"] = r_m.start;
					line_data.judgeLineMoveEvents[m][$ "end"] = r_m[$ "end"];
					line_data.judgeLineMoveEvents[m][$ "start2"] = r_m.start2;
					line_data.judgeLineMoveEvents[m][$ "end2"] = r_m.end2;
				};
			};
			
			var bpm = line_data.bpm;
			var line_speed_events = line_data.speedEvents;
			array_sort(line_speed_events, function(a, b) { return a.startTime - b.startTime; });
			// Official v1 uses a large negative start time as a pre-roll
			// sentinel. PCR starts the first speed segment at chart time 0;
			// keeping the sentinel would move the line hundreds of floor units
			// before the first note.
			if (game.version == 1 && array_length(line_speed_events) > 0) {
				var first_speed = line_speed_events[0];
				if (is_struct(first_speed) && is_real(first_speed.startTime)
					&& first_speed.startTime < 0) {
					first_speed.startTime = 0;
				};
			};
			var line_seconds_per_beat = 1.875 / bpm;
			if (game.version == 1) {
				// v1 stores no floor base. Materialize the same cumulative
				// timeline used by the reference loader before notes are read.
				var v1_floor = 0;
				for (var v1_speed_i = 0; v1_speed_i < array_length(line_speed_events); v1_speed_i++) {
					var v1_speed_event = line_speed_events[v1_speed_i];
					if (!is_struct(v1_speed_event)) then continue;
					v1_speed_event.floorPosition = v1_floor;
					var v1_start = real(v1_speed_event.startTime ?? 0);
					var v1_end = real(v1_speed_event.endTime ?? v1_start);
					v1_floor += max(0, v1_end - v1_start) * line_seconds_per_beat * real(v1_speed_event.value ?? 0);
				};
			};
			for(var a = 0 ; a < array_length(line_data.notesAbove) ; a ++){
				var n = line_data.notesAbove[a];
				if (!is_struct(n)) then continue;
				var hold_floor_length = 0;
				if (n.type == 3) {
					var hold_beats = max(0, floor(n.holdTime));
					hold_floor_length = official_floor_at_beat(line_speed_events, n.time + hold_beats, line_seconds_per_beat) - n.floorPosition;
					if (hold_floor_length == 0) then hold_floor_length = hold_beats * line_seconds_per_beat * real(n[$ "speed"] ?? 1);
				};
				array_add(self._notes , { "type" : n.type , "time" : n.time , "holdTime" : (n.type == 3 ? max(0, floor(n.holdTime)) : 0) , "holdFloorLength" : hold_floor_length, "speed" : real(n[$ "speed"] ?? 1), "xOffset" : n.positionX , "yOffset" : n.floorPosition , "hl" : false , "isAbove" : true , "id" : i , "bpm" : bpm});
			};
			
			for(var b = 0 ; b < array_length(line_data.notesBelow) ; b ++){
				var n = line_data.notesBelow[b];
				if (!is_struct(n)) then continue;
				var hold_floor_length = 0;
				if (n.type == 3) {
					var hold_beats = max(0, floor(n.holdTime));
					hold_floor_length = official_floor_at_beat(line_speed_events, n.time + hold_beats, line_seconds_per_beat) - n.floorPosition;
					if (hold_floor_length == 0) then hold_floor_length = hold_beats * line_seconds_per_beat * real(n[$ "speed"] ?? 1);
				};
				array_add(self._notes , { "type" : n.type , "time" : n.time , "holdTime" : (n.type == 3 ? max(0, floor(n.holdTime)) : 0) , "holdFloorLength" : hold_floor_length, "speed" : real(n[$ "speed"] ?? 1), "xOffset" : n.positionX , "yOffset" : n.floorPosition , "hl" : false , "isAbove" : false , "id" : i , "bpm" : bpm});
			};
			//delete(self.chart.judgeLineList[i].notesAbove);
			//delete(self.chart.judgeLineList[i].notesBelow);
		};
		array_set(game.__time, 5, self.chart.offset * 1000000);
		print("[R-Chart] Done." , game.settings.enableDebug);
		return(true);
	});
	
	///@desc 事件分类
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
	
	///@desc 背景应用
	static Background = (func(custom = ""){
		var p = ((is_string(custom) && string_length(custom)) ? custom : "");
		var kept = chart_blur_bind_game(false);
		if (sprite_exists(kept) && asset_sprite_valid(self.bg) && self.bg == kept) {
			if (is_string(p) && string_length(p)) then self.bg_source_path = gx_path_clean(chart_file_readable_path(string_replace_all(p, "\\", "/")));
			var _kw = sprite_get_width(self.bg);
			var _kh = sprite_get_height(self.bg);
			print($"[R-BG] Using kept loading blur size={_kw}x{_kh}" , game.settings.enableDebug);
			return;
		};
		if(!is_string(p) || !string_length(p)){
			if(asset_sprite_valid(self.bg) && self.bg != kept) then sprite_delete(self.bg);
			if (!sprite_exists(kept)) then self.bg = -1;
			print("[R-BG] Empty path." , game.settings.enableDebug);
			return;
		};
		p = string_replace_all(p, "\\", "/");
		if(!chart_file_exists_any(p)){
			print($"[R-BG] Missing file: {p}" , game.settings.enableDebug);
			return;
		};
		p = chart_file_readable_path(p);
		p = gx_path_clean(p);
		if (asset_sprite_valid(self.bg)
				&& string(self[$ "bg_source_path"] ?? "") == p
				&& bool(self[$ "bg_blurred"] ?? false)) {
			print("[R-BG] Reusing already-blurred sprite." , game.settings.enableDebug);
			return;
		};
		if(asset_sprite_valid(self.bg) && self.bg != kept) then sprite_delete(self.bg);
		self.bg = -1;
		self.bg_source_path = p;
		self.bg_blurred = false;
		self.bg_blur_pending = false;
		self.bg_blur_tries = 0;
		chart_cache_legacy_cleanup();

		kept = chart_blur_bind_game(false);
		if (sprite_exists(kept) && asset_sprite_valid(self.bg) && self.bg == kept) {
			print($"[R-BG] Using loading-screen blur sprite size={sprite_get_width(self.bg)}x{sprite_get_height(self.bg)}" , game.settings.enableDebug);
			return;
		};

		// GM 2024+/LTS may return asset refs from sprite_add (not reals).
		// Do NOT require is_real(...); validate with sprite_exists via asset_sprite_valid.
		var base_spr = -1;
		var try_paths = [p];
		array_add(try_paths, string_replace_all(p, "/", "\\"));
		var cache_path = "";

		for (var ti = 0; ti < array_length(try_paths); ti++) {
			var tp = try_paths[ti];
			var s1 = sprite_add(tp, 1, false, false, 0, 0);
			if (asset_sprite_valid(s1)) { base_spr = s1; print($"[R-BG] ok try[{ti}] imgnum=1 path={tp} type={typeof(s1)}" , game.settings.enableDebug); break; };
			var s0 = sprite_add(tp, 0, false, false, 0, 0);
			if (asset_sprite_valid(s0)) { base_spr = s0; print($"[R-BG] ok try[{ti}] imgnum=0 path={tp} type={typeof(s0)}" , game.settings.enableDebug); break; };
			print($"[R-BG] sprite_add failed try[{ti}]: {tp} (s0={s0}/{typeof(s0)}, s1={s1}/{typeof(s1)})" , game.settings.enableDebug);
		};
		if (!asset_sprite_valid(base_spr)) {
			var fname = chart_path_file_name(p);
			cache_path = chart_gm_cache_dir() + "bg_load_" + fname;
			if (file_exists(cache_path)) then file_delete(cache_path);
			if (chart_use_native_files() && chart_native_exists(cache_path)) then chart_native_delete(cache_path);
			if (chart_use_native_files() && chart_native_exists(p)) then chart_native_copy(p, cache_path);
			else if (!pls_is_html5()) then file_copy(p, cache_path);
			if (file_exists(cache_path) || (chart_use_native_files() && chart_native_exists(cache_path))) {
				var sc = sprite_add(cache_path, 0, false, false, 0, 0);
				if (asset_sprite_valid(sc)) then base_spr = sc;
				else {
					sc = sprite_add(cache_path, 1, false, false, 0, 0);
					if (asset_sprite_valid(sc)) then base_spr = sc;
				};
			};
			if (file_exists(cache_path)) then file_delete(cache_path);
			if (chart_use_native_files() && chart_native_exists(cache_path)) then chart_native_delete(cache_path);
		};
		
		if(!asset_sprite_valid(base_spr)){
			print($"[R-BG] sprite_add failed all strategies: {p}" , game.settings.enableDebug);
			return;
		};

		if(is_struct(game.settings) && bool(game.settings.enableBlur)){
			// Same call as oLoadAnimator/Step: file path, 10 iters, middle-center.
			var blurred = kawase_blur_sprite(p, 1, 0, 10, SPRITE_OFFSET.MIDDLE_CENTER, [0, 0]);
			if (!asset_sprite_valid(blurred) || blurred == base_spr) {
				blurred = kawase_blur_sprite(base_spr, 1, 0, 10, SPRITE_OFFSET.MIDDLE_CENTER, [0, 0]);
			};
			if(asset_sprite_valid(blurred) && blurred != base_spr){
				sprite_delete(base_spr);
				game.bg = blurred;
				self.bg_blurred = true;
			}else{
				game.bg = base_spr;
				if (pls_is_gxgames()) {
					self.bg_blur_pending = true;
					print("[R-BG] Blur failed in Create; will retry with loading-screen path call." , game.settings.enableDebug);
				} else {
					print("[R-BG] Blur failed, using raw sprite." , game.settings.enableDebug);
				};
			};
		}else{
			game.bg = base_spr;
		};

		if (asset_sprite_valid(game.bg)) {
			var _bw = sprite_get_width(game.bg);
			var _bh = sprite_get_height(game.bg);
			sprite_set_offset(game.bg, _bw * 0.5, _bh * 0.5);
			print($"[R-BG] origin=({sprite_get_xoffset(game.bg)}, {sprite_get_yoffset(game.bg)}) size={_bw}x{_bh}" , game.settings.enableDebug);
		};
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
			ini_write_string("Resource" , "font.ui" , pls_bundled_font_path());
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
		self.res_path[$ "font.ui"] = (ini_read_string("Resource" , "font.ui" , pls_bundled_font_path()));
		self.res_path[$ "effc.hit"] = (ini_read_string("Resource" , "effc.hit" , $"{working_directory}resource/effect.png"));
		
		///
		var name = (struct_get_names(self.settings));
		for(var i = 0 ; i < array_length(name) ; i ++){
			if (is_string(self.settings[$ name[i]])) then self.settings[$ name[i]] = (ini_read_string("Settings" , name[i] , self.settings[$ name[i]]));
			else self.settings[$ name[i]] = (self.strToReal(ini_read_string("Settings" , name[i] , self.settings[$ name[i]])));
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
		ini_write_string("Settings", "language", lang_current_id());
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
	//					game.font = (pls_font_add(self.res_path[$ name[i]] , 25 , false , false , -infinity, infinity));
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
	
	///@desc 资源管理器
	static Resource = (func(){
		if(!asset_font_valid(self.font)){
			self.font = (pls_ui_font_add(47));
		};
		self.Configs();
		if (variable_global_exists("render_mode") && global.render_mode) {
			self.settings.aa_level = variable_global_exists("render_aa_level") ? global.render_aa_level : 8;
			self.settings.enableAutoPlay = true;
			print($"[Renderer] Anti-aliasing: {self.settings.aa_level}x MSAA");
		};
		//self.Img();
		// Prefer active chart session image; do not invent missing defaults.
		var _bg_path = "";
		if (variable_global_exists("chart_session") && is_struct(global.chart_session) && bool(global.chart_session.ready) && is_string(global.chart_session.image_file) && string_length(global.chart_session.image_file)) {
			_bg_path = chart_in_path(global.chart_session.image_file);
		} else if (is_struct(self.folder_chart) && is_string(self.folder_chart.bg) && string_length(self.folder_chart.bg)) {
			_bg_path = chart_in_path(self.folder_chart.bg);
		};
		if (string_length(_bg_path)) {
			self.Background(_bg_path);
		};
		display_custom(game.settings.aa_level , game.settings.enableVsync);
		print("[L-Resource] Done." , game.settings.enableDebug);
	});
	
	///@desc 清理
	static Clean = (func(full = false){
		if(asset_sprite_valid(self.bg) && self.bg != chart_blur_kept()){
			sprite_delete(self.bg);	
		};
		self.bg = -1;
		self.bg_source_path = "";
		self.bg_blurred = false;
		self.bg_blur_pending = false;
		self.bg_blur_tries = 0;
		chart_blur_release();

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
				pls_ui_font_delete(self.font);
			};
			self.font = undefined;
			if(sprite_exists(self.effc)){
				sprite_delete(self.effc);	
			};
			self.effc = undefined;
			
		};
		print($"[D-Clean] {full ? "Full Clean Done." : "Done."}" , game.settings.enableDebug);
	});
	
	///@desc 数学函数
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
			if((!struct_exists(pos_struct , "start")) || (!struct_exists(pos_struct , "end"))
				|| (!struct_exists(pos_struct , "start2")) || (!struct_exists(pos_struct , "end2"))) then return(undefined);
			return({
				"start" : (0.5 + (pos_struct.start / 10)),
				"end" : (0.5 + (pos_struct[$ "end"] / 10)),
				"start2" : (0.5 + (pos_struct.start2 / 10)),
				"end2" : (0.5 + (pos_struct.end2 / 10))
			});
		})
		//pause1 : (function)
	});
	
	///@desc Phi小工具(仅对官谱格式写)
	static PhiTool = {
		///@desc 转变音符类型
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
		
		///@desc  保存谱面
		SaveTrack : (function(path){
			var js_str = (json_stringify(game.chart , true)),
				buff = (buffer_create(string_byte_length(js_str) , buffer_grow , 1));
			buffer_write(buff , buffer_string , js_str);
			buffer_save(buff , path);
			buffer_delete(buff);
			
			return(true);
		}),
		
		///@desc  文本
		FitEventsTrack : (function(){
				
		})
	};
	
	
	///@desc 创建判定线（同步路径：录像模式。交互加载走 official_lines_begin/pump/finish）
	static CreateLines = (func(){
		official_lines_begin();
		while (!official_lines_pump(0)) {};
		official_lines_finish();
	});
	
	
	print($"[Initional] Done." , self.settings.enableDebug);
	//});
};

function rpe_read_info_number(root_path, key_name, fallback) {
	var root = chart_path_norm(root_path);
	if (string_length(root) && string_char_at(root, string_length(root)) != "/") then root += "/";
	var info_paths = [root + "info.yml", root + "info.yaml", root + "info.txt"];
	var want = string_lower(string_replace_all(string(key_name), " ", ""));
	for (var path_i = 0; path_i < array_length(info_paths); path_i++) {
		var info_path = info_paths[path_i];
		if (!chart_file_exists_any(info_path)) then continue;
		var text = chart_read_text_file(info_path, -1);
		if (!string_length(text)) then continue;
		var lines = string_split(string_replace_all(text, "\r", ""), "\n");
		for (var info_i = 0; info_i < array_length(lines); info_i++) {
			var line_text = string_replace_all(lines[info_i], "\n", "");
			if (!string_length(line_text)) then continue;
			var first = string_char_at(line_text, 1);
			if (first == "#" || first == "-" || first == " " || first == "\t") then continue;
			var sep = string_pos(":", line_text);
			if (sep <= 0) then sep = string_pos("=", line_text);
			if (sep <= 0) then continue;
			var key = string_lower(string_replace_all(string_copy(line_text, 1, sep - 1), " ", ""));
			key = string_replace_all(key, "\t", "");
			if (key != want) then continue;
			var value = chart_info_trim_value(string_copy(line_text, sep + 1, string_length(line_text) - sep));
			return number(value, fallback);
		};
	};
	return fallback;
}

function rpe_read_info_offset_ms(root_path) {
	var root = chart_path_norm(root_path);
	if (string_length(root) && string_char_at(root, string_length(root)) != "/") then root += "/";
	var info_path = root + "info.txt";
	if (!chart_file_exists_any(info_path)) then info_path = root + "info.yml";
	if (!chart_file_exists_any(info_path)) then info_path = root + "info.yaml";
	if (!chart_file_exists_any(info_path)) then return 0;

	var text = chart_read_text_file(info_path, -1);
	if (!string_length(text)) then return 0;
	var lines = string_split(string_replace_all(text, "\r", ""), "\n");
	var result = 0;
	for (var info_i = 0; info_i < array_length(lines); info_i++) {
		var line_text = string_replace_all(lines[info_i], "\n", "");
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
	return result;
};

function rpe_array_to_beat(_time_array) {
	if (is_real(_time_array)) then return _time_array;
	if (!is_array(_time_array)) then return 0;
	var _n = array_length(_time_array);
	if (_n <= 0) then return 0;
	var _beat = real(array_get(_time_array, 0));
	if (_n == 1) then return _beat;
	var _num = real(array_get(_time_array, 1));
	var _den = (_n >= 3) ? real(array_get(_time_array, 2)) : 1;
	if (_den == 0) then return _beat;
	return _beat + _num / _den;
};

/// Activate RPE notes that should already be live after loading / retry / intro.
function rpe_sync_note_activation(_now_sec = undefined) {
	if (!variable_global_exists("game_1") || !is_struct(game_1)) then return;
	var _notes = game_1._notes;
	if (!is_array(_notes)) then return;
	if (_now_sec == undefined) {
		_now_sec = (variable_global_exists("game") && is_struct(game) && is_array(game.__time))
			? real(game.__time[1]) : 0;
	};
	var _records = game_1._note_activation_records;
	var _enabled = bool(game_1._note_activation_enabled ?? false);
	if (!_enabled) {
		for (var _i = 0; _i < array_length(_notes); _i++) {
			var _note = _notes[_i];
			if (!is_struct(_note)) then continue;
			chart_note_activate(_note.id);
			var _key = string(_note.id);
			if (is_struct(_records) && struct_exists(_records, _key)) {
				_records[$ _key].activated = true;
			};
		};
		game_1._note_activation_index = array_length(_notes);
		return;
	};
	var _index = 0;
	var _count = array_length(_notes);
	while (_index < _count) {
		var _item = _notes[_index];
		if (!is_struct(_item)) {
			_index++;
			continue;
		};
		var _always = bool(_item.alwaysActive ?? false);
		if (!_always && real(_item.activateSec ?? infinity) > _now_sec) then break;
		chart_note_activate(_item.id);
		var _item_key = string(_item.id);
		if (is_struct(_records) && struct_exists(_records, _item_key)) {
			_records[$ _item_key].activated = true;
		};
		_index++;
	};
	for (var _rest = _index; _rest < _count; _rest++) {
		var _late = _notes[_rest];
		if (!is_struct(_late) || !bool(_late.alwaysActive ?? false)) then continue;
		chart_note_activate(_late.id);
		var _late_key = string(_late.id);
		if (is_struct(_records) && struct_exists(_records, _late_key)) {
			_records[$ _late_key].activated = true;
		};
	};
	game_1._note_activation_index = _index;
	game_1._note_activation_last_time = _now_sec;
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

	if ((variable_global_exists("render_mode") && global.render_mode)
		|| (variable_global_exists("pls_archive_test") && global.pls_archive_test)) then return true;
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
	if (variable_global_exists("pls_archive_test") && global.pls_archive_test) then return true;
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

function render_ffmpeg_spec() {
	var spec = "";
	if (variable_global_exists("render_ffmpeg")) then spec = string_trim(string(global.render_ffmpeg ?? ""));
	if (!string_length(spec)) then spec = (os_type == os_windows ? "ffmpeg.exe" : "ffmpeg");
	return spec;
}

function render_ffmpeg_join(_dir, _name) {
	var d = string(_dir ?? "");
	if (!string_length(d)) then return string(_name ?? "");
	var last = string_char_at(d, string_length(d));
	if (last != "/" && last != "\\") then d += "/";
	return d + string(_name ?? "");
}

function render_ffmpeg_available() {
	var spec = render_ffmpeg_spec();
	if (file_exists(spec)) then return true;
	var norm = string_replace_all(spec, "\\", "/");
	var has_dir = (string_pos("/", norm) > 0)
		|| (string_length(norm) >= 2 && string_char_at(norm, 2) == ":");
	if (has_dir) then return false;
	var names = [spec];
	if (os_type == os_windows) {
		var lower = string_lower(spec);
		if (string_length(lower) < 4 || string_copy(lower, string_length(lower) - 3, 4) != ".exe") {
			array_add(names, spec + ".exe");
		};
	};
	var roots = [program_directory, working_directory];
	for (var root_i = 0; root_i < array_length(roots); root_i++) {
		for (var name_i = 0; name_i < array_length(names); name_i++) {
			if (file_exists(render_ffmpeg_join(roots[root_i], names[name_i]))) then return true;
		};
	};
	var path_env = environment_get_variable("PATH");
	if (!is_string(path_env) || !string_length(path_env)) then path_env = environment_get_variable("Path");
	if (!is_string(path_env) || !string_length(path_env)) then return false;
	var parts = string_split(path_env, os_type == os_windows ? ";" : ":");
	for (var part_i = 0; part_i < array_length(parts); part_i++) {
		var dir = string_trim(parts[part_i]);
		if (!string_length(dir)) then continue;
		for (var name_i = 0; name_i < array_length(names); name_i++) {
			if (file_exists(render_ffmpeg_join(dir, names[name_i]))) then return true;
		};
	};
	return false;
}

function render_ffmpeg_require() {
	if (render_ffmpeg_available()) then return true;
	var title = lang("render.ffmpegMissingTitle", "Error");
	var text = lang("render.ffmpegMissing", "FFmpeg was not found. Install FFmpeg or add it to the system PATH.");
	var buttons = [msgbox_button(lang("common.ok", "OK"))];
	if (i_wbox_native_ready()) {
		msgbox_error_sync(text, title, buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
	} else {
		msgbox_error_async(text, title, buttons, MSGBOX_BUTTON_ALIGN.RIGHT);
	};
	global.render_mode = false;
	if (variable_global_exists("render_cli") && global.render_cli) {
		global.render_cli = false;
		game_end();
		return false;
	};
	global.render_cli = false;
	room_goto(room_menu);
	return false;
}

function render_hitsound_path(_default_sound, _custom_path = "") {
	var _path = string(_custom_path ?? "");
	if (string_length(_path)) {
		_path = chart_file_readable_path(_path);
		if (file_exists(_path)) then _path = skin_sound_prepared_path(_path, true);
	};
	if (!is_string(_path) || !string_length(_path) || !file_exists(_path)) {
		switch (_default_sound) {
			case snd_note_drag: _path = working_directory + "render_sfx/drag.wav"; break;
			case snd_note_flick: _path = working_directory + "render_sfx/flick.wav"; break;
			default: _path = working_directory + "render_sfx/tap.wav"; break;
		};
	};
	return file_exists(_path) ? _path : "";
};

function render_schedule_note_hitsound(_note, _event_time, _custom_path = "", _is_fake = false) {
	if (!instance_exists(_note)) then return false;
	var fallback = snd_note_tap;
	if (variable_instance_exists(_note, "sound") && audio_exists(_note.sound)) then fallback = _note.sound;
	var path = string(_custom_path ?? "");
	if (!string_length(path)) then path = skin_hitsound_path_for_note(_note);
	return render_schedule_hitsound(fallback, _event_time, path, _is_fake);
};

function render_schedule_hitsound(_default_sound, _event_time, _custom_path = "", _is_fake = false) {
	if (!(variable_global_exists("render_mode") && global.render_mode)) then return false;
	if (bool(_is_fake)) then return false;
	var _path = render_hitsound_path(_default_sound, _custom_path);
	if (!string_length(_path)) then return false;
	// Precomputed events must start on the first frame in which the note is
	// actually judged and drawn. Runtime fallback events already use that frame.
	var _fps = max(1, real(global.render_fps));
	var _scheduled_time = max(0, real(_event_time));
	_scheduled_time = ceil(_scheduled_time * _fps - 0.000001) / _fps;
	if (!variable_global_exists("render_hitsounds") || !is_array(global.render_hitsounds)) {
		global.render_hitsounds = [];
	};
	array_add(global.render_hitsounds, {
		path: _path,
		time: _scheduled_time,
		volume: 0.5
	});
	return true;
};

function render_play_hitsound(_default_sound, _custom_path = "") {
	if (variable_instance_exists(id, "isFake") && bool(variable_instance_get(id, "isFake"))) then return false;
	if (variable_global_exists("render_mode") && global.render_mode) {
		if (variable_instance_exists(id, "render_hitsound_scheduled")
			&& bool(variable_instance_get(id, "render_hitsound_scheduled"))) then return true;
		var _path = render_hitsound_path(_default_sound, _custom_path);
		if (string_length(_path)) {
			var _event_time = max(0, global.render_frame) / max(1, global.render_fps);
			return bool(video_renderer_add_hitsound(_path, _event_time, 0.5));
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
	if (media_use_gx()) {
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
	static Fonts = {};
	//static BPMList = undefined;
	
	static chart_info = {
		"name" : "",
		"level" : "",
		"offset" : 0,
		"meta_offset" : 0,
		"info_offset" : 0,
		"song" : "",
		"background" : "",
		"line_length" : 6
	};
	
	static version = 0;
	
	static line_list = []; // 线列表
	static attachUI_Group = ["default" , "pause" , "combonumber" , "combo" , "score" , "bar" , "name" , "level"]; // UI绑定组
	static fatherLineList = [];  // 父线列表
	static Texture = {}; // 纹理存储
	static _notes = []; // 音符存储
	static chart_time = [0 , 0]; // chart real time / multi-BPM compensation
	static Reader = (func(_chart){
		var f = (string_length(_chart) ? _chart : ($"{working_directory}chart/Chart_IN.json"));
		show_debug_message($"[R-Chart] Loading: {f}");
		if (!chart_file_exists_any(f)) {
			show_debug_message($"[R-Chart] Missing file: {f}");
			return false;
		};

		var r = "";
		var session = chart_session_ensure();
		if (string(session.detected_chart_path) == chart_path_norm(f)
			&& is_string(session.detected_chart_text) && string_length(session.detected_chart_text)) {
			r = session.detected_chart_text;
			session.detected_chart_path = "";
			session.detected_chart_text = "";
		} else {
			r = chart_read_text_file(f, -1);
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
		if (string_length(self.chart_info.song) && chart_file_exists_any(chart_path_join(InChartPath, self.chart_info.song))) {
			game.folder_chart.music = self.chart_info.song;
		};
		if (string_length(self.chart_info.background) && chart_file_exists_any(chart_path_join(InChartPath, self.chart_info.background))) {
			game.folder_chart.bg = self.chart_info.background;
		};
		var meta_offset = real(meta[$ "offset"] ?? 0);
		var info_offset = rpe_read_info_offset_ms(InChartPath);
		self.chart_info.meta_offset = meta_offset;
		self.chart_info.info_offset = info_offset;
		self.chart_info.offset = meta_offset + info_offset;
		var info_line_length = rpe_read_info_number(InChartPath, "linelength", 6);
		if (!is_finite(info_line_length) || info_line_length <= 0) then info_line_length = 6;
		self.chart_info.line_length = info_line_length;
		var meta_aspect = meta[$ "aspectRatio"] ?? (meta[$ "aspect_ratio"] ?? undefined);
		var parsed_meta_aspect = chart_parse_aspect_ratio(meta_aspect, 0);
		if (parsed_meta_aspect > 0) {
			chart_aspect_ratio = parsed_meta_aspect;
			if (variable_global_exists("chart_session") && is_struct(global.chart_session)) {
				global.chart_session.aspect_ratio = parsed_meta_aspect;
			};
		};
		print($"RPE offset(ms): META={meta_offset}, info={info_offset}, total={self.chart_info.offset}", game.settings.enableDebug);
		
		delete(self.chart.META);
		
		print("[R-Chart] Done." , game.settings.enableDebug);
		return true;
	});
	
	///@desc RPE创建判定线（同步路径：录像模式。交互加载走 rpe_lines_begin/pump/finish）
	static CreateLines = (func(){
		rpe_lines_begin();
		while (!rpe_lines_pump(0)) {};
		rpe_lines_finish();
	});
	
	///@desc RPE数学函数(aligned with PCR ArrayToTime / BPM helpers)
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
	
	// 谱面信息
	static chart = {
		"version" : 4,
		"offset" : 0,
		"judgeLineList" : [],
		"notes" : [],
        "bpmList" : []
	};
    
    static line_group = [];
	
	
	///@desc 读取器
	static Reader = (func(_chart){
		var f = (string_length(_chart) ? _chart : ($"{working_directory}chart/Chart_IN.json")),
			handle = (file_text_open_read(chart_file_readable_path(f)));
		var cl = false;
		
        // idk
		var _pe_chart_func = {
			// Notes         
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
			//  判定线事件
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
			//  
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
			
			//  
			if(!cl){
				self.chart.offset = (number(text , 0));
				cl = true;
				continue;
			};
			
			// 
			var __t = (string_replace_all(string_copy(text , 1 , 2) , " " , "")),
				args = (string_split_ext(string_copy(text , 3 , string_length(text)) , [" " , "\n" , "\r"] , true));
			
			// 
			if(!array_length(args)) then continue;
			
			// 
			var lineID = 0;
			
			// 
			if(string_length(__t) == 2) then lineID = (number(args[0] , -1));
			//var lineID = (number(args))
			
			//
			if(lineID == -1) then continue;
			
			// 
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
	
	///@desc PEC数学函数
	static Math = ({
		///@desc Second 闂?Beat
		secToBeat : (func(_sec , _bpm){
			 return((_sec) * ((_bpm) / 60));	
		}),
		
		///@desc Beat 闂?Second
		beatToSec : (func(_beat , _bpm){
			return(_beat * (60 / _bpm));	
		}),
        
        /// @desc
		/// @param {Real} wx 
        /// @param {Real} wy 
        /// @returns {Array} 
        pos_to_size : (func(xx , yy){
            var sw = 1366;
            var sh = 768;
        
            var world_w = 2048;  // 1024 - (-1024)
            var world_h = 1400;  // 700 - (-700)
        
            var sx = (xx + 1024) * (sw / world_w);
            var sy = sh - (yy + 700) * (sh / world_h);
        
            return [sx, sy];
        })
	});
	
    ///@desc PEC创建判定线
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
    
	///@desc 保存谱面
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

function pec_note_alpha_visible(_raw, _is_above, _sec_to_hit, _note_sec = undefined) {
	if (_raw >= -0.5) then return true;
	if (abs(_raw + 1) <= 0.5) then return false;
	if (abs(_raw + 2) <= 0.5) then return bool(_is_above);
	if (_raw > -1000 && _raw <= -100) {
		// Phira PE extension: appear (abs(alpha)-100)/10 beats before the note.
		var appear_beats = (abs(_raw) - 100) / 10;
		var bpm = 140;
		if (variable_global_exists("game_2") && is_struct(game_2) && is_struct(game_2.chart)
			&& is_array(game_2.chart.bpmList)) {
			var sec = (is_undefined(_note_sec) ? 0 : real(_note_sec));
			bpm = pec_bpm_at_sec(game_2.chart.bpmList, sec);
		};
		return (_sec_to_hit < appear_beats * 60 / max(0.0001, bpm));
	};
	return false;
}

function pec_line_data() {
	return { moveEvents: [], alphaEvents: [], rotateEvents: [], speedEvents: [] };
}

function pec_beat_to_sec(timeline, beat) {
	if (!is_array(timeline) || array_length(timeline) <= 0) then return 0;
	if (beat < timeline[0].beat) then return 0;
	var low = 0;
	var high = array_length(timeline) - 1;
	while (low < high) {
		var middle = (low + high + 1) div 2;
		if (timeline[middle].beat <= beat) low = middle;
		else high = middle - 1;
	};
	var point = timeline[low];
	return point.second + (beat - point.beat) * 60 / point.bpm;
}

function pec_bpm_index_at_sec(timeline, sec) {
	if (!is_array(timeline) || array_length(timeline) <= 0) then return 0;
	var low = 0;
	var high = array_length(timeline) - 1;
	while (low < high) {
		var middle = (low + high + 1) div 2;
		if (timeline[middle].second <= sec) low = middle;
		else high = middle - 1;
	};
	return low;
}

function pec_bpm_at_sec(timeline, sec) {
	if (!is_array(timeline) || array_length(timeline) <= 0) then return 60;
	return timeline[pec_bpm_index_at_sec(timeline, sec)].bpm;
}

function pec_cmp_real(a, b) {
	// GML array_sort truncates the comparator to an integer. `a - b` of 0.125
	// becomes 0, so cv 30 and cv 30.125 would compare equal and can swap.
	if (a < b) then return -1;
	if (a > b) then return 1;
	return 0;
}

function pec_floor_at_sec(speed_events, sec) {
	if (!is_array(speed_events) || array_length(speed_events) <= 0) then return 0;
	if (sec < speed_events[0].startSec) then return 0;
	var low = 0;
	var high = array_length(speed_events) - 1;
	while (low < high) {
		var middle = (low + high + 1) div 2;
		if (speed_events[middle].startSec <= sec) low = middle;
		else high = middle - 1;
	};
	var event = speed_events[low];
	var elapsed = max(0, sec - event.startSec);
	// A cv only lasts until the next cv. Without this clamp a 70000 segment
	// would keep integrating after cv 14 and throw later notes off the chart.
	if (struct_exists(event, "endSec") && is_finite(event.endSec)) {
		elapsed = min(elapsed, max(0, event.endSec - event.startSec));
	};
	return event.floor + elapsed * event.value;
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
		var start_sec = pec_beat_to_sec(timeline, source.startBeat);
		var end_sec = pec_beat_to_sec(timeline, source.endBeat);
		var event = {
			startSec: start_sec,
			endSec: end_sec,
			start: previous,
			"end": source.target,
			easing: pec_easing(source.easing),
			instant: (start_sec == end_sec)
		};
		if (kind == "move") {
			event.startX = previous[0];
			event.startY = previous[1];
			event.endX = source.target[0];
			event.endY = source.target[1];
		};
		array_add(result, event);
		previous = source.target;
	};
	return result;
}

function pec_reader_load(ctx, chart_path) {
	ctx.chart = { version: 4, offsetSeconds: 0, judgeLineList: [], notes: [], bpmList: [] };
	ctx.line_group = [];
	if (!chart_file_exists_any(chart_path)) then return false;
	var pec_text = chart_read_text_file(chart_path, -1);
	if (!string_length(pec_text)) then return false;
	var pec_lines = string_split(string_replace_all(pec_text, "\r", ""), "\n");
	if (array_length(pec_lines) <= 0) then return false;
	var pec_line_index = 0;
	var pec_header_offset_ms = number(pec_lines[pec_line_index], 0);
	pec_line_index++;
	var pec_info_offset_ms = 0;
	if (variable_global_exists("chart_session") && is_struct(global.chart_session)) {
		pec_info_offset_ms = real(global.chart_session.info_offset_ms ?? 0);
	};
	ctx.chart.offsetSeconds = (pec_header_offset_ms + pec_info_offset_ms) / 1000 - 0.175;
	var pending_line = "";
	var has_pending_line = false;
	var last_note = undefined;
	while (has_pending_line || pec_line_index < array_length(pec_lines)) {
		var source_line;
		if (has_pending_line) {
			source_line = pending_line;
			has_pending_line = false;
		} else {
			source_line = pec_lines[pec_line_index];
			pec_line_index++;
		};
		var tokens = string_split_ext(source_line, [" ", "\t", "\r", "\n"], true);
		if (array_length(tokens) <= 0) then continue;
		var command = string_lower(tokens[0]);
		if (command == "bp" && array_length(tokens) >= 3) {
			array_add(ctx.chart.bpmList, { beat: number(tokens[1], 0), bpm: max(0.0001, number(tokens[2], 60)), second: 0 });
			continue;
		};
		// Phira: "#" / "&" are first-class commands that rewrite the last note.
		if (command == "#" && array_length(tokens) >= 2) {
			if (is_struct(last_note)) then last_note.speed = number(tokens[1], last_note.speed);
			continue;
		};
		if (command == "&" && array_length(tokens) >= 2) {
			if (is_struct(last_note)) then last_note.xscale = number(tokens[1], last_note.xscale);
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
			var hold = (command == "n2");
			var minimum = (hold ? 7 : 6);
			if (array_length(tokens) < minimum) then continue;
			var _speed = 1;
			var width_scale = 1;
			var extra_i = minimum;
			while (extra_i < array_length(tokens)) {
				if (tokens[extra_i] == "#" && extra_i + 1 < array_length(tokens)) {
					_speed = number(tokens[extra_i + 1], 1);
					extra_i += 2;
				} else if (tokens[extra_i] == "&" && extra_i + 1 < array_length(tokens)) {
					width_scale = number(tokens[extra_i + 1], 1);
					extra_i += 2;
				} else extra_i++;
			};
			for (var modifier_i = 0; modifier_i < 2; modifier_i++) {
				if (!has_pending_line && pec_line_index >= array_length(pec_lines)) break;
				var modifier_line;
				if (has_pending_line) {
					modifier_line = pending_line;
					has_pending_line = false;
				} else {
					modifier_line = pec_lines[pec_line_index];
					pec_line_index++;
				};
				var modifier = string_split_ext(modifier_line, [" ", "\t", "\r", "\n"], true);
				if (array_length(modifier) < 2) {
					pending_line = modifier_line;
					has_pending_line = true;
					break;
				};
				if (modifier[0] == "#") _speed = number(modifier[1], 1);
				else if (modifier[0] == "&") width_scale = number(modifier[1], 1);
				else {
					pending_line = modifier_line;
					has_pending_line = true;
					break;
				};
			};
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
			last_note = ctx.chart.notes[array_length(ctx.chart.notes) - 1];
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
	array_sort(ctx.chart.bpmList, function(a, b) { return pec_cmp_real(a.beat, b.beat); });
	for (var bpm_i = 1; bpm_i < array_length(ctx.chart.bpmList); bpm_i++) {
		var previous = ctx.chart.bpmList[bpm_i-1];
		ctx.chart.bpmList[bpm_i].second = previous.second + (ctx.chart.bpmList[bpm_i].beat-previous.beat)*60/previous.bpm;
	};
	for (var bpm_tick_i = 0; bpm_tick_i < array_length(ctx.chart.bpmList); bpm_tick_i++) {
		ctx.chart.bpmList[bpm_tick_i].holdTickInterval = 30 / max(1, ctx.chart.bpmList[bpm_tick_i].bpm);
	};
	for (var line_i = 0; line_i < array_length(ctx.chart.judgeLineList); line_i++) {
		var item = ctx.chart.judgeLineList[line_i];
		item.moveEvents = pec_finalize_property(item.moveEvents, ctx.chart.bpmList, "move");
		item.alphaEvents = pec_finalize_property(item.alphaEvents, ctx.chart.bpmList, "alpha");
		item.rotateEvents = pec_finalize_property(item.rotateEvents, ctx.chart.bpmList, "rotate");
		var speed_count = array_length(item.speedEvents);
		for (var speed_order_i = 0; speed_order_i < speed_count; speed_order_i++) {
			item.speedEvents[speed_order_i].order = speed_order_i;
		};
		array_sort(item.speedEvents, function(a, b) {
			var beat_cmp = pec_cmp_real(a.beat, b.beat);
			if (beat_cmp != 0) then return beat_cmp;
			return pec_cmp_real(a.order, b.order);
		});
		// Phira inserts (t=0, speed=0) when the first cv is not at the origin.
		if (array_length(item.speedEvents) > 0 && abs(item.speedEvents[0].beat) > 0.00001) {
			var _shifted = [];
			array_add(_shifted, { beat: 0, value: 0, order: -1 });
			for (var _si = 0; _si < array_length(item.speedEvents); _si++) array_add(_shifted, item.speedEvents[_si]);
			item.speedEvents = _shifted;
			speed_count = array_length(item.speedEvents);
		};
		for (var speed_i = 0; speed_i < speed_count; speed_i++) {
			item.speedEvents[speed_i].startSec = pec_beat_to_sec(ctx.chart.bpmList, item.speedEvents[speed_i].beat);
		};
		array_sort(item.speedEvents, function(a, b) {
			var sec_cmp = pec_cmp_real(a.startSec, b.startSec);
			if (sec_cmp != 0) then return sec_cmp;
			return pec_cmp_real(a.order, b.order);
		});
		var floor_value = 0;
		for (var speed_i = 0; speed_i < speed_count; speed_i++) {
			var speed_item = item.speedEvents[speed_i];
			if (speed_i > 0) {
				var previous_speed = item.speedEvents[speed_i-1];
				previous_speed.endSec = speed_item.startSec;
				floor_value += (speed_item.startSec-previous_speed.startSec)*previous_speed.value;
			};
			speed_item.floor = floor_value;
			speed_item.endSec = infinity;
		};
	};
	for (var note_i = 0; note_i < array_length(ctx.chart.notes); note_i++) {
		var note = ctx.chart.notes[note_i];
		var speed_events = ctx.chart.judgeLineList[note.line_id].speedEvents;
		note.startSec = pec_beat_to_sec(ctx.chart.bpmList, note.startBeat);
		note.endSec = pec_beat_to_sec(ctx.chart.bpmList, note.endBeat);
		note.floorPosition = pec_floor_at_sec(speed_events, note.startSec);
		note.endFloorPosition = pec_floor_at_sec(speed_events, note.endSec);
		note.highlightKey = note.startBeat;
		note.localXFactor = note.xOffset * 0.05625;
		note.sideDirection = note.isAbove ? -1 : 1;
		note.angleOffset = note.isAbove ? 0 : 180;
		note.speedFloorStart = note.speed * note.floorPosition;
		note.speedFloorEnd = note.speed * note.endFloorPosition;
		note.speedHoldFloorLength = note.speed * (note.endFloorPosition - note.floorPosition);
	};
	array_sort(ctx.chart.notes, function(a,b) {
		if (a.highlightKey < b.highlightKey) then return -1;
		if (a.highlightKey > b.highlightKey) then return 1;
		return 0;
	});
	for (var highlight_i = 0; highlight_i < array_length(ctx.chart.notes); highlight_i++) ctx.chart.notes[highlight_i].hl = 0;
	if (bool(game.settings.enableNoteHightLight ?? true)) {
		var group_start = 0;
		while (group_start < array_length(ctx.chart.notes)) {
			var group_end = group_start + 1;
			var group_key = ctx.chart.notes[group_start].highlightKey;
			while (group_end < array_length(ctx.chart.notes) && ctx.chart.notes[group_end].highlightKey == group_key) group_end++;
			if (group_end - group_start > 1) {
				for (var group_i = group_start; group_i < group_end; group_i++) ctx.chart.notes[group_i].hl = 1;
			};
			group_start = group_end;
		};
	};
	return true;
}

function pec_create_runtime(ctx) {
	pec_lines_begin(ctx);
	while (!pec_lines_pump(0)) {};
	pec_lines_finish();
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

