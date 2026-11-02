// PEC 播放实体：共享静态方法，由 ChartActors 显式调度。
// 原 oLine_2 / oNote_2 事件保留为迁移对照，不再创建这些 Object Instances。

function PECJudgeLine(_object, _x, _y, _depth, _fields)
	: ChartActor(_object, _x, _y, _depth, _fields) constructor {
	// 原事件：objects/oLine_2/Create_0.gml；迁移前源码见 docs/constructor-migration/legacy/pec。
	static actor_create = function() {
		///@desc 创建：PEC 判定线的运行时状态
		depth = DEPTH.LINE;

		// 贴图缺失时退回默认判定线。
		if (!chart_actor_var_exists(id, "image_id") || !sprite_exists(image_id)) then image_id = line;
		if (!chart_actor_var_exists(id, "line_csv_scale")) then line_csv_scale = 1;
		sprite_index = image_id;
		image_blend = chart_line_judge_blend();
		var initial_scale = (variable_global_exists("global_scales") ? global_scales : 1);
		// 默认线和自定义贴图的初始缩放不同。
		if (image_id == line) {
			image_xscale = 0.9204 * initial_scale;
			image_yscale = 0.52 * initial_scale;
		} else {
			var _csv_scale = chart_line_csv_sprite_scale(chart_line_override(line_id), image_id);
			image_xscale = _csv_scale[0];
			image_yscale = _csv_scale[1];
		};
		// 没有事件结构就用空的 PEC 线数据，并缓存各通道长度。
		if (!chart_actor_var_exists(id, "events") || !is_struct(events)) then events = pec_line_data();
		_move_index = 0;
		_alpha_index = 0;
		_rotate_index = 0;
		_speed_index = 0;
		_move_value = [0, 0];
		_move_x = 0;
		_move_y = 0;
		_alpha_value = 1;
		_alpha_raw = 255;
		_rotate_value = 0;
		floor_position = 0;
		line_sec = 0;
		_last_line_sec = -infinity;
		__cos = 1;
		__sin = 0;
		_last_angle = 0;
		_last_scale = -1;
		_last_room_height = -1;
		_last_view_width = -1;
		_move_events = events.moveEvents;
		_alpha_events = events.alphaEvents;
		_rotate_events = events.rotateEvents;
		_speed_events = events.speedEvents;
		_move_count = array_length(_move_events);
		_alpha_count = array_length(_alpha_events);
		_rotate_count = array_length(_rotate_events);
		_speed_count = array_length(_speed_events);
		chart_force_event_init = false;
		if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then visible = false;
	};

	// 原事件：objects/oLine_2/Step_1.gml；迁移前源码见 docs/constructor-migration/legacy/pec。
	static actor_begin = function() {
		///@desc 步进开始：PEC 判定线自己的谱面秒
		line_sec = game.__time[1] - game_2.chart.offsetSeconds;
	};

	// 原事件：objects/oLine_2/Step_0.gml；迁移前源码见 docs/constructor-migration/legacy/pec。
	static actor_step = function() {
		///@desc 步进：求值归一化后的 PEC 事件和速度 floor
		// 加载动画或暂停时不推进，除非强制初始化。
		if (variable_global_exists("loading_animation_active") && global.loading_animation_active
			&& !chart_force_event_init) then exit;
		var current_scale = (variable_global_exists("global_scales") ? global_scales : 1);
		// 缩放或视口变了才重算精灵缩放。
		if (current_scale != _last_scale || room_height != _last_room_height
			|| chart_view_width != _last_view_width) {
			if (image_id == line) {
				image_xscale = 0.9204 * current_scale;
				image_yscale = 0.52 * current_scale;
			} else {
				var _csv_scale = chart_line_csv_sprite_scale(chart_line_override(line_id), image_id);
				image_xscale = _csv_scale[0];
				image_yscale = _csv_scale[1];
			};
			_last_scale = current_scale;
			_last_room_height = room_height;
			_last_view_width = chart_view_width;
		};
		if (game.paused && !chart_force_event_init) {
			// 暂停事件值，只校正窗口变化后的坐标。
			x = chart_view_left + chart_view_width * _move_x;
			y = chart_view_height * _move_y;
			exit;
		};
		line_sec = game.__time[1] - game_2.chart.offsetSeconds;
		image_blend = chart_line_judge_blend();
		// 时间回退时游标和当前值全部归零重放。
		if (line_sec < _last_line_sec) {
			_move_index = 0; _alpha_index = 0; _rotate_index = 0; _speed_index = 0;
			_move_x = 0; _move_y = 0; _alpha_value = 1; _rotate_value = 0;
		};
		_last_line_sec = line_sec;

		// 吃掉已经结束的位移，再对当前这一条做缓动。
		while (_move_index < _move_count && line_sec >= _move_events[_move_index].endSec) {
			_move_x = _move_events[_move_index].endX;
			_move_y = _move_events[_move_index].endY;
			_move_index++;
		};
		if (_move_index < _move_count && line_sec >= _move_events[_move_index].startSec) {
			var move_event = _move_events[_move_index];
			// 瞬时事件直接取终点。
			if (move_event.instant) {
				_move_x = move_event.endX;
				_move_y = move_event.endY;
			}
			else {
				_move_x = tween_execute(line_sec, move_event.startSec, move_event.endSec, move_event.startX, move_event.endX, move_event.easing);
				_move_y = tween_execute(line_sec, move_event.startSec, move_event.endSec, move_event.startY, move_event.endY, move_event.easing);
			};
		};

		// 透明度：先落到已结束事件的终点，再插值当前事件。
		while (_alpha_index < _alpha_count && line_sec >= _alpha_events[_alpha_index].endSec) {
			_alpha_value = _alpha_events[_alpha_index][$ "end"];
			_alpha_index++;
		};
		if (_alpha_index < _alpha_count && line_sec >= _alpha_events[_alpha_index].startSec) {
			var alpha_event = _alpha_events[_alpha_index];
			_alpha_value = (alpha_event.instant ? alpha_event[$ "end"] : tween_execute(line_sec, alpha_event.startSec, alpha_event.endSec, alpha_event.start, alpha_event[$ "end"], alpha_event.easing));
		};

		// 旋转同样先消费已结束事件。
		while (_rotate_index < _rotate_count && line_sec >= _rotate_events[_rotate_index].endSec) {
			_rotate_value = _rotate_events[_rotate_index][$ "end"];
			_rotate_index++;
		};
		if (_rotate_index < _rotate_count && line_sec >= _rotate_events[_rotate_index].startSec) {
			var rotate_event = _rotate_events[_rotate_index];
			_rotate_value = (rotate_event.instant ? rotate_event[$ "end"] : tween_execute(line_sec, rotate_event.startSec, rotate_event.endSec, rotate_event.start, rotate_event[$ "end"], rotate_event.easing));
		};

		floor_position = pec_floor_at_sec(_speed_events, line_sec);

		x = chart_view_left + chart_view_width * _move_x;
		y = chart_view_height * _move_y;
		_alpha_raw = _alpha_value * 255;
		image_alpha = clamp(_alpha_value, 0, 1);
		image_angle = _rotate_value;
		// 角度没变就不重算正余弦。
		if (image_angle != _last_angle) {
			__cos = dcos(image_angle);
			__sin = dsin(image_angle);
			_last_angle = image_angle;
		};
	};

	// 原事件：objects/oLine_2/Other_10.gml；迁移前源码见 docs/constructor-migration/legacy/pec。
	static user_0 = function() {
		///@desc 用户事件 0：事件初始化
		line_time = 0;
		_counts = [0 , 0 , 0 , 0];

		_x = (room_width / 2);
		_y = (room_height / 2);
		_a = 0;
		_r = 0;
		_s = 0;

		var name = (struct_get_names(self.events));

		// 速度事件不改缓动表；其余通道把缓动号映射成运行时索引。
		for(var i = 0 ; i < array_length(name) ; i ++){
		    var _events = (self.events[$ name[i]]);
		    
		    // 速度不走这张缓动表。
		    if(name[i] == "speedEvents") then continue;
		        
		    var index = [ 0, 1, 3, 2, 6, 5, 4, 7, 9, 8, 12, 11, 10, 13, 15, 14, pointer_null, 17, 16, pointer_null, 19, 18, 22, 21, 20, 23, 25, 24, pointer_null, 27, 26, 28 ];
		    
		    for(var l = 0 ; l < array_length(_events) ; l ++){
		        var _event = (_events[l]);
		        // 第一条事件作为初始位置、透明度和旋转。
		        if(l == 0){
		            switch (name[i]) {
		            	case "moveEvents":
		                    _x = (number(_event.value[0] , 0));
		                    _y = (number(_event.value[1] , 0));
		                break;
		            
		                case "alphaEvents":
		                    _a = (number(_event.value , 0));
		                break;
		            
		                case "rotateEvents":
		                    _r = (number(_event.value , 0));
		                break;    
		            };
		        };
		        
		        //if(_events.startT)
		        struct_set(self.events[$ name[i]][l] , "easingType" , index[_event.easingType]);
		    };
		};
	};

	// Object 默认 Draw 改为显式绘制，动画帧由运行容器推进。
	static actor_draw = function() {
		if (!sprite_exists(sprite_index) || image_alpha <= 0) then return;
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale,
			image_angle, image_blend, image_alpha);
	};

	// 事件数据为共享托管值；这里只断开本线持有的引用。
	static actor_cleanup = function() {
		events = undefined;
		_move_events = undefined;
		_alpha_events = undefined;
		_rotate_events = undefined;
		_speed_events = undefined;
		_move_value = undefined;
	};

	actor_create();
}

