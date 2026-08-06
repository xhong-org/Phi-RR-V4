/// @description Track absolute RPE chart seconds.
var chart_offset = chart_extra_offset_seconds();
chart_time = max(0, game.__time[1] - chart_offset);
