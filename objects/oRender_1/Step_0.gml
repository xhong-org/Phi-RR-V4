/// @description
//if(game.settings.enableFPS) then window_set_caption($"{GAME_NAME} - FPS: {fps} / {fps_real}");
if(!game.paused){
	// The chart clock stays entirely on get_timer()'s microsecond timebase.
	game.Math.ctime();
	event_user(0); // BPMList compensation (RPE Other_10)
	var _rpe = game_1;
	// Activate only notes entering the configured preload window.
	if (is_struct(_rpe) && bool(_rpe._note_activation_enabled ?? false)
		&& is_array(_rpe._notes)) {
		var _room_w = room_width;
		var _room_h = room_height;
		var _room_half_w = _room_w * 0.5;
		var _room_half_h = _room_h * 0.5;
		var _notes_h = _room_h * 0.6;
		var _screen_margin = _room_h * 0.15;
		var _note_now = game.__time[1];
		var _notes = _rpe._notes;
		var _note_count = array_length(_notes);
		var _note_index = clamp(real(_rpe._note_activation_index ?? 0), 0, _note_count);
		var _activation_records = _rpe._note_activation_records;
		while (_note_index < _note_count && _notes[_note_index].activateSec <= _note_now) {
			var _time_note_id = _notes[_note_index].id;
			instance_activate_object(_time_note_id);
			if (is_struct(_activation_records)) {
				var _time_note_key = string(_time_note_id);
				if (struct_exists(_activation_records, _time_note_key)) {
					_activation_records[$ _time_note_key].activated = true;
				};
			};
			_note_index++;
		};
		_rpe._note_activation_index = _note_index;
		_rpe._note_activation_last_time = _note_now;

		// Phira-style spatial query: project the screen onto each line's local
		// normal, then binary-search floor-sorted dormant notes in that interval.
		var _spatial_groups = _rpe._note_spatial_groups;
		if (is_array(_spatial_groups)) {
			var _spatial_group_count = array_length(_spatial_groups);
			for (var _sgi = 0; _sgi < _spatial_group_count; _sgi++) {
				var _sg = _spatial_groups[_sgi];
				var _sg_line = _sg.line;
				if (!instance_exists(_sg_line)) then continue;
				var _sg_speed = real(_sg.speed);
				if (_sg_speed == 0) then continue;
				var _sg_reversed = (_sg.above ? -1 : 1);
				var _sg_nx = real(_sg_line.__sin) * _sg_reversed;
				var _sg_ny = real(_sg_line.__cos) * _sg_reversed;
				var _sg_x = real(_sg_line.x);
				var _sg_y = real(_sg_line.y);
				var _p0 = -_sg_x * _sg_nx - _sg_y * _sg_ny;
				var _p1 = (_room_w - _sg_x) * _sg_nx - _sg_y * _sg_ny;
				var _p2 = -_sg_x * _sg_nx + (_room_h - _sg_y) * _sg_ny;
				var _p3 = (_room_w - _sg_x) * _sg_nx + (_room_h - _sg_y) * _sg_ny;
				var _proj_min = min(_p0, _p1, _p2, _p3) - _screen_margin;
				var _proj_max = max(_p0, _p1, _p2, _p3) + _screen_margin;
				var _floor_min = -infinity;
				var _floor_max = infinity;
				if (_sg.spatialSafe) {
					var _sg_floor = real(_sg_line.__value[0]);
					var _floor_scale = _notes_h * _sg_speed;
					var _floor_a = _sg_floor + _proj_min / _floor_scale;
					var _floor_b = _sg_floor + _proj_max / _floor_scale;
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
				var _sg_note_count = array_length(_sg_notes);
				for (var _sni = _lo; _sni < _sg_note_count; _sni++) {
					var _sn = _sg_notes[_sni];
					if (_sn.spatialFloor > _floor_max) then break;
					if (_sn.activated) then continue;
					var _sn_to_hit = _sn.startSec - real(_sg_line.line_sec);
					var _sn_to_hit_real = _sn_to_hit * real(_sn.timeFactor);
					if (_sn_to_hit <= 0) then continue;
					if (is_finite(_sn.visibleTime) && _sn.visibleTime < 999999
						&& _sn_to_hit_real > _sn.visibleTime) then continue;
					instance_activate_object(_sn.id);
					_sn.activated = true;
				};
			};
		};

		// Holds are grouped so each line/side projects the viewport only once.
		var _hold_groups = _rpe._note_spatial_hold_groups;
		if (is_array(_hold_groups)) {
			var _hold_group_count = array_length(_hold_groups);
			for (var _hgi = 0; _hgi < _hold_group_count; _hgi++) {
				var _hg = _hold_groups[_hgi];
				var _sh_line = _hg.line;
				if (!instance_exists(_sh_line)) then continue;
				var _sh_reversed = (_hg.above ? -1 : 1);
				var _sh_nx = real(_sh_line.__sin) * _sh_reversed;
				var _sh_ny = real(_sh_line.__cos) * _sh_reversed;
				var _sh_x = real(_sh_line.x);
				var _sh_y = real(_sh_line.y);
				var _hp0 = -_sh_x * _sh_nx - _sh_y * _sh_ny;
				var _hp1 = (_room_w - _sh_x) * _sh_nx - _sh_y * _sh_ny;
				var _hp2 = -_sh_x * _sh_nx + (_room_h - _sh_y) * _sh_ny;
				var _hp3 = (_room_w - _sh_x) * _sh_nx + (_room_h - _sh_y) * _sh_ny;
				var _hproj_min = min(_hp0, _hp1, _hp2, _hp3) - _screen_margin;
				var _hproj_max = max(_hp0, _hp1, _hp2, _hp3) + _screen_margin;
				var _sh_floor = real(_sh_line.__value[0]);
				var _sh_line_sec = real(_sh_line.line_sec);
				var _hold_notes = _hg.notes;
				var _hold_count = real(_hg.count);
				var _shi = 0;
				while (_shi < _hold_count) {
					var _sh = _hold_notes[_shi];
					if (_sh.activated || _sh.endSec <= _sh_line_sec) {
						_hold_count--;
						_hold_notes[@ _shi] = _hold_notes[_hold_count];
						continue;
					};
					var _sh_to_hit = _sh.startSec - _sh_line_sec;
				var _sh_to_hit_real = _sh_to_hit * real(_sh.timeFactor);
				if (is_finite(_sh.visibleTime) && _sh.visibleTime < 999999
						&& _sh_to_hit_real > _sh.visibleTime) { _shi++; continue; };
				if (_sh_to_hit <= 0) {
					instance_activate_object(_sh.id);
					_sh.activated = true;
					_hold_count--;
					_hold_notes[@ _shi] = _hold_notes[_hold_count];
					continue;
				};
				if (_sh.spatialSafe) {
					var _hold_head_px = (real(_sh.spatialFloor) - _sh_floor)
						* _notes_h + real(_sh.yOrigin) * _room_h;
					var _hold_tail_px = _hold_head_px + real(_sh.speed)
						* (real(_sh.endSpatialFloor) - real(_sh.spatialFloor)) * _notes_h;
					if (max(_hold_head_px, _hold_tail_px) < _hproj_min
						|| min(_hold_head_px, _hold_tail_px) > _hproj_max) { _shi++; continue; };
				};
				instance_activate_object(_sh.id);
				_sh.activated = true;
				_hold_count--;
				_hold_notes[@ _shi] = _hold_notes[_hold_count];
				};
				_hg.count = _hold_count;
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
