/// @description GX.games menu: click-to-pick, optional API backup
window_set_caption(GAME_NAME + " - Menu");
chart_session_ensure();
if (variable_global_exists("render_gui_returning") && global.render_gui_returning) {
        global.render_gui_returning = false;
        chart_session_cleanup(true);
        game_set_speed(60, gamespeed_fps);
};

gx_drop_boot();
gx_drop_set_enabled(false);
pending_path = "";
busy = false;
hover_pick = false;
hover_drop_btn = false;
hover_api = false;
hover_drop = false;
import_opened = false;
drop_panel_open = false;
drop_panel_just_opened = false;
api_online = false;
health_id = -1;
health_timer = 0;
query_http_id = -1;
query_http_dest = "";
last_error = "";
if (pls_is_gx_remote()) {
        status_text = "单击选择文件。";
        detail_text = "远程不使用本机 17890 API。";
        var remote_err = "";
        try { remote_err = gx_query_unquote(i_gx_query_get("pls-r:err")); } catch (err_read) { delete(err_read); remote_err = ""; };
        if (string_length(remote_err)) then last_error = remote_err;
} else {
        status_text = "正在连接本地 Node 文件系统 API...";
        detail_text = "API: node tools/gx-fs-api/server.js";
        health_id = gx_fs_request_health();
};

var query_chart = gx_query_chart();
if (string_length(query_chart)) {
        var query_lower = string_lower(query_chart);
        if (string_pos("file:", query_lower) == 1) {
                last_error = "http 页面读不了 file://。请点击打开导入页上传。";
                status_text = "地址参数无法直接读本地文件。";
        } else if (gx_file_picker_is_url(query_chart)) {
                var qname = gx_file_picker_url_filename(query_chart);
                query_http_dest = chart_path_join(gx_file_picker_download_dir(), qname);
                query_http_id = http_get_file(query_chart, query_http_dest);
                busy = true;
                status_text = "正在从 URL 下载谱面...";
        } else {
                var local_zip = chart_path_join(gx_file_picker_download_dir(), gx_file_picker_safe_name(query_chart));
                if (!file_exists(local_zip)) then local_zip = chart_path_join("/_savedata/charts/", gx_file_picker_safe_name(query_chart));
                if (file_exists(local_zip)) {
                        pending_path = local_zip;
                        var session_q = chart_session_ensure();
                        session_q.source_path = local_zip;
                        session_q.ready = false;
                        session_q.error = "";
                        session_q.status = "Queued";
                        session_q.detail = local_zip;
                        room_goto(room_loading);
                } else {
                        status_text = "未找到 " + query_chart + "，请在导入页重新上传。";
                };
        };
};

layout_w = -1;
layout_h = -1;
layout_scale = -1;
pick_x = 0; pick_y = 0; pick_w = 1; pick_h = 1;
drop_btn_x = 0; drop_btn_y = 0; drop_btn_w = 1; drop_btn_h = 1;
api_btn_x = 0; api_btn_y = 0; api_btn_w = 0; api_btn_h = 0;
drop_x = 0; drop_y = 0; drop_w = 1; drop_h = 1;

ui_font = pls_ui_font_add(28);
pls_gx_menu_layout();
