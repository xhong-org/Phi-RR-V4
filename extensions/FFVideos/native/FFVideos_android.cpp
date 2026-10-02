#include "native/FFVideosInternal_native.h"

#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <android/log.h>
#include <android/native_window.h>
#include <android/native_window_jni.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <jni.h>
#include <media/NdkMediaCodec.h>
#include <media/NdkMediaError.h>
#include <media/NdkMediaExtractor.h>
#include <media/NdkMediaFormat.h>
#include <sys/stat.h>
#include <unistd.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <cstdint>
#include <cstring>
#include <limits>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <thread>
#include <unordered_map>
#include <vector>

namespace {

constexpr std::int32_t kStatusError = -1;
constexpr std::int32_t kStatusClosed = 0;
constexpr std::int32_t kStatusPreparing = 1;
constexpr std::int32_t kStatusPlaying = 2;
constexpr std::int32_t kStatusPaused = 3;
constexpr std::int32_t kStatusEnded = 4;

constexpr GLenum GL_TEXTURE_EXTERNAL_OES_ENUM = 0x8D65;
constexpr GLenum GL_TEXTURE_BINDING_EXTERNAL_OES_ENUM = 0x8D67;

JavaVM* g_javaVm = nullptr;

extern "C" void FFVideos_StoreJavaVM(JavaVM* vm) {
    if (vm) g_javaVm = vm;
}

JavaVM* javaVm() {
    if (g_javaVm) return g_javaVm;
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
    if (count > 0 && created) g_javaVm = created;
    return g_javaVm;
}

struct JniSession {
    JNIEnv* env = nullptr;
    bool detach = false;

    JniSession() {
        JavaVM* vm = javaVm();
        if (!vm) return;
        jint status = vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
        if (status == JNI_OK) return;
        if (status == JNI_EDETACHED) {
            JavaVMAttachArgs args{};
            args.version = JNI_VERSION_1_6;
            args.name = const_cast<char*>("FFVideos");
            args.group = nullptr;
            if (vm->AttachCurrentThread(&env, &args) == JNI_OK) {
                detach = true;
                return;
            }
        }
        env = nullptr;
    }

    ~JniSession() {
        if (detach) {
            if (JavaVM* vm = javaVm()) vm->DetachCurrentThread();
        }
    }
};

struct JniSurfaceApi {
    jclass surfaceTextureClass = nullptr;
    jclass surfaceClass = nullptr;
    jmethodID surfaceTextureCtor = nullptr;
    jmethodID updateTexImage = nullptr;
    jmethodID getTransformMatrix = nullptr;
    jmethodID setDefaultBufferSize = nullptr;
    jmethodID surfaceTextureRelease = nullptr;
    jmethodID surfaceCtor = nullptr;
    jmethodID surfaceRelease = nullptr;
    bool ready = false;
};

JniSurfaceApi g_jni;
std::mutex g_mutex;
std::string g_globalError;
bool g_ready = false;
GLuint g_program = 0;
GLuint g_vbo = 0;
GLuint g_vao = 0;
EGLContext g_pipelineContext = EGL_NO_CONTEXT;
GLint g_uTexture = -1;
GLint g_uMatrix = -1;
GLint g_uAlpha = -1;
GLint g_uDim = -1;
GLint g_aPosition = 0;
GLint g_aTexCoord = 1;
std::int32_t g_nextHandle = 1;

void setGlobalError(std::string message) {
    std::lock_guard lock(g_mutex);
    g_globalError = std::move(message);
}

bool jniOk(JNIEnv* env, const char* what) {
    if (!env->ExceptionCheck()) return true;
    env->ExceptionDescribe();
    env->ExceptionClear();
    setGlobalError(std::string(what) + " threw a JNI exception.");
    return false;
}

bool ensureJni(JNIEnv* env) {
    if (g_jni.ready) return true;
    jclass st = env->FindClass("android/graphics/SurfaceTexture");
    jclass surface = env->FindClass("android/view/Surface");
    if (!st || !surface) {
        if (env->ExceptionCheck()) {
            env->ExceptionDescribe();
            env->ExceptionClear();
        }
        setGlobalError("SurfaceTexture JNI classes were not found.");
        return false;
    }
    g_jni.surfaceTextureClass = static_cast<jclass>(env->NewGlobalRef(st));
    g_jni.surfaceClass = static_cast<jclass>(env->NewGlobalRef(surface));
    env->DeleteLocalRef(st);
    env->DeleteLocalRef(surface);
    g_jni.surfaceTextureCtor = env->GetMethodID(g_jni.surfaceTextureClass, "<init>", "(I)V");
    g_jni.updateTexImage = env->GetMethodID(g_jni.surfaceTextureClass, "updateTexImage", "()V");
    g_jni.getTransformMatrix = env->GetMethodID(g_jni.surfaceTextureClass, "getTransformMatrix", "([F)V");
    g_jni.setDefaultBufferSize = env->GetMethodID(g_jni.surfaceTextureClass, "setDefaultBufferSize", "(II)V");
    g_jni.surfaceTextureRelease = env->GetMethodID(g_jni.surfaceTextureClass, "release", "()V");
    g_jni.surfaceCtor = env->GetMethodID(g_jni.surfaceClass, "<init>", "(Landroid/graphics/SurfaceTexture;)V");
    g_jni.surfaceRelease = env->GetMethodID(g_jni.surfaceClass, "release", "()V");
    if (!g_jni.surfaceTextureCtor || !g_jni.updateTexImage || !g_jni.getTransformMatrix
        || !g_jni.setDefaultBufferSize || !g_jni.surfaceTextureRelease || !g_jni.surfaceCtor
        || !g_jni.surfaceRelease) {
        setGlobalError("SurfaceTexture JNI methods were not found.");
        return false;
    }
    g_jni.ready = true;
    return true;
}

using BindVertexArrayFn = void (*)(GLuint);
BindVertexArrayFn bindVertexArrayFn() {
    static BindVertexArrayFn fn = reinterpret_cast<BindVertexArrayFn>(
        eglGetProcAddress("glBindVertexArray"));
    if (!fn) {
        fn = reinterpret_cast<BindVertexArrayFn>(
            eglGetProcAddress("glBindVertexArrayOES"));
    }
    return fn;
}

GLuint compileShader(GLenum type, const char* source, std::string* error) {
    const GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, nullptr);
    glCompileShader(shader);
    GLint status = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == GL_TRUE) return shader;
    GLint length = 0;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
    std::string log(static_cast<std::size_t>(std::max(length, 1)), '\0');
    glGetShaderInfoLog(shader, length, nullptr, log.data());
    glDeleteShader(shader);
    *error = log;
    return 0;
}

