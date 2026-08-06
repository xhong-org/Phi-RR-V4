/// @desc Chart loading session + menu/play pipeline helpers

enum CHART_FORMAT {
        UNKNOWN = 0,
        OFFICIAL = 1,
        RPE = 2,
        PEC = 3
};

function chart_session_default() {
        return {
                "source_path" : "",
                "extract_dir" : "",
                "active_dir" : "",
                "format" : CHART_FORMAT.UNKNOWN,
                "format_name" : "unknown",
                "chart_file" : "",
                "music_file" : "",
                "image_file" : "",
                "line_file" : "",
                "line_overrides" : [],
                "extra_file" : "",
                "info_offset_ms" : 0,
                "name" : "",
                "level" : "",
                "play_room" : -1,
                "ready" : false,
                "from_zip" : false,
                "status" : "Idle",
                "detail" : "",
                "error" : "",
                "files" : undefined
        };
}

function chart_session_ensure() {
        if (!variable_global_exists("chart_session") || !is_struct(global.chart_session)) {
                global.chart_session = chart_session_default();
        };
        if (!variable_global_exists("chart_active_path") || !is_string(global.chart_active_path) || !string_length(global.chart_active_path)) {
                global.chart_active_path = (working_directory + "chart/");
        };
        return global.chart_session;
}

function chart_session_reset() {
        global.chart_session = chart_session_default();
        global.chart_active_path = (working_directory + "chart/");
        return global.chart_session;
}

function chart_session_set_status(status_text, detail_text = "") {
        var session = chart_session_ensure();
        session.status = status_text;
        session.detail = detail_text;
        print($"[ChartSession] {status_text} {detail_text}");
}

function chart_session_cleanup(full_reset = true) {
        var session = chart_session_ensure();
        var extract_dir = "";
        if (is_struct(session)) {
                extract_dir = string(session.extract_dir);
                // Also clean default unzip target when package load failed mid-way.
                if (!string_length(extract_dir) && session.from_zip) {
                        extract_dir = chart_path_norm(game_save_id + "track/");
                };
        };

        if (string_length(extract_dir) && directory_exists(extract_dir)) {
                directory_destroy(extract_dir);
                print($"[ChartSession] Cleaned extract dir: {extract_dir}");
        };

        // Always wipe default track cache on cleanup.
        var track_path = chart_path_norm(game_save_id + "track/");
        if (directory_exists(track_path)) {
                directory_destroy(track_path);
        };

        if (full_reset) {
                global.chart_session = chart_session_default();
                global.chart_active_path = (working_directory + "chart/");
        } else if (is_struct(session)) {
                session.extract_dir = "";
                session.active_dir = "";
                session.files = undefined;
                session.ready = false;
        };
        return true;
}

function chart_session_fail(message, cleanup = true) {
        var session = chart_session_ensure();
        session.ready = false;
        session.error = message;
        session.status = "Failed";
        session.detail = message;
        session.format = CHART_FORMAT.UNKNOWN;
        session.format_name = "unknown";
        session.chart_file = "";
        session.music_file = "";
        session.image_file = "";
        session.name = "";
        session.level = "";
        session.play_room = -1;
        print($"[ChartSession][Error] {message}");
        if (cleanup) then chart_session_cleanup(true);
        return false;
}

function chart_session_has_track() {
        var session = chart_session_ensure();
        return (session.ready && string_length(session.chart_file) > 0 && session.format != CHART_FORMAT.UNKNOWN);
}

function chart_path_norm(path) {
        var p = string(path);
        p = string_replace_all(p, "\\", "/");
        return p;
}

function chart_path_join(base_path, child_name) {
        var base = chart_path_norm(base_path);
        var child = string_replace_all(string(child_name), "\\", "/");
        while (string_length(child) > 0 && string_char_at(child, 1) == "/") {
                child = string_delete(child, 1, 1);
        };
        if (!string_length(base)) then return child;
        var last = string_char_at(base, string_length(base));
        if (last != "/") then base += "/";
        return base + child;
}

