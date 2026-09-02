/**
 * GX.games extra.json video boot. Muted HTMLVideoElement + WebGL blit into
 * the current GameMaker framebuffer so notes still draw on top.
 */
(function (g) {
    "use strict";
    if (!g) return;
    function bind(name, fn) {
        g[name] = fn;
        try { if (typeof Da !== "undefined" && Da) Da[name] = fn; } catch (e0) {}
        try { if (typeof window !== "undefined") window[name] = fn; } catch (e1) {}
    }
    if (g.__plsVideoBoot) {
        var names = [
            "i_gx_video_ping", "i_gx_video_create", "i_gx_video_begin", "i_gx_video_append",
            "i_gx_video_end", "i_gx_video_play", "i_gx_video_pause", "i_gx_video_stop",
            "i_gx_video_seek_ms", "i_gx_video_get_position_ms", "i_gx_video_get_length_ms",
            "i_gx_video_get_width", "i_gx_video_get_height", "i_gx_video_get_status",
            "i_gx_video_draw", "i_gx_video_set_loop", "i_gx_video_release", "i_gx_video_last_error",
            "i_gx_video_shutdown"
        ];
        for (var ni = 0; ni < names.length; ni++) {
            if (typeof g[names[ni]] === "function") bind(names[ni], g[names[ni]]);
        }
        return;
    }
    g.__plsVideoBoot = 1;
    var nextId = 1;
    var slots = {};
    var lastErr = "";
    var pageHidden = 0;
    var glPack = null;
    var ST_ERROR = -1;
    var ST_CLOSED = 0;
    var ST_PREP = 1;
    var ST_PLAY = 2;
    var ST_PAUSE = 3;
    var ST_ENDED = 4;

    function mimeFromPath(p) {
        p = String(p || "").split("?")[0].toLowerCase();
        if (p.indexOf("data:video/") === 0) {
            var sc = p.indexOf(";");
            return sc > 0 ? p.slice(5, sc) : "video/mp4";
        }
        if (p.slice(-4) === ".mp4" || p.slice(-4) === ".m4v") return "video/mp4";
        if (p.slice(-5) === ".webm") return "video/webm";
        if (p.slice(-4) === ".mov") return "video/quicktime";
        if (p.slice(-4) === ".ogv") return "video/ogg";
        if (p.slice(-4) === ".mkv") return "video/x-matroska";
        return "video/mp4";
    }

    function b64u8(b64) {
        var bin = atob(String(b64 || ""));
        var u = new Uint8Array(bin.length);
        for (var i = 0; i < bin.length; i++) u[i] = bin.charCodeAt(i) & 255;
        return u;
    }

    function makeVideo() {
        var el = document.createElement("video");
        el.muted = true;
        el.defaultMuted = true;
        el.volume = 0;
        el.autoplay = false;
        el.controls = false;
        el.playsInline = true;
        el.preload = "auto";
        el.crossOrigin = "anonymous";
        el.disablePictureInPicture = true;
        el.setAttribute("playsinline", "");
        el.setAttribute("webkit-playsinline", "");
        el.setAttribute("muted", "");
        el.setAttribute("data-pls-gx-video", "1");
        el.style.cssText = "position:fixed;left:0;top:0;width:1px;height:1px;opacity:0;pointer-events:none;z-index:-1;border:0;";
        try { (document.body || document.documentElement).appendChild(el); } catch (e0) {}
        return el;
    }

    function revoke(s) {
        if (!s) return;
        if (s.objectUrl) {
            try { URL.revokeObjectURL(s.objectUrl); } catch (e0) {}
            s.objectUrl = "";
        }
    }

    function attachSrc(s, url, mime) {
        if (!s.el) s.el = makeVideo();
        var el = s.el;
        el.muted = true;
        el.volume = 0;
        s.srcUrl = String(url || "");
        s.mime = mime || mimeFromPath(s.srcUrl);
        try { el.pause(); } catch (e0) {}
        try { el.removeAttribute("src"); el.load(); } catch (e1) {}
        el.src = s.srcUrl;
        try { el.load(); } catch (e2) {}
        if (s.want && !pageHidden) {
            var p = el.play();
            if (p && p.catch) p.catch(function () {});
        }
        return 1;
    }

    function slotOf(id) {
        return slots[id | 0];
    }

    function statusOf(s) {
        if (!s || !s.el) return ST_CLOSED;
        var el = s.el;
        if (el.error) {
            lastErr = "video error";
            return ST_ERROR;
        }
        if (el.ended) return ST_ENDED;
        if (el.readyState < 2) return ST_PREP;
        if (el.paused) return ST_PAUSE;
        return ST_PLAY;
    }

    function pauseAll() {
        var ids = Object.keys(slots);
        for (var i = 0; i < ids.length; i++) {
            var s = slots[ids[i]];
            if (!s || !s.el) continue;
            try { s.el.pause(); } catch (e0) {}
        }
    }

    function onPageHidden(hidden) {
        pageHidden = hidden ? 1 : 0;
        if (hidden) pauseAll();
        else {
            var ids = Object.keys(slots);
            for (var i = 0; i < ids.length; i++) {
                var s = slots[ids[i]];
                if (!s || !s.el || !s.want) continue;
                var p = s.el.play();
                if (p && p.catch) p.catch(function () {});
            }
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
    }

    function getGL() {
        try {
            if (typeof GLctx !== "undefined" && GLctx && GLctx.drawArrays) return GLctx;
        } catch (e0) {}
        try {
            if (typeof GL !== "undefined" && GL && GL.currentContext) {
                return GL.currentContext.GLctx || GL.currentContext;
            }
        } catch (e1) {}
        try {
            if (g.Module && g.Module.ctx && g.Module.ctx.drawArrays) return g.Module.ctx;
        } catch (e2) {}
        try {
            var canvas = document.getElementById("canvas") || document.querySelector("canvas");
            if (canvas) {
                return canvas.getContext("webgl2") || canvas.getContext("webgl") || canvas.getContext("experimental-webgl");
            }
        } catch (e3) {}
        return null;
    }

    function compile(gl, type, src) {
        var sh = gl.createShader(type);
        gl.shaderSource(sh, src);
        gl.compileShader(sh);
        if (!gl.getShaderParameter(sh, gl.COMPILE_STATUS)) {
            lastErr = "shader compile";
            gl.deleteShader(sh);
            return null;
        }
        return sh;
    }

    function ensureGL(gl) {
        if (glPack && glPack.gl === gl && glPack.prog) return glPack;
        var vs = compile(gl, gl.VERTEX_SHADER, [
            "attribute vec2 a_pos;",
            "attribute vec2 a_uv;",
            "varying vec2 v_uv;",
            "void main(){",
            "  gl_Position=vec4(a_pos,0.0,1.0);",
            "  v_uv=a_uv;",
            "}"
        ].join("\n"));
        var fs = compile(gl, gl.FRAGMENT_SHADER, [
            "precision mediump float;",
            "varying vec2 v_uv;",
            "uniform sampler2D u_tex;",
            "uniform float u_alpha;",
            "uniform float u_dim;",
            "void main(){",
            "  vec4 c=texture2D(u_tex,v_uv);",
            "  c.rgb*=(1.0-u_dim);",
            "  c.a*=u_alpha;",
            "  gl_FragColor=c;",
            "}"
        ].join("\n"));
        if (!vs || !fs) return null;
        var prog = gl.createProgram();
        gl.attachShader(prog, vs);
        gl.attachShader(prog, fs);
        gl.bindAttribLocation(prog, 0, "a_pos");
        gl.bindAttribLocation(prog, 1, "a_uv");
        gl.linkProgram(prog);
        if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) {
            lastErr = "shader link";
            return null;
        }
        var buf = gl.createBuffer();
        var tex = gl.createTexture();
        var vao = null;
        try {
            if (typeof gl.createVertexArray === "function") vao = gl.createVertexArray();
        } catch (e0) {}
        glPack = {
            gl: gl,
            prog: prog,
            buf: buf,
            tex: tex,
            vao: vao,
            locPos: gl.getAttribLocation(prog, "a_pos"),
            locUv: gl.getAttribLocation(prog, "a_uv"),
            locTex: gl.getUniformLocation(prog, "u_tex"),
            locAlpha: gl.getUniformLocation(prog, "u_alpha"),
            locDim: gl.getUniformLocation(prog, "u_dim")
        };
        return glPack;
    }

    function corsRetry(s) {
        if (!s || s.corsTried) return;
        var src = String(s.srcUrl || "");
        if (src.indexOf("http://") !== 0 && src.indexOf("https://") !== 0) return;
        s.corsTried = 1;
        try {
            fetch(src).then(function (r) { return r.blob(); }).then(function (blob) {
                revoke(s);
                var url = URL.createObjectURL(blob);
                s.objectUrl = url;
                attachSrc(s, url, blob.type || s.mime);
            }).catch(function () {
                lastErr = "video cors fetch failed";
            });
        } catch (e0) {
            lastErr = "video cors retry failed";
        }
    }

    function drainGL(gl) {
        var n = 0, e = 0, last = 0;
        while (n < 16) {
            e = gl.getError();
            if (!e) break;
            last = e;
            n++;
        }
        return last;
    }

    function uploadVideoTex(gl, pack, el) {
        var w = el.videoWidth | 0, h = el.videoHeight | 0;
        if (w <= 0 || h <= 0) return 0;
        try { if (gl.PIXEL_UNPACK_BUFFER) gl.bindBuffer(gl.PIXEL_UNPACK_BUFFER, null); } catch (e0) {}
        try { gl.pixelStorei(gl.UNPACK_ALIGNMENT, 1); } catch (e1) {}
        try { gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, 1); } catch (e2) {}
        try { gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, 0); } catch (e3) {}
        try {
            if (gl.UNPACK_ROW_LENGTH) {
                gl.pixelStorei(gl.UNPACK_ROW_LENGTH, 0);
                gl.pixelStorei(gl.UNPACK_SKIP_ROWS, 0);
                gl.pixelStorei(gl.UNPACK_SKIP_PIXELS, 0);
            }
        } catch (e4) {}
        drainGL(gl);
        function attempt(name, fn) {
            try {
                fn();
                var err = gl.getError();
                if (!err) {
                    pack.upload = name;
                    pack.texW = w;
                    pack.texH = h;
                    return true;
                }
                lastErr = "texImage2D " + err + " " + name;
            } catch (ex) {
                lastErr = "texImage2D throw " + name + " " + (ex && ex.message ? ex.message : ex);
                drainGL(gl);
            }
            return false;
        }
        var is2 = !!gl.texStorage2D;
        var tries = [];
        if (is2) {
            tries.push(["rgba8-9", function () {
                gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8 || 0x8058, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, el);
            }]);
            tries.push(["rgba-9", function () {
                gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, el);
            }]);
        }
        tries.push(["rgba-6", function () {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, el);
        }]);
        tries.push(["alloc-sub", function () {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
            gl.texSubImage2D(gl.TEXTURE_2D, 0, 0, 0, gl.RGBA, gl.UNSIGNED_BYTE, el);
        }]);
        if (pack.upload) {
            for (var c = 0; c < tries.length; c++) {
                if (tries[c][0] === pack.upload) {
                    if (attempt(pack.upload, tries[c][1])) return 1;
                    pack.upload = "";
                    break;
                }
            }
        }
        for (var i = 0; i < tries.length; i++) {
            drainGL(gl);
            if (attempt(tries[i][0], tries[i][1])) {
                try { console.log("[GXVideo] upload " + pack.upload + " " + w + "x" + h); } catch (eLog) {}
                return 1;
            }
        }
        return -1;
    }

    function drawVideo(s, left, top, right, bottom, alpha, dim) {
        if (!s || !s.el) return 0;
        if (!(right > left) || !(bottom > top)) return 1;
        var el = s.el;
        if (s.want && el.paused && !pageHidden) {
            el.muted = true;
            el.volume = 0;
            var playp = el.play();
            if (playp && playp.catch) playp.catch(function () {});
        }
        if (el.readyState < 2 || el.videoWidth <= 0 || el.videoHeight <= 0) return 0;
        var gl = getGL();
        if (!gl) {
            lastErr = "no webgl";
            return -1;
        }
        var pack = ensureGL(gl);
        if (!pack) return -1;
        var prevProg = gl.getParameter(gl.CURRENT_PROGRAM);
        var prevBuf = gl.getParameter(gl.ARRAY_BUFFER_BINDING);
        var prevTex = gl.getParameter(gl.TEXTURE_BINDING_2D);
        var prevActive = gl.getParameter(gl.ACTIVE_TEXTURE);
        var prevUnpack = null;
        try { if (gl.PIXEL_UNPACK_BUFFER) prevUnpack = gl.getParameter(gl.PIXEL_UNPACK_BUFFER_BINDING); } catch (eU) {}
        var prevVAO = null;
        try { prevVAO = gl.getParameter(gl.VERTEX_ARRAY_BINDING); } catch (e0) {}
        var prevBlend = gl.isEnabled(gl.BLEND);
        var prevDepth = gl.isEnabled(gl.DEPTH_TEST);
        var prevCull = gl.isEnabled(gl.CULL_FACE);
        var prevScissor = gl.isEnabled(gl.SCISSOR_TEST);
        var prevStencil = gl.isEnabled(gl.STENCIL_TEST);
        var prevDepthMask = gl.getParameter(gl.DEPTH_WRITEMASK);
        var prevColorMask = gl.getParameter(gl.COLOR_WRITEMASK);
        var prevBlendSrcRGB = gl.getParameter(gl.BLEND_SRC_RGB);
        var prevBlendDstRGB = gl.getParameter(gl.BLEND_DST_RGB);
        var prevBlendSrcA = gl.getParameter(gl.BLEND_SRC_ALPHA);
        var prevBlendDstA = gl.getParameter(gl.BLEND_DST_ALPHA);
        var prevEqRGB = gl.getParameter(gl.BLEND_EQUATION_RGB);
        var prevEqA = gl.getParameter(gl.BLEND_EQUATION_ALPHA);
        drainGL(gl);
        var ok = 1;
        try {
            if (pack.vao) gl.bindVertexArray(pack.vao);
            gl.useProgram(pack.prog);
            gl.activeTexture(gl.TEXTURE0);
            gl.bindTexture(gl.TEXTURE_2D, pack.tex);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
            if (uploadVideoTex(gl, pack, el) <= 0) {
                ok = -1;
            } else {
                var x1 = left * 2 - 1;
                var x2 = right * 2 - 1;
                var y1 = 1 - top * 2;
                var y2 = 1 - bottom * 2;
                var verts = new Float32Array([
                    x1, y1, 0, 0,
                    x2, y1, 1, 0,
                    x1, y2, 0, 1,
                    x2, y2, 1, 1
                ]);
                gl.bindBuffer(gl.ARRAY_BUFFER, pack.buf);
                gl.bufferData(gl.ARRAY_BUFFER, verts, gl.DYNAMIC_DRAW);
                gl.enableVertexAttribArray(pack.locPos);
                gl.vertexAttribPointer(pack.locPos, 2, gl.FLOAT, false, 16, 0);
                gl.enableVertexAttribArray(pack.locUv);
                gl.vertexAttribPointer(pack.locUv, 2, gl.FLOAT, false, 16, 8);
                gl.uniform1i(pack.locTex, 0);
                gl.uniform1f(pack.locAlpha, alpha);
                gl.uniform1f(pack.locDim, dim);
                gl.disable(gl.DEPTH_TEST);
                gl.disable(gl.CULL_FACE);
                gl.disable(gl.STENCIL_TEST);
                gl.disable(gl.SCISSOR_TEST);
                gl.depthMask(false);
                gl.colorMask(true, true, true, true);
                gl.enable(gl.BLEND);
                gl.blendEquation(gl.FUNC_ADD);
                gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
                gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
            }
        } catch (e1) {
            lastErr = "gl draw failed " + (e1 && e1.message ? e1.message : e1);
            if (String(lastErr).indexOf("Security") >= 0 || String(lastErr).indexOf("tainted") >= 0) corsRetry(s);
            ok = -1;
        }
        try { gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, 0); } catch (e2) {}
        try {
            if (gl.PIXEL_UNPACK_BUFFER) gl.bindBuffer(gl.PIXEL_UNPACK_BUFFER, prevUnpack);
        } catch (e4) {}
        try {
            if (pack.vao) gl.bindVertexArray(prevVAO);
            gl.bindBuffer(gl.ARRAY_BUFFER, prevBuf);
            gl.useProgram(prevProg);
            gl.activeTexture(prevActive);
            gl.bindTexture(gl.TEXTURE_2D, prevTex);
            if (prevBlend) gl.enable(gl.BLEND); else gl.disable(gl.BLEND);
            if (prevDepth) gl.enable(gl.DEPTH_TEST); else gl.disable(gl.DEPTH_TEST);
            if (prevCull) gl.enable(gl.CULL_FACE); else gl.disable(gl.CULL_FACE);
            if (prevScissor) gl.enable(gl.SCISSOR_TEST); else gl.disable(gl.SCISSOR_TEST);
            if (prevStencil) gl.enable(gl.STENCIL_TEST); else gl.disable(gl.STENCIL_TEST);
            gl.depthMask(!!prevDepthMask);
            gl.colorMask(!!prevColorMask[0], !!prevColorMask[1], !!prevColorMask[2], !!prevColorMask[3]);
            gl.blendEquationSeparate(prevEqRGB, prevEqA);
            gl.blendFuncSeparate(prevBlendSrcRGB, prevBlendDstRGB, prevBlendSrcA, prevBlendDstA);
        } catch (e3) {}
        return ok;
    }

    bind("i_gx_video_ping", function () { return 1; });
    bind("i_gx_video_last_error", function () { return lastErr || ""; });
    bind("i_gx_video_begin", function (mime) {
        lastErr = "";
        var id = nextId++;
        slots[id] = { mime: String(mime || "video/mp4"), parts: [], total: 0, want: 0, el: null, objectUrl: "", srcUrl: "", corsTried: 0 };
        return id;
    });
    bind("i_gx_video_append", function (id, b64) {
        var s = slotOf(id);
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
    bind("i_gx_video_end", function (id) {
        var s = slotOf(id);
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
        revoke(s);
        var blob = new Blob([u], { type: s.mime || "video/mp4" });
        var url = URL.createObjectURL(blob);
        s.objectUrl = url;
        s.el = s.el || makeVideo();
        return attachSrc(s, url, s.mime);
    });
    bind("i_gx_video_create", function (path) {
        lastErr = "";
        var p = String(path || "");
        var id = nextId++;
        var s = slots[id] = { mime: mimeFromPath(p), parts: [], total: 0, want: 0, el: makeVideo(), objectUrl: "", srcUrl: "", corsTried: 0 };
        if (p.indexOf("http://") === 0 || p.indexOf("https://") === 0 || p.indexOf("blob:") === 0 || p.indexOf("data:") === 0) {
            return attachSrc(s, p, s.mime) ? id : 0;
        }
        lastErr = "path needs url";
        delete slots[id];
        return 0;
    });
    bind("i_gx_video_play", function (id) {
        var s = slotOf(id);
        if (!s || !s.el) return 0;
        s.want = 1;
        if (pageHidden) return 1;
        s.el.muted = true;
        s.el.volume = 0;
        var p = s.el.play();
        if (p && p.catch) p.catch(function () {});
        return 1;
    });
    bind("i_gx_video_pause", function (id) {
        var s = slotOf(id);
        if (!s || !s.el) return 0;
        s.want = 0;
        try { s.el.pause(); } catch (e0) {}
        return 1;
    });
    bind("i_gx_video_stop", function (id) {
        var s = slotOf(id);
        if (!s || !s.el) return 0;
        s.want = 0;
        try { s.el.pause(); s.el.currentTime = 0; } catch (e0) {}
        return 1;
    });
    bind("i_gx_video_seek_ms", function (id, ms) {
        var s = slotOf(id);
        if (!s || !s.el) return 0;
        var sec = Math.max(0, Number(ms) / 1000);
        try { s.el.currentTime = sec; } catch (e0) { return 0; }
        return 1;
    });
    bind("i_gx_video_get_position_ms", function (id) {
        var s = slotOf(id);
        if (!s || !s.el) return 0;
        return (s.el.currentTime || 0) * 1000;
    });
    bind("i_gx_video_get_length_ms", function (id) {
        var s = slotOf(id);
        if (!s || !s.el) return 0;
        var d = s.el.duration;
        return isFinite(d) ? d * 1000 : 0;
    });
    bind("i_gx_video_get_width", function (id) {
        var s = slotOf(id);
        if (!s || !s.el) return 0;
        return s.el.videoWidth || 0;
    });
    bind("i_gx_video_get_height", function (id) {
        var s = slotOf(id);
        if (!s || !s.el) return 0;
        return s.el.videoHeight || 0;
    });
    bind("i_gx_video_get_status", function (id) {
        return statusOf(slotOf(id));
    });
    bind("i_gx_video_set_loop", function (id, enabled) {
        var s = slotOf(id);
        if (!s || !s.el) return 0;
        s.el.loop = Number(enabled) > 0;
        return 1;
    });
    bind("i_gx_video_draw", function (id, left, top, right, bottom, alpha, dim) {
        return drawVideo(slotOf(id), Number(left) || 0, Number(top) || 0, Number(right) || 0, Number(bottom) || 0, Number(alpha), Number(dim));
    });
    function releaseSlot(id, s) {
        if (!s) return 0;
        if (s.el) {
            try { s.el.pause(); s.el.removeAttribute("src"); s.el.load(); } catch (e0) {}
            try { if (s.el.parentNode) s.el.parentNode.removeChild(s.el); } catch (e1) {}
            s.el = null;
        }
        s.parts = [];
        s.want = 0;
        revoke(s);
        if (id != null) delete slots[id | 0];
        return 1;
    }
    function shutdownVideos() {
        var ids = Object.keys(slots);
        var i;
        for (i = 0; i < ids.length; i++) releaseSlot(ids[i] | 0, slots[ids[i]]);
        slots = {};
        try {
            var nodes = document.querySelectorAll("video[data-pls-gx-video]");
            for (i = 0; i < nodes.length; i++) {
                var el = nodes[i];
                try { el.pause(); el.removeAttribute("src"); el.load(); } catch (e2) {}
                try { if (el.parentNode) el.parentNode.removeChild(el); } catch (e3) {}
            }
        } catch (e4) {}
        lastErr = "";
        return 1;
    }
    bind("i_gx_video_release", function (id) {
        var s = slotOf(id);
        if (!s) return 0;
        return releaseSlot(id, s);
    });
    bind("i_gx_video_shutdown", shutdownVideos);
})(typeof globalThis !== "undefined" ? globalThis : window);
