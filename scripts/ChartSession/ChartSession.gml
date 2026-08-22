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
                "aspect_ratio" : 16 / 9,
                "name" : "",
                "level" : "",
                "composer" : "",
                "charter" : "",
                "illustrator" : "",
                "play_room" : -1,
                "ready" : false,
                "from_zip" : false,
                "status" : "Idle",
                "detail" : "",
                "error" : "",
                "files" : undefined,
                "detected_chart_path" : "",
                "detected_chart_text" : ""
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

function chart_hud_ready() {
        if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then return false;
        if (instance_exists(oPlayTransition)) then return true;
        if (variable_global_exists("game") && is_struct(game) && !game.paused) then return true;
        return false;
}

/// Hide or show chart objects without deactivate/activate.
/// Activating is deferred to the end of the event, so a following
/// event_perform or first Step is skipped and judge-line init is lost.
function chart_set_gameplay_visible(_visible) {
        var _show = bool(_visible);
        var _apply_line_list = function(_owner, _visible_flag) {
                if (!is_struct(_owner) || !struct_exists(_owner, "runtime_line_instances")) then return;
                var _lines = _owner.runtime_line_instances;
                if (!is_array(_lines)) then return;
                for (var _i = 0; _i < array_length(_lines); _i++) {
                        var _line = _lines[_i];
                        if (instance_exists(_line)) then _line.visible = _visible_flag;
                };
        };
        if (variable_global_exists("game")) then _apply_line_list(game, _show);
        if (variable_global_exists("game_1")) then _apply_line_list(game_1, _show);
        if (variable_global_exists("game_2")) then _apply_line_list(game_2, _show);
        with (oLine) visible = _show;
        with (oLine_1) visible = _show;
        with (oLine_2) visible = _show;
        with (oNote) visible = _show;
        with (oNote_1) visible = _show;
        with (oNote_2) visible = _show;
}

/// Park FX behind the loading overlay. Judge lines stay active so CreateLines
/// init is not thrown away by a later activate.
function chart_idle_behind_loading() {
        if (!(variable_global_exists("loading_animation_active") && global.loading_animation_active)) then return;
        chart_set_gameplay_visible(false);
        instance_deactivate_object(oRPEEffect);
        instance_deactivate_object(oEffect);
        instance_deactivate_object(oEffectNew);
}

function chart_loading_animation_abort() {
        if (instance_exists(oLoadAnimator)) {
                with (oLoadAnimator) instance_destroy();
        };
        if (variable_global_exists("loading_animation_active")) {
                global.loading_animation_active = false;
        };
        if (variable_global_exists("loading_animation_load_start")) {
                global.loading_animation_load_start = false;
        };
        if (variable_global_exists("loading_animator_finished")) {
                global.loading_animator_finished = false;
        };
        if (variable_global_exists("load_animator_instance")) {
                global.load_animator_instance = noone;
        };
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
        session.composer = "";
        session.charter = "";
        session.illustrator = "";
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
                var scale_cell = row[$ "Scale"];
                var has_scale = !is_undefined(scale_cell) && string_length(string_trim(string(scale_cell)));
                array_add(result, {
                        LineId: floor(real(row.LineId)),
                        Image: chart_path_rel(root_dir, image_full),
                        Scale: (has_scale ? number(scale_cell, 1) : undefined),
                        Aspect: number(row[$ "Aspect"] ?? (row[$ "Horz"] ?? 1), 1),
                        UseLineScale: chart_line_csv_parse_bool(row[$ "UseLineScale"], true),
                        Vert: row[$ "Vert"]
                });
        };
        return result;
}

function chart_line_csv_parse_bool(value, fallback = true) {
        if (is_bool(value)) then return value;
        if (is_real(value) && is_finite(value)) then return value != 0;
        var text = string_lower(string_trim(string(value ?? "")));
        if (text == "true" || text == "1" || text == "yes") then return true;
        if (text == "false" || text == "0" || text == "no") then return false;
        return fallback;
}

