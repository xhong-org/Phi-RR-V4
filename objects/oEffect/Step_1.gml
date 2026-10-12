///@desc 步进开始：旧版打击粒子保持在 PhiZone z 7，避开不可见区间 [8, 16)
// 只在谱面图层模式下改深度，并同步粒子系统。
if (variable_global_exists("chart_layer_mode") && global.chart_layer_mode) {
	var _hit_depth = chart_layer_depth(7);
	if (depth != _hit_depth) then depth = _hit_depth;
	if (variable_instance_exists(id, "p1")) then part_system_depth(p1, depth);
}
