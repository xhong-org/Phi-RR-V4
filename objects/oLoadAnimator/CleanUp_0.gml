///@desc 清理：释放运行时封面、模糊图和字体
if (sprite_exists(clear_sprite)) then sprite_delete(clear_sprite);
// 仍被谱面留用的模糊图不能在这里删。
if (sprite_exists(blur_sprite) && blur_sprite != chart_blur_kept()) then sprite_delete(blur_sprite);
blur_sprite = -1;
if (sprite_exists(panel_sprite)) then sprite_delete(panel_sprite);
pls_ui_font_release_instance();
// 动画没正常结束就清掉全局占用标记。
if (variable_global_exists("loading_animation_active")
        && (!variable_global_exists("loading_animator_finished") || !global.loading_animator_finished)) {
    global.loading_animation_active = false;
};
if (variable_global_exists("load_animator_instance")
        && global.load_animator_instance == id) {
    global.load_animator_instance = noone;
};
