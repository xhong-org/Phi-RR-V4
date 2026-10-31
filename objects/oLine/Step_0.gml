///@desc 步进：同一阶段里推进游标并求值事件
// 加载动画或暂停时不推进，除非强制初始化。
if (variable_global_exists("loading_animation_active") && global.loading_animation_active
	&& !chart_force_event_init) then exit;
if (game.paused && !chart_force_event_init) {
	// 保留已求值的事件，只把归一化位置映射到当前窗口。
	x = chart_view_left + chart_view_width * __x;
	y = chart_view_height * (1 - __y);
	exit;
};
// 先推进游标，再求值。
event_user(3);
event_user(2);
