if (!instance_exists(owner) || !variable_global_exists("game") || !is_struct(game)) {
	instance_destroy();
	exit;
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
		state = PLAY_TRANSITION_STATE.INTRO_DELAY;
	};
	var _render_elapsed = max(0, (global.render_frame - render_started_frame) / max(1, global.render_fps));
	if (_render_elapsed < 0.1) {
		game.paused = true;
		play_transition_apply(0);
		state = PLAY_TRANSITION_STATE.INTRO_DELAY;
	} else if (_render_elapsed < 1.1) {
		game.paused = true;
		progress = clamp((_render_elapsed - 0.1) / 1.0, 0, 1);
		play_transition_apply(Easings.InOutExpo(progress));
		state = PLAY_TRANSITION_STATE.INTRO;
	} else if (_render_elapsed < 1.6) {
		game.paused = true;
		play_transition_apply(1);
		state = PLAY_TRANSITION_STATE.START_DELAY;
	} else {
		if (state != PLAY_TRANSITION_STATE.PLAYING) {
			play_transition_activate_gameplay();
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
		if (!instance_exists(oMedia)) then break;
		var _media = instance_find(oMedia, 0);
		if (!variable_instance_exists(_media, "isExists")
			|| !variable_instance_exists(_media, "success")) then break;
		if (!bool(variable_instance_get(_media, "isExists"))
			|| !bool(variable_instance_get(_media, "success"))) then break;
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
