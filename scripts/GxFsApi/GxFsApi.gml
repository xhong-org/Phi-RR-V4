/// @desc GX runner client for the local Node filesystem API.

#macro GX_FS_API_DEFAULT "http://127.0.0.1:17890"

function gx_fs_api_base() {
        if (variable_global_exists("gx_fs_api_base") && is_string(global.gx_fs_api_base) && string_length(global.gx_fs_api_base)) {
                return global.gx_fs_api_base;
        };
        return GX_FS_API_DEFAULT;
}

function gx_fs_hex(text) {
        var src = string(text);
        var buf = buffer_create(max(16, string_byte_length(src) + 4), buffer_grow, 1);
        buffer_write(buf, buffer_text, src);
        var used = buffer_tell(buf);
        buffer_seek(buf, buffer_seek_start, 0);
        var hex = "";
        var digits = "0123456789ABCDEF";
        for (var i = 0; i < used; i++) {
                var b = buffer_read(buf, buffer_u8);
                hex += string_char_at(digits, (b >> 4) + 1) + string_char_at(digits, (b & 15) + 1);
        };
        buffer_delete(buf);
        return hex;
}

function gx_fs_url(route, os_path = "") {
        var url = gx_fs_api_base() + route;
        if (string_length(os_path)) {
                url += ((string_pos("?", url) > 0) ? "&" : "?") + "hex=" + gx_fs_hex(os_path);
        };
        return url;
}

function gx_fs_parse_entry_list(raw) {
        var items = [];
        if (!is_array(raw)) then return items;
        for (var i = 0; i < array_length(raw); i++) {
                var e = raw[i];
                if (!is_struct(e)) then continue;
                array_add(items, {
                        name: string(e[$ "name"] ?? ""),
                        path: string(e[$ "path"] ?? ""),
                        is_dir: bool(e[$ "is_dir"] ?? false)
                });
        };
        return items;
}

function gx_fs_parse_entries(result_text) {
        var items = [];
        var drives = [];
        var parent = "";
        var listed = "";
        try {
                var data = json_parse(result_text);
                if (!is_struct(data)) then return { ok: false, items: items, drives: drives, parent: parent, path: listed, error: "invalid json" };
                listed = string(data[$ "path"] ?? "");
                parent = string(data[$ "parent"] ?? "");
                items = gx_fs_parse_entry_list(data[$ "entries"]);
                drives = gx_fs_parse_entry_list(data[$ "drives"]);
                if (array_length(drives) <= 0 && !string_length(listed)) then drives = items;
                var ok = bool(data[$ "ok"] ?? true);
                var err = string(data[$ "error"] ?? "");
                return { ok: ok, items: items, drives: drives, parent: parent, path: listed, error: err };
        } catch (parse_error) {
                delete(parse_error);
                return { ok: false, items: items, drives: drives, parent: parent, path: listed, error: "json parse failed" };
        };
}

function gx_fs_request_health() {
        return http_get(gx_fs_url("/health"));
}

function gx_fs_request_roots() {
        return http_get(gx_fs_url("/roots"));
}

function gx_fs_request_list(os_path) {
        return http_get(gx_fs_url("/list", os_path));
}

function gx_fs_request_search(os_path, query) {
        return http_get(gx_fs_url("/search", os_path) + "&qhex=" + gx_fs_hex(query));
}

function gx_fs_file_url(os_path) {
        return gx_fs_url("/file", os_path);
}

function gx_fs_request_fetch(os_path) {
        return http_get(gx_fs_url("/fetch", os_path));
}

function gx_fs_request_unpack(os_path) {
        return http_get(gx_fs_url("/unpack", os_path));
}

function gx_fs_request_blob(os_path) {
        return http_get(gx_fs_url("/blob", os_path));
}

function gx_fs_media_url(os_path) {
        return gx_fs_url("/media", os_path);
}

function gx_fs_request_pcm(os_path) {
        return http_get(gx_fs_url("/pcm", os_path));
}

function gx_media_store_host_files(files) {
        global.gx_media_host_files = {};
        if (!is_array(files)) then return;
        for (var i = 0; i < array_length(files); i++) {
                var item = files[i];
                if (!is_struct(item)) then continue;
                var rel = gx_fs_safe_rel(item[$ "rel"] ?? "");
                var src = string(item[$ "path"] ?? "");
                if (!string_length(rel) || !string_length(src)) then continue;
                global.gx_media_host_files[$ rel] = src;
                global.gx_media_host_files[$ string_lower(rel)] = src;
                var base = chart_path_file_name(rel);
                if (string_length(base)) {
                        global.gx_media_host_files[$ base] = src;
                        global.gx_media_host_files[$ string_lower(base)] = src;
                };
        };
}

