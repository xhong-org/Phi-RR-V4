///@desc 创建：PEC 判定线的运行时状态
depth = DEPTH.LINE;

// 贴图缺失时退回默认判定线。
if (!variable_instance_exists(id, "image_id") || !sprite_exists(image_id)) then image_id = line;
if (!variable_instance_exists(id, "line_csv_scale")) then line_csv_scale = 1;
sprite_index = image_id;
image_blend = chart_line_judge_blend();
var initial_scale = (variable_global_exists("global_scales") ? global_scales : 1);
// 默认线和自定义贴图的初始缩放不同。
if (image_id == line) {
	image_xscale = 0.9204 * initial_scale;
	image_yscale = 0.52 * initial_scale;
} else {
	var _csv_scale = chart_line_csv_sprite_scale(chart_line_override(line_id), image_id);
	image_xscale = _csv_scale[0];
	image_yscale = _csv_scale[1];
};
// 没有事件结构就用空的 PEC 线数据，并缓存各通道长度。
if (!variable_instance_exists(id, "events") || !is_struct(events)) then events = pec_line_data();
_move_index = 0;
_alpha_index = 0;
_rotate_index = 0;
_speed_index = 0;
_move_value = [0, 0];
_move_x = 0;
_move_y = 0;
_alpha_value = 1;
_alpha_raw = 255;
_rotate_value = 0;
floor_position = 0;
line_sec = 0;
_last_line_sec = -infinity;
__cos = 1;
__sin = 0;
_last_angle = 0;
_last_scale = -1;
_last_room_height = -1;
_last_view_width = -1;
_move_events = events.moveEvents;
_alpha_events = events.alphaEvents;
_rotate_events = events.rotateEvents;
_speed_events = events.speedEvents;
_move_count = array_length(_move_events);
_alpha_count = array_length(_alpha_events);
_rotate_count = array_length(_rotate_events);
_speed_count = array_length(_speed_events);
chart_force_event_init = false;
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then visible = false;
