///@desc 跟随音符大小更新旧版粒子，并同步 PhiZone Z
if (note_scale != game.settings.noteSize) {
	note_scale = game.settings.noteSize;
	part_type_size(_hitFX, note_scale, note_scale, 0, 0);
	part_type_size(part, (_scale - 1) * note_scale, (_scale + 2) * note_scale, _scale_ins * note_scale, 0);
	part_type_speed(part, (_spd - 15) * note_scale, _spd * note_scale, -3.2 * note_scale, 0);
}
if (variable_global_exists("chart_layer_mode") && global.chart_layer_mode) {
	var _hit_depth = chart_layer_depth(hit_effect_layer_z);
	if (depth != _hit_depth) then depth = _hit_depth;
	if (variable_instance_exists(id, "p1")) then part_system_depth(p1, depth);
}
