/// @description RPE judge line (PCR-aligned preprocess)
// Coordinate/runtime model references com.teammio.pcr:
// - rpec_parser.gml (event layer conversion)
// - CCEvents.gml / CCLEExecute (event cursor + tween)
// - notes/rpe_parse CoordinateSystemConversion + speed integrals

// depth applied after zOrder/line_id resolve
_father_chain = [];
sprite_index = line;
image_blend = c_white;
image_alpha = 1;
image_angle = 0;

if (!variable_instance_exists(id, "line_id")) then line_id = 0;
if (!variable_instance_exists(id, "events")) then events = [];
if (!variable_instance_exists(id, "extEvents")) then extEvents = {};
if (!variable_instance_exists(id, "isFather")) then isFather = -1;
if (!variable_instance_exists(id, "rotFatherLine")) then rotFatherLine = false;
if (!variable_instance_exists(id, "image")) then image = "line.png";
if (!variable_instance_exists(id, "line_csv_scale")) then line_csv_scale = 1;
if (!variable_instance_exists(id, "anchor")) then anchor = [0.5, 0.5];
if (!variable_instance_exists(id, "bpmfactor")) then bpmfactor = 1;
if (!variable_instance_exists(id, "isCover") || is_undefined(isCover)) then isCover = true;
if (!variable_instance_exists(id, "alphaControl")) then alphaControl = [];
if (!variable_instance_exists(id, "sizeControl")) then sizeControl = [];
if (!variable_instance_exists(id, "posControl")) then posControl = [];
if (!variable_instance_exists(id, "yControl")) then yControl = [];
if (!variable_instance_exists(id, "bindUI")) then bindUI = 0;
if (!variable_instance_exists(id, "attachUI")) then attachUI = bindUI;
if (!is_real(isFather)) then isFather = -1;
if (!is_bool(rotFatherLine) && !is_real(rotFatherLine)) then rotFatherLine = false;
rotFatherLine = bool(rotFatherLine);
if (!is_real(bpmfactor) || bpmfactor <= 0) then bpmfactor = 1;
anchor_x = 0.5;
anchor_y = 0.5;
if (is_array(anchor) && array_length(anchor) >= 2) {
	anchor_x = real(anchor[0]);
	anchor_y = real(anchor[1]);
};
if (!is_finite(anchor_x)) then anchor_x = 0.5;
if (!is_finite(anchor_y)) then anchor_y = 0.5;
has_paint_events = (image == "line.png" && is_struct(extEvents) && struct_exists(extEvents, "paintEvents"));
has_gif_events = (image != "line.png" && is_struct(extEvents) && struct_exists(extEvents, "gifEvents"));
has_scale_x_events = false;
has_scale_y_events = false;
has_incline_events = false;
gif_event_index = 0;
rpe_world_query = false;
rpe_world_applied = false;
paint_surface = -1;
paint_has_content = false;
paint_last_valid = false;
paint_last_x = 0;
paint_last_y = 0;
paint_last_radius = 0;
paint_last_time = -infinity;

// attachUI (PCR 1.2.1-Public): pause / combonumber / combo / score / bar / name / level
// Only known keys bind HUD; bound lines stay fully transparent (not drawn).
attachUI = (is_undefined(attachUI) ? bindUI : attachUI);
bindUI = (is_undefined(bindUI) ? attachUI : bindUI);
attach_ui_key = "";
is_attach_ui = false;
var _aui_raw = attachUI;
if (is_string(_aui_raw)) {
        var _aui_key = string_lower(string_replace_all(_aui_raw, " ", ""));
        // match RPE.attachUI_Group without "default"
        var _attach_ui_keys = ["pause", "combonumber", "combo", "score", "bar", "name", "level"];
        if (array_get_index(_attach_ui_keys, _aui_key) >= 0) {
                attach_ui_key = _aui_key;
                is_attach_ui = true;
        };
};
if (is_attach_ui) {
        image_alpha = 0;
};

// RPE.CreateLines assigns the final depth after sorting by zOrder and line_id.
if (!variable_instance_exists(id, "zOrder") || !is_real(zOrder)) then zOrder = 0;
zOrder = real(zOrder);
if (!is_finite(zOrder)) then zOrder = 0;
z = zOrder; // PCR alias
depth = DEPTH.LINE;

