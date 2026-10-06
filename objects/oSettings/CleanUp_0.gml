/// @description Release settings UI font
if (is_string(editing_key) && string_length(editing_key)) {
	try { settings_gui_commit_edit(); } catch (commit_err) { delete(commit_err); };
};
if (os_type == os_android) {
	try { keyboard_virtual_hide(); } catch (hide_err) { delete(hide_err); };
};
try { skin_import_cancel(); } catch (cancel_err) { delete(cancel_err); };
try { skin_preview_unload(); } catch (unload_err) { delete(unload_err); };
try { settings_skin_preview_surface_free(); } catch (surf_err) { delete(surf_err); };
try { pls_ui_font_release_instance(); } catch (font_err) { delete(font_err); };
