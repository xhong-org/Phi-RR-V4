///@desc 创建：读取并归一化 RPE extra.json 里的视频和特效
// 画在 oBG_1 前面。绘制先压暗插图，再由视频盖住这层压暗。
depth = DEPTH.BG - 2;
videos = [];
video_layers = [];
video_chart_time = 0;
video_last_chart_time = -infinity;
video_backend_ready = false;
video_os_paused = false;
effect_controller = -1;
effect_layer_passes = [];
requests_chart_layers = false;

var extra_path = "";
var extra_allowed = true;
// 会话指定了 extra 文件才读；明确没有就不要回退到 extra.json。
if (variable_global_exists("chart_session") && is_struct(global.chart_session) && global.chart_session.ready) {
	if (is_string(global.chart_session.extra_file) && string_length(global.chart_session.extra_file)) {
		extra_path = chart_path_join(InChartPath, global.chart_session.extra_file);
	} else {
		extra_allowed = false;
	};
};
if (extra_allowed && !string_length(extra_path)) then extra_path = chart_path_join(InChartPath, "extra.json");
var extra_root = string_length(extra_path) ? chart_path_dir(extra_path) : InChartPath;

// 文件存在时按平台初始化视频后端。
if (string_length(extra_path) && chart_file_exists_any(extra_path)) {
	// Windows 需要 D3D11 设备和上下文。
	if (os_type == os_windows && extension_exists("FFVideos")) {
		var video_d3d_info = os_get_info();
		if (ds_exists(video_d3d_info, ds_type_map)
			&& ds_map_exists(video_d3d_info, "video_d3d11_device")
			&& ds_map_exists(video_d3d_info, "video_d3d11_context")) {
			video_backend_ready = ffvideos_ext_initialize(
				video_d3d_info[? "video_d3d11_device"],
				video_d3d_info[? "video_d3d11_context"]) == 3;
		};
		if (ds_exists(video_d3d_info, ds_type_map)) then ds_map_destroy(video_d3d_info);
	// Android 和 GX 用空指针初始化各自后端。
	} else if (os_type == os_android) {
		video_backend_ready = ffvideos_ext_initialize(pointer_null, pointer_null) == 3;
		if (video_backend_ready) then print("[FFVideos] Android MediaCodec backend ready");
	} else if (pls_is_gxgames()) {
		video_backend_ready = ffvideos_ext_initialize(pointer_null, pointer_null) == 3;
		print($"[GXVideo] ping={video_backend_ready ? 1 : 0} error={ffvideos_ext_get_error(0)}");
		if (video_backend_ready) then print("[GXVideo] HTMLVideo backend ready");
		else print("[GXVideo] HTMLVideo backend waiting; Step will retry ping");
	};
	// GX 允许稍后在步进里重试，其他平台失败就记日志。
	if (!video_backend_ready && !pls_is_gxgames()) then print($"[FFVideos] Initialization failed: {ffvideos_ext_get_error(0)}");
};

///@desc 读取 extra 文本，优先走谱面读取再退回逐行缓冲
///@param {String} path 文件路径
///@returns {String} 文本，失败为空串
var read_extra_text = function(path) {
	// 路径无效直接空串。
	if (!is_string(path) || !string_length(path)) then return "";
	var native_text = chart_read_text_file(path, -1);
	// 原生读取成功就不用再逐行拼。
	if (is_string(native_text) && string_length(native_text)) then return native_text;
	var handle = file_text_open_read(chart_file_readable_path(path));
	// 文本文件打不开。
	if (is_undefined(handle) || handle < 0) then return "";
	var temp = buffer_create(65536, buffer_grow, 1);
	// 逐行写入可增长缓冲，保留换行。
	while (!file_text_eof(handle)) {
		buffer_write(temp, buffer_text, file_text_readln(handle));
		buffer_write(temp, buffer_text, "\n");
	};
	file_text_close(handle);
	var text = "";
	if (buffer_tell(temp) > 0) {
		buffer_seek(temp, buffer_seek_start, 0);
		text = buffer_read(temp, buffer_text);
	};
	buffer_delete(temp);
	return is_string(text) ? text : "";
};

