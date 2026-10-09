/// @desc GX.games compatibility helpers. HTML5 JS is not used; this is GML for os_gxgames.

enum HTML5_OPEN_STATUS {
        IDLE = 0,
        PICKING = 1,
        OK = 2,
        CANCELLED = 3,
        ERROR = 4
};

function pls_is_gxgames() {
        return (os_type == os_gxgames);
}

function pls_is_gx_remote() {
        if (!pls_is_gxgames()) then return false;
        var mode = "";
        try { mode = gx_query_unquote(i_gx_query_get("pls-r:mode")); } catch (mode_error) { delete(mode_error); mode = ""; };
        if (mode == "1") then return true;
        var forced = "";
        try { forced = string_lower(gx_query_unquote(i_gx_query_get("pls_remote"))); } catch (force_error) { delete(force_error); forced = ""; };
        return (forced == "1" || forced == "true" || forced == "yes");
}

function gx_file_ui_cmd(cmd) {
        if (!pls_is_gxgames()) then return 0;
        var n = 0;
        try { n = real(i_gx_drop_import(string(cmd))); } catch (rpc_error) { delete(rpc_error); n = 0; };
        return n;
}

function gx_file_ui_set_pick_rect(x, y, w, h) {
        return gx_file_ui_cmd("pls-f:pickrect\t" + string(x) + "\t" + string(y) + "\t" + string(w) + "\t" + string(h) + "\t" + string(room_width) + "\t" + string(room_height));
}

function gx_file_ui_set_drop(on) {
        return gx_file_ui_cmd(on ? "pls-f:drop\t1" : "pls-f:drop\t0");
}

function gx_fs_wipe(path) {
        if (!pls_is_gxgames()) then return 0;
        if (!is_string(path) || !string_length(path)) then return 0;
        return gx_file_ui_cmd("pls-f:wipe\t" + string(path));
}

function gx_fs_copy_js_file(src_path, dest_path) {
        if (!pls_is_gxgames() || !is_string(src_path) || !string_length(src_path)) then return false;
        if (!is_string(dest_path) || !string_length(dest_path)) then return false;
        var size = gx_file_ui_cmd("pls-f:fopen\t" + gx_path_clean(src_path));
        if (!(is_real(size) && size > 0)) then return false;
        gx_fs_mkdirs(chart_path_dir(dest_path));
        var buf = buffer_create(size, buffer_fixed, 1);
        var off = 0;
        var chunk = 16384;
        while (off < size) {
                var n = min(chunk, size - off);
                var b64 = "";
                try { b64 = string(i_gx_drop_chunk(off, n)); } catch (chunk_error) { delete(chunk_error); b64 = ""; };
                if (!is_string(b64) || !string_length(b64)) {
                        buffer_delete(buf);
                        return false;
                };
                var piece = buffer_base64_decode(b64);
                if (!buffer_exists(piece)) {
                        buffer_delete(buf);
                        return false;
                };
                var piece_size = buffer_get_size(piece);
                if (piece_size <= 0) {
                        buffer_delete(piece);
                        buffer_delete(buf);
                        return false;
                };
                buffer_copy(piece, 0, piece_size, buf, off);
                buffer_delete(piece);
                off += piece_size;
        };
        try { if (file_exists(dest_path)) then file_delete(dest_path); } catch (del_error) { delete(del_error); };
        buffer_save(buf, dest_path);
        buffer_delete(buf);
        return file_exists(dest_path);
}

function gx_fs_read_js_text(path, max_chars = -1) {
        if (!pls_is_gxgames() || !is_string(path) || !string_length(path)) then return "";
        var size = gx_file_ui_cmd("pls-f:fopen\t" + gx_path_clean(path));
        if (!(is_real(size) && size > 0)) then return "";
        var want = size;
        if (max_chars > 0) then want = min(size, max_chars * 4);
        var buf = buffer_create(want, buffer_fixed, 1);
        var off = 0;
        var chunk = 16384;
        while (off < want) {
                var n = min(chunk, want - off);
                var b64 = "";
                try { b64 = string(i_gx_drop_chunk(off, n)); } catch (chunk_error) { delete(chunk_error); b64 = ""; };
                if (!is_string(b64) || !string_length(b64)) {
                        buffer_delete(buf);
                        return "";
                };
                var piece = buffer_base64_decode(b64);
                if (!buffer_exists(piece)) {
                        buffer_delete(buf);
                        return "";
                };
                var piece_size = buffer_get_size(piece);
                buffer_copy(piece, 0, min(piece_size, want - off), buf, off);
                buffer_delete(piece);
                off += piece_size;
        };
        var text = "";
        try {
                var src = buffer_create(want + 1, buffer_fixed, 1);
                buffer_copy(buf, 0, want, src, 0);
                buffer_poke(src, want, buffer_u8, 0);
                buffer_seek(src, buffer_seek_start, 0);
                text = buffer_read(src, buffer_string);
                buffer_delete(src);
        } catch (read_error) {
                delete(read_error);
                text = "";
        };
        buffer_delete(buf);
        if (!is_string(text)) then return "";
        if (max_chars > 0 && string_length(text) > max_chars) then text = string_copy(text, 1, max_chars);
        return text;
}

function gx_fs_chart_head(path) {
        if (!pls_is_gxgames() || !is_string(path) || !string_length(path)) then return "";
        var n = gx_file_ui_cmd("pls-f:head\t" + gx_path_clean(path));
        if (!(is_real(n) && n > 0)) {
                var name = chart_path_file_name(path);
                if (string_length(name)) {
                        n = gx_file_ui_cmd("pls-f:head\t" + name);
                        if (!(is_real(n) && n > 0)) then n = gx_file_ui_cmd("pls-f:head\t/tmp/pls/track/" + name);
                };
        };
        if (!(is_real(n) && n > 0)) then return "";
        var head = "";
        try { head = string(i_gx_query_get("pls-f:head")); } catch (head_error) { delete(head_error); head = ""; };
        if (!is_string(head) || !string_length(head)) {
                try { head = string(i_gx_drop_error()); } catch (err_head) { delete(err_head); head = ""; };
        };
        return is_string(head) ? head : "";
}

/// Last bytes of a chart. Format detection only reads the head, so a META
/// object written after judgeLineList is invisible unless the tail is checked too.
function gx_fs_chart_tail(path, max_chars = 16000) {
        if (!pls_is_gxgames() || !is_string(path) || !string_length(path)) then return "";
        var size = gx_file_ui_cmd("pls-f:fopen\t" + gx_path_clean(path));
        if (!(is_real(size) && size > 0)) {
                var name = chart_path_file_name(path);
                if (string_length(name)) {
                        size = gx_file_ui_cmd("pls-f:fopen\t" + name);
                        if (!(is_real(size) && size > 0)) then size = gx_file_ui_cmd("pls-f:fopen\t/tmp/pls/track/" + name);
                        if (!(is_real(size) && size > 0)) then size = gx_file_ui_cmd("pls-f:fopen\t/_savedata/track/" + name);
                };
        };
        if (!(is_real(size) && size > 0)) then return "";
        var max_bytes = max(8, max_chars * 4);
        var take = min(size, max_bytes);
        var start = size - take;
        var buf = buffer_create(take, buffer_fixed, 1);
        var off = 0;
        var chunk = 16384;
        while (off < take) {
                var n = min(chunk, take - off);
                var b64 = "";
                try { b64 = string(i_gx_drop_chunk(start + off, n)); } catch (chunk_error) { delete(chunk_error); b64 = ""; };
                if (!is_string(b64) || !string_length(b64)) {
                        buffer_delete(buf);
                        return "";
                };
                var piece = buffer_base64_decode(b64);
                if (!buffer_exists(piece)) {
                        buffer_delete(buf);
                        return "";
                };
                var piece_size = buffer_get_size(piece);
                if (piece_size <= 0) {
                        buffer_delete(piece);
                        buffer_delete(buf);
                        return "";
                };
                buffer_copy(piece, 0, min(piece_size, take - off), buf, off);
                buffer_delete(piece);
                off += piece_size;
        };
        var text = chart_buffer_slice_to_text(buf, 0, take);
        buffer_delete(buf);
        if (!is_string(text)) then return "";
        if (max_chars > 0 && string_length(text) > max_chars) {
                text = string_copy(text, string_length(text) - max_chars + 1, max_chars);
        };
        return text;
}

function gx_fs_materialize_extract(track_path) {
        if (!pls_is_gxgames() || !is_string(track_path) || !string_length(track_path)) then return 0;
        var listed = gx_fs_list_files(track_path);
        var copied = 0;
        var dest_root = chart_path_norm(track_path);
        if (string_length(dest_root) && string_char_at(dest_root, string_length(dest_root)) != "/") then dest_root += "/";
        for (var i = 0; i < array_length(listed); i++) {
                var src = listed[i];
                var rel = chart_path_rel(dest_root, src);
                if (!string_length(rel)) then rel = chart_path_file_name(src);
                var ext = chart_path_ext(rel);
                if (ext == ".mp4" || ext == ".webm" || ext == ".mov" || ext == ".mkv" || ext == ".ogv" || ext == ".m4v") {
                        var vsize = gx_file_ui_cmd("pls-f:fopen\t" + gx_path_clean(src));
                        if (is_real(vsize) && vsize > 24 * 1024 * 1024) then continue;
                };
                var dest = chart_path_join(dest_root, rel);
                if (gx_fs_copy_js_file(src, dest)) {
                        copied++;
                        continue;
                };
                var alt = chart_path_join("/tmp/pls/track", rel);
                if (gx_fs_copy_js_file(alt, dest)) then copied++;
        };
        print($"[GXZip] materialized {copied}/{array_length(listed)} files into {dest_root}");
        return copied;
}

function gx_fs_list_files(dir_path) {
        var files = [];
        if (!pls_is_gxgames() || !is_string(dir_path) || !string_length(dir_path)) then return files;
        var n = gx_file_ui_cmd("pls-f:list\t" + gx_path_clean(dir_path));
        if (!(is_real(n) && n > 0)) then return files;
        var raw = "";
        try { raw = string(i_gx_query_get("pls-f:list")); } catch (list_error) { delete(list_error); raw = ""; };
        if (!is_string(raw) || !string_length(raw)) then return files;
        var parts = string_split(string_replace_all(raw, "\r", ""), "\n");
        var root = chart_path_norm(dir_path);
        if (string_length(root) && string_char_at(root, string_length(root)) != "/") then root += "/";
        for (var i = 0; i < array_length(parts); i++) {
                var rel = string_trim(parts[i]);
                if (!string_length(rel)) then continue;
                if (string_pos("..", rel) > 0) then continue;
                array_add(files, chart_path_join(root, rel));
        };
        return files;
}

