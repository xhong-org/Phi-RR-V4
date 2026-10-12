///@desc 步进：文件选择器输入，打开期间保持模态
var scale_now = (variable_global_exists("global_scales") ? global_scales : 1.0);
// 房间或缩放变了就重排并刷新列表。
if (layout_w != room_width || layout_h != room_height || layout_scale != scale_now) {
        gx_fp_layout();
        gx_fp_refresh_list();
        layout_w = room_width;
        layout_h = room_height;
        layout_scale = scale_now;
};

// 松开鼠标后才接收点击，避免打开瞬间误触。
if (!armed && !mouse_check_button(mb_left)) then armed = true;

// 下载中只更新进度文字。
if (downloading) {
        if (download_total > 0) {
                status_text = langf("picker.downloadProgress", string(download_got), string(download_total));
        } else if (download_got > 0) {
                status_text = langf("picker.downloadBytes", string(download_got));
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

// Esc：下载中只取消下载，否则关闭选择器。
if (keyboard_check_pressed(vk_escape)) {
        if (downloading) {
                downloading = false;
                download_id = -1;
                api_job = "";
                api_fetch_json = false;
                last_error = lang("picker.downloadCancelled");
                status_text = last_error;
        } else {
                gx_fp_finish_cancel();
        };
        exit;
};

// 未下载时处理回车、后退和上下选择。
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

// 滚轮滚动列表。
if (mouse_wheel_up()) then scroll = max(0, scroll - 1);
if (mouse_wheel_down()) {
        var max_scroll = max(0, array_length(items) - visible_rows);
        scroll = min(max_scroll, scroll + 1);
};

// 还没武装或这一帧没按下左键，就不处理点击。
if (!armed || !mouse_check_button_pressed(mb_left)) then exit;
// 下载中只允许点取消。
if (downloading) {
        if (hover_cancel) {
                downloading = false;
                download_id = -1;
                last_error = lang("picker.downloadCancelled");
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

// 点盘符就跳到对应根目录。
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
                // 400 毫秒内点同一行视为双击打开。
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
