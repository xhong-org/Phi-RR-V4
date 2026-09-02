/// @description Release UI font and file input
gx_file_ui_set_drop(false);
gx_drop_set_enabled(false);
if (variable_instance_exists(id, "ui_font") && font_exists(ui_font)) {
        font_delete(ui_font);
        ui_font = -1;
};
