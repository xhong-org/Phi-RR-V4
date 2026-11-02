/// RPEN (Re:PhiEdit-Next) noise geometry. Rendering uses OfficialBlock materials.
/// Format reference: Phira-Pro/prpr/src/core/rpe_next_block.rs and parse/rpe.rs.
/// Upstream protocol: https://github.com/kclg-YSJ/rpe-next
/// Reference fixtures: rpe-next@78dfc8b and 0.13.1@7b46dc0923deee6d10d14a9dc5adf92e8cecc66f.
/// All stored times are global BPM seconds, without line bpmfactor or audio offset.
/// Geometry stays in the centered 1350 x 900 canvas until the caller maps corners.

function rpen_noise_error(_path, _message) {
    throw ({ message: "RPEN " + _path + ": " + _message });
}

function rpen_noise_number(_value, _path) {
    if (!is_numeric(_value) || is_bool(_value) || !is_finite(_value)) {
        rpen_noise_error(_path, "expected a finite number");
    }
    return real(_value);
}

function rpen_noise_flag(_value, _path, _fallback = false) {
    _value = _value ?? undefined;
    if (is_undefined(_value)) return _fallback;
    if (is_bool(_value)) return _value;
    if (is_numeric(_value) && (sign(_value) == 0 || sign(_value - 1) == 0)) return sign(_value) != 0;
    rpen_noise_error(_path, "expected boolean or 0/1");
}

function rpen_noise_array(_value, _path) {
    if (is_undefined(_value)) return [];
    if (!is_array(_value)) rpen_noise_error(_path, "expected an array");
    return _value;
}

function rpen_noise_position(_value, _path) {
    if (!is_struct(_value)) rpen_noise_error(_path, "expected {x,y}");
    return [rpen_noise_number(_value[$ "x"], _path + ".x"),
            rpen_noise_number(_value[$ "y"], _path + ".y")];
}

function rpen_noise_beat(_value, _path) {
    if (!is_array(_value) || array_length(_value) != 3) {
        rpen_noise_error(_path, "expected [integer,numerator,denominator]");
    }
    for (var _i = 0; _i < 3; _i++) {
        var _part = rpen_noise_number(_value[_i], _path + "[" + string(_i) + "]");
        if (sign(_part - floor(_part)) != 0 || abs(_part) > 9007199254740991) {
            rpen_noise_error(_path, "beat components must be safe integers");
        }
    }
    if (_value[2] <= 0) rpen_noise_error(_path, "beat denominator must be positive");
    return _value[0] + _value[1] / _value[2];
}

function rpen_noise_tempo(_chart) {
    var _source = rpen_noise_array(_chart[$ "BPMList"], "BPMList");
    if (array_length(_source) <= 0) rpen_noise_error("BPMList", "must not be empty");
    var _tempo = [];
    for (var _i = 0; _i < array_length(_source); _i++) {
        var _path = "BPMList[" + string(_i) + "]";
        var _entry = _source[_i];
        if (!is_struct(_entry)) rpen_noise_error(_path, "expected an object");
        var _beat = rpen_noise_beat(_entry[$ "startTime"], _path + ".startTime");
        var _bpm = rpen_noise_number(_entry[$ "bpm"], _path + ".bpm");
        if (_bpm <= 0) rpen_noise_error(_path + ".bpm", "must be positive");
        array_push(_tempo, { beat: _beat, bpm: _bpm, second: 0, ord: _i });
    }
    array_sort(_tempo, function(_a, _b) {
        var _order = sign(_a.beat - _b.beat);
        return _order != 0 ? _order : sign(_a.ord - _b.ord);
    });
    _tempo[0].second = _tempo[0].beat * 60 / _tempo[0].bpm;
    for (var _i = 1; _i < array_length(_tempo); _i++) {
        var _previous = _tempo[_i - 1];
        _tempo[_i].second = _previous.second + (_tempo[_i].beat - _previous.beat) * 60 / _previous.bpm;
    }
    return _tempo;
}

