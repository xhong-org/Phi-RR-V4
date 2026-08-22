/// @description Track absolute RPE chart seconds.
if (variable_instance_exists(id, "effect_boundary_role")) then exit;
var chart_offset = chart_extra_offset_seconds();
chart_time = max(0, game.__time[1] - chart_offset);
effect_boundaries_create();
