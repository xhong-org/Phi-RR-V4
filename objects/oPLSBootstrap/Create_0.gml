/// @description Route command-line archive tests without changing normal startup.
global.pls_archive_test = false;
global.pls_archive_test_path = "";
global.pls_exit_test = false;
global.render_mode = false;
global.render_source = "";
global.render_output = "";
global.render_fps = 60;
global.render_resolution = "native";
global.render_width = 1366;
global.render_height = 768;
global.render_aspect_ratio = "16:9";
global.render_crf = 18;
global.render_aa_level = 8;
global.render_cli = false;
global.render_gui_returning = false;
global.render_preset = "medium";
global.render_encoder = "auto";
global.render_seed = 0;
global.render_ffmpeg = "ffmpeg.exe";
global.render_hitsounds = [];
global.default_notes_texture_loaded = false;
global.default_hitsounds_load_requested = false;

var param_count = parameter_count();
var render_base_height = 768;
var render_aspect_width = 16;
var render_aspect_height = 9;
for (var i = 1; i < param_count; i++) {
        if (parameter_string(i) == "-archive-test" && i + 1 < param_count) {
                i++;
                global.pls_archive_test_path = parameter_string(i);
                global.pls_archive_test = string_length(global.pls_archive_test_path) > 0;
        } else if (parameter_string(i) == "-render" && i + 1 < param_count) {
                i++;
                global.render_source = parameter_string(i);
                global.render_mode = string_length(global.render_source) > 0;
        } else if (parameter_string(i) == "-output" && i + 1 < param_count) {
                i++;
                global.render_output = parameter_string(i);
        } else if (parameter_string(i) == "-fps" && i + 1 < param_count) {
                i++;
                global.render_fps = clamp(real(parameter_string(i)), 1, 240);
        } else if ((parameter_string(i) == "-resolution" || parameter_string(i) == "-res") && i + 1 < param_count) {
                i++;
                global.render_resolution = string_lower(parameter_string(i));
                switch (global.render_resolution) {
                        case "720p":
                                render_base_height = 720;
                                break;
                        case "1080p":
                                render_base_height = 1080;
                                break;
                        case "2k":
                        case "1440p":
                                render_base_height = 1440;
                                break;
                        case "4k":
                        case "2160p":
                                render_base_height = 2160;
                                break;
                        case "native":
                                render_base_height = 768;
                                break;
                        default:
                                print($"[Renderer] Unknown resolution '{global.render_resolution}', using native");
                                global.render_resolution = "native";
                                render_base_height = 768;
                                break;
                };
        } else if (parameter_string(i) == "-ar" && i + 1 < param_count) {
                i++;
                var aspect_value = string_trim(parameter_string(i));
                var aspect_separator = string_pos(":", aspect_value);
                if (aspect_separator <= 1 || aspect_separator >= string_length(aspect_value)) {
                        print($"[Renderer] Invalid aspect ratio '{aspect_value}', using 16:9");
                        render_aspect_width = 16;
                        render_aspect_height = 9;
                        global.render_aspect_ratio = "16:9";
                } else {
                        var aspect_width = real(string_trim(string_copy(aspect_value, 1, aspect_separator - 1)));
                        var aspect_height = real(string_trim(string_copy(aspect_value, aspect_separator + 1,
                                string_length(aspect_value) - aspect_separator)));
                        if (is_nan(aspect_width) || !is_finite(aspect_width) || aspect_width <= 0
                                || is_nan(aspect_height) || !is_finite(aspect_height) || aspect_height <= 0) {
                                print($"[Renderer] Invalid aspect ratio '{aspect_value}', using 16:9");
                                render_aspect_width = 16;
                                render_aspect_height = 9;
                                global.render_aspect_ratio = "16:9";
                        } else {
                                render_aspect_width = aspect_width;
                                render_aspect_height = aspect_height;
                                global.render_aspect_ratio = $"{string(aspect_width)}:{string(aspect_height)}";
                        };
                };
        } else if (parameter_string(i) == "-crf" && i + 1 < param_count) {
                i++;
                global.render_crf = clamp(round(real(parameter_string(i))), 0, 51);
        } else if (parameter_string(i) == "-preset" && i + 1 < param_count) {
                i++;
                global.render_preset = string_lower(parameter_string(i));
        } else if (parameter_string(i) == "-encoder" && i + 1 < param_count) {
                i++;
                global.render_encoder = string_lower(parameter_string(i));
        } else if (parameter_string(i) == "-render-seed" && i + 1 < param_count) {
                i++;
                global.render_seed = real(parameter_string(i));
        } else if (parameter_string(i) == "-ffmpeg" && i + 1 < param_count) {
                i++;
                global.render_ffmpeg = parameter_string(i);
        } else if (parameter_string(i) == "-exit-test") {
                global.pls_exit_test = true;
        };
};

global.render_height = render_base_height;
global.render_width = max(2, round((render_base_height * render_aspect_width / render_aspect_height) / 2) * 2);

if (global.render_mode) {
	global.render_cli = true;
        if (!string_length(global.render_output)) {
                global.render_output = working_directory + "render.mp4";
        };
        var render_session = chart_session_reset();
        render_session.source_path = global.render_source;
        var render_source_type = directory_exists(global.render_source) ? "directory"
                : ((chart_path_ext(global.render_source) == ".zip" || chart_path_ext(global.render_source) == ".pez") ? "archive" : "file");
        print($"[Renderer] Source ({render_source_type}): {global.render_source}");
        room_goto(room_loading);
} else if (global.pls_archive_test) {
        var session = chart_session_reset();
        session.source_path = global.pls_archive_test_path;
        print($"[ArchiveTest] Source: {global.pls_archive_test_path}");
        room_goto(room_loading);
} else {
        room_goto(room_menu);
};