function rpen_noise_seconds(_tempo, _beat_value, _path) {
    var _beat = rpen_noise_beat(_beat_value, _path);
    var _lo = 0;
    var _hi = array_length(_tempo);
    while (_lo < _hi) {
        var _mid = (_lo + _hi) div 2;
        if (sign(_tempo[_mid].beat - _beat) <= 0) _lo = _mid + 1;
        else _hi = _mid;
    }
    var _entry = _tempo[max(0, _lo - 1)];
    return _entry.second + (_beat - _entry.beat) * 60 / _entry.bpm;
}

function rpen_noise_nonempty(_value) {
    if (is_array(_value)) return array_length(_value) > 0;
    if (is_struct(_value)) return struct_names_count(_value) > 0;
    return false;
}

///@desc New RPEN overlap semantics are feature-driven, as in the reference parser.
function rpen_noise_features(_chart, _source) {
    var _meta = _chart[$ "META"];
    if (is_struct(_meta)) {
        var _version = _meta[$ "RPEVersion"];
        if (is_numeric(_version) && _version >= 230) {
            for (var _i = 0; _i < array_length(_source); _i++) {
                if (is_struct(_source[_i]) && struct_exists(_source[_i], "bottomLeft")) return true;
            }
        }
        if (rpen_noise_nonempty(_meta[$ "effects"])) return true;
    }
    var _keys = ["noiseAreaLayers", "globalEvents", "effects", "shaderEvents"];
    for (var _i = 0; _i < array_length(_keys); _i++) {
        if (rpen_noise_nonempty(_chart[$ _keys[_i]])) return true;
    }
    for (var _i = 0; _i < array_length(_source); _i++) {
        if (is_struct(_source[_i]) && struct_exists(_source[_i], "layerId")) return true;
    }
    var _lines = _chart[$ "judgeLineList"];
    if (!is_array(_lines)) return false;
    for (var _i = 0; _i < array_length(_lines); _i++) {
        var _line = _lines[_i];
        if (!is_struct(_line)) continue;
        var _factor = _line[$ "bpmfactor"];
        if (is_numeric(_factor) && abs(_factor - 1) > 0.000000000001) return true;
        var _skew = _line[$ "skewControl"];
        if (is_array(_skew)) {
            for (var _j = 0; _j < array_length(_skew); _j++) {
                if (is_struct(_skew[_j]) && is_numeric(_skew[_j][$ "skew"]) && sign(_skew[_j].skew) != 0) return true;
            }
        }
        var _extended = _line[$ "extended"];
        if (is_struct(_extended)) {
            var _paint = _extended[$ "paintEvents"];
            if (is_array(_paint)) {
                for (var _j = 0; _j < array_length(_paint); _j++) {
                    var _event = _paint[_j];
                    if (is_struct(_event) && (struct_exists(_event, "shader")
                        || struct_exists(_event, "shaderType") || struct_exists(_event, "name"))) return true;
                }
            }
        }
        var _event_layers = _line[$ "eventLayers"];
        if (!is_array(_event_layers)) continue;
        for (var _j = 0; _j < array_length(_event_layers); _j++) {
            if (!is_struct(_event_layers[_j])) continue;
            var _moves = _event_layers[_j][$ "moveXEvents"];
            if (!is_array(_moves)) continue;
            for (var _k = 0; _k < array_length(_moves); _k++) {
                if (is_struct(_moves[_k]) && is_struct(_moves[_k][$ "trajectory"])) return true;
            }
        }
    }
    return false;
}

function rpen_noise_bounce(_t) {
    if (_t < 4 / 11) return (121 / 16) * _t * _t;
    if (_t < 8 / 11) { _t -= 6 / 11; return (121 / 16) * _t * _t + 0.75; }
    if (_t < 10 / 11) { _t -= 9 / 11; return (121 / 16) * _t * _t + 0.9375; }
    _t -= 21 / 22;
    return (121 / 16) * _t * _t + 0.984375;
}

