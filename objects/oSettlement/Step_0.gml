///@desc 推进结算动画，并处理重试和继续
if (consumed) then exit;
if (!variable_global_exists("game") || !is_struct(game)) {
	instance_destroy();
	exit;
};

var now = settlement_elapsed_us();
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
page_eased = Easings.OutCubic(settlement_phase(now, 0, 450000));
art_eased = Easings.OutExpo(settlement_phase(now, 100000, 1000000));
score_eased = Easings.OutCubic(settlement_phase(now, 400000, 1100000));
score_show = round(score_value * score_eased);
record_eased = Easings.OutCubic(settlement_phase(now, 1200000, 450000));
stats_eased = Easings.OutQuart(settlement_phase(now, 950000, 650000));
for (var i = 0; i < 4; i++) {
	judge_eased[@ i] = Easings.OutCubic(settlement_phase(now, 1250000 + i * 100000, 500000));
};
footer_eased = Easings.OutCubic(settlement_phase(now, 1550000, 650000));
var rank_raw = settlement_phase(now, 1750000, 850000);
rank_alpha = Easings.OutCubic(settlement_phase(now, 1750000, 250000));
rank_scale = lerp(1.18, 1, Easings.OutBack(rank_raw));
rank_flash = sin(rank_raw * pi) * (1 - rank_raw);
easing_complete = now >= animation_dur;
settlement_refresh_layout();

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
if (!input_armed || footer_eased < 0.95) then exit;

if (pointer.pressed && retry_hover) {
	settlement_begin_leave(true);
} else if (pointer.pressed && cont_hover) {
	settlement_begin_leave(false);
};
