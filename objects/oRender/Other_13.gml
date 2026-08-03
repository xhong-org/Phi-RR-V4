/// @description 绘制FPS

draw_set_halign(fa_left);
draw_set_colour(c_gray);
//draw_text_transformed(30 , 150 , $"Effect Counts: {array_length(oEffectNew.effect_events)}" , 0.35 , 0.35 , 0);
draw_set_halign(fa_right);
draw_set_colour(c_white);
draw_text_transformed(room_width , (30 * global_scales) , $"{ceil(fpsReal)}({fps})" , 0.35 * global_scales , 0.35 * global_scales , 0);