function chart_path_ext(path) {
        var p = chart_path_norm(path);
        var point = string_last_pos(".", p);
        if (point <= 0) then return "";
        return string_lower(string_copy(p, point, string_length(p) - point + 1));
}

function chart_path_file_name(path) {
        var p = chart_path_norm(path);
        var slash = max(string_last_pos("/", p), string_last_pos("\\", p));
        if (slash <= 0) then return p;
        return string_copy(p, slash + 1, string_length(p) - slash);
}

function chart_path_dir(path) {
        var p = chart_path_norm(path);
        var slash = string_last_pos("/", p);
        if (slash <= 0) then return "";
        return string_copy(p, 1, slash);
}

function chart_find_sidecar(files, file_name, chart_path) {
        if (!is_array(files)) then return "";
        var wanted = string_lower(file_name);
        var chart_dir = string_lower(chart_path_dir(chart_path));
        var fallback = "";
        for (var i = 0; i < array_length(files); i++) {
                var path = files[i];
                if (string_lower(chart_path_file_name(path)) != wanted) then continue;
                if (string_lower(chart_path_dir(path)) == chart_dir) then return path;
                if (!string_length(fallback)) then fallback = path;
        };
        return fallback;
}

function chart_load_line_overrides(line_path, chart_path, root_dir) {
        var result = [];
        if (!file_exists(line_path)) then return result;
        var grid = load_csv(line_path);
        if (!ds_exists(grid, ds_type_grid)) then return result;
        var rows = ds_grid_to_struct_array(grid);
        ds_grid_destroy(grid);
        if (!is_array(rows)) then return result;

        var chart_name = string_lower(chart_path_file_name(chart_path));
        var line_dir = chart_path_dir(line_path);
        for (var i = 0; i < array_length(rows); i++) {
                var row = rows[i];
                if (!is_struct(row) || is_undefined(row[$ "LineId"]) || is_undefined(row[$ "Image"])) then continue;
                var row_chart = string_lower(chart_path_file_name(string(row[$ "Chart"] ?? "")));
                if (string_length(row_chart) && row_chart != chart_name) then continue;
                var image_name = chart_path_norm(string(row.Image));
                var image_full = chart_path_join(line_dir, image_name);
                if (!file_exists(image_full)) then image_full = chart_path_join(root_dir, image_name);
                array_add(result, {
                        LineId: floor(real(row.LineId)),
                        Image: chart_path_rel(root_dir, image_full),
                        Scale: real(row[$ "Scale"] ?? 1)
                });
        };
        return result;
}

function chart_line_override(line_id) {
        var session = chart_session_ensure();
        if (!is_array(session.line_overrides)) then return undefined;
        for (var i = array_length(session.line_overrides) - 1; i >= 0; i--) {
                if (session.line_overrides[i].LineId == line_id) then return session.line_overrides[i];
        };
        return undefined;
}

function chart_line_override_sprite(line_id) {
        var row = chart_line_override(line_id);
        if (!is_struct(row)) then return -1;
        var key = "line_csv_" + string(line_id);
        if (struct_exists(game.TextureGroup, key) && sprite_exists(game.TextureGroup[$ key])) {
                return game.TextureGroup[$ key];
        };
        var sprite = sprite_add(chart_path_join(InChartPath, row.Image), 0, false, false, 0, 0);
        if (!sprite_exists(sprite)) then return -1;
        sprite_set_offset(sprite, sprite_get_width(sprite) / 2, sprite_get_height(sprite) / 2);
        game.TextureGroup[$ key] = sprite;
        return sprite;
}

function chart_extra_offset_seconds() {
        var session = chart_session_ensure();
        switch (session.format) {
                case CHART_FORMAT.RPE:
                        if (variable_global_exists("game_1") && is_struct(game_1) && is_struct(game_1.chart_info)) {
                                return real(game_1.chart_info.offset ?? 0) / 1000;
                        };
                break;
                case CHART_FORMAT.PEC:
                        if (variable_global_exists("game_2") && is_struct(game_2) && is_struct(game_2.chart)) {
                                return real(game_2.chart.offsetSeconds ?? 0);
                        };
                break;
                case CHART_FORMAT.OFFICIAL:
                        if (variable_global_exists("game") && is_struct(game) && is_struct(game.chart)) {
                                return real(game.chart.offset ?? 0);
                        };
                break;
        };
        return 0;
}