bool linkVideoProgram(const char* vertexSource, const char* fragmentSource, std::string* error) {
    const GLuint vertex = compileShader(GL_VERTEX_SHADER, vertexSource, error);
    if (!vertex) return false;
    const GLuint fragment = compileShader(GL_FRAGMENT_SHADER, fragmentSource, error);
    if (!fragment) {
        glDeleteShader(vertex);
        return false;
    }
    if (g_program) {
        glDeleteProgram(g_program);
        g_program = 0;
    }
    g_program = glCreateProgram();
    glAttachShader(g_program, vertex);
    glAttachShader(g_program, fragment);
    glBindAttribLocation(g_program, 0, "a_position");
    glBindAttribLocation(g_program, 1, "a_texcoord");
    glLinkProgram(g_program);
    glDeleteShader(vertex);
    glDeleteShader(fragment);
    GLint linked = 0;
    glGetProgramiv(g_program, GL_LINK_STATUS, &linked);
    if (linked == GL_TRUE) return true;
    GLint length = 0;
    glGetProgramiv(g_program, GL_INFO_LOG_LENGTH, &length);
    *error = std::string(static_cast<std::size_t>(std::max(length, 1)), '\0');
    glGetProgramInfoLog(g_program, length, nullptr, error->data());
    glDeleteProgram(g_program);
    g_program = 0;
    return false;
}

bool ensureDrawPipeline() {
    const EGLContext current = eglGetCurrentContext();
    if (current == EGL_NO_CONTEXT) return false;
    if (g_program && g_vbo && current == g_pipelineContext) return true;
    g_program = 0;
    g_vbo = 0;
    g_vao = 0;
    g_pipelineContext = current;

    static constexpr char kVertex100[] = R"GLSL(
#version 100
attribute vec2 a_position;
attribute vec2 a_texcoord;
varying vec2 v_texcoord;
void main() {
    gl_Position = vec4(a_position, 0.0, 1.0);
    v_texcoord = a_texcoord;
}
)GLSL";
    static constexpr char kFragment100[] = R"GLSL(
#version 100
#extension GL_OES_EGL_image_external : require
precision mediump float;
uniform samplerExternalOES u_texture;
uniform mat4 u_stMatrix;
uniform float u_alpha;
uniform float u_dim;
varying vec2 v_texcoord;
void main() {
    vec2 uv = (u_stMatrix * vec4(v_texcoord, 0.0, 1.0)).xy;
    vec4 colour = texture2D(u_texture, uv);
    colour.rgb *= (1.0 - clamp(u_dim, 0.0, 1.0));
    gl_FragColor = vec4(colour.rgb, clamp(u_alpha, 0.0, 1.0));
}
)GLSL";
    static constexpr char kVertex300[] = R"GLSL(
#version 300 es
in vec2 a_position;
in vec2 a_texcoord;
out vec2 v_texcoord;
void main() {
    gl_Position = vec4(a_position, 0.0, 1.0);
    v_texcoord = a_texcoord;
}
)GLSL";
    static constexpr char kFragment300[] = R"GLSL(
#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump float;
uniform samplerExternalOES u_texture;
uniform mat4 u_stMatrix;
uniform float u_alpha;
uniform float u_dim;
in vec2 v_texcoord;
out vec4 fragColor;
void main() {
    vec2 uv = (u_stMatrix * vec4(v_texcoord, 0.0, 1.0)).xy;
    vec4 colour = texture(u_texture, uv);
    colour.rgb *= (1.0 - clamp(u_dim, 0.0, 1.0));
    fragColor = vec4(colour.rgb, clamp(u_alpha, 0.0, 1.0));
}
)GLSL";

    std::string error;
    const char* glVersion = reinterpret_cast<const char*>(glGetString(GL_VERSION));
    const bool gles3 = glVersion != nullptr
        && (std::strstr(glVersion, "OpenGL ES 3") != nullptr
            || std::strstr(glVersion, "OpenGL ES-CM 3") != nullptr);
    const bool linked = gles3
        ? (linkVideoProgram(kVertex300, kFragment300, &error)
            || linkVideoProgram(kVertex100, kFragment100, &error))
        : (linkVideoProgram(kVertex100, kFragment100, &error)
            || linkVideoProgram(kVertex300, kFragment300, &error));
    if (!linked) {
        setGlobalError(std::string("GLES video program compile failed (")
            + (glVersion ? glVersion : "unknown") + "): " + error);
        return false;
    }
    g_uTexture = glGetUniformLocation(g_program, "u_texture");
    g_uMatrix = glGetUniformLocation(g_program, "u_stMatrix");
    g_uAlpha = glGetUniformLocation(g_program, "u_alpha");
    g_uDim = glGetUniformLocation(g_program, "u_dim");
    g_aPosition = glGetAttribLocation(g_program, "a_position");
    g_aTexCoord = glGetAttribLocation(g_program, "a_texcoord");
    if (g_aPosition < 0) g_aPosition = 0;
    if (g_aTexCoord < 0) g_aTexCoord = 1;

    static constexpr float kQuad[] = {
        -1.0f,  1.0f, 0.0f, 0.0f,
         1.0f,  1.0f, 1.0f, 0.0f,
        -1.0f, -1.0f, 0.0f, 1.0f,
        -1.0f, -1.0f, 0.0f, 1.0f,
         1.0f,  1.0f, 1.0f, 0.0f,
         1.0f, -1.0f, 1.0f, 1.0f
    };
    glGenBuffers(1, &g_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, g_vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(kQuad), kQuad, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    using GenVertexArraysFn = void (*)(GLsizei, GLuint*);
    const auto genVao = reinterpret_cast<GenVertexArraysFn>(eglGetProcAddress("glGenVertexArrays"));
    const auto genVaoOes = reinterpret_cast<GenVertexArraysFn>(eglGetProcAddress("glGenVertexArraysOES"));
    if (genVao) genVao(1, &g_vao);
    else if (genVaoOes) genVaoOes(1, &g_vao);
    return true;
}

void destroyDrawPipeline() {
    if (eglGetCurrentContext() != EGL_NO_CONTEXT) {
        if (g_vao) {
            using DeleteVertexArraysFn = void (*)(GLsizei, const GLuint*);
            const auto deleteVao = reinterpret_cast<DeleteVertexArraysFn>(eglGetProcAddress("glDeleteVertexArrays"));
            const auto deleteVaoOes = reinterpret_cast<DeleteVertexArraysFn>(eglGetProcAddress("glDeleteVertexArraysOES"));
            if (deleteVao) deleteVao(1, &g_vao);
            else if (deleteVaoOes) deleteVaoOes(1, &g_vao);
        }
        if (g_vbo) glDeleteBuffers(1, &g_vbo);
        if (g_program) glDeleteProgram(g_program);
    }
    g_vao = 0;
    g_vbo = 0;
    g_program = 0;
    g_pipelineContext = EGL_NO_CONTEXT;
}

int64_t mediaInt64(AMediaFormat* format, const char* key, int64_t fallback = 0) {
    int64_t value = 0;
    return AMediaFormat_getInt64(format, key, &value) ? value : fallback;
}

int32_t mediaInt32(AMediaFormat* format, const char* key, int32_t fallback = 0) {
    int32_t value = 0;
    return AMediaFormat_getInt32(format, key, &value) ? value : fallback;
}

void readVideoSize(AMediaFormat* format, std::int32_t* width, std::int32_t* height) {
    int32_t w = mediaInt32(format, AMEDIAFORMAT_KEY_WIDTH);
    int32_t h = mediaInt32(format, AMEDIAFORMAT_KEY_HEIGHT);
    int32_t cropLeft = 0, cropTop = 0, cropRight = 0, cropBottom = 0;
    const bool cropped = AMediaFormat_getInt32(format, "crop-left", &cropLeft)
        && AMediaFormat_getInt32(format, "crop-top", &cropTop)
        && AMediaFormat_getInt32(format, "crop-right", &cropRight)
        && AMediaFormat_getInt32(format, "crop-bottom", &cropBottom);
    if (cropped) {
        w = std::max(1, cropRight - cropLeft + 1);
        h = std::max(1, cropBottom - cropTop + 1);
    }
    const int32_t rotation = mediaInt32(format, "rotation-degrees");
    if (rotation == 90 || rotation == 270) std::swap(w, h);
    *width = std::max(w, 0);
    *height = std::max(h, 0);
}

