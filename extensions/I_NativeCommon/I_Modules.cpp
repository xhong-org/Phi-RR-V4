#include <d3d11.h>
#include <d3d11shader.h>
#include <d3dcompiler.h>
#include <windows.h>

#if defined(I_SHADERS_BUILD)
#include "native/IShadersInternal_native.h"
#elif defined(I_PARALLEL_BUILD)
#include "native/IParallelInternal_native.h"
#elif defined(I_PULSE_BUILD)
#include "native/IPulseInternal_native.h"
#endif

#include <algorithm>
#include <atomic>
#include <condition_variable>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <functional>
#include <memory>
#include <mutex>
#include <sstream>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

namespace {
#if defined(I_PARALLEL_BUILD)
class WorkerPool {
public:
    WorkerPool() {
        const unsigned hardware = std::thread::hardware_concurrency();
        const unsigned count = std::clamp(hardware > 1 ? hardware - 1 : 1u, 1u, 8u);
        for (unsigned index = 0; index < count; ++index) workers.emplace_back([this] { workerLoop(); });
    }

    ~WorkerPool() {
        {
            std::lock_guard lock(mutex);
            stopping = true;
            ++generation;
        }
        start.notify_all();
        for (auto& worker : workers) if (worker.joinable()) worker.join();
    }

    void run(std::size_t count, std::function<void(std::size_t)> callback) {
        if (count == 0) return;
        if (count < 8 || workers.empty()) {
            for (std::size_t index = 0; index < count; ++index) callback(index);
            return;
        }
        {
            std::lock_guard lock(mutex);
            task = std::move(callback);
            itemCount = count;
            next.store(0, std::memory_order_relaxed);
            pending = workers.size();
            ++generation;
        }
        start.notify_all();
        processItems();
        std::unique_lock lock(mutex);
        finished.wait(lock, [this] { return pending == 0; });
        task = {};
    }

    std::int32_t size() const { return static_cast<std::int32_t>(workers.size()); }

private:
    void processItems() {
        while (true) {
            const std::size_t index = next.fetch_add(1, std::memory_order_relaxed);
            if (index >= itemCount) break;
            task(index);
        }
    }

    void workerLoop() {
        std::uint64_t seen = 0;
        while (true) {
            {
                std::unique_lock lock(mutex);
                start.wait(lock, [this, &seen] { return stopping || generation != seen; });
                if (stopping) return;
                seen = generation;
            }
            processItems();
            {
                std::lock_guard lock(mutex);
                if (--pending == 0) finished.notify_one();
            }
        }
    }

    std::vector<std::thread> workers;
    std::mutex mutex;
    std::condition_variable start;
    std::condition_variable finished;
    std::function<void(std::size_t)> task;
    std::atomic<std::size_t> next{0};
    std::size_t itemCount = 0;
    std::size_t pending = 0;
    std::uint64_t generation = 0;
    bool stopping = false;
};

std::unique_ptr<WorkerPool> g_workerPool;
std::vector<std::int32_t> g_lineParents;
std::vector<std::uint8_t> g_lineRotateWithParent;
std::vector<std::vector<std::int32_t>> g_lineLevels;
std::vector<double> g_lineWorldX;
std::vector<double> g_lineWorldY;
std::vector<double> g_lineWorldR;
#endif

#if defined(I_PULSE_BUILD)
HWND g_dragWindow = nullptr;
WNDPROC g_previousWindowProc = nullptr;
bool g_windowDragging = false;
bool g_windowResizing = false;
WPARAM g_resizeHitTest = HTNOWHERE;
POINT g_dragStartCursor{};
RECT g_dragStartRect{};
SIZE g_resizeMinTrackSize{};

bool isResizeHitTest(WPARAM hitTest) {
    return hitTest == HTLEFT || hitTest == HTRIGHT || hitTest == HTTOP || hitTest == HTBOTTOM
        || hitTest == HTTOPLEFT || hitTest == HTTOPRIGHT
        || hitTest == HTBOTTOMLEFT || hitTest == HTBOTTOMRIGHT;
}

HCURSOR resizeCursor(WPARAM hitTest) {
    if (hitTest == HTLEFT || hitTest == HTRIGHT) return LoadCursorA(nullptr, IDC_SIZEWE);
    if (hitTest == HTTOP || hitTest == HTBOTTOM) return LoadCursorA(nullptr, IDC_SIZENS);
    if (hitTest == HTTOPLEFT || hitTest == HTBOTTOMRIGHT) return LoadCursorA(nullptr, IDC_SIZENWSE);
    if (hitTest == HTTOPRIGHT || hitTest == HTBOTTOMLEFT) return LoadCursorA(nullptr, IDC_SIZENESW);
    return LoadCursorA(nullptr, IDC_ARROW);
}

void stopWindowInteraction(HWND window) {
    g_windowDragging = false;
    g_windowResizing = false;
    g_resizeHitTest = HTNOWHERE;
    if (GetCapture() == window) ReleaseCapture();
}

LRESULT CALLBACK rpeWindowProc(HWND window, UINT message, WPARAM wParam, LPARAM lParam) {
    if (message == WM_NCLBUTTONDOWN && !IsZoomed(window)) {
        if (wParam == HTCAPTION || isResizeHitTest(wParam)) {
            g_windowDragging = wParam == HTCAPTION;
            g_windowResizing = isResizeHitTest(wParam);
            g_resizeHitTest = g_windowResizing ? wParam : HTNOWHERE;
            GetCursorPos(&g_dragStartCursor);
            GetWindowRect(window, &g_dragStartRect);
            if (g_windowResizing) {
                MINMAXINFO limits{};
                if (g_previousWindowProc) {
                    CallWindowProcW(g_previousWindowProc, window, WM_GETMINMAXINFO, 0,
                        reinterpret_cast<LPARAM>(&limits));
                }
                g_resizeMinTrackSize.cx = std::max<LONG>(
                    GetSystemMetrics(SM_CXMINTRACK), limits.ptMinTrackSize.x);
                g_resizeMinTrackSize.cy = std::max<LONG>(
                    GetSystemMetrics(SM_CYMINTRACK), limits.ptMinTrackSize.y);
                SetCursor(resizeCursor(g_resizeHitTest));
            }
            SetCapture(window);
            return 0;
        }
    }
    if ((message == WM_MOUSEMOVE || message == WM_NCMOUSEMOVE)
        && (g_windowDragging || g_windowResizing) && GetCapture() == window) {
        POINT cursor{};
        GetCursorPos(&cursor);
        const LONG deltaX = cursor.x - g_dragStartCursor.x;
        const LONG deltaY = cursor.y - g_dragStartCursor.y;
        if (g_windowDragging) {
            SetWindowPos(window, nullptr,
                g_dragStartRect.left + deltaX, g_dragStartRect.top + deltaY,
                0, 0, SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOOWNERZORDER);
        } else {
            RECT resized = g_dragStartRect;
            if (g_resizeHitTest == HTLEFT || g_resizeHitTest == HTTOPLEFT || g_resizeHitTest == HTBOTTOMLEFT) {
                resized.left += deltaX;
            }
            if (g_resizeHitTest == HTRIGHT || g_resizeHitTest == HTTOPRIGHT || g_resizeHitTest == HTBOTTOMRIGHT) {
                resized.right += deltaX;
            }
            if (g_resizeHitTest == HTTOP || g_resizeHitTest == HTTOPLEFT || g_resizeHitTest == HTTOPRIGHT) {
                resized.top += deltaY;
            }
            if (g_resizeHitTest == HTBOTTOM || g_resizeHitTest == HTBOTTOMLEFT || g_resizeHitTest == HTBOTTOMRIGHT) {
                resized.bottom += deltaY;
            }

            if (resized.right - resized.left < g_resizeMinTrackSize.cx) {
                if (g_resizeHitTest == HTLEFT || g_resizeHitTest == HTTOPLEFT || g_resizeHitTest == HTBOTTOMLEFT) {
                    resized.left = resized.right - g_resizeMinTrackSize.cx;
                } else {
                    resized.right = resized.left + g_resizeMinTrackSize.cx;
                }
            }
            if (resized.bottom - resized.top < g_resizeMinTrackSize.cy) {
                if (g_resizeHitTest == HTTOP || g_resizeHitTest == HTTOPLEFT || g_resizeHitTest == HTTOPRIGHT) {
                    resized.top = resized.bottom - g_resizeMinTrackSize.cy;
                } else {
                    resized.bottom = resized.top + g_resizeMinTrackSize.cy;
                }
            }

            SetCursor(resizeCursor(g_resizeHitTest));
            SetWindowPos(window, nullptr, resized.left, resized.top,
                resized.right - resized.left, resized.bottom - resized.top,
                SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOOWNERZORDER);
        }
        return 0;
    }
    if ((message == WM_LBUTTONUP || message == WM_NCLBUTTONUP)
        && (g_windowDragging || g_windowResizing)) {
        stopWindowInteraction(window);
        return 0;
    }
    if (message == WM_CAPTURECHANGED || message == WM_CANCELMODE) {
        g_windowDragging = false;
        g_windowResizing = false;
        g_resizeHitTest = HTNOWHERE;
    }
    return g_previousWindowProc ? CallWindowProcW(g_previousWindowProc, window, message, wParam, lParam)
        : DefWindowProcW(window, message, wParam, lParam);
}
#endif

#if defined(I_SHADERS_BUILD)
struct UniformInfo {
    UINT offset = 0;
    UINT size = 0;
};

struct ShaderRecord {
    ID3D11PixelShader* shader = nullptr;
    ID3D11VertexShader* vertexShader = nullptr;
    ID3D11InputLayout* inputLayout = nullptr;
    ID3D11Buffer* vertexConstants = nullptr;
    UINT vertexConstantSlot = 0;
    UINT vertexMatrixOffset = UINT_MAX;
    std::vector<std::uint8_t> vertexConstantData;
    ID3D11Buffer* constants = nullptr;
    UINT constantSlot = 2;
    std::vector<std::uint8_t> constantData;
    std::unordered_map<std::string, UniformInfo> uniforms;