function pls_gx_menu_layout() {
        if (!variable_global_exists("global_scales")) {
                globalvar global_scales;
                global_scales = 1.0;
        };
        var s = global_scales;
        if (!is_real(s) || s <= 0) then s = 1.0;
        var rw = max(1, room_width);
        var rh = max(1, room_height);
        var gap = max(12, 18 * s);
        var btn_h = min(rh * 0.13, 92 * s);
        var remote = pls_is_gx_remote();
        var count = remote ? 1 : 2;
        var btn_w = min((rw - gap * (count + 1)) / count, 320 * s);
        var total = count * btn_w + (count - 1) * gap;
        var x0 = (rw - total) * 0.5;
        var yy = rh * 0.44;
        pick_x = x0;
        pick_y = yy;
        pick_w = btn_w;
        pick_h = btn_h;
        drop_btn_x = 0;
        drop_btn_y = 0;
        drop_btn_w = 0;
        drop_btn_h = 0;
        if (remote) {
                api_btn_x = 0;
                api_btn_y = 0;
                api_btn_w = 0;
                api_btn_h = 0;
        } else {
                api_btn_x = x0 + btn_w + gap;
                api_btn_y = yy;
                api_btn_w = btn_w;
                api_btn_h = btn_h;
        };
        drop_x = pick_x;
        drop_y = pick_y;
        drop_w = pick_w;
        drop_h = pick_h;
        layout_w = rw;
        layout_h = rh;
        layout_scale = s;
        settings_menu_button_layout();
}

function gx_file_ui_drop_open() {
        if (!pls_is_gxgames()) then return false;
        var v = "";
        try { v = gx_query_unquote(i_gx_query_get("pls-f:drop")); } catch (drop_error) { delete(drop_error); v = ""; };
        return v == "1";
}

function gx_remote_exit(error_text = "") {
        if (!pls_is_gxgames()) then return 0;
        var cmd = "pls-r:exit";
        if (is_string(error_text) && string_length(error_text)) then cmd += "\t" + string_copy(string(error_text), 1, 180);
        return gx_file_ui_cmd(cmd);
}

function pls_return_to_entry(error_text = "") {
        gx_drop_set_enabled(false);
        gx_file_ui_set_drop(false);
        if (pls_is_gxgames()) then gx_video_shutdown();
        if (pls_is_gx_remote()) {
                gx_remote_exit(error_text);
                return true;
        };
        room_goto(room_menu);
        return false;
}

function pls_is_html5() {
        return false;
}

function pls_draw_flush() {
        if (pls_is_gxgames()) then return;
        draw_flush();
}

function pls_window_width() {
        var w = window_get_width();
        if (!is_real(w) || w <= 1) then w = display_get_width();
        if (!is_real(w) || w <= 1) then w = max(1, room_width);
        return max(1, w);
}

function pls_window_height() {
        var h = window_get_height();
        if (!is_real(h) || h <= 1) then h = display_get_height();
        if (!is_real(h) || h <= 1) then h = max(1, room_height);
        return max(1, h);
}

function pls_font_path(path) {
        return string_replace_all(string(path), "\\", "/");
}

function pls_font_add(path, size, bold = false, italic = false, first = -infinity, last = infinity) {
        return font_add(pls_font_path(path), size, bold, italic, first, last);
}

/// Included Files copied by GitHub Desktop can be an LFS pointer or a truncated file.
/// font_add on those returns a handle that draws nothing.
function pls_font_file_ok(_path) {
        if (!is_string(_path) || !string_length(_path) || !file_exists(_path)) then return false;
        if (pls_is_html5()) then return true;
        var bin = -1;
        var ok = false;
        try {
                bin = file_bin_open(_path, 0);
                if (bin != -1) {
                        var b0 = file_bin_read_byte(bin);
                        var b1 = file_bin_read_byte(bin);
                        var b2 = file_bin_read_byte(bin);
                        var b3 = file_bin_read_byte(bin);
                        var ttf = (b0 == 0 && b1 == 1 && b2 == 0 && b3 == 0);
                        var otto = (b0 == ord("O") && b1 == ord("T") && b2 == ord("T") && b3 == ord("O"));
                        var tru = (b0 == ord("t") && b1 == ord("r") && b2 == ord("u") && b3 == ord("e"));
                        var ttc = (b0 == ord("t") && b1 == ord("t") && b2 == ord("c") && b3 == ord("f"));
                        ok = ttf || otto || tru || ttc;
                };
        } catch (font_err) {
                delete(font_err);
                ok = false;
        };
        if (bin != -1) {
                try { file_bin_close(bin); } catch (close_err) { delete(close_err); };
        };
        return ok;
}

function pls_font_add_system(size, bold, italic) {
        var names = ["Microsoft YaHei", "Microsoft YaHei UI", "SimHei", "SimSun", "Noto Sans CJK SC", "Arial"];
        if (os_type == os_android) {
                names = [
                        "/system/fonts/NotoSansCJK-Regular.ttc",
                        "/system/fonts/NotoSansSC-Regular.otf",
                        "/system/fonts/DroidSansFallback.ttf"
                ];
        };
        for (var i = 0; i < array_length(names); i++) {
                var font_id = -1;
                try {
                        font_id = font_add(names[i], size, bold, italic, 32, 65535);
                } catch (add_err) {
                        delete(add_err);
                        font_id = -1;
                };
                if (font_exists(font_id)) then return font_id;
        };
        return -1;
}

function pls_font_enable_sdf(font_id, enable) {
        if (!font_exists(font_id)) then return false;
        font_enable_sdf(font_id, enable);
        return true;
}

function pls_bundled_font_path() {
        return working_directory + "resource/saira.ttf";
}

function pls_ui_font_cache() {
        if (!variable_global_exists("pls_ui_fonts") || !is_struct(global.pls_ui_fonts)) {
                global.pls_ui_fonts = {};
        };
        return global.pls_ui_fonts;
}

function pls_ui_font_key(size, bold, italic, enable_sdf) {
        return $"{size}|{bold ? 1 : 0}|{italic ? 1 : 0}|{enable_sdf ? 1 : 0}";
}

function pls_ui_font_add(size, bold = true, italic = false, first = -infinity, last = infinity, enable_sdf = true) {
        var cache = pls_ui_font_cache();
        var key = pls_ui_font_key(size, bold, italic, enable_sdf);
        if (struct_exists(cache, key)) {
                var existing = cache[$ key];
                if (font_exists(existing)) then return existing;
        };
        if (!variable_global_exists("pls_font_page_ready")) {
                // Default 1024px evicts CJK glyphs mid-frame on smaller GPUs, so settings text draws blank.
                font_texture_page_size = max(1024, font_texture_page_size);
                if (font_texture_page_size < 2048) then font_texture_page_size = 2048;
                global.pls_font_page_ready = true;
        };
        font_add_enable_aa(true);
        var path = pls_bundled_font_path();
        var font_id = -1;
        if (pls_font_file_ok(path)) {
                font_id = pls_font_add(path, size, bold, italic, first, last);
        };
        if (!font_exists(font_id)) then font_id = pls_font_add_system(size, bold, italic);
        if (!font_exists(font_id)) then return -1;
        if (enable_sdf) then pls_font_enable_sdf(font_id, true);
        cache[$ key] = font_id;
        return font_id;
}

function pls_ui_font_is_shared(font_id) {
        if (!font_exists(font_id)) then return false;
        var cache = pls_ui_font_cache();
        var names = struct_get_names(cache);
        for (var i = 0; i < array_length(names); i++) {
                if (cache[$ names[i]] == font_id) then return true;
        };
        return false;
}

function pls_ui_font_delete(font_id) {
        if (pls_ui_font_is_shared(font_id)) then return false;
        if (font_exists(font_id)) then font_delete(font_id);
        return true;
}

function pls_ui_font_release_instance() {
        if (!variable_instance_exists(id, "ui_font")) then return;
        pls_ui_font_delete(ui_font);
        ui_font = -1;
}

function html5_files_available() {
        return false;
}

function gx_files_available() {
        return pls_is_gxgames();
}

function chart_use_native_files() {
        if (os_type == os_android && android_files_available()) then return true;
        return false;
}

function chart_native_exists(path) {
        return android_files_exists(path);
}

function chart_native_is_dir(path) {
        return android_files_is_dir(path);
}

function chart_native_mkdir(path) {
        return android_files_mkdir(path);
}

function chart_native_list(path) {
        return android_files_list(path);
}

function chart_native_delete(path) {
        return android_files_delete(path);
}

function chart_native_copy(source_path, dest_path) {
        return android_files_copy(source_path, dest_path);
}

function chart_native_size(path) {
        return android_files_size(path);
}

function chart_native_error() {
        return android_files_error();
}

function chart_native_logs_dir() {
        return android_files_logs_dir();
}

function chart_native_external_dir() {
        return android_files_external_dir();
}

function chart_native_read_text(path) {
        return android_files_read_text(path);
}

function chart_native_write_text(path, text) {
        return android_files_write_text(path, text);
}

function chart_native_append_text(path, text) {
        return android_files_append_text(path, text);
}

function gx_zip_ensure() {
        if (!variable_global_exists("gx_zip") || !is_struct(global.gx_zip)) {
                global.gx_zip = { next_id:1, last_error:"", tasks:{} };
        };
        return global.gx_zip;
}

function gx_zip_extract(archive_path, output_directory, overwrite, clean_output) {
        var state = gx_zip_ensure();
        var src = gx_path_clean(archive_path);
        if (!file_exists(src)) {
                state.last_error = "Zip file does not exist: " + src;
                return false;
        };
        var orig_src = src;
        var ext = string_lower(filename_ext(src));
        if (ext != ".zip") {
                var zip_copy = gx_path_clean(chart_path_join(gx_file_picker_download_dir(), "extract_src.zip"));
                if (file_exists(zip_copy)) {
                        try { file_delete(zip_copy); } catch (zip_del_error) { delete(zip_del_error); };
                };
                try {
                        file_copy(src, zip_copy);
                } catch (zip_copy_error) {
                        delete(zip_copy_error);
                };
                if (file_exists(zip_copy)) then src = zip_copy;
        };
        var dest = gx_path_clean(output_directory);
        while (string_length(dest) > 1 && string_char_at(dest, string_length(dest)) == "/") {
                dest = string_copy(dest, 1, string_length(dest) - 1);
        };
        if (clean_output) {
                if (file_exists(chart_path_join(dest, "extra.json"))) then file_delete(chart_path_join(dest, "extra.json"));
                chart_session_remove_dir(dest);
        };
        if (!directory_exists(dest)) then directory_create(dest);
        var js_n = gx_file_ui_cmd("pls-f:unzip\t" + orig_src + "\t" + dest);
        if (!(is_real(js_n) && js_n > 0) && orig_src != src) {
                js_n = gx_file_ui_cmd("pls-f:unzip\t" + src + "\t" + dest);
        };
        if (is_real(js_n) && js_n > 0) {
                state.last_error = "";
                print($"[GXZip] JS unzip n={js_n} dest={dest}");
                return true;
        };
        var js_err = "";
        try { js_err = gx_query_unquote(i_gx_query_get("pls-f:unziperr")); } catch (js_err_read) { delete(js_err_read); js_err = ""; };
        var extracted = -1;
        try {
                extracted = zip_unzip(src, dest);
        } catch (zip_error) {
                state.last_error = "zip_unzip exception: " + string(zip_error);
                if (string_length(js_err)) then state.last_error += " js=" + js_err;
                return false;
        };
        if (!is_real(extracted) || extracted <= 0) {
                state.last_error = "zip_unzip failed (n=" + string(extracted) + ") src=" + src + " dest=" + dest;
                if (string_length(js_err)) then state.last_error += " js=" + js_err;
                return false;
        };
        state.last_error = "";
        return true;
}

