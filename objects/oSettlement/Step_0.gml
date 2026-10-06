/// @description Settlement timeline, input, and leave fade.
if (consumed) then exit;
if (!variable_global_exists("game") || !is_struct(game)) {
	instance_destroy();
	exit;
};

settlement_refresh_layout();
var now = settlement_elapsed_us();
var s = variable_global_exists("global_scales") ? global_scales : 1;
if (!is_real(s) || s <= 0) then s = 1;

if (leaving) {
	var leave_raw = clamp((now - leave_started_at) / max(1, leave_fade_dur), 0, 1);
	fade_alpha = leave_raw;
	settlement_set_ending_volume(1 - fade_alpha);
	if (leave_raw >= 1) {
		if (leave_wait_at < 0) then leave_wait_at = now;
		if (now - leave_wait_at >= leave_wait_dur) {
			if (leave_retry) then settlement_do_retry();
			else settlement_do_continue();
		};
	};
	exit;
};

var elapsed = max(0, now);
var slide_raw = clamp(elapsed / max(1, slide_dur), 0, 1);
slide_eased = Easings.OutExpo(slide_raw);
var slide_off = (1 - slide_eased) * slide_dist;
illus_cx = illus_rest_cx + slide_off;
score_x = score_rest_x + slide_off;
combo_x = lerp(score_rest_x + slide_dist + box_d, score_rest_x, slide_eased);
judge_x = lerp(score_rest_x + slide_dist + 2 * box_d, score_rest_x, slide_eased);

var user_raw = clamp(elapsed / max(1, user_dur), 0, 1);
user_alpha = Easings.InOutCubic(user_raw);
var btn_raw = clamp(elapsed / max(1, btn_dur), 0, 1);
var btn_eased = Easings.InOutCubic(btn_raw);
retry_x = lerp(-240 * s, retry_rest_x, btn_eased);
cont_x = lerp(240 * s, cont_rest_x, btn_eased);

if (score_tween_at < 0 && slide_raw >= score_decel_t) then score_tween_at = now;
if (score_tween_at >= 0) {
	var score_raw = clamp((now - score_tween_at) / max(1, text_dur), 0, 1);
	box_alpha[@ 0] = Easings.OutCubic(score_raw);
	var score_k = box_alpha[0];
	score_show = score_value * score_k;
	best_show = best_prev * score_k;
	delta_show = score_delta * score_k;
	gap_show = score_gap * score_k;
} else {
	box_alpha[@ 0] = 0;
	score_show = 0;
	best_show = 0;
	delta_show = 0;
	gap_show = 0;
};

if (box_alpha[0] >= 1) {
	if (box1_at < 0) then box1_at = now;
	box_alpha[@ 1] = Easings.OutCubic(clamp((now - box1_at) / max(1, text_dur), 0, 1));
} else {
	box_alpha[@ 1] = 0;
};
if (box_alpha[1] >= 1) {
	if (box2_at < 0) then box2_at = now;
	box_alpha[@ 2] = Easings.OutCubic(clamp((now - box2_at) / max(1, text_dur), 0, 1));
} else {
	box_alpha[@ 2] = 0;
};

var other_done = (slide_raw >= 1 && user_raw >= 1 && btn_raw >= 1 && box_alpha[2] >= 1);
if (other_done && !rank_started) {
	rank_started = true;
	rank_fade_at = now;
};
if (rank_started) {
	if (rank_scale_at < 0) {
		var fade_raw = clamp((now - rank_fade_at) / max(1, rank_fade_dur), 0, 1);
		rank_alpha = Easings.Linear(fade_raw);
		rank_scale = 2;
		if (fade_raw >= 1) then rank_scale_at = now;
	} else {
		rank_alpha = 1;
		var scale_raw = clamp((now - rank_scale_at) / max(1, rank_scale_dur), 0, 1);
		rank_scale = lerp(2, 1, Easings.InOutQuint(scale_raw));
		if (scale_raw >= 1) then easing_complete = true;
	};
} else {
	rank_alpha = 0;
	rank_scale = 2;
};

if (easing_complete) {
	if (hold_at < 0) then hold_at = now;
	if (variable_global_exists("render_mode") && global.render_mode
		&& now - hold_at >= hold_dur) {
		global.render_settlement_finished = true;
	};
};

rank_cx = score_x + score_w - 168 * s;
rank_cy = score_bottom - score_h * 0.42;

var bar_h = 72 * s;
var retry_w = 210 * s;
retry_hit = [retry_x, retry_y, retry_x + retry_w, retry_y + bar_h];
var cont_w = 210 * s;
cont_hit = [room_width + cont_x - cont_w, room_height - bar_h, room_width + cont_x, room_height];

if (variable_global_exists("render_mode") && global.render_mode) then exit;

if (keyboard_check_pressed(ord("R"))) {
	settlement_begin_leave(true);
	exit;
};
if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_escape)) {
	settlement_begin_leave(false);
	exit;
};
if (mouse_check_button_pressed(mb_left)) {
	var mx = mouse_x;
	var my = mouse_y;
	if (point_in_rectangle(mx, my, retry_hit[0], retry_hit[1], retry_hit[2], retry_hit[3])) {
		settlement_begin_leave(true);
	} else if (point_in_rectangle(mx, my, cont_hit[0], cont_hit[1], cont_hit[2], cont_hit[3])) {
		settlement_begin_leave(false);
	};
};