    ~ShaderRecord() {
        if (inputLayout) inputLayout->Release();
        if (vertexShader) vertexShader->Release();
        if (vertexConstants) vertexConstants->Release();
        if (constants) constants->Release();
        if (shader) shader->Release();
    }
};

ID3D11Device* g_device = nullptr;
ID3D11DeviceContext* g_context = nullptr;
std::unordered_map<int, std::unique_ptr<ShaderRecord>> g_shaders;
int g_nextHandle = 1;
std::string g_lastError;
std::string g_translatedSource;
std::string g_translatedVertexSource;
ID3D11PixelShader* g_previousShader = nullptr;
ID3D11Buffer* g_previousConstants = nullptr;
ID3D11VertexShader* g_fullscreenVertexShader = nullptr;
ID3D11RasterizerState* g_fullscreenRasterizer = nullptr;
ID3D11DepthStencilState* g_fullscreenDepthStencil = nullptr;
ID3D11BlendState* g_fullscreenBlend = nullptr;
UINT g_previousSlot = 0;
bool g_active = false;
std::int32_t g_lastTargetWidth = 0;
std::int32_t g_lastTargetHeight = 0;
extern "C" IMAGE_DOS_HEADER __ImageBase;

void setError(const std::string& value) { g_lastError = value; }

std::uintptr_t parsePointer(std::string_view text) {
    if (text.empty()) return 0;
    try {
		std::string value(text);
		if (value.rfind("0x", 0) == 0 || value.rfind("0X", 0) == 0) value.erase(0, 2);
		return static_cast<std::uintptr_t>(std::stoull(value, nullptr, 16));
    } catch (...) {
        return 0;
    }
}

std::string blobText(ID3DBlob* blob) {
    if (!blob || !blob->GetBufferPointer() || blob->GetBufferSize() == 0) return {};
    return std::string(static_cast<const char*>(blob->GetBufferPointer()), blob->GetBufferSize());
}

std::string trim(const std::string& value) {
    const auto start = value.find_first_not_of(" \t\r\n");
    if (start == std::string::npos) return {};
    const auto end = value.find_last_not_of(" \t\r\n");
    return value.substr(start, end - start + 1);
}

bool writeResource(int id, const std::filesystem::path& output) {
    HMODULE module = reinterpret_cast<HMODULE>(&__ImageBase);
    HRSRC resource = FindResourceW(module, MAKEINTRESOURCEW(id), MAKEINTRESOURCEW(10));
    if (!resource) return false;
    HGLOBAL loaded = LoadResource(module, resource);
    const void* data = LockResource(loaded);
    const DWORD size = SizeofResource(module, resource);
    if (!data || !size) return false;
    std::ofstream stream(output, std::ios::binary | std::ios::trunc);
    stream.write(static_cast<const char*>(data), size);
    return stream.good();
}

std::filesystem::path ensureCompiler() {
    const auto root = std::filesystem::temp_directory_path() / "PhigrosLoaderRPEShaderCompiler";
    std::filesystem::create_directories(root);
    const std::pair<int, const wchar_t*> files[] = {
        {101, L"HLSLCompiler.exe"}, {102, L"FShaderCommon.shader"},
        {103, L"HLSL11_PShaderCommon.shader"}, {104, L"HLSL11_VShaderCommon.shader"},
        {105, L"VShaderCommon.shader"}, {106, L"d3dcompiler_46.dll"},
        {107, L"libEGL.dll"}, {108, L"libGLESv2.dll"}
    };
    for (const auto& [id, name] : files) {
        const auto path = root / name;
        if (!std::filesystem::exists(path) && !writeResource(id, path)) return {};
    }
    return root;
}

std::string replaceAll(std::string value, const std::string& from, const std::string& to) {
    std::size_t position = 0;
    while ((position = value.find(from, position)) != std::string::npos) {
        value.replace(position, from.size(), to);
        position += to.size();
    }
    return value;
}

std::string convertUniforms(const std::string& source) {
    // Render-target post effects have no useful mip chain. Explicit LOD also keeps
    // translated GLSL texture reads valid inside runtime-bounded HLSL loops.
    const std::string compatibleSource = replaceAll(source,
        "return t.Sample(s, uv);", "return t.SampleLevel(s, uv, 0);");
    std::istringstream input(compatibleSource);
    std::ostringstream body;
    std::ostringstream constants;
    std::string line;
    while (std::getline(input, line)) {
        const std::string clean = trim(line);
        if (clean.rfind("uniform ", 0) == 0) {
            const bool runnerUniform = clean.find("_gm_") != std::string::npos
                || clean.find("sampler__gm_BaseTexture") != std::string::npos
                || clean.find("texture__gm_BaseTexture") != std::string::npos;
            if (!runnerUniform) {
                std::string declaration = clean.substr(8);
                const auto semicolon = declaration.find(';');
                if (semicolon != std::string::npos) declaration.resize(semicolon + 1);
				const auto registerSemantic = declaration.find(": register(");
				if (registerSemantic != std::string::npos) declaration = trim(declaration.substr(0, registerSemantic)) + ";";
                constants << declaration << '\n';
                continue;
            }
        }
        if (clean.rfind("for", 0) == 0) body << "[loop]\n";
        body << line << '\n';
    }
    return "cbuffer RPEExternalUniforms : register(b2) {\n" + constants.str() + "};\n" + body.str();
}

void restoreState() {
    if (!g_active || !g_context) return;
    g_context->PSSetShader(g_previousShader, nullptr, 0);
    g_context->PSSetConstantBuffers(g_previousSlot, 1, &g_previousConstants);
    if (g_previousConstants) g_previousConstants->Release();
    if (g_previousShader) g_previousShader->Release();
    g_previousConstants = nullptr;
    g_previousShader = nullptr;
    g_active = false;
}
#endif
}

