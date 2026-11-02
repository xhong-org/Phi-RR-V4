/// Constructor actors own gameplay state; only depth groups remain room instances.
function ChartActor(_object, _x, _y, _depth, _fields) constructor {
    object_index = _object;
    x = _x; y = _y; depth = _depth;
    sprite_index = -1; image_index = 0; image_speed = 1;
    image_xscale = 1; image_yscale = 1; image_angle = 0;
    image_blend = c_white; image_alpha = 1; visible = true;
    speed = 0; direction = 0;
    active = true; disposed = false;
    actor_bucket = undefined; actor_group = undefined;
    actor_slot = -1; actor_draw_slot = -1; actor_all_slot = -1;
    var runtime = chart_actors_state();
    uid = runtime.next_uid++;
    id = self;
    if (is_struct(_fields)) {
        var names = struct_get_names(_fields);
        for (var i = 0; i < array_length(names); i++) self[$ names[i]] = _fields[$ names[i]];
    }
    static actor_create = function() {};
    static actor_begin = function() {};
    static actor_step = function() {};
    static actor_end = function() {};
    static actor_draw = function() {};
    static actor_cleanup = function() {};
    static user_0 = function() {};
    static user_1 = function() {};
    static user_2 = function() {};
    static user_3 = function() {};
    static user_4 = function() {};
    static user_5 = function() {};
    static user_6 = function() {};
    static user_7 = function() {};
    static user_8 = function() {};
}

function chart_actor_object(_object) {
    return _object == oLine || _object == oLine_1 || _object == oLine_2
        || _object == oNote || _object == oNote_1 || _object == oNote_2;
}

function chart_actors_state() {
    if (!variable_global_exists("chart_actors") || !is_struct(global.chart_actors)) {
        global.chart_actors = {
            next_uid:1, buckets:{}, groups:{}, group_list:[], running:false,
            disposed:false, ticks:0, update_us:0, visible:true,
            lines_ready:false, draw_boundaries:[]
        };
    }
    return global.chart_actors;
}

function chart_actor_bucket(_object, _create = true) {
    if (!_create && (!variable_global_exists("chart_actors") || !is_struct(global.chart_actors))) return undefined;
    var runtime = chart_actors_state();
    var key = string(_object);
    if (!struct_exists(runtime.buckets, key)) {
        if (!_create) return undefined;
        runtime.buckets[$ key] = {all:[], live:[], object:_object};
    }
    return runtime.buckets[$ key];
}

/// The list is stable through a session, including sleeping notes used by retry.
function chart_actor_list(_object, _active_only = true) {
    var bucket = chart_actor_bucket(_object, false);
    if (!is_struct(bucket)) return [];
    return _active_only ? bucket.live : bucket.all;
}

function chart_actor_alive(_actor) {
    return is_struct(_actor) && struct_exists(_actor, "disposed") && !_actor.disposed;
}

function chart_actor_exists(_target) {
    if (is_struct(_target)) return chart_actor_alive(_target) && _target.active;
    if (chart_actor_object(_target)) return chart_actor_number(_target) > 0;
    return instance_exists(_target);
}

function chart_actor_var_exists(_target, _name) {
    if (is_struct(_target)) return struct_exists(_target, _name);
    return variable_instance_exists(_target, _name);
}
function chart_actor_var_get(_target, _name) {
    if (is_struct(_target)) return _target[$ _name];
    return variable_instance_get(_target, _name);
}
function chart_actor_var_set(_target, _name, _value) {
    if (is_struct(_target)) _target[$ _name] = _value;
    else variable_instance_set(_target, _name, _value);
}
function chart_actor_key(_target) {
    return is_struct(_target) ? string(_target.uid) : string(_target);
}
function chart_actor_number(_object) {
    if (chart_actor_object(_object)) {
        var bucket = chart_actor_bucket(_object, false);
        return is_struct(bucket) ? array_length(bucket.live) : 0;
    }
    return instance_number(_object);
}
function chart_actor_find(_object, _index) {
    if (!chart_actor_object(_object)) return instance_find(_object, _index);
    var actors = chart_actor_list(_object);
    return (_index >= 0 && _index < array_length(actors)) ? actors[_index] : noone;
}

