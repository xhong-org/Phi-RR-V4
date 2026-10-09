// 石库水
#macro print LogOutputFile
#macro elif else if
#macro func function
#macro isExists chart_file_exists_any
#macro InChartPath (variable_global_exists("chart_active_path") && is_string(global.chart_active_path) && string_length(global.chart_active_path) ? global.chart_active_path : (working_directory + "chart/"))
#macro VerReal { "windows": 40537, "android": 40534, "gxgames": 40532 } // 各平台版本号(独立)
#macro VerStr "v.4.1.0b"

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


/// @desc 资源检测函数(sprite)(ref && real)
/// @param _id {Ref}
function asset_sprite_valid(_id) {
	if (is_undefined(_id)) then return (false);
	if (is_string(_id)) then return (false);
	// Failed sprite_add traditionally returns -1
	if (is_real(_id) && _id < 0) then return (false);
	return (sprite_exists(_id));
}

/// @desc 资源检测函数(font)(ref && real)
/// @param _id {Ref}
function asset_font_valid(_id) {
	if (is_undefined(_id)) then return (false);
	if (is_string(_id)) then return (false);
	if (is_real(_id) && _id < 0) then return (false);
	return (font_exists(_id));
}

/// @desc buffer缓冲区检测函数(buffer)(ref && real)
/// @param _id {Buffer ID}
function asset_buffer_valid(_id) {
	if (is_undefined(_id)) then return (false);
	if (is_string(_id)) then return (false);
	if (is_real(_id) && _id < 0) then return (false);
	return (buffer_exists(_id));
}



// 实验性内容
//scheduler_resolution_set(800000000000);
//gpu_set_texfilter(true);
if (os_browser == browser_not_a_browser) then gml_release_mode(true);
//gml_pragma("forceinline");

//string_format()

/// @desc 图层深度 (未知) 
// 憋憋枚举
enum DEPTH {
	DEBUG = -15000,
	LINE = -3000,
	NOTE = -7000,
	HEF = -11000,
	BG = -100
};

/// PhiZone z: higher values draw later. 1000 depth per unit keeps 1.5 and 2
/// apart, and a line-id tie break cannot cross into the next layer.
function chart_layer_depth(z) {
	return (-1000 * z);
}

/// VM rejects other_instance.depth = value as a read-only built-in.
/// Setting it from inside the instance still works.
function chart_set_instance_depth(_inst, _depth) {
	if (!instance_exists(_inst)) then return;
	with (_inst) {
		depth = _depth;
	};
}

/// RPE type 1 tap, 2 hold, 3 flick, 4 drag. Explicit zIndex wins.
function chart_note_layer_z(rpe_type, explicit_z = undefined) {
	if (is_real(explicit_z) && is_finite(explicit_z)) then return explicit_z;
	var priority = 3;
	if (rpe_type == 2) then priority = 1;
	else if (rpe_type == 3) then priority = 4;
	else if (rpe_type == 4) then priority = 2;
	return priority + 2;
}

/// RPE LineData::update parent block, in view pixels, y still up.
/// A child offset is scaled by view/1350 and view/900 before the father
/// rotation. Rotating in chart space first opens a rectangle once the father
/// turns and those two scales differ, which is every 16:9 playfield.
/// Returns [x from view center, y up, rotation]. Unparented lines and fathers
/// with rotation 0 match the previous chart-space fold.
function rpe_line_view_pose(_line, _sx, _sy) {
	var local_x = 0;
	var local_y = 0;
	var local_r = 0;
	if (!instance_exists(_line)) then return [local_x, local_y, local_r];
	if (variable_instance_exists(_line, "__raw_x") && is_real(_line.__raw_x)) then local_x = _line.__raw_x * _sx;
	if (variable_instance_exists(_line, "__raw_y") && is_real(_line.__raw_y)) then local_y = _line.__raw_y * _sy;
	if (variable_instance_exists(_line, "__raw_r") && is_real(_line.__raw_r)) then local_r = _line.__raw_r;
	if (!variable_instance_exists(_line, "_father_chain") || !is_array(_line._father_chain)) {
		_line._father_chain = [];
	};
	var chain = _line._father_chain;
	if (array_length(chain) == 0 && is_real(_line.isFather) && _line.isFather >= 0
			&& variable_global_exists("game_1") && is_struct(game_1) && is_array(game_1.line_list)) {
		var lazy_parent = _line.isFather;
		var lazy_guard = 0;
		var line_list = game_1.line_list;
		while (lazy_parent >= 0 && lazy_parent < array_length(line_list) && lazy_guard < 16) {
			var lazy_line = line_list[lazy_parent];
			if (!instance_exists(lazy_line)) then break;
			array_add(chain, lazy_line);
			lazy_parent = is_real(lazy_line.isFather) ? lazy_line.isFather : -1;
			lazy_guard++;
		};
	};
	if (array_length(chain) <= 0) then return [local_x, local_y, local_r];
	var parent_x = 0;
	var parent_y = 0;
	var parent_r = 0;
	var have_parent = false;
	for (var ai = array_length(chain) - 1; ai >= 0; ai--) {
		var ancestor = chain[ai];
		if (!instance_exists(ancestor) || !variable_instance_exists(ancestor, "__raw_x")) {
			have_parent = false;
			break;
		};
		var ancestor_x = ancestor.__raw_x * _sx;
		var ancestor_y = ancestor.__raw_y * _sy;
		if (!have_parent) {
			parent_x = ancestor_x;
			parent_y = ancestor_y;
			parent_r = ancestor.__raw_r;
			have_parent = true;
		} else {
			var parent_cos = dcos(parent_r);
			var parent_sin = dsin(parent_r);
			parent_x += ancestor_x * parent_cos + ancestor_y * parent_sin;
			parent_y += ancestor_y * parent_cos - ancestor_x * parent_sin;
			parent_r = ancestor.__raw_r + (bool(ancestor.rotFatherLine) ? parent_r : 0);
		};
	};
	if (!have_parent) then return [local_x, local_y, local_r];
	var child_cos = dcos(parent_r);
	var child_sin = dsin(parent_r);
	var out_r = local_r;
	if (bool(_line.rotFatherLine)) then out_r += parent_r;
	return [
		parent_x + local_x * child_cos + local_y * child_sin,
		parent_y + local_y * child_cos - local_x * child_sin,
		out_r
	];
}

/// PhiEdit 1.7 EditMain::computeViewSize. Fit the chart aspect into 1350x900.
function rpe_preview_size(_aspect) {
	if (!is_real(_aspect) || !is_finite(_aspect) || _aspect <= 0) then _aspect = 16 / 9;
	var preview_w = 1350;
	var preview_h = 1350 / _aspect;
	if (preview_h > 900) {
		preview_h = 900;
		preview_w = _aspect * 900;
	};
	return [preview_w, preview_h];
}

/// line.png only. LineView::apply uses scaleX * 4000 and scaleY * 5 design
/// points at editor zoom 1, independent of the texture's pixel size.
/// Those points sit in the preview from computeViewSize, then map onto the
/// playfield by view/preview.
function rpe_default_line_pixel_size(scale_x, scale_y, view_w) {
	var design_y = view_w / 1350;
	if (variable_global_exists("chart_view_height") && is_real(chart_view_height) && chart_view_height > 0) {
		design_y = chart_view_height / 900;
	};
	var aspect = 16 / 9;
	if (variable_global_exists("chart_aspect_ratio") && is_real(chart_aspect_ratio) && is_finite(chart_aspect_ratio) && chart_aspect_ratio > 0) {
		aspect = chart_aspect_ratio;
	};
	var preview = rpe_preview_size(aspect);
	var view_h = design_y * 900;
	return [scale_x * 4000 * (view_w / preview[0]), scale_y * 5 * (view_h / preview[1])];
}

/// Custom judge-line texture only (Texture != "line.png"), including GIF frames.
/// LineView::apply sets scale to scaleX / shrink and scaleY / shrink. Playback
/// shrink is 1, so the sprite is its pixel size times the line scale, in
/// preview points. computeViewSize is that preview. The playfield shows the
/// same 1350x900 chart space across view_w x view_h, so each axis maps by
/// view/preview on its own.
function rpe_custom_texture_pixel_size(scale_x, scale_y, sprite_w, sprite_h, view_w) {
	var aspect = 16 / 9;
	if (variable_global_exists("chart_aspect_ratio") && is_real(chart_aspect_ratio) && is_finite(chart_aspect_ratio) && chart_aspect_ratio > 0) {
		aspect = chart_aspect_ratio;
	};
	var preview = rpe_preview_size(aspect);
	var preview_w = preview[0];
	var preview_h = preview[1];
	var view_h = view_w * preview_h / preview_w;
	if (variable_global_exists("chart_view_height") && is_real(chart_view_height) && chart_view_height > 0) {
		view_h = chart_view_height;
	};
	return [sprite_w * scale_x * (view_w / preview_w), sprite_h * scale_y * (view_h / preview_h)];
}

/// Pixel width of the judge line as Draw draws it. Used to clip an attached video.
function chart_line_pixel_width(line_instance) {
	if (!instance_exists(line_instance)) then return 0;
	var view_w = 1;
	if (variable_global_exists("chart_view_width") && is_real(chart_view_width) && chart_view_width > 0) {
		view_w = chart_view_width;
	};
	var scale_x = real(line_instance.__scale_x);
	if (!is_finite(scale_x)) then scale_x = 1;
	var scale_y = real(line_instance.__scale_y);
	if (!is_finite(scale_y)) then scale_y = 1;
	var sprite = line_instance.sprite_index;
	var sprite_w = max(1, sprite_get_width(sprite));
	var sprite_h = max(1, sprite_get_height(sprite));
	if (!line_instance.is_default_line) {
		var csv = chart_line_override(line_instance.line_id);
		if (is_struct(csv)) {
			var csv_scale = chart_line_csv_sprite_scale(csv, sprite);
			return abs(csv_scale[0] * scale_x) * sprite_w;
		};
		var custom_px = rpe_custom_texture_pixel_size(scale_x, scale_y, sprite_w, sprite_h, view_w);
		return abs(custom_px[0]);
	};
	var pixel_size = rpe_default_line_pixel_size(scale_x, scale_y, view_w);
	return abs(pixel_size[0]);
}

/// PhiZone scaleOnNotes 2. Notes stay full size and are masked to the line's
/// current pixel width. The strip is infinite along the note highway.
/// Returns 0 (no clip), 1 (scissor), or 2 (rotated shader).
function chart_note_scale_clip_begin(line_instance) {
	static u_clip = -1;
	static u_half = -1;
	static fetched = false;
	if (!instance_exists(line_instance)) then return 0;
	var mode = 0;
	if (variable_instance_exists(line_instance, "scale_on_notes") && is_real(line_instance.scale_on_notes)) {
		mode = real(line_instance.scale_on_notes);
	};
	if (mode != 2) then return 0;

	var half_w = chart_line_pixel_width(line_instance) * 0.5;
	var ang = line_instance.image_angle;
	var norm = ang mod 360;
	if (norm < 0) then norm += 360;
	var view_l = 0;
	var view_t = 0;
	var view_r = room_width;
	var view_b = room_height;
	if (variable_global_exists("chart_view_left") && is_real(chart_view_left)) then view_l = chart_view_left;
	if (variable_global_exists("chart_view_right") && is_real(chart_view_right)) then view_r = chart_view_right;
	if (variable_global_exists("chart_view_height") && is_real(chart_view_height) && chart_view_height > 0) then view_b = chart_view_height;

	var horizontal = (norm <= 0.75 || norm >= 359.25 || abs(norm - 180) <= 0.75);
	var vertical = (abs(norm - 90) <= 0.75 || abs(norm - 270) <= 0.75);
	if (horizontal || vertical) {
		var clip_l = view_l;
		var clip_t = view_t;
		var clip_r = view_r;
		var clip_b = view_b;
		if (horizontal) {
			clip_l = line_instance.x - half_w;
			clip_r = line_instance.x + half_w;
		} else {
			clip_t = line_instance.y - half_w;
			clip_b = line_instance.y + half_w;
		};
		var l = max(view_l, clip_l);
		var t = max(view_t, clip_t);
		var r = min(view_r, clip_r);
		var b = min(view_b, clip_b);
		// Wider than the chart view: the default pipeline must draw notes and hits.
		if (l <= view_l && t <= view_t && r >= view_r && b >= view_b) then return 0;
		var sl = floor(l);
		var st = floor(t);
		var sw = max(0, ceil(r) - sl);
		var sh = max(0, ceil(b) - st);
		gpu_set_scissor(sl, st, sw, sh);
		return 1;
	};

	var dir_x = dcos(ang);
	var dir_y = -dsin(ang);
	var cover = true;
	if (abs((view_l - line_instance.x) * dir_x + (view_t - line_instance.y) * dir_y) > half_w) then cover = false;
	else if (abs((view_r - line_instance.x) * dir_x + (view_t - line_instance.y) * dir_y) > half_w) then cover = false;
	else if (abs((view_l - line_instance.x) * dir_x + (view_b - line_instance.y) * dir_y) > half_w) then cover = false;
	else if (abs((view_r - line_instance.x) * dir_x + (view_b - line_instance.y) * dir_y) > half_w) then cover = false;
	if (cover) then return 0;
	// shader_reset inside a z-range capture drops later sprites off that surface.
	var _capture_target = surface_get_target();
	if (surface_exists(_capture_target) && _capture_target != application_surface) then return 0;
	if (!shader_is_compiled(shd_note_scale_clip)) then return 0;
	if (!fetched) {
		u_clip = shader_get_uniform(shd_note_scale_clip, "u_clip");
		u_half = shader_get_uniform(shd_note_scale_clip, "u_half");
		fetched = (u_clip >= 0 && u_half >= 0);
		if (!fetched) then return 0;
	};
	shader_set(shd_note_scale_clip);
	shader_set_uniform_f(u_clip, line_instance.x, line_instance.y, dir_x, dir_y);
	shader_set_uniform_f(u_half, half_w);
	return 2;
}