void logVideo(int level, const std::string& message) {
    __android_log_print(level, "FFVideos", "%s", message.c_str());
}

std::string mediaStatusName(media_status_t status) {
    switch (status) {
        case AMEDIA_OK: return "OK";
        case AMEDIA_ERROR_UNKNOWN: return "UNKNOWN";
        case AMEDIA_ERROR_MALFORMED: return "MALFORMED";
        case AMEDIA_ERROR_UNSUPPORTED: return "UNSUPPORTED";
        case AMEDIA_ERROR_INVALID_OBJECT: return "INVALID_OBJECT";
        case AMEDIA_ERROR_INVALID_PARAMETER: return "INVALID_PARAMETER";
        case AMEDIA_ERROR_INVALID_OPERATION: return "INVALID_OPERATION";
        default:
            if (static_cast<int>(status) == 1100) return "INSUFFICIENT_RESOURCE";
            if (static_cast<int>(status) == 1101) return "RECLAIMED";
            return "code=" + std::to_string(static_cast<int>(status));
    }
}

void copyFormatBuffer(AMediaFormat* source, AMediaFormat* dest, const char* key) {
    void* data = nullptr;
    size_t size = 0;
    if (source && dest && AMediaFormat_getBuffer(source, key, &data, &size) && data && size > 0) {
        AMediaFormat_setBuffer(dest, key, data, size);
    }
}

AMediaFormat* makeDecoderFormat(AMediaFormat* source, const std::string& mime,
    std::int32_t width, std::int32_t height, bool includeProfile) {
    AMediaFormat* format = AMediaFormat_new();
    if (!format) return nullptr;
    AMediaFormat_setString(format, AMEDIAFORMAT_KEY_MIME, mime.c_str());
    if (width > 0) AMediaFormat_setInt32(format, AMEDIAFORMAT_KEY_WIDTH, width);
    if (height > 0) AMediaFormat_setInt32(format, AMEDIAFORMAT_KEY_HEIGHT, height);
    copyFormatBuffer(source, format, "csd-0");
    copyFormatBuffer(source, format, "csd-1");
    copyFormatBuffer(source, format, "csd-2");
    const int32_t maxInput = mediaInt32(source, AMEDIAFORMAT_KEY_MAX_INPUT_SIZE);
    if (maxInput > 0) {
        AMediaFormat_setInt32(format, AMEDIAFORMAT_KEY_MAX_INPUT_SIZE,
            std::min(maxInput, 8 * 1024 * 1024));
    }
    if (includeProfile && source) {
        const int32_t profile = mediaInt32(source, "profile");
        const int32_t level = mediaInt32(source, "level");
        if (profile) AMediaFormat_setInt32(format, "profile", profile);
        if (level) AMediaFormat_setInt32(format, "level", level);
    }
    return format;
}

std::vector<std::string> softwareDecoderNames(const std::string& mime) {
    if (mime == "video/avc") return { "c2.android.avc.decoder", "OMX.google.h264.decoder" };
    if (mime == "video/hevc") return { "c2.android.hevc.decoder", "OMX.google.hevc.decoder" };
    if (mime == "video/x-vnd.on2.vp9") return { "c2.android.vp9.decoder", "OMX.google.vp9.decoder" };
    if (mime == "video/x-vnd.on2.vp8") return { "c2.android.vp8.decoder", "OMX.google.vp8.decoder" };
    if (mime == "video/av01") return { "c2.android.av1.decoder" };
    if (mime == "video/mp4v-es") return { "c2.android.mpeg4.decoder", "OMX.google.mpeg4.decoder" };
    return {};
}

std::string findSurfaceDecoder(JNIEnv* env, const std::string& mime, std::int32_t width, std::int32_t height) {
    if (!env || mime.empty()) return {};
    const jint w = std::max(width, 16);
    const jint h = std::max(height, 16);
    jclass formatClass = env->FindClass("android/media/MediaFormat");
    jclass listClass = env->FindClass("android/media/MediaCodecList");
    if (!formatClass || !listClass) {
        if (env->ExceptionCheck()) env->ExceptionClear();
        return {};
    }
    jmethodID createVideoFormat = env->GetStaticMethodID(formatClass, "createVideoFormat",
        "(Ljava/lang/String;II)Landroid/media/MediaFormat;");
    jmethodID setInteger = env->GetMethodID(formatClass, "setInteger", "(Ljava/lang/String;I)V");
    jmethodID listCtor = env->GetMethodID(listClass, "<init>", "(I)V");
    jmethodID findDecoder = env->GetMethodID(listClass, "findDecoderForFormat",
        "(Landroid/media/MediaFormat;)Ljava/lang/String;");
    if (!createVideoFormat || !setInteger || !listCtor || !findDecoder) {
        if (env->ExceptionCheck()) env->ExceptionClear();
        return {};
    }
    jstring jmime = env->NewStringUTF(mime.c_str());
    jobject format = env->CallStaticObjectMethod(formatClass, createVideoFormat, jmime, w, h);
    if (!format || env->ExceptionCheck()) {
        env->ExceptionClear();
        return {};
    }
    constexpr jint kColorFormatSurface = 0x7F000789;
    jstring colorKey = env->NewStringUTF("color-format");
    env->CallVoidMethod(format, setInteger, colorKey, kColorFormatSurface);
    if (env->ExceptionCheck()) {
        env->ExceptionClear();
        return {};
    }
    jobject list = env->NewObject(listClass, listCtor, 0);
    if (!list || env->ExceptionCheck()) {
        env->ExceptionClear();
        return {};
    }
    auto nameObj = static_cast<jstring>(env->CallObjectMethod(list, findDecoder, format));
    if (env->ExceptionCheck()) {
        env->ExceptionClear();
        nameObj = nullptr;
    }
    std::string name;
    if (nameObj) {
        const char* chars = env->GetStringUTFChars(nameObj, nullptr);
        if (chars) {
            name = chars;
            env->ReleaseStringUTFChars(nameObj, chars);
        }
    }
    return name;
}

void uniqueAppend(std::vector<std::string>* names, const std::string& name) {
    if (std::find(names->begin(), names->end(), name) == names->end()) names->push_back(name);
}

struct VideoPlayer {
    explicit VideoPlayer(std::string sourcePath) : path(std::move(sourcePath)) {}

    ~VideoPlayer() {
        requestStop();
        joinWorker();
        releaseDecoder();
        releaseSurface();
    }

    void requestStop() {
        stop.store(true, std::memory_order_release);
        cv.notify_all();
        frameReady.notify_all();
    }

    void joinWorker() {
        if (worker.joinable()) worker.join();
    }

    void startWorker() {
        worker = std::thread([this] { run(); });
    }

    bool surfaceAlive() const {
        return oesTexture != 0 && surfaceTexture != nullptr && window != nullptr
            && !surfaceInvalid
            && glContext != EGL_NO_CONTEXT
            && glContext == eglGetCurrentContext();
    }

