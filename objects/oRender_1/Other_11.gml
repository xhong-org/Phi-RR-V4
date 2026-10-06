/// @description Enable UI draw event (ported from oRender, attachUI-ready)
// bindUI layout written by oLine_1 when attachUI is set:
// keys: pause / combonumber / combo / score / bar / name / level
// array: [offX, offY, color, alpha, rot, scaleX, scaleY]
// offX/offY are center-relative (line.xy - room center), PCR-aligned.
// Final HUD pos = default_layout + offset.
var ui_fade = (variable_instance_exists(id, "chart_exit_alpha") ? chart_exit_alpha : 1);
var _transition_active = play_transition_active;
var _transition_bar_alpha = (_transition_active ? play_transition_bar_alpha : 1);

var _ui_name = game.folder_chart.name;
var _ui_level = game.folder_chart.level;
if ((!is_string(_ui_name) || !string_length(_ui_name))
	&& variable_global_exists("game_1") && is_struct(game_1) && is_struct(game_1.chart_info)
	&& is_string(game_1.chart_info.name) && string_length(game_1.chart_info.name)) {
	_ui_name = game_1.chart_info.name;
};
if ((!is_string(_ui_level) || !string_length(_ui_level))
	&& variable_global_exists("game_1") && is_struct(game_1) && is_struct(game_1.chart_info)
	&& is_string(game_1.chart_info.level) && string_length(game_1.chart_info.level)) {
	_ui_level = game_1.chart_info.level;
};

// default HUD layout (Phigros absolute screen positions)
var u_combo_num = [chart_view_left + chart_view_width / 2, 60 * global_scales, image_blend, ui_fade, 0, global_scales, global_scales];
var u_combo = [chart_view_left + chart_view_width / 2, 90 * global_scales, image_blend, ui_fade, 0, 0.3 * global_scales, 0.3 * global_scales];
var u_name = [chart_view_left + 40 * global_scales, room_height - (35 * global_scales), image_blend, ui_fade, 0, font_scales * global_scales, font_scales * global_scales];
var u_level = [chart_view_right - (40 * global_scales), room_height - (10 * global_scales), image_blend, ui_fade, 0, 0.55 * global_scales, 0.55 * global_scales];
var u_score = [chart_view_right - (40 * global_scales), 70 * global_scales, image_blend, ui_fade, 0, 0.75 * global_scales, 0.75 * global_scales];
var u_pause = [chart_view_left + 50 * global_scales, 50 * global_scales, c_white, ui_fade, 0, 0.8 * global_scales, 0.8 * global_scales];
var u_bar = [chart_view_left, 0, image_blend, ui_fade, 0, 1, 1];

if (_transition_active) {
	if (!play_transition_bound_ui.name) then u_name[@ 1] += play_transition_name_y;
	if (!play_transition_bound_ui.level) then u_level[@ 1] += play_transition_level_y;
	if (!play_transition_bound_ui.score) then u_score[@ 1] += play_transition_score_y;
	if (!play_transition_bound_ui.pause) then u_pause[@ 1] += play_transition_pause_y;
	if (!play_transition_bound_ui.bar) then u_bar[@ 3] *= _transition_bar_alpha;
};

// Bound HUD stays on the original layout above. The line only contributes its
// offset from the chart center: position = original + (line - center).
if (variable_instance_exists(id, "bindUI") && is_struct(bindUI)
	&& variable_instance_exists(id, "bindUI_attached") && is_struct(bindUI_attached)) {
	var _keys = ["combonumber", "combo", "name", "level", "score", "pause", "bar"];
	var _slots = [u_combo_num, u_combo, u_name, u_level, u_score, u_pause, u_bar];
	for (var _si = 0; _si < array_length(_keys); _si++) {
		var _key = _keys[_si];
		if (!struct_exists(bindUI_attached, _key) || !bindUI_attached[$ _key]) then continue;
		if (!struct_exists(bindUI, _key)) then continue;
		var b = bindUI[$ _key];
		if (!is_array(b) || array_length(b) < 7) then continue;
		var s = _slots[_si];
		var base_x = s[0];
		var base_y = s[1];
		var base_sx = s[5];
		var base_sy = s[6];
		s[@ 0] = base_x + b[0];
		s[@ 1] = base_y + b[1];
		s[@ 2] = b[2];
		var bound_alpha = real(b[3]);
		if (!is_finite(bound_alpha)) then bound_alpha = 0;
		s[@ 3] = max(0, bound_alpha) * ui_fade;
		s[@ 4] = b[4];
		// line scale multiplies default visual scale (scale 1 keeps default HUD size)
		s[@ 5] = base_sx * b[5];
		s[@ 6] = base_sy * b[6];
	};
};

