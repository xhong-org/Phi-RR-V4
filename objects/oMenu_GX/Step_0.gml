/// @description GX click-to-pick / API backup
var scale_now = (variable_global_exists("global_scales") ? global_scales : 1.0);
if (layout_w != room_width || layout_h != room_height || layout_scale != scale_now) {
        pls_gx_menu_layout();
};

gx_drop_boot();
if (busy) {
        gx_drop_set_enabled(false);
        gx_file_ui_set_drop(false);
} else {
        gx_drop_set_enabled(true);
};
drop_panel_open = gx_file_ui_drop_open();

if (!pls_is_gx_remote()) {
        health_timer++;
        if (health_timer > 180) {
                health_timer = 0;
                if (!api_online) then health_id = gx_fs_request_health();
        };
};
if (import_opened) then i_gx_drop_poll_import();

hover_pick = !drop_panel_open && point_in_rectangle(mouse_x, mouse_y, pick_x, pick_y, pick_x + pick_w, pick_y + pick_h);
hover_drop_btn = false;
hover_api = !drop_panel_open && (api_btn_w > 0) && point_in_rectangle(mouse_x, mouse_y, api_btn_x, api_btn_y, api_btn_x + api_btn_w, api_btn_y + api_btn_h);
hover_drop = hover_pick || gx_drop_hover();

var drop_status = gx_drop_status();
gx_drop_unpause();

if (!busy && import_opened) {
        var imported = gx_import_poll_file();
        if (string_length(imported)) {
                busy = true;
                pending_path = imported;
                var session_import = chart_session_ensure();
                session_import.source_path = imported;
                session_import.ready = false;
                session_import.error = "";
                session_import.status = "Queued";
                session_import.detail = imported;
                room_goto(room_loading);
                exit;
        };
};

if (!busy && mouse_check_button_pressed(mb_left)) {
        if (hover_api && !drop_panel_open) {
                if (api_online) {
                        gx_fs_picker_open();
                        status_text = "已打开本机文件浏览。";
                } else {
                        health_id = gx_fs_request_health();
                        last_error = "未连接到 http://127.0.0.1:17890";
                        status_text = "API 未连接。仍可单击选择文件。";
                };
        } else if (hover_pick) {
                gx_file_ui_set_drop(true);
                drop_panel_open = true;
                status_text = "在弹出层里选择文件。";
        };
};

if (drop_status == GX_DROP_STATUS.READING) {
        status_text = "正在读取文件...";
        last_error = "";
} else if (drop_status == GX_DROP_STATUS.ERROR) {
        last_error = gx_drop_error();
        if (!string_length(last_error)) then last_error = "读取失败。";
        status_text = "上传失败。";
} else if (drop_status == GX_DROP_STATUS.OK && !busy) {
        busy = true;
        status_text = "正在导入 " + gx_drop_filename();
        last_error = "";
        var dest = gx_drop_take_file();
        gx_drop_reset();
        gx_file_ui_set_drop(false);
        if (!string_length(dest)) {
                busy = false;
                last_error = "无法写入谱面包。";
                status_text = "上传失败。";
        } else if (!gx_file_picker_is_package(dest) && !gx_file_picker_looks_like_zip(dest)) {
                busy = false;
                last_error = "不是有效的 .zip / .pez 包。";
                status_text = "上传失败。";
        } else {
                pending_path = dest;
                var session = chart_session_ensure();
                session.source_path = dest;
                session.ready = false;
                session.error = "";
                session.status = "Queued";
                session.detail = dest;
                room_goto(room_loading);
        };
} else if (drop_status == GX_DROP_STATUS.IDLE && !busy && !string_length(last_error)) {
        if (drop_panel_open) {
                status_text = "在弹出层里选择文件。";
        } else if (pls_is_gx_remote()) {
                status_text = "单击选择文件。";
        } else {
                status_text = api_online ? "单击选择文件，或用 API 浏览本机。" : "单击选择文件。API 未连接。";
        };
};