function rpen_noise_ease_in(_family, _t) {
    switch (_family) {
        case 1: return 1 - cos(_t * pi * 0.5);
        case 2: return _t * _t;
        case 3: return _t * _t * _t;
        case 4: return _t * _t * _t * _t;
        case 5: return _t * _t * _t * _t * _t;
        case 6: return sign(_t) == 0 ? 0 : power(2, 10 * (_t - 1));
        case 7: return 1 - sqrt(abs(1 - _t * _t));
        case 8: return _t * _t * (2.70158 * _t - 1.70158);
        case 9:
            if (sign(_t) == 0 || sign(_t - 1) == 0) return _t;
            return -power(2, 10 * _t - 10) * sin((10 * _t - 10.75) * 2 * pi / 3);
        case 10: return 1 - rpen_noise_bounce(1 - _t);
    }
    return _t;
}

///@desc RPEN IDs 1..29; deliberately independent from legacy line easing.
function rpen_noise_curve(_id, _t) {
    if (_id == 1) return _t;
    static _families = [0, 0, 1, 1, 2, 2, 1, 2, 3, 3, 4, 4, 3, 4, 5, 5, 6, 6, 7, 7, 8, 8, 7, 8, 9, 9, 10, 10, 10, 9];
    static _directions = [0, 0, 1, 0, 1, 0, 2, 2, 1, 0, 1, 0, 2, 2, 1, 0, 1, 0, 1, 0, 1, 0, 2, 2, 1, 0, 1, 0, 2, 2];
    var _family = _families[_id];
    var _direction = _directions[_id];
    if (_direction == 0) return rpen_noise_ease_in(_family, _t);
    if (_direction == 1) return 1 - rpen_noise_ease_in(_family, 1 - _t);
    if (_family == 8) {
        var _k = 1.70158 * 1.525;
        if (_t < 0.5) {
            var _x = 2 * _t;
            return _x * _x * ((_k + 1) * _x - _k) * 0.5;
        }
        var _x = 2 * _t - 2;
        return (_x * _x * ((_k + 1) * _x + _k) + 2) * 0.5;
    }
    if (_family == 9) {
        if (sign(_t) == 0 || sign(_t - 1) == 0) return _t;
        var _wave = sin((20 * _t - 11.125) * 2 * pi / 4.5) * 0.5;
        return _t < 0.5 ? -power(2, 20 * _t - 10) * _wave : power(2, 10 - 20 * _t) * _wave + 1;
    }
    return _t < 0.5 ? rpen_noise_ease_in(_family, 2 * _t) * 0.5
                    : 1 - rpen_noise_ease_in(_family, 2 - 2 * _t) * 0.5;
}

///@desc Solve Bezier X before sampling Y; bounded bisection handles flat endpoints.
function rpen_noise_bezier(_progress, _points) {
    if (sign(_progress) <= 0) return 0;
    if (sign(_progress - 1) >= 0) return 1;
    // Reflect the latter half to avoid cancellation near a flat X endpoint.
    var _reverse = _progress > 0.5;
    var _target = _reverse ? 1 - _progress : _progress;
    var _x1 = _reverse ? 1 - _points[2] : _points[0];
    var _x2 = _reverse ? 1 - _points[0] : _points[2];
    var _lo = 0;
    var _hi = 1;
    repeat (48) {
        var _t = (_lo + _hi) * 0.5;
        var _u = 1 - _t;
        var _x = 3 * _t * _u * _u * _x1 + 3 * _t * _t * _u * _x2 + _t * _t * _t;
        if (sign(_x - _target) < 0) _lo = _t;
        else _hi = _t;
    }
    var _t = (_lo + _hi) * 0.5;
    var _u = 1 - _t;
    var _y1 = _reverse ? 1 - _points[3] : _points[1];
    var _y2 = _reverse ? 1 - _points[1] : _points[3];
    var _y = 3 * _t * _u * _u * _y1 + 3 * _t * _t * _u * _y2 + _t * _t * _t;
    return _reverse ? 1 - _y : _y;
}

