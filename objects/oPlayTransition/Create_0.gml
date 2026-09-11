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
	SETTLEMENT,
	FINISHED
};

state = PLAY_TRANSITION_STATE.WAIT_MEDIA;
state_started_at = get_timer();
intro_delay = 100000;
animation_duration = 1000000;
play_delay = 500000;
exit_delay = 1000000;
progress = 0;
line_progress = 0;
render_started_frame = 0;
render_outro_started_frame = 0;
render_exit_delay_started_frame = 0;
transition_instances = [];
chart_instances_activation_requested = false;

function play_transition_deactivate_gameplay() {
	if (array_length(transition_instances) > 0) then return;
	// Never deactivate judge lines here. Loading already hid them; a second
	// deactivate/activate pair is deferred and skips line event init.
	chart_set_gameplay_visible(false);
	if (instance_exists(oEffect)) then with (oEffect) isDraw = false;
	if (instance_exists(oEffectNew)) then with (oEffectNew) isDraw = false;
	transition_instances = [true];
}

function play_transition_activate_gameplay() {
	chart_set_gameplay_visible(true);
	transition_instances = [];
	if (instance_exists(oEffect)) then with (oEffect) isDraw = true;
	if (instance_exists(oEffectNew)) then with (oEffectNew) isDraw = true;
}

function play_transition_activate_chart_instances() {
    if (!instance_exists(owner)) then return;
    if (owner.object_index == oRender_1) {
        rpe_sync_note_activation();
    } else if (owner.object_index == oRender_2) {
        pec_sync_note_activation();
    } else if (owner.object_index == oRender) {
        official_sync_note_activation();
    };
    chart_instances_activation_requested = true;
}

function play_transition_sync_bound_ui() {
	if (!instance_exists(owner) || owner.object_index != oRender_1) then return;
	if (!variable_instance_exists(owner, "play_transition_bound_ui")
		|| !is_struct(owner.play_transition_bound_ui)) then return;

	// Lines stay active (only hidden) during the transition. Enumerate the
	// retained line list so attachUI bindings survive child lines.
	var _render_owner = owner;
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
	var _outro_bg_end = 0.5;
	if (variable_global_exists("render_mode") && global.render_mode && !render_wants_settlement()) {
		_outro_bg_end = 0;
	};
	owner.play_transition_bg_alpha = _outro ? lerp(1, _outro_bg_end, _p) : _p;
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
	chart_playback_teardown_for_menu();
	state = PLAY_TRANSITION_STATE.FINISHED;
	if (variable_global_exists("pls_environment_run") && global.pls_environment_run) then game_end();
	else pls_return_to_entry();
}

play_transition_apply(0);
if (variable_global_exists("game") && is_struct(game)) then game.paused = true;
play_transition_deactivate_gameplay();
if (instance_exists(oLoadAnimator)) then chart_loading_animation_finish();
