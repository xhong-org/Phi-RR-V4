///@desc 在合成后的谱面之上绘制结算，录像也会采集此事件
if (consumed) then exit;
pls_draw_flush();
gpu_push_state();
shader_reset();
chart_mask_scissor_clear();
gpu_set_blendmode(bm_normal);
gpu_set_texfilter(true);
var old_colour = draw_get_colour();
var old_alpha = draw_get_alpha();
var old_halign = draw_get_halign();
var old_valign = draw_get_valign();
var old_font = draw_get_font();
if (asset_font_valid(ui_font)) then draw_set_font(ui_font);

var s = layout_scale;
var w = layout_width;
var dx = detail_x + 40 * (1 - art_eased);
var dw = detail_width;
var right = dx + dw;
var a = page_eased;

settlement_draw_background();

var score_top = 84;
var score_bottom = 268;
settlement_draw_rect(52, score_top, (w - 104) * art_eased, 1, c_white, 0.22 * a);
var user_right = w - 52;
var user_width = min(w * 0.35, max(200, settlement_label_width(user_name, 22) + 106));
settlement_draw_trapezoid(user_right - user_width, 20, user_width, 54, -22, a);
if (asset_sprite_valid(head_sprite)) {
	draw_sprite_stretched_ext(head_sprite, 0, layout_x + (user_right - 50) * s,
		layout_y + 28 * s, 38 * s, 38 * s, c_white, a);
};
settlement_draw_label(user_name, user_right - 64, 47, 22, c_white, a, user_width - 106, fa_right, true);

// 曲绘保持等比裁剪，斜边和下缘渐变直接用几何绘制。
var ax = 52 - 40 * (1 - art_eased);
settlement_draw_art(ax, 112, art_width, 500, 72, art_eased);
settlement_draw_label(song_name, ax + 26, 532, 38, c_white, art_eased, art_width - 128, fa_left, true);
settlement_draw_label(song_level, ax + 26, 578, 24, c_white, art_eased, art_width - 138);

// 主分数与评级各占一列，所有评级贴图均按包围盒等比适配。
settlement_draw_rect(dx, 96, dw, 160, colour_panel, panel_alpha * art_eased);
var score_y = 198 + 12 * (1 - score_eased);
settlement_draw_label(lang("settlement.score", "SCORE"), dx + 24, 126, 18,
	c_white, art_eased, dw - 240);
settlement_draw_label(ScoreSystemPad(score_show), dx + 22, score_y, 86,
	c_white, score_eased, dw - 240);
settlement_draw_rect(dx, score_bottom, dw * art_eased, 1, c_white, 0.24 * a);
var rank_x = right - 96;
var rank_y = (score_top + score_bottom) * 0.5;
if (rank_alpha > 0) {
	draw_set_colour(c_white);
	draw_set_alpha((0.1 + 0.25 * rank_flash) * rank_alpha);
	draw_circle(layout_x + rank_x * s, layout_y + rank_y * s,
		(72 + 18 * rank_flash) * s, true);
	if (asset_sprite_valid(rank_sprite)) {
		var rank_fit = min(138 / max(1, sprite_get_width(rank_sprite)),
			144 / max(1, sprite_get_height(rank_sprite)));
		draw_sprite_ext(rank_sprite, 0, layout_x + rank_x * s, layout_y + rank_y * s,
			rank_fit * rank_scale * s, rank_fit * rank_scale * s, 0, c_white, rank_alpha);
	};
};

var record_y = 284 + 8 * (1 - record_eased);
settlement_draw_tag(score_status, dx, record_y, record_eased, dw);
settlement_draw_tag(score_record_line, dx, record_y + 42, record_eased, dw);

// 最大连击与准确率先出现，再逐列展开四种判定。
var stats_y = 391 + 12 * (1 - stats_eased);
var acc_text = string_replace_all(string_format(acc_value, 1, 2), " ", "") + "%";
settlement_draw_label(string(floor(max_combo)), dx, stats_y, 44, c_white, stats_eased, dw * 0.44);
settlement_draw_label(lang("settlement.maxCombo", "MAX COMBO"), dx, stats_y + 35,
	18, c_white, stats_eased, dw * 0.44);
settlement_draw_label(acc_text, right, stats_y, 44, c_white, stats_eased, dw * 0.48, fa_right);
settlement_draw_label(lang("settlement.accuracy", "ACCURACY"), right, stats_y + 35,
	18, c_white, stats_eased, dw * 0.48, fa_right);

var counts = [perfect_count, good_count, bad_count, miss_count];
var labels = ["PERFECT", "GOOD", "BAD", "MISS"];
var cell_w = dw / 4;
settlement_draw_rect(dx, 450, dw * stats_eased, 4, c_white, stats_eased);
// 共用一条底纹，各列内部留白，数量与判定类型沿同一条中心线。
settlement_draw_rect(dx, 474, dw, 104, colour_panel, panel_alpha * judge_eased[0]);
for (var i = 0; i < 4; i++) {
	var j = judge_eased[i];
	var jx = dx + (i + 0.5) * cell_w;
	var jy = 474 + 12 * (1 - j);
	settlement_draw_label(string(floor(counts[i])), jx, jy + 34, 34, c_white, j, cell_w - 40, fa_center);
	settlement_draw_label(labels[i], jx, jy + 77, 18, c_white, j, cell_w - 40, fa_center);
};

var detail_a = judge_eased[3];
var detail_y = 598 + 8 * (1 - detail_a);
settlement_draw_rect(dx, detail_y, dw, 44, colour_panel, panel_alpha * detail_a);
settlement_draw_label("EARLY  " + string(floor(early_count)), dx + dw * 0.25, detail_y + 22, 20,
	c_white, detail_a, dw * 0.5 - 40, fa_center);
settlement_draw_label("LATE  " + string(floor(late_count)), dx + dw * 0.75, detail_y + 22, 20,
	c_white, detail_a, dw * 0.5 - 40, fa_center);

settlement_draw_button(retry_hit, spr_retry, button_cut, retry_hover);
settlement_draw_button(cont_hit, spr_resume, -button_cut, cont_hover);

if (fade_alpha > 0) {
	draw_set_colour(c_black);
	draw_set_alpha(fade_alpha);
	draw_rectangle(0, 0, chart_frame_width(), chart_frame_height(), false);
};
pls_draw_flush();
gpu_pop_state();
draw_set_font(old_font);
draw_set_halign(old_halign);
draw_set_valign(old_valign);
draw_set_alpha(old_alpha);
draw_set_colour(old_colour);
