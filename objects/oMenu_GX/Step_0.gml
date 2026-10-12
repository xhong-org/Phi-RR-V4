///@desc 处理 GX 点击选文件、API 浏览和拖放导入
var scale_now = (variable_global_exists("global_scales") ? global_scales : 1.0);
if (layout_w != room_width || layout_h != room_height || layout_scale != scale_now) {
        pls_gx_menu_layout();
};

// 忙碌或设置打开时关掉拖放，避免误导入。
if (busy || settings_gui_blocking()) {
        gx_drop_set_enabled(false);
        gx_file_ui_set_drop(false);
} else {
        gx_drop_set_enabled(true);
};
drop_panel_open = gx_file_ui_drop_open();

// 本地模式定期重试 API 健康检查。
if (!pls_is_gx_remote()) {
        health_timer++;
        if (health_timer > 180) {
                health_timer = 0;
                if (!api_online) then health_id = gx_fs_request_health();
        };
};
if (import_opened) then i_gx_drop_poll_import();

// 设置界面挡住时清掉悬停并退出。
if (settings_gui_blocking()) {
        hover_pick = false;
        hover_drop_btn = false;
        hover_api = false;
        hover_drop = false;
        hover_settings = false;
        exit;
};

hover_pick = !drop_panel_open && point_in_rectangle(mouse_x, mouse_y, pick_x, pick_y, pick_x + pick_w, pick_y + pick_h);
hover_drop_btn = false;
hover_api = !drop_panel_open && (api_btn_w > 0) && point_in_rectangle(mouse_x, mouse_y, api_btn_x, api_btn_y, api_btn_x + api_btn_w, api_btn_y + api_btn_h);
hover_drop = hover_pick || gx_drop_hover();
hover_settings = !drop_panel_open && settings_menu_button_hit(mouse_x, mouse_y);

var drop_status = gx_drop_status();
gx_drop_unpause();

// 拖放面板导入成功就立刻进加载房间。
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

// 左键：设置、API 浏览，或打开点击选文件面板。
if (!busy && mouse_check_button_pressed(mb_left)) {
        if (hover_settings) {
                settings_gui_open();
        } else if (hover_api && !drop_panel_open) {
                if (api_online) {
                        gx_fs_picker_open();
                        status_text = lang("gx.openedBrowse");
                } else {
                        health_id = gx_fs_request_health();
                        last_error = lang("gx.notConnected");
                        status_text = lang("gx.statusApiOffStillClick");
                };
        } else if (hover_pick) {
                gx_file_ui_set_drop(true);
                drop_panel_open = true;
                status_text = lang("gx.statusPopup");
        };
};

// 按拖放状态更新提示，读完且是谱面包才进加载。
if (drop_status == GX_DROP_STATUS.READING) {
        status_text = lang("gx.statusReading");
        last_error = "";
} else if (drop_status == GX_DROP_STATUS.ERROR) {
        last_error = gx_drop_error();
        if (!string_length(last_error)) then last_error = lang("gx.readFailed");
        status_text = lang("gx.uploadFailed");
} else if (drop_status == GX_DROP_STATUS.OK && !busy) {
        busy = true;
        status_text = langf("gx.importing", gx_drop_filename());
        last_error = "";
        var dest = gx_drop_take_file();
        gx_drop_reset();
        gx_file_ui_set_drop(false);
        if (!string_length(dest)) {
                busy = false;
                last_error = lang("gx.writeFailed");
                status_text = lang("gx.uploadFailed");
        } else if (!gx_file_picker_is_package(dest) && !gx_file_picker_looks_like_zip(dest)) {
                busy = false;
                last_error = lang("gx.notZip");
                status_text = lang("gx.uploadFailed");
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
                status_text = lang("gx.statusPopup");
        } else if (pls_is_gx_remote()) {
                status_text = lang("gx.statusClick");
        } else {
                status_text = api_online ? lang("gx.statusClickOrApi") : lang("gx.statusClickApiOff");
        };
};
