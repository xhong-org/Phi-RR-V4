///@desc 初始化 RPE 音符的地板、控制和空间索引
depth = DEPTH.NOTE;
inition = false;
canDraw = false;
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then visible = false;

// CreateLines 没写入的字段用默认值补齐。
if (!variable_instance_exists(id, "type")) then type = 1;
if (!variable_instance_exists(id, "rpe_type")) then rpe_type = type;
if (!variable_instance_exists(id, "isAbove")) then isAbove = true;
if (!variable_instance_exists(id, "alpha")) then alpha = 1;
if (!variable_instance_exists(id, "start_beat")) then start_beat = 0;
if (!variable_instance_exists(id, "end_beat")) then end_beat = start_beat;
if (!variable_instance_exists(id, "start_sec")) then start_sec = game_1.Math.beatToAbsSec(start_beat);
if (!variable_instance_exists(id, "end_sec")) then end_sec = game_1.Math.beatToAbsSec(end_beat);
if (!variable_instance_exists(id, "hold_beat")) then hold_beat = max(0, end_beat - start_beat);
if (!variable_instance_exists(id, "xOffset")) then xOffset = 0;
if (!variable_instance_exists(id, "yOffset")) then yOffset = 0;
if (!variable_instance_exists(id, "yorigin")) then yorigin = real(yOffset) / 900;
if (!variable_instance_exists(id, "floorPosition")) then floorPosition = 0;
if (!variable_instance_exists(id, "endFloorPosition")) then endFloorPosition = floorPosition;
if (!variable_instance_exists(id, "holdFloorLength")) then holdFloorLength = endFloorPosition - floorPosition;
if (!variable_instance_exists(id, "size")) then size = 1;
if (!variable_instance_exists(id, "note_speed")) then note_speed = 1;
if (!variable_instance_exists(id, "note_layer_bias")) then note_layer_bias = 0;
if (!variable_instance_exists(id, "visibleTime")) then visibleTime = 999999;
if (!variable_instance_exists(id, "isFake")) then isFake = false;
if (!variable_instance_exists(id, "note_tint")) then note_tint = c_white;
if (!variable_instance_exists(id, "has_hit_tint")) then has_hit_tint = false;
if (!variable_instance_exists(id, "hit_tint")) then hit_tint = c_white;
if (!variable_instance_exists(id, "hit_effect_z")) then hit_effect_z = 7;
if (!variable_instance_exists(id, "line_id")) then line_id = 0;
if (!variable_instance_exists(id, "compactHold")) then compactHold = false;
if (!variable_instance_exists(id, "custom_sound")) then custom_sound = -1;
if (!variable_instance_exists(id, "custom_fmod_sound")) then custom_fmod_sound = -1;
if (!variable_instance_exists(id, "custom_hitsound_path")) then custom_hitsound_path = "";

type = real(type);
start_beat = real(start_beat);
end_beat = real(end_beat);
start_sec = real(start_sec);
end_sec = real(end_sec);
hold_beat = real(hold_beat);
xOffset = real(xOffset);
yOffset = real(yOffset);
yorigin = real(yorigin);
floorPosition = real(floorPosition);
endFloorPosition = real(endFloorPosition);
holdFloorLength = real(holdFloorLength);
if (holdFloorLength == 0) then holdFloorLength = (endFloorPosition - floorPosition);
hold_length_floor = holdFloorLength;
size = real(size);
// 谱面倍率在 note_speed。此时读内置 speed 还是 0，创建结构还没写入 hspeed。
note_speed = real(note_speed);
if (!is_finite(note_speed)) then note_speed = 1;
speed = 0;
direction = 0;
visibleTime = real(visibleTime);
alpha = clamp(real(alpha), 0, 1);
isAbove = bool(isAbove);
isFake = bool(isFake);
is_real_note = !isFake;
has_hit_tint = bool(has_hit_tint);
compactHold = bool(compactHold);
_debug_text_x = 0;
_debug_text_y = 0;

_is_hold = (type == 3);
_step_user_count = (_is_hold ? 2 : 1);
_judge_user_count = (_is_hold ? 6 : 5);

// 绑定到 RPE 判定线，线不存在就销毁。
if (!variable_global_exists("game_1") || !is_struct(game_1) || !is_array(game_1.line_list)
	|| line_id < 0 || line_id >= array_length(game_1.line_list)) {
	show_debug_message($"[oNote_1] invalid line_id={line_id}");
	instance_destroy();
	exit;
};
_line_ref = game_1.line_list[line_id];
if (!instance_exists(_line_ref)) {
	show_debug_message($"[oNote_1] missing line instance id={line_id}");
	instance_destroy();
	exit;
};

var _line_factor = (variable_instance_exists(_line_ref, "bpmfactor") ? real(_line_ref.bpmfactor) : 1);
if (!is_real(_line_factor) || _line_factor <= 0) then _line_factor = 1;
_line_time_factor = _line_factor;
_preload_seconds = (variable_global_exists("game") && is_struct(game)
	? real(game.settings.notePreloadSeconds ?? 0) / _line_factor
	: 0);