    void dropSurface() {
        hasFrame.store(false, std::memory_order_release);
        surfaceInvalid = true;
        ANativeWindow* oldWindow = nullptr;
        {
            std::lock_guard lock(mutex);
            oldWindow = window;
            window = nullptr;
        }
        if (oldWindow) ANativeWindow_release(oldWindow);
        JniSession jni;
        if (jni.env) {
            if (surface) {
                if (g_jni.surfaceRelease) jni.env->CallVoidMethod(surface, g_jni.surfaceRelease);
                if (jni.env->ExceptionCheck()) jni.env->ExceptionClear();
                jni.env->DeleteGlobalRef(surface);
                surface = nullptr;
            }
            if (surfaceTexture) {
                if (g_jni.surfaceTextureRelease) {
                    jni.env->CallVoidMethod(surfaceTexture, g_jni.surfaceTextureRelease);
                }
                if (jni.env->ExceptionCheck()) jni.env->ExceptionClear();
                jni.env->DeleteGlobalRef(surfaceTexture);
                surfaceTexture = nullptr;
            }
        } else {
            surface = nullptr;
            surfaceTexture = nullptr;
        }
        const bool sameContext = glContext != EGL_NO_CONTEXT
            && eglGetCurrentContext() == glContext;
        if (oesTexture && sameContext) glDeleteTextures(1, &oesTexture);
        oesTexture = 0;
        glContext = EGL_NO_CONTEXT;
    }

    bool ensureSurface() {
        if (surfaceAlive()) return true;
        if (eglGetCurrentContext() == EGL_NO_CONTEXT) {
            setGlobalError("Video surface needs a current GLES context (Draw).");
            return false;
        }
        JniSession jni;
        if (!jni.env) {
            setGlobalError(javaVm()
                ? "Video surface JNI attach failed."
                : "Video surface JavaVM is missing (JNI_OnLoad).");
            return false;
        }
        if (!ensureJni(jni.env)) return false;

        dropSurface();

        glGenTextures(1, &oesTexture);
        glBindTexture(GL_TEXTURE_EXTERNAL_OES_ENUM, oesTexture);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES_ENUM, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES_ENUM, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES_ENUM, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES_ENUM, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        jobject localTexture = jni.env->NewObject(g_jni.surfaceTextureClass, g_jni.surfaceTextureCtor,
            static_cast<jint>(oesTexture));
        if (!localTexture || !jniOk(jni.env, "SurfaceTexture.<init>")) return false;
        surfaceTexture = jni.env->NewGlobalRef(localTexture);
        jni.env->DeleteLocalRef(localTexture);

        const std::int32_t w = std::max(videoWidth.load(std::memory_order_acquire), 1);
        const std::int32_t h = std::max(videoHeight.load(std::memory_order_acquire), 1);
        jni.env->CallVoidMethod(surfaceTexture, g_jni.setDefaultBufferSize, w, h);
        jniOk(jni.env, "SurfaceTexture.setDefaultBufferSize");

        jobject localSurface = jni.env->NewObject(g_jni.surfaceClass, g_jni.surfaceCtor, surfaceTexture);
        if (!localSurface || !jniOk(jni.env, "Surface.<init>")) return false;
        surface = jni.env->NewGlobalRef(localSurface);
        jni.env->DeleteLocalRef(localSurface);

        ANativeWindow* createdWindow = ANativeWindow_fromSurface(jni.env, surface);
        if (!createdWindow) {
            setGlobalError("ANativeWindow_fromSurface failed.");
            return false;
        }
        {
            std::lock_guard lock(mutex);
            window = createdWindow;
        }
        glContext = eglGetCurrentContext();
        surfaceInvalid = false;
        if (codec) codecNeedsSurface.store(true, std::memory_order_release);
        cv.notify_all();
        setGlobalError({});
        return true;
    }

    void updateDefaultBufferSize() {
        if (!surfaceTexture || !g_jni.ready || !g_jni.setDefaultBufferSize) return;
        JniSession jni;
        if (!jni.env) return;
        const std::int32_t w = std::max(videoWidth.load(std::memory_order_acquire), 1);
        const std::int32_t h = std::max(videoHeight.load(std::memory_order_acquire), 1);
        jni.env->CallVoidMethod(surfaceTexture, g_jni.setDefaultBufferSize, w, h);
        if (jni.env->ExceptionCheck()) jni.env->ExceptionClear();
    }

    bool updateImage(float* matrix16) {
        if (!surfaceTexture) return false;
        JniSession jni;
        if (!jni.env || !g_jni.ready) return false;
        glActiveTexture(GL_TEXTURE0);
        if (oesTexture) glBindTexture(GL_TEXTURE_EXTERNAL_OES_ENUM, oesTexture);
        jni.env->CallVoidMethod(surfaceTexture, g_jni.updateTexImage);
        if (jni.env->ExceptionCheck()) {
            jni.env->ExceptionClear();
            surfaceInvalid = true;
            hasFrame.store(false, std::memory_order_release);
            return false;
        }
        jfloatArray array = jni.env->NewFloatArray(16);
        if (!array) return false;
        jni.env->CallVoidMethod(surfaceTexture, g_jni.getTransformMatrix, array);
        if (jni.env->ExceptionCheck()) {
            jni.env->ExceptionClear();
            jni.env->DeleteLocalRef(array);
            return false;
        }
        jni.env->GetFloatArrayRegion(array, 0, 16, matrix16);
        jni.env->DeleteLocalRef(array);
        hasFrame.store(true, std::memory_order_release);
        return true;
    }

    std::int32_t status() const { return playbackStatus.load(std::memory_order_acquire); }

    float positionMs() const {
        std::lock_guard lock(mutex);
        if (!playing) return static_cast<float>(pausedPositionMs);
        const auto elapsed = std::chrono::duration<double, std::milli>(
            std::chrono::steady_clock::now() - clockStart).count();
        return static_cast<float>(clockBaseMs + elapsed);
    }

    bool play() {
        std::lock_guard lock(mutex);
        const auto statusNow = playbackStatus.load(std::memory_order_acquire);
        if (statusNow == kStatusError || statusNow == kStatusPreparing) return false;
        if (statusNow == kStatusEnded) seekRequestMs = 0.0;
        clockBaseMs = pausedPositionMs;
        clockStart = std::chrono::steady_clock::now();
        playing = true;
        playbackStatus.store(kStatusPlaying, std::memory_order_release);
        cv.notify_all();
        return true;
    }

    bool pausePlayback() {
        std::lock_guard lock(mutex);
        if (!playing) return playbackStatus.load(std::memory_order_acquire) == kStatusPaused;
        pausedPositionMs = clockBaseMs + std::chrono::duration<double, std::milli>(
            std::chrono::steady_clock::now() - clockStart).count();
        playing = false;
        playbackStatus.store(kStatusPaused, std::memory_order_release);
        cv.notify_all();
        return true;
    }

