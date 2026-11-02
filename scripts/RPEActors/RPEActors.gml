// RPE 判定线和音符：由 ChartActors 统一调度的 Constructor。
// 行为共享于 static；空间索引以稳定 uid 为键，不将 struct 字符串化。
// 迁移前完整源码保存在 docs/constructor-migration/legacy/rpe/。

function RPEJudgeLine(_object, _x, _y, _depth, _fields)
	: ChartActor(_object, _x, _y, _depth, _fields) constructor {
	static rpe_eval_events = function(layer_index, event_name, default_value) {
	         // 层或通道不存在就用默认值。
	         if (!is_struct(events[layer_index])) then return default_value;
	         if (!struct_exists(events[layer_index], event_name)) then return default_value;
	         var arr = events[layer_index][$ event_name];
	        if (!is_array(arr) || array_length(arr) <= 0) then return default_value;

	        if (!is_struct(events_count[layer_index])) then events_count[layer_index] = {};
	        if (!is_struct(events_hold[layer_index])) then events_hold[layer_index] = {};
	        if (!is_struct(events_recall[layer_index])) then events_recall[layer_index] = {};
	        if (!struct_exists(events_count[layer_index], event_name)) then events_count[layer_index][$ event_name] = 0;
	        if (!struct_exists(events_hold[layer_index], event_name)) then events_hold[layer_index][$ event_name] = default_value;
	        if (!struct_exists(events_recall[layer_index], event_name)) then events_recall[layer_index][$ event_name] = default_value;

	        var n = array_length(arr);
	        var idx = clamp(events_count[layer_index][$ event_name], 0, n);

	        if (idx >= n) {
	                if (line_time >= arr[n - 1].endTime) then return arr[n - 1][$ "end"];
	                idx = n - 1;
	        };

	        while ((idx > 0) && (line_time < arr[idx].startTime)) {
	                idx--;
	        };

	        // 吃掉已经结束的事件，记住终点。
	        while ((idx < n) && (arr[idx].endTime <= line_time)) {
	                events_hold[layer_index][$ event_name] = arr[idx][$ "end"];
	                idx++;
	        };
	        events_count[layer_index][$ event_name] = idx;

	        if (idx >= n) {
	                return events_hold[layer_index][$ event_name];
	        };

	        var ev = arr[idx];
	        var st = ev.startTime;
	        var et = ev.endTime;

	        // 还在这条开始之前：用上一条终点，没有上一条就用起点。
	        if (line_time < st) {
	                if (idx > 0) then return arr[idx - 1][$ "end"];
	                return ev.start;
	        };

	        var v0 = ev.start;
	        var v1 = ev[$ "end"];
	        if (st == et || v0 == v1) then return v1;

	        var ease = real(ev.easingType ?? 1);
	        if (!is_real(ease) || ease <= 1 || ease >= 32) then ease = 1;
	        var e0 = clamp(real(ev.easingLeft ?? 0), 0, 1);
	        var e1 = clamp(real(ev.easingRight ?? 1), 0, 1);
	        if (e0 == e1) {
	                e0 = 0;
	                e1 = 1;
	        };
	        var tval;

	        // 贝塞尔用牛顿迭代把 x 解回参数，再取 y。
	        if (bool(ev[$ "bezier"] ?? 0) && is_array(ev.bezierPoints) && array_length(ev.bezierPoints) >= 4) {
	                var p = clamp((line_time - st) / (et - st), 0, 1);
	                var x1 = ev.bezierPoints[0];
	                var y1 = ev.bezierPoints[1];
	                var x2 = ev.bezierPoints[2];
	                var y2 = ev.bezierPoints[3];
	                var tt = p;
	                for (var k = 0; k < 5; k++) {
	                        var u = 1 - tt;
	                        var xx = 3 * u * u * tt * x1 + 3 * u * tt * tt * x2 + tt * tt * tt;
	                        var dx = 3 * u * u * x1 + 6 * u * tt * (x2 - x1) + 3 * tt * tt * (1 - x2);
	                        // 导数太小就停止，避免除爆。
	                        if (abs(dx) < 0.000001) then break;
	                        tt -= (xx - p) / dx;
	                        tt = clamp(tt, 0, 1);
	                };
	                var uu = 1 - tt;
	                var yy = 3 * uu * uu * tt * y1 + 3 * uu * tt * tt * y2 + tt * tt * tt;
	                tval = lerp(v0, v1, yy);
	        } else {
	                if (ease <= 1) {
	                        var p = clamp((line_time - st) / max(0.0000001, et - st), 0, 1);
	                        tval = lerp(v0, v1, p);
	                } else {
	                        tval = tween_execute(line_time, st, et, v0, v1, ease, e0, e1);
	                };
	        };

	        // 非有限结果退回上次有效值。
	        if (!is_finite(tval)) {
	                tval = events_recall[layer_index][$ event_name];
	        } else {
	                events_recall[layer_index][$ event_name] = tval;
	        };
	        return tval;
	};

	static rpe_speed_floor_at = function(t) {
	        // 没有速度事件。
	        if (!is_array(rpe_speed_events) || array_length(rpe_speed_events) <= 0) then return 0;
	        var first_speed = rpe_speed_events[0];
	        // 旧表带 floorPosition，走遗留查询。
	        if (is_struct(first_speed) && struct_exists(first_speed, "floorPosition")) {
	                return rpe_legacy_floor_at(rpe_speed_events, t);
	        };
	        var floor_sum = 0;
	        var layer_n = array_length(rpe_speed_events);
	        for (var layer_i = 0; layer_i < layer_n; layer_i++) {
	                floor_sum += rpe_layer_floor_at(rpe_speed_events[layer_i], t);
	        };
	        return floor_sum;
	};

	static rpe_speed_floor = function() {
	        var t = (chart_actor_var_exists(id, "line_sec") ? line_sec : 0);
	        return rpe_speed_floor_at(t);
	};

	static rpe_event_progress = function(ev, st, et) {
	        // 零时长直接到终点。
	        if (st == et) then return 1;
	        var ease = real(ev.easingType ?? 1);
	        if (!is_real(ease) || ease <= 1 || ease >= 32) then ease = 1;
	        var e0 = clamp(real(ev.easingLeft ?? 0), 0, 1);
	        var e1 = clamp(real(ev.easingRight ?? 1), 0, 1);
	        if (e0 == e1) {
	                e0 = 0;
	                e1 = 1;
	        };

	        if (bool(ev[$ "bezier"] ?? 0) && is_array(ev.bezierPoints) && array_length(ev.bezierPoints) >= 4) {
	                var p = clamp((line_time - st) / (et - st), 0, 1);
	                var x1 = ev.bezierPoints[0];
	                var y1 = ev.bezierPoints[1];
	                var x2 = ev.bezierPoints[2];
	                var y2 = ev.bezierPoints[3];
	                var tt = p;
	                for (var k = 0; k < 5; k++) {
	                        var u = 1 - tt;
	                        var xx = 3 * u * u * tt * x1 + 3 * u * tt * tt * x2 + tt * tt * tt;
	                        var dx = 3 * u * u * x1 + 6 * u * tt * (x2 - x1) + 3 * tt * tt * (1 - x2);
	                        // 导数太小就停止。
	                        if (abs(dx) < 0.000001) then break;
	                        tt -= (xx - p) / dx;
	                        tt = clamp(tt, 0, 1);
	                };
	                var uu = 1 - tt;
	                return (3 * uu * uu * tt * y1 + 3 * uu * tt * tt * y2 + tt * tt * tt);
	        };

	        if (ease <= 1) {
	                return clamp((line_time - st) / max(0.0000001, et - st), 0, 1);
	        };
	        // 不要夹到 0 到 1：OutElastic、Back 和缓动窗口采样可以超出。
	        return tween_execute(line_time, st, et, 0, 1, ease, e0, e1);
	};

	static rpe_eval_ext_events = function(event_name, default_value) {
	         // 没有扩展事件或这条通道就用默认值。
	         if (!is_struct(extEvents)) then return default_value;
	         if (!struct_exists(extEvents, event_name)) then return default_value;
	         var arr = extEvents[$ event_name];
	        if (!is_array(arr) || array_length(arr) <= 0) then return default_value;

	        if (!struct_exists(ext_count, event_name)) then ext_count[$ event_name] = 0;
	        if (!struct_exists(ext_hold, event_name)) then ext_hold[$ event_name] = default_value;
	        if (!struct_exists(ext_recall, event_name)) then ext_recall[$ event_name] = default_value;

	        var n = array_length(arr);
	        var idx = clamp(ext_count[$ event_name], 0, n);

	        if (idx >= n) {
	                if (line_time >= arr[n - 1].endTime) then return arr[n - 1][$ "end"];
	                idx = n - 1;
	        };

	        while ((idx > 0) && (line_time < arr[idx].startTime)) {
	                idx--;
	        };

	        while ((idx < n) && (arr[idx].endTime <= line_time)) {
	                ext_hold[$ event_name] = arr[idx][$ "end"];
	                idx++;
	        };
	        ext_count[$ event_name] = idx;

	        if (idx >= n) then return ext_hold[$ event_name];

	        var ev = arr[idx];
	        var st = ev.startTime;
	        var et = ev.endTime;
	        if (line_time < st) {
	                if (idx > 0) then return arr[idx - 1][$ "end"];
	                return default_value;
	        };

	        var v0 = real(ev.start);
	        var v1 = real(ev[$ "end"]);
	        if (st == et || v0 == v1) then return v1;

	        var tval = lerp(v0, v1, rpe_event_progress(ev, st, et));
	        // 非有限结果退回上次有效值。
	        if (!is_finite(tval)) {
	                tval = ext_recall[$ event_name];
	        } else {
	                ext_recall[$ event_name] = tval;
	        };
	        return tval;
	};

	static rpe_eval_color_events = function(default_value) {
	         // 没有颜色通道就用默认色。
	         if (!is_struct(extEvents)) then return default_value;
	         if (!struct_exists(extEvents, "colorEvents")) then return default_value;
	         var arr = extEvents[$ "colorEvents"];
	        if (!is_array(arr) || array_length(arr) <= 0) then return default_value;

	        var event_name = "colorEvents";
	        if (!struct_exists(ext_count, event_name)) then ext_count[$ event_name] = 0;
	        if (!struct_exists(ext_hold, event_name)) then ext_hold[$ event_name] = default_value;
	        if (!struct_exists(ext_recall, event_name)) then ext_recall[$ event_name] = default_value;

	        var n = array_length(arr);
	        var idx = clamp(ext_count[$ event_name], 0, n);
	        if (idx >= n) {
	                if (line_time >= arr[n - 1].endTime) then return arr[n - 1][$ "end"];
	                idx = n - 1;
	        };

	        while ((idx > 0) && (line_time < arr[idx].startTime)) {
	                idx--;
	        };
	        while ((idx < n) && (arr[idx].endTime <= line_time)) {
	                ext_hold[$ event_name] = arr[idx][$ "end"];
	                idx++;
	        };
	        ext_count[$ event_name] = idx;
	        if (idx >= n) then return ext_hold[$ event_name];

	        var ev = arr[idx];
	        var st = ev.startTime;
	        var et = ev.endTime;
	        if (line_time < st) {
	                if (idx > 0) then return arr[idx - 1][$ "end"];
	                return default_value;
	        };

	        var v0 = ev.start;
	        var v1 = ev[$ "end"];
	        if (st == et || v0 == v1) then return v1;

	        var p = rpe_event_progress(ev, st, et);
	        var tval = merge_color(v0, v1, p);
	        ext_recall[$ event_name] = tval;
	        return tval;
	};

	static rpe_select_text_font = function(text_event) {
				// 事件不是结构就返回。
				if (!is_struct(text_event)) then return;
				var font_name = string(text_event[$ "font"] ?? "cmdysj");
				// 空名或默认 cmdysj 不换字体。
				if (!string_length(font_name) || string_lower(font_name) == "cmdysj") then return;
				if (struct_exists(game_1, "Fonts") && is_struct(game_1.Fonts)
					&& struct_exists(game_1.Fonts, font_name)) {
					var selected_font = game_1.Fonts[$ font_name];
					// 字体已经加载才换上。
					if (selected_font != -1 && font_exists(selected_font)) then line_text_font = selected_font;
				};
			};

	static rpe_eval_text_events = function(default_value) {
			line_text_font = (!is_undefined(game.font) && font_exists(game.font)) ? game.font : -1;
			// 没有文本通道就用默认文字。
			if (!is_struct(extEvents)) then return default_value;
			if (!struct_exists(extEvents, "textEvents")) then return default_value;
			var arr = extEvents[$ "textEvents"];
			if (!is_array(arr) || array_length(arr) <= 0) then return default_value;

			///@desc 按文本事件里的字体名切换绘制字体
			///@param {Struct} text_event 文本事件
			///@returns {Undefined} 无
			

	        var event_name = "textEvents";
	        if (!struct_exists(ext_count, event_name)) then ext_count[$ event_name] = 0;
	        if (!struct_exists(ext_hold, event_name)) then ext_hold[$ event_name] = default_value;
	        if (!struct_exists(ext_recall, event_name)) then ext_recall[$ event_name] = default_value;

			var n = array_length(arr);
			var idx = clamp(ext_count[$ event_name], 0, n);
			if (idx >= n) {
					if (line_time >= arr[n - 1].endTime) {
							rpe_select_text_font(arr[n - 1]);
							return string(arr[n - 1][$ "end"]);
					};
					idx = n - 1;
			};

	        while ((idx > 0) && (line_time < arr[idx].startTime)) {
	                idx--;
	        };
	        while ((idx < n) && (arr[idx].endTime <= line_time)) {
	                ext_hold[$ event_name] = string(arr[idx][$ "end"]);
	                idx++;
	        };
			ext_count[$ event_name] = idx;
			if (idx >= n) {
					rpe_select_text_font(arr[n - 1]);
					return ext_hold[$ event_name];
			};

	        var ev = arr[idx];
	        var st = ev.startTime;
	        var et = ev.endTime;
			var v0 = string(ev.start);
			var v1 = string(ev[$ "end"]);
			// 还没到这条开始就用上一条的文字。
			if (line_time < st) {
					if (idx > 0) {
							rpe_select_text_font(arr[idx - 1]);
							return string(arr[idx - 1][$ "end"]);
					};
					return string(default_value);
			};
			rpe_select_text_font(ev);
			// 起终点相同就不用插值。
			if (st == et || v0 == v1) then return v1;

	        var p = rpe_event_progress(ev, st, et);
	        var out_text = v0;
	        // 百分号标记按数字插值，否则只在前缀关系下逐字变长。
	        if (bool(ev[$ "isPercent"] ?? false)) {
	                var n0 = real(v0);
	                var n1 = real(v1);
	                var delta = lerp(n0, n1, p);
	                if ((frac(n0) != 0) || (frac(n1) != 0)) then out_text = string_format(delta, -1, 3);
	                else out_text = string_format(delta, -1, 0);
	        } else {
	                var lh = string_length(v0);
	                var lt = string_length(v1);
	                var is_prefix = false;
	                if (lt >= lh && string_copy(v1, 1, lh) == v0) then is_prefix = true;
	                if (lh >= lt && string_copy(v0, 1, lt) == v1) then is_prefix = true;
	                // 一方是另一方的前缀时，按长度裁切。
	                if (is_prefix) {
	                        var lp_now = lerp(lh, lt, p);
	                        if (lh < lt) then out_text = string_copy(v1, 1, max(0, round(lp_now)));
	                        else out_text = string_copy(v0, 1, max(0, round(lp_now)));
	                } else {
	                        out_text = v0;
	                };
	        };
	        ext_recall[$ event_name] = out_text;
	        return out_text;
	};

	static rpe_floor_at_sec = function(sec) {
	        return rpe_speed_floor_at(sec);
	};

	static rpe_floor_at_beat = function(beat) {
	        return rpe_floor_at_sec(game_1.Math.beatToAbsSec(beat));
	};

	static rpe_prepare_control = function(raw, value_name) {
		var result = { positions: [], values: [], easings: [], length: 0 };
		// 不是数组就返回空表。
		if (!is_array(raw)) then return result;
		var entries = [];
		for (var ci = 0; ci < array_length(raw); ci++) {
			var ce = raw[ci];
			// 跳过坏点，位置或值不是有限数也不收。
			if (!is_struct(ce)) then continue;
			var control_position = real(ce[$ "x"] ?? 0) / 540;
			var control_value = real(ce[$ value_name] ?? 1);
			// 位置不是有限数就丢掉这一点。
			if (!is_finite(control_position)) then continue;
			if (!is_finite(control_value)) then control_value = 1;
			array_add(entries, {
				position:control_position,
				value:control_value,
				easing:rpe_map_easing(ce[$ "easing"] ?? 1)
			});
		};
		array_sort(entries,
	///@desc 按位置比较两个控制点
	///@param {Struct} a 前一个点
	///@param {Struct} b 后一个点
	///@returns {Real} a 更小为 -1，更大为 1
	function(a, b) {
			// 位置小的排前面，相等则视为相同。
			if (a.position < b.position) then return -1;
			if (a.position > b.position) then return 1;
			return 0;
		});
		for (var entry_i = 0; entry_i < array_length(entries); entry_i++) {
			var existing_count = array_length(result.positions);
			// 同一位置后来的点覆盖前面的。
			if (existing_count > 0 && result.positions[existing_count - 1] == entries[entry_i].position) {
				result.values[existing_count - 1] = entries[entry_i].value;
				result.easings[existing_count - 1] = entries[entry_i].easing;
				continue;
			};
			array_add(result.positions, entries[entry_i].position);
			array_add(result.values, entries[entry_i].value);
			array_add(result.easings, entries[entry_i].easing);
		};
		result.length = array_length(result.positions);
		return result;
	};

	// 迁移前事件：objects/oLine_1/Create_0.gml；完整原文件见 docs/constructor-migration/legacy/rpe/。
	static actor_create = function() {
		///@desc 创建：RPE 判定线预处理，对齐 PCR
		// 坐标和运行时参考 com.teammio.pcr：
		// - rpec_parser.gml（事件层转换）
		// - CCEvents.gml / CCLEExecute（事件游标和缓动）
		// - notes/rpe_parse 的坐标系转换和速度积分

		// 深度等 zOrder 和 line_id 确定后再写。
		_father_chain = [];
		pose_epoch = -1;
		pose_scale_x = 0;
		pose_scale_y = 0;
		pose_value = [0, 0, 0];
		pose_parent_value = [0, 0, 0];
		pose_visiting = false;
		sprite_index = line;
		image_blend = c_white;
		image_alpha = 1;
		image_angle = 0;

		// 缺省字段补成可运行的默认值。
		if (!chart_actor_var_exists(id, "line_id")) then line_id = 0;
		if (!chart_actor_var_exists(id, "events")) then events = [];
		if (!chart_actor_var_exists(id, "extEvents")) then extEvents = {};
		if (!chart_actor_var_exists(id, "isFather")) then isFather = -1;
		if (!chart_actor_var_exists(id, "rotFatherLine")) then rotFatherLine = false;
		if (!chart_actor_var_exists(id, "image")) then image = "line.png";
		if (!chart_actor_var_exists(id, "line_csv_scale")) then line_csv_scale = 1;
		if (!chart_actor_var_exists(id, "anchor")) then anchor = [0.5, 0.5];
		if (!chart_actor_var_exists(id, "bpmfactor")) then bpmfactor = 1;
		if (!chart_actor_var_exists(id, "isCover") || is_undefined(isCover)) then isCover = true;
		if (!chart_actor_var_exists(id, "alphaControl")) then alphaControl = [];
		if (!chart_actor_var_exists(id, "sizeControl")) then sizeControl = [];
		if (!chart_actor_var_exists(id, "posControl")) then posControl = [];
		if (!chart_actor_var_exists(id, "yControl")) then yControl = [];
		if (!chart_actor_var_exists(id, "bindUI")) then bindUI = 0;
		if (!chart_actor_var_exists(id, "attachUI")) then attachUI = bindUI;
		if (!is_real(isFather)) then isFather = -1;
		if (!is_bool(rotFatherLine) && !is_real(rotFatherLine)) then rotFatherLine = false;
		rotFatherLine = bool(rotFatherLine);
		if (!is_real(bpmfactor) || bpmfactor <= 0) then bpmfactor = 1;
		anchor_x = 0.5;
		anchor_y = 0.5;
		// 锚点必须是有限数，否则回到中心。
		if (is_array(anchor) && array_length(anchor) >= 2) {
			anchor_x = real(anchor[0]);
			anchor_y = real(anchor[1]);
		};
		if (!is_finite(anchor_x)) then anchor_x = 0.5;
		if (!is_finite(anchor_y)) then anchor_y = 0.5;
		has_paint_events = (image == "line.png" && is_struct(extEvents) && struct_exists(extEvents, "paintEvents"));
		has_gif_events = (image != "line.png" && is_struct(extEvents) && struct_exists(extEvents, "gifEvents"));
		paint_surface = -1;
		paint_has_content = false;
		paint_last_valid = false;
		paint_last_x = 0;
		paint_last_y = 0;
		paint_last_radius = 0;
		paint_last_time = -infinity;

		// attachUI（PCR 1.2.1-Public）：pause / combonumber / combo / score / bar / name / level
		// 只有已知键才绑定界面；绑定后的线保持全透明，不绘制。
		attachUI = (is_undefined(attachUI) ? bindUI : attachUI);
		bindUI = (is_undefined(bindUI) ? attachUI : bindUI);
		attach_ui_key = "";
		is_attach_ui = false;
		var _aui_raw = attachUI;
		if (is_string(_aui_raw)) {
		        var _aui_key = string_lower(string_replace_all(_aui_raw, " ", ""));
		        // 对齐 RPE.attachUI_Group，不含 default。
		        var _attach_ui_keys = ["pause", "combonumber", "combo", "score", "bar", "name", "level"];
		        // 命中已知键才算界面绑定。
		        if (array_get_index(_attach_ui_keys, _aui_key) >= 0) {
		                attach_ui_key = _aui_key;
		                is_attach_ui = true;
		        };
		};
		if (is_attach_ui) {
		        image_alpha = 0;
		};

		// RPE.CreateLines 按 zOrder 和 line_id 排序后才写最终深度。
		if (!chart_actor_var_exists(id, "zOrder") || !is_real(zOrder)) then zOrder = 0;
		zOrder = real(zOrder);
		if (!is_finite(zOrder)) then zOrder = 0;
		z = zOrder; // PCR 别名
		depth = DEPTH.LINE;

		rpe_map_easing = rpe_map_easing_id;

		is_default_line = (image == "line.png");
		line_image = line;
		gif_data = undefined;
		if (has_gif_events && is_string(image) && string_length(image)) {
			if (!struct_exists(game_1, "Gif") || !is_struct(game_1.Gif)) then game_1.Gif = {};
			var gif_cache_valid = false;
			// 缓存有效才复用，坏帧就删掉重载。
			if (struct_exists(game_1.Gif, image)) {
				var cached_gif = game_1.Gif[$ image];
				gif_cache_valid = is_struct(cached_gif)
					&& is_array(cached_gif.frames) && array_length(cached_gif.frames) > 0
					&& is_array(cached_gif.delays)
					&& array_length(cached_gif.delays) == array_length(cached_gif.frames)
					&& real(cached_gif.total) > 0;
				if (gif_cache_valid) {
					for (var gif_cache_i = 0; gif_cache_i < array_length(cached_gif.frames); gif_cache_i++) {
						// 有一帧精灵丢了，整段缓存作废。
						if (!sprite_exists(cached_gif.frames[gif_cache_i])) {
							gif_cache_valid = false;
							break;
						};
					};
				};
				// 缓存无效就删掉坏帧。
				if (!gif_cache_valid) {
					if (is_struct(cached_gif) && is_array(cached_gif.frames)) {
						for (var gif_stale_i = 0; gif_stale_i < array_length(cached_gif.frames); gif_stale_i++) {
							if (sprite_exists(cached_gif.frames[gif_stale_i])) then sprite_delete(cached_gif.frames[gif_stale_i]);
						};
					};
					struct_remove(game_1.Gif, image);
				};
			};
			if (!gif_cache_valid) {
				var gif_frame_delays_raw = [];
				var gif_frame_sprites = [];
				var gif_path = chart_resolve_asset(image);
				var gif_last_sprite = -1;
				if (string_length(gif_path)) then gif_last_sprite = sprite_add_gif(gif_path, 0, 0, gif_frame_delays_raw, gif_frame_sprites);
				// 拆帧数组为空时，至少留下最后一张。
				if (array_length(gif_frame_sprites) <= 0 && sprite_exists(gif_last_sprite)) then array_add(gif_frame_sprites, gif_last_sprite);
				var gif_frame_delays = [];
				var gif_total_time = 0;
				var gif_frame_ends = [];
				for (var gif_load_i = 0; gif_load_i < array_length(gif_frame_sprites); gif_load_i++) {
					var gif_frame_sprite = gif_frame_sprites[gif_load_i];
					if (sprite_exists(gif_frame_sprite)) {
						sprite_set_offset(gif_frame_sprite, sprite_get_width(gif_frame_sprite) * 0.5, sprite_get_height(gif_frame_sprite) * 0.5);
					};
					var gif_delay_seconds = 0.01;
					if (gif_load_i < array_length(gif_frame_delays_raw)) then gif_delay_seconds = max(0.01, real(gif_frame_delays_raw[gif_load_i]) * 0.01);
					array_add(gif_frame_delays, gif_delay_seconds);
					gif_total_time += gif_delay_seconds;
					array_push(gif_frame_ends, gif_total_time);
				};
				game_1.Gif[$ image] = {
					frames: gif_frame_sprites,
					delays: gif_frame_delays,
					ends: gif_frame_ends,
					total: gif_total_time
				};
			};
			gif_data = game_1.Gif[$ image];
			if (is_struct(gif_data) && is_array(gif_data.frames) && array_length(gif_data.frames) > 0
				&& sprite_exists(gif_data.frames[0])) then line_image = gif_data.frames[0];
		// 静态自定义贴图按文件名缓存在 game_1.Texture。
		} else if (is_string(image) && string_length(image) && image != "line.png") {
				var tex_path = chart_resolve_asset(image);
		        if (string_length(tex_path)) {
		                if (variable_global_exists("game_1") && is_struct(game_1)) {
		                        if (!struct_exists(game_1, "Texture") || !is_struct(game_1.Texture)) then game_1.Texture = {};
		                        if (!struct_exists(game_1.Texture, image) || !sprite_exists(game_1.Texture[$ image])) {
							var spr = chart_sprite_add_file(tex_path);
							if (sprite_exists(spr)) {
								sprite_set_offset(spr, sprite_get_width(spr) / 2, sprite_get_height(spr) / 2);
		                                        game_1.Texture[$ image] = spr;
		                                };
		                        };
		                        if (struct_exists(game_1.Texture, image) && sprite_exists(game_1.Texture[$ image])) {
		                                line_image = game_1.Texture[$ image];
		                        };
		                };
		        };
				// 贴图没找到只警告一次。
				if (line_image == line && variable_global_exists("game_1") && is_struct(game_1)) {
					if (!struct_exists(game_1, "_texture_miss") || !is_struct(game_1._texture_miss)) then game_1._texture_miss = {};
					if (!struct_exists(game_1._texture_miss, image)) {
						game_1._texture_miss[$ image] = true;
						print($"[RPE] Texture missing: {image} looked in chart root and Pictures/");
					};
				};
		};
		sprite_index = line_image;
		image_speed = 0;
		if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then visible = false;

		// 每层事件的游标、保持值和上次有效值。
		events_count = [];
		events_hold = [];
		events_recall = [];
		rpe_speed_events = [];
		speed_event_index = 0;

		// 在 line_time 上求值一条事件通道，游标类似 CCLEExecute。
		///@desc 求值某一层的一条数值事件
		///@param {Real} layer_index 事件层下标
		///@param {String} event_name 通道名
		///@param {Real} default_value 通道缺失时的值
		///@returns {Real} 当前值


		// RPEVersion 小于 170 存扁平梯形表，每段自带 floorPosition。
		// 170 及以上每层速度是一个已积分的层结构。
		///@desc 求给定秒数上的速度 floor
		///@param {Real} t 谱面秒
		///@returns {Real} 各层 floor 之和


		///@desc 用当前 line_sec 求速度 floor
		///@returns {Real} 当前 floor


		// 扩展事件是单通道，不按多层相加。
		///@desc 求一条事件在 line_time 上的缓动进度
		///@param {Struct} ev 事件
		///@param {Real} st 开始秒
		///@param {Real} et 结束秒
		///@returns {Real} 进度，弹性等缓动可以超出 0 到 1


		///@desc 求值一条扩展数值事件
		///@param {String} event_name 通道名
		///@param {Real} default_value 通道缺失时的值
		///@returns {Real} 当前值


		///@desc 求值颜色事件并混合两端颜色
		///@param {Real} default_value 没有颜色事件时的颜色
		///@returns {Real} 当前颜色


		///@desc 求值文本事件，并按事件选择字体
		///@param {String} default_value 没有文本事件时的文字
		///@returns {String} 当前文字

		if (!is_array(events)) then events = [];
		var _clean_layers = [];
		for (var li = 0; li < array_length(events); li++) {
		        if (is_struct(events[li])) {
		                // RPE 允许省略通道。建游标前补齐标准通道，
		                // 这样每一层从第一步起形状都稳定。
		                if (!struct_exists(events[li], "moveXEvents")) then events[li].moveXEvents = [];
		                if (!struct_exists(events[li], "moveYEvents")) then events[li].moveYEvents = [];
		                if (!struct_exists(events[li], "alphaEvents")) then events[li].alphaEvents = [];
		                if (!struct_exists(events[li], "rotateEvents")) then events[li].rotateEvents = [];
		                if (!struct_exists(events[li], "speedEvents")) then events[li].speedEvents = [];
		                array_add(_clean_layers, events[li]);
		        };
		};
		events = _clean_layers;
		rpe_events_initialized = true;
		rpe_events_test_logged = false;
		rpe_force_event_init = false;

		for (var li = 0; li < array_length(events); li++) {
		        var ev_layer = events[li];
		        var cmap = {};
		        var hmap = {};
		        var rmap = {};
		        var names = struct_get_names(ev_layer);
		        for (var ni = 0; ni < array_length(names); ni++) {
		                var en = names[ni];
		                var is_speed = (en == "speedEvents");
		                ev_layer[$ en] = rpe_prep_event_array(ev_layer[$ en], is_speed);
		                cmap[$ en] = 0;
		                var arr0 = ev_layer[$ en];
		                // 有事件时用第一条的起点当保持值。
		                if (is_array(arr0) && array_length(arr0) > 0) {
		                        hmap[$ en] = arr0[0][$ "start"] ?? 0;
		                        rmap[$ en] = hmap[$ en];
		                } else {
		                        hmap[$ en] = 0;
		                        rmap[$ en] = 0;
		                };
		        };
		        array_add(events_count, cmap);
		        array_add(events_hold, hmap);
		        array_add(events_recall, rmap);
		};

		if (!chart_actor_var_exists(id, "integrate_speed_easings")) then integrate_speed_easings = undefined;
		rpe_speed_events = rpe_build_speed_events(events, integrate_speed_easings);
		speed_event_index = 0;

		if (!is_struct(extEvents)) then extEvents = {};
		ext_count = {};
		ext_hold = {};
		ext_recall = {};
		has_text_events = false;
		has_color_events = false;
		has_scale_events = false;

		// 扩展通道的特殊预处理，语义对齐 PCR rpec_parser。
		var enames = struct_get_names(extEvents);
		for (var ei = 0; ei < array_length(enames); ei++) {
		        var en = enames[ei];
		        var raw_arr = extEvents[$ en];
		        // 不是数组的通道清空。
		        if (!is_array(raw_arr)) {
		                extEvents[$ en] = [];
		                continue;
		        };

		        // 颜色：拍数换成秒，RGB 数组收成颜色值。
		        if (en == "colorEvents") {
		                has_color_events = (array_length(raw_arr) > 0);
		                for (var ci = 0; ci < array_length(raw_arr); ci++) {
		                        var cev = raw_arr[ci];
		                        if (!is_struct(cev)) then continue;
		                        if (struct_exists(cev, "startTime")) then cev.startTime = game_1.Math.beatToAbsSec(game_1.Math.arrToBeat(cev.startTime));
		                        if (struct_exists(cev, "endTime")) then cev.endTime = game_1.Math.beatToAbsSec(game_1.Math.arrToBeat(cev.endTime));
		                        var el = cev[$ "easingLeft"] ?? 0;
		                        var er = cev[$ "easingRight"] ?? 1;
		                        // 缓动窗口非法时恢复成整段。
		                        if ((el == er) || (el < 0) || (el > 1) || (er < 0) || (er > 1)) {
		                                el = 0; er = 1;
		                        };
		                        cev.easingLeft = el;
		                        cev.easingRight = er;
		                        cev.easingType = rpe_map_easing(cev[$ "easingType"] ?? 1);
		                        if (!struct_exists(cev, "bezier")) then cev.bezier = 0;
		                        if (!struct_exists(cev, "bezierPoints")) then cev.bezierPoints = [0, 0, 0, 0];

		                        var c0 = cev.start;
		                        var c1 = cev[$ "end"];
		                        // 起点和终点都可以是 RGB 数组。
		                        if (is_array(c0) && array_length(c0) >= 3) {
		                                cev.start = make_color_rgb(real(c0[0]), real(c0[1]), real(c0[2]));
		                        } else if (!is_real(c0)) {
		                                cev.start = c_white;
		                        };
		                        if (is_array(c1) && array_length(c1) >= 3) {
		                                cev[$ "end"] = make_color_rgb(real(c1[0]), real(c1[1]), real(c1[2]));
		                        } else if (!is_real(c1)) {
		                                cev[$ "end"] = cev.start;
		                        };
		                };
		                extEvents[$ en] = raw_arr;
		                if (array_length(raw_arr) > 0) {
		                        ext_count[$ en] = 0;
		                        ext_hold[$ en] = raw_arr[0].start;
		                        ext_recall[$ en] = raw_arr[0].start;
		                };
		                continue;
		        };

		        // 文本：拍数换成秒，并识别两端都有的 %P% 百分号标记。
		        if (en == "textEvents") {
		                has_text_events = (array_length(raw_arr) > 0);
		                for (var ti = 0; ti < array_length(raw_arr); ti++) {
		                        var tev = raw_arr[ti];
		                        if (!is_struct(tev)) then continue;
		                        if (struct_exists(tev, "startTime")) then tev.startTime = game_1.Math.beatToAbsSec(game_1.Math.arrToBeat(tev.startTime));
		                        if (struct_exists(tev, "endTime")) then tev.endTime = game_1.Math.beatToAbsSec(game_1.Math.arrToBeat(tev.endTime));
		                        var el2 = tev[$ "easingLeft"] ?? 0;
		                        var er2 = tev[$ "easingRight"] ?? 1;
		                        if ((el2 == er2) || (el2 < 0) || (el2 > 1) || (er2 < 0) || (er2 > 1)) {
		                                el2 = 0; er2 = 1;
		                        };
		                        tev.easingLeft = el2;
		                        tev.easingRight = er2;
		                        tev.easingType = rpe_map_easing(tev[$ "easingType"] ?? 1);
		                        if (!struct_exists(tev, "bezier")) then tev.bezier = 0;
		                        if (!struct_exists(tev, "bezierPoints")) then tev.bezierPoints = [0, 0, 0, 0];

		                        var ts = string(tev[$ "start"] ?? "");
		                        var te = string(tev[$ "end"] ?? ts);
		                        var marker = "%P%";
		                        var has_p0 = (string_pos(marker, ts) > 0);
		                        var has_p1 = (string_pos(marker, te) > 0);
		                        // 两端都有标记才按数字百分比插值。
		                        tev.isPercent = (has_p0 && has_p1);
		                        tev.start = string_replace_all(ts, marker, "");
		                        tev[$ "end"] = string_replace_all(te, marker, "");
		                };
		                extEvents[$ en] = raw_arr;
		                if (array_length(raw_arr) > 0) {
		                        ext_count[$ en] = 0;
		                        ext_hold[$ en] = string(raw_arr[0].start);
		                        ext_recall[$ en] = string(raw_arr[0].start);
		                };
		                continue;
		        };

		        // 数值通道：scaleX、scaleY、paint 以及其他。
		        if (en == "scaleXEvents" || en == "scaleYEvents") then has_scale_events = true;
		        extEvents[$ en] = rpe_prep_event_array(raw_arr, false);
		        var narr = extEvents[$ en];
		        if (is_array(narr) && array_length(narr) > 0) {
		                ext_count[$ en] = 0;
		                ext_hold[$ en] = real(narr[0].start ?? 0);
		                ext_recall[$ en] = real(narr[0].start ?? 0);
		        };
		};

		line_texture_use_judge_color = is_default_line
			&& !has_color_events
			&& !has_gif_events
			&& !has_paint_events
			&& !is_attach_ui;

		// 固定通道不再逐帧经过事件求值器；仍按原层顺序相加，保留浮点加法次序。
		rpe_event_routes = [];
		// 常量分类要区分极小变化；不能把引擎比较容差当成可省略的动画幅度。
		var route_epsilon = math_get_epsilon();
		math_set_epsilon(0);
		try {
			for (var route_i = 0; route_i < array_length(events); route_i++) {
				var route_layer = events[route_i];
				var fixed_x = rpe_event_constant(route_layer.moveXEvents);
				var fixed_y = rpe_event_constant(route_layer.moveYEvents);
				var fixed_a = rpe_event_constant(route_layer.alphaEvents);
				var fixed_r = rpe_event_constant(route_layer.rotateEvents);
				if (fixed_x == 0 && fixed_y == 0 && fixed_a == 0 && fixed_r == 0) continue;
				array_push(rpe_event_routes, [route_i, fixed_x, fixed_y, fixed_a, fixed_r]);
			}
		} finally {
			math_set_epsilon(route_epsilon);
		}

		// PCR 的 calcFloorPosition，用和运行时同一张合并表。
		///@desc 按秒查询速度 floor
		///@param {Real} sec 谱面秒
		///@returns {Real} floor


		///@desc 按拍查询速度 floor
		///@param {Real} beat 拍数
		///@returns {Real} floor

		// PCR 的 isCover 和音符控制。
		// isCover 为 false 时音符过线后仍然可见。
		isCover = (is_bool(isCover) ? isCover : (real(isCover) != 0));
		_uncover = !isCover;
		_alpha_decimal = 255;
		///@desc 把音符控制点收成按位置排序的表
		///@param {Array} raw 原始控制点
		///@param {String} value_name 取值字段名
		///@returns {Struct} positions、values、easings 和 length

		_control_alpha = rpe_prepare_control(alphaControl, "alpha");
		_control_pos = rpe_prepare_control(posControl, "pos");
		_control_size = rpe_prepare_control(sizeControl, "size");
		_control_y = rpe_prepare_control(yControl, "y");
		_control_skew = rpe_prepare_control(chart_actor_var_exists(id, "skewControl") ? skewControl : [], "skew");

		// 运行时状态。
		line_time = 0;
		line_sec = 0;
		__raw_x = 0;
		__raw_y = 0;
		__raw_r = 0;
		__raw_a = 0;
		__scale_x = 1;
		__scale_y = 1;
		__incline = 0;
		__incline_sin = 0;
		__paint_radius = -1;
		__gif_progress = 0;
		__color = c_white;
		line_text = "";
		line_text_font = (!is_undefined(game.font) && font_exists(game.font)) ? game.font : -1;
		__x = room_width * 0.5;
		__y = room_height * 0.5;
		__a = 255;
		__r = 0;
		__cos = 1;
		__sin = 0;
		__value = [0, 0];
		x = __x;
		y = __y;
		image_blend = __color;
		if (is_attach_ui) {
		        // 绑定界面的线精灵保持隐藏；真实透明度在步进里算完再写到界面。
		        image_alpha = 0;
		};

		// 排版缓存不包含缩放，窗口变化仍使用实时变换。
		_text_layout_source = undefined;
		_text_layout_font = undefined;
		_text_layout_em = 1;
		_text_layout_rows = [];
		_text_layout_width = 0;
	};

	// 迁移前事件：objects/oLine_1/Step_0.gml；完整原文件见 docs/constructor-migration/legacy/rpe/。
	static actor_step = function() {
		///@desc 步进：RPE 判定线事件运行时，对齐 PCR
		// 退场只保留已有事件值；Step End 和绘制前仍可校正窗口几何。
		if (chart_play_ending()) then exit;
		if (!is_array(events)) then events = [];
		if (!is_array(events_count)) then events_count = [];
		if (!is_array(events_hold)) then events_hold = [];
		if (!is_array(events_recall)) then events_recall = [];
		// 谱面构建被推迟后，线可能被重新激活。
		// 在第一个有效帧求值前，补上缺失的事件游标。
		if (!chart_actor_var_exists(id, "rpe_events_initialized") || !rpe_events_initialized
			|| array_length(events_count) != array_length(events)
			|| array_length(events_hold) != array_length(events)
			|| array_length(events_recall) != array_length(events)) {
		    events_count = [];
		    events_hold = [];
		    events_recall = [];
		    for (var _init_layer = 0; _init_layer < array_length(events); _init_layer++) {
		        var _init_events = events[_init_layer];
		        var _init_counts = {};
		        var _init_hold = {};
		        var _init_recall = {};
		        if (is_struct(_init_events)) {
		            if (!struct_exists(_init_events, "moveXEvents")) then _init_events.moveXEvents = [];
		            if (!struct_exists(_init_events, "moveYEvents")) then _init_events.moveYEvents = [];
		            if (!struct_exists(_init_events, "alphaEvents")) then _init_events.alphaEvents = [];
		            if (!struct_exists(_init_events, "rotateEvents")) then _init_events.rotateEvents = [];
		            if (!struct_exists(_init_events, "speedEvents")) then _init_events.speedEvents = [];
		            var _init_names = struct_get_names(_init_events);
		            for (var _init_name_i = 0; _init_name_i < array_length(_init_names); _init_name_i++) {
		                var _init_name = _init_names[_init_name_i];
		                var _init_array = _init_events[$ _init_name];
		                _init_counts[$ _init_name] = 0;
		                // 有事件时用第一条起点初始化保持值。
		                if (is_array(_init_array) && array_length(_init_array) > 0) {
		                    var _init_value = _init_array[0][$ "start"] ?? 0;
		                    _init_hold[$ _init_name] = _init_value;
		                    _init_recall[$ _init_name] = _init_value;
		                } else {
		                    _init_hold[$ _init_name] = 0;
		                    _init_recall[$ _init_name] = 0;
		                };
		            };
		        };
		        array_add(events_count, _init_counts);
		        array_add(events_hold, _init_hold);
		        array_add(events_recall, _init_recall);
		    };
		    rpe_events_initialized = true;
		};
		// 多层数值在 RPE 编辑器空间里相加。
		// 父级和屏幕变换放在步进结束，好让父线先求值。
		// 扩展事件（缩放、颜色、文本）只在 extEvents 里存一份。

		// 加载动画或暂停时不求值，除非强制初始化或转场还在更新。
		if (variable_global_exists("loading_animation_active") && global.loading_animation_active
			&& !rpe_force_event_init) then exit;
		var _transition_updates = chart_actor_exists(oRender_1)
			&& chart_actor_var_exists(oRender_1, "play_transition_active")
			&& bool(oRender_1.play_transition_active);
		if (variable_global_exists("game") && is_struct(game) && game.paused
			&& !_transition_updates && !rpe_force_event_init) then exit;
		var _events = events;
		var _event_layer_count = (is_array(_events) ? array_length(_events) : 0);
		// 既没有事件层也没有扩展事件。
		if (_event_layer_count <= 0 && !is_struct(extEvents)) then exit;

		// 当前谱面时间，单位是拍
		var now_sec = 0;
		if (variable_global_exists("game") && is_struct(game) && is_array(game.__time)) {
		        now_sec = game.__time[1];
		};

		var chart_offset_sec = 0;
		if (variable_global_exists("game_1") && is_struct(game_1) && is_struct(game_1.chart_info)) {
		        chart_offset_sec = real(game_1.chart_info.offset ?? 0) / 1000;
		};

		var tf = ((!is_real(bpmfactor) || bpmfactor <= 0) ? 1 : bpmfactor);
		// PCR 的绝对谱面秒 = 媒体秒 -（META.offset + 外部信息偏移）。
		var chart_sec = now_sec - chart_offset_sec;
		// PCR：selftime = chart_time / timeFactor(bpmfactor)，速度 floor 用它。
		line_sec = chart_sec / tf;
		// RPE 解析器把运行时事件时间都存成累计 BPM 秒。
		line_time = line_sec;

		// ---- multi-layer sum (local RPE space only this step) ----
		var sum_x = 0;
		var sum_y = 0;
		var sum_a = 0;
		var sum_r = 0;

		for (var route_i = 0; route_i < array_length(rpe_event_routes); route_i++) {
			var route = rpe_event_routes[route_i];
			var i = route[0];
			sum_x += is_undefined(route[1]) ? rpe_eval_events(i, "moveXEvents", 0) : route[1];
			sum_y += is_undefined(route[2]) ? rpe_eval_events(i, "moveYEvents", 0) : route[2];
			sum_a += is_undefined(route[3]) ? rpe_eval_events(i, "alphaEvents", 0) : route[3];
			sum_r += is_undefined(route[4]) ? rpe_eval_events(i, "rotateEvents", 0) : route[4];
		}
		var speed_floor = rpe_speed_floor();

		__raw_x = sum_x;
		__raw_y = sum_y;
		__raw_r = sum_r;
		// 同一轮局部事件全部结束后，世界姿态缓存可供所有 Step End 共用。
		game_1._pose_epoch++;
		// attachUI 把真实透明度留给界面写入；线本身在步进结束和绘制里隐藏。
		__raw_a = sum_a;
		// PCR 的 _alpha_decimal 是未夹取的 RPE 透明度之和，可以是负数或大于 255。
		_alpha_decimal = sum_a;
		__value[0] = speed_floor; // 速度预处理里已经除过 4.5（PCR）
		__value[1] = speed_floor;
		__a = sum_a;

		if (!rpe_events_test_logged && line_id == 0
		        && variable_global_exists("pls_archive_test") && global.pls_archive_test) {
		    print($"[RPE Events][INIT] line=0 initialized={rpe_events_initialized} layers={_event_layer_count} cursors={array_length(events_count)} x={sum_x} y={sum_y} alpha={sum_a} rot={sum_r} speedLayers={array_length(rpe_speed_events)}");
		    rpe_events_test_logged = true;
		};

		// 扩展特殊事件
		__scale_x = rpe_eval_ext_events("scaleXEvents", 1);
		__scale_y = rpe_eval_ext_events("scaleYEvents", 1);
		__incline = rpe_eval_ext_events("inclineEvents", 0);
		__incline_sin = dsin(__incline);
		if (has_color_events) {
		        __color = rpe_eval_color_events(c_white);
		} else {
		        // 没有颜色事件就用白。
		        __color = c_white;
		};
		if (has_text_events) {
		        line_text = rpe_eval_text_events("");
		} else {
		        line_text = "";
		};
		__paint_radius = (has_paint_events ? rpe_eval_ext_events("paintEvents", -1) : -1);
		if (has_gif_events && is_struct(gif_data) && real(gif_data.total) > 0) {
			var _gif_duration = real(gif_data.total);
			__gif_progress = frac(max(0, line_time) / _gif_duration);
			var _gif_events = extEvents[$ "gifEvents"];
			var _gif_event_count = (is_array(_gif_events) ? array_length(_gif_events) : 0);
			// 有 gif 事件时按事件覆盖进度，空隙里沿用上一个终点往后走。
			if (_gif_event_count > 0) {
				var _gif_last_end_time = 0;
				var _gif_last_end_value = 0;
				var _gif_has_previous = false;
				for (var _gi = 0; _gi < _gif_event_count; _gi++) {
					var _gev = _gif_events[_gi];
					if (!is_struct(_gev)) then continue;
					// 还没到这条就开始，后面更晚。
					if (line_time < _gev.startTime) then break;
					// 落在区间内就插值。
					if (line_time <= _gev.endTime) {
						__gif_progress = lerp(real(_gev.start), real(_gev[$ "end"]), rpe_event_progress(_gev, _gev.startTime, _gev.endTime));
						_gif_has_previous = false;
						break;
					};
					_gif_last_end_time = _gev.endTime;
					_gif_last_end_value = real(_gev[$ "end"]);
					_gif_has_previous = true;
				};
				if (_gif_has_previous) then __gif_progress = frac(_gif_last_end_value + (line_time - _gif_last_end_time) / _gif_duration);
			};
		};
	};

	// 迁移前事件：objects/oLine_1/Step_2.gml；完整原文件见 docs/constructor-migration/legacy/rpe/。
	static actor_end = function() {
		///@desc 步进结束：所有线求值后再做父级变换和屏幕映射
		// RPE 在父级旋转之前，用视口宽/1350 和视口高/900 缩放子级偏移。
		// 步进结束时，每条线这一帧的 __raw_* 都已经写完。
		// 退场不重复写绑定界面；窗口变化由渲染器的 Draw Begin 统一校正。
		if (chart_play_ending()) then exit;

		// 加载动画或暂停时不做屏幕映射，除非强制初始化或转场还在更新。
		if (variable_global_exists("loading_animation_active") && global.loading_animation_active
			&& !rpe_force_event_init) then exit;
		var _transition_updates = chart_actor_exists(oRender_1)
			&& chart_actor_var_exists(oRender_1, "play_transition_active")
			&& bool(oRender_1.play_transition_active);
		if (variable_global_exists("game") && is_struct(game) && game.paused
			&& !_transition_updates && !rpe_force_event_init) then exit;

		// 姿态已经是视图像素。高度用窗口高度。只有水平范围受谱面宽高比限制。
		var chart_view_h = chart_view_height;
		var chart_view_w = chart_view_width;
		var pose = rpe_line_view_pose(id, chart_view_w / 1350, chart_view_h / 900);
		x = pose[0] + chart_view_left + chart_view_w * 0.5;
		y = -pose[1] + chart_view_h * 0.5;
		image_angle = -pose[2];
		image_blend = __color;

		__x = x;
		__y = y;
		__r = image_angle;
		__cos = dcos(image_angle);
		__sin = dsin(image_angle);
		// attachUI：把线的变换写进 oRender_1.bindUI（对齐 PCR），并隐藏线的绘制。
		// PCR 存的是相对中心的偏移：posx = x - 场景半宽，posy = y - 场景半高。
		// 界面最终位置 = 默认布局位置 + 偏移，不是线的绝对坐标。
		// 原始值留给 PE 的负透明度音符语义，可绘制值再夹取。
		// 多层 RPE 谱的透明度相加后经常是 510、1020 或 1530。
		var ui_alpha = clamp(__raw_a / 255, 0, 1);
		_alpha_decimal = __raw_a;
		if (is_attach_ui && is_string(attach_ui_key) && string_length(attach_ui_key) > 0
		        && chart_actor_exists(oRender_1) && chart_actor_var_exists(oRender_1, "bindUI")) {
				var ui_off_x = x - (chart_view_left + chart_view_w * 0.5);
				var ui_off_y = y - (chart_view_h * 0.5);
		        with (oRender_1) {
		                if (is_struct(bindUI) && struct_exists(bindUI, other.attach_ui_key)) {
		                        var slot = bindUI[$ other.attach_ui_key];
		                        // 槽不够长就重建，避免写越界。
		                        if (!is_array(slot) || array_length(slot) < 7) {
		                                slot = array_create(7, 0);
		                                bindUI[$ other.attach_ui_key] = slot;
		                        };
		                        // 槽位：[offX, offY, color, alpha, rot, scaleX, scaleY]
		                        slot[@ 0] = ui_off_x;
		                        slot[@ 1] = ui_off_y;
		                        slot[@ 2] = other.image_blend;
		                        slot[@ 3] = ui_alpha;
		                        slot[@ 4] = other.image_angle;
		                        slot[@ 5] = other.__scale_x;
		                        slot[@ 6] = other.__scale_y;
		                        if (is_struct(bindUI_attached)) then bindUI_attached[$ other.attach_ui_key] = true;
		                };
		        };
		        // PCR：绑定界面的线不绘制（enabled=false）。
		        image_alpha = 0;
		} else {
		        image_alpha = ui_alpha;
		};
	};

	// 迁移前事件：objects/oLine_1/Draw_0.gml；完整原文件见 docs/constructor-migration/legacy/rpe/。
	static actor_draw = function() {
		///@desc 绘制：RPE 判定线，支持扩展缩放、颜色和文本
		chart_mask_scissor_set();
		// 加载动画或判定线尚未解冻时不画。
		if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then exit;
		if (chart_actor_exists(oRender_1)
			&& chart_actor_var_exists(oRender_1, "_chart_lines_thaw_pending")
			&& oRender_1._chart_lines_thaw_pending) then exit;
		var s = (variable_global_exists("global_scales") ? global_scales : 1.0);
		if (!is_real(s) || s <= 0) then s = 1.0;
		var _room_w = room_width;
		var _room_h = room_height;

		// 没有 zIndex 时视频跟这条线一起画，appearanceOnAttach 为 0
		// （默认，包括从没设置过的谱）会藏起线。声明了视频 zIndex 的由 oExtraPlay 画，
		// 这条线留在自己的层上。appearanceOnAttach 为 1 或 2 时线仍可见，在视频上方或下方。
		var line_has_attached_video = false;
		var attached_video_owns_depth = false;
		if (chart_actor_exists(oExtraPlay)) {
			with (oExtraPlay) {
				var _attached_video = video_line_index(other.id);
				line_has_attached_video = _attached_video >= 0;
				// 视频自己有 z 时不在这条线里画。
				if (line_has_attached_video && is_real(videos[_attached_video].zIndex)) {
					attached_video_owns_depth = true;
				};
				if (line_has_attached_video && !attached_video_owns_depth) then draw_attached_video(_attached_video);
			};
		};
		var attach_look = 0;
		if (chart_actor_var_exists(id, "appearance_on_attach") && is_real(appearance_on_attach)) {
			attach_look = appearance_on_attach;
		};
		// 吸附视频且外观为 0、又没有文本时，线本身不画。
		if (line_has_attached_video && attach_look <= 0 && !has_text_events) then exit;

		if (has_paint_events) {
			// 涂鸦表面尺寸必须跟房间一致，否则重建并清空。
			if (!surface_exists(paint_surface)
				|| surface_get_width(paint_surface) != _room_w
				|| surface_get_height(paint_surface) != _room_h) {
				if (surface_exists(paint_surface)) then surface_free(paint_surface);
				paint_surface = surface_create(_room_w, _room_h);
				if (surface_exists(paint_surface)) {
					surface_set_target(paint_surface);
					draw_clear_alpha(c_black, 0);
					surface_reset_target();
				};
				paint_has_content = false;
				paint_last_valid = false;
			};
			if (surface_exists(paint_surface)) {
				// 时间回退就清掉已经涂上的内容。
				if (line_time < paint_last_time) {
					surface_set_target(paint_surface);
					draw_clear_alpha(c_black, 0);
					surface_reset_target();
					paint_has_content = false;
					paint_last_valid = false;
				};
				paint_last_time = line_time;
				var paint_radius = real(__paint_radius) * s * sqrt(abs(__scale_x * __scale_y));
				// 半径不大于 0 时清空并停止涂鸦。
				if (paint_radius <= 0) {
					if (paint_has_content) {
						surface_set_target(paint_surface);
						draw_clear_alpha(c_black, 0);
						surface_reset_target();
					};
					paint_has_content = false;
					paint_last_valid = false;
				} else {
					var paint_alpha = clamp(max(0, __raw_a) / 255, 0, 1);
					// 有透明度才把上一帧到这一帧连成一条带子。
					if (paint_alpha > 0 && !game.paused) {
						surface_set_target(paint_surface);
						draw_set_colour(__color);
						draw_set_alpha(paint_alpha);
						if (paint_last_valid) {
							var paint_dx = x - paint_last_x;
							var paint_dy = y - paint_last_y;
							var paint_distance = point_distance(paint_last_x, paint_last_y, x, y);
							// 移动足够远才补中间的两个三角形。
							if (paint_distance > 0.001) {
								var paint_normal_x = -paint_dy / paint_distance;
								var paint_normal_y = paint_dx / paint_distance;
								var last_ax = paint_last_x + paint_normal_x * paint_last_radius;
								var last_ay = paint_last_y + paint_normal_y * paint_last_radius;
								var last_bx = paint_last_x - paint_normal_x * paint_last_radius;
								var last_by = paint_last_y - paint_normal_y * paint_last_radius;
								var now_ax = x + paint_normal_x * paint_radius;
								var now_ay = y + paint_normal_y * paint_radius;
								var now_bx = x - paint_normal_x * paint_radius;
								var now_by = y - paint_normal_y * paint_radius;
								draw_triangle(last_ax, last_ay, last_bx, last_by, now_ax, now_ay, false);
								draw_triangle(last_bx, last_by, now_bx, now_by, now_ax, now_ay, false);
							};
						};
						draw_circle(x, y, paint_radius, false);
						draw_set_alpha(1);
						surface_reset_target();
						paint_has_content = true;
						paint_last_valid = true;
						paint_last_x = x;
						paint_last_y = y;
						paint_last_radius = paint_radius;
					} else {
						paint_last_valid = false;
					};
				};
				draw_surface(paint_surface, 0, 0);
			};
			// 涂鸦画完就不再画线精灵。
			exit;
		};

		// 完全透明就不再画精灵。
		if (image_alpha <= 0) then exit;

		// 颜色来自扩展 colorEvents，否则是白。
		image_blend = __color;

			if (has_text_events) {
				if (string_length(line_text) > 0) {
					if (line_text_font != -1 && font_exists(line_text_font)) then draw_set_font(line_text_font);
					else if (variable_global_exists("game") && is_struct(game) && !is_undefined(game.font) && font_exists(game.font)) then draw_set_font(game.font);
					// PhiEdit 标签字号 100，节点缩放是 (scaleX, scaleY) * 0.5，左对齐。
					// 锚点 (0,0) 是行框左下，(1,1) 是右上。cmdysj 的行框是一个 em
					// （上升 880，下降 -120）。image_angle 已经是取反后的谱面旋转，
					// 在这个 Y 向下的空间里就是 cocos 的顺时针旋转。
					var _old_halign = draw_get_halign();
					var _old_valign = draw_get_valign();
					draw_set_halign(fa_left);
					draw_set_valign(fa_top);
					draw_set_colour(image_blend);
					draw_set_alpha(image_alpha);
					var text_view_w = _room_w;
					if (variable_global_exists("chart_view_width") && is_real(chart_view_width) && chart_view_width > 0) {
						text_view_w = chart_view_width;
					};
					var text_font = draw_get_font();
					if (_text_layout_source != line_text || _text_layout_font != text_font) {
						var text_em_px = string_width("■");
						// 方块测不出宽度时用字号兜底。
						if (text_em_px < 1) then text_em_px = max(1, font_get_size(draw_get_font()));
						var text_body = string_replace_all(line_text, "\r\n", "\n");
						text_body = string_replace_all(text_body, "\r", "");
						var text_rows = string_split(text_body, "\n");
						var text_row_n = array_length(text_rows);
						// 拆不出行时仍画整段。
						if (text_row_n < 1) {
							text_rows = [text_body];
							text_row_n = 1;
						};
						var text_w = 0;
						for (var text_i = 0; text_i < text_row_n; text_i++) {
							var row = text_rows[text_i];
							var row_width = 0;
							// 多行时最后一行去掉尾部空白再量宽。
							if (text_row_n > 1 && text_i == text_row_n - 1) {
								var row_len = string_length(row);
								var trail_n = row_len;
								while (trail_n > 0) {
									var trail_ch = string_char_at(row, trail_n);
									// 遇到非空白就停。
									if (trail_ch != " " && trail_ch != "\t") then break;
									trail_n--;
								};
								if (trail_n > 0) then row_width = string_width(string_copy(row, 1, trail_n));
							} else if (string_length(row) > 0) {
								row_width = string_width(row);
							};
							if (row_width > text_w) then text_w = row_width;
						};
						_text_layout_source = line_text;
						_text_layout_font = text_font;
						_text_layout_em = text_em_px;
						_text_layout_rows = text_rows;
						_text_layout_width = text_w;
					}
					var text_em_px = _text_layout_em;
					var text_rows = _text_layout_rows;
					var text_row_n = array_length(text_rows);
					var text_w = _text_layout_width;
					var text_unit = (50 * (text_view_w / 1350)) / text_em_px;
					var text_scale_x = text_unit * __scale_x;
					var text_scale_y = text_unit * __scale_y;
					var text_h = text_row_n * text_em_px;
					var pen_x = -anchor_x * text_w;
					var pen_top = -(1 - anchor_y) * text_h;
					var text_cos = dcos(image_angle);
					var text_sin = dsin(image_angle);
					for (var text_i = 0; text_i < text_row_n; text_i++) {
						var row = text_rows[text_i];
						// 空行跳过。
						if (string_length(row) <= 0) then continue;
						var text_lx = pen_x * text_scale_x;
						var text_ly = (pen_top + text_i * text_em_px) * text_scale_y;
						var text_draw_x = x + text_lx * text_cos + text_ly * text_sin;
						var text_draw_y = y - text_lx * text_sin + text_ly * text_cos;
						draw_text_transformed(text_draw_x, text_draw_y, row, text_scale_x, text_scale_y, image_angle);
					};
					draw_set_halign(_old_halign);
					draw_set_valign(_old_valign);
					draw_set_alpha(1);
				};
		} else {
			var frame = 0;
			// GIF 按累计延迟选出当前帧，绘制子图固定为 0。
			if (has_gif_events && is_struct(gif_data) && is_array(gif_data.frames) && array_length(gif_data.frames) > 0) {
				var gif_time = frac(__gif_progress) * max(0.000001, real(gif_data.total));
				var lo = 0;
				var hi = array_length(gif_data.ends);
				while (lo < hi) {
					var mid = (lo + hi) div 2;
					if (gif_data.ends[mid] <= gif_time) lo = mid + 1;
					else hi = mid;
				}
				frame = min(lo, array_length(gif_data.frames) - 1);
				var gif_sprite = gif_data.frames[frame];
				if (sprite_exists(gif_sprite)) then sprite_index = gif_sprite;
				frame = 0;
			};
			var _line_sprite = sprite_index;
			var anchor_width = max(1, sprite_get_width(_line_sprite));
			var anchor_height = max(1, sprite_get_height(_line_sprite));
			var texture_view_w = chart_view_width;
			var sx;
			var sy;
			// 默认线、CSV 覆盖和自定义贴图像素尺寸各算各的缩放。
			if (!is_default_line) {
				var _csv = chart_line_override(line_id);
				if (is_struct(_csv)) {
					var _csv_scale = chart_line_csv_sprite_scale(_csv, _line_sprite);
					sx = _csv_scale[0] * __scale_x;
					sy = _csv_scale[1] * __scale_y;
				} else {
					var texture_px = rpe_custom_texture_pixel_size(__scale_x, __scale_y, anchor_width, anchor_height, texture_view_w);
					sx = texture_px[0] / anchor_width;
					sy = texture_px[1] / anchor_height;
				};
			} else {
				var line_px = rpe_default_line_pixel_size(__scale_x, __scale_y, texture_view_w);
				sx = line_px[0] / anchor_width;
				sy = line_px[1] / anchor_height;
			};
			// Cocos 的锚点 Y 向上。缩放和旋转之后，锚点像素必须仍落在线上。
			// 运行时 sprite_add 的原点是 (0, 0)；1x1 的 Box.png 存不住 0.5 偏移，
			// 于是居中的 4000x4000 背景会从线往右下画。
			var anchor_local_x = anchor_x * anchor_width;
			var anchor_local_y = (1 - anchor_y) * anchor_height;
			if (!is_default_line) {
				sprite_set_offset(_line_sprite, 0, 0);
			} else {
				anchor_local_x -= sprite_get_xoffset(_line_sprite);
				anchor_local_y -= sprite_get_yoffset(_line_sprite);
			};
			// 默认 line.png 用 FC/AP。colorEvents、自定义贴图、GIF、涂鸦、
			// attachUI 和文本保持 __color（常常是白），不采样判定色。
			var texture_blend = __color;
			// appearanceOnAttach 为 1 时保持白色，除非颜色事件已经写了 __color。
			// 为 2 时用 FC/AP 判定色，和普通默认线一样。
			var judge_tint = line_texture_use_judge_color
				&& !(line_has_attached_video && attach_look == 1);
			if (judge_tint && variable_global_exists("game") && is_struct(game)
				&& bool(game.settings.enableLineJudge)) {
				texture_blend = chart_line_judge_blend();
			};
			// draw_sprite_ext 绕精灵原点缩放和旋转。把原点挪开，锚点像素才留在线上。旋转和音符相同。
			var anchor_shift_x = -anchor_local_x * sx;
			var anchor_shift_y = -anchor_local_y * sy;
			var anchor_cos = dcos(image_angle);
			var anchor_sin = dsin(image_angle);
			var sprite_draw_x = x + anchor_shift_x * anchor_cos + anchor_shift_y * anchor_sin;
			var sprite_draw_y = y - anchor_shift_x * anchor_sin + anchor_shift_y * anchor_cos;
			draw_sprite_ext(_line_sprite, frame, sprite_draw_x, sprite_draw_y, sx, sy, image_angle, texture_blend, image_alpha);
		};

		if (variable_global_exists("game") && is_struct(game) && game.settings.enableDisplayLineID) {
		        draw_set_halign(fa_center);
		        draw_set_valign(fa_middle);
		        draw_set_colour(c_white);
		        draw_set_alpha(1);
		        draw_text_transformed(x, y - 16 * s, string(line_id), 0.32 * s, 0.32 * s, image_angle);
		};
	};

	static actor_cleanup = function() {
		///@desc 清理：释放这条线自己的涂鸦表面，贴图仍留在 game_1
		if (chart_actor_var_exists(id, "paint_surface") && surface_exists(paint_surface)) {
			surface_free(paint_surface);
			paint_surface = -1;
		};

		// 断开这条线持有的谱面、父链和缓存引用；共享资源由谱面管理器释放。
		_father_chain = [];
		events = [];
		extEvents = undefined;
		events_count = [];
		events_hold = [];
		events_recall = [];
		rpe_speed_events = [];
		rpe_event_routes = [];
		ext_count = undefined;
		ext_hold = undefined;
		ext_recall = undefined;
		_control_alpha = undefined;
		_control_pos = undefined;
		_control_size = undefined;
		_control_y = undefined;
		_control_skew = undefined;
		gif_data = undefined;
		_text_layout_rows = [];
		line_text = "";
	};

	actor_create();
}

