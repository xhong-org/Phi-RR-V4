#include "native/IShadersInternal_native.h"

#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <memory>
#include <mutex>
#include <regex>
#include <sstream>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

#ifndef GL_READ_FRAMEBUFFER
#define GL_READ_FRAMEBUFFER 0x8CA8
#endif
#ifndef GL_DRAW_FRAMEBUFFER
#define GL_DRAW_FRAMEBUFFER 0x8CA9
#endif

namespace {

struct UniformRecord {
    GLint location = -1;
    int components = 4;
    float values[4] = {0.0f, 0.0f, 0.0f, 0.0f};
};

struct ShaderRecord {
    GLuint program = 0;
    GLint uvRectLocation = -1;
    GLint yFlipLocation = -1;
    GLint texScaleLocation = -1;
    GLint textureLocation = -1;
    std::unordered_map<std::string, UniformRecord> uniforms;
};

std::recursive_mutex g_mutex;
std::string g_error;
std::string g_translatedSource;
bool g_ready = false;
GLuint g_quadVbo = 0;
GLuint g_vao = 0;
GLuint g_inputTexture = 0;
GLuint g_blitFbo = 0;
int g_nextHandle = 1;
std::unordered_map<int, std::unique_ptr<ShaderRecord>> g_shaders;
std::int32_t g_lastTargetWidth = 0;
std::int32_t g_lastTargetHeight = 0;
bool g_inputCaptured = false;
bool g_inputYFlipped = false;
GLint g_lastCaptureFbo = 0;
const char* g_lastCaptureMethod = "none";
GLint g_potWidth = 0;
GLint g_potHeight = 0;
float g_texScaleX = 1.0f;
float g_texScaleY = 1.0f;
GLint g_lastCopyX = 0;
GLint g_lastCopyY = 0;

using BindVertexArrayFn = void (*)(GLuint);
using GenVertexArraysFn = void (*)(GLsizei, GLuint*);
using DeleteVertexArraysFn = void (*)(GLsizei, const GLuint*);
using BlitFramebufferFn = void (*)(GLint, GLint, GLint, GLint, GLint, GLint, GLint, GLint, GLbitfield, GLenum);

BindVertexArrayFn bindVertexArrayFn() {
    static BindVertexArrayFn fn = reinterpret_cast<BindVertexArrayFn>(
        eglGetProcAddress("glBindVertexArray"));
    if (!fn) {
        fn = reinterpret_cast<BindVertexArrayFn>(
            eglGetProcAddress("glBindVertexArrayOES"));
    }
    return fn;
}

BlitFramebufferFn blitFramebufferFn() {
    static BlitFramebufferFn fn = nullptr;
    static bool resolved = false;
    if (!resolved) {
        resolved = true;
        fn = reinterpret_cast<BlitFramebufferFn>(eglGetProcAddress("glBlitFramebuffer"));
        if (!fn) fn = reinterpret_cast<BlitFramebufferFn>(eglGetProcAddress("glBlitFramebufferANGLE"));
        if (!fn) fn = reinterpret_cast<BlitFramebufferFn>(eglGetProcAddress("glBlitFramebufferEXT"));
    }
    return fn;
}

void setError(std::string message) {
    g_error = std::move(message);
}

std::string replaceAll(std::string value, const std::string& from, const std::string& to) {
    std::size_t position = 0;
    while ((position = value.find(from, position)) != std::string::npos) {
        value.replace(position, from.size(), to);
        position += to.size();
    }
    return value;
}

std::string trim(const std::string& value) {
    const auto start = value.find_first_not_of(" \t\r\n");
    if (start == std::string::npos) return {};
    const auto end = value.find_last_not_of(" \t\r\n");
    return value.substr(start, end - start + 1);
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
    std::smatch lineMatch;
    if (std::regex_search(log, lineMatch, std::regex(R"(0:(\d+):)"))) {
        const int failLine = std::stoi(lineMatch[1].str());
        std::istringstream listing(source);
        std::string listed;
        int listedIndex = 1;
        while (std::getline(listing, listed)) {
            if (listedIndex == failLine) {
                log += " | source: " + listed;
                break;
            }
            ++listedIndex;
        }
    }
    *error = log;
    return 0;
}

void destroyRecord(ShaderRecord& record) {
    if (record.program) glDeleteProgram(record.program);
    record.program = 0;
}

void parseUniforms(const std::string& source, ShaderRecord& record) {
    std::istringstream input(source);
    std::string line;
    while (std::getline(input, line)) {
        const std::string clean = trim(line);
        if (clean.rfind("uniform ", 0) != 0) continue;
        std::string declaration = clean.substr(8);
        const auto semicolon = declaration.find(';');
        if (semicolon != std::string::npos) declaration.resize(semicolon);
        std::istringstream tokens(declaration);
        std::string type;
        std::string name;
        tokens >> type >> name;
        if (type == "highp" || type == "mediump" || type == "lowp") {
            type = name;
            tokens >> name;
        }
        if (name.empty()) continue;
        if (type == "sampler2D" || type == "mat4" || type == "mat3" || type == "mat2") continue;
        if (name == "u_uvRect" || name == "u_yFlip" || name == "u_texScale") continue;
        if (!name.empty() && name[0] == '_') name.erase(name.begin());
        UniformRecord uniform;
        if (type == "float") uniform.components = 1;
        else if (type == "vec2") uniform.components = 2;
        else if (type == "vec3") uniform.components = 3;
        else if (type == "vec4") uniform.components = 4;
        else continue;
        record.uniforms[name] = uniform;
        record.uniforms["_" + name] = uniform;
    }
}

void uploadUniforms(ShaderRecord& record) {
    for (auto& [name, uniform] : record.uniforms) {
        (void)name;
        if (uniform.location < 0) continue;
        switch (uniform.components) {
            case 1: glUniform1f(uniform.location, uniform.values[0]); break;
            case 2: glUniform2f(uniform.location, uniform.values[0], uniform.values[1]); break;
            case 3: glUniform3f(uniform.location, uniform.values[0], uniform.values[1], uniform.values[2]); break;
            default: glUniform4f(uniform.location, uniform.values[0], uniform.values[1], uniform.values[2], uniform.values[3]); break;
        }
    }
}

// Clip-space quad. Viewport already crops to the chart strip, so this does not
// fight GameMaker's pixel ortho / gm_Matrices layout.
const char* kVertexSourceEs100 = R"GLSL(
#version 100
attribute vec2 a_position;
attribute vec2 a_texcoord;
uniform vec4 u_uvRect;
uniform float u_yFlip;
varying vec2 uv;
varying vec2 v_texcoord;
varying vec2 v_vTexcoord;
void main() {
    gl_Position = vec4(a_position, 0.0, 1.0);
    vec2 mapped = vec2(
        mix(u_uvRect.x, u_uvRect.z, a_texcoord.x),
        mix(u_uvRect.y, u_uvRect.w, a_texcoord.y));
    uv = mapped;
    v_texcoord = a_texcoord;
    v_vTexcoord = mapped;
}
)GLSL";