// Six components: x'=a*x+b*y+tx, y'=c*x+d*y+ty. Allocated only at import.
function rpen_noise_relative(_axis, _from, _to, _ax, _ay) {
    if (_axis == 3) {
        var _angle = (_to - _from) * pi / 180;
        var _c = cos(_angle);
        var _s = sin(_angle);
        return [_c, _s, -_s, _c, _ax - _c * _ax - _s * _ay, _ay + _s * _ax - _c * _ay];
    }
    var _ratio = sign(_from) == 0 ? 1 : _to / _from;
    if (!is_finite(_ratio)) _ratio = 1;
    if (_axis == 1) return [_ratio, 0, 0, 1, _ax * (1 - _ratio), 0];
    if (_axis == 2) return [1, 0, 0, _ratio, 0, _ay * (1 - _ratio)];
    return [1, 0, 0, 1, 0, 0];
}

function rpen_noise_affine_multiply(_a, _b) {
    return [
        _a[0] * _b[0] + _a[1] * _b[2],
        _a[0] * _b[1] + _a[1] * _b[3],
        _a[2] * _b[0] + _a[3] * _b[2],
        _a[2] * _b[1] + _a[3] * _b[3],
        _a[0] * _b[4] + _a[1] * _b[5] + _a[4],
        _a[2] * _b[4] + _a[3] * _b[5] + _a[5]
    ];
}

function rpen_noise_track(_source, _axis, _fallback, _tempo, _path) {
    _source = rpen_noise_array(_source, _path);
    var _events = [];
    for (var _i = 0; _i < array_length(_source); _i++) {
        var _path_i = _path + "[" + string(_i) + "]";
        var _raw = _source[_i];
        if (!is_struct(_raw)) rpen_noise_error(_path_i, "expected an event object");
        var _a = rpen_noise_seconds(_tempo, _raw[$ "startTime"], _path_i + ".startTime");
        var _b = rpen_noise_seconds(_tempo, _raw[$ "endTime"], _path_i + ".endTime");
        if (sign(_a - _b) > 0) rpen_noise_error(_path_i, "startTime is after endTime");
        var _v0 = rpen_noise_number(_raw[$ "start"], _path_i + ".start");
        var _v1 = rpen_noise_number(_raw[$ "end"], _path_i + ".end");
        var _ease_raw = _raw[$ "easingType"];
        var _ease = is_undefined(_ease_raw) ? 1 : rpen_noise_number(_ease_raw, _path_i + ".easingType");
        if (_ease < 1 || _ease > 29 || sign(_ease - floor(_ease)) != 0) rpen_noise_error(_path_i, "easingType must be 1..29");
        var _left_raw = _raw[$ "easingLeft"];
        var _right_raw = _raw[$ "easingRight"];
        var _left = is_undefined(_left_raw) ? 0 : rpen_noise_number(_left_raw, _path_i + ".easingLeft");
        var _right = is_undefined(_right_raw) ? 1 : rpen_noise_number(_right_raw, _path_i + ".easingRight");
        if (_left < 0 || _right > 1 || sign(_left - _right) >= 0) rpen_noise_error(_path_i, "invalid easing bounds");
        var _bezier = rpen_noise_flag(_raw[$ "bezier"], _path_i + ".bezier");
        var _points = _raw[$ "bezierPoints"];
        if (is_undefined(_points)) _points = [0, 0, 1, 1];
        if (!is_array(_points) || array_length(_points) != 4) rpen_noise_error(_path_i, "bezierPoints must contain four numbers");
        for (var _j = 0; _j < 4; _j++) rpen_noise_number(_points[_j], _path_i + ".bezierPoints");
        if (_bezier && (_points[0] < 0 || _points[0] > 1 || _points[2] < 0 || _points[2] > 1)) {
            rpen_noise_error(_path_i, "Bezier X controls must be in 0..1");
        }
        var _inst = rpen_noise_flag(_raw[$ "inst"], _path_i + ".inst");
        if (_inst && sign(_v0 - _v1) != 0) rpen_noise_error(_path_i, "inst requires equal start/end values");
        var _step = rpen_noise_flag(_raw[$ "transformStep"], _path_i + ".transformStep");
        if (_step && sign(_a - _b) != 0) rpen_noise_error(_path_i, "transformStep requires zero duration");
        var _ref0_raw = _raw[$ "transformStart"] ?? undefined;
        var _ref1_raw = _raw[$ "transformEnd"] ?? undefined;
        var _ref0 = is_undefined(_ref0_raw) ? _v0 : rpen_noise_number(_ref0_raw, _path_i + ".transformStart");
        var _ref1 = is_undefined(_ref1_raw) ? _v1 : rpen_noise_number(_ref1_raw, _path_i + ".transformEnd");
        var _anchor = [0, 0];
        if (_axis != 0) _anchor = rpen_noise_position(_raw[$ "anchor"], _path_i + ".anchor");
        else if (!is_undefined(_ref0_raw) || !is_undefined(_ref1_raw) || _step) {
            rpen_noise_error(_path_i, "transform metadata is invalid on movement events");
        }
        var _base = rpen_noise_curve(_ease, _left);
        var _range = rpen_noise_curve(_ease, _right) - _base;
        array_push(_events, {
            a: _a, b: _b, v0: _v0, v1: _v1, ease: _ease, left: _left, right: _right,
            bezier: _bezier, points: _points, ease_base: _base, ease_range: _range,
            ax: _anchor[0], ay: _anchor[1], ref0: _ref0, ref1: _ref1, step: _step,
            prefix: [1, 0, 0, 1, 0, 0], ord: _i
        });
    }
    array_sort(_events, function(_a, _b) {
        var _order = sign(_a.a - _b.a);
        return _order != 0 ? _order : sign(_a.ord - _b.ord);
    });
    for (var _i = 1; _i < array_length(_events); _i++) {
        var _previous = _events[_i - 1];
        var _next = _events[_i];
        var _chain = _axis != 0 && sign(_previous.a - _next.a) == 0
            && sign(_previous.a - _previous.b) == 0 && _previous.step;
        if (sign(_next.a - _previous.b) < 0 || (sign(_next.a - _previous.a) == 0 && !_chain)) {
            rpen_noise_error(_path, "overlapping events");
        }
        if (_axis != 0) {
            var _completed = rpen_noise_relative(_axis, _previous.ref0, _previous.ref1, _previous.ax, _previous.ay);
            var _bridge = rpen_noise_relative(_axis, _previous.ref1, _next.ref0, _previous.ax, _previous.ay);
            _next.prefix = rpen_noise_affine_multiply(_bridge, rpen_noise_affine_multiply(_completed, _previous.prefix));
        }
    }
    return { axis: _axis, fallback: _fallback, events: _events, value: _fallback, sample_index: -1 };
}

