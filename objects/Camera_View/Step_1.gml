/* began */
/// @desc Keep room size + global_scales in sync with window

if (!variable_instance_exists(id, "start_width") || !is_real(start_width) || start_width <= 0) {
        start_width = max(1, room_width);
};
if (!variable_instance_exists(id, "start_height") || !is_real(start_height) || start_height <= 0) {
        start_height = max(1, room_height);
};

// Interactive rooms follow the window; offline rendering keeps its requested surface size.
var _render_sizing = variable_global_exists("render_mode") && global.render_mode;
var _sw = _render_sizing ? global.render_width : pls_window_width();
var _sh = _render_sizing ? global.render_height : pls_window_height();
if (pls_is_gxgames()) {
        // Opera's canvas size jitters by 1-2px; ignore that or surfaces churn
        // every frame and playback gets slower the longer it runs.
        if (!variable_instance_exists(id, "gx_last_room_w")) then gx_last_room_w = room_width;
        if (!variable_instance_exists(id, "gx_last_room_h")) then gx_last_room_h = room_height;
        if (abs(_sw - gx_last_room_w) > 4 || abs(_sh - gx_last_room_h) > 4) {
                gx_last_room_w = _sw;
                gx_last_room_h = _sh;
                if (room_width != _sw) {
                        room_width = _sw;
                        alarm[0] = 1;
                };
                if (room_height != _sh) {
                        room_height = _sh;
                        alarm[0] = 1;
                };
        };
        if (!variable_instance_exists(id, "gx_gui_w") || gx_gui_w != room_width || gx_gui_h != room_height) {
                display_set_gui_size(max(1, room_width), max(1, room_height));
                gx_gui_w = room_width;
                gx_gui_h = room_height;
        };
} else {
        if (room_width != _sw) {
                room_width = _sw;
                alarm[0] = 1;
        };
        if (room_height != _sh) {
                room_height = _sh;
                alarm[0] = 1;
        };
};

// Always refresh global_scales here so UI in the same frame can use it.
if (!variable_global_exists("global_scales")) {
        globalvar global_scales;
};
if (start_width > 0 && start_height > 0) {
        global_scales = min(room_width / start_width, room_height / start_height);
} else {
	global_scales = 1.0;
};
chart_view_refresh(room_width, room_height);

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
