///@desc ??????????????? PhiZone Z
if (variable_global_exists("chart_layer_mode") && global.chart_layer_mode) {
	var _hit_depth = chart_layer_depth(hit_effect_layer_z);
	if (depth != _hit_depth) then depth = _hit_depth;
}
