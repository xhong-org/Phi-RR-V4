// 官谱线/音符的受控生命周期。旧 Object Events 保留用于迁移对照。
// 方法存于 constructor static，避免每颗音符重复分配行为闭包。
// 原源码与事件映射另见 docs/constructor-migration/。

function OfficialJudgeLine(_object, _x, _y, _depth, _fields) : ChartActor(_object, _x, _y, _depth, _fields) constructor {
    // 原事件源码保留于 objects/oLine/Create_0.gml。
    static actor_create = function() {
        ///@desc 创建：缓存每帧热路径要用的不变谱面数据
        depth = DEPTH.LINE;
        sprite_index = self.image_id;
        image_blend = chart_line_judge_blend();

        // 拆出四条事件流并记下长度，避免每帧再查结构。
        _events = self.events;
        struct_remove(self, "events");
        // 只有收成播放谱后仍带缓动的线才走缓动。v1 和纯线性线保持原来的插值
        ease_live = (_events[$ "simEase"] == true);

        _move_events = _events.judgeLineMoveEvents;
        _rotate_events = _events.judgeLineRotateEvents;
        _alpha_events = _events.judgeLineDisappearEvents;
        _speed_events = _events.speedEvents;
        events_flat = false;
        _move_pack = [];
        _rotate_pack = [];
        _alpha_pack = [];
        _speed_pack = [];
        // 后门关闭时继续用结构体。打开时热路径只读数组
        if (official_array_pack_enabled()) {
        	_move_pack = official_pack_move(_move_events);
        	_rotate_pack = official_pack_axis(_rotate_events);
        	_alpha_pack = official_pack_axis(_alpha_events);
        	_speed_pack = official_pack_speed(_speed_events, (1 / (_events.bpm / 1.875)));
        	events_flat = true;
        };
        _event_groups = [_move_events, _rotate_events, _alpha_events, _speed_events];
        _event_lengths = events_flat ? [
        	array_length(_move_pack) div OFF_EV_MOVE,
        	array_length(_rotate_pack) div OFF_EV_AXIS,
        	array_length(_alpha_pack) div OFF_EV_AXIS,
        	array_length(_speed_pack) div OFF_EV_SPEED
        ] : [
        	array_length(_move_events),
        	array_length(_rotate_events),
        	array_length(_alpha_events),
        	array_length(_speed_events)
        ];

        _counts = [0, 0, 0, 0];
        _beat_per_second = (_events.bpm / 1.875);
        _seconds_per_beat = (1 / _beat_per_second);
        _last_event_time = 0;

        __x = 0;
        __y = 0;
        __a = 0;
        __r = 0;
        __cos = 1;
        __sin = 0;
        __value = [0, 0];

        // 用户事件 1 预计算速度事件的 floor。
        chart_actor_user(1);

        chart_force_event_init = false;
        if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then visible = false;

        print($"[{self.line_id}] BPM: {_events.bpm}");
    };

    // 原事件源码保留于 objects/oLine/Step_0.gml。
    static actor_step = function() {
        ///@desc 步进：同一阶段里推进游标并求值事件
        // 加载动画或暂停时不推进，除非强制初始化。
        if (variable_global_exists("loading_animation_active") && global.loading_animation_active
        	&& !chart_force_event_init) then exit;
        if (game.paused && !chart_force_event_init) {
        	// 保留已求值的事件，只把归一化位置映射到当前窗口。
        	x = chart_view_left + chart_view_width * __x;
        	y = chart_view_height * (1 - __y);
        	exit;
        };
        // 先推进游标，再求值。
        chart_actor_user(3);
        chart_actor_user(2);
    };

    // 原事件源码保留于 objects/oLine/Draw_0.gml。
    static actor_draw = function() {
        ///@desc 绘制：不临时分配缩放数组
        // 加载动画或判定线尚未解冻时不画。
        if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then exit;
        if (chart_actor_exists(oRender)
        	&& chart_actor_var_exists(oRender, "_chart_lines_thaw_pending")
        	&& oRender._chart_lines_thaw_pending) then exit;
        // 完全透明就不用算缩放。
        if(image_alpha <= 0) then exit;

        var draw_scale_x,
        	draw_scale_y;
        // 第二条默认线和自定义贴图用不同的缩放。
        if(self.image_id == line_2){
        		draw_scale_x = (0.71 * chart_view_height / 768);
        		draw_scale_y = (0.68 * chart_view_width / 1366);
        }else{
        	var _csv_scale = chart_line_csv_sprite_scale(chart_line_override(line_id), sprite_index);
        	draw_scale_x = _csv_scale[0];
        	draw_scale_y = _csv_scale[1];
        };

        BYD_COLOR_FUNC;
        else{
        	image_blend = chart_line_judge_blend();
        };

        if(self.line_id == 0 && keyboard_check_pressed(vk_f8)) then print([draw_scale_x, draw_scale_y]);
        draw_sprite_ext(sprite_index, 0, x, y, draw_scale_x, draw_scale_y, image_angle, image_blend, image_alpha);
    };

    // 原事件源码保留于 objects/oLine/Other_11.gml。
    static user_1 = function() {
        ///@desc 用户事件 1：预计算每个速度事件起点的累计 floor
        if (events_flat) {
        	var flat_n = _event_lengths[3];
        	speedValueList = array_create(max(1, flat_n), 0);
        	for (var flat_i = 0; flat_i < flat_n; flat_i++) {
        		speedValueList[flat_i] = _speed_pack[flat_i * OFF_EV_SPEED + 3];
        	};
        	exit;
        };
        var value = 0;
        speedValueList = [0];
        for(var i = 0 ; i < _event_lengths[3] ; i ++){
        	var speed_event = (_speed_events[i]),
        		duration = ((speed_event.endTime - speed_event.startTime) * _seconds_per_beat);
        	// 有官方 floorPosition 就用它。旧谱可能没有，这时退回累计值。
        	var event_floor = value;
        	if (struct_exists(speed_event, "floorPosition") && is_real(speed_event.floorPosition)) {
        		event_floor = speed_event.floorPosition;
        	};
        	if (i == 0) then speedValueList[0] = event_floor;
        	else speedValueList[i] = event_floor;
        	value = event_floor + duration * speed_event.value;
        };
    };

    // 原事件源码保留于 objects/oLine/Other_12.gml。
    static user_2 = function() {
        ///@desc 用户事件 2：求值四条已缓存的事件流，不每帧分配数组
        if (events_flat) {
        	official_line_eval_flat();
        	exit;
        };
        var now_time = (game.__time[1] * _beat_per_second),
        	next_x = __x,
        	next_y = __y,
        	next_alpha = __a,
        	next_rotation = __r;

        // 位移、透明度、旋转各自按当前事件插值。带缓动的线用 RPE 缓动号折进度
        if(_event_lengths[0] > 0){
        	var move_event = (_move_events[_counts[0]]);
        	var move_progress = (move_event.startTime == move_event.endTime ? 1 : clamp((now_time - move_event.startTime) / (move_event.endTime - move_event.startTime), 0, 1));
        	var move_x = move_progress;
        	var move_y = move_progress;
        	if (ease_live) {
        		var ease_x = move_event[$ "easeType"];
        		var ease_y = move_event[$ "easeType2"];
        		if ((is_real(ease_x) && ease_x > 1) || is_real(move_event[$ "easeLeft"])) then move_x = official_sim_progress(move_event, move_progress, 0);
        		if ((is_real(ease_y) && ease_y > 1) || is_real(move_event[$ "easeLeft2"])) then move_y = official_sim_progress(move_event, move_progress, 1);
        	};
        	next_x = (move_event.start == move_event[$ "end"] ? move_event[$ "end"] : lerp(move_event.start, move_event[$ "end"], move_x));
        	next_y = (move_event.start2 == move_event[$ "end2"] ? move_event[$ "end2"] : lerp(move_event.start2, move_event[$ "end2"], move_y));
        };

        if(_event_lengths[2] > 0){
        	var alpha_event = (_alpha_events[_counts[2]]);
        	var alpha_progress = (alpha_event.startTime == alpha_event.endTime ? 1 : clamp((now_time - alpha_event.startTime) / (alpha_event.endTime - alpha_event.startTime), 0, 1));
        	if (ease_live) {
        		var ease_a = alpha_event[$ "easeType"];
        		if ((is_real(ease_a) && ease_a > 1) || is_real(alpha_event[$ "easeLeft"])) then alpha_progress = official_sim_progress(alpha_event, alpha_progress, 0);
        	};
        	next_alpha = (alpha_event.start == alpha_event[$ "end"] ? alpha_event[$ "end"] : lerp(alpha_event.start, alpha_event[$ "end"], alpha_progress));
        };

        if(_event_lengths[1] > 0){
        	var rotate_event = (_rotate_events[_counts[1]]);
        	var rotate_progress = (rotate_event.startTime == rotate_event.endTime ? 1 : clamp((now_time - rotate_event.startTime) / (rotate_event.endTime - rotate_event.startTime), 0, 1));
        	if (ease_live) {
        		var ease_r = rotate_event[$ "easeType"];
        		if ((is_real(ease_r) && ease_r > 1) || is_real(rotate_event[$ "easeLeft"])) then rotate_progress = official_sim_progress(rotate_event, rotate_progress, 0);
        	};
        	next_rotation = (rotate_event.start == rotate_event[$ "end"] ? rotate_event[$ "end"] : lerp(rotate_event.start, rotate_event[$ "end"], rotate_progress));
        };

        if(_event_lengths[3] > 0){
        	// floorPosition 是该事件起点的 float32 基准。开始前用下一条向前延伸。
        	// 超过最后一条的结束时间后，沿用最后一个值。
        	var speed_event = (_speed_events[_counts[3]]);
        	__value[0] = ((game.__time[1] - speed_event.startTime * _seconds_per_beat) * speed_event.value + __value[1]);
        };

        // NaN 不写回，避免坏事件把线坐标打飞。
        if(!is_nan(next_x)) then __x = next_x;
        if(!is_nan(next_y)) then __y = next_y;
        if(!is_nan(next_alpha)) then __a = next_alpha;
        if(!is_nan(next_rotation)) then __r = next_rotation;

        // 原先的缩放式子化简后就是这两个乘积。
        x = (chart_view_left + chart_view_width * __x);
        y = (chart_view_height * (1 - __y));
        image_alpha = __a;
        image_angle = __r;
        __cos = dcos(__r);
        __sin = dsin(__r);
    };

    // 原事件源码保留于 objects/oLine/Other_13.gml。
    static user_3 = function() {
        ///@desc 用户事件 3：推进事件游标；回放或大跳转时二分查找
        if (events_flat) {
        	official_line_seek_flat();
        	exit;
        };
        var now_time = (game.__time[1] * _beat_per_second),
        	is_seek = (now_time < _last_event_time || abs(now_time - _last_event_time) > _beat_per_second * 2);

        for(var i = 0 ; i < 4 ; i ++){
        	var event_length = (_event_lengths[i]);
        	// 这条流没有事件就跳过。
        	if(event_length <= 0) then continue;

        	var events = (_event_groups[i]),
        		count = (clamp(_counts[i], 0, event_length - 1));

        	if(i == 3){
        		// sim-phi：取第一条还没结束的速度事件。空隙用下一条，不要把上一段速度延续过去。
        		// 大跳转时二分找第一条尚未结束的速度事件。
        		if(is_seek){
        			var low = 0,
        				high = event_length - 1,
        				found = event_length - 1;
        			while(low <= high){
        				var middle = ((low + high) >> 1);
        				if(events[middle].endTime < now_time){
        					low = middle + 1;
        				}else{
        					found = middle;
        					high = middle - 1;
        				};
        			};
        			count = found;
        		}else{
        			// 正常播放只向前挪到还没结束的事件。
        			while(count < event_length - 1 && events[count].endTime < now_time) count ++;
        		};
        	// 其他事件在跳转时二分到最后一个已经开始的事件。
        	}else if(is_seek){
        		var low = 0,
        			high = event_length - 1,
        			found = 0;
        		while(low <= high){
        			var middle = ((low + high) >> 1);
        			if(events[middle].startTime <= now_time){
        				found = middle;
        				low = middle + 1;
        			}else{
        				high = middle - 1;
        			};
        		};
        		count = found;
        	}else{
        		// 正常播放时前后微调，停在包含当前时间的事件上。
        		while(count < event_length - 1 && events[count].endTime < now_time) count ++;
        		while(count > 0 && events[count].startTime > now_time) count --;
        	};

        	_counts[i] = count;
        	// 速度流的 floor 基准跟着游标走。
        	if(i == 3) then __value[1] = (speedValueList[count]);
        };

        _last_event_time = now_time;
    };

    // 原事件源码保留于 objects/oLine/KeyPress_118.gml。
    static actor_begin = function() {
        if (keyboard_check_pressed(vk_f7)) {
            ///@desc 按键按下 F7：打印这条判定线的编号和房间高度
            print($"Line {line_id} x {room_height}");
        }
    };

    static actor_cleanup = function() {
        // 判定线不拥有共享精灵；解除事件流与运行缓存的引用即可。
        _events = undefined;
        _move_events = undefined;
        _rotate_events = undefined;
        _alpha_events = undefined;
        _speed_events = undefined;
        _event_groups = undefined;
        _event_lengths = undefined;
        _move_pack = undefined;
        _rotate_pack = undefined;
        _alpha_pack = undefined;
        _speed_pack = undefined;
        _counts = undefined;
        speedValueList = undefined;
        __value = undefined;
    };

    actor_create();
}