bool isIdentChar(char c) {
    return std::isalnum(static_cast<unsigned char>(c)) != 0 || c == '_';
}

std::string replaceToken(std::string source, const std::string& from, const std::string& to) {
    std::string result;
    result.reserve(source.size());
    for (std::size_t i = 0; i < source.size();) {
        if (source.compare(i, from.size(), from) == 0) {
            const bool beforeOk = (i == 0) || !isIdentChar(source[i - 1]);
            const bool afterOk = (i + from.size() >= source.size()) || !isIdentChar(source[i + from.size()]);
            if (beforeOk && afterOk) {
                result += to;
                i += from.size();
                continue;
            }
        }
        result += source[i++];
    }
    return result;
}

std::string toLowerCopy(std::string value) {
    for (char& c : value) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return value;
}

bool looksLikeHlsl(const std::string& source) {
    return source.find("float4") != std::string::npos
        || source.find("float2") != std::string::npos
        || source.find("float3") != std::string::npos
        || source.find("SV_Target") != std::string::npos
        || source.find("SV_TARGET") != std::string::npos
        || source.find("SV_Position") != std::string::npos
        || source.find("SV_POSITION") != std::string::npos
        || source.find("SamplerState") != std::string::npos
        || source.find("Texture2D") != std::string::npos
        || source.find("cbuffer ") != std::string::npos
        || source.find(": register(") != std::string::npos
        || source.find("tex2D(") != std::string::npos
        || source.find("tex2Dlod(") != std::string::npos
        || source.find(".Sample(") != std::string::npos
        || source.find(".SampleLevel(") != std::string::npos;
}

bool looksLikeParticleShader(const std::string& sourceName, const std::string& source) {
    const std::string lowerName = toLowerCopy(sourceName);
    const std::string lower = toLowerCopy(source);
    return lowerName.find("rain") != std::string::npos
        || lowerName.find("snow") != std::string::npos
        || lowerName.find("bokeh") != std::string::npos
        || lowerName.find("particle") != std::string::npos
        || lowerName.find("drop") != std::string::npos
        || lowerName.find("flake") != std::string::npos
        || lower.find("generatedropposition") != std::string::npos
        || lower.find("dropwidth") != std::string::npos
        || lower.find("dropheight") != std::string::npos
        || lower.find("snowsize") != std::string::npos
        || lower.find("flakesize") != std::string::npos
        || lower.find("particlecount") != std::string::npos;
}

bool looksLikeCameraShader(const std::string& sourceName, const std::string& source) {
    const std::string lowerName = toLowerCopy(sourceName);
    const std::string lower = toLowerCopy(source);
    if (lowerName.find("camera") != std::string::npos
        || lowerName.find("camshake") != std::string::npos
        || lowerName.find("shake") != std::string::npos) {
        return true;
    }
    const bool hasTransform = lower.find("zoom") != std::string::npos
        || lower.find("angle") != std::string::npos
        || lower.find("rotate") != std::string::npos
        || lower.find("camera") != std::string::npos;
    const bool hasUvMath = lower.find("uv -") != std::string::npos
        || lower.find("uv-") != std::string::npos
        || lower.find("float2x2") != std::string::npos
        || lower.find("mat2") != std::string::npos
        || lower.find("sincos") != std::string::npos;
    return hasTransform && hasUvMath;
}

void queryFramebufferSize(GLint* width, GLint* height) {
    GLint viewport[4] = {0, 0, 0, 0};
    glGetIntegerv(GL_VIEWPORT, viewport);
    *width = std::max(viewport[2], 1);
    *height = std::max(viewport[3], 1);

    GLint framebuffer = 0;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &framebuffer);
    if (framebuffer == 0) {
        const EGLDisplay display = eglGetCurrentDisplay();
        const EGLSurface surface = eglGetCurrentSurface(EGL_DRAW);
        EGLint surfaceWidth = 0;
        EGLint surfaceHeight = 0;
        if (display != EGL_NO_DISPLAY && surface != EGL_NO_SURFACE
            && eglQuerySurface(display, surface, EGL_WIDTH, &surfaceWidth)
            && eglQuerySurface(display, surface, EGL_HEIGHT, &surfaceHeight)
            && surfaceWidth > 0 && surfaceHeight > 0) {
            *width = surfaceWidth;
            *height = surfaceHeight;
        }
    }
}

std::string rewriteDynamicForLoops(std::string source) {
    // Keep the loop index as float. Rain/snow call generateDropPosition(i, i * 10.0);
    // converting i to int makes GLES ES 1.00 reject the mixed-type call.
    // Bound must be an identifier, not a literal: `i < 64` is already legal GLES
    // and rewriting it to `if (i < 64)` with a float index is a type error.
    static const std::regex symmetric(
        R"(for\s*\(\s*float\s+(\w+)\s*=\s*-\s*([A-Za-z_]\w*)\s*;\s*\1\s*<=\s*\2\s*;\s*\1\s*\+\+\s*\))");
    static const std::regex fromZeroFloat(
        R"(for\s*\(\s*float\s+(\w+)\s*=\s*0(?:\.0)?\s*;\s*\1\s*<=?\s*([A-Za-z_]\w*)\s*;\s*(?:\+\+\1|\1\+\+|\1\s*\+=\s*1(?:\.0)?)\s*\))");
    static const std::regex fromZeroIntUniform(
        R"(for\s*\(\s*int\s+(\w+)\s*=\s*0\s*;\s*\1\s*<=?\s*(?:int\s*\(\s*)?([A-Za-z_]\w*)(?:\s*\))?\s*;\s*(?:\+\+\1|\1\+\+)\s*\))");
    static const std::regex fromZeroInc(
        R"(for\s*\(\s*float\s+(\w+)\s*=\s*0\.0\s*;\s*\1\s*<\s*([A-Za-z_]\w*)\s*;\s*\1\s*\+\+\s*\))");
    static const std::regex fromZeroAdd(
        R"(for\s*\(\s*float\s+(\w+)\s*=\s*0\.0\s*;\s*\1\s*<\s*([A-Za-z_]\w*)\s*;\s*\1\s*\+=\s*1\.0\s*\))");
    // Cap at 12: bokeh_pr uses `for (x = -radius; x <= radius)` with radius~10.
    // Expanding that to ±32 is 65x65 samples and Mali/Adreno skip the shader
    // (compile succeeds, every pixel comes out black).
    source = std::regex_replace(source, symmetric,
        "for (float $1 = -8.0; $1 <= 8.0; $1 += 1.0) if ($1 >= -float($2) && $1 <= float($2))");
    source = std::regex_replace(source, fromZeroFloat,
        "for (float $1 = 0.0; $1 < 512.0; $1 += 1.0) if ($1 < float($2))");
    source = std::regex_replace(source, fromZeroIntUniform,
        "for (float $1 = 0.0; $1 < 512.0; $1 += 1.0) if ($1 < float($2))");
    source = std::regex_replace(source, fromZeroInc,
        "for (float $1 = 0.0; $1 < 512.0; $1 += 1.0) if ($1 < float($2))");
    source = std::regex_replace(source, fromZeroAdd,
        "for (float $1 = 0.0; $1 < 512.0; $1 += 1.0) if ($1 < float($2))");
    return source;
}