///@desc 把 RPE 节拍数组或数字换成拍数
///@param {Any} value 节拍数组 [整数, 分子, 分母] 或实数
///@param {Real} fallback 无法解析时的默认拍
///@returns {Real} 拍数
extra_beat_value = function(value, fallback = 0) {
	// 三分量节拍：整数加分子除以分母，分母为 0 则不用。
	if (is_array(value) && array_length(value) >= 3) {
		var denominator = real(value[2]);
		// 分母为 0 不能除。
		if (denominator != 0) then return real(value[0]) + real(value[1]) / denominator;
	};
	// 已经是数字就直接用，否则回退。
	if (is_real(value)) then return value;
	return fallback;
};

var extra_text = "";
if (extra_allowed && string_length(extra_path) && chart_file_exists_any(extra_path)) {
	extra_text = read_extra_text(extra_path);
};
var extra = undefined;
if (string_length(extra_text)) {
	try { extra = json_parse(extra_text); } catch (error) { delete(error); };
};
delete(extra_text);

if (is_struct(extra)) {
	extra_bpm_points = [];
	var extra_bpm = extra[$ "bpm"];
	// 单个 BPM 从 0 拍开始；数组则收集每个大于 0 的点。
	if (is_real(extra_bpm) && extra_bpm > 0) {
		array_add(extra_bpm_points, { beat: 0, second: 0, bpm: extra_bpm });
	} else if (is_array(extra_bpm)) {
		for (var bpm_i = 0; bpm_i < array_length(extra_bpm); bpm_i++) {
			var bpm_item = extra_bpm[bpm_i];
			if (is_struct(bpm_item) && real(bpm_item[$ "bpm"] ?? 0) > 0) {
				array_add(extra_bpm_points, { beat: extra_beat_value(bpm_item[$ "time"], 0), second: 0, bpm: real(bpm_item[$ "bpm"]) });
			};
		};
	};
	// 一个点都没有就用 120。
	if (array_length(extra_bpm_points) <= 0) then array_add(extra_bpm_points, { beat: 0, second: 0, bpm: 120 });
	array_sort(extra_bpm_points,
///@desc 按节拍先后比较两个 BPM 点
///@param {Struct} a 前一个点
///@param {Struct} b 后一个点
///@returns {Real} a 更早为负，更晚为正
function(a, b) { return sign(a.beat - b.beat); });
	// 用上一段 BPM 把节拍积分成秒。
	for (var bpm_j = 1; bpm_j < array_length(extra_bpm_points); bpm_j++) {
		var previous_bpm = extra_bpm_points[bpm_j - 1];
		extra_bpm_points[bpm_j].second = previous_bpm.second + (extra_bpm_points[bpm_j].beat - previous_bpm.beat) * 60 / previous_bpm.bpm;
	};
///@desc 按分段 BPM 把拍数换成秒
///@param {Real} beat 拍数
///@returns {Real} 对应秒数
	extra_beat_to_second = function(beat) {
		var point = extra_bpm_points[0];
		for (var point_i = 1; point_i < array_length(extra_bpm_points); point_i++) {
			// 停在最后一个不晚于目标拍的点。
			if (extra_bpm_points[point_i].beat > beat) then break;
			point = extra_bpm_points[point_i];
		};
		return point.second + (beat - point.beat) * 60 / point.bpm;
	};
///@desc 把动画数组或常数收成可采样结构
///@param {Any} raw 常数或事件数组
///@param {Real} fallback 缺省值
///@returns {Struct} fixed 为真时只用 value
	extra_parse_anim = function(raw, fallback) {
		// 不是数组就当成固定值。
		if (!is_array(raw)) then return { fixed: true, value: real(raw ?? fallback), events: [] };
		var result = { fixed: false, value: fallback, events: [] };
		for (var anim_i = 0; anim_i < array_length(raw); anim_i++) {
			var event = raw[anim_i];
			// 跳过坏条目。
			if (!is_struct(event)) then continue;
			array_add(result.events, {
				startTime: extra_beat_to_second(extra_beat_value(event[$ "startTime"], 0)),
				endTime: extra_beat_to_second(extra_beat_value(event[$ "endTime"], 0)),
				start: real(event[$ "start"] ?? fallback),
				"end" : real(event[$ "end"] ?? fallback),
				easingType: real(event[$ "easingType"] ?? 1),
				easingLeft: real(event[$ "easingLeft"] ?? 0),
				easingRight: real(event[$ "easingRight"] ?? 1)
			});
		};
		array_sort(result.events,
///@desc 按开始时间排序动画事件
///@param {Struct} a 前一个事件
///@param {Struct} b 后一个事件
///@returns {Real} a 更早为负
function(a, b) { return sign(a.startTime - b.startTime); });
		return result;
	};
///@desc 把视频缩放模式收成 fit、inside 或 cropCenter
///@param {Any} raw 原始模式字符串
///@returns {String} 归一化后的模式
	extra_video_scale = function(raw) {
		var mode = string_lower(string(raw ?? "cropCenter"));
		// 只认 fit 和 inside，其余都是居中裁切。
		if (mode == "fit") then return "fit";
		if (mode == "inside") then return "inside";
		return "cropCenter";
	};
///@desc 解析视频吸附到判定线的参数
///@param {Any} raw 原始 attach 结构
///@returns {Struct} 吸附参数，无效时无返回值
	extra_video_attach = function(raw) {
		// 不是结构或线号非法就没有吸附。
		if (!is_struct(raw)) then return undefined;
		var line_id = floor(real(raw[$ "line"] ?? -1));
		// 线号非法就没有吸附。
		if (line_id < 0) then return undefined;
		// 省略系数时保持旧行为，完全跟着判定线。
		// 显式 0 是 PhiZone 的“不继承”，cropCenter 会留在谱面视口中心，而不是被线带出画面。
		var has_x = is_real(raw[$ "positionXFactor"]);
		var has_y = is_real(raw[$ "positionYFactor"]);
		return {
			line: line_id,
			position_x_factor: (has_x ? real(raw[$ "positionXFactor"]) : 1),
			position_y_factor: (has_y ? real(raw[$ "positionYFactor"]) : 1),
			rotation_factor: real(raw[$ "rotationFactor"] ?? 1),
			tint_factor: real(raw[$ "tintFactor"] ?? 1),
			scale_x_mode: floor(real(raw[$ "scaleXMode"] ?? 0)),
			scale_y_mode: floor(real(raw[$ "scaleYMode"] ?? 0))
		};
	};
///@desc 在谱面时间上采样一段动画
///@param {Struct} anim extra_parse_anim 的结果
///@param {Real} chart_time 谱面秒
///@returns {Real} 采样值
	sample_anim = function(anim, chart_time) {
		// 固定值或没有事件就直接返回。
		if (anim.fixed || !is_array(anim.events) || array_length(anim.events) <= 0) then return anim.value;
		var sampled = anim.value;
		for (var sample_i = 0; sample_i < array_length(anim.events); sample_i++) {
			var sample_event = anim.events[sample_i];
			// 还没到这条的开始，后面更晚，停在上一个终点。
			if (chart_time < sample_event.startTime) then break;
			// 落在区间内就做缓动。
			if (chart_time <= sample_event.endTime) {
				return tween_execute(chart_time, sample_event.startTime, sample_event.endTime,
					sample_event.start, sample_event[$ "end"], sample_event.easingType,
					sample_event.easingLeft, sample_event.easingRight);
			};
			sampled = sample_event[$ "end"];
		};
		return sampled;
	};
	var raw_videos = (is_array(extra[$ "videos"]) ? extra.videos : []);
	for (var video_i = 0; video_i < array_length(raw_videos); video_i++) {
		var source = raw_videos[video_i];
		// 没有路径的条目跳过。
		if (!is_struct(source) || !is_string(source[$ "path"])) then continue;
		var relative_path = string_replace_all(source.path, "\\", "/");
		// 拒绝跳出谱面目录的路径。
		if (string_pos("..", relative_path) > 0 || string_char_at(relative_path, 1) == "/") then continue;
		if (is_real(source[$ "zIndex"])) then requests_chart_layers = true;
		array_add(videos, {
			path: chart_file_readable_path(chart_path_join(extra_root, relative_path)),
			startTime: extra_beat_to_second(extra_beat_value(source[$ "time"], 0)),
			endTime: infinity,
			duration_ms: 0,
			scale: extra_video_scale(source[$ "scale"] ?? "cropCenter"),
			zIndex: (is_real(source[$ "zIndex"] ?? undefined) ? real(source[$ "zIndex"]) : undefined),
			attach: extra_video_attach(source[$ "attach"] ?? undefined),
			alpha: extra_parse_anim(source[$ "alpha"], 1),
			dim: extra_parse_anim(source[$ "dim"], 0),
			handle: -1,
			error_logged: false,
			draw_logged: false,
			completed: false,
			clip_surface: -1
	});
	};
	array_sort(videos,
///@desc 按开始时间排序视频
///@param {Struct} a 前一段
///@param {Struct} b 后一段
///@returns {Real} a 更早为负
function(a, b) { return sign(a.startTime - b.startTime); });
	print($"[FFVideos] Parsed videos={array_length(videos)}, extra={extra_path}");
	for (var video_log_i = 0; video_log_i < array_length(videos); video_log_i++) {
		var video_log_path = videos[video_log_i].path;
		var video_log_host = gx_media_host_path_for(video_log_path);
		print($"[FFVideos] Video[{video_log_i}] path={video_log_path}, exists={gx_media_source_exists(video_log_path)}, host={video_log_host}, start={videos[video_log_i].startTime}");
	};
	if (is_array(extra[$ "effects"])) {
		for (var layer_effect_i = 0; layer_effect_i < array_length(extra.effects); layer_effect_i++) {
			var layer_effect = extra.effects[layer_effect_i];
			// 带目标范围的特效需要谱面分层。
			if (is_struct(layer_effect) && is_struct(layer_effect[$ "targetRange"])) {
				requests_chart_layers = true;
				break;
			};
		};
	};
	var parsed_effects = rpe_effect_parse(extra, extra_bpm_points);
	effect_layer_passes = parsed_effects.local;
	if (array_length(effect_layer_passes) > 0) then requests_chart_layers = true;
	print($"[RPE Effect] Parsed shaders: local={array_length(parsed_effects.local)}, global={array_length(parsed_effects.global)}");
	// 有本地或全局着色器才创建控制器。
	if (array_length(parsed_effects.local) > 0 || array_length(parsed_effects.global) > 0) {
		var effect_depth = requests_chart_layers ? chart_layer_depth(24) : (DEPTH.DEBUG + 1);
		effect_controller = instance_create_depth(0, 0, effect_depth, oRPEEffect, {
			effects_local:parsed_effects.local,
			effects_global:parsed_effects.global
		});
	};
};

