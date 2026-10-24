///@desc 推进 RPE 时钟、音符激活和曲终退出
if (chart_load_step(oLine_1, rpe_lines_pump, rpe_lines_complete, rpe_lines_thaw_force_init, rpe_sync_note_activation)) then exit;
if (variable_global_exists("loading_animation_active") && global.loading_animation_active) exit;
//if(game.settings.enableFPS) then window_set_caption($"{GAME_NAME} - FPS: {fps} / {fps_real}");
var chart_os_hold = chart_android_focus_step();
if(!game.paused && !chart_os_hold){
	// 谱面时钟只用 get_timer 的微秒时间基。
	game.Math.ctime();
	event_user(0); // 用用户事件 0 补偿 BPM 列表
	var _rpe = game_1;
	// 只激活进入预加载窗口的音符。
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
		// 按时间顺序激活到期音符。
		while (_note_index < _note_count && _notes[_note_index].activateSec <= _note_now) {
			var _time_note_id = _notes[_note_index].id;
			chart_note_activate(_time_note_id);
			if (is_struct(_activation_records)) {
				var _time_note_key = string(_time_note_id);
				if (struct_exists(_activation_records, _time_note_key)) {
					rpe_note_mark_active(_activation_records[$ _time_note_key]);
				};
			};
			_note_index++;
		};
		_rpe._note_activation_index = _note_index;
		_rpe._note_activation_last_time = _note_now;

		// 把屏幕投到每条线的法线，再对按地板排序的休眠音符做二分。
		var _spatial_groups = _rpe._note_spatial_groups;
		if (is_array(_spatial_groups)) {
			var _spatial_group_count = array_length(_spatial_groups);
			for (var _sgi = 0; _sgi < _spatial_group_count; _sgi++) {
				var _sg = _spatial_groups[_sgi];
				if (_sg.remaining <= 0) continue;
				var _sg_line = _sg.line;
				// 判定线不在或速度为 0 时跳过这一组。
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
				// 二分找到第一枚进入地板区间的音符。
				while (_lo < _hi) {
					var _mid = (_lo + _hi) div 2;
					if (_sg_notes[_mid].spatialFloor < _floor_min) then _lo = _mid + 1;
					else _hi = _mid;
				};
				var _sg_note_count = array_length(_sg_notes);
				for (var _sni = _lo; _sni < _sg_note_count; _sni++) {
					if (_sg.blockLive[_sni div 64] <= 0) {
						_sni = ((_sni div 64) + 1) * 64 - 1;
						continue;
					}
					var _sn = _sg_notes[_sni];
					// 超出地板区间就不用再看后面的音符。
					if (_sn.spatialFloor > _floor_max) then break;
					if (_sn.activated) then continue;
					var _sn_to_hit = _sn.startSec - real(_sg_line.line_sec);
					var _sn_to_hit_real = _sn_to_hit * real(_sn.timeFactor);
					if (_sn_to_hit <= 0) then continue;
					if (is_finite(_sn.visibleTime) && _sn.visibleTime < 999999
						&& _sn_to_hit_real > _sn.visibleTime) then continue;
					chart_note_activate(_sn.id);
					rpe_note_mark_active(_sn);
				};
			};
		};

		// Hold 按线和上下侧分组，每组只投影一次视口。
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
				if (_hg.remaining <= 0) continue;
				var _hold_notes = _hg.notes;
				var _hold_count = array_length(_hold_notes);
				var _floor_min = -infinity;
				var _floor_max = infinity;
				var _shi = 0;
				if (_hg.spatialSafe) {
					var _offset_px = _hg.yOrigin * _room_h;
					var _scale = _hg.speed * _notes_h;
					var _fa = _sh_floor + (_hproj_min - _offset_px) / _scale;
					var _fb = _sh_floor + (_hproj_max - _offset_px) / _scale;
					// 只增加少量候选，避免代数换算的末位误差把边界 Hold 漏掉。
					var _epsilon = max(1, abs(_fa), abs(_fb)) * 0.0000001;
					_floor_min = min(_fa, _fb) - _epsilon;
					_floor_max = max(_fa, _fb) + _epsilon;
					var _hi = _hold_count;
					while (_shi < _hi) {
						var _mid = (_shi + _hi) div 2;
						if (_hg.tailMax[_mid] < _floor_min) _shi = _mid + 1;
						else _hi = _mid;
					}
				}
				for (; _shi < _hold_count; _shi++) {
					if (_hg.blockLive[_shi div 64] <= 0) {
						_shi = ((_shi div 64) + 1) * 64 - 1;
						continue;
					}
					var _sh = _hold_notes[_shi];
					if (min(_sh.spatialFloor, _sh.endSpatialFloor) > _floor_max) break;
					if (_sh.activated || _sh.endSec <= _sh_line_sec) continue;
					var _sh_to_hit = _sh.startSec - _sh_line_sec;
					if (is_finite(_sh.visibleTime) && _sh.visibleTime < 999999
						&& _sh_to_hit * _sh.timeFactor > _sh.visibleTime) continue;
					if (_sh_to_hit > 0 && _sh.spatialSafe) {
						var _head_px = _sh.speed * (_sh.spatialFloor - _sh_floor) * _notes_h + _sh.yOrigin * _room_h;
						var _tail_px = _head_px + _sh.speed * (_sh.endSpatialFloor - _sh.spatialFloor) * _notes_h;
						if (max(_head_px, _tail_px) < _hproj_min || min(_head_px, _tail_px) > _hproj_max) continue;
					}
					chart_note_activate(_sh.id);
					rpe_note_mark_active(_sh);
				}
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
	// 音频播完就进入退出流程。
	if (exit_media.length > 0 && game.__time[4] >= exit_media.length) {
		chart_exit_started = true;
		chart_exit_timer = get_timer();
		chart_exit_alpha = 1;
		game.paused = true;
		m_pause();
	};
};

event_user(_step_fps_user_count);