function chart_extra_asset_path(relative_path) {
        var session = chart_session_ensure();
        var root = InChartPath;
        if (is_string(session.extra_file) && string_length(session.extra_file)) {
                root = chart_path_dir(chart_path_join(InChartPath, session.extra_file));
        };
        return chart_path_join(root, relative_path);
}

function chart_path_rel(base_dir, full_path) {
        var base = chart_path_norm(base_dir);
        var full = chart_path_norm(full_path);
        if (string_length(base) && string_char_at(base, string_length(base)) != "/") then base += "/";
        if (string_pos(string_lower(base), string_lower(full)) == 1) {
                return string_copy(full, string_length(base) + 1, string_length(full) - string_length(base));
        };
        return chart_path_file_name(full);
}

function chart_session_bind_paths() {
        var session = chart_session_ensure();
        if (string_length(session.active_dir)) {
                global.chart_active_path = session.active_dir;
        } else {
                global.chart_active_path = (working_directory + "chart/");
        };
        if (string_length(global.chart_active_path) && string_char_at(global.chart_active_path, string_length(global.chart_active_path)) != "/") {
                global.chart_active_path += "/";
        };
        return global.chart_active_path;
}

function chart_session_apply_folder(_game) {
        if (!is_struct(_game)) then return false;
        if (!chart_session_has_track()) then return false;
        var session = global.chart_session;
        _game.folder_chart.name = session.name;
        _game.folder_chart.level = session.level;
        _game.folder_chart.chart = session.chart_file;
        _game.folder_chart.music = session.music_file;
        _game.folder_chart.bg = session.image_file;
        return true;
}

function chart_session_play_room_for(format_id) {
        switch (format_id) {
                case CHART_FORMAT.OFFICIAL: return room_play_official;
                case CHART_FORMAT.RPE: return room_play_rpe;
                case CHART_FORMAT.PEC: return room_play_pec;
        };
        return -1;
}

function chart_session_format_name(format_id) {
        switch (format_id) {
                case CHART_FORMAT.OFFICIAL: return "Official";
                case CHART_FORMAT.RPE: return "RPE";
                case CHART_FORMAT.PEC: return "PEC";
        };
        return "unknown";
}

function chart_read_text_file(path, max_chars = 200000) {
        if (!file_exists(path)) then return "";
        var buff = buffer_load(path);
        if (buff < 0) then return "";
        var text = buffer_read(buff, buffer_text);
        if (!is_string(text)) {
                buffer_seek(buff, buffer_seek_start, 0);
                text = buffer_read(buff, buffer_string);
        };
        buffer_delete(buff);
        if (!is_string(text)) then return "";
        if (string_length(text) > max_chars) then text = string_copy(text, 1, max_chars);
        return text;
}

function chart_detect_format(chart_path) {
        if (!file_exists(chart_path)) then return CHART_FORMAT.UNKNOWN;
        var ext = chart_path_ext(chart_path);
        if (ext == ".pec") then return CHART_FORMAT.PEC;

        if (ext == ".json" || ext == ".txt") {
                var text = chart_read_text_file(chart_path, 120000);
                if (!string_length(text)) then return CHART_FORMAT.UNKNOWN;

                if (string_pos("\"RPEVersion\"", text) > 0) {
                        return CHART_FORMAT.RPE;
                };

                if (string_pos("\"formatVersion\"", text) > 0 && string_pos("\"judgeLineList\"", text) > 0) {
                        return CHART_FORMAT.OFFICIAL;
                };

                if (string_pos("\"META\"", text) > 0 && string_pos("eventLayers", text) > 0) {
                        return CHART_FORMAT.RPE;
                };

                var lower = string_lower(text);
                if (string_pos("\nbp ", lower) > 0 || string_pos("\nn1 ", lower) > 0 || string_pos("\nn2 ", lower) > 0 || string_pos("\ncv ", lower) > 0) {
                        return CHART_FORMAT.PEC;
                };

                try {
                        var parsed = json_parse(text);
                        if (is_struct(parsed)) {
                                if (struct_exists(parsed, "META") && is_struct(parsed.META) && struct_exists(parsed.META, "RPEVersion")) {
                                        return CHART_FORMAT.RPE;
                                };
                                if (struct_exists(parsed, "formatVersion") && struct_exists(parsed, "judgeLineList")) {
                                        return CHART_FORMAT.OFFICIAL;
                                };
                        };
                } catch (e) {
                        delete(e);
                };
        };

        var head = string_lower(chart_read_text_file(chart_path, 4000));
        if (string_pos("bp ", head) > 0 || string_pos("n1 ", head) > 0) then return CHART_FORMAT.PEC;
        return CHART_FORMAT.UNKNOWN;
}

