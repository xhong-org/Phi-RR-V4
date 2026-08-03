/// @description Draw without allocating a temporary scale array.
if(image_alpha <= 0) then exit;

var draw_scale_x,
	draw_scale_y;
if(self.image_id == line_2){
	draw_scale_x = (0.71 * room_height / 768);
	draw_scale_y = (0.68 * room_width / 1366);
}else{
	draw_scale_x = (self.Scales * room_height / 1080 * 1.35);
	draw_scale_y = draw_scale_x;
};

BYD_COLOR_FUNC;
else{
	image_blend = (game.settings.enableLineJudge ? #ffeca0 : c_white);
	if(game.settings.enableLineJudge){
		if(!bool(phi_state_list.good + phi_state_list.bad + phi_state_list.miss)) then image_blend = #ffeca0;
		if(phi_state_list.good) then image_blend = (make_colour_rgb(162, 238, 255));
		if(bool(phi_state_list.bad + phi_state_list.miss)) then image_blend = c_white;
	};
};

if(self.line_id == 0 && keyboard_check_pressed(vk_f8)) then print([draw_scale_x, draw_scale_y]);
draw_sprite_ext(sprite_index, 0, x, y, draw_scale_x, draw_scale_y, image_angle, image_blend, image_alpha);
