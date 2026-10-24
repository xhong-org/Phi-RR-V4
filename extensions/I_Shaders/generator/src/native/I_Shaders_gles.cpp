#include "native/I_Shaders_gles.h"

#include <GL/gl.h>

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstring>
#include <memory>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

// Both Windows backends sample a copy of the current target. PS slot 0 can
// still contain a font, note atlas or video plane after GameMaker flushes.
ID3D11ShaderResourceView* rpeSnapshotRenderTarget();

namespace {

constexpr unsigned kGlBgra = 0x80E1;
constexpr unsigned kGlClampToEdge = 0x812F;
constexpr unsigned kGlTexture0 = 0x84C0;
constexpr unsigned kGlUnpackRowLength = 0x0CF2;
constexpr unsigned kGlFragmentShader = 0x8B30;
constexpr unsigned kGlVertexShader = 0x8B31;
constexpr unsigned kGlCompileStatus = 0x8B81;
constexpr unsigned kGlLinkStatus = 0x8B82;
constexpr unsigned kGlInfoLogLength = 0x8B84;
constexpr unsigned kGlSampler2D = 0x8B5E;
constexpr unsigned kGlFloatVec2 = 0x8B50;
constexpr unsigned kGlFloatVec3 = 0x8B51;
constexpr unsigned kGlFloatVec4 = 0x8B52;
constexpr unsigned kGlFramebuffer = 0x8D40;
constexpr unsigned kGlColorAttachment0 = 0x8CE0;
constexpr unsigned kGlFramebufferComplete = 0x8CD5;
constexpr int WGL_CONTEXT_MAJOR_VERSION_ARB = 0x2091;
constexpr int WGL_CONTEXT_MINOR_VERSION_ARB = 0x2092;
constexpr int WGL_CONTEXT_PROFILE_MASK_ARB = 0x9126;
constexpr int WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB = 0x00000002;
constexpr std::int32_t kHandleBase = 1000000;

struct UniformRecord {
    int location = -1;
    int components = 1;
    float values[4] = {0, 0, 0, 0};
};

struct ShaderRecord {
    unsigned program = 0;
    int uvRectLocation = -1;
    std::unordered_map<std::string, UniformRecord> uniforms;
};

using CreateContextAttribs = HGLRC(WINAPI*)(HDC, HGLRC, const int*);
using GLUIntProc = unsigned(WINAPI*)();
using GLUIntUIntProc = unsigned(WINAPI*)(unsigned);
using GLShaderSource = void(WINAPI*)(unsigned, int, const char* const*, const int*);
using GLVoidUInt = void(WINAPI*)(unsigned);
using GLGetShaderiv = void(WINAPI*)(unsigned, unsigned, int*);
using GLGetInfoLog = void(WINAPI*)(unsigned, int, int*, char*);
using GLAttach = void(WINAPI*)(unsigned, unsigned);
using GLBindAttrib = void(WINAPI*)(unsigned, unsigned, const char*);
using GLGetProgramiv = void(WINAPI*)(unsigned, unsigned, int*);
using GLUseProgram = void(WINAPI*)(unsigned);
using GLGetUniformLocation = int(WINAPI*)(unsigned, const char*);
using GLGetAttribLocation = int(WINAPI*)(unsigned, const char*);
using GLUniform1i = void(WINAPI*)(int, int);
using GLUniform1f = void(WINAPI*)(int, float);
using GLUniform2f = void(WINAPI*)(int, float, float);
using GLUniform4f = void(WINAPI*)(int, float, float, float, float);
using GLGen = void(WINAPI*)(int, unsigned*);
using GLBindTexture = void(WINAPI*)(unsigned, unsigned);
using GLTexImage = void(WINAPI*)(unsigned, int, int, int, int, int, unsigned, unsigned, const void*);
using GLTexParam = void(WINAPI*)(unsigned, unsigned, int);
using GLActiveTexture = void(WINAPI*)(unsigned);
using GLGenFb = void(WINAPI*)(int, unsigned*);
using GLBindFb = void(WINAPI*)(unsigned, unsigned);
using GLFbTexture = void(WINAPI*)(unsigned, unsigned, unsigned, unsigned, int);
using GLCheckFb = unsigned(WINAPI*)(unsigned);
using GLViewport = void(WINAPI*)(int, int, int, int);
using GLClearColor = void(WINAPI*)(float, float, float, float);
using GLClear = void(WINAPI*)(unsigned);
using GLEnableAttrib = void(WINAPI*)(unsigned);
using GLDisableAttrib = void(WINAPI*)(unsigned);
using GLAttribPointer = void(WINAPI*)(unsigned, int, unsigned, unsigned char, int, const void*);
using GLDrawArrays = void(WINAPI*)(unsigned, int, int);
using GLReadPixels = void(WINAPI*)(int, int, int, int, unsigned, unsigned, void*);
using GLPixelStore = void(WINAPI*)(unsigned, int);
using GLGetActiveUniform = void(WINAPI*)(unsigned, unsigned, int, int*, int*, unsigned*, char*);
using GLDelete = void(WINAPI*)(int, const unsigned*);
using GLDeleteProgram = void(WINAPI*)(unsigned);
using GLGetIntegerv = void(WINAPI*)(unsigned, int*);
using GLGetString = const unsigned char*(WINAPI*)(unsigned);

HWND g_window = nullptr;
HDC g_dc = nullptr;
HGLRC g_context = nullptr;
bool g_ready = false;
std::string g_error;
int g_nextHandle = kHandleBase;
std::unordered_map<int, std::unique_ptr<ShaderRecord>> g_shaders;
unsigned g_sourceTexture = 0;
unsigned g_targetTexture = 0;
unsigned g_fbo = 0;
int g_sourceWidth = 0;
int g_sourceHeight = 0;
int g_targetWidth = 0;
int g_targetHeight = 0;
unsigned g_sourceFormat = GL_RGBA;
ID3D11Texture2D* g_staging = nullptr;
int g_stagingWidth = 0;
int g_stagingHeight = 0;
DXGI_FORMAT g_stagingFormat = DXGI_FORMAT_UNKNOWN;

GLUIntUIntProc glCreateShaderFn = nullptr;
GLShaderSource glShaderSourceFn = nullptr;
GLVoidUInt glCompileShaderFn = nullptr;
GLGetShaderiv glGetShaderivFn = nullptr;
GLGetInfoLog glGetShaderInfoLogFn = nullptr;
GLUIntProc glCreateProgramFn = nullptr;
GLAttach glAttachShaderFn = nullptr;
GLBindAttrib glBindAttribLocationFn = nullptr;
GLVoidUInt glLinkProgramFn = nullptr;
GLGetProgramiv glGetProgramivFn = nullptr;
GLGetInfoLog glGetProgramInfoLogFn = nullptr;
GLUseProgram glUseProgramFn = nullptr;
GLGetUniformLocation glGetUniformLocationFn = nullptr;
GLUniform1i glUniform1iFn = nullptr;
GLUniform1f glUniform1fFn = nullptr;
GLUniform2f glUniform2fFn = nullptr;
GLUniform4f glUniform4fFn = nullptr;
GLGen glGenTexturesFn = nullptr;
GLBindTexture glBindTextureFn = nullptr;
GLTexImage glTexImage2DFn = nullptr;
GLTexParam glTexParameteriFn = nullptr;
GLActiveTexture glActiveTextureFn = nullptr;
GLGenFb glGenFramebuffersFn = nullptr;
GLBindFb glBindFramebufferFn = nullptr;
GLFbTexture glFramebufferTexture2DFn = nullptr;
GLCheckFb glCheckFramebufferStatusFn = nullptr;
GLViewport glViewportFn = nullptr;
GLClearColor glClearColorFn = nullptr;
GLClear glClearFn = nullptr;
GLEnableAttrib glEnableVertexAttribArrayFn = nullptr;
GLDisableAttrib glDisableVertexAttribArrayFn = nullptr;
GLAttribPointer glVertexAttribPointerFn = nullptr;
GLDrawArrays glDrawArraysFn = nullptr;
GLReadPixels glReadPixelsFn = nullptr;
GLPixelStore glPixelStoreiFn = nullptr;
GLGetActiveUniform glGetActiveUniformFn = nullptr;
GLGetProgramiv glGetProgramivCountFn = nullptr;
GLDelete glDeleteTexturesFn = nullptr;
GLDelete glDeleteFramebuffersFn = nullptr;
GLDeleteProgram glDeleteProgramFn = nullptr;
GLVoidUInt glDeleteShaderFn = nullptr;
GLGetIntegerv glGetIntegervFn = nullptr;
GLGetString glGetStringFn = nullptr;

void setError(std::string value) { g_error = std::move(value); }

std::string trim(const std::string& value) {
    const auto start = value.find_first_not_of(" \t\r\n");
    if (start == std::string::npos) return {};
    const auto end = value.find_last_not_of(" \t\r\n");
    return value.substr(start, end - start + 1);
}

std::string stripComments(std::string source) {
    std::string result;
    result.reserve(source.size());
    for (std::size_t i = 0; i < source.size();) {
        if (i + 1 < source.size() && source[i] == '/' && source[i + 1] == '/') {
            while (i < source.size() && source[i] != '\n') ++i;
            continue;
        }
        if (i + 1 < source.size() && source[i] == '/' && source[i + 1] == '*') {
            i += 2;
            while (i + 1 < source.size() && !(source[i] == '*' && source[i + 1] == '/')) ++i;
            i = std::min(i + 2, source.size());
            result.push_back(' ');
            continue;
        }
        result.push_back(source[i++]);
    }
    return result;
}

LRESULT CALLBACK windowProc(HWND window, UINT message, WPARAM wParam, LPARAM lParam) {
    return DefWindowProcW(window, message, wParam, lParam);
}

bool loadGl() {
    auto load = [](const char* name) { return wglGetProcAddress(name); };
    glCreateShaderFn = reinterpret_cast<GLUIntUIntProc>(load("glCreateShader"));
    glShaderSourceFn = reinterpret_cast<GLShaderSource>(load("glShaderSource"));
    glCompileShaderFn = reinterpret_cast<GLVoidUInt>(load("glCompileShader"));
    glGetShaderivFn = reinterpret_cast<GLGetShaderiv>(load("glGetShaderiv"));
    glGetShaderInfoLogFn = reinterpret_cast<GLGetInfoLog>(load("glGetShaderInfoLog"));
    glCreateProgramFn = reinterpret_cast<GLUIntProc>(load("glCreateProgram"));
    glAttachShaderFn = reinterpret_cast<GLAttach>(load("glAttachShader"));
    glBindAttribLocationFn = reinterpret_cast<GLBindAttrib>(load("glBindAttribLocation"));
    glLinkProgramFn = reinterpret_cast<GLVoidUInt>(load("glLinkProgram"));
    glGetProgramivFn = reinterpret_cast<GLGetProgramiv>(load("glGetProgramiv"));
    glGetProgramInfoLogFn = reinterpret_cast<GLGetInfoLog>(load("glGetProgramInfoLog"));
    glUseProgramFn = reinterpret_cast<GLUseProgram>(load("glUseProgram"));
    glGetUniformLocationFn = reinterpret_cast<GLGetUniformLocation>(load("glGetUniformLocation"));
    glUniform1iFn = reinterpret_cast<GLUniform1i>(load("glUniform1i"));
    glUniform1fFn = reinterpret_cast<GLUniform1f>(load("glUniform1f"));
    glUniform2fFn = reinterpret_cast<GLUniform2f>(load("glUniform2f"));
    glUniform4fFn = reinterpret_cast<GLUniform4f>(load("glUniform4f"));
    glGenTexturesFn = reinterpret_cast<GLGen>(GetProcAddress(GetModuleHandleA("opengl32.dll"), "glGenTextures"));
    glBindTextureFn = reinterpret_cast<GLBindTexture>(GetProcAddress(GetModuleHandleA("opengl32.dll"), "glBindTexture"));
    glTexImage2DFn = reinterpret_cast<GLTexImage>(GetProcAddress(GetModuleHandleA("opengl32.dll"), "glTexImage2D"));
    glTexParameteriFn = reinterpret_cast<GLTexParam>(GetProcAddress(GetModuleHandleA("opengl32.dll"), "glTexParameteri"));
    glActiveTextureFn = reinterpret_cast<GLActiveTexture>(load("glActiveTexture"));
    glGenFramebuffersFn = reinterpret_cast<GLGenFb>(load("glGenFramebuffers"));
    glBindFramebufferFn = reinterpret_cast<GLBindFb>(load("glBindFramebuffer"));
    glFramebufferTexture2DFn = reinterpret_cast<GLFbTexture>(load("glFramebufferTexture2D"));
    glCheckFramebufferStatusFn = reinterpret_cast<GLCheckFb>(load("glCheckFramebufferStatus"));
    glViewportFn = reinterpret_cast<GLViewport>(GetProcAddress(GetModuleHandleA("opengl32.dll"), "glViewport"));
    glClearColorFn = reinterpret_cast<GLClearColor>(GetProcAddress(GetModuleHandleA("opengl32.dll"), "glClearColor"));
    glClearFn = reinterpret_cast<GLClear>(GetProcAddress(GetModuleHandleA("opengl32.dll"), "glClear"));
    glEnableVertexAttribArrayFn = reinterpret_cast<GLEnableAttrib>(load("glEnableVertexAttribArray"));
    glDisableVertexAttribArrayFn = reinterpret_cast<GLDisableAttrib>(load("glDisableVertexAttribArray"));
    glVertexAttribPointerFn = reinterpret_cast<GLAttribPointer>(load("glVertexAttribPointer"));
    glDrawArraysFn = reinterpret_cast<GLDrawArrays>(GetProcAddress(GetModuleHandleA("opengl32.dll"), "glDrawArrays"));
    glReadPixelsFn = reinterpret_cast<GLReadPixels>(GetProcAddress(GetModuleHandleA("opengl32.dll"), "glReadPixels"));
    glPixelStoreiFn = reinterpret_cast<GLPixelStore>(GetProcAddress(GetModuleHandleA("opengl32.dll"), "glPixelStorei"));
    glGetActiveUniformFn = reinterpret_cast<GLGetActiveUniform>(load("glGetActiveUniform"));
    glDeleteTexturesFn = reinterpret_cast<GLDelete>(GetProcAddress(GetModuleHandleA("opengl32.dll"), "glDeleteTextures"));
    glDeleteFramebuffersFn = reinterpret_cast<GLDelete>(load("glDeleteFramebuffers"));
    glDeleteProgramFn = reinterpret_cast<GLDeleteProgram>(load("glDeleteProgram"));
    glDeleteShaderFn = reinterpret_cast<GLVoidUInt>(load("glDeleteShader"));
    glGetIntegervFn = reinterpret_cast<GLGetIntegerv>(GetProcAddress(GetModuleHandleA("opengl32.dll"), "glGetIntegerv"));
    glGetStringFn = reinterpret_cast<GLGetString>(GetProcAddress(GetModuleHandleA("opengl32.dll"), "glGetString"));
    return glCreateShaderFn && glShaderSourceFn && glCompileShaderFn && glCreateProgramFn
        && glLinkProgramFn && glUseProgramFn && glGenTexturesFn && glTexImage2DFn
        && glGenFramebuffersFn && glFramebufferTexture2DFn && glReadPixelsFn && glDrawArraysFn
        && glUniform1fFn && glUniform4fFn && glGetUniformLocationFn;
}

bool makeCurrent() {
    return g_ready && g_dc && g_context && wglMakeCurrent(g_dc, g_context) == TRUE;
}

void doneCurrent() {
    wglMakeCurrent(nullptr, nullptr);
}

unsigned compileStage(unsigned type, const std::string& source, std::string* error) {
    const unsigned shader = glCreateShaderFn(type);
    const char* text = source.c_str();
    glShaderSourceFn(shader, 1, &text, nullptr);
    glCompileShaderFn(shader);
    int status = 0;
    glGetShaderivFn(shader, kGlCompileStatus, &status);
    if (status) return shader;
    int length = 0;
    glGetShaderivFn(shader, kGlInfoLogLength, &length);
    std::string log(static_cast<std::size_t>(std::max(length, 1)), '\0');
    glGetShaderInfoLogFn(shader, length, nullptr, log.data());
    glDeleteShaderFn(shader);
    *error = log;
    return 0;
}

struct Varying {
    std::string type;
    std::string name;
};

std::vector<Varying> fragmentVaryings(const std::string& source) {
    std::vector<Varying> varyings;
    std::istringstream input(stripComments(source));
    std::string line;
    while (std::getline(input, line)) {
        const std::string clean = trim(line);
        const auto varying = clean.find("varying");
        if (varying == std::string::npos || clean.find(';') == std::string::npos) continue;
        if (varying > 0 && (std::isalnum(static_cast<unsigned char>(clean[varying - 1])) || clean[varying - 1] == '_')) continue;
        std::string declaration = clean.substr(varying + 7);
        const auto semicolon = declaration.find(';');
        if (semicolon == std::string::npos) continue;
        declaration.resize(semicolon);
        std::istringstream tokens(declaration);
        std::string type;
        std::string name;
        tokens >> type >> name;
        if (type == "highp" || type == "mediump" || type == "lowp") {
            type = name;
            tokens >> name;
        }
        if (name.empty()) continue;
        if (type != "float" && type != "vec2" && type != "vec3" && type != "vec4") continue;
        varyings.push_back({type, name});
    }
    return varyings;
}

std::string buildVertex(const std::vector<Varying>& varyings) {
    std::ostringstream vertex;
    vertex << "#version 100\nprecision mediump float;\n"
              "attribute vec2 a_position;\nattribute vec2 a_texcoord;\nuniform vec4 u_uvRect;\n";
    for (const auto& varying : varyings) vertex << "varying " << varying.type << " " << varying.name << ";\n";
    vertex << "void main() {\n"
              "    gl_Position = vec4(a_position, 0.0, 1.0);\n"
              "    vec2 rpeUv = vec2(mix(u_uvRect.x, u_uvRect.z, a_texcoord.x), mix(u_uvRect.y, u_uvRect.w, a_texcoord.y));\n";
    for (const auto& varying : varyings) {
        if (varying.type == "vec2") vertex << "    " << varying.name << " = rpeUv;\n";
        else if (varying.type == "vec3") vertex << "    " << varying.name << " = vec3(rpeUv, 0.0);\n";
        else if (varying.type == "vec4") vertex << "    " << varying.name << " = vec4(1.0);\n";
        else vertex << "    " << varying.name << " = 0.0;\n";
    }
    vertex << "}\n";
    return vertex.str();
}

std::string prepareFragment(std::string source) {
    source.erase(std::remove(source.begin(), source.end(), '\r'), source.end());
    if (source.find("#version") == std::string::npos) source = "#version 100\n" + source;
    if (source.find("precision ") == std::string::npos) {
        const auto line = source.find('\n');
        source.insert(line == std::string::npos ? source.size() : line + 1, "precision mediump float;\n");
    }
    return source;
}

int componentsForType(unsigned type) {
    if (type == GL_FLOAT) return 1;
    if (type == kGlFloatVec2) return 2;
    if (type == kGlFloatVec3) return 3;
    if (type == kGlFloatVec4) return 4;
    return 0;
}

void releaseStaging() {
    if (g_staging) g_staging->Release();
    g_staging = nullptr;
    g_stagingWidth = 0;
    g_stagingHeight = 0;
    g_stagingFormat = DXGI_FORMAT_UNKNOWN;
}

ID3D11Texture2D* ensureStaging(ID3D11Device* device, int width, int height, DXGI_FORMAT format) {
    if (g_staging && g_stagingWidth == width && g_stagingHeight == height && g_stagingFormat == format) return g_staging;
    releaseStaging();
    D3D11_TEXTURE2D_DESC desc{};
    desc.Width = static_cast<UINT>(width);
    desc.Height = static_cast<UINT>(height);
    desc.MipLevels = 1;
    desc.ArraySize = 1;
    desc.Format = format;
    desc.SampleDesc.Count = 1;
    desc.Usage = D3D11_USAGE_STAGING;
    desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    if (FAILED(device->CreateTexture2D(&desc, nullptr, &g_staging))) {
        g_staging = nullptr;
        return nullptr;
    }
    g_stagingWidth = width;
    g_stagingHeight = height;
    g_stagingFormat = format;
    return g_staging;
}

unsigned glFormatFor(DXGI_FORMAT format) {
    if (format == DXGI_FORMAT_B8G8R8A8_UNORM || format == DXGI_FORMAT_B8G8R8A8_UNORM_SRGB) return kGlBgra;
    if (format == DXGI_FORMAT_R8G8B8A8_UNORM || format == DXGI_FORMAT_R8G8B8A8_UNORM_SRGB) return GL_RGBA;
    return 0;
}

bool ensureSourceTexture(int width, int height, unsigned format) {
    if (g_sourceTexture && g_sourceWidth == width && g_sourceHeight == height && g_sourceFormat == format) return true;
    if (g_sourceTexture) glDeleteTexturesFn(1, &g_sourceTexture);
    glGenTexturesFn(1, &g_sourceTexture);
    glBindTextureFn(GL_TEXTURE_2D, g_sourceTexture);
    glTexParameteriFn(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteriFn(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteriFn(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, kGlClampToEdge);
    glTexParameteriFn(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, kGlClampToEdge);
    g_sourceWidth = width;
    g_sourceHeight = height;
    g_sourceFormat = format;
    return g_sourceTexture != 0;
}

bool ensureTarget(int width, int height) {
    if (g_targetTexture && g_targetWidth == width && g_targetHeight == height && g_fbo) return true;
    if (g_targetTexture) glDeleteTexturesFn(1, &g_targetTexture);
    if (!g_fbo) glGenFramebuffersFn(1, &g_fbo);
    glGenTexturesFn(1, &g_targetTexture);
    glBindTextureFn(GL_TEXTURE_2D, g_targetTexture);
    glTexParameteriFn(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteriFn(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexImage2DFn(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    glBindFramebufferFn(kGlFramebuffer, g_fbo);
    glFramebufferTexture2DFn(kGlFramebuffer, kGlColorAttachment0, GL_TEXTURE_2D, g_targetTexture, 0);
    g_targetWidth = width;
    g_targetHeight = height;
    return glCheckFramebufferStatusFn(kGlFramebuffer) == kGlFramebufferComplete;
}

void uploadUniform(const UniformRecord& uniform) {
    if (uniform.location < 0) return;
    if (uniform.components <= 1) glUniform1fFn(uniform.location, uniform.values[0]);
    else if (uniform.components == 2) glUniform2fFn(uniform.location, uniform.values[0], uniform.values[1]);
    else glUniform4fFn(uniform.location, uniform.values[0], uniform.values[1], uniform.values[2], uniform.values[3]);
}

} // namespace

bool rpe_gles_startup() {
    rpe_gles_shutdown();
    WNDCLASSW windowClass{};
    windowClass.lpfnWndProc = windowProc;
    windowClass.hInstance = GetModuleHandleW(nullptr);
    windowClass.lpszClassName = L"PhiRRDirectGlsl";
    RegisterClassW(&windowClass);
    g_window = CreateWindowExW(0, windowClass.lpszClassName, L"PhiRRDirectGlsl", WS_POPUP,
        0, 0, 32, 32, nullptr, nullptr, windowClass.hInstance, nullptr);
    if (!g_window) {
        setError("Direct GLSL ES could not create its OpenGL window.");
        return false;
    }
    g_dc = GetDC(g_window);
    PIXELFORMATDESCRIPTOR format{};
    format.nSize = sizeof(format);
    format.nVersion = 1;
    format.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
    format.iPixelType = PFD_TYPE_RGBA;
    format.cColorBits = 32;
    const int pixelFormat = ChoosePixelFormat(g_dc, &format);
    if (!pixelFormat || !SetPixelFormat(g_dc, pixelFormat, &format)) {
        setError("Direct GLSL ES could not choose an OpenGL pixel format.");
        rpe_gles_shutdown();
        return false;
    }
    HGLRC legacy = wglCreateContext(g_dc);
    if (!legacy || !wglMakeCurrent(g_dc, legacy)) {
        setError("Direct GLSL ES could not create a legacy OpenGL context.");
        if (legacy) wglDeleteContext(legacy);
        rpe_gles_shutdown();
        return false;
    }
    auto createAttribs = reinterpret_cast<CreateContextAttribs>(wglGetProcAddress("wglCreateContextAttribsARB"));
    if (!createAttribs) {
        wglMakeCurrent(nullptr, nullptr);
        wglDeleteContext(legacy);
        setError("OpenGL has no compatibility context. Direct GLSL ES is unavailable.");
        rpe_gles_shutdown();
        return false;
    }
    const int attribs[] = {
        WGL_CONTEXT_MAJOR_VERSION_ARB, 4,
        WGL_CONTEXT_MINOR_VERSION_ARB, 1,
        WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB,
        0
    };
    g_context = createAttribs(g_dc, nullptr, attribs);
    wglMakeCurrent(nullptr, nullptr);
    wglDeleteContext(legacy);
    if (!g_context || !wglMakeCurrent(g_dc, g_context) || !loadGl()) {
        setError("Direct GLSL ES could not create an OpenGL 4.1 compatibility context.");
        rpe_gles_shutdown();
        return false;
    }
    const unsigned char* extensions = glGetStringFn ? glGetStringFn(GL_EXTENSIONS) : nullptr;
    if (!extensions || !std::strstr(reinterpret_cast<const char*>(extensions), "GL_ARB_ES2_compatibility")) {
        setError("OpenGL is missing GL_ARB_ES2_compatibility, so GLSL ES 1.00 cannot be compiled directly.");
        rpe_gles_shutdown();
        return false;
    }
    g_ready = true;
    doneCurrent();
    setError({});
    return true;
}

void rpe_gles_shutdown() {
    if (g_dc && g_context) wglMakeCurrent(g_dc, g_context);
    if (g_ready) {
        for (auto& [handle, record] : g_shaders) {
            (void)handle;
            if (record && record->program && glDeleteProgramFn) glDeleteProgramFn(record->program);
        }
        if (g_sourceTexture && glDeleteTexturesFn) glDeleteTexturesFn(1, &g_sourceTexture);
        if (g_targetTexture && glDeleteTexturesFn) glDeleteTexturesFn(1, &g_targetTexture);
        if (g_fbo && glDeleteFramebuffersFn) glDeleteFramebuffersFn(1, &g_fbo);
    }
    g_shaders.clear();
    g_sourceTexture = 0;
    g_targetTexture = 0;
    g_fbo = 0;
    g_sourceWidth = g_sourceHeight = g_targetWidth = g_targetHeight = 0;
    g_ready = false;
    wglMakeCurrent(nullptr, nullptr);
    if (g_context) wglDeleteContext(g_context);
    g_context = nullptr;
    if (g_window && g_dc) ReleaseDC(g_window, g_dc);
    g_dc = nullptr;
    if (g_window) DestroyWindow(g_window);
    g_window = nullptr;
    releaseStaging();
}

bool rpe_gles_available() { return g_ready; }

bool hasGlslCall(std::string_view source, std::string_view token) {
    std::size_t position = 0;
    while ((position = source.find(token, position)) != std::string_view::npos) {
        const bool identifierBefore = position > 0
            && (std::isalnum(static_cast<unsigned char>(source[position - 1])) || source[position - 1] == '_');
        if (!identifierBefore) return true;
        position += token.size();
    }
    return false;
}

bool rpe_gles_is_source(std::string_view source) {
    // YoYo's HLSL names its sampler helper gl_texture2D(). That contains the
    // substring texture2D(, but it is already HLSL and must stay on D3DCompile.
    if (source.find("cbuffer") != std::string_view::npos
        || source.find("SV_Target") != std::string_view::npos
        || source.find("SV_TARGET") != std::string_view::npos
        || source.find(": register(") != std::string_view::npos
        || source.find("Texture2D") != std::string_view::npos
        || source.find("SamplerState") != std::string_view::npos
        || source.find("gl_texture2D") != std::string_view::npos) return false;
    return source.find("gl_FragColor") != std::string_view::npos
        || hasGlslCall(source, "texture2D(")
        || source.find("#version 100") != std::string_view::npos;
}

std::int32_t rpe_gles_compile(std::string_view source, std::string_view sourceName) {
    (void)sourceName;
    if (!makeCurrent()) {
        setError("Direct GLSL ES compiler is not initialized.");
        return -1;
    }
    const std::string fragment = prepareFragment(std::string(source));
    const auto varyings = fragmentVaryings(fragment);
    std::string error;
    const unsigned fragmentShader = compileStage(kGlFragmentShader, fragment, &error);
    if (!fragmentShader) {
        doneCurrent();
        setError("GLSL ES fragment compile failed: " + error);
        return -1;
    }
    const unsigned vertexShader = compileStage(kGlVertexShader, buildVertex(varyings), &error);
    if (!vertexShader) {
        glDeleteShaderFn(fragmentShader);
        doneCurrent();
        setError("GLSL ES vertex compile failed: " + error);
        return -1;
    }
    const unsigned program = glCreateProgramFn();
    glAttachShaderFn(program, vertexShader);
    glAttachShaderFn(program, fragmentShader);
    glBindAttribLocationFn(program, 0, "a_position");
    glBindAttribLocationFn(program, 1, "a_texcoord");
    glLinkProgramFn(program);
    glDeleteShaderFn(vertexShader);
    glDeleteShaderFn(fragmentShader);
    int linked = 0;
    glGetProgramivFn(program, kGlLinkStatus, &linked);
    if (!linked) {
        int length = 0;
        glGetProgramivFn(program, kGlInfoLogLength, &length);
        std::string log(static_cast<std::size_t>(std::max(length, 1)), '\0');
        glGetProgramInfoLogFn(program, length, nullptr, log.data());
        glDeleteProgramFn(program);
        doneCurrent();
        setError("GLSL ES link failed: " + log);
        return -1;
    }
    auto record = std::make_unique<ShaderRecord>();
    record->program = program;
    record->uvRectLocation = glGetUniformLocationFn(program, "u_uvRect");
    int uniformCount = 0;
    glGetProgramivFn(program, 0x8B86, &uniformCount); // GL_ACTIVE_UNIFORMS
    for (int index = 0; index < uniformCount; ++index) {
        char name[128] = {};
        int length = 0;
        int size = 0;
        unsigned type = 0;
        glGetActiveUniformFn(program, static_cast<unsigned>(index), sizeof(name) - 1, &length, &size, &type, name);
        if (type == kGlSampler2D) {
            glUseProgramFn(program);
            glUniform1iFn(glGetUniformLocationFn(program, name), 0);
            continue;
        }
        const int components = componentsForType(type);
        if (components <= 0 || name[0] == '\0' || std::strcmp(name, "u_uvRect") == 0) continue;
        UniformRecord uniform;
        uniform.location = glGetUniformLocationFn(program, name);
        uniform.components = components;
        record->uniforms[name] = uniform;
    }
    glUseProgramFn(0);
    const int handle = g_nextHandle++;
    g_shaders.emplace(handle, std::move(record));
    doneCurrent();
    setError({});
    return handle;
}

bool rpe_gles_set_uniform(std::int32_t handle, std::string_view name, std::int32_t component, float value) {
    const auto shaderIt = g_shaders.find(handle);
    if (shaderIt == g_shaders.end() || name.empty() || component < 0 || component > 3) return false;
    const std::string uniformName(name);
    auto uniformIt = shaderIt->second->uniforms.find(uniformName);
    if (uniformIt == shaderIt->second->uniforms.end() && !uniformName.empty() && uniformName[0] == '_') {
        uniformIt = shaderIt->second->uniforms.find(uniformName.substr(1));
    }
    if (uniformIt == shaderIt->second->uniforms.end()) {
        uniformIt = shaderIt->second->uniforms.find("_" + uniformName);
    }
    if (uniformIt == shaderIt->second->uniforms.end()) return false;
    if (component >= uniformIt->second.components) return false;
    uniformIt->second.values[component] = value;
    return true;
}

std::int32_t rpe_gles_draw(ID3D11Device* device, ID3D11DeviceContext* context, std::int32_t handle,
    float uvLeft, float uvTop, float uvRight, float uvBottom,
    std::int32_t* targetWidth, std::int32_t* targetHeight) {
    const auto shaderIt = g_shaders.find(handle);
    if (!device || !context || shaderIt == g_shaders.end()) {
        setError("Direct GLSL ES draw failed: backend or handle is invalid.");
        return 0;
    }
    ID3D11ShaderResourceView* sourceView = rpeSnapshotRenderTarget();
    ID3D11RenderTargetView* targetView = nullptr;
    context->OMGetRenderTargets(1, &targetView, nullptr);
    if (!sourceView || !targetView) {
        if (sourceView) sourceView->Release();
        if (targetView) targetView->Release();
        setError("Direct GLSL ES draw failed: D3D11 source or target is not bound.");
        return 0;
    }
    ID3D11Resource* sourceResource = nullptr;
    ID3D11Resource* targetResource = nullptr;
    sourceView->GetResource(&sourceResource);
    targetView->GetResource(&targetResource);
    ID3D11Texture2D* sourceTexture = nullptr;
    ID3D11Texture2D* targetTexture = nullptr;
    if (sourceResource) sourceResource->QueryInterface(__uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&sourceTexture));
    if (targetResource) targetResource->QueryInterface(__uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&targetTexture));
    if (sourceResource) sourceResource->Release();
    if (targetResource) targetResource->Release();
    if (!sourceTexture || !targetTexture) {
        if (sourceTexture) sourceTexture->Release();
        if (targetTexture) targetTexture->Release();
        sourceView->Release();
        targetView->Release();
        setError("Direct GLSL ES draw failed: bound resources are not 2D textures.");
        return 0;
    }
    D3D11_TEXTURE2D_DESC sourceDesc{};
    D3D11_TEXTURE2D_DESC targetDesc{};
    sourceTexture->GetDesc(&sourceDesc);
    targetTexture->GetDesc(&targetDesc);
    if (targetWidth) *targetWidth = static_cast<std::int32_t>(targetDesc.Width);
    if (targetHeight) *targetHeight = static_cast<std::int32_t>(targetDesc.Height);
    const unsigned uploadFormat = glFormatFor(sourceDesc.Format);
    if (!uploadFormat || glFormatFor(targetDesc.Format) == 0) {
        sourceTexture->Release();
        targetTexture->Release();
        sourceView->Release();
        targetView->Release();
        setError("Direct GLSL ES draw failed: only RGBA8 and BGRA8 targets are supported.");
        return 0;
    }
    ID3D11Texture2D* readable = sourceTexture;
    ID3D11Texture2D* resolved = nullptr;
    if (sourceDesc.SampleDesc.Count > 1) {
        D3D11_TEXTURE2D_DESC resolvedDesc = sourceDesc;
        resolvedDesc.SampleDesc.Count = 1;
        resolvedDesc.SampleDesc.Quality = 0;
        resolvedDesc.BindFlags = D3D11_BIND_SHADER_RESOURCE;
        resolvedDesc.MiscFlags = 0;
        if (FAILED(device->CreateTexture2D(&resolvedDesc, nullptr, &resolved))) {
            sourceTexture->Release();
            targetTexture->Release();
            sourceView->Release();
            targetView->Release();
            setError("Direct GLSL ES draw failed: could not resolve a multisampled source.");
            return 0;
        }
        context->ResolveSubresource(resolved, 0, sourceTexture, 0, sourceDesc.Format);
        readable = resolved;
    }
    ID3D11Texture2D* staging = ensureStaging(device, static_cast<int>(sourceDesc.Width),
        static_cast<int>(sourceDesc.Height), sourceDesc.Format);
    if (!staging) {
        if (resolved) resolved->Release();
        sourceTexture->Release();
        targetTexture->Release();
        sourceView->Release();
        targetView->Release();
        setError("Direct GLSL ES draw failed: could not create a staging texture.");
        return 0;
    }
    context->CopyResource(staging, readable);
    D3D11_MAPPED_SUBRESOURCE mapped{};
    if (FAILED(context->Map(staging, 0, D3D11_MAP_READ, 0, &mapped)) || !mapped.pData) {
        if (resolved) resolved->Release();
        sourceTexture->Release();
        targetTexture->Release();
        sourceView->Release();
        targetView->Release();
        setError("Direct GLSL ES draw failed: staging map failed.");
        return 0;
    }

    const int viewX = std::clamp(static_cast<int>(std::floor(std::min(uvLeft, uvRight) * targetDesc.Width)), 0, static_cast<int>(targetDesc.Width));
    const int viewY = std::clamp(static_cast<int>(std::floor(std::min(uvTop, uvBottom) * targetDesc.Height)), 0, static_cast<int>(targetDesc.Height));
    const int viewRight = std::clamp(static_cast<int>(std::ceil(std::max(uvLeft, uvRight) * targetDesc.Width)), 0, static_cast<int>(targetDesc.Width));
    const int viewBottom = std::clamp(static_cast<int>(std::ceil(std::max(uvTop, uvBottom) * targetDesc.Height)), 0, static_cast<int>(targetDesc.Height));
    const int viewW = viewRight - viewX;
    const int viewH = viewBottom - viewY;
    if (viewW <= 0 || viewH <= 0) {
        context->Unmap(staging, 0);
        if (resolved) resolved->Release();
        sourceTexture->Release();
        targetTexture->Release();
        sourceView->Release();
        targetView->Release();
        setError("Direct GLSL ES draw skipped: empty viewport.");
        return 0;
    }
    if (!makeCurrent() || !ensureSourceTexture(static_cast<int>(sourceDesc.Width), static_cast<int>(sourceDesc.Height), uploadFormat)
        || !ensureTarget(viewW, viewH)) {
        context->Unmap(staging, 0);
        if (resolved) resolved->Release();
        sourceTexture->Release();
        targetTexture->Release();
        sourceView->Release();
        targetView->Release();
        if (g_error.empty()) setError("Direct GLSL ES draw failed: OpenGL target allocation failed.");
        doneCurrent();
        return 0;
    }
    glPixelStoreiFn(GL_UNPACK_ALIGNMENT, 1);
    glPixelStoreiFn(kGlUnpackRowLength, static_cast<int>(mapped.RowPitch / 4));
    glBindTextureFn(GL_TEXTURE_2D, g_sourceTexture);
    glTexImage2DFn(GL_TEXTURE_2D, 0, GL_RGBA, static_cast<int>(sourceDesc.Width), static_cast<int>(sourceDesc.Height),
        0, uploadFormat, GL_UNSIGNED_BYTE, mapped.pData);
    glPixelStoreiFn(kGlUnpackRowLength, 0);
    context->Unmap(staging, 0);

    ShaderRecord& record = *shaderIt->second;
    auto screenSize = record.uniforms.find("screenSize");
    if (screenSize == record.uniforms.end()) screenSize = record.uniforms.find("_screenSize");
    if (screenSize != record.uniforms.end()) {
        screenSize->second.values[0] = static_cast<float>(viewW);
        screenSize->second.values[1] = static_cast<float>(viewH);
    }
    auto bounds = record.uniforms.find("_rpeTextureBounds");
    if (bounds == record.uniforms.end()) bounds = record.uniforms.find("rpeTextureBounds");
    if (bounds != record.uniforms.end()) {
        bounds->second.values[0] = uvLeft;
        bounds->second.values[1] = uvTop;
        bounds->second.values[2] = uvRight;
        bounds->second.values[3] = uvBottom;
    }

    glBindFramebufferFn(kGlFramebuffer, g_fbo);
    glViewportFn(0, 0, viewW, viewH);
    glDisable(GL_BLEND);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glDisable(GL_SCISSOR_TEST);
    glUseProgramFn(record.program);
    if (record.uvRectLocation >= 0) glUniform4fFn(record.uvRectLocation, uvLeft, uvTop, uvRight, uvBottom);
    for (const auto& [name, uniform] : record.uniforms) {
        (void)name;
        uploadUniform(uniform);
    }
    glActiveTextureFn(kGlTexture0);
    glBindTextureFn(GL_TEXTURE_2D, g_sourceTexture);
    // a_texcoord.y is 0 at the top. Uploaded D3D rows put the top row at GL v=0.
    const float quad[] = {
        -1.f, 1.f, 0.f, 0.f,
        1.f, 1.f, 1.f, 0.f,
        -1.f, -1.f, 0.f, 1.f,
        1.f, -1.f, 1.f, 1.f
    };
    glEnableVertexAttribArrayFn(0);
    glEnableVertexAttribArrayFn(1);
    glVertexAttribPointerFn(0, 2, GL_FLOAT, 0, 16, quad);
    glVertexAttribPointerFn(1, 2, GL_FLOAT, 0, 16, quad + 2);
    glDrawArraysFn(GL_TRIANGLE_STRIP, 0, 4);
    std::vector<unsigned char> readback(static_cast<std::size_t>(viewW) * static_cast<std::size_t>(viewH) * 4);
    glPixelStoreiFn(GL_PACK_ALIGNMENT, 1);
    glReadPixelsFn(0, 0, viewW, viewH, glFormatFor(targetDesc.Format), GL_UNSIGNED_BYTE, readback.data());
    glDisableVertexAttribArrayFn(0);
    glDisableVertexAttribArrayFn(1);
    glBindFramebufferFn(kGlFramebuffer, 0);
    glUseProgramFn(0);
    doneCurrent();

    std::vector<unsigned char> flipped(readback.size());
    const std::size_t stride = static_cast<std::size_t>(viewW) * 4;
    for (int row = 0; row < viewH; ++row) {
        std::memcpy(flipped.data() + static_cast<std::size_t>(row) * stride,
            readback.data() + static_cast<std::size_t>(viewH - 1 - row) * stride, stride);
    }
    D3D11_BOX box{};
    box.left = static_cast<UINT>(viewX);
    box.top = static_cast<UINT>(viewY);
    box.right = static_cast<UINT>(viewRight);
    box.bottom = static_cast<UINT>(viewBottom);
    box.front = 0;
    box.back = 1;
    context->UpdateSubresource(targetTexture, 0, &box, flipped.data(), static_cast<UINT>(stride), 0);
    if (resolved) resolved->Release();
    sourceTexture->Release();
    targetTexture->Release();
    sourceView->Release();
    targetView->Release();
    setError({});
    return 7;
}

bool rpe_gles_release(std::int32_t handle) {
    const auto shaderIt = g_shaders.find(handle);
    if (shaderIt == g_shaders.end()) return false;
    if (makeCurrent() && shaderIt->second->program && glDeleteProgramFn) glDeleteProgramFn(shaderIt->second->program);
    doneCurrent();
    g_shaders.erase(shaderIt);
    return true;
}

std::string rpe_gles_last_error() { return g_error; }

#ifdef RPE_GLES_SELF_TEST
#include <cstdio>
int main() {
    FILE* log = nullptr;
    freopen_s(&log, "C:\\Users\\Administrator\\AppData\\Local\\Temp\\gles_self_test.log", "w", stdout);
    setvbuf(stdout, nullptr, _IONBF, 0);
    if (!rpe_gles_startup()) {
        std::printf("startup failed: %s\n", rpe_gles_last_error().c_str());
        return 1;
    }
    ID3D11Device* device = nullptr;
    ID3D11DeviceContext* context = nullptr;
    if (FAILED(D3D11CreateDevice(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, D3D11_CREATE_DEVICE_BGRA_SUPPORT,
            nullptr, 0, D3D11_SDK_VERSION, &device, nullptr, &context))) {
        std::printf("d3d failed\n");
        return 2;
    }
    const unsigned pixels[4] = {0xFF0000FFu, 0xFF00FF00u, 0xFFFF0000u, 0xFFFFFFFFu};
    D3D11_TEXTURE2D_DESC desc{};
    desc.Width = 2;
    desc.Height = 2;
    desc.MipLevels = 1;
    desc.ArraySize = 1;
    desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    desc.SampleDesc.Count = 1;
    desc.Usage = D3D11_USAGE_DEFAULT;
    desc.BindFlags = D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_RENDER_TARGET;
    D3D11_SUBRESOURCE_DATA data{};
    data.pSysMem = pixels;
    data.SysMemPitch = 8;
    ID3D11Texture2D* source = nullptr;
    ID3D11Texture2D* target = nullptr;
    device->CreateTexture2D(&desc, &data, &source);
    device->CreateTexture2D(&desc, nullptr, &target);
    ID3D11ShaderResourceView* srv = nullptr;
    ID3D11RenderTargetView* rtv = nullptr;
    device->CreateShaderResourceView(source, nullptr, &srv);
    device->CreateRenderTargetView(target, nullptr, &rtv);
    context->PSSetShaderResources(0, 1, &srv);
    context->OMSetRenderTargets(1, &rtv, nullptr);
    const char* fragment = R"(precision mediump float;
varying vec2 uv;
uniform sampler2D screenTexture;
void main() { gl_FragColor = texture2D(screenTexture, uv); }
)";
    const int handle = rpe_gles_compile(fragment, "self");
    std::printf("compile=%d error=%s\n", handle, rpe_gles_last_error().c_str());
    std::int32_t width = 0;
    std::int32_t height = 0;
    const int draw = rpe_gles_draw(device, context, handle, 0, 0, 1, 1, &width, &height);
    std::printf("draw=%d %dx%d error=%s\n", draw, width, height, rpe_gles_last_error().c_str());
    desc.Usage = D3D11_USAGE_STAGING;
    desc.BindFlags = 0;
    desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    ID3D11Texture2D* stage = nullptr;
    device->CreateTexture2D(&desc, nullptr, &stage);
    context->CopyResource(stage, target);
    D3D11_MAPPED_SUBRESOURCE mapped{};
    context->Map(stage, 0, D3D11_MAP_READ, 0, &mapped);
    const auto* out = static_cast<const unsigned char*>(mapped.pData);
    std::printf("top-left BGRA=%u,%u,%u,%u\n", out[0], out[1], out[2], out[3]);
    std::printf("top-right BGRA=%u,%u,%u,%u\n", out[4], out[5], out[6], out[7]);
    const auto* row1 = out + mapped.RowPitch;
    std::printf("bottom-left BGRA=%u,%u,%u,%u\n", row1[0], row1[1], row1[2], row1[3]);
    std::printf("bottom-right BGRA=%u,%u,%u,%u\n", row1[4], row1[5], row1[6], row1[7]);
    const bool ok = out[0] == 255 && out[1] == 0 && out[2] == 0 && out[3] == 255
        && out[4] == 0 && out[5] == 255 && out[6] == 0
        && row1[0] == 0 && row1[1] == 0 && row1[2] == 255
        && row1[4] == 255 && row1[5] == 255 && row1[6] == 255;
    std::printf("match=%d\n", ok ? 1 : 0);
    context->Unmap(stage, 0);
    rpe_gles_shutdown();
    return ok ? 0 : 3;
}
#endif
