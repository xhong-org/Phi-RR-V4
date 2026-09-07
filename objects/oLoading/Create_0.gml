/// @description Loading pipeline controller
window_set_caption(GAME_NAME + " - " + lang("common.loading"));
chart_session_ensure();

phase = 0;
phase_timer = 0;
done = false;
failed = false;
message = lang("loading.preparing");
detail = "";
ui_font = pls_ui_font_add(28);

var session = chart_session_ensure();
source_path = session.source_path;
if (!string_length(source_path)) {
        failed = true;
        message = lang("loading.noSource");
        detail = lang("loading.backToMenu");
        phase = 99;
};
