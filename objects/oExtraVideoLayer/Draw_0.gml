///@desc 绘制：按 z 画出这一层视频，盖住更低的片段
// 宿主没了就不再画。
if (!instance_exists(video_layer_owner)) then exit;
var _index = video_layer_index;
with (video_layer_owner) video_draw_index(_index);
