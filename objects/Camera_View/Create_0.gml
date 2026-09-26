/* began */
/// @desc Camera / scale owner. Must run before UI objects.
// Keep this object first in room instance order.

// Design resolution snapshot for global_scales.
start_width = room_width;
start_height = room_height;
if (start_width <= 0) then start_width = 1366;
if (start_height <= 0) then start_height = 768;

var _archive_sizing = variable_global_exists("pls_archive_test") && global.pls_archive_test;
if ((variable_global_exists("render_mode") && global.render_mode) || _archive_sizing) {
	// Keep gameplay coordinates proportional to the original 1366x768 design.
	// Archive tests honor -resolution the same way, so text size can be compared.
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

// Global UI/world scale. Other objects should read this, not recompute window scale.
globalvar global_scales;
global_scales = 1.0;
// Aspect ratio of the effective chart area. Keep this global so the mask,
// chart layout, and custom judge-line textures use the same viewport.
globalvar chart_aspect_ratio;
chart_aspect_ratio = 16 / 9;
if (variable_global_exists("chart_session") && is_struct(global.chart_session)) {
	var _session_aspect = chart_parse_aspect_ratio(global.chart_session[$ "aspect_ratio"] ?? (16 / 9), 16 / 9);
	if (is_finite(_session_aspect) && _session_aspect > 0) then chart_aspect_ratio = _session_aspect;
};
globalvar chart_surface, chart_surface_active;
chart_surface = -1;
chart_surface_active = false;
globalvar chart_background_surface;
chart_background_surface = -1;

// Immediate scale for current room size.
if (start_width > 0 && start_height > 0) {
        global_scales = min(room_width / start_width, room_height / start_height);
};
chart_view_refresh(room_width, room_height);

depth = -100000; // run early relative to normal gameplay objects when possible

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


/// @function    camera_zoom_out_centered(cam, zoom_factor)
/// @description 将指定摄像机缩放并居中
/// @param {camera} cam           摄像机ID，通常是 view_camera[0]
/// @param {real}   zoom_factor   缩放系数，0.5即为缩小一半
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
