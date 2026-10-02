/// @description Own the chart composition surface.
depth = -12000;
surface_id = -1;
surface_width = 0;
surface_height = 0;
target_active = false;
// True only on the draw that created the composition surface.
surface_born = false;
globalvar chart_surface_active;
chart_surface_active = false;
globalvar chart_background_surface;
chart_background_surface = -1;
function chart_mask_surface_ensure() {
    var _w = max(1, surface_get_width(application_surface));
    var _h = max(1, surface_get_height(application_surface));
    if (!surface_exists(surface_id) || abs(surface_width - _w) > 2 || abs(surface_height - _h) > 2) {
        if (surface_exists(surface_id)) surface_free(surface_id);
        surface_id = surface_create(_w, _h);
        surface_width = _w;
        surface_height = _h;
        surface_born = surface_exists(surface_id);
    };
    return surface_exists(surface_id);
}