function chart_line_csv_sprite_scale(_override, _sprite = -1) {
        var _scale = 1;
        var _aspect = 1;
        var _use_line_scale = true;
        if (is_struct(_override)) {
                if (is_real(_override[$ "Scale"]) && is_finite(_override.Scale)) {
                        _scale = _override.Scale;
                } else if (!is_undefined(_override[$ "Vert"])) {
                        var _vert = real(_override.Vert);
                        if (is_finite(_vert) && _vert != 0 && sprite_exists(_sprite)) {
                                _scale = abs(_vert) * (1080 / max(1, sprite_get_height(_sprite)));
                                _use_line_scale = (_vert > 0);
                        };
                };
                if (is_real(_override[$ "Aspect"]) && is_finite(_override.Aspect) && _override.Aspect > 0) {
                        _aspect = _override.Aspect;
                };
                if (struct_exists(_override, "UseLineScale")) {
                        _use_line_scale = bool(_override.UseLineScale);
                };
        };
        var _view_h = room_height;
        var _view_w = room_width;
        if (variable_global_exists("chart_view_height") && is_real(chart_view_height) && chart_view_height > 0) {
                _view_h = chart_view_height;
        };
        if (variable_global_exists("chart_view_width") && is_real(chart_view_width) && chart_view_width > 0) {
                _view_w = chart_view_width;
        };
        var _d_scale;
        if (_use_line_scale) {
                var _ui_scale = (_view_w > _view_h * 0.75) ? (_view_h / 18.75) : (_view_w / 14.0625);
                _d_scale = (_ui_scale * 18.75) / 1080;
        } else {
                _d_scale = _view_h / 1080;
        };
        var _base = _d_scale * _scale;
        return [_base * _aspect, _base];
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
        if (max_chars > 0 && string_length(text) > max_chars) then text = string_copy(text, 1, max_chars);
        return text;
}

function chart_cache_detected_text(path, text) {
        var session = chart_session_ensure();
        session.detected_chart_path = chart_path_norm(path);
        session.detected_chart_text = text;
}

