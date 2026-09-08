/// @description Release room-owned resources before changing rooms.
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

// Judged / culled notes and parked FX are inactive and otherwise survive room change.
if (!(variable_global_exists("loading_animation_active") && global.loading_animation_active)) {
        instance_activate_all();
};
