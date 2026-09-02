/**
 * GX.games audio boot. Inlined into runner HTML so OGG playback does not
 * depend on gx_drop.js resolving next to runner.html.
 */
(function (g) {
    "use strict";
    if (!g || g.__plsAudioBoot) return;
    g.__plsAudioBoot = 1;
    function bind(name, fn) {
        g[name] = fn;
        try { if (typeof Da !== "undefined" && Da) Da[name] = fn; } catch (e0) {}
        try { if (typeof window !== "undefined") window[name] = fn; } catch (e1) {}
    }
    var ctx = null;
    var nextId = 1;
    var slots = {};
    var lastErr = "";
    var pageHidden = 0;
    function AC() {
        try {
            if (!ctx) {
                var C = g.AudioContext || g.webkitAudioContext;
                if (!C) {
                    lastErr = "no AudioContext";
                    return null;
                }
                ctx = new C();
            }
            if (ctx.state === "suspended") ctx.resume();
            return ctx;
        } catch (e) {
            lastErr = "AudioContext failed";
            return null;
        }
    }
    function unlock() {
        AC();
        var ids = Object.keys(slots);
        for (var i = 0; i < ids.length; i++) {
            var s = slots[ids[i]];
            if (!s) continue;
            if (pageHidden) continue;
            if (s.el && s.want) {
                var p = s.el.play();
                if (p && p.catch) p.catch(function () {});
            } else if (s.want && s.buffer && !s.playing) {
                playBuf(s);
            }
        }
    }
    function mimeFromPath(p) {
        p = String(p || "").split("?")[0].toLowerCase();
        if (p.indexOf("data:audio/") === 0) {
            var sc = p.indexOf(";");
            return sc > 0 ? p.slice(5, sc) : "audio/ogg";
        }
        if (p.slice(-4) === ".ogg" || p.slice(-4) === ".oga" || p.slice(-5) === ".opus") return "audio/ogg";
        if (p.slice(-4) === ".mp3") return "audio/mpeg";
        if (p.slice(-4) === ".wav" || p.slice(-5) === ".wave") return "audio/wav";
        if (p.slice(-5) === ".flac") return "audio/flac";
        if (p.slice(-4) === ".m4a") return "audio/mp4";
        if (p.slice(-4) === ".aac") return "audio/aac";
        return "audio/ogg";
    }
    function pauseAll() {
        var ids = Object.keys(slots);
        for (var i = 0; i < ids.length; i++) {
            var s = slots[ids[i]];
            if (!s) continue;
            if (s.el) {
                try { s.el.pause(); } catch (e0) {}
            } else {
                s.off = posOf(s);
                s.playing = 0;
                stopSrc(s);
            }
        }
        if (ctx && ctx.state === "running") {
            try { ctx.suspend(); } catch (e1) {}
        }
    }
    function onPageHidden(hidden) {
        pageHidden = hidden ? 1 : 0;
        if (hidden) pauseAll();
        else if (ctx && ctx.state === "suspended") {
            try { ctx.resume(); } catch (e2) {}
        }
    }
    if (typeof document !== "undefined") {
        document.addEventListener("visibilitychange", function () {
            onPageHidden(!!document.hidden);
        }, true);
        document.addEventListener("pagehide", function () { onPageHidden(true); }, true);
        document.addEventListener("pageshow", function () { onPageHidden(false); }, true);
        document.addEventListener("freeze", function () { onPageHidden(true); }, true);
        document.addEventListener("resume", function () { onPageHidden(false); }, true);
        document.addEventListener("pointerdown", unlock, true);
        document.addEventListener("keydown", unlock, true);
    }
    function b64u8(b64) {
        var bin = atob(String(b64 || ""));
        var u = new Uint8Array(bin.length);
        for (var i = 0; i < bin.length; i++) u[i] = bin.charCodeAt(i) & 255;
        return u;
    }
    function stopSrc(s) {
        if (!s || !s.src) return;
        try { s.src.onended = null; s.src.stop(); } catch (e0) {}
        try { s.src.disconnect(); } catch (e1) {}
        s.src = null;
    }
    function posOf(s) {
        if (!s) return 0;
        if (!s.playing || !ctx) return s.off || 0;
        var p = (s.off || 0) + (ctx.currentTime - s.t0);
        if (s.dur && p > s.dur) p = s.dur;
        return p < 0 ? 0 : p;
    }
    function playBuf(s) {
        var c = AC();
        if (!c || !s.buffer) {
            s.want = 1;
            return 1;
        }
        stopSrc(s);
        var src = c.createBufferSource();
        src.buffer = s.buffer;
        src.connect(c.destination);
        s.off = s.off || 0;
        try { src.start(0, s.off); } catch (e0) {
            try { src.start(0); } catch (e1) {}
        }
        s.src = src;
        s.t0 = c.currentTime;
        s.playing = 1;
        s.want = 0;
        src.onended = function () {
            if (s.src === src) {
                s.playing = 0;
                s.off = s.dur || 0;
            }
        };
        return 1;
    }
    function attachEl(s, u8, mime) {
        try {
            var blob = new Blob([u8], { type: mime || "audio/ogg" });
            var url = URL.createObjectURL(blob);
            var el = new Audio();
            el.preload = "auto";
            el.src = url;
            el.__plsObjectUrl = url;
            s.el = el;
            el.addEventListener("loadedmetadata", function () {
                s.dur = isFinite(el.duration) ? el.duration : 0;
                if (s.want) {
                    var p = el.play();
                    if (p && p.catch) p.catch(function () {});
                }
            });
            try { el.load(); } catch (e0) {}
            return 1;
        } catch (e1) {
            lastErr = "element failed";
            return 0;
        }
    }
    function decodeU8(s, u8, mime) {
        var c = AC();
        if (!c) return attachEl(s, u8, mime);
        var ab = u8.buffer.slice(u8.byteOffset, u8.byteOffset + u8.byteLength);
        var ok = 1;
        try {
            var p = c.decodeAudioData(ab);
            if (p && p.then) {
                p.then(function (buf) {
                    s.buffer = buf;
                    s.dur = buf.duration || 0;
                    if (s.want) playBuf(s);
                }).catch(function () {
                    lastErr = "ogg decode failed";
                    attachEl(s, u8, mime);
                });
                return 1;
            }
        } catch (e0) {}
        try {
            c.decodeAudioData(ab, function (buf) {
                s.buffer = buf;
                s.dur = buf.duration || 0;
                if (s.want) playBuf(s);
            }, function () {
                lastErr = "ogg decode failed";
                attachEl(s, u8, mime);
            });
        } catch (e1) {
            ok = attachEl(s, u8, mime);
        }
        return ok;
    }
    bind("i_gx_audio_begin", function (mime) {
        lastErr = "";
        var id = nextId++;
        slots[id] = { mime: String(mime || "audio/ogg"), parts: [], total: 0, off: 0, dur: 0, playing: 0, want: 0 };
        return id;
    });
    bind("i_gx_audio_append", function (id, b64) {
        var s = slots[id | 0];
        if (!s) {
            lastErr = "append";
            return 0;
        }
        var u = b64u8(b64);
        if (u.length) {
            s.parts.push(u);
            s.total += u.length;
        }
        return 1;
    });
    bind("i_gx_audio_end", function (id) {
        var s = slots[id | 0];
        if (!s) {
            lastErr = "end";
            return 0;
        }
        var u = new Uint8Array(s.total);
        var o = 0;
        for (var i = 0; i < s.parts.length; i++) {
            u.set(s.parts[i], o);
            o += s.parts[i].length;
        }
        s.parts = [];
        if (!u.length) {
            lastErr = "empty";
            return 0;
        }
        return decodeU8(s, u, s.mime);
    });
    bind("i_gx_audio_create", function (path) {
        lastErr = "";
        var p = String(path || "");
        var id = nextId++;
        var s = slots[id] = { off: 0, dur: 0, playing: 0, want: 0, mime: mimeFromPath(p) };
        if (p.indexOf("http://") === 0 || p.indexOf("https://") === 0 || p.indexOf("blob:") === 0 || p.indexOf("data:") === 0) {
            try {
                fetch(p).then(function (r) { return r.arrayBuffer(); }).then(function (ab) {
                    decodeU8(s, new Uint8Array(ab), s.mime);
                }).catch(function () { lastErr = "fetch failed"; });
                return id;
            } catch (e0) {}
        }
        lastErr = "path needs bytes";
        return 0;
    });
    bind("i_gx_audio_play", function (id) {
        var s = slots[id | 0];
        if (!s) return 0;
        if (s.el) {
            var p = s.el.play();
            if (p && p.catch) p.catch(function () {});
            return 1;
        }
        s.want = 1;
        return playBuf(s);
    });
    bind("i_gx_audio_pause", function (id) {
        var s = slots[id | 0];
        if (!s) return 0;
        if (s.el) {
            s.el.pause();
            return 1;
        }
        s.off = posOf(s);
        s.playing = 0;
        stopSrc(s);
        return 1;
    });
    bind("i_gx_audio_resume", function (id) {
        var s = slots[id | 0];
        if (!s) return 0;
        if (s.el) {
            var p = s.el.play();
            if (p && p.catch) p.catch(function () {});
            return 1;
        }
        s.want = 1;
        return playBuf(s);
    });
    bind("i_gx_audio_stop", function (id) {
        var s = slots[id | 0];
        if (!s) return 0;
        if (s.el) {
            s.el.pause();
            try { s.el.currentTime = 0; } catch (e0) {}
            return 1;
        }
        s.off = 0;
        s.playing = 0;
        s.want = 0;
        stopSrc(s);
        return 1;
    });
    bind("i_gx_audio_set_position_ms", function (id, ms) {
        var s = slots[id | 0];
        if (!s) return 0;
        var sec = Math.max(0, Number(ms) / 1000);
        if (s.el) {
            try { s.el.currentTime = sec; } catch (e0) {}
            return 1;
        }
        s.off = sec;
        if (s.playing) playBuf(s);
        return 1;
    });
    bind("i_gx_audio_get_position_ms", function (id) {
        var s = slots[id | 0];
        if (!s) return 0;
        if (s.el) return (s.el.currentTime || 0) * 1000;
        return posOf(s) * 1000;
    });
    bind("i_gx_audio_get_length_ms", function (id) {
        var s = slots[id | 0];
        if (!s) return 0;
        if (s.el) {
            var d = s.el.duration;
            return isFinite(d) ? d * 1000 : 0;
        }
        return (s.dur || 0) * 1000;
    });
    bind("i_gx_audio_release", function (id) {
        var s = slots[id | 0];
        if (!s) return 0;
        stopSrc(s);
        if (s.el) {
            try { s.el.pause(); s.el.removeAttribute("src"); s.el.load(); } catch (e0) {}
            if (s.el.__plsObjectUrl) {
                try { URL.revokeObjectURL(s.el.__plsObjectUrl); } catch (e1) {}
            }
        }
        delete slots[id | 0];
        return 1;
    });
    bind("i_gx_audio_last_error", function () { return lastErr || ""; });
    bind("i_gx_audio_ping", function () { return 1; });
    bind("i_gx_page_hidden", function () { return pageHidden; });
})(typeof globalThis !== "undefined" ? globalThis : window);
