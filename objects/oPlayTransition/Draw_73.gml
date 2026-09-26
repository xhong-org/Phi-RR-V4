/// Drawn after oChartMask composites. While the mask still exists this object
/// stays behind it, so the ending black cannot be covered by the letterbox.
if (!variable_instance_exists(id, "mask_released") || !mask_released) then exit;
depth = -12200;
chart_mask_side_dim_draw();
