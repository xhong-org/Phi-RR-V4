/// @description Capture normally unless RPE effects own the final composition.
if (instance_exists(oRPEEffect)) then exit;
event_user(0);
if (!encoder_finished && surface_exists(overlay_surface)) {
    draw_surface_stretched(overlay_surface, 0, 0, room_width, room_height);
};