function OfficialNote(_object, _x, _y, _depth, _fields) : ChartActor(_object, _x, _y, _depth, _fields) constructor {
    // 原事件源码保留于 objects/oNote/Create_0.gml。
    static actor_create = function() {
        ///@desc 缓存官谱音符的节拍换算和判定线引用
        depth = DEPTH.NOTE;
        inition = false;
        if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then visible = false;

        _is_hold = (self.type == 3);
        _step_user_count = (_is_hold ? 2 : 1);
        _judge_user_count = (_is_hold ? 6 : 5);
        _beat_per_second = (self.bpm / 1.875);
        _seconds_per_beat = (1 / _beat_per_second);
        if (!is_real(self.line_id)) then self.line_id = 0;
        // 判定线无效就销毁，避免后续热路径空引用。
        if (!is_array(game.line_list) || self.line_id < 0 || self.line_id >= array_length(game.line_list)) {
                show_debug_message($"[oNote] invalid line_id={self.line_id}, lines={is_array(game.line_list) ? array_length(game.line_list) : -1}");
                chart_actor_destroy();
                exit;
        };
        _line_ref = (game.line_list[self.line_id]);
        _last_global_scales = -1;
        _last_note_size = -1;
        _last_view_width = -1;
        _last_view_height = -1;
        _last_view_left = -1;
        _now_seconds = 0;
        _now_beat = 0;

        chart_actor_user(0);

        canDraw = false;
        hl = self._hl;

        // Hold、Drag/Flick、Tap 的迟到窗口毫秒不同。
        var late_ms = _is_hold ? 161 : ((self.type == 2 || self.type == 4) ? 160 : 201);
        lateHitTime = (late_ms * 0.001 * _beat_per_second);
        chart_kb_register_note();
    };

    // 原事件源码保留于 objects/oNote/Step_0.gml。
    static actor_step = function() {
        ///@desc 推进官谱音符时间，并分发缩放、判定和位移
        if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then exit;
        _now_seconds = game.__time[1];
        _now_beat = (_now_seconds * _beat_per_second);
        var geometry_changed = _last_view_width != chart_view_width
        	|| _last_view_height != chart_view_height || _last_view_left != chart_view_left;
        _last_view_width = chart_view_width;
        _last_view_height = chart_view_height;
        _last_view_left = chart_view_left;

        // 缩放变了才刷新贴图尺寸。
        if(_last_global_scales != global_scales || _last_note_size != game.settings.noteSize){
        	geometry_changed = true;
        	chart_actor_user(7);
        	_last_global_scales = global_scales;
        	_last_note_size = game.settings.noteSize;
        };
        // 暂停期间不执行判定、消失和 Hold 事件，只在窗口变动时刷新几何。
        if (game.paused) {
        	if (geometry_changed && !isBad) then chart_actor_user(_step_user_count);
        	exit;
        };

        // Bad 闪完一秒后停用。
        if(isBad){
        	if(_now_seconds - judgeRealTime >= 1) then chart_actor_deactivate(self);
        	exit;
        };

        if(!game.paused) then chart_actor_user(_judge_user_count);
        if(!isBad) then chart_actor_user(_step_user_count);
    };

    // 原事件源码保留于 objects/oNote/Draw_0.gml。
    static actor_draw = function() {
        ///@desc 直接绘制可见的官谱音符，跳过额外事件分发
        if(!canDraw) then exit;

        // Miss 透明度只在绘制时使用，不写进 image_alpha，避免重开后残留。
        var hold_alpha = (_is_hold && isMiss) ? 0.45 : 1;

        // 皮肤开启时走皮肤精灵，否则用默认音符图。
        if (skin_active()) {
        	var _skin_kind = (type == 2 ? "drag" : (type == 4 ? "flick" : "tap"));
        	var _skin_spr = skin_note_sprite(_skin_kind, isBad ? 0 : hl);
        	var _skin_hold = (!_is_hold) ? undefined : skin_hold_parts(hl);
        	var _compact = is_struct(_skin_hold) && bool(_skin_hold.compact);
        	var _tail_trim = (_compact && is_struct(_skin_hold)) ? image_yscale * sprite_get_height(_skin_hold.tail) * 0.5 : 0;
        	var sk = sprite_exists(_skin_spr) ? skin_note_scale_k(_skin_spr) : 1;
        	var hk = (is_struct(_skin_hold) && sprite_exists(_skin_hold.head)) ? skin_note_scale_k(_skin_hold.head) : 1;
        	if(!_is_hold){
        		// Bad 判定画红帧并提前结束。
        		if(isBad){
        			var alpha = ((1 - (_now_seconds - judgeRealTime)) * 0.5);
        			if (sprite_exists(_skin_spr)) then draw_sprite_ext(_skin_spr, 0, _bad_x, _bad_y, image_xscale * sk, image_yscale * sk, _bad_angle, c_red, alpha);
        			else draw_sprite_ext(sprite_index, 2, _bad_x, _bad_y, image_xscale, image_yscale, _bad_angle, c_red, alpha);
        			exit;
        		};
        		image_alpha = chart_note_pass_fade(_now_seconds, realHitTime, chart_note_miss_window_sec(self.type, false));
        		if (sprite_exists(_skin_spr)) then draw_sprite_ext(_skin_spr, 0, x, y, image_xscale * sk, image_yscale * sk, image_angle, image_blend, image_alpha);
        		else draw_sprite_ext(sprite_index, hl, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
        	}else if(isHold){
        		if (is_struct(_skin_hold)) {
        			draw_hold_fit(_hx0, _hy0, image_xscale * hk, image_yscale * hk, yscale,
        				image_angle, 0, image_blend, hold_alpha, false, false, _tail_trim * hk, 1,
        				_skin_hold.head, _skin_hold.body, _skin_hold.tail);
        		} else {
        			draw_hold_fit(_hx0, _hy0, image_xscale, image_yscale, yscale,
        				image_angle, hl, image_blend, hold_alpha, false);
        		};
        	}else{
        		if (is_struct(_skin_hold)) {
        			draw_hold_fit(_hx0, _hy0, image_xscale * hk, image_yscale * hk, yscale,
        				image_angle, 0, image_blend, hold_alpha, true, !_compact, _tail_trim * hk, 1,
        				_skin_hold.head, _skin_hold.body, _skin_hold.tail);
        		} else {
        			draw_hold_fit(_hx0, _hy0, image_xscale, image_yscale, yscale,
        				image_angle, hl, image_blend, hold_alpha, true);
        		};
        	};
        	exit;
        };

        if(!_is_hold){
        	// 默认皮肤的 Bad 同样画红帧后结束。
        	if(isBad){
        		var alpha = ((1 - (_now_seconds - judgeRealTime)) * 0.5);
        		draw_sprite_ext(sprite_index, 2, _bad_x, _bad_y, image_xscale, image_yscale, _bad_angle, c_red, alpha);
        		exit;
        	};
        	image_alpha = chart_note_pass_fade(_now_seconds, realHitTime, chart_note_miss_window_sec(self.type, false));
        	draw_sprite_ext(sprite_index, hl, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
        }else if(isHold){
        	draw_hold_fit(_hx0, _hy0, image_xscale, image_yscale, yscale,
        		image_angle, hl, image_blend, hold_alpha, false);
        }else{
        	draw_hold_fit(_hx0, _hy0, image_xscale, image_yscale, yscale,
        		image_angle, hl, image_blend, hold_alpha, true);
        };
    };

    // 原事件源码保留于 objects/oNote/Other_10.gml。
    static user_0 = function() {
        ///@desc 初始化官谱音符贴图、判定时间和连击计数
        if(inition) then exit;

        realHitTime = (self.time * _seconds_per_beat);
        hold_time_length = (self.holdTime * _seconds_per_beat);
        _hold_body_height = (sprite_get_height(note_hold_body));
        var _skin_hl = (chart_actor_var_exists(id, "_hl") && is_real(_hl)) ? _hl : 0;
        var _skin_hold = skin_hold_parts(_skin_hl);
        if (is_struct(_skin_hold) && sprite_exists(_skin_hold.body)) {
        	_hold_body_height = max(1, sprite_get_height(_skin_hold.body));
        };
        max_visible_position = official_max_visible_pos(self.yOffset);
        // 官谱 Hold 在头碰到判定线后隐藏，身体不算地板跨度。
        maximum_visual_length = max_visible_position;

        // 按音符类型绑定贴图和打击音。
        switch(self.type){
        	case 1:
        		sprite_index = note_tap;
        		sound = skin_note_sound("tap", snd_note_tap);
        	break;
        	case 2:
        		sprite_index = note_drag;
        		sound = skin_note_sound("drag", snd_note_drag);
        	break;
        	case 3:
        		sound = skin_note_sound("tap", snd_note_tap);
        		depth ++;
        		sprite_index = note_hold_head;
        		_hx0 = 0;
        		_hy0 = 0;
        		_hx1 = 0;
        		_hy1 = 0;
        		_hx2 = 0;
        		_hy2 = 0;
        		var body_speed = chart_actor_var_exists(id, "bodySpeed") ? real(bodySpeed) : 1;
        		if (!is_finite(body_speed) || body_speed < 0) then body_speed = 0;
        		yscale = (hold_time_length * room_height * 0.6 / _hold_body_height * body_speed);
        		isClickRealTime = realHitTime;
        		isHold = false;
        		_bak_time = realHitTime;
        		notJudge = true;
        		isMiss = false;
        	break;
        	case 4:
        		sprite_index = note_flick;
        		sound = skin_note_sound("flick", snd_note_flick);
        	break;
        };

        isBad = false;
        _bad_x = 0;
        _bad_y = 0;
        _bad_angle = 0;
        _note_x = 0;
        _note_y = 0;
        isJudge = false;
        var initial_scale = (variable_global_exists("global_scales") ? global_scales : 1.0);
        image_xscale = (initial_scale / 6) * game.settings.noteSize;
        image_yscale = image_xscale;
        _last_global_scales = initial_scale;
        _last_note_size = game.settings.noteSize;

        if(self.type != 3 && BYD_COLOR_MODE) then hl = 2;
        hit_status = TYPE.NONE;
        hitTime2 = chart_auto_hit_offset_ms(self.type);

        judgeTime = (self.time + hitTime2 * 0.001 * _beat_per_second);
        judgeRealTime = (judgeTime * _seconds_per_beat);
        // GX 此时音频长度常还是 -1/0。未知长度也计入，避免官谱分数 0/0 变成 NaN。
        var _media_len = 0;
        if (chart_actor_exists(oMedia) && is_real(oMedia.length) && is_finite(oMedia.length) && oMedia.length > 0) then _media_len = oMedia.length;
        var combo_ready = chart_actor_var_exists(id, "combo_added") && combo_added;
        if (!combo_ready && (_media_len <= 0 || (realHitTime * 1000000) <= _media_len)) then maxcombo ++;

        inition = true;
    };

    // 原事件源码保留于 objects/oNote/Other_11.gml。
    static user_1 = function() {
        ///@desc 更新非 Hold 官谱音符的位置和可见性
        if(_is_hold || !inition) then exit;

        var line_floor = (_line_ref.__value[0]),
        	floor_delta = (self.isAbove ? line_floor - self.yOffset : self.yOffset - line_floor);

        var line_x = (_line_ref.x),
        	line_y = (_line_ref.y),
        	local_x = (self.xOffset * chart_view_width * 0.05625),
        	local_y = (floor_delta * self.speed * chart_view_height * 0.6),
        	rotation = (_line_ref.image_angle),
        	rotation_cos = (_line_ref.__cos),
        	rotation_sin = (_line_ref.__sin);

        // 未旋转坐标留给判定和特效定位。
        _note_x = (line_x + local_x);
        _note_y = (line_y + local_y);

        x = (line_x + local_x * rotation_cos + local_y * rotation_sin);
        y = (line_y - local_x * rotation_sin + local_y * rotation_cos);
        image_angle = rotation;

        // 判定线地板还没越过 maxVisiblePos 就继续画，过线后才藏。
        var is_out_line = true;
        if (_now_seconds < realHitTime) then is_out_line = (line_floor <= max_visible_position);
        canDraw = is_out_line;
    };

    // 原事件源码保留于 objects/oNote/Other_12.gml。
    static user_2 = function() {
        ///@desc 更新官谱 Hold：头速为 1，身体按 bodySpeed 乘时长伸缩
        if(!_is_hold || !inition) then exit;

        var line_floor = _line_ref.__value[0];
        var time_before = (_now_seconds < realHitTime);
        var body_speed = chart_actor_var_exists(id, "bodySpeed") ? real(bodySpeed) : 1;
        if (!is_finite(body_speed)) then body_speed = 1;
        var hold_sec = hold_time_length;
        // 速度为 0 或空 Hold 不画。
        if (abs(body_speed) <= 0.0000001 || hold_sec <= 0) {
        	canDraw = false;
        	exit;
        };
        // 和 Tap 一样，判定线地板越过 maxVisiblePos 才隐藏。
        if (time_before && line_floor > max_visible_position) {
        	canDraw = false;
        	exit;
        };

        var position_floor_delta = (yOffset - line_floor);
        var line_x = _line_ref.x;
        var line_y = _line_ref.y;
        var local_x = xOffset * chart_view_width * 0.05625;
        var scale_y = chart_view_height * 0.6;
        var rotation = _line_ref.image_angle;
        var rotation_cos = _line_ref.__cos;
        var rotation_sin = _line_ref.__sin;
        var dir = (isAbove ? -1 : 1);
        var axis_x = rotation_sin * dir;
        var axis_y = rotation_cos * dir;
        var base_x = line_x + local_x * rotation_cos;
        var base_y = line_y - local_x * rotation_sin;

        var full_px = body_speed * hold_sec * scale_y;
        if (full_px < 0) then full_px = 0;
        var remain_px = full_px;
        var show_head = time_before;
        // 击中后按已过时间缩短身体。
        if (!time_before) {
        	var gone = clamp((_now_seconds - realHitTime) / hold_sec, 0, 1);
        	remain_px = full_px * (1 - gone);
        };
        var _skin_hold = skin_active() ? skin_hold_parts(hl) : undefined;
        var _head_spr = note_hold_head;
        var _compact = false;
        if (is_struct(_skin_hold)) {
        	if (sprite_exists(_skin_hold.head)) then _head_spr = _skin_hold.head;
        	if (sprite_exists(_skin_hold.body)) then _hold_body_height = max(1, sprite_get_height(_skin_hold.body));
        	_compact = bool(_skin_hold.compact);
        };
        var head_offset = 0;
        if (show_head && !_compact) {
        	var head_scale = is_struct(_skin_hold) ? skin_note_scale_k(_head_spr) : 1;
        	head_offset = max(0, sprite_get_yoffset(_head_spr)) * image_yscale * head_scale;
        	if (head_offset > remain_px) then head_offset = remain_px;
        };
        var hold_length = max(0, remain_px - head_offset);
        yscale = hold_length / max(1, _hold_body_height);

        if (show_head) {
        	var head_distance = position_floor_delta * scale_y;
        	var head_x = base_x + axis_x * head_distance;
        	var head_y = base_y + axis_y * head_distance;
        	_hx0 = head_x;
        	_hy0 = head_y;
        	_hx1 = head_x + axis_x * head_offset;
        	_hy1 = head_y + axis_y * head_offset;
        	_hx2 = head_x + axis_x * (head_offset + hold_length);
        	_hy2 = head_y + axis_y * (head_offset + hold_length);
        } else {
        	_hx0 = base_x;
        	_hy0 = base_y;
        	_hx1 = base_x + axis_x * hold_length;
        	_hy1 = base_y + axis_y * hold_length;
        	_hx2 = _hx1;
        	_hy2 = _hy1;
        };

        image_angle = (-180 * (!isAbove) + rotation);
        canDraw = (show_head || hold_length > 0);
    };

    // 原事件源码保留于 objects/oNote/Other_15.gml。
    static user_5 = function() {
        ///@desc 用缓存节拍判定非 Hold 官谱音符
        var now_time = _now_beat,
        	now_hit_time = judgeTime;

        // 非自动播放只处理超时 Miss。
        if (!chart_autoplay_active()) then exit;

        // 关闭准度判定时，过窗口直接记 Miss。
        if(now_time > self.time + lateHitTime && !isBad && !game.settings.enableAccJudgment){
        	judgeCalc(self.time, now_time, self.bpm, 0, 0, self.type, false);
        	chart_actor_deactivate(self);
        	exit;
        };

        // Drag 和 Flick 到点即判，不等 Tap 的击中时刻。
        if ((self.type == 2 || self.type == 4) && !isJudge && now_time >= self.time
        	&& now_hit_time >= self.time && now_hit_time <= self.time + lateHitTime) {
        	chart_actor_user(1);
        	var line_x = (_line_ref.x),
        		local_x = (_note_x - line_x),
        		hit_x = (line_x + local_x * _line_ref.__cos),
        		hit_y = (_line_ref.y - local_x * _line_ref.__sin);
        	hit_status = (judgeCalc(self.time, now_hit_time, self.bpm, hit_x, hit_y, self.type));
        	skin_play_note_hitsound();
        	isJudge = true;
        };

        if(now_time >= now_hit_time){
        	if(!isJudge && hit_status == TYPE.NONE && self.type == 1){
        		chart_actor_user(1);
        		var line_x = (_line_ref.x),
        			local_x = (_note_x - line_x),
        			hit_x = (line_x + local_x * _line_ref.__cos),
        			hit_y = (_line_ref.y - local_x * _line_ref.__sin);
        		hit_status = (judgeCalc(self.time, now_hit_time, self.bpm, hit_x, hit_y, self.type));
        		if(hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT) then skin_play_note_hitsound();
        		isJudge = true;
        	}else if(hit_status == TYPE.BAD && self.type == 1){
        		if(!isBad){
        			_bad_x = _note_x;
        			_bad_y = _note_y;
        			_bad_angle = image_angle;
        		};
        		isBad = true;
        		if(image_alpha <= 0) then chart_actor_deactivate(self);
        	}else if(hit_status != TYPE.NONE && isJudge){
        		chart_actor_deactivate(self);
        	};
        };
    };

    // 原事件源码保留于 objects/oNote/Other_16.gml。
    static user_6 = function() {
        ///@desc 用缓存节拍判定官谱 Hold，并按节拍刷新尾迹
        var now_time = _now_beat,
        	now_hit_time = judgeTime;

        // 手动判定统一在渲染器 Step End 处理，先接收本帧输入再决定超时。
        if (!chart_autoplay_active()) then exit;

        // 自动播放在击中时刻判定 Hold 头。
        if(now_time >= now_hit_time && !isMiss && notJudge && hit_status == TYPE.NONE){
        	chart_actor_user(2);
        	hit_status = (judgeCalc(self.time, now_hit_time, self.bpm, _hx0, _hy0, self.type, true, false));
        	if(hit_status == TYPE.MISS && !isMiss){
        		isMiss = true;
        		judgeCalc(self.time, now_hit_time, self.bpm, _hx0, _hy0, self.type, true, true);
        	}else{
        		_bak_time = _now_seconds;
        		skin_play_note_hitsound();
        	};
        	notJudge = false;
        };

        if(now_time > self.time + lateHitTime && !isMiss && notJudge && !game.settings.enableAccJudgment){
        	hit_status = (judgeCalc(self.time, now_time, self.bpm, _hx0, _hy0, self.type, false, false));
        	notJudge = false;
        };

        if(now_time >= self.time){
        	// 到开始时间后钉在判定线上，并按半拍刷新尾迹。
        	if(!isHold){
        		isHold = true;
        		chart_actor_user(2);
        	}else if(!notJudge && !isMiss && (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT)){
        		if(_now_seconds - _bak_time >= (60 / self.bpm) / 2){
        			_eff_c(_hx0, _hy0, hit_status == TYPE.PREFECT ? #ffeca0 : make_colour_rgb(162, 238, 255));
        			_bak_time = _now_seconds;
        		};
        	};

        	if(now_time >= self.time + self.holdTime){
        		hit_status = (judgeCalc(self.time, now_hit_time, self.bpm, _hx0, _hy0, self.type, false, !isMiss));
        		chart_actor_deactivate(self);
        	};
        };
    };

    // 原事件源码保留于 objects/oNote/Other_17.gml。
    static user_7 = function() {
        ///@desc 窗口缩放变化后刷新官谱音符缩放
        image_xscale = (global_scales / 6) * game.settings.noteSize;
        image_yscale = image_xscale;
    };

    // 原事件源码保留于 objects/oNote/Other_18.gml。
    static user_8 = function() {
        ///@desc 窗口尺寸变化后重算 Hold 身体长度
        if(!_is_hold) then exit;

        var scale_y = (room_height * 0.6);
        if(isHold) then yscale = ((isClickRealTime + hold_time_length - game.__time[1]) * scale_y / _hold_body_height * self[$ "speed"]);
        else yscale = (hold_time_length * scale_y / _hold_body_height * self[$ "speed"]);
    };

    static actor_cleanup = function() {
        // 判定索引由播放容器先清理；精灵和音效由皮肤/谱面所有者释放。
        _line_ref = undefined;
        kb_record = undefined;
    };

    actor_create();
}
