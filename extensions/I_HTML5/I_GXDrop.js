/**
 * GX.games chart import. JS extensions are not stored in the .unx; this file
 * must also run as page script (included file + HTML prepend).
 *
 * Opera GX treats canvas drops as downloads; drag handlers also crashed
 * the browser. Do not attach drag listeners. The overlay pick control is a
 * native file input covering the "选择文件" button (real click, not
 * input.click() on a hidden 1x1 field). Do not cover the GML menu button.
 *
 * File pick is async (FileReader / arrayBuffer). Write the zip to MEMFS in
 * that callback. Focus the canvas before hiding the overlay: hiding a focused
 * <input> leaves GameMaker's focuscb on blur and the runner stays paused.
 * Do not dispatch synthetic focus events (that re-enters the focus listener).
 * Do not call resumeMainLoop from GML Step or before canvas.active.
 */
(function (global) {
    "use strict";
    if (global.__plsGxDropLoaded26) {
        global.__plsGxDropVer = 26;
        try { if (typeof global.i_gx_drop_boot === "function") global.i_gx_drop_boot(); } catch (e0) {}
        return;
    }
    global.__plsGxDropLoaded26 = 1;
    global.__plsGxDropVer = 26;

    var STATUS_IDLE = 0;
    var STATUS_HOVER = 1;
    var STATUS_READING = 2;
    var STATUS_OK = 3;
    var STATUS_ERROR = 4;

    var state = {
        status: STATUS_IDLE,
        hover: 0,
        name: "",
        error: "",
        bytes: null,
        importedPath: "",
        enabled: 0
    };

    var pickRect = null;
    var booted = 0;
    var dropLayerOpen = 0;
    var lastUnzipError = "";
    var lastUnzipCount = 0;
    var lastListText = "";
    var readFileBytes = null;
    var lastReadChunk = "";
    var lastHeadText = "";
    var extractedFiles = {};
    var extractedList = [];
    var importedZipBytes = null;

    function isLoopbackHost() {
        try {
            var h = String(window.location.hostname || "").toLowerCase();
            return h === "127.0.0.1" || h === "localhost" || h === "::1" || h === "[::1]" || h === "" || h === "0.0.0.0";
        } catch (e) {
            return true;
        }
    }

    function isRemoteMode() {
        try {
            if (window.sessionStorage && sessionStorage.getItem("plsGxRemote") === "1") return true;
        } catch (e0) {}
        try {
            var u = new URL(window.location.href);
            var q = String(u.searchParams.get("pls_remote") || "").toLowerCase();
            if (q === "1" || q === "true" || q === "yes") {
                try { sessionStorage.setItem("plsGxRemote", "1"); } catch (e1) {}
                return true;
            }
            if (q === "0" || q === "false" || q === "no") return false;
        } catch (e2) {}
        return !isLoopbackHost();
    }

    function persistFs(done) {
        var finished = 0;
        function finish() {
            if (finished) return;
            finished = 1;
            if (typeof done === "function") done();
        }
        var pending = 0;
        eachModule(function (m) {
            if (!m || !m.FS || typeof m.FS.syncfs !== "function") return;
            pending++;
            try {
                m.FS.syncfs(false, function () {
                    pending--;
                    if (pending <= 0) finish();
                });
            } catch (e0) {
                pending--;
            }
        });
        if (pending <= 0) finish();
        setTimeout(finish, 400);
    }

    function wipeFsPath(raw) {
        var p = toStr(raw).replace(/\\/g, "/");
        if (!p) return 0;
        while (p.length > 1 && p.charAt(p.length - 1) === "/") p = p.slice(0, -1);
        var lower = p.toLowerCase();
        var allowed = lower.indexOf("/tmp/pls") === 0
            || lower.indexOf("/_savedata/track") === 0 || lower === "/_savedata/track"
            || lower.indexOf("/savedata/track") === 0 || lower === "/savedata/track"
            || lower.indexOf("/_savedata/charts") === 0 || lower === "/_savedata/charts"
            || lower.indexOf("/savedata/charts") === 0 || lower === "/savedata/charts"
            || /\/track$/i.test(p);
        if (!allowed) return 0;
        if (lower.indexOf("/tmp/pls") === 0
            || lower.indexOf("/_savedata/track") === 0
            || lower.indexOf("/savedata/track") === 0
            || /\/track$/i.test(p)) {
            clearExtracted();
        }
        var fs = getFS();
        if (!fs) return 1;
        function rm(path) {
            try {
                var st = fs.stat(path);
                if (st && typeof fs.isDir === "function" && fs.isDir(st.mode)) {
                    var names = fs.readdir(path) || [];
                    for (var i = 0; i < names.length; i++) {
                        if (names[i] === "." || names[i] === "..") continue;
                        rm(path + "/" + names[i]);
                    }
                    try { fs.rmdir(path); } catch (e1) {}
                } else if (typeof fs.unlink === "function") {
                    fs.unlink(path);
                }
            } catch (e2) {}
        }
        rm(p);
        try { if (typeof fs.unlink === "function") fs.unlink(p + "/extra.json"); } catch (e3) {}
        return 1;
    }

    function wipeExtractDirs() {
        wipeFsPath("/tmp/pls");
        wipeFsPath("/tmp/pls/track");
        wipeFsPath("/tmp/pls/tmp");
        wipeFsPath("/_savedata/track");
        wipeFsPath("/savedata/track");
        wipeFsPath("/_savedata/charts");
        wipeFsPath("/savedata/charts");
        wipeFsPath("/_savedata/tmp");
        wipeFsPath("/savedata/tmp");
    }

    function zipU16(b, o) {
        return b[o] | (b[o + 1] << 8);
    }

    function zipU32(b, o) {
        return (b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24)) >>> 0;
    }

    function zipInflateRaw(src) {
        var pos = 0;
        var bitBuf = 0;
        var bitCnt = 0;
        var out = new Uint8Array(Math.max(1024, src.length * 4));
        var outLen = 0;
        function putByte(v) {
            if (outLen >= out.length) {
                var grown = new Uint8Array(out.length * 2);
                grown.set(out);
                out = grown;
            }
            out[outLen++] = v & 255;
        }
        var LEN_BASE = [3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258];
        var LEN_EXTRA = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0];
        var DIST_BASE = [1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577];
        var DIST_EXTRA = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13];
        var CL_ORDER = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

        function bits(n) {
            while (bitCnt < n) {
                if (pos >= src.length) throw new Error("deflate truncated");
                bitBuf |= src[pos++] << bitCnt;
                bitCnt += 8;
            }
            var v = bitBuf & ((1 << n) - 1);
            bitBuf >>>= n;
            bitCnt -= n;
            return v;
        }

        function buildHuff(lengths) {
            var maxLen = 0;
            var i;
            for (i = 0; i < lengths.length; i++) {
                if (lengths[i] > maxLen) maxLen = lengths[i];
            }
            var blCount = [];
            for (i = 0; i <= maxLen; i++) blCount[i] = 0;
            for (i = 0; i < lengths.length; i++) blCount[lengths[i]]++;
            blCount[0] = 0;
            var nextCode = [];
            var code = 0;
            nextCode[0] = 0;
            for (i = 1; i <= maxLen; i++) {
                code = (code + blCount[i - 1]) << 1;
                nextCode[i] = code;
            }
            var symbols = [];
            for (i = 0; i <= maxLen; i++) symbols[i] = {};
            for (i = 0; i < lengths.length; i++) {
                var len = lengths[i];
                if (!len) continue;
                symbols[len][nextCode[len]] = i;
                nextCode[len]++;
            }
            return { maxLen: maxLen, symbols: symbols };
        }

        function decodeSym(huff) {
            var code = 0;
            var len;
            for (len = 1; len <= huff.maxLen; len++) {
                code = (code << 1) | bits(1);
                if (Object.prototype.hasOwnProperty.call(huff.symbols[len], code)) {
                    return huff.symbols[len][code];
                }
            }
            throw new Error("bad deflate huffman");
        }

        function fixedLit() {
            var lengths = [];
            var i;
            for (i = 0; i <= 143; i++) lengths[i] = 8;
            for (i = 144; i <= 255; i++) lengths[i] = 9;
            for (i = 256; i <= 279; i++) lengths[i] = 7;
            for (i = 280; i <= 287; i++) lengths[i] = 8;
            return buildHuff(lengths);
        }

        function fixedDist() {
            var lengths = [];
            var i;
            for (i = 0; i < 32; i++) lengths[i] = 5;
            return buildHuff(lengths);
        }

        function copyMatch(len, dist) {
            var from = outLen - dist;
            if (from < 0) throw new Error("bad deflate distance");
            var i;
            for (i = 0; i < len; i++) putByte(out[from + i]);
        }

        function inflateBlock(lit, dist) {
            for (;;) {
                var sym = decodeSym(lit);
                if (sym < 256) {
                    putByte(sym);
                } else if (sym === 256) {
                    return;
                } else {
                    var li = sym - 257;
                    if (li < 0 || li >= LEN_BASE.length) throw new Error("bad deflate length");
                    var length = LEN_BASE[li] + (LEN_EXTRA[li] ? bits(LEN_EXTRA[li]) : 0);
                    var di = decodeSym(dist);
                    if (di < 0 || di >= DIST_BASE.length) throw new Error("bad deflate dist");
                    var distance = DIST_BASE[di] + (DIST_EXTRA[di] ? bits(DIST_EXTRA[di]) : 0);
                    copyMatch(length, distance);
                }
            }
        }

        var litFixed = null;
        var distFixed = null;
        for (;;) {
            var bfinal = bits(1);
            var btype = bits(2);
            if (btype === 0) {
                bitBuf = 0;
                bitCnt = 0;
                if (pos + 4 > src.length) throw new Error("deflate stored truncated");
                var len = src[pos] | (src[pos + 1] << 8);
                var nlen = src[pos + 2] | (src[pos + 3] << 8);
                pos += 4;
                if ((len ^ 0xffff) !== nlen) throw new Error("deflate stored nlen");
                if (pos + len > src.length) throw new Error("deflate stored data");
                var si;
                for (si = 0; si < len; si++) putByte(src[pos++]);
            } else if (btype === 1) {
                if (!litFixed) {
                    litFixed = fixedLit();
                    distFixed = fixedDist();
                }
                inflateBlock(litFixed, distFixed);
            } else if (btype === 2) {
                var hlit = bits(5) + 257;
                var hdist = bits(5) + 1;
                var hclen = bits(4) + 4;
                var clens = [];
                var ci;
                for (ci = 0; ci < 19; ci++) clens[ci] = 0;
                for (ci = 0; ci < hclen; ci++) clens[CL_ORDER[ci]] = bits(3);
                var clTree = buildHuff(clens);
                var all = [];
                var need = hlit + hdist;
                while (all.length < need) {
                    var c = decodeSym(clTree);
                    if (c < 16) {
                        all.push(c);
                    } else if (c === 16) {
                        if (!all.length) throw new Error("deflate cl 16");
                        var r16 = 3 + bits(2);
                        var prev = all[all.length - 1];
                        while (r16--) all.push(prev);
                    } else if (c === 17) {
                        var r17 = 3 + bits(3);
                        while (r17--) all.push(0);
                    } else if (c === 18) {
                        var r18 = 11 + bits(7);
                        while (r18--) all.push(0);
                    } else {
                        throw new Error("deflate cl");
                    }
                }
                inflateBlock(buildHuff(all.slice(0, hlit)), buildHuff(all.slice(hlit, hlit + hdist)));
            } else {
                throw new Error("deflate btype");
            }
            if (bfinal) break;
        }
        return out.subarray(0, outLen);
    }

    function zipDecodeName(bytes, utf8) {
        if (utf8 && typeof TextDecoder !== "undefined") {
            try { return new TextDecoder("utf-8").decode(bytes); } catch (e0) {}
        }
        var s = "";
        var i;
        for (i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
        return s;
    }

    function zipFindEocd(b) {
        var min = Math.max(0, b.length - 22 - 65535);
        var i;
        for (i = b.length - 22; i >= min; i--) {
            if (zipU32(b, i) === 0x06054b50) return i;
        }
        return -1;
    }

    function unzipBytesToFs(fs, zip, destRoot) {
        var eocd = zipFindEocd(zip);
        if (eocd < 0) throw new Error("zip eocd missing");
        var entries = zipU16(zip, eocd + 10);
        var cdSize = zipU32(zip, eocd + 12);
        var cdOff = zipU32(zip, eocd + 16);
        if (entries === 0xffff || cdSize === 0xffffffff || cdOff === 0xffffffff) {
            throw new Error("zip64 not supported");
        }
        if (cdOff + cdSize > zip.length) throw new Error("zip central truncated");
        if (fs && typeof fs.mkdirTree === "function") {
            try { fs.mkdirTree(destRoot); } catch (eMk) {}
        }
        var wrote = 0;
        var p = cdOff;
        var n;
        var canWrite = !!(fs && typeof fs.writeFile === "function");
        for (n = 0; n < entries; n++) {
            if (p + 46 > zip.length || zipU32(zip, p) !== 0x02014b50) throw new Error("zip central magic");
            var flag = zipU16(zip, p + 8);
            var method = zipU16(zip, p + 10);
            var compSize = zipU32(zip, p + 20);
            var uncompSize = zipU32(zip, p + 24);
            var nameLen = zipU16(zip, p + 28);
            var extraLen = zipU16(zip, p + 30);
            var commentLen = zipU16(zip, p + 32);
            var localOff = zipU32(zip, p + 42);
            var nameBytes = zip.subarray(p + 46, p + 46 + nameLen);
            p += 46 + nameLen + extraLen + commentLen;
            var name = zipDecodeName(nameBytes, (flag & 0x800) !== 0).replace(/\\/g, "/");
            if (!name || name.charAt(name.length - 1) === "/") continue;
            if (name.indexOf("..") >= 0 || name.charAt(0) === "/" || name.indexOf(":") >= 0) continue;
            if (name.indexOf("__MACOSX/") === 0 || name.indexOf(".DS_Store") >= 0) continue;
            if (flag & 1) throw new Error("zip encrypted: " + name);
            if (localOff + 30 > zip.length || zipU32(zip, localOff) !== 0x04034b50) {
                throw new Error("zip local magic: " + name);
            }
            var localNameLen = zipU16(zip, localOff + 26);
            var localExtraLen = zipU16(zip, localOff + 28);
            var dataOff = localOff + 30 + localNameLen + localExtraLen;
            if (dataOff + compSize > zip.length) throw new Error("zip data truncated: " + name);
            var payload = zip.subarray(dataOff, dataOff + compSize);
            var outBytes;
            if (method === 0) {
                outBytes = payload;
            } else if (method === 8) {
                outBytes = zipInflateRaw(payload);
            } else {
                throw new Error("zip method " + method + ": " + name);
            }
            if (uncompSize && outBytes.length !== uncompSize) {
                throw new Error("zip size mismatch: " + name);
            }
            if (canWrite) {
                var roots = [destRoot];
                if (destRoot !== "/tmp/pls/track") roots.push("/tmp/pls/track");
                if (destRoot !== "/_savedata/track") roots.push("/_savedata/track");
                var ri;
                for (ri = 0; ri < roots.length; ri++) {
                    var outPath = roots[ri] + "/" + name;
                    var slash = outPath.lastIndexOf("/");
                    var folder = slash >= 0 ? outPath.substring(0, slash) : "";
                    if (folder && typeof fs.mkdirTree === "function") {
                        try { fs.mkdirTree(folder); } catch (eDir) {}
                    }
                    try { fs.writeFile(outPath, outBytes); } catch (eWrite) {}
                }
            }
            storeExtracted(name, outBytes);
            wrote++;
        }
        return wrote;
    }

    function clearExtracted() {
        extractedFiles = {};
        extractedList = [];
    }

    function rememberImportedZip(bytes) {
        var u8 = asUint8(bytes);
        if (u8 && u8.length >= 22) importedZipBytes = u8;
    }

    function looksLikeZip(bytes) {
        var u8 = asUint8(bytes);
        if (!u8 || u8.length < 4) return false;
        return u8[0] === 0x50 && u8[1] === 0x4b && (u8[2] === 0x03 || u8[2] === 0x05 || u8[2] === 0x07);
    }

    function storeExtracted(name, bytes) {
        if (!name || !bytes || !bytes.length) return;
        var rel = String(name).replace(/\\/g, "/");
        while (rel.charAt(0) === "/") rel = rel.slice(1);
        if (!rel) return;
        if (!extractedFiles[rel]) extractedList.push(rel);
        extractedFiles[rel] = bytes;
        extractedFiles[rel.toLowerCase()] = bytes;
        var base = rel.split("/").pop();
        if (base) {
            extractedFiles[base] = bytes;
            extractedFiles[base.toLowerCase()] = bytes;
        }
    }

    function lookupExtracted(raw) {
        var src = toStr(raw).replace(/\\/g, "/");
        if (!src) return null;
        if (extractedFiles[src]) return extractedFiles[src];
        var lower = src.toLowerCase();
        if (extractedFiles[lower]) return extractedFiles[lower];
        var base = src.split("/").pop();
        if (base && extractedFiles[base]) return extractedFiles[base];
        if (base && extractedFiles[base.toLowerCase()]) return extractedFiles[base.toLowerCase()];
        var keys = Object.keys(extractedFiles);
        var i;
        for (i = 0; i < keys.length; i++) {
            var keyBase = keys[i].split("/").pop();
            if (base && keyBase === base) return extractedFiles[keys[i]];
            if (base && keyBase && keyBase.toLowerCase() === base.toLowerCase()) return extractedFiles[keys[i]];
        }
        return null;
    }

    function unzipToFs(srcRaw, destRaw) {
        lastUnzipError = "";
        lastUnzipCount = 0;
        clearExtracted();
        var src = toStr(srcRaw).replace(/\\/g, "/");
        var dest = toStr(destRaw).replace(/\\/g, "/");
        while (dest.length > 1 && dest.charAt(dest.length - 1) === "/") dest = dest.slice(0, -1);
        var destLower = dest.toLowerCase();
        var allowed = destLower.indexOf("/tmp/pls") === 0
            || destLower.indexOf("/_savedata/track") === 0
            || destLower.indexOf("/savedata/track") === 0
            || destLower.indexOf("/_savedata/") === 0
            || destLower.indexOf("/savedata/") === 0
            || /\/track$/i.test(dest);
        if (!src || !dest || !allowed) {
            lastUnzipError = "unzip dest not allowed dest=" + dest;
            return 0;
        }
        var fs = getFS();
        var zip = null;
        if (importedZipBytes && importedZipBytes.length >= 22) zip = importedZipBytes;
        if (!zip && state.bytes && looksLikeZip(state.bytes)) zip = state.bytes;
        if (!zip && fs && typeof fs.readFile === "function") {
            zip = readFsBytes(fs, src);
            if (!zip) {
                var tries = candidatePaths(src);
                var ti;
                for (ti = 0; ti < tries.length && !zip; ti++) zip = readFsBytes(fs, tries[ti]);
            }
        }
        if (!zip || zip.length < 22) {
            lastUnzipError = "zip missing src=" + src
                + " mem=" + (importedZipBytes ? importedZipBytes.length : 0)
                + " state=" + (state.bytes ? state.bytes.length : 0);
            return 0;
        }
        try {
            lastUnzipCount = unzipBytesToFs(fs, zip, dest);
            if (lastUnzipCount <= 0) {
                lastUnzipError = lastUnzipError || "unzip wrote 0 files";
                return 0;
            }
            try { console.log("[pls-gx] unzip ok n=" + lastUnzipCount + " dest=" + dest + " mem=" + extractedList.length); } catch (eLog) {}
            return lastUnzipCount;
        } catch (err) {
            lastUnzipError = (err && err.message) ? err.message : String(err);
            try { console.log("[pls-gx] unzip fail " + lastUnzipError); } catch (eLog2) {}
            return 0;
        }
    }

    function listFsPath(raw) {
        lastListText = "";
        var root = toStr(raw).replace(/\\/g, "/");
        while (root.length > 1 && root.charAt(root.length - 1) === "/") root = root.slice(0, -1);
        var lower = root.toLowerCase();
        var allowed = lower.indexOf("/tmp/pls") === 0
            || lower.indexOf("/_savedata/track") === 0
            || lower.indexOf("/savedata/track") === 0
            || lower.indexOf("/_savedata/charts") === 0
            || lower.indexOf("/savedata/charts") === 0
            || /\/track$/i.test(root);
        if (!root || !allowed) return 0;
        var files = [];
        var fs = getFS();
        function walk(dir, rel) {
            if (!fs || typeof fs.readdir !== "function") return;
            var names;
            try { names = fs.readdir(dir) || []; } catch (e0) { return; }
            var i;
            for (i = 0; i < names.length; i++) {
                var n = names[i];
                if (n === "." || n === "..") continue;
                var p = dir + "/" + n;
                var r = rel ? (rel + "/" + n) : n;
                try {
                    var st = fs.stat(p);
                    if (st && typeof fs.isDir === "function" && fs.isDir(st.mode)) {
                        walk(p, r);
                    } else {
                        files.push(r);
                    }
                } catch (e1) {}
            }
        }
        var tries = [root];
        if (root.indexOf("/tmp/pls/track") === 0) tries.push("/_savedata/track");
        if (root.indexOf("/_savedata/track") === 0 || /\/track$/i.test(root)) tries.push("/tmp/pls/track");
        var ti;
        for (ti = 0; ti < tries.length; ti++) walk(tries[ti], "");
        for (ti = 0; ti < extractedList.length; ti++) files.push(extractedList[ti]);
        var seen = {};
        var unique = [];
        for (ti = 0; ti < files.length; ti++) {
            if (seen[files[ti]]) continue;
            seen[files[ti]] = 1;
            unique.push(files[ti]);
        }
        lastListText = unique.join("\n");
        return unique.length;
    }

    function openReadPath(raw) {
        readFileBytes = null;
        lastReadChunk = "";
        var src = toStr(raw).replace(/\\/g, "/");
        if (!src) return 0;
        var bytes = lookupExtracted(src);
        if (!bytes) {
            var fs = getFS();
            if (fs) {
                bytes = readFsBytes(fs, src);
                if (!bytes) {
                    var tries = candidatePaths(src);
                    var i;
                    for (i = 0; i < tries.length && !bytes; i++) {
                        bytes = lookupExtracted(tries[i]) || readFsBytes(fs, tries[i]);
                    }
                }
            }
        }
        if (!bytes || !bytes.length) return 0;
        readFileBytes = bytes;
        state.bytes = bytes;
        return bytes.length;
    }

    function makeReadChunk(offset, length) {
        lastReadChunk = "";
        if (!readFileBytes) return 0;
        var start = Math.max(0, toNum(offset) | 0);
        var count = Math.max(0, toNum(length) | 0);
        if (count <= 0 || start >= readFileBytes.length) return 0;
        lastReadChunk = bytesToBase64(readFileBytes.subarray(start, Math.min(readFileBytes.length, start + count)));
        return lastReadChunk ? 1 : 0;
    }

    function makeHeadText(raw) {
        lastHeadText = "";
        var n = openReadPath(raw);
        if (n <= 0) {
            var name = toStr(raw).replace(/\\/g, "/").split("/").pop();
            if (name) n = openReadPath(name);
            if (n <= 0 && name) n = openReadPath("/tmp/pls/track/" + name);
            if (n <= 0 && name) n = openReadPath("/_savedata/track/" + name);
        }
        if (n <= 0 || !readFileBytes) {
            try { console.log("[pls-gx] head miss path=" + toStr(raw) + " mem=" + extractedList.length); } catch (eMiss) {}
            return 0;
        }
        var take = Math.min(readFileBytes.length, 4096);
        try {
            lastHeadText = new TextDecoder("utf-8").decode(readFileBytes.subarray(0, take));
        } catch (e0) {
            var s = "";
            var i;
            for (i = 0; i < take; i++) s += String.fromCharCode(readFileBytes[i]);
            lastHeadText = s;
        }
        if (lastHeadText.length > 4096) lastHeadText = lastHeadText.slice(0, 4096);
        state.error = lastHeadText;
        try { console.log("[pls-gx] head ok n=" + lastHeadText.length + " name=" + toStr(raw).split("/").pop()); } catch (eLog) {}
        return lastHeadText.length;
    }

    function wipeGxVideos() {
        var n = 0;
        try {
            if (typeof global.i_gx_video_shutdown === "function") n = toNum(global.i_gx_video_shutdown());
        } catch (e0) {}
        try {
            var nodes = document.querySelectorAll("video[data-pls-gx-video]");
            var i;
            for (i = 0; i < nodes.length; i++) {
                var el = nodes[i];
                try { el.pause(); el.removeAttribute("src"); el.load(); } catch (e1) {}
                try { if (el.parentNode) el.parentNode.removeChild(el); } catch (e2) {}
                n = 1;
            }
        } catch (e3) {}
        return n > 0 ? 1 : 1;
    }

    function remoteExit(err) {
        wipeGxVideos();
        wipeExtractDirs();
        persistFs(function () {
            try {
                var u = new URL(window.location.href);
                u.searchParams.delete("pls_chart");
                u.searchParams.delete("chart");
                if (err) u.searchParams.set("err", String(err).slice(0, 180));
                else u.searchParams.delete("err");
                if (isRemoteMode()) u.searchParams.set("pls_remote", "1");
                window.location.replace(u.pathname + u.search + u.hash);
            } catch (e) {
                try { window.location.reload(); } catch (e2) {}
            }
        });
    }

    function remoteQueryErr() {
        try { return new URL(window.location.href).searchParams.get("err") || ""; } catch (e) { return ""; }
    }

    function toStr(value) {
        if (value === undefined || value === null) return "";
        return String(value);
    }

    function toNum(value) {
        var n = Number(value);
        return isFinite(n) ? n : 0;
    }

    function isPackageName(name) {
        var lower = toStr(name).toLowerCase();
        return lower.slice(-4) === ".zip" || lower.slice(-4) === ".pez";
    }

    function safeName(name) {
        var src = toStr(name);
        var out = "";
        for (var i = 0; i < src.length; i++) {
            var c = src.charCodeAt(i);
            var keep = (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c === 46 || c === 45 || c === 95;
            out += keep ? src.charAt(i) : "_";
        }
        while (out.indexOf("..") >= 0) out = out.split("..").join("_");
        if (!out) out = "chart.zip";
        if (!isPackageName(out)) out += ".zip";
        return out;
    }

    function lookupFn(name) {
        try {
            if (typeof global[name] === "function") return global[name];
        } catch (e0) {}
        try {
            if (typeof window !== "undefined" && typeof window[name] === "function") return window[name];
        } catch (e1) {}
        return null;
    }

    function eachModule(fn) {
        var seen = [];
        function tryMod(m) {
            if (!m || typeof m !== "object" || seen.indexOf(m) >= 0) return;
            seen.push(m);
            try { fn(m); } catch (e) {}
        }
        try { tryMod(typeof Module !== "undefined" ? Module : null); } catch (e0) {}
        try { tryMod(global.Module); } catch (e1) {}
        try { tryMod(typeof window !== "undefined" ? window.Module : null); } catch (e2) {}
        try { tryMod(global.k); } catch (e3) {}
        try { tryMod(typeof window !== "undefined" ? window.k : null); } catch (e4) {}
        try {
            var nameFn = lookupFn("ModuleName");
            if (nameFn) tryMod(nameFn());
        } catch (e5) {}
    }

    function resumeMainLoopOnce() {
        eachModule(function (m) {
            if (typeof m.resumeMainLoop === "function") m.resumeMainLoop();
            else if (typeof m._emscripten_resume_main_loop === "function") m._emscripten_resume_main_loop();
        });
    }

    function hidePauseUi() {
        try {
            var menu = document.getElementById("pauseMenuContainer");
            if (menu) menu.hidden = true;
            var canvas = document.getElementById("canvas");
            if (canvas) {
                canvas.classList.remove("paused");
                canvas.classList.add("unpaused");
            }
        } catch (e0) {}
    }

    function canvasEl() {
        try { return document.getElementById("canvas"); } catch (e) { return null; }
    }

    var restoringFocus = 0;

    function gameLoopReady() {
        var c = canvasEl();
        return !!(c && c.classList && c.classList.contains("active"));
    }

    function restoreFocus() {
        if (restoringFocus) return;
        restoringFocus = 1;
        try { window.focus(); } catch (e0) {}
        try {
            var c = canvasEl();
            if (c) {
                try { c.tabIndex = 0; } catch (eT) {}
                try { c.focus(); } catch (eF) {}
            }
        } catch (e1) {}
        restoringFocus = 0;
    }

    function unpauseGame(kickLoop) {
        restoreFocus();
        try {
            var resumeFn = lookupFn("resume");
            if (typeof resumeFn === "function") resumeFn();
        } catch (e1) {}
        try {
            var gmUnpause = lookupFn("GM_unpause");
            if (typeof gmUnpause === "function") gmUnpause();
        } catch (e2) {}
        hidePauseUi();
        if (kickLoop && gameLoopReady()) {
            try { resumeMainLoopOnce(); } catch (e4) {}
        }
    }

    var pokeGen = 0;

    function pokeUnpause() {
        pokeGen++;
        var g = pokeGen;
        function go(kick) {
            if (g !== pokeGen) return;
            unpauseGame(!!kick && gameLoopReady());
        }
        go(false);
        setTimeout(function () { go(false); }, 0);
        setTimeout(function () { go(false); }, 50);
        setTimeout(function () { go(true); }, 280);
    }

    function patchPause() {
    }

    function readFile(file, done) {
        if (file && typeof file.arrayBuffer === "function") {
            file.arrayBuffer().then(function (buf) {
                done(null, new Uint8Array(buf));
            }).catch(function () {
                readWithFileReader(file, done);
            });
            return;
        }
        readWithFileReader(file, done);
    }

    function readWithFileReader(file, done) {
        try {
            var reader = new FileReader();
            reader.onload = function () { done(null, new Uint8Array(reader.result)); };
            reader.onerror = function () { done(reader.error || new Error("FileReader failed")); };
            reader.readAsArrayBuffer(file);
        } catch (err) {
            done(err);
        }
    }

    function setDropVisual(text) {
        var visual = document.getElementById("pls-gx-drop-visual");
        if (visual) visual.textContent = text || "点下方按钮选择 .zip / .pez 谱面包";
    }

    function writeImportedBytes(name, bytes) {
        rememberImportedZip(bytes);
        if (!bytes || !bytes.length) return "";
        var fs = getFS();
        var paths = [
            "/_savedata/charts/" + name,
            "/tmp/pls/charts/" + name,
            "/tmp/charts/" + name
        ];
        var written = "";
        if (fs && typeof fs.writeFile === "function") {
            for (var i = 0; i < paths.length; i++) {
                var dest = paths[i];
                var slash = dest.lastIndexOf("/");
                var folder = slash >= 0 ? dest.substring(0, slash) : "";
                if (folder && typeof fs.mkdirTree === "function") {
                    try { fs.mkdirTree(folder); } catch (e1) {}
                }
                try {
                    fs.writeFile(dest, bytes);
                    if (!written) written = dest.charAt(0) === "/" ? dest : "/" + dest;
                } catch (e2) {}
            }
        }
        return written || ("/_savedata/charts/" + name);
    }

    function takeFile(file) {
        exportDropApi();
        if (!file) {
            state.status = STATUS_ERROR;
            state.error = "没有检测到文件。";
            setDropVisual(state.error);
            restoreFocus();
            return;
        }
        if (!isPackageName(file.name)) {
            state.status = STATUS_ERROR;
            state.error = "请选择 .zip / .pez 谱面包。";
            setDropVisual(state.error);
            restoreFocus();
            return;
        }
        state.status = STATUS_READING;
        state.error = "";
        state.name = safeName(file.name);
        state.bytes = null;
        state.importedPath = "";
        setDropVisual("正在读取 " + state.name);
        readFile(file, function (err, bytes) {
            if (err) {
                state.status = STATUS_ERROR;
                state.error = err.message || "读取文件失败。";
                setDropVisual(state.error);
                exportDropApi();
                pokeUnpause();
                return;
            }
            state.bytes = bytes || new Uint8Array(0);
            rememberImportedZip(state.bytes);
            if (!state.bytes.length) {
                state.status = STATUS_ERROR;
                state.error = "文件是空的。";
                setDropVisual(state.error);
                exportDropApi();
                pokeUnpause();
                return;
            }
            state.importedPath = writeImportedBytes(state.name, state.bytes);
            state.status = STATUS_OK;
            state.error = "";
            setDropVisual("已选择 " + state.name);
            try {
                console.log("[pls-gx] pick ok name=" + state.name + " path=" + (state.importedPath || "") + " size=" + state.bytes.length);
            } catch (eLog) {}
            exportDropApi();
            restoreFocus();
            pokeUnpause();
        });
    }

    function applyBox(el, box) {
        if (!el || !box) return;
        el.style.left = box.x + "px";
        el.style.top = box.y + "px";
        el.style.width = Math.max(0, box.w) + "px";
        el.style.height = Math.max(0, box.h) + "px";
        el.style.right = "auto";
        el.style.bottom = "auto";
        el.style.inset = "auto";
    }

    function roomToCss(x, y, w, h, roomW, roomH) {
        var canvas = document.getElementById("canvas");
        var rw = toNum(roomW);
        var rh = toNum(roomH);
        if (rw <= 0) rw = (canvas && canvas.width) || 1;
        if (rh <= 0) rh = (canvas && canvas.height) || 1;
        if (!canvas || typeof canvas.getBoundingClientRect !== "function") {
            return { x: x, y: y, w: w, h: h };
        }
        var r = canvas.getBoundingClientRect();
        return {
            x: r.left + (x / rw) * r.width,
            y: r.top + (y / rh) * r.height,
            w: (w / rw) * r.width,
            h: (h / rh) * r.height
        };
    }

    function hideOverlayFileInput() {
        var el = document.getElementById("pls-gx-file");
        if (el) el.style.display = "none";
    }

    function onPickChange(ev) {
        exportDropApi();
        var el = ev && ev.target;
        var file = el && el.files && el.files[0];
        restoreFocus();
        if (file) takeFile(file);
        else pokeUnpause();
        setTimeout(function () {
            restoreFocus();
            replacePickInput();
        }, 0);
    }

    function makePickInput() {
        var el = document.createElement("input");
        el.id = "pls-gx-hidden-file";
        el.type = "file";
        el.accept = ".zip,.pez,application/zip,application/x-zip-compressed";
        el.multiple = false;
        el.title = "选择文件";
        el.style.cssText = "position:absolute;inset:0;width:100%;height:100%;opacity:0;cursor:pointer;z-index:3;margin:0;padding:0;border:0;font-size:24px;";
        el.addEventListener("change", onPickChange);
        el.addEventListener("input", onPickChange);
        el.addEventListener("cancel", function () { pokeUnpause(); });
        el.addEventListener("click", function (ev) {
            if (ev && ev.stopPropagation) ev.stopPropagation();
            unpauseGame(false);
        });
        return el;
    }

    function replacePickInput() {
        var wrap = document.getElementById("pls-gx-drop-pick");
        if (!wrap) return null;
        var old = document.getElementById("pls-gx-hidden-file");
        if (old && old.parentNode) {
            try { old.parentNode.removeChild(old); } catch (e0) {}
        }
        var el = makePickInput();
        wrap.appendChild(el);
        return el;
    }

    function dropLayer() {
        if (typeof document === "undefined") return null;
        var layer = document.getElementById("pls-gx-drop-layer");
        if (layer && !layer.__plsDropV17) {
            try { if (layer.parentNode) layer.parentNode.removeChild(layer); } catch (e0) {}
            layer = null;
        }
        if (layer) return layer;
        layer = document.createElement("div");
        layer.id = "pls-gx-drop-layer";
        layer.__plsDropV17 = 1;
        layer.style.cssText = "position:fixed;inset:0;display:none;z-index:2147483645;background:rgba(6,10,24,0.78);align-items:center;justify-content:center;";
        var box = document.createElement("div");
        box.id = "pls-gx-drop-box";
        box.style.cssText = "position:relative;width:min(84vw,720px);height:min(52vh,360px);border:3px dashed #7aa2ff;border-radius:18px;background:#141b2c;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;";
        var visual = document.createElement("div");
        visual.id = "pls-gx-drop-visual";
        visual.style.cssText = "pointer-events:none;text-align:center;color:#e8eefc;font:20px/1.5 sans-serif;padding:8px 24px;";
        visual.textContent = "点下方按钮选择 .zip / .pez 谱面包";
        var pickBtn = document.createElement("div");
        pickBtn.id = "pls-gx-drop-pick";
        pickBtn.style.cssText = "position:relative;z-index:2;padding:10px 20px;font-size:16px;color:#fff;background:#3d6cb3;border-radius:8px;cursor:pointer;overflow:hidden;min-width:140px;text-align:center;";
        var pickLabel = document.createElement("span");
        pickLabel.style.cssText = "pointer-events:none;";
        pickLabel.textContent = "选择文件";
        pickBtn.appendChild(pickLabel);
        var close = document.createElement("button");
        close.type = "button";
        close.textContent = "关闭";
        close.style.cssText = "position:absolute;top:-48px;right:0;z-index:2;padding:8px 16px;font-size:16px;color:#fff;background:#3d6cb3;border:0;border-radius:8px;cursor:pointer;";
        close.addEventListener("click", function (ev) {
            if (ev && ev.stopPropagation) ev.stopPropagation();
            setDropLayer(false);
        });
        box.appendChild(visual);
        box.appendChild(pickBtn);
        box.appendChild(close);
        layer.appendChild(box);
        (document.body || document.documentElement).appendChild(layer);
        replacePickInput();
        return layer;
    }

    function onReturnFromDialog() {
        if (restoringFocus) return;
        if (!dropLayerOpen && state.status !== STATUS_READING && state.status !== STATUS_OK) return;
        pokeUnpause();
        exportDropApi();
        if (!dropLayerOpen) return;
        var layer = document.getElementById("pls-gx-drop-layer");
        if (layer) layer.style.display = "flex";
        var el = document.getElementById("pls-gx-hidden-file");
        if (el && el.files && el.files[0] && state.status === STATUS_IDLE) takeFile(el.files[0]);
    }

    function hideDropLayerQuiet() {
        dropLayerOpen = 0;
        var layer = document.getElementById("pls-gx-drop-layer");
        if (layer) layer.style.display = "none";
        hideOverlayFileInput();
    }

    function setDropLayer(on) {
        var want = on ? 1 : 0;
        var wasOpen = dropLayerOpen;
        if (!want && wasOpen) restoreFocus();
        dropLayerOpen = want;
        var layer = dropLayer();
        if (layer) layer.style.display = dropLayerOpen ? "flex" : "none";
        hideOverlayFileInput();
        if (wasOpen && !dropLayerOpen) pokeUnpause();
        exportDropApi();
        if (dropLayerOpen) {
            replacePickInput();
            if (state.status === STATUS_IDLE) setDropVisual("点下方按钮选择 .zip / .pez 谱面包");
        }
        return 1;
    }

    function setPickRect(x, y, w, h, roomW, roomH) {
        pickRect = roomToCss(toNum(x), toNum(y), toNum(w), toNum(h), toNum(roomW), toNum(roomH));
        hideOverlayFileInput();
        return 1;
    }

    function setEnabled(on) {
        state.enabled = on ? 1 : 0;
        if (!state.enabled) hideDropLayerQuiet();
        else dropLayer();
        hideOverlayFileInput();
        return 1;
    }

    function boot() {
        if (typeof document === "undefined") return 0;
        hideOverlayFileInput();
        dropLayer();
        patchPause();
        exportDropApi();
        reexportVideo();
        reexportShader();
        if (booted) return 1;
        booted = 1;
        window.addEventListener("focus", onReturnFromDialog);
        window.addEventListener("pageshow", onReturnFromDialog);
        document.addEventListener("visibilitychange", function () {
            if (document.visibilityState === "visible") onReturnFromDialog();
        }, true);
        interceptDownloadTabs();
        listenImportChannel();
        return 1;
    }

    function reexportVideo() {
        var names = [
            "i_gx_video_ping", "i_gx_video_create", "i_gx_video_begin", "i_gx_video_append",
            "i_gx_video_end", "i_gx_video_play", "i_gx_video_pause", "i_gx_video_stop",
            "i_gx_video_seek_ms", "i_gx_video_get_position_ms", "i_gx_video_get_length_ms",
            "i_gx_video_get_width", "i_gx_video_get_height", "i_gx_video_get_status",
            "i_gx_video_draw", "i_gx_video_set_loop", "i_gx_video_release", "i_gx_video_last_error",
            "i_gx_video_shutdown"
        ];
        for (var i = 0; i < names.length; i++) {
            if (typeof global[names[i]] === "function") exportGx(names[i], global[names[i]]);
        }
        if (typeof global.i_gx_drop_import === "function") exportGx("i_gx_drop_import", global.i_gx_drop_import);
        if (typeof global.i_gx_query_get === "function") exportGx("i_gx_query_get", global.i_gx_query_get);
    }

    function reexportShader() {
        var names = [
            "i_gx_shader_ping", "i_gx_shader_begin", "i_gx_shader_append", "i_gx_shader_end",
            "i_gx_shader_set_uniform", "i_gx_shader_capture", "i_gx_shader_draw",
            "i_gx_shader_end_draw", "i_gx_shader_release", "i_gx_shader_shutdown",
            "i_gx_shader_target_width", "i_gx_shader_target_height", "i_gx_shader_last_error"
        ];
        for (var i = 0; i < names.length; i++) {
            if (typeof global[names[i]] === "function") exportGx(names[i], global[names[i]]);
        }
    }

    function fileUiRpcNum(raw) {
        var s = toStr(raw);
        if (s.indexOf("pls-f:") !== 0) return null;
        var parts = s.slice(6).split("\t");
        var op = parts[0];
        function num(i) { return toNum(parts[i] == null ? "" : parts[i]); }
        try {
            switch (op) {
                case "pickrect": return setPickRect(num(1), num(2), num(3), num(4), num(5), num(6));
                case "drop": return setDropLayer(num(1) > 0);
                case "pick":
                    return setDropLayer(true);
                case "wipe": return wipeFsPath(parts[1] || "");
                case "unzip": return unzipToFs(parts[1] || "", parts[2] || "");
                case "list": return listFsPath(parts[1] || "");
                case "fopen": return openReadPath(parts[1] || "");
                case "fread": return makeReadChunk(num(1), num(2));
                case "head": return makeHeadText(parts[1] || "");
                case "mode": return isRemoteMode() ? 1 : 0;
                default: return 0;
            }
        } catch (e) {
            return 0;
        }
    }

    function remoteRpcNum(raw) {
        var s = toStr(raw);
        if (s.indexOf("pls-r:") !== 0) return null;
        var parts = s.slice(6).split("\t");
        var op = parts[0];
        try {
            switch (op) {
                case "mode": return isRemoteMode() ? 1 : 0;
                case "exit": remoteExit(parts[1] || ""); return 1;
                default: return 0;
            }
        } catch (e) {
            return 0;
        }
    }

    function videoRpcNum(raw) {
        var s = toStr(raw);
        if (s.indexOf("pls-v:") !== 0) return null;
        var parts = s.slice(6).split("\t");
        var op = parts[0];
        function arg(i) { return parts[i] == null ? "" : parts[i]; }
        function num(i) { return toNum(arg(i)); }
        try {
            switch (op) {
                case "ping": return (typeof global.i_gx_video_create === "function") ? 1 : 0;
                case "create": return toNum(global.i_gx_video_create(arg(1)));
                case "begin": return toNum(global.i_gx_video_begin(arg(1)));
                case "append": return toNum(global.i_gx_video_append(num(1), arg(2)));
                case "end": return toNum(global.i_gx_video_end(num(1)));
                case "play": return toNum(global.i_gx_video_play(num(1)));
                case "pause": return toNum(global.i_gx_video_pause(num(1)));
                case "stop": return toNum(global.i_gx_video_stop(num(1)));
                case "seek": return toNum(global.i_gx_video_seek_ms(num(1), num(2)));
                case "pos": return toNum(global.i_gx_video_get_position_ms(num(1)));
                case "len": return toNum(global.i_gx_video_get_length_ms(num(1)));
                case "w": return toNum(global.i_gx_video_get_width(num(1)));
                case "h": return toNum(global.i_gx_video_get_height(num(1)));
                case "st": return toNum(global.i_gx_video_get_status(num(1)));
                case "loop": return toNum(global.i_gx_video_set_loop(num(1), num(2)));
                case "draw": return toNum(global.i_gx_video_draw(num(1), num(2), num(3), num(4), num(5), num(6), num(7)));
                case "rel": return toNum(global.i_gx_video_release(num(1)));
                case "wipe":
                case "shutdown": return wipeGxVideos();
                default: return 0;
            }
        } catch (e) {
            return 0;
        }
    }

    function shaderRpcNum(raw) {
        var s = toStr(raw);
        if (s.indexOf("pls-s:") !== 0) return null;
        var parts = s.slice(6).split("\t");
        var op = parts[0];
        function arg(i) { return parts[i] == null ? "" : parts[i]; }
        function num(i) { return toNum(arg(i)); }
        try {
            switch (op) {
                case "ping": return (typeof global.i_gx_shader_ping === "function") ? global.i_gx_shader_ping() : 0;
                case "begin": return toNum(global.i_gx_shader_begin(arg(1)));
                case "append": return toNum(global.i_gx_shader_append(num(1), arg(2)));
                case "end": return toNum(global.i_gx_shader_end(num(1)));
                case "uni": return toNum(global.i_gx_shader_set_uniform(num(1), arg(2), num(3), num(4)));
                case "cap": return toNum(global.i_gx_shader_capture(num(1)));
                case "draw": return toNum(global.i_gx_shader_draw(num(1), num(2), num(3), num(4), num(5)));
                case "fin": return toNum(global.i_gx_shader_end_draw());
                case "rel": return toNum(global.i_gx_shader_release(num(1)));
                case "shut": global.i_gx_shader_shutdown(); return 1;
                case "tw": return toNum(global.i_gx_shader_target_width());
                case "th": return toNum(global.i_gx_shader_target_height());
                default: return 0;
            }
        } catch (e) {
            return 0;
        }
    }

    function looksLikeChartUrl(url) {
        var u = toStr(url).toLowerCase();
        if (!u) return false;
        if (u.indexOf("gx_import.html") >= 0) return false;
        return u.slice(-4) === ".zip" || u.slice(-4) === ".pez" || u.indexOf("file:") === 0 || u.indexOf("blob:") === 0;
    }

    function importPageUrl() {
        try {
            var u = new URL("gx_import.html", window.location.href);
            if (u.protocol === "http:" || u.protocol === "https:") return u.href;
        } catch (e) {}
        return "";
    }

    function interceptDownloadTabs() {
        if (global.__plsGxOpenHooked) return;
        global.__plsGxOpenHooked = true;
        var origOpen = window.open;
        window.open = function (url, name, specs) {
            if (looksLikeChartUrl(url)) {
                url = importPageUrl();
                name = name || "pls_gx_import";
            }
            if (typeof origOpen === "function") return origOpen.call(window, url, name, specs);
            window.location.href = url;
            return window;
        };
        if (global.navigation && typeof navigation.addEventListener === "function") {
            navigation.addEventListener("navigate", function (ev) {
                try {
                    var dest = ev.destination && ev.destination.url;
                    if (!looksLikeChartUrl(dest)) return;
                    if (typeof ev.preventDefault === "function") ev.preventDefault();
                    if (typeof origOpen === "function") origOpen.call(window, importPageUrl(), "pls_gx_import");
                    else window.location.replace(importPageUrl());
                } catch (e) {}
            });
        }
    }

    function applyImportedBytes(name, bytes) {
        if (!bytes || !bytes.length) return;
        state.bytes = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
        rememberImportedZip(state.bytes);
        state.name = safeName(name || "chart.zip");
        state.importedPath = writeImportedBytes(state.name, state.bytes);
        state.status = STATUS_OK;
        state.error = "";
        pokeUnpause();
        var frame = document.getElementById("pls-gx-import-frame");
        if (frame) frame.style.display = "none";
    }

    function listenImportChannel() {
        if (global.__plsGxImportHooked) return;
        global.__plsGxImportHooked = true;
        try {
            var ch = new BroadcastChannel("pls-gx-import");
            ch.onmessage = function (ev) {
                if (!ev || !ev.data || !ev.data.ready) return;
                pollIndexedDb();
            };
        } catch (e1) {}
        window.addEventListener("message", function (ev) {
            if (ev && ev.data && ev.data.plsGxImport) pollIndexedDb();
        });
        window.addEventListener("storage", function (ev) {
            if (ev && ev.key === "pls_gx_import_ready") pollIndexedDb();
        });
    }

    function pollIndexedDb() {
        try {
            var req = indexedDB.open("pls-gx-import", 1);
            req.onsuccess = function () {
                try {
                    if (!req.result.objectStoreNames.contains("files")) return;
                    var tx = req.result.transaction("files", "readonly");
                    var get = tx.objectStore("files").get("latest");
                    get.onsuccess = function () {
                        var rec = get.result;
                        if (rec && rec.bytes) applyImportedBytes(rec.name, rec.bytes);
                    };
                } catch (e2) {}
            };
        } catch (e3) {}
    }

    function getFS() {
        var mod = (typeof Module !== "undefined") ? Module : null;
        if (!mod && typeof k !== "undefined") mod = k;
        if (typeof FS !== "undefined") return FS;
        if (mod && mod.FS) return mod.FS;
        return null;
    }

    function bytesToBase64(bytes) {
        var binary = "";
        for (var i = 0; i < bytes.length; i += 8192) {
            binary += String.fromCharCode.apply(null, bytes.subarray(i, Math.min(bytes.length, i + 8192)));
        }
        return btoa(binary);
    }

    var audios = {};
    var pendingAudio = {};
    var nextAudio = 1;
    var lastAudioError = "";
    var skipLocalAudio = (typeof global.i_gx_audio_ping === "function" && global.i_gx_audio_ping() > 0);

    function mediaMime(path) {
        var p = toStr(path).toLowerCase();
        if (p.slice(-4) === ".ogg" || p.slice(-4) === ".oga" || p.slice(-5) === ".opus") return "audio/ogg";
        if (p.slice(-4) === ".mp3") return "audio/mpeg";
        if (p.slice(-4) === ".wav" || p.slice(-5) === ".wave") return "audio/wav";
        if (p.slice(-5) === ".flac") return "audio/flac";
        if (p.slice(-4) === ".m4a") return "audio/mp4";
        if (p.slice(-4) === ".aac") return "audio/aac";
        return "application/octet-stream";
    }

    function addPath(list, p) {
        if (!p) return;
        if (list.indexOf(p) < 0) list.push(p);
    }

    function candidatePaths(path) {
        var p = toStr(path).replace(/\\/g, "/");
        while (p.indexOf("//") >= 0) p = p.split("//").join("/");
        var list = [];
        addPath(list, p);
        if (p.charAt(0) !== "/") addPath(list, "/" + p);
        var fname = p.split("/").pop();
        var rest = p.replace(/^\//, "");
        var prefixes = ["/_savedata/", "/savedata/", "/save/", "/", "/game/", "/html5game/", "/tmp/pls/", "/tmp/pls/charts/", "/tmp/pls/track/", "/tmp/"];
        for (var i = 0; i < prefixes.length; i++) {
            addPath(list, prefixes[i] + rest);
            if (fname) addPath(list, prefixes[i] + fname);
        }
        var marker = p.indexOf("/_savedata/");
        if (marker >= 0) addPath(list, p.slice(marker));
        var charts = p.toLowerCase().indexOf("charts/");
        if (charts >= 0) addPath(list, "/_savedata/" + p.slice(charts));
        return list;
    }

    function asUint8(bytes) {
        if (!bytes) return null;
        if (bytes instanceof Uint8Array) return bytes.length ? bytes : null;
        if (bytes.buffer && typeof bytes.length === "number") {
            return bytes.length ? new Uint8Array(bytes.buffer, bytes.byteOffset || 0, bytes.byteLength || bytes.length) : null;
        }
        return null;
    }

    function readFsBytes(fs, path) {
        try {
            var encoded = fs.readFile(path, { encoding: "binary" });
            var u8 = asUint8(encoded);
            if (u8) return u8;
        } catch (e0) {}
        try {
            var raw = fs.readFile(path);
            var u82 = asUint8(raw);
            if (u82) return u82;
        } catch (e1) {}
        return null;
    }

    function blobUrlFromBytes(bytes, mime) {
        var blob = new Blob([bytes], { type: mime || "application/octet-stream" });
        return URL.createObjectURL(blob);
    }

    function mediaSrc(path) {
        var p = toStr(path).replace(/\\/g, "/");
        if (!p) return "";
        if (p.indexOf("blob:") === 0 || p.indexOf("http://") === 0 || p.indexOf("https://") === 0 || p.indexOf("data:") === 0) return p;
        var mem = lookupExtracted(p);
        if (mem && mem.length) return blobUrlFromBytes(mem, mediaMime(p));
        var fs = getFS();
        if (fs && typeof fs.readFile === "function") {
            var tries = candidatePaths(p);
            for (var i = 0; i < tries.length; i++) {
                var bytes = lookupExtracted(tries[i]) || readFsBytes(fs, tries[i]);
                if (bytes && bytes.length) return blobUrlFromBytes(bytes, mediaMime(tries[i]));
            }
            lastAudioError = "fs read failed tries=" + tries.length;
        } else {
            lastAudioError = mem ? "" : "no FS";
        }
        return "";
    }

    function b64ToBytes(b64) {
        var src = toStr(b64);
        if (!src) return new Uint8Array(0);
        var bin = atob(src);
        var out = new Uint8Array(bin.length);
        for (var i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i) & 255;
        return out;
    }

    function makeAudioEl(src, objectUrl) {
        var el = new Audio();
        el.preload = "auto";
        try { el.crossOrigin = "anonymous"; } catch (e0) {}
        el.src = src;
        if (objectUrl) el.__plsObjectUrl = objectUrl;
        try { el.load(); } catch (e1) {}
        return el;
    }

    function exportGx(name, fn) {
        global[name] = fn;
        try { if (typeof Da !== "undefined" && Da) Da[name] = fn; } catch (e) {}
    }

    function exportDropApi() {
        var names = [
            "i_gx_drop_boot", "i_gx_drop_set_enabled", "i_gx_drop_open_import",
            "i_gx_drop_poll_import", "i_gx_drop_unpause", "i_gx_drop_status",
            "i_gx_drop_hover", "i_gx_drop_filename", "i_gx_drop_error",
            "i_gx_drop_size", "i_gx_drop_chunk", "i_gx_drop_import", "i_gx_drop_reset",
            "i_gx_import_url", "i_gx_query_get"
        ];
        for (var i = 0; i < names.length; i++) {
            if (typeof global[names[i]] === "function") exportGx(names[i], global[names[i]]);
        }
    }

    function unlockAudio() {
        var ids = Object.keys(audios);
        for (var i = 0; i < ids.length; i++) {
            var el = audios[ids[i]];
            if (!el || !el.__plsNeedsGesture) continue;
            try {
                var p = el.play();
                if (p && p.catch) p.catch(function () {});
            } catch (e) {}
            el.__plsNeedsGesture = false;
        }
    }

    if (typeof document !== "undefined") {
        document.addEventListener("pointerdown", unlockAudio, true);
        document.addEventListener("keydown", unlockAudio, true);
    }

    if (skipLocalAudio) {
        exportGx("i_gx_audio_create", global.i_gx_audio_create);
        exportGx("i_gx_audio_begin", global.i_gx_audio_begin);
        exportGx("i_gx_audio_append", global.i_gx_audio_append);
        exportGx("i_gx_audio_end", global.i_gx_audio_end);
        exportGx("i_gx_audio_play", global.i_gx_audio_play);
        exportGx("i_gx_audio_pause", global.i_gx_audio_pause);
        exportGx("i_gx_audio_resume", global.i_gx_audio_resume);
        exportGx("i_gx_audio_stop", global.i_gx_audio_stop);
        exportGx("i_gx_audio_set_position_ms", global.i_gx_audio_set_position_ms);
        exportGx("i_gx_audio_get_position_ms", global.i_gx_audio_get_position_ms);
        exportGx("i_gx_audio_get_length_ms", global.i_gx_audio_get_length_ms);
        exportGx("i_gx_audio_release", global.i_gx_audio_release);
        exportGx("i_gx_audio_last_error", global.i_gx_audio_last_error);
    }

    if (!skipLocalAudio) {
    exportGx("i_gx_audio_create", function (path, useStream) {
        lastAudioError = "";
        var src = mediaSrc(path);
        if (!src) return 0;
        var id = nextAudio++;
        var el = makeAudioEl(src, src.indexOf("blob:") === 0 ? src : "");
        el.__plsUseStream = toNum(useStream);
        audios[id] = el;
        return id;
    });
    exportGx("i_gx_audio_begin", function (mime) {
        lastAudioError = "";
        var id = nextAudio++;
        pendingAudio[id] = { mime: toStr(mime) || "application/octet-stream", parts: [], total: 0 };
        return id;
    });
    exportGx("i_gx_audio_append", function (handle, b64) {
        var id = toNum(handle) | 0;
        var rec = pendingAudio[id];
        if (!rec) {
            lastAudioError = "append without begin";
            return 0;
        }
        try {
            var bytes = b64ToBytes(b64);
            if (bytes && bytes.length) {
                rec.parts.push(bytes);
                rec.total += bytes.length;
            }
            return 1;
        } catch (e) {
            lastAudioError = "b64 decode failed";
            return 0;
        }
    });
    exportGx("i_gx_audio_end", function (handle) {
        var id = toNum(handle) | 0;
        var rec = pendingAudio[id];
        if (!rec) {
            lastAudioError = "end without begin";
            return 0;
        }
        delete pendingAudio[id];
        if (!rec.total) {
            lastAudioError = "empty audio bytes";
            return 0;
        }
        var out = new Uint8Array(rec.total);
        var off = 0;
        for (var i = 0; i < rec.parts.length; i++) {
            out.set(rec.parts[i], off);
            off += rec.parts[i].length;
        }
        var src = blobUrlFromBytes(out, rec.mime);
        audios[id] = makeAudioEl(src, src);
        return 1;
    });
    exportGx("i_gx_audio_play", function (handle) {
        var el = audios[toNum(handle) | 0];
        if (!el) return 0;
        var p = el.play();
        if (p && p.catch) p.catch(function () { el.__plsNeedsGesture = true; });
        return 1;
    });
    exportGx("i_gx_audio_pause", function (handle) {
        var el = audios[toNum(handle) | 0];
        if (!el) return 0;
        el.pause();
        return 1;
    });
    exportGx("i_gx_audio_resume", function (handle) {
        var el = audios[toNum(handle) | 0];
        if (!el) return 0;
        var p = el.play();
        if (p && p.catch) p.catch(function () { el.__plsNeedsGesture = true; });
        return 1;
    });
    exportGx("i_gx_audio_stop", function (handle) {
        var el = audios[toNum(handle) | 0];
        if (!el) return 0;
        el.pause();
        try { el.currentTime = 0; } catch (e) {}
        return 1;
    });
    exportGx("i_gx_audio_set_position_ms", function (handle, ms) {
        var el = audios[toNum(handle) | 0];
        if (!el) return 0;
        try { el.currentTime = Math.max(0, toNum(ms) / 1000); } catch (e) { return 0; }
        return 1;
    });
    exportGx("i_gx_audio_get_position_ms", function (handle) {
        var el = audios[toNum(handle) | 0];
        if (!el) return 0;
        return (el.currentTime || 0) * 1000;
    });
    exportGx("i_gx_audio_get_length_ms", function (handle) {
        var el = audios[toNum(handle) | 0];
        if (!el) return 0;
        var d = el.duration;
        if (!isFinite(d)) return 0;
        return d * 1000;
    });
    exportGx("i_gx_audio_release", function (handle) {
        var id = toNum(handle) | 0;
        var hadPending = !!pendingAudio[id];
        if (hadPending) delete pendingAudio[id];
        var el = audios[id];
        if (!el) return hadPending ? 1 : 0;
        try { el.pause(); el.removeAttribute("src"); el.load(); } catch (e) {}
        if (el.__plsObjectUrl) {
            try { URL.revokeObjectURL(el.__plsObjectUrl); } catch (e2) {}
        }
        delete audios[id];
        return 1;
    });
    exportGx("i_gx_audio_last_error", function () {
        return lastAudioError || "";
    });
    }

    global.i_gx_query_get = function (key) {
        var k = toStr(key);
        if (k === "pls-r:mode" || k === "pls-f:mode") return isRemoteMode() ? "1" : "0";
        if (k === "pls-f:drop") return dropLayerOpen ? "1" : "0";
        if (k === "pls-f:path") return state.importedPath || "";
        if (k === "pls-f:unziperr") return lastUnzipError || "";
        if (k === "pls-f:unzipn") return String(lastUnzipCount || 0);
        if (k === "pls-f:list") return lastListText || "";
        if (k === "pls-f:chunk") return lastReadChunk || "";
        if (k === "pls-f:head") return lastHeadText || "";
        if (k === "pls-r:err") return remoteQueryErr();
        if (k.indexOf("pls-v:") === 0) {
            if (k === "pls-v:ver") return "gxvideo9";
            if (k === "pls-v:err") {
                try { return toStr(global.i_gx_video_last_error()); } catch (e0) { return ""; }
            }
            return "";
        }
        if (k.indexOf("pls-s:") === 0) {
            if (k === "pls-s:ver") return "gxshader2";
            if (k === "pls-s:err") {
                try { return toStr(global.i_gx_shader_last_error()); } catch (e1) { return ""; }
            }
            return "";
        }
        try {
            return new URL(window.location.href).searchParams.get(k) || "";
        } catch (e) {
            return "";
        }
    };
    global.i_gx_drop_boot = function () { return boot(); };
    global.i_gx_drop_set_enabled = function (value) { boot(); return setEnabled(toNum(value) > 0); };
    global.i_gx_import_url = function () {
        return importPageUrl();
    };
    global.i_gx_drop_open_import = function () {
        boot();
        unpauseGame(false);
        var url = importPageUrl();
        if (!url) return 0;
        var frame = document.getElementById("pls-gx-import-frame");
        if (!frame) {
            frame = document.createElement("iframe");
            frame.id = "pls-gx-import-frame";
            frame.style.cssText = "position:fixed;inset:0;width:100%;height:100%;z-index:2147483647;border:0;background:#0a0e18";
            (document.body || document.documentElement).appendChild(frame);
        }
        frame.src = url;
        frame.style.display = "block";
        return 1;
    };
    global.i_gx_drop_poll_import = function () { pollIndexedDb(); return state.status; };
    global.i_gx_drop_unpause = function () {
        hidePauseUi();
        try {
            var gmUnpause = lookupFn("GM_unpause");
            if (typeof gmUnpause === "function") gmUnpause();
        } catch (e0) {}
        return 1;
    };
    global.i_gx_drop_status = function () { return state.status; };
    global.i_gx_drop_hover = function () { return state.hover ? 1 : 0; };
    global.i_gx_drop_filename = function () { return state.name || ""; };
    global.i_gx_drop_error = function () { return state.error || ""; };
    global.i_gx_drop_size = function () { return state.bytes ? state.bytes.length : 0; };
    global.i_gx_drop_chunk = function (offset, length) {
        if (!state.bytes) return "";
        var start = Math.max(0, toNum(offset) | 0);
        var count = Math.max(0, toNum(length) | 0);
        if (count <= 0 || start >= state.bytes.length) return "";
        return bytesToBase64(state.bytes.subarray(start, Math.min(state.bytes.length, start + count)));
    };
    global.i_gx_drop_import = function (path) {
        var fileUi = fileUiRpcNum(path);
        if (fileUi !== null) return fileUi;
        var remote = remoteRpcNum(path);
        if (remote !== null) return remote;
        var shader = shaderRpcNum(path);
        if (shader !== null) return shader;
        var rpc = videoRpcNum(path);
        if (rpc !== null) return rpc;
        if (!state.bytes) return 0;
        var dest = toStr(path).replace(/\\/g, "/");
        var fs = getFS();
        try {
            if (fs && typeof fs.writeFile === "function") {
                var slash = dest.lastIndexOf("/");
                var folder = slash >= 0 ? dest.substring(0, slash) : "";
                if (folder && typeof fs.mkdirTree === "function") {
                    try { fs.mkdirTree(folder); } catch (e1) {}
                }
                fs.writeFile(dest, state.bytes);
                return 1;
            }
        } catch (err) {}
        return 0;
    };
    global.i_gx_drop_reset = function () {
        state.status = STATUS_IDLE;
        state.hover = 0;
        state.name = "";
        state.error = "";
        state.bytes = null;
        state.importedPath = "";
        return 1;
    };
    exportDropApi();

    (function installGxVideo(g) {
        if (!g) return;
        var videoNames = [
            "i_gx_video_ping", "i_gx_video_create", "i_gx_video_begin", "i_gx_video_append",
            "i_gx_video_end", "i_gx_video_play", "i_gx_video_pause", "i_gx_video_stop",
            "i_gx_video_seek_ms", "i_gx_video_get_position_ms", "i_gx_video_get_length_ms",
            "i_gx_video_get_width", "i_gx_video_get_height", "i_gx_video_get_status",
            "i_gx_video_draw", "i_gx_video_set_loop", "i_gx_video_release", "i_gx_video_last_error",
            "i_gx_video_shutdown"
        ];
        function bindVideo(name, fn) {
            exportGx(name, fn);
            try { if (typeof window !== "undefined") window[name] = fn; } catch (e0) {}
        }
        var already = 0;
        try { already = (typeof g.i_gx_video_ping === "function" && g.i_gx_video_ping() > 0) ? 1 : 0; } catch (e1) {}
        if (already) {
            for (var vi = 0; vi < videoNames.length; vi++) {
                if (typeof g[videoNames[vi]] === "function") bindVideo(videoNames[vi], g[videoNames[vi]]);
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
            try { el.crossOrigin = "anonymous"; } catch (e0) {}
            try { el.disablePictureInPicture = true; } catch (e1) {}
            el.setAttribute("playsinline", "");
            el.setAttribute("webkit-playsinline", "");
            el.setAttribute("muted", "");
            el.setAttribute("data-pls-gx-video", "1");
            el.style.cssText = "position:fixed;left:0;top:0;width:1px;height:1px;opacity:0;pointer-events:none;z-index:-1;border:0;";
            try { (document.body || document.documentElement).appendChild(el); } catch (e2) {}
            return el;
        }
        function revoke(s) {
            if (!s || !s.objectUrl) return;
            try { URL.revokeObjectURL(s.objectUrl); } catch (e0) {}
            s.objectUrl = "";
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
        function slotOf(id) { return slots[id | 0]; }
        function statusOf(s) {
            if (!s || !s.el) return ST_CLOSED;
            var el = s.el;
            if (el.error) { lastErr = "video error"; return ST_ERROR; }
            if (el.ended) return ST_ENDED;
            if (el.readyState < 2) return ST_PREP;
            if (el.paused) return ST_PAUSE;
            return ST_PLAY;
        }
        function pauseAll() {
            var ids = Object.keys(slots);
            for (var i = 0; i < ids.length; i++) {
                var s = slots[ids[i]];
                if (s && s.el) { try { s.el.pause(); } catch (e0) {} }
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
            document.addEventListener("visibilitychange", function () { onPageHidden(!!document.hidden); }, true);
            document.addEventListener("pagehide", function () { onPageHidden(true); }, true);
            document.addEventListener("pageshow", function () { onPageHidden(false); }, true);
        }
        function getGL() {
            try { if (typeof GLctx !== "undefined" && GLctx && GLctx.drawArrays) return GLctx; } catch (e0) {}
            try {
                if (typeof GL !== "undefined" && GL && GL.currentContext) return GL.currentContext.GLctx || GL.currentContext;
            } catch (e1) {}
            try { if (g.Module && g.Module.ctx && g.Module.ctx.drawArrays) return g.Module.ctx; } catch (e2) {}
            try {
                var canvas = document.getElementById("canvas") || document.querySelector("canvas");
                if (canvas) return canvas.getContext("webgl2") || canvas.getContext("webgl") || canvas.getContext("experimental-webgl");
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
            var vs = compile(gl, gl.VERTEX_SHADER, "attribute vec2 a_pos;attribute vec2 a_uv;varying vec2 v_uv;void main(){gl_Position=vec4(a_pos,0.0,1.0);v_uv=a_uv;}");
            var fs = compile(gl, gl.FRAGMENT_SHADER, "precision mediump float;varying vec2 v_uv;uniform sampler2D u_tex;uniform float u_alpha;uniform float u_dim;void main(){vec4 c=texture2D(u_tex,v_uv);c.rgb*=(1.0-u_dim);c.a*=u_alpha;gl_FragColor=c;}");
            if (!vs || !fs) return null;
            var prog = gl.createProgram();
            gl.attachShader(prog, vs);
            gl.attachShader(prog, fs);
            gl.bindAttribLocation(prog, 0, "a_pos");
            gl.bindAttribLocation(prog, 1, "a_uv");
            gl.linkProgram(prog);
            if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) { lastErr = "shader link"; return null; }
            var buf = gl.createBuffer();
            var tex = gl.createTexture();
            var vao = null;
            try { if (typeof gl.createVertexArray === "function") vao = gl.createVertexArray(); } catch (e0) {}
            glPack = { gl: gl, prog: prog, buf: buf, tex: tex, vao: vao, locPos: gl.getAttribLocation(prog, "a_pos"), locUv: gl.getAttribLocation(prog, "a_uv"), locTex: gl.getUniformLocation(prog, "u_tex"), locAlpha: gl.getUniformLocation(prog, "u_alpha"), locDim: gl.getUniformLocation(prog, "u_dim") };
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
                }).catch(function () { lastErr = "video cors fetch failed"; });
            } catch (e0) { lastErr = "video cors retry failed"; }
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
            if (pack.upload === "sub" && pack.texW === w && pack.texH === h) {
                if (attempt("sub", function () {
                    gl.texSubImage2D(gl.TEXTURE_2D, 0, 0, 0, gl.RGBA, gl.UNSIGNED_BYTE, el);
                })) return 1;
            } else if (pack.upload) {
                var cached = pack.upload;
                pack.upload = "";
                if (cached === "rgba8-9" && attempt("rgba8-9", function () {
                    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8 || 0x8058, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, el);
                })) return 1;
                if (cached === "rgba-9" && attempt("rgba-9", function () {
                    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, el);
                })) return 1;
                if (cached === "rgba8-6" && attempt("rgba8-6", function () {
                    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8 || 0x8058, gl.RGBA, gl.UNSIGNED_BYTE, el);
                })) return 1;
                if (cached === "rgba-6" && attempt("rgba-6", function () {
                    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, el);
                })) return 1;
                if (cached === "rgb-9" && attempt("rgb-9", function () {
                    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, w, h, 0, gl.RGB, gl.UNSIGNED_BYTE, el);
                })) return 1;
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
                tries.push(["rgba8-6", function () {
                    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8 || 0x8058, gl.RGBA, gl.UNSIGNED_BYTE, el);
                }]);
            }
            tries.push(["rgba-6", function () {
                gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, el);
            }]);
            tries.push(["rgb-9", function () {
                gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, w, h, 0, gl.RGB, gl.UNSIGNED_BYTE, el);
            }]);
            tries.push(["rgb-6", function () {
                gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, gl.RGB, gl.UNSIGNED_BYTE, el);
            }]);
            tries.push(["alloc-sub", function () {
                gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
                gl.texSubImage2D(gl.TEXTURE_2D, 0, 0, 0, gl.RGBA, gl.UNSIGNED_BYTE, el);
            }]);
            for (var i = 0; i < tries.length; i++) {
                drainGL(gl);
                if (attempt(tries[i][0], tries[i][1])) {
                    if (tries[i][0] === "alloc-sub") pack.upload = "sub";
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
            if (!gl) { lastErr = "no webgl"; return -1; }
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
                    if (String(lastErr).indexOf("Security") >= 0 || String(lastErr).indexOf("tainted") >= 0) corsRetry(s);
                } else {
                    var x1 = left * 2 - 1, x2 = right * 2 - 1, y1 = 1 - top * 2, y2 = 1 - bottom * 2;
                    var verts = new Float32Array([x1, y1, 0, 0, x2, y1, 1, 0, x1, y2, 0, 1, x2, y2, 1, 1]);
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
        bindVideo("i_gx_video_ping", function () { return 1; });
        try { console.log("[GXVideo] HTMLVideo API bound"); } catch (eLog) {}
        bindVideo("i_gx_video_last_error", function () { return lastErr || ""; });
        bindVideo("i_gx_video_begin", function (mime) {
            lastErr = "";
            var id = nextId++;
            slots[id] = { mime: String(mime || "video/mp4"), parts: [], total: 0, want: 0, el: null, objectUrl: "", srcUrl: "", corsTried: 0 };
            return id;
        });
        bindVideo("i_gx_video_append", function (id, b64) {
            var s = slotOf(id);
            if (!s) { lastErr = "append"; return 0; }
            var u = b64u8(b64);
            if (u.length) { s.parts.push(u); s.total += u.length; }
            return 1;
        });
        bindVideo("i_gx_video_end", function (id) {
            var s = slotOf(id);
            if (!s) { lastErr = "end"; return 0; }
            var u = new Uint8Array(s.total);
            var o = 0;
            for (var i = 0; i < s.parts.length; i++) { u.set(s.parts[i], o); o += s.parts[i].length; }
            s.parts = [];
            if (!u.length) { lastErr = "empty"; return 0; }
            revoke(s);
            var blob = new Blob([u], { type: s.mime || "video/mp4" });
            var url = URL.createObjectURL(blob);
            s.objectUrl = url;
            s.el = s.el || makeVideo();
            return attachSrc(s, url, s.mime);
        });
        bindVideo("i_gx_video_create", function (path) {
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
        bindVideo("i_gx_video_play", function (id) {
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
        bindVideo("i_gx_video_pause", function (id) {
            var s = slotOf(id);
            if (!s || !s.el) return 0;
            s.want = 0;
            try { s.el.pause(); } catch (e0) {}
            return 1;
        });
        bindVideo("i_gx_video_stop", function (id) {
            var s = slotOf(id);
            if (!s || !s.el) return 0;
            s.want = 0;
            try { s.el.pause(); s.el.currentTime = 0; } catch (e0) {}
            return 1;
        });
        bindVideo("i_gx_video_seek_ms", function (id, ms) {
            var s = slotOf(id);
            if (!s || !s.el) return 0;
            try { s.el.currentTime = Math.max(0, Number(ms) / 1000); } catch (e0) { return 0; }
            return 1;
        });
        bindVideo("i_gx_video_get_position_ms", function (id) {
            var s = slotOf(id);
            if (!s || !s.el) return 0;
            return (s.el.currentTime || 0) * 1000;
        });
        bindVideo("i_gx_video_get_length_ms", function (id) {
            var s = slotOf(id);
            if (!s || !s.el) return 0;
            var d = s.el.duration;
            return isFinite(d) ? d * 1000 : 0;
        });
        bindVideo("i_gx_video_get_width", function (id) {
            var s = slotOf(id);
            if (!s || !s.el) return 0;
            return s.el.videoWidth || 0;
        });
        bindVideo("i_gx_video_get_height", function (id) {
            var s = slotOf(id);
            if (!s || !s.el) return 0;
            return s.el.videoHeight || 0;
        });
        bindVideo("i_gx_video_get_status", function (id) { return statusOf(slotOf(id)); });
        bindVideo("i_gx_video_set_loop", function (id, enabled) {
            var s = slotOf(id);
            if (!s || !s.el) return 0;
            s.el.loop = Number(enabled) > 0;
            return 1;
        });
        bindVideo("i_gx_video_draw", function (id, left, top, right, bottom, alpha, dim) {
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
        bindVideo("i_gx_video_release", function (id) {
            var s = slotOf(id);
            if (!s) return 0;
            return releaseSlot(id, s);
        });
        bindVideo("i_gx_video_shutdown", shutdownVideos);
    })(global);

    (function installGxShader(g) {
        if (!g) return;
        function bindShader(name, fn) {
            exportGx(name, fn);
            try { if (typeof window !== "undefined") window[name] = fn; } catch (e0) {}
        }
        var nextId = 1;
        var slots = {};
        var lastErr = "";
        var lastW = 0;
        var lastH = 0;
        var captured = 0;
        var inputTex = null;
        var texW = 0;
        var texH = 0;
        var quadBuf = null;
        var quadVao = null;
        var quadGl = null;

        function setErr(msg) {
            lastErr = String(msg || "");
            return 0;
        }
        function getGL() {
            try { if (typeof GLctx !== "undefined" && GLctx && GLctx.drawArrays) return GLctx; } catch (e0) {}
            try {
                if (typeof GL !== "undefined" && GL && GL.currentContext) return GL.currentContext.GLctx || GL.currentContext;
            } catch (e1) {}
            try { if (g.Module && g.Module.ctx && g.Module.ctx.drawArrays) return g.Module.ctx; } catch (e2) {}
            try {
                var canvas = document.getElementById("canvas") || document.querySelector("canvas");
                if (canvas) return canvas.getContext("webgl2") || canvas.getContext("webgl") || canvas.getContext("experimental-webgl");
            } catch (e3) {}
            return null;
        }
        function isWebGL2(gl) {
            if (!gl) return false;
            try {
                if (typeof WebGL2RenderingContext !== "undefined" && gl instanceof WebGL2RenderingContext) return true;
            } catch (e0) {}
            return typeof gl.texStorage2D === "function" && typeof gl.createVertexArray === "function";
        }
        function drainGL(gl) {
            var n = 0, e = 0;
            while (n < 16) {
                e = gl.getError();
                if (!e) break;
                n++;
            }
            return e;
        }
        function b64ToU8(b64) {
            var raw = String(b64 || "").replace(/[^A-Za-z0-9+/=]/g, "");
            var bin = "";
            try { bin = atob(raw); } catch (e0) { return new Uint8Array(0); }
            var u = new Uint8Array(bin.length);
            for (var i = 0; i < bin.length; i++) u[i] = bin.charCodeAt(i);
            return u;
        }
        function u8ToUtf8(u) {
            try { return new TextDecoder("utf-8").decode(u); } catch (e0) {
                var s = "";
                for (var i = 0; i < u.length; i++) s += String.fromCharCode(u[i]);
                try { return decodeURIComponent(escape(s)); } catch (e1) { return s; }
            }
        }
        function replaceAll(value, from, to) {
            var pos = 0, out = String(value || "");
            while ((pos = out.indexOf(from, pos)) >= 0) {
                out = out.slice(0, pos) + to + out.slice(pos + from.length);
                pos += to.length;
            }
            return out;
        }
        function replaceToken(source, from, to) {
            var re = new RegExp("(^|[^A-Za-z0-9_])" + from.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "(?![A-Za-z0-9_])", "g");
            return source.replace(re, "$1" + to);
        }
        function toLower(s) { return String(s || "").toLowerCase(); }
        function looksLikeHlsl(source) {
            return source.indexOf("float4") >= 0 || source.indexOf("float2") >= 0 || source.indexOf("SV_Target") >= 0
                || source.indexOf("SV_TARGET") >= 0 || source.indexOf("SamplerState") >= 0 || source.indexOf("Texture2D") >= 0
                || source.indexOf("cbuffer ") >= 0 || source.indexOf("tex2D(") >= 0 || source.indexOf(".Sample(") >= 0;
        }
        function looksLikeParticleShader(name, source) {
            var n = toLower(name), s = toLower(source);
            return n.indexOf("rain") >= 0 || n.indexOf("snow") >= 0 || n.indexOf("bokeh") >= 0
                || n.indexOf("particle") >= 0 || n.indexOf("drop") >= 0 || n.indexOf("flake") >= 0
                || s.indexOf("generatedropposition") >= 0 || s.indexOf("dropwidth") >= 0
                || s.indexOf("dropheight") >= 0 || s.indexOf("snowsize") >= 0 || s.indexOf("flakesize") >= 0
                || s.indexOf("particlecount") >= 0;
        }
        function looksLikeCameraShader(name, source) {
            var n = toLower(name), s = toLower(source);
            if (n.indexOf("camera") >= 0 || n.indexOf("camshake") >= 0 || n.indexOf("shake") >= 0) return true;
            var hasTransform = s.indexOf("zoom") >= 0 || s.indexOf("angle") >= 0 || s.indexOf("rotate") >= 0 || s.indexOf("camera") >= 0;
            var hasUvMath = s.indexOf("uv -") >= 0 || s.indexOf("uv-") >= 0 || s.indexOf("float2x2") >= 0
                || s.indexOf("mat2") >= 0 || s.indexOf("sincos") >= 0;
            return hasTransform && hasUvMath;
        }
        function stripShaderComments(source) {
            var out = "", i = 0, n = String(source || "").length;
            while (i < n) {
                if (i + 1 < n && source.charAt(i) === "/" && source.charAt(i + 1) === "/") {
                    while (i < n && source.charAt(i) !== "\n") i++;
                    continue;
                }
                if (i + 1 < n && source.charAt(i) === "/" && source.charAt(i + 1) === "*") {
                    i += 2;
                    while (i + 1 < n && !(source.charAt(i) === "*" && source.charAt(i + 1) === "/")) i++;
                    i = Math.min(i + 2, n);
                    out += " ";
                    continue;
                }
                out += source.charAt(i++);
            }
            return out;
        }
        function rewriteParticleHelpers(fragment) {
            // Rain/Snow almost always assign a local uv from gl_FragCoord, so this
            // must run even when remapFragCoord is skipped.
            fragment = replaceAll(fragment, "vec2 dropPos = generateDropPosition(i, i * 10.0);",
                "float rpe_i = float(i);\n"
                + "        vec2 dropPos = vec2("
                + "fract(sin(dot(vec2(rpe_i, time + rpe_i * 10.0 + 10.0), vec2(12.9898, 78.233))) * 43758.5453123) * screenSize.x, "
                + "mod(fract(sin(dot(vec2(rpe_i, rpe_i * 10.0), vec2(12.9898, 78.233))) * 43758.5453123) * screenSize.y - time * 2000.0, screenSize.y));");
            fragment = replaceAll(fragment, "dropWidth * screenSize.x", "max(dropWidth * screenSize.x, 1.5)");
            fragment = replaceAll(fragment, "snowSize * screenSize.x", "max(snowSize * screenSize.x, 1.5)");
            fragment = replaceAll(fragment, "flakeSize * screenSize.x", "max(flakeSize * screenSize.x, 1.5)");
            return fragment;
        }
        function rewriteDynamicForLoops(source, intIndex) {
            if (intIndex) {
                source = source.replace(
                    /for\s*\(\s*float\s+(\w+)\s*=\s*-\s*([A-Za-z_]\w*)\s*;\s*\1\s*<=\s*\2\s*;\s*\1\s*\+\+\s*\)/g,
                    "for (int $1 = -8; $1 <= 8; $1++) if (float($1) >= -float($2) && float($1) <= float($2))");
                source = source.replace(
                    /for\s*\(\s*float\s+(\w+)\s*=\s*0(?:\.0)?\s*;\s*\1\s*<=?\s*([A-Za-z_]\w*)\s*;\s*(?:\+\+\1|\1\+\+|\1\s*\+=\s*1(?:\.0)?)\s*\)/g,
                    "for (int $1 = 0; $1 < 512; $1++) if (float($1) < float($2))");
                source = source.replace(
                    /for\s*\(\s*int\s+(\w+)\s*=\s*0\s*;\s*\1\s*<=?\s*(?:int\s*\(\s*)?([A-Za-z_]\w*)(?:\s*\))?\s*;\s*(?:\+\+\1|\1\+\+)\s*\)/g,
                    "for (int $1 = 0; $1 < 512; $1++) if (float($1) < float($2))");
                source = source.replace(
                    /for\s*\(\s*float\s+(\w+)\s*=\s*0\.0\s*;\s*\1\s*<\s*([A-Za-z_]\w*)\s*;\s*\1\s*\+\+\s*\)/g,
                    "for (int $1 = 0; $1 < 512; $1++) if (float($1) < float($2))");
                source = source.replace(
                    /for\s*\(\s*float\s+(\w+)\s*=\s*0\.0\s*;\s*\1\s*<\s*([A-Za-z_]\w*)\s*;\s*\1\s*\+=\s*1\.0\s*\)/g,
                    "for (int $1 = 0; $1 < 512; $1++) if (float($1) < float($2))");
                return source;
            }
            source = source.replace(
                /for\s*\(\s*float\s+(\w+)\s*=\s*-\s*([A-Za-z_]\w*)\s*;\s*\1\s*<=\s*\2\s*;\s*\1\s*\+\+\s*\)/g,
                "for (float $1 = -8.0; $1 <= 8.0; $1 += 1.0) if ($1 >= -float($2) && $1 <= float($2))");
            source = source.replace(
                /for\s*\(\s*float\s+(\w+)\s*=\s*0(?:\.0)?\s*;\s*\1\s*<=?\s*([A-Za-z_]\w*)\s*;\s*(?:\+\+\1|\1\+\+|\1\s*\+=\s*1(?:\.0)?)\s*\)/g,
                "for (float $1 = 0.0; $1 < 512.0; $1 += 1.0) if ($1 < float($2))");
            source = source.replace(
                /for\s*\(\s*int\s+(\w+)\s*=\s*0\s*;\s*\1\s*<=?\s*(?:int\s*\(\s*)?([A-Za-z_]\w*)(?:\s*\))?\s*;\s*(?:\+\+\1|\1\+\+)\s*\)/g,
                "for (float $1 = 0.0; $1 < 512.0; $1 += 1.0) if ($1 < float($2))");
            source = source.replace(
                /for\s*\(\s*float\s+(\w+)\s*=\s*0\.0\s*;\s*\1\s*<\s*([A-Za-z_]\w*)\s*;\s*\1\s*\+\+\s*\)/g,
                "for (float $1 = 0.0; $1 < 512.0; $1 += 1.0) if ($1 < float($2))");
            source = source.replace(
                /for\s*\(\s*float\s+(\w+)\s*=\s*0\.0\s*;\s*\1\s*<\s*([A-Za-z_]\w*)\s*;\s*\1\s*\+=\s*1\.0\s*\)/g,
                "for (float $1 = 0.0; $1 < 512.0; $1 += 1.0) if ($1 < float($2))");
            return source;
        }
        function hasVaryingUv(source) {
            return /varying\s+(?:(?:lowp|mediump|highp)\s+)?vec2\s+uv\b/.test(source);
        }
        function hasLocalUv(source) {
            return /\bvec2\s+uv\s*=/.test(source);
        }
        function insertAfterPrecision(fragment, text) {
            var precisionLine = fragment.indexOf("precision ");
            var insertAt = precisionLine < 0 ? -1 : fragment.indexOf("\n", precisionLine);
            if (insertAt < 0) return text + fragment;
            return fragment.slice(0, insertAt + 1) + text + fragment.slice(insertAt + 1);
        }
        function insertMainPrelude(fragment, prelude) {
            var mainPos = fragment.indexOf("void main");
            if (mainPos < 0) return fragment;
            var brace = fragment.indexOf("{", mainPos);
            if (brace < 0) return fragment;
            return fragment.slice(0, brace + 1) + "\n    " + prelude + fragment.slice(brace + 1);
        }
        function remapFragCoord(fragment) {
            if (fragment.indexOf("gl_FragCoord") < 0 || fragment.indexOf("screenSize") < 0) return fragment;
            if (fragment.indexOf("uniform vec4 u_uvRect") < 0) {
                fragment = insertAfterPrecision(fragment, "uniform vec4 u_uvRect;\n");
            }
            var pixelInit = "vec2 rpe_pixel = vec2("
                + "(uv.x - u_uvRect.x) / max(u_uvRect.z - u_uvRect.x, 0.0001), "
                + "(uv.y - u_uvRect.y) / max(u_uvRect.w - u_uvRect.y, 0.0001)"
                + ") * screenSize;\n";
            fragment = insertMainPrelude(fragment, pixelInit);
            fragment = replaceAll(fragment, "gl_FragCoord.xy", "rpe_pixel");
            fragment = replaceAll(fragment, "gl_FragCoord.x", "rpe_pixel.x");
            fragment = replaceAll(fragment, "gl_FragCoord.y", "rpe_pixel.y");
            return fragment;
        }
        function remapWindowCoordToGameMaker(fragment) {
            if (fragment.indexOf("gl_FragCoord") < 0) return fragment;
            if (fragment.indexOf("screenSize") < 0 && fragment.indexOf("iResolution") < 0) return fragment;
            fragment = replaceAll(fragment, "gl_FragCoord.xy", "rpe_pixel");
            fragment = replaceAll(fragment, "gl_FragCoord.x", "rpe_pixel.x");
            fragment = replaceAll(fragment, "gl_FragCoord.y", "rpe_pixel.y");
            return insertMainPrelude(fragment, "vec2 rpe_pixel = vec2(gl_FragCoord.x, screenSize.y - gl_FragCoord.y);\n");
        }
        function addCopyTexSampleFlip(fragment) {
            var helper = "uniform vec2 u_texScale;\n"
                + "vec4 rpe_sample(sampler2D t, vec2 u) {\n"
                + "    vec2 scale = u_texScale;\n"
                + "    return texture2D(t, vec2(u.x * scale.x, (1.0 - u.y) * scale.y));\n"
                + "}\n";
            fragment = insertAfterPrecision(fragment, helper);
            fragment = replaceAll(fragment, "texture2D(", "rpe_sample(");
            fragment = replaceAll(fragment,
                "return rpe_sample(t, vec2(u.x * scale.x, (1.0 - u.y) * scale.y));",
                "return texture2D(t, vec2(u.x * scale.x, (1.0 - u.y) * scale.y));");
            return fragment;
        }
        function hlslToGlslEs(source, sourceName) {
            source = replaceAll(source, "\r\n", "\n");
            source = source.replace(/SamplerState\s+\w+\s*;/g, "");
            source = source.replace(/Texture2D\s*(?:<\s*\w+\s*>)?\s+(\w+)\s*;/g, "sampler2D $1;");
            source = source.replace(/(\w+)\.SampleLevel\s*\(\s*\w+\s*,\s*([^,]+)\s*,[^)]+\)/g, "texture2D($1, $2)");
            source = source.replace(/(\w+)\.Sample\s*\(\s*\w+\s*,\s*([^)]+)\)/g, "texture2D($1, $2)");
            source = source.replace(/\btex2D\s*\(/g, "texture2D(");
            source = replaceToken(source, "_MainTex", "screenTexture");
            source = replaceToken(source, "gm_BaseTexture", "screenTexture");
            source = replaceToken(source, "float4x4", "mat4");
            source = replaceToken(source, "float3x3", "mat3");
            source = replaceToken(source, "float2x2", "mat2");
            source = replaceToken(source, "float4", "vec4");
            source = replaceToken(source, "float3", "vec3");
            source = replaceToken(source, "float2", "vec2");
            source = replaceToken(source, "lerp", "mix");
            source = replaceToken(source, "frac", "fract");
            source = replaceToken(source, "atan2", "atan");
            source = source.replace(/saturate\s*\(([^)]+)\)/g, "clamp(($1), 0.0, 1.0)");
            source = source.replace(/(?:float4|vec4|void)\s+main\s*\([^)]*\)(?:\s*:\s*\w+)?/, "void main()");
            var mainPos = source.indexOf("void main()");
            if (mainPos >= 0) {
                var brace = source.indexOf("{", mainPos);
                if (brace >= 0) {
                    var depth = 0, end = brace;
                    for (; end < source.length; end++) {
                        if (source[end] === "{") depth++;
                        else if (source[end] === "}") {
                            depth--;
                            if (depth === 0) break;
                        }
                    }
                    var body = source.slice(brace, end);
                    body = body.replace(/return\s+([^;]+);/g, "gl_FragColor = ($1); return;");
                    source = source.slice(0, brace) + body + source.slice(end);
                }
            }
            if ((looksLikeCameraShader(sourceName, source) || looksLikeParticleShader(sourceName, source))
                && source.indexOf("screenSize") < 0) {
                source = "uniform vec2 screenSize;\n" + source;
            }
            return source;
        }
        function prepareGlslEs(fragment, sourceName, es300) {
            fragment = replaceAll(fragment, "\r\n", "\n");
            fragment = stripShaderComments(fragment);
            fragment = replaceAll(fragment, "#version 300 es", "");
            fragment = replaceAll(fragment, "#version 100", "");
            fragment = fragment.replace(/precision\s+(?:lowp|mediump|highp)\s+float\s*;/g, "");
            fragment = fragment.replace(/\blayout\s*\([^)]*\)\s*/g, "");
            fragment = replaceAll(fragment, "texture2D(", "__RPE_TEX2D__(");
            fragment = fragment.replace(/\btexture\s*\(/g, "texture2D(");
            fragment = replaceAll(fragment, "__RPE_TEX2D__(", "texture2D(");
            if (fragment.indexOf("iTime") >= 0 && fragment.indexOf("uniform float time") < 0 && fragment.indexOf("uniform float iTime") < 0) {
                fragment = "uniform float time;\n#define iTime time\n" + fragment;
            } else if (fragment.indexOf("iTime") >= 0 && fragment.indexOf("uniform float time") >= 0) {
                fragment = "#define iTime time\n" + fragment;
            }
            if (fragment.indexOf("iResolution") >= 0 && fragment.indexOf("screenSize") < 0) {
                fragment = "uniform vec2 screenSize;\n#define iResolution screenSize\n" + fragment;
            } else if (fragment.indexOf("iResolution") >= 0) {
                fragment = "#define iResolution screenSize\n" + fragment;
            }
            fragment = rewriteDynamicForLoops(fragment, !es300);
            fragment = rewriteParticleHelpers(fragment);
            fragment = replaceAll(fragment, "return color / total;",
                "return (total > 0.0001) ? (color / total) : texture2D(screenTexture, uv);");
            fragment = replaceAll(fragment, "uniform sampler2D screenTexture;",
                "uniform sampler2D gm_BaseTexture;\n#define screenTexture gm_BaseTexture");
            fragment = replaceAll(fragment, "mat3(1.0)",
                "mat3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0)");
            fragment = replaceAll(fragment, "uv != clamp(uv, vec2(0.0), vec2(1.0))",
                "(uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)");
            fragment = replaceAll(fragment, "uv != clamp(uv, vec2(0.), vec2(1.))",
                "(uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)");
            if (fragment.indexOf("gl_FragCoord") >= 0 && fragment.indexOf("screenSize") < 0) {
                fragment = "uniform vec2 screenSize;\n" + fragment;
            }
            if ((looksLikeCameraShader(sourceName, fragment) || looksLikeParticleShader(sourceName, fragment))
                && fragment.indexOf("screenSize") < 0) {
                fragment = "uniform vec2 screenSize;\n" + fragment;
            }
            var localUv = hasLocalUv(fragment);
            var varyingUv = hasVaryingUv(fragment);
            // Camera / bloom / glitch assign `vec2 uv = gl_FragCoord.xy / screenSize`.
            // Y-flip window coords into GameMaker top-left space; do not remap
            // through the letterboxed varying or the local uv clashes.
            if (localUv && fragment.indexOf("gl_FragCoord") >= 0) {
                fragment = remapWindowCoordToGameMaker(fragment);
            } else if (!localUv) {
                fragment = remapFragCoord(fragment);
                if (!varyingUv) fragment = "varying vec2 uv;\n" + fragment;
            }
            var outName = "";
            fragment = fragment.replace(/\bout\s+(?:(?:lowp|mediump|highp)\s+)?vec4\s+(\w+)\s*;/g, function (m, n) {
                outName = n;
                return "";
            });
            if (es300) {
                fragment = replaceAll(fragment, "varying ", "in ");
                fragment = replaceAll(fragment, "gl_FragColor", "rpe_FragColor");
                if (outName && outName !== "rpe_FragColor" && outName !== "gl_FragColor") {
                    fragment = replaceToken(fragment, outName, "rpe_FragColor");
                }
                fragment = "#version 300 es\nprecision highp float;\nout vec4 rpe_FragColor;\n" + fragment;
                fragment = addCopyTexSampleFlip(fragment);
                fragment = replaceAll(fragment, "texture2D(", "texture(");
            } else {
                fragment = fragment.replace(/\bin\s+((?:lowp|mediump|highp)\s+)?(vec2|vec3|vec4|float)\s+/g, "varying $1$2 ");
                if (outName && outName !== "gl_FragColor") fragment = replaceToken(fragment, outName, "gl_FragColor");
                if (fragment.indexOf("dFdx") >= 0 || fragment.indexOf("dFdy") >= 0) {
                    fragment = "#extension GL_OES_standard_derivatives : enable\n" + fragment;
                }
                fragment = "#version 100\nprecision highp float;\n" + fragment;
                fragment = addCopyTexSampleFlip(fragment);
            }
            return fragment;
        }
        function parseUniforms(src, record) {
            record.uniforms = {};
            var re = /uniform\s+(?:(?:lowp|mediump|highp)\s+)?(float|vec2|vec3|vec4)\s+(\w+)\s*;/g;
            var m;
            while ((m = re.exec(src))) {
                var type = m[1], name = m[2];
                if (name === "u_uvRect" || name === "u_yFlip" || name === "u_texScale") continue;
                var comp = type === "float" ? 1 : type === "vec2" ? 2 : type === "vec3" ? 3 : 4;
                var rec = { components: comp, values: [0, 0, 0, 0], location: -1 };
                record.uniforms[name] = rec;
                record.uniforms["_" + name] = rec;
            }
        }
        function compileShader(gl, type, src) {
            var sh = gl.createShader(type);
            gl.shaderSource(sh, src);
            gl.compileShader(sh);
            if (!gl.getShaderParameter(sh, gl.COMPILE_STATUS)) {
                var log = gl.getShaderInfoLog(sh) || "compile failed";
                gl.deleteShader(sh);
                return { sh: null, log: log };
            }
            return { sh: sh, log: "" };
        }
        var vsSrc100 = "#version 100\n"
            + "attribute vec2 a_position;\n"
            + "attribute vec2 a_texcoord;\n"
            + "uniform vec4 u_uvRect;\n"
            + "varying vec2 uv;\n"
            + "varying vec2 v_texcoord;\n"
            + "varying vec2 v_vTexcoord;\n"
            + "void main() {\n"
            + "    gl_Position = vec4(a_position, 0.0, 1.0);\n"
            + "    vec2 mapped = vec2(mix(u_uvRect.x, u_uvRect.z, a_texcoord.x), mix(u_uvRect.y, u_uvRect.w, a_texcoord.y));\n"
            + "    uv = mapped;\n"
            + "    v_texcoord = a_texcoord;\n"
            + "    v_vTexcoord = mapped;\n"
            + "}\n";
        var vsSrc300 = "#version 300 es\n"
            + "in vec2 a_position;\n"
            + "in vec2 a_texcoord;\n"
            + "uniform vec4 u_uvRect;\n"
            + "out vec2 uv;\n"
            + "out vec2 v_texcoord;\n"
            + "out vec2 v_vTexcoord;\n"
            + "void main() {\n"
            + "    gl_Position = vec4(a_position, 0.0, 1.0);\n"
            + "    vec2 mapped = vec2(mix(u_uvRect.x, u_uvRect.z, a_texcoord.x), mix(u_uvRect.y, u_uvRect.w, a_texcoord.y));\n"
            + "    uv = mapped;\n"
            + "    v_texcoord = a_texcoord;\n"
            + "    v_vTexcoord = mapped;\n"
            + "}\n";
        function ensureQuad(gl) {
            if (quadGl === gl && quadBuf && (!isWebGL2(gl) || quadVao)) return 1;
            if (quadGl !== gl) {
                quadBuf = null;
                quadVao = null;
            }
            quadGl = gl;
            if (!quadBuf) {
                quadBuf = gl.createBuffer();
                gl.bindBuffer(gl.ARRAY_BUFFER, quadBuf);
                gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
                    -1, 1, 0, 0,
                    1, 1, 1, 0,
                    -1, -1, 0, 1,
                    1, -1, 1, 1
                ]), gl.STATIC_DRAW);
            }
            if (!quadVao && typeof gl.createVertexArray === "function") {
                try { quadVao = gl.createVertexArray(); } catch (e0) { quadVao = null; }
            }
            return 1;
        }
        function linkProgram(gl, vsSource, fsSource) {
            var vs = compileShader(gl, gl.VERTEX_SHADER, vsSource);
            if (!vs.sh) return { prog: null, log: "shader vertex compile: " + vs.log };
            var fs = compileShader(gl, gl.FRAGMENT_SHADER, fsSource);
            if (!fs.sh) {
                gl.deleteShader(vs.sh);
                return { prog: null, log: fs.log };
            }
            var prog = gl.createProgram();
            gl.attachShader(prog, vs.sh);
            gl.attachShader(prog, fs.sh);
            gl.bindAttribLocation(prog, 0, "a_position");
            gl.bindAttribLocation(prog, 1, "a_texcoord");
            gl.linkProgram(prog);
            gl.deleteShader(vs.sh);
            gl.deleteShader(fs.sh);
            if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) {
                var linkLog = gl.getProgramInfoLog(prog) || "link failed";
                gl.deleteProgram(prog);
                return { prog: null, log: "shader link failed: " + linkLog };
            }
            return { prog: prog, log: "" };
        }
        function capture(gl) {
            var vp = gl.getParameter(gl.VIEWPORT);
            var x = vp[0] | 0, y = vp[1] | 0, w = Math.max(vp[2] | 0, 1), h = Math.max(vp[3] | 0, 1);
            var prevScissor = gl.isEnabled(gl.SCISSOR_TEST);
            gl.disable(gl.SCISSOR_TEST);
            try { if (gl.PIXEL_UNPACK_BUFFER) gl.bindBuffer(gl.PIXEL_UNPACK_BUFFER, null); } catch (e0) {}
            try { if (gl.PIXEL_PACK_BUFFER) gl.bindBuffer(gl.PIXEL_PACK_BUFFER, null); } catch (e1) {}
            gl.activeTexture(gl.TEXTURE0);
            if (!inputTex) inputTex = gl.createTexture();
            gl.bindTexture(gl.TEXTURE_2D, inputTex);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
            drainGL(gl);
            if (texW !== w || texH !== h) {
                gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
                var allocErr = gl.getError();
                if (allocErr) {
                    if (prevScissor) gl.enable(gl.SCISSOR_TEST);
                    return setErr("shader capture texImage2D " + allocErr);
                }
                texW = w;
                texH = h;
            }
            gl.copyTexSubImage2D(gl.TEXTURE_2D, 0, 0, 0, x, y, w, h);
            var copyErr = gl.getError();
            if (prevScissor) gl.enable(gl.SCISSOR_TEST);
            if (copyErr) return setErr("shader capture copyTexSubImage2D " + copyErr);
            lastW = w;
            lastH = h;
            captured = 1;
            return 1;
        }

        bindShader("i_gx_shader_ping", function () { return getGL() ? 1 : 0; });
        bindShader("i_gx_shader_last_error", function () { return lastErr || ""; });
        bindShader("i_gx_shader_target_width", function () { return lastW; });
        bindShader("i_gx_shader_target_height", function () { return lastH; });
        bindShader("i_gx_shader_begin", function (name) {
            lastErr = "";
            var id = nextId++;
            slots[id] = { name: String(name || "external.fs"), parts: [], total: 0, prog: null, uniforms: {}, compiled: 0 };
            return id;
        });
        bindShader("i_gx_shader_append", function (id, b64) {
            var s = slots[id | 0];
            if (!s) return setErr("shader append");
            var u = b64ToU8(b64);
            if (u.length) { s.parts.push(u); s.total += u.length; }
            return 1;
        });
        bindShader("i_gx_shader_end", function (id) {
            var s = slots[id | 0];
            if (!s) return setErr("shader end");
            var u = new Uint8Array(s.total);
            var o = 0;
            for (var i = 0; i < s.parts.length; i++) { u.set(s.parts[i], o); o += s.parts[i].length; }
            s.parts = [];
            var source = u8ToUtf8(u);
            if (!source) return setErr("shader source empty");
            if (looksLikeHlsl(source)) source = hlslToGlslEs(source, s.name);
            var gl = getGL();
            if (!gl) return setErr("no webgl");
            ensureQuad(gl);
            var prefer300 = isWebGL2(gl);
            var prepared = prepareGlslEs(source, s.name, prefer300);
            var linked = linkProgram(gl, prefer300 ? vsSrc300 : vsSrc100, prepared);
            if (!linked.prog && prefer300) {
                try { console.log("[GXShader] ES300 failed " + s.name + " " + linked.log); } catch (e300) {}
                prepared = prepareGlslEs(source, s.name, false);
                linked = linkProgram(gl, vsSrc100, prepared);
            }
            if (!linked.prog) {
                try { console.log("[GXShader] compile failed: " + s.name + " " + linked.log); } catch (eLog) {}
                return setErr("GLSL compile failed (" + s.name + "): " + linked.log);
            }
            parseUniforms(prepared, s);
            s.prog = linked.prog;
            s.uvRectLoc = gl.getUniformLocation(s.prog, "u_uvRect");
            s.texScaleLoc = gl.getUniformLocation(s.prog, "u_texScale");
            s.texLoc = gl.getUniformLocation(s.prog, "gm_BaseTexture");
            if (s.texLoc == null) s.texLoc = gl.getUniformLocation(s.prog, "screenTexture");
            s.samplerLocs = [];
            var samplerRe = /uniform\s+(?:(?:lowp|mediump|highp)\s+)?sampler2D\s+(\w+)/g;
            var sm;
            while ((sm = samplerRe.exec(prepared))) {
                var sloc = gl.getUniformLocation(s.prog, sm[1]);
                if (sloc != null) s.samplerLocs.push(sloc);
            }
            var names = Object.keys(s.uniforms);
            for (var ui = 0; ui < names.length; ui++) {
                var uname = names[ui];
                if (uname.charAt(0) === "_") continue;
                var loc = gl.getUniformLocation(s.prog, uname);
                if (loc == null) loc = gl.getUniformLocation(s.prog, "_" + uname);
                s.uniforms[uname].location = loc;
            }
            s.compiled = 1;
            lastErr = "";
            try {
                console.log("[GXShader] compiled " + s.name + " handle=" + id
                    + " camera=" + (looksLikeCameraShader(s.name, source) ? 1 : 0)
                    + " particle=" + (looksLikeParticleShader(s.name, source) ? 1 : 0)
                    + " webgl2=" + (prefer300 ? 1 : 0));
            } catch (eLog2) {}
            return id;
        });
        bindShader("i_gx_shader_set_uniform", function (id, name, component, value) {
            var s = slots[id | 0];
            if (!s || !s.uniforms) return 0;
            var rec = s.uniforms[String(name || "")];
            if (!rec) rec = s.uniforms["_" + String(name || "")];
            if (!rec) return 0;
            var c = component | 0;
            if (c < 0 || c > 3) return 0;
            rec.values[c] = Number(value) || 0;
            return 1;
        });
        bindShader("i_gx_shader_capture", function (id) {
            var s = slots[id | 0];
            if (!s || !s.compiled) return setErr("shader capture: not compiled");
            var gl = getGL();
            if (!gl) return setErr("no webgl");
            captured = 0;
            return capture(gl);
        });
        bindShader("i_gx_shader_draw", function (id, uvLeft, uvTop, uvRight, uvBottom) {
            var s = slots[id | 0];
            if (!s || !s.compiled || !s.prog) return setErr("shader draw: not compiled");
            if (!captured || !inputTex) return setErr("shader draw: no capture");
            var gl = getGL();
            if (!gl) return setErr("no webgl");
            ensureQuad(gl);
            if (isWebGL2(gl) && !quadVao) return setErr("shader draw: no VAO");
            var left = Math.max(0, Math.min(Number(uvLeft) || 0, 1));
            var right = Math.max(0, Math.min(Number(uvRight) || 0, 1));
            var top = Math.max(0, Math.min(Number(uvTop) || 0, 1));
            var bottom = Math.max(0, Math.min(Number(uvBottom) || 0, 1));
            if (right < left) { var t0 = left; left = right; right = t0; }
            if (bottom < top) { var t1 = top; top = bottom; bottom = t1; }
            var width = Math.max(lastW, 1);
            var height = Math.max(lastH, 1);
            var viewX = Math.floor(left * width);
            var viewW = Math.ceil((right - left) * width);
            var viewH = Math.ceil((bottom - top) * height);
            var viewY = Math.floor((1.0 - bottom) * height);
            if (viewW <= 0 || viewH <= 0) return setErr("shader draw: empty viewport");

            var prevProg = gl.getParameter(gl.CURRENT_PROGRAM);
            var prevBuf = gl.getParameter(gl.ARRAY_BUFFER_BINDING);
            var prevTex = gl.getParameter(gl.TEXTURE_BINDING_2D);
            var prevActive = gl.getParameter(gl.ACTIVE_TEXTURE);
            var prevUnpack = null;
            try { if (gl.PIXEL_UNPACK_BUFFER) prevUnpack = gl.getParameter(gl.PIXEL_UNPACK_BUFFER_BINDING); } catch (eU) {}
            var prevVAO = null;
            try { prevVAO = gl.getParameter(gl.VERTEX_ARRAY_BINDING); } catch (e0) {}
            var prevViewport = gl.getParameter(gl.VIEWPORT);
            var prevScissorBox = gl.getParameter(gl.SCISSOR_BOX);
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
            try {
                if (quadVao) gl.bindVertexArray(quadVao);
                gl.useProgram(s.prog);
                gl.viewport(viewX, viewY, viewW, viewH);
                gl.enable(gl.SCISSOR_TEST);
                gl.scissor(viewX, viewY, viewW, viewH);
                gl.disable(gl.DEPTH_TEST);
                gl.disable(gl.BLEND);
                gl.disable(gl.CULL_FACE);
                gl.disable(gl.STENCIL_TEST);
                gl.depthMask(false);
                gl.colorMask(true, true, true, true);
                gl.activeTexture(gl.TEXTURE0);
                gl.bindTexture(gl.TEXTURE_2D, inputTex);
                if (s.uvRectLoc) gl.uniform4f(s.uvRectLoc, left, top, right, bottom);
                if (s.texScaleLoc) gl.uniform2f(s.texScaleLoc, 1, 1);
                if (s.texLoc) gl.uniform1i(s.texLoc, 0);
                if (s.samplerLocs) {
                    for (var si = 0; si < s.samplerLocs.length; si++) gl.uniform1i(s.samplerLocs[si], 0);
                }
                var screen = s.uniforms.screenSize || s.uniforms._screenSize;
                if (screen) {
                    screen.values[0] = width;
                    screen.values[1] = height;
                }
                var unames = Object.keys(s.uniforms);
                for (var ui = 0; ui < unames.length; ui++) {
                    if (unames[ui].charAt(0) === "_") continue;
                    var rec = s.uniforms[unames[ui]];
                    if (!rec || rec.location == null) continue;
                    if (rec.components === 1) gl.uniform1f(rec.location, rec.values[0]);
                    else if (rec.components === 2) gl.uniform2f(rec.location, rec.values[0], rec.values[1]);
                    else if (rec.components === 3) gl.uniform3f(rec.location, rec.values[0], rec.values[1], rec.values[2]);
                    else gl.uniform4f(rec.location, rec.values[0], rec.values[1], rec.values[2], rec.values[3]);
                }
                gl.bindBuffer(gl.ARRAY_BUFFER, quadBuf);
                gl.enableVertexAttribArray(0);
                gl.enableVertexAttribArray(1);
                gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 16, 0);
                gl.vertexAttribPointer(1, 2, gl.FLOAT, false, 16, 8);
                gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
                gl.disableVertexAttribArray(0);
                gl.disableVertexAttribArray(1);
            } catch (eDraw) {
                lastErr = "shader draw failed " + (eDraw && eDraw.message ? eDraw.message : eDraw);
            }
            try { if (gl.PIXEL_UNPACK_BUFFER) gl.bindBuffer(gl.PIXEL_UNPACK_BUFFER, prevUnpack); } catch (e4) {}
            try {
                if (quadVao) gl.bindVertexArray(prevVAO);
                gl.bindBuffer(gl.ARRAY_BUFFER, prevBuf);
                gl.useProgram(prevProg);
                gl.activeTexture(prevActive);
                gl.bindTexture(gl.TEXTURE_2D, prevTex);
                gl.viewport(prevViewport[0], prevViewport[1], prevViewport[2], prevViewport[3]);
                if (prevScissor) gl.enable(gl.SCISSOR_TEST); else gl.disable(gl.SCISSOR_TEST);
                gl.scissor(prevScissorBox[0], prevScissorBox[1], prevScissorBox[2], prevScissorBox[3]);
                if (prevBlend) gl.enable(gl.BLEND); else gl.disable(gl.BLEND);
                if (prevDepth) gl.enable(gl.DEPTH_TEST); else gl.disable(gl.DEPTH_TEST);
                if (prevCull) gl.enable(gl.CULL_FACE); else gl.disable(gl.CULL_FACE);
                if (prevStencil) gl.enable(gl.STENCIL_TEST); else gl.disable(gl.STENCIL_TEST);
                gl.depthMask(!!prevDepthMask);
                gl.colorMask(!!prevColorMask[0], !!prevColorMask[1], !!prevColorMask[2], !!prevColorMask[3]);
                gl.blendEquationSeparate(prevEqRGB, prevEqA);
                gl.blendFuncSeparate(prevBlendSrcRGB, prevBlendDstRGB, prevBlendSrcA, prevBlendDstA);
            } catch (e3) {}
            return lastErr && lastErr.indexOf("shader draw failed") === 0 ? 0 : 7;
        });
        bindShader("i_gx_shader_end_draw", function () { return 1; });
        bindShader("i_gx_shader_release", function (id) {
            var s = slots[id | 0];
            if (!s) return 0;
            var gl = getGL();
            if (gl && s.prog) try { gl.deleteProgram(s.prog); } catch (e0) {}
            delete slots[id | 0];
            return 1;
        });
        bindShader("i_gx_shader_shutdown", function () {
            var gl = getGL();
            var ids = Object.keys(slots);
            for (var i = 0; i < ids.length; i++) {
                var s = slots[ids[i]];
                if (gl && s && s.prog) try { gl.deleteProgram(s.prog); } catch (e0) {}
            }
            slots = {};
            if (gl && inputTex) try { gl.deleteTexture(inputTex); } catch (e1) {}
            if (gl && quadBuf) try { gl.deleteBuffer(quadBuf); } catch (e2) {}
            if (gl && quadVao) try { gl.deleteVertexArray(quadVao); } catch (e3) {}
            inputTex = null;
            quadBuf = null;
            quadVao = null;
            quadGl = null;
            texW = 0;
            texH = 0;
            captured = 0;
            return 1;
        });
        try { console.log("[GXShader] WebGL extra.json shader API bound"); } catch (eLog) {}
    })(global);

    if (typeof document !== "undefined") {
        if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", boot);
        else boot();
        setTimeout(boot, 0);
        setTimeout(boot, 500);
    }
})(typeof window !== "undefined" ? window : this);