std::string stripShaderComments(std::string source) {
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
            result += ' ';
            continue;
        }
        result += source[i++];
    }
    return result;
}

std::string unwrapCbuffer(std::string source) {
    static const std::regex header(R"(cbuffer\s+\w+\s*(?::\s*register\s*\(\s*\w+\s*\))?\s*\{)");
    std::smatch match;
    while (std::regex_search(source, match, header)) {
        const std::size_t start = static_cast<std::size_t>(match.position());
        std::size_t brace = start + static_cast<std::size_t>(match.length()) - 1;
        int depth = 1;
        std::size_t end = brace + 1;
        for (; end < source.size() && depth > 0; ++end) {
            if (source[end] == '{') ++depth;
            else if (source[end] == '}') --depth;
        }
        std::string body = source.substr(brace + 1, end - brace - 2);
        source.replace(start, end - start, body);
    }
    return source;
}

std::string stripHlslFloatSuffix(std::string source) {
    source = std::regex_replace(source, std::regex(R"((\d+\.\d*|\d*\.\d+|\d+\.)[fF]\b)"), "$1");
    source = std::regex_replace(source, std::regex(R"((\d+)[fF]\b)"), "$1.0");
    return source;
}

std::string promoteCtorIntLiterals(const std::string& args) {
    std::string result;
    result.reserve(args.size() + 8);
    for (std::size_t i = 0; i < args.size();) {
        if ((i == 0 || !isIdentChar(args[i - 1])) && args[i] >= '0' && args[i] <= '9') {
            std::size_t j = i;
            while (j < args.size() && args[j] >= '0' && args[j] <= '9') ++j;
            const bool alreadyFloat = (j < args.size() && (args[j] == '.' || args[j] == 'e' || args[j] == 'E'));
            result.append(args, i, j - i);
            if (!alreadyFloat) result += ".0";
            i = j;
            continue;
        }
        result += args[i++];
    }
    return result;
}

std::string promoteVectorConstructors(std::string source) {
    static const std::regex ctor(R"(\b(vec[234]|mat[234])\s*\(([^;()]*)\))");
    std::string result;
    result.reserve(source.size());
    std::size_t last = 0;
    for (std::sregex_iterator it(source.begin(), source.end(), ctor), end; it != end; ++it) {
        result.append(source, last, static_cast<std::size_t>(it->position()) - last);
        result += it->str(1) + "(" + promoteCtorIntLiterals(it->str(2)) + ")";
        last = static_cast<std::size_t>(it->position() + it->length());
    }
    result.append(source, last, std::string::npos);
    return result;
}

std::string convertMainSignature(std::string source) {
    static const std::regex mainRe(
        R"((?:float4|vec4|void)\s+main\s*\(([^)]*)\)(?:\s*:\s*\w+)?)");
    std::smatch match;
    if (!std::regex_search(source, match, mainRe)) return source;
    const std::string params = match[1].str();
    std::string prelude;
    std::istringstream paramStream(params);
    std::string param;
    while (std::getline(paramStream, param, ',')) {
        param = trim(param);
        if (param.empty()) continue;
        const bool isOut = param.rfind("out ", 0) == 0 || param.find(" out ") != std::string::npos;
        if (isOut) continue;
        std::string noSemantic = param;
        const auto colon = noSemantic.find(':');
        std::string semantic;
        if (colon != std::string::npos) {
            semantic = toLowerCopy(trim(noSemantic.substr(colon + 1)));
            noSemantic = trim(noSemantic.substr(0, colon));
        }
        std::istringstream tokens(noSemantic);
        std::string type;
        std::string name;
        tokens >> type >> name;
        if (name.empty()) {
            name = type;
            type = "vec2";
        }
        if (semantic.find("sv_position") != std::string::npos || semantic.find("sv_pos") != std::string::npos) {
            prelude += "    vec4 " + name + " = vec4(gl_FragCoord.xy, 0.0, 1.0);\n";
        } else if (semantic.find("texcoord") != std::string::npos || type.find("2") != std::string::npos) {
            if (name != "uv") prelude += "    vec2 " + name + " = uv;\n";
        } else if (type == "PS_INPUT" || type == "v2f" || type == "VSOutput" || type == "VS_OUTPUT") {
            prelude += "    vec2 " + name + "_uv = uv;\n";
            prelude += "    vec4 " + name + "_pos = vec4(gl_FragCoord.xy, 0.0, 1.0);\n";
            source = replaceAll(source, name + ".uv", name + "_uv");
            source = replaceAll(source, name + ".texcoord", name + "_uv");
            source = replaceAll(source, name + ".TexCoord", name + "_uv");
            source = replaceAll(source, name + ".pos", name + "_pos");
            source = replaceAll(source, name + ".position", name + "_pos");
            source = replaceAll(source, name + ".Position", name + "_pos");
            source = replaceAll(source, name + ".sv_position", name + "_pos");
        }
    }
    source = std::regex_replace(source, mainRe, "void main()", std::regex_constants::format_first_only);
    if (!prelude.empty()) {
        const auto mainPos = source.find("void main()");
        if (mainPos != std::string::npos) {
            const auto brace = source.find('{', mainPos);
            if (brace != std::string::npos) source.insert(brace + 1, "\n" + prelude);
        }
    }
    return source;
}