///@desc Tracks retain only their current index/value; seeking never depends on them.
function rpen_noise_track_sample(_track, _now) {
    var _events = _track.events;
    var _lo = 0;
    var _hi = array_length(_events);
    var _time = _now + 0.000000001;
    while (_lo < _hi) {
        var _mid = (_lo + _hi) div 2;
        if (sign(_events[_mid].a - _time) <= 0) _lo = _mid + 1;
        else _hi = _mid;
    }
    _track.sample_index = _lo - 1;
    if (_lo <= 0) {
        _track.value = _track.fallback;
        return _track.value;
    }
    var _event = _events[_lo - 1];
    if (sign(_event.v0 - _event.v1) == 0) {
        _track.value = _event.v0;
        return _track.value;
    }
    var _p = sign(_event.a - _event.b) == 0 ? 1 : clamp((_now - _event.a) / (_event.b - _event.a), 0, 1);
    var _eased;
    if (_event.bezier) _eased = rpen_noise_bezier(_p, _event.points);
    else if (abs(_event.ease_range) < 0.000000000001) _eased = _p;
    else _eased = (rpen_noise_curve(_event.ease, _event.left + (_event.right - _event.left) * _p) - _event.ease_base) / _event.ease_range;
    _track.value = _event.v0 + (_event.v1 - _event.v0) * _eased;
    return _track.value;
}

