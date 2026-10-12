///@desc 异步 HTTP：接收本地 Node 文件系统返回的 GX PCM JSON
if (!media_use_gx()) then exit;
if (!variable_instance_exists(id, "gx_pcm_id") || !is_real(gx_pcm_id) || gx_pcm_id < 0) then exit;

var req = async_load[? "id"];
// 不是这次 PCM 请求就忽略。
if (req != gx_pcm_id) then exit;

var status = async_load[? "status"];
// 还在传输。
if (status > 0) then exit;

gx_pcm_id = -1;
var audio_path = chart_file_readable_path(self[$ "name"] ?? "");
// HTTP 失败就改走 js 或流。
if (status < 0) {
	print("[L-Sound] GX PCM HTTP failed.");
	if (!gx_media_try_js_or_stream(id, audio_path)) then self[$ "success"] = false;
	exit;
};

var http_status = ds_map_exists(async_load, "http_status") ? async_load[? "http_status"] : 200;
// 非 2xx 同样改走备用加载。
if (is_real(http_status) && http_status != 0 && (http_status < 200 || http_status >= 300)) {
	print("[L-Sound] GX PCM HTTP " + string(http_status));
	if (!gx_media_try_js_or_stream(id, audio_path)) then self[$ "success"] = false;
	exit;
};

if (!gx_media_apply_pcm_json(id, string(async_load[? "result"] ?? ""))) {
	if (!gx_media_try_js_or_stream(id, audio_path)) then self[$ "success"] = false;
};
