/// @description Menu UI bootstrap
// Depends on Camera_View defining global_scales first.
window_set_caption(GAME_NAME + " - Menu");
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

hover_open = false;
hover_sample = false;
hover_render = false;

// Layout cache. Rebuild when room size or global_scales changes.
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
btn_render = {
        "label" : "X X XXX",
        "x" : 0, "y" : 0, "w" : 1, "h" : 1
};

ui_font = -1;
if (file_exists(working_directory + "resource/saira.ttf")) {
        font_add_enable_aa(true);
        ui_font = font_add(working_directory + "resource/saira.ttf", 28, true, false, -infinity, infinity);
        if (font_exists(ui_font)) then font_enable_sdf(ui_font, true);
};

event_user(0);
