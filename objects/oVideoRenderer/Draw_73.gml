/// @description Capture normally unless RPE effects own the final composition.
if (instance_exists(oRPEEffect)) then exit;
event_user(0);
