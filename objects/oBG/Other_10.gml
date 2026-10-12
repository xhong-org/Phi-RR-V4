///@desc 用户事件 0：按房间尺寸创建背景表面
size = [ room_width , room_height ];
// 表面不存在才创建，避免重复分配。
if (!(is_real(surface) && surface_exists(surface))) {
        surface = surface_create(size[0], size[1]);
};