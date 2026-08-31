/// @description Create the MediaCodec output surface on the GL thread.
if (video_handle < 0) then exit;
var setup_status = ffvideos_ext_get_status(video_handle);
if (setup_status == FFVideosStatus.Error || setup_status == FFVideosStatus.Closed) then exit;
ffvideos_ext_draw(video_handle, 0, 0, 0, 0, 0, 0);
