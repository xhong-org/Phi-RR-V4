/// @description Release room-owned resources before changing rooms.
if (instance_exists(oMenu)) {
        with (oMenu) {
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

// Judged PEC notes are inactive and otherwise escape normal room teardown.
instance_activate_object(oNote_2);
