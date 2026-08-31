/// @description Release room-owned resources before changing rooms.
if (instance_exists(oMenu_Windows)) {
        with (oMenu_Windows) {
                if (variable_instance_exists(id, "ui_font") && font_exists(ui_font)) {
                        font_delete(ui_font);
                        ui_font = -1;
                };
        };
};
if (instance_exists(oMenu_Android)) {
        with (oMenu_Android) {
                if (variable_instance_exists(id, "ui_font") && font_exists(ui_font)) {
                        font_delete(ui_font);
                        ui_font = -1;
                };
        };
};
if (instance_exists(oLoading)) {
        with (oLoading) {
                if (variable_instance_exists(id, "ui_font") && font_exists(ui_font)) {
                        font_delete(ui_font);
                        ui_font = -1;
                };
        };
};

// Judged / culled notes and parked FX are inactive and otherwise survive room change.
if (!(variable_global_exists("loading_animation_active") && global.loading_animation_active)) {
        instance_activate_all();
};