function chart_note_scale_clip_end(active) {
	if (active == 1) {
		chart_mask_scissor_set();
	} else if (active == 2) {
		shader_reset();
	};
}


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
		"aa_level" : 0,							// aa_level等级(default:0)
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
		"notePreloadSeconds" : 3,				// RPE/PEC note preload seconds (0-60). Official ignores this.
		"disableChartShader" : false,			// 禁用谱面 Shader(default:false)
		"directGlslEs" : false,					// Windows: compile chart GLSL ES directly (default:false)
		"disableChartVideo" : false,			// 禁用谱面视频(default:false)
		"enableNoiseArea" : true,				// 是否启用噪区(default:true)
		"enableNoiseAreaFine" : false,			// 是否开启噪区精细(default:false)
		"reduceNoiseAreaWave" : false,			// 减少噪区起伏幅度(default:false)
		"TEST1" : false							// judge offset jitter test (default false)
	};

	// Captured once, before Configs() overwrites this shared static with configs.ini.
	if (!variable_global_exists("phigros_settings_baseline") || !is_struct(global.phigros_settings_baseline)) {
		global.phigros_settings_baseline = {};
		var _settings_names = struct_get_names(settings);
		for (var _settings_i = 0; _settings_i < array_length(_settings_names); _settings_i++) {
			var _settings_key = _settings_names[_settings_i];
			global.phigros_settings_baseline[$ _settings_key] = settings[$ _settings_key];
		};
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
		
		//var ok = (game.PhiTool.FitEventsTrack;
		//if(ok) then game.PhiTool.ExportRPE(InChartPath + "RPE170.json");
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
		// Backgroud 图像添加检验
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
			
			if (file_exists(cache_path)) then file_delete(cache_path); // 清理冲突名字图片缓存
			
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
			if (settings_saved_key_ignored(name[i])) then continue;
			if (is_string(self.settings[$ name[i]])) then self.settings[$ name[i]] = (ini_read_string("Settings" , name[i] , self.settings[$ name[i]]));
			else self.settings[$ name[i]] = (self.strToReal(ini_read_string("Settings" , name[i] , string(self.settings[$ name[i]])), self.settings[$ name[i]]));
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
	
	///@desc Phi小工具。官谱与 PEC 都能导出 RPE 160。
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
			return chart_buffer_save_text(path, json_stringify(game.chart, true));
		}),
		
		///@desc 把官谱里被切成线性段的判定线事件拟合成 RPE 缓动，生成 RPE 谱。
		/// 不改 game.chart。META.RPEVersion = 160，走 1.7 之前的速度积分。
		FitEventsTrack : (function(){
			if (!variable_global_exists("game") || !is_struct(game) || !is_struct(game[$ "chart"])) then return false;
			var built = phi_official_to_rpe(game.chart);
			if (!is_struct(built)) then return false;
			self.rpeStats = built[$ "stats"];
			variable_struct_remove(built, "stats");
			self.rpeChart = built;
			var stats = self.rpeStats;
			if (is_struct(stats)) then phi_tools_event_report(stats);
			return true;
		}),

		///@desc 导出 RPE（META.RPEVersion = 160）。路径为空时写到当前谱面目录的 Chart_RPE.json。
		ExportRPE : (function(path = ""){
			if (!self.FitEventsTrack()) then return false;
			if (!is_string(path) || !string_length(path)) {
				var root = working_directory;
				if (variable_global_exists("InChartPath") && is_string(InChartPath) && string_length(InChartPath)) then root = InChartPath;
				path = chart_path_join(root, "Chart_RPE.json");
			};
			chart_buffer_save_text(path, json_stringify(self.rpeChart, true));
			show_debug_message($"[PhiTool] Wrote RPE chart: {path}");
			return true;
		}),

		///@desc 把 PEC 文本写成 RPE。不改 game.chart。META.RPEVersion = 160。
		PecToRPE : (function(pec_text){
			if (!is_string(pec_text) || !string_length(pec_text)) then return false;
			var built = phi_pec_to_rpe(pec_text);
			if (!is_struct(built)) then return false;
			self.rpeStats = built[$ "stats"];
			variable_struct_remove(built, "stats");
			self.rpeChart = built;
			var stats = self.rpeStats;
			if (is_struct(stats)) then phi_tools_event_report(stats);
			return true;
		}),

		///@desc 把 PEC 文本导出成 RPE 文件。路径为空时写到当前谱面目录的 Chart_PEC_RPE.json。
		ExportPecRPE : (function(pec_text, path = ""){
			if (!self.PecToRPE(pec_text)) then return false;
			if (!is_string(path) || !string_length(path)) {
				var root = working_directory;
				if (variable_global_exists("InChartPath") && is_string(InChartPath) && string_length(InChartPath)) then root = InChartPath;
				path = chart_path_join(root, "Chart_PEC_RPE.json");
			};
			chart_buffer_save_text(path, json_stringify(self.rpeChart, true));
			show_debug_message($"[PhiTool] Wrote PEC as RPE: {path}");
			return true;
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

/// buffer_string plants a NUL on the last UTF-8 byte when the buffer was sized to
/// the string, and buffer_save writes the whole allocation. Either one leaves a
/// garbled last character. Write buffer_text plus a sacrificial ASCII byte, then
/// save every byte except that extra one.
function chart_buffer_save_text(path, text) {
	var body = is_string(text) ? text : string(text);
	var payload = body + " ";
	var bytes = string_byte_length(payload);
	if (bytes < 1) then bytes = 1;
	var buff = buffer_create(bytes, buffer_fixed, 1);
	buffer_write(buff, buffer_text, payload);
	var wrote = buffer_tell(buff);
	if (wrote > 0) then wrote -= 1;
	if (wrote < 0) then wrote = 0;
	buffer_save_ext(buff, path, 0, wrote);
	buffer_delete(buff);
	return true;
}

function phi_gcd(a, b) {
	var gcd_a = abs(floor(real(a)));
	var gcd_b = abs(floor(real(b)));
	while (gcd_b > 0) {
		var gcd_next = gcd_a mod gcd_b;
		gcd_a = gcd_b;
		gcd_b = gcd_next;
	};
	if (gcd_a < 1) then return 1;
	return gcd_a;
}

/// Official ticks are 1/32 beat on that line's own BPM. Lines in one chart do not
/// share a BPM, so the chart beat is tick * chartBPM / (lineBPM * 32). The fraction
/// is kept exact: rounding onto a 32-grid shortens holds when the BPMs do not divide.
function phi_tick_to_time(tick, line_bpm, chart_bpm) {
	var line_rate = real(line_bpm);
	var chart_rate = real(chart_bpm);
	if (!(line_rate > 0)) then line_rate = (chart_rate > 0) ? chart_rate : 120;
	if (!(chart_rate > 0)) then chart_rate = line_rate;
	var ticks = real(tick);
	if (!is_finite(ticks)) then ticks = 0;
	var chart_i = round(chart_rate);
	var line_i = round(line_rate);
	var tick_i = round(ticks);
	var exact = (abs(chart_i - chart_rate) <= 0.000001)
		&& (abs(line_i - line_rate) <= 0.000001)
		&& (abs(tick_i - ticks) <= 0.000001);
	if (!exact || line_i <= 0 || chart_i <= 0) {
		return phi_beats_to_array(ticks * chart_rate / line_rate / 32);
	};
	var num = tick_i * chart_i;
	var den = line_i * 32;
	var g = phi_gcd(num, den);
	num = floor(num / g);
	den = floor(den / g);
	if (den < 1) then den = 1;
	var bar = floor(num / den);
	var rem = num - bar * den;
	return [bar, rem, den];
}

/// Most common line BPM. Ties keep the earlier line, so a one-off line does not
/// become the chart tempo that every other line is measured against.
function phi_chart_bpm(lines) {
	var best_bpm = 0;
	var best_count = 0;
	var seen_bpm = [];
	var seen_count = [];
	if (!is_array(lines)) then return 120;
	for (var i = 0; i < array_length(lines); i++) {
		var judge_line = lines[i];
		if (!is_struct(judge_line)) then continue;
		var bpm_value = judge_line[$ "bpm"];
		var bpm = is_real(bpm_value) ? real(bpm_value) : 0;
		if (!(bpm > 0) || !is_finite(bpm)) then continue;
		var found = -1;
		for (var seen_i = 0; seen_i < array_length(seen_bpm); seen_i++) {
			if (abs(seen_bpm[seen_i] - bpm) <= 0.000001) {
				found = seen_i;
				break;
			};
		};
		if (found < 0) {
			array_push(seen_bpm, bpm);
			array_push(seen_count, 1);
			found = array_length(seen_bpm) - 1;
		} else {
			seen_count[found] = seen_count[found] + 1;
		};
		if (seen_count[found] > best_count) {
			best_count = seen_count[found];
			best_bpm = seen_bpm[found];
		};
	};
	if (!(best_bpm > 0)) then return 120;
	return best_bpm;
}

function phi_beats_to_array(beats) {
	var value = real(beats);
	if (!is_finite(value)) then value = 0;
	var bar = floor(value);
	var num = round((value - bar) * 32);
	if (num >= 32) {
		bar += 1;
		num = 0;
	};
	if (num < 0) then num = 0;
	return [bar, num, 32];
}

function phi_official_event_cmp(a, b) {
	var start_delta = real(a.startTime) - real(b.startTime);
	if (start_delta != 0) then return start_delta;
	return real(a.endTime) - real(b.endTime);
}

function phi_event_start_value(ev, channel) {
	if (channel == 1) then return real(ev[$ "start2"] ?? 0);
	if (is_real(ev[$ "start"])) then return real(ev.start);
	return real(ev[$ "value"] ?? 0);
}

function phi_event_end_value(ev, channel) {
	if (channel == 1) then return real(ev[$ "end2"] ?? ev[$ "start2"] ?? 0);
	if (is_real(ev[$ "end"])) then return real(ev[$ "end"]);
	return real(ev[$ "value"] ?? phi_event_start_value(ev, channel));
}

/// Ease-out bakes sometimes write the end value one tick early. Only an exact
/// plateau is a snap. High-order outs get very close to the end without being flat,
/// and a loose epsilon would cut that tail off and miss the easing.
function phi_trim_end(values, i0, i1) {
	if (i1 - i0 < 2) then return i1;
	var final_v = values[i1];
	var eps = max(0.00000001, abs(final_v) * 0.00000001);
	var i = i1;
	while (i > i0 + 1 && abs(values[i - 1] - final_v) <= eps) i--;
	return i;
}

function phi_fit_event(t0, t1, v0, v1, ease, left = 0, right = 1) {
	return { t0: t0, t1: t1, v0: v0, v1: v1, ease: ease, left: left, right: right };
}

/// Lower rank is the simpler curve. A near-tie keeps the simpler easing,
/// so bake noise does not promote a quart into a quint.
function phi_ease_rank(ease_type) {
	static ease_rank = [0, 0, 1, 2, 4, 5, 3, 6, 7, 8, 15, 16, 9, 17, 18, 19, 13, 14, 10, 11, 20, 21, 12, 22, 26, 27, 23, 24, 25, 28];
	var index = floor(real(ease_type));
	if (index < 1 || index >= array_length(ease_rank)) then return 100;
	return ease_rank[index];
}

/// A slice this many times longer than the average step is its own straight
/// move. The knots on either end do not describe the line between them.
function phi_wide_gap_limit(times, i0, i1) {
	var gaps = i1 - i0;
	if (gaps < 1) then return -1;
	return (times[i1] - times[i0]) / gaps * 2.5;
}

function phi_span_has_wide_gap(times, i0, i1) {
	var wide = phi_wide_gap_limit(times, i0, i1);
	if (!(wide > 0)) then return false;
	for (var gap_i = i0; gap_i < i1; gap_i++) {
		if (times[gap_i + 1] - times[gap_i] > wide) then return true;
	};
	return false;
}

/// Max |sample - ease| / |end - start|. Endpoints match by construction.
/// stride skips intermediate knots during the length search.
/// A long official slice is linear. Knot error never looks inside it, so an
/// overshoot (bounce, back, elastic) can pass both ends and still leave the line.
function phi_norm_ease_error(times, values, i0, i1, ease_type, stride, check_gaps = false) {
	var t0 = times[i0];
	var t1 = times[i1];
	var v0 = values[i0];
	var v1 = values[i1];
	var span = t1 - t0;
	if (span <= 0.000000001) then return 0;
	var amp = v1 - v0;
	var scale = abs(amp);
	var err = 0;
	var step = max(1, stride);
	for (var sample_i = i0; sample_i <= i1; sample_i += step) {
		var p = (times[sample_i] - t0) / span;
		if (p < 0) then p = 0;
		if (p > 1) then p = 1;
		var pred = v0 + amp * rpe_ease_value(ease_type, p);
		var diff = abs(pred - values[sample_i]);
		var nerr = (scale < 0.00000001) ? diff : diff / scale;
		if (nerr > err) then err = nerr;
		if (err > 0.05) then return err;
	};
	if (!check_gaps || err > 0.05) then return err;
	var wide = phi_wide_gap_limit(times, i0, i1);
	if (!(wide > 0)) then return err;
	for (var gap_i = i0; gap_i < i1; gap_i++) {
		var g0 = times[gap_i];
		var g1 = times[gap_i + 1];
		var gap_t = g1 - g0;
		if (gap_t <= wide) then continue;
		var y0 = values[gap_i];
		var y1 = values[gap_i + 1];
		for (var sample_k = 1; sample_k <= 8; sample_k++) {
			var along = sample_k * 0.125;
			var p_gap = (g0 + gap_t * along - t0) / span;
			if (p_gap < 0) then p_gap = 0;
			if (p_gap > 1) then p_gap = 1;
			var gap_pred = v0 + amp * rpe_ease_value(ease_type, p_gap);
			var chord = y0 + (y1 - y0) * along;
			var gap_diff = abs(gap_pred - chord);
			var gap_nerr = (scale < 0.00000001) ? gap_diff : gap_diff / scale;
			if (gap_nerr > err) then err = gap_nerr;
			if (err > 0.05) then return err;
		};
	};
	return err;
}

function phi_best_ease(times, values, i0, i1, stride, check_gaps = false) {
	var best_type = 1;
	var best_err = phi_norm_ease_error(times, values, i0, i1, 1, stride, check_gaps);
	for (var ease_type = 2; ease_type <= 29; ease_type++) {
		var err = phi_norm_ease_error(times, values, i0, i1, ease_type, stride, check_gaps);
		if (err < best_err) {
			best_err = err;
			best_type = ease_type;
		};
	};
	var simple_type = best_type;
	var simple_err = best_err;
	for (var pick = 1; pick <= 29; pick++) {
		if (phi_ease_rank(pick) >= phi_ease_rank(simple_type)) then continue;
		var pick_err = phi_norm_ease_error(times, values, i0, i1, pick, stride, check_gaps);
		if (pick_err <= best_err + 0.004) {
			simple_type = pick;
			simple_err = pick_err;
		};
	};
	return { ease: simple_type, err: simple_err };
}

/// Undefined when no full easing (types 1..29, window 0..1) stays within 1.2%
/// of the value change, including the chord of a long linear slice.
/// A flat span is one linear event. A bump that leaves and comes back is not an easing.
function phi_ease_fits(times, values, i0, i1, verify) {
	if (i1 - i0 < 5) then return undefined;
	var v0 = values[i0];
	var v1 = values[i1];
	var scale = abs(v1 - v0);
	if (scale < 0.00001) {
		var dev = 0;
		var flat_step = max(1, ceil((i1 - i0) / 16));
		for (var flat_i = i0; flat_i <= i1; flat_i += flat_step) {
			var flat_d = abs(values[flat_i] - v0);
			if (flat_d > dev) then dev = flat_d;
		};
		if (dev <= 0.0008) then return { ease: 1, err: 0 };
		return undefined;
	};
	var sample_stride = 1;
	if (!verify) {
		var span_n = i1 - i0;
		if (span_n > 24) then sample_stride = ceil(span_n / 16);
	};
	var check_gaps = phi_span_has_wide_gap(times, i0, i1);
	var choice = phi_best_ease(times, values, i0, i1, sample_stride, check_gaps);
	if (choice.err > 0.012) then return undefined;
	return choice;
}

/// Longest prefix of [i0, i1] that is one full easing.
/// The head of an ease-out is not itself an ease-out, so short lengths are
/// allowed to miss. The search keeps going until a longer length hits, then
/// binary-searches the last good sample. Sparse candidate grids missed that
/// join and the old fitter then wrote every tick as linear.
function phi_longest_ease(times, values, i0, i1) {
	static ladder = [5, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 256, 384, 512, 768, 1024];
	var limit = i1 - i0;
	var best = -1;
	var fail_at = -1;
	var ladder_n = array_length(ladder);
	for (var ladder_i = 0; ladder_i <= ladder_n; ladder_i++) {
		var len = limit;
		if (ladder_i < ladder_n) then len = ladder[ladder_i];
		if (len > limit) then continue;
		if (len < 5) then continue;
		var end_at = i0 + len;
		var hit = phi_ease_fits(times, values, i0, end_at, false);
		if (is_struct(hit)) {
			best = end_at;
			if (end_at >= i1) then fail_at = -1;
		} else if (best >= 0) {
			fail_at = end_at;
			break;
		};
		if (end_at >= i1) then break;
	};
	if (best < 0) then return undefined;
	if (fail_at > best) {
		var lo = best;
		var hi = fail_at;
		while (hi - lo > 1) {
			var mid = floor((lo + hi) * 0.5);
			if (is_struct(phi_ease_fits(times, values, i0, mid, false))) {
				lo = mid;
			} else {
				hi = mid;
			};
		};
		best = lo;
	};
	var shrink = 0;
	while (best >= i0 + 5 && shrink < 24) {
		shrink++;
		var verified = phi_ease_fits(times, values, i0, best, true);
		if (is_struct(verified)) {
			return { end_at: best, ease: verified.ease, err: verified.err };
		};
		best -= 1;
	};
	return undefined;
}

function phi_fit_piece(times, values, i0, i1, depth) {
	var out = [];
	var cursor = i0;
	var guard = 0;
	if (depth < 0) then depth = 0;
	while (cursor < i1 && guard < 100000) {
		guard++;
		var trimmed = phi_trim_end(values, cursor, i1);
		var has_tail = (times[trimmed] < times[i1] - 0.000000001);
		if (trimmed <= cursor) {
			if (has_tail) then array_push(out, phi_fit_event(times[cursor], times[i1], values[cursor], values[i1], 1));
			break;
		};
		if (trimmed - cursor < 5) {
			for (var linear_i = cursor; linear_i < trimmed; linear_i++) {
				array_push(out, phi_fit_event(times[linear_i], times[linear_i + 1], values[linear_i], values[linear_i + 1], 1));
			};
			if (has_tail) then array_push(out, phi_fit_event(times[trimmed], times[i1], values[trimmed], values[i1], 1));
			break;
		};
		var found = phi_longest_ease(times, values, cursor, trimmed);
		if (!is_struct(found)) {
			array_push(out, phi_fit_event(times[cursor], times[cursor + 1], values[cursor], values[cursor + 1], 1));
			cursor += 1;
			continue;
		};
		var end_at = found.end_at;
		array_push(out, phi_fit_event(times[cursor], times[end_at], values[cursor], values[end_at], found.ease));
		cursor = end_at;
	};
	return out;
}

function phi_merge_linear(events) {
	var out = [];
	for (var i = 0; i < array_length(events); i++) {
		var ev = events[i];
		var count = array_length(out);
		if (count > 0) {
			var prev = out[count - 1];
			if (prev.ease == 1 && ev.ease == 1 && abs(ev.t0 - prev.t1) <= 0.001 && abs(ev.v0 - prev.v1) <= 0.001) {
				var dt0 = prev.t1 - prev.t0;
				var dt1 = ev.t1 - ev.t0;
				var same = false;
				if (dt0 <= 0.000001 && dt1 <= 0.000001) {
					same = (abs(ev.v1 - prev.v1) <= 0.001);
				} else if (dt0 > 0.000001 && dt1 > 0.000001) {
					var slope0 = (prev.v1 - prev.v0) / dt0;
					var slope1 = (ev.v1 - ev.v0) / dt1;
					same = (abs(slope0 - slope1) <= max(0.0001, 0.001 * max(abs(slope0), 0.000001)));
				};
				if (same) {
					prev.t1 = ev.t1;
					prev.v1 = ev.v1;
					continue;
				};
			};
		};
		array_push(out, {
			t0: ev.t0, t1: ev.t1, v0: ev.v0, v1: ev.v1, ease: ev.ease,
			left: real(ev[$ "left"] ?? 0), right: real(ev[$ "right"] ?? 1)
		});
	};
	return out;
}

/// channel 0 reads start/end. channel 1 reads start2/end2. Speed events are not passed here.
function phi_fit_channel(events, channel) {
	var fitted = [];
	if (!is_array(events)) then return fitted;
	var evs = [];
	for (var copy_i = 0; copy_i < array_length(events); copy_i++) {
		var src = events[copy_i];
		if (!is_struct(src) || !is_real(src[$ "startTime"]) || !is_real(src[$ "endTime"])) then continue;
		array_push(evs, src);
	};
	if (array_length(evs) <= 0) then return fitted;
	array_sort(evs, phi_official_event_cmp);
	var n = array_length(evs);
	var index = 0;
	while (index < n) {
		var head = evs[index];
		var head_dt = head.endTime - head.startTime;
		if (head_dt <= 0) {
			array_push(fitted, phi_fit_event(head.startTime, head.endTime, phi_event_start_value(head, channel), phi_event_end_value(head, channel), 1));
			index++;
			continue;
		};
		var end_index = index + 1;
		var primary_dt = head_dt;
		while (end_index < n) {
			var seg = evs[end_index];
			var prev = evs[end_index - 1];
			var seg_dt = seg.endTime - seg.startTime;
			if (abs(seg.startTime - prev.endTime) > 0.001) then break;
			if (abs(phi_event_start_value(seg, channel) - phi_event_end_value(prev, channel)) > 0.001) then break;
			if (seg_dt <= 0) then break;
			if (abs(seg_dt - primary_dt) > 0.001 && end_index + 1 < n) {
				var next_seg = evs[end_index + 1];
				var next_dt = next_seg.endTime - next_seg.startTime;
				if (abs(next_seg.startTime - seg.endTime) <= 0.001
					&& abs(phi_event_start_value(next_seg, channel) - phi_event_end_value(seg, channel)) <= 0.001
					&& abs(next_dt - seg_dt) <= 0.001) then break;
			};
			end_index++;
		};
		// A handful of long keyframes is the official chart itself, not a baked easing.
		// Curve fitting starts once a uniform run has enough slices to show the shape.
		if (end_index - index < 5) {
			for (var raw_i = index; raw_i < end_index; raw_i++) {
				var raw_ev = evs[raw_i];
				array_push(fitted, phi_fit_event(raw_ev.startTime, raw_ev.endTime, phi_event_start_value(raw_ev, channel), phi_event_end_value(raw_ev, channel), 1));
			};
		} else {
			var times = [head.startTime];
			var values = [phi_event_start_value(head, channel)];
			for (var build_i = index; build_i < end_index; build_i++) {
				array_push(times, evs[build_i].endTime);
				array_push(values, phi_event_end_value(evs[build_i], channel));
			};
			var piece = phi_fit_piece(times, values, 0, array_length(times) - 1, 0);
			for (var piece_i = 0; piece_i < array_length(piece); piece_i++) array_push(fitted, piece[piece_i]);
		};
		index = end_index;
	};
	return phi_merge_linear(fitted);
}

function phi_scale_events(fitted, kind, line_bpm, chart_bpm) {
	var out = [];
	for (var i = 0; i < array_length(fitted); i++) {
		var ev = fitted[i];
		var v0 = ev.v0;
		var v1 = ev.v1;
		if (kind == "x") {
			v0 = (ev.v0 - 0.5) * 1350;
			v1 = (ev.v1 - 0.5) * 1350;
		} else if (kind == "y") {
			v0 = (ev.v0 - 0.5) * 900;
			v1 = (ev.v1 - 0.5) * 900;
		} else if (kind == "r") {
			v0 = -ev.v0;
			v1 = -ev.v1;
		} else if (kind == "a") {
			v0 = ev.v0 * 255;
			v1 = ev.v1 * 255;
		} else if (kind == "s") {
			v0 = ev.v0 * 4.5;
			v1 = ev.v1 * 4.5;
		};
		array_push(out, {
			startTime: phi_tick_to_time(ev.t0, line_bpm, chart_bpm),
			endTime: phi_tick_to_time(ev.t1, line_bpm, chart_bpm),
			"start": v0,
			"end": v1,
			easingType: ev.ease,
			easingLeft: real(ev[$ "left"] ?? 0),
			easingRight: real(ev[$ "right"] ?? 1)
		});
	};
	return out;
}

function phi_convert_speed(events, line_bpm, chart_bpm) {
	var out = [];
	if (!is_array(events)) then return out;
	var evs = [];
	for (var i = 0; i < array_length(events); i++) {
		var src = events[i];
		if (!is_struct(src) || !is_real(src[$ "startTime"]) || !is_real(src[$ "endTime"])) then continue;
		array_push(evs, src);
	};
	array_sort(evs, phi_official_event_cmp);
	for (var speed_i = 0; speed_i < array_length(evs); speed_i++) {
		var ev = evs[speed_i];
		var _speed = real(ev[$ "value"] ?? ev[$ "start"] ?? 0) * 4.5;
		array_push(out, {
			startTime: phi_tick_to_time(ev.startTime, line_bpm, chart_bpm),
			endTime: phi_tick_to_time(ev.endTime, line_bpm, chart_bpm),
			"start": _speed,
			"end": _speed,
			easingType: 1,
			easingLeft: 0,
			easingRight: 1
		});
	};
	return out;
}

function phi_push_official_notes(notes, list, above, line_bpm, chart_bpm) {
	if (!is_array(list)) then return;
	for (var i = 0; i < array_length(list); i++) {
		var note = list[i];
		if (!is_struct(note)) then continue;
		var off_type = floor(real(note[$ "type"] ?? 1));
		var rpe_type = 1;
		if (off_type == 2) then rpe_type = 4;
		else if (off_type == 3) then rpe_type = 2;
		else if (off_type == 4) then rpe_type = 3;
		var start_tick = real(note[$ "time"] ?? 0);
		var hold_tick = 0;
		if (off_type == 3) then hold_tick = max(0, floor(real(note[$ "holdTime"] ?? 0)));
		var note_speed = real(note[$ "speed"] ?? 1);
		if (!is_finite(note_speed)) then note_speed = 1;
		var note_alpha = 255;
		if (off_type == 3) {
			// Official hold head distance is the raw floor delta. It does not multiply
			// note.speed. This chart copies the judge-line speed (2.3, 999, ...) into
			// that field. RPE applies note.speed to the head as well as the body, so
			// keeping 2.3/999 makes the head fall that many times too fast.
			// Head speed stays 1. Body length is endFloor - startFloor, the integral
			// of this line's speed across the hold, including BPM and speed changes.
			// Speed 0 is kept: those holds fall until the head reaches the judge line,
			// then the renderer hides them. An empty hold is not drawn.
			if (hold_tick <= 0) {
				note_speed = 0;
				note_alpha = 0;
			} else if (abs(note_speed) <= 0.0000001) {
				note_speed = 0;
				note_alpha = 255;
			} else {
				note_speed = 1;
			};
		};
		array_push(notes, {
			type: rpe_type,
			startTime: phi_tick_to_time(start_tick, line_bpm, chart_bpm),
			endTime: phi_tick_to_time(start_tick + hold_tick, line_bpm, chart_bpm),
			positionX: real(note[$ "positionX"] ?? 0) * 75.375,
			above: above,
			isFake: 0,
			speed: note_speed,
			size: 1,
			yOffset: 0,
			visibleTime: 999999,
			alpha: note_alpha
		});
	};
}

function phi_count_eased(events) {
	var eased = 0;
	for (var i = 0; i < array_length(events); i++) {
		if (events[i].ease != 1) then eased++;
	};
	return eased;
}

/// Bake-slice move / rotate / alpha back into RPE easings. Speed stays linear.
/// Each uniform run is the longest full easing (types 1..29) within 1.2% of the
/// value change. A long straight slice is scored on its chord, not only its ends.
/// Ease-out joins are included, because the head of an ease-out is
/// not itself an ease-out. Short keyframe runs stay linear. No easing window:
/// a partial window was matching the wrong family. META.RPEVersion is 160 so
/// playback uses the pre-1.7 speed table. That table is what keeps converted
/// note speeds in line with the official chart. META does not write PGRVersion.
function phi_official_to_rpe(chart) {
	if (!is_struct(chart) || !is_array(chart[$ "judgeLineList"])) then return undefined;
	var lines = chart.judgeLineList;
	var chart_bpm = phi_chart_bpm(lines);
	var judge = [];
	var raw_events = 0;
	var out_events = 0;
	var eased_events = 0;
	var off_move = 0;
	var off_rotate = 0;
	var off_alpha = 0;
	var rpe_move_x = 0;
	var rpe_move_y = 0;
	var rpe_rotate = 0;
	var rpe_alpha = 0;
	for (var line_i = 0; line_i < array_length(lines); line_i++) {
		var _line = lines[line_i];
		if (!is_struct(_line)) then continue;
		var line_bpm = real(_line[$ "bpm"] ?? chart_bpm);
		if (!(line_bpm > 0)) then line_bpm = chart_bpm;
		var move_src = _line[$ "judgeLineMoveEvents"] ?? [];
		var rotate_src = _line[$ "judgeLineRotateEvents"] ?? [];
		var alpha_src = _line[$ "judgeLineDisappearEvents"] ?? [];
		var speed_src = _line[$ "speedEvents"] ?? [];
		if (!is_array(move_src)) then move_src = [];
		if (!is_array(rotate_src)) then rotate_src = [];
		if (!is_array(alpha_src)) then alpha_src = [];
		if (!is_array(speed_src)) then speed_src = [];
		raw_events += array_length(move_src) + array_length(rotate_src) + array_length(alpha_src) + array_length(speed_src);
		off_move += array_length(move_src);
		off_rotate += array_length(rotate_src);
		off_alpha += array_length(alpha_src);
		var move_x = phi_fit_channel(move_src, 0);
		var move_y = phi_fit_channel(move_src, 1);
		var rotate = phi_fit_channel(rotate_src, 0);
		var alpha = phi_fit_channel(alpha_src, 0);
		var _speed = phi_convert_speed(speed_src, line_bpm, chart_bpm);
		eased_events += phi_count_eased(move_x) + phi_count_eased(move_y) + phi_count_eased(rotate) + phi_count_eased(alpha);
		rpe_move_x += array_length(move_x);
		rpe_move_y += array_length(move_y);
		rpe_rotate += array_length(rotate);
		rpe_alpha += array_length(alpha);
		out_events += array_length(move_x) + array_length(move_y) + array_length(rotate) + array_length(alpha) + array_length(_speed);
		var notes = [];
		phi_push_official_notes(notes, _line[$ "notesAbove"], 1, line_bpm, chart_bpm);
		phi_push_official_notes(notes, _line[$ "notesBelow"], 0, line_bpm, chart_bpm);
		// Times are already chart beats, so the line clock stays at factor 1.
		// A per-line factor on top of the converted beats would play the line twice.
		array_push(judge, {
			bpm: line_bpm,
			bpmfactor: 1,
			notes: notes,
			numOfNotes: array_length(notes),
			eventLayers: [{
				speedEvents: _speed,
				moveXEvents: phi_scale_events(move_x, "x", line_bpm, chart_bpm),
				moveYEvents: phi_scale_events(move_y, "y", line_bpm, chart_bpm),
				rotateEvents: phi_scale_events(rotate, "r", line_bpm, chart_bpm),
				alphaEvents: phi_scale_events(alpha, "a", line_bpm, chart_bpm)
			}],
			Texture: "line.png",
			isCover: 1,
			father: -1,
			zOrder: 0
		});
	};
	var chart_name = "";
	var chart_level = "";
	var chart_song = "";
	var chart_bg = "";
	var chart_composer = "";
	var chart_charter = "";
	if (variable_global_exists("game") && is_struct(game) && is_struct(game[$ "folder_chart"])) {
		chart_name = string(game.folder_chart[$ "name"] ?? "");
		chart_level = string(game.folder_chart[$ "level"] ?? "");
		chart_song = string(game.folder_chart[$ "music"] ?? "");
		chart_bg = string(game.folder_chart[$ "bg"] ?? "");
	};
	if (variable_global_exists("chart_session") && is_struct(global.chart_session)) {
		if (!string_length(chart_name)) then chart_name = string(global.chart_session[$ "name"] ?? "");
		if (!string_length(chart_level)) then chart_level = string(global.chart_session[$ "level"] ?? "");
		chart_composer = string(global.chart_session[$ "composer"] ?? "");
		chart_charter = string(global.chart_session[$ "charter"] ?? "");
	};
	return {
		META: {
			RPEVersion: 160,
			offset: real(chart[$ "offset"] ?? 0) * 1000,
			name: chart_name,
			level: chart_level,
			song: chart_song,
			background: chart_bg,
			composer: chart_composer,
			charter: chart_charter,
			id: ""
		},
		BPMList: [{ bpm: chart_bpm, startTime: [0, 0, 1] }],
		judgeLineList: judge,
		stats: {
			rawEvents: raw_events,
			outEvents: out_events,
			easedEvents: eased_events,
			offTotal: off_move + off_rotate + off_alpha,
			offMove: off_move,
			offRotate: off_rotate,
			offAlpha: off_alpha,
			rpeTotal: rpe_move_x + rpe_move_y + rpe_rotate + rpe_alpha,
			rpeEase: eased_events,
			rpeLinear: (rpe_move_x + rpe_move_y + rpe_rotate + rpe_alpha) - eased_events,
			moveX: rpe_move_x,
			moveY: rpe_move_y,
			alpha: rpe_alpha,
			rotate: rpe_rotate
		}
	};
}

/// Beat real -> RPE [bar, numerator, denominator]. The fraction is reduced.
function phi_real_to_beat_array(beat) {
	var value = real(beat);
	if (!is_finite(value)) then value = 0;
	var negative = (value < 0);
	if (negative) then value = -value;
	var bar = floor(value);
	var den = 1000000;
	var num = round((value - bar) * den);
	if (num >= den) {
		bar += 1;
		num = 0;
	};
	if (num < 0) then num = 0;
	var g = phi_gcd(num, den);
	num = floor(num / g);
	den = floor(den / g);
	if (den < 1) then den = 1;
	if (negative) {
		if (num == 0) {
			bar = -bar;
		} else {
			bar = -(bar + 1);
			num = den - num;
		};
	};
	return [bar, num, den];
}

function phi_pec_rpe_event(t0, t1, v0, v1, ease) {
	var ease_id = floor(real(ease));
	if (!is_finite(ease_id)) then ease_id = 1;
	return {
		startTime: phi_real_to_beat_array(t0),
		endTime: phi_real_to_beat_array(t1),
		"start": v0,
		"end": v1,
		easingType: ease_id,
		easingLeft: 0,
		easingRight: 1
	};
}

function phi_pec_cmp_span(a, b) {
	var span_cmp = pec_cmp_real(a.startBeat, b.startBeat);
	if (span_cmp != 0) then return span_cmp;
	span_cmp = pec_cmp_real(a.endBeat, b.endBeat);
	if (span_cmp != 0) then return span_cmp;
	return pec_cmp_real(a.order, b.order);
}

function phi_pec_cmp_beat(a, b) {
	var beat_cmp = pec_cmp_real(a.beat, b.beat);
	if (beat_cmp != 0) then return beat_cmp;
	return pec_cmp_real(a.order, b.order);
}

function phi_pec_line_bucket() {
	return { speed: [], move: [], rotate: [], alpha: [] };
}

/// PEC file position -> RPE editor units. PEC (0, 0) is the bottom-left of a
/// 2048x1400 field. RPE (0, 0) is the view center, Y up, on a 1350x900 field.
function phi_pec_rpe_x(file_x) {
	return 1350 * (real(file_x) / 2048 - 0.5);
}

function phi_pec_rpe_y(file_y) {
	var norm_y = 1 - real(file_y) / 1400;
	return 900 * (0.5 - norm_y);
}

function phi_pec_sec_to_beat(timeline, sec) {
	if (!is_array(timeline) || array_length(timeline) <= 0) then return 0;
	if (sec <= timeline[0].second) then return timeline[0].beat;
	var low = 0;
	var high = array_length(timeline) - 1;
	while (low < high) {
		var middle = (low + high + 1) div 2;
		if (timeline[middle].second <= sec) then low = middle;
		else high = middle - 1;
	};
	var point = timeline[low];
	var bpm = max(0.0001, real(point.bpm));
	return point.beat + (sec - point.second) * bpm / 60;
}

function phi_pec_build_timeline(bpm_raw) {
	var list = [];
	if (is_array(bpm_raw)) {
		for (var bpm_i = 0; bpm_i < array_length(bpm_raw); bpm_i++) {
			var src = bpm_raw[bpm_i];
			if (!is_struct(src)) then continue;
			var bpm = real(src[$ "bpm"] ?? 60);
			if (!(bpm > 0) || !is_finite(bpm)) then bpm = 60;
			array_push(list, { beat: real(src[$ "beat"] ?? 0), bpm: bpm, order: real(src[$ "order"] ?? bpm_i), second: 0 });
		};
	};
	if (array_length(list) <= 0) then array_push(list, { beat: 0, bpm: 60, order: 0, second: 0 });
	array_sort(list, phi_pec_cmp_beat);
	var collapsed = [];
	for (var collapse_i = 0; collapse_i < array_length(list); collapse_i++) {
		var item = list[collapse_i];
		var count = array_length(collapsed);
		if (count > 0 && abs(collapsed[count - 1].beat - item.beat) <= 0.0000001) {
			collapsed[count - 1] = item;
		} else {
			array_push(collapsed, item);
		};
	};
	collapsed[0].second = 0;
	for (var second_i = 1; second_i < array_length(collapsed); second_i++) {
		var previous = collapsed[second_i - 1];
		collapsed[second_i].second = previous.second + (collapsed[second_i].beat - previous.beat) * 60 / max(0.0001, previous.bpm);
	};
	return collapsed;
}

/// cv holds until the next cv. A PhiEditor warp (|speed/7| >= 1000) does not
/// move notes during the segment; the floor jumps when the next cv starts.
function phi_pec_speed_to_rpe(raw, timeline) {
	var out = [];
	if (!is_array(raw) || array_length(raw) <= 0) then return out;
	var evs = [];
	for (var raw_i = 0; raw_i < array_length(raw); raw_i++) {
		var src = raw[raw_i];
		if (!is_struct(src)) then continue;
		array_push(evs, src);
	};
	if (array_length(evs) <= 0) then return out;
	array_sort(evs, phi_pec_cmp_beat);
	if (abs(evs[0].beat) > 0.00001) {
		var shifted = [{ beat: 0, value: 0, order: -1 }];
		for (var shift_i = 0; shift_i < array_length(evs); shift_i++) array_push(shifted, evs[shift_i]);
		evs = shifted;
	};
	var kept = [];
	for (var keep_i = 0; keep_i < array_length(evs); keep_i++) {
		var keep_count = array_length(kept);
		if (keep_count > 0 && abs(kept[keep_count - 1].beat - evs[keep_i].beat) <= 0.0000001) {
			kept[keep_count - 1] = evs[keep_i];
		} else {
			array_push(kept, evs[keep_i]);
		};
	};
	for (var speed_i = 0; speed_i < array_length(kept); speed_i++) {
		var ev = kept[speed_i];
		var pec_speed = real(ev.value) / 7;
		if (!is_finite(pec_speed)) then pec_speed = 0;
		var beat = real(ev.beat);
		var last = (speed_i >= array_length(kept) - 1);
		if (last) {
			var tail = (abs(pec_speed) >= 1000) ? 0 : pec_speed * 4.5;
			array_push(out, phi_pec_rpe_event(beat, beat + 1, tail, tail, 1));
			continue;
		};
		var next_beat = real(kept[speed_i + 1].beat);
		if (next_beat <= beat) then continue;
		if (abs(pec_speed) < 1000) {
			var held = pec_speed * 4.5;
			array_push(out, phi_pec_rpe_event(beat, next_beat, held, held, 1));
			continue;
		};
		var t0 = pec_beat_to_sec(timeline, beat);
		var t1 = pec_beat_to_sec(timeline, next_beat);
		var dur = t1 - t0;
		var spike = 0.001;
		if (!(dur > spike * 2)) {
			var short_speed = pec_speed * 4.5;
			array_push(out, phi_pec_rpe_event(beat, next_beat, short_speed, short_speed, 1));
			continue;
		};
		var hold_beat = phi_pec_sec_to_beat(timeline, t0 + dur - spike);
		if (hold_beat <= beat || hold_beat >= next_beat) {
			var fallback = pec_speed * 4.5;
			array_push(out, phi_pec_rpe_event(beat, next_beat, fallback, fallback, 1));
			continue;
		};
		array_push(out, phi_pec_rpe_event(beat, hold_beat, 0, 0, 1));
		var jump = pec_speed * dur / spike * 4.5;
		array_push(out, phi_pec_rpe_event(hold_beat, next_beat, jump, jump, 1));
	};
	return out;
}

function phi_pec_move_to_rpe(raw) {
	var move_x = [];
	var move_y = [];
	if (!is_array(raw) || array_length(raw) <= 0) {
		array_push(move_x, phi_pec_rpe_event(0, 1, phi_pec_rpe_x(0), phi_pec_rpe_x(0), 1));
		array_push(move_y, phi_pec_rpe_event(0, 1, phi_pec_rpe_y(1400), phi_pec_rpe_y(1400), 1));
		return { x: move_x, y: move_y, count: 0 };
	};
	array_sort(raw, phi_pec_cmp_span);
	var prev_x = 0;
	var prev_y = 1400;
	for (var move_i = 0; move_i < array_length(raw); move_i++) {
		var ev = raw[move_i];
		var x1 = real(ev.x);
		var y1 = real(ev.y);
		var ease = real(ev[$ "ease"] ?? 1);
		array_push(move_x, phi_pec_rpe_event(ev.startBeat, ev.endBeat, phi_pec_rpe_x(prev_x), phi_pec_rpe_x(x1), ease));
		array_push(move_y, phi_pec_rpe_event(ev.startBeat, ev.endBeat, phi_pec_rpe_y(prev_y), phi_pec_rpe_y(y1), ease));
		prev_x = x1;
		prev_y = y1;
	};
	return { x: move_x, y: move_y, count: array_length(raw) };
}

function phi_pec_scalar_to_rpe(raw, kind) {
	var out = [];
	if (!is_array(raw)) then raw = [];
	if (array_length(raw) <= 0) {
		if (kind == "alpha") then array_push(out, phi_pec_rpe_event(0, 1, 255, 255, 1));
		return { events: out, count: 0 };
	};
	array_sort(raw, phi_pec_cmp_span);
	var previous = 0;
	for (var scalar_i = 0; scalar_i < array_length(raw); scalar_i++) {
		var ev = raw[scalar_i];
		var target = real(ev.target);
		if (!is_finite(target)) then target = previous;
		var ease = real(ev[$ "ease"] ?? 1);
		array_push(out, phi_pec_rpe_event(ev.startBeat, ev.endBeat, previous, target, ease));
		previous = target;
	};
	if (kind == "alpha" && array_length(out) > 0 && real(raw[0].startBeat) > 0.0000001) {
		var held = [phi_pec_rpe_event(0, raw[0].startBeat, 255, 255, 1)];
		for (var hold_i = 0; hold_i < array_length(out); hold_i++) array_push(held, out[hold_i]);
		out = held;
	};
	return { events: out, count: array_length(raw) };
}

function phi_pec_note_to_rpe(note) {
	var rpe_type = floor(real(note[$ "type"] ?? 1));
	if (rpe_type < 1 || rpe_type > 4) then rpe_type = 1;
	var start_beat = real(note[$ "startBeat"] ?? 0);
	var end_beat = real(note[$ "endBeat"] ?? start_beat);
	if (!is_finite(start_beat)) then start_beat = 0;
	if (!is_finite(end_beat) || end_beat < start_beat) then end_beat = start_beat;
	var note_speed = real(note[$ "speed"] ?? 1);
	if (!is_finite(note_speed)) then note_speed = 1;
	var note_size = real(note[$ "size"] ?? 1);
	if (!is_finite(note_size)) then note_size = 1;
	return {
		type: rpe_type,
		startTime: phi_real_to_beat_array(start_beat),
		endTime: phi_real_to_beat_array(end_beat),
		positionX: real(note[$ "x"] ?? 0) * 75.375 / 115.2,
		above: (real(note[$ "above"] ?? 1) == 1) ? 1 : 0,
		isFake: (real(note[$ "fake"] ?? 0) != 0) ? 1 : 0,
		speed: note_speed,
		size: note_size,
		yOffset: 0,
		visibleTime: 999999,
		alpha: 255
	};
}

/// Read a PEC chart the same way pec_reader_load does. Values stay in file units.
function phi_pec_parse(pec_text) {
	if (!is_string(pec_text) || !string_length(pec_text)) then return undefined;
	var pec_lines = string_split(string_replace_all(pec_text, "\r", ""), "\n");
	if (array_length(pec_lines) <= 0) then return undefined;
	var pec_line_index = 0;
	var offset_ms = number(pec_lines[pec_line_index], 0);
	if (!is_finite(offset_ms)) then offset_ms = 0;
	pec_line_index++;
	var pending_line = "";
	var has_pending_line = false;
	var saw_command = false;
	var order_n = 0;
	var line_buckets = [];
	var note_list = [];
	var bpm_list = [];
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
			saw_command = true;
			array_push(bpm_list, { beat: number(tokens[1], 0), bpm: max(0.0001, number(tokens[2], 60)), order: order_n });
			order_n++;
			continue;
		};
		if (command == "#" || command == "&") then continue;
		var is_note = (command == "n1" || command == "n2" || command == "n3" || command == "n4");
		var is_line = (command == "cv" || command == "cp" || command == "cm" || command == "cd" || command == "cr" || command == "ca" || command == "cf");
		if (!is_note && !is_line) then continue;
		if (array_length(tokens) < 2) then continue;
		saw_command = true;
		var line_id = max(0, floor(number(tokens[1], 0)));
		while (array_length(line_buckets) <= line_id) array_push(line_buckets, phi_pec_line_bucket());
		var bucket = line_buckets[line_id];
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
				if (!has_pending_line && pec_line_index >= array_length(pec_lines)) then break;
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
				if (modifier[0] == "#") then _speed = number(modifier[1], 1);
				else if (modifier[0] == "&") then width_scale = number(modifier[1], 1);
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
			array_push(note_list, {
				type: (command == "n1" ? 1 : (command == "n2" ? 2 : (command == "n3" ? 3 : 4))),
				lineId: line_id,
				startBeat: start_beat,
				endBeat: end_beat,
				x: number(tokens[x_index], 0),
				above: (number(tokens[side_index], 1) == 1) ? 1 : 0,
				fake: (number(tokens[fake_index], 0) != 0) ? 1 : 0,
				speed: _speed,
				size: width_scale,
				order: order_n
			});
			order_n++;
			continue;
		};
		switch (command) {
			case "cv":
				if (array_length(tokens) >= 4) then array_push(bucket.speed, { beat: number(tokens[2], 0), value: number(tokens[3], 0), order: order_n });
			break;
			case "cp":
				if (array_length(tokens) >= 5) then array_push(bucket.move, { startBeat: number(tokens[2], 0), endBeat: number(tokens[2], 0), x: number(tokens[3], 0), y: number(tokens[4], 0), ease: 1, order: order_n });
			break;
			case "cm":
				if (array_length(tokens) >= 7) then array_push(bucket.move, { startBeat: number(tokens[2], 0), endBeat: number(tokens[3], 0), x: number(tokens[4], 0), y: number(tokens[5], 0), ease: number(tokens[6], 1), order: order_n });
			break;
			case "cd":
				if (array_length(tokens) >= 4) then array_push(bucket.rotate, { startBeat: number(tokens[2], 0), endBeat: number(tokens[2], 0), target: number(tokens[3], 0), ease: 1, order: order_n });
			break;
			case "cr":
				if (array_length(tokens) >= 6) then array_push(bucket.rotate, { startBeat: number(tokens[2], 0), endBeat: number(tokens[3], 0), target: number(tokens[4], 0), ease: number(tokens[5], 1), order: order_n });
			break;
			case "ca":
				if (array_length(tokens) >= 4) then array_push(bucket.alpha, { startBeat: number(tokens[2], 0), endBeat: number(tokens[2], 0), target: number(tokens[3], 0), ease: 1, order: order_n });
			break;
			case "cf":
				if (array_length(tokens) >= 5) {
					// pec_reader_load forces this fade to linear. Keep the file easing.
					var cf_ease = (array_length(tokens) >= 6) ? number(tokens[5], 1) : 1;
					array_push(bucket.alpha, { startBeat: number(tokens[2], 0), endBeat: number(tokens[3], 0), target: number(tokens[4], 0), ease: cf_ease, order: order_n });
				};
			break;
		};
		order_n++;
	};
	if (!saw_command) then return undefined;
	return {
		offsetMs: offset_ms,
		bpmList: bpm_list,
		lines: line_buckets,
		notes: note_list
	};
}