std::string convertMainReturns(std::string source) {
    const auto mainPos = source.find("void main()");
    if (mainPos == std::string::npos) return source;
    const auto brace = source.find('{', mainPos);
    if (brace == std::string::npos) return source;
    int depth = 0;
    std::size_t end = brace;
    for (; end < source.size(); ++end) {
        if (source[end] == '{') ++depth;
        else if (source[end] == '}') {
            --depth;
            if (depth == 0) break;
        }
    }
    std::string body = source.substr(brace, end - brace);
    static const std::regex retRe(R"(return\s+([^;]+);)");
    body = std::regex_replace(body, retRe, "gl_FragColor = ($1); return;");
    source.replace(brace, end - brace, body);
    return source;
}

std::string prefixGlobalUniforms(std::string source) {
    const auto mainPos = source.find("void main()");
    const std::size_t limit = mainPos == std::string::npos ? source.size() : mainPos;
    std::string header = source.substr(0, limit);
    std::string rest = source.substr(limit);
    std::istringstream input(header);
    std::ostringstream output;
    std::string line;
    static const std::regex globalRe(
        R"(^\s*(?:static\s+)?(?:const\s+)?(float|vec2|vec3|vec4|int|bool|mat2|mat3|mat4|sampler2D)\s+(\w+)\s*(?:=[^;]+)?;\s*$)");
    while (std::getline(input, line)) {
        const std::string clean = trim(line);
        if (clean.find('(') != std::string::npos
            || clean.rfind("uniform ", 0) == 0
            || clean.rfind("varying ", 0) == 0
            || clean.rfind("attribute ", 0) == 0
            || clean.rfind("#", 0) == 0
            || clean.rfind("struct ", 0) == 0
            || clean.rfind("const ", 0) == 0) {
            output << line << '\n';
            continue;
        }
        std::smatch match;
        if (std::regex_match(clean, match, globalRe)) {
            if (clean.find('=') != std::string::npos) {
                output << "const " << match[1].str() << " " << match[2].str()
                    << clean.substr(clean.find('=')) << "\n";
            } else {
                output << "uniform " << match[1].str() << " " << match[2].str() << ";\n";
            }
        } else {
            output << line << '\n';
        }
    }
    return output.str() + rest;
}

std::string rewriteMulCalls(std::string source) {
    std::size_t pos = 0;
    while ((pos = source.find("mul(", pos)) != std::string::npos) {
        std::size_t start = pos + 4;
        int depth = 1;
        std::size_t comma = std::string::npos;
        std::size_t end = start;
        for (; end < source.size() && depth > 0; ++end) {
            if (source[end] == '(') ++depth;
            else if (source[end] == ')') --depth;
            else if (source[end] == ',' && depth == 1 && comma == std::string::npos) comma = end;
        }
        if (comma == std::string::npos || depth != 0) {
            pos += 4;
            continue;
        }
        const std::string left = trim(source.substr(start, comma - start));
        const std::string right = trim(source.substr(comma + 1, end - comma - 2));
        const std::string replaced = "((" + left + ") * (" + right + "))";
        source.replace(pos, end - pos, replaced);
        pos += replaced.size();
    }
    return source;
}

std::string hlslToGlslEs(std::string source, const std::string& sourceName) {
    source = replaceAll(source, "\r\n", "\n");
    source = stripShaderComments(source);
    source = std::regex_replace(source, std::regex(R"(#pragma[^\n]*)"), "");
    source = std::regex_replace(source, std::regex(R"(#include[^\n]*)"), "");
    source = std::regex_replace(source, std::regex(R"(\[(?:loop|unroll|flatten|branch|fastopt)[^\]]*\])"), "");
    source = unwrapCbuffer(source);
    source = std::regex_replace(source, std::regex(R"(\s*:\s*register\s*\(\s*\w+\s*\))"), "");
    source = std::regex_replace(source, std::regex(R"(\s*:\s*packoffset\s*\(\s*[^)]+\))"), "");
    source = std::regex_replace(source, std::regex(R"(SamplerState\s+\w+\s*;)"), "");
    source = std::regex_replace(source, std::regex(R"(SamplerState\s+\w+\s*=\s*sampler_state\s*\{[^}]*\}\s*;)"), "");
    source = std::regex_replace(source, std::regex(R"(Texture2D\s*(?:<\s*\w+\s*>)?\s+(\w+)\s*;)"), "sampler2D $1;");
    source = replaceAll(source, "sampler2D_half", "sampler2D");
    source = replaceAll(source, "sampler2D_float", "sampler2D");

    source = std::regex_replace(source,
        std::regex(R"((\w+)\.SampleLevel\s*\(\s*\w+\s*,\s*([^,]+)\s*,[^)]+\))"),
        "texture2D($1, $2)");
    source = std::regex_replace(source,
        std::regex(R"((\w+)\.Sample\s*\(\s*\w+\s*,\s*([^)]+)\))"),
        "texture2D($1, $2)");
    source = std::regex_replace(source,
        std::regex(R"(tex2Dlod\s*\(\s*(\w+)\s*,\s*(?:float4|vec4)\s*\(\s*([^,]+)\s*,[^)]+\))"),
        "texture2D($1, $2)");
    source = std::regex_replace(source, std::regex(R"(tex2D\s*\()"), "texture2D(");

    source = replaceToken(source, "_MainTex", "screenTexture");
    source = replaceToken(source, "gm_BaseTexture", "screenTexture");

    source = replaceToken(source, "float4x4", "mat4");
    source = replaceToken(source, "float3x3", "mat3");
    source = replaceToken(source, "float2x2", "mat2");
    source = replaceToken(source, "float4", "vec4");
    source = replaceToken(source, "float3", "vec3");
    source = replaceToken(source, "float2", "vec2");
    source = replaceToken(source, "half4", "vec4");
    source = replaceToken(source, "half3", "vec3");
    source = replaceToken(source, "half2", "vec2");
    source = replaceToken(source, "half", "float");
    source = replaceToken(source, "fixed4", "vec4");
    source = replaceToken(source, "fixed3", "vec3");
    source = replaceToken(source, "fixed2", "vec2");
    source = replaceToken(source, "fixed", "float");
    source = replaceToken(source, "uint", "int");
    source = replaceToken(source, "dword", "int");

    source = rewriteMulCalls(source);
    static const std::regex mat2Re(R"(mat2\s*\(\s*([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\))");
    source = std::regex_replace(source, mat2Re, "mat2($1, $3, $2, $4)");

    source = replaceToken(source, "lerp", "mix");
    source = replaceToken(source, "frac", "fract");
    source = replaceToken(source, "atan2", "atan");
    source = replaceToken(source, "rsqrt", "inversesqrt");
    source = replaceToken(source, "fmod", "mod");
    source = replaceToken(source, "ddx", "dFdx");
    source = replaceToken(source, "ddy", "dFdy");
    source = std::regex_replace(source, std::regex(R"(saturate\s*\(([^)]+)\))"), "clamp(($1), 0.0, 1.0)");
    source = std::regex_replace(source, std::regex(R"(rcp\s*\(([^)]+)\))"), "(1.0 / ($1))");
    source = std::regex_replace(source, std::regex(R"(mad\s*\(([^,]+),([^,]+),([^)]+)\))"), "(($1) * ($2) + ($3))");
    source = std::regex_replace(source, std::regex(R"(clip\s*\(([^)]+)\)\s*;)"), "if (($1) < 0.0) discard;");
    source = std::regex_replace(source,
        std::regex(R"(sincos\s*\(\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^)]+)\s*\)\s*;)"),
        "$2 = sin($1); $3 = cos($1);");

    source = convertMainSignature(source);
    source = convertMainReturns(source);
    source = prefixGlobalUniforms(source);
    source = stripHlslFloatSuffix(source);
    source = promoteVectorConstructors(source);

    if (source.find("gl_FragCoord") != std::string::npos && source.find("screenSize") == std::string::npos) {
        source = "uniform vec2 screenSize;\n" + source;
    }
    if (looksLikeCameraShader(sourceName, source) || looksLikeParticleShader(sourceName, source)) {
        if (source.find("screenSize") == std::string::npos) {
            source = "uniform vec2 screenSize;\n" + source;
        }
    }
    if (source.find("dFdx") != std::string::npos || source.find("dFdy") != std::string::npos) {
        source = "#extension GL_OES_standard_derivatives : enable\n" + source;
    }
    return source;
}

