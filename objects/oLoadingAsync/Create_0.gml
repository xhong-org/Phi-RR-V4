/// @description Loading pipeline controller with asynchronous archive extraction.
window_set_caption(GAME_NAME + " - Loading");
chart_session_ensure();

phase = 0;
phase_timer = 0;
done = false;
failed = false;
message = "Preparing...";
detail = "";
ui_font = pls_ui_font_add(28);

var session = chart_session_ensure();
source_path = session.source_path;
if (!string_length(source_path)) {
        failed = true;
        message = "No chart source queued.";
        detail = "Back to menu";
        phase = 99;
};