///@desc Apply a track prefix and its current relative transform to a reused point.
function rpen_noise_track_transform(_track, _point) {
    if (_track.sample_index < 0) return;
    var _event = _track.events[_track.sample_index];
    var _prefix = _event.prefix;
    var _px = _prefix[0] * _point[0] + _prefix[1] * _point[1] + _prefix[4];
    var _py = _prefix[2] * _point[0] + _prefix[3] * _point[1] + _prefix[5];
    if (_track.axis == 3) {
        var _angle = (_track.value - _event.ref0) * pi / 180;
        var _c = cos(_angle);
        var _s = sin(_angle);
        var _dx = _px - _event.ax;
        var _dy = _py - _event.ay;
        _point[0] = _event.ax + _c * _dx + _s * _dy;
        _point[1] = _event.ay - _s * _dx + _c * _dy;
    } else {
        var _ratio = sign(_event.ref0) == 0 ? 1 : _track.value / _event.ref0;
        if (!is_finite(_ratio)) _ratio = 1;
        _point[0] = _track.axis == 1 ? _event.ax + (_px - _event.ax) * _ratio : _px;
        _point[1] = _track.axis == 2 ? _event.ay + (_py - _event.ay) * _ratio : _py;
    }
}

function rpen_noise_intervals(_source, _appear, _disappear, _tempo, _path) {
    _source = rpen_noise_array(_source, _path);
    var _intervals = [];
    for (var _i = 0; _i < array_length(_source); _i++) {
        var _path_i = _path + "[" + string(_i) + "]";
        var _raw = _source[_i];
        if (!is_struct(_raw)) rpen_noise_error(_path_i, "expected an interval object");
        var _original_a = rpen_noise_seconds(_tempo, _raw[$ "startTime"], _path_i + ".startTime");
        var _original_b = rpen_noise_seconds(_tempo, _raw[$ "endTime"], _path_i + ".endTime");
        if (sign(_original_a - _original_b) > 0) rpen_noise_error(_path_i, "startTime is after endTime");
        var _ready_raw = _raw[$ "readyFlash"] ?? undefined;
        var _ready = 0.5;
        if (is_bool(_ready_raw)) _ready = _ready_raw ? 0.5 : 0;
        else if (!is_undefined(_ready_raw)) {
            _ready = max(0, rpen_noise_number(_ready_raw, _path_i + ".readyFlash"));
            _ready = floor(_ready * 1000 + 0.5) / 1000;
        }
        var _a = max(_original_a, _appear);
        var _b = min(_original_b, _disappear);
        if (sign(_a - _b) < 0 || (sign(_original_a - _original_b) == 0 && sign(_a - _b) == 0)) {
            array_push(_intervals, { a: _a, b: _b, ready: _ready, ord: _i });
        }
    }
    array_sort(_intervals, function(_a, _b) {
        var _order = sign(_a.a - _b.a);
        return _order != 0 ? _order : sign(_a.ord - _b.ord);
    });
    var _merged = [];
    for (var _i = 0; _i < array_length(_intervals); _i++) {
        var _entry = _intervals[_i];
        var _n = array_length(_merged);
        if (_n > 0 && sign(_merged[_n - 1].a - _entry.a) == 0) {
            var _previous = _merged[_n - 1];
            _previous.b = max(_previous.b, _entry.b);
            _previous.ready = max(_previous.ready, _entry.ready);
        } else array_push(_merged, _entry);
    }
    var _active = [];
    for (var _i = 0; _i < array_length(_merged); _i++) {
        var _entry = _merged[_i];
        if (sign(_entry.a - _entry.b) >= 0) continue;
        var _n = array_length(_active);
        if (_n > 0 && sign(_active[_n - 1].b - _entry.a) > 0) rpen_noise_error(_path, "overlapping active intervals");
        array_push(_active, _entry);
    }
    return { intervals: _merged, active: _active };
}

