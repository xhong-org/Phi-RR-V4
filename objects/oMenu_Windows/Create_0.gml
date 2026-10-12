///@desc 初始化 Windows 菜单按钮、工具面板和字体
// 布局依赖 Camera_View 先定义好 global_scales。
window_set_caption(GAME_NAME + " - " + lang("common.menu"));
chart_session_ensure();
if (variable_global_exists("render_gui_returning") && global.render_gui_returning) {
        global.render_gui_returning = false;
        chart_session_cleanup(true);
};
display_ui_apply();

pending_path = "";
status_text = lang("menu.statusSelect");
detail_text = lang("menu.detailSupported");
last_error = "";

hover_open = false;
hover_sample = false;
hover_render = false;
hover_settings = false;
tools_open = false;
tools_status = "";
hover_tools_export = false;
hover_tools_pec = false;
hover_tools_close = false;
tools_hover = -1;
tools_export_box = { x: 0, y: 0, w: 1, h: 1 };
tools_pec_box = { x: 0, y: 0, w: 1, h: 1 };
tools_close_box = { x: 0, y: 0, w: 1, h: 1 };

// 布局缓存，房间尺寸或 global_scales 变化时重建。
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
