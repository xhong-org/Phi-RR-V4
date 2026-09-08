/// @description Initialize a normalized PEC note.
depth = DEPTH.NOTE;
canDraw = false;
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then visible = false;

judged = false;
hold_started = false;
hit_status = TYPE.NONE;
hold_effect_sec = -infinity;
image_alpha = 1;
if (!variable_instance_exists(id, "note_speed")) {
	note_speed = (variable_instance_exists(id, "speed") ? speed : 1);
};
note_speed = real(note_speed);
if (!is_finite(note_speed)) then note_speed = 1;
// GameMaker applies built-in `speed` after Step; never use it as note velocity.
speed = 0;
direction = 0;
if (!variable_instance_exists(id, "widthScale")) then widthScale = 1;
if (!variable_instance_exists(id, "isFake")) then isFake = false;
if (!variable_instance_exists(id, "start_beat")) then start_beat = 0;
if (!variable_instance_exists(id, "end_beat")) then end_beat = start_beat;
start_beat = real(start_beat);
end_beat = real(end_beat);
if (!variable_instance_exists(id, "localXFactor")) then localXFactor = xOffset * 0.05625;
if (!variable_instance_exists(id, "sideDirection")) then sideDirection = isAbove ? -1 : 1;
if (!variable_instance_exists(id, "angleOffset")) then angleOffset = isAbove ? 0 : 180;
speedFloorStart = note_speed * floorPosition;
speedFloorEnd = note_speed * endFloorPosition;
speedHoldFloorLength = note_speed * (endFloorPosition - floorPosition);
if (!is_array(game_2.line_group) || line_id < 0 || line_id >= array_length(game_2.line_group)) {
	instance_deactivate_object(self);
	exit;
};
line_ref = game_2.line_group[line_id];
var base_scale = (variable_global_exists("global_scales") ? global_scales : 1) / 6;
image_xscale = base_scale * widthScale;
uniform_scale = bool(game.settings.noteUniformScale ?? false);
image_yscale = uniform_scale ? image_xscale : base_scale;
hl = 0;
if (variable_global_exists("BYD_COLOR_MODE") && BYD_COLOR_MODE && type != 2) then hl = 2;
if (variable_instance_exists(id, "_hl") && _hl == 1) then hl = 1;
hit_offset = (abs(game.settings.judgeOffset) >= 30000 ? random_range(-201, 201) : game.settings.judgeOffset) * 0.001;
use_acc_judgment = bool(game.settings.enableAccJudgment ?? true);
late_window_sec = ((type == 2 || type == 3 || type == 4) ? 0.161 : 0.201);
hold_body_height = max(1, sprite_get_height(note_hold_body));
switch (type) {
	case 1: sprite_index = note_tap; sound = skin_note_sound("tap", snd_note_tap); judge_type = 1; break;
	case 2: depth = DEPTH.LINE - 1; sprite_index = note_hold_head; sound = skin_note_sound("tap", snd_note_tap); judge_type = 3; break;
	case 3: sprite_index = note_flick; sound = skin_note_sound("flick", snd_note_flick); judge_type = 4; break;
	case 4: sprite_index = note_drag; sound = skin_note_sound("drag", snd_note_drag); judge_type = 2; break;
};
hold_head_attach = 0;
if (type == 2) {
		hold_head_attach = max(1, sprite_get_yoffset(sprite_index));
		var _skin_hold = skin_hold_parts(hl);
		if (is_struct(_skin_hold)) {
			if (sprite_exists(_skin_hold.body)) then hold_body_height = max(1, sprite_get_height(_skin_hold.body));
			if (sprite_exists(_skin_hold.head)) then hold_head_attach = max(1, sprite_get_yoffset(_skin_hold.head));
		};
};
hold_bpm_index = 0;
hold_bpm_last_sec = -infinity;
judge_sec = startSec + hit_offset;
trigger_sec = ((judge_type == 2 || judge_type == 4) ? startSec : judge_sec);
late_deadline_sec = startSec + late_window_sec;
hx0 = 0; hy0 = 0; hx1 = 0; hy1 = 0; hx2 = 0; hy2 = 0;