function chart_actor_group(_depth) {
    var runtime = chart_actors_state();
    // One bridge per interval between native draws, rather than one Object per
    // note's fractional depth. Exact actor depths are sorted within the interval.
    var bounds = runtime.draw_boundaries;
    var epsilon = math_get_epsilon();
    math_set_epsilon(0);
    var lo = 0, hi = array_length(bounds);
    while (lo < hi) {
        var mid = (lo + hi) div 2;
        if (_depth > bounds[mid]) hi = mid; else lo = mid + 1;
    }
    math_set_epsilon(epsilon);
    var key = string(lo);
    if (!struct_exists(runtime.groups, key)) {
        // A boundary-equal actor belongs after that native draw. Put the bridge
        // strictly inside its interval so native creation order cannot move the
        // entire group across the boundary. Actors retain their actual depths.
        var count = array_length(bounds);
        var bridge_depth = _depth;
        if (count > 0) {
            if (lo == 0) bridge_depth = bounds[0] + max(1, abs(bounds[0]) * 0.000000001);
            else if (lo == count) bridge_depth = bounds[count - 1] - max(1, abs(bounds[count - 1]) * 0.000000001);
            else bridge_depth = bounds[lo - 1] + (bounds[lo] - bounds[lo - 1]) * 0.5;
        }
        var group = {depth:bridge_depth, actors:[], bridge:noone, dirty:false};
        runtime.groups[$ key] = group;
        array_push(runtime.group_list, group);
        group.bridge = instance_create_depth(0, 0, bridge_depth, oChartActorDraw, {actor_group:group});
    }
    return runtime.groups[$ key];
}

/// Draw Begin: preserve interleaving with native UI, videos and range captures.
/// Rebuild only when those external depth boundaries change.
function chart_actors_draw_prepare() {
    if (!variable_global_exists("chart_actors") || !is_struct(global.chart_actors)) return;
    var runtime = global.chart_actors;
    if (runtime.disposed) return;
    var bounds = [];
    for (var i = 0; i < instance_count; i++) {
        var native = instance_id[i];
        if (native.object_index != oChartActorDraw) array_push(bounds, native.depth);
    }
    var epsilon = math_get_epsilon();
    math_set_epsilon(0);
    array_sort(bounds, function(a, b) { return sign(b - a); });
    var unique = [];
    for (var i = 0; i < array_length(bounds); i++)
        if (i == 0 || bounds[i] != bounds[i - 1]) array_push(unique, bounds[i]);
    bounds = unique;
    var old = runtime.draw_boundaries;
    var changed = array_length(old) != array_length(bounds);
    for (var i = 0; i < array_length(bounds) && !changed; i++) changed = bounds[i] != old[i];
    math_set_epsilon(epsilon);
    if (!changed) return;
    for (var i = 0; i < array_length(runtime.group_list); i++) {
        var group = runtime.group_list[i];
        group.actors = [];
        if (instance_exists(group.bridge)) instance_destroy(group.bridge);
    }
    runtime.groups = {}; runtime.group_list = []; runtime.draw_boundaries = bounds;
    var keys = struct_get_names(runtime.buckets);
    for (var k = 0; k < array_length(keys); k++) {
        var actors = runtime.buckets[$ keys[k]].live;
        for (var i = 0; i < array_length(actors); i++) {
            var actor = actors[i];
            var group = chart_actor_group(actor.depth);
            actor.actor_group = group;
            actor.actor_draw_slot = array_length(group.actors);
            array_push(group.actors, actor);
            group.dirty = true;
        }
    }
}

function chart_actor_attach(_actor) {
    if (!chart_actor_alive(_actor) || !_actor.active || _actor.actor_slot >= 0) return;
    var bucket = chart_actor_bucket(_actor.object_index);
    _actor.actor_bucket = bucket;
    _actor.actor_slot = array_length(bucket.live);
    array_push(bucket.live, _actor);
    var group = chart_actor_group(_actor.depth);
    _actor.actor_group = group;
    _actor.actor_draw_slot = array_length(group.actors);
    array_push(group.actors, _actor);
    group.dirty = true;
}

