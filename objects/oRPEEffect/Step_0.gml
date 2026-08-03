/// @description Track absolute RPE chart seconds.
var chart_offset = (is_struct(game_1.chart_info) ? real(game_1.chart_info.offset ?? 0) / 1000 : 0);
chart_time = max(0, game.__time[1] - chart_offset);
