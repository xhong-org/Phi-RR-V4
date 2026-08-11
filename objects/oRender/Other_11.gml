/// @description 启用绘制UI事件
var ui_fade = (variable_instance_exists(id, "chart_exit_alpha") ? chart_exit_alpha : 1);
var _transition_pause_y = (play_transition_active ? play_transition_pause_y : 0);
var _transition_name_y = (play_transition_active ? play_transition_name_y : 0);
var _transition_level_y = (play_transition_active ? play_transition_level_y : 0);
var _transition_score_y = (play_transition_active ? play_transition_score_y : 0);
var _transition_bar_alpha = (play_transition_active ? play_transition_bar_alpha : 1);
draw_set_halign(fa_middle);
draw_set_valign(fa_center);

draw_set_font(game.font);
draw_text_transformed_colour(room_width / 2 , 90 * global_scales , game.settings.comboString , 0.3 * global_scales , 0.3 * global_scales , 0 , image_blend , image_blend , image_blend , image_blend , (combo >= 3) * ui_fade);
draw_text_transformed_colour(room_width / 2 , 60 * global_scales , string(combo) ,  global_scales ,  global_scales , 0 , image_blend , image_blend , image_blend , image_blend , (combo >= 3) * ui_fade);

// 曲名
draw_set_halign(fa_left);
draw_set_valign(fa_center);
draw_text_transformed_colour(40 * global_scales , room_height - (35 * global_scales) + _transition_name_y , game.folder_chart.name , font_scales * global_scales , font_scales * global_scales , 0 , image_blend , image_blend , image_blend , image_blend , ui_fade);

// 难度
draw_set_halign(fa_right);
draw_set_valign(fa_bottom);
draw_text_transformed_colour(room_width - (40 * global_scales) , room_height - (10 * global_scales) + _transition_level_y , game.folder_chart.level , 0.55 * global_scales , 0.55 * global_scales , 0 , image_blend , image_blend , image_blend , image_blend , ui_fade);
// 绘制分数
draw_set_valign(fa_center);
draw_text_transformed_colour(room_width - (40 * global_scales) , (70 * global_scales) + _transition_score_y , ScoreSystem() , 0.75 * global_scales , 0.75 * global_scales , 0 , image_blend , image_blend , image_blend , image_blend , ui_fade);
//draw_text_transformed_colour(room_width - 40 , 100 , $"({accCalc()}%)" , 0.4 , 0.4 , 0 , image_blend , image_blend , image_blend , image_blend , 1);
//var p = (phi_state_list);
//draw_text_transformed_colour(room_width - 40 , 130 , $"({p.prefect} {p.good} {p.bad} {p.miss})" , 0.4 , 0.4 , 0 , image_blend , image_blend , image_blend , image_blend , 1);
//// 摆设暂停键(等下辈子写吧)
draw_sprite_ext(spr_pause , 0 , 50 * global_scales, 50 * global_scales + _transition_pause_y , 0.8 * global_scales , 0.8 * global_scales , 0 , c_white , ui_fade);

var val = (game.__time[4] / oMedia.length);
draw_sprite_ext(spr_pixel_2 , 0 , 0 , 0 , val * (room_width / 2) , (4 * global_scales) , 0 , c_gray , ui_fade * _transition_bar_alpha);
draw_sprite_ext(spr_pixel_2 , 0 , val * room_width - 2 , 0 , 1 , (4 * global_scales) , 0 , image_blend , ui_fade * _transition_bar_alpha);
// ((game.__time[4] / oMedia.length) * (room_width / 2))
//print($"{game.__time[4]} | {oMedia.length} -> {game.__time[4] / oMedia.length}");
//print();
