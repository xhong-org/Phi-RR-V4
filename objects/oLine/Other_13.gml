///@desc 用户事件 3：推进事件游标；回放或大跳转时二分查找
if (events_flat) {
	official_line_seek_flat();
	exit;
};
var now_time = (game.__time[1] * _beat_per_second),
	is_seek = (now_time < _last_event_time || abs(now_time - _last_event_time) > _beat_per_second * 2);

for(var i = 0 ; i < 4 ; i ++){
	var event_length = (_event_lengths[i]);
	// 这条流没有事件就跳过。
	if(event_length <= 0) then continue;

	var events = (_event_groups[i]),
		count = (clamp(_counts[i], 0, event_length - 1));

	if(i == 3){
		// sim-phi：取第一条还没结束的速度事件。空隙用下一条，不要把上一段速度延续过去。
		// 大跳转时二分找第一条尚未结束的速度事件。
		if(is_seek){
			var low = 0,
				high = event_length - 1,
				found = event_length - 1;
			while(low <= high){
				var middle = ((low + high) >> 1);
				if(events[middle].endTime < now_time){
					low = middle + 1;
				}else{
					found = middle;
					high = middle - 1;
				};
			};
			count = found;
		}else{
			// 正常播放只向前挪到还没结束的事件。
			while(count < event_length - 1 && events[count].endTime < now_time) count ++;
		};
	// 其他事件在跳转时二分到最后一个已经开始的事件。
	}else if(is_seek){
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
		// 正常播放时前后微调，停在包含当前时间的事件上。
		while(count < event_length - 1 && events[count].endTime < now_time) count ++;
		while(count > 0 && events[count].startTime > now_time) count --;
	};

	_counts[i] = count;
	// 速度流的 floor 基准跟着游标走。
	if(i == 3) then __value[1] = (speedValueList[count]);
};

_last_event_time = now_time;