// 一段视频播到自己的文件结束，下一段不会替换它。
// PhiZone 用开始加时长，所以更高的层可以盖住下面那层。
for (var video_layer_i = 0; video_layer_i < array_length(videos); video_layer_i++) {
	// 没有 z 的视频不单独建图层。
	if (!is_real(videos[video_layer_i].zIndex)) then continue;
	array_add(video_layers, instance_create_depth(0, 0, chart_layer_depth(videos[video_layer_i].zIndex), oExtraVideoLayer, {
		video_layer_owner: id,
		video_layer_index: video_layer_i
	}));
};

///@desc 关闭全部已打开的视频句柄
///@returns {Undefined} 无
video_close_all = function() {
	for (var _close_i = 0; _close_i < array_length(videos); _close_i++) {
		// 只关还开着的句柄。
		if (videos[_close_i].handle >= 0) then ffvideos_ext_close(videos[_close_i].handle);
		videos[_close_i].handle = -1;
	};
};

// 这条线当前吸附的视频。没有自己 z 的片段跟线一起画；
// 有 z 的只回报下标，让线留在自己的层上。
///@desc 查找吸附在这条判定线上的视频下标
///@param {Id.Instance} line_instance 判定线实例
///@returns {Real} 视频下标，没有则为 -1
video_line_index = function(line_instance) {
	// 关掉视频或线不存在。
	if (chart_setting_on("disableChartVideo") || !instance_exists(line_instance)) then return -1;
	var _layered = -1;
	for (var _line_i = 0; _line_i < array_length(videos); _line_i++) {
		var _line_video = videos[_line_i];
		// 没打开或没有吸附就跳过。
		if (_line_video.handle < 0 || !is_struct(_line_video.attach)) then continue;
		// 不是这条线就跳过。
		if (_line_video.attach.line != line_instance.line_id) then continue;
		// 没有 z 的优先返回，有 z 的只记住第一条。
		if (!is_real(_line_video.zIndex)) then return _line_i;
		if (_layered < 0) then _layered = _line_i;
	};
	return _layered;
};

