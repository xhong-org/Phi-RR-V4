/// @description Initialise RPE note state
if (inition) then exit;

// map Official-compatible sprites (type already remapped in CreateLines)
switch (type) {
	case 1:
		depth = DEPTH.NOTE + 1;
		sprite_index = note_tap;
		sound = snd_note_tap;
		break;
	case 2:
		depth = DEPTH.NOTE + 2;
		sprite_index = note_drag;
		sound = snd_note_drag;
		break;
	case 3:
		depth = DEPTH.NOTE + 3;
		sound = snd_note_tap;
		sprite_index = note_hold_head;
		_hx0 = 0; _hy0 = 0;
		_hx1 = 0; _hy1 = 0;
		_hx2 = 0; _hy2 = 0;
		_hold_body_height = max(1, sprite_get_height(note_hold_body));
		_hold_tail_height = max(1, sprite_get_height(note_hold_end));
		_hold_head_attach = max(1, sprite_get_yoffset(note_hold_head) - sprite_get_bbox_top(note_hold_head));
		isHold = false;
		notJudge = true;
		isMiss = false;
		_bak_time = 0;
		__first__ = false; // PCR: head judged / attached to line
		break;
	case 4:
		depth = DEPTH.NOTE;
		sprite_index = note_flick;
		sound = snd_note_flick;
		break;
	default:
		depth = DEPTH.NOTE + 1;
		sprite_index = note_tap;
		sound = snd_note_tap;
		break;
};

// Shared judge/draw flags (must exist for non-hold notes too)
isHold = false;
notJudge = true;
isMiss = false;
isBad = false;
_bad_x = 0;
_bad_y = 0;
_bad_angle = 0;
_note_x = 0;
_note_y = 0;
_x_h = 0;
_y_h = 0;
isJudge = false;
hit_status = TYPE.NONE;

var initial_scale = (variable_global_exists("global_scales") ? global_scales : 1.0);
image_xscale = (initial_scale / 6) * size;
image_yscale = image_xscale;
_last_global_scales = initial_scale;
image_alpha = alpha;
image_blend = c_white;

// hold visual length in floor units (PCR velocity)
if (_is_hold) {
	if (hold_length_floor == 0 && endFloorPosition != floorPosition) {
		hold_length_floor = endFloorPosition - floorPosition;
		holdFloorLength = hold_length_floor;
	};
	yscale = 0;
};

hl = 0;
if (variable_global_exists("BYD_COLOR_MODE") && BYD_COLOR_MODE && type != 3) then hl = 2;
if (variable_instance_exists(id, "_hl") && is_real(_hl)) then hl = _hl;

// auto-judge offset (same as Official)
if (variable_global_exists("game") && is_struct(game) && game.settings.TEST1) {
	hitTime2 = choose(choose(random_range(-95, 0), random_range(0, 95), choose(1, 2, 5, -1, -6, choose(200, 10))), 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
} else if (variable_global_exists("game") && is_struct(game)) {
	hitTime2 = (abs(game.settings.judgeOffset) >= 30000 ? random_range(-201, 201) : game.settings.judgeOffset);
} else {
	hitTime2 = 0;
};

inition = true;
