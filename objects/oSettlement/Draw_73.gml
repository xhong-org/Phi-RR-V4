/// @description Draw settlement above the composited chart.
if (consumed) then exit;
chart_mask_scissor_clear();
pls_draw_flush();

var old_colour = draw_get_colour();
var old_alpha = draw_get_alpha();
var old_halign = draw_get_halign();
var old_valign = draw_get_valign();
var old_font = draw_get_font();
var old_filter = gpu_get_texfilter();
gpu_set_blendmode(bm_normal);
gpu_set_texfilter(true);
if (variable_global_exists("game") && is_struct(game) && asset_font_valid(game.font)) then draw_set_font(game.font);

var s = variable_global_exists("global_scales") ? global_scales : 1;
if (!is_real(s) || s <= 0) then s = 1;
var skew = 18 * s;

settlement_draw_diamond_frame(illus_cx, illus_rest_cy, illus_half * 1.08, make_colour_rgb(18, 20, 26), 0.92);
settlement_draw_textured_diamond(illus_cx, illus_rest_cy, illus_half, illustration, c_white, 1);
settlement_draw_diamond_ring(illus_cx, illus_rest_cy, illus_half * 1.02, make_colour_rgb(210, 220, 230), 0.35);

settlement_draw_panel(score_x, score_bottom, score_w, score_h, skew, 0.62);
draw_set_colour(c_white);
draw_set_alpha(1);
draw_set_valign(fa_middle);
var title_y = score_bottom - score_h + 26 * s;
var title_pad = 28 * s;
var name_scale = 0.28 * s;
var level_scale = 0.26 * s;
var level_w = string_width(string(song_level)) * level_scale;
var name_max_w = max(1, score_w - title_pad * 2 - level_w - 16 * s);
var name_raw_w = max(1, string_width(string(song_name)));
name_scale = min(name_scale, name_max_w / name_raw_w);
draw_set_halign(fa_left);
draw_text_transformed(score_x + title_pad, title_y, song_name, name_scale, name_scale, 0);
draw_set_halign(fa_right);
draw_text_transformed(score_x + score_w - title_pad, title_y, song_level, level_scale, level_scale, 0);
settlement_draw_panel(combo_x, combo_bottom, combo_w, combo_h, skew, 0.62);
settlement_draw_panel(judge_x, judge_bottom, judge_w, judge_h, skew, 0.62);

var a0 = box_alpha[0];
var a1 = box_alpha[1];
var a2 = box_alpha[2];
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_colour(c_white);
draw_set_alpha(a0);
var score_tx = score_x + 28 * s;
draw_text_transformed(score_tx, score_bottom - score_h * 0.50, ScoreSystemPad(score_show), 0.72 * s, 0.72 * s, 0);
draw_set_alpha(a0 * 0.85);
var rec_label = "NEW BEST";
if (variable_global_exists("render_mode") && global.render_mode) {
	rec_label = "RECORDER";
} else if (variable_global_exists("game") && is_struct(game) && is_struct(game.settings)
	&& bool(game.settings.enableAutoPlay ?? true)) {
	rec_label = "AUTOPLAY";
};
draw_text_transformed(score_tx, score_bottom - score_h * 0.22,
	$"{rec_label}  {ScoreSystemPad(best_show)}  +{ScoreSystemPad(delta_show)}",
	0.22 * s, 0.22 * s, 0);

if (asset_sprite_valid(rank_sprite) && rank_alpha > 0) {
	draw_sprite_ext(rank_sprite, 0, rank_cx, rank_cy, rank_base_scale * rank_scale, rank_base_scale * rank_scale, 0, c_white, rank_alpha);
};

draw_set_alpha(a1);
draw_set_halign(fa_left);
draw_text_transformed(combo_x + 28 * s, combo_bottom - combo_h * 0.58, string(floor(max_combo)), 0.48 * s, 0.48 * s, 0);
draw_set_alpha(a1 * 0.8);
draw_text_transformed(combo_x + 28 * s, combo_bottom - combo_h * 0.24, "Max Combo", 0.22 * s, 0.22 * s, 0);
draw_set_halign(fa_right);
draw_set_alpha(a1);
var acc_s = string_replace_all(string_format(acc_value, 1, 2), " ", "") + "%";
draw_text_transformed(combo_x + combo_w - 28 * s, combo_bottom - combo_h * 0.58, acc_s, 0.48 * s, 0.48 * s, 0);
draw_set_alpha(a1 * 0.8);
draw_text_transformed(combo_x + combo_w - 28 * s, combo_bottom - combo_h * 0.24, "Accuracy", 0.22 * s, 0.22 * s, 0);

draw_set_alpha(a2);
draw_set_halign(fa_left);
var jy = judge_bottom - judge_h * 0.58;
var ly = judge_bottom - judge_h * 0.24;
var jx = judge_x + 24 * s;
var jgap = 88 * s;
draw_text_transformed(jx, jy, string(floor(perfect_count)), 0.32 * s, 0.32 * s, 0);
draw_text_transformed(jx + jgap, jy, string(floor(good_count)), 0.32 * s, 0.32 * s, 0);
draw_text_transformed(jx + jgap * 2, jy, string(floor(bad_count)), 0.32 * s, 0.32 * s, 0);
draw_text_transformed(jx + jgap * 3, jy, string(floor(miss_count)), 0.32 * s, 0.32 * s, 0);
draw_set_alpha(a2 * 0.75);
draw_text_transformed(jx, ly, "Perfect", 0.18 * s, 0.18 * s, 0);
draw_text_transformed(jx + jgap, ly, "Good", 0.18 * s, 0.18 * s, 0);
draw_text_transformed(jx + jgap * 2, ly, "Bad", 0.18 * s, 0.18 * s, 0);
draw_text_transformed(jx + jgap * 3, ly, "Miss", 0.18 * s, 0.18 * s, 0);
draw_set_halign(fa_right);
draw_set_alpha(a2);
draw_text_transformed(judge_x + judge_w - 28 * s, jy - 10 * s, string(floor(early_count)), 0.22 * s, 0.22 * s, 0);
draw_text_transformed(judge_x + judge_w - 28 * s, jy + 14 * s, string(floor(late_count)), 0.22 * s, 0.22 * s, 0);
draw_set_alpha(a2 * 0.75);
draw_text_transformed(judge_x + judge_w - 70 * s, jy - 10 * s, "Early", 0.18 * s, 0.18 * s, 0);
draw_text_transformed(judge_x + judge_w - 70 * s, jy + 14 * s, "Late", 0.18 * s, 0.18 * s, 0);

settlement_draw_user(s);
settlement_draw_retry(s);
settlement_draw_continue(s);

if (fade_alpha > 0) {
	draw_set_colour(c_black);
	draw_set_alpha(fade_alpha);
	draw_rectangle(0, 0, room_width, room_height, false);
};

draw_set_font(old_font);
draw_set_halign(old_halign);
draw_set_valign(old_valign);
draw_set_alpha(old_alpha);
draw_set_colour(old_colour);
gpu_set_texfilter(old_filter);
gpu_set_blendmode(bm_normal);
pls_draw_flush();