std::string remapFragCoord(std::string fragment) {
    if (fragment.find("gl_FragCoord") == std::string::npos) return fragment;
    if (fragment.find("screenSize") == std::string::npos) return fragment;

    if (fragment.find("uniform vec4 u_uvRect") == std::string::npos) {
        const auto precisionLine = fragment.find("precision ");
        const auto insertAt = precisionLine == std::string::npos
            ? std::string::npos
            : fragment.find('\n', precisionLine);
        if (insertAt == std::string::npos) fragment = "uniform vec4 u_uvRect;\n" + fragment;
        else fragment.insert(insertAt + 1, "uniform vec4 u_uvRect;\n");
    }

    const char* pixelInit =
        "vec2 rpe_pixel = vec2("
        "(uv.x - u_uvRect.x) / max(u_uvRect.z - u_uvRect.x, 0.0001), "
        "(uv.y - u_uvRect.y) / max(u_uvRect.w - u_uvRect.y, 0.0001)"
        ") * screenSize;\n";
    const auto mainPos = fragment.find("void main");
    if (mainPos != std::string::npos) {
        const auto brace = fragment.find('{', mainPos);
        if (brace != std::string::npos) {
            fragment.insert(brace + 1, std::string("\n    ") + pixelInit);
        }
    }

    fragment = replaceAll(fragment, "gl_FragCoord.xy", "rpe_pixel");
    fragment = replaceAll(fragment, "gl_FragCoord.x", "rpe_pixel.x");
    fragment = replaceAll(fragment, "gl_FragCoord.y", "rpe_pixel.y");
    fragment = replaceAll(fragment,
        "vec2 dropPos = generateDropPosition(i, i * 10.0);",
        "float rpe_i = float(i);\n"
        "        vec2 dropPos = vec2("
        "fract(sin(dot(vec2(rpe_i, time + rpe_i * 10.0 + 10.0), vec2(12.9898, 78.233))) * 43758.5453123) * screenSize.x, "
        "mod(fract(sin(dot(vec2(rpe_i, rpe_i * 10.0), vec2(12.9898, 78.233))) * 43758.5453123) * screenSize.y - time * 2000.0, screenSize.y));");
    fragment = replaceAll(fragment, "dropWidth * screenSize.x", "max(dropWidth * screenSize.x, 1.5)");
    fragment = replaceAll(fragment, "snowSize * screenSize.x", "max(snowSize * screenSize.x, 1.5)");
    fragment = replaceAll(fragment, "flakeSize * screenSize.x", "max(flakeSize * screenSize.x, 1.5)");
    return fragment;
}

std::string addCopyTexSampleFlip(std::string fragment) {
    // Capture lives in the lower-left of a POT texture. GameMaker uv is top-left;
    // multiply by u_texScale so we do not sample the empty POT padding (black).
    const std::string helper =
        "uniform vec2 u_texScale;\n"
        "vec4 rpe_sample(sampler2D t, vec2 u) {\n"
        "    vec2 scale = u_texScale;\n"
        "    return texture2D(t, vec2(u.x * scale.x, (1.0 - u.y) * scale.y));\n"
        "}\n";
    auto insertAt = fragment.find("precision ");
    if (insertAt != std::string::npos) insertAt = fragment.find('\n', insertAt);
    if (insertAt == std::string::npos) fragment = helper + fragment;
    else fragment.insert(insertAt + 1, helper);
    fragment = replaceAll(fragment, "texture2D(", "rpe_sample(");
    fragment = replaceAll(fragment,
        "return rpe_sample(t, vec2(u.x * scale.x, (1.0 - u.y) * scale.y));",
        "return texture2D(t, vec2(u.x * scale.x, (1.0 - u.y) * scale.y));");
    return fragment;
}

bool hasVaryingUv(const std::string& source) {
    static const std::regex re(R"(varying\s+(?:(?:lowp|mediump|highp)\s+)?vec2\s+uv\b)");
    return std::regex_search(source, re);
}

bool hasLocalUv(const std::string& source) {
    static const std::regex re(R"(\bvec2\s+uv\s*=)");
    return std::regex_search(source, re);
}

std::string remapWindowCoordToGameMaker(std::string fragment) {
    if (fragment.find("gl_FragCoord") == std::string::npos) return fragment;
    if (fragment.find("screenSize") == std::string::npos
        && fragment.find("iResolution") == std::string::npos) return fragment;
    fragment = replaceAll(fragment, "gl_FragCoord.xy", "rpe_pixel");
    fragment = replaceAll(fragment, "gl_FragCoord.x", "rpe_pixel.x");
    fragment = replaceAll(fragment, "gl_FragCoord.y", "rpe_pixel.y");
    const char* pixelInit =
        "vec2 rpe_pixel = vec2(gl_FragCoord.x, screenSize.y - gl_FragCoord.y);\n";
    const auto mainPos = fragment.find("void main");
    if (mainPos != std::string::npos) {
        const auto brace = fragment.find('{', mainPos);
        if (brace != std::string::npos) {
            fragment.insert(brace + 1, std::string("\n    ") + pixelInit);
        }
    }
    return fragment;
}

