///@desc 清理：释放可选的离屏背景表面
if (is_real(surface) && surface_exists(surface)) {
        surface_free(surface);
};
surface = -1;