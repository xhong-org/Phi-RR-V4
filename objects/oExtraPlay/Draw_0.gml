/// @description Draw the current RPE video behind judge lines.
if (video_index < 0 || video_handle < 0) then exit;
var status = ffvideos_get_status(video_handle);
if (status != FFVideosStatus.Playing && status != FFVideosStatus.Paused) then exit;
var video_width = ffvideos_get_width(video_handle);
var video_height = ffvideos_get_height(video_handle);
if (video_width <= 0 || video_height <= 0) then exit;

var scale_mode = videos[video_index].scale;
var sx = room_width / video_width;
var sy = room_height / video_height;
var draw_sx = (scale_mode == "fit" ? sx : (scale_mode == "inside" ? min(sx, sy) : max(sx, sy)));
var draw_sy = (scale_mode == "fit" ? sy : draw_sx);
var draw_width = video_width * draw_sx;
var draw_height = video_height * draw_sy;
var draw_x = (room_width - draw_width) * 0.5;
var draw_y = (room_height - draw_height) * 0.5;
var alpha = clamp(real(videos[video_index].alpha.value), 0, 1);
var dim = clamp(real(videos[video_index].dim.value), 0, 1);
draw_flush();
var video_draw_status = ffvideos_draw(video_handle,
	draw_x / room_width,
	draw_y / room_height,
	(draw_x + draw_width) / room_width,
	(draw_y + draw_height) / room_height,
	alpha,
	dim);
if (video_draw_status < 0 && !video_error_logged) {
	print($"[FFVideos] Draw failed: {ffvideos_get_error(0)}");
	video_error_logged = true;
};