#if defined(I_SHADERS_BUILD)
std::string rpe_glsl_translate(std::string_view source, std::string_view sourceName) {
    g_translatedSource.clear();
    g_translatedVertexSource.clear();
    if (source.empty()) {
        setError("External GLSL source is empty.");
        return g_translatedSource;
    }
    const auto compilerRoot = ensureCompiler();
    if (compilerRoot.empty()) {
        setError("Failed to extract the embedded YoYo HLSLCompiler.");
        return g_translatedSource;
    }

    std::string fragment = replaceAll(std::string(source), "#version 100", "");
    fragment = replaceAll(fragment, "uniform sampler2D screenTexture;", "#define screenTexture (gm_BaseTexture)");
    static const char* vertex = R"GLSL(attribute vec3 position;
attribute vec4 color0;
attribute vec2 texcoord;
varying vec2 uv;
varying vec4 SB;
mat4 transpose4(mat4 m) {
    return mat4(m[0][0],m[1][0],m[2][0],m[3][0],m[0][1],m[1][1],m[2][1],m[3][1],m[0][2],m[1][2],m[2][2],m[3][2],m[0][3],m[1][3],m[2][3],m[3][3]);
}
void main() {
    gl_Position = transpose4(gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION]) * vec4(position, 1.0);
    uv = texcoord;
    SB = color0;
}
)GLSL";

    const auto jobRoot = compilerRoot / ("job_" + std::to_string(GetCurrentProcessId()));
    std::filesystem::remove_all(jobRoot);
    std::filesystem::create_directories(jobRoot / "out");
    const auto inputPath = jobRoot / "external.shader";
    std::ofstream inputFile(inputPath, std::ios::binary | std::ios::trunc);
    inputFile << vertex << "//######################_==_YOYO_SHADER_MARKER_==_######################@~" << fragment;
    inputFile.close();

    std::wstring command = L"\"" + (compilerRoot / "HLSLCompiler.exe").wstring()
        + L"\" -hlsl11 -shader \"" + inputPath.wstring()
        + L"\" -name \"" + std::filesystem::path(sourceName.empty() ? "external" : std::string(sourceName)).stem().wstring()
        + L"\" -out \"" + (jobRoot / "out").wstring()
        + L"\" -preamble \"" + compilerRoot.wstring()
        + L"\" -typedefine \"#define _YY_HLSL11_ 1\"";
    std::vector<wchar_t> mutableCommand(command.begin(), command.end());
    mutableCommand.push_back(L'\0');
    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    PROCESS_INFORMATION process{};
    const BOOL started = CreateProcessW(nullptr, mutableCommand.data(), nullptr, nullptr, FALSE,
        CREATE_NO_WINDOW, nullptr, compilerRoot.c_str(), &startup, &process);
    if (!started) {
        setError("Failed to start the embedded YoYo HLSLCompiler.");
        return g_translatedSource;
    }
    WaitForSingleObject(process.hProcess, 30000);
    CloseHandle(process.hThread);
    CloseHandle(process.hProcess);

    const auto outputPath = jobRoot / "out" / "fout.shader";
    std::ifstream outputFile(outputPath, std::ios::binary);
    if (!outputFile) {
        setError("YoYo HLSLCompiler did not produce fout.shader.");
        return g_translatedSource;
    }
    std::ostringstream outputText;
    outputText << outputFile.rdbuf();
    g_translatedSource = convertUniforms(outputText.str());
    std::ifstream vertexOutputFile(jobRoot / "out" / "vout.shader", std::ios::binary);
    if (vertexOutputFile) {
        std::ostringstream vertexOutputText;
        vertexOutputText << vertexOutputFile.rdbuf();
        g_translatedVertexSource = vertexOutputText.str();
    }
    if (g_translatedSource.empty()) setError("YoYo HLSLCompiler returned an empty pixel shader.");
    else setError({});
    return g_translatedSource;
}