/// PEC text -> RPE chart. META.RPEVersion is 160 so playback uses the pre-1.7
/// speed table, the same divisor (4.5) this conversion writes. Note X is
/// fileX * 75.375 / 115.2. Speed is fileSpeed * 4.5 / 7. The PEC player's
/// extra -0.175s lead is not written into META.offset.
function phi_pec_to_rpe(pec_text, meta = undefined) {
	var parsed = phi_pec_parse(pec_text);
	if (!is_struct(parsed)) then return undefined;
	var timeline = phi_pec_build_timeline(parsed.bpmList);
	var chart_bpm = real(timeline[0].bpm);
	if (!(chart_bpm > 0)) then chart_bpm = 60;
	var bpm_out = [];
	for (var bpm_i = 0; bpm_i < array_length(timeline); bpm_i++) {
		array_push(bpm_out, {
			bpm: timeline[bpm_i].bpm,
			startTime: phi_real_to_beat_array(timeline[bpm_i].beat)
		});
	};
	var notes_by_line = [];
	var line_count = array_length(parsed.lines);
	for (var note_i = 0; note_i < array_length(parsed.notes); note_i++) {
		var note = parsed.notes[note_i];
		var note_line = floor(real(note[$ "lineId"] ?? 0));
		if (note_line < 0) then continue;
		while (line_count <= note_line) {
			array_push(parsed.lines, phi_pec_line_bucket());
			line_count++;
		};
	};
	for (var empty_i = 0; empty_i < array_length(parsed.lines); empty_i++) array_push(notes_by_line, []);
	array_sort(parsed.notes, function(a, b) {
		var note_cmp = pec_cmp_real(a.startBeat, b.startBeat);
		if (note_cmp != 0) then return note_cmp;
		return pec_cmp_real(a.order, b.order);
	});
	for (var place_i = 0; place_i < array_length(parsed.notes); place_i++) {
		var placed = parsed.notes[place_i];
		var placed_line = floor(real(placed[$ "lineId"] ?? 0));
		if (placed_line < 0 || placed_line >= array_length(notes_by_line)) then continue;
		array_push(notes_by_line[placed_line], phi_pec_note_to_rpe(placed));
	};
	var judge = [];
	var raw_move = 0;
	var raw_rotate = 0;
	var raw_alpha = 0;
	var raw_speed = 0;
	var out_move_x = 0;
	var out_move_y = 0;
	var out_rotate = 0;
	var out_alpha = 0;
	var out_speed = 0;
	for (var line_i = 0; line_i < array_length(parsed.lines); line_i++) {
		var bucket = parsed.lines[line_i];
		if (!is_struct(bucket)) then bucket = phi_pec_line_bucket();
		var move = phi_pec_move_to_rpe(bucket.move);
		var rotate = phi_pec_scalar_to_rpe(bucket.rotate, "rotate");
		var alpha = phi_pec_scalar_to_rpe(bucket.alpha, "alpha");
		var _speed = phi_pec_speed_to_rpe(bucket.speed, timeline);
		raw_move += move.count;
		raw_rotate += rotate.count;
		raw_alpha += alpha.count;
		raw_speed += array_length(bucket.speed);
		out_move_x += array_length(move.x);
		out_move_y += array_length(move.y);
		out_rotate += array_length(rotate.events);
		out_alpha += array_length(alpha.events);
		out_speed += array_length(_speed);
		var line_notes = notes_by_line[line_i];
		array_push(judge, {
			bpm: chart_bpm,
			bpmfactor: 1,
			notes: line_notes,
			numOfNotes: array_length(line_notes),
			eventLayers: [{
				speedEvents: _speed,
				moveXEvents: move.x,
				moveYEvents: move.y,
				rotateEvents: rotate.events,
				alphaEvents: alpha.events
			}],
			Texture: "line.png",
			isCover: 1,
			father: -1,
			zOrder: 0
		});
	};
	var chart_name = "";
	var chart_level = "";
	var chart_song = "";
	var chart_bg = "";
	var chart_composer = "";
	var chart_charter = "";
	var chart_aspect = 0;
	if (is_struct(meta)) {
		chart_name = string(meta[$ "name"] ?? "");
		chart_level = string(meta[$ "level"] ?? "");
		chart_song = string(meta[$ "song"] ?? "");
		chart_bg = string(meta[$ "background"] ?? "");
		chart_composer = string(meta[$ "composer"] ?? "");
		chart_charter = string(meta[$ "charter"] ?? "");
		chart_aspect = real(meta[$ "aspect"] ?? 0);
	} else {
		if (variable_global_exists("game") && is_struct(game) && is_struct(game[$ "folder_chart"])) {
			chart_name = string(game.folder_chart[$ "name"] ?? "");
			chart_level = string(game.folder_chart[$ "level"] ?? "");
			chart_song = string(game.folder_chart[$ "music"] ?? "");
			chart_bg = string(game.folder_chart[$ "bg"] ?? "");
		};
		if (variable_global_exists("chart_session") && is_struct(global.chart_session)) {
			if (!string_length(chart_name)) then chart_name = string(global.chart_session[$ "name"] ?? "");
			if (!string_length(chart_level)) then chart_level = string(global.chart_session[$ "level"] ?? "");
			chart_composer = string(global.chart_session[$ "composer"] ?? "");
			chart_charter = string(global.chart_session[$ "charter"] ?? "");
			chart_aspect = real(global.chart_session[$ "aspect_ratio"] ?? 0);
		};
	};
	var chart_meta = {
		RPEVersion: 160,
		offset: real(parsed.offsetMs),
		name: chart_name,
		level: chart_level,
		song: chart_song,
		background: chart_bg,
		composer: chart_composer,
		charter: chart_charter,
		id: ""
	};
	if (is_finite(chart_aspect) && chart_aspect > 0) then chart_meta.aspectRatio = chart_aspect;
	var note_count = array_length(parsed.notes);
	return {
		META: chart_meta,
		BPMList: bpm_out,
		judgeLineList: judge,
		stats: {
			source: "PEC",
			lines: array_length(judge),
			notes: note_count,
			rawEvents: raw_move + raw_rotate + raw_alpha + raw_speed,
			outEvents: out_move_x + out_move_y + out_rotate + out_alpha + out_speed,
			offTotal: raw_move + raw_rotate + raw_alpha,
			offMove: raw_move,
			offRotate: raw_rotate,
			offAlpha: raw_alpha,
			offSpeed: raw_speed,
			rpeTotal: out_move_x + out_move_y + out_rotate + out_alpha,
			rpeEase: 0,
			rpeLinear: out_move_x + out_move_y + out_rotate + out_alpha,
			moveX: out_move_x,
			moveY: out_move_y,
			alpha: out_alpha,
			rotate: out_rotate
		}
	};
}