function chart_pick_best(list, preferred_name, base_dir = "") {
        if (!is_array(list) || array_length(list) <= 0) then return "";

        // Prefer info.txt path only when the file really exists.
        if (string_length(preferred_name)) {
                var prefer = string_replace_all(string(preferred_name), "\\", "/");
                while (string_length(prefer) > 0 && string_char_at(prefer, 1) == "/") {
                        prefer = string_delete(prefer, 1, 1);
                };

                if (string_length(base_dir)) {
                        var preferred_full = chart_path_join(base_dir, prefer);
                        if (file_exists(preferred_full)) then return preferred_full;
                };
                if (file_exists(prefer)) then return prefer;

                var prefer_lower = string_lower(chart_path_file_name(prefer));
                for (var i = 0; i < array_length(list); i++) {
                        var item = list[i];
                        if (string_lower(chart_path_file_name(item)) == prefer_lower) {
                                if (file_exists(item)) then return item;
                        };
                };
                // Preferred name is incomplete / wrong: fall through to directory scan.
        };

        for (var j = 0; j < array_length(list); j++) {
                if (file_exists(list[j])) then return list[j];
        };
        return "";
}

function chart_info_trim_value(val) {
        var v = string(val);
        v = string_replace_all(v, "\r", "");
        v = string_replace_all(v, "\n", "");
        while (string_length(v) > 0 && (string_char_at(v, 1) == " " || string_char_at(v, 1) == "\t")) {
                v = string_delete(v, 1, 1);
        };
        while (string_length(v) > 0) {
                var last = string_char_at(v, string_length(v));
                if (last == " " || last == "\t") then v = string_delete(v, string_length(v), 1);
                else break;
        };
        // Strip simple YAML/JSON quotes and null-ish values.
        if (string_length(v) >= 2) {
                var a = string_char_at(v, 1);
                var b = string_char_at(v, string_length(v));
                if ((a == "\"" && b == "\"") || (a == "'" && b == "'")) {
                        v = string_copy(v, 2, string_length(v) - 2);
                };
        };
        var lower = string_lower(v);
        if (lower == "null" || lower == "~" || lower == "none") then return "";
        return v;
}

