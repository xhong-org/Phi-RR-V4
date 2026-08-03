/// @description Advance event cursors; binary-search on replay or large seeks.
var now_time = (game.__time[1] * _beat_per_second),
	is_seek = (now_time < _last_event_time || abs(now_time - _last_event_time) > _beat_per_second * 2);

for(var i = 0 ; i < 4 ; i ++){
	var event_length = (_event_lengths[i]);
	if(event_length <= 0) then continue;

	var events = (_event_groups[i]),
		count = (clamp(_counts[i], 0, event_length - 1));

	if(is_seek){
		var low = 0,
			high = event_length - 1,
			found = 0;
		while(low <= high){
			var middle = ((low + high) >> 1);
			if(events[middle].startTime <= now_time){
				found = middle;
				low = middle + 1;
			}else{
				high = middle - 1;
			};
		};
		count = found;
	}else{
		while(count < event_length - 1 && events[count].endTime < now_time) count ++;
		while(count > 0 && events[count].startTime > now_time) count --;
	};

	_counts[i] = count;
	if(i == 3) then __value[1] = (speedValueList[count]);
};

_last_event_time = now_time;
