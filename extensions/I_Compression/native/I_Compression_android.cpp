#include "native/ICompressionInternal_native.h"
#include "archive_magic.hpp"

#include <archive.h>
#include <archive_entry.h>

#include <android/log.h>
#include <dlfcn.h>
#include <jni.h>
#include <limits.h>
#include <locale.h>
#include <unistd.h>
#include <zlib.h>

#include <algorithm>
#include <atomic>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>
#include <thread>
#include <unordered_map>
#include <vector>

namespace {

constexpr std::uintmax_t kMaxArchiveBytes = 1ull << 30;
constexpr const char* kLogTag = "ICompression";

enum TaskStatus : int32_t {
    TaskUnknown = 0,
    TaskQueued = 1,
    TaskRunning = 2,
    TaskSucceeded = 3,
    TaskFailed = 4,
    TaskCancelled = 5,
};

struct ZipTask {
    std::atomic<int32_t> status{TaskQueued};
    std::atomic<int32_t> exit_code{-1};
    std::atomic<bool> cancel_requested{false};
    std::mutex mutex;
    std::string error;
    std::thread worker;
};

std::mutex g_tasks_mutex;
std::unordered_map<int32_t, std::shared_ptr<ZipTask>> g_tasks;
std::atomic<int32_t> g_next_task_id{1};
std::mutex g_error_mutex;
std::string g_last_error;
std::atomic<bool> g_shutting_down{false};

void set_last_error(std::string message) {
    std::lock_guard lock(g_error_mutex);
    g_last_error = std::move(message);
}

void log_info(const std::string& message) {
    __android_log_print(ANDROID_LOG_INFO, kLogTag, "%s", message.c_str());
}

std::shared_ptr<ZipTask> find_task(int32_t task_id) {
    std::lock_guard lock(g_tasks_mutex);
    const auto it = g_tasks.find(task_id);
    return it == g_tasks.end() ? nullptr : it->second;
}

bool is_dangerous_clean_path(const std::filesystem::path& path) {
    const auto absolute = std::filesystem::absolute(path).lexically_normal();
    return absolute.empty() || absolute == absolute.root_path();
}

std::filesystem::path resolve_real_path(const std::filesystem::path& path) {
    std::error_code error;
    auto canonical = std::filesystem::weakly_canonical(path, error);
    if (!error && !canonical.empty()) return canonical;
    char buffer[PATH_MAX]{};
    if (realpath(path.c_str(), buffer) != nullptr) {
        return std::filesystem::path(buffer);
    }
    return path.lexically_normal();
}

bool looks_like_utf8(std::string_view text) {
    std::size_t i = 0;
    while (i < text.size()) {
        const auto ch = static_cast<unsigned char>(text[i]);
        std::size_t need = 0;
        if (ch <= 0x7F) need = 1;
        else if ((ch & 0xE0) == 0xC0) need = 2;
        else if ((ch & 0xF0) == 0xE0) need = 3;
        else if ((ch & 0xF8) == 0xF0) need = 4;
        else return false;
        if (i + need > text.size()) return false;
        for (std::size_t n = 1; n < need; ++n) {
            if ((static_cast<unsigned char>(text[i + n]) & 0xC0) != 0x80) return false;
        }
        i += need;
    }
    return true;
}

std::string hex_preview(std::string_view text, std::size_t max_bytes = 24);

JavaVM* g_java_vm = nullptr;

extern "C" void ICompression_StoreJavaVM(JavaVM* vm) {
    g_java_vm = vm;
    __android_log_print(ANDROID_LOG_INFO, kLogTag, "stored JavaVM=%p", static_cast<void*>(vm));
}

JavaVM* java_vm() {
    if (g_java_vm) return g_java_vm;
    static JavaVM* cached = nullptr;
    if (cached) return cached;
    using GetCreatedJavaVMs = jint (*)(JavaVM**, jsize, jsize*);
    auto load = [](void* handle, const char* name) -> GetCreatedJavaVMs {
        return handle ? reinterpret_cast<GetCreatedJavaVMs>(dlsym(handle, name)) : nullptr;
    };
    GetCreatedJavaVMs fn = load(RTLD_DEFAULT, "JNI_GetCreatedJavaVMs");
    if (!fn) fn = load(dlopen("libnativehelper.so", RTLD_NOW), "JNI_GetCreatedJavaVMs");
    if (!fn) fn = load(dlopen("libart.so", RTLD_NOW), "JNI_GetCreatedJavaVMs");
    if (!fn) return nullptr;
    JavaVM* created = nullptr;
    jsize count = 0;
    fn(&created, 1, &count);
    if (count > 0 && created) {
        cached = created;
        g_java_vm = created;
    }
    return cached;
}

struct JniAttach {
    JNIEnv* env = nullptr;
    bool detach = false;

    JniAttach() {
        JavaVM* vm = java_vm();
        if (!vm) return;
        const jint status = vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
        if (status == JNI_OK) return;
        if (status == JNI_EDETACHED && vm->AttachCurrentThread(&env, nullptr) == JNI_OK) {
            detach = true;
            return;
        }
        env = nullptr;
    }

