///@desc 校验渲染参数并进入加载房间
setup_store_text();
var source = string_trim(path_text);
var output = string_trim(output_text);
var fps_raw = real(string_trim(fps_text));
var quality_raw = real(string_trim(quality_text));
var aspect_value = string_trim(aspect_text);
var aspect_separator = string_pos(":", aspect_value);
var aspect_width = aspect_separator > 1 ? real(string_trim(string_copy(aspect_value, 1, aspect_separator - 1))) : 0;
var aspect_height = aspect_separator > 1 ? real(string_trim(string_copy(aspect_value, aspect_separator + 1, string_length(aspect_value) - aspect_separator))) : 0;
// 缺谱面、帧率、质量或宽高比时直接退出。
if (!string_length(source)) { setup_set_status(lang("render.chartRequired")); exit; };
if (string_length(string_trim(fps_text)) <= 0 || is_nan(fps_raw) || !is_finite(fps_raw)) { setup_set_status(lang("render.fpsRange")); exit; };
if (string_length(string_trim(quality_text)) <= 0 || is_nan(quality_raw) || !is_finite(quality_raw)) { setup_set_status(lang("render.qualityRange")); exit; };
if (aspect_separator <= 1 || aspect_separator >= string_length(aspect_value) || is_nan(aspect_width) || !is_finite(aspect_width) || aspect_width <= 0 || is_nan(aspect_height) || !is_finite(aspect_height) || aspect_height <= 0) { setup_set_status(lang("render.aspectPositive")); exit; };
// 没填输出时用工作目录下的 render.mp4。
if (!string_length(output)) output = working_directory + "render.mp4";
var output_normalized = string_replace_all(output, "\\", "/");
var output_last = string_length(output_normalized) > 0 ? string_char_at(output_normalized, string_length(output_normalized)) : "";
// 输出是目录时补上默认文件名。
if (output_last == "/") output = chart_path_join(output_normalized, "render.mp4");
else if (directory_exists(output)) output = chart_path_join(output, "render.mp4");
var output_dir = chart_path_dir(output);
if (string_length(output_dir) && !directory_exists(output_dir)) { setup_set_status(lang("render.outputMissing")); exit; };
var fps_value = clamp(round(fps_raw), 1, 240);
var quality = clamp(round(quality_raw), 0, 51);
fps_text = string(fps_value);
quality_text = string(quality);
if (!file_exists(source) && !directory_exists(source)) { setup_set_status(lang("render.chartMissing")); exit; };
// 没有 ffmpeg 就不开始渲染。
if (!render_ffmpeg_require()) then exit;
global.render_source = source;
global.render_output = output;
global.render_fps = fps_value;
global.render_resolution = resolutions[resolution_index];
global.render_aspect_ratio = aspect_value;
global.render_height = (resolution_index == 0 ? 720 : (resolution_index == 1 ? 1080 : (resolution_index == 2 ? 1440 : 2160)));
global.render_width = max(2, round((global.render_height * aspect_width / aspect_height) / 2) * 2);
global.render_crf = quality;
global.render_aa_level = aa_values[aa_index];
global.render_mode = true;
global.render_cli = false;
global.render_settlement = bool(record_settlement);
global.render_settlement_finished = false;
chart_session_reset();
global.chart_session.source_path = source;
room_goto(room_loading);
