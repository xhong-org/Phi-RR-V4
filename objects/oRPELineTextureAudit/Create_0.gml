/// @description Wait for RPE lines, then audit custom texture loading once.
persistent = true;
wait_frames = 0;
audit_complete = false;
test_mode = variable_global_exists("pls_archive_test") && global.pls_archive_test;
exit_test_mode = variable_global_exists("pls_exit_test") && global.pls_exit_test;
text_probe_done = false;
print($"[RPETextureAudit] Created testMode={test_mode}");

function rpe_text_probe_reset_cursors() {
	with (oLine_1) {
		if (is_array(events_count)) {
			for (var layer_i = 0; layer_i < array_length(events_count); layer_i++) {
				var layer_counts = events_count[layer_i];
				if (!is_struct(layer_counts)) then continue;
				var count_names = struct_get_names(layer_counts);
				for (var name_i = 0; name_i < array_length(count_names); name_i++) {
					layer_counts[$ count_names[name_i]] = 0;
				};
			};
		};
		if (is_struct(ext_count)) {
			var ext_names = struct_get_names(ext_count);
			for (var ext_i = 0; ext_i < array_length(ext_names); ext_i++) {
				ext_count[$ ext_names[ext_i]] = 0;
			};
		};
	};
}

function rpe_text_probe_seek(_sec) {
	if (!variable_global_exists("game") || !is_struct(game) || !is_array(game.__time)) then return false;
	var offset_sec = 0;
	if (variable_global_exists("game_1") && is_struct(game_1) && is_struct(game_1.chart_info)) {
		offset_sec = real(game_1.chart_info.offset ?? 0) / 1000;
	};
	game.__time[1] = _sec + offset_sec;
	rpe_text_probe_reset_cursors();
	with (oLine_1) {
		rpe_force_event_init = true;
		event_perform(ev_step, ev_step_normal);
		event_perform(ev_step, ev_step_end);
		rpe_force_event_init = false;
	};
	return true;
}

