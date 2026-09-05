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
                        extract_dir = chart_session_track_dir();
                };
        };

        if (string_length(extract_dir)) {
                chart_session_remove_dir(extract_dir);
                print($"[ChartSession] Cleaned extract dir: {extract_dir}");
        };

        chart_session_remove_dir(chart_session_track_dir());
        chart_session_remove_dir(chart_gm_cache_dir());
        chart_cache_legacy_cleanup();

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

function chart_playback_teardown_reset() {
        global.chart_playback_torn_down = false;
}

/// Reactivate judged/culled instances so room change can destroy them.
function chart_playback_prepare_exit() {
        instance_activate_all();
}

function chart_playback_release_hitsounds() {
        if (!variable_global_exists("game_1") || !is_struct(game_1)) then return;
        if (!struct_exists(game_1, "HitSounds") || !is_struct(game_1.HitSounds)) then return;
        if (extension_exists("FMOD") && instance_exists(oMedia)) {
                var media = instance_find(oMedia, 0);
                if (media.track > 0) then fmod_system_select(media.track);
        };
        var hit_names = struct_get_names(game_1.HitSounds);
        for (var i = 0; i < array_length(hit_names); i++) {
                var sound = game_1.HitSounds[$ hit_names[i]];
                if (sound > 0 && extension_exists("FMOD")) then fmod_sound_release(sound);
        };
        game_1.HitSounds = {};
}

