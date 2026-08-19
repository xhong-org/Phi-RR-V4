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

// apply attached slots: offset from center, not hard absolute line xy
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
		// position = default layout + center-relative line offset
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
draw_text_transformed_colour(u_combo[0], u_combo[1], game.settings.comboString, u_combo[5], u_combo[6], u_combo[4], u_combo[2], u_combo[2], u_combo[2], u_combo[2], (combo >= 3 ? u_combo[3] : 0));
draw_text_transformed_colour(u_combo_num[0], u_combo_num[1], string(combo), u_combo_num[5], u_combo_num[6], u_combo_num[4], u_combo_num[2], u_combo_num[2], u_combo_num[2], u_combo_num[2], (combo >= 3 ? u_combo_num[3] : 0));

// chart name
draw_set_halign(fa_left);
draw_set_valign(fa_center);
draw_text_transformed_colour(u_name[0], u_name[1], _ui_name, u_name[5], u_name[6], u_name[4], u_name[2], u_name[2], u_name[2], u_name[2], u_name[3]);
//draw_text_transformed_colour(100 ,100, string_format(game.__time[1] , 0 , 10), u_name[5], u_name[6], u_name[4], u_name[2], u_name[2], u_name[2], u_name[2], u_name[3]);

// difficulty
draw_set_halign(fa_right);
draw_set_valign(fa_bottom);
draw_text_transformed_colour(u_level[0], u_level[1], _ui_level, u_level[5], u_level[6], u_level[4], u_level[2], u_level[2], u_level[2], u_level[2], u_level[3]);

// score
draw_set_valign(fa_center);
draw_text_transformed_colour(u_score[0], u_score[1], ScoreSystem(), u_score[5], u_score[6], u_score[4], u_score[2], u_score[2], u_score[2], u_score[2], u_score[3]);

// pause icon
draw_sprite_ext(spr_pause, 0, u_pause[0], u_pause[1], u_pause[5], u_pause[6], u_pause[4], u_pause[2], u_pause[3]);

// progress bar
var _mlen = 0;
if (instance_exists(oMedia)) then _mlen = real(oMedia.length);
var val = (_mlen > 0 ? clamp(game.__time[4] / _mlen, 0, 1) : 0);
var bar_x = u_bar[0];
var bar_y = u_bar[1];
var bar_angle = u_bar[4];
var bar_scale_x = u_bar[5];
var bar_scale_y = u_bar[6];
var bar_progress_length = chart_view_width * bar_scale_x * val;
var marker_local_x = bar_progress_length - sprite_get_width(spr_pixel_2) * bar_scale_x;
var marker_x = bar_x + marker_local_x * dcos(bar_angle);
var marker_y = bar_y - marker_local_x * dsin(bar_angle);

draw_sprite_ext(
	spr_pixel_2, 0, bar_x, bar_y,
	(chart_view_width / sprite_get_width(spr_pixel_2)) * bar_scale_x * val,
	4 * global_scales * bar_scale_y,
	bar_angle, c_gray, u_bar[3]
);
draw_sprite_ext(
	spr_pixel_2, 0, marker_x, marker_y,
	bar_scale_x,
	4 * global_scales * bar_scale_y,
	bar_angle, u_bar[2], u_bar[3]
);
