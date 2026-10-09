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

if (tools_open) {
        hover_open = false;
        hover_sample = false;
        hover_render = false;
        hover_settings = false;
        var ts = (variable_global_exists("global_scales") ? global_scales : 1.0);
        if (!is_real(ts) || ts <= 0) then ts = 1.0;
        var panel_w = min(room_width - 40, 520 * ts);
        var panel_h = min(room_height - 40, 400 * ts);
        var panel_x = (room_width - panel_w) * 0.5;
        var panel_y = (room_height - panel_h) * 0.5;
        var row_h = 48 * ts;
        var row_w = panel_w - 48 * ts;
        tools_export_box = { x: panel_x + 24 * ts, y: panel_y + 78 * ts, w: row_w, h: row_h };
        tools_pec_box = { x: panel_x + 24 * ts, y: panel_y + 78 * ts + row_h + 14 * ts, w: row_w, h: row_h };
        tools_close_box = { x: panel_x + 24 * ts, y: panel_y + panel_h - 24 * ts - row_h, w: row_w, h: row_h };
        var tmx = mouse_x;
        var tmy = mouse_y;
        hover_tools_export = point_in_rectangle(tmx, tmy, tools_export_box.x, tools_export_box.y, tools_export_box.x + tools_export_box.w, tools_export_box.y + tools_export_box.h);
        hover_tools_pec = point_in_rectangle(tmx, tmy, tools_pec_box.x, tools_pec_box.y, tools_pec_box.x + tools_pec_box.w, tools_pec_box.y + tools_pec_box.h);
        hover_tools_close = point_in_rectangle(tmx, tmy, tools_close_box.x, tools_close_box.y, tools_close_box.x + tools_close_box.w, tools_close_box.y + tools_close_box.h);
        if (mouse_check_button_pressed(mb_left)) {
                if (hover_tools_close) {
                        tools_open = false;
                } else if (hover_tools_export || hover_tools_pec) {
                        var want_pec = hover_tools_pec;
                        var source_format = CHART_FORMAT.OFFICIAL;
                        if (want_pec) then source_format = CHART_FORMAT.PEC;
                        phi_tools_log("open dialog pec=" + string(want_pec) + " format=" + string(source_format));
                        var tool_path = get_open_filename(lang("menu.toolsPick"), "");
                        phi_tools_log("open path=" + string(tool_path));
                        if (string_length(tool_path)) {
                                var prepared = phi_tools_prepare_rpe_package(tool_path, source_format);
                                phi_tools_log("prepare struct=" + string(is_struct(prepared)) + " ok=" + string(is_struct(prepared) ? prepared.ok : false));
                                tools_status = phi_tools_finish_save(prepared, tool_path, want_pec);
                        };
                } else if (tmx < panel_x || tmx > panel_x + panel_w || tmy < panel_y || tmy > panel_y + panel_h) {
                        tools_open = false;
                };
        };
        if (keyboard_check_pressed(vk_escape)) then tools_open = false;
        if (keyboard_check_pressed(ord("X"))) room_goto(room_render_setup);
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
                tools_open = true;
                tools_status = "";
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
