/// @description Render settings interaction.
if (instance_exists(oFilePicker)) then exit;
if (keyboard_check_pressed(vk_escape)) { room_goto(room_menu); exit; };
setup_store_text();
if ((field == 2 || field == 3) && string_length(string_trim(keyboard_string)) > 0) {
    var numeric_probe = real(string_trim(keyboard_string));
    if (is_nan(numeric_probe) || numeric_probe == infinity || numeric_probe == -infinity) {
        setup_set_status(lang("render.fpsNumeric"));
    };
};
if (field == 4 && string_length(string_trim(keyboard_string)) > 0) {
    var aspect_probe = string_trim(keyboard_string);
    var aspect_separator = string_pos(":", aspect_probe);
    if (aspect_separator <= 1 || aspect_separator >= string_length(aspect_probe)) setup_set_status(lang("render.aspectFormat"));
};
var control_down = keyboard_check(vk_control) || keyboard_check(vk_lcontrol) || keyboard_check(vk_rcontrol);
if (control_down && keyboard_check_pressed(ord("C"))) {
    try {
        clipboard_set_text(string(keyboard_string));
        setup_set_status(lang("render.copied"));
    } catch (clipboard_copy_error) {
        delete(clipboard_copy_error);
        setup_set_status(lang("render.copyUnavailable"));
    };
    exit;
};
if (control_down && keyboard_check_pressed(ord("V"))) {
    try {
        var pasted_text = clipboard_get_text();
        if (is_string(pasted_text)) keyboard_string += pasted_text;
        setup_store_text();
        setup_set_status(lang("render.pasted"));
    } catch (clipboard_paste_error) {
        delete(clipboard_paste_error);
        setup_set_status(lang("render.pasteUnavailable"));
    };
    exit;
};
if (keyboard_check_pressed(vk_delete)) {
    keyboard_string = "";
    setup_store_text();
    setup_set_status(lang("render.cleared"));
    exit;
};
if (keyboard_check_pressed(vk_enter)) {
    setup_store_text();
    if (field < 4) { field++; setup_begin_text(); }
    else event_user(0);
    exit;
};
if (keyboard_check_pressed(vk_tab)) {
    setup_store_text();
    field = (field + 1) mod 5;
    setup_begin_text();
};
if (keyboard_check_pressed(vk_backspace)) {
    var text_now = keyboard_string;
    if (string_length(text_now) > 0) keyboard_string = string_delete(text_now, string_length(text_now), 1);
};
if (keyboard_check_pressed(ord("F")) && field == 0) {
    if (gx_file_picker_needed()) {
        gx_file_picker_open(method(id, function(path) {
            path_text = path;
            field = 0;
            setup_begin_text();
        }), method(id, function() {
            setup_begin_text();
        }));
        exit;
    };
    var selected = get_open_filename_ext("Chart package|*.zip;*.pez|All files|*.*", "", "", "Select chart package");
    if (string_length(selected)) { path_text = selected; setup_begin_text(); }
};
if (keyboard_check_pressed(ord("O")) && field == 1) {
    var selected_output = get_save_filename_ext("MP4 video|*.mp4|All files|*.*", "render.mp4", "", "Select video output");
    if (string_length(selected_output)) { output_text = selected_output; setup_begin_text(); };
    exit;
};
if (mouse_check_button_pressed(mb_left)) {
    var scale = variable_global_exists("global_scales") ? max(0.01, global_scales) : 1.0;
    var panel_width = 980 * scale;
    var left = (room_width - panel_width) * 0.5;
    var top = max(18 * scale, room_height * 0.5 - 380 * scale);
    var row = top + 92 * scale;
    if (point_in_rectangle(mouse_x, mouse_y, left + 610 * scale, row, left + 790 * scale, row + 48 * scale)) {
        if (gx_file_picker_needed()) {
            gx_file_picker_open(method(id, function(path) {
                path_text = path;
                field = 0;
                setup_begin_text();
            }), method(id, function() {
                setup_begin_text();
            }));
            exit;
        };
        var selected_mouse = get_open_filename_ext("Chart package|*.zip;*.pez|All files|*.*", "", "", "Select chart package");
        if (string_length(selected_mouse)) { path_text = selected_mouse; field = 0; setup_begin_text(); };
        exit;
    };
    if (point_in_rectangle(mouse_x, mouse_y, left + 610 * scale, row + 62 * scale, left + 790 * scale, row + 110 * scale)) {
        var selected_output_mouse = get_save_filename_ext("MP4 video|*.mp4|All files|*.*", "render.mp4", "", "Select video output");
        if (string_length(selected_output_mouse)) { output_text = selected_output_mouse; field = 1; setup_begin_text(); };
        exit;
    };
    for (var i = 0; i < 5; i++) {
        if (point_in_rectangle(mouse_x, mouse_y, left + 210 * scale, row + i * 62 * scale, left + 790 * scale, row + 48 * scale + i * 62 * scale)) {
            setup_store_text(); field = i; setup_begin_text(); exit;
        };
    };
    var option_top = row + 5 * 62 * scale + 16 * scale;
    if (point_in_rectangle(mouse_x, mouse_y, left + 210 * scale, option_top, left + 390 * scale, option_top + 48 * scale)) resolution_index = (resolution_index + 1) mod array_length(resolutions);
    else if (point_in_rectangle(mouse_x, mouse_y, left + 590 * scale, option_top, left + 790 * scale, option_top + 48 * scale)) aa_index = (aa_index + 1) mod array_length(aa_values);
    else if (point_in_rectangle(mouse_x, mouse_y, left + 210 * scale, option_top + 62 * scale, left + 520 * scale, option_top + 110 * scale)) {
        ratio_index = (ratio_index + 1) mod array_length(ratios);
        aspect_text = ratios[ratio_index];
        setup_begin_text();
    }
    else if (point_in_rectangle(mouse_x, mouse_y, left + 210 * scale, option_top + 124 * scale, left + 520 * scale, option_top + 172 * scale)) {
        record_settlement = !record_settlement;
        exit;
    }
    else if (point_in_rectangle(mouse_x, mouse_y, left + 580 * scale, option_top + 52 * scale, left + 750 * scale, option_top + 104 * scale)) event_user(0);
};
