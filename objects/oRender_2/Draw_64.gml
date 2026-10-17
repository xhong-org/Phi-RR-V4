///@desc 版本号和帧率不走 GUI。遮罩贴回会盖掉这一层。
if (!chart_hud_ready()) then exit;
draw_set_valign(fa_top);
draw_set_halign(fa_left);
draw_set_colour(c_white);
draw_set_alpha(1);
