///@desc 异步 HTTP：沙箱地址或 Node 文件系统接口的列表与下载
var req = async_load[? "id"];
var status = async_load[? "status"];

// 盘符列表还在传输就先等。
if (api_roots_id >= 0 && req == api_roots_id) {
        // status 大于 0 表示仍在进行。
        if (status > 0) then exit;
        api_roots_id = -1;
        if (status < 0) {
                last_error = "Local Node API roots failed. Start tools/gx-fs-api/server.js";
                status_text = last_error;
                exit;
        };
        var parsed_roots = gx_fs_parse_entries(string(async_load[? "result"] ?? ""));
        var drive_src = (is_array(parsed_roots.drives) && array_length(parsed_roots.drives) > 0)
                ? parsed_roots.drives : parsed_roots.items;
        roots = gx_fp_only_drives(drive_src);
        root_rects = [];
        gx_fp_layout();
        if (array_length(roots) <= 0) {
                last_error = "No ready drives from Node API. Restart tools/gx-fs-api/server.js";
                status_text = last_error;
                exit;
        };
        var start_dir = "";
        if (string_length(last_dir_cached)) then start_dir = last_dir_cached;
        else start_dir = roots[0].path;
        restore_pending = (start_dir == last_dir_cached && string_length(last_dir_cached) > 0);
        gx_fp_set_directory(start_dir, true);
        exit;
};

// 目录列表回调。
if (api_list_id >= 0 && req == api_list_id) {
        if (status > 0) then exit;
        api_list_id = -1;
        if (status < 0) {
                last_error = "Local Node API list failed.";
                status_text = last_error;
                gx_fp_apply_listing({ ok: false, items: [], parent: "", path: current_dir, error: last_error });
                exit;
        };
        gx_fp_apply_listing(gx_fs_parse_entries(string(async_load[? "result"] ?? "")));
        exit;
};

// 不是当前下载就忽略。
if (!downloading) then exit;
if (req != download_id) then exit;

// 下载进行中只更新已收字节。
if (status > 0) {
        if (ds_map_exists(async_load, "sizeDownloaded")) then download_got = async_load[? "sizeDownloaded"];
        if (ds_map_exists(async_load, "contentLength")) then download_total = async_load[? "contentLength"];
        exit;
};

downloading = false;
download_id = -1;
var fetch_json = api_fetch_json;
var job = string(api_job);
api_fetch_json = false;

if (status < 0) {
        api_job = "";
        last_error = "Download failed.";
        if (ds_map_exists(async_load, "http_status")) {
                last_error += " HTTP " + string(async_load[? "http_status"]);
        };
        status_text = last_error;
        exit;
};

// 解包结果转成待写入的文件列表。
if (job == "unpack") {
        var unpacked = gx_fs_parse_unpack(string(async_load[? "result"] ?? ""));
        if (!unpacked.ok || array_length(unpacked.files) <= 0) {
                api_job = "";
                last_error = string_length(unpacked.error) ? unpacked.error : "Node unpack returned no files.";
                if (ds_map_exists(async_load, "http_status")) {
                        last_error += " HTTP " + string(async_load[? "http_status"]);
                };
                status_text = last_error;
                exit;
        };
        api_unpack_files = unpacked.files;
        api_unpack_index = 0;
        gx_media_store_host_files(unpacked.files);
        gx_fs_mkdirs(download_path);
        gx_fp_blob_next();
        exit;
};

// 单个 blob 写到目标路径后继续下一个。
if (job == "blob") {
        if (api_unpack_index < 0 || api_unpack_index >= array_length(api_unpack_files)) {
                gx_fp_blob_fail("Blob copy index is invalid.");
                exit;
        };
        var item = api_unpack_files[api_unpack_index];
        var rel = gx_fs_safe_rel(item[$ "rel"] ?? "");
        var dest_file = gx_path_clean(chart_path_join(download_path, rel));
        var saved_blob = gx_fs_save_bytes_json(string(async_load[? "result"] ?? ""), dest_file);
        if (!saved_blob.ok) {
                gx_fp_blob_fail(saved_blob.error);
                exit;
        };
        api_unpack_index += 1;
        gx_fp_blob_next();
        exit;
};

// JSON 拉取结果落到本地再结束选择。
if (fetch_json || job == "fetch") {
        api_job = "";
        var raw = string(async_load[? "result"] ?? "");
        var saved = gx_fs_save_fetch_json(raw, download_path);
        if (!saved.ok) {
                last_error = saved.error;
                if (ds_map_exists(async_load, "http_status")) {
                        last_error += " HTTP " + string(async_load[? "http_status"]);
                };
                status_text = last_error;
                exit;
        };
        last_error = "";
        status_text = langf("picker.imported", chart_path_file_name(download_path), saved.kind);
        gx_fp_finish_ok(is_string(saved.dest) && string_length(saved.dest) ? saved.dest : download_path);
        exit;
};

var http_status = ds_map_exists(async_load, "http_status") ? async_load[? "http_status"] : 200;
// 非 2xx 视为下载失败。
if (is_real(http_status) && http_status != 0 && (http_status < 200 || http_status >= 300)) {
        last_error = "Download failed. HTTP " + string(http_status);
        status_text = last_error;
        exit;
};

var dest = download_path;
if (ds_map_exists(async_load, "result") && is_string(async_load[? "result"]) && string_length(async_load[? "result"])) {
        dest = async_load[? "result"];
};
if (!file_exists(dest)) {
        last_error = "Download finished but the file is missing.";
        status_text = last_error;
        exit;
};
// 普通下载必须是 zip 或 pez。
if (!gx_file_picker_looks_like_zip(dest)) {
        last_error = "Downloaded file is not a zip/pez package.";
        status_text = last_error;
        exit;
};

last_error = "";
status_text = langf("picker.downloaded", chart_path_file_name(dest));
gx_fp_finish_ok(dest);
