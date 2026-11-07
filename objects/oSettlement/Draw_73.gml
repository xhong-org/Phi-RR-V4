///@desc Official 风格结算，仍在 Draw End 合成，录像沿用同一画面
if (consumed) then exit;
settlement_start_animation();
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

settlement_draw_background();

// 曲绘和三个成绩板各自从右侧跟进入场，稳定后共用同一斜率。
var entry_distance = room_width / layout_scale;
var art_dx = entry_distance * (1 - art_eased);
settlement_draw_art(104 + art_dx, 227, 1001, 626, 166, art_eased > 0 ? 1 : 0);
var title_max_width = min(650, max(1, 916 - settlement_label_width(song_level, 28) - 24 - 160));
settlement_draw_label(song_name, 160 + art_dx, 788, 64, c_white, art_eased, title_max_width, fa_left, true);
settlement_draw_label(song_level, 916 + art_dx, 811, 28, c_white, art_eased, 180, fa_right, true);

var score_dx = entry_distance * (1 - panel_eased[0]);
var stats_dx = entry_distance * (1 - panel_eased[1]);
var judge_dx = entry_distance * (1 - panel_eased[2]);
settlement_draw_panel(1049 + score_dx, 227, 784, 313, 85, 1);
settlement_draw_panel(1008 + stats_dx, 584, 729, 112, 30, 1);
settlement_draw_panel(966 + judge_dx, 740, 729, 113, 30, 1);

// 参考里的分数直接揭示最终值，不从零滚动；评级稍后出现。
settlement_draw_label(ScoreSystemPad(score_show), 1115 + score_dx, 430, 76,
    c_white, score_eased, 405);
var score_caption = score_status;
if (string_length(score_record_line)) then score_caption += "  " + score_record_line;
settlement_draw_label(score_caption, 1125 + score_dx, 490, 24,
    c_white, record_eased, 520);
settlement_draw_rank(1653 + score_dx, 382);

var acc_text = string_replace_all(string_format(acc_value, 1, 2), " ", "") + "%";
settlement_draw_label(string(floor(max_combo)), 1068 + stats_dx, 625, 48, c_white, stats_eased, 260);
settlement_draw_label("Max Combo", 1068 + stats_dx, 664, 24, c_white, stats_eased, 260);
settlement_draw_label(acc_text, 1686 + stats_dx, 625, 48, c_white, stats_eased, 330, fa_right);
settlement_draw_label("Accuracy", 1686 + stats_dx, 664, 24, c_white, stats_eased, 330, fa_right);

var counts = [perfect_count, good_count, bad_count, miss_count];
var labels = ["Perfect", "Good", "Bad", "Miss"];
for (var i = 0; i < 4; i++) {
    var jx = 1058 + i * 114 + judge_dx;
    settlement_draw_label(string(floor(counts[i])), jx, 785, 40, c_white, judge_eased[i], 108, fa_center);
    settlement_draw_label(labels[i], jx, 819, 16, c_white, judge_eased[i], 108, fa_center);
};
var detail_alpha = judge_eased[3];
settlement_draw_label("Early", 1487 + judge_dx, 786, 24, c_white, detail_alpha, 120);
settlement_draw_label("Late", 1487 + judge_dx, 814, 24, c_white, detail_alpha, 120);
settlement_draw_label(string(floor(early_count)), 1642 + judge_dx, 786, 24, c_white, detail_alpha, 80, fa_right);
settlement_draw_label(string(floor(late_count)), 1642 + judge_dx, 814, 24, c_white, detail_alpha, 80, fa_right);

settlement_draw_player();
settlement_draw_score_sync();
settlement_draw_button(retry_hit, spr_retry, button_cut, retry_hover, edge_eased);
settlement_draw_button(cont_hit, spr_resume, -button_cut, cont_hover, footer_eased);
// 本地化提示、data图标和可配置字节数共用消息框的文字淡入。
settlement_draw_toast();

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
