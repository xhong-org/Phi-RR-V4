/// @description Shared prepare/start/end playback transition.
if (!variable_instance_exists(id, "owner")) then owner = noone;
// Draw before the chart composition mask so the animation line is clipped with it.
depth = DEPTH.HEF + 2;

enum PLAY_TRANSITION_STATE {
	WAIT_MEDIA,
	INTRO_DELAY,
	INTRO,
	START_DELAY,
	PLAYING,
	OUTRO,
	EXIT_DELAY,
	FINISHED
};

state = PLAY_TRANSITION_STATE.WAIT_MEDIA;
state_started_at = get_timer();
intro_delay = 100000;
animation_duration = 1000000;
play_delay = 500000;
exit_delay = 500000;
progress = 0;
line_progress = 0;
render_started_frame = 0;
render_outro_started_frame = 0;
transition_instances = [];

function play_transition_deactivate_gameplay() {
	if (array_length(transition_instances) > 0) then return;
	// Pausing already stops gameplay updates. Keep instances active so line
	// parent references and the note preload activation set survive the
	// transition unchanged; only suppress their drawing temporarily.
	with (oLine) { array_add(other.transition_instances, [id, visible]); visible = false; };
	with (oLine_1) { array_add(other.transition_instances, [id, visible]); visible = false; };
	with (oLine_2) { array_add(other.transition_instances, [id, visible]); visible = false; };
	with (oNote) { array_add(other.transition_instances, [id, visible]); visible = false; };
	with (oNote_1) { array_add(other.transition_instances, [id, visible]); visible = false; };
	with (oNote_2) { array_add(other.transition_instances, [id, visible]); visible = false; };
	if (instance_exists(oEffect)) then with (oEffect) isDraw = false;
	if (instance_exists(oEffectNew)) then with (oEffectNew) isDraw = false;
}

function play_transition_activate_gameplay() {
	for (var _i = 0; _i < array_length(transition_instances); _i++) {
		var _record = transition_instances[_i];
		if (is_array(_record) && array_length(_record) >= 2 && instance_exists(_record[0])) {
			_record[0].visible = _record[1];
		};
	};
	transition_instances = [];
	if (instance_exists(oEffect)) then with (oEffect) isDraw = true;
	if (instance_exists(oEffectNew)) then with (oEffectNew) isDraw = true;
}

function play_transition_sync_bound_ui() {
	if (!instance_exists(owner) || owner.object_index != oRender_1) then return;
	if (!variable_instance_exists(owner, "play_transition_bound_ui")
		|| !is_struct(owner.play_transition_bound_ui)) then return;

	// Lines are created after the renderer in some load paths. Refresh this
	// relationship while the transition is active instead of relying on the
	// renderer's one-time Create scan.
	var _render_owner = owner;
	// The gameplay objects are inactive during the transition, so enumerate
	// the chart's retained line list instead of relying on an active-object
	// query. This also preserves bindings for child lines.
	if (variable_global_exists("game_1") && is_struct(game_1)
		&& is_array(game_1.line_list)) {
		var _lines = game_1.line_list;
		for (var _line_i = 0; _line_i < array_length(_lines); _line_i++) {
			var _line = _lines[_line_i];
			if (!instance_exists(_line) || !_line.is_attach_ui
				|| !is_string(_line.attach_ui_key) || !string_length(_line.attach_ui_key)
				|| !struct_exists(_render_owner.play_transition_bound_ui, _line.attach_ui_key)) then continue;
			_render_owner.play_transition_bound_ui[$ _line.attach_ui_key] = true;
		};
	};
}

function play_transition_apply(_value, _outro = false) {
	if (!instance_exists(owner)) then return;
	var _p = clamp(_value, 0, 1);
	var _hidden = _outro ? _p : (1 - _p);
	play_transition_sync_bound_ui();
	owner.play_transition_active = true;
	owner.play_transition_pause_y = -max(1, 70 * global_scales) * _hidden;
	owner.play_transition_name_y = max(1, 60 * global_scales) * _hidden;
	owner.play_transition_level_y = max(1, 60 * global_scales) * _hidden;
	owner.play_transition_score_y = -max(1, 110 * global_scales) * _hidden;
	owner.play_transition_ui_alpha = _outro ? (1 - _p) : 1;
	owner.play_transition_bar_alpha = _outro ? 1 : _p;
	owner.play_transition_bg_alpha = _outro ? (1 - _p) : _p;
	line_progress = _outro ? (1 - _p) : _p;
}

function play_transition_begin_exit() {
	if (state >= PLAY_TRANSITION_STATE.OUTRO) then return;
	game.paused = true;
	m_pause();
	play_transition_deactivate_gameplay();
	state = PLAY_TRANSITION_STATE.OUTRO;
	state_started_at = get_timer();
}

function play_transition_finish_exit() {
	if (!instance_exists(owner)) then return;
	owner.chart_exit_queued = true;
	if (owner.object_index == oRender_1 && variable_global_exists("game_1")
		&& is_struct(game_1) && struct_exists(game_1, "HitSounds") && is_struct(game_1.HitSounds)) {
		if (instance_exists(oExtraPlay)) then with (oExtraPlay) instance_destroy();
		if (instance_exists(oMedia)) {
			var _media = instance_find(oMedia, 0);
			if (_media.track > 0) then fmod_system_select(_media.track);
		};
		var _hit_names = struct_get_names(game_1.HitSounds);
		for (var _i = 0; _i < array_length(_hit_names); _i++) {
			var _sound = game_1.HitSounds[$ _hit_names[_i]];
			if (_sound > 0) then fmod_sound_release(_sound);
		};
		game_1.HitSounds = {};
	};
	m_clean(true);
	chart_session_cleanup(true);
	state = PLAY_TRANSITION_STATE.FINISHED;
	room_goto(room_menu);
}

play_transition_apply(0);
if (variable_global_exists("game") && is_struct(game)) then game.paused = true;
play_transition_deactivate_gameplay();