    ~JniAttach() {
        if (detach) {
            if (JavaVM* vm = java_vm()) vm->DetachCurrentThread();
        }
    }
};

std::u16string utf8_to_utf16(std::string_view text) {
    std::u16string out;
    std::size_t i = 0;
    while (i < text.size()) {
        const auto lead = static_cast<unsigned char>(text[i]);
        std::uint32_t code = 0;
        std::size_t need = 0;
        if (lead < 0x80) {
            code = lead;
            need = 1;
        } else if ((lead & 0xE0) == 0xC0) {
            code = lead & 0x1F;
            need = 2;
        } else if ((lead & 0xF0) == 0xE0) {
            code = lead & 0x0F;
            need = 3;
        } else if ((lead & 0xF8) == 0xF0) {
            code = lead & 0x07;
            need = 4;
        } else {
            ++i;
            continue;
        }
        if (i + need > text.size()) break;
        for (std::size_t n = 1; n < need; ++n) {
            code = (code << 6) | (static_cast<unsigned char>(text[i + n]) & 0x3F);
        }
        i += need;
        if (code <= 0xFFFF) {
            out.push_back(static_cast<char16_t>(code));
        } else {
            code -= 0x10000;
            out.push_back(static_cast<char16_t>(0xD800 + (code >> 10)));
            out.push_back(static_cast<char16_t>(0xDC00 + (code & 0x3FF)));
        }
    }
    return out;
}

jstring utf8_to_jstring(JNIEnv* env, const std::string& utf8) {
    const auto utf16 = utf8_to_utf16(utf8);
    if (utf16.empty()) return env->NewStringUTF("");
    return env->NewString(reinterpret_cast<const jchar*>(utf16.data()), static_cast<jsize>(utf16.size()));
}

bool java_exception(JNIEnv* env, std::string* error, const char* what) {
    if (!env->ExceptionCheck()) return false;
    env->ExceptionDescribe();
    env->ExceptionClear();
    if (error) *error = std::string(what) + " threw a JNI exception.";
    return true;
}

bool java_mkdirs(JNIEnv* env, const std::string& path, std::string* error) {
    jclass file_class = env->FindClass("java/io/File");
    if (!file_class) return false;
    jmethodID ctor = env->GetMethodID(file_class, "<init>", "(Ljava/lang/String;)V");
    jmethodID mkdirs = env->GetMethodID(file_class, "mkdirs", "()Z");
    jmethodID is_dir = env->GetMethodID(file_class, "isDirectory", "()Z");
    jstring jpath = utf8_to_jstring(env, path);
    if (!ctor || !mkdirs || !is_dir || !jpath) {
        env->DeleteLocalRef(file_class);
        return false;
    }
    jobject file = env->NewObject(file_class, ctor, jpath);
    if (!file || java_exception(env, error, "File.mkdirs")) {
        env->DeleteLocalRef(jpath);
        env->DeleteLocalRef(file_class);
        return false;
    }
    env->CallBooleanMethod(file, mkdirs);
    const bool ok = env->CallBooleanMethod(file, is_dir);
    env->DeleteLocalRef(file);
    env->DeleteLocalRef(jpath);
    env->DeleteLocalRef(file_class);
    return ok && !java_exception(env, error, "File.mkdirs");
}

bool java_file_exists(JNIEnv* env, const std::string& path) {
    jclass file_class = env->FindClass("java/io/File");
    if (!file_class) return false;
    jmethodID ctor = env->GetMethodID(file_class, "<init>", "(Ljava/lang/String;)V");
    jmethodID exists = env->GetMethodID(file_class, "exists", "()Z");
    jstring jpath = utf8_to_jstring(env, path);
    if (!ctor || !exists || !jpath) {
        env->DeleteLocalRef(file_class);
        return false;
    }
    jobject file = env->NewObject(file_class, ctor, jpath);
    const bool ok = file && env->CallBooleanMethod(file, exists);
    if (file) env->DeleteLocalRef(file);
    env->DeleteLocalRef(jpath);
    env->DeleteLocalRef(file_class);
    if (env->ExceptionCheck()) env->ExceptionClear();
    return ok;
}

void java_list_dir(JNIEnv* env, const std::string& path) {
    jclass file_class = env->FindClass("java/io/File");
    if (!file_class) return;
    jmethodID ctor = env->GetMethodID(file_class, "<init>", "(Ljava/lang/String;)V");
    jmethodID list = env->GetMethodID(file_class, "list", "()[Ljava/lang/String;");
    jstring jpath = utf8_to_jstring(env, path);
    if (!ctor || !list || !jpath) {
        env->DeleteLocalRef(file_class);
        return;
    }
    jobject file = env->NewObject(file_class, ctor, jpath);
    auto names = file ? static_cast<jobjectArray>(env->CallObjectMethod(file, list)) : nullptr;
    if (names) {
        const jsize count = env->GetArrayLength(names);
        log_info("java list " + path + " count=" + std::to_string(static_cast<int>(count)));
        for (jsize i = 0; i < count; ++i) {
            auto item = static_cast<jstring>(env->GetObjectArrayElement(names, i));
            if (!item) continue;
            const char* utf = env->GetStringUTFChars(item, nullptr);
            log_info(std::string("java child[") + std::to_string(static_cast<int>(i)) + "]=" + (utf ? utf : "")
                + " hex=" + hex_preview(utf ? utf : ""));
            if (utf) env->ReleaseStringUTFChars(item, utf);
            env->DeleteLocalRef(item);
        }
        env->DeleteLocalRef(names);
    } else {
        log_info("java list failed for " + path);
    }
    if (file) env->DeleteLocalRef(file);
    env->DeleteLocalRef(jpath);
    env->DeleteLocalRef(file_class);
    if (env->ExceptionCheck()) env->ExceptionClear();
}

bool java_write_archive_entry(JNIEnv* env, const std::string& dest_utf8, struct archive* reader, std::string* error) {
    const auto slash = dest_utf8.find_last_of('/');
    if (slash != std::string::npos && !java_mkdirs(env, dest_utf8.substr(0, slash), error)) {
        if (error && error->empty()) *error = "Failed to create parent directory: " + dest_utf8;
        return false;
    }
    jclass file_class = env->FindClass("java/io/File");
    jclass stream_class = env->FindClass("java/io/FileOutputStream");
    if (!file_class || !stream_class) {
        if (error) *error = "JNI File/FileOutputStream classes were not found.";
        return false;
    }
    jmethodID file_ctor = env->GetMethodID(file_class, "<init>", "(Ljava/lang/String;)V");
    jmethodID stream_ctor = env->GetMethodID(stream_class, "<init>", "(Ljava/io/File;)V");
    jmethodID write = env->GetMethodID(stream_class, "write", "([BII)V");
    jmethodID close = env->GetMethodID(stream_class, "close", "()V");
    jstring jpath = utf8_to_jstring(env, dest_utf8);
    if (!file_ctor || !stream_ctor || !write || !close || !jpath) {
        if (error) *error = "JNI FileOutputStream methods were not found.";
        return false;
    }
    jobject file = env->NewObject(file_class, file_ctor, jpath);
    jobject stream = file ? env->NewObject(stream_class, stream_ctor, file) : nullptr;
    if (!stream || java_exception(env, error, "FileOutputStream")) {
        if (error && error->empty()) *error = "Failed to open Java file: " + dest_utf8;
        if (file) env->DeleteLocalRef(file);
        env->DeleteLocalRef(jpath);
        env->DeleteLocalRef(file_class);
        env->DeleteLocalRef(stream_class);
        return false;
    }

    const void* buffer = nullptr;
    size_t size = 0;
    la_int64_t offset = 0;
    while (true) {
        const int read_status = archive_read_data_block(reader, &buffer, &size, &offset);
        if (read_status == ARCHIVE_EOF) break;
        if (read_status != ARCHIVE_OK && read_status != ARCHIVE_WARN) {
            env->CallVoidMethod(stream, close);
            env->DeleteLocalRef(stream);
            env->DeleteLocalRef(file);
            env->DeleteLocalRef(jpath);
            env->DeleteLocalRef(file_class);
            env->DeleteLocalRef(stream_class);
            *error = std::string("Failed to read archive payload: ") + archive_error_string(reader);
            return false;
        }
        if (size == 0) continue;
        jbyteArray chunk = env->NewByteArray(static_cast<jsize>(size));
        env->SetByteArrayRegion(chunk, 0, static_cast<jsize>(size),
            reinterpret_cast<const jbyte*>(buffer));
        env->CallVoidMethod(stream, write, chunk, 0, static_cast<jint>(size));
        env->DeleteLocalRef(chunk);
        if (java_exception(env, error, "FileOutputStream.write")) {
            env->CallVoidMethod(stream, close);
            env->DeleteLocalRef(stream);
            env->DeleteLocalRef(file);
            env->DeleteLocalRef(jpath);
            env->DeleteLocalRef(file_class);
            env->DeleteLocalRef(stream_class);
            return false;
        }
    }
    env->CallVoidMethod(stream, close);
    java_exception(env, error, "FileOutputStream.close");
    const bool exists = java_file_exists(env, dest_utf8);
    env->DeleteLocalRef(stream);
    env->DeleteLocalRef(file);
    env->DeleteLocalRef(jpath);
    env->DeleteLocalRef(file_class);
    env->DeleteLocalRef(stream_class);
    if (!exists) {
        *error = "Java wrote path but exists() is false: " + dest_utf8;
        return false;
    }
    return true;
}

std::string java_bytes_to_utf8(const char* bytes, std::size_t size, const char* charset) {
    if (!bytes || size == 0) return {};
    JavaVM* vm = java_vm();
    if (!vm) return {};
    JNIEnv* env = nullptr;
    bool detach = false;
    jint status = vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
    if (status == JNI_EDETACHED) {
        if (vm->AttachCurrentThread(&env, nullptr) != JNI_OK) return {};
        detach = true;
    } else if (status != JNI_OK) {
        return {};
    }
    std::string result;
    jclass string_class = env->FindClass("java/lang/String");
    if (string_class) {
        jmethodID ctor = env->GetMethodID(string_class, "<init>", "([BLjava/lang/String;)V");
        if (ctor) {
            jbyteArray array = env->NewByteArray(static_cast<jsize>(size));
            jstring charset_name = env->NewStringUTF(charset);
            if (array && charset_name) {
                env->SetByteArrayRegion(array, 0, static_cast<jsize>(size),
                    reinterpret_cast<const jbyte*>(bytes));
                jstring decoded = static_cast<jstring>(env->NewObject(string_class, ctor, array, charset_name));
                if (decoded && !env->ExceptionCheck()) {
                    const char* utf = env->GetStringUTFChars(decoded, nullptr);
                    if (utf) {
                        result = utf;
                        env->ReleaseStringUTFChars(decoded, utf);
                    }
                }
                if (decoded) env->DeleteLocalRef(decoded);
            }
            if (array) env->DeleteLocalRef(array);
            if (charset_name) env->DeleteLocalRef(charset_name);
        }
        env->DeleteLocalRef(string_class);
    }
    if (env->ExceptionCheck()) env->ExceptionClear();
    if (detach) vm->DetachCurrentThread();
    return result;
}

std::string hex_preview(std::string_view text, std::size_t max_bytes) {
    std::string out;
    const std::size_t n = std::min(text.size(), max_bytes);
    out.reserve(n * 3);
    static const char* kDigits = "0123456789ABCDEF";
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = static_cast<unsigned char>(text[i]);
        out.push_back(kDigits[value >> 4]);
        out.push_back(kDigits[value & 0x0F]);
        if (i + 1 < n) out.push_back(' ');
    }
    if (text.size() > max_bytes) out += "...";
    return out;
}