draw_set_font(game.font);

// combo number + combo string
draw_set_halign(fa_middle);
draw_set_valign(fa_center);
draw_text_transformed_colour(u_combo[0], u_combo[1], chart_combo_caption(), u_combo[5], u_combo[6], u_combo[4], u_combo[2], u_combo[2], u_combo[2], u_combo[2], (combo >= 3 ? u_combo[3] : 0));
draw_text_transformed_colour(u_combo_num[0], u_combo_num[1], string(combo), u_combo_num[5], u_combo_num[6], u_combo_num[4], u_combo_num[2], u_combo_num[2], u_combo_num[2], u_combo_num[2], (combo >= 3 ? u_combo_num[3] : 0));

// chart name
draw_set_halign(fa_left);
draw_set_valign(fa_center);
draw_text_transformed_colour(u_name[0], u_name[1], _ui_name, u_name[5], u_name[6], u_name[4], u_name[2], u_name[2], u_name[2], u_name[2], u_name[3]);

// difficulty
draw_set_halign(fa_right);
draw_set_valign(fa_bottom);
draw_text_transformed_colour(u_level[0], u_level[1], _ui_level, u_level[5], u_level[6], u_level[4], u_level[2], u_level[2], u_level[2], u_level[2], u_level[3]);

// score
// fa_center. A bound line near chart y=-820 plus the top default puts the
// glyph center on the window edge (Wavetapper). Keep that offset, and keep
// a zero-offset score (Algebra) on the original top layout. Only lift a
// score whose text box crosses the same bottom inset the level uses.
var score_text = ScoreSystem();
if (variable_instance_exists(id, "bindUI_attached") && is_struct(bindUI_attached)
	&& struct_exists(bindUI_attached, "score") && bindUI_attached.score
	&& abs(u_score[4]) <= 0.5) {
	var score_box_h = string_height(score_text) * abs(u_score[6]);
	var score_bottom = u_score[1] + score_box_h * 0.5;
	var score_limit = room_height - (10 * global_scales);
	if (score_bottom > score_limit) {
		u_score[@ 1] -= (score_bottom - score_limit);
	};
};
draw_set_valign(fa_center);
draw_text_transformed_colour(u_score[0], u_score[1], score_text, u_score[5], u_score[6], u_score[4], u_score[2], u_score[2], u_score[2], u_score[2], u_score[3]);

draw_sprite_ext(spr_pause, 0, u_pause[0], u_pause[1], u_pause[5], u_pause[6], u_pause[4], u_pause[2], u_pause[3]);

// progress bar
// Phira draws a judge line at length 6, so scale 1 is six screens wide and
// charters put the bar line at about 1/6 to make that line one screen wide
// (Algebra is 0.1667). This bar is already one screen at scale 1. Multiplying
// by the raw line scale turns that into a sub-pixel hairline on most bound
// charts. Map through the line length and do not grow past the screen.
var _mlen = 0;
if (instance_exists(oMedia)) then _mlen = real(oMedia.length);
var val = (_mlen > 0 ? clamp(game.__time[4] / _mlen, 0, 1) : 0);
var bar_x = u_bar[0];
var bar_y = u_bar[1];
var bar_angle = u_bar[4];
var _bar_raw_x = real(u_bar[5]);
var _bar_raw_y = real(u_bar[6]);
if (!is_finite(_bar_raw_x)) then _bar_raw_x = 1;
if (!is_finite(_bar_raw_y)) then _bar_raw_y = 1;
var bar_scale_x = clamp(_bar_raw_x * 6, 0, 1);
var bar_scale_y = clamp(_bar_raw_y * 6, 0, 1);
var bar_progress_length = chart_view_width * bar_scale_x * val;
var marker_local_x = bar_progress_length - sprite_get_width(spr_pixel_2) * bar_scale_x;
var marker_x = bar_x + marker_local_x * dcos(bar_angle);
var marker_y = bar_y - marker_local_x * dsin(bar_angle);
// The track stays the dim half of the bound colour. White (no colour event)
// stays gray. A line colour event tints the track the same way as the head.
var _bar_colour = u_bar[2];
var _bar_track = merge_color(c_black, _bar_colour, 0.5);

draw_sprite_ext(
	spr_pixel_2, 0, bar_x, bar_y,
	(chart_view_width / sprite_get_width(spr_pixel_2)) * bar_scale_x * val,
	4 * global_scales * bar_scale_y,
	bar_angle, _bar_track, u_bar[3]
);
draw_sprite_ext(
	spr_pixel_2, 0, marker_x, marker_y,
	bar_scale_x,
	4 * global_scales * bar_scale_y,
	bar_angle, u_bar[2], u_bar[3]
);