function chart_actor_detach(_actor) {
    var bucket = _actor.actor_bucket;
    var slot = _actor.actor_slot;
    if (is_struct(bucket) && slot >= 0) {
        var last = array_length(bucket.live) - 1;
        var moved = bucket.live[last];
        bucket.live[slot] = moved;
        moved.actor_slot = slot;
        array_pop(bucket.live);
    }
    _actor.actor_slot = -1;
    var group = _actor.actor_group;
    slot = _actor.actor_draw_slot;
    var disposing = variable_global_exists("chart_actors") && is_struct(global.chart_actors)
        && global.chart_actors.disposed;
    if (is_struct(group) && slot >= 0 && !disposing) {
        var last = array_length(group.actors) - 1;
        if (group.dirty) {
            var moved = group.actors[last];
            group.actors[slot] = moved;
            moved.actor_draw_slot = slot;
            array_pop(group.actors);
        } else {
            // A hit must not force the entire visible draw list to be sorted.
            array_delete(group.actors, slot, 1);
            for (var i = slot; i < last; i++) group.actors[i].actor_draw_slot = i;
        }
    }
    _actor.actor_draw_slot = -1;
    _actor.actor_group = undefined;
}

function chart_actor_set_depth(_actor, _depth) {
    if (!is_struct(_actor)) { with (_actor) depth = _depth; return; }
    var epsilon = math_get_epsilon();
    math_set_epsilon(0);
    var unchanged = _actor.depth == _depth;
    math_set_epsilon(epsilon);
    if (unchanged) return;
    var live = _actor.active;
    chart_actor_detach(_actor);
    _actor.depth = _depth;
    if (live) chart_actor_attach(_actor);
}

function chart_actor_create(_x, _y, _depth, _object, _fields = undefined) {
    var actor;
    switch (_object) {
        case oLine: actor = new OfficialJudgeLine(_object, _x, _y, _depth, _fields); break;
        case oNote: actor = new OfficialNote(_object, _x, _y, _depth, _fields); break;
        case oLine_1: actor = new RPEJudgeLine(_object, _x, _y, _depth, _fields); break;
        case oNote_1: actor = new RPENote(_object, _x, _y, _depth, _fields); break;
        case oLine_2: actor = new PECJudgeLine(_object, _x, _y, _depth, _fields); break;
        case oNote_2: actor = new PECNote(_object, _x, _y, _depth, _fields); break;
        default: return instance_create_depth(_x, _y, _depth, _object, _fields);
    }
    if (actor.disposed) return noone;
    var bucket = chart_actor_bucket(_object);
    actor.actor_bucket = bucket;
    actor.actor_all_slot = array_length(bucket.all);
    array_push(bucket.all, actor);
    chart_actor_attach(actor);
    return actor;
}

function chart_actor_activate(_target = self) {
    if (is_struct(_target)) {
        if (_target.disposed) return;
        _target.active = true;
        chart_actor_attach(_target);
    } else if (chart_actor_object(_target)) {
        var actors = chart_actor_list(_target, false);
        for (var i = 0; i < array_length(actors); i++) chart_actor_activate(actors[i]);
    } else instance_activate_object(_target);
}
function chart_actor_deactivate(_target = self) {
    if (is_struct(_target)) {
        chart_actor_detach(_target);
        _target.active = false;
    } else if (chart_actor_object(_target)) {
        var bucket = chart_actor_bucket(_target, false);
        if (!is_struct(bucket)) return;
        while (array_length(bucket.live)) chart_actor_deactivate(bucket.live[0]);
    } else instance_deactivate_object(_target);
}
function chart_actor_destroy(_target = self) {
    if (!is_struct(_target)) {
        if (chart_actor_object(_target)) {
            var actors = chart_actor_list(_target, false);
            while (array_length(actors)) {
                chart_actor_destroy(actors[array_length(actors) - 1]);
                actors = chart_actor_bucket(_target).all;
            }
        } else instance_destroy(_target);
        return;
    }
    if (_target.disposed) return;
    chart_actor_detach(_target);
    _target.active = false;
    _target.disposed = true;
    _target.actor_cleanup();
    var bucket = _target.actor_bucket;
    var slot = _target.actor_all_slot;
    if (is_struct(bucket) && slot >= 0) {
        var last = array_length(bucket.all) - 1;
        var moved = bucket.all[last];
        bucket.all[slot] = moved;
        moved.actor_all_slot = slot;
        array_pop(bucket.all);
    }
    _target.actor_all_slot = -1;
    _target.actor_bucket = undefined;
    _target.id = undefined;
    // Break links to the judgment graph, lines and shared chart data.
    var names = struct_get_names(_target);
    for (var i = 0; i < array_length(names); i++) {
        var value = _target[$ names[i]];
        if (is_struct(value) || is_array(value) || is_method(value)) _target[$ names[i]] = undefined;
    }
}

