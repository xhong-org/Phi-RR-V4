/// @description Draw FPS
draw_set_halign(fa_right);
draw_set_colour(c_white);
draw_text_transformed(chart_view_right, (30 * global_scales), $"{ceil(fpsReal)}({fps})", 0.35 * global_scales, 0.35 * global_scales, 0);
