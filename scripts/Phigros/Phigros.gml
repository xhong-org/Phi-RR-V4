
/*							

			我就直说了,我以后不会再写Phi-RR(Phigros)了。
			别问我为什么不改,我已经很尽力在改了(你看到作者的话,那就是我对这坨代码的看法了)
			
			。。。
			我不行了,我就再做最后的优化我就滚去现实生活了.啥v5,不熟
			写GameMaker都是疯掉的没一个正常,哈哈哈,全是傻逼弱智没脑的人,我也是。。。
			瞎几把改
			
			傻逼。
			
			以上全是作者发电。。。。
			
			写不动了,我懒得写了,我本来也不爱写注释
			
			
			v4完结

																									*/
// 石库水
#macro print LogOutputFile
#macro elif else if
#macro func function
#macro isExists chart_file_exists_any
#macro InChartPath (variable_global_exists("chart_active_path") && is_string(global.chart_active_path) && string_length(global.chart_active_path) ? global.chart_active_path : (working_directory + "chart/"))
#macro VerReal { "windows": 40542, "android": 40534, "gxgames": 40532 } // 各平台版本号(独立)
#macro VerStr "v.4.1.1-fin"

///@desc 按当前操作系统从 VerReal 取出对应版本号
///@returns {Real} 平台版本号，未知平台为 40500
/// 作者的话: 没啥好说的
function ver_real() {
	var platform = "other";
	if (os_type == os_gxgames) then platform = "gxgames";
	else if (os_type == os_windows) then platform = "windows";
	else if (os_type == os_android) then platform = "android";
	var names = struct_get_names(VerReal);
	// 平台名与 VerReal 字段对齐后返回
	for (var i = 0; i < array_length(names); i++) {
		if (string_lower(names[i]) == platform) then return (struct_get(VerReal , names[i]))//VerReal[$ names[i]];
	};
	return 40500;
}

// 其他
/// 作者的话: v4.0.6的旧产物
#macro GAME_NAME "Re: Phi-RR - " + VerStr
#macro HYW_MODE true
#macro BYD_COLOR_MODE true
#macro BYD_COLOR_FUNC if(BYD_COLOR_MODE && PhiTime) then image_blend = (make_colour_hsv( (game.__time[1] * 50) % 255  , 255  , 255 ))


///@desc 判断精灵资源是否可用
///@param {Any} _id 精灵索引或资源引用
///@returns {Bool} 存在且有效为真
/// 作者的话: 没啥用
function asset_sprite_valid(_id) {
	if (is_undefined(_id)) then return (false);
	if (is_string(_id)) then return (false);
	// sprite_add 失败时通常返回 -1
	if (is_real(_id) && _id < 0) then return (false);
	return (sprite_exists(_id));
}

///@desc 判断字体资源是否可用
///@param {Any} _id 字体索引或资源引用
///@returns {Bool} 存在且有效为真
/// 作者的话: 没啥用
function asset_font_valid(_id) {
	if (is_undefined(_id)) then return (false);
	if (is_string(_id)) then return (false);
	if (is_real(_id) && _id < 0) then return (false);
	return (font_exists(_id));
}

///@desc 判断缓冲区是否可用
///@param {Any} _id 缓冲区索引
///@returns {Bool} 存在且有效为真
/// 作者的话: 没啥用
function asset_buffer_valid(_id) {
	if (is_undefined(_id)) then return (false);
	if (is_string(_id)) then return (false);
	if (is_real(_id) && _id < 0) then return (false);
	return (buffer_exists(_id));
}



// 实验性内容
/// 作者的话: 本就是测试用的,你当它是滚木了
//scheduler_resolution_set(800000000000);
//gpu_set_texfilter(true);
if (os_browser == browser_not_a_browser) then gml_release_mode(true);
//gml_pragma("forceinline");

//string_format()

/// @desc 图层深度 (未知) 
// 憋憋枚举
/// 作者的话: 枚举,不过现在已经基本成滚木了,虽然还是有用到的,自从兼容了RPE和PhiZone,我当它是滚木
enum DEPTH {
	DEBUG = -15000,
	LINE = -3000,
	NOTE = -7000,
	HEF = -11000,
	BG = -100
};

///@desc 把 PhiZone 的 Z 坐标换成实例深度
///@param {Real} z 图层 Z
///@returns {Real} 深度，为 -1000 乘以 Z
/// 作者的话: 诺,刚说完
function chart_layer_depth(z) {
	return (-1000 * z);
}

///@desc 安全地设置实例深度
///@param {Id.Instance} _inst 目标实例
///@param {Real} _depth 新的深度
///@returns {Undefined} 无
/// 作者的话: 安全在哪
function chart_set_instance_depth(_inst, _depth) {
	// 实例已销毁则直接退出
	if (!instance_exists(_inst)) then return;
	with (_inst) {
		depth = _depth;
	};
}

///@desc 解析 RPE 音符的图层 Z
///@param {Real} rpe_type RPE 音符类型
///@param {Any} explicit_z 显式 Z，默认未定义
///@returns {Real} 使用的图层 Z
/// 作者的话: 对Shader渲染层级
function chart_note_layer_z(rpe_type, explicit_z = undefined) {
	if (is_real(explicit_z) && is_finite(explicit_z)) then return explicit_z;
	var priority = 3;
	// 2/3/4 类音符使用不同叠层优先级
	if (rpe_type == 2) then priority = 1;
	else if (rpe_type == 3) then priority = 4;
	else if (rpe_type == 4) then priority = 2;
	return priority + 2;
}

