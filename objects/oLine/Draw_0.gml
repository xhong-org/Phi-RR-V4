///@desc 绘制：不临时分配缩放数组
// 加载动画或判定线尚未解冻时不画。
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then exit;
if (instance_exists(oRender)
	&& variable_instance_exists(oRender, "_chart_lines_thaw_pending")
	&& oRender._chart_lines_thaw_pending) then exit;
// 完全透明就不用算缩放。
if(image_alpha <= 0) then exit;

var draw_scale_x,
	draw_scale_y;
// 第二条默认线和自定义贴图用不同的缩放。
if(self.image_id == line_2){
		draw_scale_x = (0.71 * chart_view_height / 768);
		draw_scale_y = (0.68 * chart_view_width / 1366);
}else{
	var _csv_scale = chart_line_csv_sprite_scale(chart_line_override(line_id), sprite_index);
	draw_scale_x = _csv_scale[0];
	draw_scale_y = _csv_scale[1];
};

BYD_COLOR_FUNC;
else{
	image_blend = chart_line_judge_blend();
};

if(self.line_id == 0 && keyboard_check_pressed(vk_f8)) then print([draw_scale_x, draw_scale_y]);
draw_sprite_ext(sprite_index, 0, x, y, draw_scale_x, draw_scale_y, image_angle, image_blend, image_alpha);