    bool seek(float positionMs) {
        if (!std::isfinite(positionMs)) return false;
        std::lock_guard lock(mutex);
        const double duration = videoDurationMs.load(std::memory_order_acquire);
        const double target = duration > 0.0
            ? std::clamp(static_cast<double>(positionMs), 0.0, duration)
            : std::max(0.0, static_cast<double>(positionMs));
        pausedPositionMs = target;
        clockBaseMs = target;
        clockStart = std::chrono::steady_clock::now();
        seekRequestMs = target;
        if (playbackStatus.load(std::memory_order_acquire) == kStatusEnded) {
            playbackStatus.store(playing ? kStatusPlaying : kStatusPaused, std::memory_order_release);
        }
        cv.notify_all();
        return true;
    }

    bool prepareFrame(float positionMs, float timeoutMs) {
        if (!std::isfinite(positionMs) || !std::isfinite(timeoutMs) || timeoutMs <= 0.0f) return false;
        if (!ensureSurface()) return false;
        std::unique_lock lock(mutex);
        const auto statusNow = playbackStatus.load(std::memory_order_acquire);
        if (statusNow == kStatusError) return false;
        const auto ready = cv.wait_for(lock, std::chrono::duration<double, std::milli>(timeoutMs), [this] {
            const auto value = playbackStatus.load(std::memory_order_acquire);
            return value != kStatusPreparing || stop.load(std::memory_order_acquire);
        });
        if (!ready || playbackStatus.load(std::memory_order_acquire) == kStatusError) return false;
        const double duration = videoDurationMs.load(std::memory_order_acquire);
        const double target = duration > 0.0
            ? std::clamp(static_cast<double>(positionMs), 0.0, duration)
            : std::max(0.0, static_cast<double>(positionMs));
        playing = false;
        pausedPositionMs = target;
        clockBaseMs = target;
        frameRequestMs = target;
        const std::uint64_t generation = ++frameRequestGeneration;
        playbackStatus.store(kStatusPaused, std::memory_order_release);
        cv.notify_all();
        const bool completed = frameReady.wait_for(lock,
            std::chrono::duration<double, std::milli>(timeoutMs), [this, generation] {
                return frameCompletedGeneration >= generation
                    || playbackStatus.load(std::memory_order_acquire) == kStatusError
                    || stop.load(std::memory_order_acquire);
            });
        return completed && frameCompletedGeneration >= generation && frameRequestSucceeded;
    }

    void setError(std::string message) {
        {
            std::lock_guard lock(errorMutex);
            lastError = std::move(message);
        }
        playbackStatus.store(kStatusError, std::memory_order_release);
        cv.notify_all();
        frameReady.notify_all();
    }

    std::string error() const {
        std::lock_guard lock(errorMutex);
        return lastError;
    }

    std::string path;
    std::thread worker;
    mutable std::mutex mutex;
    std::condition_variable cv;
    std::condition_variable frameReady;
    std::atomic<bool> stop{false};
    std::atomic<std::int32_t> playbackStatus{kStatusPreparing};
    std::atomic<std::int32_t> videoWidth{0};
    std::atomic<std::int32_t> videoHeight{0};
    std::atomic<float> videoDurationMs{0.0f};
    std::atomic<bool> loop{false};
    std::atomic<bool> hasFrame{false};
    bool playing = false;
    double pausedPositionMs = 0.0;
    double clockBaseMs = 0.0;
    std::chrono::steady_clock::time_point clockStart{};
    std::optional<double> seekRequestMs;
    std::optional<double> frameRequestMs;
    std::uint64_t frameRequestGeneration = 0;
    std::uint64_t frameCompletedGeneration = 0;
    bool frameRequestSucceeded = false;
    GLuint oesTexture = 0;
    jobject surfaceTexture = nullptr;
    jobject surface = nullptr;
    ANativeWindow* window = nullptr;
    AMediaExtractor* extractor = nullptr;
    AMediaCodec* codec = nullptr;
    mutable std::mutex errorMutex;
    std::string lastError;

private:
    bool openExtractor() {
        extractor = AMediaExtractor_new();
        if (!extractor) {
            setError("AMediaExtractor_new failed.");
            return false;
        }
        std::string source = path;
        std::replace(source.begin(), source.end(), '\\', '/');
        if (source.rfind("file://", 0) == 0) source.erase(0, 7);
        media_status_t status = AMediaExtractor_setDataSource(extractor, source.c_str());
        if (status != AMEDIA_OK) {
            const int fd = open(source.c_str(), O_RDONLY);
            if (fd < 0) {
                setError("Failed to open video file: " + source);
                return false;
            }
            struct stat info {};
            if (fstat(fd, &info) != 0) {
                close(fd);
                setError("Failed to stat video file: " + source);
                return false;
            }
            status = AMediaExtractor_setDataSourceFd(extractor, fd, 0, info.st_size);
            close(fd);
            if (status != AMEDIA_OK) {
                setError("AMediaExtractor_setDataSource failed for " + source);
                return false;
            }
        }

        const size_t trackCount = AMediaExtractor_getTrackCount(extractor);
        videoTrack = static_cast<size_t>(-1);
        AMediaFormat* format = nullptr;
        for (size_t i = 0; i < trackCount; ++i) {
            AMediaFormat* trackFormat = AMediaExtractor_getTrackFormat(extractor, i);
            if (!trackFormat) continue;
            const char* mime = nullptr;
            AMediaFormat_getString(trackFormat, AMEDIAFORMAT_KEY_MIME, &mime);
            if (mime && std::strncmp(mime, "video/", 6) == 0) {
                videoTrack = i;
                format = trackFormat;
                break;
            }
            AMediaFormat_delete(trackFormat);
        }
        if (videoTrack == static_cast<size_t>(-1) || !format) {
            setError("No video track was found.");
            return false;
        }
        if (AMediaExtractor_selectTrack(extractor, videoTrack) != AMEDIA_OK) {
            AMediaFormat_delete(format);
            setError("AMediaExtractor_selectTrack failed.");
            return false;
        }

        std::int32_t width = 0;
        std::int32_t height = 0;
        readVideoSize(format, &width, &height);
        videoWidth.store(width, std::memory_order_release);
        videoHeight.store(height, std::memory_order_release);
        const int64_t durationUs = mediaInt64(format, AMEDIAFORMAT_KEY_DURATION);
        videoDurationMs.store(static_cast<float>(std::max<int64_t>(durationUs, 0) / 1000.0),
            std::memory_order_release);
        const char* mime = nullptr;
        AMediaFormat_getString(format, AMEDIAFORMAT_KEY_MIME, &mime);
        mimeType = mime ? mime : "";
        pendingFormat = format;
        return true;
    }

