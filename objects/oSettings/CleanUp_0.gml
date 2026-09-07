/// @description Release settings UI font
if (is_string(editing_key) && string_length(editing_key)) {
	try { settings_gui_commit_edit(); } catch (commit_err) { delete(commit_err); };
};
if (os_type == os_android) {
	try { keyboard_virtual_hide(); } catch (hide_err) { delete(hide_err); };
};
if (variable_instance_exists(id, "ui_font") && font_exists(ui_font)) {
	font_delete(ui_font);
	ui_font = -1;
};