std::filesystem::path path_from_utf8(const std::string& utf8) {
    return std::filesystem::path(std::u8string(reinterpret_cast<const char8_t*>(utf8.data()), utf8.size()));
}

bool write_bytes_to_utf8_path(const std::string& dest_utf8, struct archive* reader, std::string* error) {
    JniAttach jni;
    if (jni.env) {
        if (java_write_archive_entry(jni.env, dest_utf8, reader, error)) return true;
        log_info("java write failed for " + dest_utf8 + " err=" + (error ? *error : ""));
    }
    const auto parent = path_from_utf8(dest_utf8).parent_path();
    std::error_code fs_error;
    if (!parent.empty()) {
        std::filesystem::create_directories(parent, fs_error);
        if (fs_error) {
            *error = "Failed to create parent directory: " + fs_error.message();
            return false;
        }
    }
    FILE* output = fopen(dest_utf8.c_str(), "wb");
    if (!output) {
        *error = "Failed to create file: " + dest_utf8;
        return false;
    }
    const void* buffer = nullptr;
    size_t size = 0;
    la_int64_t offset = 0;
    while (true) {
        const int read_status = archive_read_data_block(reader, &buffer, &size, &offset);
        if (read_status == ARCHIVE_EOF) break;
        if (read_status != ARCHIVE_OK && read_status != ARCHIVE_WARN) {
            fclose(output);
            *error = std::string("Failed to read archive payload: ") + archive_error_string(reader);
            return false;
        }
        if (size > 0 && fwrite(buffer, 1, size, output) != size) {
            fclose(output);
            *error = "Failed to write file: " + dest_utf8;
            return false;
        }
    }
    if (fclose(output) != 0) {
        *error = "Failed to close file: " + dest_utf8;
        return false;
    }
    return true;
}

std::string normalize_entry_slashes(std::string raw) {
    for (char& ch : raw) {
        if (ch == '\\') ch = '/';
    }
    while (!raw.empty() && raw.front() == '/') raw.erase(raw.begin());
    return raw;
}

std::string decode_raw_name(std::string raw) {
    raw = normalize_entry_slashes(std::move(raw));
    if (raw.empty() || looks_like_utf8(raw)) return raw;
    std::string sjis = java_bytes_to_utf8(raw.data(), raw.size(), "Shift_JIS");
    if (!sjis.empty() && looks_like_utf8(sjis)) return sjis;
    std::string gbk = java_bytes_to_utf8(raw.data(), raw.size(), "GBK");
    if (!gbk.empty()) return gbk;
    std::string gb18030 = java_bytes_to_utf8(raw.data(), raw.size(), "GB18030");
    if (!gb18030.empty()) return gb18030;
    return raw;
}