function phi_tools_digits5() {
	var n = irandom(99999);
	var text = string(n);
	while (string_length(text) < 5) text = "0" + text;
	return text;
}

function phi_tools_stem_ext(file_name) {
	var dot = string_last_pos(".", file_name);
	if (dot <= 1) then return { stem: file_name, ext: "" };
	return {
		stem: string_copy(file_name, 1, dot - 1),
		ext: string_copy(file_name, dot, string_length(file_name) - dot + 1)
	};
}

function phi_tools_name_taken(taken, file_name) {
	return variable_struct_exists(taken, string_lower(file_name));
}

/// "{stem}{mark}.{ext}", or "{stem}{mark}-{00000}.{ext}" when that name is already used.
function phi_tools_unique_marked_name(stem, mark, ext, taken) {
	var plain = stem + mark + ext;
	if (!phi_tools_name_taken(taken, plain)) then return plain;
	for (var try_i = 0; try_i < 30; try_i++) {
		var marked = stem + mark + "-" + phi_tools_digits5() + ext;
		if (!phi_tools_name_taken(taken, marked)) then return marked;
	};
	return stem + mark + "-" + phi_tools_digits5() + ext;
}

function phi_tools_collect_names(discovered) {
	var taken = {};
	var keys = ["chart", "music", "image", "text", "shader", "other"];
	for (var key_i = 0; key_i < array_length(keys); key_i++) {
		var list = discovered[$ keys[key_i]];
		if (!is_array(list)) then continue;
		for (var file_i = 0; file_i < array_length(list); file_i++) {
			taken[$ string_lower(chart_path_file_name(list[file_i]))] = 1;
		};
	};
	return taken;
}