/// Direct user-method dispatch replaces Object user events in actor scope.
function chart_actor_user(_number) {
    if (!is_struct(self)) { event_user(_number); return; }
    switch (_number) {
        case 0: user_0(); break; case 1: user_1(); break; case 2: user_2(); break;
        case 3: user_3(); break; case 4: user_4(); break; case 5: user_5(); break;
        case 6: user_6(); break; case 7: user_7(); break; case 8: user_8(); break;
    }
}
function chart_actor_event(_type, _number) {
    if (!is_struct(self)) { event_perform(_type, _number); return; }
    if (_type == ev_step) {
        switch (_number) {
            case ev_step_begin: actor_begin(); break;
            case ev_step_normal: actor_step(); break;
            case ev_step_end: actor_end(); break;
        }
    } else if (_type == ev_other && _number >= 10) chart_actor_user(_number - 10);
}

function chart_actor_phase(_object, _phase) {
    var bucket = chart_actor_bucket(_object, false);
    if (!is_struct(bucket)) return;
    var i = 0;
    while (i < array_length(bucket.live)) {
        var actor = bucket.live[i];
        switch (_phase) {
            case 0: actor.actor_begin(); break;
            case 1: actor.actor_step(); break;
            case 2: actor.actor_end(); break;
        }
        // Retirement swaps the last live actor into this slot.
        if (actor.active && !actor.disposed && actor.actor_slot == i) i++;
    }
}

/// The renderer calls this after advancing its clock and before visibility queries.
function chart_actors_lines_step() {
    if (!variable_global_exists("chart_actors") || !is_struct(global.chart_actors)) return;
    var runtime = chart_actors_state();
    if (runtime.disposed || runtime.lines_ready) return;
    runtime.lines_ready = true;
    chart_actor_phase(oLine, 0); chart_actor_phase(oLine_1, 0); chart_actor_phase(oLine_2, 0);
    chart_actor_phase(oLine, 1); chart_actor_phase(oLine_1, 1); chart_actor_phase(oLine_2, 1);
    chart_actor_phase(oLine, 2); chart_actor_phase(oLine_1, 2); chart_actor_phase(oLine_2, 2);
}

/// Explicit schedule: clock -> local lines -> world poses -> activation -> notes -> judge.
function chart_actors_step() {
    if (!variable_global_exists("chart_actors") || !is_struct(global.chart_actors)) return;
    var runtime = chart_actors_state();
    if (runtime.running || runtime.disposed) return;
    var started = get_timer();
    runtime.running = true;
    try {
        chart_actors_lines_step();
        chart_actor_phase(oNote, 1); chart_actor_phase(oNote_1, 1); chart_actor_phase(oNote_2, 1);
    } finally { runtime.running = false; runtime.lines_ready = false; }
    runtime.ticks++;
    runtime.update_us = get_timer() - started;
    // No native image animation is performed for a struct. PEC's default drawing
    // uses this frame counter; the other formats drive GIF animation themselves.
    var lines = chart_actor_list(oLine_2);
    for (var i = 0; i < array_length(lines); i++) {
        var actor = lines[i];
        if (!game.paused && sprite_exists(actor.sprite_index)) {
            var frames = sprite_get_number(actor.sprite_index);
            var rate = sprite_get_speed(actor.sprite_index);
            if (sprite_get_speed_type(actor.sprite_index) == spritespeed_framespersecond)
                rate /= game_get_speed(gamespeed_fps);
            actor.image_index = (actor.image_index + actor.image_speed * rate) mod max(1, frames);
        }
    }
}