/// Stop audio, drop FX/video, and wipe extract files before returning to menu.
function chart_playback_teardown_for_menu() {
        if (variable_global_exists("chart_playback_torn_down") && global.chart_playback_torn_down) {
                return true;
        };
        global.chart_playback_torn_down = true;
        chart_playback_prepare_exit();

        if (instance_exists(oExtraPlay)) {
                with (oExtraPlay) instance_destroy();
        };
        if (pls_is_gxgames()) then gx_video_shutdown();
        if (instance_exists(oRPEEffect)) {
                with (oRPEEffect) instance_destroy();
        } else if (extension_exists("I_Shaders")) {
                rpe_ext_shutdown();
        };

        chart_playback_release_hitsounds();
        m_stop();
        m_clean(true);
        mus_system_clean();
        chart_session_cleanup(true);
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

function chart_blur_kept() {
        if (!variable_global_exists("chart_kept_blur")) then return -1;
        return sprite_exists(global.chart_kept_blur) ? global.chart_kept_blur : -1;
}

function chart_blur_keep(spr) {
        if (!sprite_exists(spr)) then return -1;
        var prev = chart_blur_kept();
        if (prev != -1 && prev != spr) {
                try { sprite_delete(prev); } catch (del_error) { delete(del_error); };
        };
        global.chart_kept_blur = spr;
        return spr;
}

function chart_blur_keep_from_animator() {
        if (!instance_exists(oLoadAnimator)) then return chart_blur_kept();
        var spr = -1;
        with (oLoadAnimator) {
                if (sprite_exists(blur_sprite)) then spr = blur_sprite;
        };
        if (sprite_exists(spr)) then return chart_blur_keep(spr);
        return chart_blur_kept();
}

/// Share the loading-screen blur with gameplay. Do not steal oLoadAnimator.blur_sprite
/// while the overlay is still drawing it.
function chart_blur_bind_game(_force = false) {
        var kept = chart_blur_keep_from_animator();
        if (!sprite_exists(kept)) then return -1;
        if (!variable_global_exists("game") || !is_struct(game)) then return kept;
        var allow = _force || pls_is_gxgames();
        if (!allow && is_struct(game.settings)) then allow = bool(game.settings.enableBlur);
        if (!allow) then return kept;
        if (asset_sprite_valid(game.bg) && game.bg != kept) {
                try { sprite_delete(game.bg); } catch (del_error) { delete(del_error); };
        };
        game.bg = kept;
        game.bg_blurred = true;
        game.bg_blur_pending = false;
        var _bw = sprite_get_width(kept);
        var _bh = sprite_get_height(kept);
        if (_bw > 0 && _bh > 0) then sprite_set_offset(kept, _bw * 0.5, _bh * 0.5);
        return kept;
}

function chart_loading_blur_draw_sprite() {
        if (instance_exists(oLoadAnimator)) {
                with (oLoadAnimator) {
                        if (sprite_exists(blur_sprite)) then return blur_sprite;
                };
        };
        var kept = chart_blur_kept();
        if (sprite_exists(kept)) then return kept;
        if (variable_global_exists("game") && is_struct(game) && asset_sprite_valid(game.bg)) then return game.bg;
        return -1;
}

function chart_blur_release() {
        var spr = chart_blur_kept();
        if (spr != -1) {
                try { sprite_delete(spr); } catch (del_error) { delete(del_error); };
        };
        global.chart_kept_blur = -1;
}

function chart_loading_animation_abort() {
        chart_blur_release();
        if (instance_exists(oLoadAnimator)) {
                with (oLoadAnimator) {
                        visible = false;
                        persistent = false;
                        instance_destroy();
                };
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

function chart_loading_take_blur_sprite() {
        // Ownership stays with the animator until finish(). Gameplay shares the same sprite.
        return chart_blur_keep_from_animator();
}

function chart_loading_animation_finish() {
        chart_blur_bind_game(false);
        if (instance_exists(oLoadAnimator)) {
                with (oLoadAnimator) {
                        if (sprite_exists(blur_sprite) && blur_sprite == chart_blur_kept()) then blur_sprite = -1;
                        visible = false;
                        persistent = false;
                        instance_destroy();
                };
        };
        global.loading_animation_active = false;
        global.loading_animation_load_start = false;
        global.loading_animator_finished = true;
        global.loading_render_ready = true;
        global.load_animator_instance = noone;
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
        if (cleanup) {
                chart_session_cleanup(true);
                var kept = chart_session_ensure();
                kept.error = message;
                kept.status = "Failed";
                kept.detail = message;
        };
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

function chart_gx_local_root() {
        return "/tmp/pls/";
}

function chart_gx_sandbox_root() {
        var base = gx_path_clean(string(game_save_id));
        if (!string_length(base)) then base = "/_savedata";
        if (string_char_at(base, string_length(base)) != "/") then base += "/";
        return base;
}

function chart_session_track_dir() {
        if (chart_use_native_files()) {
                var external = chart_native_external_dir();
                if (!string_length(external) && os_type == os_android) then external = "/storage/emulated/0/Android/data/com.xthx.pls/files/";
                var track = chart_path_norm(external + "track/");
                chart_native_mkdir(track);
                return track;
        };
        if (pls_is_gxgames()) {
                var gx_track = chart_path_join(chart_gx_sandbox_root(), "track");
                if (string_length(gx_track) && string_char_at(gx_track, string_length(gx_track)) != "/") then gx_track += "/";
                if (!directory_exists(gx_track)) then directory_create(gx_track);
                return gx_track;
        };
        var track = chart_path_join(game_save_id, "track");
        while (string_pos("//", track) > 0) {
                track = string_replace_all(track, "//", "/");
        };
        if (string_length(track) && string_char_at(track, string_length(track)) != "/") then track += "/";
        return track;
}

function chart_path_dir_exists(path) {
        if (directory_exists(path)) then return true;
        if (chart_use_native_files()) then return chart_native_is_dir(path);
        return false;
}

function chart_file_exists_any(path) {
        if (file_exists(path)) then return true;
        if (chart_use_native_files()) then return chart_native_exists(path);
        if (pls_is_gxgames() && is_string(path) && string_length(path)) {
                var n = gx_file_ui_cmd("pls-f:fopen\t" + gx_path_clean(path));
                if (is_real(n) && n > 0) then return true;
        };
        return false;
}

function chart_gm_cache_dir() {
        if (chart_use_native_files()) {
                var android_dir = chart_path_norm(chart_native_external_dir() + "tmp/");
                chart_native_mkdir(android_dir);
                return android_dir;
        };
        if (pls_is_gxgames()) {
                var gx_tmp = chart_path_join(chart_gx_local_root(), "tmp");
                if (string_length(gx_tmp) && string_char_at(gx_tmp, string_length(gx_tmp)) != "/") then gx_tmp += "/";
                if (!directory_exists(gx_tmp)) then directory_create(gx_tmp);
                return gx_tmp;
        };
        var dir = chart_path_norm(game_save_id + "tmp/");
        if (!directory_exists(dir)) then directory_create(dir);
        return dir;
}

function chart_delete_files_with_prefix(dir, prefix) {
        dir = chart_path_norm(dir);
        if (!string_length(dir) || !string_length(prefix)) then return;
        if (string_char_at(dir, string_length(dir)) != "/") then dir += "/";
        var lower_prefix = string_lower(prefix);
        if (chart_use_native_files()) {
                if (!chart_native_is_dir(dir)) then return;
                var listing = chart_native_list(dir);
                var parts = string_split(string_replace_all(string(listing), "\r", ""), "\n");
                for (var list_i = 0; list_i < array_length(parts); list_i++) {
                        var listed = string_replace_all(string_trim(parts[list_i]), "\\", "/");
                        if (!string_length(listed)) then continue;
                        var name = chart_path_file_name(listed);
                        if (string_pos(lower_prefix, string_lower(name)) != 1) then continue;
                        chart_native_delete(listed);
                        if (file_exists(listed)) then file_delete(listed);
                };
                return;
        };
        if (!directory_exists(dir)) then return;
        var found = file_find_first(dir + prefix + "*", 0);
        var names = [];
        while (string_length(found)) {
                array_add(names, found);
                found = file_find_next();
        };
        file_find_close();
        for (var name_i = 0; name_i < array_length(names); name_i++) {
                var full = dir + names[name_i];
                if (!directory_exists(full) && file_exists(full)) then file_delete(full);
        };
}

function chart_cache_legacy_cleanup() {
        chart_delete_files_with_prefix(working_directory, "bg_cache_");
        chart_delete_files_with_prefix(working_directory + "caches/", "bg_cache_");
        chart_delete_files_with_prefix(game_save_id, "bg_cache_");
        chart_delete_files_with_prefix(game_save_id + "caches/", "bg_cache_");
        if (os_type == os_android && android_files_available()) {
                var external = android_files_external_dir();
                var internal = android_files_internal_dir();
                chart_delete_files_with_prefix(external, "bg_cache_");
                chart_delete_files_with_prefix(external + "caches/", "bg_cache_");
                chart_delete_files_with_prefix(internal, "bg_cache_");
                chart_delete_files_with_prefix(internal + "caches/", "bg_cache_");
                chart_session_remove_dir(chart_path_norm(external + "track_cache/"));
                chart_session_remove_dir(chart_path_norm(internal + "track_cache/"));
                chart_session_remove_dir(chart_path_norm(external + "caches/"));
                chart_session_remove_dir(chart_path_norm(internal + "caches/"));
        };
        if (directory_exists(working_directory + "caches/")) then directory_destroy(working_directory + "caches/");
        if (directory_exists(game_save_id + "caches/")) then directory_destroy(game_save_id + "caches/");
}

function chart_file_readable_path(path) {
        if (file_exists(path)) then return path;
        if (os_type != os_android || !android_files_available()) then return path;
        if (!android_files_exists(path)) then return path;
        var cache_dir = chart_gm_cache_dir();
        var ext = chart_path_ext(path);
        var dest = cache_dir + md5_string_utf8(path) + ext;
        if (!android_files_exists(dest) && !file_exists(dest)) {
                if (!android_files_copy(path, dest)) {
                        print($"[ChartSession] UTF-8 copy failed: {path} -> {dest} {android_files_error()}");
                        return path;
                };
                print($"[ChartSession] UTF-8 readable copy: {path} -> {dest}");
        };
        return dest;
}

function chart_path_is_absolute(path) {
        var p = chart_path_norm(path);
        if (!string_length(p)) then return false;
        if (string_pos("blob:", p) == 1) then return true;
        if (string_pos("http://", p) == 1) then return true;
        if (string_pos("https://", p) == 1) then return true;
        if (string_char_at(p, 1) == "/") then return true;
        if (string_length(p) >= 2 && string_char_at(p, 2) == ":") then return true;
        return false;
}

/// @desc Join InChartPath + relative name, then make it GM-openable on Android.
function chart_in_path(relative_or_full) {
        var p = string(relative_or_full);
        if (!string_length(p)) then return "";
        var full = chart_path_is_absolute(p) ? chart_path_norm(p) : chart_path_join(InChartPath, p);
        return chart_file_readable_path(full);
}

function chart_list_immediate_dirs(parent_path) {
        var dirs = [];
        var parent = chart_path_norm(parent_path);
        if (!string_length(parent)) then return dirs;
        if (string_char_at(parent, string_length(parent)) != "/") then parent += "/";

        if (chart_use_native_files()) {
                var listing = chart_native_list(parent);
                var parts = string_split(string_replace_all(listing, "\r", ""), "\n");
                var seen = {};
                for (var list_i = 0; list_i < array_length(parts); list_i++) {
                        var listed = string_replace_all(string_trim(parts[list_i]), "\\", "/");
                        if (!string_length(listed)) then continue;
                        var rel = chart_path_rel(parent, listed);
                        var slash = string_pos("/", rel);
                        if (slash <= 0) then continue;
                        var child_name = string_copy(rel, 1, slash - 1);
                        if (!string_length(child_name) || child_name == "." || child_name == "..") then continue;
                        var key = string_lower(child_name);
                        if (struct_exists(seen, key)) then continue;
                        seen[$ key] = true;
                        array_add(dirs, chart_path_join(parent, child_name));
                };
                return dirs;
        };

        var list_root = pls_is_gxgames() ? parent : string_replace_all(parent, "/", "\\");
        var probe = file_find_first(list_root + "*", fa_directory);
        while (string_length(probe)) {
                if (probe != "." && probe != "..") {
                        var full = chart_path_join(parent, probe);
                        if (directory_exists(parent + probe) || directory_exists(full) || chart_path_dir_exists(full)) {
                                array_add(dirs, full);
                        };
                };
                probe = file_find_next();
        };
        file_find_close();
        return dirs;
}

function chart_session_unique_nested_root(track_path, discovered) {
        var track = chart_path_norm(track_path);
        if (string_length(track) && string_char_at(track, string_length(track)) != "/") then track += "/";
        if (!is_struct(discovered) || !is_array(discovered.chart) || array_length(discovered.chart) <= 0) then return "";

        var first_child = "";
        var unique = true;
        var has_root_file = false;
        for (var i = 0; i < array_length(discovered.chart); i++) {
                var rel = chart_path_rel(track, discovered.chart[i]);
                var slash = string_pos("/", rel);
                if (slash <= 0) {
                        has_root_file = true;
                        break;
                };
                var child = string_copy(rel, 1, slash - 1);
                if (!string_length(first_child)) then first_child = child;
                else if (string_lower(first_child) != string_lower(child)) then unique = false;
        };
        if (has_root_file || !unique || !string_length(first_child)) then return "";
        return chart_path_join(track, first_child);
}

/// @desc Windows-style extract root: scan all files, then nested folder fallback.
function chart_session_resolve_extract_root(track_path) {
        print($"[ChartSession][Unzip][finish] scanning output={track_path} exists={chart_path_exists_any(track_path)}");
        var discovered_root = File_Discoverer(track_path);
        print($"[ChartSession][Unzip][finish] discovered charts={array_length(discovered_root.chart)} music={array_length(discovered_root.music)} image={array_length(discovered_root.image)} other={array_length(discovered_root.other)}");

        if (array_length(discovered_root.chart) > 0) {
                var nested_root = chart_session_unique_nested_root(track_path, discovered_root);
                if (string_length(nested_root)) {
                        print($"[ChartSession][Unzip][finish] nested package root={nested_root}");
                        return nested_root;
                };
                return track_path;
        };

        var children = chart_list_immediate_dirs(track_path);
        for (var child_i = 0; child_i < array_length(children); child_i++) {
                var full = children[child_i];
                print($"[ChartSession][Unzip][finish] child={full} dir={chart_path_dir_exists(full)}");
                var nested = File_Discoverer(full);
                print($"[ChartSession][Unzip][finish] nested={full} charts={array_length(nested.chart)} music={array_length(nested.music)}");
                if (array_length(nested.chart) > 0 || array_length(nested.music) > 0) {
                        return full;
                };
        };
        return track_path;
}

function chart_pick_stem_match(list, chart_full) {
        if (!is_array(list) || !string_length(chart_full)) then return "";
        var chart_stem = string_lower(chart_path_file_name(chart_full));
        var dot = string_last_pos(".", chart_stem);
        if (dot > 0) then chart_stem = string_copy(chart_stem, 1, dot - 1);
        if (!string_length(chart_stem)) then return "";
        for (var i = 0; i < array_length(list); i++) {
                var iname = string_lower(chart_path_file_name(list[i]));
                var idot = string_last_pos(".", iname);
                var istem = (idot > 0) ? string_copy(iname, 1, idot - 1) : iname;
                if (istem == chart_stem && chart_file_exists_any(list[i])) then return list[i];
        };
        return "";
}

function chart_session_wipe_files(dir) {
        dir = chart_path_norm(dir);
        if (!string_length(dir)) then return;
        var gx = pls_is_gxgames();
        var sep = gx ? "/" : "\\";
        var root = gx ? dir : string_replace_all(dir, "/", "\\");
        if (string_length(root) && string_char_at(root, string_length(root)) != sep) then root += sep;
        var dirs = [root];
        var files = [];
        while (array_length(dirs) > 0) {
                var n = array_length(dirs);
                for (var i = 0; i < n; i++) {
                        var path = dirs[i];
                        var file_name = file_find_first(path + "*", fa_none);
                        while (string_length(file_name)) {
                                if (file_name != "." && file_name != "..") {
                                        var full_file = path + file_name;
                                        if (file_exists(full_file) && !directory_exists(full_file)) {
                                                array_push(files, string_replace_all(full_file, "\\", "/"));
                                        };
                                };
                                file_name = file_find_next();
                        };
                        file_find_close();
                        var dir_name = file_find_first(path + "*", fa_directory);
                        while (string_length(dir_name)) {
                                if (dir_name != "." && dir_name != "..") {
                                        if (directory_exists(path + dir_name)) {
                                                array_push(dirs, path + dir_name + sep);
                                        };
                                };
                                dir_name = file_find_next();
                        };
                        file_find_close();
                };
                array_delete(dirs, 0, n);
        };
        for (var f = 0; f < array_length(files); f++) {
                if (file_exists(files[f])) then file_delete(files[f]);
        };
}

function chart_session_remove_dir(path) {
        if (!string_length(path)) then return;
        path = chart_path_norm(path);
        if (pls_is_gxgames()) then gx_fs_wipe(path);
        if (chart_use_native_files()) {
                if (chart_native_is_dir(path) || chart_native_exists(path)) {
                        chart_native_delete(path);
                        print($"[ChartSession] Native cleaned: {path} err={chart_native_error()}");
                };
                return;
        };
        var extra_left = chart_path_join(path, "extra.json");
        if (file_exists(extra_left)) then file_delete(extra_left);
        chart_session_wipe_files(path);
        if (file_exists(extra_left)) then file_delete(extra_left);
        if (directory_exists(path)) then directory_destroy(path);
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
        if (!chart_file_exists_any(line_path)) then return result;
        var grid = load_csv(chart_file_readable_path(line_path));
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
                if (!chart_file_exists_any(image_full)) then image_full = chart_path_join(root_dir, image_name);
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
        var sprite = sprite_add(chart_file_readable_path(chart_path_join(InChartPath, row.Image)), 0, false, false, 0, 0);
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

function chart_text_strip_bom(text) {
        if (!is_string(text) || !string_length(text)) then return "";
        if (string_char_at(text, 1) == chr(0xFEFF)) then return string_delete(text, 1, 1);
        return text;
}

function chart_buffer_utf16_to_text(buff, start, nbytes, big_endian) {
        if (!asset_buffer_valid(buff) || nbytes < 2) then return "";
        var size = buffer_get_size(buff);
        if (start < 0 || start >= size) then return "";
        var end_pos = min(start + nbytes, size);
        var text = "";
        var i = start;
        while (i + 1 < end_pos) {
                var b0 = buffer_peek(buff, i, buffer_u8);
                var b1 = buffer_peek(buff, i + 1, buffer_u8);
                var code = big_endian ? ((b0 << 8) | b1) : (b0 | (b1 << 8));
                i += 2;
                if (code == 0) then break;
                if (code >= 0xD800 && code <= 0xDBFF && i + 1 < end_pos) {
                        var s0 = buffer_peek(buff, i, buffer_u8);
                        var s1 = buffer_peek(buff, i + 1, buffer_u8);
                        var low = big_endian ? ((s0 << 8) | s1) : (s0 | (s1 << 8));
                        if (low >= 0xDC00 && low <= 0xDFFF) {
                                i += 2;
                                code = 0x10000 + (((code - 0xD800) << 10) | (low - 0xDC00));
                        };
                };
                text += chr(code);
        };
        return text;
}

function chart_buffer_slice_to_text(buff, start, nbytes) {
        if (!asset_buffer_valid(buff) || nbytes <= 0) then return "";
        var src = buffer_create(nbytes + 1, buffer_fixed, 1);
        if (!asset_buffer_valid(src)) then return "";
        buffer_copy(buff, start, nbytes, src, 0);
        buffer_poke(src, nbytes, buffer_u8, 0);
        buffer_seek(src, buffer_seek_start, 0);
        var text = "";
        try {
                text = buffer_read(src, buffer_text);
        } catch (text_error) {
                delete(text_error);
                text = "";
        };
        if (!is_string(text) || !string_length(text)) {
                try {
                        buffer_seek(src, buffer_seek_start, 0);
                        text = buffer_read(src, buffer_string);
                } catch (string_error) {
                        delete(string_error);
                        text = "";
                };
        };
        buffer_delete(src);
        return is_string(text) ? text : "";
}

/// Legacy Windows path used before GX buffer/JS readers.
function chart_read_text_via_file(path, max_chars) {
        var handle = -1;
        try { handle = file_text_open_read(path); } catch (open_error) { delete(open_error); return ""; };
        if (is_undefined(handle) || (is_real(handle) && handle < 0)) then return "";
        var text = "";
        try {
                while (!file_text_eof(handle)) {
                        text += file_text_readln(handle);
                        if (!file_text_eof(handle)) then text += "\n";
                        if (max_chars > 0 && string_length(text) >= max_chars) then break;
                };
        } catch (read_error) {
                delete(read_error);
        };
        file_text_close(handle);
        if (!is_string(text)) then return "";
        if (max_chars > 0 && string_length(text) > max_chars) then text = string_copy(text, 1, max_chars);
        return chart_text_strip_bom(text);
}

function chart_read_text_file(path, max_chars = 200000) {
        if (!is_string(path) || !string_length(path)) then return "";
        if (chart_use_native_files() && chart_native_exists(path)) {
                var native_text = chart_native_read_text(path);
                if (!is_string(native_text)) then native_text = "";
                if (max_chars > 0 && string_length(native_text) > max_chars) then native_text = string_copy(native_text, 1, max_chars);
                return chart_text_strip_bom(native_text);
        };
        if (!file_exists(path)) {
                if (pls_is_gxgames()) then return gx_fs_read_js_text(path, max_chars);
                return "";
        };

        var text = "";
        var buff = -1;
        try { buff = buffer_load(path); } catch (load_error) { delete(load_error); buff = -1; };
        if (asset_buffer_valid(buff)) {
                var size = buffer_get_size(buff);
                if (size > 0) {
                        var start = 0;
                        var take = size;
                        if (max_chars > 0) then take = min(size, max_chars * 4);
                        var b0 = buffer_peek(buff, 0, buffer_u8);
                        var b1 = (size > 1) ? buffer_peek(buff, 1, buffer_u8) : 0;
                        var b2 = (size > 2) ? buffer_peek(buff, 2, buffer_u8) : 0;
                        if (size >= 3 && b0 == 0xEF && b1 == 0xBB && b2 == 0xBF) {
                                start = 3;
                                take = min(take, size - 3);
                                text = chart_buffer_slice_to_text(buff, start, take);
                        } else if (size >= 2 && b0 == 0xFF && b1 == 0xFE) {
                                start = 2;
                                take = min(take, size - 2);
                                text = chart_buffer_utf16_to_text(buff, start, take, false);
                        } else if (size >= 2 && b0 == 0xFE && b1 == 0xFF) {
                                start = 2;
                                take = min(take, size - 2);
                                text = chart_buffer_utf16_to_text(buff, start, take, true);
                        } else {
                                take = min(take, size);
                                text = chart_buffer_slice_to_text(buff, 0, take);
                        };
                };
                buffer_delete(buff);
        };

        text = chart_text_strip_bom(is_string(text) ? text : "");
        if (!string_length(text)) then text = chart_read_text_via_file(path, max_chars);
        if (!string_length(text) && pls_is_gxgames()) then return gx_fs_read_js_text(path, max_chars);
        if (max_chars > 0 && string_length(text) > max_chars) then text = string_copy(text, 1, max_chars);
        return text;
}

function chart_cache_detected_text(path, text) {
        var session = chart_session_ensure();
        session.detected_chart_path = chart_path_norm(path);
        session.detected_chart_text = text;
}

function chart_detect_format(chart_path) {
        if (!chart_file_exists_any(chart_path)) then return CHART_FORMAT.UNKNOWN;
        var ext = chart_path_ext(chart_path);
        if (ext == ".pec") then return CHART_FORMAT.PEC;

        if (ext == ".json" || ext == ".txt") {
                var text = "";
                if (pls_is_gxgames()) then text = gx_fs_chart_head(chart_path);
                if (!string_length(text)) then text = chart_read_text_file(chart_path, 16000);
                if (pls_is_gxgames() && (string_pos("\"RPEVersion\"", text) <= 0) && (string_pos("\"BPMList\"", text) <= 0)) {
                        var js_head = gx_fs_chart_head(chart_path);
                        if (string_length(js_head) > string_length(text)) then text = js_head;
                };
                if (!string_length(text)) then return CHART_FORMAT.UNKNOWN;

                if (string_pos("\"RPEVersion\"", text) > 0
                        || (string_pos("\"META\"", text) > 0 && string_pos("\"BPMList\"", text) > 0)) {
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

function chart_pick_preferred(list, preferred_name, base_dir = "") {
        if (!string_length(preferred_name)) then return "";
        var prefer = string_replace_all(string(preferred_name), "\\", "/");
        while (string_length(prefer) > 0 && string_char_at(prefer, 1) == "/") {
                prefer = string_delete(prefer, 1, 1);
        };
        if (!string_length(prefer)) then return "";

        if (string_length(base_dir)) {
                var preferred_full = chart_path_join(base_dir, prefer);
                if (chart_file_exists_any(preferred_full)) then return preferred_full;
        };
        if (chart_file_exists_any(prefer)) then return prefer;

        if (!is_array(list)) then return "";
        var prefer_lower = string_lower(chart_path_file_name(prefer));
        for (var i = 0; i < array_length(list); i++) {
                var item = list[i];
                if (string_lower(chart_path_file_name(item)) == prefer_lower) {
                        if (chart_file_exists_any(item)) then return item;
                };
        };
        return "";
}

function chart_pick_best(list, preferred_name, base_dir = "") {
        if (!is_array(list) || array_length(list) <= 0) then return "";

        // Prefer info.txt path only when the file really exists.
        var preferred_hit = chart_pick_preferred(list, preferred_name, base_dir);
        if (string_length(preferred_hit)) then return preferred_hit;

        for (var j = 0; j < array_length(list); j++) {
                if (chart_file_exists_any(list[j])) then return list[j];
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
        var text = chart_read_text_file(info_path, -1);
        if (!string_length(text)) then return info;
        var lines = string_split(string_replace_all(text, "\r", ""), "\n");
        for (var info_i = 0; info_i < array_length(lines); info_i++) {
                var text_ln = string_replace_all(lines[info_i], "\n", "");
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
        return info;
}

function chart_parse_info_csv(info_path) {
        var info = {
                "name" : "", "level" : "", "image" : "", "music" : "", "chart" : "",
                "composer" : "", "charter" : "", "illustrator" : "",
                "offset_ms" : 0, "aspect_ratio" : 16 / 9
        };
        if (!chart_file_exists_any(info_path)) then return info;
        var grid = load_csv(chart_file_readable_path(info_path));
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
        if (chart_file_exists_any(txt)) {
                return {
                        "info" : chart_parse_info_file(txt),
                        "has_info" : true,
                        "source" : "info.txt"
                };
        };

        var yml = chart_path_join(root, "info.yml");
        if (chart_file_exists_any(yml)) {
                return {
                        "info" : chart_parse_info_file(yml),
                        "has_info" : true,
                        "source" : "info.yml"
                };
        };

        var csv = chart_path_join(root, "info.csv");
        if (chart_file_exists_any(csv)) {
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
        if (!chart_path_dir_exists(root) && !chart_file_exists_any(root)) {
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
        var music_full = chart_pick_preferred(discovered.music, info.music, root);
        if (!string_length(music_full) && string_length(chart_full)) {
                music_full = chart_pick_stem_match(discovered.music, chart_full);
        };
        if (!string_length(music_full)) {
                music_full = chart_pick_best(discovered.music, "", root);
        };
        var image_full = chart_pick_preferred(discovered.image, info.image, root);
        if (!string_length(image_full) && string_length(chart_full)) {
                image_full = chart_pick_stem_match(discovered.image, chart_full);
        };
        // Still none: choose the largest image file (usually the illustration, not UI icons)
        if (!string_length(image_full) && is_array(discovered.image) && array_length(discovered.image) > 0) {
                var best_img = "";
                var best_size = -1;
                for (var ij = 0; ij < array_length(discovered.image); ij++) {
                        var ip = discovered.image[ij];
                        if (!chart_file_exists_any(ip)) then continue;
                        var sz = chart_archive_size_bytes(ip);
                        if (sz < 0) then sz = 0;
                        if (sz > best_size) {
                                best_size = sz;
                                best_img = ip;
                        };
                };
                image_full = best_img;
        };

        print($"[ChartSession] Picked info={info_source} chart={chart_full} music={music_full} image={image_full}");

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
                print($"[ChartSession] Scan leftover charts={array_length(discovered.chart)} music={array_length(discovered.music)} image={array_length(discovered.image)} text={array_length(discovered.text)}");
                return chart_session_fail("Missing required file(s): " + missing_text);
        };

        chart_session_set_status("Detecting format", chart_path_file_name(chart_full));
        var format_id = chart_detect_format(chart_full);
        if (format_id == CHART_FORMAT.UNKNOWN && is_array(discovered.chart)) {
                for (var chart_try_i = 0; chart_try_i < array_length(discovered.chart); chart_try_i++) {
                        var chart_try = discovered.chart[chart_try_i];
                        var chart_try_name = string_lower(chart_path_file_name(chart_try));
                        if (chart_try_name == "extra.json") then continue;
                        if (chart_try == chart_full) then continue;
                        var try_id = chart_detect_format(chart_try);
                        if (try_id != CHART_FORMAT.UNKNOWN) {
                                chart_full = chart_try;
                                format_id = try_id;
                                break;
                        };
                };
        };
        if (format_id == CHART_FORMAT.UNKNOWN) {
                var fail_head = pls_is_gxgames() ? gx_fs_chart_head(chart_full) : chart_read_text_file(chart_full, 80);
                fail_head = string_copy(string_replace_all(string_replace_all(string(fail_head), "\n", " "), "\r", ""), 1, 80);
                var fail_n = pls_is_gxgames() ? gx_file_ui_cmd("pls-f:head\t" + chart_full) : -1;
                return chart_session_fail("Unsupported chart format: " + chart_path_file_name(chart_full) + " head=" + fail_head + " headcmd=" + string(fail_n));
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
        session.extract_dir = chart_session_track_dir();

        if (!chart_file_exists_any(zip_path)) {
                return chart_session_fail("Zip file does not exist.");
        };

        chart_session_set_status("Preparing extract folder", "");
        var track_path = chart_session_track_dir();
        chart_session_remove_dir(track_path);
        if (chart_use_native_files()) {
                chart_native_mkdir(track_path);
        } else {
                directory_create(track_path);
        };
        session.extract_dir = track_path;

        chart_session_set_status("Unzipping", chart_path_file_name(zip_path));
        if (pls_is_gxgames()) {
                if (!gx_zip_extract(zip_path, track_path, true, false)) {
                        var gx_err = unicode_zip_backend_last_error();
                        if (!string_length(gx_err)) then gx_err = "Failed to unzip chart package.";
                        return chart_session_fail(gx_err);
                };
        } else {
                var unzip_count = zip_unzip(zip_path, track_path);
                if (!unzip_count) {
                        return chart_session_fail("Failed to unzip chart package.");
                };
        };

        var root = chart_session_resolve_extract_root(track_path);
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
        if (chart_path_dir_exists(path) || directory_exists(path)) {
                return chart_session_build_from_dir(path, path, false);
        };
        if (chart_file_exists_any(path)) {
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