function phi_tools_chart_key(key) {
	var normalized = string_lower(string_replace_all(string(key), " ", ""));
	normalized = string_replace_all(normalized, "\t", "");
	return normalized == "chart" || normalized == "track" || normalized == "chartfile" || normalized == "谱面";
}

/// Replace every Chart field. Append one when the file has none.
function phi_tools_set_chart_field(path, chart_name) {
	var text = chart_read_text_file(path, -1);
	if (!is_string(text)) then text = "";
	var newline = (string_pos("\r\n", text) > 0) ? "\r\n" : "\n";
	var lines = string_split(string_replace_all(text, "\r", ""), "\n");
	var found = false;
	var out = "";
	for (var line_i = 0; line_i < array_length(lines); line_i++) {
		var line_text = lines[line_i];
		var sep = string_pos(":", line_text);
		var eq = string_pos("=", line_text);
		if (eq > 0 && (sep <= 0 || eq < sep)) then sep = eq;
		var rewritten = line_text;
		if (sep > 1) {
			var first = string_char_at(line_text, 1);
			var key = string_copy(line_text, 1, sep - 1);
			if (first != "#" && first != "-" && first != " " && first != "\t" && phi_tools_chart_key(key)) {
				rewritten = key + string_char_at(line_text, sep) + " " + chart_name;
				found = true;
			};
		};
		if (line_i > 0) then out += newline;
		out += rewritten;
	};
	if (!found) {
		if (string_length(out) > 0) then out += newline;
		out += "Chart: " + chart_name;
	};
	chart_buffer_save_text(path, out);
	return true;
}