std::string prepareGlslEs(std::string fragment) {
    if (fragment.find("rpe_sample(") != std::string::npos && fragment.find("#version") != std::string::npos) {
        return fragment;
    }
    fragment = replaceAll(fragment, "\r\n", "\n");
    fragment = replaceAll(fragment, "#version 300 es", "");
    fragment = replaceAll(fragment, "#version 100", "");
    fragment = std::regex_replace(fragment,
        std::regex(R"(precision\s+(?:lowp|mediump|highp)\s+float\s*;)"), "");
    fragment = rewriteDynamicForLoops(fragment);
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

    const bool localUv = hasLocalUv(fragment);
    const bool varyingUv = hasVaryingUv(fragment);
    // Camera / bloom / glitch .fs files assign `vec2 uv = gl_FragCoord.xy / screenSize`.
    // Remapping through the letterboxed varying would clash with that local uv.
    if (localUv && fragment.find("gl_FragCoord") != std::string::npos) {
        fragment = remapWindowCoordToGameMaker(fragment);
    } else if (!localUv) {
        fragment = remapFragCoord(fragment);
        if (!varyingUv) fragment = "varying vec2 uv;\n" + fragment;
    }

    fragment = "#version 100\nprecision highp float;\n" + fragment;
    fragment = addCopyTexSampleFlip(fragment);
    return fragment;
}

bool linkProgram(GLuint vertex, GLuint pixel, GLuint* program, std::string* error) {
    *program = glCreateProgram();
    glAttachShader(*program, vertex);
    glAttachShader(*program, pixel);
    glBindAttribLocation(*program, 0, "a_position");
    glBindAttribLocation(*program, 1, "a_texcoord");
    glLinkProgram(*program);
    GLint linked = 0;
    glGetProgramiv(*program, GL_LINK_STATUS, &linked);
    if (linked == GL_TRUE) return true;
    GLint length = 0;
    glGetProgramiv(*program, GL_INFO_LOG_LENGTH, &length);
    *error = std::string(static_cast<std::size_t>(std::max(length, 1)), '\0');
    glGetProgramInfoLog(*program, length, nullptr, error->data());
    glDeleteProgram(*program);
    *program = 0;
    return false;
}

int nextPowerOfTwo(int value) {
    int pot = 1;
    while (pot < value) pot <<= 1;
    return std::max(pot, 1);
}

bool captureInputFromCurrentFramebuffer(GLint width, GLint height) {
    GLint sourceFbo = 0;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &sourceFbo);
    GLint viewport[4] = {0, 0, width, height};
    glGetIntegerv(GL_VIEWPORT, viewport);
    const GLint copyX = viewport[0];
    const GLint copyY = viewport[1];
    const GLint copyW = std::max(viewport[2], 1);
    const GLint copyH = std::max(viewport[3], 1);
    g_lastCaptureFbo = sourceFbo;
    g_lastCaptureMethod = "none";
    g_inputCaptured = false;
    g_inputYFlipped = false;
    if (copyW <= 0 || copyH <= 0) {
        setError("Android shader capture skipped: empty framebuffer size.");
        return false;
    }

    glDisable(GL_SCISSOR_TEST);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glPixelStorei(GL_PACK_ALIGNMENT, 1);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glFinish();

    // NPOT + GL_LINEAR returns black on many GLES2/3 drivers. Copy into the
    // lower-left of a POT texture and scale UVs when sampling.
    const GLint potW = nextPowerOfTwo(copyW);
    const GLint potH = nextPowerOfTwo(copyH);
    glBindFramebuffer(GL_FRAMEBUFFER, static_cast<GLuint>(sourceFbo));
    glActiveTexture(GL_TEXTURE0);
    if (g_inputTexture == 0) glGenTextures(1, &g_inputTexture);
    glBindTexture(GL_TEXTURE_2D, g_inputTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    while (glGetError() != GL_NO_ERROR) {}
    if (potW != g_potWidth || potH != g_potHeight) {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, potW, potH, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
        const GLenum allocError = glGetError();
        if (allocError != GL_NO_ERROR) {
            setError("Android shader capture failed: POT glTexImage2D error " + std::to_string(allocError));
            return false;
        }
        g_potWidth = potW;
        g_potHeight = potH;
    }
    glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, copyX, copyY, copyW, copyH);
    const GLenum copyError = glGetError();
    if (copyError != GL_NO_ERROR) {
        setError("Android shader capture failed: glCopyTexSubImage2D error " + std::to_string(copyError)
            + " fbo=" + std::to_string(sourceFbo)
            + " vp=" + std::to_string(copyX) + "," + std::to_string(copyY)
            + "," + std::to_string(copyW) + "x" + std::to_string(copyH));
        return false;
    }
    g_lastTargetWidth = copyW;
    g_lastTargetHeight = copyH;
    g_texScaleX = static_cast<float>(copyW) / static_cast<float>(potW);
    g_texScaleY = static_cast<float>(copyH) / static_cast<float>(potH);
    g_lastCopyX = copyX;
    g_lastCopyY = copyY;
    g_inputCaptured = true;
    g_inputYFlipped = true;
    g_lastCaptureMethod = "copysub";
    return true;
}

} // namespace

std::string rpe_glsl_translate(std::string_view source, std::string_view sourceName) {
    std::lock_guard lock(g_mutex);
    g_translatedSource.clear();
    if (source.empty()) {
        setError("External shader source is empty.");
        return g_translatedSource;
    }
    std::string sourceCopy(source);
    const std::string nameCopy(sourceName);
    if (looksLikeHlsl(sourceCopy)) {
        sourceCopy = hlslToGlslEs(sourceCopy, nameCopy);
        if (sourceCopy.empty()) {
            setError("HLSL to GLSL ES translation produced empty source.");
            return g_translatedSource;
        }
    }
    g_translatedSource = prepareGlslEs(sourceCopy);
    setError({});
    return g_translatedSource;
}