///@desc Parse RPEN entries only; the original chart/list is not mutated.
function rpen_blocks_parse(_chart) {
    if (!is_struct(_chart)) rpen_noise_error("chart", "expected an object");
    var _source = _chart[$ "blockAreaList"];
    if (is_undefined(_source)) _source = _chart[$ "BlockAreaList"];
    _source = rpen_noise_array(_source, "blockAreaList");
    var _layers = _chart[$ "noiseAreaLayers"];
    var _ids = ["default"];
    if (!is_undefined(_layers)) {
        if (!is_array(_layers) || array_length(_layers) < 1 || array_length(_layers) > 32) {
            rpen_noise_error("noiseAreaLayers", "must contain 1..32 layers");
        }
        _ids = [];
        for (var _i = 0; _i < array_length(_layers); _i++) {
            if (!is_struct(_layers[_i]) || !is_string(_layers[_i][$ "id"])) {
                rpen_noise_error("noiseAreaLayers[" + string(_i) + "]", "missing string layer ID");
            }
            var _layer_id = _layers[_i].id;
            for (var _j = 0; _j < array_length(_ids); _j++) {
                if (_ids[_j] == _layer_id) rpen_noise_error("noiseAreaLayers", "duplicate layer ID: " + _layer_id);
            }
            array_push(_ids, _layer_id);
        }
    }
    var _options = _chart[$ "noiseAreaOptions"];
    if (!is_undefined(_options) && !is_struct(_options)) rpen_noise_error("noiseAreaOptions", "expected an object");
    var _single = rpen_noise_features(_chart, _source);
    if (is_struct(_options)) {
        var _ignore = _options[$ "ignoreTripleInversion"];
        if (!is_undefined(_ignore)) {
            if (!is_bool(_ignore)) rpen_noise_error("noiseAreaOptions.ignoreTripleInversion", "expected a boolean");
            _single = _single || _ignore;
        }
    }
    var _tempo = undefined;
    var _blocks = [];
    for (var _i = 0; _i < array_length(_source); _i++) {
        var _area = _source[_i];
        var _path = "blockAreaList[" + string(_i) + "]";
        if (!is_struct(_area)) rpen_noise_error(_path, "expected an area object");
        var _next = struct_exists(_area, "bottomLeft") || struct_exists(_area, "topRight");
        var _native = struct_exists(_area, "bottomLeftPercentage") || struct_exists(_area, "topRightPercentage");
        if (_next == _native) rpen_noise_error(_path, "unknown or ambiguous rectangle schema");
        if (_native) continue;
        if (is_undefined(_tempo)) _tempo = rpen_noise_tempo(_chart);
        var _bl = rpen_noise_position(_area[$ "bottomLeft"], _path + ".bottomLeft");
        var _tr = rpen_noise_position(_area[$ "topRight"], _path + ".topRight");
        var _cx = (_bl[0] + _tr[0]) * 0.5;
        var _cy = (_bl[1] + _tr[1]) * 0.5;
        var _width = abs(_tr[0] - _bl[0]);
        var _height = abs(_tr[1] - _bl[1]);
        if (!is_finite(_cx) || !is_finite(_cy) || !is_finite(_width) || !is_finite(_height)) rpen_noise_error(_path, "invalid rectangle");
        var _appear = rpen_noise_seconds(_tempo, _area[$ "appearTime"], _path + ".appearTime");
        var _disappear = rpen_noise_seconds(_tempo, _area[$ "disappearTime"], _path + ".disappearTime");
        if (sign(_appear - _disappear) > 0) rpen_noise_error(_path, "appearTime is after disappearTime");
        var _invert = _area[$ "isInvert"];
        if (is_undefined(_invert)) _invert = false;
        if (!is_bool(_invert)) rpen_noise_error(_path + ".isInvert", "expected a boolean");
        var _layer_id = _area[$ "layerId"];
        if (is_undefined(_layer_id)) _layer_id = "default";
        if (!is_string(_layer_id)) rpen_noise_error(_path + ".layerId", "expected a string");
        var _layer = -1;
        // Without an explicit layer table older exports still share one layer.
        if (is_undefined(_layers)) _layer = 0;
        else for (var _j = 0; _j < array_length(_ids); _j++) if (_ids[_j] == _layer_id) _layer = _j;
        if (_layer < 0) rpen_noise_error(_path + ".layerId", "unknown layer: " + _layer_id);
        var _interval_data = rpen_noise_intervals(_area[$ "activeIntervals"], _appear, _disappear, _tempo, _path + ".activeIntervals");
        var _block = official_block_shell();
        _block.rpen = true;
        _block.layer = _layer;
        _block.layer_id = _layer_id;
        _block.single_inversion = _single;
        _block.ord = _i;
        _block.subtract = _invert;
        _block.appear = _appear;
        _block.disappear = _disappear;
        _block.enable = array_length(_interval_data.intervals) > 0 ? _interval_data.intervals[0].a : infinity;
        _block.disable = _disappear;
        _block.x0 = _bl[0]; _block.y0 = _bl[1];
        _block.x1 = _tr[0]; _block.y1 = _tr[1];
        _block.rpen_center_x = _cx; _block.rpen_center_y = _cy;
        _block.rpen_width = _width; _block.rpen_height = _height;
        _block.intervals = _interval_data.intervals;
        _block.activations = _interval_data.active;
        _block.tracks = [
            rpen_noise_track(_area[$ "moveXEvents"], 0, _cx, _tempo, _path + ".moveXEvents"),
            rpen_noise_track(_area[$ "moveYEvents"], 0, _cy, _tempo, _path + ".moveYEvents"),
            rpen_noise_track(_area[$ "rotateEvents"], 3, 0, _tempo, _path + ".rotateEvents"),
            rpen_noise_track(_area[$ "scaleXEvents"], 1, 1, _tempo, _path + ".scaleXEvents"),
            rpen_noise_track(_area[$ "scaleYEvents"], 2, 1, _tempo, _path + ".scaleYEvents")
        ];
        _block.rpen_pose_result = [_cx, _cy, _width, _height, 0];
        _block.rpen_point = [_cx, _cy];
        _block.rpen_pose_now = -infinity;
        array_push(_blocks, _block);
    }
    return _blocks;
}