function gx_media_persist_host_files(dir) {
        if (!pls_is_gxgames()) then return;
        if (!variable_global_exists("gx_media_host_files") || !is_struct(global.gx_media_host_files)) then return;
        var dest = gx_path_clean(chart_path_join(dir, ".gx_host.json"));
        try {
                var raw = json_stringify(global.gx_media_host_files);
                var buf = buffer_create(string_byte_length(raw) + 1, buffer_grow, 1);
                buffer_write(buf, buffer_text, raw);
                gx_fs_mkdirs(chart_path_dir(dest));
                buffer_save(buf, dest);
                buffer_delete(buf);
        } catch (save_error) {
                delete(save_error);
        };
}

function gx_media_load_host_files(dir) {
        if (!pls_is_gxgames()) then return;
        if (variable_global_exists("gx_media_host_files") && is_struct(global.gx_media_host_files)
                && array_length(struct_get_names(global.gx_media_host_files)) > 0) then return;
        var src = gx_path_clean(chart_path_join(dir, ".gx_host.json"));
        if (!file_exists(src)) then return;
        var buf = -1;
        try { buf = buffer_load(src); } catch (load_error) { delete(load_error); return; };
        if (!buffer_exists(buf)) then return;
        var raw = buffer_read(buf, buffer_text);
        buffer_delete(buf);
        try {
                var data = json_parse(raw);
                if (is_struct(data)) then global.gx_media_host_files = data;
        } catch (parse_error) {
                delete(parse_error);
        };
}

function gx_media_host_path_for(local_path) {
        if (!pls_is_gxgames()) then return "";
        if (variable_global_exists("chart_active_path") && is_string(global.chart_active_path)) {
                gx_media_load_host_files(global.chart_active_path);
        };
        if (!variable_global_exists("gx_media_host_files") || !is_struct(global.gx_media_host_files)) then return "";
        var map = global.gx_media_host_files;
        var p = string_replace_all(string(local_path), "\\", "/");
        if (struct_exists(map, p)) then return string(map[$ p]);
        var name = chart_path_file_name(p);
        if (string_length(name)) {
                if (struct_exists(map, name)) then return string(map[$ name]);
                var lower = string_lower(name);
                if (struct_exists(map, lower)) then return string(map[$ lower]);
        };
        var keys = struct_get_names(map);
        var plen = string_length(p);
        for (var i = 0; i < array_length(keys); i++) {
                var k = keys[i];
                var klen = string_length(k);
                if (string_length(name) && string_lower(chart_path_file_name(k)) == string_lower(name)) then return string(map[$ k]);
                if (klen > 0 && plen >= klen && string_copy(p, plen - klen + 1, klen) == k) then return string(map[$ k]);
        };
        return "";
}

function gx_fs_mkdirs(dir_path) {
        var dir = gx_path_clean(string(dir_path));
        while (string_length(dir) > 1 && string_char_at(dir, string_length(dir)) == "/") {
                dir = string_copy(dir, 1, string_length(dir) - 1);
        };
        if (!string_length(dir) || dir == "/" || directory_exists(dir)) then return dir;
        var parent = chart_path_dir(dir);
        while (string_length(parent) > 1 && string_char_at(parent, string_length(parent)) == "/") {
                parent = string_copy(parent, 1, string_length(parent) - 1);
        };
        if (string_length(parent) && parent != dir) then gx_fs_mkdirs(parent);
        try {
                if (!directory_exists(dir)) then directory_create(dir);
        } catch (mkdir_error) {
                delete(mkdir_error);
        };
        return dir;
}

function gx_fs_safe_rel(rel) {
        var p = string_replace_all(string(rel), "\\", "/");
        while (string_pos("//", p) > 0) {
                p = string_replace_all(p, "//", "/");
        };
        while (string_pos("../", p) > 0) {
                p = string_replace_all(p, "../", "");
        };
        while (string_length(p) && string_char_at(p, 1) == "/") {
                p = string_delete(p, 1, 1);
        };
        return p;
}