std::int32_t rpe_hlsl_initialize(void* devicePointer, void* contextPointer) {
    std::lock_guard lock(g_mutex);
    (void)devicePointer;
    (void)contextPointer;
    rpe_hlsl_shutdown();
    const float vertices[] = {
        -1.0f,  1.0f, 0.0f, 0.0f,
         1.0f,  1.0f, 1.0f, 0.0f,
        -1.0f, -1.0f, 0.0f, 1.0f,
         1.0f, -1.0f, 1.0f, 1.0f,
    };
    glGenBuffers(1, &g_quadVbo);
    glBindBuffer(GL_ARRAY_BUFFER, g_quadVbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    const auto genVao = reinterpret_cast<GenVertexArraysFn>(eglGetProcAddress("glGenVertexArrays"));
    const auto genVaoOes = reinterpret_cast<GenVertexArraysFn>(eglGetProcAddress("glGenVertexArraysOES"));
    if (genVao) genVao(1, &g_vao);
    else if (genVaoOes) genVaoOes(1, &g_vao);
    g_ready = g_quadVbo != 0;
    if (!g_ready) {
        setError("Failed to create the GLES quad vertex buffer.");
        return -1;
    }
    setError({});
    return 3;
}

std::int32_t rpe_hlsl_state() {
    std::lock_guard lock(g_mutex);
    return 202608360 + (g_ready ? 3 : 0);
}

std::int32_t rpe_hlsl_compile(std::string_view source, std::string_view sourceName) {
    std::lock_guard lock(g_mutex);
    if (!g_ready || source.empty()) {
        setError("RPE GLSL ES backend is not initialized.");
        return -1;
    }
    std::string fragment = g_translatedSource.empty() ? std::string(source) : g_translatedSource;
    const std::string nameCopy(sourceName);
    if (looksLikeHlsl(fragment)) {
        fragment = hlslToGlslEs(fragment, nameCopy);
        if (fragment.empty()) {
            setError("HLSL to GLSL ES translation produced empty source.");
            g_translatedSource.clear();
            return -1;
        }
    }
    fragment = prepareGlslEs(fragment);

    std::string error;
    const GLuint vertex = compileShader(GL_VERTEX_SHADER, kVertexSourceEs100, &error);
    if (!vertex) {
        setError("GLES ES 1.00 vertex compile failed: " + error);
        g_translatedSource.clear();
        return -1;
    }
    const GLuint pixel = compileShader(GL_FRAGMENT_SHADER, fragment.c_str(), &error);
    if (!pixel) {
        glDeleteShader(vertex);
        setError("GLSL ES 1.00 fragment compile failed (" + std::string(sourceName) + "): " + error);
        g_translatedSource.clear();
        return -1;
    }

    auto record = std::make_unique<ShaderRecord>();
    if (!linkProgram(vertex, pixel, &record->program, &error)) {
        glDeleteShader(vertex);
        glDeleteShader(pixel);
        setError("GLES program link failed: " + error);
        g_translatedSource.clear();
        return -1;
    }
    glDeleteShader(vertex);
    glDeleteShader(pixel);
    record->uvRectLocation = glGetUniformLocation(record->program, "u_uvRect");
    record->yFlipLocation = glGetUniformLocation(record->program, "u_yFlip");
    record->texScaleLocation = glGetUniformLocation(record->program, "u_texScale");
    record->textureLocation = glGetUniformLocation(record->program, "gm_BaseTexture");
    if (record->textureLocation < 0) {
        record->textureLocation = glGetUniformLocation(record->program, "screenTexture");
    }
    parseUniforms(fragment, *record);
    for (auto& [name, uniform] : record->uniforms) {
        uniform.location = glGetUniformLocation(record->program, name.c_str());
        if (uniform.location < 0 && !name.empty() && name[0] != '_') {
            uniform.location = glGetUniformLocation(record->program, ("_" + name).c_str());
        }
    }
    const int handle = g_nextHandle++;
    g_shaders.emplace(handle, std::move(record));
    g_translatedSource.clear();
    setError({});
    return handle;
}

bool rpe_hlsl_set_uniform_component(std::int32_t handle, std::string_view name,
    std::int32_t component, float value) {
    std::lock_guard lock(g_mutex);
    const auto shaderIt = g_shaders.find(handle);
    if (shaderIt == g_shaders.end() || name.empty() || component < 0 || component > 3) return false;
    auto& uniforms = shaderIt->second->uniforms;
    const std::string uniformName(name);
    auto uniformIt = uniforms.find(uniformName);
    if (uniformIt == uniforms.end()) uniformIt = uniforms.find("_" + uniformName);
    if (uniformIt == uniforms.end()) return false;
    uniformIt->second.values[component] = value;
    return true;
}

bool rpe_hlsl_begin(std::int32_t handle) {
    std::lock_guard lock(g_mutex);
    const auto shaderIt = g_shaders.find(handle);
    g_inputCaptured = false;
    if (!g_ready || shaderIt == g_shaders.end()) {
        setError("Android shader begin failed: backend or handle is invalid.");
        return false;
    }
    GLint targetWidth = 1;
    GLint targetHeight = 1;
    queryFramebufferSize(&targetWidth, &targetHeight);
    g_lastTargetWidth = targetWidth;
    g_lastTargetHeight = targetHeight;
    if (!captureInputFromCurrentFramebuffer(targetWidth, targetHeight)) return false;
    return true;
}

std::int32_t rpe_hlsl_draw(std::int32_t handle, float uvLeft, float uvTop, float uvRight, float uvBottom) {
    std::lock_guard lock(g_mutex);
    const auto shaderIt = g_shaders.find(handle);
    if (!g_ready || !g_quadVbo || shaderIt == g_shaders.end() || !g_inputCaptured || g_inputTexture == 0) {
        if (g_error.empty()) setError("Android shader draw skipped: captured source texture is missing.");
        return 0;
    }
    ShaderRecord& record = *shaderIt->second;

    GLint previousProgram = 0;
    GLint previousArrayBuffer = 0;
    GLint previousTexture = 0;
    GLint previousActive = 0;
    GLint previousVao = 0;
    GLint previousViewport[4] = {0, 0, 0, 0};
    GLint previousScissor[4] = {0, 0, 0, 0};
    GLint previousSrc = 0;
    GLint previousDst = 0;
    GLint drawFbo = 0;
    const GLboolean previousBlend = glIsEnabled(GL_BLEND);
    const GLboolean previousDepth = glIsEnabled(GL_DEPTH_TEST);
    const GLboolean previousCull = glIsEnabled(GL_CULL_FACE);
    const GLboolean previousScissorEnabled = glIsEnabled(GL_SCISSOR_TEST);
    glGetIntegerv(GL_CURRENT_PROGRAM, &previousProgram);
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &previousArrayBuffer);
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &previousTexture);
    glGetIntegerv(GL_ACTIVE_TEXTURE, &previousActive);
    glGetIntegerv(0x85B5, &previousVao);
    glGetIntegerv(GL_VIEWPORT, previousViewport);
    glGetIntegerv(GL_SCISSOR_BOX, previousScissor);
    glGetIntegerv(GL_BLEND_SRC_RGB, &previousSrc);
    glGetIntegerv(GL_BLEND_DST_RGB, &previousDst);
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &drawFbo);

    const float width = static_cast<float>(std::max(g_lastTargetWidth, 1));
    const float height = static_cast<float>(std::max(g_lastTargetHeight, 1));
    const float left = std::clamp(std::min(uvLeft, uvRight), 0.0f, 1.0f);
    const float right = std::clamp(std::max(uvLeft, uvRight), 0.0f, 1.0f);
    const float top = std::clamp(std::min(uvTop, uvBottom), 0.0f, 1.0f);
    const float bottom = std::clamp(std::max(uvTop, uvBottom), 0.0f, 1.0f);
    const GLint viewX = static_cast<GLint>(std::floor(left * width));
    const GLint viewW = static_cast<GLint>(std::ceil((right - left) * width));
    const GLint viewH = static_cast<GLint>(std::ceil((bottom - top) * height));
    const GLint viewY = static_cast<GLint>(std::floor((1.0f - bottom) * height));
    if (viewW <= 0 || viewH <= 0) {
        setError("Android shader draw skipped: empty viewport.");
        return 0;
    }

    auto boundsIt = record.uniforms.find("_rpeTextureBounds");
    if (boundsIt == record.uniforms.end()) boundsIt = record.uniforms.find("rpeTextureBounds");
    if (boundsIt != record.uniforms.end()) {
        boundsIt->second.values[0] = left;
        boundsIt->second.values[1] = top;
        boundsIt->second.values[2] = right;
        boundsIt->second.values[3] = bottom;
    }
    auto screenSizeIt = record.uniforms.find("screenSize");
    if (screenSizeIt == record.uniforms.end()) screenSizeIt = record.uniforms.find("_screenSize");
    if (screenSizeIt != record.uniforms.end()) {
        screenSizeIt->second.values[0] = width;
        screenSizeIt->second.values[1] = height;
    }

    if (const auto bindVao = bindVertexArrayFn()) bindVao(g_vao);
    glViewport(viewX, viewY, viewW, viewH);
    glEnable(GL_SCISSOR_TEST);
    glScissor(viewX, viewY, viewW, viewH);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_BLEND);
    glDisable(GL_CULL_FACE);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, g_inputTexture);
    glUseProgram(record.program);
    if (record.uvRectLocation >= 0) glUniform4f(record.uvRectLocation, left, top, right, bottom);
    if (record.yFlipLocation >= 0) glUniform1f(record.yFlipLocation, g_inputYFlipped ? 1.0f : 0.0f);
    uploadUniforms(record);
    if (record.texScaleLocation >= 0) glUniform2f(record.texScaleLocation, g_texScaleX, g_texScaleY);
    if (record.textureLocation >= 0) glUniform1i(record.textureLocation, 0);

    glBindBuffer(GL_ARRAY_BUFFER, g_quadVbo);
    const GLsizei stride = static_cast<GLsizei>(4 * sizeof(float));
    for (GLuint attrib = 0; attrib < 4; ++attrib) glDisableVertexAttribArray(attrib);
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, stride, nullptr);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, stride,
        reinterpret_cast<const void*>(2 * sizeof(float)));
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);

    glBindBuffer(GL_ARRAY_BUFFER, previousArrayBuffer);
    if (const auto bindVao = bindVertexArrayFn()) bindVao(static_cast<GLuint>(previousVao));
    glBindTexture(GL_TEXTURE_2D, static_cast<GLuint>(previousTexture));
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
    setError(std::string("ok ") + g_lastCaptureMethod
        + " fbo=" + std::to_string(g_lastCaptureFbo)
        + " drawFbo=" + std::to_string(drawFbo)
        + " size=" + std::to_string(g_lastTargetWidth) + "x" + std::to_string(g_lastTargetHeight)
        + " pot=" + std::to_string(g_potWidth) + "x" + std::to_string(g_potHeight)
        + " scale=" + std::to_string(g_texScaleX) + "," + std::to_string(g_texScaleY)
        + " vp=" + std::to_string(g_lastCopyX) + "," + std::to_string(g_lastCopyY)
        + " yflip=" + (g_inputYFlipped ? "1" : "0")
        + " tex=" + std::to_string(g_inputTexture)
        + " samp=" + std::to_string(record.textureLocation)
        + " texScaleLoc=" + std::to_string(record.texScaleLocation));
    return 7;
}