function phi_tools_write_default_info(path, chart_name) {
	var body = "Name: \nLevel: \nComposer: \nCharter: \nIllustrator: \nSong: \nPicture: \nChart: " + chart_name + "\nOffset: 0\n";
	chart_buffer_save_text(path, body);
	return true;
}

function phi_tools_log(message) {
	print("[PhiTool] " + string(message), true);
}

function phi_tools_event_report(stats) {
	if (!is_struct(stats)) then return;
	if (string(stats[$ "source"] ?? "") == "PEC") {
		var pec_line = "PEC: lines->" + string(stats[$ "lines"] ?? 0)
			+ " notes->" + string(stats[$ "notes"] ?? 0)
			+ " move->" + string(stats[$ "offMove"] ?? 0)
			+ " rotate->" + string(stats[$ "offRotate"] ?? 0)
			+ " alpha->" + string(stats[$ "offAlpha"] ?? 0)
			+ " speed->" + string(stats[$ "offSpeed"] ?? 0);
		var pec_rpe_line = "RPE: Total->" + string(stats[$ "rpeTotal"] ?? 0)
			+ " MoveXEvents->" + string(stats[$ "moveX"] ?? 0)
			+ " MoveYEvents->" + string(stats[$ "moveY"] ?? 0)
			+ " AlphaEvents->" + string(stats[$ "alpha"] ?? 0)
			+ " RotateEvents->" + string(stats[$ "rotate"] ?? 0);
		print("[PhiTools] " + pec_line + "\n" + pec_rpe_line, true);
		return;
	};
	var official_line = "Phigros Official: Total->" + string(stats[$ "offTotal"] ?? 0)
		+ " judgeLineMoveEvents->" + string(stats[$ "offMove"] ?? 0)
		+ " judgeLineRotateEvents->" + string(stats[$ "offRotate"] ?? 0)
		+ " judgeLineDisappearEvents->" + string(stats[$ "offAlpha"] ?? 0);
	var rpe_line = "RPE: Total->" + string(stats[$ "rpeTotal"] ?? 0)
		+ " ease-> " + string(stats[$ "rpeEase"] ?? 0)
		+ " no_ease->" + string(stats[$ "rpeLinear"] ?? 0)
		+ " MoveXEvents->" + string(stats[$ "moveX"] ?? 0)
		+ " MoveYEvents->" + string(stats[$ "moveY"] ?? 0)
		+ " AlphaEvents->" + string(stats[$ "alpha"] ?? 0)
		+ " RotateEvents->" + string(stats[$ "rotate"] ?? 0);
	print("[PhiTools] " + official_line + "\n" + rpe_line, true);
}