    bool configureAndStart(ANativeWindow* output) {
        if (!pendingFormat || mimeType.empty() || !output) {
            setError("MediaCodec is missing format, mime, or output surface.");
            return false;
        }
        updateDefaultBufferSize();
        const std::int32_t width = videoWidth.load(std::memory_order_acquire);
        const std::int32_t height = videoHeight.load(std::memory_order_acquire);
        if (width > 0 && height > 0) {
            ANativeWindow_setBuffersGeometry(output, width, height, 0);
        }

        std::vector<std::string> names;
        JniSession jni;
        if (jni.env) uniqueAppend(&names, findSurfaceDecoder(jni.env, mimeType, width, height));
        uniqueAppend(&names, std::string());
        for (const auto& name : softwareDecoderNames(mimeType)) uniqueAppend(&names, name);

        AMediaFormat* clean = makeDecoderFormat(pendingFormat, mimeType, width, height, false);
        AMediaFormat* withProfile = makeDecoderFormat(pendingFormat, mimeType, width, height, true);
        AMediaFormat* formats[] = { clean, withProfile, pendingFormat };

        std::string lastDetail = "no decoder candidates";
        AMediaCodec* started = nullptr;
        std::string startedName;
        for (int attempt = 0; attempt < 2 && !started; ++attempt) {
            if (attempt == 1) {
                logVideo(ANDROID_LOG_WARN, "Retrying MediaCodec after a short delay.");
                std::this_thread::sleep_for(std::chrono::milliseconds(40));
            }
            for (const auto& name : names) {
                const std::string label = name.empty() ? ("type:" + mimeType) : name;
                for (int variant = 0; variant < 3; ++variant) {
                    AMediaFormat* format = formats[variant];
                    if (!format) continue;
                    AMediaCodec* candidate = name.empty()
                        ? AMediaCodec_createDecoderByType(mimeType.c_str())
                        : AMediaCodec_createCodecByName(name.c_str());
                    if (!candidate) {
                        lastDetail = label + " create failed";
                        continue;
                    }
                    const char* variantName = variant == 0 ? "clean" : (variant == 1 ? "profile" : "raw");
                    const media_status_t cfg = AMediaCodec_configure(candidate, format, output, nullptr, 0);
                    if (cfg != AMEDIA_OK) {
                        lastDetail = label + " " + variantName + " configure=" + mediaStatusName(cfg);
                        logVideo(ANDROID_LOG_WARN, lastDetail);
                        AMediaCodec_delete(candidate);
                        continue;
                    }
                    const media_status_t start = AMediaCodec_start(candidate);
                    if (start != AMEDIA_OK) {
                        lastDetail = label + " " + variantName + " start=" + mediaStatusName(start);
                        logVideo(ANDROID_LOG_WARN, lastDetail);
                        AMediaCodec_stop(candidate);
                        AMediaCodec_delete(candidate);
                        continue;
                    }
                    started = candidate;
                    startedName = label + "/" + variantName;
                    break;
                }
                if (started) break;
            }
        }
        if (clean) AMediaFormat_delete(clean);
        if (withProfile) AMediaFormat_delete(withProfile);

        if (!started) {
            setError("MediaCodec configure failed. mime=" + mimeType
                + " size=" + std::to_string(width) + "x" + std::to_string(height)
                + " last=" + lastDetail);
            return false;
        }
        codec = started;
        logVideo(ANDROID_LOG_INFO, "decoder started " + startedName
            + " mime=" + mimeType
            + " size=" + std::to_string(width) + "x" + std::to_string(height));
        codecNeedsSurface.store(false, std::memory_order_release);
        return true;
    }

    bool startCodec() {
        ANativeWindow* output = nullptr;
        {
            std::lock_guard lock(mutex);
            output = window;
        }
        return configureAndStart(output);
    }

    bool rebindCodecWindow() {
        ANativeWindow* output = nullptr;
        {
            std::lock_guard lock(mutex);
            output = window;
        }
        if (!output || mimeType.empty()) return false;
        using SetOutputSurfaceFn = media_status_t (*)(AMediaCodec*, ANativeWindow*);
        static SetOutputSurfaceFn setOutputSurface = reinterpret_cast<SetOutputSurfaceFn>(
            dlsym(RTLD_DEFAULT, "AMediaCodec_setOutputSurface"));
        if (codec && setOutputSurface && setOutputSurface(codec, output) == AMEDIA_OK) {
            AMediaCodec_flush(codec);
            inputEos = false;
            outputEos = false;
            return true;
        }
        if (codec) {
            AMediaCodec_stop(codec);
            AMediaCodec_delete(codec);
            codec = nullptr;
        }
        if (!configureAndStart(output)) {
            setError("MediaCodec surface rebind failed after resume. " + error());
            return false;
        }
        inputEos = false;
        outputEos = false;
        return true;
    }

    void doSeek(double positionMs) {
        if (!extractor || !codec) return;
        const int64_t timeUs = static_cast<int64_t>(std::max(0.0, positionMs) * 1000.0);
        AMediaExtractor_seekTo(extractor, timeUs, AMEDIAEXTRACTOR_SEEK_PREVIOUS_SYNC);
        AMediaCodec_flush(codec);
        discardUntilUs = timeUs;
        inputEos = false;
        outputEos = false;
    }

    bool decodeUntil(double targetMs, int maxFrames) {
        const int64_t targetUs = static_cast<int64_t>(std::max(0.0, targetMs) * 1000.0);
        discardUntilUs = std::max<int64_t>(0, targetUs - 80000);
        for (int i = 0; i < maxFrames && !stop.load(std::memory_order_acquire); ++i) {
            if (pump(false, 20000, true)) return true;
            if (outputEos) break;
        }
        return false;
    }

    bool pump(bool paced, int64_t timeoutUs, bool stopAfterRender = false) {
        if (!codec || !extractor) return false;
        if (!inputEos) {
            const ssize_t input = AMediaCodec_dequeueInputBuffer(codec, 0);
            if (input >= 0) {
                size_t capacity = 0;
                uint8_t* buffer = AMediaCodec_getInputBuffer(codec, static_cast<size_t>(input), &capacity);
                ssize_t sample = -1;
                if (buffer && capacity > 0) {
                    sample = AMediaExtractor_readSampleData(extractor, buffer, capacity);
                }
                if (sample < 0) {
                    AMediaCodec_queueInputBuffer(codec, static_cast<size_t>(input), 0, 0, 0,
                        AMEDIACODEC_BUFFER_FLAG_END_OF_STREAM);
                    inputEos = true;
                } else {
                    const int64_t pts = AMediaExtractor_getSampleTime(extractor);
                    AMediaCodec_queueInputBuffer(codec, static_cast<size_t>(input), 0,
                        static_cast<size_t>(sample), pts, 0);
                    AMediaExtractor_advance(extractor);
                }
            }
        }

        AMediaCodecBufferInfo info{};
        const ssize_t output = AMediaCodec_dequeueOutputBuffer(codec, &info, timeoutUs);
        if (output == AMEDIACODEC_INFO_OUTPUT_FORMAT_CHANGED) {
            AMediaFormat* format = AMediaCodec_getOutputFormat(codec);
            if (format) {
                std::int32_t width = 0;
                std::int32_t height = 0;
                readVideoSize(format, &width, &height);
                if (width > 0) videoWidth.store(width, std::memory_order_release);
                if (height > 0) videoHeight.store(height, std::memory_order_release);
                AMediaFormat_delete(format);
            }
            return false;
        }
        if (output < 0) return false;

        const bool eos = (info.flags & AMEDIACODEC_BUFFER_FLAG_END_OF_STREAM) != 0;
        bool render = info.size > 0 && info.presentationTimeUs >= discardUntilUs;
        if (paced && render && playing) {
            const int64_t clockUs = static_cast<int64_t>(positionClockMs() * 1000.0);
            if (info.presentationTimeUs > clockUs + 2000) {
                const auto wait = std::min<int64_t>(info.presentationTimeUs - clockUs, 40000);
                std::this_thread::sleep_for(std::chrono::microseconds(wait));
            }
        }
        AMediaCodec_releaseOutputBuffer(codec, static_cast<size_t>(output), render);
        if (render) lastPtsUs = info.presentationTimeUs;
        if (eos) outputEos = true;
        return render && (!stopAfterRender || lastPtsUs >= discardUntilUs);
    }

