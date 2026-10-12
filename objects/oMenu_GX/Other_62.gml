///@desc 处理本地 API 健康检查和谱面 URL 下载完成
var req = async_load[? "id"];
var status = async_load[? "status"];

// 还在下载中的正状态码先忽略。
if (health_id >= 0 && req == health_id) {
        if (status > 0) then exit;
        health_id = -1;
        // 健康检查失败就提示先启动本地服务。
        if (status < 0) {
                api_online = false;
                detail_text = lang("gx.runServer");
                exit;
        };
        var body = string(async_load[? "result"] ?? "");
        api_online = (string_pos("\"ok\":true", body) > 0) || (string_pos("\"ok\": true", body) > 0);
        detail_text = api_online ? langf("gx.connected", gx_fs_api_base()) : lang("gx.apiNoResponse");
        if (api_online && !busy) then status_text = lang("gx.statusClickOrApi");
        exit;
};

if (query_http_id < 0) then exit;
// 不是这次 URL 下载的回调就丢掉。
if (req != query_http_id) then exit;

var status = async_load[? "status"];
if (status > 0) then exit;

query_http_id = -1;
// URL 下载失败则停在菜单并显示错误。
if (status < 0) {
        busy = false;
        last_error = lang("gx.urlFailed");
        status_text = lang("gx.uploadFailed");
        exit;
};

var dest = query_http_dest;
if (ds_map_exists(async_load, "result") && is_string(async_load[? "result"]) && string_length(async_load[? "result"])) {
        dest = async_load[? "result"];
};
if (!file_exists(dest)) {
        busy = false;
        last_error = lang("gx.downloadMissing");
        status_text = lang("gx.uploadFailed");
        exit;
};

pending_path = dest;
var session = chart_session_ensure();
session.source_path = dest;
session.ready = false;
session.error = "";
session.status = "Queued";
session.detail = dest;
room_goto(room_loading);