std::string entry_utf8_name(struct archive_entry* entry) {
    const char* raw = archive_entry_pathname(entry);
    if (raw && raw[0] && looks_like_utf8(raw)) return normalize_entry_slashes(raw);
    const char* utf8 = archive_entry_pathname_utf8(entry);
    if (utf8 && utf8[0] && looks_like_utf8(utf8)) return normalize_entry_slashes(utf8);
    const wchar_t* wide = archive_entry_pathname_w(entry);
    if (wide && wide[0]) {
        std::string converted;
        for (const wchar_t* cursor = wide; *cursor; ++cursor) {
            const auto code = static_cast<std::uint32_t>(*cursor);
            if (code < 0x80) converted.push_back(static_cast<char>(code));
            else if (code < 0x800) {
                converted.push_back(static_cast<char>(0xC0 | (code >> 6)));
                converted.push_back(static_cast<char>(0x80 | (code & 0x3F)));
            } else if (code < 0x10000) {
                converted.push_back(static_cast<char>(0xE0 | (code >> 12)));
                converted.push_back(static_cast<char>(0x80 | ((code >> 6) & 0x3F)));
                converted.push_back(static_cast<char>(0x80 | (code & 0x3F)));
            } else {
                converted.push_back(static_cast<char>(0xF0 | (code >> 18)));
                converted.push_back(static_cast<char>(0x80 | ((code >> 12) & 0x3F)));
                converted.push_back(static_cast<char>(0x80 | ((code >> 6) & 0x3F)));
                converted.push_back(static_cast<char>(0x80 | (code & 0x3F)));
            }
        }
        if (looks_like_utf8(converted)) return normalize_entry_slashes(converted);
    }
    return decode_raw_name(raw ? raw : "");
}

bool read_file_u16(FILE* file, std::uint16_t* value) {
    unsigned char bytes[2];
    if (fread(bytes, 1, 2, file) != 2) return false;
    *value = static_cast<std::uint16_t>(bytes[0] | (bytes[1] << 8));
    return true;
}

bool read_file_u32(FILE* file, std::uint32_t* value) {
    unsigned char bytes[4];
    if (fread(bytes, 1, 4, file) != 4) return false;
    *value = static_cast<std::uint32_t>(bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24));
    return true;
}

std::string zip_name_from_extra(const std::vector<std::uint8_t>& extra) {
    std::size_t offset = 0;
    while (offset + 4 <= extra.size()) {
        const std::uint16_t id = static_cast<std::uint16_t>(extra[offset] | (extra[offset + 1] << 8));
        const std::uint16_t size = static_cast<std::uint16_t>(extra[offset + 2] | (extra[offset + 3] << 8));
        offset += 4;
        if (offset + size > extra.size()) break;
        if (id == 0x7075 && size >= 5) {
            std::string utf8(reinterpret_cast<const char*>(extra.data() + offset + 5), size - 5);
            if (!utf8.empty()) return normalize_entry_slashes(utf8);
        }
        offset += size;
    }
    return {};
}

std::string decode_zip_filename_bytes(const std::string& raw, std::uint16_t flags, const std::vector<std::uint8_t>& extra) {
    const std::string unicode = zip_name_from_extra(extra);
    if (!unicode.empty()) return unicode;
    if ((flags & 0x0800) != 0 || looks_like_utf8(raw)) return normalize_entry_slashes(raw);
    return decode_raw_name(raw);
}

std::string zip_local_header_name(const std::string& archive_path, la_int64_t offset) {
    FILE* file = fopen(archive_path.c_str(), "rb");
    if (!file || offset < 0) {
        if (file) fclose(file);
        return {};
    }
    if (fseeko(file, static_cast<off_t>(offset), SEEK_SET) != 0) {
        fclose(file);
        return {};
    }
    std::uint32_t signature = 0;
    std::uint16_t flags = 0;
    std::uint16_t name_len = 0;
    std::uint16_t extra_len = 0;
    if (!read_file_u32(file, &signature) || signature != 0x04034b50u) {
        fclose(file);
        return {};
    }
    if (fseeko(file, 2, SEEK_CUR) != 0 || !read_file_u16(file, &flags)) {
        fclose(file);
        return {};
    }
    if (fseeko(file, 18, SEEK_CUR) != 0
        || !read_file_u16(file, &name_len)
        || !read_file_u16(file, &extra_len)) {
        fclose(file);
        return {};
    }
    std::string name(name_len, '\0');
    if (name_len && fread(name.data(), 1, name_len, file) != name_len) {
        fclose(file);
        return {};
    }
    std::vector<std::uint8_t> extra(extra_len);
    if (extra_len && fread(extra.data(), 1, extra_len, file) != extra_len) {
        fclose(file);
        return {};
    }
    fclose(file);
    return decode_zip_filename_bytes(name, flags, extra);
}

std::unordered_map<std::uint32_t, std::string> zip_central_names(const std::string& archive_path) {
    std::unordered_map<std::uint32_t, std::string> names;
    FILE* file = fopen(archive_path.c_str(), "rb");
    if (!file) return names;
    if (fseeko(file, 0, SEEK_END) != 0) {
        fclose(file);
        return names;
    }
    const off_t file_size = ftello(file);
    if (file_size < 22) {
        fclose(file);
        return names;
    }
    const off_t max_back = file_size > 65557 ? 65557 : file_size;
    std::vector<unsigned char> tail(static_cast<std::size_t>(max_back));
    if (fseeko(file, file_size - max_back, SEEK_SET) != 0
        || fread(tail.data(), 1, tail.size(), file) != tail.size()) {
        fclose(file);
        return names;
    }
    off_t eocd = -1;
    for (off_t i = static_cast<off_t>(tail.size()) - 22; i >= 0; --i) {
        if (tail[static_cast<std::size_t>(i)] == 0x50 && tail[static_cast<std::size_t>(i) + 1] == 0x4B
            && tail[static_cast<std::size_t>(i) + 2] == 0x05 && tail[static_cast<std::size_t>(i) + 3] == 0x06) {
            eocd = i;
            break;
        }
    }
    if (eocd < 0) {
        fclose(file);
        return names;
    }
    const std::size_t base = static_cast<std::size_t>(eocd);
    const std::uint32_t cd_size = static_cast<std::uint32_t>(
        tail[base + 12] | (tail[base + 13] << 8) | (tail[base + 14] << 16) | (tail[base + 15] << 24));
    const std::uint32_t cd_offset = static_cast<std::uint32_t>(
        tail[base + 16] | (tail[base + 17] << 8) | (tail[base + 18] << 16) | (tail[base + 19] << 24));
    if (fseeko(file, static_cast<off_t>(cd_offset), SEEK_SET) != 0) {
        fclose(file);
        return names;
    }
    std::vector<unsigned char> central(cd_size);
    if (cd_size == 0 || fread(central.data(), 1, central.size(), file) != central.size()) {
        fclose(file);
        return names;
    }
    fclose(file);
    std::size_t cursor = 0;
    while (cursor + 46 <= central.size()) {
        const std::uint32_t signature = static_cast<std::uint32_t>(
            central[cursor] | (central[cursor + 1] << 8) | (central[cursor + 2] << 16) | (central[cursor + 3] << 24));
        if (signature != 0x02014b50u) break;
        const std::uint16_t flags = static_cast<std::uint16_t>(central[cursor + 8] | (central[cursor + 9] << 8));
        const std::uint16_t name_len = static_cast<std::uint16_t>(central[cursor + 28] | (central[cursor + 29] << 8));
        const std::uint16_t extra_len = static_cast<std::uint16_t>(central[cursor + 30] | (central[cursor + 31] << 8));
        const std::uint16_t comment_len = static_cast<std::uint16_t>(central[cursor + 32] | (central[cursor + 33] << 8));
        const std::uint32_t local_offset = static_cast<std::uint32_t>(
            central[cursor + 42] | (central[cursor + 43] << 8) | (central[cursor + 44] << 16) | (central[cursor + 45] << 24));
        if (cursor + 46 + name_len + extra_len + comment_len > central.size()) break;
        std::string name(reinterpret_cast<const char*>(central.data() + cursor + 46), name_len);
        std::vector<std::uint8_t> extra(central.begin() + cursor + 46 + name_len,
            central.begin() + cursor + 46 + name_len + extra_len);
        names[local_offset] = decode_zip_filename_bytes(name, flags, extra);
        cursor += 46u + name_len + extra_len + comment_len;
    }
    return names;
}

