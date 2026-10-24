///@desc 按键按下 F11：切换全屏，渲染模式不处理
if (variable_global_exists("render_mode") && global.render_mode) then exit;

// 进入全屏时去掉边框，退出时再加回。
var entering_fullscreen = !window_get_fullscreen();
if (entering_fullscreen) {
	// 跨房间保留窗口状态，避免在全屏进入谱面后丢失恢复尺寸。
	global.windowed_bounds = {
		width:window_get_width(), height:window_get_height(), x:window_get_x(), y:window_get_y()
	};
	window_set_showborder(false);
	window_set_fullscreen(true);
} else {
	window_set_fullscreen(false);
	window_set_showborder(true);
	if (variable_global_exists("windowed_bounds") && is_struct(global.windowed_bounds)) {
		var bounds = global.windowed_bounds;
		window_set_size(bounds.width, bounds.height);
		window_set_position(bounds.x, bounds.y);
	};
};
// 系统可能稍后才完成切换。下一帧重新读取尺寸，再统一更新缩放和应用表面。
size_last_w = -1;
size_last_h = -1;
alarm[0] = 1;
