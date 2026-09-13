/// @description Initialise note state and cache time conversions.
if(inition) then exit;

realHitTime = (self.time * _seconds_per_beat);
hold_time_length = (self.holdTime * _seconds_per_beat);
_hold_body_height = (sprite_get_height(note_hold_body));
var _skin_hl = (variable_instance_exists(id, "_hl") && is_real(_hl)) ? _hl : 0;
var _skin_hold = skin_hold_parts(_skin_hl);
if (is_struct(_skin_hold) && sprite_exists(_skin_hold.body)) {
	_hold_body_height = max(1, sprite_get_height(_skin_hold.body));
};
max_visible_position = (self.yOffset + 0.01);
maximum_visual_length = (self._is_hold && holdFloorLength > 0
	? (self.yOffset + holdFloorLength + 0.01)
	: max_visible_position);

switch(self.type){
	case 1:
		sprite_index = note_tap;
		sound = skin_note_sound("tap", snd_note_tap);
	break;
	case 2:
		sprite_index = note_drag;
		sound = skin_note_sound("drag", snd_note_drag);
	break;
	case 3:
		sound = skin_note_sound("tap", snd_note_tap);
		depth ++;
		sprite_index = note_hold_head;
		_hx0 = 0;
		_hy0 = 0;
		_hx1 = 0;
		_hy1 = 0;
		_hx2 = 0;
		_hy2 = 0;
		yscale = (hold_time_length * room_height * 0.6 / _hold_body_height * self[$ "speed"]);
		isClickRealTime = realHitTime;
		isHold = false;
		_bak_time = realHitTime;
		notJudge = true;
		isMiss = false;
	break;
	case 4:
		sprite_index = note_flick;
		sound = skin_note_sound("flick", snd_note_flick);
	break;
};

isBad = false;
_bad_x = 0;
_bad_y = 0;
_bad_angle = 0;
_note_x = 0;
_note_y = 0;
isJudge = false;
var initial_scale = (variable_global_exists("global_scales") ? global_scales : 1.0);
image_xscale = (initial_scale / 6);
image_yscale = image_xscale;
_last_global_scales = initial_scale;

if(self.type != 3 && BYD_COLOR_MODE) then hl = 2;
hit_status = TYPE.NONE;
hitTime2 = chart_auto_hit_offset_ms(self.type);

judgeTime = (self.time + hitTime2 * 0.001 * _beat_per_second);
judgeRealTime = (judgeTime * _seconds_per_beat);
// GX audio length is often still -1/0 here (JS decode / PCM HTTP). Treat
// unknown length as "count this note" so official score is not 0/0 = NaN.
var _media_len = 0;
if (instance_exists(oMedia) && is_real(oMedia.length) && is_finite(oMedia.length) && oMedia.length > 0) then _media_len = oMedia.length;
if (_media_len <= 0 || (realHitTime * 1000000) <= _media_len) then maxcombo ++;

inition = true;