bool is_safe_relative_name(std::string_view name) {
    if (name.empty() || name[0] == '/' || name[0] == '\\') return false;
    if (name.find(':') != std::string_view::npos) return false;
    std::filesystem::path relative{std::string(name)};
    const auto normalized = relative.lexically_normal().generic_string();
    return normalized.find("..") == std::string::npos;
}

std::string normalize_kind_name(struct archive* reader) {
    const char* format = archive_format_name(reader);
    std::string format_name = format ? format : "";
    std::string filter;
    const int filters = archive_filter_count(reader);
    for (int i = 0; i < filters; ++i) {
        const char* name = archive_filter_name(reader, i);
        if (!name || std::strcmp(name, "none") == 0) continue;
        if (!filter.empty()) filter.push_back('+');
        filter += name;
    }
    auto contains = [](const std::string& hay, const char* needle) {
        return hay.find(needle) != std::string::npos;
    };
    if (contains(format_name, "ZIP") || contains(format_name, "Zip")) return "zip";
    if (contains(format_name, "RAR") || contains(format_name, "Rar")) return "rar";
    if (contains(format_name, "7-Zip") || contains(format_name, "7zip") || contains(format_name, "7z")) return "7z";
    if (contains(format_name, "cpio")) return "cpio";
    if (contains(format_name, "ISO")) return "iso";
    const bool tar = contains(format_name, "tar") || contains(format_name, "TAR")
        || contains(format_name, "pax") || contains(format_name, "ustar")
        || contains(format_name, "gnutar");
    if (tar && (contains(filter, "gzip") || contains(filter, "gzip"))) return "tar.gz";
    if (tar && contains(filter, "xz")) return "tar.xz";
    if (tar && (contains(filter, "bzip2") || contains(filter, "bz2"))) return "tar.bz2";
    if (tar && contains(filter, "zstd")) return "tar.zst";
    if (tar) return "tar";
    if (contains(filter, "gzip")) return "gzip";
    if (contains(filter, "xz")) return "xz";
    if (contains(filter, "bzip2")) return "bzip2";
    if (!format_name.empty()) return format_name;
    return "unknown";
}

std::string detect_archive(const std::filesystem::path& archive) {
    const std::string magic = detect_archive_kind_from_path(archive.string());
    struct archive* reader = archive_read_new();
    if (!reader) return magic;
    archive_read_support_filter_all(reader);
    archive_read_support_format_all(reader);
    const int opened = archive_read_open_filename(reader, archive.string().c_str(), 10240);
    std::string kind = magic;
    if (opened == ARCHIVE_OK || opened == ARCHIVE_WARN) {
        struct archive_entry* entry = nullptr;
        archive_read_next_header(reader, &entry);
        kind = normalize_kind_name(reader);
        if (kind.empty() || kind == "unknown") kind = magic;
    }
    archive_read_free(reader);
    log_info("detect " + archive.string() + " -> " + kind + " (magic=" + magic + ")");
    return kind.empty() ? "unknown" : kind;
}

bool collect_files(const std::filesystem::path& source, bool include_root,
    std::vector<std::pair<std::string, std::filesystem::path>>* files, std::string* error) {
    std::error_code fs_error;
    if (std::filesystem::is_regular_file(source, fs_error)) {
        files->push_back({source.filename().generic_string(), source});
        return true;
    }
    if (!std::filesystem::is_directory(source, fs_error)) {
        *error = "Source path does not exist.";
        return false;
    }
    const auto root = include_root ? source.parent_path() : source;
    for (const auto& entry : std::filesystem::recursive_directory_iterator(source, fs_error)) {
        if (fs_error) {
            *error = fs_error.message();
            return false;
        }
        if (!entry.is_regular_file()) continue;
        auto relative = std::filesystem::relative(entry.path(), root, fs_error).generic_string();
        if (fs_error || relative.empty()) {
            *error = "Failed to compute archive entry name.";
            return false;
        }
        files->push_back({relative, entry.path()});
    }
    return true;
}

