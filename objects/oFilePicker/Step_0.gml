/// @description Picker input; modal while open
var scale_now = (variable_global_exists("global_scales") ? global_scales : 1.0);
if (layout_w != room_width || layout_h != room_height || layout_scale != scale_now) {
        gx_fp_layout();
        gx_fp_refresh_list();
        layout_w = room_width;
        layout_h = room_height;
        layout_scale = scale_now;
};

if (!armed && !mouse_check_button(mb_left)) then armed = true;

if (downloading) {
        if (download_total > 0) {
                status_text = "Downloading " + string(download_got) + " / " + string(download_total) + " bytes";
        } else if (download_got > 0) {
                status_text = "Downloading " + string(download_got) + " bytes";
        };
};

var mx = mouse_x;
var my = mouse_y;
hover_open = gx_fp_hit(mx, my, btn_open);
hover_cancel = gx_fp_hit(mx, my, btn_cancel);
hover_folder = gx_fp_hit(mx, my, btn_folder);
hover_up = gx_fp_hit(mx, my, btn_up);
hover_back = gx_fp_hit(mx, my, btn_back);
hover_fwd = gx_fp_hit(mx, my, btn_fwd);

if (keyboard_check_pressed(vk_escape)) {
        if (downloading) {
                downloading = false;
                download_id = -1;
                api_job = "";
                api_fetch_json = false;
                last_error = "Download cancelled.";
                status_text = last_error;
        } else {
                gx_fp_finish_cancel();
        };
        exit;
};

if (!downloading) {
        if (keyboard_check_pressed(vk_enter)) {
                gx_fp_activate_selected();
                exit;
        };
        if (keyboard_check_pressed(vk_backspace) || keyboard_check_pressed(vk_left)) {
                if (gx_fp_history_can_back()) then gx_fp_go_back();
                else gx_fp_go_up();
                exit;
        };
        if (keyboard_check_pressed(vk_right) && gx_fp_history_can_fwd()) {
                gx_fp_go_forward();
                exit;
        };
        if (keyboard_check_pressed(vk_up) && selected > 0) {
                selected -= 1;
                if (selected < scroll) then scroll = selected;
        };
        if (keyboard_check_pressed(vk_down) && selected < array_length(items) - 1) {
                selected += 1;
                if (selected >= scroll + visible_rows) then scroll = selected - visible_rows + 1;
        };
};

if (mouse_wheel_up()) then scroll = max(0, scroll - 1);
if (mouse_wheel_down()) {
        var max_scroll = max(0, array_length(items) - visible_rows);
        scroll = min(max_scroll, scroll + 1);
};

if (!armed || !mouse_check_button_pressed(mb_left)) then exit;
if (downloading) {
        if (hover_cancel) {
                downloading = false;
                download_id = -1;
                last_error = "Download cancelled.";
                status_text = last_error;
        };
        exit;
};

if (hover_back) { gx_fp_go_back(); exit; };
if (hover_fwd) { gx_fp_go_forward(); exit; };
if (hover_up) { gx_fp_go_up(); exit; };
if (hover_cancel) { gx_fp_finish_cancel(); exit; };
if (hover_open) { gx_fp_activate_selected(); exit; };
if (hover_folder) { gx_fp_confirm_local(current_dir); exit; };

for (var ri = 0; ri < array_length(root_rects); ri++) {
        if (gx_fp_hit(mx, my, root_rects[ri])) {
                gx_fp_goto_root(root_rects[ri].path);
                exit;
        };
};

if (mx >= list_x && mx < list_x + list_w && my >= list_y && my < list_y + list_h) {
        var row = floor((my - list_y) / row_h);
        var index = scroll + row;
        if (index >= 0 && index < array_length(items)) {
                var now = current_time;
                if (index == last_click_index && (now - last_click_time) < 400) {
                        selected = index;
                        gx_fp_activate_selected();
                } else {
                        selected = index;
                };
                last_click_index = index;
                last_click_time = now;
        };
        exit;
};
