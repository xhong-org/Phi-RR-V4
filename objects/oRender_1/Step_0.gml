/// @description
//if(game.settings.enableFPS) then window_set_caption($"{GAME_NAME} - FPS: {fps} / {fps_real}");
if(!game.paused){
	// The chart clock stays entirely on get_timer()'s microsecond timebase.
	game.Math.ctime();
	event_user(0); // BPMList compensation (RPE Other_10)
	// Activate only notes entering the configured preload window.
	if (is_struct(game_1) && bool(game_1._note_activation_enabled ?? false)
		&& is_array(game_1._notes)) {
		var _note_now = game.__time[1];
		var _note_index = clamp(real(game_1._note_activation_index ?? 0), 0, array_length(game_1._notes));
		while (_note_index < array_length(game_1._notes)
			&& game_1._notes[_note_index].activateSec <= _note_now) {
			var _time_note_id = game_1._notes[_note_index].id;
			instance_activate_object(_time_note_id);
			if (struct_exists(game_1, "_note_activation_records")) {
				var _time_note_key = string(_time_note_id);
				if (struct_exists(game_1._note_activation_records, _time_note_key)) {
					game_1._note_activation_records[$ _time_note_key].activated = true;
				};
			};
			_note_index++;
		};
		game_1._note_activation_index = _note_index;
		game_1._note_activation_last_time = _note_now;

		// Phira-style spatial query: project the screen onto each line's local
		// normal, then binary-search floor-sorted dormant notes in that interval.
		if (is_array(game_1._note_spatial_groups)) {
			var _screen_margin = room_height * 0.15;
			for (var _sgi = 0; _sgi < array_length(game_1._note_spatial_groups); _sgi++) {
				var _sg = game_1._note_spatial_groups[_sgi];
				var _sg_line = _sg.line;
				if (!instance_exists(_sg_line)) then continue;
				var _sg_speed = real(_sg.speed);
				if (_sg_speed == 0) then continue;
				var _sg_reversed = (_sg.above ? -1 : 1);
				var _sg_nx = real(_sg_line.__sin) * _sg_reversed;
				var _sg_ny = real(_sg_line.__cos) * _sg_reversed;
				var _p0 = (0 - _sg_line.x) * _sg_nx + (0 - _sg_line.y) * _sg_ny;
				var _p1 = (room_width - _sg_line.x) * _sg_nx + (0 - _sg_line.y) * _sg_ny;
				var _p2 = (0 - _sg_line.x) * _sg_nx + (room_height - _sg_line.y) * _sg_ny;
				var _p3 = (room_width - _sg_line.x) * _sg_nx + (room_height - _sg_line.y) * _sg_ny;
				var _proj_min = min(_p0, _p1, _p2, _p3) - _screen_margin;
				var _proj_max = max(_p0, _p1, _p2, _p3) + _screen_margin;
				var _floor_min = -infinity;
				var _floor_max = infinity;
				if (_sg.spatialSafe) {
					var _floor_a = real(_sg_line.__value[0]) + _proj_min / (room_height * 0.6 * _sg_speed);
					var _floor_b = real(_sg_line.__value[0]) + _proj_max / (room_height * 0.6 * _sg_speed);
					_floor_min = min(_floor_a, _floor_b);
					_floor_max = max(_floor_a, _floor_b);
				};
				var _sg_notes = _sg.notes;
				var _lo = 0;
				var _hi = array_length(_sg_notes);
				while (_lo < _hi) {
					var _mid = (_lo + _hi) div 2;
					if (_sg_notes[_mid].spatialFloor < _floor_min) then _lo = _mid + 1;
					else _hi = _mid;
				};
				for (var _sni = _lo; _sni < array_length(_sg_notes); _sni++) {
					var _sn = _sg_notes[_sni];
					if (_sn.spatialFloor > _floor_max) then break;
					if (_sn.activated) then continue;
					var _sn_to_hit = _sn.startSec - real(_sg_line.line_sec);
					if (_sn_to_hit <= 0) then continue;
					if (is_finite(_sn.visibleTime) && _sn.visibleTime < 999999
						&& _sn_to_hit > _sn.visibleTime) then continue;
					instance_activate_object(_sn.id);
					_sn.activated = true;
				};
			};
		};

		// Holds are interval geometry and cannot be represented by one sorted key.
		// Their count is normally small, so dormant interval checks stay cheap.
		if (is_array(game_1._note_spatial_holds)) {
			for (var _shi = 0; _shi < array_length(game_1._note_spatial_holds); _shi++) {
				var _sh = game_1._note_spatial_holds[_shi];
				if (_sh.activated || !instance_exists(_sh.line)) then continue;
				var _sh_line = _sh.line;
				var _sh_to_hit = _sh.startSec - real(_sh_line.line_sec);
				var _sh_to_end = _sh.endSec - real(_sh_line.line_sec);
				if (_sh_to_end <= 0) then continue;
				if (_sh_to_hit > 0 && is_finite(_sh.visibleTime) && _sh.visibleTime < 999999
					&& _sh_to_hit > _sh.visibleTime) then continue;
				if (_sh_to_hit <= 0) {
					instance_activate_object(_sh.id);
					_sh.activated = true;
					continue;
				};
				var _sh_reversed = (_sh.above ? -1 : 1);
				var _sh_nx = real(_sh_line.__sin) * _sh_reversed;
				var _sh_ny = real(_sh_line.__cos) * _sh_reversed;
				var _hp0 = (0 - _sh_line.x) * _sh_nx + (0 - _sh_line.y) * _sh_ny;
				var _hp1 = (room_width - _sh_line.x) * _sh_nx + (0 - _sh_line.y) * _sh_ny;
				var _hp2 = (0 - _sh_line.x) * _sh_nx + (room_height - _sh_line.y) * _sh_ny;
				var _hp3 = (room_width - _sh_line.x) * _sh_nx + (room_height - _sh_line.y) * _sh_ny;
				var _hproj_min = min(_hp0, _hp1, _hp2, _hp3) - room_height * 0.15;
				var _hproj_max = max(_hp0, _hp1, _hp2, _hp3) + room_height * 0.15;
				if (_sh.spatialSafe) {
					var _hold_head_px = (real(_sh.spatialFloor) - real(_sh_line.__value[0]))
						* room_height * 0.6 + real(_sh.yOrigin) * room_height;
					var _hold_tail_px = _hold_head_px + real(_sh.speed)
						* (real(_sh.endSpatialFloor) - real(_sh.spatialFloor)) * room_height * 0.6;
					if (max(_hold_head_px, _hold_tail_px) < _hproj_min
						|| min(_hold_head_px, _hold_tail_px) > _hproj_max) then continue;
				};
				instance_activate_object(_sh.id);
				_sh.activated = true;
			};
		};
	};
}
elif(game.paused && game.__time[0] > 0){
	//
};

