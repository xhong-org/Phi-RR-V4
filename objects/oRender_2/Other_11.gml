/// @description Draw PEC chart UI and progress.
var ui_alpha = chart_exit_alpha;
draw_set_font(game.font);
draw_set_halign(fa_center);
draw_set_valign(fa_center);
draw_text_transformed_colour(room_width/2, 90*global_scales, game.settings.comboString, 0.3*global_scales, 0.3*global_scales, 0, c_white, c_white, c_white, c_white, (combo>=3)*ui_alpha);
draw_text_transformed_colour(room_width/2, 60*global_scales, string(combo), global_scales, global_scales, 0, c_white, c_white, c_white, c_white, (combo>=3)*ui_alpha);
draw_set_halign(fa_left);
draw_text_transformed_colour(40*global_scales, room_height-35*global_scales, game.folder_chart.name, font_scales*global_scales, font_scales*global_scales, 0, c_white, c_white, c_white, c_white, ui_alpha);
draw_set_halign(fa_right);
draw_set_valign(fa_bottom);
draw_text_transformed_colour(room_width-40*global_scales, room_height-10*global_scales, game.folder_chart.level, 0.55*global_scales, 0.55*global_scales, 0, c_white, c_white, c_white, c_white, ui_alpha);
draw_set_valign(fa_center);
draw_text_transformed_colour(room_width-40*global_scales, 70*global_scales, ScoreSystem(), 0.75*global_scales, 0.75*global_scales, 0, c_white, c_white, c_white, c_white, ui_alpha);
draw_sprite_ext(spr_pause, 0, 50*global_scales, 50*global_scales, 0.8*global_scales, 0.8*global_scales, 0, c_white, ui_alpha);
var progress = 0;
if (instance_exists(oMedia) && oMedia.length > 0) then progress = clamp(game.__time[4]/oMedia.length, 0, 1);
draw_sprite_ext(spr_pixel_2, 0, 0, 0, progress*(room_width/2), 4*global_scales, 0, c_gray, ui_alpha);
draw_sprite_ext(spr_pixel_2, 0, progress*room_width-2, 0, 1, 4*global_scales, 0, c_white, ui_alpha);
