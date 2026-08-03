/// @description RPE note (PCR-aligned floor/position model)
depth = DEPTH.NOTE;
inition = false;
canDraw = false;

// defaults from CreateLines
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
if (!variable_instance_exists(id, "speed")) then speed = 1;
if (!variable_instance_exists(id, "visibleTime")) then visibleTime = 999999;
if (!variable_instance_exists(id, "isFake")) then isFake = false;
if (!variable_instance_exists(id, "note_tint")) then note_tint = c_white;
if (!variable_instance_exists(id, "has_hit_tint")) then has_hit_tint = false;
if (!variable_instance_exists(id, "hit_tint")) then hit_tint = c_white;
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
speed = real(speed);
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

// bind to RPE line list
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
_ox_v = 0;
_oy_v = 0;
outside = false;
__first__ = false;

// Phira-style dormant-note index. Static non-holds are grouped by effective
// floor for binary viewport queries; Holds use interval overlap queries.
if (variable_global_exists("game_1") && is_struct(game_1)
	&& struct_exists(game_1, "_note_activation_records")) {
	var _spatial_record = {
		id:id,
		line:_line_ref,
		startSec:start_sec,
		endSec:end_sec,
		yOrigin:yorigin,
		visibleTime:visibleTime,
		speed:speed,
		alpha:alpha,
		above:isAbove,
		activated:false,
		spatialSafe:true,
		spatialFloor:floorPosition,
		endSpatialFloor:endFloorPosition
	};
	if (variable_instance_exists(_line_ref, "_control_y") && is_struct(_line_ref._control_y)) {
		var _spatial_y_values = _line_ref._control_y.values;
		for (var _spatial_yi = 0; _spatial_yi < array_length(_spatial_y_values); _spatial_yi++) {
			if (real(_spatial_y_values[_spatial_yi]) != 1) {
				_spatial_record.spatialSafe = false;
				break;
			};
		};
	};
	game_1._note_activation_records[$ string(id)] = _spatial_record;
	if (visibleTime > 0 && speed != 0) {
		if (_is_hold) {
			array_add(game_1._note_spatial_holds, _spatial_record);
		} else {
			_spatial_record.spatialFloor += yOffset / (540 * speed);
			_spatial_record.endSpatialFloor += yOffset / (540 * speed);
			var _group_key = string(line_id) + ":" + string(isAbove) + ":" + string(speed);
			var _spatial_group;
			if (!struct_exists(game_1._note_spatial_group_map, _group_key)) {
				_spatial_group = { line:_line_ref, speed:speed, above:isAbove,
					spatialSafe:_spatial_record.spatialSafe, notes:[] };
				game_1._note_spatial_group_map[$ _group_key] = _spatial_group;
				array_add(game_1._note_spatial_groups, _spatial_group);
			} else {
				_spatial_group = game_1._note_spatial_group_map[$ _group_key];
			};
			array_add(_spatial_group.notes, _spatial_record);
		};
	};
};

rpe_sample_control = function(control_name, note_pos_speed, default_value = 1) {
	if (!instance_exists(_line_ref)) then return default_value;
	var field_name = "_control_" + control_name;
	if (!variable_instance_exists(_line_ref, field_name)) then return default_value;
	var control = variable_instance_get(_line_ref, field_name);
	if (!is_struct(control) || real(control.length) < 2) then return default_value;
	var n = real(control.length);
	var positions = control.positions;
	var values = control.values;
	var easings = control.easings;
	if (note_pos_speed <= real(positions[0])) then return real(values[0]);
	if (note_pos_speed > real(positions[n - 1])) then return default_value;
	for (var i = 0; i < n - 1; i++) {
		var p0 = real(positions[i]);
		var p1 = real(positions[i + 1]);
		if (p1 < note_pos_speed) then continue;
		return tween_execute(note_pos_speed, p0, p1, real(values[i]), real(values[i + 1]), real(easings[i]));
	};
	return real(values[n - 1]);
};

rpe_note_apply_visibility = function() {
	if (!instance_exists(_line_ref)) {
		canDraw = false;
		image_alpha = 0;
		return false;
	};

	var note_a = alpha;
	if (variable_instance_exists(id, "isMiss") && isMiss) then note_a *= 0.5;
	if (note_a <= 0) {
		canDraw = false;
		image_alpha = 0;
		return false;
	};

	var sec_to_hit = start_sec - _now_seconds;
	var time_before = (sec_to_hit > 0);
	if (time_before && is_finite(visibleTime) && visibleTime < 999999 && sec_to_hit > visibleTime) {
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

	if (!alpha_extra) {
		canDraw = false;
		image_alpha = 0;
		return false;
	};

	var final_a = note_a * rpe_sample_control("alpha", _control_position_speed, 1);
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
if (audio_exists(custom_sound)) then sound = custom_sound;
lateHitTime = 0.25;
judgeBeat = start_beat;
judgeTime = start_sec;
judgeRealTime = 0;