std::int32_t rpe_hlsl_initialize(void* devicePointer, void* contextPointer) {
    rpe_hlsl_shutdown();
    g_device = static_cast<ID3D11Device*>(devicePointer);
    g_context = static_cast<ID3D11DeviceContext*>(contextPointer);
    if (!g_device || !g_context) {
        setError("Invalid D3D11 device or context pointer.");
        return (g_device ? 1 : 0) | (g_context ? 2 : 0);
    }
    static constexpr char fullscreenVertexSource[] = R"HLSL(
struct VSOutput {
    float4 position : SV_Position;
    float2 texcoord : TEXCOORD0;
};
VSOutput main(uint vertexId : SV_VertexID) {
    VSOutput output;
    static const float2 vertices[6] = {
        float2(0.0, 0.0), float2(1.0, 0.0), float2(0.0, 1.0),
        float2(0.0, 1.0), float2(1.0, 0.0), float2(1.0, 1.0)
    };
    float2 uv = vertices[vertexId];
    output.position = float4(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0, 0.0, 1.0);
    output.texcoord = float2(uv.x, 1.0 - uv.y);
    return output;
}
)HLSL";
    ID3DBlob* vertexBytecode = nullptr;
    ID3DBlob* vertexErrors = nullptr;
    HRESULT vertexResult = D3DCompile(fullscreenVertexSource, sizeof(fullscreenVertexSource) - 1,
        "RPEFullscreenVS", nullptr, nullptr, "main", "vs_4_0",
        D3DCOMPILE_ENABLE_STRICTNESS | D3DCOMPILE_OPTIMIZATION_LEVEL3, 0,
        &vertexBytecode, &vertexErrors);
    if (FAILED(vertexResult) || !vertexBytecode) {
        setError("Failed to compile the external shader fullscreen vertex shader: " + blobText(vertexErrors));
        if (vertexErrors) vertexErrors->Release();
        if (vertexBytecode) vertexBytecode->Release();
        return -1;
    }
    vertexResult = g_device->CreateVertexShader(vertexBytecode->GetBufferPointer(),
        vertexBytecode->GetBufferSize(), nullptr, &g_fullscreenVertexShader);
    vertexBytecode->Release();
    if (vertexErrors) vertexErrors->Release();
    if (FAILED(vertexResult) || !g_fullscreenVertexShader) {
        setError("Failed to create the external shader fullscreen vertex shader.");
        return -1;
    }
    D3D11_RASTERIZER_DESC rasterizerDesc{};
    rasterizerDesc.FillMode = D3D11_FILL_SOLID;
    rasterizerDesc.CullMode = D3D11_CULL_NONE;
    rasterizerDesc.DepthClipEnable = TRUE;
    if (FAILED(g_device->CreateRasterizerState(&rasterizerDesc, &g_fullscreenRasterizer))) return -1;
    D3D11_DEPTH_STENCIL_DESC depthStencilDesc{};
    depthStencilDesc.DepthEnable = FALSE;
    depthStencilDesc.StencilEnable = FALSE;
    if (FAILED(g_device->CreateDepthStencilState(&depthStencilDesc, &g_fullscreenDepthStencil))) return -1;
    D3D11_BLEND_DESC blendDesc{};
    blendDesc.RenderTarget[0].RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_ALL;
    if (FAILED(g_device->CreateBlendState(&blendDesc, &g_fullscreenBlend))) return -1;
    setError({});
    return 3;
}

std::int32_t rpe_hlsl_state() {
    return 202607257 + (g_device ? 1 : 0) + (g_context ? 2 : 0);
}

