/// @description Keep hit effects on PhiZone z 7, outside invis [8, 16).
if (variable_global_exists("chart_layer_mode") && global.chart_layer_mode) {
	var _hit_depth = chart_layer_depth(7);
	if (depth != _hit_depth) then depth = _hit_depth;
}
