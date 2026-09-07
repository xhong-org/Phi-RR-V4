/// @description Menu interactions
// Rebuild when Camera_View changes room size / global_scales.
var scale_now = (variable_global_exists("global_scales") ? global_scales : 1.0);
if (layout_w != room_width || layout_h != room_height || layout_scale != scale_now) {
        event_user(0);
};

if (settings_gui_blocking()) {
        hover_open = false;
        hover_sample = false;
        hover_render = false;
        hover_settings = false;
        exit;
};

var mx = mouse_x;
var my = mouse_y;

hover_open = (mx >= btn_open.x && mx <= btn_open.x + btn_open.w && my >= btn_open.y && my <= btn_open.y + btn_open.h);
hover_sample = (mx >= btn_sample.x && mx <= btn_sample.x + btn_sample.w && my >= btn_sample.y && my <= btn_sample.y + btn_sample.h);
hover_render = (mx >= btn_render.x && mx <= btn_render.x + btn_render.w && my >= btn_render.y && my <= btn_render.y + btn_render.h);
hover_settings = settings_menu_button_hit(mx, my);

if (mouse_check_button_pressed(mb_left)) {
        if (hover_settings) {
                settings_gui_open();
        } else if (hover_open) {
                var path = get_open_filename(lang("menu.filterChart"), "");
                if (!string_length(path)) {
                        last_error = lang("menu.noFile");
                        status_text = lang("menu.cancelled");
                        detail_text = last_error;
                } else {
                        pending_path = path;
                        var session = chart_session_ensure();
                        session.source_path = path;
                        session.ready = false;
                        session.error = "";
                        session.status = "Queued";
                        session.detail = path;
                        room_goto(room_loading);
                };
        } else if (hover_sample) {
                var session_sample = chart_session_ensure();
                session_sample.source_path = "__sample__";
                session_sample.ready = false;
                session_sample.error = "";
                session_sample.status = "Queued";
                session_sample.detail = "sample";
                room_goto(room_loading);
        } else if (hover_render) {
                //room_goto(room_render_setup);
        };
};

if (keyboard_check_pressed(ord("O"))) {
        var path2 = get_open_filename(lang("menu.filterChart"), "");
        if (string_length(path2)) {
                var session_o = chart_session_ensure();
                session_o.source_path = path2;
                session_o.ready = false;
                session_o.error = "";
                session_o.status = "Queued";
                session_o.detail = path2;
                room_goto(room_loading);
        };
};
if (keyboard_check_pressed(ord("S"))) {
        var session_s = chart_session_ensure();
        session_s.source_path = "__sample__";
        session_s.ready = false;
        session_s.error = "";
        session_s.status = "Queued";
        session_s.detail = "sample";
        room_goto(room_loading);
};
if (keyboard_check_pressed(ord("X"))) room_goto(room_render_setup);
