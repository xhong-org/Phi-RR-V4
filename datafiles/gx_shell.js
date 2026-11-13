/* GX.Games browser lifecycle. Fullscreen belongs to the document so file/UI
 * overlays remain usable. A denied request never counts as fullscreen. */
(function (g) {
    "use strict";
    if (g.PhiGX) return;
    var d = g.document;
    var mobile = /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent)
        || (navigator.maxTouchPoints > 1 && /Macintosh/i.test(navigator.userAgent));
    var picking = false, pending = null, gate, button, entered = false, blocked = false;
    var locale = /^zh\b/i.test(navigator.language) ? "zh-CN" : "en-US";
    var inputEvents = [], keyPresses = [], keys = {}, contacts = {}, generation = 0;
    var resizeQueued = false;
    function resetInput() {
        inputEvents = []; keyPresses = []; keys = {}; contacts = {}; generation++;
    }
    function focusCanvas() {
        var canvas = d.getElementById("canvas");
        if (canvas) { canvas.tabIndex = 0; canvas.focus({ preventScroll:true }); }
    }
    function resizeCanvas() {
        var canvas = d.getElementById("canvas"), module = g.Module;
        if (!canvas || !canvas.classList.contains("active") || !module || !module.phiResizeCanvas) return;
        var rect = canvas.getBoundingClientRect(), ratio = g.devicePixelRatio || 1;
        if (rect.width < 1 || rect.height < 1) return;
        var gl = module.phiGLContext && module.phiGLContext();
        var limit = gl ? gl.getParameter(gl.MAX_RENDERBUFFER_SIZE) : 8192;
        ratio = Math.min(ratio, limit / rect.width, limit / rect.height);
        var width = Math.max(1, Math.round(rect.width * ratio)), height = Math.max(1, Math.round(rect.height * ratio));
        if (canvas.width !== width || canvas.height !== height) {
            module.phiResizeCanvas(width, height);
            canvas.style.width = rect.width + "px";
            canvas.style.height = rect.height + "px";
        }
    }
    function scheduleCanvasResize() {
        if (resizeQueued) return;
        resizeQueued = true;
        g.requestAnimationFrame(function () { resizeQueued = false; resizeCanvas(); });
    }
    function pollInput() {
        var now = performance.now(), focused = !d.hidden && !picking && !blocked && d.hasFocus();
        if (!focused) resetInput();
        var packet = { generation:generation, focused:focused,
            keys:Object.keys(keys).map(Number), presses:keyPresses.map(function (e) { return [e[0], Math.max(0, now-e[1])]; }),
            events:inputEvents.map(function (e) { return [e[0],e[1],e[2],e[3],Math.max(0,now-e[4])]; }) };
        inputEvents = []; keyPresses = [];
        return JSON.stringify(packet);
    }
    function installInput() {
        function editable(target) { return target && (target.isContentEditable || /^(INPUT|TEXTAREA|SELECT|BUTTON)$/.test(target.tagName)); }
        d.addEventListener("keydown", function (ev) {
            if (editable(ev.target) || blocked || picking) return;
            var code = /^Key[A-Z]$/.test(ev.code) ? ev.code.charCodeAt(3) : ev.keyCode;
            if (code < 65 || code > 90) return;
            if (!keys[code] && !ev.repeat) keyPresses.push([code,performance.now()]);
            keys[code] = true; ev.preventDefault();
        }, true);
        d.addEventListener("keyup", function (ev) {
            var code = /^Key[A-Z]$/.test(ev.code) ? ev.code.charCodeAt(3) : ev.keyCode;
            delete keys[code];
        }, true);
        function pointer(ev, kind) {
            var canvas = d.getElementById("canvas");
            if (!canvas || blocked || picking) return;
            if (kind === 1) {
                if (ev.target !== canvas || ev.button > 0) return;
                focusCanvas(); contacts[ev.pointerId] = true;
                try { canvas.setPointerCapture(ev.pointerId); } catch (err) {}
            } else if (!contacts[ev.pointerId]) return;
            var rect = canvas.getBoundingClientRect();
            var stamp = ev.timeStamp;
            if (!isFinite(stamp) || Math.abs(stamp-performance.now()) > 60000) stamp = performance.now();
            inputEvents.push([kind,ev.pointerId,(ev.clientX-rect.left)/Math.max(1,rect.width),(ev.clientY-rect.top)/Math.max(1,rect.height),stamp]);
            if (inputEvents.length > 4096) resetInput();
            if (kind === 3) delete contacts[ev.pointerId];
            if (ev.pointerType !== "mouse" && ev.cancelable) ev.preventDefault();
        }
        d.addEventListener("pointerdown", function (ev) { pointer(ev,1); }, {capture:true,passive:false});
        d.addEventListener("pointermove", function (ev) {
            var samples = ev.getCoalescedEvents ? ev.getCoalescedEvents() : [];
            if (!samples.length) samples = [ev];
            for (var i=0;i<samples.length;i++) pointer(samples[i],2);
        }, {capture:true,passive:false});
        d.addEventListener("pointerup", function (ev) { pointer(ev,3); }, {capture:true,passive:false});
        d.addEventListener("pointercancel", resetInput, true);
        g.addEventListener("blur", resetInput);
        d.addEventListener("visibilitychange", function () { if (d.hidden) resetInput(); });
        d.addEventListener("pls-gx-fullscreen", function (ev) { if (ev.detail.suspended) resetInput(); });
    }
    function zh() { return locale === "zh-CN"; }
    function fullscreen() {
        return !!(d.fullscreenElement || d.webkitFullscreenElement
            || g.matchMedia("(display-mode: fullscreen)").matches);
    }
    function supported() {
        return !!(d.documentElement.requestFullscreen || d.documentElement.webkitRequestFullscreen);
    }
    function resize() {
        if (typeof g.ensureAspectRatio === "function") g.ensureAspectRatio();
        g.dispatchEvent(new Event("resize"));
    }
    function render(force) {
        if (!gate) return;
        var active = fullscreen();
        var suspended = mobile && (!active || picking);
        if (blocked !== suspended || force === true) {
            blocked = suspended;
            d.dispatchEvent(new CustomEvent("pls-gx-fullscreen", { detail: { suspended: blocked } }));
            var lifecycle = blocked ? g.GM_pause : g.GM_unpause;
            if (typeof lifecycle === "function") lifecycle();
        }
        gate.hidden = !mobile || active || picking;
        button.hidden = mobile;
        button.textContent = active ? (zh() ? "退出全屏" : "Exit fullscreen") : (zh() ? "全屏" : "Fullscreen");
        var title = gate.querySelector("strong");
        var detail = gate.querySelector("p");
        var action = gate.querySelector("button");
        title.textContent = zh() ? "Phi-RR · 全屏游玩" : "Phi-RR · Fullscreen play";
        action.textContent = entered ? (zh() ? "点击恢复全屏" : "Tap to restore fullscreen")
            : (zh() ? "点击进入全屏" : "Tap to enter fullscreen");
        detail.textContent = supported()
            ? (zh() ? "横屏体验更佳。选择文件后若退出全屏，请在此恢复。"
                : "Landscape works best. Restore fullscreen here after choosing a file.")
            : (zh() ? "此浏览器未提供页面全屏功能，请使用支持全屏的浏览器打开。"
                : "This browser does not provide page fullscreen. Open this page in a browser that supports it.");
        action.disabled = !supported();
    }
    function request() {
        if (fullscreen()) { render(); return Promise.resolve(true); }
        if (picking || pending || !supported()) { render(); return pending || Promise.resolve(false); }
        var target = d.documentElement;
        var fn = target.requestFullscreen || target.webkitRequestFullscreen;
        try {
            var result = fn.call(target, { navigationUI: "hide" });
            pending = Promise.resolve(result).then(function () {
                entered = fullscreen();
                if (entered && mobile && screen.orientation && screen.orientation.lock) {
                    screen.orientation.lock("landscape").catch(function () {});
                }
                return entered;
            }, function () { return false; }).finally(function () { pending = null; render(); resize(); if (fullscreen()) focusCanvas(); });
            return pending;
        } catch (err) { render(); return Promise.resolve(false); }
    }
    function pickerOpened() { picking = true; resetInput(); render(); }
    function pickerReturned() {
        if (!picking) return;
        picking = false;
        focusCanvas();
        render();
        // Some browsers retain activation through change/cancel; others require
        // the visible recovery button. Both paths check the actual DOM state.
        if (mobile && !fullscreen()) request();
        setTimeout(function () { render(); resize(); }, 150);
    }
    function init() {
        installInput();
        // The runner also changes canvas attributes after fullscreen callbacks.
        // Reconcile those later writes through Emscripten's resize listeners.
        var canvas = d.getElementById("canvas");
        if (canvas) {
            new MutationObserver(scheduleCanvasResize).observe(canvas,
                {attributes:true,attributeFilter:["width","height","class"]});
            if (g.ResizeObserver) new ResizeObserver(scheduleCanvasResize).observe(canvas);
        }
        var style = d.createElement("style");
        style.textContent = "html,body{margin:0!important;padding:0!important;background:#080d18;overflow:hidden;width:100%;height:100%;min-width:0!important;min-height:0!important}"
            + "body{height:100dvh}canvas#canvas{max-width:100vw;max-height:100dvh;touch-action:none}"
            + "#pls-gx-fs-gate[hidden],#pls-gx-fullscreen[hidden]{display:none!important}"
            + "#pls-gx-fs-gate{position:fixed;inset:0;z-index:2147483647;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:20px;background:#080d18;color:#ecf3ff;text-align:center;box-sizing:border-box;padding:max(24px,env(safe-area-inset-top)) max(24px,env(safe-area-inset-right)) max(24px,env(safe-area-inset-bottom)) max(24px,env(safe-area-inset-left));font:18px/1.6 system-ui,sans-serif}"
            + "#pls-gx-fs-gate strong{font-size:clamp(24px,5vw,38px)}#pls-gx-fs-gate p{max-width:36em;color:#abbcd6;margin:0}"
            + "#pls-gx-fs-gate button,#pls-gx-fullscreen{font:inherit;border:1px solid #7c9bc3;border-radius:10px;background:#213b60;color:white;padding:14px 24px;cursor:pointer}"
            + "#pls-gx-fullscreen{position:fixed;right:max(12px,env(safe-area-inset-right));bottom:max(12px,env(safe-area-inset-bottom));z-index:2147483643;font:14px system-ui,sans-serif;padding:10px 16px;opacity:.85}"
            + "#pls-gx-fs-gate button:disabled{opacity:.45;cursor:default}";
        d.head.appendChild(style);
        gate = d.createElement("div");
        gate.id = "pls-gx-fs-gate";
        gate.setAttribute("role", "dialog");
        gate.setAttribute("aria-modal", "true");
        gate.innerHTML = "<strong></strong><p></p><button type='button'></button>";
        gate.addEventListener("click", function (ev) { ev.preventDefault(); ev.stopPropagation(); request(); });
        d.body.appendChild(gate);
        button = d.createElement("button");
        button.id = "pls-gx-fullscreen";
        button.type = "button";
        button.addEventListener("click", function () {
            if (fullscreen()) {
                var exit = d.exitFullscreen || d.webkitExitFullscreen;
                if (exit) Promise.resolve(exit.call(d)).catch(function () {});
            } else request();
        });
        d.body.appendChild(button);
        function changed() { entered = entered || fullscreen(); render(); resize(); }
        d.addEventListener("fullscreenchange", changed);
        d.addEventListener("webkitfullscreenchange", changed);
        d.addEventListener("fullscreenerror", render);
        g.addEventListener("focus", function () { if (picking) setTimeout(pickerReturned, 150); });
        g.addEventListener("pageshow", function () { render(); resize(); });
        d.addEventListener("visibilitychange", function () {
            if (d.visibilityState === "visible") { if (picking) pickerReturned(); else render(); }
        });
        d.addEventListener("pointerup", function (ev) {
            if (!mobile || fullscreen() || picking || ev.target.closest("input[type=file]")) return;
            request();
        }, true);
        render();
        // This is allowed to fail without activation; the first real touch then
        // performs the mandatory request through the gate above.
        if (mobile) request();
    }
    g.PhiGX = { isMobile: mobile, fullscreen: fullscreen, requestFullscreen: request,
        runtimeReady: function () { render(true); resize(); focusCanvas(); },
        resizeCanvas:resizeCanvas, pollInput:pollInput, resetInput:resetInput,
        suspended: function () { return mobile && (picking || !fullscreen()); },
        pickerOpened: pickerOpened, pickerReturned: pickerReturned,
        setLocale: function (value) { locale = value === "zh-CN" ? "zh-CN" : "en-US"; render(); } };
    if (d.readyState === "loading") d.addEventListener("DOMContentLoaded", init); else init();
})(window);
