/// @function get_window_pos_scale(X, Y, W, H)
/// @desc 将配置坐标转换为当前窗口的实际坐标
/// @param {float} X 配置X坐标
/// @param {float} Y 配置Y坐标
/// @param {float} W 窗口宽度
/// @param {float} H 窗口高度
/// @returns {array} [screen_x, screen_y] 转换后的屏幕坐标

function get_window_pos_scale(X, Y, W = -1, H = -1) {
    if (!is_real(W) || W <= 0) then W = pls_window_width();
    if (!is_real(H) || H <= 0) then H = pls_window_height();
    // 计算水平和垂直的缩放比例
    var scale_x = (W / 1350.0);  // 1350 = 675 * 2
    var scale_y = (H / 900.0);   // 900 = 450 * 2
    
    // 选择较小的比例以确保内容完全显示在屏幕内
    //var scale = min(scale_x, scale_y);
    
    // 将配置坐标转换为实际屏幕坐标
    // GameMaker中通常使用左上角为原点，Y轴向下为正
    //var screen_x = X * scale + W / 2.0;
    //var screen_y = -Y * scale + H / 2.0;
	
	var screen_x = ((X * scale_x + (W / 2))),
		screen_y = ((-Y * scale_y + (H / 2)));
    
    return [screen_x, screen_y];
};