function phi_tools_trim_dir(path) {
	var text = chart_path_norm(path);
	while (string_length(text) > 3 && string_char_at(text, string_length(text)) == "/") {
		text = string_copy(text, 1, string_length(text) - 1);
	};
	return text;
}

function phi_tools_crc32(buf) {
	static crc_table = undefined;
	if (!is_array(crc_table)) {
		crc_table = array_create(256, 0);
		for (var i = 0; i < 256; i++) {
			var c = i;
			for (var k = 0; k < 8; k++) {
				if ((c & 1) != 0) then c = 3988292384 ^ (c >> 1);
				else c = c >> 1;
			};
			crc_table[i] = c & 4294967295;
		};
	};
	var crc = 4294967295;
	var size = buffer_get_size(buf);
	buffer_seek(buf, buffer_seek_start, 0);
	for (var pos = 0; pos < size; pos++) {
		var byte = buffer_read(buf, buffer_u8);
		crc = crc_table[(crc ^ byte) & 255] ^ (crc >> 8);
		crc = crc & 4294967295;
	};
	return (crc ^ 4294967295) & 4294967295;
}

function phi_tools_zip_magic_ok(path) {
	if (!file_exists(path)) then return false;
	var bin = file_bin_open(path, 0);
	if (bin < 0) then return false;
	var b0 = file_bin_read_byte(bin);
	var b1 = file_bin_read_byte(bin);
	file_bin_close(bin);
	return b0 == 80 && b1 == 75;
}

function phi_tools_list_pack_files(root) {
	var discovered = File_Discoverer(root);
	var files = [];
	var keys = ["chart", "music", "image", "text", "shader", "other"];
	for (var key_i = 0; key_i < array_length(keys); key_i++) {
		var list = discovered[$ keys[key_i]];
		if (!is_array(list)) then continue;
		for (var file_i = 0; file_i < array_length(list); file_i++) array_push(files, list[file_i]);
	};
	return files;
}

/// Write an uncompressed zip. Windows tar -a treats .pez as an unknown suffix.
function phi_tools_pack_stored_zip(root, archive_path) {
	var prefix = chart_path_norm(root);
	if (string_length(prefix) > 0 && string_char_at(prefix, string_length(prefix)) != "/") then prefix += "/";
	var prefix_len = string_length(prefix);
	var prefix_lower = string_lower(prefix);
	var files = phi_tools_list_pack_files(root);
	phi_tools_log("stored zip files=" + string(array_length(files)) + " root=" + prefix);
	var zip_buf = buffer_create(1024, buffer_grow, 1);
	var entries = [];
	for (var i = 0; i < array_length(files); i++) {
		var full = chart_path_norm(files[i]);
		if (string_copy(string_lower(full), 1, prefix_len) != prefix_lower) {
			phi_tools_log("stored zip skip outside root " + full);
			continue;
		};
		var rel = string_replace_all(string_copy(full, prefix_len + 1, string_length(full) - prefix_len), "\\", "/");
		if (!string_length(rel)) then continue;
		var data = buffer_load(files[i]);
		if (data < 0 || !buffer_exists(data)) {
			phi_tools_log("stored zip read failed " + files[i]);
			buffer_delete(zip_buf);
			return false;
		};
		var size = buffer_get_size(data);
		var crc = phi_tools_crc32(data);
		var name_bytes = string_byte_length(rel);
		var offset = buffer_tell(zip_buf);
		buffer_write(zip_buf, buffer_u32, 67324752);
		buffer_write(zip_buf, buffer_u16, 20);
		buffer_write(zip_buf, buffer_u16, 2048);
		buffer_write(zip_buf, buffer_u16, 0);
		buffer_write(zip_buf, buffer_u16, 0);
		buffer_write(zip_buf, buffer_u16, 0);
		buffer_write(zip_buf, buffer_u32, crc);
		buffer_write(zip_buf, buffer_u32, size);
		buffer_write(zip_buf, buffer_u32, size);
		buffer_write(zip_buf, buffer_u16, name_bytes);
		buffer_write(zip_buf, buffer_u16, 0);
		buffer_write(zip_buf, buffer_text, rel);
		var data_at = buffer_tell(zip_buf);
		buffer_copy(data, 0, size, zip_buf, data_at);
		buffer_seek(zip_buf, buffer_seek_start, data_at + size);
		buffer_delete(data);
		array_push(entries, { name: rel, name_bytes: name_bytes, crc: crc, size: size, offset: offset });
		phi_tools_log("stored zip add " + rel + " bytes=" + string(size));
	};
	if (array_length(entries) <= 0) {
		phi_tools_log("stored zip has no files");
		buffer_delete(zip_buf);
		return false;
	};
	var central_offset = buffer_tell(zip_buf);
	for (var entry_i = 0; entry_i < array_length(entries); entry_i++) {
		var entry = entries[entry_i];
		buffer_write(zip_buf, buffer_u32, 33639248);
		buffer_write(zip_buf, buffer_u16, 20);
		buffer_write(zip_buf, buffer_u16, 20);
		buffer_write(zip_buf, buffer_u16, 2048);
		buffer_write(zip_buf, buffer_u16, 0);
		buffer_write(zip_buf, buffer_u16, 0);
		buffer_write(zip_buf, buffer_u16, 0);
		buffer_write(zip_buf, buffer_u32, entry.crc);
		buffer_write(zip_buf, buffer_u32, entry.size);
		buffer_write(zip_buf, buffer_u32, entry.size);
		buffer_write(zip_buf, buffer_u16, entry.name_bytes);
		buffer_write(zip_buf, buffer_u16, 0);
		buffer_write(zip_buf, buffer_u16, 0);
		buffer_write(zip_buf, buffer_u16, 0);
		buffer_write(zip_buf, buffer_u16, 0);
		buffer_write(zip_buf, buffer_u32, 0);
		buffer_write(zip_buf, buffer_u32, entry.offset);
		buffer_write(zip_buf, buffer_text, entry.name);
	};
	var central_size = buffer_tell(zip_buf) - central_offset;
	var count = array_length(entries);
	buffer_write(zip_buf, buffer_u32, 101010256);
	buffer_write(zip_buf, buffer_u16, 0);
	buffer_write(zip_buf, buffer_u16, 0);
	buffer_write(zip_buf, buffer_u16, count);
	buffer_write(zip_buf, buffer_u16, count);
	buffer_write(zip_buf, buffer_u32, central_size);
	buffer_write(zip_buf, buffer_u32, central_offset);
	buffer_write(zip_buf, buffer_u16, 0);
	buffer_resize(zip_buf, buffer_tell(zip_buf));
	buffer_save(zip_buf, archive_path);
	buffer_delete(zip_buf);
	var magic_ok = phi_tools_zip_magic_ok(archive_path);
	phi_tools_log("stored zip saved exists=" + string(file_exists(archive_path)) + " bytes=" + string(chart_archive_size_bytes(archive_path)) + " pk=" + string(magic_ok));
	return magic_ok;
}

function phi_tools_fail(message, work, packed) {
	phi_tools_log("fail: " + string(message));
	if (is_string(work) && string_length(work)) then chart_session_remove_dir(work);
	if (is_string(packed) && string_length(packed) && file_exists(packed)) then file_delete(packed);
	return { ok: false, archive: "", suggest: "", directory: "", error: message };
}

function phi_tools_find_official(discovered) {
	if (!is_struct(discovered) || !is_array(discovered[$ "chart"])) {
		phi_tools_log("find official: discovered chart list is missing");
		return "";
	};
	var charts = discovered.chart;
	phi_tools_log("find official: chart candidates=" + string(array_length(charts)));
	for (var i = 0; i < array_length(charts); i++) {
		var format_id = chart_detect_format(charts[i]);
		phi_tools_log("find official [" + string(i) + "] format=" + string(format_id) + " path=" + string(charts[i]));
		if (format_id == CHART_FORMAT.OFFICIAL) then return charts[i];
	};
	return "";
}

function phi_tools_find_pec(discovered) {
	if (!is_struct(discovered) || !is_array(discovered[$ "chart"])) {
		phi_tools_log("find pec: discovered chart list is missing");
		return "";
	};
	var charts = discovered.chart;
	phi_tools_log("find pec: chart candidates=" + string(array_length(charts)));
	for (var i = 0; i < array_length(charts); i++) {
		var format_id = chart_detect_format(charts[i]);
		phi_tools_log("find pec [" + string(i) + "] format=" + string(format_id) + " path=" + string(charts[i]));
		if (format_id == CHART_FORMAT.PEC) then return charts[i];
	};
	return "";
}

function phi_tools_meta_from_root(root) {
	var info_pack = chart_load_root_info(root);
	var info = (is_struct(info_pack) ? info_pack[$ "info"] : undefined);
	if (!is_struct(info)) then return undefined;
	return {
		name: string(info[$ "name"] ?? ""),
		level: string(info[$ "level"] ?? ""),
		song: string(info[$ "music"] ?? ""),
		background: string(info[$ "image"] ?? ""),
		composer: string(info[$ "composer"] ?? ""),
		charter: string(info[$ "charter"] ?? ""),
		aspect: real(info[$ "aspect_ratio"] ?? 0)
	};
}

/// Save-dialog half of a Tools export. prepare already built the temp archive.
function phi_tools_finish_save(prepared, tool_path, want_pec) {
	if (!is_struct(prepared) || !prepared.ok) {
		var fail_text = is_struct(prepared) ? string(prepared[$ "error"] ?? "") : "";
		phi_tools_log("prepare error=" + fail_text);
		if (string_length(fail_text)) then return fail_text;
		var fail_key = "menu.toolsFail";
		if (want_pec) then fail_key = "menu.toolsFailPec";
		return lang(fail_key);
	};
	var save_filter = (string_lower(chart_path_ext(tool_path)) == ".pez") ? lang("menu.toolsSavePez") : lang("menu.toolsSaveZip");
	phi_tools_log("save dialog filter=" + save_filter + " suggest=" + string(prepared.suggest) + " dir=" + string(prepared.directory) + " temp=" + string(prepared.archive) + " temp_exists=" + string(file_exists(prepared.archive)) + " temp_bytes=" + string(chart_archive_size_bytes(prepared.archive)));
	var saved = get_save_filename_ext(save_filter, prepared.suggest, prepared.directory, lang("menu.toolsSaveTitle"));
	phi_tools_log("save path=" + string(saved));
	var status = "";
	if (!string_length(saved)) {
		status = lang("menu.cancelled");
	} else {
		if (file_exists(saved)) then file_delete(saved);
		file_copy(prepared.archive, saved);
		var saved_ok = file_exists(saved);
		phi_tools_log("copy exists=" + string(saved_ok) + " bytes=" + string(chart_archive_size_bytes(saved)));
		var fail_key = "menu.toolsFail";
		if (want_pec) then fail_key = "menu.toolsFailPec";
		if (saved_ok) then status = langf("menu.toolsDone", saved);
		else status = lang(fail_key);
	};
	if (file_exists(prepared.archive)) then file_delete(prepared.archive);
	return status;
}