bool extract_archive(const std::filesystem::path& archive, const std::filesystem::path& output,
    bool overwrite, const std::string& password, const std::shared_ptr<ZipTask>& task) {
    struct archive* reader = archive_read_new();
    if (!reader) {
        task->error = "Failed to allocate libarchive reader.";
        return false;
    }
    archive_read_support_filter_all(reader);
    archive_read_support_format_all(reader);
    archive_read_set_format_option(reader, "zip", "hdrcharset", "UTF-8");
    archive_read_set_options(reader, "hdrcharset=UTF-8");
    if (!password.empty()) archive_read_add_passphrase(reader, password.c_str());
    setlocale(LC_ALL, "C.UTF-8");
    setlocale(LC_CTYPE, "C.UTF-8");

    const auto real_output = resolve_real_path(output);
    std::string output_utf8 = real_output.generic_string();
    if (output_utf8.empty() || output_utf8.back() != '/') output_utf8.push_back('/');
    log_info("extract dest=" + output_utf8);
    log_info(std::string("java_vm=") + (java_vm() ? "ok" : "missing"));
    const std::string extract_log_path = output_utf8 + "_extract_log.txt";
    FILE* extract_log = fopen(extract_log_path.c_str(), "wb");
    auto log_line = [&](const std::string& line) {
        log_info(line);
        if (extract_log) {
            fwrite(line.data(), 1, line.size(), extract_log);
            fputc('\n', extract_log);
            fflush(extract_log);
        }
    };

    int status = archive_read_open_filename(reader, archive.string().c_str(), 10240);
    if (status != ARCHIVE_OK && status != ARCHIVE_WARN) {
        task->error = std::string("Failed to open archive: ") + archive_error_string(reader);
        if (extract_log) fclose(extract_log);
        archive_read_free(reader);
        return false;
    }
    log_line("extract kind=" + normalize_kind_name(reader) + " path=" + archive.string());
    const auto central_names = zip_central_names(archive.string());
    log_line("zip central names=" + std::to_string(central_names.size()));

    int written = 0;
    int skipped = 0;
    int utf8_names = 0;
    int unnamed = 0;
    struct archive_entry* entry = nullptr;
    while (true) {
        if (task->cancel_requested.load()) {
            task->error = "Archive extraction was cancelled.";
            if (extract_log) fclose(extract_log);
            archive_read_free(reader);
            return false;
        }
        status = archive_read_next_header(reader, &entry);
        if (status == ARCHIVE_EOF) break;
        if (status == ARCHIVE_RETRY) continue;
        if (status != ARCHIVE_OK && status != ARCHIVE_WARN) {
            task->error = std::string("Failed to read archive header: ") + archive_error_string(reader);
            if (extract_log) fclose(extract_log);
            archive_read_free(reader);
            return false;
        }

        const char* raw_utf8 = archive_entry_pathname_utf8(entry);
        const char* raw_path = archive_entry_pathname(entry);
        std::string name = entry_utf8_name(entry);
        const la_int64_t header_pos = archive_read_header_position(reader);
        if (name.empty()) {
            name = zip_local_header_name(archive.string(), header_pos);
            if (name.empty()) {
                const auto found = central_names.find(static_cast<std::uint32_t>(header_pos));
                if (found != central_names.end()) name = found->second;
            }
            if (!name.empty()) log_line("recovered name=" + name + " hex=" + hex_preview(name)
                + " pos=" + std::to_string(static_cast<long long>(header_pos)));
        }
        const bool non_ascii = !name.empty() && !std::all_of(name.begin(), name.end(), [](unsigned char ch) {
            return ch < 0x80;
        });
        if (non_ascii) ++utf8_names;
        log_line(std::string("entry name=") + name
            + " utf8=" + (raw_utf8 ? raw_utf8 : "")
            + " raw=" + (raw_path ? raw_path : "")
            + " hex=" + hex_preview(name)
            + " pos=" + std::to_string(static_cast<long long>(header_pos))
            + " type=" + std::to_string(static_cast<int>(archive_entry_filetype(entry)))
            + " size=" + std::to_string(static_cast<long long>(archive_entry_size(entry))));

        if (name.empty()) {
            ++unnamed;
            name = "_unnamed_" + std::to_string(unnamed);
            log_line("empty name fallback=" + name
                + " size=" + std::to_string(static_cast<long long>(archive_entry_size(entry))));
        }
        if (!is_safe_relative_name(name)) {
            task->error = "Refusing unsafe archive entry path: " + name;
            if (extract_log) fclose(extract_log);
            archive_read_free(reader);
            return false;
        }

        const auto file_type = archive_entry_filetype(entry);
        const bool is_dir = file_type == AE_IFDIR || name.back() == '/';
        const std::string dest_utf8 = output_utf8 + name;
        if (is_dir) {
            JniAttach jni;
            bool made = false;
            if (jni.env) made = java_mkdirs(jni.env, dest_utf8, &task->error);
            if (!made) {
                std::error_code fs_error;
                std::filesystem::create_directories(path_from_utf8(dest_utf8), fs_error);
                made = !fs_error;
                if (fs_error) task->error = "Failed to create directory: " + dest_utf8 + " " + fs_error.message();
            }
            if (!made) {
                if (extract_log) fclose(extract_log);
                archive_read_free(reader);
                return false;
            }
            ++written;
            log_info("mkdir " + dest_utf8);
            continue;
        }
        if (file_type == AE_IFLNK) {
            ++skipped;
            archive_read_data_skip(reader);
            log_info("skip symlink " + name);
            continue;
        }
        if (!overwrite) {
            std::error_code exists_error;
            if (std::filesystem::exists(path_from_utf8(dest_utf8), exists_error)) {
                ++skipped;
                archive_read_data_skip(reader);
                continue;
            }
        }
        if (non_ascii && java_vm() == nullptr) {
            task->error = "JavaVM is missing; cannot write UTF-8 filename: " + name;
            if (extract_log) fclose(extract_log);
            archive_read_free(reader);
            return false;
        }
        if (!write_bytes_to_utf8_path(dest_utf8, reader, &task->error)) {
            if (extract_log) fclose(extract_log);
            archive_read_free(reader);
            return false;
        }
        ++written;
        log_line("wrote " + dest_utf8);
    }
    archive_read_free(reader);
    log_line("extract done written=" + std::to_string(written)
        + " skipped=" + std::to_string(skipped)
        + " utf8_names=" + std::to_string(utf8_names)
        + " unnamed=" + std::to_string(unnamed));
    if (extract_log) fclose(extract_log);
    {
        JniAttach jni;
        if (jni.env) java_list_dir(jni.env, output_utf8);
        else log_info("java_list_dir skipped, JavaVM missing");
    }
    return true;
}

std::string canonical_write_format(std::string format) {
    for (char& ch : format) {
        if (ch >= 'A' && ch <= 'Z') ch = static_cast<char>(ch - 'A' + 'a');
    }
    if (format.empty() || format == "zip" || format == ".zip") return "zip";
    if (format == "7z" || format == ".7z" || format == "7zip") return "7z";
    if (format == "tar" || format == ".tar") return "tar";
    if (format == "tar.gz" || format == "tgz" || format == ".tar.gz" || format == ".tgz" || format == "gzip") {
        return "tar.gz";
    }
    if (format == "tar.xz" || format == "txz" || format == ".tar.xz") return "tar.xz";
    if (format == "rar" || format == ".rar") return "rar";
    return format;
}

