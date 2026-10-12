///@desc 步进开始：打击特效保持在 PhiZone z 7，避开不可见区间 [8, 16)
// 只在谱面图层模式下把深度拉回 z 7。
if (variable_global_exists("chart_layer_mode") && global.chart_layer_mode) {
	var _hit_depth = chart_layer_depth(7);
	if (depth != _hit_depth) then depth = _hit_depth;
}
