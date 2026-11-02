///@desc 闹钟 0：窗口尺寸变化后刷新谱面对象与缩放
//show_debug_message("THIS-CV");

// 创建事件没跑完时，补一份设计分辨率。
if (!chart_actor_var_exists(id, "start_width") || !is_real(start_width) || start_width <= 0) {
        start_width = max(1, room_width);
};
if (!chart_actor_var_exists(id, "start_height") || !is_real(start_height) || start_height <= 0) {
        start_height = max(1, room_height);
};

// 先更新比例，再通知对象，避免回调沿用切换前的缩放。
if (start_width > 0 && start_height > 0) {
        global_scales = min(room_width / start_width, room_height / start_height);
};
chart_view_refresh(room_width, room_height);
// 退场已经冻结事件；Step 和 Draw Begin 会用保留值校正线与音符的几何。
if (chart_play_ending()) then exit;

// 通知音符和判定线按新尺寸重算。
if (chart_actor_exists(oNote)) {
        { var _actors_720 = chart_actor_list(oNote); for (var _actor_i_720 = 0; _actor_i_720 < array_length(_actors_720); _actor_i_720++) with (_actors_720[_actor_i_720]) {
                chart_actor_user(1);
                chart_actor_user(2);
                chart_actor_user(8);
        } };
};

if (chart_actor_exists(oLine)) {
        { var _actors_881 = chart_actor_list(oLine); for (var _actor_i_881 = 0; _actor_i_881 < array_length(_actors_881); _actor_i_881++) with (_actors_881[_actor_i_881]) {
                chart_actor_user(2);
        } };
};