bool compress_archive(const std::filesystem::path& source, const std::filesystem::path& archive_path,
    bool include_root, bool overwrite, const std::string& password, const std::string& format_name,
    const std::shared_ptr<ZipTask>& task) {
    const std::string format = canonical_write_format(format_name);
    if (format == "rar") {
        task->error = "RAR compression is not supported; extract-only.";
        return false;
    }
    if (!password.empty() && (format == "tar" || format == "tar.gz" || format == "tar.xz")) {
        task->error = "Password is not supported for tar/gzip/xz output.";
        return false;
    }

    std::error_code fs_error;
    if (std::filesystem::exists(archive_path, fs_error)) {
        if (!overwrite) {
            task->error = "Archive already exists.";
            return false;
        }
        std::filesystem::remove(archive_path, fs_error);
        if (fs_error) {
            task->error = "Failed to replace existing archive: " + fs_error.message();
            return false;
        }
    }
    if (!archive_path.parent_path().empty()) {
        std::filesystem::create_directories(archive_path.parent_path(), fs_error);
        if (fs_error) {
            task->error = "Failed to create archive directory: " + fs_error.message();
            return false;
        }
    }

    std::vector<std::pair<std::string, std::filesystem::path>> files;
    if (!collect_files(source, include_root, &files, &task->error)) return false;

    struct archive* writer = archive_write_new();
    if (!writer) {
        task->error = "Failed to allocate libarchive writer.";
        return false;
    }
    if (format == "7z") {
        archive_write_set_format_7zip(writer);
    } else if (format == "tar") {
        archive_write_set_format_pax_restricted(writer);
    } else if (format == "tar.gz") {
        archive_write_set_format_pax_restricted(writer);
        archive_write_add_filter_gzip(writer);
    } else if (format == "tar.xz") {
        archive_write_set_format_pax_restricted(writer);
        archive_write_add_filter_xz(writer);
    } else {
        archive_write_set_format_zip(writer);
        archive_write_set_format_option(writer, "zip", "hdrcharset", "UTF-8");
        if (!password.empty()) {
            if (archive_write_set_format_option(writer, "zip", "encryption", "aes256") != ARCHIVE_OK) {
                archive_write_set_format_option(writer, "zip", "encryption", "traditional");
            }
        }
    }
    if (!password.empty()) archive_write_set_passphrase(writer, password.c_str());
    if (archive_write_open_filename(writer, archive_path.string().c_str()) != ARCHIVE_OK) {
        task->error = std::string("Failed to create archive: ") + archive_error_string(writer);
        archive_write_free(writer);
        return false;
    }

    std::vector<char> buffer(64 * 1024);
    for (const auto& [name, path] : files) {
        if (task->cancel_requested.load()) {
            task->error = "Archive compression was cancelled.";
            archive_write_free(writer);
            return false;
        }
        struct archive_entry* entry = archive_entry_new();
        archive_entry_set_pathname_utf8(entry, name.c_str());
        archive_entry_set_filetype(entry, AE_IFREG);
        archive_entry_set_perm(entry, 0644);
        std::error_code size_error;
        const auto file_size = std::filesystem::file_size(path, size_error);
        if (!size_error) archive_entry_set_size(entry, static_cast<la_int64_t>(file_size));
        if (archive_write_header(writer, entry) != ARCHIVE_OK) {
            task->error = std::string("Failed to write header for ") + name + ": " + archive_error_string(writer);
            archive_entry_free(entry);
            archive_write_free(writer);
            return false;
        }
        std::ifstream input(path, std::ios::binary);
        if (!input) {
            task->error = "Failed to read " + path.string();
            archive_entry_free(entry);
            archive_write_free(writer);
            return false;
        }
        while (input) {
            input.read(buffer.data(), static_cast<std::streamsize>(buffer.size()));
            const auto read = input.gcount();
            if (read > 0 && archive_write_data(writer, buffer.data(), static_cast<size_t>(read)) < 0) {
                task->error = std::string("Failed to write ") + name + ": " + archive_error_string(writer);
                archive_entry_free(entry);
                archive_write_free(writer);
                return false;
            }
        }
        archive_entry_free(entry);
    }
    if (archive_write_close(writer) != ARCHIVE_OK) {
        task->error = std::string("Failed to finalize archive: ") + archive_error_string(writer);
        archive_write_free(writer);
        return false;
    }
    archive_write_free(writer);
    return true;
}

bool prepare_extract(const std::filesystem::path& archive, const std::filesystem::path& output,
    bool overwrite, bool clean_output, const std::string& password, const std::shared_ptr<ZipTask>& task) {
    std::error_code error;
    if (!std::filesystem::is_regular_file(archive, error)) {
        task->error = "Archive does not exist: " + archive.string();
        return false;
    }
    const auto archive_size = std::filesystem::file_size(archive, error);
    if (error) {
        task->error = "Failed to inspect archive size: " + error.message();
        return false;
    }
    if (archive_size > kMaxArchiveBytes) {
        task->error = "Archive size exceeds the 1 GiB limit.";
        return false;
    }
    if (clean_output) {
        if (is_dangerous_clean_path(output)) {
            task->error = "Refusing to clean a filesystem root directory.";
            return false;
        }
        std::filesystem::remove_all(output, error);
        if (error) {
            task->error = "Failed to clean output directory: " + error.message();
            return false;
        }
    }
    std::filesystem::create_directories(output, error);
    if (error) {
        task->error = "Failed to create output directory: " + error.message();
        return false;
    }
    const auto real_output = resolve_real_path(output);
    log_info("extract archive=" + archive.string() + " output=" + real_output.generic_string()
        + " requested=" + output.generic_string());
    return extract_archive(archive, real_output, overwrite, password, task);
}

template <typename Work>
int32_t start_task(Work work) {
    if (g_shutting_down.load()) {
        set_last_error("I_Compression is shutting down.");
        return -1;
    }
    int32_t task_id = g_next_task_id.fetch_add(1);
    if (task_id <= 0) {
        g_next_task_id.store(2);
        task_id = 1;
    }
    auto task = std::make_shared<ZipTask>();
    {
        std::lock_guard lock(g_tasks_mutex);
        g_tasks[task_id] = task;
    }
    task->worker = std::thread([task, work = std::move(work)]() mutable {
        task->status.store(TaskRunning);
        bool succeeded = false;
        try {
            succeeded = work(task);
        } catch (const std::exception& exception) {
            task->error = exception.what();
        } catch (...) {
            task->error = "Unknown native archive error.";
        }
        if (task->cancel_requested.load()) task->status.store(TaskCancelled);
        else task->status.store(succeeded ? TaskSucceeded : TaskFailed);
        task->exit_code.store(succeeded ? 0 : 1);
    });
    return task_id;
}

bool run_now(const std::function<bool(const std::shared_ptr<ZipTask>&)>& work) {
    auto task = std::make_shared<ZipTask>();
    bool succeeded = false;
    try {
        succeeded = work(task);
    } catch (const std::exception& exception) {
        task->error = exception.what();
    } catch (...) {
        task->error = "Unknown native archive error.";
    }
    if (!succeeded) set_last_error(task->error);
    else set_last_error({});
    return succeeded;
}

} // namespace

void unicode_zip_initialize() {
    g_shutting_down.store(false);
    setlocale(LC_ALL, "C.UTF-8");
    setlocale(LC_CTYPE, "C.UTF-8");
    set_last_error({});
    log_info(std::string("initialize java_vm=") + (java_vm() ? "ok" : "missing"));
}

bool unicode_zip_available() {
    return true;
}