std::int32_t rpe_hlsl_target_width() {
    std::lock_guard lock(g_mutex);
    return g_lastTargetWidth;
}

std::int32_t rpe_hlsl_target_height() {
    std::lock_guard lock(g_mutex);
    return g_lastTargetHeight;
}

bool rpe_hlsl_end() {
    std::lock_guard lock(g_mutex);
    return true;
}

bool rpe_hlsl_release(std::int32_t handle) {
    std::lock_guard lock(g_mutex);
    const auto shaderIt = g_shaders.find(handle);
    if (shaderIt == g_shaders.end()) return false;
    destroyRecord(*shaderIt->second);
    g_shaders.erase(shaderIt);
    return true;
}

void rpe_hlsl_shutdown() {
    for (auto& [handle, record] : g_shaders) {
        (void)handle;
        if (record) destroyRecord(*record);
    }
    g_shaders.clear();
    if (g_quadVbo) {
        glDeleteBuffers(1, &g_quadVbo);
        g_quadVbo = 0;
    }
    if (g_vao) {
        const auto deleteVao = reinterpret_cast<DeleteVertexArraysFn>(eglGetProcAddress("glDeleteVertexArrays"));
        const auto deleteVaoOes = reinterpret_cast<DeleteVertexArraysFn>(eglGetProcAddress("glDeleteVertexArraysOES"));
        if (deleteVao) deleteVao(1, &g_vao);
        else if (deleteVaoOes) deleteVaoOes(1, &g_vao);
        g_vao = 0;
    }
    if (g_blitFbo) {
        glDeleteFramebuffers(1, &g_blitFbo);
        g_blitFbo = 0;
    }
    if (g_inputTexture) {
        glDeleteTextures(1, &g_inputTexture);
        g_inputTexture = 0;
    }
    g_potWidth = 0;
    g_potHeight = 0;
    g_texScaleX = 1.0f;
    g_texScaleY = 1.0f;
    g_inputCaptured = false;
    g_ready = false;
    g_translatedSource.clear();
}

std::string rpe_hlsl_get_error() {
    std::lock_guard lock(g_mutex);
    return g_error;
}