function gx_zip_extract_async(archive_path, output_directory, overwrite, clean_output) {
        var state = gx_zip_ensure();
        var task_id = state.next_id++;
        var ok = gx_zip_extract(archive_path, output_directory, overwrite, clean_output);
        state.tasks[$ string(task_id)] = {
                status: ok ? UNICODE_ZIP_TASK_STATUS.SUCCEEDED : UNICODE_ZIP_TASK_STATUS.FAILED,
                exit_code: ok ? 0 : 1,
                error: ok ? "" : state.last_error
        };
        return task_id;
}

function gx_zip_task_get(task_id) {
        var state = gx_zip_ensure();
        var key = string(task_id);
        if (!struct_exists(state.tasks, key)) then return undefined;
        return state.tasks[$ key];
}

function gx_zip_available() {
        return true;
}

function gx_zip_detect(archive_path) {
        if (!file_exists(archive_path)) then return "";
        var ext = string_lower(filename_ext(archive_path));
        if (ext == ".zip" || ext == ".pez") then return "zip";
        return "zip";
}

function gx_zip_compress(source_path, archive_path, include_root, overwrite) {
        gx_zip_ensure().last_error = "ZIP compress is not implemented on GX.games.";
        return false;
}

function gx_zip_compress_async(source_path, archive_path, include_root, overwrite) {
        return -1;
}

function gx_zip_task_status(task_id) {
        var task = gx_zip_task_get(task_id);
        if (!is_struct(task)) then return UNICODE_ZIP_TASK_STATUS.UNKNOWN;
        return task.status;
}

function gx_zip_task_exit_code(task_id) {
        var task = gx_zip_task_get(task_id);
        if (!is_struct(task)) then return 0;
        return task.exit_code;
}

function gx_zip_task_error(task_id) {
        var task = gx_zip_task_get(task_id);
        if (!is_struct(task)) then return "";
        return task.error;
}

function gx_zip_task_cancel(task_id) {
        var task = gx_zip_task_get(task_id);
        if (!is_struct(task)) then return false;
        if (task.status == UNICODE_ZIP_TASK_STATUS.QUEUED || task.status == UNICODE_ZIP_TASK_STATUS.RUNNING) {
                task.status = UNICODE_ZIP_TASK_STATUS.CANCELLED;
                task.exit_code = 1;
                task.error = "ZIP extraction was cancelled.";
        };
        return true;
}

function gx_zip_task_release(task_id) {
        var state = gx_zip_ensure();
        var key = string(task_id);
        if (!struct_exists(state.tasks, key)) then return false;
        struct_remove(state.tasks, key);
        return true;
}

function gx_zip_last_error() {
        return gx_zip_ensure().last_error;
}

function html5_open_pick(filter) {
        return false;
}

function html5_open_status() {
        return HTML5_OPEN_STATUS.ERROR;
}

function html5_open_path() {
        return "";
}

function html5_open_error() {
        return "HTML5 backend retired; use GX.games.";
}

function html5_open_reset() {
}

function media_use_html5() {
        return false;
}

function media_use_gx() {
        return pls_is_gxgames();
}

function gx_file_picker_needed() {
        return pls_is_gxgames();
}

enum GX_DROP_STATUS {
        IDLE = 0,
        HOVER = 1,
        READING = 2,
        OK = 3,
        ERROR = 4
};

function gx_drop_boot() {
        if (!pls_is_gxgames()) then return 0;
        return i_gx_drop_boot();
}

function gx_drop_unpause() {
        if (!pls_is_gxgames()) then return 0;
        return i_gx_drop_unpause();
}

function gx_drop_set_enabled(enabled) {
        if (!pls_is_gxgames()) then return 0;
        return i_gx_drop_set_enabled(enabled ? 1 : 0);
}

function gx_drop_open_import() {
        if (!pls_is_gxgames()) then return 0;
        return i_gx_drop_open_import();
}

function gx_query_unquote(text) {
        text = string_trim(string(text));
        var n = string_length(text);
        if (n >= 2) {
                var first = string_char_at(text, 1);
                var last = string_char_at(text, n);
                if ((first == "\"" && last == "\"") || (first == "'" && last == "'")) {
                        text = string_copy(text, 2, n - 2);
                };
        };
        return text;
}

function gx_query_chart() {
        if (!pls_is_gxgames()) then return "";
        var q = gx_query_unquote(i_gx_query_get("pls_chart"));
        if (!string_length(q)) then q = gx_query_unquote(i_gx_query_get("chart"));
        return q;
}

function gx_import_ready_candidates() {
        return [
                gx_path_clean(chart_path_join(gx_file_picker_download_dir(), ".pls_ready")),
                gx_path_clean(chart_path_join(string(game_save_id), "charts/.pls_ready")),
                gx_path_clean("/_savedata/charts/.pls_ready"),
                gx_path_clean("charts/.pls_ready")
        ];
}

function gx_import_read_text(path) {
        if (!file_exists(path)) then return "";
        var buf = buffer_load(path);
        if (!buffer_exists(buf)) then return "";
        var text = "";
        try {
                buffer_seek(buf, buffer_seek_start, 0);
                text = buffer_read(buf, buffer_text);
        } catch (read_error) {
                delete(read_error);
                text = "";
        };
        buffer_delete(buf);
        return string_trim(string(text));
}

function gx_import_poll_file() {
        var ready_paths = gx_import_ready_candidates();
        for (var i = 0; i < array_length(ready_paths); i++) {
                var ready = ready_paths[i];
                if (!file_exists(ready)) then continue;
                var name = gx_file_picker_safe_name(gx_import_read_text(ready));
                if (!string_length(name)) then name = "chart.zip";
                var dir = chart_path_dir(ready);
                var zip_path = chart_path_join(dir, name);
                if (!file_exists(zip_path)) then zip_path = chart_path_join(gx_file_picker_download_dir(), name);
                if (!file_exists(zip_path)) then zip_path = chart_path_join("/_savedata/charts/", name);
                try { file_delete(ready); } catch (del_error) { delete(del_error); };
                if (file_exists(zip_path)) then return zip_path;
        };
        return "";
}

function gx_drop_status() {
        if (!pls_is_gxgames()) then return GX_DROP_STATUS.IDLE;
        return i_gx_drop_status();
}

function gx_drop_hover() {
        if (!pls_is_gxgames()) then return false;
        return (i_gx_drop_hover() > 0);
}

function gx_drop_filename() {
        if (!pls_is_gxgames()) then return "";
        return string(i_gx_drop_filename());
}

function gx_drop_error() {
        if (!pls_is_gxgames()) then return "";
        return string(i_gx_drop_error());
}

function gx_drop_size() {
        if (!pls_is_gxgames()) then return 0;
        return i_gx_drop_size();
}

function gx_drop_reset() {
        if (!pls_is_gxgames()) then return 0;
        return i_gx_drop_reset();
}

function gx_drop_save_chunks(dest_path) {
        var size = gx_drop_size();
        if (size <= 0) then return false;
        var buf = buffer_create(size, buffer_fixed, 1);
        var off = 0;
        var chunk = 16384;
        while (off < size) {
                var n = min(chunk, size - off);
                var b64 = i_gx_drop_chunk(off, n);
                if (!is_string(b64) || !string_length(b64)) {
                        buffer_delete(buf);
                        return false;
                };
                var piece = buffer_base64_decode(b64);
                if (!buffer_exists(piece)) {
                        buffer_delete(buf);
                        return false;
                };
                var piece_size = buffer_get_size(piece);
                buffer_copy(piece, 0, piece_size, buf, off);
                buffer_delete(piece);
                off += piece_size;
        };
        buffer_save(buf, dest_path);
        buffer_delete(buf);
        return file_exists(dest_path);
}

function gx_drop_take_file() {
        if (!pls_is_gxgames()) then return "";
        var name = gx_file_picker_safe_name(gx_drop_filename());
        if (!string_length(name)) then name = "chart.zip";
        var dest = chart_path_join(gx_file_picker_download_dir(), name);
        if (file_exists(dest)) then return dest;
        var js_path = "";
        try { js_path = gx_query_unquote(i_gx_query_get("pls-f:path")); } catch (path_error) { delete(path_error); js_path = ""; };
        if (string_length(js_path) && file_exists(js_path)) then return js_path;
        var imported = (i_gx_drop_import(dest) > 0) && file_exists(dest);
        if (!imported) {
                var rel = "charts/" + name;
                imported = (i_gx_drop_import(rel) > 0) && file_exists(rel);
                if (imported) then dest = rel;
        };
        if (!imported) {
                var tmp_dest = chart_path_join(chart_gx_local_root(), "charts/" + name);
                imported = (i_gx_drop_import(tmp_dest) > 0) && file_exists(tmp_dest);
                if (imported) then dest = tmp_dest;
        };
        if (!imported) then imported = gx_drop_save_chunks(dest);
        if (!imported || !file_exists(dest)) then return "";
        return dest;
}

function gx_file_picker_is_url(text) {
        var t = string_lower(string_trim(string(text)));
        return (string_pos("https://", t) == 1) || (string_pos("http://", t) == 1);
}

function gx_file_picker_is_package(path) {
        var ext = chart_path_ext(path);
        return (ext == ".zip") || (ext == ".pez");
}

function gx_file_picker_queue_chart(path) {
        if (!is_string(path) || !string_length(path)) then return false;
        var session = chart_session_ensure();
        session.source_path = path;
        session.ready = false;
        session.error = "";
        session.status = "Queued";
        session.detail = path;
        room_goto(room_loading);
        return true;
}

function gx_file_picker_open(on_ok = undefined, on_cancel = undefined) {
        if (instance_exists(oFilePicker)) then return instance_find(oFilePicker, 0);
        var inst = instance_create_depth(0, 0, -2000000, oFilePicker);
        inst.on_ok = is_undefined(on_ok) ? gx_file_picker_queue_chart : on_ok;
        inst.on_cancel = on_cancel;
        if (!pls_is_gxgames()) {
                with (inst) {
                        roots = gx_file_picker_roots();
                        gx_fp_layout();
                        var start = last_dir_cached;
                        if (!string_length(start)) then start = gx_file_picker_download_dir();
                        gx_fp_set_directory(start, true);
                };
        };
        return inst;
}

function gx_path_clean(path) {
        var p = chart_path_norm(path);
        while (string_pos("//", p) > 0) {
                p = string_replace_all(p, "//", "/");
        };
        return p;
}

function gx_file_picker_ensure_dir(dir_path) {
        var dir = gx_path_clean(dir_path);
        if (!string_length(dir)) then return "";
        if (string_char_at(dir, string_length(dir)) != "/") then dir += "/";
        if (!directory_exists(dir)) {
                try {
                        directory_create(dir);
                } catch (mkdir_error) {
                        delete(mkdir_error);
                };
        };
        return dir;
}

