///@desc 把配置坐标换成当前窗口上的屏幕坐标
///@param {Real} X 配置横坐标
///@param {Real} Y 配置纵坐标
///@param {Real} W 窗口宽度，非正数时改用当前窗口宽
///@param {Real} H 窗口高度，非正数时改用当前窗口高
///@returns {Array} 屏幕坐标，依次为横坐标和纵坐标
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