///@desc Five reused canvas values: center X/Y, absolute full width/height, clockwise radians.
function rpen_block_pose(_block, _now, _aspect) {
    if (sign(_block.rpen_pose_now - _now) == 0) return _block.rpen_pose_result;
    var _tracks = _block.tracks;
    for (var _i = 0; _i < 5; _i++) rpen_noise_track_sample(_tracks[_i], _now);
    var _point = _block.rpen_point;
    _point[0] = _block.rpen_center_x;
    _point[1] = _block.rpen_center_y;
    rpen_noise_track_transform(_tracks[3], _point);
    rpen_noise_track_transform(_tracks[4], _point);
    rpen_noise_track_transform(_tracks[2], _point);
    var _result = _block.rpen_pose_result;
    _result[0] = _point[0] + _tracks[0].value - _block.rpen_center_x;
    _result[1] = _point[1] + _tracks[1].value - _block.rpen_center_y;
    _result[2] = abs(_block.rpen_width * _tracks[3].value);
    _result[3] = abs(_block.rpen_height * _tracks[4].value);
    _result[4] = _tracks[2].value * pi / 180;
    _block.rpen_pose_now = _now;
    return _result;
}

///@desc 0 active, 1 ready, 2 disabled. Lifecycle/zero area visibility is checked by caller.
function rpen_block_phase(_block, _now) {
    _block.fade = 1;
    var _time = _now + 0.000000001;
    var _active = _block.activations;
    var _lo = 0;
    var _hi = array_length(_active);
    while (_lo < _hi) {
        var _mid = (_lo + _hi) div 2;
        if (sign(_active[_mid].a - _time) <= 0) _lo = _mid + 1;
        else _hi = _mid;
    }
    if (_lo > 0 && sign(_time - _active[_lo - 1].b) < 0) return 0;
    var _intervals = _block.intervals;
    _lo = 0;
    _hi = array_length(_intervals);
    while (_lo < _hi) {
        var _mid = (_lo + _hi) div 2;
        if (sign(_intervals[_mid].a - _time) <= 0) _lo = _mid + 1;
        else _hi = _mid;
    }
    if (_lo < array_length(_intervals)) {
        var _next = _intervals[_lo];
        if (_next.ready > 0 && sign(_time - (_next.a - _next.ready)) >= 0) return 1;
    }
    return 2;
}
