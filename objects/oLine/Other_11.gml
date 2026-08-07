/// @description Precompute the accumulated floor position at each speed event.
var value = 0;
speedValueList = [0];
for(var i = 0 ; i < _event_lengths[3] ; i ++){
	var speed_event = (_speed_events[i]),
		duration = ((speed_event.endTime - speed_event.startTime) * _seconds_per_beat);
	// Use the official event floor base when it is present. Older charts may
	// omit it, so keep the cumulative value as a fallback.
	var event_floor = value;
	if (struct_exists(speed_event, "floorPosition") && is_real(speed_event.floorPosition)) {
		event_floor = speed_event.floorPosition;
	};
	if (i == 0) then speedValueList[0] = event_floor;
	else speedValueList[i] = event_floor;
	value = event_floor + duration * speed_event.value;
};
