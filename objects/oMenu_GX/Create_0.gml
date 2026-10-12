///@desc 初始化 GX 菜单、远程状态和可选的本地 API
window_set_caption(GAME_NAME + " - " + lang("common.menu"));
chart_session_ensure();
if (variable_global_exists("render_gui_returning") && global.render_gui_returning) {
        global.render_gui_returning = false;
        chart_session_cleanup(true);
};
display_ui_apply();

gx_drop_boot();
gx_drop_set_enabled(false);
pending_path = "";
busy = false;
hover_pick = false;
hover_drop_btn = false;
hover_api = false;
hover_drop = false;
hover_settings = false;
import_opened = false;
drop_panel_open = false;
drop_panel_just_opened = false;
api_online = false;
health_id = -1;
health_timer = 0;
query_http_id = -1;
query_http_dest = "";
last_error = "";
// 远程页面只提示点击选文件；本地则探测 API 健康。
if (pls_is_gx_remote()) {
        status_text = lang("gx.statusClick");
        detail_text = lang("gx.detailRemote");
        var remote_err = "";
        try { remote_err = gx_query_unquote(i_gx_query_get("pls-r:err")); } catch (err_read) { delete(err_read); remote_err = ""; };
        if (string_length(remote_err)) then last_error = remote_err;
} else {
        status_text = lang("gx.statusConnecting");
        detail_text = lang("gx.detailApi");
        health_id = gx_fs_request_health();
};

// 地址栏带谱面参数时，按协议下载或直接进加载。
var query_chart = gx_query_chart();
if (string_length(query_chart)) {
        var query_lower = string_lower(query_chart);
        // file: 协议在网页里不可读。
        if (string_pos("file:", query_lower) == 1) {
                last_error = lang("gx.fileProtocol");
                status_text = lang("gx.fileProtocolStatus");
        } else if (gx_file_picker_is_url(query_chart)) {
                var qname = gx_file_picker_url_filename(query_chart);
                query_http_dest = chart_path_join(gx_file_picker_download_dir(), qname);
                query_http_id = http_get_file(query_chart, query_http_dest);
                busy = true;
                status_text = lang("gx.downloadingUrl");
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
                        status_text = langf("gx.notFound", query_chart);
                };
        };
};

layout_w = -1;
layout_h = -1;
layout_scale = -1;
btn_settings = { "label" : lang("common.settings"), "x" : 0, "y" : 0, "w" : 1, "h" : 1 };
pick_x = 0; pick_y = 0; pick_w = 1; pick_h = 1;
drop_btn_x = 0; drop_btn_y = 0; drop_btn_w = 1; drop_btn_h = 1;
api_btn_x = 0; api_btn_y = 0; api_btn_w = 0; api_btn_h = 0;
drop_x = 0; drop_y = 0; drop_w = 1; drop_h = 1;

ui_font = pls_ui_font_add(28);
pls_gx_menu_layout();