std::int32_t rpe_hlsl_compile(std::string_view source, std::string_view sourceName) {
    if (!g_device || !g_context || source.empty()) {
        setError("RPE HLSL backend is not initialized.");
        return -1;
    }

    ID3DBlob* bytecode = nullptr;
    ID3DBlob* errors = nullptr;
    const UINT flags = D3DCOMPILE_ENABLE_STRICTNESS | D3DCOMPILE_OPTIMIZATION_LEVEL3;
    const std::string sourceCopy(source);
    const std::string sourceNameCopy = sourceName.empty() ? "external.hlsl" : std::string(sourceName);
    const HRESULT compileResult = D3DCompile(sourceCopy.data(), sourceCopy.size(),
        sourceNameCopy.c_str(), nullptr, nullptr, "main", "ps_4_0",
        flags, 0, &bytecode, &errors);
    if (FAILED(compileResult)) {
        setError(blobText(errors));
        if (errors) errors->Release();
        if (bytecode) bytecode->Release();
        return -1;
    }
    if (errors) errors->Release();

    auto record = std::make_unique<ShaderRecord>();
    HRESULT result = g_device->CreatePixelShader(bytecode->GetBufferPointer(),
        bytecode->GetBufferSize(), nullptr, &record->shader);
    if (FAILED(result)) {
        bytecode->Release();
        setError("ID3D11Device::CreatePixelShader failed.");
        return -1;
    }

    if (!g_translatedVertexSource.empty()) {
        ID3DBlob* vertexBytecode = nullptr;
        ID3DBlob* vertexErrors = nullptr;
        result = D3DCompile(g_translatedVertexSource.data(), g_translatedVertexSource.size(),
            sourceNameCopy.c_str(), nullptr, nullptr, "main", "vs_4_0", flags, 0,
            &vertexBytecode, &vertexErrors);
        if (SUCCEEDED(result) && vertexBytecode) {
            result = g_device->CreateVertexShader(vertexBytecode->GetBufferPointer(),
                vertexBytecode->GetBufferSize(), nullptr, &record->vertexShader);
            const D3D11_INPUT_ELEMENT_DESC elements[] = {
                {"TEXCOORD", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D11_INPUT_PER_VERTEX_DATA, 0},
                {"TEXCOORD", 1, DXGI_FORMAT_R32G32B32A32_FLOAT, 0, 12, D3D11_INPUT_PER_VERTEX_DATA, 0},
                {"TEXCOORD", 2, DXGI_FORMAT_R32G32_FLOAT, 0, 28, D3D11_INPUT_PER_VERTEX_DATA, 0}
            };
            if (SUCCEEDED(result)) {
                result = g_device->CreateInputLayout(elements, 3, vertexBytecode->GetBufferPointer(),
                    vertexBytecode->GetBufferSize(), &record->inputLayout);
            }
            ID3D11ShaderReflection* vertexReflection = nullptr;
            if (SUCCEEDED(result) && SUCCEEDED(D3DReflect(vertexBytecode->GetBufferPointer(),
                vertexBytecode->GetBufferSize(), IID_ID3D11ShaderReflection,
                reinterpret_cast<void**>(&vertexReflection))) && vertexReflection) {
                ID3D11ShaderReflectionVariable* matrices = vertexReflection->GetVariableByName("_gm_Matrices");
                D3D11_SHADER_VARIABLE_DESC matrixDesc{};
                if (matrices && SUCCEEDED(matrices->GetDesc(&matrixDesc))) {
                    ID3D11ShaderReflectionConstantBuffer* vertexBuffer = matrices->GetBuffer();
                    D3D11_SHADER_BUFFER_DESC vertexBufferDesc{};
                    if (vertexBuffer && SUCCEEDED(vertexBuffer->GetDesc(&vertexBufferDesc))) {
                        D3D11_SHADER_INPUT_BIND_DESC vertexBindDesc{};
                        if (SUCCEEDED(vertexReflection->GetResourceBindingDescByName(vertexBufferDesc.Name, &vertexBindDesc))) {
                            record->vertexConstantSlot = vertexBindDesc.BindPoint;
                            record->vertexMatrixOffset = matrixDesc.StartOffset + 4u * 16u * sizeof(float);
                            record->vertexConstantData.resize((vertexBufferDesc.Size + 15u) & ~15u, 0);
                            D3D11_BUFFER_DESC vertexNativeDesc{};
                            vertexNativeDesc.ByteWidth = static_cast<UINT>(record->vertexConstantData.size());
                            vertexNativeDesc.Usage = D3D11_USAGE_DEFAULT;
                            vertexNativeDesc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
                            g_device->CreateBuffer(&vertexNativeDesc, nullptr, &record->vertexConstants);
                        }
                    }
                }
                vertexReflection->Release();
            }
        }
        if (vertexErrors) vertexErrors->Release();
        if (vertexBytecode) vertexBytecode->Release();
        if (FAILED(result) || !record->vertexShader || !record->inputLayout) {
            setError("Failed to compile or create the translated vertex shader.");
            return -1;
        }
    }

    ID3D11ShaderReflection* reflection = nullptr;
    result = D3DReflect(bytecode->GetBufferPointer(), bytecode->GetBufferSize(),
        IID_ID3D11ShaderReflection, reinterpret_cast<void**>(&reflection));
    bytecode->Release();
    if (SUCCEEDED(result) && reflection) {
        D3D11_SHADER_DESC shaderDesc{};
        reflection->GetDesc(&shaderDesc);
        for (UINT bufferIndex = 0; bufferIndex < shaderDesc.ConstantBuffers; ++bufferIndex) {
            ID3D11ShaderReflectionConstantBuffer* reflectedBuffer = reflection->GetConstantBufferByIndex(bufferIndex);
            D3D11_SHADER_BUFFER_DESC bufferDesc{};
            if (FAILED(reflectedBuffer->GetDesc(&bufferDesc)) || bufferDesc.Type != D3D_CT_CBUFFER) continue;
            D3D11_SHADER_INPUT_BIND_DESC bindDesc{};
            if (FAILED(reflection->GetResourceBindingDescByName(bufferDesc.Name, &bindDesc))) continue;

            record->constantSlot = bindDesc.BindPoint;
            record->constantData.resize((bufferDesc.Size + 15u) & ~15u, 0);
            for (UINT variableIndex = 0; variableIndex < bufferDesc.Variables; ++variableIndex) {
                ID3D11ShaderReflectionVariable* variable = reflectedBuffer->GetVariableByIndex(variableIndex);
                D3D11_SHADER_VARIABLE_DESC variableDesc{};
                if (SUCCEEDED(variable->GetDesc(&variableDesc))) {
                    record->uniforms[variableDesc.Name] = {variableDesc.StartOffset, variableDesc.Size};
                }
            }

            D3D11_BUFFER_DESC nativeBufferDesc{};
            nativeBufferDesc.ByteWidth = static_cast<UINT>(record->constantData.size());
            nativeBufferDesc.Usage = D3D11_USAGE_DEFAULT;
            nativeBufferDesc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
            result = g_device->CreateBuffer(&nativeBufferDesc, nullptr, &record->constants);
            if (FAILED(result)) {
                reflection->Release();
                setError("Failed to create the external shader constant buffer.");
                return -1;
            }
            break;
        }
        reflection->Release();
    }

    const int handle = g_nextHandle++;
    g_shaders.emplace(handle, std::move(record));
    g_translatedVertexSource.clear();
    setError({});
    return handle;
}

bool rpe_hlsl_set_uniform_component(std::int32_t handle, std::string_view name,
    std::int32_t component, float value) {
    const auto shaderIt = g_shaders.find(handle);
    if (shaderIt == g_shaders.end() || name.empty() || component < 0 || component > 3) return false;
    ShaderRecord& record = *shaderIt->second;
    const std::string uniformName(name);
    const auto uniformIt = record.uniforms.find(uniformName);
    auto resolvedUniform = uniformIt;
    if (resolvedUniform == record.uniforms.end()) resolvedUniform = record.uniforms.find("_" + uniformName);
    if (resolvedUniform == record.uniforms.end()) return false;
    const UINT componentOffset = static_cast<UINT>(component) * sizeof(float);
    if (componentOffset + sizeof(float) > resolvedUniform->second.size
        || resolvedUniform->second.offset + componentOffset + sizeof(float) > record.constantData.size()) return false;
    std::memcpy(record.constantData.data() + resolvedUniform->second.offset + componentOffset, &value, sizeof(float));
    return true;
}

