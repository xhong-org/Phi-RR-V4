///@desc 从 RPE 时间轴解析当前 BPM
// 时间轴还没建好就退出。
if (!variable_global_exists("game_1") || !is_struct(game_1) || !is_struct(game_1.Math)) then exit;

var timeline = game_1.Math.ensureBpmTimeline();
if (!is_array(timeline) || array_length(timeline) <= 0) then exit;

var chart_offset_sec = real(game_1.chart_info.offset ?? 0) / 1000;
var chart_sec = game.__time[1] - chart_offset_sec;
bpm_count = game_1.Math.segmentIndexAtAbsSec(chart_sec);
rpe_bpm = real(timeline[bpm_count].bpm);
//print($"BPMList: {timeline}");