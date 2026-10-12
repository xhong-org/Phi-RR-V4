/* began */
///@desc 创建：相机与全局缩放的主人，必须早于界面对象
// 房间实例顺序里应排在最前。

// 记下设计分辨率，供 global_scales 使用。
start_width = room_width;
start_height = room_height;
if (start_width <= 0) then start_width = 1366;
if (start_height <= 0) then start_height = 768;

var _archive_sizing = variable_global_exists("pls_archive_test") && global.pls_archive_test;
if ((variable_global_exists("render_mode") && global.render_mode) || _archive_sizing) {
	// 玩法坐标仍按最初的 1366x768 比例。归档测试同样遵守 -resolution，方便对比文字大小。
	start_width = 1366;
	start_height = 768;
	room_width = global.render_width;
	room_height = global.render_height;
} else if (pls_is_gxgames()) {
	room_width = pls_window_width();
	room_height = pls_window_height();
};
gx_last_room_w = room_width;
gx_last_room_h = room_height;
gx_gui_w = -1;
gx_gui_h = -1;

// 全局界面与世界缩放。其他对象应读它，不要自己再算窗口缩放。
globalvar global_scales;
global_scales = 1.0;
// 有效谱面区域的宽高比。遮罩、谱面布局和自定义判定线贴图共用这一视口。
globalvar chart_aspect_ratio;
chart_aspect_ratio = 16 / 9;
// 谱面会话里的宽高比优先于默认 16:9。
if (variable_global_exists("chart_session") && is_struct(global.chart_session)) {
	var _session_aspect = chart_parse_aspect_ratio(global.chart_session[$ "aspect_ratio"] ?? (16 / 9), 16 / 9);
	if (is_finite(_session_aspect) && _session_aspect > 0) then chart_aspect_ratio = _session_aspect;
};
globalvar chart_surface, chart_surface_active;
chart_surface = -1;
chart_surface_active = false;
globalvar chart_background_surface;
chart_background_surface = -1;

// 按当前房间尺寸立刻算出缩放。
if (start_width > 0 && start_height > 0) {
        global_scales = min(room_width / start_width, room_height / start_height);
};
chart_view_refresh(room_width, room_height);

depth = -100000; // 尽量早于普通玩法对象执行

// Windows 下按设置安装无阻塞拖动，避免拖窗口时卡住。
_prevent_move_freeze_applied = undefined;
if (os_type == os_windows && extension_exists("I_Pulse")) {
	var render_window = variable_global_exists("render_mode") && global.render_mode;
	var prevent_move_freeze = !render_window;
	if (variable_global_exists("game") && is_struct(game) && is_struct(game.settings)) {
		prevent_move_freeze = !render_window && bool(game.settings.preventWindowMoveFreeze ?? true);
	};
	var drag_enabled = prevent_move_freeze ? rpe_window_drag_enable(window_handle()) : false;
	if (!prevent_move_freeze) rpe_window_drag_disable();
	_prevent_move_freeze_applied = prevent_move_freeze;
	if (!variable_global_exists("rpe_nonblocking_drag_logged")) {
		global.rpe_nonblocking_drag_logged = true;
		print($"[Window] Non-blocking move/resize: enabled={prevent_move_freeze}, installed={drag_enabled}");
	};
};


///@desc 将指定摄像机缩放并保持画面中心不变
///@param {Id.Camera} cam 摄像机，通常是 view_camera[0]
///@param {Real} zoom_factor 缩放系数，小于 1 为缩小
///@returns {Undefined} 无
function camera_zoom_out_centered(cam, zoom_factor) {
    // 1. 获取摄像机当前的宽度和高度
    var _cam_w = camera_get_view_width(cam);
    var _cam_h = camera_get_view_height(cam);

    // 2. 计算缩放后的新宽度和高度
    var _new_w = _cam_w * zoom_factor;
    var _new_h = _cam_h * zoom_factor;

    // 3. 设置摄像机的新尺寸
    camera_set_view_size(cam, _new_w, _new_h);

    // 4. 获取当前摄像机位置（左上角坐标）
    var _cam_x = camera_get_view_x(cam);
    var _cam_y = camera_get_view_y(cam);

    // 5. 计算视图中心点坐标
    var _center_x = _cam_x + _cam_w * 0.5;
    var _center_y = _cam_y + _cam_h * 0.5;

    // 6. 计算缩放后，为使中心点不变，摄像机左上角应处的新位置
    var _new_x = _center_x - _new_w * 0.5;
    var _new_y = _center_y - _new_h * 0.5;

    // 7. 设置摄像机的新位置
    camera_set_view_pos(cam, _new_x, _new_y);
}

/* ended */