function RPENote(_object, _x, _y, _depth, _fields)
	: ChartActor(_object, _x, _y, _depth, _fields) constructor {
	static rpe_sample_control = function(control_index, note_pos_speed, default_value = 1) {
		var control = rpe_controls[control_index];
		// 控制点不足两个时无法插值。
		if (!is_struct(control) || real(control.length) < 2) then return default_value;
		var n = real(control.length);
		var positions = control.positions;
		var values = control.values;
		var easings = control.easings;
		// 落在首点之前用首值，越过末点用默认值。
		if (note_pos_speed <= real(positions[0])) {
			rpe_control_cursors[@ control_index] = 0;
			return real(values[0]);
		};
		if (note_pos_speed > real(positions[n - 1])) {
			rpe_control_cursors[@ control_index] = n - 2;
			return default_value;
		};
		var i = clamp(rpe_control_cursors[control_index], 0, n - 2);
		// 游标向两侧走到包住当前速度的区间。
		while (i > 0 && note_pos_speed <= real(positions[i])) i--;
		while (i < n - 2 && real(positions[i + 1]) < note_pos_speed) i++;
		rpe_control_cursors[@ control_index] = i;
		return tween_execute(note_pos_speed, real(positions[i]), real(positions[i + 1]),
			real(values[i]), real(values[i + 1]), real(easings[i]));
	};

	static rpe_note_apply_visibility = function() {
		// 判定线没了就直接藏掉。
		if (!chart_actor_exists(_line_ref)) {
			canDraw = false;
			image_alpha = 0;
			return false;
		};

		var note_a = alpha;
		if (chart_actor_var_exists(id, "isMiss") && isMiss) then note_a *= 0.5;
		// 速度 0 的 Hold 曾经被导出成透明。头碰到判定线前保持可见，Other_12 到点再藏。
		var speed_zero_hold = _is_hold && abs(note_speed) <= 0.0000001 && hold_length_floor > 0.0000001;
		if (note_a <= 0) {
			// 普通透明音符直接不画；速度 0 的 Hold 除外。
			if (!speed_zero_hold) {
				canDraw = false;
				image_alpha = 0;
				return false;
			};
			note_a = 1;
		};

		var sec_to_hit = start_sec - _now_seconds;
		var sec_to_hit_real = sec_to_hit * _line_time_factor;
		var time_before = (sec_to_hit > 0);
		// visibleTime 是相对音符头的有符号实时阈值。负值会让短 Hold 在开始后继续隐藏。
		if (is_finite(visibleTime) && visibleTime < 999999 && sec_to_hit_real > visibleTime) {
			canDraw = false;
			image_alpha = 0;
			return false;
		};

		var adec = 255;
		if (chart_actor_var_exists(_line_ref, "_alpha_decimal")) then adec = real(_line_ref._alpha_decimal);
		else if (chart_actor_var_exists(_line_ref, "__raw_a")) then adec = real(_line_ref.__raw_a);

		var uncover = chart_actor_var_exists(_line_ref, "_uncover") ? bool(_line_ref._uncover) : false;
		var alpha_extra = 0;
		if (time_before) {
			if (adec >= 0 && (_is_out_line || uncover)) then alpha_extra = 1;
		} else if (adec >= 0) {
			alpha_extra = 1;
		};

		// 判定线透明度不允许露出时不画。
		if (!alpha_extra) {
			canDraw = false;
			image_alpha = 0;
			return false;
		};

		var final_a = note_a * rpe_sample_control(0, _control_position_speed, 1);
		// 控制曲线把透明度压到 0 也不画。
		if (final_a <= 0) {
			canDraw = false;
			image_alpha = 0;
			return false;
		};

		image_alpha = final_a;
		return true;
	};

	// 迁移前事件：objects/oNote_1/Create_0.gml；完整原文件见 docs/constructor-migration/legacy/rpe/。
	static actor_create = function() {
		///@desc 初始化 RPE 音符的地板、控制和空间索引
		depth = DEPTH.NOTE;
		inition = false;
		canDraw = false;
		if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then visible = false;

		// CreateLines 没写入的字段用默认值补齐。
		if (!chart_actor_var_exists(id, "type")) then type = 1;
		if (!chart_actor_var_exists(id, "rpe_type")) then rpe_type = type;
		if (!chart_actor_var_exists(id, "isAbove")) then isAbove = true;
		if (!chart_actor_var_exists(id, "alpha")) then alpha = 1;
		if (!chart_actor_var_exists(id, "start_beat")) then start_beat = 0;
		if (!chart_actor_var_exists(id, "end_beat")) then end_beat = start_beat;
		if (!chart_actor_var_exists(id, "start_sec")) then start_sec = game_1.Math.beatToAbsSec(start_beat);
		if (!chart_actor_var_exists(id, "end_sec")) then end_sec = game_1.Math.beatToAbsSec(end_beat);
		if (!chart_actor_var_exists(id, "hold_beat")) then hold_beat = max(0, end_beat - start_beat);
		if (!chart_actor_var_exists(id, "xOffset")) then xOffset = 0;
		if (!chart_actor_var_exists(id, "yOffset")) then yOffset = 0;
		if (!chart_actor_var_exists(id, "yorigin")) then yorigin = real(yOffset) / 900;
		if (!chart_actor_var_exists(id, "floorPosition")) then floorPosition = 0;
		if (!chart_actor_var_exists(id, "endFloorPosition")) then endFloorPosition = floorPosition;
		if (!chart_actor_var_exists(id, "holdFloorLength")) then holdFloorLength = endFloorPosition - floorPosition;
		if (!chart_actor_var_exists(id, "size")) then size = 1;
		if (!chart_actor_var_exists(id, "note_speed")) then note_speed = 1;
		if (!chart_actor_var_exists(id, "note_layer_bias")) then note_layer_bias = 0;
		if (!chart_actor_var_exists(id, "visibleTime")) then visibleTime = 999999;
		if (!chart_actor_var_exists(id, "isFake")) then isFake = false;
		if (!chart_actor_var_exists(id, "note_tint")) then note_tint = c_white;
		if (!chart_actor_var_exists(id, "has_hit_tint")) then has_hit_tint = false;
		if (!chart_actor_var_exists(id, "hit_tint")) then hit_tint = c_white;
		if (!chart_actor_var_exists(id, "hit_effect_z")) then hit_effect_z = 7;
		if (!chart_actor_var_exists(id, "line_id")) then line_id = 0;
		if (!chart_actor_var_exists(id, "compactHold")) then compactHold = false;
		if (!chart_actor_var_exists(id, "custom_sound")) then custom_sound = -1;
		if (!chart_actor_var_exists(id, "custom_fmod_sound")) then custom_fmod_sound = -1;
		if (!chart_actor_var_exists(id, "custom_hitsound_path")) then custom_hitsound_path = "";

		type = real(type);
		start_beat = real(start_beat);
		end_beat = real(end_beat);
		start_sec = real(start_sec);
		end_sec = real(end_sec);
		hold_beat = real(hold_beat);
		xOffset = real(xOffset);
		yOffset = real(yOffset);
		yorigin = real(yorigin);
		floorPosition = real(floorPosition);
		endFloorPosition = real(endFloorPosition);
		holdFloorLength = real(holdFloorLength);
		if (holdFloorLength == 0) then holdFloorLength = (endFloorPosition - floorPosition);
		hold_length_floor = holdFloorLength;
		size = real(size);
		// 谱面倍率在 note_speed。此时读内置 speed 还是 0，创建结构还没写入 hspeed。
		note_speed = real(note_speed);
		if (!is_finite(note_speed)) then note_speed = 1;
		speed = 0;
		direction = 0;
		visibleTime = real(visibleTime);
		alpha = clamp(real(alpha), 0, 1);
		isAbove = bool(isAbove);
		isFake = bool(isFake);
		is_real_note = !isFake;
		has_hit_tint = bool(has_hit_tint);
		compactHold = bool(compactHold);
		_debug_text_x = 0;
		_debug_text_y = 0;

		_is_hold = (type == 3);
		_step_user_count = (_is_hold ? 2 : 1);
		_judge_user_count = (_is_hold ? 6 : 5);

		// 绑定到 RPE 判定线，线不存在就销毁。
		if (!variable_global_exists("game_1") || !is_struct(game_1) || !is_array(game_1.line_list)
			|| line_id < 0 || line_id >= array_length(game_1.line_list)) {
			show_debug_message($"[oNote_1] invalid line_id={line_id}");
			chart_actor_destroy();
			exit;
		};
		_line_ref = game_1.line_list[line_id];
		if (!chart_actor_exists(_line_ref)) {
			show_debug_message($"[oNote_1] missing line instance id={line_id}");
			chart_actor_destroy();
			exit;
		};

		var _line_factor = (chart_actor_var_exists(_line_ref, "bpmfactor") ? real(_line_ref.bpmfactor) : 1);
		if (!is_real(_line_factor) || _line_factor <= 0) then _line_factor = 1;
		_line_time_factor = _line_factor;
		_preload_seconds = (variable_global_exists("game") && is_struct(game)
			? real(game.settings.notePreloadSeconds ?? 0) / _line_factor
			: 0);
		_max_visible_floor_distance = 12;
		_last_global_scales = -1;
		_last_note_size = -1;
		_now_seconds = 0;
		_now_beat = 0;
		_line_time = 0;

		var _mvp = floorPosition + 0.01;
		var _mvl = _mvp;
		if (variable_global_exists("game") && is_struct(game) && is_struct(game.Math) && struct_exists(game.Math, "maxVisiblePos")) {
			_mvp = game.Math.maxVisiblePos(floorPosition);
			if (_is_hold) {
				if (hold_length_floor > 0) then _mvl = game.Math.maxVisiblePos(floorPosition + hold_length_floor);
				else _mvl = _mvp;
			};
		} else if (_is_hold && hold_length_floor > 0) {
			_mvl = floorPosition + hold_length_floor + 0.01;
		};
		maximum_visual_position = _mvp;
		maximum_visual_length = _mvl;
		_is_out = true;
		_is_out_line = true;
		_position_floor_delta = 0;
		_note_position_speed = 0;
		_control_position_speed = 0;
		_note_skew_degrees = 0;
		rpe_skip_pass_fade = (abs(real(alpha) - 1) > 0.001);
		if (!rpe_skip_pass_fade && chart_actor_exists(_line_ref)) {
			rpe_skip_pass_fade = !rpe_alpha_control_is_identity(_line_ref.alphaControl);
		};
		_ox_v = 0;
		_oy_v = 0;
		outside = false;
		__first__ = false;

		// 休眠音符索引：非 Hold 按有效地板分组做视口二分，Hold 用区间重叠查询。
		if (variable_global_exists("game_1") && is_struct(game_1)
			&& struct_exists(game_1, "_note_activation_records")) {
			var _spatial_record = {
				id:id,
				line:_line_ref,
				startSec:start_sec,
				endSec:end_sec,
				yOrigin:yorigin,
				visibleTime:visibleTime,
				timeFactor:_line_time_factor,
				speed:note_speed,
				alpha:alpha,
				above:isAbove,
				activated:false,
				spatialSafe:true,
				spatialFloor:floorPosition,
				endSpatialFloor:endFloorPosition
			};
			if (chart_actor_var_exists(_line_ref, "_control_y") && is_struct(_line_ref._control_y)) {
				var _spatial_y_values = _line_ref._control_y.values;
				// Y 控制不是恒定 1 时，空间查询不再安全。
				for (var _spatial_yi = 0; _spatial_yi < array_length(_spatial_y_values); _spatial_yi++) {
					if (real(_spatial_y_values[_spatial_yi]) != 1) {
						_spatial_record.spatialSafe = false;
						break;
					};
				};
			};
			// 倾斜可能把中心在视口外的音符拉回画面，不能只按中心查询休眠音符。
			if (!_is_hold && is_struct(_line_ref._control_skew)) {
				var skew_values = _line_ref._control_skew.values;
				for (var si = 0; si < array_length(skew_values); si++) {
					if (real(skew_values[si]) == 0) then continue;
					_spatial_record.spatialSafe = false;
					break;
				};
			};
			game_1._note_activation_records[$ chart_actor_key(id)] = _spatial_record;
			// 可见且速度非 0 才进入空间分组。
			if (visibleTime > 0 && note_speed != 0) {
				if (_is_hold) {
					var _hold_group_key = string(line_id) + ":" + string(isAbove)
						+ ":" + string(note_speed) + ":" + string(yorigin);
					var _hold_first = game_1._note_spatial_hold_group_map[$ _hold_group_key];
					var _hold_group = rpe_note_group_find(_hold_first, note_speed, yorigin);
					if (!is_struct(_hold_group)) {
						_hold_group = {
							line:_line_ref, above:isAbove, speed:note_speed, yOrigin:yorigin,
							spatialSafe:_spatial_record.spatialSafe, notes:[], count:0, nextWithKey:_hold_first
						};
						game_1._note_spatial_hold_group_map[$ _hold_group_key] = _hold_group;
						array_add(game_1._note_spatial_hold_groups, _hold_group);
					};
					array_add(_hold_group.notes, _spatial_record);
				} else {
					_spatial_record.spatialFloor += yOffset / (540 * note_speed);
					_spatial_record.endSpatialFloor += yOffset / (540 * note_speed);
					var _group_key = string(line_id) + ":" + string(isAbove) + ":" + string(note_speed);
					var _spatial_first = game_1._note_spatial_group_map[$ _group_key];
					var _spatial_group = rpe_note_group_find(_spatial_first, note_speed);
					if (!is_struct(_spatial_group)) {
						_spatial_group = { line:_line_ref, speed:note_speed, above:isAbove,
							spatialSafe:_spatial_record.spatialSafe, notes:[], nextWithKey:_spatial_first };
						game_1._note_spatial_group_map[$ _group_key] = _spatial_group;
						array_add(game_1._note_spatial_groups, _spatial_group);
					};
					array_add(_spatial_group.notes, _spatial_record);
				};
			};
		};

		rpe_controls = [_line_ref._control_alpha, _line_ref._control_pos, _line_ref._control_size, _line_ref._control_y, _line_ref._control_skew];
		rpe_control_cursors = [0, 0, 0, 0, 0];
		///@desc 按音符位置速度采样一条 RPE 控制曲线
		///@param {Real} control_index 控制下标：0 透明，1 位置，2 大小，3 Y，4 倾斜
		///@param {Real} note_pos_speed 采样用的位置速度
		///@param {Real} default_value 越过末点时返回的默认值
		///@returns {Real} 插值后的控制值


		///@desc 按透明度、可见时间和判定线遮罩决定能否绘制
		///@returns {Bool} 本帧是否应该绘制


		hitTime2 = 0;
		chart_actor_user(0);
		if (!bool(game.settings.noteUniformScale ?? false)) then image_yscale = (global_scales / 6) * game.settings.noteSize;
		image_blend = note_tint;
		if (audio_exists(custom_sound) && custom_sound != snd_note_tap && custom_sound != snd_note_drag && custom_sound != snd_note_flick) then sound = custom_sound;
		lateHitTime = 0.25;
		judgeBeat = start_beat;
		judgeTime = start_sec;
		judgeRealTime = 0;
		chart_kb_register_note();
	};

	// 迁移前事件：objects/oNote_1/Step_0.gml；完整原文件见 docs/constructor-migration/legacy/rpe/。
	static actor_step = function() {
		///@desc 推进 RPE 音符时间、裁剪、位移和自动判定
		if (!inition) then exit;
		if (variable_global_exists("loading_animation_active") && global.loading_animation_active) then exit;
		if (variable_global_exists("game") && is_struct(game) && game.paused) then exit;
		// 判定线不在就停止绘制。
		if (!chart_actor_exists(_line_ref)) { canDraw = false; exit; };

		// 绑定的判定线自带本地时钟，含 bpmfactor 和累计偏移。
		_now_seconds = (chart_actor_var_exists(_line_ref, "line_sec") ? _line_ref.line_sec : 0);

		_line_time = (chart_actor_var_exists(_line_ref, "line_time") ? _line_ref.line_time : 0);

		// 判定窗口用秒，多 BPM 谱面才不会用错单位。
		var late_ms = _is_hold ? 161 : ((type == 2 || type == 4) ? 160 : 201);
		lateHitTime = late_ms * 0.001;
		if (chart_autoplay_active()) judgeTime = start_sec + hitTime2 * 0.001;

		// 窗口缩放变了才刷新尺寸。
		if (_last_global_scales != global_scales || _last_note_size != game.settings.noteSize) {
			chart_actor_user(7);
			_last_global_scales = global_scales;
			_last_note_size = game.settings.noteSize;
		};

		// Bad 淡出结束后停用。
		if (isBad) {
			if (_now_seconds - judgeRealTime >= 1) then chart_actor_deactivate(self);
			exit;
		};

		// 预加载窗口外按地板距离提前裁掉。
		if (_preload_seconds > 0) {
			var sec_to_hit = start_sec - _now_seconds;
			if (sec_to_hit > _preload_seconds) {
				var line_floor_pre = real(_line_ref.__value[0]);
				// 判定线还没进入最远可见窗口时，远处音符不画。
				if (line_floor_pre + _max_visible_floor_distance < floorPosition
					&& line_floor_pre < maximum_visual_position - _max_visible_floor_distance) {
					canDraw = false;
					exit;
				};
			};
		};

		// 假音符即使未判定，过了结束时间也要清掉。
		if (isFake) {
			if (_is_hold) {
				if (_now_seconds >= end_sec) {
					canDraw = false;
					chart_actor_deactivate(self);
					exit;
				};
			} else if (_now_seconds >= start_sec) {
				canDraw = false;
				chart_actor_deactivate(self);
				exit;
			};
		};

		// 世界姿态在 Step End 才完整；绘制前统一更新外观，击中坐标由判定分支按需刷新。

		// 真音符走和官谱相同的自动判定。
		if (!isFake) then chart_actor_user(_judge_user_count);
	};

	// 迁移前事件：objects/oNote_1/Draw_0.gml；完整原文件见 docs/constructor-migration/legacy/rpe/。
	static actor_draw = function() {
		///@desc 在谱面遮罩内绘制 RPE 音符或 Hold
		chart_mask_scissor_set();
		if (!canDraw) then exit;

		var _clip_line = noone;
		if (chart_actor_var_exists(id, "_line_ref")) then _clip_line = _line_ref;
		var _clip = chart_note_scale_clip_begin(_clip_line);

		var _sprite = sprite_index;
		var _frame = hl;
		var _xscale = image_xscale;
		var _yscale = image_yscale;
		var _angle = image_angle;
		var _blend = image_blend;
		var _alpha = image_alpha;
		var _skew_world = undefined;
		if (!_is_hold && _note_skew_degrees != 0 && _yscale != 0) {
			// 与 Rex SkewImage 一样，把局部 Y 乘 tan(skewX) 后加到局部 X。
			// 先变换现有世界坐标，再保留调用者矩阵；零倾斜不分配矩阵。
			var _shear = dtan(_note_skew_degrees) * _xscale / _yscale;
			if (is_finite(_shear)) {
				var _skew_angle = isBad ? _bad_angle : _angle;
				var _skew_x = isBad ? _bad_x : x;
				var _skew_y = isBad ? _bad_y : y;
				var _c = dcos(_skew_angle);
				var _s = dsin(_skew_angle);
				var _matrix = matrix_build_identity();
				_matrix[0] = 1 + _shear * _c * _s;
				_matrix[1] = -_shear * _s * _s;
				_matrix[4] = _shear * _c * _c;
				_matrix[5] = 1 - _shear * _s * _c;
				_matrix[12] = _skew_x - _matrix[0] * _skew_x - _matrix[4] * _skew_y;
				_matrix[13] = _skew_y - _matrix[1] * _skew_x - _matrix[5] * _skew_y;
				_skew_world = matrix_get(matrix_world);
				matrix_set(matrix_world, matrix_multiply(_matrix, _skew_world));
			};
		};
		if (!_is_hold && !isBad && !rpe_skip_pass_fade) {
			_alpha *= chart_note_pass_fade(_now_seconds, start_sec, chart_note_miss_window_sec(type, false));
		};

		// 皮肤和默认贴图分开画，Hold 再按是否击中选择头尾。
		if (skin_active()) {
			var _skin_kind = (type == 2 ? "drag" : (type == 4 ? "flick" : "tap"));
			var _skin_spr = skin_note_sprite(_skin_kind, isBad ? 0 : _frame);
			var _skin_hold = _is_hold ? skin_hold_parts(_frame) : undefined;
			var sk = sprite_exists(_skin_spr) ? skin_note_scale_k(_skin_spr) : 1;
			var hk = (is_struct(_skin_hold) && sprite_exists(_skin_hold.head)) ? skin_note_scale_k(_skin_hold.head) : 1;
			if (!_is_hold) {
				if (isBad) {
					var a = ((1 - (_now_seconds - judgeRealTime)) * 0.5);
					if (sprite_exists(_skin_spr)) then draw_sprite_ext(_skin_spr, 0, _bad_x, _bad_y, _xscale * sk, _yscale * sk, _bad_angle, c_red, a);
					else draw_sprite_ext(_sprite, 2, _bad_x, _bad_y, _xscale, _yscale, _bad_angle, c_red, a);
				} else if (sprite_exists(_skin_spr)) {
					draw_sprite_ext(_skin_spr, 0, x, y, _xscale * sk, _yscale * sk, _angle, _blend, _alpha);
				} else {
					draw_sprite_ext(_sprite, _frame, x, y, _xscale, _yscale, _angle, _blend, _alpha);
				};
			} else {
				var a = (isMiss ? 0.5 : _alpha);
				var _use_compact = compactHold || (is_struct(_skin_hold) && bool(_skin_hold.compact));
				var _keep_head = is_struct(_skin_hold) && bool(_skin_hold.keep_head);
				var _tail_trim = (_use_compact ? _yscale * (_hold_tail_height * 0.5) : 0);
				if (is_struct(_skin_hold)) {
					draw_hold_fit(_hx0, _hy0, _xscale * hk, _yscale * hk, yscale,
						_angle, 0, _blend, a, _is_out || _keep_head, _is_out && !_use_compact, _tail_trim * hk, 1,
						_skin_hold.head, _skin_hold.body, _skin_hold.tail);
				} else {
					draw_hold_fit(_hx0, _hy0, _xscale, _yscale, yscale,
						_angle, _frame, _blend, a, _is_out, _is_out && !compactHold, _tail_trim);
				};
			};
		} else if (!_is_hold) {
			if (isBad) {
				var a = ((1 - (_now_seconds - judgeRealTime)) * 0.5);
				draw_sprite_ext(_sprite, 2, _bad_x, _bad_y, _xscale, _yscale, _bad_angle, c_red, a);
			} else {
				draw_sprite_ext(_sprite, _frame, x, y, _xscale, _yscale, _angle, _blend, _alpha);
			};
		} else {
			var a = (isMiss ? 0.5 : _alpha);
			var _tail_trim = (compactHold ? _yscale * (_hold_tail_height * 0.5) : 0);
			draw_hold_fit(_hx0, _hy0, _xscale, _yscale, yscale,
				_angle, _frame, _blend, a, _is_out, _is_out && !compactHold, _tail_trim);
		};

		if (is_array(_skew_world)) then matrix_set(matrix_world, _skew_world);
		chart_note_scale_clip_end(_clip);
	};

	// 迁移前事件：objects/oNote_1/Other_10.gml；完整原文件见 docs/constructor-migration/legacy/rpe/。
	static user_0 = function() {
		///@desc 按类型初始化 RPE 音符贴图、Hold 几何和判定偏移
		if (inition) then exit;

		// 类型已在 CreateLines 映射成官谱兼容编号。
		switch (type) {
			case 1:
				depth = DEPTH.NOTE + 1;
				sprite_index = note_tap;
				sound = skin_note_sound("tap", snd_note_tap);
				break;
			case 2:
				depth = DEPTH.NOTE + 2;
				sprite_index = note_drag;
				sound = skin_note_sound("drag", snd_note_drag);
				break;
			case 3:
				depth = DEPTH.NOTE + 3;
				sound = skin_note_sound("tap", snd_note_tap);
				sprite_index = note_hold_head;
				_hx0 = 0; _hy0 = 0;
				_hx1 = 0; _hy1 = 0;
				_hx2 = 0; _hy2 = 0;
				_hold_body_height = max(1, sprite_get_height(note_hold_body));
				_hold_tail_height = max(1, sprite_get_height(note_hold_end));
				_hold_head_attach = max(1, sprite_get_yoffset(note_hold_head));
				isHold = false;
				notJudge = true;
				isMiss = false;
				_bak_time = 0;
				__first__ = false; // PCR：头已判定并贴上判定线
				break;
			case 4:
				depth = DEPTH.NOTE;
				sprite_index = note_flick;
				sound = skin_note_sound("flick", snd_note_flick);
				break;
			default:
				depth = DEPTH.NOTE + 1;
				sprite_index = note_tap;
				sound = skin_note_sound("tap", snd_note_tap);
				break;
		};

		// 非 Hold 也要有这些判定和绘制标记。
		isHold = false;
		notJudge = true;
		isMiss = false;
		isBad = false;
		_bad_x = 0;
		_bad_y = 0;
		_bad_angle = 0;
		_note_x = 0;
		_note_y = 0;
		_x_h = 0;
		_y_h = 0;
		isJudge = false;
		hit_status = TYPE.NONE;

		var initial_scale = (variable_global_exists("global_scales") ? global_scales : 1.0);
		image_xscale = (initial_scale / 6) * size * game.settings.noteSize;
		image_yscale = image_xscale;
		_last_global_scales = initial_scale;
		_last_note_size = game.settings.noteSize;
		image_alpha = alpha;
		image_blend = c_white;

		// Hold 视觉长度用地板单位。
		if (_is_hold) {
			if (hold_length_floor == 0 && endFloorPosition != floorPosition) {
				hold_length_floor = endFloorPosition - floorPosition;
				holdFloorLength = hold_length_floor;
			};
			yscale = 0;
		};

		hl = 0;
		if (variable_global_exists("BYD_COLOR_MODE") && BYD_COLOR_MODE && type != 3) then hl = 2;
		if (chart_actor_var_exists(id, "_hl") && is_real(_hl)) then hl = _hl;
		if (_is_hold) {
			var _skin_hold = skin_hold_parts(hl);
			if (is_struct(_skin_hold)) {
				if (sprite_exists(_skin_hold.body)) then _hold_body_height = max(1, sprite_get_height(_skin_hold.body));
				if (sprite_exists(_skin_hold.tail)) then _hold_tail_height = max(1, sprite_get_height(_skin_hold.tail));
				if (sprite_exists(_skin_hold.head)) then _hold_head_attach = max(1, sprite_get_yoffset(_skin_hold.head));
			};
		};

		hitTime2 = chart_auto_hit_offset_ms(type);

		if (variable_global_exists("chart_layer_mode") && global.chart_layer_mode
			&& chart_actor_var_exists(id, "note_layer_z") && is_real(note_layer_z)) {
			depth = chart_layer_depth(note_layer_z) - note_layer_bias;
		};

		inition = true;
	};

	// 迁移前事件：objects/oNote_1/Other_11.gml；完整原文件见 docs/constructor-migration/legacy/rpe/。
	static user_1 = function() {
		///@desc 更新非 Hold 的 RPE 音符位置和屏幕外裁剪
		if (_is_hold || !inition) then exit;
		var _line = _line_ref;
		if (!chart_actor_exists(_line)) { canDraw = false; exit; };

		var line_floor = real(_line.__value[0]);
		_position_floor_delta = floorPosition - line_floor;
		// 采样坐标与 170 之前的播放器相同：音符速度乘地板差。
		_note_position_speed = note_speed * _position_floor_delta;
		_control_position_speed = _note_position_speed;

			var notes_w = chart_view_width * 0.05625;
			var notes_h = chart_view_height * 0.6;
		var posx = (xOffset / 75.375) * notes_w;
		if (chart_actor_var_exists(_line, "__incline_sin")) {
			var incline_y = _note_position_speed + (2 * yOffset / 900 * note_speed);
			posx *= 1 - real(_line.__incline_sin) * incline_y * 1.25;
		};
			var posy = (yorigin * chart_view_height) + (_note_position_speed * notes_h);
		posx *= rpe_sample_control(1, _control_position_speed, 1);
		posy *= rpe_sample_control(3, _control_position_speed, 1);
		var control_size = rpe_sample_control(2, _control_position_speed, 1);
		// PhiZone 的 skewControl 是绕音符中心的水平剪切，单位为角度。
		_note_skew_degrees = -xOffset * rpe_sample_control(4, _control_position_speed, 0);
		var _settings = game.settings;
		var note_scale = (global_scales / 6) * _settings.noteSize;
		image_xscale = note_scale * size * control_size;
		var uniform_scale = bool(_settings.noteUniformScale ?? false);
		image_yscale = uniform_scale ? image_xscale : note_scale;

		var reversed = (isAbove ? -1 : 1);
		var c = _line.__cos;
		var s = _line.__sin;
		_ox_v = s * reversed;
		_oy_v = c * reversed;

		_x_h = _line.x + c * posx;
		_y_h = _line.y - s * posx;
		_note_x = _x_h;
		_note_y = _y_h;

		x = _x_h + _ox_v * posy;
		y = _y_h + _oy_v * posy;

		// 调试用的文字锚点。
		_debug_text_x = x//_x_h + _ox_v * posy;
		_debug_text_y = ((_y_h + (50 * (global_scales))) + _oy_v * posy);

		image_angle = _line.image_angle + (isAbove ? 0 : 180);

		var uncover = bool(_line._uncover);
		if (_now_seconds < start_sec) {
			// isCover 用有符号距离挡住完全在判定线后的音符。
			_is_out_line = uncover || _note_position_speed >= -0.000001;
		} else {
			_is_out_line = true;
		};

		var sWH = room_width * 0.5;
		var sHH = room_height * 0.5;
		var dx = x - sWH;
		var dy = y - sHH;
		var radius = sWH * 1.2365 + sHH;
		var radius_sq = radius * radius;
		outside = (_note_skew_degrees == 0 && (dx * dx + dy * dy) >= radius_sq);

		// 已判定或 Bad 仍要画淡出；飞出屏幕则不画。
		if (isJudge || isBad) {
			canDraw = true;
			if (!isBad) then image_alpha = alpha;
			exit;
		};
		if (outside) {
			canDraw = false;
			exit;
		};
		if (!rpe_note_apply_visibility()) then exit;
		canDraw = true;
	};

	// 迁移前事件：objects/oNote_1/Other_12.gml；完整原文件见 docs/constructor-migration/legacy/rpe/。
	static user_2 = function() {
		///@desc 更新 RPE Hold 的头、身体和尾部几何
		if (!_is_hold || !inition) then exit;
		var _line = _line_ref;
		if (!chart_actor_exists(_line)) { canDraw = false; exit; };

		var line_floor = real(_line.__value[0]);
		var time_before = (_now_seconds < start_sec);
		_position_floor_delta = floorPosition - line_floor;
		// 谱面速度 0 只是标记。头碰到判定线前仍按 1 倍下落。
		var chart_speed = note_speed;
		var visual_speed = chart_speed;
		if (abs(chart_speed) <= 0.0000001) then visual_speed = 1;
		_control_position_speed = visual_speed * _position_floor_delta;
		// 击中前已经越过判定线就立刻隐藏。速度 0 的 Hold 之后保持隐藏。
		if (time_before && _position_floor_delta * visual_speed <= -0.001) {
			canDraw = false;
			image_alpha = 0;
			exit;
		};
		if (abs(chart_speed) <= 0.0000001 && _position_floor_delta <= 0.001) {
			canDraw = false;
			image_alpha = 0;
			exit;
		};

		if (time_before) {
			// 击中前头和身体都在速度缩放后的地板空间里。
			_note_position_speed = _control_position_speed;
		} else {
			_note_position_speed = 0;
			isHold = true;
		};

		// 头是否露出、身体是否钉住，看谱面时间而不是判定状态。
		_is_out = time_before;
		if (time_before) {
			var uncover = bool(_line._uncover);
			// 击中前按预先算好的尾部可见边界遮罩。
			_is_out_line = uncover || line_floor <= maximum_visual_length;
		} else {
			_is_out_line = true;
		};

			var scene_w = chart_view_width;
			var scene_h = chart_view_height;
		var notes_w = scene_w * 0.05625;
		var notes_h = scene_h * 0.6;
		var posx = (xOffset / 75.375) * notes_w;
		var posy = (yorigin * scene_h) + (_note_position_speed * notes_h);
		posx *= rpe_sample_control(1, _control_position_speed, 1);
		var control_y = rpe_sample_control(3, _control_position_speed, 1);
		posy *= control_y;
		var control_size = rpe_sample_control(2, _control_position_speed, 1);
		var _settings = game.settings;
		var note_scale = (global_scales / 6) * _settings.noteSize;
		image_xscale = note_scale * size * control_size;
		var uniform_factor = bool(_settings.noteUniformScale ?? false) ? size * control_size : 1;
		image_yscale = note_scale * uniform_factor;

		var reversed = (isAbove ? -1 : 1);
		var line_x = _line.x;
		var line_y = _line.y;
		var c = _line.__cos;
		var s = _line.__sin;
		_ox_v = s * reversed;
		_oy_v = c * reversed;

		_x_h = line_x + c * posx;
		_y_h = line_y - s * posx;
		_note_x = _x_h;
		_note_y = _y_h;
		x = _x_h + _ox_v * posy;
		y = _y_h + _oy_v * posy;
		_hx0 = x;
		_hy0 = y;

		_debug_text_x = x//_x_h + _ox_v * posy;
		_debug_text_y = ((_y_h + (50 * (global_scales))) + _oy_v * posy);

		var length_floor = hold_length_floor;
		if (length_floor == 0) then length_floor = (endFloorPosition - floorPosition);
		// 身体长度用同一套速度、Y 控制和地板差。
		var base_length = notes_h * visual_speed * control_y * uniform_factor;

		var _skin_hold = skin_active() ? skin_hold_parts(hl) : undefined;
		var _use_compact = compactHold || (is_struct(_skin_hold) && bool(_skin_hold.compact));
		var _hold_skin_scale = 1;
		if (is_struct(_skin_hold)) {
			if (sprite_exists(_skin_hold.body)) then _hold_body_height = max(1, sprite_get_height(_skin_hold.body));
			if (sprite_exists(_skin_hold.tail)) then _hold_tail_height = max(1, sprite_get_height(_skin_hold.tail));
			if (sprite_exists(_skin_hold.head)) then _hold_head_attach = max(1, sprite_get_yoffset(_skin_hold.head));
			_hold_skin_scale = skin_note_scale_k(_skin_hold.head);
		};
		var head_offset = 0;
		if (_is_out && (!_use_compact)) {
			head_offset = _hold_head_attach * image_yscale * _hold_skin_scale;
		};

		var hold_units = (time_before ? length_floor : endFloorPosition - line_floor);
		var signed_hold_px = base_length * hold_units;
		// 用户放大头部时也不能把短 Hold 的尾端推过实际终点。
		head_offset = min(head_offset, max(0, signed_hold_px));
		var hold_px = max(0, signed_hold_px - head_offset);
		if (!chart_actor_var_exists(id, "_hold_body_height") || _hold_body_height <= 0) {
			_hold_body_height = max(1, sprite_get_height(note_hold_body));
		};
		if (!chart_actor_var_exists(id, "_hold_tail_height") || _hold_tail_height <= 0) {
			_hold_tail_height = max(1, sprite_get_height(note_hold_end));
		};
		yscale = hold_px / max(1, _hold_body_height);

		var tail_trim = (_use_compact ? image_yscale * _hold_skin_scale * (_hold_tail_height * 0.5) : 0);
		var tail_offset = max(head_offset, head_offset + hold_px - tail_trim);
		var body_ox = _ox_v;
		var body_oy = _oy_v;
		_hx1 = x + body_ox * head_offset;
		_hy1 = y + body_oy * head_offset;
		_hx2 = x + body_ox * tail_offset;
		_hy2 = y + body_oy * tail_offset;
		image_angle = _line.image_angle + (isAbove ? 0 : 180);

		var sWH = scene_w * 0.5;
		var sHH = scene_h * 0.5;
		var dx = x - sWH;
		var dy = y - sHH;
		var dyn_r = sWH * 1.2365 + sHH + note_speed * max(0, _note_position_speed) * notes_h;
		var dyn_r_sq = dyn_r * dyn_r;
		outside = ((dx * dx + dy * dy) >= dyn_r_sq);
		// 飞出动态半径且朝向屏幕外才丢掉。
		if (outside) {
			var dot = dx * (_x_h - sWH) + dy * (_y_h - sHH);
			if (dot <= 0) {
				canDraw = false;
				exit;
			};
		};
		// 尾部不可见且身体已经缩没就停止绘制。
		if (!(_is_out_line && (hold_px > 0.5 || _is_out || _now_seconds < end_sec))) {
			canDraw = false;
			exit;
		};
		if (!rpe_note_apply_visibility()) then exit;
		canDraw = true;
	};

	// 迁移前事件：objects/oNote_1/Other_15.gml；完整原文件见 docs/constructor-migration/legacy/rpe/。
	static user_5 = function() {
		///@desc 自动判定非 Hold 的 RPE 音符
		if (_is_hold || !inition || isFake) then exit;

		var now_time = _now_seconds;
		var now_hit = judgeTime;

		// 非自动播放只处理超时 Miss。
		if (!chart_autoplay_active()) then exit;

		if (now_time > start_sec + lateHitTime && !isBad && !isJudge && !game.settings.enableAccJudgment) {
			if (is_real_note) {
				judgeCalc(start_sec, now_time, 0, _note_x, _note_y, type, false, true, true);
			};
			chart_actor_deactivate(self);
			exit;
		};

		// Drag 和 Flick 到点即判并停用。
		if ((type == 2 || type == 4) && !isJudge && now_time >= start_sec
			&& now_hit >= start_sec && now_hit <= start_sec + lateHitTime) {
			if (is_real_note) {
				var _hit_xy = rpe_note_hit_effect_xy();
				hit_status = judgeCalc(start_sec, now_hit, 0, _hit_xy[0], _hit_xy[1], type, true, true, true, has_hit_tint ? hit_tint : undefined);
				skin_play_note_hitsound();
			};
			isJudge = true;
			judgeRealTime = _now_seconds;
			//print($"type={type} time={string_format(start_beat , 0 , 10)} lineID={line_id} line_xy=[{_line_ref.x} , {_line_ref.y}] note_xy=[{x} , {y}] above={isAbove}")
			chart_actor_deactivate(self);
			exit;
		};

		if (now_time >= now_hit) {
			if (!isJudge && hit_status == TYPE.NONE && type == 1) {
				if (is_real_note) {
					var _tap_xy = rpe_note_hit_effect_xy();
					hit_status = judgeCalc(start_sec, now_hit, 0, _tap_xy[0], _tap_xy[1], type, true, true, true, has_hit_tint ? hit_tint : undefined);
					if (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT) then skin_play_note_hitsound();
				};
				isJudge = true;
				judgeRealTime = _now_seconds;
				if (hit_status == TYPE.BAD) {
					isBad = true;
					_bad_x = x;
					_bad_y = y;
					_bad_angle = image_angle;
				} else {
					chart_actor_deactivate(self);
				};
			} else if (hit_status == TYPE.BAD && type == 1) {
				isBad = true;
				if (image_alpha <= 0) then chart_actor_deactivate(self);
			} else if (hit_status != TYPE.NONE && isJudge) {
				chart_actor_deactivate(self);
			};
		};
	};

	// 迁移前事件：objects/oNote_1/Other_16.gml；完整原文件见 docs/constructor-migration/legacy/rpe/。
	static user_6 = function() {
		///@desc 自动判定 RPE Hold，并按 BPM 刷新尾迹
		if (!_is_hold || !inition || isFake) then exit;

		var now_time = _now_seconds;
		var now_hit = judgeTime;
		// 手动判定统一在渲染器 Step End 处理。
		if (!chart_autoplay_active()) then exit;
		var bpm_use = game_1.Math.bpmAtAbsSec(_now_seconds);

		// 自动播放在击中时刻判定 Hold 头。
		if (now_time >= now_hit && !isMiss && notJudge && hit_status == TYPE.NONE) {
			if (is_real_note) {
				var _hold_xy = rpe_note_hit_effect_xy();
				hit_status = judgeCalc(start_sec, now_hit, 0, _hold_xy[0], _hold_xy[1], type, true, false, true, has_hit_tint ? hit_tint : undefined);
				if (hit_status == TYPE.MISS && !isMiss) {
					isMiss = true;
					judgeCalc(start_sec, now_hit, 0, _hold_xy[0], _hold_xy[1], type, true, true, true);
				} else {
					_bak_time = _now_seconds;
					skin_play_note_hitsound();
				};
			};
			notJudge = false;
			isHold = true;
			__first__ = true;
			judgeRealTime = _now_seconds;
		};

		if (now_time > start_sec + lateHitTime && !isMiss && notJudge) {
			if (is_real_note) {
				hit_status = judgeCalc(start_sec, now_time, 0, _hx0, _hy0, type, false, true, true);
			};
			notJudge = false;
			isMiss = true;
			__first__ = true;
			isHold = true;
		};

		if (now_time >= start_sec) {
			if (!isHold) then isHold = true;
			if (!__first__ && !notJudge) then __first__ = true;

			if (!notJudge && !isMiss && (hit_status == TYPE.GOOD || hit_status == TYPE.PREFECT)) {
				if (_now_seconds - _bak_time >= (60 / max(1, bpm_use)) / 2) {
					var _tick_xy = rpe_note_hit_effect_xy();
					if (variable_global_exists("_eff_c")) then _eff_c(_tick_xy[0], _tick_xy[1], has_hit_tint ? hit_tint : (hit_status == TYPE.PREFECT ? #ffeca0 : make_colour_rgb(162, 238, 255)), undefined, hit_effect_z);
					_bak_time = _now_seconds;
				};
			};

			if (now_time >= end_sec) {
				if (is_real_note) {
					hit_status = judgeCalc(start_sec, now_hit, 0, _hx0, _hy0, type, false, !isMiss, true);
				};
				chart_actor_deactivate(self);
			};
		};
	};

	// 迁移前事件：objects/oNote_1/Other_17.gml；完整原文件见 docs/constructor-migration/legacy/rpe/。
	static user_7 = function() {
		///@desc 窗口缩放变化后刷新 RPE 音符缩放
		var note_scale = (global_scales / 6) * game.settings.noteSize;
		image_xscale = note_scale * size;
		image_yscale = bool(game.settings.noteUniformScale ?? false) ? image_xscale : note_scale;
	};

	static actor_cleanup = function() {
		// 先由管理器清空判定/空间/激活索引，再释放实体的引用。
		_line_ref = noone;
		rpe_controls = [];
		rpe_control_cursors = [];
		kb_record = undefined;
	};

	actor_create();
}

