///@desc 房间结束：换房前释放本房占用的界面字体
if (instance_exists(oMenu_Windows)) {
        with (oMenu_Windows) pls_ui_font_release_instance();
};
if (instance_exists(oMenu_Android)) {
        with (oMenu_Android) pls_ui_font_release_instance();
};
if (instance_exists(oMenu_GX)) {
        with (oMenu_GX) pls_ui_font_release_instance();
};
if (instance_exists(oLoading)) {
        with (oLoading) pls_ui_font_release_instance();
};
if (instance_exists(oLoadingAsync)) {
        with (oLoadingAsync) pls_ui_font_release_instance();
};
if (instance_exists(oRenderSetup)) {
        with (oRenderSetup) pls_ui_font_release_instance();
};
if (instance_exists(oFilePicker)) {
        with (oFilePicker) pls_ui_font_release_instance();
};

// 已判定或被剔除的音符、以及停放的特效是未激活的，不唤醒就会留到下一个房间。
if (!(variable_global_exists("loading_animation_active") && global.loading_animation_active)) {
        instance_activate_all();
};
