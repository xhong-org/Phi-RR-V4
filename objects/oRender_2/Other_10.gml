/// @description Synchronize the current PEC BPM from the normalized seconds timeline.
var bpm_events = game_2.chart.bpmList;
var chart_sec = game.__time[1] - game_2.chart.offsetSeconds;
bpm_count = 0;
for (var bpm_i = 1; bpm_i < array_length(bpm_events); bpm_i++) {
	if (bpm_events[bpm_i].second > chart_sec) then break;
	bpm_count = bpm_i;
};
pec_bpm = (array_length(bpm_events) > 0 ? bpm_events[bpm_count].bpm : 60);
