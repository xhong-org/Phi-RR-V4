if (audit_complete) {
        wait_frames++;
        if (exit_test_mode && room == room_menu) {
                print("[ChartExitTest][PASS] Returned to room_menu with bound UI alpha <= 0.");
                game_end();
        } else if (exit_test_mode && wait_frames >= 600) {
                print("[ChartExitTest][FAIL] Timed out waiting for room_menu.");
                game_end(1);
        };
        exit;
};
wait_frames++;

if (wait_frames == 1 || (wait_frames mod 300) == 0) {
        print($"[RPETextureAudit] Waiting frame={wait_frames} room={room_get_name(room)} lines={instance_number(oLine_1)}");
};

if (room != room_play_rpe
        || !variable_global_exists("game_1")
        || !is_struct(game_1)
        || instance_number(oLine_1) <= 0) {
        if (wait_frames >= 1800) {
                print("[RPETextureAudit][FAIL] Timed out waiting for RPE judge lines.");
                audit_complete = true;
                if (test_mode) then game_end();
                else instance_destroy();
        };
        exit;
};

var unique_textures = {};
var referenced_lines = 0;
var unique_count = 0;
var files_found = 0;
var sprites_loaded = 0;
var lines_bound = 0;
var missing_count = 0;
var line_alpha_mismatch = 0;
var line_alpha_min = infinity;
var line_alpha_max = -infinity;

var line_count = instance_number(oLine_1);
for (var instance_i = 0; instance_i < line_count; instance_i++) {
        var line_instance = instance_find(oLine_1, instance_i);
        if (!instance_exists(line_instance)) then continue;
	var line_i = line_instance.line_id;
	var raw_alpha = real(line_instance.__raw_a);
	var expected_line_alpha = clamp(raw_alpha / 255, 0, 1);
	line_alpha_min = min(line_alpha_min, raw_alpha);
	line_alpha_max = max(line_alpha_max, raw_alpha);
	if (!line_instance.is_attach_ui
		&& abs(real(line_instance.image_alpha) - expected_line_alpha) > 0.00001) {
		line_alpha_mismatch++;
		print($"[RPEAlphaAudit][LINE_MISMATCH] line={line_i} raw={raw_alpha} actual={line_instance.image_alpha} expected={expected_line_alpha}");
	};
	var texture_name = string(line_instance.image ?? "line.png");
        if (!string_length(texture_name) || texture_name == "line.png") then continue;
        referenced_lines++;

        var file_ok = file_exists(InChartPath + texture_name);
        var sprite_id = -1;
        var sprite_ok = false;
        if (struct_exists(game_1, "Texture") && is_struct(game_1.Texture)
                && struct_exists(game_1.Texture, texture_name)) {
                sprite_id = game_1.Texture[$ texture_name];
                sprite_ok = sprite_exists(sprite_id);
        };

        var bound_ok = sprite_ok && (line_instance.sprite_index == sprite_id);
        if (bound_ok) then lines_bound++;

        if (!struct_exists(unique_textures, texture_name)) {
                struct_set(unique_textures, texture_name, true);
                unique_count++;
                if (file_ok) then files_found++;
                if (sprite_ok) then sprites_loaded++;
                if (!file_ok || !sprite_ok) then missing_count++;
                print($"[RPETextureAudit] texture=\"{texture_name}\" file={file_ok} sprite={sprite_ok} firstLine={line_i} path=\"{InChartPath + texture_name}\"");
        };
};

var passed = (files_found == unique_count && sprites_loaded == unique_count && lines_bound == referenced_lines);
print($"[RPETextureAudit][SUMMARY] pass={passed} referencedLines={referenced_lines} boundLines={lines_bound} unique={unique_count} files={files_found} sprites={sprites_loaded} missing={missing_count}");

var note_alpha_count = 0;
var note_alpha_mismatch = 0;
var note_alpha_min = infinity;
var note_alpha_max = -infinity;
if (is_struct(game_1._note_activation_records)) {
	var note_keys = struct_get_names(game_1._note_activation_records);
	for (var note_i = 0; note_i < array_length(note_keys); note_i++) {
		var note_record = game_1._note_activation_records[$ note_keys[note_i]];
		if (!is_struct(note_record)) then continue;
		var note_alpha = real(note_record.alpha);
		note_alpha_count++;
		note_alpha_min = min(note_alpha_min, note_alpha);
		note_alpha_max = max(note_alpha_max, note_alpha);
		if (note_alpha < 0 || note_alpha > 1) then note_alpha_mismatch++;
	};
};
if (line_count <= 0) {
	line_alpha_min = 0;
	line_alpha_max = 0;
};
if (note_alpha_count <= 0) {
	note_alpha_min = 0;
	note_alpha_max = 0;
};
var alpha_passed = (line_alpha_mismatch == 0 && note_alpha_mismatch == 0 && note_alpha_count > 0);
print($"[RPEAlphaAudit][SUMMARY] pass={alpha_passed} lines={line_count} lineRawMin={line_alpha_min} lineRawMax={line_alpha_max} lineMismatch={line_alpha_mismatch} notes={note_alpha_count} noteMin={note_alpha_min} noteMax={note_alpha_max} noteMismatch={note_alpha_mismatch}");
audit_complete = true;

if (exit_test_mode) {
        var exit_renderer = instance_find(oRender_1, 0);
        if (instance_exists(exit_renderer) && is_struct(exit_renderer.bindUI)) {
                var exit_ui_keys = struct_get_names(exit_renderer.bindUI);
                for (var exit_ui_i = 0; exit_ui_i < array_length(exit_ui_keys); exit_ui_i++) {
                        var exit_ui_slot = exit_renderer.bindUI[$ exit_ui_keys[exit_ui_i]];
                        if (is_array(exit_ui_slot) && array_length(exit_ui_slot) >= 4) {
                                exit_ui_slot[@ 3] = -1;
                        };
                };
        };
        var exit_media = instance_find(oMedia, 0);
        if (instance_exists(exit_media)) then exit_media.length = 1;
        wait_frames = 0;
        print("[ChartExitTest] Armed with all bound UI alpha=-1.");
} else if (test_mode) then game_end();
else instance_destroy();
