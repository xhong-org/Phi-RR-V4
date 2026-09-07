/// @description Menu UI bootstrap
// Depends on Camera_View defining global_scales first.
window_set_caption(GAME_NAME + " - " + lang("common.menu"));
chart_session_ensure();
if (variable_global_exists("render_gui_returning") && global.render_gui_returning) {
        global.render_gui_returning = false;
        chart_session_cleanup(true);
        game_set_speed(60, gamespeed_fps);
};

pending_path = "";
status_text = lang("menu.statusSelect");
detail_text = lang("menu.detailSupported");
last_error = "";

hover_open = false;
hover_sample = false;
hover_render = false;
hover_settings = false;

// Layout cache. Rebuild when room size or global_scales changes.
layout_w = -1;
layout_h = -1;
layout_scale = -1;

btn_open = {
        "label" : lang("menu.openPackage"),
        "x" : 0, "y" : 0, "w" : 1, "h" : 1
};
btn_sample = {
        "label" : lang("menu.loadSample"),
        "x" : 0, "y" : 0, "w" : 1, "h" : 1
};
btn_render = {
        "label" : lang("menu.renderPlaceholder"),
        "x" : 0, "y" : 0, "w" : 1, "h" : 1
};
btn_settings = {
        "label" : lang("common.settings"),
        "x" : 0, "y" : 0, "w" : 1, "h" : 1
};

ui_font = pls_ui_font_add(28);

event_user(0);
