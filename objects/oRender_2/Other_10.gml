///@desc 按秒时间轴同步当前 PEC 的 BPM
var bpm_events = game_2.chart.bpmList;
var chart_sec = game.__time[1] - game_2.chart.offsetSeconds;
if (!variable_instance_exists(id, "pec_bpm_last_sec") || chart_sec < pec_bpm_last_sec) {
	bpm_count = pec_bpm_index_at_sec(bpm_events, chart_sec);
};
// BPM 事件向前走到当前秒。
while (bpm_count + 1 < array_length(bpm_events) && bpm_events[bpm_count + 1].second <= chart_sec) bpm_count++;
pec_bpm_last_sec = chart_sec;
pec_bpm = (array_length(bpm_events) > 0 ? bpm_events[bpm_count].bpm : 60);