/// @desc Parse root-only info.txt / info.yml style metadata.
function chart_parse_info_file(info_path) {
        var info = {
                "name" : "",
                "level" : "",
                "image" : "",
                "music" : "",
                "chart" : "",
                "offset_ms" : 0
        };
        if (!file_exists(info_path)) then return info;

        var handle = file_text_open_read(info_path);
        if (handle < 0) then return info;
        while (!file_text_eof(handle)) {
                var text_ln = file_text_readln(handle);
                text_ln = string_replace_all(text_ln, "\r", "");
                text_ln = string_replace_all(text_ln, "\n", "");
                if (!string_length(text_ln)) then continue;

                // Skip YAML multi-line block markers / comments.
                var first = string_char_at(text_ln, 1);
                if (first == "#" || first == "-" || first == " " || first == "\t") then continue;

                var sep = string_pos(":", text_ln);
                if (sep <= 0) then sep = string_pos("=", text_ln);
                if (sep <= 0) then continue;

                var key = string_lower(string_replace_all(string_copy(text_ln, 1, sep - 1), " ", ""));
                key = string_replace_all(key, "\t", "");
                var val = chart_info_trim_value(string_copy(text_ln, sep + 1, string_length(text_ln) - sep));
                if (!string_length(val)) then continue;

                // info.txt: Name/Song/Picture/Chart/Level
                // info.yml: name/music/illustration/chart/level/difficulty
                switch (key) {
                        case "name":
                        case "title":
                                info.name = val;
                        break;
                        case "level":
                                info.level = val;
                        break;
                        case "difficulty":
                                // Prefer explicit level; difficulty is fallback only.
                                if (!string_length(info.level)) then info.level = val;
                        break;
                        case "image":
                        case "illustration":
                        case "background":
                        case "bg":
                        case "picture":
                                info.image = val;
                        break;
                        case "music":
                        case "song":
                        case "songfile":
                        case "audio":
                                info.music = val;
                        break;
                        case "chart":
                        case "track":
                        case "chartfile":
                                info.chart = val;
                        break;
                        case "offset":
                                info.offset_ms = number(val, 0);
                        break;
                };
        };
        file_text_close(handle);
        return info;
}

/// @desc info.txt / info.yml are valid only in package root.
function chart_load_root_info(root_dir) {
        var info = {
                "name" : "",
                "level" : "",
                "image" : "",
                "music" : "",
                "chart" : "",
                "offset_ms" : 0
        };
        var root = chart_path_norm(root_dir);
        if (string_length(root) && string_char_at(root, string_length(root)) != "/") then root += "/";

        var txt = chart_path_join(root, "info.txt");
        if (file_exists(txt)) {
                return {
                        "info" : chart_parse_info_file(txt),
                        "has_info" : true,
                        "source" : "info.txt"
                };
        };

        var yml = chart_path_join(root, "info.yml");
        if (file_exists(yml)) {
                return {
                        "info" : chart_parse_info_file(yml),
                        "has_info" : true,
                        "source" : "info.yml"
                };
        };

        // Nested info.txt/yml discovered by scan are ignored on purpose.
        return {
                "info" : info,
                "has_info" : false,
                "source" : ""
        };
}

