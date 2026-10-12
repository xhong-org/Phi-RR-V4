///@desc 没有 RPE 效果接管合成时，在绘制结束抓帧并贴进度
// RPE 效果会在自己的绘制结束里抓帧。
if (instance_exists(oRPEEffect)) then exit;
event_user(0);
if (!encoder_finished && surface_exists(overlay_surface)) {
    draw_surface_stretched(overlay_surface, 0, 0, room_width, room_height);
};
