///@desc 创建：持有谱面合成表面
depth = -12000;
surface_id = -1;
surface_width = 0;
surface_height = 0;
target_active = false;
// 只在创建合成表面的那一帧绘制里为真。
surface_born = false;
globalvar chart_surface_active;
chart_surface_active = false;
globalvar chart_background_surface;
chart_background_surface = -1;
///@desc 保证谱面合成表面存在且尺寸接近应用表面
///@returns {Bool} 表面可用则为 true
function chart_mask_surface_ensure() {
    var _w = max(1, surface_get_width(application_surface));
    var _h = max(1, surface_get_height(application_surface));
    // 不存在或尺寸差超过 2 像素才重建，避免抖动反复分配。
    if (!surface_exists(surface_id) || abs(surface_width - _w) > 2 || abs(surface_height - _h) > 2) {
        // 旧表面先释放。
        if (surface_exists(surface_id)) surface_free(surface_id);
        surface_id = surface_create(_w, _h);
        surface_width = _w;
        surface_height = _h;
        surface_born = surface_exists(surface_id);
    };
    return surface_exists(surface_id);
}
