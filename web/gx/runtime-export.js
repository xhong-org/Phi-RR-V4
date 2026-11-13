// Processed by Emscripten before Closure minification. Keep public keys stable
// while allowing the compiler to rename its internal FS functions.
(function () {
    // GameMaker also syncs after native writes. Serialize both native and JS
    // requests so skin extraction cannot race dozens of IndexedDB transactions.
    var original = FS.syncfs;
    var active = false, queue = [];
    FS.syncfs = function (populate, callback) {
        var last = queue[queue.length - 1];
        if (!populate && last && !last.populate) last.callbacks.push(callback);
        else queue.push({ populate: populate, callbacks: [callback] });
        if (!active) drain();
    };
    function drain() {
        if (!queue.length) { active = false; return; }
        active = true;
        var next = queue.shift();
        original.call(FS, next.populate, function (error) {
            for (var i = 0; i < next.callbacks.length; i++) {
                if (typeof next.callbacks[i] === 'function') next.callbacks[i](error);
            }
            drain();
        });
    }
})();
Module["FS"] = {
    "readFile": function (path, options) { return FS.readFile(path, options); },
    "writeFile": function (path, bytes) { return FS.writeFile(path, bytes); },
    "mkdirTree": function (path) { return FS.mkdirTree(path); },
    "readdir": function (path) { return FS.readdir(path); },
    "stat": function (path) { return FS.stat(path); },
    "isDir": function (mode) { return FS.isDir(mode); },
    "unlink": function (path) { return FS.unlink(path); },
    "rmdir": function (path) { return FS.rmdir(path); },
    "syncfs": function (populate, callback) { return FS.syncfs(populate, callback); }
};
Module["phiGLContext"] = function () { return GLctx; };
Module["phiResizeCanvas"] = function (width, height) { Browser.setCanvasSize(width, height); };