    double positionClockMs() const {
        if (!playing) return pausedPositionMs;
        return clockBaseMs + std::chrono::duration<double, std::milli>(
            std::chrono::steady_clock::now() - clockStart).count();
    }

    void run() {
        if (!openExtractor()) return;
        updateDefaultBufferSize();
        {
            std::unique_lock lock(mutex);
            while (!stop.load(std::memory_order_acquire) && window == nullptr) {
                cv.wait_for(lock, std::chrono::milliseconds(50));
            }
            if (stop.load(std::memory_order_acquire)) return;
            if (window == nullptr) return;
        }
        if (!startCodec()) return;
        decodeUntil(pausedPositionMs, 48);
        playbackStatus.store(kStatusPaused, std::memory_order_release);
        cv.notify_all();

        while (!stop.load(std::memory_order_acquire)) {
            double seekMs = -1.0;
            double frameMs = -1.0;
            std::uint64_t frameGen = 0;
            bool isPlaying = false;
            {
                std::unique_lock lock(mutex);
                if (seekRequestMs) {
                    seekMs = *seekRequestMs;
                    seekRequestMs.reset();
                }
                if (frameRequestMs) {
                    frameMs = *frameRequestMs;
                    frameGen = frameRequestGeneration;
                    frameRequestMs.reset();
                }
                isPlaying = playing;
                if (!isPlaying && seekMs < 0.0 && frameMs < 0.0
                    && !codecNeedsSurface.load(std::memory_order_acquire)
                    && !stop.load(std::memory_order_acquire)) {
                    cv.wait_for(lock, std::chrono::milliseconds(20));
                    continue;
                }
            }
            if (stop.load(std::memory_order_acquire)) break;
            if (codecNeedsSurface.load(std::memory_order_acquire)) {
                std::unique_lock lock(mutex);
                cv.wait_for(lock, std::chrono::milliseconds(50), [this] {
                    return stop.load(std::memory_order_acquire) || window != nullptr;
                });
                const bool ready = window != nullptr && !stop.load(std::memory_order_acquire);
                lock.unlock();
                if (ready && codecNeedsSurface.exchange(false, std::memory_order_acq_rel)) {
                    if (rebindCodecWindow()) doSeek(positionClockMs());
                }
            }
            if (seekMs >= 0.0) {
                doSeek(seekMs);
                if (!isPlaying && frameMs < 0.0) decodeUntil(seekMs, 24);
            }
            if (frameMs >= 0.0) {
                doSeek(frameMs);
                const bool ok = decodeUntil(frameMs, 48);
                {
                    std::lock_guard lock(mutex);
                    frameRequestSucceeded = ok;
                    frameCompletedGeneration = frameGen;
                }
                frameReady.notify_all();
                continue;
            }
            if (isPlaying) {
                pump(true, 8000);
                if (outputEos) {
                    if (loop.load(std::memory_order_acquire)) {
                        doSeek(0.0);
                        std::lock_guard lock(mutex);
                        pausedPositionMs = 0.0;
                        clockBaseMs = 0.0;
                        clockStart = std::chrono::steady_clock::now();
                    } else {
                        std::lock_guard lock(mutex);
                        playing = false;
                        pausedPositionMs = videoDurationMs.load(std::memory_order_acquire);
                        playbackStatus.store(kStatusEnded, std::memory_order_release);
                    }
                }
            }
        }
    }

    void releaseDecoder() {
        if (codec) {
            AMediaCodec_stop(codec);
            AMediaCodec_delete(codec);
            codec = nullptr;
        }
        if (extractor) {
            AMediaExtractor_delete(extractor);
            extractor = nullptr;
        }
        if (pendingFormat) {
            AMediaFormat_delete(pendingFormat);
            pendingFormat = nullptr;
        }
    }

    void releaseSurface() {
        dropSurface();
    }

    AMediaFormat* pendingFormat = nullptr;
    std::string mimeType;
    size_t videoTrack = static_cast<size_t>(-1);
    EGLContext glContext = EGL_NO_CONTEXT;
    std::atomic<bool> codecNeedsSurface{false};
    bool surfaceInvalid = false;
    int64_t discardUntilUs = 0;
    int64_t lastPtsUs = 0;
    bool inputEos = false;
    bool outputEos = false;
};

std::unordered_map<std::int32_t, std::shared_ptr<VideoPlayer>> g_players;

std::shared_ptr<VideoPlayer> getPlayer(std::int32_t handle) {
    std::lock_guard lock(g_mutex);
    const auto found = g_players.find(handle);
    return found == g_players.end() ? nullptr : found->second;
}

} // namespace

std::int32_t ffvideos_initialize(void* device, void* context) {
    (void)device;
    (void)context;
    ffvideos_shutdown();
    g_ready = true;
    {
        JniSession jni;
        if (jni.env) ensureJni(jni.env);
    }
    ensureDrawPipeline();
    setGlobalError({});
    return 3;
}

std::int32_t ffvideos_open(std::string_view path) {
    if (!g_ready || path.empty()) {
        setGlobalError("FFVideos is not initialized or the path is empty.");
        return -1;
    }
    try {
        auto player = std::make_shared<VideoPlayer>(std::string(path));
        std::int32_t handle = -1;
        {
            std::lock_guard lock(g_mutex);
            const std::int32_t firstCandidate = g_nextHandle;
            while (g_players.find(g_nextHandle) != g_players.end()) {
                g_nextHandle = g_nextHandle == std::numeric_limits<std::int32_t>::max()
                    ? 1 : g_nextHandle + 1;
                if (g_nextHandle == firstCandidate) {
                    g_globalError = "No video handles are available.";
                    return -1;
                }
            }
            handle = g_nextHandle;
            g_nextHandle = g_nextHandle == std::numeric_limits<std::int32_t>::max()
                ? 1 : g_nextHandle + 1;
            g_players.emplace(handle, player);
            g_globalError.clear();
        }
        player->startWorker();
        player->ensureSurface();
        return handle;
    } catch (...) {
        setGlobalError("Unexpected failure while opening the video.");
        return -1;
    }
}

bool ffvideos_close(std::int32_t handle) {
    std::shared_ptr<VideoPlayer> removed;
    {
        std::lock_guard lock(g_mutex);
        const auto found = g_players.find(handle);
        if (found == g_players.end()) return false;
        removed = std::move(found->second);
        g_players.erase(found);
    }
    if (removed) removed->requestStop();
    return true;
}

bool ffvideos_play(std::int32_t handle) {
    const auto player = getPlayer(handle);
    return player && player->play();
}

bool ffvideos_pause(std::int32_t handle) {
    const auto player = getPlayer(handle);
    return player && player->pausePlayback();
}

bool ffvideos_seek(std::int32_t handle, float positionMs) {
    const auto player = getPlayer(handle);
    return player && player->seek(positionMs);
}

bool ffvideos_prepare_frame(std::int32_t handle, float positionMs, float timeoutMs) {
    const auto player = getPlayer(handle);
    return player && player->prepareFrame(positionMs, timeoutMs);
}

bool ffvideos_set_volume(std::int32_t handle, float volume) {
    (void)volume;
    return static_cast<bool>(getPlayer(handle));
}

