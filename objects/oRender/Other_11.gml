/// @description Enable chart UI draw event.
var ui_fade = (variable_instance_exists(id, "chart_exit_alpha") ? chart_exit_alpha : 1);
var _transition_pause_y = (play_transition_active ? play_transition_pause_y : 0);
var _transition_name_y = (play_transition_active ? play_transition_name_y : 0);
var _transition_level_y = (play_transition_active ? play_transition_level_y : 0);
var _transition_score_y = (play_transition_active ? play_transition_score_y : 0);
var _transition_bar_alpha = (play_transition_active ? play_transition_bar_alpha : 1);
var _chart_left = chart_view_left;
var _chart_width = chart_view_width;
var _chart_right = chart_view_right;
draw_set_halign(fa_middle);
draw_set_valign(fa_center);

draw_set_font(game.font);
draw_text_transformed_colour(_chart_left + _chart_width / 2, 90 * global_scales, game.settings.comboString, 0.3 * global_scales, 0.3 * global_scales, 0, image_blend, image_blend, image_blend, image_blend, (combo >= 3) * ui_fade);
draw_text_transformed_colour(_chart_left + _chart_width / 2, 60 * global_scales, string(combo), global_scales, global_scales, 0, image_blend, image_blend, image_blend, image_blend, (combo >= 3) * ui_fade);

draw_set_halign(fa_left);
draw_set_valign(fa_center);
draw_text_transformed_colour(_chart_left + 40 * global_scales, room_height - (35 * global_scales) + _transition_name_y, game.folder_chart.name, font_scales * global_scales, font_scales * global_scales, 0, image_blend, image_blend, image_blend, image_blend, ui_fade);

draw_set_halign(fa_right);
draw_set_valign(fa_bottom);
draw_text_transformed_colour(_chart_right - (40 * global_scales), room_height - (10 * global_scales) + _transition_level_y, game.folder_chart.level, 0.55 * global_scales, 0.55 * global_scales, 0, image_blend, image_blend, image_blend, image_blend, ui_fade);
draw_set_valign(fa_center);
draw_text_transformed_colour(_chart_right - (40 * global_scales), (70 * global_scales) + _transition_score_y, ScoreSystem(), 0.75 * global_scales, 0.75 * global_scales, 0, image_blend, image_blend, image_blend, image_blend, ui_fade);
draw_sprite_ext(spr_pause, 0, _chart_left + 50 * global_scales, 50 * global_scales + _transition_pause_y, 0.8 * global_scales, 0.8 * global_scales, 0, c_white, ui_fade);

var val = (game.__time[4] / oMedia.length);
draw_sprite_ext(spr_pixel_2, 0, _chart_left, 0, val * (_chart_width / 2), 4 * global_scales, 0, c_gray, ui_fade * _transition_bar_alpha);
draw_sprite_ext(spr_pixel_2, 0, _chart_left + val * _chart_width - 2, 0, 1, 4 * global_scales, 0, image_blend, ui_fade * _transition_bar_alpha);
