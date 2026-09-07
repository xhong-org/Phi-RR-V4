/// @description Resolve recursive RPE parent transforms before drawing.
if (!variable_global_exists("game_1") || !is_struct(game_1) || !is_array(game_1.line_list)) then exit;

var line_count = array_length(game_1.line_list);
var worker_resolved = false;
var worker_enabled = bool(game.settings.enableRPEMulticore ?? true);
var worker_min_lines = max(1, floor(real(game.settings.rpeWorkerMinLines ?? 32)));
var worker_profile_frames = max(60, floor(real(game.settings.rpeWorkerProfileFrames ?? 1800)));
var worker_render_mode = variable_global_exists("render_mode") && global.render_mode;
var worker_window_width = chart_view_width;
var worker_window_height = chart_view_height;
var worker_view_left = chart_view_left;
var worker_scale_x = worker_window_width / 1350.0;
var worker_scale_y = worker_window_height / 900.0;
var worker_half_width = worker_window_width * 0.5;
var worker_half_height = worker_window_height * 0.5;
var line_layout_changed = !variable_instance_exists(id, "_rpe_layout_width")
	|| !variable_instance_exists(id, "_rpe_layout_height")
	|| _rpe_layout_width != worker_window_width || _rpe_layout_height != worker_window_height;
_rpe_layout_width = worker_window_width;
_rpe_layout_height = worker_window_height;
var line_resolve_start = get_timer();
if (worker_enabled && os_type == os_windows && extension_exists("I_Parallel") && line_count >= worker_min_lines) {
	var worker_frame_start = get_timer();
	var hierarchy_size = line_count * 8;
	var input_size = line_count * 24;
	var output_size = line_count * 24;
	if (!variable_instance_exists(id, "_rpe_worker_input") || !buffer_exists(_rpe_worker_input)) {
		_rpe_worker_hierarchy = buffer_create(hierarchy_size, buffer_fixed, 1);
		_rpe_worker_input = buffer_create(input_size, buffer_fixed, 1);
		_rpe_worker_output = buffer_create(output_size, buffer_fixed, 1);
		_rpe_worker_uploaded_count = -1;
	} else {
		if (!buffer_exists(_rpe_worker_hierarchy)) _rpe_worker_hierarchy = buffer_create(hierarchy_size, buffer_fixed, 1);
		else if (buffer_get_size(_rpe_worker_hierarchy) != hierarchy_size) buffer_resize(_rpe_worker_hierarchy, hierarchy_size);
		if (buffer_get_size(_rpe_worker_input) != input_size) buffer_resize(_rpe_worker_input, input_size);
		if (buffer_get_size(_rpe_worker_output) != output_size) buffer_resize(_rpe_worker_output, output_size);
	};
	if (_rpe_worker_uploaded_count != line_count) {
		for (var hierarchy_line_index = 0; hierarchy_line_index < line_count; hierarchy_line_index++) {
			var hierarchy_line = game_1.line_list[hierarchy_line_index];
			var hierarchy_offset = hierarchy_line_index * 8;
			var hierarchy_parent = -1;
			var hierarchy_rotate = 0;
			if (instance_exists(hierarchy_line)) {
				hierarchy_parent = is_real(hierarchy_line.isFather) ? floor(hierarchy_line.isFather) : -1;
				hierarchy_rotate = bool(hierarchy_line.rotFatherLine);
			};
			buffer_poke(_rpe_worker_hierarchy, hierarchy_offset, buffer_s32, hierarchy_parent);
			buffer_poke(_rpe_worker_hierarchy, hierarchy_offset + 4, buffer_s32, hierarchy_rotate);
		};
		if (rpe_worker_upload_lines(buffer_get_address(_rpe_worker_hierarchy), line_count)) {
			_rpe_worker_uploaded_count = line_count;
		};
	};
	var worker_snapshot_start = get_timer();
	buffer_seek(_rpe_worker_input, buffer_seek_start, 0);
	for (var worker_line_index = 0; worker_line_index < line_count; worker_line_index++) {
		var worker_line = game_1.line_list[worker_line_index];
		if (instance_exists(worker_line)) {
			buffer_write(_rpe_worker_input, buffer_f64, real(worker_line.__raw_x));
			buffer_write(_rpe_worker_input, buffer_f64, real(worker_line.__raw_y));
			buffer_write(_rpe_worker_input, buffer_f64, real(worker_line.__raw_r));
		} else {
			buffer_write(_rpe_worker_input, buffer_f64, 0);
			buffer_write(_rpe_worker_input, buffer_f64, 0);
			buffer_write(_rpe_worker_input, buffer_f64, 0);
		};
	};
	var worker_snapshot_us = get_timer() - worker_snapshot_start;
	var worker_native_start = get_timer();
	var worker_count = rpe_worker_resolve_lines(
		buffer_get_address(_rpe_worker_input), line_count, buffer_get_address(_rpe_worker_output));
	var worker_native_us = get_timer() - worker_native_start;
	worker_resolved = worker_count > 0;
	if (worker_resolved) {
		if (!variable_instance_exists(id, "_rpe_worker_logged") || !_rpe_worker_logged) {
			print($"[RPE Worker] Parallel line resolver enabled: workers={worker_count}, lines={line_count}");
			_rpe_worker_logged = true;
		};
		var worker_apply_start = get_timer();
		buffer_seek(_rpe_worker_output, buffer_seek_start, 0);
		for (var result_line_index = 0; result_line_index < line_count; result_line_index++) {
			var result_child = game_1.line_list[result_line_index];
			var result_world_x = buffer_read(_rpe_worker_output, buffer_f64);
			var result_world_y = buffer_read(_rpe_worker_output, buffer_f64);
			var result_world_r = buffer_read(_rpe_worker_output, buffer_f64);
			if (!instance_exists(result_child)) then continue;
			result_child.x = result_world_x * worker_scale_x + worker_view_left + worker_half_width;
			result_child.y = -result_world_y * worker_scale_y + worker_half_height;
			result_child.image_angle = -result_world_r;
			result_child.__x = result_child.x;
			result_child.__y = result_child.y;
			result_child.__r = result_child.image_angle;
			result_child.__cos = dcos(result_child.image_angle);
			result_child.__sin = dsin(result_child.image_angle);
			if (result_child.is_attach_ui && is_string(result_child.attach_ui_key) && string_length(result_child.attach_ui_key)
				&& is_struct(bindUI) && struct_exists(bindUI, result_child.attach_ui_key)) {
				var result_ui_slot = bindUI[$ result_child.attach_ui_key];
				if (is_array(result_ui_slot) && array_length(result_ui_slot) >= 7) {
					result_ui_slot[@ 0] = result_child.x - (worker_view_left + worker_half_width);
					result_ui_slot[@ 1] = result_child.y - room_height * 0.5;
					result_ui_slot[@ 2] = result_child.image_blend;
					result_ui_slot[@ 3] = clamp(real(result_child.__raw_a) / 255, 0, 1);
					result_ui_slot[@ 4] = result_child.image_angle;
					result_ui_slot[@ 5] = result_child.__scale_x;
					result_ui_slot[@ 6] = result_child.__scale_y;
					if (is_struct(bindUI_attached)) then bindUI_attached[$ result_child.attach_ui_key] = true;
				};
			};
		};
		var worker_apply_us = get_timer() - worker_apply_start;
		var worker_total_us = get_timer() - worker_frame_start;
		if (!variable_instance_exists(id, "_rpe_worker_profile_samples")) {
			_rpe_worker_profile_samples = 0;
			_rpe_worker_profile_snapshot_us = 0;
			_rpe_worker_profile_native_us = 0;
			_rpe_worker_profile_apply_us = 0;
			_rpe_worker_profile_total_us = 0;
		};
		_rpe_worker_profile_samples++;
		_rpe_worker_profile_snapshot_us += worker_snapshot_us;
		_rpe_worker_profile_native_us += worker_native_us;
		_rpe_worker_profile_apply_us += worker_apply_us;
		_rpe_worker_profile_total_us += worker_total_us;
		if (_rpe_worker_profile_samples >= worker_profile_frames) {
			print($"[RPE Worker] avg us: snapshot={_rpe_worker_profile_snapshot_us / _rpe_worker_profile_samples}, native={_rpe_worker_profile_native_us / _rpe_worker_profile_samples}, apply={_rpe_worker_profile_apply_us / _rpe_worker_profile_samples}, total={_rpe_worker_profile_total_us / _rpe_worker_profile_samples}, lines={line_count}");
			_rpe_worker_profile_samples = 0;
			_rpe_worker_profile_snapshot_us = 0;
			_rpe_worker_profile_native_us = 0;
			_rpe_worker_profile_apply_us = 0;
			_rpe_worker_profile_total_us = 0;
		};
	};
};

