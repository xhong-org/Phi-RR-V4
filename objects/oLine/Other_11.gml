/// @description Precompute the accumulated floor position at each speed event.
var value = 0;
speedValueList = [0];
for(var i = 0 ; i < _event_lengths[3] ; i ++){
	var speed_event = (_speed_events[i]),
		duration = ((speed_event.endTime - speed_event.startTime) * _seconds_per_beat);
	value += (duration * speed_event.value);
	array_add(speedValueList, value);
};