function gx_file_picker_download_dir() {
        if (pls_is_gxgames()) {
                return gx_file_picker_ensure_dir(chart_path_join(chart_gx_sandbox_root(), "charts"));
        };
        var base = gx_path_clean(string(game_save_id));
        if (!string_length(base)) then base = gx_path_clean(working_directory);
        return gx_file_picker_ensure_dir(chart_path_join(base, "charts"));
}

function gx_file_picker_roots() {
        var roots = [];
        var downloads = gx_file_picker_download_dir();
        if (string_length(downloads)) {
                array_add(roots, { name: "Downloads", path: downloads });
        };
        var save_dir = chart_path_norm(game_save_id);
        if (string_length(save_dir)) {
                array_add(roots, { name: "Save Data", path: save_dir });
        };
        array_add(roots, { name: lang("picker.gameFiles", "Game Files"), path: chart_path_norm(working_directory) });
        var sample = chart_path_norm(working_directory + "chart/");
        if (directory_exists(sample)) {
                array_add(roots, { name: "Sample", path: sample });
        };
        var bundled = chart_path_norm(working_directory + "charts/");
        if (directory_exists(bundled)) {
                array_add(roots, { name: "Bundled", path: bundled });
        };
        return roots;
}

function gx_file_picker_dir_key(path) {
        var p = chart_path_norm(path);
        if (string_length(p) && string_char_at(p, string_length(p)) != "/") then p += "/";
        return p;
}

function gx_file_picker_parent(path) {
        var p = chart_path_norm(path);
        while (string_length(p) > 1 && string_char_at(p, string_length(p)) == "/") {
                p = string_copy(p, 1, string_length(p) - 1);
        };
        return chart_path_dir(p);
}