bool rpe_hlsl_begin(std::int32_t handle) {
    restoreState();
    const auto shaderIt = g_shaders.find(handle);
    if (!g_context || shaderIt == g_shaders.end()) return false;
    ShaderRecord& record = *shaderIt->second;
    g_previousSlot = record.constantSlot;
    g_context->PSGetShader(&g_previousShader, nullptr, nullptr);
    g_context->PSGetConstantBuffers(g_previousSlot, 1, &g_previousConstants);
    if (record.constants && !record.constantData.empty()) {
        g_context->UpdateSubresource(record.constants, 0, nullptr, record.constantData.data(), 0, 0);
        g_context->PSSetConstantBuffers(record.constantSlot, 1, &record.constants);
    }
    g_context->PSSetShader(record.shader, nullptr, 0);
    g_active = true;
    return true;
}

std::int32_t rpe_hlsl_draw(std::int32_t handle, float uvLeft, float uvTop,
    float uvRight, float uvBottom) {
    restoreState();
    const auto shaderIt = g_shaders.find(handle);
    if (!g_context || !g_fullscreenVertexShader || shaderIt == g_shaders.end()) return 0;
    ShaderRecord& record = *shaderIt->second;

    ID3D11ShaderResourceView* sourceView = nullptr;
    g_context->PSGetShaderResources(0, 1, &sourceView);
    if (!sourceView) return 1;

    ID3D11VertexShader* previousVertexShader = nullptr;
    ID3D11PixelShader* previousPixelShader = nullptr;
    ID3D11InputLayout* previousInputLayout = nullptr;
    ID3D11Buffer* previousConstants = nullptr;
    ID3D11Buffer* previousVertexBuffer = nullptr;
    ID3D11Buffer* previousVertexConstants = nullptr;
    UINT previousVertexStride = 0;
    UINT previousVertexOffset = 0;
    D3D11_PRIMITIVE_TOPOLOGY previousTopology{};
    UINT previousViewportCount = D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE;
    D3D11_VIEWPORT previousViewports[D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE]{};
    ID3D11RenderTargetView* targetView = nullptr;
    ID3D11RasterizerState* previousRasterizer = nullptr;
    ID3D11DepthStencilState* previousDepthStencil = nullptr;
    ID3D11BlendState* previousBlend = nullptr;
    UINT previousStencilRef = 0;
    FLOAT previousBlendFactor[4]{};
    UINT previousSampleMask = 0;
    g_context->VSGetShader(&previousVertexShader, nullptr, nullptr);
    g_context->PSGetShader(&previousPixelShader, nullptr, nullptr);
    g_context->IAGetInputLayout(&previousInputLayout);
    g_context->IAGetPrimitiveTopology(&previousTopology);
    g_context->IAGetVertexBuffers(0, 1, &previousVertexBuffer, &previousVertexStride, &previousVertexOffset);
    if (record.vertexConstants) g_context->VSGetConstantBuffers(record.vertexConstantSlot, 1, &previousVertexConstants);
    g_context->RSGetViewports(&previousViewportCount, previousViewports);
    g_context->OMGetRenderTargets(1, &targetView, nullptr);
    g_context->RSGetState(&previousRasterizer);
    g_context->OMGetDepthStencilState(&previousDepthStencil, &previousStencilRef);
    g_context->OMGetBlendState(&previousBlend, previousBlendFactor, &previousSampleMask);
    g_context->PSGetConstantBuffers(record.constantSlot, 1, &previousConstants);

    float viewportOffsetX = 0.0f;
    float viewportOffsetY = 0.0f;
    float viewportWidth = 0.0f;
    float viewportHeight = 0.0f;
    if (targetView) {
        ID3D11Resource* targetResource = nullptr;
        targetView->GetResource(&targetResource);
        if (targetResource) {
            ID3D11Texture2D* targetTexture = nullptr;
            if (SUCCEEDED(targetResource->QueryInterface(__uuidof(ID3D11Texture2D),
                reinterpret_cast<void**>(&targetTexture))) && targetTexture) {
                D3D11_TEXTURE2D_DESC targetDesc{};
                targetTexture->GetDesc(&targetDesc);
                g_lastTargetWidth = static_cast<std::int32_t>(targetDesc.Width);
                g_lastTargetHeight = static_cast<std::int32_t>(targetDesc.Height);
                D3D11_VIEWPORT viewport{};
                viewport.TopLeftX = uvLeft * static_cast<float>(targetDesc.Width);
                viewport.TopLeftY = uvTop * static_cast<float>(targetDesc.Height);
                viewport.Width = (uvRight - uvLeft) * static_cast<float>(targetDesc.Width);
                viewport.Height = (uvBottom - uvTop) * static_cast<float>(targetDesc.Height);
                viewport.MinDepth = 0.0f;
                viewport.MaxDepth = 1.0f;
                if (viewport.Width > 0.0f && viewport.Height > 0.0f) {
                    viewportOffsetX = viewport.TopLeftX;
                    viewportOffsetY = viewport.TopLeftY;
                    viewportWidth = viewport.Width;
                    viewportHeight = viewport.Height;
                    g_context->RSSetViewports(1, &viewport);
                }
                targetTexture->Release();
            }
            targetResource->Release();
        }
    }

    const auto boundsIt = record.uniforms.find("_rpeTextureBounds");
    if (boundsIt != record.uniforms.end() && boundsIt->second.offset + 4 * sizeof(float) <= record.constantData.size()) {
        const float bounds[4] = {uvLeft, uvTop, uvRight, uvBottom};
        std::memcpy(record.constantData.data() + boundsIt->second.offset, bounds, sizeof(bounds));
    }
    const auto offsetIt = record.uniforms.find("_rpeFragOffset");
    if (offsetIt != record.uniforms.end() && offsetIt->second.offset + 2 * sizeof(float) <= record.constantData.size()) {
        const float offset[2] = {viewportOffsetX, viewportOffsetY};
        std::memcpy(record.constantData.data() + offsetIt->second.offset, offset, sizeof(offset));
    }
    const auto viewportIt = record.uniforms.find("_rpeViewportSize");
    if (viewportIt != record.uniforms.end() && viewportIt->second.offset + 2 * sizeof(float) <= record.constantData.size()) {
        const float viewportSize[2] = {viewportWidth, viewportHeight};
        std::memcpy(record.constantData.data() + viewportIt->second.offset, viewportSize, sizeof(viewportSize));
    }
    auto screenSizeIt = record.uniforms.find("screenSize");
    if (screenSizeIt == record.uniforms.end()) screenSizeIt = record.uniforms.find("_screenSize");
    if (screenSizeIt != record.uniforms.end() && screenSizeIt->second.offset + 2 * sizeof(float) <= record.constantData.size()) {
        const float physicalScreenSize[2] = {viewportWidth, viewportHeight};
        std::memcpy(record.constantData.data() + screenSizeIt->second.offset, physicalScreenSize, sizeof(physicalScreenSize));
    }

    if (record.constants && !record.constantData.empty()) {
        g_context->UpdateSubresource(record.constants, 0, nullptr, record.constantData.data(), 0, 0);
        g_context->PSSetConstantBuffers(record.constantSlot, 1, &record.constants);
    }
    if (record.vertexConstants && record.vertexMatrixOffset != UINT_MAX
        && record.vertexMatrixOffset + 16 * sizeof(float) <= record.vertexConstantData.size()) {
        const float matrix[16] = {
            2.0f / viewportWidth, 0, 0, 0,
            0, -2.0f / viewportHeight, 0, 0,
            0, 0, 1, 0,
            -1, 1, 0, 1
        };
        std::memcpy(record.vertexConstantData.data() + record.vertexMatrixOffset, matrix, sizeof(matrix));
        g_context->UpdateSubresource(record.vertexConstants, 0, nullptr,
            record.vertexConstantData.data(), 0, 0);
        g_context->VSSetConstantBuffers(record.vertexConstantSlot, 1, &record.vertexConstants);
    }
    ID3D11Buffer* quadBuffer = nullptr;
    if (record.vertexShader && record.inputLayout) {
        struct QuadVertex { float position[3]; float colour[4]; float uv[2]; };
        const QuadVertex vertices[4] = {
            {{0, 0, 0}, {1, 1, 1, 1}, {0, 0}},
            {{viewportWidth, 0, 0}, {1, 1, 1, 1}, {1, 0}},
            {{0, viewportHeight, 0}, {1, 1, 1, 1}, {0, 1}},
            {{viewportWidth, viewportHeight, 0}, {1, 1, 1, 1}, {1, 1}}
        };
        D3D11_BUFFER_DESC quadDesc{};
        quadDesc.ByteWidth = sizeof(vertices);
        quadDesc.Usage = D3D11_USAGE_IMMUTABLE;
        quadDesc.BindFlags = D3D11_BIND_VERTEX_BUFFER;
        D3D11_SUBRESOURCE_DATA quadData{};
        quadData.pSysMem = vertices;
        if (FAILED(g_device->CreateBuffer(&quadDesc, &quadData, &quadBuffer))) quadBuffer = nullptr;
    }
    const UINT quadStride = 9 * sizeof(float);
    const UINT quadOffset = 0;
    g_context->IASetInputLayout(record.inputLayout);
    g_context->IASetPrimitiveTopology(record.vertexShader
        ? D3D11_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP : D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    if (quadBuffer) g_context->IASetVertexBuffers(0, 1, &quadBuffer, &quadStride, &quadOffset);
    g_context->RSSetState(g_fullscreenRasterizer);
    g_context->OMSetDepthStencilState(g_fullscreenDepthStencil, 0);
    const FLOAT blendFactor[4] = {0.0f, 0.0f, 0.0f, 0.0f};
    g_context->OMSetBlendState(g_fullscreenBlend, blendFactor, 0xffffffffu);
    g_context->VSSetShader(record.vertexShader ? record.vertexShader : g_fullscreenVertexShader, nullptr, 0);
    g_context->PSSetShader(record.shader, nullptr, 0);
    g_context->Draw(record.vertexShader ? 4 : 6, 0);

    g_context->PSSetShader(previousPixelShader, nullptr, 0);
    g_context->VSSetShader(previousVertexShader, nullptr, 0);
    g_context->IASetInputLayout(previousInputLayout);
    g_context->IASetPrimitiveTopology(previousTopology);
    g_context->IASetVertexBuffers(0, 1, &previousVertexBuffer, &previousVertexStride, &previousVertexOffset);
    g_context->RSSetState(previousRasterizer);
    g_context->OMSetDepthStencilState(previousDepthStencil, previousStencilRef);
    g_context->OMSetBlendState(previousBlend, previousBlendFactor, previousSampleMask);
    if (previousViewportCount > 0) g_context->RSSetViewports(previousViewportCount, previousViewports);
    g_context->PSSetConstantBuffers(record.constantSlot, 1, &previousConstants);
    if (record.vertexConstants) g_context->VSSetConstantBuffers(record.vertexConstantSlot, 1, &previousVertexConstants);

    if (previousConstants) previousConstants->Release();
    if (previousInputLayout) previousInputLayout->Release();
    if (previousPixelShader) previousPixelShader->Release();
    if (previousVertexShader) previousVertexShader->Release();
    if (previousVertexBuffer) previousVertexBuffer->Release();
    if (previousVertexConstants) previousVertexConstants->Release();
    if (quadBuffer) quadBuffer->Release();
    if (previousBlend) previousBlend->Release();
    if (previousDepthStencil) previousDepthStencil->Release();
    if (previousRasterizer) previousRasterizer->Release();
    if (targetView) targetView->Release();
    sourceView->Release();
    return 7;
}

std::int32_t rpe_hlsl_target_width() {
    return g_lastTargetWidth;
}

std::int32_t rpe_hlsl_target_height() {
    return g_lastTargetHeight;
}
#endif

#if defined(I_PARALLEL_BUILD)
bool rpe_worker_upload_lines(void* inputPointer, std::int32_t lineCount) {
    if (!inputPointer || lineCount <= 0) return false;
    const auto* input = static_cast<const std::uint8_t*>(inputPointer);
    g_lineParents.resize(lineCount);
    g_lineRotateWithParent.resize(lineCount);
    g_lineWorldX.resize(lineCount);
    g_lineWorldY.resize(lineCount);
    g_lineWorldR.resize(lineCount);
    for (std::int32_t index = 0; index < lineCount; ++index) {
        std::int32_t parent = -1;
        std::int32_t rotate = 0;
        std::memcpy(&parent, input + static_cast<std::size_t>(index) * 8, sizeof(parent));
        std::memcpy(&rotate, input + static_cast<std::size_t>(index) * 8 + 4, sizeof(rotate));
        if (parent < 0 || parent >= lineCount || parent == index) parent = -1;
        g_lineParents[index] = parent;
        g_lineRotateWithParent[index] = rotate != 0;
    }

    std::vector<std::int32_t> state(lineCount, 0);
    std::vector<std::int32_t> depth(lineCount, 0);
    std::function<std::int32_t(std::int32_t)> resolveDepth = [&](std::int32_t index) -> std::int32_t {
        if (state[index] == 2) return depth[index];
        if (state[index] == 1) {
            g_lineParents[index] = -1;
            state[index] = 2;
            return depth[index] = 0;
        }
        state[index] = 1;
        const std::int32_t parent = g_lineParents[index];
        depth[index] = parent >= 0 ? resolveDepth(parent) + 1 : 0;
        state[index] = 2;
        return depth[index];
    };
    std::int32_t maxDepth = 0;
    for (std::int32_t index = 0; index < lineCount; ++index) {
        const std::int32_t lineDepth = resolveDepth(index);
        if (lineDepth > maxDepth) maxDepth = lineDepth;
    }
    g_lineLevels.assign(static_cast<std::size_t>(maxDepth + 1), {});
    for (std::int32_t index = 0; index < lineCount; ++index) g_lineLevels[depth[index]].push_back(index);
    return true;
}

std::int32_t rpe_worker_resolve_lines(void* inputPointer, std::int32_t lineCount, void* outputPointer) {
    if (!inputPointer || !outputPointer || lineCount <= 0
        || static_cast<std::size_t>(lineCount) != g_lineParents.size()) return 0;
    if (!g_workerPool) g_workerPool = std::make_unique<WorkerPool>();
    const auto* input = static_cast<const std::uint8_t*>(inputPointer);
    auto* output = static_cast<std::uint8_t*>(outputPointer);
    constexpr std::size_t stride = 24;
    constexpr double radians = 3.14159265358979323846 / 180.0;

    for (const auto& level : g_lineLevels) {
        g_workerPool->run(level.size(), [&](std::size_t levelIndex) {
            const std::int32_t index = level[levelIndex];
            const std::size_t offset = static_cast<std::size_t>(index) * stride;
            double rawX = 0;
            double rawY = 0;
            double rawR = 0;
            std::memcpy(&rawX, input + offset, sizeof(rawX));
            std::memcpy(&rawY, input + offset + 8, sizeof(rawY));
            std::memcpy(&rawR, input + offset + 16, sizeof(rawR));
            const std::int32_t parent = g_lineParents[index];
            if (parent < 0) {
                g_lineWorldX[index] = rawX;
                g_lineWorldY[index] = rawY;
                g_lineWorldR[index] = rawR;
                return;
            }
            const double parentR = g_lineWorldR[parent];
            const double cosine = std::cos(parentR * radians);
            const double sine = std::sin(parentR * radians);
            g_lineWorldX[index] = g_lineWorldX[parent] + rawX * cosine + rawY * sine;
            g_lineWorldY[index] = g_lineWorldY[parent] + rawY * cosine - rawX * sine;
            g_lineWorldR[index] = rawR + (g_lineRotateWithParent[index] ? parentR : 0.0);
        });
    }

    for (std::int32_t index = 0; index < lineCount; ++index) {
        const std::size_t offset = static_cast<std::size_t>(index) * stride;
        std::memcpy(output + offset, &g_lineWorldX[index], sizeof(double));
        std::memcpy(output + offset + 8, &g_lineWorldY[index], sizeof(double));
        std::memcpy(output + offset + 16, &g_lineWorldR[index], sizeof(double));
    }
    return g_workerPool->size();
}

void rpe_worker_shutdown() {
    g_workerPool.reset();
    g_lineParents.clear();
    g_lineRotateWithParent.clear();
    g_lineLevels.clear();
    g_lineWorldX.clear();
    g_lineWorldY.clear();
    g_lineWorldR.clear();
}
#endif

#if defined(I_PULSE_BUILD)
bool rpe_window_drag_enable(void* windowPointer) {
    HWND window = static_cast<HWND>(windowPointer);
    if (!window || !IsWindow(window)) return false;
    if (g_dragWindow == window
        && reinterpret_cast<WNDPROC>(GetWindowLongPtrW(window, GWLP_WNDPROC)) == rpeWindowProc) return true;
    rpe_window_drag_disable();
    SetLastError(0);
    const LONG_PTR previous = SetWindowLongPtrW(window, GWLP_WNDPROC,
        reinterpret_cast<LONG_PTR>(rpeWindowProc));
    if (previous == 0 && GetLastError() != 0) return false;
    g_dragWindow = window;
    g_previousWindowProc = reinterpret_cast<WNDPROC>(previous);
    return true;
}

void rpe_window_drag_disable() {
    if (g_dragWindow && IsWindow(g_dragWindow)) {
        if ((g_windowDragging || g_windowResizing) && GetCapture() == g_dragWindow) ReleaseCapture();
        const auto current = reinterpret_cast<WNDPROC>(GetWindowLongPtrW(g_dragWindow, GWLP_WNDPROC));
        if (current == rpeWindowProc && g_previousWindowProc) {
            SetWindowLongPtrW(g_dragWindow, GWLP_WNDPROC,
                reinterpret_cast<LONG_PTR>(g_previousWindowProc));
        }
    }
    g_windowDragging = false;
    g_windowResizing = false;
    g_resizeHitTest = HTNOWHERE;
    g_dragWindow = nullptr;
    g_previousWindowProc = nullptr;
}
#endif

#if defined(I_SHADERS_BUILD)
bool rpe_hlsl_end() {
    restoreState();
    return true;
}

bool rpe_hlsl_release(std::int32_t handle) {
    restoreState();
    return g_shaders.erase(handle) > 0;
}

void rpe_hlsl_shutdown() {
    restoreState();
    g_shaders.clear();
    if (g_fullscreenVertexShader) g_fullscreenVertexShader->Release();
    if (g_fullscreenBlend) g_fullscreenBlend->Release();
    if (g_fullscreenDepthStencil) g_fullscreenDepthStencil->Release();
    if (g_fullscreenRasterizer) g_fullscreenRasterizer->Release();
    g_fullscreenVertexShader = nullptr;
    g_fullscreenBlend = nullptr;
    g_fullscreenDepthStencil = nullptr;
    g_fullscreenRasterizer = nullptr;
    g_lastTargetWidth = 0;
    g_lastTargetHeight = 0;
    g_device = nullptr;
    g_context = nullptr;
}

std::string rpe_hlsl_get_error() {
    return g_lastError;
}
#endif