bool ffvideos_set_loop(std::int32_t handle, bool enabled) {
    const auto player = getPlayer(handle);
    if (!player) return false;
    player->loop.store(enabled, std::memory_order_release);
    return true;
}

std::int32_t ffvideos_get_status(std::int32_t handle) {
    const auto player = getPlayer(handle);
    return player ? player->status() : kStatusClosed;
}

float ffvideos_get_duration(std::int32_t handle) {
    const auto player = getPlayer(handle);
    return player ? player->videoDurationMs.load(std::memory_order_acquire) : 0.0f;
}

float ffvideos_get_position(std::int32_t handle) {
    const auto player = getPlayer(handle);
    return player ? player->positionMs() : 0.0f;
}

std::int32_t ffvideos_get_width(std::int32_t handle) {
    const auto player = getPlayer(handle);
    return player ? player->videoWidth.load(std::memory_order_acquire) : 0;
}

std::int32_t ffvideos_get_height(std::int32_t handle) {
    const auto player = getPlayer(handle);
    return player ? player->videoHeight.load(std::memory_order_acquire) : 0;
}

std::int32_t ffvideos_draw(std::int32_t handle, float left, float top, float right,
    float bottom, float alpha, float dim) {
    const auto player = getPlayer(handle);
    if (!player || !g_ready) return 0;
    // Decoder waits on the output Surface. Create it even if the OES shader
    // has not compiled yet, otherwise playback dies before the first frame.
    if (!player->ensureSurface()) return -1;
    if (!ensureDrawPipeline()) return -1;

    float matrix[16]{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    };
    player->updateImage(matrix);
    if (!(right > left && bottom > top) || !player->hasFrame.load(std::memory_order_acquire)) return 0;

    GLint previousProgram = 0;
    GLint previousArrayBuffer = 0;
    GLint previousTexture2D = 0;
    GLint previousExternal = 0;
    GLint previousActive = 0;
    GLint previousVao = 0;
    GLint previousViewport[4] = {0, 0, 0, 0};
    GLint previousScissor[4] = {0, 0, 0, 0};
    GLint previousSrc = 0;
    GLint previousDst = 0;
    const GLboolean previousBlend = glIsEnabled(GL_BLEND);
    const GLboolean previousDepth = glIsEnabled(GL_DEPTH_TEST);
    const GLboolean previousCull = glIsEnabled(GL_CULL_FACE);
    const GLboolean previousScissorEnabled = glIsEnabled(GL_SCISSOR_TEST);
    glGetIntegerv(GL_CURRENT_PROGRAM, &previousProgram);
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &previousArrayBuffer);
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &previousTexture2D);
    glGetIntegerv(GL_TEXTURE_BINDING_EXTERNAL_OES_ENUM, &previousExternal);
    glGetIntegerv(GL_ACTIVE_TEXTURE, &previousActive);
    glGetIntegerv(0x85B5, &previousVao);
    glGetIntegerv(GL_VIEWPORT, previousViewport);
    glGetIntegerv(GL_SCISSOR_BOX, previousScissor);
    glGetIntegerv(GL_BLEND_SRC_RGB, &previousSrc);
    glGetIntegerv(GL_BLEND_DST_RGB, &previousDst);

    const float width = static_cast<float>(std::max(previousViewport[2], 1));
    const float height = static_cast<float>(std::max(previousViewport[3], 1));
    const float clippedLeft = std::clamp(left, 0.0f, 1.0f);
    const float clippedTop = std::clamp(top, 0.0f, 1.0f);
    const float clippedRight = std::clamp(right, 0.0f, 1.0f);
    const float clippedBottom = std::clamp(bottom, 0.0f, 1.0f);
    glViewport(
        static_cast<GLint>(clippedLeft * width),
        static_cast<GLint>((1.0f - clippedBottom) * height),
        static_cast<GLsizei>((clippedRight - clippedLeft) * width),
        static_cast<GLsizei>((clippedBottom - clippedTop) * height));

    if (const auto bindVao = bindVertexArrayFn()) bindVao(g_vao);
    glDisable(GL_CULL_FACE);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_EXTERNAL_OES_ENUM, player->oesTexture);
    glUseProgram(g_program);
    if (g_uTexture >= 0) glUniform1i(g_uTexture, 0);
    if (g_uMatrix >= 0) glUniformMatrix4fv(g_uMatrix, 1, GL_FALSE, matrix);
    if (g_uAlpha >= 0) glUniform1f(g_uAlpha, std::clamp(alpha, 0.0f, 1.0f));
    if (g_uDim >= 0) glUniform1f(g_uDim, std::clamp(dim, 0.0f, 1.0f));
    glBindBuffer(GL_ARRAY_BUFFER, g_vbo);
    glEnableVertexAttribArray(static_cast<GLuint>(g_aPosition));
    glEnableVertexAttribArray(static_cast<GLuint>(g_aTexCoord));
    glVertexAttribPointer(static_cast<GLuint>(g_aPosition), 2, GL_FLOAT, GL_FALSE,
        4 * sizeof(float), nullptr);
    glVertexAttribPointer(static_cast<GLuint>(g_aTexCoord), 2, GL_FLOAT, GL_FALSE,
        4 * sizeof(float), reinterpret_cast<const void*>(2 * sizeof(float)));
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    glDisableVertexAttribArray(static_cast<GLuint>(g_aPosition));
    glDisableVertexAttribArray(static_cast<GLuint>(g_aTexCoord));

    glBindBuffer(GL_ARRAY_BUFFER, previousArrayBuffer);
    if (const auto bindVao = bindVertexArrayFn()) bindVao(static_cast<GLuint>(previousVao));
    glBindTexture(GL_TEXTURE_EXTERNAL_OES_ENUM, static_cast<GLuint>(previousExternal));
    glBindTexture(GL_TEXTURE_2D, static_cast<GLuint>(previousTexture2D));
    glActiveTexture(static_cast<GLenum>(previousActive));
    glUseProgram(previousProgram);
    glViewport(previousViewport[0], previousViewport[1], previousViewport[2], previousViewport[3]);
    if (previousScissorEnabled) glEnable(GL_SCISSOR_TEST);
    else glDisable(GL_SCISSOR_TEST);
    glScissor(previousScissor[0], previousScissor[1], previousScissor[2], previousScissor[3]);
    if (previousBlend) glEnable(GL_BLEND);
    else glDisable(GL_BLEND);
    if (previousDepth) glEnable(GL_DEPTH_TEST);
    else glDisable(GL_DEPTH_TEST);
    if (previousCull) glEnable(GL_CULL_FACE);
    else glDisable(GL_CULL_FACE);
    glBlendFunc(previousSrc, previousDst);
    return 7;
}

std::string ffvideos_get_error(std::int32_t handle) {
    if (const auto player = getPlayer(handle)) {
        const std::string playerError = player->error();
        if (!playerError.empty()) return playerError;
    }
    std::lock_guard lock(g_mutex);
    return g_globalError;
}

void ffvideos_shutdown() {
    std::unordered_map<std::int32_t, std::shared_ptr<VideoPlayer>> players;
    {
        std::lock_guard lock(g_mutex);
        players.swap(g_players);
        g_nextHandle = 1;
        g_ready = false;
    }
    for (auto& [handle, player] : players) {
        (void)handle;
        if (player) player->requestStop();
    }
    players.clear();
    destroyDrawPipeline();
}
