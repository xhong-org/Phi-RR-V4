/// @description Local Node API health + optional chart URL download
var req = async_load[? "id"];
var status = async_load[? "status"];

if (health_id >= 0 && req == health_id) {
        if (status > 0) then exit;
        health_id = -1;
        if (status < 0) {
                api_online = false;
                detail_text = "请先运行 node tools/gx-fs-api/server.js";
                exit;
        };
        var body = string(async_load[? "result"] ?? "");
        api_online = (string_pos("\"ok\":true", body) > 0) || (string_pos("\"ok\": true", body) > 0);
        detail_text = api_online ? ("已连接 " + gx_fs_api_base()) : "本地 API 无响应";
        if (api_online && !busy) then status_text = "单击选择文件，或用 API 浏览本机。";
        exit;
};

if (query_http_id < 0) then exit;
if (req != query_http_id) then exit;

var status = async_load[? "status"];
if (status > 0) then exit;

query_http_id = -1;
if (status < 0) {
        busy = false;
        last_error = "URL 下载失败。";
        status_text = "上传失败。";
        exit;
};

var dest = query_http_dest;
if (ds_map_exists(async_load, "result") && is_string(async_load[? "result"]) && string_length(async_load[? "result"])) {
        dest = async_load[? "result"];
};
if (!file_exists(dest)) {
        busy = false;
        last_error = "下载完成但文件不存在。";
        status_text = "上传失败。";
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
