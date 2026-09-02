/// @description Android menu UI bootstrap
chart_session_ensure();
if (variable_global_exists("render_gui_returning") && global.render_gui_returning) {
        global.render_gui_returning = false;
        chart_session_cleanup(true);
        game_set_speed(60, gamespeed_fps);
};

pending_path = "";
status_text = "Select a custom chart package or load the bundled sample.";
detail_text = "Supported: Official / RPE / PEC  |  package: .zip / .pez";
last_error = "";
picking = false;

hover_open = false;
hover_sample = false;

layout_w = -1;
layout_h = -1;
layout_scale = -1;

btn_open = {
        "label" : "Open Chart Package",
        "x" : 0, "y" : 0, "w" : 1, "h" : 1
};
btn_sample = {
        "label" : "Load Sample Chart",
        "x" : 0, "y" : 0, "w" : 1, "h" : 1
};

ui_font = pls_ui_font_add(28);

if (extension_exists("I_AndroidOpen")) then i_android_open_reset();
event_user(0);