function PECNote(_object, _x, _y, _depth, _fields)
	: ChartActor(_object, _x, _y, _depth, _fields) constructor {
	// 原事件：objects/oNote_2/Create_0.gml；迁移前源码见 docs/constructor-migration/legacy/pec。
	static actor_create = function() {
		///@desc 初始化规范化后的 PEC 音符和判定窗口
		depth = DEPTH.NOTE;
		canDraw = false;
		_last_view_width = -1;
		_last_view_height = -1;
		_last_view_left = -1;
		_last_geometry_scale = -1;
		if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then visible = false;

		judged = false;
		hold_started = false;
		isMiss = false;
		hit_status = TYPE.NONE;
		isBad = false;
		judgeRealTime = 0;
		_bad_x = 0; _bad_y = 0; _bad_angle = 0;
		hold_effect_sec = -infinity;
		image_alpha = 1;
		if (!chart_actor_var_exists(id, "note_speed")) {
			note_speed = (chart_actor_var_exists(id, "speed") ? speed : 1);
		};
		note_speed = real(note_speed);
		if (!is_finite(note_speed)) then note_speed = 1;
		// 保留原事件的独立音符速度；Constructor 不依赖内置运动。
		speed = 0;
		direction = 0;
		if (!chart_actor_var_exists(id, "widthScale")) then widthScale = 1;
		if (!chart_actor_var_exists(id, "isFake")) then isFake = false;
		if (!chart_actor_var_exists(id, "start_beat")) then start_beat = 0;
		if (!chart_actor_var_exists(id, "end_beat")) then end_beat = start_beat;
		start_beat = real(start_beat);
		end_beat = real(end_beat);
		if (!chart_actor_var_exists(id, "localXFactor")) then localXFactor = xOffset * 0.05625;
		if (!chart_actor_var_exists(id, "sideDirection")) then sideDirection = isAbove ? -1 : 1;
		if (!chart_actor_var_exists(id, "angleOffset")) then angleOffset = isAbove ? 0 : 180;
		speedFloorStart = note_speed * floorPosition;
		speedFloorEnd = note_speed * endFloorPosition;
		speedHoldFloorLength = note_speed * (endFloorPosition - floorPosition);
		// 判定线不存在就停用。
		if (!is_array(game_2.line_group) || line_id < 0 || line_id >= array_length(game_2.line_group)) {
			chart_actor_deactivate(self);
			exit;
		};
		line_ref = game_2.line_group[line_id];
		var base_scale = (variable_global_exists("global_scales") ? global_scales : 1) / 6 * game.settings.noteSize;
		image_xscale = base_scale * widthScale;
		uniform_scale = bool(game.settings.noteUniformScale ?? false);
		image_yscale = uniform_scale ? image_xscale : base_scale;
		hl = 0;
		if (variable_global_exists("BYD_COLOR_MODE") && BYD_COLOR_MODE && type != 2) then hl = 2;
		if (chart_actor_var_exists(id, "_hl") && _hl == 1) then hl = 1;
		use_acc_judgment = bool(game.settings.enableAccJudgment ?? true);
		hold_body_height = max(1, sprite_get_height(note_hold_body));
		// PEC 类型编号和官谱不同，这里映射贴图与判定类型。
		switch (type) {
			case 1: sprite_index = note_tap; sound = skin_note_sound("tap", snd_note_tap); judge_type = 1; break;
			case 2: depth = DEPTH.LINE - 1; sprite_index = note_hold_head; sound = skin_note_sound("tap", snd_note_tap); judge_type = 3; break;
			case 3: sprite_index = note_flick; sound = skin_note_sound("flick", snd_note_flick); judge_type = 4; break;
			case 4: sprite_index = note_drag; sound = skin_note_sound("drag", snd_note_drag); judge_type = 2; break;
		};
		hit_offset = chart_auto_hit_offset_ms(judge_type) * 0.001;
		late_window_sec = ((judge_type == 2 || judge_type == 4) ? 0.160 : (judge_type == 3 ? 0.161 : 0.201));
		hold_head_attach = 0;
		if (type == 2) {
				hold_head_attach = max(1, sprite_get_yoffset(sprite_index));
				var _skin_hold = skin_hold_parts(hl);
				if (is_struct(_skin_hold)) {
					if (sprite_exists(_skin_hold.body)) then hold_body_height = max(1, sprite_get_height(_skin_hold.body));
					if (sprite_exists(_skin_hold.head)) then hold_head_attach = max(1, sprite_get_yoffset(_skin_hold.head));
				};
		};
		hold_bpm_index = 0;
		hold_bpm_last_sec = -infinity;
		judge_sec = startSec + hit_offset;
		trigger_sec = ((judge_type == 2 || judge_type == 4) ? startSec : judge_sec);
		late_deadline_sec = startSec + late_window_sec;
		hx0 = 0; hy0 = 0; hx1 = 0; hy1 = 0; hx2 = 0; hy2 = 0;
		chart_kb_register_note();
	};

	// 原事件：objects/oNote_2/Step_0.gml；迁移前源码见 docs/constructor-migration/legacy/pec。
	static actor_step = function() {
		///@desc 更新 PEC 音符位置，并处理自动播放或超时判定
		if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then exit;
		if (!chart_actor_exists(line_ref)) then exit;
		var current_scale = (variable_global_exists("global_scales") ? global_scales : 1) / 6 * game.settings.noteSize;
		var geometry_changed = _last_view_width != chart_view_width
			|| _last_view_height != chart_view_height || _last_view_left != chart_view_left
			|| _last_geometry_scale != current_scale;
		_last_view_width = chart_view_width;
		_last_view_height = chart_view_height;
		_last_view_left = chart_view_left;
		_last_geometry_scale = current_scale;
		// 暂停时只允许窗口校正，下面几何分支之后直接退出，不进入任何判定。
		if (game.paused && !geometry_changed) then exit;
		var chart_sec = game.__time[1] - game_2.chart.offsetSeconds;
		if (isBad) {
			if (game.paused) then exit;
			canDraw = true;
			if (chart_sec - judgeRealTime >= 1) chart_actor_deactivate(self);
			exit;
		}
		var line_floor = line_ref.floor_position;
		image_xscale = current_scale * widthScale;
		image_yscale = uniform_scale ? image_xscale : current_scale;
		var scene_height = chart_view_height * 0.6;
		var local_x = localXFactor * chart_view_width;
		var axis_x = line_ref.__sin * sideDirection;
		var axis_y = line_ref.__cos * sideDirection;
		var base_x = line_ref.x + line_ref.__cos * local_x;
		var base_y = line_ref.y - line_ref.__sin * local_x;
		var before_hold = (type == 2 && chart_sec < startSec);
		// 位移是音符速度乘音符地板与判定线地板之差。
		var speed_pos = note_speed * (floorPosition - line_floor);
		var distance_units = (type == 2 && !before_hold) ? 0 : speed_pos;
		var distance = distance_units * scene_height;
		var note_x = base_x + axis_x * distance;
		var note_y = base_y + axis_y * distance;
		image_angle = line_ref.image_angle + angleOffset;
		var pec_alpha_raw = real(line_ref._alpha_raw ?? (line_ref._alpha_value * 255));
		var line_notes_visible = pec_note_alpha_visible(pec_alpha_raw, isAbove, startSec - chart_sec, startSec);
		var behind_line = (speed_pos < -0.000001);
		image_alpha = 1;
		if (type != 2) {
			image_alpha = chart_note_pass_fade(chart_sec, startSec, late_window_sec);
		};

		// Hold 单独算头尾，并在自动或手动路径里判定。
		if (type == 2) {
			var before = before_hold;
			var _skin_hold = skin_active() ? skin_hold_parts(hl) : undefined;
			var head_scale = 1;
			if (is_struct(_skin_hold)) {
				if (sprite_exists(_skin_hold.body)) then hold_body_height = max(1, sprite_get_height(_skin_hold.body));
				if (sprite_exists(_skin_hold.head)) then hold_head_attach = max(1, sprite_get_yoffset(_skin_hold.head));
				head_scale = skin_note_scale_k(_skin_hold.head);
			};
			var head_offset = 0;
			if (before && !(is_struct(_skin_hold) && bool(_skin_hold.compact))) {
				head_offset = max(0, hold_head_attach * image_yscale * head_scale);
			};
			var units = before ? speedHoldFloorLength : speedFloorEnd - note_speed * line_floor;
			head_offset = min(head_offset, max(0, units * scene_height));
			var hold_length = max(0, units * scene_height - head_offset);
			var body_scale = hold_length / hold_body_height;
			if (before) {
				hx0 = note_x; hy0 = note_y;
				hx1 = note_x + axis_x * head_offset; hy1 = note_y + axis_y * head_offset;
				hx2 = note_x + axis_x * (head_offset + hold_length); hy2 = note_y + axis_y * (head_offset + hold_length);
			} else {
				hx0 = base_x; hy0 = base_y;
				hx1 = base_x + axis_x * hold_length; hy1 = base_y + axis_y * hold_length;
			};
			yscale = body_scale;
			canDraw = line_notes_visible && (hold_length > 0 || before) && (before ? !behind_line : true);
			if (game.paused) then exit;
			if (!isFake && !chart_autoplay_active()) then exit;
			// 自动播放到判定秒开始 Hold，超时则记 Miss。
			if (chart_autoplay_active()) {
				if (!hold_started && chart_sec >= judge_sec) {
					hold_started = true;
					if (!isFake) {
						var hold_sample_sec = (!use_acc_judgment && chart_sec > late_deadline_sec) ? chart_sec : judge_sec;
						var _hold_xy = pec_note_hit_effect_xy();
						hit_status = judgeCalc(startSec, hold_sample_sec, 0, _hold_xy[0], _hold_xy[1], judge_type, true, false, true);
						if (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT) {
							hold_effect_sec = chart_sec;
							skin_play_note_hitsound();
						};
					};
				};
			} else if (!isFake && !hold_started && !isMiss && chart_sec > late_deadline_sec) {
				isMiss = true;
				hold_started = true;
				hit_status = judgeCalc(startSec, chart_sec, 0, base_x, base_y, judge_type, false, true, true);
			};
			if (hold_started && !isFake && !isMiss && (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT)
				&& chart_autoplay_active()) {
				var bpm_events = game_2.chart.bpmList;
				if (chart_sec < hold_bpm_last_sec) then hold_bpm_index = pec_bpm_index_at_sec(bpm_events, chart_sec);
				// BPM 事件向前走到当前秒，按间隔刷尾迹。
				while (hold_bpm_index + 1 < array_length(bpm_events) && bpm_events[hold_bpm_index + 1].second <= chart_sec) hold_bpm_index++;
				hold_bpm_last_sec = chart_sec;
				if (chart_sec - hold_effect_sec >= bpm_events[hold_bpm_index].holdTickInterval) {
					var _tick_xy = pec_note_hit_effect_xy();
					if (variable_global_exists("_eff_c")) then _eff_c(_tick_xy[0], _tick_xy[1], hit_status == TYPE.PREFECT ? #ffeca0 : make_colour_rgb(162, 238, 255));
					hold_effect_sec = chart_sec;
				};
			};
			// Hold 结束时补记判定并停用。
			if (chart_sec >= endSec && (hold_started || isMiss || chart_autoplay_active() || chart_sec > late_deadline_sec)) {
				if (!isFake) {
					if (hold_started && (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT) && !isMiss) {
						judgeCalc(startSec, judge_sec, 0, base_x, base_y, judge_type, false, true, true);
					} else if (!isMiss) {
						judgeCalc(startSec, endSec + 1, 0, base_x, base_y, judge_type, false, true, true);
					};
				};
				canDraw = false;
				chart_actor_deactivate(self);
			};
			//if(line_id == 7 && floor(start_beat) == 32){
			//	print($"Hold State: hitTime={start_beat} line_id={line_id} type={type} x={note_x} y={note_y} rot={image_angle} yscale={yscale} nowTime={chart_sec} lineFP={line_floor} noteFP={floorPosition} speed={note_speed}");
			//};
			exit;
		};

		x = note_x;
		y = note_y;


		canDraw = line_notes_visible && !judged && (chart_sec < startSec ? !behind_line : image_alpha > 0);
		if (game.paused) then exit;
		if (!isFake && !chart_autoplay_active()) then exit;
		// 非 Hold：到触发秒判定，超时则记 Miss。
		if (chart_autoplay_active()) {
			if (chart_sec >= trigger_sec && !judged) {
				judged = true;
				if (!isFake) {
					var note_sample_sec = (!use_acc_judgment && chart_sec > late_deadline_sec) ? chart_sec : judge_sec;
					var _hit_xy = pec_note_hit_effect_xy();
					hit_status = judgeCalc(startSec, note_sample_sec, 0, _hit_xy[0], _hit_xy[1], judge_type, true, true, true);
					if (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT) then skin_play_note_hitsound();
				};
				canDraw = false;
				chart_actor_deactivate(self);
			};
		} else if (!judged && chart_sec > late_deadline_sec) {
			judged = true;
			if (!isFake) {
				judgeCalc(startSec, chart_sec, 0, x, y, judge_type, false, true, true);
			};
			canDraw = false;
			chart_actor_deactivate(self);
		};
	};

	// 原事件：objects/oNote_2/Draw_0.gml；迁移前源码见 docs/constructor-migration/legacy/pec。
	static actor_draw = function() {
		///@desc 绘制 PEC 音符或 Hold 几何
		if (!canDraw) then exit;
		if (isBad) {
			var bad_sprite = skin_active() ? skin_note_sprite("tap", 0) : -1;
			var bad_scale = sprite_exists(bad_sprite) ? skin_note_scale_k(bad_sprite) : 1;
			if (!sprite_exists(bad_sprite)) bad_sprite = sprite_index;
			var age = game.__time[1] - game_2.chart.offsetSeconds - judgeRealTime;
			draw_sprite_ext(bad_sprite, 0, _bad_x, _bad_y, image_xscale * bad_scale, image_yscale * bad_scale,
				_bad_angle, c_red, max(0, 1 - age) * 0.5);
			exit;
		}

		// 有皮肤时换皮肤精灵，否则用默认 Hold 绘制。
		if (skin_active()) {
			var _skin_kind = (type == 4 ? "drag" : (type == 3 ? "flick" : "tap"));
			var _skin_spr = skin_note_sprite(_skin_kind, hl);
			var _skin_hold = (type == 2) ? skin_hold_parts(hl) : undefined;
			var _keep_head = is_struct(_skin_hold) && bool(_skin_hold.keep_head);
			var _compact = is_struct(_skin_hold) && bool(_skin_hold.compact);
			var _tail_trim = _compact ? image_yscale * sprite_get_height(_skin_hold.tail) * 0.5 : 1;
			var sk = sprite_exists(_skin_spr) ? skin_note_scale_k(_skin_spr) : 1;
			var hk = (is_struct(_skin_hold) && sprite_exists(_skin_hold.head)) ? skin_note_scale_k(_skin_hold.head) : 1;
			if (type != 2) {
				if (sprite_exists(_skin_spr)) then draw_sprite_ext(_skin_spr, 0, x, y, image_xscale * sk, image_yscale * sk, image_angle, image_blend, image_alpha);
				else draw_sprite_ext(sprite_index, hl, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
			} else if (hold_started) {
				var hold_a = isMiss ? 0.5 : image_alpha;
				if (is_struct(_skin_hold)) {
					draw_hold_fit(hx0, hy0, image_xscale * hk, image_yscale * hk, yscale,
						image_angle, 0, image_blend, hold_a, _keep_head, false, _compact ? _tail_trim * hk : 0, 1,
						_skin_hold.head, _skin_hold.body, _skin_hold.tail);
				} else {
					draw_hold_fit(hx0, hy0, image_xscale, image_yscale, yscale,
						image_angle, hl, image_blend, hold_a, false);
				};
			} else {
				if (is_struct(_skin_hold)) {
					draw_hold_fit(hx0, hy0, image_xscale * hk, image_yscale * hk, yscale,
						image_angle, 0, image_blend, image_alpha, true, !_compact, _tail_trim * hk, 1,
						_skin_hold.head, _skin_hold.body, _skin_hold.tail);
				} else {
					draw_hold_fit(hx0, hy0, image_xscale, image_yscale, yscale,
						image_angle, hl, image_blend, image_alpha, true, false, 1);
				};
			};
			exit;
		};

		if (type != 2) {
			draw_sprite_ext(sprite_index, hl, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
		} else if (hold_started) {
			draw_hold_fit(hx0, hy0, image_xscale, image_yscale, yscale,
				image_angle, hl, image_blend, isMiss ? 0.5 : image_alpha, false);
		} else {
			draw_hold_fit(hx0, hy0, image_xscale, image_yscale, yscale,
				image_angle, hl, image_blend, image_alpha, true, false, 1);
		};
	};

	// 共享皮肤、音频与精灵由会话释放，音符只解除引用。
	static actor_cleanup = function() {
		line_ref = undefined;
		kb_record = undefined;
	};

	actor_create();
}
