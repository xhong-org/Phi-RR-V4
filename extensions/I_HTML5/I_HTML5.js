/**
 * I_HTML5 — GameMaker HTML5 backend for picker, VFS, zip, dialogs, and audio.
 * Export names match extgen `__EXT_NATIVE__i_html5_*` plus unprefixed aliases.
 */
(function (global) {
    "use strict";

    var ROOT = "/html5fs/";
    var LOGS = "/html5fs/logs/";
    var IMPORTS = "/html5fs/imports/";
    var BASE64_LIMIT = 32 * 1024 * 1024;
    var STATUS_IDLE = 0, STATUS_PICKING = 1, STATUS_OK = 2, STATUS_CANCELLED = 3, STATUS_ERROR = 4;
    var ZIP_UNKNOWN = 0, ZIP_QUEUED = 1, ZIP_RUNNING = 2, ZIP_OK = 3, ZIP_FAIL = 4, ZIP_CANCEL = 5;
    var MSG_UNKNOWN = 0, MSG_RUNNING = 1, MSG_DONE = 2;

    var files = Object.create(null);
    var dirs = Object.create(null);
    var blobUrls = Object.create(null);
    var lastError = "";
    var zipLastError = "";
    var nextTask = 1;
    var zipTasks = Object.create(null);
    var picker = { status: STATUS_IDLE, path: "", name: "", error: "" };
    var msgButtons = ["", "", "", ""];
    var msgAlign = 1;
    var msgTasks = Object.create(null);
    var nextMsg = 1;
    var audios = Object.create(null);
    var nextAudio = 1;
    var encoder = (typeof TextEncoder !== "undefined") ? new TextEncoder() : null;
    var decoder = (typeof TextDecoder !== "undefined") ? new TextDecoder("utf-8") : null;

    function toStr(value) {
        if (value === undefined || value === null) return "";
        return String(value);
    }

    function toNum(value) {
        var n = Number(value);
        return isFinite(n) ? n : 0;
    }

    function toBool(value) {
        if (value === true || value === 1 || value === "1") return true;
        if (value === false || value === 0 || value === "0" || value === "") return false;
        return !!value;
    }

    function setError(message) {
        lastError = toStr(message);
        if (lastError && global.console && console.warn) console.warn("[I_HTML5] " + lastError);
        return 0;
    }

    function clearError() {
        lastError = "";
        return 1;
    }

    function setZipError(message) {
        zipLastError = toStr(message);
        lastError = zipLastError;
        if (zipLastError && global.console && console.warn) console.warn("[I_HTML5:zip] " + zipLastError);
        return 0;
    }

    function normPath(path) {
        var p = toStr(path).replace(/\\/g, "/");
        if (!p) return "";
        p = p.replace(/\/{2,}/g, "/");
        return p;
    }

    function dirPath(path) {
        var p = normPath(path);
        if (!p) return "";
        if (p.charAt(p.length - 1) !== "/") p += "/";
        return p;
    }

    function parentDir(path) {
        var p = normPath(path);
        if (!p) return "";
        if (p.charAt(p.length - 1) === "/") p = p.substring(0, p.length - 1);
        var slash = p.lastIndexOf("/");
        if (slash < 0) return "";
        return p.substring(0, slash + 1);
    }

    function fileName(path) {
        var p = normPath(path);
        var slash = p.lastIndexOf("/");
        return slash < 0 ? p : p.substring(slash + 1);
    }

    function ensureDir(path) {
        var dir = dirPath(path);
        if (!dir) return false;
        var built = (dir.charAt(0) === "/") ? "/" : "";
        var parts = dir.split("/");
        for (var i = 0; i < parts.length; i++) {
            if (!parts[i]) continue;
            built += parts[i] + "/";
            dirs[built] = true;
        }
        dirs[dir] = true;
        return true;
    }

    function isDir(path) {
        var dir = dirPath(path);
        if (dirs[dir]) return true;
        var prefix = dir;
        var key;
        for (key in files) {
            if (Object.prototype.hasOwnProperty.call(files, key) && key.indexOf(prefix) === 0) return true;
        }
        for (key in dirs) {
            if (Object.prototype.hasOwnProperty.call(dirs, key) && key.indexOf(prefix) === 0) return true;
        }
        return false;
    }

    function existsPath(path) {
        var p = normPath(path);
        if (!p) return false;
        if (Object.prototype.hasOwnProperty.call(files, p)) return true;
        return isDir(p);
    }

    function revokeUrl(path) {
        var p = normPath(path);
        if (blobUrls[p]) {
            try { URL.revokeObjectURL(blobUrls[p]); } catch (e) {}
            delete blobUrls[p];
        }
    }

    function writeBytes(path, bytes) {
        var p = normPath(path);
        if (!p) return setError("write path is empty.");
        ensureDir(parentDir(p));
        revokeUrl(p);
        files[p] = bytes || new Uint8Array(0);
        return clearError();
    }

    function deletePath(path) {
        var p = normPath(path);
        if (!p) return setError("delete path is empty.");
        if (Object.prototype.hasOwnProperty.call(files, p)) {
            revokeUrl(p);
            delete files[p];
            return clearError();
        }
        var dir = dirPath(p);
        var key;
        var removed = false;
        for (key in files) {
            if (Object.prototype.hasOwnProperty.call(files, key) && (key === p || key.indexOf(dir) === 0)) {
                revokeUrl(key);
                delete files[key];
                removed = true;
            }
        }
        for (key in dirs) {
            if (Object.prototype.hasOwnProperty.call(dirs, key) && (key === dir || key.indexOf(dir) === 0)) {
                delete dirs[key];
                removed = true;
            }
        }
        if (!removed) return setError("delete path does not exist: " + p);
        return clearError();
    }

    function encodeUtf8(text) {
        var s = toStr(text);
        if (encoder) return encoder.encode(s);
        var out = [];
        for (var i = 0; i < s.length; i++) {
            var c = s.charCodeAt(i);
            if (c < 0x80) out.push(c);
            else if (c < 0x800) out.push(0xc0 | (c >> 6), 0x80 | (c & 0x3f));
            else if (c >= 0xd800 && c <= 0xdbff && i + 1 < s.length) {
                var c2 = s.charCodeAt(++i);
                var cp = 0x10000 + ((c & 0x3ff) << 10) + (c2 & 0x3ff);
                out.push(0xf0 | (cp >> 18), 0x80 | ((cp >> 12) & 0x3f), 0x80 | ((cp >> 6) & 0x3f), 0x80 | (cp & 0x3f));
            } else {
                out.push(0xe0 | (c >> 12), 0x80 | ((c >> 6) & 0x3f), 0x80 | (c & 0x3f));
            }
        }
        return new Uint8Array(out);
    }

    function decodeUtf8(bytes) {
        if (!bytes || !bytes.length) return "";
        if (decoder) return decoder.decode(bytes);
        var s = "";
        for (var i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
        try { return decodeURIComponent(escape(s)); } catch (e) { return s; }
    }

    function bytesToBase64(bytes) {
        if (!bytes || !bytes.length) return "";
        var binary = "";
        var chunk = 0x8000;
        for (var i = 0; i < bytes.length; i += chunk) {
            binary += String.fromCharCode.apply(null, bytes.subarray(i, i + chunk));
        }
        return btoa(binary);
    }

    function base64ToBytes(data) {
        var s = toStr(data);
        if (!s) return new Uint8Array(0);
        var binary = atob(s);
        var out = new Uint8Array(binary.length);
        for (var i = 0; i < binary.length; i++) out[i] = binary.charCodeAt(i);
        return out;
    }

    function mimeForPath(path) {
        var ext = fileName(path).split(".").pop().toLowerCase();
        var map = {
            png: "image/png", jpg: "image/jpeg", jpeg: "image/jpeg", gif: "image/gif", webp: "image/webp", bmp: "image/bmp",
            ogg: "audio/ogg", mp3: "audio/mpeg", wav: "audio/wav", flac: "audio/flac", m4a: "audio/mp4",
            mp4: "video/mp4", webm: "video/webm", json: "application/json", txt: "text/plain",
            ttf: "font/ttf", otf: "font/otf", woff: "font/woff", zip: "application/zip", pez: "application/zip"
        };
        return map[ext] || "application/octet-stream";
    }

    function blobUrlFor(path) {
        var p = normPath(path);
        if (p.indexOf("blob:") === 0 || p.indexOf("http:") === 0 || p.indexOf("https:") === 0 || p.indexOf("data:") === 0) return p;
        if (!Object.prototype.hasOwnProperty.call(files, p)) {
            setError("url path does not exist: " + p);
            return "";
        }
        if (blobUrls[p]) return blobUrls[p];
        var blob = new Blob([files[p]], { type: mimeForPath(p) });
        var url = URL.createObjectURL(blob);
        blobUrls[p] = url;
        clearError();
        return url;
    }

    function listFiles(path) {
        var p = normPath(path);
        if (!p) return setError("list path is empty."), "";
        if (Object.prototype.hasOwnProperty.call(files, p) && !isDir(p)) {
            clearError();
            return p;
        }
        var prefix = dirPath(p);
        if (!existsPath(p) && !existsPath(prefix)) {
            setError("list path does not exist: " + p);
            return "";
        }
        var out = [];
        var key;
        for (key in files) {
            if (Object.prototype.hasOwnProperty.call(files, key) && key.indexOf(prefix) === 0) out.push(key);
        }
        out.sort();
        clearError();
        return out.join("\n");
    }

    function u16(bytes, o) { return bytes[o] | (bytes[o + 1] << 8); }
    function u32(bytes, o) { return (bytes[o] | (bytes[o + 1] << 8) | (bytes[o + 2] << 16) | (bytes[o + 3] << 24)) >>> 0; }

    function reverseBits(code, len) {
        var r = 0;
        for (var i = 0; i < len; i++) {
            r = (r << 1) | (code & 1);
            code >>= 1;
        }
        return r;
    }

    function buildHuffman(lengths) {
        var n = lengths.length;
        var maxBits = 0;
        var i;
        for (i = 0; i < n; i++) if (lengths[i] > maxBits) maxBits = lengths[i];
        if (!maxBits) return { table: new Int32Array(1), maxBits: 0 };
        var blCount = new Uint16Array(maxBits + 1);
        for (i = 0; i < n; i++) blCount[lengths[i]]++;
        blCount[0] = 0;
        var nextCode = new Uint16Array(maxBits + 1);
        var code = 0;
        for (var bits = 1; bits <= maxBits; bits++) {
            code = (code + blCount[bits - 1]) << 1;
            nextCode[bits] = code;
        }
        var tableSize = 1 << maxBits;
        var table = new Int32Array(tableSize);
        for (i = 0; i < tableSize; i++) table[i] = -1;
        for (var sym = 0; sym < n; sym++) {
            var len = lengths[sym];
            if (!len) continue;
            var c = nextCode[len]++;
            var rev = reverseBits(c, len);
            var incr = 1 << len;
            for (i = rev; i < tableSize; i += incr) table[i] = (len << 16) | sym;
        }
        return { table: table, maxBits: maxBits };
    }

    var LEN_BASE = [3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258];
    var LEN_EXTRA = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0];
    var DIST_BASE = [1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577];
    var DIST_EXTRA = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13];
    var CLC_ORDER = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];
    var FIXED_LIT = (function () {
        var lengths = new Uint8Array(288);
        var i;
        for (i = 0; i <= 143; i++) lengths[i] = 8;
        for (i = 144; i <= 255; i++) lengths[i] = 9;
        for (i = 256; i <= 279; i++) lengths[i] = 7;
        for (i = 280; i <= 287; i++) lengths[i] = 8;
        return buildHuffman(lengths);
    })();
    var FIXED_DIST = (function () {
        var lengths = new Uint8Array(32);
        for (var i = 0; i < 32; i++) lengths[i] = 5;
        return buildHuffman(lengths);
    })();

    function inflateRawSync(src) {
        var data = src;
        var pos = 0;
        var bitBuf = 0;
        var bitCnt = 0;
        var out = [];

        function bits(n) {
            while (bitCnt < n) {
                if (pos >= data.length) throw new Error("deflate truncated");
                bitBuf |= data[pos++] << bitCnt;
                bitCnt += 8;
            }
            var v = bitBuf & ((1 << n) - 1);
            bitBuf >>>= n;
            bitCnt -= n;
            return v;
        }

        function decode(tree) {
            if (!tree.maxBits) throw new Error("empty huffman table");
            while (bitCnt < tree.maxBits) {
                if (pos >= data.length) throw new Error("deflate truncated");
                bitBuf |= data[pos++] << bitCnt;
                bitCnt += 8;
            }
            var entry = tree.table[bitBuf & ((1 << tree.maxBits) - 1)];
            if (entry < 0) throw new Error("invalid huffman code");
            var len = entry >>> 16;
            bitBuf >>>= len;
            bitCnt -= len;
            return entry & 0xffff;
        }

        function inflateCodes(lit, dist) {
            for (;;) {
                var sym = decode(lit);
                if (sym < 256) {
                    out.push(sym);
                } else if (sym === 256) {
                    return;
                } else {
                    var lenIdx = sym - 257;
                    if (lenIdx >= LEN_BASE.length) throw new Error("invalid length symbol");
                    var length = LEN_BASE[lenIdx] + (LEN_EXTRA[lenIdx] ? bits(LEN_EXTRA[lenIdx]) : 0);
                    var distSym = decode(dist);
                    if (distSym >= DIST_BASE.length) throw new Error("invalid distance symbol");
                    var distance = DIST_BASE[distSym] + (DIST_EXTRA[distSym] ? bits(DIST_EXTRA[distSym]) : 0);
                    if (distance <= 0 || distance > out.length) throw new Error("invalid backreference");
                    var copyFrom = out.length - distance;
                    for (var i = 0; i < length; i++) out.push(out[copyFrom + i]);
                }
            }
        }

        function inflateDynamic() {
            var nlit = bits(5) + 257;
            var ndist = bits(5) + 1;
            var nclen = bits(4) + 4;
            var clens = new Uint8Array(19);
            var i;
            for (i = 0; i < nclen; i++) clens[CLC_ORDER[i]] = bits(3);
            var clTree = buildHuffman(clens);
            var lengths = new Uint8Array(nlit + ndist);
            var n = 0;
            while (n < nlit + ndist) {
                var sym = decode(clTree);
                if (sym < 16) {
                    lengths[n++] = sym;
                } else if (sym === 16) {
                    var rep = 3 + bits(2);
                    if (!n) throw new Error("invalid repeat");
                    var prev = lengths[n - 1];
                    while (rep--) lengths[n++] = prev;
                } else if (sym === 17) {
                    var z = 3 + bits(3);
                    while (z--) lengths[n++] = 0;
                } else if (sym === 18) {
                    var z2 = 11 + bits(7);
                    while (z2--) lengths[n++] = 0;
                } else {
                    throw new Error("invalid code length symbol");
                }
            }
            inflateCodes(buildHuffman(lengths.subarray(0, nlit)), buildHuffman(lengths.subarray(nlit)));
        }

        for (;;) {
            var bfinal = bits(1);
            var btype = bits(2);
            if (btype === 0) {
                bitBuf = 0;
                bitCnt = 0;
                if (pos + 4 > data.length) throw new Error("stored block truncated");
                var len = u16(data, pos);
                var nlen = u16(data, pos + 2);
                pos += 4;
                if ((len ^ 0xffff) !== nlen) throw new Error("stored block nlen mismatch");
                if (pos + len > data.length) throw new Error("stored block truncated");
                for (var i = 0; i < len; i++) out.push(data[pos++]);
            } else if (btype === 1) {
                inflateCodes(FIXED_LIT, FIXED_DIST);
            } else if (btype === 2) {
                inflateDynamic();
            } else {
                throw new Error("invalid deflate block type");
            }
            if (bfinal) break;
        }
        return new Uint8Array(out);
    }

    function inflateRawAsync(bytes) {
        if (typeof DecompressionStream === "undefined") {
            return Promise.resolve(inflateRawSync(bytes));
        }
        try {
            var ds = new DecompressionStream("deflate-raw");
            var stream = new Blob([bytes]).stream().pipeThrough(ds);
            return new Response(stream).arrayBuffer().then(function (buf) {
                return new Uint8Array(buf);
            }).catch(function () {
                return inflateRawSync(bytes);
            });
        } catch (e) {
            return Promise.resolve(inflateRawSync(bytes));
        }
    }

    function parseZip(bytes) {
        if (!bytes || bytes.length < 22) throw new Error("archive is too small");
        if (bytes[0] !== 0x50 || bytes[1] !== 0x4b) throw new Error("not a ZIP archive");
        var i;
        var eocd = -1;
        for (i = bytes.length - 22; i >= 0; i--) {
            if (u32(bytes, i) === 0x06054b50) {
                eocd = i;
                break;
            }
            if (bytes.length - i > 0x10016) break;
        }
        if (eocd < 0) throw new Error("ZIP end of central directory not found");
        var cdSize = u32(bytes, eocd + 12);
        var cdOff = u32(bytes, eocd + 16);
        var entries = [];
        var pos = cdOff;
        var end = cdOff + cdSize;
        while (pos + 46 <= end && pos + 4 <= bytes.length) {
            if (u32(bytes, pos) !== 0x02014b50) break;
            var flag = u16(bytes, pos + 8);
            var method = u16(bytes, pos + 10);
            var compSize = u32(bytes, pos + 20);
            var uncompSize = u32(bytes, pos + 24);
            var nameLen = u16(bytes, pos + 28);
            var extraLen = u16(bytes, pos + 30);
            var commentLen = u16(bytes, pos + 32);
            var localOff = u32(bytes, pos + 42);
            var nameBytes = bytes.subarray(pos + 46, pos + 46 + nameLen);
            var name = (flag & 0x800) ? decodeUtf8(nameBytes) : decodeUtf8(nameBytes);
            pos += 46 + nameLen + extraLen + commentLen;
            entries.push({
                name: name.replace(/\\/g, "/"),
                method: method,
                flag: flag,
                compSize: compSize,
                uncompSize: uncompSize,
                localOff: localOff
            });
        }
        return entries;
    }

    function zipEntryData(bytes, entry) {
        var off = entry.localOff;
        if (off + 30 > bytes.length || u32(bytes, off) !== 0x04034b50) throw new Error("invalid local header: " + entry.name);
        var nameLen = u16(bytes, off + 26);
        var extraLen = u16(bytes, off + 28);
        var dataOff = off + 30 + nameLen + extraLen;
        if (dataOff + entry.compSize > bytes.length) throw new Error("compressed data truncated: " + entry.name);
        return bytes.subarray(dataOff, dataOff + entry.compSize);
    }

    function joinPath(base, rel) {
        var b = dirPath(base);
        var r = toStr(rel).replace(/\\/g, "/");
        while (r.charAt(0) === "/") r = r.substring(1);
        if (r.indexOf("../") >= 0) r = r.split("/").filter(function (p) { return p && p !== "." && p !== ".."; }).join("/");
        return b + r;
    }

    function extractZipBytes(bytes, outputDirectory, overwrite, cleanOutput) {
        var dest = dirPath(outputDirectory);
        if (!dest) throw new Error("output directory is empty");
        if (cleanOutput) deletePath(dest);
        ensureDir(dest);
        var entries = parseZip(bytes);
        var count = 0;
        var jobs = [];
        for (var i = 0; i < entries.length; i++) {
            var entry = entries[i];
            if (!entry.name || entry.name.charAt(entry.name.length - 1) === "/") {
                ensureDir(joinPath(dest, entry.name));
                continue;
            }
            if (entry.flag & 1) throw new Error("password-protected ZIP is not supported on HTML5: " + entry.name);
            var outPath = joinPath(dest, entry.name);
            if (!overwrite && Object.prototype.hasOwnProperty.call(files, outPath)) continue;
            ensureDir(parentDir(outPath));
            jobs.push({ entry: entry, outPath: outPath });
        }
        function writeOne(job, data) {
            writeBytes(job.outPath, data);
            count++;
        }
        var chain = Promise.resolve();
        jobs.forEach(function (job) {
            chain = chain.then(function () {
                var compressed = zipEntryData(bytes, job.entry);
                if (job.entry.method === 0) {
                    writeOne(job, new Uint8Array(compressed));
                    return;
                }
                if (job.entry.method !== 8) throw new Error("unsupported ZIP method " + job.entry.method + ": " + job.entry.name);
                return inflateRawAsync(compressed).then(function (raw) { writeOne(job, raw); });
            });
        });
        return chain.then(function () { return count; });
    }

    function detectZip(path) {
        var p = normPath(path);
        if (!Object.prototype.hasOwnProperty.call(files, p)) return "";
        var b = files[p];
        if (b.length >= 4 && b[0] === 0x50 && b[1] === 0x4b && (b[2] === 0x03 || b[2] === 0x05 || b[2] === 0x07)) return "zip";
        return "";
    }

    function collectUnder(path, includeRoot) {
        var prefix = dirPath(path);
        var p = normPath(path);
        var collected = [];
        var key;
        if (Object.prototype.hasOwnProperty.call(files, p)) {
            collected.push(p);
            return collected;
        }
        for (key in files) {
            if (!Object.prototype.hasOwnProperty.call(files, key)) continue;
            if (key.indexOf(prefix) === 0) collected.push(key);
        }
        collected.sort();
        if (!includeRoot && collected.length) {
            // keep relative names from prefix
        }
        return collected;
    }

    function dosTimeNow() {
        var d = new Date();
        var time = (d.getHours() << 11) | (d.getMinutes() << 5) | (d.getSeconds() >> 1);
        var date = ((d.getFullYear() - 1980) << 9) | ((d.getMonth() + 1) << 5) | d.getDate();
        return { time: time, date: date };
    }

    function crc32(bytes) {
        var table = crc32.table;
        if (!table) {
            table = new Uint32Array(256);
            for (var i = 0; i < 256; i++) {
                var c = i;
                for (var k = 0; k < 8; k++) c = (c & 1) ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1);
                table[i] = c >>> 0;
            }
            crc32.table = table;
        }
        var crc = 0 ^ -1;
        for (var j = 0; j < bytes.length; j++) crc = (crc >>> 8) ^ table[(crc ^ bytes[j]) & 0xff];
        return (crc ^ -1) >>> 0;
    }

    function writeU16(arr, v) { arr.push(v & 0xff, (v >> 8) & 0xff); }
    function writeU32(arr, v) { arr.push(v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff); }

    function compressStore(sourcePath, archivePath, includeRoot, overwrite) {
        var dest = normPath(archivePath);
        if (!dest) throw new Error("archive path is empty");
        if (!overwrite && Object.prototype.hasOwnProperty.call(files, dest)) throw new Error("archive exists");
        var list = collectUnder(sourcePath, includeRoot);
        if (!list.length) throw new Error("nothing to compress");
        var srcDir = dirPath(sourcePath);
        var srcBase = includeRoot ? parentDir(srcDir) : srcDir;
        var local = [];
        var central = [];
        var offset = 0;
        var stamp = dosTimeNow();
        for (var i = 0; i < list.length; i++) {
            var full = list[i];
            var rel = full;
            if (srcBase && rel.indexOf(srcBase) === 0) rel = rel.substring(srcBase.length);
            if (!rel) continue;
            var data = files[full];
            var nameBytes = encodeUtf8(rel);
            var crc = crc32(data);
            var localOff = offset;
            var lh = [];
            writeU32(lh, 0x04034b50);
            writeU16(lh, 20);
            writeU16(lh, 0x0800);
            writeU16(lh, 0);
            writeU16(lh, stamp.time);
            writeU16(lh, stamp.date);
            writeU32(lh, crc);
            writeU32(lh, data.length);
            writeU32(lh, data.length);
            writeU16(lh, nameBytes.length);
            writeU16(lh, 0);
            local = local.concat(lh);
            for (var n = 0; n < nameBytes.length; n++) local.push(nameBytes[n]);
            for (var d = 0; d < data.length; d++) local.push(data[d]);
            var ch = [];
            writeU32(ch, 0x02014b50);
            writeU16(ch, 20);
            writeU16(ch, 20);
            writeU16(ch, 0x0800);
            writeU16(ch, 0);
            writeU16(ch, stamp.time);
            writeU16(ch, stamp.date);
            writeU32(ch, crc);
            writeU32(ch, data.length);
            writeU32(ch, data.length);
            writeU16(ch, nameBytes.length);
            writeU16(ch, 0);
            writeU16(ch, 0);
            writeU16(ch, 0);
            writeU16(ch, 0);
            writeU32(ch, 0);
            writeU32(ch, localOff);
            central = central.concat(ch);
            for (n = 0; n < nameBytes.length; n++) central.push(nameBytes[n]);
            offset = local.length;
        }
        var eocd = [];
        writeU32(eocd, 0x06054b50);
        writeU16(eocd, 0);
        writeU16(eocd, 0);
        writeU16(eocd, list.length);
        writeU16(eocd, list.length);
        writeU32(eocd, central.length);
        writeU32(eocd, local.length);
        writeU16(eocd, 0);
        writeBytes(dest, new Uint8Array(local.concat(central, eocd)));
        return true;
    }

    function makeTask() {
        var id = nextTask++;
        zipTasks[id] = { status: ZIP_QUEUED, exitCode: 0, error: "", cancelled: false };
        return id;
    }

    function acceptFromFilter(filter) {
        var f = toStr(filter).toLowerCase();
        if (!f || f.indexOf("zip") >= 0 || f.indexOf("pez") >= 0) {
            return ".zip,.pez,application/zip,application/x-zip-compressed,application/octet-stream";
        }
        return filter;
    }

    function ensureOverlay() {
        var id = "i-html5-overlay-root";
        var el = document.getElementById(id);
        if (el) return el;
        el = document.createElement("div");
        el.id = id;
        el.style.cssText = "position:fixed;inset:0;display:none;align-items:center;justify-content:center;background:rgba(0,0,0,0.55);z-index:2147483646;font-family:sans-serif;";
        document.body.appendChild(el);
        return el;
    }

    function showDomDialog(title, message, kind, done) {
        var root = ensureOverlay();
        root.innerHTML = "";
        var box = document.createElement("div");
        box.style.cssText = "min-width:280px;max-width:480px;background:#1c2230;color:#fff;border:1px solid #6a7388;border-radius:8px;padding:18px 20px;";
        var h = document.createElement("div");
        h.textContent = title || "Message";
        h.style.cssText = "font-size:18px;margin-bottom:10px;color:" + (kind === 3 ? "#ff6b6b" : kind === 2 ? "#ffd166" : "#9ad1ff") + ";";
        var p = document.createElement("div");
        p.textContent = message || "";
        p.style.cssText = "font-size:14px;line-height:1.4;white-space:pre-wrap;margin-bottom:16px;";
        var row = document.createElement("div");
        row.style.cssText = "display:flex;gap:8px;" + (msgAlign === 2 ? "justify-content:center;" : msgAlign === 3 ? "justify-content:flex-end;" : "justify-content:flex-start;");
        var labels = [];
        for (var i = 0; i < 4; i++) if (msgButtons[i]) labels.push({ index: i + 1, text: msgButtons[i] });
        if (!labels.length) labels.push({ index: 1, text: "OK" });
        labels.forEach(function (btn) {
            var b = document.createElement("button");
            b.textContent = btn.text;
            b.style.cssText = "background:#3b82f6;color:#fff;border:0;border-radius:4px;padding:8px 14px;cursor:pointer;";
            b.onclick = function () {
                root.style.display = "none";
                done(btn.index);
            };
            row.appendChild(b);
        });
        box.appendChild(h);
        box.appendChild(p);
        box.appendChild(row);
        root.appendChild(box);
        root.style.display = "flex";
    }

    function mediaUrl(path) {
        var p = toStr(path);
        if (p.indexOf("blob:") === 0 || p.indexOf("http") === 0 || p.indexOf("data:") === 0) return p;
        return blobUrlFor(p);
    }

    function exportFn(name, fn) {
        global[name] = fn;
        global["__EXT_NATIVE__" + name] = fn;
    }

    function stripHtml5AssetPrefix(value) {
        var v = toStr(value);
        if (!v) return v;
        var changed = true;
        while (changed) {
            changed = false;
            if (v.indexOf("html5game/html5game/") === 0) {
                v = v.substring(10);
                changed = true;
            }
            var prefixes = ["html5game/", "./html5game/"];
            for (var i = 0; i < prefixes.length; i++) {
                var prefix = prefixes[i];
                if (v.indexOf(prefix + "blob:") === 0 || v.indexOf(prefix + "data:") === 0
                    || v.indexOf(prefix + "http:") === 0 || v.indexOf(prefix + "https:") === 0) {
                    v = v.substring(prefix.length);
                    changed = true;
                }
            }
        }
        return v;
    }

    function patchElementSrc(ctor) {
        if (!ctor || !ctor.prototype) return;
        var proto = ctor.prototype;
        var desc = Object.getOwnPropertyDescriptor(proto, "src");
        if (!desc || !desc.set || desc.set.__plsPatched) return;
        var origSet = desc.set;
        var patchedSet = function (next) {
            origSet.call(this, stripHtml5AssetPrefix(next));
        };
        patchedSet.__plsPatched = true;
        Object.defineProperty(proto, "src", {
            configurable: true,
            enumerable: desc.enumerable,
            get: desc.get,
            set: patchedSet
        });
    }

    function unlockHtml5Audio() {
        var id;
        for (id in audios) {
            if (!Object.prototype.hasOwnProperty.call(audios, id)) continue;
            var el = audios[id];
            if (!el || !el.__plsNeedsGesture) continue;
            el.__plsNeedsGesture = false;
            var playPromise = el.play();
            if (playPromise && playPromise.catch) playPromise.catch(function () {});
        }
        try {
            var AudioCtx = global.AudioContext || global.webkitAudioContext;
            if (AudioCtx) {
                if (!global.__plsAudioContext) global.__plsAudioContext = new AudioCtx();
                if (global.__plsAudioContext.state === "suspended") global.__plsAudioContext.resume();
            }
        } catch (err) {}
    }

    function installHtml5RuntimeHooks() {
        if (global.__plsHtml5Hooks) return;
        global.__plsHtml5Hooks = true;
        try {
            patchElementSrc(global.HTMLImageElement);
            patchElementSrc(global.HTMLAudioElement);
        } catch (err) {}
        if (typeof document === "undefined") return;
        var once = function () {
            unlockHtml5Audio();
            document.removeEventListener("pointerdown", once, true);
            document.removeEventListener("touchstart", once, true);
            document.removeEventListener("keydown", once, true);
        };
        document.addEventListener("pointerdown", once, true);
        document.addEventListener("touchstart", once, true);
        document.addEventListener("keydown", once, true);
    }

    exportFn("i_html5_initialize", function () {
        ensureDir(ROOT);
        ensureDir(LOGS);
        ensureDir(IMPORTS);
        installHtml5RuntimeHooks();
        clearError();
        zipLastError = "";
        return 1;
    });

    exportFn("i_html5_shutdown", function () {
        var key;
        for (key in blobUrls) if (Object.prototype.hasOwnProperty.call(blobUrls, key)) revokeUrl(key);
        for (key in audios) {
            if (!Object.prototype.hasOwnProperty.call(audios, key)) continue;
            try { audios[key].pause(); } catch (e) {}
        }
        files = Object.create(null);
        dirs = Object.create(null);
        audios = Object.create(null);
        zipTasks = Object.create(null);
        msgTasks = Object.create(null);
        picker.status = STATUS_IDLE;
        return 1;
    });

    exportFn("i_html5_available", function () { return 1; });

    exportFn("i_html5_open_pick", function (filter) {
        if (picker.status === STATUS_PICKING) return 0;
        if (typeof document === "undefined") {
            picker.status = STATUS_ERROR;
            picker.error = "document is unavailable.";
            return 0;
        }
        picker.status = STATUS_PICKING;
        picker.path = "";
        picker.name = "";
        picker.error = "";
        var input = document.createElement("input");
        input.type = "file";
        input.accept = acceptFromFilter(filter);
        input.style.display = "none";
        var finished = false;
        function fail(message, status) {
            if (finished) return;
            finished = true;
            picker.status = status;
            picker.error = message;
            try { document.body.removeChild(input); } catch (e) {}
        }
        input.onchange = function () {
            if (finished) return;
            var file = input.files && input.files[0];
            if (!file) {
                fail("No file selected.", STATUS_CANCELLED);
                return;
            }
            var name = file.name || "chart.zip";
            name = name.replace(/[\\/:*?"<>|]/g, "_");
            file.arrayBuffer().then(function (buf) {
                var dest = IMPORTS + name;
                writeBytes(dest, new Uint8Array(buf));
                picker.path = dest;
                picker.name = name;
                picker.error = "";
                picker.status = STATUS_OK;
                finished = true;
                try { document.body.removeChild(input); } catch (e) {}
            }).catch(function (err) {
                fail(err && err.message ? err.message : "Failed to read the selected file.", STATUS_ERROR);
            });
        };
        input.oncancel = function () { fail("No file selected.", STATUS_CANCELLED); };
        document.body.appendChild(input);
        try {
            input.click();
        } catch (e) {
            fail(e && e.message ? e.message : "Failed to open the file picker.", STATUS_ERROR);
            return 0;
        }
        setTimeout(function () {
            if (picker.status === STATUS_PICKING && input.files && input.files.length === 0) {
                /* still waiting for the user */
            }
        }, 0);
        return 1;
    });

    exportFn("i_html5_open_busy", function () { return picker.status === STATUS_PICKING ? 1 : 0; });
    exportFn("i_html5_open_status", function () { return picker.status; });
    exportFn("i_html5_open_path", function () { return picker.path || ""; });
    exportFn("i_html5_open_name", function () { return picker.name || ""; });
    exportFn("i_html5_open_error", function () { return picker.error || ""; });
    exportFn("i_html5_open_reset", function () {
        picker.status = STATUS_IDLE;
        picker.path = "";
        picker.name = "";
        picker.error = "";
        return 1;
    });

    exportFn("i_html5_files_root", function () { return ROOT; });
    exportFn("i_html5_files_logs_dir", function () { ensureDir(LOGS); return LOGS; });
    exportFn("i_html5_files_mkdir", function (path) { return ensureDir(path) ? clearError() : setError("mkdir path is empty."); });
    exportFn("i_html5_files_exists", function (path) { return existsPath(path) ? 1 : 0; });
    exportFn("i_html5_files_is_dir", function (path) { return isDir(path) ? 1 : 0; });
    exportFn("i_html5_files_list", function (path) { return listFiles(path); });
    exportFn("i_html5_files_write_text", function (path, text) { return writeBytes(path, encodeUtf8(text)); });
    exportFn("i_html5_files_append_text", function (path, text) {
        var p = normPath(path);
        var extra = encodeUtf8(text);
        if (Object.prototype.hasOwnProperty.call(files, p)) {
            var cur = files[p];
            var merged = new Uint8Array(cur.length + extra.length);
            merged.set(cur, 0);
            merged.set(extra, cur.length);
            return writeBytes(p, merged);
        }
        return writeBytes(p, extra);
    });
    exportFn("i_html5_files_read_text", function (path) {
        var p = normPath(path);
        if (!Object.prototype.hasOwnProperty.call(files, p)) {
            setError("read path does not exist: " + p);
            return "";
        }
        clearError();
        return decodeUtf8(files[p]);
    });
    exportFn("i_html5_files_copy", function (sourcePath, destPath) {
        var src = normPath(sourcePath);
        var dst = normPath(destPath);
        if (!Object.prototype.hasOwnProperty.call(files, src)) return setError("copy source does not exist: " + src);
        return writeBytes(dst, new Uint8Array(files[src]));
    });
    exportFn("i_html5_files_delete", function (path) { return deletePath(path); });
    exportFn("i_html5_files_size", function (path) {
        var p = normPath(path);
        if (!Object.prototype.hasOwnProperty.call(files, p)) return -1;
        return files[p].length;
    });
    exportFn("i_html5_files_write_base64", function (path, data) {
        try { return writeBytes(path, base64ToBytes(data)); }
        catch (e) { return setError(e.message || "base64 decode failed"); }
    });
    exportFn("i_html5_files_append_base64", function (path, data) {
        try {
            var extra = base64ToBytes(data);
            var p = normPath(path);
            if (Object.prototype.hasOwnProperty.call(files, p)) {
                var cur = files[p];
                var merged = new Uint8Array(cur.length + extra.length);
                merged.set(cur, 0);
                merged.set(extra, cur.length);
                return writeBytes(p, merged);
            }
            return writeBytes(p, extra);
        } catch (e) {
            return setError(e.message || "base64 decode failed");
        }
    });
    exportFn("i_html5_files_read_base64", function (path) {
        var p = normPath(path);
        if (!Object.prototype.hasOwnProperty.call(files, p)) {
            setError("read path does not exist: " + p);
            return "";
        }
        if (files[p].length > BASE64_LIMIT) {
            setError("file exceeds 32MB base64 cap");
            return "";
        }
        clearError();
        return bytesToBase64(files[p]);
    });
    exportFn("i_html5_files_read_base64_range", function (path, offset, size) {
        var p = normPath(path);
        if (!Object.prototype.hasOwnProperty.call(files, p)) {
            setError("read path does not exist: " + p);
            return "";
        }
        var buf = files[p];
        var start = Math.max(0, toNum(offset) | 0);
        var count = toNum(size);
        if (count < 0) count = buf.length - start;
        if (start > buf.length) start = buf.length;
        if (start + count > buf.length) count = buf.length - start;
        if (count < 0) count = 0;
        if (count > BASE64_LIMIT) {
            setError("range exceeds 32MB base64 cap");
            return "";
        }
        clearError();
        return bytesToBase64(buf.subarray(start, start + count));
    });
    exportFn("i_html5_files_url", function (path) { return blobUrlFor(path); });
    exportFn("i_html5_files_error", function () { return lastError || ""; });

    exportFn("i_html5_zip_available", function () { return 1; });
    exportFn("i_html5_zip_detect", function (archivePath) { return detectZip(archivePath); });
    exportFn("i_html5_zip_extract", function (archivePath, outputDirectory, overwrite, cleanOutput) {
        try {
            var p = normPath(archivePath);
            if (!Object.prototype.hasOwnProperty.call(files, p)) return setZipError("Zip file does not exist.");
            var bytes = files[p];
            var entries = parseZip(bytes);
            for (var i = 0; i < entries.length; i++) {
                if (entries[i].method === 8) {
                    /* sync path still works via inflateRawSync through the async helper's fallback */
                }
            }
            var dest = dirPath(outputDirectory);
            if (toBool(cleanOutput)) deletePath(dest);
            ensureDir(dest);
            for (i = 0; i < entries.length; i++) {
                var entry = entries[i];
                if (!entry.name || entry.name.charAt(entry.name.length - 1) === "/") {
                    ensureDir(joinPath(dest, entry.name));
                    continue;
                }
                if (entry.flag & 1) return setZipError("password-protected ZIP is not supported on HTML5");
                var outPath = joinPath(dest, entry.name);
                if (!toBool(overwrite) && Object.prototype.hasOwnProperty.call(files, outPath)) continue;
                var compressed = zipEntryData(bytes, entry);
                var raw;
                if (entry.method === 0) raw = new Uint8Array(compressed);
                else if (entry.method === 8) raw = inflateRawSync(compressed);
                else return setZipError("unsupported ZIP method " + entry.method);
                writeBytes(outPath, raw);
            }
            zipLastError = "";
            return 1;
        } catch (e) {
            return setZipError(e.message || "ZIP extract failed");
        }
    });
    exportFn("i_html5_zip_extract_async", function (archivePath, outputDirectory, overwrite, cleanOutput) {
        var id = makeTask();
        var task = zipTasks[id];
        var p = normPath(archivePath);
        if (!Object.prototype.hasOwnProperty.call(files, p)) {
            task.status = ZIP_FAIL;
            task.exitCode = 1;
            task.error = "Zip file does not exist.";
            zipLastError = task.error;
            return id;
        }
        task.status = ZIP_RUNNING;
        extractZipBytes(files[p], outputDirectory, toBool(overwrite), toBool(cleanOutput)).then(function () {
            if (task.cancelled) {
                task.status = ZIP_CANCEL;
                task.exitCode = 1;
                task.error = "ZIP extraction was cancelled.";
                return;
            }
            task.status = ZIP_OK;
            task.exitCode = 0;
            task.error = "";
            zipLastError = "";
        }).catch(function (err) {
            task.status = ZIP_FAIL;
            task.exitCode = 1;
            task.error = err && err.message ? err.message : "ZIP extraction failed.";
            zipLastError = task.error;
        });
        return id;
    });
    exportFn("i_html5_zip_compress", function (sourcePath, archivePath, includeRoot, overwrite) {
        try {
            compressStore(sourcePath, archivePath, toBool(includeRoot), toBool(overwrite));
            zipLastError = "";
            return 1;
        } catch (e) {
            return setZipError(e.message || "ZIP compress failed");
        }
    });
    exportFn("i_html5_zip_compress_async", function (sourcePath, archivePath, includeRoot, overwrite) {
        var id = makeTask();
        var task = zipTasks[id];
        task.status = ZIP_RUNNING;
        setTimeout(function () {
            if (task.cancelled) {
                task.status = ZIP_CANCEL;
                task.exitCode = 1;
                task.error = "ZIP compression was cancelled.";
                return;
            }
            try {
                compressStore(sourcePath, archivePath, toBool(includeRoot), toBool(overwrite));
                task.status = ZIP_OK;
                task.exitCode = 0;
                task.error = "";
                zipLastError = "";
            } catch (e) {
                task.status = ZIP_FAIL;
                task.exitCode = 1;
                task.error = e.message || "ZIP compression failed.";
                zipLastError = task.error;
            }
        }, 0);
        return id;
    });
    exportFn("i_html5_zip_task_status", function (taskId) {
        var task = zipTasks[toNum(taskId) | 0];
        return task ? task.status : ZIP_UNKNOWN;
    });
    exportFn("i_html5_zip_task_exit_code", function (taskId) {
        var task = zipTasks[toNum(taskId) | 0];
        return task ? task.exitCode : 0;
    });
    exportFn("i_html5_zip_task_error", function (taskId) {
        var task = zipTasks[toNum(taskId) | 0];
        return task ? (task.error || "") : "";
    });
    exportFn("i_html5_zip_task_cancel", function (taskId) {
        var task = zipTasks[toNum(taskId) | 0];
        if (!task) return 0;
        task.cancelled = true;
        if (task.status === ZIP_QUEUED || task.status === ZIP_RUNNING) {
            task.status = ZIP_CANCEL;
            task.exitCode = 1;
            task.error = "ZIP extraction was cancelled.";
        }
        return 1;
    });
    exportFn("i_html5_zip_task_release", function (taskId) {
        var id = toNum(taskId) | 0;
        if (!zipTasks[id]) return 0;
        delete zipTasks[id];
        return 1;
    });
    exportFn("i_html5_zip_last_error", function () { return zipLastError || ""; });

    exportFn("i_html5_msgbox_clear_buttons", function () {
        msgButtons = ["", "", "", ""];
        return 1;
    });
    exportFn("i_html5_msgbox_set_button", function (index, text) {
        var i = (toNum(index) | 0) - 1;
        if (i < 0 || i > 3) return 0;
        msgButtons[i] = toStr(text);
        return 1;
    });
    exportFn("i_html5_msgbox_set_button_alignment", function (alignment) {
        msgAlign = toNum(alignment) | 0;
        return 1;
    });
    exportFn("i_html5_msgbox_show_sync", function (message, title, kind) {
        var labels = [];
        for (var i = 0; i < 4; i++) if (msgButtons[i]) labels.push(msgButtons[i]);
        if (labels.length <= 1) {
            if (global.alert) global.alert((title ? title + "\n\n" : "") + toStr(message));
            return 1;
        }
        if (global.confirm) {
            var ok = global.confirm((title ? title + "\n\n" : "") + toStr(message));
            return ok ? 1 : 2;
        }
        return 1;
    });
    exportFn("i_html5_msgbox_show_async", function (message, title, kind) {
        var id = nextMsg++;
        msgTasks[id] = { status: MSG_RUNNING, result: 0 };
        if (typeof document === "undefined") {
            msgTasks[id].status = MSG_DONE;
            msgTasks[id].result = 1;
            return id;
        }
        showDomDialog(toStr(title), toStr(message), toNum(kind) | 0, function (result) {
            if (!msgTasks[id]) return;
            msgTasks[id].status = MSG_DONE;
            msgTasks[id].result = result;
        });
        return id;
    });
    exportFn("i_html5_msgbox_task_status", function (taskId) {
        var task = msgTasks[toNum(taskId) | 0];
        return task ? task.status : MSG_UNKNOWN;
    });
    exportFn("i_html5_msgbox_task_result", function (taskId) {
        var task = msgTasks[toNum(taskId) | 0];
        return task ? task.result : 0;
    });
    exportFn("i_html5_msgbox_task_release", function (taskId) {
        var id = toNum(taskId) | 0;
        if (!msgTasks[id]) return 0;
        delete msgTasks[id];
        return 1;
    });

    exportFn("i_html5_audio_create", function (path, useStream) {
        var url = mediaUrl(path);
        if (!url) return 0;
        var el = new Audio();
        el.preload = toBool(useStream) ? "auto" : "auto";
        el.src = url;
        try { el.load(); } catch (e) {}
        var id = nextAudio++;
        audios[id] = el;
        return id;
    });
    exportFn("i_html5_audio_play", function (handle) {
        var el = audios[toNum(handle) | 0];
        if (!el) return 0;
        var p = el.play();
        if (p && p.catch) p.catch(function () { el.__plsNeedsGesture = true; });
        return 1;
    });
    exportFn("i_html5_audio_pause", function (handle) {
        var el = audios[toNum(handle) | 0];
        if (!el) return 0;
        el.pause();
        return 1;
    });
    exportFn("i_html5_audio_resume", function (handle) {
        var el = audios[toNum(handle) | 0];
        if (!el) return 0;
        var p = el.play();
        if (p && p.catch) p.catch(function () { el.__plsNeedsGesture = true; });
        return 1;
    });
    exportFn("i_html5_audio_stop", function (handle) {
        var el = audios[toNum(handle) | 0];
        if (!el) return 0;
        el.pause();
        try { el.currentTime = 0; } catch (e) {}
        return 1;
    });
    exportFn("i_html5_audio_set_position_ms", function (handle, ms) {
        var el = audios[toNum(handle) | 0];
        if (!el) return 0;
        try { el.currentTime = Math.max(0, toNum(ms) / 1000); } catch (e) { return 0; }
        return 1;
    });
    exportFn("i_html5_audio_get_position_ms", function (handle) {
        var el = audios[toNum(handle) | 0];
        if (!el) return 0;
        return (el.currentTime || 0) * 1000;
    });
    exportFn("i_html5_audio_get_length_ms", function (handle) {
        var el = audios[toNum(handle) | 0];
        if (!el) return 0;
        var d = el.duration;
        if (!isFinite(d)) return 0;
        return d * 1000;
    });
    exportFn("i_html5_audio_release", function (handle) {
        var id = toNum(handle) | 0;
        var el = audios[id];
        if (!el) return 0;
        try { el.pause(); el.removeAttribute("src"); el.load(); } catch (e) {}
        delete audios[id];
        return 1;
    });
    exportFn("i_html5_audio_play_oneshot", function (path) {
        var url = mediaUrl(path);
        if (!url) return 0;
        var el = new Audio(url);
        var p = el.play();
        if (p && p.catch) p.catch(function () {});
        return 1;
    });

    if (typeof document !== "undefined") {
        ensureDir(ROOT);
        ensureDir(LOGS);
        ensureDir(IMPORTS);
        installHtml5RuntimeHooks();
    }
})(typeof window !== "undefined" ? window : globalThis);