function chart_session_build_from_dir(dir_path, source_path = "", from_zip = false) {
        var session = chart_session_ensure();
        var root = chart_path_norm(dir_path);
        if (string_length(root) && string_char_at(root, string_length(root)) != "/") then root += "/";

        chart_session_set_status("Scanning files", root);
        if (!directory_exists(root) && !file_exists(root)) {
                return chart_session_fail("Track directory not found.");
        };

        var discovered = File_Discoverer(root);
        session.files = discovered;
        session.source_path = source_path;
        session.extract_dir = from_zip ? root : "";
        session.active_dir = root;
        session.from_zip = from_zip;
        global.chart_active_path = root;

        // Priority: root info.txt -> root info.yml -> pure directory scan.
        // Nested info.* found while scanning are ignored.
        chart_session_set_status("Reading metadata", "root info.txt / info.yml only");
        var info_pack = chart_load_root_info(root);
        var info = info_pack.info;
        var has_info = info_pack.has_info;
        var info_source = info_pack.source;

        chart_session_set_status(
                "Selecting assets",
                has_info ? (info_source + " + directory scan") : "directory scan only"
        );
        var chart_full = chart_pick_best(discovered.chart, info.chart, root);
        var music_full = chart_pick_best(discovered.music, info.music, root);
        var image_full = chart_pick_best(discovered.image, info.image, root);
        // If info image is wrong/missing, try matching chart stem (e.g. 57649733.json -> 57649733.png)
        if (!string_length(image_full) && string_length(chart_full) && is_array(discovered.image)) {
                var chart_stem = string_lower(chart_path_file_name(chart_full));
                var dot = string_last_pos(".", chart_stem);
                if (dot > 0) then chart_stem = string_copy(chart_stem, 1, dot - 1);
                for (var ii = 0; ii < array_length(discovered.image); ii++) {
                        var iname = string_lower(chart_path_file_name(discovered.image[ii]));
                        var idot = string_last_pos(".", iname);
                        var istem = (idot > 0) ? string_copy(iname, 1, idot - 1) : iname;
                        if (istem == chart_stem && file_exists(discovered.image[ii])) {
                                image_full = discovered.image[ii];
                                break;
                        };
                };
        };
        // Still none: choose the largest image file (usually the illustration, not UI icons)
        if (!string_length(image_full) && is_array(discovered.image) && array_length(discovered.image) > 0) {
                var best_img = "";
                var best_size = -1;
                for (var ij = 0; ij < array_length(discovered.image); ij++) {
                        var ip = discovered.image[ij];
                        if (!file_exists(ip)) then continue;
                        // skip tiny likely-icon names only as soft preference via size
                        var sz = 0;
                        // GML has no portable file_size; estimate via buffer
                        var _b = buffer_load(ip);
                        if (_b >= 0) {
                                sz = buffer_get_size(_b);
                                buffer_delete(_b);
                        };
                        if (sz > best_size) {
                                best_size = sz;
                                best_img = ip;
                        };
                };
                image_full = best_img;
        };

        // Chart + music are both required. Missing either => fail, cleanup, back to menu.
        if (!string_length(chart_full) || !string_length(music_full)) {
                var missing = [];
                if (!string_length(chart_full)) then array_push(missing, "chart");
                if (!string_length(music_full)) then array_push(missing, "music");
                var missing_text = "";
                for (var mi = 0; mi < array_length(missing); mi++) {
                        if (mi > 0) then missing_text += ", ";
                        missing_text += missing[mi];
                };
                return chart_session_fail("Missing required file(s): " + missing_text);
        };

        chart_session_set_status("Detecting format", chart_path_file_name(chart_full));
        var format_id = chart_detect_format(chart_full);
        if (format_id == CHART_FORMAT.UNKNOWN) {
                return chart_session_fail("Unsupported chart format.");
        };

        session.format = format_id;
        session.format_name = chart_session_format_name(format_id);
        session.chart_file = chart_path_rel(root, chart_full);
        session.music_file = chart_path_rel(root, music_full);
        session.image_file = string_length(image_full) ? chart_path_rel(root, image_full) : "";
        var sidecar_files = [];
        if (is_array(discovered.text)) {
                for (var sidecar_text_i = 0; sidecar_text_i < array_length(discovered.text); sidecar_text_i++) {
                        array_add(sidecar_files, discovered.text[sidecar_text_i]);
                };
        };
        if (is_array(discovered.other)) {
                for (var sidecar_other_i = 0; sidecar_other_i < array_length(discovered.other); sidecar_other_i++) {
                        array_add(sidecar_files, discovered.other[sidecar_other_i]);
                };
        };
        var line_full = chart_find_sidecar(sidecar_files, "line.csv", chart_full);
        var extra_full = chart_find_sidecar(sidecar_files, "extra.json", chart_full);
        session.line_file = string_length(line_full) ? chart_path_rel(root, line_full) : "";
        session.line_overrides = chart_load_line_overrides(line_full, chart_full, root);
        session.extra_file = string_length(extra_full) ? chart_path_rel(root, extra_full) : "";
        session.info_offset_ms = real(info.offset_ms ?? 0);

        // name/level only from root info; otherwise keep empty strings.
        session.name = (has_info && string_length(info.name)) ? info.name : "";
        session.level = (has_info && string_length(info.level)) ? info.level : "";
        session.play_room = chart_session_play_room_for(format_id);
        session.ready = true;
        session.error = "";
        var ready_label = string_length(session.name) ? session.name : session.chart_file;
        chart_session_set_status("Ready", $"{session.format_name} / {ready_label}");
        return true;
}

