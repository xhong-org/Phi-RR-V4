// 在 oChartMask 合成之后画。遮罩还在时本对象在它后面，结束黑边不会被信箱盖住。
// 遮罩还没释放就不画侧边压暗。
if (!variable_instance_exists(id, "mask_released") || !mask_released) then exit;
depth = -12200;
chart_mask_side_dim_draw();