function gx_fs_save_bytes_json(raw, dest) {
        try {
                var data = json_parse(raw);
                if (!is_struct(data) || !bool(data[$ "ok"] ?? false)) {
                        var err = is_struct(data) ? string(data[$ "error"] ?? "fetch failed") : "fetch json invalid";
                        return { ok: false, error: err, dest: dest };
                };
                var b64 = string(data[$ "base64"] ?? "");
                if (!string_length(b64)) then return { ok: false, error: "empty base64", dest: dest };
                var buf = buffer_base64_decode(b64);
                if (!buffer_exists(buf)) then return { ok: false, error: "base64 decode failed", dest: dest };
                gx_fs_mkdirs(chart_path_dir(dest));
                if (file_exists(dest)) {
                        try { file_delete(dest); } catch (del_error) { delete(del_error); };
                };
                buffer_save(buf, dest);
                var saved = buffer_get_size(buf);
                buffer_delete(buf);
                if (!file_exists(dest)) {
                        var tries = [];
                        array_add(tries, gx_path_clean(chart_path_join(chart_path_dir(dest), gx_file_picker_safe_name(chart_path_file_name(dest)))));
                        if (variable_instance_exists(id, "download_path") && string_length(download_path)) {
                                array_add(tries, gx_path_clean(chart_path_join(download_path, gx_file_picker_safe_name(chart_path_file_name(dest)))));
                        };
                        for (var ti = 0; ti < array_length(tries); ti++) {
                                var fallback = tries[ti];
                                if (!string_length(fallback) || fallback == dest) then continue;
                                gx_fs_mkdirs(chart_path_dir(fallback));
                                var buf2 = buffer_base64_decode(b64);
                                if (buffer_exists(buf2)) {
                                        buffer_save(buf2, fallback);
                                        buffer_delete(buf2);
                                };
                                if (file_exists(fallback)) {
                                        return { ok: true, error: "", kind: string(data[$ "kind"] ?? ""), size: saved, name: string(data[$ "name"] ?? ""), dest: fallback };
                                };
                        };
                        return { ok: false, error: "buffer_save did not create " + dest, dest: dest };
                };
                return { ok: true, error: "", kind: string(data[$ "kind"] ?? ""), size: saved, name: string(data[$ "name"] ?? ""), dest: dest };
        } catch (save_error) {
                var msg = string(save_error);
                delete(save_error);
                return { ok: false, error: msg, dest: dest };
        };
}

function gx_fs_save_fetch_json(raw, dest) {
        return gx_fs_save_bytes_json(raw, dest);
}

function gx_fs_parse_unpack(result_text) {
        var files = [];
        try {
                var data = json_parse(result_text);
                if (!is_struct(data) || !bool(data[$ "ok"] ?? false)) {
                        var err = is_struct(data) ? string(data[$ "error"] ?? "unpack failed") : "unpack json invalid";
                        return { ok: false, error: err, files: files, count: 0, total: 0, name: "" };
                };
                var list = data[$ "files"];
                if (is_array(list)) {
                        for (var i = 0; i < array_length(list); i++) {
                                var e = list[i];
                                if (!is_struct(e)) then continue;
                                var rel = gx_fs_safe_rel(e[$ "rel"] ?? "");
                                var src = string(e[$ "path"] ?? "");
                                if (!string_length(rel) || !string_length(src)) then continue;
                                array_add(files, {
                                        rel: rel,
                                        path: src,
                                        size: real(e[$ "size"] ?? 0),
                                        ext: string(e[$ "ext"] ?? "")
                                });
                        };
                };
                return {
                        ok: true,
                        error: "",
                        files: files,
                        count: real(data[$ "count"] ?? array_length(files)),
                        total: real(data[$ "total"] ?? 0),
                        name: string(data[$ "name"] ?? "")
                };
        } catch (parse_error) {
                var msg = string(parse_error);
                delete(parse_error);
                return { ok: false, error: msg, files: files, count: 0, total: 0, name: "" };
        };
}

function gx_fp_blob_fail(message) {
        downloading = false;
        download_id = -1;
        api_job = "";
        api_unpack_files = [];
        api_unpack_index = 0;
        last_error = message;
        status_text = last_error;
}

function gx_fp_is_video_name(path) {
        switch (chart_path_ext(path)) {
                case ".mp4":
                case ".m4v":
                case ".webm":
                case ".mov":
                case ".mkv":
                case ".ogv":
                        return true;
        };
        return false;
}

