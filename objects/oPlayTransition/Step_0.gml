if (!instance_exists(owner) || !variable_global_exists("game") || !is_struct(game)) {
	instance_destroy();
	exit;
};

if (state == PLAY_TRANSITION_STATE.PLAYING && chart_instances_activation_requested) {
    play_transition_activate_chart_instances();
    chart_instances_activation_requested = false;
};

var _now = get_timer();
var _elapsed = max(0, _now - state_started_at);

if (variable_global_exists("render_mode") && global.render_mode) {
	if (state == PLAY_TRANSITION_STATE.WAIT_MEDIA) {
		game.paused = true;
		if (!instance_exists(oMedia)) then exit;
		var _render_media = instance_find(oMedia, 0);
		if (!variable_instance_exists(_render_media, "isExists")
			|| !variable_instance_exists(_render_media, "success")) then exit;
		if (!bool(variable_instance_get(_render_media, "isExists"))
			|| !bool(variable_instance_get(_render_media, "success"))) then exit;
		render_started_frame = global.render_frame;
		// Recording starts with the start animation; skip the pre-animation wait.
		state = PLAY_TRANSITION_STATE.INTRO;
	};
	var _render_elapsed = max(0, (global.render_frame - render_started_frame) / max(1, global.render_fps));
	var _intro_animation = 1.0;
	var _intro_play_delay = 0.5;
	if (variable_global_exists("render_intro_animation_seconds")
		&& is_real(global.render_intro_animation_seconds)) {
		_intro_animation = global.render_intro_animation_seconds;
	};
	if (variable_global_exists("render_intro_start_delay_seconds")
		&& is_real(global.render_intro_start_delay_seconds)) {
		_intro_play_delay = global.render_intro_start_delay_seconds;
	};
	var _intro_total = _intro_animation + _intro_play_delay;
	if (state == PLAY_TRANSITION_STATE.PLAYING
		&& variable_global_exists("render_chart_frames")
		&& global.render_frame >= global.render_chart_frames) {
		game.paused = true;
		play_transition_deactivate_gameplay();
		owner.chart_exit_started = true;
		owner.chart_exit_alpha = 1;
		render_outro_started_frame = global.render_frame;
		state = PLAY_TRANSITION_STATE.OUTRO;
	};
	if (state == PLAY_TRANSITION_STATE.OUTRO) {
		var _render_outro_elapsed = max(0,
			(global.render_frame - render_outro_started_frame) / max(1, global.render_fps));
		progress = clamp(_render_outro_elapsed / 1.0, 0, 1);
		var _render_outro_eased = Easings.InOutExpo(progress);
		play_transition_apply(_render_outro_eased, true);
		owner.chart_exit_alpha = 1 - _render_outro_eased;
		if (_render_outro_elapsed >= 1.0) {
			play_transition_apply(1, true);
			owner.chart_exit_alpha = 0;
			line_progress = 0;
			state = PLAY_TRANSITION_STATE.EXIT_DELAY;
		};
		exit;
	};
	if (state == PLAY_TRANSITION_STATE.EXIT_DELAY) {
		game.paused = true;
		exit;
	};
	if (_render_elapsed < _intro_animation) {
		game.paused = true;
		progress = clamp(_render_elapsed / max(0.000001, _intro_animation), 0, 1);
		play_transition_apply(Easings.InOutExpo(progress));
		state = PLAY_TRANSITION_STATE.INTRO;
	} else if (_render_elapsed < _intro_total) {
		game.paused = true;
		play_transition_apply(1);
		state = PLAY_TRANSITION_STATE.START_DELAY;
	} else {
		if (state != PLAY_TRANSITION_STATE.PLAYING) {
			play_transition_activate_gameplay();
			play_transition_activate_chart_instances();
			if (owner.object_index == oRender) then with (oNote) canDraw = true;
			game.__time[0] = 1;
			game.paused = false;
			owner.play_transition_active = false;
			line_progress = 0;
			state = PLAY_TRANSITION_STATE.PLAYING;
		};
	};
	exit;
};

