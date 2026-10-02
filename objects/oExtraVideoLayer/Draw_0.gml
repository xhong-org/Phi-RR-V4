/// @description Draw one z-indexed video above lower clips.
if (!instance_exists(video_layer_owner)) then exit;
var _index = video_layer_index;
with (video_layer_owner) video_draw_index(_index);