function gx_fp_skip_sandbox_copy(item) {
        if (!is_struct(item)) then return true;
        var rel = string(item[$ "rel"] ?? "");
        var ext = string_lower(string(item[$ "ext"] ?? ""));
        if (!string_length(ext)) then ext = chart_path_ext(rel);
        if (!(gx_fp_is_video_name(ext) || gx_fp_is_video_name(rel))) then return false;
        var size = real(item[$ "size"] ?? 0);
        return (size <= 0 || size > 24 * 1024 * 1024);
}

function gx_media_source_exists(local_path) {
        if (chart_file_exists_any(local_path) || file_exists(local_path)) then return true;
        return string_length(gx_media_host_path_for(local_path)) > 0;
}

function gx_fp_blob_next() {
        if (!variable_instance_exists(id, "api_unpack_files") || !is_array(api_unpack_files)) {
                gx_fp_blob_fail("Unpack file list is missing.");
                return;
        };
        while (api_unpack_index < array_length(api_unpack_files) && gx_fp_skip_sandbox_copy(api_unpack_files[api_unpack_index])) {
                api_unpack_index += 1;
        };
        if (api_unpack_index >= array_length(api_unpack_files)) {
                downloading = false;
                download_id = -1;
                api_job = "";
                last_error = "";
                status_text = langf("picker.importedFiles", string(array_length(api_unpack_files)));
                gx_media_store_host_files(api_unpack_files);
                gx_media_persist_host_files(download_path);
                gx_fp_finish_ok(download_path);
                return;
        };
        var item = api_unpack_files[api_unpack_index];
        var rel = string(item[$ "rel"] ?? "");
        status_text = langf("picker.copying", string(api_unpack_index + 1), string(array_length(api_unpack_files)), chart_path_file_name(rel));
        api_job = "blob";
        downloading = true;
        download_id = gx_fs_request_blob(string(item[$ "path"] ?? ""));
        if (download_id < 0) {
                gx_fp_blob_fail("Failed to start blob copy for " + rel);
        };
}

function gx_fp_apply_listing(parsed) {
        if (!is_struct(parsed)) then return;
        items = parsed.items;
        var drive_src = (is_array(parsed.drives) && array_length(parsed.drives) > 0) ? parsed.drives : [];
        var filtered = gx_fp_only_drives(drive_src);
        if (array_length(filtered) > 0) {
                roots = filtered;
                gx_fp_layout();
        };
        api_parent = parsed.parent;
        if (string_length(parsed.path)) then current_dir = parsed.path;
        if (selected >= array_length(items)) then selected = array_length(items) - 1;
        if (selected < 0 && array_length(items) > 0) then selected = 0;
        scroll = 0;
        if (parsed.ok) {
                last_error = "";
                status_text = langf("picker.itemsCount", string(array_length(items)));
                restore_pending = false;
                gx_fp_cache_save();
        } else {
                last_error = parsed.error;
                if (!string_length(last_error)) then last_error = lang("picker.listFailed");
                status_text = last_error;
                if (restore_pending) {
                        restore_pending = false;
                        var letter = gx_fp_drive_letter(current_dir);
                        var fallback = "";
                        for (var ri = 0; ri < array_length(roots); ri++) {
                                if (string_length(letter) && gx_fp_drive_letter(roots[ri].path) == letter) {
                                        fallback = roots[ri].path;
                                        break;
                                };
                        };
                        if (!string_length(fallback) && array_length(roots) > 0) then fallback = roots[0].path;
                        if (string_length(fallback) && fallback != current_dir) then gx_fp_set_directory(fallback, true);
                };
        };
}

function gx_fs_picker_open(on_ok = undefined, on_cancel = undefined) {
        var inst = gx_file_picker_open(on_ok, on_cancel);
        inst.api_mode = true;
        inst.focus_url = false;
        inst.status_text = lang("picker.connecting");
        inst.last_error = "";
        with (inst) {
                api_list_id = -1;
                api_roots_id = gx_fs_request_roots();
                api_parent = "";
                api_job = "";
                api_unpack_files = [];
                api_unpack_index = 0;
                keyboard_string = "";
                gx_fp_cache_load();
                if (string_length(last_dir_cached)) then current_dir = last_dir_cached;
        };
        return inst;
}
