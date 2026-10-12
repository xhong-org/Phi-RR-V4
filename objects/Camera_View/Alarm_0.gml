///@desc 闹钟 0：窗口尺寸变化后刷新谱面对象与缩放
//show_debug_message("THIS-CV");

// 创建事件没跑完时，补一份设计分辨率。
if (!variable_instance_exists(id, "start_width") || !is_real(start_width) || start_width <= 0) {
        start_width = max(1, room_width);
};
if (!variable_instance_exists(id, "start_height") || !is_real(start_height) || start_height <= 0) {
        start_height = max(1, room_height);
};

// 通知音符和判定线按新尺寸重算。
if (instance_exists(oNote)) {
        with (oNote) {
                event_user(1);
                event_user(2);
                event_user(8);
        };
};

if (instance_exists(oLine)) {
        with (oLine) {
                event_user(2);
        };
};

// 尺寸回调里也以这里算出的缩放为准。
if (start_width > 0 && start_height > 0) {
        global_scales = min(room_width / start_width, room_height / start_height);
};
