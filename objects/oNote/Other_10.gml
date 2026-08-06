/// @description Initialise note state and cache time conversions.
if(inition) then exit;

realHitTime = (self.time * _seconds_per_beat);
hold_time_length = (self.holdTime * _seconds_per_beat);
_hold_body_height = (sprite_get_height(note_hold_body));
max_visible_position = (game.Math.maxVisiblePos(self.yOffset) + 0.01);
maximum_visual_length = (self._is_hold && holdFloorLength > 0
	? game.Math.maxVisiblePos(self.yOffset + holdFloorLength) + 0.01
	: max_visible_position);

switch(self.type){
	case 1:
		sprite_index = note_tap;
		sound = snd_note_tap;
	break;
	case 2:
		sprite_index = note_drag;
		sound = snd_note_drag;
	break;
	case 3:
		sound = snd_note_tap;
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
		sound = snd_note_flick;
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
if(game.settings.TEST1) then hitTime2 = (choose( choose(random_range(-95 , 0) , random_range(0 , 95) , choose(1 , 2 , 5 , -1 , -6 , choose(200 , 10))) , 0 , 1 , 2 , 3 , 4 , 5 , 6, 7 , 8 , 9 , 10 ));
else hitTime2 = (abs(game.settings.judgeOffset) >= 30000 ? random_range(-201, 201) : game.settings.judgeOffset);

judgeTime = (self.time + hitTime2 * 0.001 * _beat_per_second);
judgeRealTime = (judgeTime * _seconds_per_beat);
if((realHitTime * 1000000) <= oMedia.length) then maxcombo ++;

inition = true;