switch (state) {
	case PLAY_TRANSITION_STATE.WAIT_MEDIA:
		game.paused = true;
		if (!instance_exists(oMedia)) {
			state = PLAY_TRANSITION_STATE.INTRO_DELAY;
			state_started_at = _now;
			break;
		};
		var _media = instance_find(oMedia, 0);
		var _pcm_pending = variable_instance_exists(_media, "gx_pcm_id") && is_real(_media.gx_pcm_id) && _media.gx_pcm_id >= 0;
		var _success_value = variable_instance_exists(_media, "success") ? variable_instance_get(_media, "success") : false;
		var _waiting_pcm = _pcm_pending || is_undefined(_success_value);
		if (pls_is_gxgames() && _waiting_pcm) {
			if (_elapsed < 45000000) then break;
			print("[L-Sound] GX WAIT_MEDIA PCM timeout; continuing without forcing audio success.");
			if (is_undefined(_success_value)) then _media[$ "success"] = false;
			_media.gx_pcm_id = -1;
			state = PLAY_TRANSITION_STATE.INTRO_DELAY;
			state_started_at = _now;
			break;
		};
		if (!variable_instance_exists(_media, "isExists")
			|| !variable_instance_exists(_media, "success")) then break;
		if (!bool(variable_instance_get(_media, "isExists"))) {
			state = PLAY_TRANSITION_STATE.INTRO_DELAY;
			state_started_at = _now;
			break;
		};
		if (is_undefined(variable_instance_get(_media, "success"))) then break;
		if (!bool(variable_instance_get(_media, "success"))) {
			state = PLAY_TRANSITION_STATE.INTRO_DELAY;
			state_started_at = _now;
			break;
		};
		state = PLAY_TRANSITION_STATE.INTRO_DELAY;
		state_started_at = _now;
	break;

	case PLAY_TRANSITION_STATE.INTRO_DELAY:
		game.paused = true;
		if (_elapsed >= intro_delay) {
			state = PLAY_TRANSITION_STATE.INTRO;
			state_started_at = _now;
		};
	break;

	case PLAY_TRANSITION_STATE.INTRO:
		game.paused = true;
		progress = clamp(_elapsed / animation_duration, 0, 1);
		play_transition_apply(Easings.InOutExpo(progress));
		if (progress >= 1) {
			play_transition_apply(1);
			state = PLAY_TRANSITION_STATE.START_DELAY;
			state_started_at = _now;
		};
	break;

	case PLAY_TRANSITION_STATE.START_DELAY:
		game.paused = true;
		if (_elapsed >= play_delay) {
			play_transition_activate_gameplay();
			play_transition_activate_chart_instances();
			if (owner.object_index == oRender) then with (oNote) canDraw = true;
			m_play();
			game.Math.now(0);
			game.paused = false;
			owner.play_transition_active = false;
			line_progress = 0;
			state = PLAY_TRANSITION_STATE.PLAYING;
			state_started_at = _now;
		};
	break;

	case PLAY_TRANSITION_STATE.PLAYING:
		if (owner.chart_exit_started) then play_transition_begin_exit();
	break;

	case PLAY_TRANSITION_STATE.OUTRO:
		progress = clamp(_elapsed / animation_duration, 0, 1);
		var _outro_eased = Easings.InOutExpo(progress);
		play_transition_apply(_outro_eased, true);
		owner.chart_exit_alpha = 1 - _outro_eased;
		if (progress >= 1) {
			play_transition_apply(1, true);
			owner.chart_exit_alpha = 0;
			line_progress = 0;
			state = PLAY_TRANSITION_STATE.EXIT_DELAY;
			state_started_at = _now;
		};
	break;

	case PLAY_TRANSITION_STATE.EXIT_DELAY:
		if (_elapsed >= exit_delay) then play_transition_finish_exit();
	break;
};
