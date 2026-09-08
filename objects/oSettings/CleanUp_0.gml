/// @description Release settings UI font
if (is_string(editing_key) && string_length(editing_key)) {
	try { settings_gui_commit_edit(); } catch (commit_err) { delete(commit_err); };
};
if (os_type == os_android) {
	try { keyboard_virtual_hide(); } catch (hide_err) { delete(hide_err); };
};
skin_import_cancel();
skin_preview_unload();
settings_skin_preview_surface_free();
pls_ui_font_release_instance();