function chart_session_load_zip(zip_path) {
        var session = chart_session_ensure();
        session.ready = false;
        session.error = "";
        session.source_path = zip_path;
        session.from_zip = true;
        session.extract_dir = chart_path_norm(game_save_id + "track/");

        if (!file_exists(zip_path)) {
                return chart_session_fail("Zip file does not exist.");
        };

        chart_session_set_status("Preparing extract folder", "");
        var track_path = chart_path_norm(game_save_id + "track/");
        if (directory_exists(track_path)) then directory_destroy(track_path);
        directory_create(track_path);
        session.extract_dir = track_path;

        chart_session_set_status("Unzipping", chart_path_file_name(zip_path));
        var unzip_count = zip_unzip(zip_path, track_path);
        if (!unzip_count) {
                return chart_session_fail("Failed to unzip chart package.");
        };

        var discovered_root = File_Discoverer(track_path);
        var root = track_path;
        if (array_length(discovered_root.chart) <= 0) {
                var probe = file_find_first(track_path + "*", fa_directory);
                var first_dir = "";
                while (string_length(probe)) {
                        if (probe != "." && probe != "..") {
                                var full = chart_path_join(track_path, probe);
                                if (directory_exists(full)) {
                                        first_dir = full;
                                        break;
                                };
                        };
                        probe = file_find_next();
                };
                file_find_close();
                if (string_length(first_dir)) {
                        var nested = File_Discoverer(first_dir);
                        if (array_length(nested.chart) > 0 || array_length(nested.music) > 0) {
                                root = first_dir;
                        };
                };
        };

        return chart_session_build_from_dir(root, zip_path, true);
}

function chart_session_load_sample() {
        var sample_dir = working_directory + "chart/";
        chart_session_set_status("Loading sample chart", sample_dir);
        var ok = chart_session_build_from_dir(sample_dir, sample_dir, false);
        if (!ok) then return false;

        var session = global.chart_session;
        var cfg = working_directory + "resource/configs.ini";
        if (file_exists(cfg)) {
                ini_open(cfg);
                var cfg_name = ini_read_string("Chart", "name", "");
                var cfg_level = ini_read_string("Chart", "level", "");
                var cfg_chart = ini_read_string("Chart", "chart", "");
                var cfg_music = ini_read_string("Chart", "music", "");
                var cfg_bg = ini_read_string("Chart", "bg", "");
                ini_close();
                if (string_length(cfg_name) && !string_length(session.name)) {
                        session.name = cfg_name;
                };
                if (string_length(cfg_level) && !string_length(session.level)) {
                        session.level = cfg_level;
                };
                if (string_length(cfg_chart)) then session.chart_file = cfg_chart;
                if (string_length(cfg_music)) then session.music_file = cfg_music;
                if (string_length(cfg_bg)) then session.image_file = cfg_bg;
        };
        session.ready = (session.format != CHART_FORMAT.UNKNOWN && string_length(session.chart_file) > 0);
        return session.ready;
}

function chart_session_begin_source(path) {
        chart_session_reset();
        if (!string_length(path)) {
                return chart_session_fail("Empty source path.");
        };
        var ext = chart_path_ext(path);
        if (ext == ".zip" || ext == ".pez") {
                return chart_session_load_zip(path);
        };
        if (directory_exists(path)) {
                return chart_session_build_from_dir(path, path, false);
        };
        if (file_exists(path)) {
                var p = chart_path_norm(path);
                var slash = max(string_last_pos("/", p), string_last_pos("\\", p));
                var dir = (slash > 0) ? string_copy(p, 1, slash) : (working_directory + "chart/");
                var ok = chart_session_build_from_dir(dir, path, false);
                if (ok) {
                        global.chart_session.chart_file = chart_path_file_name(path);
                        global.chart_session.format = chart_detect_format(path);
                        global.chart_session.format_name = chart_session_format_name(global.chart_session.format);
                        global.chart_session.play_room = chart_session_play_room_for(global.chart_session.format);
                        global.chart_session.ready = (global.chart_session.format != CHART_FORMAT.UNKNOWN);
                        if (!global.chart_session.ready) then return chart_session_fail("Unsupported chart format.");
                };
                return ok;
        };
        return chart_session_fail("Source path not found.");
}