function chart_detect_format(chart_path) {
        if (!file_exists(chart_path)) then return CHART_FORMAT.UNKNOWN;
        var ext = chart_path_ext(chart_path);
        if (ext == ".pec") then return CHART_FORMAT.PEC;

        if (ext == ".json" || ext == ".txt") {
                // Official charts can be much larger than 120 KB; structural
                // format validation needs the complete JSON document.
                var text = chart_read_text_file(chart_path, -1);
                if (!string_length(text)) then return CHART_FORMAT.UNKNOWN;

                if (string_pos("\"RPEVersion\"", text) > 0) {
                        chart_cache_detected_text(chart_path, text);
                        return CHART_FORMAT.RPE;
                };

				if (string_pos("\"formatVersion\"", text) > 0 && string_pos("\"judgeLineList\"", text) > 0) {
					try {
						var official_probe = json_parse(text);
						if (is_struct(official_probe) && is_real(official_probe[$ "formatVersion"])
							&& real(official_probe.formatVersion) == floor(real(official_probe.formatVersion))
							&& real(official_probe.formatVersion) >= 1
							&& real(official_probe.formatVersion) <= 3
							&& is_array(official_probe[$ "judgeLineList"])) {
							return CHART_FORMAT.OFFICIAL;
						};
					} catch (official_probe_error) {
						delete(official_probe_error);
					};
				};

                if (string_pos("\"META\"", text) > 0 && string_pos("eventLayers", text) > 0) {
                        chart_cache_detected_text(chart_path, text);
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
                                        chart_cache_detected_text(chart_path, text);
                                        return CHART_FORMAT.RPE;
                                };
						if (struct_exists(parsed, "formatVersion") && is_real(parsed.formatVersion)
							&& real(parsed.formatVersion) == floor(real(parsed.formatVersion))
							&& real(parsed.formatVersion) >= 1 && real(parsed.formatVersion) <= 3
							&& is_array(parsed[$ "judgeLineList"])) {
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

function chart_parse_aspect_ratio(value, fallback = 16 / 9) {
        if (is_real(value) && is_finite(value) && value > 0) then return value;
        var text = string_trim(string(value ?? ""));
        if (!string_length(text)) then return fallback;
        var sep = string_pos(":", text);
        if (sep <= 0) then sep = string_pos("/", text);
        if (sep > 1 && sep < string_length(text)) {
                var aspect_w = number(string_trim(string_copy(text, 1, sep - 1)), 0);
                var aspect_h = number(string_trim(string_copy(text, sep + 1, string_length(text) - sep)), 0);
                if (is_real(aspect_w) && is_real(aspect_h) && is_finite(aspect_w) && is_finite(aspect_h)
                        && aspect_w > 0 && aspect_h > 0) {
                        return aspect_w / aspect_h;
                };
        };
        var parsed = number(text, 0);
        if (is_real(parsed) && is_finite(parsed) && parsed > 0) then return parsed;
        return fallback;
}

function chart_info_apply_value(info, key, val) {
        var normalized_key = string_lower(string_replace_all(string(key), " ", ""));
        normalized_key = string_replace_all(normalized_key, "\t", "");
        var value = chart_info_trim_value(val);
        if (!string_length(value)) then return;

        switch (normalized_key) {
                case "name":
                case "title":
                        info.name = value;
                break;
                case "level":
                        info.level = value;
                break;
                case "composer":
                case "musiccomposer":
                case "artist":
                        info.composer = value;
                break;
                case "charter":
                case "chartcharter":
                case "designer":
                        info.charter = value;
                break;
                case "illustrator":
                case "illustrationauthor":
                case "illustrationartist":
                        info.illustrator = value;
                break;
                case "difficulty":
                        if (!string_length(info.level)) then info.level = value;
                break;
                case "image":
                case "illustration":
                case "background":
                case "bg":
                case "picture":
                        info.image = value;
                break;
                case "music":
                case "song":
                case "songfile":
                case "audio":
                        info.music = value;
                break;
                case "chart":
                case "track":
                case "chartfile":
                        info.chart = value;
                break;
                case "offset":
                        info.offset_ms = number(value, 0);
                break;
                case "aspectratio":
                        var parsed_aspect = chart_parse_aspect_ratio(value, 0);
                        if (parsed_aspect > 0) then info.aspect_ratio = parsed_aspect;
                break;
        };
}

/// @desc Parse root-only info.txt / info.yml style metadata.
function chart_parse_info_file(info_path) {
        var info = {
                "name" : "",
                "level" : "",
                "composer" : "",
                "charter" : "",
                "illustrator" : "",
                "image" : "",
                "music" : "",
                "chart" : "",
                "offset_ms" : 0,
                "aspect_ratio" : 16 / 9
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

                var key = string_copy(text_ln, 1, sep - 1);
                var val = chart_info_trim_value(string_copy(text_ln, sep + 1, string_length(text_ln) - sep));
                chart_info_apply_value(info, key, val);
        };
        file_text_close(handle);
        return info;
}

function chart_parse_info_csv(info_path) {
        var info = {
                "name" : "", "level" : "", "image" : "", "music" : "", "chart" : "",
                "composer" : "", "charter" : "", "illustrator" : "",
                "offset_ms" : 0, "aspect_ratio" : 16 / 9
        };
        if (!file_exists(info_path)) then return info;
        var grid = load_csv(info_path);
        if (!ds_exists(grid, ds_type_grid)) then return info;

        var width = ds_grid_width(grid);
        var height = ds_grid_height(grid);
        if (width >= 2 && height >= 2
                && string_lower(chart_info_trim_value(ds_grid_get(grid, 0, 0))) == "key"
                && string_lower(chart_info_trim_value(ds_grid_get(grid, 1, 0))) == "value") {
                for (var row = 1; row < height; row++) {
                        chart_info_apply_value(info, ds_grid_get(grid, 0, row), ds_grid_get(grid, 1, row));
                };
        } else if (height >= 2) {
                // Standard info.csv: first row contains field names, second row values.
                for (var column = 0; column < width; column++) {
                        chart_info_apply_value(info, ds_grid_get(grid, column, 0), ds_grid_get(grid, column, 1));
                };
        };
        ds_grid_destroy(grid);
        return info;
}

/// @desc info.txt / info.yml are valid only in package root.
function chart_load_root_info(root_dir) {
        var info = {
                "name" : "",
                "level" : "",
                "composer" : "",
                "charter" : "",
                "illustrator" : "",
                "image" : "",
                "music" : "",
                "chart" : "",
                "offset_ms" : 0,
                "aspect_ratio" : 16 / 9
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

        var csv = chart_path_join(root, "info.csv");
        if (file_exists(csv)) {
                return {
                        "info" : chart_parse_info_csv(csv),
                        "has_info" : true,
                        "source" : "info.csv"
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
        session.aspect_ratio = real(info.aspect_ratio ?? (16 / 9));

        // name/level only from root info; otherwise keep empty strings.
        session.name = (has_info && string_length(info.name)) ? info.name : "";
        session.level = (has_info && string_length(info.level)) ? info.level : "";
        session.composer = (has_info && string_length(info.composer)) ? info.composer : "";
        session.charter = (has_info && string_length(info.charter)) ? info.charter : "";
        session.illustrator = (has_info && string_length(info.illustrator)) ? info.illustrator : "";
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