function rpe_text_probe_run() {
	chart_view_refresh(room_width, room_height);
	var view_w = chart_view_width;
	var view_h = chart_view_height;
	var view_left = chart_view_left;
	var ui_scale = variable_global_exists("global_scales") ? global_scales : 1;
	var probe_font = -1;
	if (variable_global_exists("game") && is_struct(game) && !is_undefined(game.font) && font_exists(game.font)) {
		probe_font = game.font;
		draw_set_font(probe_font);
	};
	var font_px = (probe_font != -1) ? max(1, font_get_size(probe_font)) : 1;
	var box_advance = (probe_font != -1) ? string_width("■") : 0;
	var line_box = (probe_font != -1) ? string_height(" ") : 0;
	print($"[TextProbe] room={room_width}x{room_height} view={view_w}x{view_h} left={view_left} globalScale={ui_scale} fontPx={font_px} boxAdvance={box_advance} lineBox={line_box}");

	var samples = [];
	var line_count = instance_number(oLine_1);
	for (var instance_i = 0; instance_i < line_count; instance_i++) {
		var line_instance = instance_find(oLine_1, instance_i);
		if (!instance_exists(line_instance) || !line_instance.has_text_events) then continue;
		var text_events = line_instance.extEvents[$ "textEvents"];
		if (!is_array(text_events)) then continue;
		var picked = 0;
		var saw_space = false;
		var saw_break = false;
		for (var event_i = 0; event_i < array_length(text_events) && picked < 3; event_i++) {
			var text_event = text_events[event_i];
			if (!is_struct(text_event)) then continue;
			var sample_text = string(text_event[$ "end"] ?? "");
			if (!string_length(sample_text)) then continue;
			var sample_break = string_pos("\n", sample_text) > 0;
			var sample_space = string_char_at(sample_text, string_length(sample_text)) == " "
				|| string_char_at(sample_text, 1) == " ";
			if (picked > 0 && !sample_break && !sample_space) then continue;
			if (sample_space && saw_space && !sample_break) then continue;
			if (sample_break && saw_break) then continue;
			array_add(samples, {
				line: line_instance,
				sec: real(text_event.startTime) + 0.001,
				text: sample_text
			});
			picked++;
			if (sample_space) then saw_space = true;
			if (sample_break) then saw_break = true;
		};
	};
	for (var sort_i = 1; sort_i < array_length(samples); sort_i++) {
		var sort_item = samples[sort_i];
		var sort_j = sort_i - 1;
		while (sort_j >= 0 && samples[sort_j].sec > sort_item.sec) {
			samples[sort_j + 1] = samples[sort_j];
			sort_j--;
		};
		samples[sort_j + 1] = sort_item;
	};

	var mismatch = 0;
	for (var sample_i = 0; sample_i < array_length(samples); sample_i++) {
		var sample = samples[sample_i];
		if (!rpe_text_probe_seek(sample.sec)) then continue;
		var line_instance = sample.line;
		if (!instance_exists(line_instance)) then continue;
		var expect_x = line_instance.__raw_x * (view_w / 1350) + view_left + view_w * 0.5;
		var expect_y = -line_instance.__raw_y * (view_h / 900) + view_h * 0.5;
		var dx = line_instance.x - expect_x;
		var dy = line_instance.y - expect_y;
		var em_x = 0.04 * view_w * abs(line_instance.__scale_x);
		var em_y = 0.04 * view_w * abs(line_instance.__scale_y);
		var shown = string_replace_all(string_replace_all(line_instance.line_text, "\n", "\\n"), "\r", "");
		if (string_length(shown) > 48) then shown = string_copy(shown, 1, 48);
		var pos_ok = abs(dx) <= 0.6 && abs(dy) <= 0.6;
		var size_ratio = (view_w > 0) ? (em_x / view_w) : 0;
		var size_ok = abs(size_ratio - 0.04 * abs(line_instance.__scale_x)) <= 0.00001;
		if (!pos_ok || !size_ok) then mismatch++;
		var norm_x = (view_w > 0) ? ((line_instance.x - view_left - view_w * 0.5) / view_w) : 0;
		var norm_y = (view_h > 0) ? ((line_instance.y - view_h * 0.5) / view_h) : 0;
		var newline_rpe = 0;
		if (string_pos("\n", line_instance.line_text) > 0) then newline_rpe = 50;
		print($"[TextProbe] line={line_instance.line_id} t={sample.sec} text=\"{shown}\" raw=({line_instance.__raw_x},{line_instance.__raw_y}) screen=({line_instance.x},{line_instance.y}) expect=({expect_x},{expect_y}) d=({dx},{dy}) norm=({norm_x},{norm_y}) scale=({line_instance.__scale_x},{line_instance.__scale_y}) em=({em_x},{em_y}) emPerW={size_ratio} newlineRpe={newline_rpe} anchor=({line_instance.anchor_x},{line_instance.anchor_y}) rot={line_instance.image_angle} posOk={pos_ok} sizeOk={size_ok}");
	};
	var line_length = 6;
	if (variable_global_exists("game_1") && is_struct(game_1) && is_struct(game_1.chart_info)) {
		var info_line_length = real(game_1.chart_info[$ "line_length"] ?? 6);
		if (is_finite(info_line_length) && info_line_length > 0) then line_length = info_line_length;
	};
	var logged_lines = 0;
	var judge_count = instance_number(oLine_1);
	for (var line_i = 0; line_i < judge_count && logged_lines < 4; line_i++) {
		var judge = instance_find(oLine_1, line_i);
		if (!instance_exists(judge) || !judge.is_default_line || judge.has_text_events || judge.is_attach_ui) then continue;
		if (abs(judge.__scale_x) < 0.2) then continue;
		var half_rpe = abs(judge.__scale_x) * 0.5 * line_length * 675;
		var expect_half = abs(judge.__scale_x) * line_length * 337.5;
		var half_ok = abs(half_rpe - expect_half) <= 0.01;
		if (!half_ok) then mismatch++;
		print($"[LineProbe] line={judge.line_id} scaleX={judge.__scale_x} lineLength={line_length} halfRpe={half_rpe} expect={expect_half} view={view_w}x{view_h} halfOk={half_ok}");
		logged_lines++;
	};
	if (array_length(samples) <= 0) then mismatch = 1;
	print($"[TextProbe][SUMMARY] samples={array_length(samples)} mismatch={mismatch} room={room_width}x{room_height} view={view_w}x{view_h}");
	return mismatch;
}
