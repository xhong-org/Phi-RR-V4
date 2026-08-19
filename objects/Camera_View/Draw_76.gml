/* began */
/// @desc

// 更新程序表面
if (application_surface_is_enabled()) {
	if (surface_exists(application_surface)) {
		var _sw = (max(1, room_width)), _sh = (max(1, room_height));
		if (
			((surface_get_width(application_surface)) != _sw)
		||
			((surface_get_height(application_surface)) != _sh)
		) {
			surface_resize(application_surface, _sw, _sh);
		};
	};
};

chart_view_refresh(room_width, room_height);

/* ended */