///@desc 这条判定线是否吸附了正在播放的视频
///@param {Id.Instance} line_instance 判定线实例
///@returns {Bool} 有吸附则为 true
video_attached_to_line = function(line_instance) {
	return video_line_index(line_instance) >= 0;
};

///@desc 按是否吸附选择绘制一段视频
///@param {Real} _index 视频下标
///@returns {Undefined} 无
video_draw_index = function(_index) {
	// 关掉视频、下标越界、没打开或已播完都不画。
	if (chart_setting_on("disableChartVideo")) then return;
	if (_index < 0 || _index >= array_length(videos)) then return;
	var _draw_video = videos[_index];
	if (_draw_video.handle < 0 || _draw_video.completed) then return;
	// 不在播放区间。
	if (video_chart_time < _draw_video.startTime || video_chart_time >= _draw_video.endTime) then return;
	// 有吸附跟线画，否则铺满视口。
	if (is_struct(_draw_video.attach)) then draw_attached_video(_index);
	else video_draw_fullscreen(_index);
};

///@desc 在独立表面解码，再按局部裁切、旋转和有符号缩放绘制视频
///@param {Struct} video 视频记录
///@param {Real} width 原始宽度
///@param {Real} height 原始高度
///@param {Real} sx 水平缩放
///@param {Real} sy 垂直缩放
///@param {Real} ax 中心 X
///@param {Real} ay 中心 Y
///@param {Real} angle 旋转角度
///@param {Real} tint 染色
///@param {Real} alpha 透明度
///@param {Real} dim 压暗
///@param {Real} clip_w 局部裁切宽度
///@param {Real} clip_h 局部裁切高度
///@returns {Undefined} 无
draw_transformed_video = function(video, width, height, sx, sy, ax, ay, angle, tint, alpha, dim, clip_w, clip_h) {
	if (sx == 0 || sy == 0 || alpha <= 0 || clip_w <= 0 || clip_h <= 0) then return;
	if (surface_exists(video.clip_surface)
		&& (surface_get_width(video.clip_surface) != width || surface_get_height(video.clip_surface) != height)) {
		surface_free(video.clip_surface);
		video.clip_surface = -1;
	};
	if (!surface_exists(video.clip_surface)) then video.clip_surface = surface_create(width, height);
	if (!surface_exists(video.clip_surface)) then return;
	pls_draw_flush();
	gpu_push_state();
	surface_set_target(video.clip_surface);
	draw_clear_alpha(c_black, 0);
	gpu_set_scissor(0, 0, width, height);
	// 原生视频读取实际 D3D 目标。提交一笔透明绘制，确保新表面已经绑定。
	chart_gpu_blend_commit();
	var drawn = ffvideos_ext_draw(video.handle, 0, 0, 1, 1, 1, dim);
	surface_reset_target();
	gpu_pop_state();
	if (drawn <= 0) then return;
	var source_w = min(width, clip_w / abs(sx));
	var source_h = min(height, clip_h / abs(sy));
	var local_x = -source_w * sx * 0.5;
	var local_y = -source_h * sy * 0.5;
	var c = dcos(angle);
	var s = dsin(angle);
	chart_mask_scissor_set();
	draw_surface_general(video.clip_surface, (width - source_w) * 0.5, (height - source_h) * 0.5,
		source_w, source_h, ax + c * local_x + s * local_y, ay - s * local_x + c * local_y,
		sx, sy, angle, tint, tint, tint, tint, alpha);
	pls_draw_flush();
};