if (!worker_resolved) {
	for (var line_index = 0; line_index < line_count; line_index++) {
		var child = game_1.line_list[line_index];
		if (!instance_exists(child)) then continue;

	var world_x = child.__raw_x;
	var world_y = child.__raw_y;
	var world_r = child.__raw_r;
	var parent_id = child.isFather;

	if (is_real(parent_id) && parent_id >= 0 && parent_id < line_count && parent_id != line_index) {
		var chain = [];
		var current_id = parent_id;
		var guard = 0;
		while (is_real(current_id) && current_id >= 0 && current_id < line_count && guard < line_count) {
			array_add(chain, current_id);
			var current_line = game_1.line_list[current_id];
			if (!instance_exists(current_line)) then break;
			var next_id = current_line.isFather;
			if (!is_real(next_id) || next_id < 0 || next_id == current_id) then break;
			current_id = next_id;
			guard++;
		};

		var parent_world_x = 0;
		var parent_world_y = 0;
		var parent_world_r = 0;
		var have_parent = false;
		for (var chain_index = array_length(chain) - 1; chain_index >= 0; chain_index--) {
			var ancestor = game_1.line_list[chain[chain_index]];
			if (!instance_exists(ancestor)) {
				have_parent = false;
				break;
			};
			if (!have_parent) {
				parent_world_x = ancestor.__raw_x;
				parent_world_y = ancestor.__raw_y;
				parent_world_r = ancestor.__raw_r;
				have_parent = true;
			} else {
				var parent_cos = dcos(parent_world_r);
				var parent_sin = dsin(parent_world_r);
				var next_world_x = parent_world_x + ancestor.__raw_x * parent_cos + ancestor.__raw_y * parent_sin;
				var next_world_y = parent_world_y + ancestor.__raw_y * parent_cos - ancestor.__raw_x * parent_sin;
				parent_world_x = next_world_x;
				parent_world_y = next_world_y;
				parent_world_r = ancestor.__raw_r + (ancestor.rotFatherLine ? parent_world_r : 0);
			};
		};

		if (have_parent) {
			var child_parent_cos = dcos(parent_world_r);
			var child_parent_sin = dsin(parent_world_r);
			world_x = parent_world_x + child.__raw_x * child_parent_cos + child.__raw_y * child_parent_sin;
			world_y = parent_world_y + child.__raw_y * child_parent_cos - child.__raw_x * child_parent_sin;
			world_r = child.__raw_r + (child.rotFatherLine ? parent_world_r : 0);
		};
	};

	child.x = world_x * worker_scale_x + worker_view_left + worker_half_width;
	child.y = -world_y * worker_scale_y + worker_half_height;
	child.image_angle = -world_r;
	child.__x = child.x;
	child.__y = child.y;
	child.__r = child.image_angle;
	child.__cos = dcos(child.image_angle);
	child.__sin = dsin(child.image_angle);
	if (child.is_attach_ui && is_string(child.attach_ui_key) && string_length(child.attach_ui_key)
			&& is_struct(bindUI) && struct_exists(bindUI, child.attach_ui_key)) {
		var ui_slot = bindUI[$ child.attach_ui_key];
		if (is_array(ui_slot) && array_length(ui_slot) >= 7) {
			ui_slot[@ 0] = child.x - (worker_view_left + worker_half_width);
			ui_slot[@ 1] = child.y - room_height * 0.5;
			ui_slot[@ 2] = child.image_blend;
			ui_slot[@ 3] = clamp(real(child.__raw_a) / 255, 0, 1);
			ui_slot[@ 4] = child.image_angle;
			ui_slot[@ 5] = child.__scale_x;
			ui_slot[@ 6] = child.__scale_y;
			if (is_struct(bindUI_attached)) then bindUI_attached[$ child.attach_ui_key] = true;
		};
	};
	};
	var fallback_total_us = get_timer() - line_resolve_start;
	if (!variable_instance_exists(id, "_rpe_fallback_profile_samples")) {
		_rpe_fallback_profile_samples = 0;
		_rpe_fallback_profile_total_us = 0;
	};
	_rpe_fallback_profile_samples++;
	_rpe_fallback_profile_total_us += fallback_total_us;
	if (_rpe_fallback_profile_samples >= worker_profile_frames) {
		print($"[RPE Lines] fallback avg us: total={_rpe_fallback_profile_total_us / _rpe_fallback_profile_samples}, lines={line_count}");
		_rpe_fallback_profile_samples = 0;
		_rpe_fallback_profile_total_us = 0;
	};
};

// Notes run during Step before lines finish their parent transform. Refresh only
// their visual geometry now that every line has its final world transform.
// During pause, refresh geometry only when a resize moved the judge lines.
var line_game_paused = variable_global_exists("game") && is_struct(game) && game.paused;
if (!line_game_paused || line_layout_changed) {
	with (oNote_1) {
		if (inition && instance_exists(_line_ref)) then event_user(_step_user_count);
	};
};