function chart_actor_draw_group(_group) {
    var runtime = chart_actors_state();
    if (!runtime.visible || runtime.disposed || !is_struct(_group)) return;
    // Preserve creation order even after an O(1) swap removal or reactivation.
    if (_group.dirty) {
        var epsilon = math_get_epsilon();
        math_set_epsilon(0);
        array_sort(_group.actors, function(a, b) {
            var order = sign(b.depth - a.depth);
            return order == 0 ? a.uid - b.uid : order;
        });
        math_set_epsilon(epsilon);
        for (var slot = 0; slot < array_length(_group.actors); slot++)
            _group.actors[slot].actor_draw_slot = slot;
        _group.dirty = false;
    }
    var actors = _group.actors;
    for (var i = 0; i < array_length(actors); i++) {
        var actor = actors[i];
        if (actor.active && !actor.disposed && actor.visible) actor.actor_draw();
    }
}

/// Manual teardown is idempotent; managed state remains under automatic GC.
function chart_actors_dispose(_collect = false) {
    if (!variable_global_exists("chart_actors") || !is_struct(global.chart_actors)) return;
    var runtime = global.chart_actors;
    if (runtime.disposed) return;
    runtime.disposed = true;
    chart_kb_reset();
    var keys = struct_get_names(runtime.buckets);
    for (var k = 0; k < array_length(keys); k++) {
        var bucket = runtime.buckets[$ keys[k]];
        while (array_length(bucket.all)) chart_actor_destroy(bucket.all[array_length(bucket.all) - 1]);
        bucket.all = []; bucket.live = [];
    }
    for (var i = 0; i < array_length(runtime.group_list); i++) {
        var group = runtime.group_list[i];
        group.actors = [];
        if (instance_exists(group.bridge)) instance_destroy(group.bridge);
        group.bridge = noone;
    }
    runtime.buckets = {}; runtime.groups = {}; runtime.group_list = [];
    // Runtime lookup tables are also owners. Retiring actors alone does not
    // release the references held by the chart, spatial groups and build jobs.
    var owners = ["game", "game_1", "game_2"];
    var arrays = ["_notes", "line_list", "line_group", "runtime_line_instances", "runtime_note_instances", "fatherLineList", "_note_spatial_groups", "_note_spatial_hold_groups"];
    var maps = ["_note_activation_records", "_note_spatial_group_map", "_note_spatial_hold_group_map"];
    var jobs = ["_chart_line_job", "_rpe_line_job"];
    for (var oi = 0; oi < array_length(owners); oi++) {
        if (!variable_global_exists(owners[oi])) continue;
        var owner = variable_global_get(owners[oi]);
        if (!is_struct(owner)) continue;
        for (var ai = 0; ai < array_length(arrays); ai++)
            if (struct_exists(owner, arrays[ai])) owner[$ arrays[ai]] = [];
        for (var mi = 0; mi < array_length(maps); mi++)
            if (struct_exists(owner, maps[mi])) owner[$ maps[mi]] = {};
        for (var ji = 0; ji < array_length(jobs); ji++)
            if (struct_exists(owner, jobs[ji])) owner[$ jobs[ji]] = undefined;
    }
    global.chart_actors = undefined;
    if (_collect && os_browser == browser_not_a_browser) gc_collect();
}

/// Run once after leaving gameplay. Automatic GC stays enabled during playback.
function chart_actors_collect_later() {
    if (os_browser == browser_not_a_browser)
        call_later(1, time_source_units_frames, chart_actors_collect);
}

function chart_actors_collect() {
    gc_collect();
}