function gx_file_picker_safe_name(name) {
        var src = string(name);
        var out = "";
        for (var i = 1; i <= string_length(src); i++) {
                var code = string_ord_at(src, i);
                var keep = (code >= 48 && code <= 57) || (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || (code == 46) || (code == 45) || (code == 95);
                out += keep ? string_char_at(src, i) : "_";
        };
        while (string_pos("..", out) > 0) {
                out = string_replace_all(out, "..", "_");
        };
        if (!string_length(out)) then out = "chart.zip";
        return out;
}

function gx_file_picker_url_filename(url) {
        var u = string_trim(string(url));
        var hash_at = string_pos("#", u);
        if (hash_at > 0) then u = string_copy(u, 1, hash_at - 1);
        var query_at = string_pos("?", u);
        if (query_at > 0) then u = string_copy(u, 1, query_at - 1);
        u = string_replace_all(u, "\\", "/");
        var name = chart_path_file_name(u);
        name = string_replace_all(name, "%20", "_");
        name = gx_file_picker_safe_name(name);
        if (!gx_file_picker_is_package(name)) {
                if (!string_length(name) || name == "chart.zip") {
                        name = "chart.zip";
                } else {
                        name += ".zip";
                };
        };
        return name;
}

function gx_file_picker_looks_like_zip(path) {
        if (!file_exists(path)) then return false;
        var buf = buffer_load(path);
        if (!buffer_exists(buf)) then return false;
        var ok = (buffer_get_size(buf) >= 4) && (buffer_peek(buf, 0, buffer_u8) == 80) && (buffer_peek(buf, 1, buffer_u8) == 75);
        buffer_delete(buf);
        return ok;
}

function gx_file_picker_list(dir_path) {
        var items = [];
        var seen = {};
        var dir = chart_path_norm(dir_path);
        if (!string_length(dir)) then return items;
        if (string_char_at(dir, string_length(dir)) != "/") then dir += "/";
        var limit = 400;

        try {
                var found = file_find_first(dir + "*", fa_directory);
                while (is_string(found) && string_length(found) && array_length(items) < limit) {
                        if (found != "." && found != ".." && !struct_exists(seen, found)) {
                                var full = chart_path_join(dir, found);
                                if (directory_exists(full)) {
                                        seen[$ found] = true;
                                        array_add(items, { name: found, path: full, is_dir: true });
                                };
                        };
                        found = file_find_next();
                };
                file_find_close();
        } catch (list_dir_error) {
                delete(list_dir_error);
                try { file_find_close(); } catch (list_dir_close_error) { delete(list_dir_close_error); };
        };

        try {
                var found_file = file_find_first(dir + "*", fa_none);
                while (is_string(found_file) && string_length(found_file) && array_length(items) < limit) {
                        if (found_file != "." && found_file != ".." && !struct_exists(seen, found_file)) {
                                var full_file = chart_path_join(dir, found_file);
                                if (directory_exists(full_file)) {
                                        seen[$ found_file] = true;
                                        array_add(items, { name: found_file, path: full_file, is_dir: true });
                                } else if (file_exists(full_file) && gx_file_picker_is_package(full_file)) {
                                        seen[$ found_file] = true;
                                        array_add(items, { name: found_file, path: full_file, is_dir: false });
                                };
                        };
                        found_file = file_find_next();
                };
                file_find_close();
        } catch (list_file_error) {
                delete(list_file_error);
                try { file_find_close(); } catch (list_file_close_error) { delete(list_file_close_error); };
        };

        array_sort(items, function(a, b) {
                if (a.is_dir && !b.is_dir) then return -1;
                if (!a.is_dir && b.is_dir) then return 1;
                var an = string_lower(a.name);
                var bn = string_lower(b.name);
                if (an == bn) then return 0;
                return (an < bn) ? -1 : 1;
        });
        return items;
}

function gx_fp_hit(mx, my, box) {
        if (!is_struct(box)) then return false;
        return (mx >= box.x && mx < box.x + box.w && my >= box.y && my < box.y + box.h);
}

function gx_fp_drive_letter(os_path) {
        var p = string_replace_all(string(os_path), "/", "\\");
        if (string_length(p) >= 2 && string_char_at(p, 2) == ":") {
                var ch = string_upper(string_char_at(p, 1));
                var code = ord(ch);
                if (code >= 65 && code <= 90) then return ch;
        };
        return "";
}

function gx_fp_is_drive_root(name, os_path) {
        var n = string_upper(string_trim(string(name)));
        n = string_replace_all(n, "/", "");
        n = string_replace_all(n, "\\", "");
        if (string_length(n) == 2 && string_char_at(n, 2) == ":") {
                var ncode = ord(string_char_at(n, 1));
                if (ncode >= 65 && ncode <= 90) then return true;
        };
        var p = string_replace_all(string(os_path), "/", "\\");
        while (string_length(p) > 3 && string_char_at(p, string_length(p)) == "\\") {
                p = string_copy(p, 1, string_length(p) - 1);
        };
        if (string_length(p) == 2 && string_char_at(p, 2) == ":") then return true;
        if (string_length(p) == 3 && string_char_at(p, 2) == ":" && string_char_at(p, 3) == "\\") then return true;
        return false;
}

function gx_fp_only_drives(list) {
        var out = [];
        var seen = {};
        if (!is_array(list)) then return out;
        for (var i = 0; i < array_length(list); i++) {
                var e = list[i];
                if (!is_struct(e)) then continue;
                if (!gx_fp_is_drive_root(e[$ "name"] ?? "", e[$ "path"] ?? "")) then continue;
                var letter = gx_fp_drive_letter(string(e[$ "path"] ?? ""));
                if (!string_length(letter)) then letter = string_upper(string_char_at(string(e[$ "name"] ?? " "), 1));
                if (!string_length(letter) || struct_exists(seen, letter)) then continue;
                seen[$ letter] = true;
                array_add(out, { name: letter + ":", path: letter + ":\\" });
        };
        return out;
}

function gx_fp_cache_path() {
        var base = gx_path_clean(string(game_save_id));
        if (!string_length(base)) then base = gx_path_clean(working_directory);
        return gx_path_clean(chart_path_join(base, "gx_picker.ini"));
}

function gx_fp_cache_load() {
        last_dir_cached = "";
        if (!is_struct(drive_cache)) then drive_cache = {};
        var f = gx_fp_cache_path();
        if (!file_exists(f)) then return;
        ini_open(f);
        last_dir_cached = string(ini_read_string("picker", "last_dir", ""));
        for (var i = 0; i < 26; i++) {
                var letter = chr(65 + i);
                var stored = string(ini_read_string("picker", "last_" + letter, ""));
                if (string_length(stored)) then drive_cache[$ letter] = stored;
        };
        ini_close();
}

function gx_fp_cache_save() {
        if (!variable_instance_exists(id, "current_dir") || !string_length(current_dir)) then return;
        var f = gx_fp_cache_path();
        ini_open(f);
        ini_write_string("picker", "last_dir", current_dir);
        var letter = gx_fp_drive_letter(current_dir);
        if (string_length(letter)) {
                ini_write_string("picker", "last_" + letter, current_dir);
                if (!is_struct(drive_cache)) then drive_cache = {};
                drive_cache[$ letter] = current_dir;
        };
        ini_close();
        last_dir_cached = current_dir;
}

function gx_fp_history_can_back() {
        return is_array(nav_history) && array_length(nav_history) > 0;
}

function gx_fp_history_can_fwd() {
        return is_array(nav_future) && array_length(nav_future) > 0;
}

function gx_fp_goto_root(root_path) {
        var dest = string(root_path);
        var letter = gx_fp_drive_letter(dest);
        if (string_length(letter) && is_struct(drive_cache) && struct_exists(drive_cache, letter)) {
                var cached = string(drive_cache[$ letter]);
                if (string_length(cached) && gx_fp_drive_letter(cached) == letter) then dest = cached;
        };
        gx_fp_set_directory(dest);
}

function gx_fp_go_back() {
        if (!gx_fp_history_can_back()) then return;
        if (!is_array(nav_future)) then nav_future = [];
        array_add(nav_future, current_dir);
        var prev = nav_history[array_length(nav_history) - 1];
        array_delete(nav_history, array_length(nav_history) - 1, 1);
        gx_fp_set_directory(prev, true);
}

function gx_fp_go_forward() {
        if (!gx_fp_history_can_fwd()) then return;
        if (!is_array(nav_history)) then nav_history = [];
        array_add(nav_history, current_dir);
        var next = nav_future[array_length(nav_future) - 1];
        array_delete(nav_future, array_length(nav_future) - 1, 1);
        gx_fp_set_directory(next, true);
}

function gx_fp_layout() {
        var s = 1.0;
        if (variable_global_exists("global_scales") && is_real(global_scales) && global_scales > 0) then s = global_scales;
        layout_s = s;
        var rw = max(1, room_width);
        var rh = max(1, room_height);
        panel_w = min(rw * 0.92, 1000 * s);
        panel_h = min(rh * 0.92, 660 * s);
        panel_x = (rw - panel_w) * 0.5;
        panel_y = (rh - panel_h) * 0.5;
        var pad = 18 * s;
        var inner_x = panel_x + pad;
        var inner_w = panel_w - pad * 2;
        title_y = panel_y + pad;
        hint_y = title_y;
        url_x = inner_x;
        url_y = hint_y;
        url_w = 0;
        url_h = 0;
        btn_go = { label: "", x: 0, y: 0, w: 0, h: 0 };
        btn_paste = { label: "", x: 0, y: 0, w: 0, h: 0 };
        roots_y = panel_y + pad;
        roots_h = 36 * s;
        var n = array_length(roots);
        var gap = 6 * s;
        var min_w = 52 * s;
        var per_row = max(1, floor((inner_w + gap) / (min_w + gap)));
        var rows = max(1, ceil(max(1, n) / per_row));
        var root_w = (inner_w - gap * (per_row - 1)) / per_row;
        root_rects = [];
        for (var i = 0; i < n; i++) {
                var col = i mod per_row;
                var row = i div per_row;
                array_add(root_rects, {
                        label: roots[i].name,
                        path: roots[i].path,
                        x: inner_x + col * (root_w + gap),
                        y: roots_y + row * (roots_h + gap),
                        w: root_w,
                        h: roots_h
                });
        };
        var drives_bottom = roots_y + rows * (roots_h + gap) - gap;
        var nav_y = drives_bottom + 10 * s;
        var nav_h = 36 * s;
        var nav_w = (inner_w - gap * 2) / 3;
        btn_up = { label: lang("picker.up"), x: inner_x, y: nav_y, w: nav_w, h: nav_h };
        btn_back = { label: lang("picker.back"), x: btn_up.x + btn_up.w + gap, y: nav_y, w: nav_w, h: nav_h };
        btn_fwd = { label: lang("picker.fwd"), x: btn_back.x + btn_back.w + gap, y: nav_y, w: nav_w, h: nav_h };
        path_y = nav_y + nav_h + 8 * s;
        path_h = 24 * s;
        path_x = inner_x;
        path_w = inner_w;
        var footer_y = panel_y + panel_h - pad - 40 * s;
        btn_cancel = { label: lang("picker.cancel"), x: inner_x + inner_w - 120 * s, y: footer_y, w: 120 * s, h: 40 * s };
        btn_open = { label: lang("picker.open"), x: btn_cancel.x - 8 * s - 120 * s, y: footer_y, w: 120 * s, h: 40 * s };
        btn_folder = { label: lang("picker.useFolder"), x: btn_open.x - 8 * s - 150 * s, y: footer_y, w: 150 * s, h: 40 * s };
        status_h = 22 * s;
        status_y = footer_y - 10 * s - status_h;
        list_x = inner_x;
        list_y = path_y + path_h + 8 * s;
        list_w = inner_w;
        list_h = max(48 * s, status_y - 8 * s - list_y);
        row_h = max(24, 32 * s);
        visible_rows = max(1, floor(list_h / row_h));
}

function gx_fp_refresh_list() {
        if (variable_instance_exists(id, "api_mode") && api_mode) {
                status_text = langf("picker.listing", current_dir);
                api_list_id = gx_fs_request_list(current_dir);
                return;
        };
        items = gx_file_picker_list(current_dir);
        if (selected >= array_length(items)) then selected = array_length(items) - 1;
        if (selected < 0 && array_length(items) > 0) then selected = 0;
        if (scroll > selected) then scroll = max(0, selected);
        if (selected >= scroll + visible_rows) then scroll = max(0, selected - visible_rows + 1);
        var max_scroll = max(0, array_length(items) - visible_rows);
        if (scroll > max_scroll) then scroll = max_scroll;
}

function gx_fp_set_directory(dir_path, from_history = false) {
        var dest = string(dir_path);
        if (!from_history) {
                if (variable_instance_exists(id, "current_dir") && string_length(current_dir) && current_dir != dest) {
                        if (!is_array(nav_history)) then nav_history = [];
                        array_add(nav_history, current_dir);
                        if (array_length(nav_history) > 64) then array_delete(nav_history, 0, array_length(nav_history) - 64);
                        nav_future = [];
                };
        };
        if (variable_instance_exists(id, "api_mode") && api_mode) {
                current_dir = dest;
                selected = 0;
                scroll = 0;
                gx_fp_cache_save();
                gx_fp_refresh_list();
                return;
        };
        current_dir = gx_file_picker_dir_key(dest);
        if (!string_length(current_dir)) then current_dir = gx_file_picker_download_dir();
        selected = 0;
        scroll = 0;
        gx_fp_cache_save();
        gx_fp_refresh_list();
}

function gx_fp_sync_url_field() {
        if (focus_url) {
                url_text = string(keyboard_string);
        };
}

function gx_fp_set_focus_url(enable) {
        gx_fp_sync_url_field();
        focus_url = enable;
        if (focus_url) {
                keyboard_string = url_text;
        } else {
                keyboard_string = url_text;
        };
}

function gx_fp_finish_ok(path) {
        if (confirmed) then return;
        confirmed = true;
        var cb = on_ok;
        instance_destroy();
        if (is_callable(cb)) then cb(path);
}

function gx_fp_finish_cancel() {
        if (confirmed) then return;
        confirmed = true;
        var cb = on_cancel;
        instance_destroy();
        if (is_callable(cb)) then cb();
}

function gx_fp_confirm_local(path) {
        var target = string_trim(string(path));
        if (!string_length(target)) {
                last_error = "No path selected.";
                status_text = last_error;
                return;
        };
        if (variable_instance_exists(id, "api_mode") && api_mode && gx_file_picker_is_package(target)) {
                var dest_name = gx_file_picker_safe_name(chart_path_file_name(target));
                var dot = string_last_pos(".", dest_name);
                var stem = (dot > 1) ? string_copy(dest_name, 1, dot - 1) : dest_name;
                if (!string_length(stem)) then stem = "chart";
                download_path = gx_path_clean(chart_path_join(gx_file_picker_download_dir(), stem));
                gx_fs_mkdirs(download_path);
                download_url = gx_fs_url("/unpack", target);
                downloading = true;
                api_fetch_json = false;
                api_job = "unpack";
                api_unpack_files = [];
                api_unpack_index = 0;
                last_error = "";
                status_text = lang("picker.unpacking");
                download_id = gx_fs_request_unpack(target);
                if (download_id < 0) {
                        downloading = false;
                        api_job = "";
                        last_error = "Failed to start local API unpack.";
                        status_text = last_error;
                };
                return;
        };
        if (gx_file_picker_is_package(target)) {
                if (!file_exists(target)) {
                        last_error = "Package not found in the GX sandbox.";
                        status_text = last_error;
                        return;
                };
                gx_fp_finish_ok(target);
                return;
        };
        if (directory_exists(target)) {
                gx_fp_finish_ok(target);
                return;
        };
        last_error = "Not a .zip / .pez package or folder.";
        status_text = last_error;
}

function gx_fp_activate_selected() {
        if (selected < 0 || selected >= array_length(items)) then return;
        var item = items[selected];
        if (item.is_dir) {
                gx_fp_set_directory(item.path);
        } else {
                gx_fp_confirm_local(item.path);
        };
}

function gx_fp_go_up() {
        if (variable_instance_exists(id, "api_mode") && api_mode) {
                if (string_length(api_parent) && api_parent != current_dir) {
                        gx_fp_set_directory(api_parent);
                };
                return;
        };
        var parent = gx_file_picker_parent(current_dir);
        if (string_length(parent) && parent != current_dir) {
                gx_fp_set_directory(parent);
        };
}

function gx_fp_start_download(url) {
        var remote = string_trim(string(url));
        if (!gx_file_picker_is_url(remote)) {
                last_error = "URL must start with http:// or https://";
                status_text = last_error;
                return;
        };
        if (string_length(remote) > 2048) {
                last_error = "URL is too long.";
                status_text = last_error;
                return;
        };
        var dest_dir = gx_file_picker_download_dir();
        var dest_name = gx_file_picker_url_filename(remote);
        var dest = chart_path_join(dest_dir, dest_name);
        if (file_exists(dest)) {
                try { file_delete(dest); } catch (del_error) { delete(del_error); };
        };
        downloading = true;
        download_url = remote;
        download_path = dest;
        download_got = 0;
        download_total = 0;
        last_error = "";
        status_text = lang("picker.downloading");
        download_id = http_get_file(remote, dest);
        if (download_id < 0) {
                downloading = false;
                last_error = "Failed to start download.";
                status_text = last_error;
        };
}

function gx_fp_submit_field() {
        gx_fp_sync_url_field();
        var text = string_trim(url_text);
        if (!string_length(text)) {
                last_error = "Paste a package URL or sandbox path.";
                status_text = last_error;
                return;
        };
        if (gx_file_picker_is_url(text)) {
                gx_fp_start_download(text);
                return;
        };
        if (variable_instance_exists(id, "api_mode") && api_mode) {
                if (gx_file_picker_is_package(text)) {
                        gx_fp_confirm_local(text);
                } else if (string_pos("\\", text) > 0 || string_pos("/", text) > 0 || string_pos(":", text) > 0) {
                        gx_fp_set_directory(text);
                } else {
                        status_text = lang("picker.searching");
                        api_list_id = gx_fs_request_search(current_dir, text);
                };
                return;
        };
        gx_fp_confirm_local(text);
}

function gx_fp_paste_clipboard() {
        try {
                var pasted = clipboard_get_text();
                if (is_string(pasted) && string_length(pasted)) {
                        url_text += pasted;
                        if (focus_url) then keyboard_string = url_text;
                        status_text = lang("picker.pasted");
                        last_error = "";
                };
        } catch (paste_error) {
                delete(paste_error);
                last_error = "Clipboard paste is unavailable.";
                status_text = last_error;
        };
}

function gx_fp_draw_button(box, hot, enabled = true) {
        var fill = hot ? make_colour_rgb(70, 110, 180) : make_colour_rgb(40, 48, 64);
        if (!enabled) then fill = make_colour_rgb(28, 32, 40);
        draw_set_alpha(enabled ? 1 : 0.55);
        draw_set_colour(fill);
        draw_rectangle(box.x, box.y, box.x + box.w, box.y + box.h, false);
        draw_set_colour(c_white);
        draw_rectangle(box.x, box.y, box.x + box.w, box.y + box.h, true);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text_transformed(box.x + box.w * 0.5, box.y + box.h * 0.5, box.label, 0.42 * layout_s, 0.42 * layout_s, 0);
        draw_set_alpha(1);
}

function gx_audio_mime(path) {
        switch (chart_path_ext(path)) {
                case ".ogg":
                case ".oga":
                case ".opus": return "audio/ogg";
                case ".mp3": return "audio/mpeg";
                case ".wav":
                case ".wave": return "audio/wav";
                case ".flac": return "audio/flac";
                case ".m4a": return "audio/mp4";
                case ".aac": return "audio/aac";
                default: return "application/octet-stream";
        };
}

function gx_video_mime(path) {
        switch (chart_path_ext(path)) {
                case ".webm": return "video/webm";
                case ".mov": return "video/quicktime";
                case ".ogv": return "video/ogg";
                case ".mkv": return "video/x-matroska";
                default: return "video/mp4";
        };
}

function gx_video_js_real(value, fallback = 0) {
        if (is_real(value) && is_finite(value)) then return value;
        return fallback;
}

function gx_video_rpc_real(op) {
        var cmd = "pls-v:" + string(op);
        for (var i = 1; i < argument_count; i++) {
                cmd += "\t" + string(argument[i]);
        };
        var n = 0;
        try { n = real(i_gx_drop_import(cmd)); } catch (rpc_error) { delete(rpc_error); n = 0; };
        return gx_video_js_real(n, 0);
}

function gx_video_rpc_enabled() {
        return (variable_global_exists("gx_video_rpc") && global.gx_video_rpc);
}

function gx_video_available() {
        if (!pls_is_gxgames()) then return false;
        var ver = "";
        var rpc = 0;
        var native = 0;
        try { ver = string(i_gx_query_get("pls-v:ver")); } catch (ver_error) { delete(ver_error); ver = ""; };
        try { rpc = real(i_gx_drop_import("pls-v:ping")); } catch (rpc_error) { delete(rpc_error); rpc = 0; };
        try { native = real(i_gx_video_ping()); } catch (ping_error) { delete(ping_error); native = 0; };
        if (!variable_global_exists("gx_video_probe_logged") || !global.gx_video_probe_logged) {
                print($"[GXVideo] ver={ver} rpc={gx_video_js_real(rpc, 0)} native={gx_video_js_real(native, 0)}");
                global.gx_video_probe_logged = true;
        };
        if (is_real(rpc) && rpc > 0) {
                global.gx_video_rpc = true;
                return true;
        };
        if (is_real(native) && native > 0) {
                global.gx_video_rpc = false;
                return true;
        };
        return false;
}

function gx_video_js_create(url) {
        if (!pls_is_gxgames() || !is_string(url) || !string_length(url)) then return -1;
        if (gx_video_rpc_enabled()) {
                var rpc_handle = gx_video_rpc_real("create", url);
                return (rpc_handle > 0) ? rpc_handle : -1;
        };
        var handle = 0;
        try { handle = real(i_gx_video_create(url)); } catch (js_error) { delete(js_error); handle = 0; };
        if (is_real(handle) && handle > 0) then return handle;
        var fallback = gx_video_rpc_real("create", url);
        return (fallback > 0) ? fallback : -1;
}

function gx_video_js_from_file(path) {
        if (!pls_is_gxgames() || !is_string(path) || !file_exists(path)) then return -1;
        var buf = -1;
        try { buf = buffer_load(path); } catch (load_error) { delete(load_error); return -1; };
        if (!buffer_exists(buf)) then return -1;
        var size = buffer_get_size(buf);
        if (size <= 0 || size > 24 * 1024 * 1024) {
                buffer_delete(buf);
                return -1;
        };
        var handle = gx_video_rpc_enabled() ? gx_video_rpc_real("begin", gx_video_mime(path)) : 0;
        if (!(handle > 0)) {
                try { handle = real(i_gx_video_begin(gx_video_mime(path))); } catch (begin_error) { delete(begin_error); handle = 0; };
        };
        if (!(is_real(handle) && handle > 0)) {
                handle = gx_video_rpc_real("begin", gx_video_mime(path));
        };
        if (!(is_real(handle) && handle > 0)) {
                buffer_delete(buf);
                return -1;
        };
        var pos = 0;
        var chunk = 98304;
        var ok = true;
        while (pos < size) {
                var n = min(chunk, size - pos);
                var b64 = buffer_base64_encode(buf, pos, n);
                var appended = gx_video_rpc_enabled() ? gx_video_rpc_real("append", handle, b64) : 0;
                if (!(appended > 0)) {
                        try { appended = real(i_gx_video_append(handle, b64)); } catch (append_error) { delete(append_error); appended = 0; };
                };
                if (appended <= 0) {
                        ok = false;
                        break;
                };
                pos += n;
        };
        buffer_delete(buf);
        var done = 0;
        if (ok) {
                done = gx_video_rpc_enabled() ? gx_video_rpc_real("end", handle) : 0;
                if (!(done > 0)) {
                        try { done = real(i_gx_video_end(handle)); } catch (end_error) { delete(end_error); done = 0; };
                };
        };
        if (!ok || done <= 0) {
                gx_video_close(handle);
                return -1;
        };
        return handle;
}

function gx_video_open(path) {
        if (!pls_is_gxgames()) then return -1;
        var host = gx_media_host_path_for(path);
        if (string_length(host)) {
                print($"[GXVideo] open stream host={host} rpc={gx_video_rpc_enabled() ? 1 : 0}");
                var streamed = gx_video_js_create(gx_fs_media_url(host));
                if (streamed > 0) then return streamed;
                print($"[GXVideo] stream create failed: {gx_video_last_error()}");
        };
        if (is_string(path) && (string_pos("http://", path) == 1 || string_pos("https://", path) == 1 || string_pos("blob:", path) == 1)) {
                var remote = gx_video_js_create(path);
                if (remote > 0) then return remote;
        };
        if (file_exists(path)) {
                var local = gx_video_js_from_file(path);
                if (local > 0) then return local;
        };
        return -1;
}

function gx_video_close(handle) {
        if (!(is_real(handle) && handle > 0)) then return 0;
        if (gx_video_rpc_enabled()) then return gx_video_rpc_real("rel", handle);
        try { return gx_video_js_real(i_gx_video_release(handle), 0); } catch (close_error) { delete(close_error); return gx_video_rpc_real("rel", handle); };
}

function gx_video_shutdown() {
        if (!pls_is_gxgames()) then return 0;
        return gx_video_rpc_real("wipe");
}

function gx_video_play(handle) {
        if (!(is_real(handle) && handle > 0)) then return 0;
        if (gx_video_rpc_enabled()) then return gx_video_rpc_real("play", handle);
        try { return gx_video_js_real(i_gx_video_play(handle), 0); } catch (play_error) { delete(play_error); return gx_video_rpc_real("play", handle); };
}

function gx_video_pause(handle) {
        if (!(is_real(handle) && handle > 0)) then return 0;
        if (gx_video_rpc_enabled()) then return gx_video_rpc_real("pause", handle);
        try { return gx_video_js_real(i_gx_video_pause(handle), 0); } catch (pause_error) { delete(pause_error); return gx_video_rpc_real("pause", handle); };
}

function gx_video_seek(handle, ms) {
        if (!(is_real(handle) && handle > 0)) then return 0;
        if (gx_video_rpc_enabled()) then return gx_video_rpc_real("seek", handle, max(0, real(ms)));
        try { return gx_video_js_real(i_gx_video_seek_ms(handle, max(0, real(ms))), 0); } catch (seek_error) { delete(seek_error); return gx_video_rpc_real("seek", handle, max(0, real(ms))); };
}

function gx_video_set_loop(handle, enabled) {
        if (!(is_real(handle) && handle > 0)) then return 0;
        if (gx_video_rpc_enabled()) then return gx_video_rpc_real("loop", handle, enabled ? 1 : 0);
        try { return gx_video_js_real(i_gx_video_set_loop(handle, enabled ? 1 : 0), 0); } catch (loop_error) { delete(loop_error); return gx_video_rpc_real("loop", handle, enabled ? 1 : 0); };
}

function gx_video_get_status(handle) {
        if (!(is_real(handle) && handle > 0)) then return 0;
        if (gx_video_rpc_enabled()) then return gx_video_rpc_real("st", handle);
        try { return gx_video_js_real(i_gx_video_get_status(handle), 0); } catch (status_error) { delete(status_error); return gx_video_rpc_real("st", handle); };
}

function gx_video_get_length_ms(handle) {
        if (!(is_real(handle) && handle > 0)) then return 0;
        if (gx_video_rpc_enabled()) then return gx_video_rpc_real("len", handle);
        try { return gx_video_js_real(i_gx_video_get_length_ms(handle), 0); } catch (len_error) { delete(len_error); return gx_video_rpc_real("len", handle); };
}

function gx_video_get_position_ms(handle) {
        if (!(is_real(handle) && handle > 0)) then return 0;
        if (gx_video_rpc_enabled()) then return gx_video_rpc_real("pos", handle);
        try { return gx_video_js_real(i_gx_video_get_position_ms(handle), 0); } catch (pos_error) { delete(pos_error); return gx_video_rpc_real("pos", handle); };
}

function gx_video_get_width(handle) {
        if (!(is_real(handle) && handle > 0)) then return 0;
        if (gx_video_rpc_enabled()) then return gx_video_rpc_real("w", handle);
        try { return gx_video_js_real(i_gx_video_get_width(handle), 0); } catch (w_error) { delete(w_error); return gx_video_rpc_real("w", handle); };
}

function gx_video_get_height(handle) {
        if (!(is_real(handle) && handle > 0)) then return 0;
        if (gx_video_rpc_enabled()) then return gx_video_rpc_real("h", handle);
        try { return gx_video_js_real(i_gx_video_get_height(handle), 0); } catch (h_error) { delete(h_error); return gx_video_rpc_real("h", handle); };
}

function gx_video_draw(handle, left, top, right, bottom, alpha, dim) {
        if (!(is_real(handle) && handle > 0)) then return 0;
        try { draw_flush(); } catch (flush_error) { delete(flush_error); };
        if (gx_video_rpc_enabled()) {
                return gx_video_rpc_real("draw", handle, left, top, right, bottom, alpha, dim);
        };
        try {
                return gx_video_js_real(i_gx_video_draw(handle, left, top, right, bottom, alpha, dim), 0);
        } catch (draw_error) {
                delete(draw_error);
                return gx_video_rpc_real("draw", handle, left, top, right, bottom, alpha, dim);
        };
}

function gx_video_last_error() {
        var rpc_err = "";
        try { rpc_err = string(i_gx_query_get("pls-v:err")); } catch (rpc_read) { delete(rpc_read); rpc_err = ""; };
        if (string_length(rpc_err)) then return rpc_err;
        try { return string(i_gx_video_last_error()); } catch (err_read) { delete(err_read); return ""; };
}

function gx_shader_js_real(value, fallback = 0) {
        if (is_real(value) && is_finite(value)) then return value;
        return fallback;
}

function gx_shader_rpc_real(op) {
        var cmd = "pls-s:" + string(op);
        for (var i = 1; i < argument_count; i++) {
                cmd += "\t" + string(argument[i]);
        };
        var n = 0;
        try { n = real(i_gx_drop_import(cmd)); } catch (rpc_error) { delete(rpc_error); n = 0; };
        return gx_shader_js_real(n, 0);
}

function gx_shader_available() {
        if (!pls_is_gxgames()) then return false;
        var ver = "";
        var rpc = 0;
        try { ver = string(i_gx_query_get("pls-s:ver")); } catch (ver_error) { delete(ver_error); ver = ""; };
        try { rpc = real(i_gx_drop_import("pls-s:ping")); } catch (rpc_error) { delete(rpc_error); rpc = 0; };
        if (!variable_global_exists("gx_shader_probe_logged") || !global.gx_shader_probe_logged) {
                print($"[GXShader] ver={ver} rpc={gx_shader_js_real(rpc, 0)}");
                global.gx_shader_probe_logged = true;
        };
        return (string_pos("gxshader", ver) == 1) && (gx_shader_js_real(rpc, 0) > 0);
}

function gx_shader_initialize() {
        return gx_shader_available() ? 3 : 0;
}

function gx_shader_state() {
        return gx_shader_available() ? 3 : 0;
}

function gx_shader_compile(_source, _source_name) {
        if (!pls_is_gxgames()) then return -1;
        var src = is_string(_source) ? _source : "";
        if (!string_length(src)) then return -1;
        var handle = gx_shader_rpc_real("begin", is_string(_source_name) ? _source_name : "external.fs");
        if (!(is_real(handle) && handle > 0)) then return -1;
        var buf = buffer_create(max(16, string_byte_length(src) + 4), buffer_grow, 1);
        buffer_write(buf, buffer_text, src);
        var size = buffer_tell(buf);
        var offset = 0;
        var chunk = 12000;
        var ok = true;
        while (offset < size) {
                var n = min(chunk, size - offset);
                var b64 = buffer_base64_encode(buf, offset, n);
                if (gx_shader_rpc_real("append", handle, b64) <= 0) {
                        ok = false;
                        break;
                };
                offset += n;
        };
        buffer_delete(buf);
        if (!ok) {
                gx_shader_rpc_real("rel", handle);
                return -1;
        };
        var compiled = gx_shader_rpc_real("end", handle);
        if (!(is_real(compiled) && compiled > 0)) {
                gx_shader_rpc_real("rel", handle);
                return -1;
        };
        return handle;
}

function gx_shader_set_uniform_component(_handle, _name, _component, _value) {
        if (!(is_real(_handle) && _handle > 0)) then return 0;
        return gx_shader_rpc_real("uni", _handle, _name, real(_component), real(_value));
}

function gx_shader_begin(_handle) {
        if (!(is_real(_handle) && _handle > 0)) then return 0;
        try { draw_flush(); } catch (flush_error) { delete(flush_error); };
        return gx_shader_rpc_real("cap", _handle);
}

function gx_shader_draw(_handle, _uv_left, _uv_top, _uv_right, _uv_bottom) {
        if (!(is_real(_handle) && _handle > 0)) then return 0;
        try { draw_flush(); } catch (flush_error) { delete(flush_error); };
        return gx_shader_rpc_real("draw", _handle, _uv_left, _uv_top, _uv_right, _uv_bottom);
}

function gx_shader_end() {
        return gx_shader_rpc_real("fin");
}

function gx_shader_release(_handle) {
        if (!(is_real(_handle) && _handle > 0)) then return 0;
        return gx_shader_rpc_real("rel", _handle);
}

function gx_shader_shutdown() {
        gx_shader_rpc_real("shut");
}

function gx_shader_target_width() {
        return gx_shader_rpc_real("tw");
}

function gx_shader_target_height() {
        return gx_shader_rpc_real("th");
}

function gx_shader_last_error() {
        var rpc_err = "";
        try { rpc_err = string(i_gx_query_get("pls-s:err")); } catch (rpc_read) { delete(rpc_read); rpc_err = ""; };
        if (string_length(rpc_err)) then return rpc_err;
        try { return string(i_gx_shader_last_error()); } catch (err_read) { delete(err_read); return ""; };
}

function gx_audio_js_create(url) {
        if (!pls_is_gxgames() || !is_string(url) || !string_length(url)) then return 0;
        var handle = 0;
        try {
                handle = real(i_gx_audio_create(url, 1));
        } catch (js_error) {
                delete(js_error);
                handle = 0;
        };
        if (!is_real(handle) || handle <= 0) then return 0;
        return handle;
}

function gx_audio_js_from_file(path) {
        if (!pls_is_gxgames() || !is_string(path) || !file_exists(path)) then return 0;
        var buf = -1;
        try {
                buf = buffer_load(path);
        } catch (load_error) {
                delete(load_error);
                return 0;
        };
        if (!buffer_exists(buf)) then return 0;
        var size = buffer_get_size(buf);
        if (size <= 0) {
                buffer_delete(buf);
                return 0;
        };
        var handle = 0;
        try {
                handle = real(i_gx_audio_begin(gx_audio_mime(path)));
        } catch (begin_error) {
                delete(begin_error);
                handle = 0;
        };
        if (!is_real(handle) || handle <= 0) {
                buffer_delete(buf);
                return 0;
        };
        var pos = 0;
        var chunk = 98304;
        var ok = true;
        while (pos < size) {
                var n = min(chunk, size - pos);
                var b64 = buffer_base64_encode(buf, pos, n);
                var appended = 0;
                try {
                        appended = real(i_gx_audio_append(handle, b64));
                } catch (append_error) {
                        delete(append_error);
                        appended = 0;
                };
                if (appended <= 0) {
                        ok = false;
                        break;
                };
                pos += n;
        };
        buffer_delete(buf);
        var done = 0;
        if (ok) {
                try {
                        done = real(i_gx_audio_end(handle));
                } catch (end_error) {
                        delete(end_error);
                        done = 0;
                };
        };
        if (!ok || done <= 0) {
                try { i_gx_audio_release(handle); } catch (rel_error) { delete(rel_error); };
                return 0;
        };
        return handle;
}

function gx_audio_try_stream(path) {
        if (!file_exists(path)) then return -1;
        var snd = -1;
        try {
                snd = audio_create_stream(path);
        } catch (stream_error) {
                delete(stream_error);
                return -1;
        };
        if (!audio_exists(snd)) then return -1;
        var len = 0;
        try {
                len = audio_sound_length(snd);
        } catch (len_error) {
                delete(len_error);
                len = 0;
        };
        if (!(is_real(len) && is_finite(len) && len > 0)) {
                try { audio_destroy_stream(snd); } catch (del_error) { delete(del_error); };
                return -1;
        };
        return snd;
}

function gx_audio_ascii_copy(src) {
        var dest = gx_path_clean(chart_path_join(chart_gm_cache_dir(), "gx_audio_" + gx_file_picker_safe_name(chart_path_file_name(src))));
        try {
                if (file_exists(dest)) then file_delete(dest);
                file_copy(src, dest);
        } catch (copy_error) {
                delete(copy_error);
                return "";
        };
        return file_exists(dest) ? dest : "";
}

function gx_audio_data_url(path) {
        if (!file_exists(path)) then return "";
        var buf = -1;
        try {
                buf = buffer_load(path);
        } catch (load_error) {
                delete(load_error);
                return "";
        };
        if (!buffer_exists(buf)) then return "";
        var size = buffer_get_size(buf);
        if (size <= 0 || size > 8 * 1024 * 1024) {
                buffer_delete(buf);
                return "";
        };
        var b64 = buffer_base64_encode(buf, 0, size);
        buffer_delete(buf);
        if (!is_string(b64) || !string_length(b64)) then return "";
        return "data:" + gx_audio_mime(path) + ";base64," + b64;
}

function gx_media_release(inst) {
        if (!instance_exists(inst)) then return;
        var kind = string(inst[$ "gx_audio_kind"] ?? "");
        if (kind == "js") {
                var h = real(inst[$ "gx_js_handle"] ?? 0);
                if (h > 0) {
                        try { i_gx_audio_stop(h); } catch (stop_error) { delete(stop_error); };
                        try { i_gx_audio_release(h); } catch (rel_error) { delete(rel_error); };
                };
                inst.gx_js_handle = 0;
        } else if (kind == "stream") {
                if (variable_instance_exists(inst, "gx_audio_inst") && inst.gx_audio_inst != -1) {
                        audio_stop_sound(inst.gx_audio_inst);
                        inst.gx_audio_inst = -1;
                };
                if (variable_instance_exists(inst, "gx_audio_asset") && inst.gx_audio_asset != -1) {
                        if (audio_exists(inst.gx_audio_asset)) then audio_destroy_stream(inst.gx_audio_asset);
                        inst.gx_audio_asset = -1;
                };
        } else if (kind == "buffer") {
                if (variable_instance_exists(inst, "gx_audio_inst") && inst.gx_audio_inst != -1) {
                        audio_stop_sound(inst.gx_audio_inst);
                        inst.gx_audio_inst = -1;
                };
                if (variable_instance_exists(inst, "gx_buffer_sound") && inst.gx_buffer_sound != -1) {
                        if (audio_exists(inst.gx_buffer_sound)) then audio_free_buffer_sound(inst.gx_buffer_sound);
                        inst.gx_buffer_sound = -1;
                };
                if (variable_instance_exists(inst, "gx_pcm_buffer") && buffer_exists(inst.gx_pcm_buffer)) {
                        buffer_delete(inst.gx_pcm_buffer);
                        inst.gx_pcm_buffer = -1;
                };
        };
        inst.gx_audio_kind = "";
}

function gx_media_apply_js(inst, handle, url) {
        inst.gx_audio_kind = "js";
        inst.gx_js_handle = handle;
        inst.gx_js_url = url;
        inst.gx_audio_asset = -1;
        inst.gx_audio_inst = -1;
        inst.use_stream = true;
        inst.position = 0;
        var ms = 0;
        try { ms = real(i_gx_audio_get_length_ms(handle)); } catch (len_error) { delete(len_error); ms = 0; };
        inst.length = max(0, ms) * 1000;
        // decodeAudioData / HTML Audio metadata is async. WAIT_MEDIA polls length.
        inst[$ "success"] = (ms > 0) ? true : undefined;
        if (ms > 0) then chart_media_on_length_ready(inst.length);
}

function gx_media_apply_stream(inst, snd) {
        inst.gx_audio_kind = "stream";
        inst.gx_audio_asset = snd;
        inst.gx_audio_inst = -1;
        inst.gx_js_handle = 0;
        inst.use_stream = true;
        inst.position = 0;
        inst.length = audio_sound_length(snd) * 1000000;
        inst[$ "success"] = true;
}

function gx_pcm_copy_kind(src, offset, bytes, kind) {
        if (!buffer_exists(src)) then return -1;
        var size = buffer_get_size(src);
        var off = max(0, floor(real(offset)));
        var len = (is_real(bytes) && bytes > 0) ? floor(bytes) : (size - off);
        if (len <= 0 || off + len > size) then return -1;
        if ((len mod 2) != 0) then len -= 1;
        if (len <= 0) then return -1;
        var dest = -1;
        try { dest = buffer_create(len, kind, 1); } catch (create_error) { delete(create_error); dest = -1; };
        if (!buffer_exists(dest)) then return -1;
        try {
                buffer_copy(src, off, len, dest, 0);
        } catch (copy_error) {
                delete(copy_error);
                buffer_delete(dest);
                return -1;
        };
        return dest;
}

function gx_media_create_buffer_sound(pcm, rate, channels) {
        if (!buffer_exists(pcm)) then return -1;
        var ch = (channels >= 2) ? audio_stereo : audio_mono;
        var len = buffer_get_size(pcm);
        var snd = -1;
        try {
                snd = audio_create_buffer_sound(pcm, buffer_s16, rate, 0, len, ch);
        } catch (pcm_error) {
                delete(pcm_error);
                snd = -1;
        };
        return audio_exists(snd) ? snd : -1;
}

function gx_media_apply_pcm(inst, buf, rate, channels, offset, bytes) {
        if (!buffer_exists(buf)) then return false;
        if (!(is_real(rate) && rate > 0) || !(is_real(channels) && channels > 0)) {
                buffer_delete(buf);
                return false;
        };
        var pcm = gx_pcm_copy_kind(buf, offset, bytes, buffer_fixed);
        if (!buffer_exists(pcm)) then pcm = gx_pcm_copy_kind(buf, offset, bytes, buffer_fast);
        buffer_delete(buf);
        if (!buffer_exists(pcm)) then return false;
        var snd = gx_media_create_buffer_sound(pcm, rate, channels);
        if (snd == -1) {
                var fast = gx_pcm_copy_kind(pcm, 0, buffer_get_size(pcm), buffer_fast);
                buffer_delete(pcm);
                pcm = fast;
                if (buffer_exists(pcm)) then snd = gx_media_create_buffer_sound(pcm, rate, channels);
        };
        if (snd == -1) {
                if (buffer_exists(pcm)) then buffer_delete(pcm);
                print("[L-Sound] GX PCM audio_create_buffer_sound failed.");
                return false;
        };
        gx_media_release(inst);
        inst.gx_audio_kind = "buffer";
        inst.gx_pcm_buffer = pcm;
        inst.gx_buffer_sound = snd;
        inst.gx_audio_asset = -1;
        inst.gx_audio_inst = -1;
        inst.gx_js_handle = 0;
        inst.gx_pcm_id = -1;
        inst.use_stream = true;
        inst.position = 0;
        var secs = 0;
        try { secs = audio_sound_length(snd); } catch (len_error) { delete(len_error); secs = 0; };
        if (!(is_real(secs) && secs > 0)) then secs = buffer_get_size(pcm) / (rate * channels * 2);
        inst.length = max(0, secs) * 1000000;
        inst[$ "success"] = true;
        chart_media_on_length_ready(inst.length);
        print("[L-Sound] GX PCM buffer rate=" + string(rate) + " ch=" + string(channels) + " bytes=" + string(buffer_get_size(pcm)));
        return true;
}

function gx_wav_try_local(inst, audio_path) {
        var ext = chart_path_ext(audio_path);
        if (ext != ".wav" && ext != ".wave") then return false;
        if (!file_exists(audio_path)) then return false;
        var buf = -1;
        try { buf = buffer_load(audio_path); } catch (load_error) { delete(load_error); return false; };
        if (!buffer_exists(buf) || buffer_get_size(buf) < 44) {
                if (buffer_exists(buf)) then buffer_delete(buf);
                return false;
        };
        buffer_seek(buf, buffer_seek_start, 0);
        var riff = buffer_read(buf, buffer_u32);
        buffer_read(buf, buffer_u32);
        var wave = buffer_read(buf, buffer_u32);
        if (riff != 0x46464952 || wave != 0x45564157) {
                buffer_delete(buf);
                return false;
        };
        var format = 0;
        var channels = 0;
        var rate = 0;
        var bits = 0;
        var data_off = -1;
        var data_len = 0;
        var size = buffer_get_size(buf);
        while (buffer_tell(buf) + 8 <= size) {
                var chunk_id = buffer_read(buf, buffer_u32);
                var chunk_sz = buffer_read(buf, buffer_u32);
                if (chunk_sz < 0) then break;
                var chunk_start = buffer_tell(buf);
                if (chunk_id == 0x20746D66) {
                        if (chunk_sz < 16 || chunk_start + 16 > size) then break;
                        format = buffer_read(buf, buffer_u16);
                        channels = buffer_read(buf, buffer_u16);
                        rate = buffer_read(buf, buffer_u32);
                        buffer_read(buf, buffer_u32);
                        buffer_read(buf, buffer_u16);
                        bits = buffer_read(buf, buffer_u16);
                        // WAVE_FORMAT_EXTENSIBLE: GUID at offset 24 of fmt payload.
                        if (format == 65534 && chunk_sz >= 40 && chunk_start + 40 <= size) {
                                buffer_seek(buf, buffer_seek_start, chunk_start + 24);
                                var sub = buffer_read(buf, buffer_u32);
                                if (sub == 1) then format = 1;
                        };
                } else if (chunk_id == 0x61746164) {
                        data_off = chunk_start;
                        data_len = chunk_sz;
                        if (data_off + data_len > size) then data_len = size - data_off;
                        break;
                };
                var next = chunk_start + chunk_sz;
                if ((chunk_sz mod 2) != 0) then next += 1;
                if (next > size) then break;
                buffer_seek(buf, buffer_seek_start, next);
        };
        if (format != 1 || bits != 16 || channels < 1 || rate <= 0 || data_off < 0 || data_len <= 0) {
                buffer_delete(buf);
                return false;
        };
        print("[L-Sound] GX local WAV PCM.");
        return gx_media_apply_pcm(inst, buf, rate, channels, data_off, data_len);
}

function gx_pcm_sidecar_path(audio_path) {
        var p = gx_path_clean(string(audio_path));
        if (!string_length(p)) then return "";
        if (string_lower(chart_path_ext(p)) == ".gxpcm") then return p;
        return p + ".gxpcm";
}

function gx_media_try_local_pcm(inst, audio_path) {
        var tries = [];
        array_add(tries, gx_pcm_sidecar_path(audio_path));
        var host = gx_media_host_path_for(audio_path);
        if (string_length(host)) then array_add(tries, gx_pcm_sidecar_path(host));
        for (var i = 0; i < array_length(tries); i++) {
                var sidecar = tries[i];
                if (!string_length(sidecar) || !file_exists(sidecar)) then continue;
                var buf = -1;
                try { buf = buffer_load(sidecar); } catch (load_error) { delete(load_error); buf = -1; };
                if (!buffer_exists(buf) || buffer_get_size(buf) < 16) {
                        if (buffer_exists(buf)) then buffer_delete(buf);
                        continue;
                };
                buffer_seek(buf, buffer_seek_start, 0);
                var magic = "";
                repeat (6) {
                        magic += chr(buffer_read(buf, buffer_u8));
                };
                if (magic != "GXPCM1") {
                        buffer_delete(buf);
                        continue;
                };
                var channels = buffer_read(buf, buffer_u16);
                var rate = buffer_read(buf, buffer_u32);
                var bytes = buffer_read(buf, buffer_u32);
                if (gx_media_apply_pcm(inst, buf, rate, channels, 16, bytes)) then return true;
        };
        return false;
}

function gx_media_apply_pcm_json(inst, raw) {
        try {
                var data = json_parse(raw);
                if (!is_struct(data) || !bool(data[$ "ok"] ?? false)) {
                        var err = is_struct(data) ? string(data[$ "error"] ?? "pcm failed") : "pcm json invalid";
                        print("[L-Sound] GX PCM json: " + err);
                        return false;
                };
                var b64 = string(data[$ "base64"] ?? "");
                if (!string_length(b64)) {
                        print("[L-Sound] GX PCM json empty.");
                        return false;
                };
                var buf = buffer_base64_decode(b64);
                if (!buffer_exists(buf)) {
                        print("[L-Sound] GX PCM base64 decode failed.");
                        return false;
                };
                var rate = real(data[$ "rate"] ?? 0);
                var channels = real(data[$ "channels"] ?? 0);
                var bytes = real(data[$ "bytes"] ?? buffer_get_size(buf));
                return gx_media_apply_pcm(inst, buf, rate, channels, 0, bytes);
        } catch (parse_error) {
                var msg = string(parse_error);
                delete(parse_error);
                print("[L-Sound] GX PCM parse failed: " + msg);
                return false;
        };
}

function gx_media_request_pcm(inst, audio_path) {
        var host = gx_media_host_path_for(audio_path);
        if (!string_length(host)) then return false;
        var req = gx_fs_request_pcm(host);
        if (!is_real(req) || req < 0) then return false;
        inst.gx_pcm_id = req;
        inst[$ "success"] = undefined;
        print("[L-Sound] GX PCM request started.");
        return true;
}

function gx_media_try_js_or_stream(inst, audio_path) {
        var js = 0;
        var ascii = file_exists(audio_path) ? gx_audio_ascii_copy(audio_path) : "";
        var load_path = (string_length(ascii) && file_exists(ascii)) ? ascii : audio_path;
        if (file_exists(load_path)) then js = gx_audio_js_from_file(load_path);
        if (js <= 0 && file_exists(load_path)) then js = gx_audio_js_create(load_path);
        if (js <= 0 && load_path != audio_path && file_exists(audio_path)) then js = gx_audio_js_from_file(audio_path);
        if (js <= 0 && file_exists(audio_path)) then js = gx_audio_js_create(audio_path);
        if (js <= 0) {
                var host = gx_media_host_path_for(audio_path);
                if (!string_length(host) && string_length(ascii)) then host = gx_media_host_path_for(ascii);
                if (string_length(host)) then js = gx_audio_js_create(gx_fs_media_url(host));
        };
        if (js <= 0 && file_exists(load_path)) {
                var data_url = gx_audio_data_url(load_path);
                if (string_length(data_url)) then js = gx_audio_js_create(data_url);
        };
        if (js > 0) {
                gx_media_apply_js(inst, js, load_path);
                print("[L-Sound] GX JS audio.");
                return true;
        };

        // GX sandbox files are not included-file streams. audio_create_stream
        // wget's them as ta///_savedata/... and 404s. Skip that fallback.
        return false;
}

function gx_audio_js_available() {
        var ping = 0;
        try { ping = real(i_gx_audio_ping()); } catch (ping_error) { delete(ping_error); ping = 0; };
        if (is_real(ping) && ping > 0) then return true;
        var handle = 0;
        try { handle = real(i_gx_audio_begin("audio/ogg")); } catch (begin_error) { delete(begin_error); return false; };
        if (!is_real(handle) || handle <= 0) then return false;
        try { i_gx_audio_release(handle); } catch (rel_error) { delete(rel_error); };
        return true;
}

function gx_media_load_from_path(inst, audio_path) {
        inst.gx_audio_kind = "";
        inst.gx_js_handle = 0;
        inst.gx_js_url = "";
        inst.gx_audio_asset = -1;
        inst.gx_audio_inst = -1;
        inst.gx_buffer_sound = -1;
        inst.gx_pcm_buffer = -1;
        inst.gx_pcm_id = -1;
        inst[$ "success"] = undefined;

        if (gx_media_try_local_pcm(inst, audio_path)) then return true;
        if (gx_wav_try_local(inst, audio_path)) then return true;
        if (gx_audio_js_available() && gx_media_try_js_or_stream(inst, audio_path)) then return true;
        if (gx_media_request_pcm(inst, audio_path)) then return true;
        if (gx_media_try_js_or_stream(inst, audio_path)) then return true;

        var js_err = "";
        try { js_err = string(i_gx_audio_last_error()); } catch (err_read) { delete(err_read); js_err = ""; };
        print("[L-Sound] Failed. path=" + string(audio_path) + (string_length(js_err) ? (" JS: " + js_err) : ""));
        inst[$ "success"] = false;
        return false;
}