_max_visible_floor_distance = 12;
_last_global_scales = -1;
_now_seconds = 0;
_now_beat = 0;
_line_time = 0;

var _mvp = floorPosition + 0.01;
var _mvl = _mvp;
if (variable_global_exists("game") && is_struct(game) && is_struct(game.Math) && struct_exists(game.Math, "maxVisiblePos")) {
	_mvp = game.Math.maxVisiblePos(floorPosition);
	if (_is_hold) {
		if (hold_length_floor > 0) then _mvl = game.Math.maxVisiblePos(floorPosition + hold_length_floor);
		else _mvl = _mvp;
	};
} else if (_is_hold && hold_length_floor > 0) {
	_mvl = floorPosition + hold_length_floor + 0.01;
};
maximum_visual_position = _mvp;
maximum_visual_length = _mvl;
_is_out = true;
_is_out_line = true;
_position_floor_delta = 0;
_note_position_speed = 0;
_control_position_speed = 0;
_note_skew_degrees = 0;
rpe_skip_pass_fade = (abs(real(alpha) - 1) > 0.001);
if (!rpe_skip_pass_fade && instance_exists(_line_ref)) {
	rpe_skip_pass_fade = !rpe_alpha_control_is_identity(_line_ref.alphaControl);
};
_ox_v = 0;
_oy_v = 0;
outside = false;
__first__ = false;

// 休眠音符索引：非 Hold 按有效地板分组做视口二分，Hold 用区间重叠查询。
if (variable_global_exists("game_1") && is_struct(game_1)
	&& struct_exists(game_1, "_note_activation_records")) {
	var _spatial_record = {
		id:id,
		line:_line_ref,
		startSec:start_sec,
		endSec:end_sec,
		yOrigin:yorigin,
		visibleTime:visibleTime,
		timeFactor:_line_time_factor,
		speed:note_speed,
		alpha:alpha,
		above:isAbove,
		activated:false,
		spatialSafe:true,
		spatialFloor:floorPosition,
		endSpatialFloor:endFloorPosition
	};
	if (variable_instance_exists(_line_ref, "_control_y") && is_struct(_line_ref._control_y)) {
		var _spatial_y_values = _line_ref._control_y.values;
		// Y 控制不是恒定 1 时，空间查询不再安全。
		for (var _spatial_yi = 0; _spatial_yi < array_length(_spatial_y_values); _spatial_yi++) {
			if (real(_spatial_y_values[_spatial_yi]) != 1) {
				_spatial_record.spatialSafe = false;
				break;
			};
		};
	};
	// 倾斜可能把中心在视口外的音符拉回画面，不能只按中心查询休眠音符。
	if (!_is_hold && is_struct(_line_ref._control_skew)) {
		var skew_values = _line_ref._control_skew.values;
		for (var si = 0; si < array_length(skew_values); si++) {
			if (real(skew_values[si]) == 0) then continue;
			_spatial_record.spatialSafe = false;
			break;
		};
	};
	game_1._note_activation_records[$ string(id)] = _spatial_record;
	// 可见且速度非 0 才进入空间分组。
	if (visibleTime > 0 && note_speed != 0) {
		if (_is_hold) {
			var _hold_group_key = string(line_id) + ":" + string(isAbove)
				+ ":" + string(note_speed) + ":" + string(yorigin);
			var _hold_first = game_1._note_spatial_hold_group_map[$ _hold_group_key];
			var _hold_group = rpe_note_group_find(_hold_first, note_speed, yorigin);
			if (!is_struct(_hold_group)) {
				_hold_group = {
					line:_line_ref, above:isAbove, speed:note_speed, yOrigin:yorigin,
					spatialSafe:_spatial_record.spatialSafe, notes:[], count:0, nextWithKey:_hold_first
				};
				game_1._note_spatial_hold_group_map[$ _hold_group_key] = _hold_group;
				array_add(game_1._note_spatial_hold_groups, _hold_group);
			};
			array_add(_hold_group.notes, _spatial_record);
		} else {
			_spatial_record.spatialFloor += yOffset / (540 * note_speed);
			_spatial_record.endSpatialFloor += yOffset / (540 * note_speed);
			var _group_key = string(line_id) + ":" + string(isAbove) + ":" + string(note_speed);
			var _spatial_first = game_1._note_spatial_group_map[$ _group_key];
			var _spatial_group = rpe_note_group_find(_spatial_first, note_speed);
			if (!is_struct(_spatial_group)) {
				_spatial_group = { line:_line_ref, speed:note_speed, above:isAbove,
					spatialSafe:_spatial_record.spatialSafe, notes:[], nextWithKey:_spatial_first };
				game_1._note_spatial_group_map[$ _group_key] = _spatial_group;
				array_add(game_1._note_spatial_groups, _spatial_group);
			};
			array_add(_spatial_group.notes, _spatial_record);
		};
	};
};