///@desc 把视频画在它吸附的判定线上
///@param {Real} _index 视频下标
///@returns {Undefined} 无
draw_attached_video = function(_index) {
	// 关掉、越界、没打开或没有吸附就不画。
	if (chart_setting_on("disableChartVideo")) then return;
	if (_index < 0 || _index >= array_length(videos)) then return;
	var video = videos[_index];
	if (video.handle < 0 || !is_struct(video.attach)) then return;
	var line_instance = noone;
	var attached_id = video.attach.line;
	if (variable_global_exists("game_1") && is_struct(game_1) && is_array(game_1.line_list)
		&& attached_id >= 0 && attached_id < array_length(game_1.line_list)) {
		line_instance = game_1.line_list[attached_id];
	};
	// 判定线实例不在了。
	if (!instance_exists(line_instance)) then return;
	var _handle = video.handle;
	var status = ffvideos_ext_get_status(_handle);
	// 渲染模式会准备精确帧，不一定进入 Playing 或 Paused。
	// Ended 也有效，解码器可以留着准备好的最后一帧；没有可画帧的状态才拒绝。
	if (status == FFVideosStatus.Preparing) {
		ffvideos_ext_draw(_handle, 0, 0, 0, 0, 0, 0);
		return;
	};
	// 出错或已关闭没有画面。
	if (status == FFVideosStatus.Error || status == FFVideosStatus.Closed) then return;
	var video_width = ffvideos_ext_get_width(_handle);
	var video_height = ffvideos_ext_get_height(_handle);
	// 尺寸还是 0 就先空画一次，让解码器报出宽高。
	if (video_width <= 0 || video_height <= 0) {
		ffvideos_ext_draw(_handle, 0, 0, 0, 0, 0, 0);
		video_width = ffvideos_ext_get_width(_handle);
		video_height = ffvideos_ext_get_height(_handle);
	};
	if (video_width <= 0 || video_height <= 0) then return;

	var sx = chart_view_width / video_width;
	var sy = chart_view_height / video_height;
	var draw_sx = (video.scale == "fit" ? sx : (video.scale == "inside" ? min(sx, sy) : max(sx, sy)));
	var draw_sy = (video.scale == "fit" ? sy : draw_sx);
	// scaleXMode 1 才缩放。模式 2 和 3 是裁切，不能把画面缩小。
	if (video.attach.scale_x_mode == 1) then draw_sx *= real(line_instance.__scale_x);
	if (video.attach.scale_y_mode == 1) then draw_sy *= real(line_instance.__scale_y);
	var draw_width = video_width * draw_sx;
	var draw_height = video_height * draw_sy;
	var center_x = chart_view_left + chart_view_width * 0.5;
	var center_y = chart_view_height * 0.5;
	var anchor_x = center_x + (line_instance.x - center_x) * video.attach.position_x_factor;
	var anchor_y = center_y + (line_instance.y - center_y) * video.attach.position_y_factor;
	var draw_x = anchor_x - draw_width * 0.5;
	var draw_y = anchor_y - draw_height * 0.5;
	// PhiZone 每帧先更新判定线附着，再由 Video.update 写入视频 alpha。
	// 因而最终透明度来自视频动画，不能用线 alpha 或 alphaFactor=0 隐藏它。
	var alpha = clamp(real(video.alpha.value), 0, 1);
	var dim = clamp(real(video.dim.value), 0, 1);
	var angle = line_instance.image_angle * video.attach.rotation_factor;
	var tint = c_white;
	if (video.attach.tint_factor != 0) {
		// 上游对 0xRRGGBB 整数插值；GML 颜色采用 0xBBGGRR，先转换再插值。
		var line_colour = line_instance.__color;
		var packed = colour_get_red(line_colour) * 65536 + colour_get_green(line_colour) * 256 + colour_get_blue(line_colour);
		packed = floor(packed * video.attach.tint_factor + (1 - video.attach.tint_factor) * 16777215);
		tint = make_colour_rgb((packed >> 16) & 255, (packed >> 8) & 255, packed & 255);
	};
	var clip_w = abs(draw_width);
	var clip_h = abs(draw_height);
	if (video.attach.scale_x_mode == 2) then clip_w = chart_line_pixel_width(line_instance);
	else if (video.attach.scale_x_mode == 3) then clip_w *= abs(real(line_instance.__scale_x));
	if (video.attach.scale_y_mode == 2) then clip_h *= abs(real(line_instance.__scale_y));
	if (alpha <= 0 || draw_sx == 0 || draw_sy == 0 || clip_w <= 0 || clip_h <= 0) then return;
	if (angle != 0 || tint != c_white || draw_sx < 0 || draw_sy < 0) {
		draw_transformed_video(video, video_width, video_height, draw_sx, draw_sy,
			anchor_x, anchor_y, angle, tint, alpha, dim, clip_w, clip_h);
		rpe_effect_grade_backdrop();
		chart_gpu_blend_commit();
		return;
	};
	var mask_x = anchor_x - clip_w * 0.5;
	var mask_y = anchor_y - clip_h * 0.5;
	// 裁切框明显小于画面才需要剪刀。
	var needs_clip = (clip_w + 0.5 < draw_width) || (clip_h + 0.5 < draw_height);
	pls_draw_flush();
	chart_mask_scissor_clear();
	// scaleXMode 2/3 是遮罩不是缩放。FFVideos 直接画进当前 D3D 目标，忽略嵌套表面，
	// 旧的回退会把整帧画上去盖住谱面。在未裁切绘制已经使用的同一目标上剪刀出线带。
	if (needs_clip && clip_w > 1 && clip_h > 1) {
		var scissor_x = max(0, floor(mask_x));
		var scissor_y = max(0, floor(mask_y));
		var scissor_r = ceil(mask_x + clip_w);
		var scissor_b = ceil(mask_y + clip_h);
		if (variable_global_exists("chart_view_right") && is_real(chart_view_right)) {
			scissor_r = min(scissor_r, ceil(chart_view_right));
		};
		if (variable_global_exists("chart_view_height") && is_real(chart_view_height)) {
			scissor_b = min(scissor_b, ceil(chart_view_height));
		};
		gpu_set_scissor(scissor_x, scissor_y, max(1, scissor_r - scissor_x), max(1, scissor_b - scissor_y));
	};
	// 裁切框太小就不画，避免零面积。
	if (clip_w > 1 && clip_h > 1) {
		chart_gpu_blend_commit();
		ffvideos_ext_draw(_handle,
			draw_x / room_width, draw_y / room_height,
			(draw_x + draw_width) / room_width, (draw_y + draw_height) / room_height,
			alpha, dim);
	};
	chart_mask_scissor_set();
	rpe_effect_grade_backdrop();
	chart_gpu_blend_commit();
};

