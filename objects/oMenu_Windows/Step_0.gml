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
        var tools_panel = phi_tools_panel_metrics(room_width, room_height, ts);
        var panel_x = tools_panel.panel_x;
        var panel_y = tools_panel.panel_y;
        var panel_w = tools_panel.panel_w;
        var panel_h = tools_panel.panel_h;
        tools_export_box = tools_panel.buttons[0];
        tools_pec_box = tools_panel.buttons[1];
        tools_close_box = tools_panel.close;
        var tmx = mouse_x;
        var tmy = mouse_y;
        tools_hover = -1;
        for (var tool_i = 0; tool_i < array_length(tools_panel.buttons); tool_i++) {
                var tool_box = tools_panel.buttons[tool_i];
                if (point_in_rectangle(tmx, tmy, tool_box.x, tool_box.y, tool_box.x + tool_box.w, tool_box.y + tool_box.h)) then tools_hover = tool_i;
        };
        hover_tools_export = (tools_hover == 0);
        hover_tools_pec = (tools_hover == 1);
        hover_tools_close = point_in_rectangle(tmx, tmy, tools_close_box.x, tools_close_box.y, tools_close_box.x + tools_close_box.w, tools_close_box.y + tools_close_box.h);
        if (mouse_check_button_pressed(mb_left)) {
                if (hover_tools_close) {
                        tools_open = false;
                } else if (tools_hover >= 0) {
                        var tool_jobs = phi_tools_jobs();
                        if (tools_hover >= array_length(tool_jobs)) then tools_hover = -1;
                };
                if (tools_hover >= 0 && mouse_check_button_pressed(mb_left) && !hover_tools_close) {
                        var tool_job = phi_tools_jobs()[tools_hover];
                        phi_tools_log("open dialog job=" + string(tools_hover) + " label=" + string(tool_job.label) + " source=" + string(tool_job.source) + " target=" + string(tool_job.target));
                        var tool_path = get_open_filename(lang("menu.toolsPick"), "");
                        phi_tools_log("open path=" + string(tool_path));
                        if (string_length(tool_path)) {
                                var prepared = phi_tools_prepare_rpe_package(tool_path, tool_job.source, tool_job.target);
                                phi_tools_log("prepare struct=" + string(is_struct(prepared)) + " ok=" + string(is_struct(prepared) ? prepared.ok : false));
                                tools_status = phi_tools_finish_save(prepared, tool_path, tool_job.fail);
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
