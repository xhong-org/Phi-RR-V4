/* began */
///@desc 步进开始：让房间尺寸和 global_scales 跟着窗口走

// 设计分辨率缺失时用当前房间尺寸补上。
if (!variable_instance_exists(id, "start_width") || !is_real(start_width) || start_width <= 0) {
        start_width = max(1, room_width);
};
if (!variable_instance_exists(id, "start_height") || !is_real(start_height) || start_height <= 0) {
        start_height = max(1, room_height);
};

// 交互房间跟窗口走。渲染和归档测试固定请求的表面，避免 -resolution 随机器变化。
var _archive_sizing = variable_global_exists("pls_archive_test") && global.pls_archive_test;
var _render_sizing = (variable_global_exists("render_mode") && global.render_mode) || _archive_sizing;
var _sw = _render_sizing ? global.render_width : pls_window_width();
var _sh = _render_sizing ? global.render_height : pls_window_height();
// Windows（DWM）和 GX 上画布会抖 1～2 像素。忽略它，否则每帧改房间和应用表面，工作集会一直涨。
var _jitter = pls_is_gxgames() ? 4 : 2;
if (!variable_instance_exists(id, "size_last_w")) then size_last_w = room_width;
if (!variable_instance_exists(id, "size_last_h")) then size_last_h = room_height;
if (abs(_sw - size_last_w) > _jitter || abs(_sh - size_last_h) > _jitter) {
        size_last_w = _sw;
        size_last_h = _sh;
        if (room_width != _sw) {
                room_width = _sw;
                alarm[0] = 1;
        };
        if (room_height != _sh) {
                room_height = _sh;
                alarm[0] = 1;
        };
};
// GX 上把 GUI 尺寸跟房间对齐。
if (pls_is_gxgames()) {
        gx_last_room_w = size_last_w;
        gx_last_room_h = size_last_h;
        if (!variable_instance_exists(id, "gx_gui_w") || gx_gui_w != room_width || gx_gui_h != room_height) {
                display_set_gui_size(max(1, room_width), max(1, room_height));
                gx_gui_w = room_width;
                gx_gui_h = room_height;
        };
};

// 这里每帧刷新 global_scales，同帧界面才能用到。
if (!variable_global_exists("global_scales")) {
        globalvar global_scales;
};
if (start_width > 0 && start_height > 0) {
        global_scales = min(room_width / start_width, room_height / start_height);
} else {
	global_scales = 1.0;
};
chart_view_refresh(room_width, room_height);

// 在任何绘制之前贴合应用表面。帧画完后再改尺寸会清掉这一帧，进房间会闪黑。
if (application_surface_is_enabled() && surface_exists(application_surface)) {
	var _surface_w = surface_get_width(application_surface);
	var _surface_h = surface_get_height(application_surface);
	if (abs(_surface_w - room_width) > 2 || abs(_surface_h - room_height) > 2) {
		surface_resize(application_surface, max(1, room_width), max(1, room_height));
	};
};

// Windows 下按设置开关无阻塞拖动窗口。
if (os_type == os_windows && extension_exists("I_Pulse")) {
	var render_window = variable_global_exists("render_mode") && global.render_mode;
	var prevent_move_freeze = !render_window;
	if (variable_global_exists("game") && is_struct(game) && is_struct(game.settings)) {
		prevent_move_freeze = !render_window && bool(game.settings.preventWindowMoveFreeze ?? true);
	};
	if (is_undefined(_prevent_move_freeze_applied) || _prevent_move_freeze_applied != prevent_move_freeze) {
		if (prevent_move_freeze) rpe_window_drag_enable(window_handle());
		else rpe_window_drag_disable();
		_prevent_move_freeze_applied = prevent_move_freeze;
		print($"[Window] non-blocking move/resize={prevent_move_freeze}");
	};
};
/* ended */