if (!(variable_global_exists("render_mode") && global.render_mode)
	&& !chart_exit_started && game.__time[0] > 0 && instance_exists(oMedia)) {
	var exit_media = instance_find(oMedia, 0);
	if (exit_media.length > 0 && game.__time[4] >= exit_media.length) {
		chart_exit_started = true;
		chart_exit_timer = get_timer();
		chart_exit_alpha = 1;
		game.paused = true;
		m_pause();
	};
};

if (chart_exit_started) {
	var chart_exit_elapsed = max(0, get_timer() - chart_exit_timer);
	chart_exit_alpha = 1 - clamp(chart_exit_elapsed / 500000, 0, 1);
	// Room navigation is time-driven; UI bindings may hide HUD elements but
	// must never control or block the end-of-chart state machine.
	if (chart_exit_elapsed >= 500000 && !chart_exit_queued) {
		chart_exit_queued = true;
		if (instance_exists(oExtraPlay)) then with (oExtraPlay) instance_destroy();
		if (is_struct(game_1) && struct_exists(game_1, "HitSounds") && is_struct(game_1.HitSounds)) {
			if (instance_exists(oMedia)) {
				var exit_media_system = instance_find(oMedia, 0);
				if (exit_media_system.track > 0) then fmod_system_select(exit_media_system.track);
			};
			var exit_hit_names = struct_get_names(game_1.HitSounds);
			for (var exit_hit_i = 0; exit_hit_i < array_length(exit_hit_names); exit_hit_i++) {
				var exit_hit_sound = game_1.HitSounds[$ exit_hit_names[exit_hit_i]];
				if (exit_hit_sound > 0) then fmod_sound_release(exit_hit_sound);
			};
			game_1.HitSounds = {};
		};
		m_clean(true);
		chart_session_cleanup(true);
		room_goto(room_menu);
	};
};

event_user(_step_fps_user_count);
