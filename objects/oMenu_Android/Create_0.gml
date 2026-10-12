///@desc 初始化 Android 菜单的会话、按钮和字体
chart_session_ensure();
// 从渲染界面返回时清掉上一局谱面会话。
if (variable_global_exists("render_gui_returning") && global.render_gui_returning) {
        global.render_gui_returning = false;
        chart_session_cleanup(true);
};
display_ui_apply();

pending_path = "";
status_text = lang("menu.statusSelect");
detail_text = lang("menu.detailSupported");
last_error = "";
picking = false;

hover_open = false;
hover_sample = false;
hover_settings = false;

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
btn_settings = {
        "label" : lang("common.settings"),
        "x" : 0, "y" : 0, "w" : 1, "h" : 1
};

ui_font = pls_ui_font_add(28);

if (extension_exists("I_AndroidOpen")) then i_android_open_reset();
event_user(0);