///@desc 沿父判定线链折算 RPE 判定线的视图位置与旋转
///@param {Id.Instance} _line 判定线实例
///@param {Real} _sx 横坐标缩放
///@param {Real} _sy 纵坐标缩放
///@returns {Array} x、y 与旋转角
/// 作者的话: 傻逼玩意,和oLine_1沾一块摘不掉了
function rpe_line_view_pose(_line, _sx, _sy) {
	// 变量
	var local_x = 0;
	var local_y = 0;
	var local_r = 0;

	// 检查实例是否暴毙
	if (!instance_exists(_line)) then return [local_x, local_y, local_r];
	if (variable_instance_exists(_line, "__raw_x") && is_real(_line.__raw_x)) then local_x = _line.__raw_x * _sx;
	if (variable_instance_exists(_line, "__raw_y") && is_real(_line.__raw_y)) then local_y = _line.__raw_y * _sy;
	if (variable_instance_exists(_line, "__raw_r") && is_real(_line.__raw_r)) then local_r = _line.__raw_r;
	if (!variable_instance_exists(_line, "_father_chain") || !is_array(_line._father_chain)) {
		_line._father_chain = [];
	};

	// 父链为空时按 isFather 向上补最多 16 层
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

	// 没有父线就只用本地坐标
	if (array_length(chain) <= 0) then return [local_x, local_y, local_r];

	var parent_x = 0;
	var parent_y = 0;
	var parent_r = 0;
	var have_parent = false;

	// 从最外层祖先往下叠旋转和平移
	for (var ai = array_length(chain) - 1; ai >= 0; ai--) {
		var ancestor = chain[ai];
		if (!instance_exists(ancestor) || !variable_instance_exists(ancestor, "__raw_x")) {
			have_parent = false;
			break;
		};

		// 换算
		var ancestor_x = ancestor.__raw_x * _sx;
		var ancestor_y = ancestor.__raw_y * _sy;

		// 爸爸
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

	// 把本线坐标旋进父线空间
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

///@desc 按 PhiEdit 1.7 的宽高比计算预览宽高
///@param {Real} _aspect 宽高比，非法时按 16:9
///@returns {Array} 预览宽度和高度
/// 作者的话: 抄RPE v1.7.0
function rpe_preview_size(_aspect) {
	if (!is_real(_aspect) || !is_finite(_aspect) || _aspect <= 0) then _aspect = 16 / 9;
	var preview_w = 1350;
	var preview_h = 1350 / _aspect;
	// 高度超过 900 时改为限高并反算宽度
	if (preview_h > 900) {
		preview_h = 900;
		preview_w = _aspect * 900;
	};
	return [preview_w, preview_h];
}

///@desc 计算默认判定线纹理的像素宽高
///@param {Real} scale_x 横向缩放
///@param {Real} scale_y 纵向缩放
///@param {Real} view_w 视图宽度
///@returns {Array} 像素宽度和高度
/// 作者的话: 没话说,global_scales差不多退役了
function rpe_default_line_pixel_size(scale_x, scale_y, view_w) {
	var design_y = view_w / 1350;
	// 有谱面视高时按 900 设计高度换算
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

///@desc 计算自定义判定线纹理的像素宽高
///@param {Real} scale_x 横向缩放
///@param {Real} scale_y 纵向缩放
///@param {Real} sprite_w 精灵宽度
///@param {Real} sprite_h 精灵高度
///@param {Real} view_w 视图宽度
///@returns {Array} 像素宽度和高度
/// 作者的话: 文本
function rpe_custom_texture_pixel_size(scale_x, scale_y, sprite_w, sprite_h, view_w) {
	var aspect = 16 / 9;
	if (variable_global_exists("chart_aspect_ratio") && is_real(chart_aspect_ratio) && is_finite(chart_aspect_ratio) && chart_aspect_ratio > 0) {
		aspect = chart_aspect_ratio;
	};
	var preview = rpe_preview_size(aspect);
	var preview_w = max(0.000001, preview[0]);
	var preview_h = max(0.000001, preview[1]);
	var view_h = view_w * preview_h / preview_w;
	if (variable_global_exists("chart_view_height") && is_real(chart_view_height) && chart_view_height > 0) {
		view_h = chart_view_height;
	};
	var fit_x = view_w / preview_w;
	var fit_y = view_h / preview_h;
	// 竖屏共用一份缩放，避免高于 PhiEdit 预览时两轴各自拉伸
	if (view_w < view_h) {
		var fit = min(fit_x, fit_y);
		fit_x = fit;
		fit_y = fit;
	};
	return [sprite_w * scale_x * fit_x, sprite_h * scale_y * fit_y];
}

///@desc 计算判定线当前的像素宽度
///@param {Id.Instance} line_instance 判定线实例
///@returns {Real} 像素宽度，实例无效时为 0
/// 作者的话: 文本文本文本
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
	// 自定义纹理走 CSV 或 RPE 贴图像素，默认线走标准线宽
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

///@desc 按判定线宽度开始裁剪音符，PhiZone 的 scaleOnNotes
///@param {Id.Instance} line_instance 判定线实例
///@returns {Real} 0 不裁剪，1 矩形剪刀，2 斜线着色器
/// 作者的话: 抄PhiZone的
function chart_note_scale_clip_begin(line_instance) {

	static u_clip = -1;
	static u_half = -1;
	static fetched = false;

	if (!instance_exists(line_instance)) then return 0;
	var mode = 0;
	if (variable_instance_exists(line_instance, "scale_on_notes") && is_real(line_instance.scale_on_notes)) {
		mode = real(line_instance.scale_on_notes);
	};
	// 仅模式 2 才按线宽裁剪
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

	// 水平或垂直线用剪刀矩形，斜线改走着色器
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
		// 裁剪区盖满视图就不必设置剪刀
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

	// 四个角都在线宽内，说明整屏已被覆盖
	if (cover) then return 0;
	// 只在应用表面或未绑定表面时启用裁剪着色器
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

///@desc 结束音符缩放裁剪，恢复剪刀或着色器
///@param {Real} active 开始裁剪时返回的方式
///@returns {Undefined} 无
/// 作者的话: 裁剪结束
function chart_note_scale_clip_end(active) {
	// 1 还原谱面剪刀，2 关闭裁剪着色器
	if (active == 1) {
		chart_mask_scissor_set();
	} else if (active == 2) {
		shader_reset();
	};
}

///@desc 音符判定类型
/// 作者的话: 这个没问题
enum TYPE {
	PREFECT,
	GOOD,
	MISS,
	BAD,
	NONE
};

///@desc 按当前判定成绩给出 FC 或 AP 判定线颜色
///@returns {Real} 混合色，未开启或已断连时为白色
/// 作者的话: 拉完了
function chart_line_judge_blend() {
	// 未开启判定线染色时保持白色
	if (!(variable_global_exists("game") && is_struct(game) && is_struct(game.settings)
		&& bool(game.settings.enableLineJudge ?? false))) then return c_white;
	var blend = #ffeca0;
	// 全 Perfect 为金色，出现 Good 变蓝，Bad 或 Miss 退回白色
	if (variable_global_exists("phi_state_list") && is_struct(phi_state_list)) {
		if (real(phi_state_list.good ?? 0) > 0) then blend = make_colour_rgb(162, 238, 255);
		if (real(phi_state_list.bad ?? 0) + real(phi_state_list.miss ?? 0) > 0) then blend = c_white;
	};
	return blend;
}


/// 作者的话: 实验性内容,v4.0.4留的
//display_set_timing_method(tm_systemtiming);
//display_reset(0 , true);



// cmd命令调用参数
var cmd_count = (parameter_count());
/// 作者的话: 最初初衷是像Undertale的玩法而设计的
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
	// 实验性内容
	if(!variable_global_exists("easing_type_in_official")) { globalvar easing_type_in_official;  };
	variable_global_set("easing_type_in_official" , 10);
};


/// 作者的话: 旧时代
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

/// 作者的话: 没啥用,可以直接删
randomise();
// 测试
var sval = "fweasfare",
	eval = "Hel";
show_debug_message(string_copy(sval, 1, string_length(eval))); 

///@desc 按 Perfect 与 Good 计算准确率并写回状态
///@returns {String} 准确率文本，无音符时为 100
/// 作者的话: 起码我自己写的
function accCalc(){
	var aoc = (phi_state_list),
		counts = (aoc.prefect + aoc.good + aoc.miss + aoc.bad),
		_acc = (clamp((100 * ((aoc.prefect + (aoc.good * 0.65)) / counts)) , 0 , 100));
	// 分母为 0 时 real 会变成 NaN，按满分处理
	if(is_nan(_acc)) then _acc = 100.0000;
	phi_state_list.acc = _acc;
	
	return(string(_acc));
};


///@desc 按时间差判定音符并更新连击、计数与打击特效
///@param {Real} oHTime 音符命中时间
///@param {Real} nHTime 实际打击时间
///@param {Real} bpm 用于把拍换算成秒
///@param {Real} xx 特效横坐标
///@param {Real} yy 特效纵坐标
///@param {Real} _type 音符类型
///@param {Bool} isFHitEf 是否播放打击特效，默认真
///@param {Bool} insCombo 是否计入连击与成绩，默认真
///@param {Bool} timeInSeconds 时间是否已是秒，默认假
///@param {Any} effectColor 特效颜色，默认未定义
///@desc 按时间差判定音符并更新连击、计数与打击特效
///@returns {Real} TYPE 判定结果
/// 作者的话: 你最好看了别笑，这个也是我写的
function judgeCalc(oHTime , nHTime , bpm , xx , yy , _type , isFHitEf = true, insCombo = true, timeInSeconds = false, effectColor = undefined){
	var timer = (timeInSeconds ? real(oHTime) : game.Math.realTimer(bpm , oHTime)),
		ntimer = (timeInSeconds ? real(nHTime) : game.Math.realTimer(bpm , nHTime)),
		score_list = [ (max(timer , ntimer)), (min(timer , ntimer)) , (timer > ntimer) ],
		offset = (abs( (score_list[0] - score_list[1]) * 1000 )),
		color = #ffeca0,
		status = TYPE.NONE;
	// 80ms 内为 Perfect
	if(offset >= -80 && offset <= 80){
		
		if(insCombo) then combo ++;
		if(phi_state_list.max_hitcombo < combo) then phi_state_list.max_hitcombo = combo;
		if(insCombo) then phi_state_list.prefect ++;
		color = #ffeca0;
		status = TYPE.PREFECT;
		
	// 80 到 160ms：Tap/Hold 记 Good，其余仍算 Perfect
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
		
	// 160 到 200ms 的 Tap 记 Bad，Hold 记 Miss
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
		
	// 更晚只在已经过点时记 Miss，提前打到则忽略
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

///@desc 重算 RPE 音符在判定线上的打击特效坐标
///@returns {Array} 特效的 x 与 y
/// 作者的话: 这个本来想写在oLine_1的Create事件
function rpe_note_hit_effect_xy() {
	// 先刷新判定线几何，再投影音符本地坐标
	if (instance_exists(_line_ref)) {
		with (_line_ref) event_perform(ev_step, ev_step_end);
		event_user(_step_user_count);
	};
	return [_x_h, _y_h];
};

///@desc 计算非 Hold 音符命中后的淡出比例
///@param {Real} _now_sec 当前时间，秒
///@param {Real} _hit_sec 命中时间，秒
///@param {Real} _miss_sec Miss 窗口，秒
///@returns {Real} 1 到 0 的透明度，Hold 不使用
/// 作者的话: 同理上面
function chart_note_pass_fade(_now_sec, _hit_sec, _miss_sec) {
	if (!is_real(_now_sec) || !is_real(_hit_sec) || !is_real(_miss_sec) || _miss_sec <= 0) then return 1;
	if (_now_sec <= _hit_sec) then return 1;
	return clamp(1 - ((_now_sec - _hit_sec) / _miss_sec), 0, 1);
}

///@desc 按音符类型给出 Miss 判定窗口
///@param {Real} _jtype 判定类型
///@param {Bool} _is_hold 是否为 Hold
///@returns {Real} 窗口秒数
/// 作者的话: 何求极
function chart_note_miss_window_sec(_jtype, _is_hold) {
	// Hold 与类型 3 为 161ms，Drag/Flick 为 160ms
	if (_is_hold || _jtype == 3) then return 0.161;
	if (_jtype == 2 || _jtype == 4) then return 0.160;
	return 0.201;
}

///@desc 判断 RPE alphaControl 是否没有真正改变透明度
///@param {Any} _raw alpha 事件数组
///@returns {Bool} 恒为 1 或 255 时为真
/// 作者的话: 这个也是，本来可以直接塞oLine_1的
function rpe_alpha_control_is_identity(_raw) {
	// 事件不足两条时视为恒等
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
		// 偏离完全不透明则不是恒等控制
		if (abs(rv - 1) > 0.001) then return false;
	};
	return true;
}

///@desc 重算 PEC 音符在判定线上的打击特效坐标
///@returns {Array} 特效的 x 与 y
/// 作者的话: 拉
function pec_note_hit_effect_xy() {
	if (!instance_exists(line_ref)) then return [x, y];
	var _local_x = localXFactor * chart_view_width;
	var _c = line_ref.__cos;
	var _s = line_ref.__sin;
	return [line_ref.x + _c * _local_x, line_ref.y - _s * _local_x];
};

///@desc 判断当前是否自动演奏，含无输入的录像模式
///@returns {Bool} 自动演奏为真
/// 作者的话: 。。。
function chart_autoplay_active() {
	// 录像没有玩家输入，一律自动演奏
	if (variable_global_exists("render_mode") && global.render_mode) then return true;
	if (!(variable_global_exists("game") && is_struct(game) && is_struct(game.settings))) then return true;
	return bool(game.settings.enableAutoPlay ?? true);
}

///@desc 取自动打击的时间偏移，单位毫秒
///@param {Any} _jtype 判定类型，默认未定义
///@returns {Real} 偏移毫秒，Drag/Flick 限制在 0 到 160
/// 作者的话: 给我裁到底层了
function chart_auto_hit_offset_ms(_jtype = undefined) {
	if (!(variable_global_exists("game") && is_struct(game) && is_struct(game.settings))) then return 0;
	var off = real(game.settings.judgeOffset ?? 0);
	if (bool(game.settings.TEST1 ?? false)) {
		off = choose(choose(random_range(-95, 0), random_range(0, 95), choose(1, 2, 5, -1, -6, choose(200, 10))), 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
	} else if (abs(off) >= 30000) {
		off = random_range(-201, 201);
	};
	// Drag/Flick 不能提前，也不能落到 Bad 或 Miss
	if (!is_undefined(_jtype) && (_jtype == 2 || _jtype == 4)) then return clamp(off, 0, 160);
	return off;
}

///@desc 判断是否为桌面系统，用于键盘判定
///@returns {Bool} Windows、Linux 或 macOS 为真
/// 作者的话: 文本
function chart_kb_desktop() {
	return (os_type == os_windows || os_type == os_linux || os_type == os_macosx);
}

///@desc 取得键盘判定的静态状态
///@returns {Struct} 宽限时间、按住数、新按下数与上一帧按键
/// 作者的话: 还得重写键盘判定，这个你当滚木用吧，但是别删了，否则屎山爆炸
function chart_kb_state_get() {
	static st = undefined;
	// 首次调用时建立 A 到 Z 的按键记录
	if (is_undefined(st)) then st = { grace_until: -1, held: 0, pressed: 0, prev: array_create(26, false) };
	return st;
}

///@desc 读取单个虚拟键是否按下
///@param {Real} _vk 虚拟键码
///@returns {Bool} 按下为真
/// 作者的话: 这个也是，别删了
function chart_kb_key_down(_vk) {
	// Windows 用直接键态，避免输入法吃掉按键
	if (os_type == os_windows) then return keyboard_check_direct(_vk);
	return keyboard_check(_vk);
}

///@desc 轮询 A 到 Z 的原始键态，使十余个键同时按下也能识别
///@returns {Struct} 更新后的键盘状态
/// 作者的话: 傻逼。
function chart_kb_poll() {
	var st = chart_kb_state_get();
	st.held = 0;
	st.pressed = 0;
	// 统计按住数量，以及相对上一帧新按下的键
	for (var i = 0; i < 26; i++) {
		var down = chart_kb_key_down(65 + i);
		if (down) then st.held++;
		if (down && !st.prev[i]) then st.pressed++;
		st.prev[i] = down;
	};
	return st;
}

///@desc 判断 A 到 Z 是否有任意键按下
///@returns {Bool} 有键按下为真
/// 作者的话: 。
function chart_kb_any_down() {
	for (var i = 0; i < 26; i++) {
		if (chart_kb_key_down(65 + i)) then return true;
	};
	return false;
}

///@desc 判断 Hold 是否仍应保持，含松键后的 80 毫秒宽限
///@returns {Bool} 仍按住或处于宽限内为真
/// 作者的话: 。
function chart_kb_hold_alive() {
	if (chart_kb_any_down()) then return true;
	var st = chart_kb_state_get();
	// 没有松键宽限时间则视为已经断开
	if (st.grace_until < 0) then return false;
	if (!(variable_global_exists("game") && is_struct(game))) then return false;
	return (game.__time[1] < st.grace_until);
}

///@desc 判断现在是否允许用键盘做全屏判定
///@returns {Bool} 允许为真
/// 作者的话: 。
function chart_player_keyboard_judge_active() {
	// 自动演奏、非桌面、暂停、加载或结算时关闭
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

///@desc 读取当前音符的判定时间，单位秒
///@returns {Real} 命中时间
/// 作者的话: 。
function chart_kb_note_hit_sec() {
	if (object_index == oNote) then return realHitTime;
	if (object_index == oNote_1) then return start_sec;
	return startSec;
}

///@desc 读取当前谱面时间，单位秒
///@returns {Real} 当前时间
/// 作者的话: 幽默。
function chart_kb_note_now_sec() {
	if (object_index == oNote || object_index == oNote_1) then return _now_seconds;
	var _off = 0;
	// oNote_2 需要扣掉谱面偏移
	if (variable_global_exists("game_2") && is_struct(game_2) && is_struct(game_2.chart)) {
		_off = real(game_2.chart.offsetSeconds ?? 0);
	};
	return game.__time[1] - _off;
}

///@desc 读取当前音符的判定类型
///@returns {Real} 判定类型
/// 作者的话: 干脆把我Phigros()全拆一个全局函数了
function chart_kb_note_judge_type() {
	if (object_index == oNote_2) then return judge_type;
	return type;
}

///@desc 判断当前音符是否为 Hold
///@returns {Bool} 是 Hold 为真
/// 作者的话: 。
function chart_kb_note_is_hold() {
	if (object_index == oNote_2) then return (type == 2);
	return (type == 3);
}

///@desc 判断当前时间是否落在该音符的键盘判定窗口
///@param {Real} _now 当前时间，秒
///@param {Real} _hit 命中时间，秒
///@param {Real} _jtype 判定类型
///@param {Bool} _hold 是否为 Hold
///@returns {Bool} 在窗口内为真
/// 作者的话: 。
function chart_kb_note_in_window(_now, _hit, _jtype, _hold) {
	// Drag/Flick 不能提前，最晚只到 Perfect 的 160ms，不含 Bad 或 Miss
	if (!_hold && (_jtype == 2 || _jtype == 4)) {
		return (_now >= _hit && _now <= _hit + 0.160);
	};
	var early = 0.200;
	var late = _hold ? 0.161 : 0.201;
	return (_now >= _hit - early && _now <= _hit + late);
}

///@desc 判断音符能否被本帧键盘选中
///@param {Real} _mode 0 为单击 Tap/Hold，1 为按住时的 Drag/Flick
///@returns {Bool} 可以选中为真
/// 作者的话: 不想理
function chart_kb_note_eligible(_mode) {
	if (variable_instance_exists(id, "kb_ignore") && kb_ignore) then return false;
	if (object_index == oNote && !inition) then return false;
	if (object_index == oNote_1 && (!inition || isFake)) then return false;
	if (object_index == oNote_2 && isFake) then return false;
	var jtype = chart_kb_note_judge_type();
	var hold = chart_kb_note_is_hold();
	if (!chart_kb_note_in_window(chart_kb_note_now_sec(), chart_kb_note_hit_sec(), jtype, hold)) then return false;
	// 单击只接未开始的 Hold 或未判定的 Tap
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

///@desc 判断 Hold 是否已经按下且尚未结束
///@returns {Bool} 仍在按住为真
/// 作者的话: 最弱智最出生的来了
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

///@desc 在同类音符里挑选离判定点最近的一个
///@param {Id.Instance} _obj 音符对象索引
///@param {Real} _mode 传给资格判断的模式
///@returns {Id.Instance} 选中的音符，没有时为 noone
/// 作者的话: 傻逼
function chart_kb_pick(_obj, _mode) {
	var best_note = noone;
	var best_dt = infinity;
	var best_hit = infinity;
	with (_obj) {
		if (!chart_kb_note_eligible(_mode)) then continue;
		var hit = chart_kb_note_hit_sec();
		var dt = abs(chart_kb_note_now_sec() - hit);
		// 时间差更小优先；一样时取更早的判定点
		if (dt < best_dt || (dt == best_dt && hit < best_hit)) {
			best_dt = dt;
			best_hit = hit;
			best_note = id;
		};
	};
	return best_note;
}

///@desc 对选中的音符执行一次键盘判定
///@param {Id.Instance} _note 音符实例
///@returns {Real} TYPE 判定结果，无效音符为 NONE
/// 作者的话: 2B
function chart_kb_apply_hit(_note) {
	if (_note == noone || !instance_exists(_note)) then return TYPE.NONE;
	var status = TYPE.NONE;
	with (_note) status = chart_kb_apply_hit_self();
	return status;
}

///@desc 在音符自己的作用域里完成键盘判定
///@returns {Real} TYPE 判定结果
/// 作者的话: 瞎几把判
function chart_kb_apply_hit_self() {
	var hold = chart_kb_note_is_hold();
	// 官方谱面音符
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
	// RPE 音符
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
	// PEC 音符
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

///@desc 把仍按着的 Hold 强制记为 Miss
///@returns {Undefined} 无
/// 作者的话: 傻逼
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

///@desc 桌面 A 到 Z 全屏判定，单击打 Tap/Hold，按住接 Drag/Flick
///@returns {Undefined} 无
/// 作者的话: 傻逼
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
	// 每个新按下的键消耗一张 Tap 或 Hold 头
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
	// 仍有键按住时连续接 Drag/Flick，并清掉松键宽限
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
			// 松键后给 80ms，超时仍未按下就断 Hold
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

///@desc 按准确率与连击计算七位分数字符串
///@param {Any} _mode 是否把连击计入分数，默认未定义时读设置
///@returns {String} 七位分数字符串
/// 作者的话: 这也是？哦不，这是我写的的改版，原理应该没变
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
	// 连击分占 10 万，其余 90 万来自准确率
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

///@desc 结算用的数值分数，规则与 ScoreSystem 相同
///@param {Any} _mode 是否把连击计入分数，默认未定义时读设置
///@returns {Real} 整数分数
/// 作者的话: 这是多余的，但又不多余
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

///@desc 把分数补成七位数字字符串
///@param {Real} _value 分数
///@returns {String} 左侧补零后的七位文本
/// 作者的话: 傻逼
function ScoreSystemPad(_value) {
	var _s = is_real(_value) && is_finite(_value) ? (_value | 0) : 0;
	if (_s < 0) then _s = 0;
	var _t = string(_s);
	while (string_length(_t) < 7) {
		_t = "0" + _t;
	};
	return _t;
};

///@desc 递归列出目录里的谱面、音乐、图片、文本与着色器
///@param {String} disc_path 要扫描的目录
///@returns {Struct} 按扩展名分组的路径数组
/// 作者的话: 啊，起码没写多
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
        // 列表接口没有结果时，改用 file_find 递归扫描
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

                                // 先收集文件
                                var file_name = file_find_first(path + "*", fa_none);
                                while(string_length(file_name)){
                                        if(file_name != "." && file_name != ".."){
                                                var full_file = path + file_name;
                                                // 没有 fa_directory 时也可能混进目录，这里跳过
                                                if(file_exists(full_file) && !directory_exists(full_file)){
                                                        array_add(file_path_list, string_replace_all(full_file, "\\", "/"));
                                                };
                                        };
                                        file_name = file_find_next();
                                };
                                file_find_close();

                                // 再把子目录放进待扫描队列
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
                // extra.json 不算谱面，其余按扩展名归类
				/// 作者的话: 笑了
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

///@desc 打开 zip 谱面包并返回会话里的曲目信息
///@param {String} path zip 路径
///@returns {Any} 成功为信息结构，失败为假
/// 作者的话: 这个最初还是fw
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



///@desc 读取 line.csv，或会话指定的判定线表
///@returns {Struct} 含 status、result 与 msg
/// 作者的话: 没怎么改
function load_line_csv(){
	var path = chart_path_join(InChartPath, "line.csv");
	if (variable_global_exists("chart_session") && is_struct(global.chart_session)
		&& is_string(global.chart_session.line_file) && string_length(global.chart_session.line_file)) {
		path = chart_path_join(InChartPath, global.chart_session.line_file);
	};
	// 文件不存在时走末尾的失败返回
	if(chart_file_exists_any(path)){
		path = chart_file_readable_path(path);
		var csv_grid = (load_csv(path));
		//print(csv_grid);
		if(!ds_exists(csv_grid , ds_type_grid)) then return({
			"status" : false,
			"result" : undefined,
			"msg" : "Is not ds_grid" /// 作者的话: 怎么把我这个保留了
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

///@desc 把 PCR 的 holdTime 取整，负的地板向零回一步
///@param {Real} _hold_time Hold 拍数
///@returns {Real} 取整后的拍数
/// 作者的话: 这里是和sim-phi对准，AI这个神笔，神马是负的地板(-FloorPosition)，这里按sim-phi音符会被隐藏
function official_format_hold_beats(_hold_time) {
	var beats = floor(real(_hold_time));
	if (!is_finite(beats)) then return 0;
	// 负数 floor 会离零更远，加一才是向零取整
	if (beats < 0) then beats += 1;
	return beats;
}

///@desc 把数值收成 float32
///@param {Real} _value 原始数值
///@returns {Real} float32 结果，非法时为 0
/// 作者的话: 官谱全是f32的，我的是f64的，不转轻松爆炸(Phira爆炸，sim-phi有自动夹断)，我跟你说，我写这个屎都夹不断，因为它太大了。。。
function official_f32(_value) {
	// 你知道我为什么用静态吗，我喜欢
	static float_buffer = (buffer_create(4, buffer_fixed, 1));
	if (!is_real(_value) || !is_finite(_value)) then return (false); // 我习惯用is_real，我没试过会不会爆
	buffer_poke(float_buffer, 0, buffer_f32, _value);
	
	// 我说了这里不buffer_delete你耳朵隆了吗
	return (buffer_peek(float_buffer, 0, buffer_f32));
};

///@desc 计算 sim-phi 的最大可见地板位置，音符保持到判定线越过它
///@param {Real} _value 地板位置
///@returns {Real} 可见上限
/// 作者的话: 依旧地板(floorPosition)
function official_max_visible_pos(_value) {
	static float_buffer = buffer_create(4, buffer_fixed, 1);
	buffer_poke(float_buffer, 0, buffer_f32, _value);
	var float_value = buffer_peek(float_buffer, 0, buffer_f32);
	if (is_nan(float_value) || abs(float_value) == infinity) then return float_value;
	var magic = 11718.75;
	var prime = (float_value >= magic ? power(2, floor(1 + log2(float_value / magic))) : 1);
	var candidate = (float_value / prime + 0.001);
	buffer_poke(float_buffer, 0, buffer_f32, candidate);
	var rounded = buffer_peek(float_buffer, 0, buffer_f32);
	// 舍入没有越过候选值就直接放大回去
	if (rounded <= candidate) then return rounded * prime;
	var bits = buffer_peek(float_buffer, 0, buffer_u32);
	buffer_poke(float_buffer, 0, buffer_u32, bits + (rounded <= 0 ? 1 : -1));
	return buffer_peek(float_buffer, 0, buffer_f32) * prime;
}

// sim-phi 用 Number(t)|0 截成 1/32 拍整数，导出不能带小数 tick
// floorPosition 是 float32 积分：从首事件起点秒数起，存 y 后再加上时长乘速度
// 负的首起点是 v1 预滚哨兵，夹到 0。重复运行结果相同，_line_floor 不使用
///@desc 按 sim-phi 预计算速度事件的地板位置
///@param {Array} _events 速度事件
///@param {Real} _seconds_per_beat 每拍秒数
///@param {Any} _line_floor 保留参数，不使用
///@returns {Array} 写好地板后的原数组
function official_prepare_speed_events(_events, _seconds_per_beat, _line_floor = undefined) {
	if (!is_array(_events) || array_length(_events) <= 0) then return _events;
	var spb = real(_seconds_per_beat);
	if (!(spb > 0) || !is_finite(spb)) then spb = 1.875 / 60;
	var count = array_length(_events);
	var floor_y = 0;
	var started = false;
	for (var speed_i = 0; speed_i < count; speed_i++) {
		var speed_event = _events[speed_i];
		if (!is_struct(speed_event)) then continue;
		var event_start = real(speed_event[$ "startTime"] ?? 0);
		var event_end = real(speed_event[$ "endTime"] ?? event_start);
		var event_value = real(speed_event[$ "value"] ?? 0);
		if (!is_finite(event_start)) then event_start = 0;
		// 只有第一条事件的负起点会被夹到 0
		if (!started && event_start < 0) then event_start = 0;
		if (!is_finite(event_end) || event_end < event_start) then event_end = event_start;
		if (!is_finite(event_value)) then event_value = 0;
		speed_event.startTime = event_start;
		speed_event.endTime = event_end;
		speed_event.value = event_value;
		if (!started) {
			floor_y = official_f32(event_start * spb);
			started = true;
		};
		speed_event.floorPosition = floor_y;
		floor_y = official_f32(floor_y + (event_end - event_start) * spb * event_value);
	};
	return _events;
}

// 游标停在第一个尚未结束的事件。空隙向前延伸该事件，末事件之后沿用最后速度
///@desc 查询某一拍上的判定线地板位置
///@param {Array} speed_events 已预处理的速度事件
///@param {Real} beat 拍数
///@param {Real} seconds_per_beat 每拍秒数
///@returns {Real} 地板位置
function official_floor_at_beat(speed_events, beat, seconds_per_beat) {
	if (!is_array(speed_events) || array_length(speed_events) <= 0) then return 0;
	var spb = real(seconds_per_beat);
	if (!(spb > 0) || !is_finite(spb)) then return 0;
	var sec = real(beat) * spb;
	if (!is_finite(sec)) then return 0;
	var count = 0;
	var event_count = array_length(speed_events);
	// 找到第一个结束时间还不早于当前秒的事件
	while (count < event_count - 1) {
		var speed_event = speed_events[count];
		if (!is_struct(speed_event)) then break;
		if (real(speed_event[$ "endTime"] ?? 0) * spb >= sec) then break;
		count++;
	};
	var chosen = speed_events[count];
	if (!is_struct(chosen)) then return 0;
	var start_sec = real(chosen[$ "startTime"] ?? 0) * spb;
	var floor0 = real(chosen[$ "floorPosition"] ?? 0);
	var value = real(chosen[$ "value"] ?? 0);
	if (!is_finite(start_sec)) then start_sec = 0;
	if (!is_finite(floor0)) then floor0 = 0;
	if (!is_finite(value)) then value = 0;
	return floor0 + (sec - start_sec) * value;
}

// 官方 Hold 头速度固定为 1，身体长度是 bodySpeed 乘秒数。速度 0 或空 Hold 不绘制
///@desc 把官方音符打包成带地板长度的结构
///@param {Struct} _note 原始音符
///@param {Bool} _above 是否在判定线上方
///@param {Real} _line_index 判定线序号
///@param {Real} _bpm 判定线 BPM
///@param {Real} _seconds_per_beat 每拍秒数
///@returns {Struct} 打包后的音符
function official_pack_note(_note, _above, _line_index, _bpm, _seconds_per_beat) {
	var chart_speed = real(_note[$ "speed"] ?? 1);
	if (!is_finite(chart_speed)) then chart_speed = 1;
	var hold_beats = 0;
	var head_speed = chart_speed;
	var body_speed = 1;
	var hold_floor = 0;
	// 只有 Hold 需要拆头速度和身体长度
	if (real(_note[$ "type"] ?? 0) == 3) {
		hold_beats = official_format_hold_beats(_note[$ "holdTime"] ?? 0);
		var hold_sec = hold_beats * _seconds_per_beat;
		body_speed = (chart_speed != 1) ? chart_speed : 1;
		head_speed = 1;
		if (chart_speed == 0 || hold_sec <= 0) {
			body_speed = 0;
			hold_beats = 0;
			hold_sec = 0;
		};
		hold_floor = body_speed * hold_sec;
		if (hold_floor < 0) then hold_floor = 0;
	};
	return {
		"type": _note.type,
		"time": _note.time,
		"holdTime": hold_beats,
		"holdFloorLength": hold_floor,
		"speed": head_speed,
		"bodySpeed": body_speed,
		"xOffset": _note.positionX,
		"yOffset": _note.floorPosition,
		"hl": false,
		"isAbove": _above,
		"id": _line_index,
		"bpm": _bpm
	};
}

///@desc 官谱运行时，负责读谱、排序、背景、配置与清理
///@returns {Struct} 构造出的 Phigros 实例
/// 作者的话: 刚开项目就写的
function Phigros() constructor { // 仅仅结构
	// 谱面&信息
	static chart = undefined;
	static version = 0;
	static line_list = [];
	// 播放时钟、暂停标记与音符缓存
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
	/// 作者的话: 古董
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
		"comboString" : "COMBO",				// 连击文本(default:"COMBO")
		"userName" : "Guest",					// 结算界面玩家名(default:"Guest")
		"enableVsync" : true,					// 是否启用垂直同步(default:true)
		"aa_level" : 0,							// aa_level等级(default:0)
		"useOldFX" : false,						// 是否使用旧版打击特效(default:false)
		"enableComboScore" : true,				// 是否启用打击分(default:true)
		"enableAutoPlay" : true,				// 是否启用自动游玩(default:true)
		"judgeOffset" : 0,						// 自动打击偏移延迟(default:0)
		"enableAccJudgment" : true,				// 是否启用Auto严肃判定(可能对其他格式的谱面无效)(default:true)
		"preventWindowMoveFreeze" : true,		// 拖动和缩放窗口时不阻塞
		"enableRPEMulticore" : true,			// 启用原生 RPE 帧工作线程
		"rpeWorkerMinLines" : 32,				// 原生并行解析所需的最少判定线数
		"rpeWorkerProfileFrames" : 1800,		// 两次工作线程计时日志之间平均的帧数
		"noteUniformScale" : false,				// RPE 的 size 与 sizeControl 也缩放高度
		"notePreloadSeconds" : 3,				// RPE/PEC 音符预加载秒数，范围 0 到 60，官谱忽略
		"disableChartShader" : false,			// 禁用谱面 Shader(default:false)
		"directGlslEs" : false,					// Windows 直接编译谱面 GLSL ES(default:false)
		"disableChartVideo" : false,			// 禁用谱面视频(default:false)
		"enableNoiseArea" : true,				// 是否启用噪区(default:true)
		"enableNoiseAreaFine" : false,			// 是否开启噪区精细(default:false)
		"reduceNoiseAreaWave" : false,			// 减少噪区起伏幅度(default:false)
		"TEST1" : false							// 判定偏移抖动测试(default false)
	};

	// 只抓一次基线，赶在 Configs 用 configs.ini 覆盖这份共享静态设置之前
	if (!variable_global_exists("phigros_settings_baseline") || !is_struct(global.phigros_settings_baseline)) {
		global.phigros_settings_baseline = {};
		var _settings_names = struct_get_names(settings);
		for (var _settings_i = 0; _settings_i < array_length(_settings_names); _settings_i++) {
			var _settings_key = _settings_names[_settings_i];
			global.phigros_settings_baseline[$ _settings_key] = settings[$ _settings_key];
		};
	};
	
	/// 必要的函数
	///@desc 把配置字符串转成数值，识别 true、false 与 undefined
	///@param {String} str 待转换文本
	///@param {Any} default_value 转换失败时的默认值
	///@returns {Any} 数值、未定义或默认值
	static strToReal = (func(str , default_value = undefined){
		if(string_lower(str) == "false") then return(0);
		if(string_lower(str) == "true") then return(1);
		if(string_lower(str) == "undefined") then return(undefined);
		try{ return(real(str)) }
		catch(e){ delete(e); return(default_value) };
	});
	
	///@desc 把数值布尔写成 true、false 或 undefined
	///@param {Any} _real 待转换值
	///@returns {String} 布尔文本
	static realToStrBool = (func(_real){
		if(!is_real(_real)) then return("undefined");
		if(bool(_real) == true) then return("true");
		else return("false");
	});
	
	///@desc 读取官谱 JSON，整理判定线并打包音符
	///@param {String} _chart 谱面路径，空则用默认文件
	///@param {Real} lmode 0 读文件，非 0 直接使用 chart_source
	///@param {Any} chart_source 已解析谱面，默认未定义
	///@returns {Bool} 成功为真
	static Reader = (func(_chart = "" , lmode = 0 , chart_source = undefined){
		// 切谱会反复调用，不能留下上一份谱面的音符引用
		if(instance_exists(oLine)) then with(oLine) instance_destroy();
		// 回放池里的音符是停用的，换谱前先激活再销毁
		instance_activate_object(oNote);
		if(instance_exists(oNote)) then with(oNote) instance_destroy();
		if(instance_exists(oEffectNew)) then with(oEffectNew) effect_events = [];
		self._notes = [];
		self.line_list = [];
		self.runtime_line_instances = [];
		self.runtime_note_instances = [];
		// 模式 0 从文件解析，否则直接接手已有结构
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
		// 只接受 1 到 3 的整数格式版本
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

			// v1 与 v2 的移动坐标是旧的打包或居中形式，v3 已归一化，Y 翻转在 oLine
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
			var line_seconds_per_beat = 1.875 / bpm;
			var line_floor = line_data[$ "floorPosition"];
			if (!is_real(line_floor) || !is_finite(line_floor)) then line_floor = undefined;
			official_prepare_speed_events(line_speed_events, line_seconds_per_beat, line_floor);
			for(var a = 0 ; a < array_length(line_data.notesAbove) ; a ++){
				var n = line_data.notesAbove[a];
				if (!is_struct(n)) then continue;
				array_add(self._notes, official_pack_note(n, true, i, bpm, line_seconds_per_beat));
			};
			
			for(var b = 0 ; b < array_length(line_data.notesBelow) ; b ++){
				var n = line_data.notesBelow[b];
				if (!is_struct(n)) then continue;
				array_add(self._notes, official_pack_note(n, false, i, bpm, line_seconds_per_beat));
			};
			//delete(self.chart.judgeLineList[i].notesAbove);
			//delete(self.chart.judgeLineList[i].notesBelow);
		};
		array_set(game.__time, 5, self.chart.offset * 1000000);
		print("[R-Chart] Done." , game.settings.enableDebug);
		return(true);
	});
	
	///@desc 按开始时间排序判定线事件，并标记同时落下的音符
	///@returns {Undefined} 无
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
		// 同一时刻的音符互相打上多押高亮
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
	
	///@desc 加载谱面背景，并按设置做模糊
	///@param {String} custom 背景路径，默认为空
	///@returns {Undefined} 无
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
		// 没有路径就丢掉旧背景
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

		// GM 2024 及以后 sprite_add 可能返回资源引用而不是实数，只用 asset_sprite_valid 检查
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
		// 直接加载失败时复制到缓存再试一次
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
			// 与 oLoadAnimator 的 Step 相同：文件路径、10 次、中心锚点
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

	///@desc 读取或创建 configs.ini，并把设置写回内存
	///@returns {Undefined} 无
	static Configs = (func(){
		var f = $"{working_directory}resource/configs.ini";
		//if(isExists(f)){
		ini_open(f);
		print($"str: {game.settings.comboString}");
		// 没有配置文件时写入默认资源和设置
		if(!isExists(f)){
			print("[F-Configs] No Found 'configs.ini' file" , game.settings.enableDebug);
			
			// 资源路径
			ini_write_string("Resource" , "note.tap" , $"{working_directory}resource/note_tap.png");
			ini_write_string("Resource" , "note.flick" , $"{working_directory}resource/note_flick.png");
			ini_write_string("Resource" , "note.drag" , $"{working_directory}resource/note_drag.png");
			ini_write_string("Resource" , "note.hold.head" , $"{working_directory}resource/hold_head.png");
			ini_write_string("Resource" , "note.hold.body" , $"{working_directory}resource/hold_body.png");
			ini_write_string("Resource" , "note.hold.end" , $"{working_directory}resource/hold_end.png");
			ini_write_string("Resource" , "font.ui" , pls_bundled_font_path());
			ini_write_string("Resource" , "effc.hit" , $"{working_directory}resource/effect.png");
			
			// 设置项
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
		// 只有没有自定义谱面会话时才读 Chart 段，避免 ini 默认值盖掉曲包信息
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
	
	///@desc 加载字体与配置，并套用当前谱面背景和显示设置
	///@returns {Undefined} 无
	static Resource = (func(){
		if(!asset_font_valid(self.font)){
			self.font = (pls_ui_font_add(47));
		};
		self.Configs();
		// 录像模式强制自动演奏，并套用渲染抗锯齿
		if (variable_global_exists("render_mode") && global.render_mode) {
			self.settings.aa_level = variable_global_exists("render_aa_level") ? global.render_aa_level : 8;
			self.settings.enableAutoPlay = true;
			print($"[Renderer] Anti-aliasing: {self.settings.aa_level}x MSAA");
		};
		//self.Img();
		// 优先用当前谱面会话的图片，不编造缺失的默认背景
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
	
	///@desc 释放背景、动态贴图和谱面实例
	///@param {Bool} full 是否连音符皮肤、字体和特效一起释放
	///@returns {Undefined} 无
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

		// line.csv 的贴图是动态创建的，不属于工程资源
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
		// 换谱或换房间时，停用的回放池也要一起清掉
		instance_activate_object(oNote);
		if(instance_exists(oNote)){
			with(oNote) instance_destroy();
		};
		
		
		
		// 完整清理才释放音符皮肤、字体和打击特效
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
		
		///@desc 把秒数换成谱面拍
		///@param {Real} bpm 每分钟拍数
		///@param {Real} rtime 秒数
		///@returns {Real} 拍数
		timer : (func(bpm , rtime){
			//print($"timer: {array_length(game.__time)}");
			return(rtime / (1.875 / bpm));
		}),
		
		///@desc 把谱面拍换成秒
		///@param {Real} bpm 每分钟拍数
		///@param {Real} ctime 拍数
		///@returns {Real} 秒数
		realTimer : (func(bpm , ctime){
			//print($"rtimer: {array_length(game.__time)}");
			return((ctime * 1.875) / bpm);
		}),
		
		///@desc 把当前微秒时钟写进指定时间槽
		///@param {Real} index 时间槽下标，默认为 1
		///@returns {Real} 写入的微秒时间
		now : (func(index = 1){
			//print($"now : {array_length(game.__time)}");
			var t = (get_timer());
			//game.__time[index] = t;
			array_set(game.__time , index , t);
			return(t);
		}),
		
		///@desc 计算扣除暂停后的谱面当前时间
		///@returns {Real} 微秒时间，录像模式返回帧时间的微秒值
		ctime : (func(){
			// 录像按帧号推进，不走真实时钟
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
		
		///@desc 计算当前时间在一段区间里的比例
		///@param {Real} _ntime 当前时间
		///@param {Real} _stime 区间起点
		///@param {Real} _etime 区间终点
		///@returns {Real} 0 到 1 附近的比例
		dtime : (func(_ntime , _stime , _etime){
			var _rdt = ((_ntime- _stime) / (_etime - _stime));
			//print($"dtimer: {array_length(game.__time)}");
			return(_rdt);
		}),
		
		///@desc 把本次暂停时长累加进暂停槽
		///@returns {Real} 本次暂停时长
		ptime : (func(){
			var time = (game.__time[4] - game.__time[2]);
			array_set(game.__time , 3 , game.__time[3] + time);	
			return(time);
		}),

		///@desc 按 float32 精度计算地板位置的最大可见值
		///@param {Real} value 地板位置
		///@returns {Real} 可见上限
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
			// 舍入没有越过候选值就直接放大回去
			if(rounded <= candidate) then return(rounded * prime);

			var bits = (buffer_peek(float_buffer, 0, buffer_u32));
			buffer_poke(float_buffer, 0, buffer_u32, bits + (rounded <= 0 ? 1 : -1));
			return(buffer_peek(float_buffer, 0, buffer_f32) * prime);
		}),
		
		///@desc 把格式 1 的打包坐标拆成格式 3 的归一化坐标
		///@param {Struct} pos_struct 含 start 与 end 的旧坐标
		///@returns {Any} 转换后的结构，字段缺失时未定义
		posCovert : (func(pos_struct){
			if((!struct_exists(pos_struct , "start")) || (!struct_exists(pos_struct , "end"))) then return(undefined);
			return({
				"start" : (round(pos_struct.start / 1000) / 880),
				"end" : (round(pos_struct[$ "end"] / 1000) / 880),
				"start2" : ((pos_struct.start % 1000) / 520),
				"end2" : ((pos_struct[$ "end"] % 1000) / 520)
			});
		}),
		
		///@desc 把格式 2 的居中坐标换成格式 3 的归一化坐标
		///@param {Struct} pos_struct 含 start、end、start2、end2
		///@returns {Any} 转换后的结构，字段缺失时未定义
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
	
	///@desc Phi小工具。官谱、RPE、PEC 之间转换。导出的 RPE 仍是 160。
	static PhiTool = {
		///@desc 转变音符类型
		///@param {Array} before_type_arr 原类型列表
		///@param {Array} after_type_arr 新类型列表，长度必须相同
		///@returns {Bool} 成功为真
		TrasformType : (function(before_type_arr , after_type_arr){
			if(is_array(after_type_arr) && is_array(before_type_arr)) {}
			else return(false);
			var lens = [
				array_length(before_type_arr),
				array_length(after_type_arr)
			];
			// 两组类型数量不一致就放弃
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
		
		///@desc 保存谱面
		///@param {String} path 输出路径
		///@returns {Bool} 是否写成功
		SaveTrack : (function(path){
			return chart_buffer_save_text(path, json_stringify(game.chart, true));
		}),
		
		///@desc 把官谱里被切成线性段的判定线事件拟合成 RPE 缓动，生成 RPE 谱。
		/// 不改 game.chart。META.RPEVersion = 160，走 1.7 之前的速度积分。
		///@returns {Bool} 成功为真
		FitEventsTrack : (function(){
			// 没有已加载的官谱就不能拟合
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
		///@param {String} path 输出路径，默认为空
		///@returns {Bool} 成功为真
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
		///@param {String} pec_text PEC 文本
		///@returns {Bool} 成功为真
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
		///@param {String} pec_text PEC 文本
		///@param {String} path 输出路径，默认为空
		///@returns {Bool} 成功为真
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
		}),

		///@desc PEC 文本 → 官谱。音符大小、透明度不写。缓动切成线性段。
		///@param {String} pec_text PEC 文本
		///@returns {Bool} 成功为真
		PecToOfficial : (function(pec_text){
			if (!is_string(pec_text) || !string_length(pec_text)) then return false;
			var built = phi_pec_to_official(pec_text);
			if (!is_struct(built)) then return false;
			self.officialStats = built[$ "stats"];
			variable_struct_remove(built, "stats");
			self.officialChart = built;
			var stats = self.officialStats;
			if (is_struct(stats)) then phi_tools_event_report(stats);
			return true;
		}),

		///@desc 导出官谱。路径为空时写到当前谱面目录的 Chart_PEC_Official.json。
		///@param {String} pec_text PEC 文本
		///@param {String} path 输出路径，默认为空
		///@returns {Bool} 成功为真
		ExportPecOfficial : (function(pec_text, path = ""){
			if (!self.PecToOfficial(pec_text)) then return false;
			if (!is_string(path) || !string_length(path)) {
				var root = working_directory;
				if (variable_global_exists("InChartPath") && is_string(InChartPath) && string_length(InChartPath)) then root = InChartPath;
				path = chart_path_join(root, "Chart_PEC_Official.json");
			};
			chart_buffer_save_text(path, phi_official_json_text(self.officialChart, true));
			show_debug_message($"[PhiTool] Wrote PEC as official: {path}");
			return true;
		}),

		///@desc RPE 谱面（struct 或 JSON 文本）→ 官谱。
		/// RPEVersion >= 170 用 1.7 的速度积分，更早的版本用旧表。父线会烘进绝对位置。
		///@param {Any} rpe_chart RPE 结构或 JSON 文本
		///@returns {Bool} 成功为真
		RpeToOfficial : (function(rpe_chart){
			var parsed = phi_rpe_chart_value(rpe_chart);
			if (!is_struct(parsed)) then return false;
			var built = phi_rpe_to_official(parsed);
			if (!is_struct(built)) then return false;
			self.officialStats = built[$ "stats"];
			variable_struct_remove(built, "stats");
			self.officialChart = built;
			var stats = self.officialStats;
			if (is_struct(stats)) then phi_tools_event_report(stats);
			return true;
		}),

		///@desc 导出官谱。路径为空时写到当前谱面目录的 Chart_RPE_Official.json。
		///@param {Any} rpe_chart RPE 结构或 JSON 文本
		///@param {String} path 输出路径，默认为空
		///@returns {Bool} 成功为真
		ExportRpeOfficial : (function(rpe_chart, path = ""){
			if (!self.RpeToOfficial(rpe_chart)) then return false;
			if (!is_string(path) || !string_length(path)) {
				var root = working_directory;
				if (variable_global_exists("InChartPath") && is_string(InChartPath) && string_length(InChartPath)) then root = InChartPath;
				path = chart_path_join(root, "Chart_RPE_Official.json");
			};
			chart_buffer_save_text(path, phi_official_json_text(self.officialChart, true));
			show_debug_message($"[PhiTool] Wrote RPE as official: {path}");
			return true;
		}),

		///@desc RPE 谱面 → PEC 文本。速度仍按 RPEVersion 选择积分，结果写成 cv。
		///@param {Any} rpe_chart RPE 结构或 JSON 文本
		///@returns {Bool} 成功为真
		RpeToPec : (function(rpe_chart){
			var parsed = phi_rpe_chart_value(rpe_chart);
			if (!is_struct(parsed)) then return false;
			var built = phi_rpe_to_pec(parsed);
			if (!is_struct(built) || !is_string(built[$ "text"])) then return false;
			self.pecStats = built[$ "stats"];
			self.pecText = built.text;
			var stats = self.pecStats;
			if (is_struct(stats)) then phi_tools_event_report(stats);
			return true;
		}),

		///@desc 导出 PEC。路径为空时写到当前谱面目录的 Chart_RPE.pec。
		///@param {Any} rpe_chart RPE 结构或 JSON 文本
		///@param {String} path 输出路径，默认为空
		///@returns {Bool} 成功为真
		ExportRpePec : (function(rpe_chart, path = ""){
			if (!self.RpeToPec(rpe_chart)) then return false;
			if (!is_string(path) || !string_length(path)) {
				var root = working_directory;
				if (variable_global_exists("InChartPath") && is_string(InChartPath) && string_length(InChartPath)) then root = InChartPath;
				path = chart_path_join(root, "Chart_RPE.pec");
			};
			chart_buffer_save_text(path, self.pecText);
			show_debug_message($"[PhiTool] Wrote RPE as PEC: {path}");
			return true;
		})
	};
	
	
	///@desc 创建判定线（同步路径：录像模式。交互加载走 official_lines_begin/pump/finish）
	///@returns {Undefined} 无
	static CreateLines = (func(){
		official_lines_begin();
		// 抽干同步创建队列
		while (!official_lines_pump(0)) {};
		official_lines_finish();
		
	});
	
	
	print($"[Initional] Done." , self.settings.enableDebug);
	//});
};

// buffer_string 会在最后一个 UTF-8 字节上放 NUL，buffer_save 又会写出整块分配
// 这里多写一个 ASCII 字节，保存时丢掉它，避免末字损坏
///@desc 把文本按 UTF-8 写入文件且不破坏最后一个字符
///@param {String} path 输出路径
///@param {String} text 文本内容
///@returns {Bool} 恒为真
function chart_buffer_save_text(path, text) {
	var body = is_string(text) ? text : string(text);
	var payload = body + " ";
	var bytes = string_byte_length(payload);
	if (bytes < 1) then bytes = 1;
	var buff = buffer_create(bytes, buffer_fixed, 1);
	buffer_write(buff, buffer_text, payload);
	var wrote = buffer_tell(buff);
	// 丢掉多写的那个牺牲字节
	if (wrote > 0) then wrote -= 1;
	if (wrote < 0) then wrote = 0;
	buffer_save_ext(buff, path, 0, wrote);
	buffer_delete(buff);
	return true;
}

///@desc 用辗转相除求两个数的最大公约数
///@param {Real} a 整数
///@param {Real} b 整数
///@returns {Real} 正的最大公约数，至少为 1
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

// 官方 tick 是该线自己 BPM 上的 1/32 拍。谱面拍等于 tick * chartBPM / (lineBPM * 32)
// 分数保持精确，硬套 32 网格会在 BPM 不能整除时缩短 Hold
///@desc 把判定线 tick 换成谱面拍数组
///@param {Real} tick 判定线 tick
///@param {Real} line_bpm 判定线 BPM
///@param {Real} chart_bpm 谱面 BPM
///@returns {Array} 小节、分子与分母
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
	// 非整数 BPM 时退回 32 分网格
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

///@desc 取出现最多的判定线 BPM，平局保留更早的线
///@param {Array} lines 判定线数组
///@returns {Real} 谱面 BPM，没有有效值时为 120
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
			array_add(seen_bpm, bpm);
			array_add(seen_count, 1);
			found = array_length(seen_bpm) - 1;
		} else {
			seen_count[found] = seen_count[found] + 1;
		};
		// 只在次数严格更多时替换，平局留在更早的 BPM
		if (seen_count[found] > best_count) {
			best_count = seen_count[found];
			best_bpm = seen_bpm[found];
		};
	};
	if (!(best_bpm > 0)) then return 120;
	return best_bpm;
}

///@desc 把实数拍收成 32 分音符数组
///@param {Real} beats 拍数
///@returns {Array} 小节、分子与分母 32
function phi_beats_to_array(beats) {
	var value = real(beats);
	if (!is_finite(value)) then value = 0;
	var bar = floor(value);
	var num = round((value - bar) * 32);
	// 分子满 32 就进一小节
	if (num >= 32) {
		bar += 1;
		num = 0;
	};
	if (num < 0) then num = 0;
	return [bar, num, 32];
}

///@desc 比较两个官谱事件的时间，供排序使用
///@param {Struct} a 事件
///@param {Struct} b 事件
///@returns {Real} 负数、零或正数
function phi_official_event_cmp(a, b) {
	var start_delta = real(a.startTime) - real(b.startTime);
	// 起点相同再比终点
	if (start_delta != 0) then return start_delta;
	return real(a.endTime) - real(b.endTime);
}

///@desc 读取事件起点值，通道 1 用第二轴
///@param {Struct} ev 事件
///@param {Real} channel 0 为第一轴，1 为第二轴
///@returns {Real} 起点值
function phi_event_start_value(ev, channel) {
	if (channel == 1) then return real(ev[$ "start2"] ?? 0);
	if (is_real(ev[$ "start"])) then return real(ev.start);
	return real(ev[$ "value"] ?? 0);
}

///@desc 读取事件终点值，通道 1 用第二轴
///@param {Struct} ev 事件
///@param {Real} channel 0 为第一轴，1 为第二轴
///@returns {Real} 终点值
function phi_event_end_value(ev, channel) {
	if (channel == 1) then return real(ev[$ "end2"] ?? ev[$ "start2"] ?? 0);
	if (is_real(ev[$ "end"])) then return real(ev[$ "end"]);
	return real(ev[$ "value"] ?? phi_event_start_value(ev, channel));
}

// 缓出烘焙有时会提前一格写成终点。只有真正的平台才截掉，过松的误差会切掉高阶缓出尾巴
///@desc 去掉采样末尾与终点相同的平台
///@param {Array} values 采样值
///@param {Real} i0 起点下标
///@param {Real} i1 终点下标
///@returns {Real} 截断后的终点下标
function phi_trim_end(values, i0, i1) {
	if (i1 - i0 < 2) then return i1;
	var final_v = values[i1];
	var eps = max(0.00000001, abs(final_v) * 0.00000001);
	var i = i1;
	// 从终点往回吃掉数值几乎不变的点
	while (i > i0 + 1 && abs(values[i - 1] - final_v) <= eps) i--;
	return i;
}

///@desc 组装一段拟合后的缓动事件
///@param {Real} t0 起点时间
///@param {Real} t1 终点时间
///@param {Real} v0 起点值
///@param {Real} v1 终点值
///@param {Real} ease 缓动类型
///@param {Real} left 缓动窗口左端，默认 0
///@param {Real} right 缓动窗口右端，默认 1
///@desc 组装一段拟合后的缓动事件
///@returns {Struct} 事件结构
function phi_fit_event(t0, t1, v0, v1, ease, left = 0, right = 1) {
	return { t0: t0, t1: t1, v0: v0, v1: v1, ease: ease, left: left, right: right };
}

// 序号越小曲线越简单。接近平局时留简单缓动，避免烘焙噪声把四次推成五次
///@desc 给缓动类型一个简单程度序号
///@param {Real} ease_type 缓动类型
///@returns {Real} 序号，未知类型为 100
function phi_ease_rank(ease_type) {
	static ease_rank = [0, 0, 1, 2, 4, 5, 3, 6, 7, 8, 15, 16, 9, 17, 18, 19, 13, 14, 10, 11, 20, 21, 12, 22, 26, 27, 23, 24, 25, 28];
	var index = floor(real(ease_type));
	if (index < 1 || index >= array_length(ease_rank)) then return 100;
	return ease_rank[index];
}

// 超过平均步长若干倍的区间本身就是直线，两端采样点不描述中间
///@desc 计算一段采样里算作宽空隙的时间阈值
///@param {Array} times 时间采样
///@param {Real} i0 起点下标
///@param {Real} i1 终点下标
///@returns {Real} 阈值，区间无效时为 -1
function phi_wide_gap_limit(times, i0, i1) {
	var gaps = i1 - i0;
	if (gaps < 1) then return -1;
	return (times[i1] - times[i0]) / gaps * 2.5;
}

///@desc 判断采样区间里是否有超长直线空隙
///@param {Array} times 时间采样
///@param {Real} i0 起点下标
///@param {Real} i1 终点下标
///@returns {Bool} 有宽空隙为真
function phi_span_has_wide_gap(times, i0, i1) {
	var wide = phi_wide_gap_limit(times, i0, i1);
	if (!(wide > 0)) then return false;
	for (var gap_i = i0; gap_i < i1; gap_i++) {
		if (times[gap_i + 1] - times[gap_i] > wide) then return true;
	};
	return false;
}

// 误差是采样与缓动之差除以起终点幅度。端点天然重合
// stride 在搜长度时跳过中间点。长直切片内部不看结点，回弹类可能两端过关却离开直线
///@desc 计算一种缓动相对采样的归一化误差
///@param {Array} times 时间采样
///@param {Array} values 数值采样
///@param {Real} i0 起点下标
///@param {Real} i1 终点下标
///@param {Real} ease_type 缓动类型
///@param {Real} stride 采样步长
///@param {Bool} check_gaps 是否检查宽空隙，默认假
///@desc 计算一种缓动相对采样的归一化误差
///@returns {Real} 归一化误差
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
		// 误差已经超过 5% 就不必再采样
		if (err > 0.05) then return err;
	};
	if (!check_gaps || err > 0.05) then return err;
	var wide = phi_wide_gap_limit(times, i0, i1);
	if (!(wide > 0)) then return err;
	for (var gap_i = i0; gap_i < i1; gap_i++) {
		var g0 = times[gap_i];
		var g1 = times[gap_i + 1];
		var gap_t = g1 - g0;
		// 宽空隙内部按八等分比较缓动和直线
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

///@desc 在 1 到 29 号缓动里选误差最小且尽量简单的一种
///@param {Array} times 时间采样
///@param {Array} values 数值采样
///@param {Real} i0 起点下标
///@param {Real} i1 终点下标
///@param {Real} stride 采样步长
///@param {Bool} check_gaps 是否检查宽空隙，默认假
///@returns {Struct} 含 ease 与 err
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
	// 误差接近时改用更简单的缓动
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

// 没有任何 1 到 29 号整段缓动能把误差压进 1.2% 时返回未定义，含长直线的弦
// 平直段是一条线性事件。离开再回来的起伏不算一种缓动
///@desc 判断整段采样能否用一种缓动拟合
///@param {Array} times 时间采样
///@param {Array} values 数值采样
///@param {Real} i0 起点下标
///@param {Real} i1 终点下标
///@param {Bool} verify 为真时逐步验证，否则抽稀
///@returns {Any} 成功为含 ease 与 err 的结构，否则未定义
function phi_ease_fits(times, values, i0, i1, verify) {
	if (i1 - i0 < 5) then return undefined;
	var v0 = values[i0];
	var v1 = values[i1];
	var scale = abs(v1 - v0);
	// 几乎不动的段，偏差够小就当成线性
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

// 找 [i0, i1] 里最长的一段完整缓动。缓出的开头本身不是缓出，短长度允许失败
// 先加长到命中，再二分最后一次成功的采样。过稀的候选会漏掉衔接，旧拟合就把每格写成线性
///@desc 从起点找出最长的一段完整缓动
///@param {Array} times 时间采样
///@param {Array} values 数值采样
///@param {Real} i0 起点下标
///@param {Real} i1 终点下标
///@returns {Any} 成功为含 end_at、ease、err 的结构，否则未定义
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
		// 在最后一次成功和第一次失败之间二分
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

///@desc 把一段采样切成缓动事件，拟合失败的格子保持线性
///@param {Array} times 时间采样
///@param {Array} values 数值采样
///@param {Real} i0 起点下标
///@param {Real} i1 终点下标
///@param {Real} depth 递归深度保留参数
///@returns {Array} 拟合事件
function phi_fit_piece(times, values, i0, i1, depth) {
	var out = [];
	var cursor = i0;
	var guard = 0;
	if (depth < 0) then depth = 0;
	// 从左向右吞掉能拟合的最长缓动
	while (cursor < i1 && guard < 100000) {
		guard++;
		var trimmed = phi_trim_end(values, cursor, i1);
		var has_tail = (times[trimmed] < times[i1] - 0.000000001);
		if (trimmed <= cursor) {
			if (has_tail) then array_add(out, phi_fit_event(times[cursor], times[i1], values[cursor], values[i1], 1));
			break;
		};
		if (trimmed - cursor < 5) {
			for (var linear_i = cursor; linear_i < trimmed; linear_i++) {
				array_add(out, phi_fit_event(times[linear_i], times[linear_i + 1], values[linear_i], values[linear_i + 1], 1));
			};
			if (has_tail) then array_add(out, phi_fit_event(times[trimmed], times[i1], values[trimmed], values[i1], 1));
			break;
		};
		var found = phi_longest_ease(times, values, cursor, trimmed);
		if (!is_struct(found)) {
			array_add(out, phi_fit_event(times[cursor], times[cursor + 1], values[cursor], values[cursor + 1], 1));
			cursor += 1;
			continue;
		};
		var end_at = found.end_at;
		array_add(out, phi_fit_event(times[cursor], times[end_at], values[cursor], values[end_at], found.ease));
		cursor = end_at;
	};
	return out;
}

///@desc 合并首尾相接且斜率相同的线性事件
///@param {Array} events 拟合事件
///@returns {Array} 合并后的事件
function phi_merge_linear(events) {
	var out = [];
	for (var i = 0; i < array_length(events); i++) {
		var ev = events[i];
		var count = array_length(out);
		if (count > 0) {
			var prev = out[count - 1];
			// 相邻线性段首尾相接时尝试按斜率合并
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
		array_add(out, {
			t0: ev.t0, t1: ev.t1, v0: ev.v0, v1: ev.v1, ease: ev.ease,
			left: real(ev[$ "left"] ?? 0), right: real(ev[$ "right"] ?? 1)
		});
	};
	return out;
}

// 通道 0 读 start/end，通道 1 读 start2/end2。速度事件不从这里进
///@desc 把一条官谱事件通道拟合成 RPE 缓动
///@param {Array} events 官谱事件
///@param {Real} channel 坐标轴通道
///@returns {Array} 拟合事件
function phi_fit_channel(events, channel) {
	var fitted = [];
	if (!is_array(events)) then return fitted;
	var evs = [];
	for (var copy_i = 0; copy_i < array_length(events); copy_i++) {
		var src = events[copy_i];
		if (!is_struct(src) || !is_real(src[$ "startTime"]) || !is_real(src[$ "endTime"])) then continue;
		array_add(evs, src);
	};
	if (array_length(evs) <= 0) then return fitted;
	array_sort(evs, phi_official_event_cmp);
	var n = array_length(evs);
	var index = 0;
	while (index < n) {
		var head = evs[index];
		var head_dt = head.endTime - head.startTime;
		if (head_dt <= 0) {
			array_add(fitted, phi_fit_event(head.startTime, head.endTime, phi_event_start_value(head, channel), phi_event_end_value(head, channel), 1));
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
		// 少量长关键帧就是官谱本身，不是烘焙缓动。均匀片段够多才开始拟合曲线
		if (end_index - index < 5) {
			for (var raw_i = index; raw_i < end_index; raw_i++) {
				var raw_ev = evs[raw_i];
				array_add(fitted, phi_fit_event(raw_ev.startTime, raw_ev.endTime, phi_event_start_value(raw_ev, channel), phi_event_end_value(raw_ev, channel), 1));
			};
		} else {
			var times = [head.startTime];
			var values = [phi_event_start_value(head, channel)];
			for (var build_i = index; build_i < end_index; build_i++) {
				array_add(times, evs[build_i].endTime);
				array_add(values, phi_event_end_value(evs[build_i], channel));
			};
			var piece = phi_fit_piece(times, values, 0, array_length(times) - 1, 0);
			for (var piece_i = 0; piece_i < array_length(piece); piece_i++) array_add(fitted, piece[piece_i]);
		};
		index = end_index;
	};
	return phi_merge_linear(fitted);
}

///@desc 把拟合值换成 RPE 单位并写成拍时间
///@param {Array} fitted 拟合事件
///@param {String} kind x、y、r、a 或 s
///@param {Real} line_bpm 判定线 BPM
///@param {Real} chart_bpm 谱面 BPM
///@returns {Array} RPE 事件
function phi_scale_events(fitted, kind, line_bpm, chart_bpm) {
	var out = [];
	for (var i = 0; i < array_length(fitted); i++) {
		var ev = fitted[i];
		var v0 = ev.v0;
		var v1 = ev.v1;
		// x/y 从归一化换成编辑器像素，旋转取反，透明度和速度放大
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
		array_add(out, {
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

///@desc 把官谱速度事件换成恒定的 RPE 速度
///@param {Array} events 速度事件
///@param {Real} line_bpm 判定线 BPM
///@param {Real} chart_bpm 谱面 BPM
///@returns {Array} RPE 速度事件
function phi_convert_speed(events, line_bpm, chart_bpm) {
	var out = [];
	if (!is_array(events)) then return out;
	var evs = [];
	for (var i = 0; i < array_length(events); i++) {
		var src = events[i];
		if (!is_struct(src) || !is_real(src[$ "startTime"]) || !is_real(src[$ "endTime"])) then continue;
		array_add(evs, src);
	};
	array_sort(evs, phi_official_event_cmp);
	for (var speed_i = 0; speed_i < array_length(evs); speed_i++) {
		var ev = evs[speed_i];
		// 官谱速度乘 4.5 后起终点相同，缓动保持线性
		var _speed = real(ev[$ "value"] ?? ev[$ "start"] ?? 0) * 4.5;
		array_add(out, {
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

///@desc 把官谱音符追加进 RPE 音符列表
///@param {Array} notes 目标列表
///@param {Array} list 上方或下方音符
///@param {Real} above 1 为线上方
///@param {Real} line_bpm 判定线 BPM
///@param {Real} chart_bpm 谱面 BPM
///@param {Array} speed_events 已预处理的速度事件
///@returns {Undefined} 无
function phi_push_official_notes(notes, list, above, line_bpm, chart_bpm, speed_events) {
	if (!is_array(list)) then return;
	var spb = 1.875 / line_bpm;
	if (!(spb > 0) || !is_finite(spb)) then spb = 1.875 / 60;
	for (var i = 0; i < array_length(list); i++) {
		var note = list[i];
		if (!is_struct(note)) then continue;
		var off_type = floor(real(note[$ "type"] ?? 1));
		var rpe_type = 1;
		// 官谱 2/3/4 对应 RPE 的 Flick、Hold、Drag
		if (off_type == 2) then rpe_type = 4;
		else if (off_type == 3) then rpe_type = 2;
		else if (off_type == 4) then rpe_type = 3;
		var start_tick = real(note[$ "time"] ?? 0);
		var hold_tick = 0;
		var note_speed = real(note[$ "speed"] ?? 1);
		if (!is_finite(note_speed)) then note_speed = 1;
		var note_alpha = 255;
		if (off_type == 3) {
			// 官谱头速度为 1，身体不跟随判定线。RPE 头身共用一个速度
			// 按这段地板行程缩放，使身体长度仍等于 bodySpeed 乘时长；线不动则保持原速度
			hold_tick = official_format_hold_beats(note[$ "holdTime"] ?? 0);
			var hold_sec = hold_tick * spb;
			var body_speed = (note_speed != 1) ? note_speed : 1;
			if (note_speed == 0 || hold_sec <= 0) {
				note_speed = 0;
				note_alpha = 0;
				hold_tick = 0;
			} else {
				var body_floor = body_speed * hold_sec;
				var integral = official_floor_at_beat(speed_events, start_tick + hold_tick, spb) - official_floor_at_beat(speed_events, start_tick, spb);
				if (abs(integral) <= 0.0000001) then note_speed = body_speed;
				else note_speed = body_floor / integral;
			};
		};
		array_add(notes, {
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

///@desc 统计非线性缓动事件的数量
///@param {Array} events 拟合事件
///@returns {Real} 非 1 号缓动的个数
function phi_count_eased(events) {
	var eased = 0;
	for (var i = 0; i < array_length(events); i++) {
		if (events[i].ease != 1) then eased++;
	};
	return eased;
}

// 把切碎的移动、旋转、透明度拟回 RPE 缓动，速度保持线性
// 均匀片段取误差 1.2% 内最长的 1 到 29 号整段缓动。长直线按弦计分
// 短关键帧保持线性，不用局部缓动窗口。META.RPEVersion 为 160，走 1.7 前速度表，不写 PGRVersion
///@desc 把官谱转换成 RPE 160 谱面
///@param {Struct} chart 官谱
///@returns {Any} RPE 谱面，无效输入为未定义
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
		var speed_play = [];
		for (var speed_copy_i = 0; speed_copy_i < array_length(speed_src); speed_copy_i++) {
			var speed_copy_src = speed_src[speed_copy_i];
			if (!is_struct(speed_copy_src)) then continue;
			var speed_copy = {};
			var speed_names = struct_get_names(speed_copy_src);
			for (var speed_name_i = 0; speed_name_i < array_length(speed_names); speed_name_i++) {
				speed_copy[$ speed_names[speed_name_i]] = speed_copy_src[$ speed_names[speed_name_i]];
			};
			array_add(speed_play, speed_copy);
		};
		array_sort(speed_play, phi_official_event_cmp);
		var line_floor = _line[$ "floorPosition"];
		if (!is_real(line_floor) || !is_finite(line_floor)) then line_floor = undefined;
		official_prepare_speed_events(speed_play, 1.875 / line_bpm, line_floor);
		var move_x = phi_fit_channel(move_src, 0);
		var move_y = phi_fit_channel(move_src, 1);
		var rotate = phi_fit_channel(rotate_src, 0);
		var alpha = phi_fit_channel(alpha_src, 0);
		var _speed = phi_convert_speed(speed_play, line_bpm, chart_bpm);
		eased_events += phi_count_eased(move_x) + phi_count_eased(move_y) + phi_count_eased(rotate) + phi_count_eased(alpha);
		rpe_move_x += array_length(move_x);
		rpe_move_y += array_length(move_y);
		rpe_rotate += array_length(rotate);
		rpe_alpha += array_length(alpha);
		out_events += array_length(move_x) + array_length(move_y) + array_length(rotate) + array_length(alpha) + array_length(_speed);
		var notes = [];
		phi_push_official_notes(notes, _line[$ "notesAbove"], 1, line_bpm, chart_bpm, speed_play);
		phi_push_official_notes(notes, _line[$ "notesBelow"], 0, line_bpm, chart_bpm, speed_play);
		// 时间已经是谱面拍，线速因子保持 1，再乘一次会把这条线放快一倍
		array_add(judge, {
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

///@desc 把实数拍收成约分后的 RPE 拍数组
///@param {Real} beat 拍数
///@returns {Array} 小节、分子与分母
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
	// 负数写成上一小节加剩余分子，避免负分子
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

///@desc 用拍时间组装一条 RPE 事件
///@param {Real} t0 起点拍
///@param {Real} t1 终点拍
///@param {Real} v0 起点值
///@param {Real} v1 终点值
///@param {Real} ease 缓动类型
///@returns {Struct} RPE 事件
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

///@desc 比较两段 PEC 区间，供排序使用
///@param {Struct} a 含 startBeat、endBeat、order
///@param {Struct} b 含 startBeat、endBeat、order
///@returns {Real} 负数、零或正数
function phi_pec_cmp_span(a, b) {
	var span_cmp = pec_cmp_real(a.startBeat, b.startBeat);
	// 起点相同再比终点和写入顺序
	if (span_cmp != 0) then return span_cmp;
	span_cmp = pec_cmp_real(a.endBeat, b.endBeat);
	if (span_cmp != 0) then return span_cmp;
	return pec_cmp_real(a.order, b.order);
}

///@desc 比较两个 PEC 拍点，供排序使用
///@param {Struct} a 含 beat 与 order
///@param {Struct} b 含 beat 与 order
///@returns {Real} 负数、零或正数
function phi_pec_cmp_beat(a, b) {
	var beat_cmp = pec_cmp_real(a.beat, b.beat);
	if (beat_cmp != 0) then return beat_cmp;
	return pec_cmp_real(a.order, b.order);
}

///@desc 建立一条 PEC 判定线的事件桶
///@returns {Struct} speed、move、rotate、alpha 四个空数组
function phi_pec_line_bucket() {
	return { speed: [], move: [], rotate: [], alpha: [] };
}

// PEC 原点在 2048x1400 左下，RPE 原点在 1350x900 视图中心且 Y 向上
///@desc 把 PEC 文件横坐标换成 RPE 编辑器单位
///@param {Real} file_x PEC 横坐标
///@returns {Real} RPE 横坐标
function phi_pec_rpe_x(file_x) {
	return 1350 * (real(file_x) / 2048 - 0.5);
}

///@desc 把 PEC 文件纵坐标换成 RPE 编辑器单位
///@param {Real} file_y PEC 纵坐标
///@returns {Real} RPE 纵坐标
function phi_pec_rpe_y(file_y) {
	var norm_y = 1 - real(file_y) / 1400;
	return 900 * (0.5 - norm_y);
}

///@desc 按 BPM 时间轴把秒换成拍
///@param {Array} timeline BPM 时间轴
///@param {Real} sec 秒
///@returns {Real} 拍数
function phi_pec_sec_to_beat(timeline, sec) {
	if (!is_array(timeline) || array_length(timeline) <= 0) then return 0;
	if (sec <= timeline[0].second) then return timeline[0].beat;
	// 二分找到不晚于该秒的最后一个 BPM 点
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

///@desc 由 BPM 变化建立带绝对秒数的时间轴
///@param {Array} bpm_raw BPM 事件
///@returns {Array} 含 beat、bpm、order、second
function phi_pec_build_timeline(bpm_raw) {
	var list = [];
	if (is_array(bpm_raw)) {
		for (var bpm_i = 0; bpm_i < array_length(bpm_raw); bpm_i++) {
			var src = bpm_raw[bpm_i];
			if (!is_struct(src)) then continue;
			var bpm = real(src[$ "bpm"] ?? 60);
			if (!(bpm > 0) || !is_finite(bpm)) then bpm = 60;
			array_add(list, { beat: real(src[$ "beat"] ?? 0), bpm: bpm, order: real(src[$ "order"] ?? bpm_i), second: 0 });
		};
	};
	if (array_length(list) <= 0) then array_add(list, { beat: 0, bpm: 60, order: 0, second: 0 });
	array_sort(list, phi_pec_cmp_beat);
	// 同一拍只保留后写入的 BPM
	var collapsed = [];
	for (var collapse_i = 0; collapse_i < array_length(list); collapse_i++) {
		var item = list[collapse_i];
		var count = array_length(collapsed);
		if (count > 0 && abs(collapsed[count - 1].beat - item.beat) <= 0.0000001) {
			collapsed[count - 1] = item;
		} else {
			array_add(collapsed, item);
		};
	};
	collapsed[0].second = 0;
	for (var second_i = 1; second_i < array_length(collapsed); second_i++) {
		var previous = collapsed[second_i - 1];
		collapsed[second_i].second = previous.second + (collapsed[second_i].beat - previous.beat) * 60 / max(0.0001, previous.bpm);
	};
	return collapsed;
}

// cv 一直持续到下一条。PhiEditor 变速（|speed/7| >= 1000）段内不推音符，下一条 cv 才跳地板
///@desc 判断 PEC 播放速度是否为瞬间变速
///@param {Real} playback_value 播放速度
///@returns {Bool} 绝对值达到 1000 为真
function pec_speed_is_warp(playback_value) {
	return abs(phi_finite_or(playback_value, 0)) >= 1000;
}
///@desc 把 PEC 速度事件换成 RPE 速度，瞬间变速收成短跳变
///@param {Array} raw PEC 速度事件
///@param {Array} timeline BPM 时间轴
///@returns {Array} RPE 速度事件
function phi_pec_speed_to_rpe(raw, timeline) {
	var out = [];
	if (!is_array(raw) || array_length(raw) <= 0) then return out;
	var evs = [];
	for (var raw_i = 0; raw_i < array_length(raw); raw_i++) {
		var src = raw[raw_i];
		if (!is_struct(src)) then continue;
		array_add(evs, src);
	};
	if (array_length(evs) <= 0) then return out;
	array_sort(evs, phi_pec_cmp_beat);
	if (abs(evs[0].beat) > 0.00001) {
		var shifted = [{ beat: 0, value: 0, order: -1 }];
		for (var shift_i = 0; shift_i < array_length(evs); shift_i++) array_add(shifted, evs[shift_i]);
		evs = shifted;
	};
	var kept = [];
	for (var keep_i = 0; keep_i < array_length(evs); keep_i++) {
		var keep_count = array_length(kept);
		if (keep_count > 0 && abs(kept[keep_count - 1].beat - evs[keep_i].beat) <= 0.0000001) {
			kept[keep_count - 1] = evs[keep_i];
		} else {
			array_add(kept, evs[keep_i]);
		};
	};
	for (var speed_i = 0; speed_i < array_length(kept); speed_i++) {
		var ev = kept[speed_i];
		var pec_speed = real(ev.value) / 7;
		if (!is_finite(pec_speed)) then pec_speed = 0;
		var beat = real(ev.beat);
		var last = (speed_i >= array_length(kept) - 1);
		if (last) {
			var tail = pec_speed_is_warp(pec_speed) ? 0 : pec_speed * 4.5;
			array_add(out, phi_pec_rpe_event(beat, beat + 1, tail, tail, 1));
			continue;
		};
		var next_beat = real(kept[speed_i + 1].beat);
		if (next_beat <= beat) then continue;
		// 普通速度整段保持，瞬间变速则大部分时间为 0、末尾跳一下
		if (!pec_speed_is_warp(pec_speed)) {
			var held = pec_speed * 4.5;
			array_add(out, phi_pec_rpe_event(beat, next_beat, held, held, 1));
			continue;
		};
		var t0 = pec_beat_to_sec(timeline, beat);
		var t1 = pec_beat_to_sec(timeline, next_beat);
		var dur = t1 - t0;
		var spike = 0.001;
		if (!(dur > spike * 2)) {
			var short_speed = pec_speed * 4.5;
			array_add(out, phi_pec_rpe_event(beat, next_beat, short_speed, short_speed, 1));
			continue;
		};
		var hold_beat = phi_pec_sec_to_beat(timeline, t0 + dur - spike);
		if (hold_beat <= beat || hold_beat >= next_beat) {
			var fallback = pec_speed * 4.5;
			array_add(out, phi_pec_rpe_event(beat, next_beat, fallback, fallback, 1));
			continue;
		};
		array_add(out, phi_pec_rpe_event(beat, hold_beat, 0, 0, 1));
		var jump = pec_speed * dur / spike * 4.5;
		array_add(out, phi_pec_rpe_event(hold_beat, next_beat, jump, jump, 1));
	};
	return out;
}

///@desc 把 PEC 移动事件拆成 RPE 的 X 和 Y
///@param {Array} raw PEC 移动事件
///@returns {Struct} 含 x、y 与 count
function phi_pec_move_to_rpe(raw) {
	var move_x = [];
	var move_y = [];
	// 没有移动时停在 PEC 左下角
	if (!is_array(raw) || array_length(raw) <= 0) {
		array_add(move_x, phi_pec_rpe_event(0, 1, phi_pec_rpe_x(0), phi_pec_rpe_x(0), 1));
		array_add(move_y, phi_pec_rpe_event(0, 1, phi_pec_rpe_y(1400), phi_pec_rpe_y(1400), 1));
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
		array_add(move_x, phi_pec_rpe_event(ev.startBeat, ev.endBeat, phi_pec_rpe_x(prev_x), phi_pec_rpe_x(x1), ease));
		array_add(move_y, phi_pec_rpe_event(ev.startBeat, ev.endBeat, phi_pec_rpe_y(prev_y), phi_pec_rpe_y(y1), ease));
		prev_x = x1;
		prev_y = y1;
	};
	return { x: move_x, y: move_y, count: array_length(raw) };
}

///@desc 把 PEC 的旋转或透明度写成从上一个值过渡的 RPE 事件
///@param {Array} raw PEC 事件
///@param {String} kind rotate 或 alpha
///@returns {Struct} 含 events 与 count
function phi_pec_scalar_to_rpe(raw, kind) {
	var out = [];
	if (!is_array(raw)) then raw = [];
	if (array_length(raw) <= 0) {
		if (kind == "alpha") then array_add(out, phi_pec_rpe_event(0, 1, 255, 255, 1));
		return { events: out, count: 0 };
	};
	array_sort(raw, phi_pec_cmp_span);
	var previous = 0;
	for (var scalar_i = 0; scalar_i < array_length(raw); scalar_i++) {
		var ev = raw[scalar_i];
		var target = real(ev.target);
		if (!is_finite(target)) then target = previous;
		var ease = real(ev[$ "ease"] ?? 1);
		array_add(out, phi_pec_rpe_event(ev.startBeat, ev.endBeat, previous, target, ease));
		previous = target;
	};
	// 第一条透明度晚于 0 拍时，前面补一段完全不透明
	if (kind == "alpha" && array_length(out) > 0 && real(raw[0].startBeat) > 0.0000001) {
		var held = [phi_pec_rpe_event(0, raw[0].startBeat, 255, 255, 1)];
		for (var hold_i = 0; hold_i < array_length(out); hold_i++) array_add(held, out[hold_i]);
		out = held;
	};
	return { events: out, count: array_length(raw) };
}

///@desc 把一条 PEC 音符换成 RPE 音符
///@param {Struct} note PEC 音符
///@returns {Struct} RPE 音符
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

///@desc 按 pec_reader_load 的方式解析 PEC，数值保持文件单位
///@param {String} pec_text PEC 文本
///@returns {Any} 解析结果，无效时未定义
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
	// 逐行识别 bp、音符和判定线命令
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
			array_add(bpm_list, { beat: number(tokens[1], 0), bpm: max(0.0001, number(tokens[2], 60)), order: order_n });
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
		while (array_length(line_buckets) <= line_id) array_add(line_buckets, phi_pec_line_bucket());
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
			array_add(note_list, {
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
				if (array_length(tokens) >= 4) then array_add(bucket.speed, { beat: number(tokens[2], 0), value: number(tokens[3], 0), order: order_n });
			break;
			case "cp":
				if (array_length(tokens) >= 5) then array_add(bucket.move, { startBeat: number(tokens[2], 0), endBeat: number(tokens[2], 0), x: number(tokens[3], 0), y: number(tokens[4], 0), ease: 1, order: order_n });
			break;
			case "cm":
				if (array_length(tokens) >= 7) then array_add(bucket.move, { startBeat: number(tokens[2], 0), endBeat: number(tokens[3], 0), x: number(tokens[4], 0), y: number(tokens[5], 0), ease: number(tokens[6], 1), order: order_n });
			break;
			case "cd":
				if (array_length(tokens) >= 4) then array_add(bucket.rotate, { startBeat: number(tokens[2], 0), endBeat: number(tokens[2], 0), target: number(tokens[3], 0), ease: 1, order: order_n });
			break;
			case "cr":
				if (array_length(tokens) >= 6) then array_add(bucket.rotate, { startBeat: number(tokens[2], 0), endBeat: number(tokens[3], 0), target: number(tokens[4], 0), ease: number(tokens[5], 1), order: order_n });
			break;
			case "ca":
				if (array_length(tokens) >= 4) then array_add(bucket.alpha, { startBeat: number(tokens[2], 0), endBeat: number(tokens[2], 0), target: number(tokens[3], 0), ease: 1, order: order_n });
			break;
			case "cf":
				if (array_length(tokens) >= 5) {
					// pec_reader_load 会把这段淡化强制成线性，这里保留文件里的缓动
					var cf_ease = (array_length(tokens) >= 6) ? number(tokens[5], 1) : 1;
					array_add(bucket.alpha, { startBeat: number(tokens[2], 0), endBeat: number(tokens[3], 0), target: number(tokens[4], 0), ease: cf_ease, order: order_n });
				};
			break;
		};
		order_n++;
	};
	// 没有任何命令就不是有效 PEC
	if (!saw_command) then return undefined;
	return {
		offsetMs: offset_ms,
		bpmList: bpm_list,
		lines: line_buckets,
		notes: note_list
	};
}

// META.RPEVersion 为 160，播放用 1.7 前速度表，除数 4.5 与这里一致
// 音符 X 为 fileX * 75.375 / 115.2，速度为 fileSpeed * 4.5 / 7。播放器多出来的 -0.175 秒不写进 offset
///@desc 把 PEC 文本转换成 RPE 谱面
///@param {String} pec_text PEC 文本
///@param {Any} meta 曲目信息，默认未定义时读当前会话
///@returns {Any} RPE 谱面，解析失败为未定义
function phi_pec_to_rpe(pec_text, meta = undefined) {
	var parsed = phi_pec_parse(pec_text);
	if (!is_struct(parsed)) then return undefined;
	var timeline = phi_pec_build_timeline(parsed.bpmList);
	var chart_bpm = real(timeline[0].bpm);
	if (!(chart_bpm > 0)) then chart_bpm = 60;
	var bpm_out = [];
	for (var bpm_i = 0; bpm_i < array_length(timeline); bpm_i++) {
		array_add(bpm_out, {
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
			array_add(parsed.lines, phi_pec_line_bucket());
			line_count++;
		};
	};
	for (var empty_i = 0; empty_i < array_length(parsed.lines); empty_i++) array_add(notes_by_line, []);
	array_sort(parsed.notes, function(a, b) {
		var note_cmp = pec_cmp_real(a.startBeat, b.startBeat);
		if (note_cmp != 0) then return note_cmp;
		return pec_cmp_real(a.order, b.order);
	});
	for (var place_i = 0; place_i < array_length(parsed.notes); place_i++) {
		var placed = parsed.notes[place_i];
		var placed_line = floor(real(placed[$ "lineId"] ?? 0));
		if (placed_line < 0 || placed_line >= array_length(notes_by_line)) then continue;
		array_add(notes_by_line[placed_line], phi_pec_note_to_rpe(placed));
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
		array_add(judge, {
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

// 每条非线性事件只切成这么多线性段，不要再乘上其他事件的结点，否则嵌套切割停不下来
#macro PHI_EASE_SLICES 16
// 采样用的最小时间间隙
#macro PHI_SAMPLE_EPS 0.00000005

// 结点前的固定空隙可能已经落进下一段，空隙要按那段起点采样再拉回来
///@desc 取一段结束前一点点的采样时间
///@param {Real} t0 起点时间
///@param {Real} t1 终点时间
///@returns {Real} 不早于起点的探测时间
function phi_probe_before(t0, t1) {
	var back = max(PHI_SAMPLE_EPS, (t1 - t0) * 0.001);
	var probe = t1 - back;
	if (probe <= t0) then return t0;
	return probe;
}

///@desc 取有限实数，否则用后备值
///@param {Any} value 候选值
///@param {Real} fallback 后备值
///@returns {Real} 有限实数
function phi_finite_or(value, fallback) {
	var n = real(value);
	if (!is_finite(n)) then return fallback;
	return n;
}

///@desc 把数值四舍五入到小数点后六位
///@param {Real} value 数值
///@returns {Real} 六位小数
function phi_round6(value) {
	return round(phi_finite_or(value, 0) * 1000000) / 1000000;
}

///@desc 把数值格式化成不带多余零的文本
///@param {Real} value 数值
///@returns {String} 数字文本
function phi_num_text(value) {
	var v = phi_round6(value);
	if (abs(v) < 0.0000005) then v = 0;
	var text = string_trim(string_format(v, 0, 6));
	var dot = string_pos(".", text);
	// 去掉小数末尾多余的 0 和点
	while (dot > 0 && string_length(text) > dot && string_char_at(text, string_length(text)) == "0") {
		text = string_copy(text, 1, string_length(text) - 1);
	}
	if (string_length(text) > 0 && string_char_at(text, string_length(text)) == ".") {
		text = string_copy(text, 1, string_length(text) - 1);
	}
	if (!string_length(text) || text == "-") then return "0";
	return text;
}

///@desc 在指定时间采样一条事件
///@param {Struct} ev 事件
///@param {Real} t 时间
///@returns {Real} 采样值
function phi_sample_event(ev, t) {
	if (t <= ev.t0) then return ev.v0;
	if (t >= ev.t1 || ev.t0 == ev.t1 || ev.v0 == ev.v1) then return ev.v1;
	// 贝塞尔按曲线纵坐标插值，其余走缓动
	if (ev.bezier) {
		var p = (t - ev.t0) / (ev.t1 - ev.t0);
		return ev.v0 + (ev.v1 - ev.v0) * phi_bezier_y(ev.pts, p);
	}
	return tween_execute(t, ev.t0, ev.t1, ev.v0, ev.v1, ev.ease, ev.e0, ev.e1);
}

///@desc 把非线性事件展开成固定段数的线性片段
///@param {Array} events 事件列表
///@returns {Array} 展开后的线性事件
function phi_expand_channel(events) {
	var out = [];
	if (!is_array(events)) then return out;
	var pieces = PHI_EASE_SLICES;
	for (var i = 0; i < array_length(events); i++) {
		var ev = events[i];
		var dur = ev.t1 - ev.t0;
		if (ev.linear || !(dur > 0.0000001)) {
			array_add(out, ev);
			continue;
		}
		var prev_t = ev.t0;
		var prev_v = ev.v0;
		// 按固定段数采样，最后一段钉在终点
		for (var s = 1; s <= pieces; s++) {
			var t = ev.t0 + dur * (s / pieces);
			var v = (s == pieces) ? ev.v1 : phi_sample_event(ev, t);
			array_add(out, {
				t0: prev_t, t1: t, v0: prev_v, v1: v,
				ease: 1, e0: 0, e1: 1, bezier: false, pts: ev.pts, linear: true
			});
			prev_t = t;
			prev_v = v;
		}
	}
	return out;
}

///@desc 把秒换成该 BPM 下的 1/32 拍 tick
///@param {Real} sec 秒
///@param {Real} bpm 每分钟拍数
///@returns {Real} tick
function phi_sec_to_tick(sec, bpm) {
	var rate = phi_finite_or(bpm, 140);
	if (!(rate > 0)) then rate = 140;
	return phi_finite_or(sec, 0) * rate / 60 * 32;
}

///@desc 把 RPE 的 BPM 列表收成带绝对秒数的时间轴
///@param {Array} bpm_list BPM 列表
///@returns {Array} 含起点拍、终点拍、BPM 与累计秒
function phi_bpm_timeline(bpm_list) {
	var tmp = [];
	if (is_array(bpm_list)) {
		for (var i = 0; i < array_length(bpm_list); i++) {
			var entry = bpm_list[i];
			if (!is_struct(entry)) then continue;
			var beat = rpe_array_to_beat(entry[$ "startTime"] ?? entry[$ "beat"] ?? 0);
			var bpm = phi_finite_or(entry[$ "bpm"] ?? 140, 140);
			if (!(bpm > 0)) then bpm = 140;
			array_add(tmp, { beat: beat, bpm: bpm, order: i });
		}
	}
	if (array_length(tmp) <= 0) then array_add(tmp, { beat: 0, bpm: 140, order: 0 });
	array_sort(tmp, function(a, b) {
		var cmp = pec_cmp_real(a.beat, b.beat);
		if (cmp != 0) then return cmp;
		return pec_cmp_real(a.order, b.order);
	});
	var collapsed = [];
	for (var j = 0; j < array_length(tmp); j++) {
		var item = tmp[j];
		var count = array_length(collapsed);
		// 同一拍只保留后出现的 BPM
		if (count > 0 && abs(collapsed[count - 1].beat - item.beat) <= 0.0000001) {
			collapsed[count - 1] = item;
		} else array_add(collapsed, item);
	}
	var timeline = [];
	var floor_sec = 0;
	for (var k = 0; k < array_length(collapsed); k++) {
		var start_beat = collapsed[k].beat;
		var bpm_value = collapsed[k].bpm;
		var end_beat = infinity;
		if (k < array_length(collapsed) - 1) then end_beat = collapsed[k + 1].beat;
		array_add(timeline, { startBeat: start_beat, endBeat: end_beat, bpm: bpm_value, floorSec: floor_sec });
		if (is_finite(end_beat)) then floor_sec += (end_beat - start_beat) * 60 / bpm_value;
	}
	return timeline;
}

///@desc 二分查找拍所在的时间轴分段
///@param {Array} timeline 时间轴
///@param {Real} beat 拍数
///@returns {Real} 分段下标
function phi_timeline_index_beat(timeline, beat) {
	var low = 0;
	var high = array_length(timeline);
	// 找最后一个起点不晚于该拍的分段
	while (low < high) {
		var mid = (low + high) >> 1;
		if (timeline[mid].startBeat <= beat) then low = mid + 1;
		else high = mid;
	}
	return max(0, low - 1);
}

///@desc 按时间轴把拍换成秒
///@param {Array} timeline 时间轴
///@param {Real} beat 拍数
///@returns {Real} 秒
function phi_timeline_beat_to_sec(timeline, beat) {
	if (!is_array(timeline) || array_length(timeline) <= 0) then return 0;
	var value = phi_finite_or(beat, 0);
	var seg = timeline[phi_timeline_index_beat(timeline, value)];
	return seg.floorSec + (value - seg.startBeat) * 60 / max(0.0001, seg.bpm);
}

///@desc 二分查找秒所在的时间轴分段
///@param {Array} timeline 时间轴
///@param {Real} sec 秒
///@returns {Real} 分段下标
function phi_timeline_index_sec(timeline, sec) {
	var low = 0;
	var high = array_length(timeline);
	while (low < high) {
		var mid = (low + high) >> 1;
		if (timeline[mid].floorSec <= sec) then low = mid + 1;
		else high = mid;
	}
	return max(0, low - 1);
}

///@desc 按时间轴把秒换成拍
///@param {Array} timeline 时间轴
///@param {Real} sec 秒
///@returns {Real} 拍数
function phi_timeline_sec_to_beat(timeline, sec) {
	if (!is_array(timeline) || array_length(timeline) <= 0) then return 0;
	var value = phi_finite_or(sec, 0);
	var seg = timeline[phi_timeline_index_sec(timeline, value)];
	return seg.startBeat + (value - seg.floorSec) * seg.bpm / 60;
}

///@desc 从元数据读取宽高比，非法时用 16:9
///@param {Struct} meta 谱面元数据
///@returns {Real} 宽高比
function phi_chart_aspect_of(meta) {
	var aspect = 16 / 9;
	if (is_struct(meta)) then aspect = chart_parse_aspect_ratio(meta[$ "aspectRatio"] ?? meta[$ "aspect_ratio"], 16 / 9);
	if (!(aspect > 0) || !is_finite(aspect)) then return 16 / 9;
	return aspect;
}

// 与 rpe_speed_slice_integral 相同，170 前后的差别由 legacy 传入，菜单转换不读 game_1.version
///@desc 计算一段速度事件在比例 p 处的地板积分
///@param {Bool} legacy 是否用 1.7 之前的速度表
///@param {Real} v0 起点速度
///@param {Real} v1 终点速度
///@param {Real} duration 时长
///@param {Real} p 0 到 1 的进度
///@param {Real} easing 缓动类型
///@param {Real} left 缓动窗口左端
///@param {Real} right 缓动窗口右端
///@desc 计算一段速度事件在比例 p 处的地板积分
///@returns {Real} 地板位移
function phi_speed_integral(legacy, v0, v1, duration, p, easing, left, right) {
	if (!(p > 0) || !(duration > 0.000000001)) then return 0;
	if (easing == 1) then return ((v1 - v0) * p * p * 0.5 + v0 * p) * duration;
	// 旧表直接套用，新表用辛普森积分
	if (legacy) then return rpe_speed_legacy_slice(v0, v1, duration, p, easing, left, right);
	var h = p / 20;
	var f0 = rpe_ease_value(easing, left);
	var range = right - left;
	var denom = rpe_ease_value(easing, right) - f0;
	var integral = 0;
	if (abs(denom) >= 0.000000000000001) {
		var sum = (rpe_ease_value(easing, range * p + left) - f0) / denom;
		sum += (rpe_ease_value(easing, left) - f0) / denom;
		for (var odd_i = 1; odd_i < 20; odd_i += 2) {
			sum += ((rpe_ease_value(easing, odd_i * h * range + left) - f0) / denom) * 4;
		}
		for (var even_i = 2; even_i < 19; even_i += 2) {
			var sample = (rpe_ease_value(easing, even_i * h * range + left) - f0) / denom;
			sum += sample + sample;
		}
		integral = sum * h / 3;
	}
	return ((v1 - v0) * integral + v0 * p) * duration;
}

///@desc 求三次贝塞尔在横坐标 p 处的纵坐标
///@param {Array} points 两个控制点的 x、y
///@param {Real} p 横向进度
///@returns {Real} 纵坐标
function phi_bezier_y(points, p) {
	var x1 = phi_finite_or(points[0], 0);
	var y1 = phi_finite_or(points[1], 0);
	var x2 = phi_finite_or(points[2], 0);
	var y2 = phi_finite_or(points[3], 0);
	var tt = clamp(p, 0, 1);
	// 牛顿法把横向进度反解成曲线参数
	for (var k = 0; k < 5; k++) {
		var u = 1 - tt;
		var xx = 3 * u * u * tt * x1 + 3 * u * tt * tt * x2 + tt * tt * tt;
		var dx = 3 * u * u * x1 + 6 * u * tt * (x2 - x1) + 3 * tt * tt * (1 - x2);
		if (abs(dx) < 0.000001) then break;
		tt -= (xx - p) / dx;
		tt = clamp(tt, 0, 1);
	}
	var uu = 1 - tt;
	return 3 * uu * uu * tt * y1 + 3 * uu * tt * tt * y2 + tt * tt * tt;
}

///@desc 把 RPE 事件预处理成以秒计的采样结构
///@param {Array} raw 原始事件
///@param {Array} timeline BPM 时间轴
///@returns {Array} 按时间排序的事件
function phi_prep_events(raw, timeline) {
	var tmp = [];
	if (!is_array(raw)) then return tmp;
	for (var i = 0; i < array_length(raw); i++) {
		var ev = raw[i];
		if (!is_struct(ev)) then continue;
		var st = phi_timeline_beat_to_sec(timeline, rpe_array_to_beat(ev[$ "startTime"] ?? 0));
		var et = phi_timeline_beat_to_sec(timeline, rpe_array_to_beat(ev[$ "endTime"] ?? ev[$ "startTime"] ?? 0));
		var v0 = phi_finite_or(ev[$ "start"] ?? 0, 0);
		var v1 = phi_finite_or(ev[$ "end"] ?? v0, v0);
		if (et < st) {
			et = st;
			v0 = v1;
		}
		var ease = rpe_map_easing_id(ev[$ "easingType"] ?? 1);
		var e0 = phi_finite_or(ev[$ "easingLeft"] ?? 0, 0);
		var e1 = phi_finite_or(ev[$ "easingRight"] ?? 1, 1);
		// 缓动窗口非法时退回整段 0 到 1
		if (e0 == e1 || e0 < 0 || e0 > 1 || e1 < 0 || e1 > 1) {
			e0 = 0;
			e1 = 1;
		}
		var pts = ev[$ "bezierPoints"];
		var bezier = bool(ev[$ "bezier"] ?? 0) && is_array(pts) && array_length(pts) >= 4;
		var linear = (abs(v1 - v0) <= 0.0000001) || (!bezier && ease <= 1);
		array_add(tmp, {
			t0: st, t1: et, v0: v0, v1: v1, ease: ease, e0: e0, e1: e1,
			bezier: bezier, pts: bezier ? pts : [0, 0, 0, 0], linear: linear
		});
	}
	array_sort(tmp, function(a, b) {
		var cmp = pec_cmp_real(a.t0, b.t0);
		if (cmp != 0) then return cmp;
		return pec_cmp_real(a.t1, b.t1);
	});
	return tmp;
}

///@desc 在指定秒采样预处理事件
///@param {Array} events 预处理事件
///@param {Real} t 秒
///@param {Real} empty_value 没有事件时的值
///@returns {Real} 采样值
function phi_eval_prepared(events, t, empty_value) {
	var n = array_length(events);
	if (n <= 0) then return empty_value;
	if (t < events[0].t0) then return events[0].v0;
	var idx = 0;
	// 跳过已经结束的事件
	while (idx < n && events[idx].t1 <= t) idx++;
	if (idx >= n) then return events[n - 1].v1;
	var ev = events[idx];
	if (t < ev.t0) {
		if (idx > 0) then return events[idx - 1].v1;
		return ev.v0;
	}
	if (ev.t0 == ev.t1 || ev.v0 == ev.v1) then return ev.v1;
	var p = (t - ev.t0) / (ev.t1 - ev.t0);
	if (ev.bezier) then return ev.v0 + (ev.v1 - ev.v0) * phi_bezier_y(ev.pts, p);
	return tween_execute(t, ev.t0, ev.t1, ev.v0, ev.v1, ev.ease, ev.e0, ev.e1);
}

///@desc 把各事件层同一通道在该秒的值相加
///@param {Array} layers 事件层
///@param {String} key 通道名
///@param {Real} t 秒
///@param {Real} empty_value 没有任何事件时的值
///@returns {Real} 合计值
function phi_layers_sum(layers, key, t, empty_value) {
	var sum = 0;
	var any = false;
	for (var i = 0; i < array_length(layers); i++) {
		var events = layers[i][$ key];
		if (!is_array(events) || array_length(events) <= 0) then continue;
		any = true;
		sum += phi_eval_prepared(events, t, 0);
	}
	if (!any) then return empty_value;
	return sum;
}

///@desc 判断时间区间里是否有非线性事件
///@param {Array} events 预处理事件
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@returns {Bool} 有非线性事件为真
function phi_list_eased(events, t0, t1) {
	if (!is_array(events)) then return false;
	for (var i = 0; i < array_length(events); i++) {
		var ev = events[i];
		if (ev.t1 <= t0 + 0.0000001) then continue;
		if (ev.t0 >= t1 - 0.0000001) then continue;
		// 与区间重叠的非线性事件就算需要切片
		if (!ev.linear) then return true;
	}
	return false;
}

///@desc 判断各层某一通道在区间里是否有非线性事件
///@param {Array} layers 事件层
///@param {String} key 通道名
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@returns {Bool} 有非线性事件为真
function phi_layers_eased(layers, key, t0, t1) {
	for (var i = 0; i < array_length(layers); i++) {
		if (phi_list_eased(layers[i][$ key], t0, t1)) then return true;
	}
	return false;
}

///@desc 把原始速度事件收成以拍计的起止速度
///@param {Array} raw 原始速度事件
///@returns {Array} 速度事件
function phi_speed_beats_from_raw(raw) {
	var out = [];
	if (!is_array(raw)) then return out;
	for (var i = 0; i < array_length(raw); i++) {
		var ev = raw[i];
		if (!is_struct(ev)) then continue;
		var st = rpe_array_to_beat(ev[$ "startTime"] ?? 0);
		var et = rpe_array_to_beat(ev[$ "endTime"] ?? ev[$ "startTime"] ?? 0);
		var v0 = phi_finite_or(ev[$ "start"] ?? 0, 0);
		var v1 = phi_finite_or(ev[$ "end"] ?? v0, v0);
		array_add(out, {
			startTime: st, endTime: et, start: v0, stop: v1,
			easingType: floor(phi_finite_or(ev[$ "easingType"] ?? 1, 1)),
			easingLeft: phi_finite_or(ev[$ "easingLeft"] ?? 0, 0),
			easingRight: phi_finite_or(ev[$ "easingRight"] ?? 1, 1)
		});
	}
	if (array_length(out) > 1) then array_sort(out, rpe_event_time_cmp);
	return out;
}

// 9999 一类的爆发常常只有一小段拍。空隙若沿用该值，后面的音符会被甩出屏幕
// 爆发本身保留，空隙改成速度 0
///@desc 把极端速度后面的空隙改成静止
///@param {Array} events 以拍计的速度事件
///@returns {Array} 补过空隙的事件
function phi_drop_extreme_speed_gaps(events) {
	var out = [];
	var n = array_length(events);
	for (var i = 0; i < n; i++) {
		if (i > 0) {
			var prev = events[i - 1];
			var gap = events[i].startTime - prev.endTime;
			// 前一段速度绝对值达到 100 时，空隙不再继承它
			if (gap > 0.0005 && abs(prev.stop) >= 100) {
				array_add(out, {
					startTime: prev.endTime,
					endTime: events[i].startTime,
					start: 0,
					stop: 0,
					easingType: 1,
					easingLeft: 0,
					easingRight: 1
				});
			}
		}
		array_add(out, events[i]);
	}
	return out;
}

///@desc 按 1.7 前的规则把多层速度合成带地板的片段
///@param {Array} beat_layers 各层以拍计的速度
///@param {Array} timeline BPM 时间轴
///@returns {Array} 以秒计的速度片段
function phi_build_legacy_speed(beat_layers, timeline) {
	var speed_layers = [];
	var speed_splits = [];
	for (var sli = 0; sli < array_length(beat_layers); sli++) {
		var raw_layer = beat_layers[sli];
		if (!is_array(raw_layer) || array_length(raw_layer) <= 0) then continue;
		var speed_layer = rpe_legacy_truncate_speed(raw_layer);
		if (array_length(speed_layer) <= 0) then continue;
		array_add(speed_layers, speed_layer);
		for (var sei = 0; sei < array_length(speed_layer); sei++) {
			array_add(speed_splits, speed_layer[sei].startTime);
			array_add(speed_splits, speed_layer[sei].endTime);
		}
	}
	if (array_length(speed_splits) <= 0) then return [];
	array_sort(speed_splits, pec_cmp_real);
	var fitted_speed = [];
	for (var ssi = 0; ssi < array_length(speed_splits) - 1; ssi++) {
		var split_start = speed_splits[ssi];
		var split_end = speed_splits[ssi + 1];
		if (split_start == split_end) then continue;
		var value_start = 0;
		var value_end = 0;
		for (var sli2 = 0; sli2 < array_length(speed_layers); sli2++) {
			value_start += rpe_legacy_speed_value(speed_layers[sli2], split_start, false);
			value_end += rpe_legacy_speed_value(speed_layers[sli2], split_end, true);
		}
		array_add(fitted_speed, { startTime: split_start, endTime: split_end, start: value_start, stop: value_end });
	}
	var segments = [];
	var speed_floor = 0;
	var fitted_count = array_length(fitted_speed);
	for (var fsi = 0; fsi < fitted_count; fsi++) {
		var fitted = fitted_speed[fsi];
		var sample_start_sec = phi_timeline_beat_to_sec(timeline, fitted.startTime);
		if (!is_finite(sample_start_sec)) then continue;
		var sample_end_sec = phi_timeline_beat_to_sec(timeline, fitted.endTime);
		if (fsi < fitted_count - 1) {
			var next_start_sec = phi_timeline_beat_to_sec(timeline, fitted_speed[fsi + 1].startTime);
			if (is_finite(next_start_sec) && next_start_sec > sample_start_sec) then sample_end_sec = next_start_sec;
		}
		if (!is_finite(sample_end_sec) || sample_end_sec <= sample_start_sec) then continue;
		var v0 = real(fitted.start) / 4.5;
		var v1 = real(fitted.stop) / 4.5;
		array_add(segments, {
			startTime: sample_start_sec, endTime: sample_end_sec,
			value: v0, endValue: v1, floorPosition: speed_floor
		});
		speed_floor += (sample_end_sec - sample_start_sec) * (v0 + v1) * 0.5;
	}
	// 最后一段之后播放会保持末速度。没有这条尾巴，斜坡会按平均值继续积分，后面的音符会漂
	if (array_length(segments) > 0) {
		var last_speed_ev = segments[array_length(segments) - 1];
		var last_end_value = real(last_speed_ev.endValue);
		if (is_finite(last_speed_ev.endTime) && is_finite(last_end_value)) {
			array_add(segments, {
				startTime: last_speed_ev.endTime,
				endTime: infinity,
				value: last_end_value,
				endValue: last_end_value,
				floorPosition: speed_floor
			});
		}
	}
	return segments;
}

///@desc 按 1.7 速度积分建立一层现代速度
///@param {Array} events 以拍计的速度事件
///@param {Array} timeline BPM 时间轴
///@returns {Any} 速度层，空输入为未定义
function phi_build_modern_layer(events, timeline) {
	if (!is_array(events) || array_length(events) <= 0) then return undefined;
	var built = [];
	var acc = 0;
	var prev_end = 0;
	var prev_value = phi_finite_or(events[0].start, 0);
	for (var ei = 0; ei < array_length(events); ei++) {
		var src = events[ei];
		var start_sec = phi_timeline_beat_to_sec(timeline, src.startTime);
		var end_sec = phi_timeline_beat_to_sec(timeline, src.endTime);
		if (!is_finite(start_sec) || !is_finite(end_sec)) then continue;
		var v0 = phi_finite_or(src.start, 0);
		var v1 = phi_finite_or(src.stop, v0);
		var easing = phi_finite_or(src.easingType, 1);
		var left = phi_finite_or(src.easingLeft, 0);
		var right = phi_finite_or(src.easingRight, 1);
		array_add(built, {
			startSec: start_sec, endSec: end_sec, v0: v0, v1: v1,
			easingType: easing, easingLeft: left, easingRight: right,
			prevEnd: prev_end, prevValue: prev_value, floorBefore: acc
		});
		// 空隙沿用上一段末速度，事件内走新积分
		if (start_sec > prev_end) then acc += (start_sec - prev_end) * prev_value / 4.5;
		var duration = end_sec - start_sec;
		if (duration > 0.000000001) then acc += phi_speed_integral(false, v0, v1, duration, 1, easing, left, right) / 4.5;
		prev_value = v1;
		prev_end = end_sec;
	}
	if (array_length(built) <= 0) then return undefined;
	return { events: built, tailEnd: prev_end, tailSpeed: prev_value, tailFloor: acc };
}

///@desc 查询现代速度层在某秒的地板
///@param {Struct} layer 速度层
///@param {Real} t 秒
///@returns {Real} 地板位置
function phi_modern_floor_at(layer, t) {
	if (!is_struct(layer)) then return 0;
	var events = layer.events;
	if (!is_array(events)) then return 0;
	var n = array_length(events);
	if (n <= 0 || !is_finite(t)) then return 0;
	var lo = 0;
	while (lo < n && events[lo].startSec < t && events[lo].endSec < t) lo++;
	// 超过最后一段后按末速度延伸
	if (lo >= n) then return layer.tailFloor + (t - layer.tailEnd) * layer.tailSpeed / 4.5;
	var ev = events[lo];
	var acc = ev.floorBefore;
	if (ev.startSec > ev.prevEnd) {
		var gap_end = min(ev.startSec, t);
		if (gap_end > ev.prevEnd) then acc += (gap_end - ev.prevEnd) * ev.prevValue / 4.5;
	}
	if (ev.startSec >= t) then return acc;
	var duration = ev.endSec - ev.startSec;
	if (duration > 0.000000001) {
		var p = (min(ev.endSec, t) - ev.startSec) / duration;
		acc += phi_speed_integral(false, ev.v0, ev.v1, duration, p, ev.easingType, ev.easingLeft, ev.easingRight) / 4.5;
	}
	return acc;
}

///@desc 按旧表或现代层查询模型地板
///@param {Struct} model 速度模型
///@param {Real} t 秒
///@returns {Real} 地板位置
function phi_model_floor(model, t) {
	if (model.legacy) then return rpe_legacy_floor_at(model.legacySegments, t);
	var sum = 0;
	var layers = model.modern;
	for (var i = 0; i < array_length(layers); i++) sum += phi_modern_floor_at(layers[i], t);
	return sum;
}

///@desc 判断区间内速度是否在变化
///@param {Struct} model 速度模型
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@returns {Bool} 起止速度不同为真
function phi_speed_span_varies(model, t0, t1) {
	if (model.legacy) {
		var segments = model.legacySegments;
		for (var i = 0; i < array_length(segments); i++) {
			var seg = segments[i];
			if (seg.endTime <= t0 + 0.0000001) then continue;
			if (seg.startTime >= t1 - 0.0000001) then continue;
			if (abs(seg.value - seg.endValue) > 0.00001) then return true;
		}
		return false;
	}
	var layers = model.modern;
	for (var li = 0; li < array_length(layers); li++) {
		var events = layers[li].events;
		for (var ei = 0; ei < array_length(events); ei++) {
			var ev = events[ei];
			if (ev.endSec <= t0 + 0.0000001) then continue;
			if (ev.startSec >= t1 - 0.0000001) then continue;
			if (abs(ev.v0 - ev.v1) > 0.00001) then return true;
		}
	}
	return false;
}

///@desc 合并并排序区间内的时间结点，去掉重复
///@param {Array} extra 额外时间
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@returns {Array} 去重后的时间
function phi_knots_unique(extra, t0, t1) {
	var raw = [t0, t1];
	for (var i = 0; i < array_length(extra); i++) {
		if (!is_real(extra[i])) then continue;
		var t = phi_finite_or(extra[i], t0);
		if (t < t0) then t = t0;
		if (t > t1) then t = t1;
		array_add(raw, t);
	}
	array_sort(raw, pec_cmp_real);
	var out = [];
	for (var j = 0; j < array_length(raw); j++) {
		var n = array_length(out);
		// 丢掉与上一个几乎相同的时间
		if (n > 0 && abs(out[n - 1] - raw[j]) <= 0.0000001) then continue;
		array_add(out, raw[j]);
	}
	if (array_length(out) < 2) then return [t0, max(t1, t0 + 0.001)];
	return out;
}

///@desc 把预处理事件的起止时间追加进结点列表
///@param {Array} dst 目标结点
///@param {Array} events 预处理事件
///@returns {Undefined} 无
function phi_knots_from_prepared(dst, events) {
	if (!is_array(events)) then return;
	for (var i = 0; i < array_length(events); i++) {
		array_add(dst, events[i].t0);
		array_add(dst, events[i].t1);
	}
}

///@desc 判断音符是否在判定线上方
///@param {Struct} note 音符
///@returns {Bool} 上方为真
function phi_note_above(note) {
	var raw = note[$ "above"];
	if (is_undefined(raw)) then raw = note[$ "isAbove"];
	if (is_undefined(raw)) then return true;
	if (is_bool(raw)) then return raw;
	return phi_finite_or(raw, 1) == 1;
}

///@desc 判断 RPE 判定线是否绑定了界面
///@param {Any} value attachUI 的值
///@returns {Bool} 绑定为真
function phi_attach_ui_active(value) {
	if (is_undefined(value) || is_bool(value)) then return value == true;
	if (is_real(value)) then return value != 0;
	var text = string_lower(string_trim(string(value)));
	// 空、0、default、false、none 都算没有绑定
	if (!string_length(text) || text == "0" || text == "default" || text == "false" || text == "none") then return false;
	return true;
}

///@desc 判断贴图是否不是默认的 line.png
///@param {Any} value 贴图名
///@returns {Bool} 自定义贴图为真
function phi_texture_custom(value) {
	var text = string_lower(string_trim(string(value ?? "")));
	if (!string_length(text) || text == "line.png") then return false;
	return true;
}

// 官谱只有移动、旋转、透明度和速度。界面绑定、自定义贴图、文本和其他扩展通道无法表现
// 颜色仍是普通线，倾斜只是无害的后备事件
///@desc 判断判定线是否含官谱表达不了的特性
///@param {Struct} src 判定线
///@param {Struct} extended 扩展事件
///@returns {Bool} 无法表达为真
function phi_line_official_unsupported(src, extended) {
	if (phi_attach_ui_active(src[$ "attachUI"])) then return true;
	if (phi_texture_custom(src[$ "Texture"])) then return true;
	if (!is_struct(extended)) then return false;
	var names = struct_get_names(extended);
	for (var i = 0; i < array_length(names); i++) {
		// 颜色和倾斜不阻止转换成官谱
		if (names[i] == "colorEvents" || names[i] == "inclineEvents") then continue;
		if (phi_extended_list(extended, names[i])) then return true;
	}
	return false;
}

///@desc 从子线回溯父链，结果从根排到自己
///@param {Array} models 线模型
///@param {Real} index 起始下标
///@returns {Array} 父链下标
function phi_parent_chain(models, index) {
	var stack = [];
	var seen = {};
	var cursor = index;
	var guard = 0;
	while (cursor >= 0 && cursor < array_length(models) && guard < 16) {
		var key = string(cursor);
		// 父链成环或超过 16 层就停止
		if (variable_struct_exists(seen, key)) then break;
		seen[$ key] = 1;
		array_add(stack, cursor);
		cursor = models[cursor].father;
		guard++;
	}
	var chain = [];
	for (var i = array_length(stack) - 1; i >= 0; i--) array_add(chain, stack[i]);
	return chain;
}

///@desc 读取模型的 BPM 因子，非法时为 1
///@param {Struct} model 线模型
///@returns {Real} 正的因子
function phi_model_factor(model) {
	var factor = phi_finite_or(model[$ "factor"] ?? 1, 1);
	if (!(factor > 0)) then factor = 1;
	return factor;
}

// 官谱 x/y 是 0 到 1 且 Y 向上，r 是屏幕角度，aspect 是视口宽除以高
// chart_sec 是真实谱面时间。每条线按 chart_sec / bpmfactor 采样，没有因子时就用 chart_sec
///@desc 沿父链算出判定线的世界坐标和旋转
///@param {Array} models 线模型
///@param {Array} chain 从根到自己的下标
///@param {Real} chart_sec 谱面秒
///@param {Real} aspect 宽高比
///@returns {Struct} 含 x、y 与 r 的姿态
function phi_world_pose(models, chain, chart_sec, aspect) {
	var parent_nx = 0;
	var parent_ny = 0;
	var parent_r = 0;
	var have = false;
	var aspect_v = aspect;
	if (!(aspect_v > 0) || !is_finite(aspect_v)) then aspect_v = 16 / 9;
	// 从根往下把子线旋进父线空间
	for (var i = 0; i < array_length(chain); i++) {
		var model = models[chain[i]];
		var sample_t = chart_sec / phi_model_factor(model);
		var raw_x = phi_layers_sum(model.layers, "x", sample_t, 0);
		var raw_y = phi_layers_sum(model.layers, "y", sample_t, 0);
		var raw_r = phi_layers_sum(model.layers, "r", sample_t, 0);
		var nx = raw_x / 1350;
		var ny = raw_y / 900;
		if (!have) {
			parent_nx = nx;
			parent_ny = ny;
			parent_r = raw_r;
			have = true;
		} else {
			var parent_cos = dcos(parent_r);
			var parent_sin = dsin(parent_r);
			parent_nx += nx * parent_cos + ny * parent_sin / aspect_v;
			parent_ny += ny * parent_cos - nx * parent_sin * aspect_v;
			if (model.rotFather) then parent_r = raw_r + parent_r;
			else parent_r = raw_r;
		}
	}
	return { x: 0.5 + parent_nx, y: 0.5 + parent_ny, r: -parent_r };
}

///@desc 判断模型旋转在区间内是否变化
///@param {Struct} model 线模型
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@returns {Bool} 有变化为真
function phi_rotation_varies(model, t0, t1) {
	if (phi_layers_eased(model.layers, "r", t0, t1)) then return true;
	var a = phi_layers_sum(model.layers, "r", t0, 0);
	var b = phi_layers_sum(model.layers, "r", t1, 0);
	return abs(a - b) > 0.001;
}

///@desc 判断父链位移或祖先旋转是否需要切片
///@param {Array} models 线模型
///@param {Array} chain 父链下标
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@returns {Bool} 需要切片为真
function phi_pose_needs_slice(models, chain, t0, t1) {
	var last = array_length(chain) - 1;
	for (var i = 0; i <= last; i++) {
		var model = models[chain[i]];
		if (phi_layers_eased(model.layers, "x", t0, t1)) then return true;
		if (phi_layers_eased(model.layers, "y", t0, t1)) then return true;
		// 只有祖先的旋转会带动子线位置
		if (i < last && phi_rotation_varies(model, t0, t1)) then return true;
	}
	return false;
}

///@desc 判断会传到本线的旋转是否需要切片
///@param {Array} models 线模型
///@param {Array} chain 父链下标
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@returns {Bool} 需要切片为真
function phi_rot_needs_slice(models, chain, t0, t1) {
	var last = array_length(chain) - 1;
	for (var i = 0; i <= last; i++) {
		var include = (i == last);
		if (!include) {
			include = true;
			for (var j = i + 1; j <= last; j++) {
				// 中间有线不跟随父旋转时，更外层的旋转传不到这里
				if (!models[chain[j]].rotFather) then include = false;
			}
		}
		if (include && phi_layers_eased(models[chain[i]].layers, "r", t0, t1)) then return true;
	}
	return false;
}

///@desc 合并首尾相接且斜率相同的标量片段
///@param {Array} events 标量片段
///@returns {Array} 合并后的片段
function phi_merge_scalar(events) {
	var out = [];
	for (var i = 0; i < array_length(events); i++) {
		var ev = events[i];
		if (ev.t1 < ev.t0) then continue;
		var n = array_length(out);
		if (n > 0) {
			var prev = out[n - 1];
			// 时间与数值都接上时再比较斜率
			if (abs(ev.t0 - prev.t1) <= 0.000001 && abs(ev.v0 - prev.v1) <= 0.00001) {
				var dt0 = prev.t1 - prev.t0;
				var dt1 = ev.t1 - ev.t0;
				var same = false;
				if (dt0 <= 0.0000001 && dt1 <= 0.0000001) then same = abs(ev.v1 - prev.v1) <= 0.00001;
				else if (dt0 > 0.0000001 && dt1 > 0.0000001) {
					var slope0 = (prev.v1 - prev.v0) / dt0;
					var slope1 = (ev.v1 - ev.v0) / dt1;
					same = abs(slope0 - slope1) <= max(0.0000001, 0.0001 * max(abs(slope0), 0.000001));
				}
				if (same) {
					prev.t1 = ev.t1;
					prev.v1 = ev.v1;
					continue;
				}
			}
		}
		array_add(out, { t0: ev.t0, t1: ev.t1, v0: ev.v0, v1: ev.v1 });
	}
	return out;
}

///@desc 合并首尾相接且两轴斜率相同的移动片段
///@param {Array} events 移动片段
///@returns {Array} 合并后的片段
function phi_merge_move(events) {
	var out = [];
	for (var i = 0; i < array_length(events); i++) {
		var ev = events[i];
		if (ev.t1 < ev.t0) then continue;
		var n = array_length(out);
		if (n > 0) {
			var prev = out[n - 1];
			var connected = abs(ev.t0 - prev.t1) <= 0.000001
				&& abs(ev.x0 - prev.x1) <= 0.00001 && abs(ev.y0 - prev.y1) <= 0.00001;
			if (connected) {
				var dt0 = prev.t1 - prev.t0;
				var dt1 = ev.t1 - ev.t0;
				var same = false;
				if (dt0 <= 0.0000001 && dt1 <= 0.0000001) {
					same = abs(ev.x1 - prev.x1) <= 0.00001 && abs(ev.y1 - prev.y1) <= 0.00001;
				} else if (dt0 > 0.0000001 && dt1 > 0.0000001) {
					var sx0 = (prev.x1 - prev.x0) / dt0;
					var sx1 = (ev.x1 - ev.x0) / dt1;
					var sy0 = (prev.y1 - prev.y0) / dt0;
					var sy1 = (ev.y1 - ev.y0) / dt1;
					same = abs(sx0 - sx1) <= max(0.0000001, 0.0001 * max(abs(sx0), 0.000001))
						&& abs(sy0 - sy1) <= max(0.0000001, 0.0001 * max(abs(sy0), 0.000001));
				}
				if (same) {
					prev.t1 = ev.t1;
					prev.x1 = ev.x1;
					prev.y1 = ev.y1;
					continue;
				}
			}
		}
		array_add(out, { t0: ev.t0, t1: ev.t1, x0: ev.x0, y0: ev.y0, x1: ev.x1, y1: ev.y1 });
	}
	return out;
}

///@desc 合并速度相同且首尾相接的片段
///@param {Array} events 速度片段
///@returns {Array} 合并后的片段
function phi_merge_speed(events) {
	var out = [];
	for (var i = 0; i < array_length(events); i++) {
		var ev = events[i];
		if (ev.t1 < ev.t0) then continue;
		var n = array_length(out);
		if (n > 0) {
			var prev = out[n - 1];
			// 速度不变就只延长上一段
			if (abs(ev.t0 - prev.t1) <= 0.000001 && abs(ev.value - prev.value) <= 0.00001) {
				prev.t1 = ev.t1;
				continue;
			}
		}
		array_add(out, { t0: ev.t0, t1: ev.t1, value: ev.value });
	}
	return out;
}

///@desc 按 BPM 因子缩放标量片段的时间
///@param {Array} events 标量片段
///@param {Real} factor 时间因子
///@returns {Array} 缩放后的片段
function phi_scale_scalar(events, factor) {
	var out = [];
	var f = factor;
	// 非法因子按 1 处理，只缩放时间不改数值
	if (!(f > 0)) then f = 1;
	for (var i = 0; i < array_length(events); i++) {
		var ev = events[i];
		array_add(out, { t0: ev.t0 * f, t1: ev.t1 * f, v0: ev.v0, v1: ev.v1 });
	}
	return out;
}

///@desc 按 BPM 因子缩放移动片段的时间
///@param {Array} events 移动片段
///@param {Real} factor 时间因子
///@returns {Array} 缩放后的片段
function phi_scale_move(events, factor) {
	var out = [];
	var f = factor;
	if (!(f > 0)) then f = 1;
	for (var i = 0; i < array_length(events); i++) {
		var ev = events[i];
		array_add(out, { t0: ev.t0 * f, t1: ev.t1 * f, x0: ev.x0, y0: ev.y0, x1: ev.x1, y1: ev.y1 });
	}
	return out;
}

///@desc 按上下文在指定秒采样一个标量
///@param {Struct} ctx 采样上下文
///@param {Real} t 秒
///@returns {Real} 采样值
function phi_ctx_scalar(ctx, t) {
	if (ctx.kind == "a") {
		// 绑定界面的线透明度不参与烘培
		if (ctx.model.attach) then return 0;
		return clamp(phi_layers_sum(ctx.model.layers, "a", t, 0) / 255, 0, 1);
	}
	if (ctx.kind == "list") then return phi_eval_prepared(ctx.events, t, ctx.empty);
	return 0;
}

///@desc 判断上下文在区间内是否需要切片
///@param {Struct} ctx 采样上下文
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@returns {Bool} 需要切片为真
function phi_ctx_needs(ctx, t0, t1) {
	if (ctx.kind == "a") then return phi_layers_eased(ctx.model.layers, "a", t0, t1);
	if (ctx.kind == "list") then return phi_list_eased(ctx.events, t0, t1);
	return false;
}

///@desc 按结点把标量切成线性段，跳变归到下一段
///@param {Array} knots 时间结点
///@param {Struct} ctx 采样上下文
///@param {Real} limit 视为跳变的差值
///@returns {Array} 线性片段
function phi_slice_scalar(knots, ctx, limit) {
	var out = [];
	for (var i = 0; i < array_length(knots) - 1; i++) {
		var t0 = knots[i];
		var t1 = knots[i + 1];
		if (t1 - t0 <= 0.0000001) then continue;
		var v0 = phi_ctx_scalar(ctx, t0);
		var pre = phi_ctx_scalar(ctx, phi_probe_before(t0, t1));
		var post = phi_ctx_scalar(ctx, t1);
		// 数值跳变属于下一段。同一时刻的零长度事件会被官谱游标盖住
		var jumped = abs(post - pre) > limit;
		array_add(out, { t0: t0, t1: t1, v0: v0, v1: (jumped ? pre : post) });
	}
	return out;
}

///@desc 按结点切出世界坐标移动和旋转
///@param {Array} knots 时间结点
///@param {Array} models 线模型
///@param {Array} chain 父链下标
///@param {Real} aspect 宽高比
///@returns {Struct} 含 move 与 rot
function phi_slice_pose(knots, models, chain, aspect) {
	var move = [];
	var rot = [];
	for (var i = 0; i < array_length(knots) - 1; i++) {
		var t0 = knots[i];
		var t1 = knots[i + 1];
		if (t1 - t0 <= 0.0000001) then continue;
		var p0 = phi_world_pose(models, chain, t0, aspect);
		var pre = phi_world_pose(models, chain, phi_probe_before(t0, t1), aspect);
		var post = phi_world_pose(models, chain, t1, aspect);
		// 小空隙也要保持原值。50 单位的台阶低于旧的 0.05 屏幕测试，会被拉过整段空白
		var jump_xy = abs(post.x - pre.x) > 0.00001 || abs(post.y - pre.y) > 0.00001;
		var jump_r = abs(post.r - pre.r) > 0.01;
		array_add(move, { t0: t0, t1: t1, x0: p0.x, y0: p0.y, x1: (jump_xy ? pre.x : post.x), y1: (jump_xy ? pre.y : post.y) });
		array_add(rot, { t0: t0, t1: t1, v0: p0.r, v1: (jump_r ? pre.r : post.r) });
	}
	return { move: move, rot: rot };
}

///@desc 用相邻结点的地板差除以时间得到速度
///@param {Struct} model 速度模型
///@param {Array} knots 时间结点
///@param {Real} factor 时间因子
///@returns {Array} 速度片段
function phi_slice_speed(model, knots, factor) {
	var out = [];
	var scale = factor;
	if (!(scale > 0)) then scale = 1;
	for (var i = 0; i < array_length(knots) - 1; i++) {
		var t0 = knots[i];
		var t1 = knots[i + 1];
		if (t1 - t0 <= 0.0000001) then continue;
		var f0 = phi_model_floor(model, t0);
		var f1 = phi_model_floor(model, t1);
		var dt = (t1 - t0) * scale;
		if (dt > 0.0000001 && is_finite(f0) && is_finite(f1)) then array_add(out, { t0: t0 * scale, t1: t1 * scale, value: (f1 - f0) / dt });
	}
	return out;
}

///@desc 在一段中间插入固定数量的采样时间
///@param {Array} dst 目标结点
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@returns {Undefined} 无
function phi_push_slice_times(dst, t0, t1) {
	var dur = t1 - t0;
	if (!(dur > 0.0000001) || !is_finite(dur) || !is_finite(t0)) then return;
	var pieces = PHI_EASE_SLICES;
	for (var s = 1; s < pieces; s++) array_add(dst, t0 + dur * (s / pieces));
}

///@desc 收集速度变化需要的时间结点
///@param {Struct} model 速度模型
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@returns {Array} 去重后的结点
function phi_speed_knots(model, t0, t1) {
	var extra = [];
	if (model.legacy) {
		var segments = model.legacySegments;
		for (var i = 0; i < array_length(segments); i++) {
			if (is_finite(segments[i].startTime)) then array_add(extra, segments[i].startTime);
			if (!is_finite(segments[i].endTime)) then continue;
			array_add(extra, segments[i].endTime);
			// 速度本身在变时，段内还要再切细
			if (abs(segments[i].value - segments[i].endValue) > 0.00001) then phi_push_slice_times(extra, segments[i].startTime, segments[i].endTime);
		}
	} else {
		var layers = model.modern;
		for (var li = 0; li < array_length(layers); li++) {
			var events = layers[li].events;
			for (var ei = 0; ei < array_length(events); ei++) {
				array_add(extra, events[ei].startSec);
				array_add(extra, events[ei].endSec);
				var speed_eased = abs(events[ei].v0 - events[ei].v1) > 0.00001;
				if (!speed_eased && events[ei].easingType > 1) then speed_eased = false;
				if (speed_eased) then phi_push_slice_times(extra, events[ei].startSec, events[ei].endSec);
			}
		}
	}
	return phi_knots_unique(extra, t0, t1);
}

///@desc 把事件起止时间乘上因子后追加进结点
///@param {Array} dst 目标结点
///@param {Array} events 预处理事件
///@param {Real} factor 时间因子
///@returns {Undefined} 无
function phi_knots_from_prepared_scaled(dst, events, factor) {
	if (!is_array(events)) then return;
	var scale = factor;
	if (!(scale > 0)) then scale = 1;
	for (var i = 0; i < array_length(events); i++) {
		array_add(dst, events[i].t0 * scale);
		array_add(dst, events[i].t1 * scale);
	}
}

// 结点用谱面秒。线上本地时间 t 的事件落在 t * bpmfactor
///@desc 收集父链位移和旋转的时间结点
///@param {Array} models 线模型
///@param {Array} chain 父链下标
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@returns {Array} 去重后的结点
function phi_pose_knots(models, chain, t0, t1) {
	var extra = [];
	for (var i = 0; i < array_length(chain); i++) {
		var model = models[chain[i]];
		var factor = phi_model_factor(model);
		var layers = model.layers;
		for (var li = 0; li < array_length(layers); li++) {
			phi_knots_from_prepared_scaled(extra, layers[li].x, factor);
			phi_knots_from_prepared_scaled(extra, layers[li].y, factor);
			phi_knots_from_prepared_scaled(extra, layers[li].r, factor);
		}
	}
	return phi_knots_unique(extra, t0, t1);
}

// 父线转动会让子线走弧线。线性转角也要额外位置采样，子线自己的旋转仍是标量
///@desc 按祖先转过的角度决定弧线要切成几段
///@param {Array} models 线模型
///@param {Array} chain 父链下标
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@param {Real} aspect 宽高比
///@returns {Real} 段数，至少为 1
function phi_pose_arc_pieces(models, chain, t0, t1, aspect) {
	if (array_length(chain) <= 1) then return 1;
	var left = t1 - 0.00002;
	if (left <= t0) then return 1;
	var angle = abs(phi_ancestor_raw_r(models, chain, left, aspect) - phi_ancestor_raw_r(models, chain, t0, aspect));
	// 转角很小就不必再切，大转角大约每 6 度一段
	if (angle <= 0.2) then return 1;
	var n = ceil(angle / 6);
	if (n < 4) then n = 4;
	if (n > 48) then n = 48;
	return n;
}

///@desc 在父线转弧的区间里补上中间结点
///@param {Array} models 线模型
///@param {Array} chain 父链下标
///@param {Array} knots 已有结点
///@param {Real} aspect 宽高比
///@returns {Array} 加密后的结点
function phi_pose_refine_knots(models, chain, knots, aspect) {
	var n = array_length(knots);
	if (n < 2 || array_length(chain) <= 1) then return knots;
	var out = [];
	for (var i = 0; i < n - 1; i++) {
		var t0 = knots[i];
		var t1 = knots[i + 1];
		array_add(out, t0);
		if (t1 - t0 <= 0.0000001) then continue;
		var pieces = phi_pose_arc_pieces(models, chain, t0, t1, aspect);
		for (var s = 1; s < pieces; s++) array_add(out, t0 + (t1 - t0) * (s / pieces));
	}
	array_add(out, knots[n - 1]);
	return out;
}

///@desc 收集透明度事件的时间结点
///@param {Struct} model 线模型
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@returns {Array} 去重后的结点
function phi_alpha_knots(model, t0, t1) {
	var extra = [];
	for (var i = 0; i < array_length(model.layers); i++) {
		phi_knots_from_prepared(extra, model.layers[i].a);
	}
	return phi_knots_unique(extra, t0, t1);
}

///@desc 取事件列表里最晚的结束时间
///@param {Array} events 事件
///@param {Real} fallback 没有更晚时间时的后备值
///@returns {Real} 结束时间
function phi_event_end(events, fallback) {
	var end_at = fallback;
	if (!is_array(events)) then return end_at;
	for (var i = 0; i < array_length(events); i++) {
		end_at = max(end_at, events[i].t1);
	}
	return end_at;
}

///@desc 接受 RPE 结构或 JSON 文本，返回谱面结构
///@param {Any} rpe_chart 结构或 JSON 文本
///@returns {Any} 含判定线的谱面，无效时未定义
function phi_rpe_chart_value(rpe_chart) {
	if (is_struct(rpe_chart)) {
		if (is_array(rpe_chart[$ "judgeLineList"])) then return rpe_chart;
		return undefined;
	}
	if (!is_string(rpe_chart) || !string_length(rpe_chart)) then return undefined;
	var parsed = undefined;
	// 文本解析失败或没有判定线就放弃
	try {
		parsed = json_parse(rpe_chart);
	} catch (parse_error) {
		delete(parse_error);
		return undefined;
	}
	if (!is_struct(parsed) || !is_array(parsed[$ "judgeLineList"])) then return undefined;
	return parsed;
}

///@desc 把 RPE 父线、缓动和速度烘成绝对的线性片段
///@param {Struct} chart RPE 谱面
///@returns {Any} 烘焙结果，无效输入为未定义
function phi_rpe_bake(chart) {
	if (!is_struct(chart) || !is_array(chart[$ "judgeLineList"])) then return undefined;
	var meta = chart[$ "META"];
	if (!is_struct(meta)) then meta = {};
	var version = phi_finite_or(meta[$ "RPEVersion"] ?? 0, 0);
	var legacy = version < 170;
	var timeline = phi_bpm_timeline(chart[$ "BPMList"]);
	var bpm = timeline[0].bpm;
	var aspect = phi_chart_aspect_of(meta);
	var source_lines = chart.judgeLineList;
	var models = [];
	var stats = {
		source: "",
		lines: 0,
		notes: 0,
		version: version,
		legacySpeed: legacy,
		parents: 0,
		attachUI: 0,
		textures: 0,
		scaleLines: 0,
		special: 0,
		noteAlpha: 0,
		noteSize: 0,
		noteScale: 0,
		fakeDropped: 0,
		dropped: 0,
		move: 0,
		rotate: 0,
		alpha: 0,
		speed: 0,
		sliced: 0
	};
	var chart_end = 1;
	var parent_ids = {};
	var source_count = array_length(source_lines);
	for (var parent_i = 0; parent_i < source_count; parent_i++) {
		var parent_src = source_lines[parent_i];
		if (!is_struct(parent_src)) then continue;
		var parent_father = floor(phi_finite_or(parent_src[$ "father"] ?? -1, -1));
		if (parent_father == parent_i) then continue;
		if (parent_father < 0 || parent_father >= source_count) then continue;
		parent_ids[$ string(parent_father)] = true;
	}
	for (var line_i = 0; line_i < array_length(source_lines); line_i++) {
		var src = source_lines[line_i];
		if (!is_struct(src)) then src = {};
		var factor = phi_finite_or(src[$ "bpmfactor"] ?? 1, 1);
		if (!(factor > 0)) then factor = 1;
		var father = floor(phi_finite_or(src[$ "father"] ?? -1, -1));
		if (father == line_i) then father = -1;
		var layers_raw = src[$ "eventLayers"];
		if (!is_array(layers_raw)) then layers_raw = [];
		var layers = [];
		var beat_speeds = [];
		var line_end = 0;
		for (var layer_i = 0; layer_i < array_length(layers_raw); layer_i++) {
			var _layer = layers_raw[layer_i];
			if (!is_struct(_layer)) then continue;
			var move_x = phi_expand_channel(phi_prep_events(_layer[$ "moveXEvents"], timeline));
			var move_y = phi_expand_channel(phi_prep_events(_layer[$ "moveYEvents"], timeline));
			var rotate = phi_expand_channel(phi_prep_events(_layer[$ "rotateEvents"], timeline));
			var alpha = phi_expand_channel(phi_prep_events(_layer[$ "alphaEvents"], timeline));
			array_add(layers, { x: move_x, y: move_y, r: rotate, a: alpha });
			var speed_beats = phi_drop_extreme_speed_gaps(phi_speed_beats_from_raw(_layer[$ "speedEvents"]));
			if (array_length(speed_beats) > 0) then array_add(beat_speeds, speed_beats);
			line_end = phi_event_end(move_x, line_end);
			line_end = phi_event_end(move_y, line_end);
			line_end = phi_event_end(rotate, line_end);
			line_end = phi_event_end(alpha, line_end);
		}
		if (array_length(layers) <= 0) then array_add(layers, { x: [], y: [], r: [], a: [] });
		var legacy_segments = [];
		var modern = [];
		if (legacy) {
			legacy_segments = phi_build_legacy_speed(beat_speeds, timeline);
			for (var seg_i = 0; seg_i < array_length(legacy_segments); seg_i++) {
				line_end = max(line_end, legacy_segments[seg_i].endTime);
			}
		} else {
			for (var modern_i = 0; modern_i < array_length(beat_speeds); modern_i++) {
				var built_layer = phi_build_modern_layer(beat_speeds[modern_i], timeline);
				if (is_struct(built_layer)) then array_add(modern, built_layer);
			}
			for (var modern_n = 0; modern_n < array_length(modern); modern_n++) {
				line_end = max(line_end, modern[modern_n].tailEnd);
			}
		}
		var attach = phi_attach_ui_active(src[$ "attachUI"]);
		if (attach) then stats.attachUI++;
		if (phi_texture_custom(src[$ "Texture"])) then stats.textures++;
		if (father >= 0) then stats.parents++;
		var extended = src[$ "extended"];
		if (!is_struct(extended)) then extended = {};
		if (phi_extended_list(extended, "scaleXEvents") || phi_extended_list(extended, "scaleYEvents")) then stats.scaleLines++;
		if (phi_extended_list(extended, "colorEvents") || phi_extended_list(extended, "textEvents")
			|| phi_extended_list(extended, "paintEvents") || phi_extended_list(extended, "gifEvents")
			|| phi_extended_list(extended, "inclineEvents")) then stats.special++;
		var notes = [];
		var real_notes = 0;
		var raw_notes = src[$ "notes"];
		if (is_array(raw_notes)) {
			for (var note_i = 0; note_i < array_length(raw_notes); note_i++) {
				var note = raw_notes[note_i];
				if (!is_struct(note)) then continue;
				var rpe_type = floor(phi_finite_or(note[$ "type"] ?? 1, 1));
				if (rpe_type < 1 || rpe_type > 4) then rpe_type = 1;
				var start_line = phi_timeline_beat_to_sec(timeline, rpe_array_to_beat(note[$ "startTime"] ?? 0));
				var end_line = phi_timeline_beat_to_sec(timeline, rpe_array_to_beat(note[$ "endTime"] ?? note[$ "startTime"] ?? 0));
				if (end_line < start_line) then end_line = start_line;
				line_end = max(line_end, end_line);
				var note_fake = bool(note[$ "isFake"] ?? false);
				if (!note_fake) then real_notes++;
				var note_alpha = phi_finite_or(note[$ "alpha"] ?? 255, 255);
				var note_size = phi_finite_or(note[$ "size"] ?? 1, 1);
				if (abs(note_alpha - 255) > 0.5) then stats.noteAlpha++;
				if (abs(note_size - 1) > 0.0001) then stats.noteSize++;
				if (phi_note_xy_scaled(note)) then stats.noteScale++;
				array_add(notes, {
					rpeType: rpe_type,
					startSec: start_line * factor,
					endSec: end_line * factor,
					officialX: phi_finite_or(note[$ "positionX"] ?? 0, 0) / 75.375,
					speed: phi_finite_or(note[$ "speed"] ?? 1, 1),
					above: phi_note_above(note),
					fake: note_fake,
					yOffset: phi_finite_or(note[$ "yOffset"] ?? 0, 0)
				});
			}
		}
		// 官谱画不出、自己又没有真实音符的线不导出。父子线保留，链接已经烘进可见运动
		var linked = (father >= 0) || variable_struct_exists(parent_ids, string(line_i));
		var drop = phi_line_official_unsupported(src, extended) && real_notes <= 0 && !linked;
		if (drop) then stats.dropped++;
		if (!drop) {
			if (!is_finite(line_end) || line_end > 100000) then line_end = 100000;
			if (line_end < 0) then line_end = 0;
			chart_end = max(chart_end, line_end * factor);
			if (!is_finite(chart_end) || chart_end > 100000) then chart_end = 100000;
		}
		array_add(models, {
			factor: factor,
			father: father,
			rotFather: bool(src[$ "rotateWithFather"] ?? false),
			attach: attach,
			layers: layers,
			legacy: legacy,
			legacySegments: legacy_segments,
			modern: modern,
			notes: notes,
			lineEnd: line_end,
			drop: drop
		});
	}
	var baked_lines = [];
	for (var bake_i = 0; bake_i < array_length(models); bake_i++) {
		var model = models[bake_i];
		if (bool(model[$ "drop"] ?? false)) then continue;
		var factor = model.factor;
		var line_start = 0;
		var line_end = max(model.lineEnd, chart_end / factor);
		if (line_end <= line_start) then line_end = line_start + 0.001;
		var chain = phi_parent_chain(models, bake_i);
		var chart_t1 = line_end * factor;
		var pose_knots = phi_pose_refine_knots(models, chain, phi_pose_knots(models, chain, 0, chart_t1), aspect);
		var pose = phi_slice_pose(pose_knots, models, chain, aspect);
		var alpha_ctx = { kind: "a", model: model };
		var alpha = phi_slice_scalar(phi_alpha_knots(model, line_start, line_end), alpha_ctx, 0.00001);
		if (model.attach) then alpha = [{ t0: line_start, t1: line_end, v0: 0, v1: 0 }];
		var _speed = phi_slice_speed(model, phi_speed_knots(model, line_start, line_end), factor);
		if (array_length(_speed) <= 0) then array_add(_speed, { t0: line_start * factor, t1: line_end * factor, value: 0 });
		var move = phi_merge_move(pose.move);
		var rot = phi_merge_scalar(pose.rot);
		alpha = phi_merge_scalar(phi_scale_scalar(alpha, factor));
		_speed = phi_merge_speed(_speed);
		array_add(baked_lines, { move: move, rot: rot, alpha: alpha, speed: _speed, notes: model.notes });
	}
	stats.lines = array_length(baked_lines);
	return {
		offsetMs: phi_finite_or(meta[$ "offset"] ?? 0, 0),
		bpm: bpm,
		timeline: timeline,
		lines: baked_lines,
		stats: stats
	};
}

///@desc 判断扩展结构里某个数组是否非空
///@param {Struct} ext 扩展结构
///@param {String} name 字段名
///@returns {Bool} 非空数组为真
function phi_extended_list(ext, name) {
	var arr = ext[$ name];
	return is_array(arr) && array_length(arr) > 0;
}

///@desc 判断音符的宽高或缩放是否偏离 1
///@param {Struct} note 音符
///@returns {Bool} 有非均匀尺寸为真
function phi_note_xy_scaled(note) {
	var keys = ["sizeX", "sizeY", "scaleX", "scaleY"];
	for (var i = 0; i < array_length(keys); i++) {
		if (!variable_struct_exists(note, keys[i])) then continue;
		// 任一轴离开 1 就算官谱表达不了
		if (abs(phi_finite_or(note[$ keys[i]], 1) - 1) > 0.0001) then return true;
	}
	return false;
}

// sim-phi 用 Number(t)|0 存时间，短于一 tick 的切片会消失并让地板跑在音符前面
// phira 用 f32 积分 (end-start)*secondsPerTick，同样的碎切片会把和撑爆
// 结点落在每个边界两侧的整数上，每段保留真实地板变化，写出的时间都是整数 tick
///@desc 取片段覆盖到的最后一个整数 tick
///@param {Array} ranges 时间片段
///@returns {Real} 结尾 tick，至少为 1
function phi_official_tick_end(ranges) {
	var end_tick = 0;
	var count = array_length(ranges);
	for (var i = 0; i < count; i++) {
		var t1 = real(ranges[i].t1);
		if (is_finite(t1) && t1 > end_tick) then end_tick = t1;
	}
	var tick_end = ceil(end_tick - 0.0000001);
	if (!is_finite(tick_end) || tick_end < 1) then tick_end = 1;
	if (tick_end > 20000000) then tick_end = 20000000;
	return tick_end;
}

///@desc 把一个时间边界的上下整数 tick 放进结点
///@param {Array} dst 目标结点
///@param {Real} edge 边界时间
///@param {Real} tick_end 允许的最大 tick
///@returns {Undefined} 无
function phi_official_push_edge(dst, edge, tick_end) {
	if (!is_finite(edge)) then return;
	var lo = floor(edge + 0.000000001);
	var hi = ceil(edge - 0.000000001);
	if (lo < 0) then lo = 0;
	if (hi < 0) then hi = 0;
	if (lo > tick_end) then lo = tick_end;
	if (hi > tick_end) then hi = tick_end;
	array_add(dst, lo);
	// 不在整数上时，地板和天花板都要保留
	if (hi != lo) then array_add(dst, hi);
}

///@desc 收集片段边界上的整数 tick 并去重
///@param {Array} ranges 时间片段
///@param {Real} tick_end 结尾 tick
///@returns {Array} 从 0 到结尾的结点
function phi_official_knots(ranges, tick_end) {
	var raw = [0, tick_end];
	var count = array_length(ranges);
	for (var i = 0; i < count; i++) {
		phi_official_push_edge(raw, real(ranges[i].t0), tick_end);
		phi_official_push_edge(raw, real(ranges[i].t1), tick_end);
	}
	array_sort(raw, pec_cmp_real);
	var knots = [];
	for (var k = 0; k < array_length(raw); k++) {
		var tk = raw[k];
		var n = array_length(knots);
		if (n > 0 && knots[n - 1] == tk) then continue;
		array_add(knots, tk);
	}
	if (array_length(knots) < 2) then return [0, tick_end];
	return knots;
}

///@desc 收成有限的 float32，非法时为 0
///@param {Real} value 数值
///@returns {Real} float32
function phi_official_f32_finite(value) {
	var out = official_f32(value);
	if (!is_finite(out)) then return 0;
	return out;
}

///@desc 把速度片段量化到整数 tick，并保持 float32 地板
///@param {Array} ranges 速度片段
///@param {Real} spb 每拍秒数
///@returns {Array} 官谱速度事件
function phi_official_quantize_speed(ranges, spb) {
	var src = [];
	var count = array_length(ranges);
	for (var i = 0; i < count; i++) {
		var ev = ranges[i];
		var t0 = real(ev.t0);
		var t1 = real(ev.t1);
		var speed_value = real(ev.v);
		if (!is_finite(t0) || !is_finite(t1) || !is_finite(speed_value)) then continue;
		if (t1 <= t0) then continue;
		array_add(src, { t0: t0, t1: t1, v: speed_value });
	}
	if (array_length(src) <= 0) then return [{ startTime: 0, endTime: 1, value: 0 }];
	array_sort(src, function(a, b) { return pec_cmp_real(a.t0, b.t0); });
	var seconds = real(spb);
	if (!(seconds > 0) || !is_finite(seconds)) then seconds = 1.875 / 140;
	var tick_end = phi_official_tick_end(src);
	var knots = phi_official_knots(src, tick_end);
	var floors = [];
	var acc = 0;
	var prev = 0;
	var si = 0;
	var nsrc = array_length(src);
	for (var ki = 0; ki < array_length(knots); ki++) {
		var t = knots[ki];
		var scan = si;
		while (scan < nsrc && src[scan].t1 <= prev + 0.000000001) scan++;
		var at = prev;
		while (scan < nsrc && src[scan].t0 < t - 0.000000000001) {
			var a = max(at, src[scan].t0);
			var b = min(t, src[scan].t1);
			if (b > a) then acc += src[scan].v * (b - a) * seconds;
			if (src[scan].t1 <= t + 0.000000001) {
				scan++;
				at = max(at, b);
			} else break;
		}
		array_add(floors, acc);
		prev = t;
		si = scan;
	}
	var out = [];
	for (var span_i = 0; span_i < array_length(knots) - 1; span_i++) {
		var span_a = knots[span_i];
		var span_b = knots[span_i + 1];
		if (span_b <= span_a) then continue;
		var dsec = (span_b - span_a) * seconds;
		var value = 0;
		if (dsec > 0) then value = (floors[span_i + 1] - floors[span_i]) / dsec;
		value = phi_official_f32_finite(value);
		var nout = array_length(out);
		// 相邻速度相同就延长上一段
		if (nout > 0 && out[nout - 1].value == value) {
			out[nout - 1].endTime = span_b;
		} else {
			array_add(out, { startTime: span_a, endTime: span_b, value: value });
		}
	}
	if (array_length(out) <= 0) then return [{ startTime: 0, endTime: 1, value: 0 }];
	return out;
}

///@desc 在两个时间点之间线性插值
///@param {Real} t0 起点时间
///@param {Real} t1 终点时间
///@param {Real} v0 起点值
///@param {Real} v1 终点值
///@param {Real} t 采样时间
///@returns {Real} 插值结果
function phi_official_lerp(t0, t1, v0, v1, t) {
	if (!(t1 > t0)) then return v1;
	var p = (t - t0) / (t1 - t0);
	if (p <= 0) then return v0;
	if (p >= 1) then return v1;
	return v0 + (v1 - v0) * p;
}

// 左极限保留跳变前的值，右极限保留跳变后的值
///@desc 计算每个结点左右两侧的事件值
///@param {Array} events 已排序事件
///@param {Array} knots 时间结点
///@returns {Array} 含 left 与 right
function phi_official_edge_values(events, knots) {
	var n = array_length(events);
	var out = [];
	var left_i = 0;
	var right_i = 0;
	var eps = 0.0000001;
	for (var ki = 0; ki < array_length(knots); ki++) {
		var t = knots[ki];
		// 左极限停在起点早于该结点的最后一段
		while (left_i + 1 < n && events[left_i + 1].t0 < t - eps) left_i++;
		var left_v = 0;
		if (n <= 0) then left_v = 0;
		else if (events[0].t0 >= t - eps) then left_v = events[0].v0;
		else {
			var left_ev = events[left_i];
			if (t <= left_ev.t1 + eps) then left_v = phi_official_lerp(left_ev.t0, left_ev.t1, left_ev.v0, left_ev.v1, t);
			else left_v = left_ev.v1;
		}
		while (right_i < n && events[right_i].t1 <= t + eps) right_i++;
		var right_v = left_v;
		if (n <= 0) then right_v = 0;
		else if (right_i >= n) then right_v = events[n - 1].v1;
		else {
			var right_ev = events[right_i];
			if (right_ev.t0 > t + eps) {
				if (right_i == 0) then right_v = right_ev.v0;
				else right_v = events[right_i - 1].v1;
			} else right_v = phi_official_lerp(right_ev.t0, right_ev.t1, right_ev.v0, right_ev.v1, t);
		}
		array_add(out, { left: left_v, right: right_v });
	}
	return out;
}

///@desc 判断两段的斜率是否相同
///@param {Real} dt0 第一段时长
///@param {Real} dv0 第一段数值差
///@param {Real} dt1 第二段时长
///@param {Real} dv1 第二段数值差
///@returns {Bool} 斜率相同为真
function phi_official_same_slope(dt0, dv0, dt1, dv1) {
	if (dt0 <= 0 || dt1 <= 0) then return false;
	var slope0 = dv0 / dt0;
	var slope1 = dv1 / dt1;
	return abs(slope0 - slope1) <= max(0.00001, 0.0001 * max(abs(slope0), 0.00001));
}

///@desc 把标量片段量化成整数 tick 的官谱事件
///@param {Array} ranges 标量片段
///@returns {Array} 官谱事件
function phi_official_quantize_scalar(ranges) {
	var src = [];
	var count = array_length(ranges);
	for (var i = 0; i < count; i++) {
		var ev = ranges[i];
		var t0 = real(ev.t0);
		var t1 = real(ev.t1);
		var v0 = real(ev.v0);
		var v1 = real(ev.v1);
		if (!is_finite(t0) || !is_finite(t1) || !is_finite(v0) || !is_finite(v1)) then continue;
		if (t1 <= t0) then continue;
		array_add(src, { t0: t0, t1: t1, v0: v0, v1: v1 });
	}
	if (array_length(src) <= 0) then return [];
	array_sort(src, function(a, b) { return pec_cmp_real(a.t0, b.t0); });
	var tick_end = phi_official_tick_end(src);
	var knots = phi_official_knots(src, tick_end);
	var edges = phi_official_edge_values(src, knots);
	var out = [];
	for (var span_i = 0; span_i < array_length(knots) - 1; span_i++) {
		var span_a = knots[span_i];
		var span_b = knots[span_i + 1];
		if (span_b <= span_a) then continue;
		var v0 = edges[span_i].right;
		var v1 = edges[span_i + 1].left;
		var nout = array_length(out);
		if (nout > 0) {
			var prev = out[nout - 1];
			var connected = abs(prev.rawEnd - v0) <= 0.00001;
			// 接得上且斜率相同就合并，避免 float32 把直线切碎
			if (connected && phi_official_same_slope(prev.endTime - prev.startTime, prev.rawEnd - prev.rawStart, span_b - span_a, v1 - v0)) {
				prev.endTime = span_b;
				prev.rawEnd = v1;
				prev.end = phi_official_f32_finite(v1);
				continue;
			}
		}
		array_add(out, {
			startTime: span_a,
			endTime: span_b,
			start: phi_official_f32_finite(v0),
			"end": phi_official_f32_finite(v1),
			rawStart: v0,
			rawEnd: v1
		});
	}
	for (var clean_i = 0; clean_i < array_length(out); clean_i++) {
		variable_struct_remove(out[clean_i], "rawStart");
		variable_struct_remove(out[clean_i], "rawEnd");
	}
	return out;
}

///@desc 把移动片段量化成带两轴的官谱事件
///@param {Array} ranges 移动片段
///@returns {Array} 官谱移动事件
function phi_official_quantize_move(ranges) {
	array_sort(ranges, function(a, b) { return pec_cmp_real(a.t0, b.t0); });
	var src_x = [];
	var src_y = [];
	var count = array_length(ranges);
	for (var i = 0; i < count; i++) {
		var ev = ranges[i];
		var t0 = real(ev.t0);
		var t1 = real(ev.t1);
		if (!is_finite(t0) || !is_finite(t1) || t1 <= t0) then continue;
		array_add(src_x, { t0: t0, t1: t1, v0: real(ev.x0), v1: real(ev.x1) });
		array_add(src_y, { t0: t0, t1: t1, v0: real(ev.y0), v1: real(ev.y1) });
	}
	if (array_length(src_x) <= 0) then return [];
	var tick_end = phi_official_tick_end(src_x);
	var knots = phi_official_knots(src_x, tick_end);
	var edge_x = phi_official_edge_values(src_x, knots);
	var edge_y = phi_official_edge_values(src_y, knots);
	var out = [];
	for (var span_i = 0; span_i < array_length(knots) - 1; span_i++) {
		var span_a = knots[span_i];
		var span_b = knots[span_i + 1];
		if (span_b <= span_a) then continue;
		array_add(out, {
			startTime: span_a,
			endTime: span_b,
			start: phi_official_f32_finite(edge_x[span_i].right),
			"end": phi_official_f32_finite(edge_x[span_i + 1].left),
			start2: phi_official_f32_finite(edge_y[span_i].right),
			end2: phi_official_f32_finite(edge_y[span_i + 1].left)
		});
	}
	return out;
}

///@desc 把烘焙结果写成官谱
///@param {Struct} baked 烘焙结果
///@param {String} source_name 来源名称
///@returns {Any} 官谱结构，无效输入为未定义
function phi_baked_to_official(baked, source_name) {
	if (!is_struct(baked)) then return undefined;
	var bpm = baked.bpm;
	if (!(bpm > 0)) then bpm = 140;
	var spb = 1.875 / bpm;
	var judge = [];
	var stats = baked.stats;
	stats.source = source_name;
	stats.notes = 0;
	for (var line_i = 0; line_i < array_length(baked.lines); line_i++) {
		var _line = baked.lines[line_i];
		var speed_ranges = [];
		var speed_src = phi_merge_speed(_line.speed);
		for (var speed_i = 0; speed_i < array_length(speed_src); speed_i++) {
			var ev = speed_src[speed_i];
			var t0 = phi_sec_to_tick(ev.t0, bpm);
			var t1 = phi_sec_to_tick(ev.t1, bpm);
			if (!is_finite(t0)) then t0 = 0;
			if (!is_finite(t1) || t1 < t0) then t1 = t0;
			if (t1 > t0) then array_add(speed_ranges, { t0: t0, t1: t1, v: real(ev.value) });
		}
		var _speed = phi_official_quantize_speed(speed_ranges, spb);
		official_prepare_speed_events(_speed, spb);
		var above = [];
		var below = [];
		for (var note_i = 0; note_i < array_length(_line.notes); note_i++) {
			var note = _line.notes[note_i];
			if (note.fake) {
				stats.fakeDropped++;
				continue;
			}
			stats.notes++;
			var off_type = 1;
			if (note.rpeType == 2) then off_type = 3;
			else if (note.rpeType == 3) then off_type = 4;
			else if (note.rpeType == 4) then off_type = 2;
			var tick = round(phi_sec_to_tick(note.startSec, bpm));
			var end_tick = round(phi_sec_to_tick(note.endSec, bpm));
			var hold = 0;
			var official_speed = note.speed;
			if (off_type == 3) {
				hold = end_tick - tick;
				if (hold < 0) then hold = 0;
				var hold_sec = hold * spb;
				if (hold_sec <= 0.0000001) {
					official_speed = 0;
					hold = 0;
				} else {
					// 官谱身体长度是速度乘 holdTime。把 RPE 地板行程和音符速度折进这一个身体速度
					var floor_end = official_floor_at_beat(_speed, tick + hold, spb);
					var floor_start = official_floor_at_beat(_speed, tick, spb);
					official_speed = ((floor_end - floor_start) * note.speed) / hold_sec;
					if (!is_finite(official_speed)) then official_speed = 0;
					official_speed = phi_official_f32_finite(official_speed);
				};
			}
			var floor_v = official_floor_at_beat(_speed, tick, spb);
			if (off_type != 3 && abs(note.speed) > 0.0000001 && abs(note.yOffset) > 0.0000001) {
				floor_v += note.yOffset / (540 * note.speed);
			}
			var packed = {
				type: int64(off_type),
				time: tick,
				holdTime: hold,
				positionX: phi_official_f32_finite(note.officialX),
				speed: phi_official_f32_finite(official_speed),
				floorPosition: floor_v
			};
			if (note.above) then array_add(above, packed);
			else array_add(below, packed);
		}
		var move_ranges = [];
		for (var move_i = 0; move_i < array_length(_line.move); move_i++) {
			var mv = _line.move[move_i];
			array_add(move_ranges, {
				t0: phi_sec_to_tick(mv.t0, bpm),
				t1: phi_sec_to_tick(mv.t1, bpm),
				x0: mv.x0, y0: mv.y0, x1: mv.x1, y1: mv.y1
			});
		}
		var move = phi_official_quantize_move(move_ranges);
		var rot_ranges = [];
		for (var rot_i = 0; rot_i < array_length(_line.rot); rot_i++) {
			var rv = _line.rot[rot_i];
			array_add(rot_ranges, {
				t0: phi_sec_to_tick(rv.t0, bpm),
				t1: phi_sec_to_tick(rv.t1, bpm),
				v0: rv.v0, v1: rv.v1
			});
		}
		var rot = phi_official_quantize_scalar(rot_ranges);
		var alpha_ranges = [];
		for (var alpha_i = 0; alpha_i < array_length(_line.alpha); alpha_i++) {
			var av = _line.alpha[alpha_i];
			array_add(alpha_ranges, {
				t0: phi_sec_to_tick(av.t0, bpm),
				t1: phi_sec_to_tick(av.t1, bpm),
				v0: av.v0, v1: av.v1
			});
		}
		var alpha = phi_official_quantize_scalar(alpha_ranges);
		stats.move += array_length(move);
		stats.rotate += array_length(rot);
		stats.alpha += array_length(alpha);
		stats.speed += array_length(_speed);
		array_add(judge, {
			bpm: bpm,
			notesAbove: above,
			notesBelow: below,
			speedEvents: _speed,
			judgeLineMoveEvents: move,
			judgeLineRotateEvents: rot,
			judgeLineDisappearEvents: alpha
		});
	}
	stats.lines = array_length(judge);
	return {
		formatVersion: int64(3),
		offset: baked.offsetMs / 1000,
		judgeLineList: judge,
		stats: stats
	};
}

// phira 把 formatVersion 读成 u32、音符类型读成 u8。json_stringify 会写成 3.0，serde 会拒绝
///@desc 把官谱写成 JSON，并把整数字段收成整数文本
///@param {Struct} chart 官谱
///@param {Bool} pretty 是否缩进
///@returns {String} JSON 文本
function phi_official_json_text(chart, pretty) {
	var text = json_stringify(chart, pretty);
	text = string_replace_all(text, "\"formatVersion\": 3.0", "\"formatVersion\": 3");
	text = string_replace_all(text, "\"formatVersion\":3.0", "\"formatVersion\":3");
	var type_n = 1;
	// 四种音符类型的 1.0 到 4.0 都改成整数
	repeat (4) {
		var type_real = "\"type\": " + string(type_n) + ".0";
		var type_real_tight = "\"type\":" + string(type_n) + ".0";
		var type_int = "\"type\": " + string(type_n);
		var type_int_tight = "\"type\":" + string(type_n);
		text = string_replace_all(text, type_real, type_int);
		text = string_replace_all(text, type_real_tight, type_int_tight);
		type_n += 1;
	}
	return text;
}

///@desc 追加一条瞬时 PEC 命令
///@param {Array} commands 命令列表
///@param {String} head 命令头
///@param {Real} beat 拍数
///@param {Array} fields 后续数值
///@returns {Undefined} 无
function phi_pec_emit_instant(commands, head, beat, fields) {
	var _line = head + " " + phi_num_text(beat);
	for (var i = 0; i < array_length(fields); i++) _line += " " + phi_num_text(fields[i]);
	array_add(commands, _line);
}

///@desc 把烘焙结果写成 PEC 命令文本
///@param {Struct} baked 烘焙结果
///@returns {Any} 含 text 与 stats 的结构，无效输入为未定义
function phi_baked_to_pec(baked) {
	if (!is_struct(baked)) then return undefined;
	var stats = baked.stats;
	stats.source = "RPE>PEC";
	stats.notes = 0;
	stats.move = 0;
	stats.rotate = 0;
	stats.alpha = 0;
	stats.speed = 0;
	var commands = [phi_num_text(baked.offsetMs)];
	var timeline = baked.timeline;
	for (var bpm_i = 0; bpm_i < array_length(timeline); bpm_i++) {
		array_add(commands, "bp " + phi_num_text(timeline[bpm_i].startBeat) + " " + phi_num_text(timeline[bpm_i].bpm));
	}
	for (var line_i = 0; line_i < array_length(baked.lines); line_i++) {
		var _line = baked.lines[line_i];
		stats.move += array_length(_line.move);
		stats.rotate += array_length(_line.rot);
		stats.alpha += array_length(_line.alpha);
		stats.speed += array_length(_line.speed);
		var _id = string(line_i);
		var prev_x = 0;
		var prev_y = 1;
		var move = _line.move;
		// 没有移动时停在画面中心
		if (array_length(move) <= 0) then array_add(move, { t0: 0, t1: 1, x0: 0.5, y0: 0.5, x1: 0.5, y1: 0.5 });
		for (var move_i = 0; move_i < array_length(move); move_i++) {
			var mv = move[move_i];
			var b0 = phi_timeline_sec_to_beat(timeline, mv.t0);
			var b1 = phi_timeline_sec_to_beat(timeline, mv.t1);
			if (abs(mv.x0 - prev_x) > 0.00001 || abs(mv.y0 - prev_y) > 0.00001) {
				phi_pec_emit_instant(commands, "cp " + _id, b0, [mv.x0 * 2048, mv.y0 * 1400]);
				prev_x = mv.x0;
				prev_y = mv.y0;
			}
			if (abs(b1 - b0) <= 0.0000001) {
				if (abs(mv.x1 - prev_x) > 0.00001 || abs(mv.y1 - prev_y) > 0.00001) {
					phi_pec_emit_instant(commands, "cp " + _id, b0, [mv.x1 * 2048, mv.y1 * 1400]);
				}
			} else if (abs(mv.x1 - prev_x) > 0.00001 || abs(mv.y1 - prev_y) > 0.00001) {
				var move_ease = floor(phi_finite_or(mv[$ "ease"] ?? 1, 1));
				if (move_ease < 1) then move_ease = 1;
				array_add(commands, "cm " + _id + " " + phi_num_text(b0) + " " + phi_num_text(b1) + " "
					+ phi_num_text(mv.x1 * 2048) + " " + phi_num_text(mv.y1 * 1400) + " " + string(move_ease));
			}
			prev_x = mv.x1;
			prev_y = mv.y1;
		}
		var prev_r = 0;
		for (var rot_i = 0; rot_i < array_length(_line.rot); rot_i++) {
			var rv = _line.rot[rot_i];
			var rb0 = phi_timeline_sec_to_beat(timeline, rv.t0);
			var rb1 = phi_timeline_sec_to_beat(timeline, rv.t1);
			var file_r0 = -rv.v0;
			var file_r1 = -rv.v1;
			if (abs(file_r0 - prev_r) > 0.0001) {
				phi_pec_emit_instant(commands, "cd " + _id, rb0, [file_r0]);
				prev_r = file_r0;
			}
			if (abs(rb1 - rb0) <= 0.0000001) {
				if (abs(file_r1 - prev_r) > 0.0001) then phi_pec_emit_instant(commands, "cd " + _id, rb0, [file_r1]);
			} else if (abs(file_r1 - prev_r) > 0.0001) {
				var rot_ease = floor(phi_finite_or(rv[$ "ease"] ?? 1, 1));
				if (rot_ease < 1) then rot_ease = 1;
				array_add(commands, "cr " + _id + " " + phi_num_text(rb0) + " " + phi_num_text(rb1) + " " + phi_num_text(file_r1) + " " + string(rot_ease));
			}
			prev_r = file_r1;
		}
		var prev_a = 255;
		var alpha_started = false;
		for (var alpha_i = 0; alpha_i < array_length(_line.alpha); alpha_i++) {
			var av = _line.alpha[alpha_i];
			var ab0 = phi_timeline_sec_to_beat(timeline, av.t0);
			var ab1 = phi_timeline_sec_to_beat(timeline, av.t1);
			var a0 = phi_pec_alpha_file(av.v0);
			var a1 = phi_pec_alpha_file(av.v1);
			if (!alpha_started || abs(a0 - prev_a) > 0.05) {
				phi_pec_emit_instant(commands, "ca " + _id, ab0, [a0]);
				prev_a = a0;
				alpha_started = true;
			}
			if (abs(ab1 - ab0) <= 0.0000001) {
				if (abs(a1 - prev_a) > 0.05) then phi_pec_emit_instant(commands, "ca " + _id, ab0, [a1]);
			} else if (abs(a1 - prev_a) > 0.05) {
				var alpha_ease = floor(phi_finite_or(av[$ "ease"] ?? 1, 1));
				if (alpha_ease < 1) then alpha_ease = 1;
				array_add(commands, "cf " + _id + " " + phi_num_text(ab0) + " " + phi_num_text(ab1) + " " + phi_num_text(a1) + " " + string(alpha_ease));
			}
			prev_a = a1;
		}
		var prev_speed = undefined;
		for (var speed_i = 0; speed_i < array_length(_line.speed); speed_i++) {
			var sv = _line.speed[speed_i];
			if (is_undefined(prev_speed) || abs(sv.value - prev_speed) > 0.00001) {
				var sb = phi_timeline_sec_to_beat(timeline, sv.t0);
				phi_pec_emit_instant(commands, "cv " + _id, sb, [sv.value * 7]);
				prev_speed = sv.value;
			}
		}
		for (var note_i = 0; note_i < array_length(_line.notes); note_i++) {
			var note = _line.notes[note_i];
			var head = "n1";
			if (note.rpeType == 2) then head = "n2";
			else if (note.rpeType == 3) then head = "n3";
			else if (note.rpeType == 4) then head = "n4";
			var nb0 = phi_timeline_sec_to_beat(timeline, note.startSec);
			var nb1 = phi_timeline_sec_to_beat(timeline, note.endSec);
			var file_x = note.officialX * 115.2;
			var side = note.above ? 1 : 2;
			var fake = note.fake ? 1 : 0;
			var body = head + " " + _id + " " + phi_num_text(nb0);
			if (note.rpeType == 2) then body += " " + phi_num_text(nb1);
			body += " " + phi_num_text(file_x) + " " + string(side) + " " + string(fake);
			array_add(commands, body);
			array_add(commands, "# " + phi_num_text(phi_finite_or(note[$ "speed"] ?? 1, 1)));
			array_add(commands, "& " + phi_num_text(phi_finite_or(note[$ "width"] ?? 1, 1)));
			stats.notes++;
		}
	}
	var text = phi_join_lines(commands) + "\n";
	return { text: text, stats: stats };
}

///@desc 把命令行拼成文本，避免一次拼接过长
///@param {Array} commands 命令行
///@returns {String} 用换行连接的文本
function phi_join_lines(commands) {
	var parts = [];
	var chunk = "";
	var count = 0;
	var total = array_length(commands);
	for (var i = 0; i < total; i++) {
		if (count > 0) then chunk += "\n";
		chunk += commands[i];
		count++;
		// 先按 32 行分块，再两两合并
		if (count >= 32) {
			array_add(parts, chunk);
			chunk = "";
			count = 0;
		}
	}
	if (string_length(chunk)) then array_add(parts, chunk);
	while (array_length(parts) > 1) {
		var merged = [];
		var part_n = array_length(parts);
		for (var p = 0; p < part_n; p += 2) {
			if (p + 1 < part_n) then array_add(merged, parts[p] + "\n" + parts[p + 1]);
			else array_add(merged, parts[p]);
		}
		parts = merged;
	}
	if (array_length(parts) <= 0) then return "";
	return parts[0];
}

///@desc 把 RPE 谱面烘焙成官谱
///@param {Struct} chart RPE 谱面
///@returns {Any} 官谱，失败为未定义
function phi_rpe_to_official(chart) {
	var baked = phi_rpe_bake(chart);
	// 烘焙失败就不再写成官谱
	if (!is_struct(baked)) then return undefined;
	return phi_baked_to_official(baked, "RPE>Official");
}

///@desc 在输出目录写官谱包，并复制音画。供 PLS_CONVERT_OUT 使用
///@param {String} out_dir 输出目录
///@returns {Bool} 写出 chart.json 为真
function phi_convert_package(out_dir) {
	var session = chart_session_ensure();
	if (!is_struct(session) || !session.ready) then return false;
	var root = session.active_dir;
	var chart_text = chart_read_text_file(chart_path_join(root, session.chart_file), -1);
	if (!is_string(chart_text) || !string_length(chart_text)) then return false;
	var built = undefined;
	if (session.format == CHART_FORMAT.RPE) {
		var parsed = phi_rpe_chart_value(chart_text);
		if (!is_struct(parsed)) then return false;
		built = phi_rpe_to_official(parsed);
		delete(parsed);
	} else if (session.format == CHART_FORMAT.PEC) {
		built = phi_pec_to_official(chart_text);
	// 只有 RPE 和 PEC 能转成官谱包
	} else return false;
	if (!is_struct(built)) then return false;
	var convert_stats = built[$ "stats"];
	if (is_struct(convert_stats)) then phi_tools_event_report(convert_stats);
	variable_struct_remove(built, "stats");
	if (!directory_exists(out_dir)) then directory_create(out_dir);
	var chart_name = "chart.json";
	chart_buffer_save_text(chart_path_join(out_dir, chart_name), phi_official_json_text(built, false));
	delete(built);
	var music_name = chart_path_file_name(session.music_file);
	var image_name = chart_path_file_name(session.image_file);
	if (string_length(session.music_file)) then file_copy(chart_path_join(root, session.music_file), chart_path_join(out_dir, music_name));
	if (string_length(session.image_file)) then file_copy(chart_path_join(root, session.image_file), chart_path_join(out_dir, image_name));
	chart_buffer_save_text(chart_path_join(out_dir, "info.txt"),
		"Name: " + string(session.name ?? "")
		+ "\nLevel: " + string(session.level ?? "")
		+ "\nComposer: " + string(session.composer ?? "")
		+ "\nCharter: " + string(session.charter ?? "")
		+ "\nSong: " + music_name
		+ "\nPicture: " + image_name
		+ "\nChart: " + chart_name
		+ "\nOffset: 0\n");
	print($"[ConvertPlay] wrote {chart_path_join(out_dir, chart_name)}");
	return file_exists(chart_path_join(out_dir, chart_name));
}

///@desc 判断 RPE 事件能否直接写成一条 PEC 缓动
///@param {Struct} ev 事件
///@returns {Bool} 无贝塞尔且窗口完整为真
function phi_rpe_event_plain(ev) {
	if (!is_struct(ev)) then return false;
	var points = ev[$ "bezierPoints"];
	// 贝塞尔和局部缓动窗口都不能直接写成 PEC
	if (bool(ev[$ "bezier"] ?? 0) && is_array(points) && array_length(points) >= 4) then return false;
	var left = phi_finite_or(ev[$ "easingLeft"] ?? 0, 0);
	var right = phi_finite_or(ev[$ "easingRight"] ?? 1, 1);
	if (abs(left - right) <= 0.000001) then return true;
	if (abs(left) > 0.0001 || abs(right - 1) > 0.0001) then return false;
	return true;
}

///@desc 把 RPE 缓动号换成 PEC 文件里的缓动号
///@param {Struct} ev 事件
///@returns {Real} PEC 缓动号
function phi_rpe_ease_file(ev) {
	var ease_id = floor(phi_finite_or(ev[$ "easingType"] ?? 1, 1));
	if (ease_id < 1) then return 1;
	// PEC 播放用文件号查表。离开 1 到 15 的对合后，文件号不是谱面里的原始号
	return phi_pec_ease_from_rpe(ease_id);
}

///@desc 把 RPE 透明度单位换成 PEC 的 0 到 255
///@param {Real} unit 0 到 1 的透明度，负数表示隐藏
///@returns {Real} PEC 透明度，隐藏为 -1
function phi_pec_alpha_file(unit) {
	// RPE 负透明度表示隐藏，PEC 用 -1。小于等于 -100 是 Phira 的提前出现，不能原样写成 -255
	if (phi_finite_or(unit, 0) <= -0.5 / 255) then return -1;
	return clamp(unit, 0, 1) * 255;
}

///@desc 取出事件层里某一通道的结构数组
///@param {Struct} layer 事件层
///@param {String} key 通道名
///@returns {Array} 事件，没有时为空数组
function phi_rpe_collect_events(layer, key) {
	if (!is_struct(layer)) then return [];
	var raw = layer[$ key];
	if (!is_array(raw)) then return [];
	var out = [];
	for (var i = 0; i < array_length(raw); i++) {
		if (is_struct(raw[i])) then array_add(out, raw[i]);
	}
	return out;
}

// PEC 的 cm、cr、cf 只存一种缓动。没有父线、只有一层、且没有贝塞尔或局部窗口时才能直接写
///@desc 判断判定线能否不烘焙就写成 PEC
///@param {Struct} src 判定线
///@returns {Bool} 可以直接写为真
function phi_rpe_line_pec_direct(src) {
	if (!is_struct(src)) then return true;
	// 有父线或 BPM 因子不是 1 时必须烘焙
	if (floor(phi_finite_or(src[$ "father"] ?? -1, -1)) >= 0) then return false;
	var factor = phi_finite_or(src[$ "bpmfactor"] ?? 1, 1);
	if (abs(factor - 1) > 0.0001) then return false;
	var layers = src[$ "eventLayers"];
	if (!is_array(layers)) then return true;
	var used = 0;
	for (var i = 0; i < array_length(layers); i++) {
		var _layer = layers[i];
		if (!is_struct(_layer)) then continue;
		var keys = ["moveXEvents", "moveYEvents", "rotateEvents", "alphaEvents"];
		var any = false;
		for (var k = 0; k < array_length(keys); k++) {
			var list = phi_rpe_collect_events(_layer, keys[k]);
			if (array_length(list) <= 0) then continue;
			any = true;
			for (var e = 0; e < array_length(list); e++) {
				if (!phi_rpe_event_plain(list[e])) then return false;
			}
		}
		if (any) then used++;
	}
	return used <= 1;
}

///@desc 按开始和结束拍排序 RPE 事件
///@param {Array} events 事件，会被原地排序
///@returns {Undefined} 无
function phi_rpe_sort_events(events) {
	if (array_length(events) <= 1) then return;
	array_sort(events, function(a, b) {
		var cmp = pec_cmp_real(rpe_array_to_beat(a[$ "startTime"] ?? 0), rpe_array_to_beat(b[$ "startTime"] ?? 0));
		if (cmp != 0) then return cmp;
		return pec_cmp_real(rpe_array_to_beat(a[$ "endTime"] ?? 0), rpe_array_to_beat(b[$ "endTime"] ?? 0));
	});
}

///@desc 把成对的 X、Y 事件合成归一化移动
///@param {Array} xs 横向事件
///@param {Array} ys 纵向事件
///@param {Array} timeline BPM 时间轴
///@returns {Any} 移动片段，对不齐时未定义
function phi_rpe_xy_move(xs, ys, timeline) {
	phi_rpe_sort_events(xs);
	phi_rpe_sort_events(ys);
	// 两轴条数、缓动或时间对不齐就不能直接合成
	if (array_length(xs) != array_length(ys)) then return undefined;
	var out = [];
	for (var i = 0; i < array_length(xs); i++) {
		if (!phi_rpe_event_plain(xs[i]) || !phi_rpe_event_plain(ys[i])) then return undefined;
		if (phi_rpe_ease_file(xs[i]) != phi_rpe_ease_file(ys[i])) then return undefined;
		var x_b0 = rpe_array_to_beat(xs[i][$ "startTime"] ?? 0);
		var x_b1 = rpe_array_to_beat(xs[i][$ "endTime"] ?? xs[i][$ "startTime"] ?? 0);
		var y_b0 = rpe_array_to_beat(ys[i][$ "startTime"] ?? 0);
		var y_b1 = rpe_array_to_beat(ys[i][$ "endTime"] ?? ys[i][$ "startTime"] ?? 0);
		if (abs(x_b0 - y_b0) > 0.000001 || abs(x_b1 - y_b1) > 0.000001) then return undefined;
		var x0 = phi_finite_or(xs[i][$ "start"] ?? 0, 0);
		var x1 = phi_finite_or(xs[i][$ "end"] ?? x0, x0);
		var y0 = phi_finite_or(ys[i][$ "start"] ?? 0, 0);
		var y1 = phi_finite_or(ys[i][$ "end"] ?? y0, y0);
		array_add(out, {
			t0: phi_timeline_beat_to_sec(timeline, x_b0),
			t1: phi_timeline_beat_to_sec(timeline, x_b1),
			x0: 0.5 + x0 / 1350,
			y0: 0.5 + y0 / 900,
			x1: 0.5 + x1 / 1350,
			y1: 0.5 + y1 / 900,
			ease: phi_rpe_ease_file(xs[i])
		});
	}
	return out;
}

///@desc 把一条标量通道换成秒时间并缩放
///@param {Array} raw 原始事件
///@param {Array} timeline BPM 时间轴
///@param {Real} scale 数值缩放
///@param {Real} shift 数值偏移
///@returns {Any} 标量片段，遇到复杂缓动为未定义
function phi_rpe_scalar_channel(raw, timeline, scale, shift) {
	phi_rpe_sort_events(raw);
	var out = [];
	for (var i = 0; i < array_length(raw); i++) {
		if (!phi_rpe_event_plain(raw[i])) then return undefined;
		var b0 = rpe_array_to_beat(raw[i][$ "startTime"] ?? 0);
		var b1 = rpe_array_to_beat(raw[i][$ "endTime"] ?? raw[i][$ "startTime"] ?? 0);
		var v0 = phi_finite_or(raw[i][$ "start"] ?? 0, 0);
		var v1 = phi_finite_or(raw[i][$ "end"] ?? v0, v0);
		array_add(out, {
			t0: phi_timeline_beat_to_sec(timeline, b0),
			t1: phi_timeline_beat_to_sec(timeline, b1),
			v0: v0 * scale + shift,
			v1: v1 * scale + shift,
			ease: phi_rpe_ease_file(raw[i])
		});
	}
	return out;
}

///@desc 把两轴缓动展开成线性移动片段
///@param {Array} xs 已预处理的横向事件
///@param {Array} ys 已预处理的纵向事件
///@param {Real} t_end 结束秒
///@param {Real} x_scale 横向缩放
///@param {Real} x_shift 横向偏移
///@param {Real} y_scale 纵向缩放
///@param {Real} y_shift 纵向偏移
///@desc 把两轴缓动展开成线性移动片段
///@returns {Array} 线性移动片段
function phi_rpe_linear_pair(xs, ys, t_end, x_scale, x_shift, y_scale, y_shift) {
	// 先把非线性事件切成固定线性段，再按共同结点采样
	xs = phi_expand_channel(xs);
	ys = phi_expand_channel(ys);
	var extra = [];
	phi_knots_from_prepared(extra, xs);
	phi_knots_from_prepared(extra, ys);
	var knots = phi_knots_unique(extra, 0, max(0.001, t_end));
	var xctx = { kind: "list", events: xs, empty: 0 };
	var yctx = { kind: "list", events: ys, empty: 0 };
	var out = [];
	for (var i = 0; i < array_length(knots) - 1; i++) {
		var t0 = knots[i];
		var t1 = knots[i + 1];
		if (t1 - t0 <= 0.0000001) then continue;
		array_add(out, {
			t0: t0, t1: t1,
			x0: phi_ctx_scalar(xctx, t0) * x_scale + x_shift,
			y0: phi_ctx_scalar(yctx, t0) * y_scale + y_shift,
			x1: phi_ctx_scalar(xctx, t1) * x_scale + x_shift,
			y1: phi_ctx_scalar(yctx, t1) * y_scale + y_shift,
			ease: 1
		});
	}
	return out;
}

///@desc 把标量事件展开成线性片段
///@param {Array} raw 原始事件
///@param {Array} timeline BPM 时间轴
///@param {Real} t_end 结束秒
///@param {Real} scale 数值缩放
///@param {Real} shift 数值偏移
///@returns {Array} 线性片段
function phi_rpe_linear_scalar(raw, timeline, t_end, scale, shift) {
	var prepared = phi_expand_channel(phi_prep_events(raw, timeline));
	var extra = [];
	phi_knots_from_prepared(extra, prepared);
	var knots = phi_knots_unique(extra, 0, max(0.001, t_end));
	var ctx = { kind: "list", events: prepared, empty: 0 };
	var out = [];
	for (var i = 0; i < array_length(knots) - 1; i++) {
		var t0 = knots[i];
		var t1 = knots[i + 1];
		if (t1 - t0 <= 0.0000001) then continue;
		array_add(out, {
			t0: t0, t1: t1,
			v0: phi_ctx_scalar(ctx, t0) * scale + shift,
			v1: phi_ctx_scalar(ctx, t1) * scale + shift,
			ease: 1
		});
	}
	return out;
}

///@desc 读取事件某个时间字段的拍数
///@param {Struct} ev 事件
///@param {String} key 字段名
///@returns {Real} 拍数
function phi_ev_beat(ev, key) {
	return rpe_array_to_beat(ev[$ key] ?? 0);
}

///@desc 查看拍区间被哪条事件覆盖
///@param {Array} events 已排序事件
///@param {Real} b0 起点拍
///@param {Real} b1 终点拍
///@returns {Struct} mode 为 full、partial 或 hold
function phi_cover_event(events, b0, b1) {
	var hold = 0;
	for (var i = 0; i < array_length(events); i++) {
		var ev = events[i];
		var s = phi_ev_beat(ev, "startTime");
		var e = phi_ev_beat(ev, "endTime");
		if (e < s) then e = s;
		var v0 = phi_finite_or(ev[$ "start"] ?? 0, 0);
		var v1 = phi_finite_or(ev[$ "end"] ?? v0, v0);
		// 已经结束的事件只留下末值
		if (e <= b0 + 0.0000001) {
			hold = v1;
			continue;
		}
		if (s >= b1 - 0.0000001) then break;
		var full = abs(s - b0) <= 0.0005 && abs(e - b1) <= 0.0005;
		return { mode: (full ? "full" : "partial"), ev: ev, v0: v0, v1: v1, ease: phi_rpe_ease_file(ev) };
	}
	return { mode: "hold", ev: undefined, v0: hold, v1: hold, ease: 1 };
}

///@desc 在指定拍采样一条原始 RPE 事件
///@param {Struct} ev 事件
///@param {Real} beat 拍数
///@returns {Real} 采样值
function phi_raw_sample(ev, beat) {
	var s = phi_ev_beat(ev, "startTime");
	var e = phi_ev_beat(ev, "endTime");
	var v0 = phi_finite_or(ev[$ "start"] ?? 0, 0);
	var v1 = phi_finite_or(ev[$ "end"] ?? v0, v0);
	var left = phi_finite_or(ev[$ "easingLeft"] ?? 0, 0);
	var right = phi_finite_or(ev[$ "easingRight"] ?? 1, 1);
	// 窗口左右重合时退回整段缓动
	if (left == right) {
		left = 0;
		right = 1;
	}
	var points = ev[$ "bezierPoints"];
	return phi_sample_event({
		t0: s, t1: max(e, s), v0: v0, v1: v1,
		ease: rpe_map_easing_id(ev[$ "easingType"] ?? 1),
		e0: left, e1: right,
		bezier: bool(ev[$ "bezier"] ?? 0) && is_array(points) && array_length(points) >= 4,
		pts: points
	}, beat);
}

///@desc 把多层事件在一段拍上的值加起来
///@param {Array} lists 多层事件
///@param {Real} b0 起点拍
///@param {Real} b1 终点拍
///@returns {Struct} 含 v0、v1、ease 与是否必须切片
function phi_span_sum(lists, b0, b1) {
	var sum0 = 0;
	var sum1 = 0;
	var ease = 1;
	var have_ease = false;
	var must_slice = false;
	for (var li = 0; li < array_length(lists); li++) {
		var cover = phi_cover_event(lists[li], b0, b1);
		// 只盖住一部分或缓动不一致时不能合成一条
		if (cover.mode == "partial") {
			must_slice = true;
			sum0 += phi_raw_sample(cover.ev, b0);
			sum1 += phi_raw_sample(cover.ev, b1);
		} else {
			sum0 += cover.v0;
			sum1 += cover.v1;
			if (cover.mode == "full" && abs(cover.v1 - cover.v0) > 0.0001) {
				if (!have_ease) {
					ease = cover.ease;
					have_ease = true;
				} else if (ease != cover.ease) then must_slice = true;
			}
		}
	}
	return { v0: sum0, v1: sum1, ease: ease, slice: must_slice };
}

///@desc 收集多层事件的起止拍并去重
///@param {Array} lists 多层事件
///@returns {Array} 拍结点
function phi_beat_bounds(lists) {
	var beats = [0];
	for (var li = 0; li < array_length(lists); li++) {
		var events = lists[li];
		for (var i = 0; i < array_length(events); i++) {
			array_add(beats, phi_ev_beat(events[i], "startTime"));
			array_add(beats, phi_ev_beat(events[i], "endTime"));
		}
	}
	array_sort(beats, pec_cmp_real);
	var out = [];
	for (var j = 0; j < array_length(beats); j++) {
		var beat = beats[j];
		if (!is_finite(beat)) then continue;
		var n = array_length(out);
		if (n > 0 && abs(out[n - 1] - beat) <= 0.0005) then continue;
		array_add(out, beat);
	}
	if (array_length(out) <= 0) then array_add(out, 0);
	return out;
}

///@desc 在拍点的跳变前或跳变后求多层合计
///@param {Array} lists 多层事件
///@param {Real} beat 拍数
///@param {Bool} after_jump 为真时取跳变后的值
///@returns {Real} 合计值
function phi_sum_at_edge(lists, beat, after_jump) {
	var sum = 0;
	var list_n = array_length(lists);
	for (var li = 0; li < list_n; li++) {
		var events = lists[li];
		var n = array_length(events);
		var hold = 0;
		var saw = false;
		var sampled = false;
		for (var i = 0; i < n; i++) {
			var ev = events[i];
			var s = phi_ev_beat(ev, "startTime");
			var e = phi_ev_beat(ev, "endTime");
			if (e < s) then e = s;
			if (beat < s - 0.0000001) then break;
			var at_start = abs(beat - s) <= 0.0000001;
			var at_end = abs(beat - e) <= 0.0000001;
			if (beat > e + 0.0000001) {
				hold = phi_finite_or(ev[$ "end"] ?? ev[$ "start"] ?? 0, 0);
				saw = true;
				continue;
			}
			// 跳变夹在同一拍的两段之间。结束的那段保留旧值，开始的那段取新值，写出时用 cp
			if (!after_jump && at_start) {
				if (!saw) then hold = phi_finite_or(ev[$ "start"] ?? 0, 0);
				saw = true;
				break;
			}
			if (after_jump && at_end && !at_start) {
				hold = phi_finite_or(ev[$ "end"] ?? ev[$ "start"] ?? 0, 0);
				saw = true;
				continue;
			}
			sum += phi_raw_sample(ev, beat);
			sampled = true;
			break;
		}
		if (sampled) {
			continue;
		}
		if (saw) then sum += hold;
		else if (n > 0) then sum += phi_finite_or(events[0][$ "start"] ?? 0, 0);
	}
	return sum;
}

///@desc 在拍点取跳变前的多层合计
///@param {Array} lists 多层事件
///@param {Real} beat 拍数
///@returns {Real} 合计值
function phi_sum_at(lists, beat) {
	return phi_sum_at_edge(lists, beat, false);
}

///@desc 只收集数值真正变化或跳变的拍点
///@param {Array} lists 多层事件
///@returns {Array} 拍结点
function phi_motion_bounds(lists) {
	var beats = [0];
	for (var li = 0; li < array_length(lists); li++) {
		var events = lists[li];
		var hold = undefined;
		for (var i = 0; i < array_length(events); i++) {
			var ev = events[i];
			var s = phi_ev_beat(ev, "startTime");
			var e = phi_ev_beat(ev, "endTime");
			if (e < s) then e = s;
			var v0 = phi_finite_or(ev[$ "start"] ?? 0, 0);
			var v1 = phi_finite_or(ev[$ "end"] ?? v0, v0);
			var jumps = false;
			if (!is_undefined(hold) && abs(v0 - hold) > 0.0001) then jumps = true;
			var changes = abs(v1 - v0) > 0.0001;
			if (jumps || changes) then array_add(beats, s);
			if (changes && e > s + 0.0000001) then array_add(beats, e);
			hold = v1;
		}
	}
	array_sort(beats, pec_cmp_real);
	var out = [];
	for (var j = 0; j < array_length(beats); j++) {
		var beat = beats[j];
		if (!is_finite(beat)) then continue;
		var n = array_length(out);
		if (n > 0 && abs(out[n - 1] - beat) <= 0.0005) then continue;
		array_add(out, beat);
	}
	if (array_length(out) <= 0) then array_add(out, 0);
	return out;
}

///@desc 按拍长决定一段要切成几片，限制在 6 到 32
///@param {Real} b0 起点拍
///@param {Real} b1 终点拍
///@returns {Real} 片数
function phi_rpe_pieces(b0, b1) {
	var n = ceil((b1 - b0) * 10);
	if (n < 6) then n = 6;
	if (n > 32) then n = 32;
	return n;
}

///@desc 累计一层轴在拍区间里走过的绝对值
///@param {Array} lists 多层事件
///@param {Real} t0 起点拍
///@param {Real} t1 终点拍
///@returns {Real} 行程
function phi_axis_travel(lists, t0, t1) {
	var travel = 0;
	for (var li = 0; li < array_length(lists); li++) {
		var events = lists[li];
		var hold = undefined;
		for (var i = 0; i < array_length(events); i++) {
			var ev = events[i];
			var s = phi_ev_beat(ev, "startTime");
			var e = phi_ev_beat(ev, "endTime");
			if (e < s) then e = s;
			var v0 = phi_finite_or(ev[$ "start"] ?? 0, 0);
			var v1 = phi_finite_or(ev[$ "end"] ?? v0, v0);
			if (e < t0 - 0.0000001) {
				hold = v1;
				continue;
			}
			if (s > t1 + 0.0000001) then break;
			if (!is_undefined(hold) && s > t0 + 0.0000001 && abs(v0 - hold) > 0.0001) then travel += abs(v0 - hold);
			var a = max(s, t0);
			var b = min(e, t1);
			if (b > a + 0.0000001) then travel += abs(phi_raw_sample(ev, b) - phi_raw_sample(ev, a));
			hold = v1;
		}
	}
	return travel;
}

///@desc 找出这段里唯一一条真正在变化的简单事件
///@param {Array} lists 多层事件
///@param {Real} b0 起点拍
///@param {Real} b1 终点拍
///@returns {Any} 事件，没有或多于一条时未定义
function phi_span_owner(lists, b0, b1) {
	var found = undefined;
	for (var li = 0; li < array_length(lists); li++) {
		var events = lists[li];
		for (var i = 0; i < array_length(events); i++) {
			var ev = events[i];
			var s = phi_ev_beat(ev, "startTime");
			var e = phi_ev_beat(ev, "endTime");
			if (e < s) then e = s;
			if (e <= b0 + 0.0000001 || s >= b1 - 0.0000001) then continue;
			var v0 = phi_finite_or(ev[$ "start"] ?? 0, 0);
			var v1 = phi_finite_or(ev[$ "end"] ?? v0, v0);
			if (abs(v1 - v0) <= 0.0001) then continue;
			if (!phi_rpe_event_plain(ev)) then return undefined;
			// 同时有两条变化就无法保留单条缓动
			if (!is_undefined(found)) then return undefined;
			found = ev;
		}
	}
	return found;
}

///@desc 把拍时间上的移动追加成归一化片段
///@param {Array} out 目标列表
///@param {Array} timeline BPM 时间轴
///@param {Real} b0 起点拍
///@param {Real} b1 终点拍
///@param {Real} x0 起点横坐标
///@param {Real} y0 起点纵坐标
///@param {Real} x1 终点横坐标
///@param {Real} y1 终点纵坐标
///@param {Real} ease 缓动号
///@desc 把拍时间上的移动追加成归一化片段
///@returns {Undefined} 无
function phi_move_push(out, timeline, b0, b1, x0, y0, x1, y1, ease) {
	array_add(out, {
		t0: phi_timeline_beat_to_sec(timeline, b0),
		t1: phi_timeline_beat_to_sec(timeline, b1),
		x0: 0.5 + x0 / 1350, y0: 0.5 + y0 / 900,
		x1: 0.5 + x1 / 1350, y1: 0.5 + y1 / 900,
		ease: ease
	});
}

///@desc 尝试把一条事件提升成整段缓动
///@param {Struct} own 候选事件
///@param {Array} own_lists 本轴的多层事件
///@param {Array} quiet_lists 另一轴的多层事件
///@param {Real} b0 当前起点拍
///@param {Real} quiet_limit 另一轴允许的行程
///@returns {Any} 成功为含 s、e、ease 的结构，否则未定义
function phi_promote_window(own, own_lists, quiet_lists, b0, quiet_limit) {
	var s = phi_ev_beat(own, "startTime");
	var e = phi_ev_beat(own, "endTime");
	if (e < s) then e = s;
	if (e <= s + 0.0000001) then return undefined;
	if (abs(s - b0) > 0.0005) then return undefined;
	var own_delta = abs(phi_finite_or(own[$ "end"] ?? 0, 0) - phi_finite_or(own[$ "start"] ?? 0, 0));
	if (phi_axis_travel(own_lists, s, e) > own_delta + 1) then return undefined;
	// 另一轴在这段里动得太多就不能整段提升
	if (phi_axis_travel(quiet_lists, s, e) > quiet_limit) then return undefined;
	return { s: s, e: e, ease: phi_rpe_ease_file(own) };
}

///@desc 在横纵两条候选里选择可以整段保留的缓动
///@param {Array} x_lists 横向多层事件
///@param {Array} y_lists 纵向多层事件
///@param {Real} b0 当前起点拍
///@param {Any} x_own 横向候选
///@param {Any} y_own 纵向候选
///@returns {Any} 提升结果，失败为未定义
function phi_promote_move(x_lists, y_lists, b0, x_own, y_own) {
	if (!is_undefined(x_own) && !is_undefined(y_own)) {
		var x_s = phi_ev_beat(x_own, "startTime");
		var x_e = phi_ev_beat(x_own, "endTime");
		var y_s = phi_ev_beat(y_own, "startTime");
		var y_e = phi_ev_beat(y_own, "endTime");
		if (y_s >= x_s - 0.0005 && y_e <= x_e + 0.0005) {
			var along_x = phi_promote_window(x_own, x_lists, y_lists, b0, 36);
			if (!is_undefined(along_x)) then return along_x;
		}
		if (x_s >= y_s - 0.0005 && x_e <= y_e + 0.0005) {
			var along_y = phi_promote_window(y_own, y_lists, x_lists, b0, 36);
			if (!is_undefined(along_y)) then return along_y;
		}
		return undefined;
	}
	if (!is_undefined(x_own)) then return phi_promote_window(x_own, x_lists, y_lists, b0, 36);
	if (!is_undefined(y_own)) then return phi_promote_window(y_own, y_lists, x_lists, b0, 36);
	return undefined;
}

///@desc 把多层 X、Y 合成 PEC 可用的移动片段
///@param {Array} x_lists 横向多层事件
///@param {Array} y_lists 纵向多层事件
///@param {Array} timeline BPM 时间轴
///@returns {Array} 移动片段
function phi_rpe_composite_move(x_lists, y_lists, timeline) {
	var lists = [];
	for (var i = 0; i < array_length(x_lists); i++) array_add(lists, x_lists[i]);
	for (var j = 0; j < array_length(y_lists); j++) array_add(lists, y_lists[j]);
	var bounds = phi_motion_bounds(lists);
	var out = [];
	if (array_length(bounds) < 2) {
		var x_hold = phi_sum_at_edge(x_lists, 0, true);
		var y_hold = phi_sum_at_edge(y_lists, 0, true);
		phi_move_push(out, timeline, 0, 0, x_hold, y_hold, x_hold, y_hold, 1);
		return out;
	}
	var b = 0;
	var bound_n = array_length(bounds);
	// 能提升成单条缓动就整段保留，否则切成线性小段
	while (b < bound_n - 1) {
		var b0 = bounds[b];
		var b1 = bounds[b + 1];
		if (b1 - b0 <= 0.0000001) {
			b++;
			continue;
		}
		var x_own = phi_span_owner(x_lists, b0, b1);
		var y_own = phi_span_owner(y_lists, b0, b1);
		var promoted = phi_promote_move(x_lists, y_lists, b0, x_own, y_own);
		if (!is_undefined(promoted)) {
			var px0 = phi_sum_at_edge(x_lists, promoted.s, true);
			var px1 = phi_sum_at_edge(x_lists, promoted.e, false);
			var py0 = phi_sum_at_edge(y_lists, promoted.s, true);
			var py1 = phi_sum_at_edge(y_lists, promoted.e, false);
			phi_move_push(out, timeline, promoted.s, promoted.e, px0, py0, px1, py1, promoted.ease);
			var next_b = b + 1;
			while (next_b < bound_n - 1 && bounds[next_b] < promoted.e - 0.0005) next_b++;
			b = next_b;
			continue;
		}
		var x0 = phi_sum_at_edge(x_lists, b0, true);
		var x1 = phi_sum_at_edge(x_lists, b1, false);
		var y0 = phi_sum_at_edge(y_lists, b0, true);
		var y1 = phi_sum_at_edge(y_lists, b1, false);
		var xs = phi_span_sum(x_lists, b0, b1);
		var ys = phi_span_sum(y_lists, b0, b1);
		var dx = abs(x1 - x0);
		var dy = abs(y1 - y0);
		var x_moves = dx > 0.05;
		var y_moves = dy > 0.05;
		var ease = 1;
		var slice = (x_moves && xs.slice) || (y_moves && ys.slice);
		if (!slice && x_moves && phi_axis_travel(x_lists, b0, b1) > dx + 1) then slice = true;
		if (!slice && y_moves && phi_axis_travel(y_lists, b0, b1) > dy + 1) then slice = true;
		if (!slice) {
			if (x_moves && y_moves && xs.ease != ys.ease) then slice = true;
			else if (x_moves) then ease = xs.ease;
			else if (y_moves) then ease = ys.ease;
		}
		if (slice && !xs.slice && !ys.slice) {
			if (dx <= 36 && dy > 36) {
				slice = false;
				ease = ys.ease;
			} else if (dy <= 36 && dx > 36) {
				slice = false;
				ease = xs.ease;
			}
		}
		if (!slice) {
			phi_move_push(out, timeline, b0, b1, x0, y0, x1, y1, ease);
		} else {
			var pieces = phi_rpe_pieces(b0, b1);
			var prev_b = b0;
			var sx = x0;
			var sy = y0;
			for (var step = 1; step <= pieces; step++) {
				var beat = b0 + (b1 - b0) * (step / pieces);
				var nx = x1;
				var ny = y1;
				if (step < pieces) {
					nx = phi_sum_at(x_lists, beat);
					ny = phi_sum_at(y_lists, beat);
				}
				phi_move_push(out, timeline, prev_b, beat, sx, sy, nx, ny, 1);
				prev_b = beat;
				sx = nx;
				sy = ny;
			}
		}
		b++;
	}
	return out;
}

///@desc 把多层标量合成 PEC 可用的片段
///@param {Array} lists 多层事件
///@param {Array} timeline BPM 时间轴
///@param {Real} scale 数值缩放
///@param {Real} shift 数值偏移
///@returns {Array} 标量片段
function phi_rpe_composite_scalar(lists, timeline, scale, shift) {
	var bounds = phi_motion_bounds(lists);
	var out = [];
	if (array_length(bounds) < 2) {
		var held = phi_sum_at_edge(lists, 0, true) * scale + shift;
		array_add(out, { t0: 0, t1: 0, v0: held, v1: held, ease: 1 });
		return out;
	}
	var b = 0;
	var bound_n = array_length(bounds);
	while (b < bound_n - 1) {
		var b0 = bounds[b];
		var b1 = bounds[b + 1];
		if (b1 - b0 <= 0.0000001) {
			b++;
			continue;
		}
		var own = phi_span_owner(lists, b0, b1);
		if (!is_undefined(own)) {
			var own_s = phi_ev_beat(own, "startTime");
			var own_e = phi_ev_beat(own, "endTime");
			if (own_e < own_s) then own_e = own_s;
			var own_delta = abs(phi_finite_or(own[$ "end"] ?? 0, 0) - phi_finite_or(own[$ "start"] ?? 0, 0));
			if (own_e > own_s + 0.0000001 && abs(own_s - b0) <= 0.0005 && phi_axis_travel(lists, own_s, own_e) <= own_delta + 0.05) {
				var whole0 = phi_sum_at_edge(lists, own_s, true);
				var whole1 = phi_sum_at_edge(lists, own_e, false);
				array_add(out, {
					t0: phi_timeline_beat_to_sec(timeline, own_s),
					t1: phi_timeline_beat_to_sec(timeline, own_e),
					v0: whole0 * scale + shift,
					v1: whole1 * scale + shift,
					ease: phi_rpe_ease_file(own)
				});
				var next_b = b + 1;
				while (next_b < bound_n - 1 && bounds[next_b] < own_e - 0.0005) next_b++;
				b = next_b;
				continue;
			}
		}
		var v0 = phi_sum_at_edge(lists, b0, true);
		var v1 = phi_sum_at_edge(lists, b1, false);
		var span = phi_span_sum(lists, b0, b1);
		var slice = span.slice && abs(v1 - v0) > 0.0001;
		// 数值几乎没走就不必切开
		if (slice && phi_axis_travel(lists, b0, b1) <= 0.0001) then slice = false;
		if (!slice) {
			array_add(out, {
				t0: phi_timeline_beat_to_sec(timeline, b0),
				t1: phi_timeline_beat_to_sec(timeline, b1),
				v0: v0 * scale + shift,
				v1: v1 * scale + shift,
				ease: (abs(v1 - v0) > 0.0001 ? span.ease : 1)
			});
		} else {
			var pieces = phi_rpe_pieces(b0, b1);
			var prev_b = b0;
			var prev = v0;
			for (var step = 1; step <= pieces; step++) {
				var beat = b0 + (b1 - b0) * (step / pieces);
				var now = v1;
				if (step < pieces) then now = phi_sum_at(lists, beat);
				array_add(out, {
					t0: phi_timeline_beat_to_sec(timeline, prev_b),
					t1: phi_timeline_beat_to_sec(timeline, beat),
					v0: prev * scale + shift,
					v1: now * scale + shift,
					ease: 1
				});
				prev_b = beat;
				prev = now;
			}
		}
		b++;
	}
	return out;
}

///@desc 收集父链位移和旋转的秒结点
///@param {Array} models 线模型
///@param {Array} chain 父链下标
///@param {Real} t_end 结束秒
///@returns {Array} 去重后的结点
function phi_pose_time_knots(models, chain, t_end) {
	var raw = [0, t_end];
	for (var ci = 0; ci < array_length(chain); ci++) {
		var layers = models[chain[ci]].layers;
		for (var li = 0; li < array_length(layers); li++) {
			var _layer = layers[li];
			var keys = ["x", "y", "r"];
			for (var ki = 0; ki < 3; ki++) {
				var events = _layer[$ keys[ki]];
				if (!is_array(events)) then continue;
				for (var ei = 0; ei < array_length(events); ei++) {
					array_add(raw, events[ei].t0);
					array_add(raw, events[ei].t1);
				}
			}
		}
	}
	array_sort(raw, pec_cmp_real);
	var out = [];
	for (var i = 0; i < array_length(raw); i++) {
		var t = raw[i];
		if (!is_finite(t) || t < 0) then continue;
		if (t > t_end) then t = t_end;
		var n = array_length(out);
		if (n > 0 && abs(out[n - 1] - t) <= 0.00005) then continue;
		array_add(out, t);
	}
	if (array_length(out) <= 0) then array_add(out, 0);
	if (array_length(out) == 1) then array_add(out, max(t_end, 0.001));
	return out;
}

///@desc 判断父链在区间内是否有非线性位移或旋转
///@param {Array} models 线模型
///@param {Array} chain 父链下标
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@returns {Bool} 有非线性事件为真
function phi_chain_eased(models, chain, t0, t1) {
	for (var ci = 0; ci < array_length(chain); ci++) {
		var layers = models[chain[ci]].layers;
		if (phi_layers_eased(layers, "x", t0, t1)) then return true;
		if (phi_layers_eased(layers, "y", t0, t1)) then return true;
		if (phi_layers_eased(layers, "r", t0, t1)) then return true;
	}
	return false;
}

///@desc 读取祖先链在该秒的原始旋转
///@param {Array} models 线模型
///@param {Array} chain 含自己的父链
///@param {Real} t 秒
///@param {Real} aspect 宽高比
///@returns {Real} 祖先旋转，没有祖先时为 0
function phi_ancestor_raw_r(models, chain, t, aspect) {
	if (array_length(chain) <= 1) then return 0;
	var anc = [];
	for (var i = 0; i < array_length(chain) - 1; i++) array_add(anc, chain[i]);
	return -phi_world_pose(models, anc, t, aspect).r;
}

///@desc 按缓动和父线转角决定世界坐标要切几段
///@param {Array} models 线模型
///@param {Array} chain 父链下标
///@param {Array} timeline BPM 时间轴
///@param {Real} aspect 宽高比
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@returns {Real} 段数
function phi_pec_world_pieces(models, chain, timeline, aspect, t0, t1) {
	var eased = phi_chain_eased(models, chain, t0, t1);
	var angle = 0;
	if (array_length(chain) > 1) {
		var left = t1 - 0.00002;
		if (left <= t0) then left = t0;
		angle = abs(phi_ancestor_raw_r(models, chain, left, aspect) - phi_ancestor_raw_r(models, chain, t0, aspect));
	}
	// 没有缓动且父线几乎不转时保持一段
	if (!eased && angle <= 0.2) then return 1;
	var b0 = phi_timeline_sec_to_beat(timeline, t0);
	var b1 = phi_timeline_sec_to_beat(timeline, t1);
	var n = ceil(max(0, b1 - b0) * 8);
	if (angle > 12) then n = max(n, ceil(angle / 6));
	if (n < 4) then n = 4;
	if (n > 48) then n = 48;
	return n;
}

// 父线姿态烘进 PEC 的移动和旋转。PEC 没有父线，父线转动会让子线走弧，这些段保持线性
///@desc 把父链世界坐标切成 PEC 的移动和旋转
///@param {Array} models 线模型
///@param {Array} chain 父链下标
///@param {Array} timeline BPM 时间轴
///@param {Real} aspect 宽高比
///@param {Real} t_end 结束秒
///@returns {Struct} 含 move 与 rot
function phi_pec_world_channels(models, chain, timeline, aspect, t_end) {
	var knots = phi_pose_time_knots(models, chain, t_end);
	var move = [];
	var rot = [];
	var knot_n = array_length(knots);
	for (var k = 0; k < knot_n - 1; k++) {
		var t0 = knots[k];
		var t1 = knots[k + 1];
		if (t1 - t0 <= 0.0000001) then continue;
		var pieces = phi_pec_world_pieces(models, chain, timeline, aspect, t0, t1);
		var prev_t = t0;
		var prev = phi_world_pose(models, chain, t0, aspect);
		for (var step = 1; step <= pieces; step++) {
			var t = t0 + (t1 - t0) * (step / pieces);
			var sample_t = t;
			// 段尾略提前采样，避免吃进下一段的跳变
			if (step == pieces && k < knot_n - 2) {
				sample_t = t - 0.00002;
				if (sample_t <= prev_t) then sample_t = t;
			}
			var now = phi_world_pose(models, chain, sample_t, aspect);
			array_add(move, {
				t0: prev_t, t1: t,
				x0: prev.x, y0: prev.y, x1: now.x, y1: now.y,
				ease: 1
			});
			array_add(rot, {
				t0: prev_t, t1: t,
				v0: prev.r, v1: now.r,
				ease: 1
			});
			prev_t = t;
			prev = now;
		}
	}
	if (array_length(move) <= 0) {
		var pose = phi_world_pose(models, chain, 0, aspect);
		array_add(move, { t0: 0, t1: 0, x0: pose.x, y0: pose.y, x1: pose.x, y1: pose.y, ease: 1 });
		array_add(rot, { t0: 0, t1: 0, v0: pose.r, v1: pose.r, ease: 1 });
	}
	return { move: move, rot: rot };
}

///@desc 把 RPE 谱面转换成 PEC 文本
///@param {Struct} chart RPE 谱面
///@returns {Any} 含 text 与 stats 的结构，无效输入为未定义
function phi_rpe_to_pec(chart) {
	if (!is_struct(chart) || !is_array(chart[$ "judgeLineList"])) then return undefined;
	var meta = chart[$ "META"];
	if (!is_struct(meta)) then meta = {};
	var version = phi_finite_or(meta[$ "RPEVersion"] ?? 0, 0);
	// 170 之前用旧速度表
	var legacy = version < 170;
	var timeline = phi_bpm_timeline(chart[$ "BPMList"]);
	var bpm = timeline[0].bpm;
	var source_lines = chart.judgeLineList;
	var baked_lines = [];
	var stats = {
		source: "RPE>PEC",
		lines: 0,
		notes: 0,
		version: version,
		legacySpeed: legacy,
		parents: 0,
		attachUI: 0,
		textures: 0,
		scaleLines: 0,
		special: 0,
		noteAlpha: 0,
		noteSize: 0,
		noteScale: 0,
		fakeDropped: 0,
		move: 0,
		rotate: 0,
		alpha: 0,
		speed: 0,
		sliced: 0
	};
	var pose_models = [];
	var aspect = phi_chart_aspect_of(meta);
	for (var line_i = 0; line_i < array_length(source_lines); line_i++) {
		var src = source_lines[line_i];
		if (!is_struct(src)) then src = {};
		var factor = phi_finite_or(src[$ "bpmfactor"] ?? 1, 1);
		if (!(factor > 0)) then factor = 1;
		var layers = src[$ "eventLayers"];
		if (!is_array(layers)) then layers = [];
		var content = undefined;
		for (var layer_i = 0; layer_i < array_length(layers); layer_i++) {
			if (!is_struct(layers[layer_i])) then continue;
			if (array_length(phi_rpe_collect_events(layers[layer_i], "moveXEvents"))
				+ array_length(phi_rpe_collect_events(layers[layer_i], "moveYEvents"))
				+ array_length(phi_rpe_collect_events(layers[layer_i], "rotateEvents"))
				+ array_length(phi_rpe_collect_events(layers[layer_i], "alphaEvents")) > 0) {
				content = layers[layer_i];
			}
		}
		if (!is_struct(content)) then content = {};
		var beat_speeds = [];
		for (var speed_i = 0; speed_i < array_length(layers); speed_i++) {
			var speed_raw = phi_speed_beats_from_raw(is_struct(layers[speed_i]) ? layers[speed_i][$ "speedEvents"] : []);
			if (array_length(speed_raw) > 0) then array_add(beat_speeds, phi_drop_extreme_speed_gaps(speed_raw));
		}
		var speed_model = { legacy: legacy, legacySegments: [], modern: [] };
		var line_end = 1;
		if (legacy) then speed_model.legacySegments = phi_build_legacy_speed(beat_speeds, timeline);
		else {
			for (var modern_i = 0; modern_i < array_length(beat_speeds); modern_i++) {
				var built_layer = phi_build_modern_layer(beat_speeds[modern_i], timeline);
				if (is_struct(built_layer)) then array_add(speed_model.modern, built_layer);
			}
		}
		var notes = [];
		var raw_notes = src[$ "notes"];
		if (is_array(raw_notes)) {
			for (var note_i = 0; note_i < array_length(raw_notes); note_i++) {
				var note = raw_notes[note_i];
				if (!is_struct(note)) then continue;
				var rpe_type = floor(phi_finite_or(note[$ "type"] ?? 1, 1));
				if (rpe_type < 1 || rpe_type > 4) then rpe_type = 1;
				var start_line = phi_timeline_beat_to_sec(timeline, rpe_array_to_beat(note[$ "startTime"] ?? 0));
				var end_line = phi_timeline_beat_to_sec(timeline, rpe_array_to_beat(note[$ "endTime"] ?? note[$ "startTime"] ?? 0));
				if (!is_finite(start_line)) then start_line = 0;
				if (!is_finite(end_line) || end_line < start_line) then end_line = start_line;
				line_end = max(line_end, end_line);
				if (abs(phi_finite_or(note[$ "alpha"] ?? 255, 255) - 255) > 0.5) then stats.noteAlpha++;
				if (abs(phi_finite_or(note[$ "size"] ?? 1, 1) - 1) > 0.0001) then stats.noteSize++;
				if (phi_note_xy_scaled(note)) then stats.noteScale++;
				var note_width = phi_finite_or(note[$ "size"] ?? 1, 1);
				if (variable_struct_exists(note, "sizeX")) then note_width = phi_finite_or(note[$ "sizeX"], note_width);
				array_add(notes, {
					rpeType: rpe_type,
					startSec: start_line * factor,
					endSec: end_line * factor,
					officialX: phi_finite_or(note[$ "positionX"] ?? 0, 0) / 75.375,
					speed: phi_finite_or(note[$ "speed"] ?? 1, 1),
					width: note_width,
					above: phi_note_above(note),
					fake: bool(note[$ "isFake"] ?? false),
					yOffset: 0
				});
			}
		}
		if (!is_finite(line_end) || line_end > 100000) then line_end = 100000;
		var x_lists = [];
		var y_lists = [];
		var r_lists = [];
		var a_lists = [];
		for (var layer_n = 0; layer_n < array_length(layers); layer_n++) {
			if (!is_struct(layers[layer_n])) then continue;
			var lx = phi_rpe_collect_events(layers[layer_n], "moveXEvents");
			var ly = phi_rpe_collect_events(layers[layer_n], "moveYEvents");
			var lr = phi_rpe_collect_events(layers[layer_n], "rotateEvents");
			var la = phi_rpe_collect_events(layers[layer_n], "alphaEvents");
			phi_rpe_sort_events(lx);
			phi_rpe_sort_events(ly);
			phi_rpe_sort_events(lr);
			phi_rpe_sort_events(la);
			if (array_length(lx) > 0) then array_add(x_lists, lx);
			if (array_length(ly) > 0) then array_add(y_lists, ly);
			if (array_length(lr) > 0) then array_add(r_lists, lr);
			if (array_length(la) > 0) then array_add(a_lists, la);
		}
		var father = floor(phi_finite_or(src[$ "father"] ?? -1, -1));
		if (father < 0 || father >= array_length(source_lines) || father == line_i) then father = -1;
		var prepared = [];
		var pose_end = line_end;
		for (var prep_i = 0; prep_i < array_length(layers); prep_i++) {
			if (!is_struct(layers[prep_i])) then continue;
			var prep_x = phi_prep_events(layers[prep_i][$ "moveXEvents"], timeline);
			var prep_y = phi_prep_events(layers[prep_i][$ "moveYEvents"], timeline);
			var prep_r = phi_prep_events(layers[prep_i][$ "rotateEvents"], timeline);
			var prep_sets = [prep_x, prep_y, prep_r];
			for (var prep_s = 0; prep_s < 3; prep_s++) {
				var prep_events = prep_sets[prep_s];
				for (var prep_e = 0; prep_e < array_length(prep_events); prep_e++) {
					pose_end = max(pose_end, prep_events[prep_e].t1);
				}
			}
			array_add(prepared, { x: prep_x, y: prep_y, r: prep_r });
		}
		array_add(pose_models, {
			father: father,
			rotFather: bool(src[$ "rotateWithFather"] ?? false),
			layers: prepared,
			endSec: pose_end
		});
		var move = [];
		var rot = [];
		if (father < 0) {
			move = phi_rpe_composite_move(x_lists, y_lists, timeline);
			rot = phi_rpe_composite_scalar(r_lists, timeline, -1, 0);
			if (array_length(move) <= 0) then array_add(move, { t0: 0, t1: 0, x0: 0.5, y0: 0.5, x1: 0.5, y1: 0.5, ease: 1 });
		} else {
			stats.parents++;
		}
		var alpha = phi_rpe_composite_scalar(a_lists, timeline, 1 / 255, 0);
		if (array_length(alpha) <= 0) then array_add(alpha, { t0: 0, t1: 0, v0: 0, v1: 0, ease: 1 });
		var _speed = phi_slice_speed(speed_model, phi_speed_knots(speed_model, 0, line_end), factor);
		if (array_length(_speed) <= 0) then array_add(_speed, { t0: 0, t1: line_end * factor, value: 0 });
		array_add(baked_lines, { move: move, rot: rot, alpha: alpha, speed: _speed, notes: notes });
	}
	for (var bake_i = 0; bake_i < array_length(pose_models); bake_i++) {
		if (pose_models[bake_i].father < 0) then continue;
		var chain = phi_parent_chain(pose_models, bake_i);
		if (array_length(chain) <= 1) then continue;
		var t_end = 0;
		for (var chain_i = 0; chain_i < array_length(chain); chain_i++) {
			t_end = max(t_end, pose_models[chain[chain_i]].endSec);
		}
		var world = phi_pec_world_channels(pose_models, chain, timeline, aspect, t_end);
		baked_lines[bake_i].move = world.move;
		baked_lines[bake_i].rot = world.rot;
	}
	stats.lines = array_length(baked_lines);
	return phi_baked_to_pec({
		offsetMs: phi_finite_or(meta[$ "offset"] ?? 0, 0),
		bpm: bpm,
		timeline: timeline,
		lines: baked_lines,
		stats: stats
	});
}

///@desc 追加一条已按秒计的预处理事件
///@param {Array} dst 目标列表
///@param {Real} t0 起点秒
///@param {Real} t1 终点秒
///@param {Real} v0 起点值
///@param {Real} v1 终点值
///@param {Real} ease 缓动号
///@returns {Undefined} 无
function phi_pec_push_prepared(dst, t0, t1, v0, v1, ease) {
	if (t1 < t0) then t1 = t0;
	// 数值不变或线性缓动时标记为不必再切
	var linear = (abs(v1 - v0) <= 0.0000001) || ease <= 1;
	array_add(dst, {
		t0: t0, t1: t1, v0: v0, v1: v1, ease: ease, e0: 0, e1: 1,
		bezier: false, pts: [0, 0, 0, 0], linear: linear
	});
}

///@desc 把 PEC 文本烘焙成官谱
///@param {String} pec_text PEC 文本
///@returns {Any} 官谱，解析失败为未定义
function phi_pec_to_official(pec_text) {
	var parsed = phi_pec_parse(pec_text);
	if (!is_struct(parsed)) then return undefined;
	// 先建成秒时间轴，再按线烘焙移动、旋转、透明度和速度
	var pec_timeline = phi_pec_build_timeline(parsed.bpmList);
	var bpm = phi_finite_or(pec_timeline[0].bpm, 60);
	if (!(bpm > 0)) then bpm = 60;
	var bpm_rows = [];
	for (var bpm_i = 0; bpm_i < array_length(pec_timeline); bpm_i++) {
		array_add(bpm_rows, { beat: pec_timeline[bpm_i].beat, bpm: pec_timeline[bpm_i].bpm });
	}
	var timeline = phi_bpm_timeline(bpm_rows);
	var lines = parsed.lines;
	var notes = parsed.notes;
	for (var note_i = 0; note_i < array_length(notes); note_i++) {
		var note_line = floor(phi_finite_or(notes[note_i][$ "lineId"] ?? 0, 0));
		while (array_length(lines) <= note_line) array_add(lines, phi_pec_line_bucket());
	}
	var chart_end = 1;
	var baked_lines = [];
	var stats = {
		source: "PEC>Official",
		lines: 0,
		notes: 0,
		version: 0,
		legacySpeed: false,
		parents: 0,
		attachUI: 0,
		textures: 0,
		scaleLines: 0,
		special: 0,
		noteAlpha: 0,
		noteSize: 0,
		noteScale: 0,
		fakeDropped: 0,
		move: 0,
		rotate: 0,
		alpha: 0,
		speed: 0,
		sliced: 0
	};
	var notes_by_line = [];
	for (var empty_i = 0; empty_i < array_length(lines); empty_i++) array_add(notes_by_line, []);
	for (var place_i = 0; place_i < array_length(notes); place_i++) {
		var placed = notes[place_i];
		var placed_line = floor(phi_finite_or(placed[$ "lineId"] ?? 0, 0));
		if (placed_line < 0 || placed_line >= array_length(notes_by_line)) then continue;
		var start_sec = pec_beat_to_sec(pec_timeline, placed.startBeat);
		var end_sec = pec_beat_to_sec(pec_timeline, placed.endBeat);
		if (end_sec < start_sec) then end_sec = start_sec;
		chart_end = max(chart_end, end_sec);
		if (abs(phi_finite_or(placed[$ "size"] ?? 1, 1) - 1) > 0.0001) then stats.noteSize++;
		array_add(notes_by_line[placed_line], {
			rpeType: floor(phi_finite_or(placed[$ "type"] ?? 1, 1)),
			startSec: start_sec,
			endSec: end_sec,
			officialX: phi_finite_or(placed[$ "x"] ?? 0, 0) / 115.2,
			speed: phi_finite_or(placed[$ "speed"] ?? 1, 1),
			above: phi_finite_or(placed[$ "above"] ?? 1, 1) == 1,
			fake: phi_finite_or(placed[$ "fake"] ?? 0, 0) != 0,
			yOffset: 0
		});
	}
	for (var line_i = 0; line_i < array_length(lines); line_i++) {
		var bucket = lines[line_i];
		if (!is_struct(bucket)) then bucket = phi_pec_line_bucket();
		var xs = [];
		var ys = [];
		var prev_x = 0;
		var prev_y = 1;
		var moves = is_array(bucket.move) ? bucket.move : [];
		array_sort(moves, phi_pec_cmp_span);
		for (var move_i = 0; move_i < array_length(moves); move_i++) {
			var mv = moves[move_i];
			var mt0 = pec_beat_to_sec(pec_timeline, mv.startBeat);
			var mt1 = pec_beat_to_sec(pec_timeline, mv.endBeat);
			// PEC 的 2048x1400 收成 0 到 1
			var x1 = phi_finite_or(mv.x, 0) / 2048;
			var y1 = phi_finite_or(mv.y, 0) / 1400;
			var ease = pec_easing(mv[$ "ease"] ?? 1);
			phi_pec_push_prepared(xs, mt0, mt1, prev_x, x1, ease);
			phi_pec_push_prepared(ys, mt0, mt1, prev_y, y1, ease);
			prev_x = x1;
			prev_y = y1;
			chart_end = max(chart_end, mt1);
		}
		var rots = [];
		var prev_r = 0;
		var rotates = is_array(bucket.rotate) ? bucket.rotate : [];
		array_sort(rotates, phi_pec_cmp_span);
		for (var rot_i = 0; rot_i < array_length(rotates); rot_i++) {
			var rv = rotates[rot_i];
			var rt0 = pec_beat_to_sec(pec_timeline, rv.startBeat);
			var rt1 = pec_beat_to_sec(pec_timeline, rv.endBeat);
			var target = -phi_finite_or(rv.target, 0);
			phi_pec_push_prepared(rots, rt0, rt1, prev_r, target, pec_easing(rv[$ "ease"] ?? 1));
			prev_r = target;
			chart_end = max(chart_end, rt1);
		}
		var alphas = [];
		var prev_a = 0;
		var alpha_raw = is_array(bucket.alpha) ? bucket.alpha : [];
		array_sort(alpha_raw, phi_pec_cmp_span);
		// 第一条透明度之前补成完全不透明
		if (array_length(alpha_raw) > 0) {
			var first_alpha = pec_beat_to_sec(pec_timeline, alpha_raw[0].startBeat);
			if (first_alpha > 0.0000001) then phi_pec_push_prepared(alphas, 0, first_alpha, 1, 1, 1);
		} else phi_pec_push_prepared(alphas, 0, 1, 1, 1, 1);
		for (var alpha_i = 0; alpha_i < array_length(alpha_raw); alpha_i++) {
			var av = alpha_raw[alpha_i];
			var at0 = pec_beat_to_sec(pec_timeline, av.startBeat);
			var at1 = pec_beat_to_sec(pec_timeline, av.endBeat);
			var target_a = phi_finite_or(av.target, 0) / 255;
			phi_pec_push_prepared(alphas, at0, at1, prev_a, target_a, pec_easing(av[$ "ease"] ?? 1));
			prev_a = target_a;
			chart_end = max(chart_end, at1);
		}
		var line_end = max(1, chart_end);
		xs = phi_expand_channel(xs);
		ys = phi_expand_channel(ys);
		rots = phi_expand_channel(rots);
		alphas = phi_expand_channel(alphas);
		var move_knots = [];
		phi_knots_from_prepared(move_knots, xs);
		phi_knots_from_prepared(move_knots, ys);
		var move_times = phi_knots_unique(move_knots, 0, line_end);
		var move_out = [];
		var xctx = { kind: "list", events: xs, empty: 0 };
		var yctx = { kind: "list", events: ys, empty: 1 };
		for (var span_i = 0; span_i < array_length(move_times) - 1; span_i++) {
			var t0 = move_times[span_i];
			var t1 = move_times[span_i + 1];
			if (t1 - t0 <= 0.0000001) then continue;
			var x0 = phi_ctx_scalar(xctx, t0);
			var y0 = phi_ctx_scalar(yctx, t0);
			var x_post = phi_ctx_scalar(xctx, t1);
			var y_post = phi_ctx_scalar(yctx, t1);
			var x_pre = phi_ctx_scalar(xctx, phi_probe_before(t0, t1));
			var y_pre = phi_ctx_scalar(yctx, phi_probe_before(t0, t1));
			var jumped = abs(x_post - x_pre) > 0.00001 || abs(y_post - y_pre) > 0.00001;
			var x1 = jumped ? x_pre : x_post;
			var y1 = jumped ? y_pre : y_post;
			array_add(move_out, { t0: t0, t1: t1, x0: x0, y0: y0, x1: x1, y1: y1 });
		}
		var rot_ctx = { kind: "list", events: rots, empty: 0 };
		var alpha_ctx = { kind: "list", events: alphas, empty: 1 };
		var rot_knots = [];
		var alpha_knots = [];
		phi_knots_from_prepared(rot_knots, rots);
		phi_knots_from_prepared(alpha_knots, alphas);
		var rot_out = phi_slice_scalar(phi_knots_unique(rot_knots, 0, line_end), rot_ctx, 0.0001);
		var alpha_out = phi_slice_scalar(phi_knots_unique(alpha_knots, 0, line_end), alpha_ctx, 0.00001);
		if (phi_list_eased(rots, 0, line_end)) then stats.sliced++;
		if (phi_list_eased(alphas, 0, line_end)) then stats.sliced++;
		var rpe_speed = phi_pec_speed_to_rpe(bucket.speed, pec_timeline);
		var _speed = [];
		for (var speed_i = 0; speed_i < array_length(rpe_speed); speed_i++) {
			var sv = rpe_speed[speed_i];
			var s0 = pec_beat_to_sec(pec_timeline, rpe_array_to_beat(sv.startTime));
			var s1 = pec_beat_to_sec(pec_timeline, rpe_array_to_beat(sv.endTime));
			if (s1 <= s0) then s1 = s0 + 0.000001;
			array_add(_speed, { t0: s0, t1: s1, value: phi_finite_or(sv.start, 0) / 4.5 });
			chart_end = max(chart_end, s1);
		}
		if (array_length(_speed) <= 0) then array_add(_speed, { t0: 0, t1: line_end, value: 0 });
		array_add(baked_lines, {
			move: phi_merge_move(move_out),
			rot: phi_merge_scalar(rot_out),
			alpha: phi_merge_scalar(alpha_out),
			speed: phi_merge_speed(_speed),
			notes: notes_by_line[line_i]
		});
	}
	stats.lines = array_length(baked_lines);
	return phi_baked_to_official({
		offsetMs: phi_finite_or(parsed.offsetMs, 0),
		bpm: bpm,
		timeline: timeline,
		lines: baked_lines,
		stats: stats
	}, "PEC>Official");
}

///@desc 生成五位随机数字文本
///@returns {String} 左侧补零的五位数字
function phi_tools_digits5() {
	var n = irandom(99999);
	var text = string(n);
	while (string_length(text) < 5) text = "0" + text;
	return text;
}

///@desc 把文件名拆成主名和扩展名
///@param {String} file_name 文件名
///@returns {Struct} 含 stem 与 ext
function phi_tools_stem_ext(file_name) {
	var dot = string_last_pos(".", file_name);
	// 没有扩展名或点在开头时整段都算主名
	if (dot <= 1) then return { stem: file_name, ext: "" };
	return {
		stem: string_copy(file_name, 1, dot - 1),
		ext: string_copy(file_name, dot, string_length(file_name) - dot + 1)
	};
}

///@desc 判断文件名是否已被占用，忽略大小写
///@param {Struct} taken 已占用名字
///@param {String} file_name 文件名
///@returns {Bool} 已占用为真
function phi_tools_name_taken(taken, file_name) {
	return variable_struct_exists(taken, string_lower(file_name));
}

///@desc 生成带标记的文件名，重名时再加五位随机数
///@param {String} stem 主名
///@param {String} mark 标记
///@param {String} ext 扩展名，含点
///@param {Struct} taken 已占用名字
///@returns {String} 不冲突的文件名
function phi_tools_unique_marked_name(stem, mark, ext, taken) {
	var plain = stem + mark + ext;
	if (!phi_tools_name_taken(taken, plain)) then return plain;
	for (var try_i = 0; try_i < 30; try_i++) {
		var marked = stem + mark + "-" + phi_tools_digits5() + ext;
		if (!phi_tools_name_taken(taken, marked)) then return marked;
	};
	return stem + mark + "-" + phi_tools_digits5() + ext;
}

///@desc 收集扫描结果里已有的文件名
///@param {Struct} discovered File_Discoverer 的结果
///@returns {Struct} 小写文件名到 1 的映射
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

///@desc 判断信息字段是不是谱面文件名
///@param {String} key 字段名
///@returns {Bool} Chart、Track 或谱面为真
function phi_tools_chart_key(key) {
	var normalized = string_lower(string_replace_all(string(key), " ", ""));
	normalized = string_replace_all(normalized, "\t", "");
	return normalized == "chart" || normalized == "track" || normalized == "chartfile" || normalized == "谱面";
}

///@desc 改写信息文件里的谱面字段，没有就追加
///@param {String} path 信息文件路径
///@param {String} chart_name 谱面文件名
///@returns {Bool} 恒为真
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
			// 跳过注释和缩进行，只改谱面字段
			if (first != "#" && first != "-" && first != " " && first != "\t" && phi_tools_chart_key(key)) {
				rewritten = key + string_char_at(line_text, sep) + " " + chart_name;
				found = true;
			};
		};
		if (line_i > 0) then out += newline;
		out += rewritten;
	};
	// 一份字段都没有时在末尾补 Chart
	if (!found) {
		if (string_length(out) > 0) then out += newline;
		out += "Chart: " + chart_name;
	};
	chart_buffer_save_text(path, out);
	return true;
}

///@desc 写一份只有谱面名的默认 info
///@param {String} path 输出路径
///@param {String} chart_name 谱面文件名
///@returns {Bool} 恒为真
function phi_tools_write_default_info(path, chart_name) {
	var body = "Name: \nLevel: \nComposer: \nCharter: \nIllustrator: \nSong: \nPicture: \nChart: " + chart_name + "\nOffset: 0\n";
	chart_buffer_save_text(path, body);
	return true;
}

///@desc 写一条 PhiTool 日志
///@param {String} message 日志内容
///@returns {Undefined} 无
function phi_tools_log(message) {
	print("[PhiTool] " + string(message), true);
}

///@desc 按来源打印转换统计
///@param {Struct} stats 统计结构
///@returns {Undefined} 无
function phi_tools_event_report(stats) {
	if (!is_struct(stats)) then return;
	var source_name = string(stats[$ "source"] ?? "");
	// 带箭头的来源是烘焙转换，PEC 和官谱各用自己的行
	if (string_pos(">", source_name) > 0) {
		var speed_kind = "";
		if (string_pos("RPE>", source_name) == 1) {
			speed_kind = " speed->RPE>=170";
			if (bool(stats[$ "legacySpeed"] ?? false)) then speed_kind = " speed->RPE<170";
		}
		var head_line = source_name
			+ " lines->" + string(stats[$ "lines"] ?? 0)
			+ " notes->" + string(stats[$ "notes"] ?? 0)
			+ " version->" + string(stats[$ "version"] ?? 0)
			+ speed_kind
			+ " parents->" + string(stats[$ "parents"] ?? 0)
			+ " attachUI->" + string(stats[$ "attachUI"] ?? 0)
			+ " textures->" + string(stats[$ "textures"] ?? 0)
			+ " special->" + string(stats[$ "special"] ?? 0)
			+ " scaleLines->" + string(stats[$ "scaleLines"] ?? 0)
			+ " noteAlpha->" + string(stats[$ "noteAlpha"] ?? 0)
			+ " noteSize->" + string(stats[$ "noteSize"] ?? 0)
			+ " noteScale->" + string(stats[$ "noteScale"] ?? 0)
			+ " fakeRemoved->" + string(stats[$ "fakeDropped"] ?? 0)
			+ " ignored->" + string(stats[$ "dropped"] ?? 0);
		var event_line = "events move->" + string(stats[$ "move"] ?? 0)
			+ " rotate->" + string(stats[$ "rotate"] ?? 0)
			+ " alpha->" + string(stats[$ "alpha"] ?? 0)
			+ " speed->" + string(stats[$ "speed"] ?? 0);
		print("[PhiTools] " + head_line + "\n" + event_line, true);
		return;
	}
	if (source_name == "PEC") {
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

///@desc 去掉目录末尾多余的斜杠，保留盘符根
///@param {String} path 目录
///@returns {String} 修剪后的路径
function phi_tools_trim_dir(path) {
	var text = chart_path_norm(path);
	// 长度大于 3 才削，避免把 C:/ 削掉
	while (string_length(text) > 3 && string_char_at(text, string_length(text)) == "/") {
		text = string_copy(text, 1, string_length(text) - 1);
	};
	return text;
}

///@desc 计算缓冲区的 CRC32
///@param {Id.Buffer} buf 缓冲区，读完后位置会变
///@returns {Real} CRC32
function phi_tools_crc32(buf) {
	static crc_table = undefined;
	// 第一次使用时建 256 项的 CRC 表
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

///@desc 判断文件头是不是 ZIP 的 PK
///@param {String} path 文件路径
///@returns {Bool} 头两个字节为 PK 时为真
function phi_tools_zip_magic_ok(path) {
	if (!file_exists(path)) then return false;
	var bin = file_bin_open(path, 0);
	if (bin < 0) then return false;
	var b0 = file_bin_read_byte(bin);
	var b1 = file_bin_read_byte(bin);
	file_bin_close(bin);
	// 80 和 75 是 ASCII 的 P 和 K
	return b0 == 80 && b1 == 75;
}

///@desc 列出目录里要打进包的全部文件
///@param {String} root 根目录
///@returns {Array} 文件路径
function phi_tools_list_pack_files(root) {
	var discovered = File_Discoverer(root);
	var files = [];
	var keys = ["chart", "music", "image", "text", "shader", "other"];
	for (var key_i = 0; key_i < array_length(keys); key_i++) {
		var list = discovered[$ keys[key_i]];
		if (!is_array(list)) then continue;
		for (var file_i = 0; file_i < array_length(list); file_i++) array_add(files, list[file_i]);
	};
	return files;
}

// 写未压缩的 zip。Windows 的 tar -a 不认识 .pez 后缀
///@desc 把目录打成存储方式的 zip
///@param {String} root 根目录
///@param {String} archive_path 输出压缩包
///@returns {Bool} 写出且文件头正确为真
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
		// 本地文件头，方法 0 表示不压缩
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
		array_add(entries, { name: rel, name_bytes: name_bytes, crc: crc, size: size, offset: offset });
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
		// 中央目录
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
	// 结束记录
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

///@desc 记录失败并清掉临时目录和半成品包
///@param {String} message 错误信息
///@param {String} work 临时目录
///@param {String} packed 半成品压缩包
///@returns {Struct} ok 为假的结果
function phi_tools_fail(message, work, packed) {
	phi_tools_log("fail: " + string(message));
	if (is_string(work) && string_length(work)) then chart_session_remove_dir(work);
	if (is_string(packed) && string_length(packed) && file_exists(packed)) then file_delete(packed);
	return { ok: false, archive: "", suggest: "", directory: "", error: message };
}

///@desc 在扫描结果里找第一份官谱
///@param {Struct} discovered 文件分组
///@returns {String} 路径，没有时为空串
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
		// 按内容识别格式，不看扩展名
		if (format_id == CHART_FORMAT.OFFICIAL) then return charts[i];
	};
	return "";
}

///@desc 在扫描结果里找第一份 PEC
///@param {Struct} discovered 文件分组
///@returns {String} 路径，没有时为空串
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

///@desc 在扫描结果里找第一份 RPE
///@param {Struct} discovered 文件分组
///@returns {String} 路径，没有时为空串
function phi_tools_find_rpe(discovered) {
	if (!is_struct(discovered) || !is_array(discovered[$ "chart"])) {
		phi_tools_log("find rpe: discovered chart list is missing");
		return "";
	};
	var charts = discovered.chart;
	phi_tools_log("find rpe: chart candidates=" + string(array_length(charts)));
	for (var i = 0; i < array_length(charts); i++) {
		var format_id = chart_detect_format(charts[i]);
		phi_tools_log("find rpe [" + string(i) + "] format=" + string(format_id) + " path=" + string(charts[i]));
		if (format_id == CHART_FORMAT.RPE) then return charts[i];
	};
	return "";
}

///@desc 返回工具面板每一行的源格式、目标格式和文案
///@returns {Array} 静态任务列表
function phi_tools_jobs() {
	static jobs = undefined;
	// 只建一次，绘制、点击和保存后缀都读这份表
	if (is_array(jobs)) then return jobs;
	jobs = [
		{ source: CHART_FORMAT.OFFICIAL, target: CHART_FORMAT.RPE, label: "menu.toolsExport", fail: "menu.toolsFail" },
		{ source: CHART_FORMAT.PEC, target: CHART_FORMAT.RPE, label: "menu.toolsExportPec", fail: "menu.toolsFailPec" },
		{ source: CHART_FORMAT.RPE, target: CHART_FORMAT.OFFICIAL, label: "menu.toolsExportRpeOfficial", fail: "menu.toolsFailRpe" }
	];
	return jobs;
}

// 官谱是 pgr，PEC 是 pec，RPE 是 rpe。未知目标不借用 _rpe
///@desc 按目标格式给出文件名标记
///@param {Real} target_id 目标格式
///@returns {String} 标记，未知时为空串
function phi_tools_save_tag(target_id) {
	if (target_id == CHART_FORMAT.OFFICIAL) then return "_pgr";
	if (target_id == CHART_FORMAT.PEC) then return "_pec";
	if (target_id == CHART_FORMAT.RPE) then return "_rpe";
	return "";
}

///@desc 计算工具面板和按钮的布局
///@param {Real} room_w 房间宽
///@param {Real} room_h 房间高
///@param {Real} ts 界面缩放
///@returns {Struct} 面板、按钮、关闭区和状态文字位置
function phi_tools_panel_metrics(room_w, room_h, ts) {
	var rows = array_length(phi_tools_jobs());
	var row_h = 40 * ts;
	var gap = 8 * ts;
	var title_h = 64 * ts;
	var status_h = 28 * ts;
	var bottom_pad = 16 * ts;
	var panel_w = min(room_w - 40, 560 * ts);
	var wanted = title_h + rows * row_h + (rows - 1) * gap + status_h + row_h + bottom_pad;
	var panel_h = min(room_h - 40, wanted);
	// 面板比内容矮时压缩每一行的高度
	if (panel_h < wanted) {
		var used = title_h + status_h + row_h + bottom_pad + (rows - 1) * gap;
		row_h = max(28 * ts, (panel_h - used) / rows);
	};
	var panel_x = (room_w - panel_w) * 0.5;
	var panel_y = (room_h - panel_h) * 0.5;
	var row_w = panel_w - 48 * ts;
	var buttons = [];
	var _y = panel_y + title_h;
	for (var i = 0; i < rows; i++) {
		array_add(buttons, { x: panel_x + 24 * ts, y: _y, w: row_w, h: row_h });
		_y += row_h + gap;
	};
	var close_h = row_h;
	return {
		panel_x: panel_x,
		panel_y: panel_y,
		panel_w: panel_w,
		panel_h: panel_h,
		buttons: buttons,
		close: { x: panel_x + 24 * ts, y: panel_y + panel_h - bottom_pad - close_h, w: row_w, h: close_h },
		status_y: panel_y + panel_h - bottom_pad - close_h - 14 * ts
	};
}

///@desc 从曲包根目录读取曲名等元数据
///@param {String} root 曲包目录
///@returns {Any} 元数据，没有信息文件时未定义
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

///@desc 按目标选择失败文案键
///@param {Any} want_pec 为真或文案键时走 PEC 失败文案
///@returns {String} 语言键
function phi_tools_fail_key(want_pec) {
	// 直接传入文案键时不再猜测
	if (is_string(want_pec) && string_length(want_pec)) then return want_pec;
	if (want_pec == true) then return "menu.toolsFailPec";
	return "menu.toolsFail";
}

///@desc 弹出保存框并把临时包复制出去
///@param {Struct} prepared prepare 的结果
///@param {String} tool_path 保留参数
///@param {Any} want_pec 失败文案选择
///@returns {String} 给界面显示的状态
function phi_tools_finish_save(prepared, tool_path, want_pec) {
	if (!is_struct(prepared) || !prepared.ok) {
		var fail_text = is_struct(prepared) ? string(prepared[$ "error"] ?? "") : "";
		phi_tools_log("prepare error=" + fail_text);
		if (string_length(fail_text)) then return fail_text;
		return lang(phi_tools_fail_key(want_pec));
	};
	var save_filter = lang("menu.toolsSavePez");
	phi_tools_log("save dialog filter=" + save_filter + " suggest=" + string(prepared.suggest) + " dir=" + string(prepared.directory) + " temp=" + string(prepared.archive) + " temp_exists=" + string(file_exists(prepared.archive)) + " temp_bytes=" + string(chart_archive_size_bytes(prepared.archive)));
	var saved = get_save_filename_ext(save_filter, prepared.suggest, prepared.directory, lang("menu.toolsSaveTitle"));
	phi_tools_log("save path=" + string(saved));
	var status = "";
	// 取消保存时删掉临时包，不留下半成品
	if (!string_length(saved)) {
		status = lang("menu.cancelled");
	} else {
		if (file_exists(saved)) then file_delete(saved);
		file_copy(prepared.archive, saved);
		var saved_ok = file_exists(saved);
		phi_tools_log("copy exists=" + string(saved_ok) + " bytes=" + string(chart_archive_size_bytes(saved)));
		if (saved_ok) then status = langf("menu.toolsDone", saved);
		else status = lang(phi_tools_fail_key(want_pec));
	};
	if (file_exists(prepared.archive)) then file_delete(prepared.archive);
	return status;
}

// 解压 zip 或 pez，转换后重新打包。默认源是官谱。这里不弹保存框
///@desc 准备一份转换后的临时曲包
///@param {String} src_path 源压缩包
///@param {Any} source_format 源格式，默认未定义时按官谱
///@param {Any} target_format 目标格式，默认未定义
///@returns {Struct} 含 ok、archive、suggest、directory、error
function phi_tools_prepare_rpe_package(src_path, source_format = undefined, target_format = undefined) {
	var work = "";
	var packed = "";
	phi_tools_log("begin log=" + LogGetPath());
	phi_tools_log("src=" + string(src_path) + " exists=" + string(chart_file_exists_any(src_path)) + " bytes=" + string(chart_archive_size_bytes(src_path)));
	try {
		if (!is_string(src_path) || !string_length(src_path)) then return phi_tools_fail("Empty package path.", work, packed);
		var archive_ext = string_lower(chart_path_ext(src_path));
		phi_tools_log("ext=" + archive_ext);
		// 只接受 zip 和 pez
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
		// GML 里 && 比 == 绑得更紧，所以格式比较单独写在 if 里
		var source_id = CHART_FORMAT.OFFICIAL;
		if (source_format == CHART_FORMAT.PEC || source_format == CHART_FORMAT.RPE || source_format == CHART_FORMAT.OFFICIAL) then source_id = source_format;
		var target_id = CHART_FORMAT.UNKNOWN;
		if (target_format == CHART_FORMAT.OFFICIAL || target_format == CHART_FORMAT.PEC || target_format == CHART_FORMAT.RPE) then target_id = target_format;
		var save_tag = phi_tools_save_tag(target_id);
		phi_tools_log("source=" + string(source_id) + " target=" + string(target_id) + " tag=" + save_tag);
		if (!string_length(save_tag)) then return phi_tools_fail(lang("menu.toolsConvert"), work, packed);
		var chart_path = "";
		var missing = "No official chart was found in the package.";
		if (source_id == CHART_FORMAT.PEC) {
			chart_path = phi_tools_find_pec(discovered);
			missing = lang("menu.toolsNoPec");
		} else if (source_id == CHART_FORMAT.RPE) {
			chart_path = phi_tools_find_rpe(discovered);
			missing = lang("menu.toolsNoRpe");
		} else {
			chart_path = phi_tools_find_official(discovered);
		};
		phi_tools_log("chart=" + string(chart_path));
		if (!string_length(chart_path)) then return phi_tools_fail(missing, work, packed);

		var built = undefined;
		var to_rpe = (target_id == CHART_FORMAT.RPE);
		var to_official = (target_id == CHART_FORMAT.OFFICIAL);
		// 只支持官谱到 RPE、PEC 到 RPE、RPE 到官谱
		if (source_id == CHART_FORMAT.OFFICIAL && to_rpe) {
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
			phi_tools_log("official->rpe lines=" + string(array_length(official_chart.judgeLineList)));
			built = phi_official_to_rpe(official_chart);
			delete(official_chart);
		} else if (source_id == CHART_FORMAT.PEC && to_rpe) {
			var pec_text = chart_read_text_file(chart_path, -1);
			phi_tools_log("pec->rpe text chars=" + string(is_string(pec_text) ? string_length(pec_text) : -1));
			if (!is_string(pec_text) || !string_length(pec_text)) then return phi_tools_fail(lang("menu.toolsPecRead"), work, packed);
			built = phi_pec_to_rpe(pec_text, phi_tools_meta_from_root(root));
		} else if (source_id == CHART_FORMAT.RPE && to_official) {
			var rpe_off_text = chart_read_text_file(chart_path, -1);
			phi_tools_log("rpe->official text chars=" + string(is_string(rpe_off_text) ? string_length(rpe_off_text) : -1));
			if (!is_string(rpe_off_text) || !string_length(rpe_off_text)) then return phi_tools_fail(lang("menu.toolsRpeRead"), work, packed);
			var rpe_off_chart = phi_rpe_chart_value(rpe_off_text);
			if (!is_struct(rpe_off_chart)) then return phi_tools_fail(lang("menu.toolsRpeRead"), work, packed);
			built = phi_rpe_to_official(rpe_off_chart);
			delete(rpe_off_chart);
		} else {
			phi_tools_log("unsupported pair source=" + string(source_id) + " target=" + string(target_id));
			return phi_tools_fail(lang("menu.toolsConvert"), work, packed);
		};
		var convert_fail = lang("menu.toolsConvert");
		phi_tools_log("convert struct=" + string(is_struct(built)));
		if (!is_struct(built)) then return phi_tools_fail(convert_fail, work, packed);
		var convert_stats = built[$ "stats"];
		if (is_struct(convert_stats)) then phi_tools_event_report(convert_stats);
		variable_struct_remove(built, "stats");

		var source_name = chart_path_file_name(chart_path);
		var parts = phi_tools_stem_ext(source_name);
		var taken = phi_tools_collect_names(discovered);
		var mark = save_tag;
		var archive_mark = save_tag;
		var chart_file_name = phi_tools_unique_marked_name(parts.stem, mark, ".json", taken);
		var chart_out = chart_path_join(chart_path_dir(chart_path), chart_file_name);
		phi_tools_log("write chart " + chart_out);
		var chart_text = json_stringify(built, true);
		if (to_official) then chart_text = phi_official_json_text(built, true);
		chart_buffer_save_text(chart_out, chart_text);
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
		var suggest = archive_parts.stem + archive_mark + ".pez";
		if (file_exists(chart_path_join(archive_dir, suggest))) {
			suggest = "";
			for (var name_try = 0; name_try < 30; name_try++) {
				var marked_archive = archive_parts.stem + archive_mark + "-" + phi_tools_digits5() + ".pez";
				if (!file_exists(chart_path_join(archive_dir, marked_archive))) {
					suggest = marked_archive;
					break;
				};
			};
			if (!string_length(suggest)) then suggest = archive_parts.stem + archive_mark + "-" + phi_tools_digits5() + ".pez";
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

///@desc 从曲包信息文件读取一个数字字段
///@param {String} root_path 曲包目录
///@param {String} key_name 字段名
///@param {Real} fallback 找不到时的值
///@returns {Real} 字段数值
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
			// 跳过注释和缩进行
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

///@desc 从曲包信息读取偏移，单位毫秒
///@param {String} root_path 曲包目录
///@returns {Real} 偏移毫秒，没有时为 0
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
		// 只认 offset 字段
		if (key != "offset") then continue;
		var value = chart_info_trim_value(string_copy(line_text, sep + 1, string_length(line_text) - sep));
		result = number(value, 0);
		break;
	};
	return result;
};

///@desc 把 RPE 拍数组换成实数拍
///@param {Any} _time_array 实数或小节、分子、分母
///@returns {Real} 拍数
function rpe_array_to_beat(_time_array) {
	if (is_real(_time_array)) then return _time_array;
	if (!is_array(_time_array)) then return 0;
	var _n = array_length(_time_array);
	if (_n <= 0) then return 0;
	var _beat = real(array_get(_time_array, 0));
	if (_n == 1) then return _beat;
	var _num = real(array_get(_time_array, 1));
	var _den = (_n >= 3) ? real(array_get(_time_array, 2)) : 1;
	// 分母为 0 时只保留小节
	if (_den == 0) then return _beat;
	return _beat + _num / _den;
};

///@desc 激活加载、重试或过场之后本该已经出现的 RPE 音符
///@param {Any} _now_sec 当前秒，默认未定义时读游戏时间
///@returns {Undefined} 无
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
	// 没开预激活时一次把全部音符打开
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
		// 列表按激活时间排序，后面的都还没到
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

///@desc 加载默认音符纹理，并开始加载打击音效组
///@returns {Bool} 恒为真
function chart_default_resources_load() {
	if (!variable_global_exists("default_notes_texture_loaded")) {
		global.default_notes_texture_loaded = false;
	};
	if (!global.default_notes_texture_loaded) {
		texturegroup_load("DefaultNotes", true);
		global.default_notes_texture_loaded = true;
		print("[Resources] DefaultNotes texture group loaded");
	};

	// 录像和归档测试不加载打击音效组
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

///@desc 判断默认打击音效是否已经加载完
///@returns {Bool} 可用为真
function chart_default_resources_ready() {
	if (variable_global_exists("render_mode") && global.render_mode) then return true;
	if (variable_global_exists("pls_archive_test") && global.pls_archive_test) then return true;
	return audio_group_is_loaded(audiogroup_hitsounds);
};

///@desc 读取默认打击音效的加载进度
///@returns {Real} 0 到 1
function chart_default_resources_progress() {
	if (variable_global_exists("render_mode") && global.render_mode) then return 1;
	if (audio_group_is_loaded(audiogroup_hitsounds)) then return 1;
	return audio_group_load_progress(audiogroup_hitsounds);
};

///@desc 卸载默认音符纹理和打击音效组
///@returns {Undefined} 无
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

///@desc 取得 FFmpeg 可执行文件名或路径
///@returns {String} 路径，Windows 默认 ffmpeg.exe
function render_ffmpeg_spec() {
	var spec = "";
	if (variable_global_exists("render_ffmpeg")) then spec = string_trim(string(global.render_ffmpeg ?? ""));
	if (!string_length(spec)) then spec = (os_type == os_windows ? "ffmpeg.exe" : "ffmpeg");
	return spec;
}

///@desc 把目录和文件名拼成路径
///@param {String} _dir 目录
///@param {String} _name 文件名
///@returns {String} 拼接后的路径
function render_ffmpeg_join(_dir, _name) {
	var d = string(_dir ?? "");
	if (!string_length(d)) then return string(_name ?? "");
	var last = string_char_at(d, string_length(d));
	// 目录末尾没有分隔符时补一个
	if (last != "/" && last != "\\") then d += "/";
	return d + string(_name ?? "");
}

///@desc 判断本机能否找到 FFmpeg
///@returns {Bool} 找到为真
function render_ffmpeg_available() {
	var spec = render_ffmpeg_spec();
	if (file_exists(spec)) then return true;
	var norm = string_replace_all(spec, "\\", "/");
	var has_dir = (string_pos("/", norm) > 0)
		|| (string_length(norm) >= 2 && string_char_at(norm, 2) == ":");
	// 已经是路径却不存在，就不再搜 PATH
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

///@desc 要求 FFmpeg 可用，否则提示并退出录像
///@returns {Bool} 可用为真
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
	// 命令行录像找不到 FFmpeg 就直接结束
	if (variable_global_exists("render_cli") && global.render_cli) {
		global.render_cli = false;
		game_end();
		return false;
	};
	global.render_cli = false;
	room_goto(room_menu);
	return false;
}

///@desc 解析打击音效文件，自定义路径无效时用默认 wav
///@param {Id.Sound} _default_sound 默认音效
///@param {String} _custom_path 自定义路径，默认为空
///@returns {String} 存在的文件路径，都没有时为空串
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

///@desc 按音符安排一条录像打击音
///@param {Id.Instance} _note 音符实例
///@param {Real} _event_time 事件时间，秒
///@param {String} _custom_path 自定义路径，默认为空
///@param {Bool} _is_fake 假音符不发声，默认假
///@returns {Bool} 安排成功为真
function render_schedule_note_hitsound(_note, _event_time, _custom_path = "", _is_fake = false) {
	if (!instance_exists(_note)) then return false;
	var fallback = snd_note_tap;
	if (variable_instance_exists(_note, "sound") && audio_exists(_note.sound)) then fallback = _note.sound;
	var path = string(_custom_path ?? "");
	if (!string_length(path)) then path = skin_hitsound_path_for_note(_note);
	return render_schedule_hitsound(fallback, _event_time, path, _is_fake);
};

///@desc 把打击音排进录像时间轴
///@param {Id.Sound} _default_sound 默认音效
///@param {Real} _event_time 事件时间，秒
///@param {String} _custom_path 自定义路径，默认为空
///@param {Bool} _is_fake 假音符不发声，默认假
///@returns {Bool} 安排成功为真
function render_schedule_hitsound(_default_sound, _event_time, _custom_path = "", _is_fake = false) {
	if (!(variable_global_exists("render_mode") && global.render_mode)) then return false;
	if (bool(_is_fake)) then return false;
	var _path = render_hitsound_path(_default_sound, _custom_path);
	if (!string_length(_path)) then return false;
	// 预计算事件要对齐音符真正被判定并画出的第一帧
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

///@desc 播放打击音，录像模式改成写入视频
///@param {Id.Sound} _default_sound 默认音效
///@param {String} _custom_path 自定义路径，默认为空
///@returns {Bool} 假音符为假，其余视播放结果
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

///@desc 播放 RPE 打击音，录像和 GX 走文件，否则可用 FMOD
///@param {Id.Sound} _default_sound 默认音效
///@param {Real} _custom_fmod_sound FMOD 声音，默认 -1
///@param {String} _custom_path 自定义路径，默认为空
///@returns {Any} 录像或 GX 返回布尔，FMOD 成功时无返回值
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

///@desc RPE 运行时，负责读谱、建线和多 BPM 换算
///@returns {Struct} 构造出的 RPE 实例
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
	static chart_time = [0 , 0]; // 谱面真实时间与多 BPM 补偿
	///@desc 读取 RPE JSON 并写入谱面信息
	///@param {String} _chart 谱面路径，空则用默认文件
	///@returns {Bool} 成功为真
	static Reader = (func(_chart){
		var f = (string_length(_chart) ? _chart : ($"{working_directory}chart/Chart_IN.json"));
		show_debug_message($"[R-Chart] Loading: {f}");
		// 文件缺失时直接失败
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
		self._bpm_timeline = undefined; // 这份谱面要重建多 BPM 时间轴
		var meta = self.chart.META;
		// 速度积分跟 RPEVersion。转换出的谱是 160，所以用 1.7 前的速度表。构建标签显示这个数
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
	///@returns {Undefined} 无
	static CreateLines = (func(){
		rpe_lines_begin();
		// 抽干同步创建队列
		while (!rpe_lines_pump(0)) {};
		rpe_lines_finish();
	});
	
	///@desc RPE 数学函数，对齐 PCR 的 ArrayToTime 与 BPM 辅助
	static Math = ({
		///@desc 拍数组换成实数，小节加分子除以分母
		arrToBeat : rpe_array_to_beat,
		
		///@desc 单一 BPM 下把秒换成拍
		///@param {Real} _sec 秒
		///@param {Real} _bpm 每分钟拍数
		///@returns {Real} 拍数
		secToBeat : (func(_sec , _bpm){
			// BPM 为 0 时没有拍
			if(_bpm == 0) then return(0);
			return(_sec * (_bpm / 60));
		}),
		
		///@desc 单一 BPM 下把拍换成秒
		///@param {Real} _beat 拍数
		///@param {Real} _bpm 每分钟拍数
		///@returns {Real} 秒
		beatToSec : (func(_beat , _bpm){
			if(_bpm == 0) then return(0);
			return(_beat * (60 / _bpm));
		}),

		///@desc 按 PCR 的 BPM 列表建一次多 BPM 时间轴
		///@returns {Array} 分段，含 startBeat、endBeat、bpm、floorSec
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
			// 按 CCBPMList 的方式稳定排序，同一拍保留后出现的 BPM
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
				// 按起点拍插入，同一拍时后写入的排在后面
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

		///@desc 二分查找拍所在的 BPM 分段
		///@param {Real} _beat 拍数
		///@returns {Real} 分段下标
		segmentIndexAtBeat : (func(_beat){
			var beat = real(_beat);
			var tl = game_1.Math.ensureBpmTimeline();
			if (!is_array(tl) || array_length(tl) <= 0) then return 0;
			var low = 0;
			var high = array_length(tl);
			// 找最后一个起点不晚于该拍的分段
			while (low < high) {
				var mid = (low + high) >> 1;
				if (real(tl[mid].startBeat) <= beat) then low = mid + 1;
				else high = mid;
			};
			return max(0, low - 1);
		}),

		///@desc 二分查找绝对秒所在的 BPM 分段
		///@param {Real} _sec 秒
		///@returns {Real} 分段下标
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

		///@desc 通过 BPM 时间轴把拍换成绝对秒
		///@param {Real} _beat 拍数
		///@returns {Real} 绝对秒
		beatToAbsSec : (func(_beat){
			var beat = real(_beat);
			var tl = game_1.Math.ensureBpmTimeline();
			if (!is_array(tl) || array_length(tl) <= 0) then return game_1.Math.beatToSec(beat, 140);
			var seg = tl[game_1.Math.segmentIndexAtBeat(beat)];
			return real(seg.floorSec) + game_1.Math.beatToSec(beat - real(seg.startBeat), real(seg.bpm));
		}),

		///@desc 把绝对秒换回连续拍，是 beatToAbsSec 的逆运算
		///@param {Real} _sec 绝对秒
		///@returns {Real} 拍数
		absSecToBeat : (func(_sec){
			var sec = real(_sec);
			var tl = game_1.Math.ensureBpmTimeline();
			if (!is_array(tl) || array_length(tl) <= 0) then return game_1.Math.secToBeat(sec, 140);
			var seg = tl[game_1.Math.segmentIndexAtAbsSec(sec)];
			return real(seg.startBeat) + game_1.Math.secToBeat(sec - real(seg.floorSec), real(seg.bpm));
		}),

		///@desc 读取绝对秒所在分段的 BPM
		///@param {Real} _sec 绝对秒
		///@returns {Real} BPM，没有时间轴时为 140
		bpmAtAbsSec : (func(_sec){
			var tl = game_1.Math.ensureBpmTimeline();
			if (!is_array(tl) || array_length(tl) <= 0) then return 140;
			return real(tl[game_1.Math.segmentIndexAtAbsSec(_sec)].bpm);
		}),
		
		///@desc 按 PCR 的表重映射 RPE 缓动号
		///@param {Real} _t 原始缓动号
		///@returns {Real} 播放用缓动号，空缺时为 1
		parseEasingType : (func(_t){
			static map = [ 0, 1, 3, 2, 6, 5, 4, 7, 9, 8, 12, 11, 10, 13, 15, 14, -1, 17, 16, -1, 19, 18, 22, 21, 20, 23, 25, 24, -1, 27, 26, 28 ];
			var t = clamp(floor(real(_t)), 0, array_length(map) - 1);
			var m = map[t];
			// 表里的 -1 表示没有对应缓动
			return(m < 0 ? 1 : m);
		})
	});
};


///@desc PEC 运行时，负责读谱、建线和坐标换算
///@returns {Struct} 构造出的 PEC 实例
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
	
	
	///@desc 读取 PEC 文本并解析成谱面
	///@param {String} _chart 谱面路径，空则用默认文件
	///@returns {Undefined} 无
	static Reader = (func(_chart){
		var f = (string_length(_chart) ? _chart : ($"{working_directory}chart/Chart_IN.json")),
			handle = (file_text_open_read(chart_file_readable_path(f)));
		var cl = false;
		
        // PEC 命令到解析函数
		var _pe_chart_func = {
			// 音符
            ///@desc 解析 Tap 音符
            ///@param {Array} arr_args0 命令参数
            ///@param {Real} arr_arg1 速度
            ///@param {Real} arr_arg2 宽度缩放
            ///@returns {Struct} 音符
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
            
            ///@desc 解析 Hold 音符
            ///@param {Array} arr_args0 命令参数
            ///@param {Real} arr_arg1 速度
            ///@param {Real} arr_arg2 宽度缩放
            ///@returns {Struct} 音符
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
            
            ///@desc 解析 Flick 音符
            ///@param {Array} arr_args0 命令参数
            ///@param {Real} arr_arg1 速度
            ///@param {Real} arr_arg2 宽度缩放
            ///@returns {Struct} 音符
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
            
            ///@desc 解析 Drag 音符
            ///@param {Array} arr_args0 命令参数
            ///@param {Real} arr_arg1 速度
            ///@param {Real} arr_arg2 宽度缩放
            ///@returns {Struct} 音符
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
			///@desc 解析瞬时速度命令 cv
			///@param {Array} arr_args0 命令参数
			///@returns {Array} 事件、线号和通道名
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
			///@desc 解析瞬时移动命令 cp
			///@param {Array} arr_args0 命令参数
			///@returns {Array} 事件、线号和通道名
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
			///@desc 解析瞬时透明度命令 ca
			///@param {Array} arr_args0 命令参数
			///@returns {Array} 事件、线号和通道名
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
			///@desc 解析瞬时旋转命令 cd
			///@param {Array} arr_args0 命令参数
			///@returns {Array} 事件、线号和通道名
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
			///@desc 解析带时长的旋转命令 cr
			///@param {Array} arr_args0 命令参数
			///@returns {Array} 事件、线号和通道名
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
			///@desc 解析带时长的移动命令 cm
			///@param {Array} arr_args0 命令参数
			///@returns {Array} 事件、线号和通道名
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
			///@desc 解析带时长的透明度命令 cf
			///@param {Array} arr_args0 命令参数
			///@returns {Array} 事件、线号和通道名
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
            ///@desc 解析 BPM 命令 bp
            ///@param {Array} arr_args0 拍和 BPM
            ///@returns {Struct} 含 time 与 bpm
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
			// 第一行是谱面偏移
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
			// 音符再读两行速度和宽度
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
		///@desc 把秒换成拍
		///@param {Real} _sec 秒
		///@param {Real} _bpm 每分钟拍数
		///@returns {Real} 拍数
		secToBeat : (func(_sec , _bpm){
			 return((_sec) * ((_bpm) / 60));	
		}),
		
		///@desc 把拍换成秒
		///@param {Real} _beat 拍数
		///@param {Real} _bpm 每分钟拍数
		///@returns {Real} 秒
		beatToSec : (func(_beat , _bpm){
			return(_beat * (60 / _bpm));	
		}),
        
        ///@desc 把 PEC 世界坐标换成 1366x768 屏幕坐标
        ///@param {Real} xx 世界横坐标
        ///@param {Real} yy 世界纵坐标
        ///@returns {Array} 屏幕 x 和 y
        pos_to_size : (func(xx , yy){
            var sw = 1366;
            var sh = 768;
        
            var world_w = 2048;  // 横向从 -1024 到 1024
            var world_h = 1400;  // 纵向从 -700 到 700
        
            var sx = (xx + 1024) * (sw / world_w);
            var sy = sh - (yy + 700) * (sh / world_h);
        
            return [sx, sy];
        })
	});
	
    ///@desc 按时间排序事件并创建 PEC 判定线
    ///@returns {Undefined} 无
    static CreateLines = (func(){
        ///@desc 比较两个事件的时间
        ///@param {Struct} x1 事件
        ///@param {Struct} x2 事件
        ///@returns {Real} 负数、零或正数
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
    
	///@desc 把当前 PEC 谱面存成按日期编号的 JSON
	///@returns {Undefined} 无
	static chartBuffSave = (function(){
		var n = 0,
			chart_dir = ($"{game_save_id}charts/");
		if(!directory_exists(chart_dir)) then directory_create(chart_dir);
		var path = ($"{chart_dir}{current_year}-{current_month}-{current_day}-");
		// 同一天已有文件时递增序号
		while(file_exists($"{path}{n}.json")){
			n ++;	
		};
		
		chart_buffer_save_text($"{path}{n}.json", json_stringify(self.chart, true));
		return;
	});
};

///@desc 按 PEC 透明度判断音符现在是否可见
///@param {Real} _raw 原始透明度
///@param {Bool} _is_above 是否在判定线上方
///@param {Real} _sec_to_hit 距离命中的秒数
///@param {Any} _note_sec 音符时间，默认未定义
///@returns {Bool} 可见为真
function pec_note_alpha_visible(_raw, _is_above, _sec_to_hit, _note_sec = undefined) {
	if (_raw >= -0.5) then return true;
	if (abs(_raw + 1) <= 0.5) then return false;
	if (abs(_raw + 2) <= 0.5) then return bool(_is_above);
	if (_raw > -1000 && _raw <= -100) {
		// Phira 扩展：在音符前 (abs(alpha)-100)/10 拍出现
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

///@desc 建立一条空的 PEC 判定线事件结构
///@returns {Struct} 四个空事件数组
function pec_line_data() {
	return { moveEvents: [], alphaEvents: [], rotateEvents: [], speedEvents: [] };
}

///@desc 按 BPM 时间轴把拍换成秒
///@param {Array} timeline BPM 时间轴
///@param {Real} beat 拍数
///@returns {Real} 秒
function pec_beat_to_sec(timeline, beat) {
	if (!is_array(timeline) || array_length(timeline) <= 0) then return 0;
	if (beat < timeline[0].beat) then return 0;
	var low = 0;
	var high = array_length(timeline) - 1;
	// 二分找到不晚于该拍的最后一个 BPM 点
	while (low < high) {
		var middle = (low + high + 1) div 2;
		if (timeline[middle].beat <= beat) low = middle;
		else high = middle - 1;
	};
	var point = timeline[low];
	return point.second + (beat - point.beat) * 60 / point.bpm;
}

///@desc 二分查找秒所在的 BPM 下标
///@param {Array} timeline BPM 时间轴
///@param {Real} sec 秒
///@returns {Real} 下标
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

///@desc 读取某秒的 BPM
///@param {Array} timeline BPM 时间轴
///@param {Real} sec 秒
///@returns {Real} BPM，没有时间轴时为 60
function pec_bpm_at_sec(timeline, sec) {
	if (!is_array(timeline) || array_length(timeline) <= 0) then return 60;
	return timeline[pec_bpm_index_at_sec(timeline, sec)].bpm;
}

///@desc 比较两个实数，供排序使用
///@param {Real} a 左值
///@param {Real} b 右值
///@returns {Real} -1、0 或 1
function pec_cmp_real(a, b) {
	// array_sort 会把比较结果截成整数，0.125 的差值会变成 0，相近的 cv 可能被对调
	if (a < b) then return -1;
	if (a > b) then return 1;
	return 0;
}

///@desc 查询某秒的 PEC 速度地板
///@param {Array} speed_events 速度事件
///@param {Real} sec 秒
///@returns {Real} 地板位置
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
	// cv 只持续到下一条。不夹住的话 70000 段会一直积分，把后面的音符甩出谱面
	if (struct_exists(event, "endSec") && is_finite(event.endSec)) {
		elapsed = min(elapsed, max(0, event.endSec - event.startSec));
	};
	// PhiEditer 把 cv 70000 写成一拍内的瞬间变速。段内不再积分，跳变记在下一条事件
	if (pec_speed_is_warp(event.value)) then elapsed = 0;
	return event.floor + elapsed * event.value;
}

///@desc 返回 PEC 文件缓动号到播放缓动号的表
///@returns {Array} 映射表
function pec_easing_table() {
	static map = [0, 1, 3, 2, 6, 5, 4, 7, 9, 8, 12, 11, 10, 13, 15, 14, 1, 17, 16, 1, 19, 18, 22, 21, 20, 23, 25, 24, 29, 27, 26, 28];
	return map;
}

///@desc 把 PEC 文件缓动号换成播放缓动号
///@param {Real} easing_id 文件缓动号
///@returns {Real} 播放缓动号
function pec_easing(easing_id) {
	var map = pec_easing_table();
	var _id = clamp(floor(real(easing_id)), 0, array_length(map) - 1);
	return map[_id];
}

///@desc 把 RPE 播放缓动反查成 PEC 文件缓动号
///@param {Real} chart_ease RPE 缓动号
///@returns {Real} 文件缓动号，找不到时为 1
function phi_pec_ease_from_rpe(chart_ease) {
	var playback = rpe_map_easing_id(chart_ease);
	var map = pec_easing_table();
	var n = array_length(map);
	// 找第一项能播成同一缓动的文件号
	for (var i = 0; i < n; i++) {
		if (map[i] == playback) then return i;
	}
	return 1;
}

///@desc 把 PEC 属性事件收成带上一值的秒时间事件
///@param {Array} raw_events 原始事件
///@param {Array} timeline BPM 时间轴
///@param {String} kind move、alpha 或 rotate
///@returns {Array} 整理后的事件
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
		// 下一段从上一段的目标值接着走
		previous = source.target;
	};
	return result;
}

///@desc 把 PEC 文件读进运行时上下文
///@param {Struct} ctx 读取上下文
///@param {String} chart_path 谱面路径
///@returns {Bool} 成功为真
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
	// 文件偏移加信息偏移，再减去播放器固定的 0.175 秒
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
		// Phira 把 # 和 & 当成独立命令，用来改上一条音符
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
		// 第一条 cv 不在 0 拍时，Phira 会补一条速度为 0 的起点
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
	// 同一高亮键的音符互相标记为多押
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

///@desc 同步创建 PEC 运行时判定线
///@param {Struct} ctx 读取上下文
///@returns {Undefined} 无
function pec_create_runtime(ctx) {
	pec_lines_begin(ctx);
	// 抽干同步创建队列
	while (!pec_lines_pump(0)) {};
	pec_lines_finish();
}

// 四层示例事件，仅作结构样例
var EventLayers = [
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