///@desc 把视频按视口模式铺满绘制
///@param {Real} _index 视频下标
///@returns {Undefined} 无
video_draw_fullscreen = function(_index) {
	// 下标越界或句柄无效就不画。
	if (_index < 0 || _index >= array_length(videos)) then return;
	var video = videos[_index];
	if (video.handle < 0) then return;
	var _handle = video.handle;
	var status = ffvideos_ext_get_status(_handle);
	// 准备中或还没有尺寸时先空画，让表面建起来。
	if (status == FFVideosStatus.Preparing || ffvideos_ext_get_width(_handle) <= 0) {
		var surface_status = ffvideos_ext_draw(_handle, 0, 0, 0, 0, 0, 0);
		if (surface_status < 0 && !video.error_logged) {
			print($"[FFVideos] Surface/draw setup: status={surface_status}, error={ffvideos_ext_get_error(_handle)}");
		};
		status = ffvideos_ext_get_status(_handle);
	};
	// 全屏绘制只接受正在播放或暂停。
	if (status != FFVideosStatus.Playing && status != FFVideosStatus.Paused) then return;
	var video_width = ffvideos_ext_get_width(_handle);
	var video_height = ffvideos_ext_get_height(_handle);
	// 再试一次取宽高，仍然没有就退出。
	if (video_width <= 0 || video_height <= 0) {
		ffvideos_ext_draw(_handle, 0, 0, 0, 0, 0, 0);
		video_width = ffvideos_ext_get_width(_handle);
		video_height = ffvideos_ext_get_height(_handle);
	};
	if (video_width <= 0 || video_height <= 0) then return;
	var scale_mode = video.scale;
	var sx = chart_view_width / video_width;
	var sy = chart_view_height / video_height;
	var draw_sx;
	var draw_sy;
	// fit 拉伸铺满，inside 完整放入，其余居中裁切。
	switch (scale_mode) {
		case "fit":
			draw_sx = sx;
			draw_sy = sy;
		break;
		case "inside":
			draw_sx = min(sx, sy);
			draw_sy = draw_sx;
		break;
		default:
			draw_sx = max(sx, sy);
			draw_sy = draw_sx;
		break;
	};
	var draw_width = video_width * draw_sx;
	var draw_height = video_height * draw_sy;
	var draw_x = chart_view_left + (chart_view_width - draw_width) * 0.5;
	var draw_y = (chart_view_height - draw_height) * 0.5;
	var alpha = clamp(real(video.alpha.value), 0, 1);
	var dim = clamp(real(video.dim.value), 0, 1);
	pls_draw_flush();
	// FFVideos 读的是原始 D3D11 目标和视口。嵌套遮罩表面会让那个视口是空的，
	// 绘制返回 0，后面的遮罩贴回就会盖住缺失的帧。直接画进谱面表面，遮罩合成只保留视口。
	chart_mask_scissor_clear();
	chart_gpu_blend_commit();
	var video_draw_status = ffvideos_ext_draw(_handle,
		draw_x / room_width,
		draw_y / room_height,
		(draw_x + draw_width) / room_width,
		(draw_y + draw_height) / room_height,
		alpha,
		dim);
	chart_mask_scissor_set();
	chart_gpu_blend_commit();
	// 失败只记一次；成功也只记第一次。
	if (video_draw_status < 0) {
		if (!video.error_logged) {
			print($"[FFVideos] Draw failed: status={status}, size={video_width}x{video_height}, error={ffvideos_ext_get_error(_handle)}");
			video.error_logged = true;
		};
	} else if (!video.draw_logged) {
		print($"[FFVideos] Draw: status={status}, size={video_width}x{video_height}, draw={video_draw_status}, error={ffvideos_ext_get_error(_handle)}");
		video.draw_logged = true;
	};
};
