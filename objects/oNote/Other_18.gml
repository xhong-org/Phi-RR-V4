/// @description Correct hold length after a window resize.
if(!_is_hold) then exit;

var scale_y = (room_height * 0.6);
if(isHold) then yscale = ((isClickRealTime + hold_time_length - game.__time[1]) * scale_y / _hold_body_height * self[$ "speed"]);
else yscale = (hold_time_length * scale_y / _hold_body_height * self[$ "speed"]);