rpe_controls = [_line_ref._control_alpha, _line_ref._control_pos, _line_ref._control_size, _line_ref._control_y, _line_ref._control_skew];
rpe_control_cursors = [0, 0, 0, 0, 0];
///@desc 按音符位置速度采样一条 RPE 控制曲线
///@param {Real} control_index 控制下标：0 透明，1 位置，2 大小，3 Y，4 倾斜
///@param {Real} note_pos_speed 采样用的位置速度
///@param {Real} default_value 越过末点时返回的默认值
///@returns {Real} 插值后的控制值
rpe_sample_control = function(control_index, note_pos_speed, default_value = 1) {
	var control = rpe_controls[control_index];
	// 控制点不足两个时无法插值。
	if (!is_struct(control) || real(control.length) < 2) then return default_value;
	var n = real(control.length);
	var positions = control.positions;
	var values = control.values;
	var easings = control.easings;
	// 落在首点之前用首值，越过末点用默认值。
	if (note_pos_speed <= real(positions[0])) {
		rpe_control_cursors[@ control_index] = 0;
		return real(values[0]);
	};
	if (note_pos_speed > real(positions[n - 1])) {
		rpe_control_cursors[@ control_index] = n - 2;
		return default_value;
	};
	var i = clamp(rpe_control_cursors[control_index], 0, n - 2);
	// 游标向两侧走到包住当前速度的区间。
	while (i > 0 && note_pos_speed <= real(positions[i])) i--;
	while (i < n - 2 && real(positions[i + 1]) < note_pos_speed) i++;
	rpe_control_cursors[@ control_index] = i;
	return tween_execute(note_pos_speed, real(positions[i]), real(positions[i + 1]),
		real(values[i]), real(values[i + 1]), real(easings[i]));
};

///@desc 按透明度、可见时间和判定线遮罩决定能否绘制
///@returns {Bool} 本帧是否应该绘制
rpe_note_apply_visibility = function() {
	// 判定线没了就直接藏掉。
	if (!instance_exists(_line_ref)) {
		canDraw = false;
		image_alpha = 0;
		return false;
	};

	var note_a = alpha;
	if (variable_instance_exists(id, "isMiss") && isMiss) then note_a *= 0.5;
	// 速度 0 的 Hold 曾经被导出成透明。头碰到判定线前保持可见，Other_12 到点再藏。
	var speed_zero_hold = _is_hold && abs(note_speed) <= 0.0000001 && hold_length_floor > 0.0000001;
	if (note_a <= 0) {
		// 普通透明音符直接不画；速度 0 的 Hold 除外。
		if (!speed_zero_hold) {
			canDraw = false;
			image_alpha = 0;
			return false;
		};
		note_a = 1;
	};

	var sec_to_hit = start_sec - _now_seconds;
	var sec_to_hit_real = sec_to_hit * _line_time_factor;
	var time_before = (sec_to_hit > 0);
	// visibleTime 是相对音符头的有符号实时阈值。负值会让短 Hold 在开始后继续隐藏。
	if (is_finite(visibleTime) && visibleTime < 999999 && sec_to_hit_real > visibleTime) {
		canDraw = false;
		image_alpha = 0;
		return false;
	};

	var adec = 255;
	if (variable_instance_exists(_line_ref, "_alpha_decimal")) then adec = real(_line_ref._alpha_decimal);
	else if (variable_instance_exists(_line_ref, "__raw_a")) then adec = real(_line_ref.__raw_a);

	var uncover = variable_instance_exists(_line_ref, "_uncover") ? bool(_line_ref._uncover) : false;
	var alpha_extra = 0;
	if (time_before) {
		if (adec >= 0 && (_is_out_line || uncover)) then alpha_extra = 1;
	} else if (adec >= 0) {
		alpha_extra = 1;
	};

	// 判定线透明度不允许露出时不画。
	if (!alpha_extra) {
		canDraw = false;
		image_alpha = 0;
		return false;
	};

	var final_a = note_a * rpe_sample_control(0, _control_position_speed, 1);
	// 控制曲线把透明度压到 0 也不画。
	if (final_a <= 0) {
		canDraw = false;
		image_alpha = 0;
		return false;
	};

	image_alpha = final_a;
	return true;
};

hitTime2 = 0;
event_user(0);
if (!bool(game.settings.noteUniformScale ?? false)) then image_yscale = (global_scales / 6);
image_blend = note_tint;
if (audio_exists(custom_sound) && custom_sound != snd_note_tap && custom_sound != snd_note_drag && custom_sound != snd_note_flick) then sound = custom_sound;
lateHitTime = 0.25;
judgeBeat = start_beat;
judgeTime = start_sec;
judgeRealTime = 0;
chart_kb_register_note();
