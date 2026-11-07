///@desc 推进结算动画，并处理重试和继续
if (consumed) then exit;
if (!variable_global_exists("game") || !is_struct(game)) {
	instance_destroy();
	exit;
};

var now = settlement_elapsed_us();
// 首个实际 Draw End 才启动时间轴，避免首次加载把入场提前消耗。
if (!animation_started) then exit;
// 离开淡出结束后再真正重试或继续。
if (leaving) {
	fade_alpha = Easings.InOutCubic(settlement_phase(now, leave_started_at, leave_fade_dur));
	settlement_set_ending_volume(1 - fade_alpha);
	if (fade_alpha >= 1) {
		if (leave_wait_at < 0) then leave_wait_at = now;
		if (now - leave_wait_at >= leave_wait_dur) {
			if (leave_retry) then settlement_do_retry();
			else settlement_do_continue();
		};
	};
	exit;
};

// 使用固定时间轴，低帧率和录像跳帧不会累积各小段的等待误差。
settlement_update_animation(now);
settlement_refresh_layout();
settlement_update_score_save(now);

if (variable_global_exists("render_mode") && global.render_mode) {
	if (now >= animation_dur + hold_dur) then global.render_settlement_finished = true;
	exit;
};

var pointer = settings_gui_pointer();
// 不把游玩结束前按住的手指带入结算按钮。
if (!input_armed && now >= 800000 && !pointer.held) {
	input_armed = true;
};
retry_hover = input_armed && settlement_button_contains(retry_hit, pointer.x, pointer.y, button_cut);
cont_hover = input_armed && settlement_button_contains(cont_hit, pointer.x, pointer.y, -button_cut);
if (settlement_player_input(pointer, now)) then exit;
if (settlement_sync_input(pointer, now)) then exit;
// 未保存时先完成同步板入场，不让重试／继续提前销毁待写成绩。
if (sync_state == 1) then exit;
if (!input_armed || footer_eased < 0.95 || edge_eased < 0.95) then exit;

if (pointer.pressed && retry_hover) {
	settlement_begin_leave(true);
} else if (pointer.pressed && cont_hover) {
	settlement_begin_leave(false);
};
