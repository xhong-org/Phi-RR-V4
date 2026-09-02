/// @description Release picker font
if (variable_instance_exists(id, "ui_font") && font_exists(ui_font)) {
        font_delete(ui_font);
        ui_font = -1;
};
