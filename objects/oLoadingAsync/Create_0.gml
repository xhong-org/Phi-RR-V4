/// @description Loading pipeline controller with asynchronous archive extraction.
window_set_caption(GAME_NAME + " - Loading");
chart_session_ensure();

phase = 0;
phase_timer = 0;
done = false;
failed = false;
message = "Preparing...";
detail = "";
ui_font = -1;
if (file_exists(working_directory + "resource/saira.ttf")) {
        font_add_enable_aa(true);
        ui_font = font_add(working_directory + "resource/saira.ttf", 28, true, false, -infinity, infinity);
        if (font_exists(ui_font)) then font_enable_sdf(ui_font, true);
};

var session = chart_session_ensure();
source_path = session.source_path;
if (!string_length(source_path)) {
        failed = true;
        message = "No chart source queued.";
        detail = "Back to menu";
        phase = 99;
};