std::string unicode_zip_detect(std::string_view archive_path) {
    if (archive_path.empty()) {
        set_last_error("Archive path must be a valid UTF-8 string.");
        return "unknown";
    }
    const std::filesystem::path archive = std::filesystem::path(std::string(archive_path)).lexically_normal();
    std::error_code error;
    if (!std::filesystem::is_regular_file(archive, error)) {
        set_last_error("Archive does not exist: " + archive.string());
        return "unknown";
    }
    set_last_error({});
    return detect_archive(archive);
}

bool unicode_zip_extract(std::string_view archive_path, std::string_view output_directory,
    bool overwrite, bool clean_output) {
    return unicode_zip_extract_password(archive_path, output_directory, overwrite, clean_output, {});
}

bool unicode_zip_extract_password(std::string_view archive_path, std::string_view output_directory,
    bool overwrite, bool clean_output, std::string_view password) {
    if (archive_path.empty() || output_directory.empty()) {
        set_last_error("Archive and output paths must be valid UTF-8 strings.");
        return false;
    }
    const std::filesystem::path archive = std::filesystem::path(std::string(archive_path)).lexically_normal();
    const std::filesystem::path output = std::filesystem::path(std::string(output_directory)).lexically_normal();
    const std::string pass(password);
    return run_now([archive, output, overwrite, clean_output, pass](const std::shared_ptr<ZipTask>& task) {
        return prepare_extract(archive, output, overwrite, clean_output, pass, task);
    });
}

bool unicode_zip_compress(std::string_view source_path, std::string_view archive_path,
    bool include_root, bool overwrite) {
    return unicode_zip_compress_password(source_path, archive_path, include_root, overwrite, {});
}

bool unicode_zip_compress_password(std::string_view source_path, std::string_view archive_path,
    bool include_root, bool overwrite, std::string_view password) {
    return unicode_zip_compress_format(source_path, archive_path, include_root, overwrite, password, "zip");
}

bool unicode_zip_compress_format(std::string_view source_path, std::string_view archive_path,
    bool include_root, bool overwrite, std::string_view password, std::string_view format) {
    if (source_path.empty() || archive_path.empty()) {
        set_last_error("Source and archive paths must be valid UTF-8 strings.");
        return false;
    }
    const std::filesystem::path source = std::filesystem::path(std::string(source_path)).lexically_normal();
    const std::filesystem::path archive = std::filesystem::path(std::string(archive_path)).lexically_normal();
    const std::string pass(password);
    const std::string kind(format);
    return run_now([source, archive, include_root, overwrite, pass, kind](const std::shared_ptr<ZipTask>& task) {
        return compress_archive(source, archive, include_root, overwrite, pass, kind, task);
    });
}

int32_t unicode_zip_extract_async(std::string_view archive_path, std::string_view output_directory,
    bool overwrite, bool clean_output) {
    return unicode_zip_extract_async_password(archive_path, output_directory, overwrite, clean_output, {});
}

int32_t unicode_zip_extract_async_password(std::string_view archive_path, std::string_view output_directory,
    bool overwrite, bool clean_output, std::string_view password) {
    if (archive_path.empty() || output_directory.empty()) {
        set_last_error("Archive and output paths must be valid UTF-8 strings.");
        return -1;
    }
    const std::filesystem::path archive = std::filesystem::path(std::string(archive_path)).lexically_normal();
    const std::filesystem::path output = std::filesystem::path(std::string(output_directory)).lexically_normal();
    const std::string pass(password);
    return start_task([archive, output, overwrite, clean_output, pass](const std::shared_ptr<ZipTask>& task) {
        return prepare_extract(archive, output, overwrite, clean_output, pass, task);
    });
}

int32_t unicode_zip_compress_async(std::string_view source_path, std::string_view archive_path,
    bool include_root, bool overwrite) {
    return unicode_zip_compress_async_password(source_path, archive_path, include_root, overwrite, {});
}

int32_t unicode_zip_compress_async_password(std::string_view source_path, std::string_view archive_path,
    bool include_root, bool overwrite, std::string_view password) {
    return unicode_zip_compress_async_format(source_path, archive_path, include_root, overwrite, password, "zip");
}

int32_t unicode_zip_compress_async_format(std::string_view source_path, std::string_view archive_path,
    bool include_root, bool overwrite, std::string_view password, std::string_view format) {
    if (source_path.empty() || archive_path.empty()) {
        set_last_error("Source and archive paths must be valid UTF-8 strings.");
        return -1;
    }
    const std::filesystem::path source = std::filesystem::path(std::string(source_path)).lexically_normal();
    const std::filesystem::path archive = std::filesystem::path(std::string(archive_path)).lexically_normal();
    const std::string pass(password);
    const std::string kind(format);
    return start_task([source, archive, include_root, overwrite, pass, kind](const std::shared_ptr<ZipTask>& task) {
        return compress_archive(source, archive, include_root, overwrite, pass, kind, task);
    });
}

int32_t unicode_zip_task_status(int32_t task_id) {
    const auto task = find_task(task_id);
    return task ? task->status.load() : TaskUnknown;
}

int32_t unicode_zip_task_exit_code(int32_t task_id) {
    const auto task = find_task(task_id);
    return task ? task->exit_code.load() : -1;
}

std::string unicode_zip_task_error(int32_t task_id) {
    const auto task = find_task(task_id);
    if (!task) return "Unknown archive task.";
    const int32_t status = task->status.load();
    if (status == TaskQueued || status == TaskRunning) return {};
    return task->error;
}

bool unicode_zip_task_cancel(int32_t task_id) {
    const auto task = find_task(task_id);
    if (!task) return false;
    const int32_t status = task->status.load();
    if (status >= TaskSucceeded) return false;
    task->cancel_requested.store(true);
    return true;
}

bool unicode_zip_task_release(int32_t task_id) {
    std::shared_ptr<ZipTask> task;
    {
        std::lock_guard lock(g_tasks_mutex);
        const auto it = g_tasks.find(task_id);
        if (it == g_tasks.end()) return false;
        task = it->second;
        if (task->status.load() == TaskQueued || task->status.load() == TaskRunning) return false;
        g_tasks.erase(it);
    }
    if (task->worker.joinable()) task->worker.join();
    return true;
}

std::string unicode_zip_last_error() {
    std::lock_guard lock(g_error_mutex);
    return g_last_error;
}

void unicode_zip_shutdown() {
    g_shutting_down.store(true);
    std::vector<std::shared_ptr<ZipTask>> tasks;
    {
        std::lock_guard lock(g_tasks_mutex);
        for (const auto& [id, task] : g_tasks) {
            (void)id;
            tasks.push_back(task);
        }
        g_tasks.clear();
    }
    for (const auto& task : tasks) task->cancel_requested.store(true);
    for (const auto& task : tasks) {
        if (task->worker.joinable()) task->worker.join();
    }
}