/// Extract a .zip / .pez, convert its official or PEC chart to RPE 160, and repack.
/// source_format defaults to an official chart. The save dialog is not opened here.
/// Returns { ok, archive, suggest, directory, error }.
function phi_tools_prepare_rpe_package(src_path, source_format = undefined) {
	var work = "";
	var packed = "";
	phi_tools_log("begin log=" + LogGetPath());
	phi_tools_log("src=" + string(src_path) + " exists=" + string(chart_file_exists_any(src_path)) + " bytes=" + string(chart_archive_size_bytes(src_path)));
	try {
		if (!is_string(src_path) || !string_length(src_path)) then return phi_tools_fail("Empty package path.", work, packed);
		var archive_ext = string_lower(chart_path_ext(src_path));
		phi_tools_log("ext=" + archive_ext);
		if (archive_ext != ".zip" && archive_ext != ".pez") then return phi_tools_fail("Choose a .zip or .pez package.", work, packed);
		if (!chart_file_exists_any(src_path)) then return phi_tools_fail("Package file does not exist.", work, packed);

		var cache = chart_gm_cache_dir();
		work = cache + "phi_tools_src/";
		packed = cache + "phi_tools_out" + archive_ext;
		phi_tools_log("cache=" + cache + " work=" + work + " packed=" + packed);
		chart_session_remove_dir(work);
		if (file_exists(packed)) then file_delete(packed);
		if (!directory_exists(work)) then directory_create(work);
		phi_tools_log("work dir exists=" + string(directory_exists(work)));

		var unzipped = 0;
		if (pls_is_gxgames()) {
			phi_tools_log("extract via gx_zip_extract");
			if (!gx_zip_extract(src_path, work, true, false)) then unzipped = 0;
			else unzipped = 1;
			phi_tools_log("gx extract ok=" + string(unzipped) + " err=" + gx_zip_last_error());
		} else {
			phi_tools_log("extract via zip_unzip");
			unzipped = zip_unzip(src_path, work);
			phi_tools_log("zip_unzip count=" + string(unzipped));
		};
		if (!unzipped) {
			phi_tools_log("extract fallback unicode_zip_backend_extract");
			var fallback_ok = unicode_zip_backend_extract(src_path, work, true, false);
			phi_tools_log("fallback ok=" + string(fallback_ok) + " err=" + unicode_zip_backend_last_error());
			if (!fallback_ok) then return phi_tools_fail("Failed to read the package.", work, packed);
		};

		var root = chart_session_resolve_extract_root(work);
		phi_tools_log("extract root=" + string(root) + " dir=" + string(directory_exists(root)));
		var discovered = File_Discoverer(root);
		phi_tools_log("discovered chart=" + string(array_length(discovered.chart))
			+ " music=" + string(array_length(discovered.music))
			+ " image=" + string(array_length(discovered.image))
			+ " text=" + string(array_length(discovered.text))
			+ " other=" + string(array_length(discovered[$ "other"])));
		// GML binds && tighter than ==, so this comparison stays in its own if.
		var want_pec = false;
		if (source_format == CHART_FORMAT.PEC) then want_pec = true;
		phi_tools_log("source_format=" + string(source_format) + " want_pec=" + string(want_pec));
		var chart_path = "";
		var missing = "No official chart was found in the package.";
		if (want_pec) {
			chart_path = phi_tools_find_pec(discovered);
			missing = lang("menu.toolsNoPec");
		} else {
			chart_path = phi_tools_find_official(discovered);
		};
		phi_tools_log("chart=" + string(chart_path));
		if (!string_length(chart_path)) then return phi_tools_fail(missing, work, packed);

		var built = undefined;
		if (want_pec) {
			var pec_text = chart_read_text_file(chart_path, -1);
			phi_tools_log("pec text chars=" + string(is_string(pec_text) ? string_length(pec_text) : -1));
			if (!is_string(pec_text) || !string_length(pec_text)) then return phi_tools_fail(lang("menu.toolsPecRead"), work, packed);
			built = phi_pec_to_rpe(pec_text, phi_tools_meta_from_root(root));
		} else {
			var official_text = chart_read_text_file(chart_path, -1);
			phi_tools_log("official text chars=" + string(is_string(official_text) ? string_length(official_text) : -1));
			var official_chart = undefined;
			try {
				official_chart = json_parse(official_text);
				phi_tools_log("json_parse struct=" + string(is_struct(official_chart)));
			} catch (parse_err) {
				var parse_detail = is_struct(parse_err) ? string(parse_err[$ "message"] ?? parse_err) : string(parse_err);
				phi_tools_log("json_parse exception: " + parse_detail);
				delete(parse_err);
				return phi_tools_fail("The official chart could not be read.", work, packed);
			};
			if (!is_struct(official_chart) || !is_array(official_chart[$ "judgeLineList"])) {
				phi_tools_log("official json missing judgeLineList");
				if (is_struct(official_chart)) then delete(official_chart);
				return phi_tools_fail("The official chart could not be read.", work, packed);
			};
			phi_tools_log("judge lines=" + string(array_length(official_chart.judgeLineList)) + " formatVersion=" + string(official_chart[$ "formatVersion"] ?? ""));
			built = phi_official_to_rpe(official_chart);
			delete(official_chart);
		};
		phi_tools_log("convert struct=" + string(is_struct(built)));
		var convert_fail = "Chart conversion failed.";
		if (want_pec) then convert_fail = lang("menu.toolsConvert");
		if (!is_struct(built)) then return phi_tools_fail(convert_fail, work, packed);
		var convert_stats = built[$ "stats"];
		if (is_struct(convert_stats)) then phi_tools_event_report(convert_stats);
		variable_struct_remove(built, "stats");

		var source_name = chart_path_file_name(chart_path);
		var parts = phi_tools_stem_ext(source_name);
		var taken = phi_tools_collect_names(discovered);
		var out_ext = parts.ext;
		if (want_pec) then out_ext = ".json";
		var chart_file_name = phi_tools_unique_marked_name(parts.stem, "_rpe160", out_ext, taken);
		var chart_out = chart_path_join(chart_path_dir(chart_path), chart_file_name);
		phi_tools_log("write chart " + chart_out);
		chart_buffer_save_text(chart_out, json_stringify(built, true));
		delete(built);
		phi_tools_log("chart written exists=" + string(file_exists(chart_out)) + " bytes=" + string(chart_archive_size_bytes(chart_out)));
		if (file_exists(chart_out) && string_lower(chart_path_norm(chart_path)) != string_lower(chart_path_norm(chart_out))) {
			phi_tools_log("delete original chart " + chart_path);
			file_delete(chart_path);
			if (file_exists(chart_path)) then file_delete(string_replace_all(chart_path, "/", "\\"));
			phi_tools_log("original chart exists=" + string(file_exists(chart_path)));
		};

		var info_txt = chart_path_join(root, "info.txt");
		var info_yml = chart_path_join(root, "info.yml");
		var has_txt = chart_file_exists_any(info_txt);
		var has_yml = chart_file_exists_any(info_yml);
		phi_tools_log("info.txt=" + string(has_txt) + " path=" + info_txt);
		phi_tools_log("info.yml=" + string(has_yml) + " path=" + info_yml);
		if (has_txt) then phi_tools_set_chart_field(info_txt, chart_file_name);
		if (has_yml) then phi_tools_set_chart_field(info_yml, chart_file_name);
		if (!has_txt && !has_yml) {
			phi_tools_log("info missing, write default info.txt");
			phi_tools_write_default_info(info_txt, chart_file_name);
		};
		phi_tools_log("info chart field=" + chart_file_name);

		var root_clean = phi_tools_trim_dir(root);
		var native_zip = chart_gm_cache_dir() + "phi_tools_native.zip";
		if (file_exists(native_zip)) then file_delete(native_zip);
		if (file_exists(packed)) then file_delete(packed);
		phi_tools_log("compress native available=" + string(unicode_zip_backend_available()) + " root=" + root_clean + " zip=" + native_zip);
		var native_ok = unicode_zip_backend_compress(root_clean, native_zip, 0, 1);
		var zip_error = unicode_zip_backend_last_error();
		var native_magic = phi_tools_zip_magic_ok(native_zip);
		phi_tools_log("native compress ok=" + string(native_ok) + " exists=" + string(file_exists(native_zip)) + " bytes=" + string(chart_archive_size_bytes(native_zip)) + " pk=" + string(native_magic) + " err=" + string(zip_error));
		var packed_ok = false;
		if (native_ok && native_magic) {
			file_copy(native_zip, packed);
			file_delete(native_zip);
			packed_ok = file_exists(packed) && phi_tools_zip_magic_ok(packed);
			phi_tools_log("copied native zip to " + packed + " ok=" + string(packed_ok) + " bytes=" + string(chart_archive_size_bytes(packed)));
		} else {
			if (file_exists(native_zip)) then file_delete(native_zip);
			phi_tools_log("native compress did not produce a zip, writing a stored zip");
			packed_ok = phi_tools_pack_stored_zip(root, packed);
		};
		chart_session_remove_dir(work);
		work = "";
		if (!packed_ok || !file_exists(packed)) {
			if (!string_length(zip_error)) then zip_error = "Failed to pack the converted chart.";
			return phi_tools_fail(zip_error, work, packed);
		};

		var archive_name = chart_path_file_name(src_path);
		var archive_parts = phi_tools_stem_ext(archive_name);
		var archive_dir = chart_path_dir(src_path);
		var suggest = archive_parts.stem + "_rpe" + archive_parts.ext;
		if (file_exists(chart_path_join(archive_dir, suggest))) {
			suggest = "";
			for (var name_try = 0; name_try < 30; name_try++) {
				var marked_archive = archive_parts.stem + "_rpe-" + phi_tools_digits5() + archive_parts.ext;
				if (!file_exists(chart_path_join(archive_dir, marked_archive))) {
					suggest = marked_archive;
					break;
				};
			};
			if (!string_length(suggest)) then suggest = archive_parts.stem + "_rpe-" + phi_tools_digits5() + archive_parts.ext;
		};
		var slash = max(string_last_pos("/", src_path), string_last_pos("\\", src_path));
		var dialog_dir = (slash > 0) ? string_copy(src_path, 1, slash) : "";
		phi_tools_log("ready suggest=" + suggest + " dialog_dir=" + dialog_dir + " archive=" + packed);
		packed = "";
		return { ok: true, archive: cache + "phi_tools_out" + archive_ext, suggest: suggest, directory: dialog_dir, error: "" };
	} catch (tool_err) {
		var detail = is_struct(tool_err) ? string(tool_err[$ "message"] ?? tool_err) : string(tool_err);
		phi_tools_log("exception: " + detail);
		delete(tool_err);
		return phi_tools_fail("Exception: " + detail, work, packed);
	};
}

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
		// Speed integration follows RPEVersion. Converted charts are 160 so the
		// pre-1.7 speed table is used. The build label shows this number.
		self.version = real(meta[$ "RPEVersion"] ?? 0);
		self.pgr_version = undefined;
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
		var n = 0,
			chart_dir = ($"{game_save_id}charts/");
		if(!directory_exists(chart_dir)) then directory_create(chart_dir);
		var path = ($"{chart_dir}{current_year}-{current_month}-{current_day}-");
		while(file_exists($"{path}{n}.json")){
			n ++;	
		};
		
		chart_buffer_save_text($"{path}{n}.json", json_stringify(self.chart, true));
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
	// PhiEditer writes cv 70000 as a one-tick warp. Notes exported a fraction
	// of a beat inside that segment pick up a floor step of 1 or more and
	// stay off screen for the whole approach. Hold the floor at the segment
	// start; the following event already stores the finished jump.
	if (abs(event.value) >= 1000) then elapsed = 0;
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
			case "cv": if (array_length(tokens) >= 4) then array_add(_l.speedEvents, { beat: number(tokens[2], 0), value: number(tokens[3], 0) / 7 }); break;
			case "cp": if (array_length(tokens) >= 5) then array_add(_l.moveEvents, { startBeat:number(tokens[2],0), endBeat:number(tokens[2],0), target:[number(tokens[3],0)/2048, 1-number(tokens[4],0)/1400], easing:1 }); break;
			case "cm": if (array_length(tokens) >= 7) then array_add(_l.moveEvents, { startBeat:number(tokens[2],0), endBeat:number(tokens[3],0), target:[number(tokens[4],0)/2048, 1-number(tokens[5],0)/1400], easing:number(tokens[6],1) }); break;
			case "cd": if (array_length(tokens) >= 4) then array_add(_l.rotateEvents, { startBeat:number(tokens[2],0), endBeat:number(tokens[2],0), target:-number(tokens[3],0), easing:1 }); break;
			case "cr": if (array_length(tokens) >= 6) then array_add(_l.rotateEvents, { startBeat:number(tokens[2],0), endBeat:number(tokens[3],0), target:-number(tokens[4],0), easing:number(tokens[5],1) }); break;
			case "ca": if (array_length(tokens) >= 4) then array_add(_l.alphaEvents, { startBeat:number(tokens[2],0), endBeat:number(tokens[2],0), target:number(tokens[3],0)/255, easing:1 }); break;
			case "cf": if (array_length(tokens) >= 5) then array_add(_l.alphaEvents, { startBeat:number(tokens[2],0), endBeat:number(tokens[3],0), target:number(tokens[4],0)/255, easing:1 }); break;
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