// RPE chart easingType values (1..28) -> EASE_TYPE / tween_execute index.
// PCR rpec_parser.parseEasingType uses array_get_index(table, rpeType), so table values are RPE ids
// and the returned index is the internal ease id. We do the same reverse lookup here.
//
// RPE: 1 Linear, 2 OutSine, 3 InSine, 4 OutQuad, 5 InQuad, 6 InOutSine, 7 InOutQuad,
// 8 OutCubic, 9 InCubic, 10 OutQuart, 11 InQuart, 12 InOutCubic, 13 InOutQuart,
// 14 OutQuint, 15 InQuint, 16 OutExpo, 17 InExpo, 18 OutCirc, 19 InCirc,
// 20 OutBack, 21 InBack, 22 InOutCirc, 23 InOutBack, 24 OutElastic, 25 InElastic,
// 26 OutBounce, 27 InBounce, 28 InOutBounce (29 InOutElastic unused)
_easing_map = [ 0, 1, 3, 2, 6, 5, 4, 7, 9, 8, 12, 11, 10, 13, 15, 14, -1, 17, 16, -1, 19, 18, 22, 21, 20, 23, 25, 24, -1, 27, 26, 28 ];

is_default_line = (image == "line.png");
line_image = line;
gif_data = undefined;
if (has_gif_events && is_string(image) && string_length(image)) {
	if (!struct_exists(game_1, "Gif") || !is_struct(game_1.Gif)) then game_1.Gif = {};
	var gif_cache_valid = false;
	if (struct_exists(game_1.Gif, image)) {
		var cached_gif = game_1.Gif[$ image];
		gif_cache_valid = is_struct(cached_gif)
			&& is_array(cached_gif.frames) && array_length(cached_gif.frames) > 0
			&& is_array(cached_gif.delays)
			&& array_length(cached_gif.delays) == array_length(cached_gif.frames)
			&& real(cached_gif.total) > 0;
		if (gif_cache_valid) {
			for (var gif_cache_i = 0; gif_cache_i < array_length(cached_gif.frames); gif_cache_i++) {
				if (!sprite_exists(cached_gif.frames[gif_cache_i])) {
					gif_cache_valid = false;
					break;
				};
			};
		};
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
		var gif_last_sprite = sprite_add_gif(chart_file_readable_path(InChartPath + image), 0, 0, gif_frame_delays_raw, gif_frame_sprites);
		if (array_length(gif_frame_sprites) <= 0 && sprite_exists(gif_last_sprite)) then array_add(gif_frame_sprites, gif_last_sprite);
		var gif_frame_delays = [];
		var gif_total_time = 0;
		for (var gif_load_i = 0; gif_load_i < array_length(gif_frame_sprites); gif_load_i++) {
			var gif_frame_sprite = gif_frame_sprites[gif_load_i];
			if (sprite_exists(gif_frame_sprite)) {
				sprite_set_offset(gif_frame_sprite, sprite_get_width(gif_frame_sprite) * 0.5, sprite_get_height(gif_frame_sprite) * 0.5);
			};
			var gif_delay_seconds = 0.01;
			if (gif_load_i < array_length(gif_frame_delays_raw)) then gif_delay_seconds = max(0.01, real(gif_frame_delays_raw[gif_load_i]) * 0.01);
			array_add(gif_frame_delays, gif_delay_seconds);
			gif_total_time += gif_delay_seconds;
		};
		game_1.Gif[$ image] = {
			frames: gif_frame_sprites,
			delays: gif_frame_delays,
			total: gif_total_time
		};
	};
	gif_data = game_1.Gif[$ image];
	if (is_struct(gif_data) && is_array(gif_data.frames) && array_length(gif_data.frames) > 0
		&& sprite_exists(gif_data.frames[0])) then line_image = gif_data.frames[0];
} else if (is_string(image) && string_length(image) && image != "line.png") {
		var tex_path = chart_file_readable_path(InChartPath + image);
        if (file_exists(tex_path) || chart_file_exists_any(InChartPath + image)) {
                if (variable_global_exists("game_1") && is_struct(game_1)) {
                        if (!struct_exists(game_1, "Texture") || !is_struct(game_1.Texture)) then game_1.Texture = {};
                        if (!struct_exists(game_1.Texture, image) || !sprite_exists(game_1.Texture[$ image])) {
					var spr = sprite_add(tex_path, 0, false, false, 0, 0);
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
};
sprite_index = line_image;
image_speed = 0;

// Per-layer cursor maps
events_count = [];
events_hold = [];
events_recall = [];
rpe_speed_events = [];
speed_event_index = 0;

// Instance-bound sorter so nested methods can resolve it (local var is not captured).
rpe_sort_events = function(a, b) {
        if (a.startTime < b.startTime) then return -1;
        if (a.startTime > b.startTime) then return 1;
        if (a.endTime < b.endTime) then return -1;
        if (a.endTime > b.endTime) then return 1;
        return 0;
};

// Bound once on the instance (avoid redefining every Step)
rpe_map_easing = function(raw) {
        // PCR-style reverse lookup: find RPE easingType inside the table, return its index.
        // Invalid / unused slots (null/-1) fall back to LINEAR (1).
        var t = floor(real(raw ?? 1));
        if (!is_real(t)) then return 1;
        if (t <= 1) then return 1;

        var m = -1;
        var n = array_length(_easing_map);
        for (var i = 0; i < n; i++) {
                var v = _easing_map[i];
                if (is_real(v) && v == t) {
                        m = i;
                        break;
                };
        };
        if (!is_real(m) || m < 0) then return 1;
        if (m <= 1) then return 1;
        // tween_execute dense sample table covers 2..31
        if (m >= 32) then return 1;
        return m;
};

rpe_prep_event_array = function(arr, is_speed) {
        if (!is_array(arr)) then return [];

        // PCR truncationEvent keeps source order and resolves overlap before layers merge.
        if (is_speed) {
                var truncated = [];
                for (var si = 0; si < array_length(arr); si++) {
                        var src = arr[si];
                        if (!is_struct(src)) then continue;
                        var st = game_1.Math.arrToBeat(src[$ "startTime"] ?? 0);
                        var et = game_1.Math.arrToBeat(src[$ "endTime"] ?? st);
                        var sv = real(src[$ "start"] ?? 0);
                        var end_value = real(src[$ "end"] ?? sv);
                        var delta = (et > st ? (end_value - sv) / (et - st) : 0);
                        var speed_easing = rpe_map_easing(src[$ "easingType"] ?? 1);
                        var speed_easing_left = real(src[$ "easingLeft"] ?? 0);
                        var speed_easing_right = real(src[$ "easingRight"] ?? 1);
                        if (!is_finite(speed_easing_left) || !is_finite(speed_easing_right)) {
                                speed_easing_left = 0;
                                speed_easing_right = 1;
                        };
                        speed_easing_left = clamp(speed_easing_left, 0, 1);
                        speed_easing_right = clamp(speed_easing_right, 0, 1);
                        if (speed_easing_left == speed_easing_right) {
                                speed_easing_left = 0;
                                speed_easing_right = 1;
                        };

                        for (var ti = array_length(truncated) - 1; ti >= 0; ti--) {
                                var old = truncated[ti];
                                var old_end = old.endTime;
                                var old_stop = old.stop;
                                if (old_end < st) {
                                         array_set(truncated, ti + 1, {
                                                 startTime: old_end, endTime: st,
                                                 start: old_stop, stop: old_stop, delta: 0,
                                                 easingType:1, easingLeft:0, easingRight:1
                                         });
                                        break;
                                };
                                var old_start = old.startTime;
                                if (old_start == st) {
                                        array_resize(truncated, ti);
                                        break;
                                };
                                if (old_start < st) {
                                        var old_value = old.start;
                                        var duration = st - old_start;
                                        var old_duration = old.endTime - old_start;
                                        var old_easing_left = real(old[$ "easingLeft"] ?? 0);
                                        var old_easing_right = real(old[$ "easingRight"] ?? 1);
                                        var cut_progress = (old_duration > 0 ? duration / old_duration : 1);
                                        old.stop = tween_execute(st, old_start, old.endTime, old_value, old.stop,
                                                real(old[$ "easingType"] ?? 1), old_easing_left, old_easing_right);
                                        old.endTime = st;
                                        old.delta = (old.stop - old_value) / duration;
                                        old.easingRight = lerp(old_easing_left, old_easing_right, cut_progress);
                                        array_resize(truncated, ti + 1);
                                        break;
                                };
                        };

                        if (st >= et) {
                                array_add(truncated, { startTime: st, endTime: st, start: end_value, stop: end_value, delta: 0, easingType:1, easingLeft:0, easingRight:1 });
                        } else {
                                array_add(truncated, {
                                        startTime:st, endTime:et, start:sv, stop:end_value, delta:delta,
                                        easingType:speed_easing, easingLeft:speed_easing_left, easingRight:speed_easing_right
                                });
                        };
                };
                array_sort(truncated, function(a, b) {
                        if (a.startTime < b.startTime) then return -1;
                        if (a.startTime > b.startTime) then return 1;
                        if (a.endTime < b.endTime) then return -1;
                        if (a.endTime > b.endTime) then return 1;
                        return 0;
                });
                return truncated;
        };

        for (var i = 0; i < array_length(arr); i++) {
                var ev = arr[i];
                if (!is_struct(ev)) then continue;

                if (struct_exists(ev, "startTime")) then ev.startTime = game_1.Math.beatToAbsSec(game_1.Math.arrToBeat(ev.startTime));
                if (struct_exists(ev, "endTime")) then ev.endTime = game_1.Math.beatToAbsSec(game_1.Math.arrToBeat(ev.endTime));

                var el = ev[$ "easingLeft"] ?? 0;
                var er = ev[$ "easingRight"] ?? 1;
                if ((el == er) || (el < 0) || (el > 1) || (er < 0) || (er > 1)) {
                        el = 0; er = 1;
                };
                ev.easingLeft = el;
                ev.easingRight = er;
                ev.easingType = rpe_map_easing(ev[$ "easingType"] ?? 1);
                if (!struct_exists(ev, "bezier")) then ev.bezier = 0;
                if (!struct_exists(ev, "bezierPoints")) then ev.bezierPoints = [0, 0, 0, 0];

                if (!struct_exists(ev, "start")) then ev.start = 0;
                if (!struct_exists(ev, "end")) then ev[$ "end"] = ev.start;
        };
        array_sort(arr, rpe_sort_events);
        return arr;
};

// Evaluate one event channel at line_time (CCLEExecute-like cursor)
rpe_eval_events = function(layer_index, event_name, default_value) {
        var arr = events[layer_index][$ event_name];
        if (!is_array(arr)) then return default_value;
        var n = array_length(arr);
        if (n <= 0) then return default_value;

        var cmap = events_count[layer_index];
        var hmap = events_hold[layer_index];
        var rmap = events_recall[layer_index];
        var idx = clamp(real(cmap[$ event_name] ?? 0), 0, n);

        if (idx >= n) {
                if (line_time >= arr[n - 1].endTime) then return arr[n - 1][$ "end"];
                idx = n - 1;
        };

        while ((idx > 0) && (line_time < arr[idx].startTime)) {
                idx--;
        };

        while ((idx < n) && (arr[idx].endTime <= line_time)) {
                hmap[$ event_name] = arr[idx][$ "end"];
                idx++;
        };
        cmap[$ event_name] = idx;

        if (idx >= n) {
                return hmap[$ event_name];
        };

        var ev = arr[idx];
        var st = ev.startTime;
        var et = ev.endTime;

        if (line_time < st) {
                if (idx > 0) then return arr[idx - 1][$ "end"];
                return ev.start;
        };

        var v0 = ev.start;
        var v1 = ev[$ "end"];
        if (st == et || v0 == v1) then return v1;

        var ease = real(ev.easingType ?? 1);
        if (!is_real(ease) || ease <= 1 || ease >= 32) then ease = 1;
        var e0 = real(ev.easingLeft ?? 0);
        var e1 = real(ev.easingRight ?? 1);
        if (e0 == e1) {
                e0 = 0;
                e1 = 1;
        };
        var tval;

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

        if (!is_finite(tval)) {
                tval = rmap[$ event_name];
        } else {
                rmap[$ event_name] = tval;
        };
        return tval;
};

// Linear speed segment: floor += elapsed * (v0 + v(t)) / 2 (Phira RPE < 170).
rpe_event_floor_at = function(ev, t) {
        var elapsed = max(0, real(t) - real(ev.startTime));
        var v0 = real(ev.value);
        var v1 = real(ev[$ "endValue"] ?? v0);
        var duration = real(ev.endTime) - real(ev.startTime);
        if (!is_finite(duration) || duration <= 0) {
                return real(ev.floorPosition) + elapsed * v0;
        };
        var u = min(1, elapsed / duration);
        var vt = v0 + (v1 - v0) * u;
        return real(ev.floorPosition) + elapsed * (v0 + vt) * 0.5;
};

// Runtime uses the merged linear-speed table produced by the PCR parser chain.
rpe_speed_floor = function() {
        if (!is_array(rpe_speed_events) || array_length(rpe_speed_events) <= 0) then return 0;
        var t = (variable_instance_exists(id, "line_sec") ? line_sec : 0);
        if (t < rpe_speed_events[0].startTime) then return 0;
        var n = array_length(rpe_speed_events);
        var idx = clamp(speed_event_index, 0, n - 1);
        while (idx > 0 && t < rpe_speed_events[idx].startTime) idx--;
        while (idx < n - 1 && t > rpe_speed_events[idx].endTime) idx++;
        speed_event_index = idx;
        return rpe_event_floor_at(rpe_speed_events[idx], t);
};

// ---- extended (special) events: single channel, not multi-layer ----
rpe_event_progress = function(ev, st, et) {
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
        return clamp(tween_execute(line_time, st, et, 0, 1, ease, e0, e1), 0, 1);
};

rpe_eval_ext_events = function(event_name, default_value) {
         var arr = extEvents[$ event_name];
        if (!is_array(arr)) then return default_value;
        var n = array_length(arr);
        if (n <= 0) then return default_value;

        var idx = clamp(real(ext_count[$ event_name] ?? 0), 0, n);

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
        if (!is_finite(tval)) {
                tval = ext_recall[$ event_name];
        } else {
                ext_recall[$ event_name] = tval;
        };
        return tval;
};

rpe_eval_color_events = function(default_value) {
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

rpe_eval_text_events = function(default_value) {
		line_text_font = (!is_undefined(game.font) && font_exists(game.font)) ? game.font : -1;
		if (!is_struct(extEvents)) then return default_value;
		if (!struct_exists(extEvents, "textEvents")) then return default_value;
		var arr = extEvents[$ "textEvents"];
		if (!is_array(arr) || array_length(arr) <= 0) then return default_value;

		var select_font = function(text_event) {
			if (!is_struct(text_event)) then return;
			var font_name = string(text_event[$ "font"] ?? "cmdysj");
			if (!string_length(font_name) || string_lower(font_name) == "cmdysj") then return;
			if (struct_exists(game_1, "Fonts") && is_struct(game_1.Fonts)
				&& struct_exists(game_1.Fonts, font_name)) {
				var selected_font = game_1.Fonts[$ font_name];
				if (selected_font != -1 && font_exists(selected_font)) then line_text_font = selected_font;
			};
		};

        var event_name = "textEvents";
        if (!struct_exists(ext_count, event_name)) then ext_count[$ event_name] = 0;
        if (!struct_exists(ext_hold, event_name)) then ext_hold[$ event_name] = default_value;
        if (!struct_exists(ext_recall, event_name)) then ext_recall[$ event_name] = default_value;

		var n = array_length(arr);
		var idx = clamp(ext_count[$ event_name], 0, n);
		if (idx >= n) {
				if (line_time >= arr[n - 1].endTime) {
						select_font(arr[n - 1]);
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
				select_font(arr[n - 1]);
				return ext_hold[$ event_name];
		};

        var ev = arr[idx];
        var st = ev.startTime;
        var et = ev.endTime;
		var v0 = string(ev.start);
		var v1 = string(ev[$ "end"]);
		if (line_time < st) {
				if (idx > 0) {
						select_font(arr[idx - 1]);
						return string(arr[idx - 1][$ "end"]);
				};
				return string(default_value);
		};
		select_font(ev);
		if (st == et || v0 == v1) then return v1;

        var p = rpe_event_progress(ev, st, et);
        var out_text = v0;
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
if (!is_array(events)) then events = [];
var _clean_layers = [];
for (var li = 0; li < array_length(events); li++) {
        if (is_struct(events[li])) {
                // RPE permits omitted channels. Materialize the canonical
                // channels before creating cursors so every layer has a
                // stable runtime shape from its first Step.
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

// PCR fittingEvents: linear sample per layer, then toSpeedEvents (1/32).
rpe_speed_layer_value = function(layer, beat, use_left_limit) {
        if (!is_array(layer) || array_length(layer) <= 0) then return 0;
        var result = real(layer[0][$ "start"] ?? 0);
        for (var i = 0; i < array_length(layer); i++) {
                var ev = layer[i];
                if (beat < ev.startTime) then break;
                if (use_left_limit && beat == ev.startTime) then break;
                if (beat >= ev.endTime) then result = real(ev.stop);
                else {
                        var span = ev.endTime - ev.startTime;
                        if (span <= 0) then result = real(ev.stop);
                        else result = real(ev.start) + (beat - ev.startTime) * ((real(ev.stop) - real(ev.start)) / span);
                };
        };
        return result;
};

var speed_layers = [];
var speed_splits = [];
for (var sli = 0; sli < array_length(events); sli++) {
        var speed_layer = (struct_exists(events[sli], "speedEvents") ? events[sli][$ "speedEvents"] : []);
        if (!is_array(speed_layer) || array_length(speed_layer) <= 0) then continue;
        array_add(speed_layers, speed_layer);
        for (var sei = 0; sei < array_length(speed_layer); sei++) {
                array_add(speed_splits, speed_layer[sei].startTime);
                array_add(speed_splits, speed_layer[sei].endTime);
        };
};
array_sort(speed_splits, function(a, b) {
        if (a < b) then return -1;
        if (a > b) then return 1;
        return 0;
});

var fitted_speed = [];
for (var ssi = 0; ssi < array_length(speed_splits) - 1; ssi++) {
        var split_start = speed_splits[ssi];
        var split_end = speed_splits[ssi + 1];
        if (split_start == split_end) then continue;
        var value_start = 0;
        var value_end = 0;
        for (var sli2 = 0; sli2 < array_length(speed_layers); sli2++) {
                value_start += rpe_speed_layer_value(speed_layers[sli2], split_start, false);
                value_end += rpe_speed_layer_value(speed_layers[sli2], split_end, true);
        };
        array_add(fitted_speed, {
                startTime: split_start, endTime: split_end,
                start: value_start, stop: value_end
        });
};

// Trapezoid of linear speed (Phira RPE < 170). 1/32 constant slices bias
// oscillating holds whose speed crosses 0, which shows up as a wrong hold_length.
rpe_speed_events = [];
var speed_floor = 0;
var fitted_count = array_length(fitted_speed);
for (var fsi = 0; fsi < fitted_count; fsi++) {
        var fitted = fitted_speed[fsi];
        var sample_start_sec = game_1.Math.beatToAbsSec(fitted.startTime);
        if (!is_finite(sample_start_sec)) then continue;
        var sample_end_sec = game_1.Math.beatToAbsSec(fitted.endTime);
        if (fsi < fitted_count - 1) {
                var next_start_sec = game_1.Math.beatToAbsSec(fitted_speed[fsi + 1].startTime);
                if (is_finite(next_start_sec) && next_start_sec > sample_start_sec) {
                        sample_end_sec = next_start_sec;
                };
        };
        if (!is_finite(sample_end_sec) || sample_end_sec <= sample_start_sec) then continue;
        var v0 = real(fitted.start) / 4.5;
        var v1 = real(fitted.stop) / 4.5;
        array_add(rpe_speed_events, {
                startTime: sample_start_sec,
                endTime: sample_end_sec,
                value: v0,
                endValue: v1,
                floorPosition: speed_floor
        });
        speed_floor += (sample_end_sec - sample_start_sec) * (v0 + v1) * 0.5;
};
if (array_length(rpe_speed_events) > 0) {
        var last_speed_ev = rpe_speed_events[array_length(rpe_speed_events) - 1];
        var last_end_value = real(last_speed_ev.endValue);
        if (is_finite(last_speed_ev.endTime)) {
                array_add(rpe_speed_events, {
                        startTime: last_speed_ev.endTime,
                        endTime: infinity,
                        value: last_end_value,
                        endValue: last_end_value,
                        floorPosition: speed_floor
                });
        };
};
speed_event_index = 0;

if (!is_struct(extEvents)) then extEvents = {};
ext_count = {};
ext_hold = {};
ext_recall = {};
has_text_events = false;
has_color_events = false;
has_scale_events = false;
has_scale_x_events = false;
has_scale_y_events = false;
has_incline_events = false;

// Special prep for extended channels (PCR rpec_parser semantics)
var enames = struct_get_names(extEvents);
for (var ei = 0; ei < array_length(enames); ei++) {
        var en = enames[ei];
        var raw_arr = extEvents[$ en];
        if (!is_array(raw_arr)) {
                extEvents[$ en] = [];
                continue;
        };

        if (en == "colorEvents") {
                has_color_events = (array_length(raw_arr) > 0);
                for (var ci = 0; ci < array_length(raw_arr); ci++) {
                        var cev = raw_arr[ci];
                        if (!is_struct(cev)) then continue;
                        if (struct_exists(cev, "startTime")) then cev.startTime = game_1.Math.beatToAbsSec(game_1.Math.arrToBeat(cev.startTime));
                        if (struct_exists(cev, "endTime")) then cev.endTime = game_1.Math.beatToAbsSec(game_1.Math.arrToBeat(cev.endTime));
                        var el = cev[$ "easingLeft"] ?? 0;
                        var er = cev[$ "easingRight"] ?? 1;
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

        // numeric channels: scaleX/scaleY/paint (and any other)
        extEvents[$ en] = rpe_prep_event_array(raw_arr, false);
        var narr = extEvents[$ en];
        var narr_n = (is_array(narr) ? array_length(narr) : 0);
        if (en == "scaleXEvents") {
                has_scale_x_events = (narr_n > 0);
                if (has_scale_x_events) then has_scale_events = true;
        } else if (en == "scaleYEvents") {
                has_scale_y_events = (narr_n > 0);
                if (has_scale_y_events) then has_scale_events = true;
        } else if (en == "inclineEvents") {
                has_incline_events = (narr_n > 0);
        };
        if (narr_n > 0) {
                ext_count[$ en] = 0;
                ext_hold[$ en] = real(narr[0].start ?? 0);
                ext_recall[$ en] = real(narr[0].start ?? 0);
        };
};

// PCR calcFloorPosition over the same merged table used by runtime.
rpe_floor_at_sec = function(sec) {
        if (!is_array(rpe_speed_events) || array_length(rpe_speed_events) <= 0) then return 0;
        if (sec < rpe_speed_events[0].startTime) then return 0;
        var n = array_length(rpe_speed_events);
        var idx = 0;
        while (idx < n - 1 && sec > rpe_speed_events[idx].endTime) idx++;
        return rpe_event_floor_at(rpe_speed_events[idx], sec);
};

rpe_floor_at_beat = function(beat) {
        return rpe_floor_at_sec(game_1.Math.beatToAbsSec(beat));
};
// ---- PCR isCover / note controls ----
// isCover=false => unCover notes (notes remain visible past the line)
isCover = (is_bool(isCover) ? isCover : (real(isCover) != 0));
_uncover = !isCover;
_alpha_decimal = 255;
rpe_prepare_control = function(raw, value_name) {
	var result = { positions: [], values: [], easings: [], length: 0 };
	if (!is_array(raw)) then return result;
	var entries = [];
	for (var ci = 0; ci < array_length(raw); ci++) {
		var ce = raw[ci];
		if (!is_struct(ce)) then continue;
		var control_position = real(ce[$ "x"] ?? 0) / 540;
		var control_value = real(ce[$ value_name] ?? 1);
		if (!is_finite(control_position)) then continue;
		if (!is_finite(control_value)) then control_value = 1;
		array_add(entries, {
			position:control_position,
			value:control_value,
			easing:rpe_map_easing(ce[$ "easing"] ?? 1)
		});
	};
	array_sort(entries, function(a, b) {
		if (a.position < b.position) then return -1;
		if (a.position > b.position) then return 1;
		return 0;
	});
	for (var entry_i = 0; entry_i < array_length(entries); entry_i++) {
		var existing_count = array_length(result.positions);
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
_control_alpha = rpe_prepare_control(alphaControl, "alpha");
_control_pos = rpe_prepare_control(posControl, "pos");
_control_size = rpe_prepare_control(sizeControl, "size");
_control_y = rpe_prepare_control(yControl, "y");

// Runtime state
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
        // line sprite stays hidden; real alpha is evaluated in Step and written to HUD
        image_alpha = 0;
};
