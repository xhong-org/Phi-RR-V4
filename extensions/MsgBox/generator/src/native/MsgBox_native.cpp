#include <Windows.h>
#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>
#include "MsgBox_native.h"

namespace {
constexpr int kRunning = 1, kDone = 2;
constexpr int kButtonAlignLeft = 1, kButtonAlignCenter = 2, kButtonAlignRight = 3;
constexpr int kButtonAreaLeft = 74, kButtonAreaWidth = 450, kButtonWidth = 105, kButtonGap = 7;
struct Task { std::atomic<int> status{kRunning}; std::atomic<int> result{0}; std::atomic<HWND> window{nullptr}; std::atomic<bool> cancelled{false}; std::thread worker; };
std::mutex tasks_mutex;
std::unordered_map<int, std::shared_ptr<Task>> tasks;
std::atomic<int> next_id{1};
std::mutex buttons_mutex;
std::vector<std::string> configured_buttons;
int configured_alignment = kButtonAlignLeft;
std::wstring wide(std::string_view s) {
    if (s.empty()) return {};
    int n=MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,s.data(),(int)s.size(),nullptr,0);
    UINT cp=CP_UTF8; DWORD flags=MB_ERR_INVALID_CHARS;
    if(!n){cp=CP_ACP;flags=0;n=MultiByteToWideChar(cp,flags,s.data(),(int)s.size(),nullptr,0);}
    if(!n)return{}; std::wstring r(n,L'\0'); MultiByteToWideChar(cp,flags,s.data(),(int)s.size(),r.data(),n); return r;
}
struct DialogState { Task* task; std::wstring message, title; std::vector<std::wstring> labels; int kind, alignment; HICON icon; int result; };
LRESULT CALLBACK dialog_proc(HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
    auto* state = reinterpret_cast<DialogState*>(GetWindowLongPtrW(window, GWLP_USERDATA));
    if (message == WM_NCCREATE) {
        state = reinterpret_cast<DialogState*>(reinterpret_cast<CREATESTRUCTW*>(lparam)->lpCreateParams);
        SetWindowLongPtrW(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(state));
        if (state->task) state->task->window.store(window);
    }
    if (message == WM_COMMAND && state && LOWORD(wparam) >= 100 && LOWORD(wparam) < 104) {
        state->result = LOWORD(wparam) - 99;
        if (state->task) state->task->result.store(state->result);
        DestroyWindow(window);
        return 0;
    }
    if (message == WM_CLOSE) { DestroyWindow(window); return 0; }
    if (message == WM_DESTROY) {
        if (state && state->task) state->task->window.store(nullptr);
        return 0;
    }
    if (message == WM_CREATE && state) {
        CreateWindowExW(0, L"STATIC", state->message.c_str(), WS_CHILD | WS_VISIBLE | SS_LEFT,
            74, 32, 450, 100, window, nullptr, GetModuleHandleW(nullptr), nullptr);
        CreateWindowExW(0, L"STATIC", nullptr, WS_CHILD | WS_VISIBLE | SS_ICON,
            20, 32, 40, 40, window, reinterpret_cast<HMENU>(10), GetModuleHandleW(nullptr), nullptr);
        SendDlgItemMessageW(window, 10, STM_SETIMAGE, IMAGE_ICON, reinterpret_cast<LPARAM>(state->icon));
        int group_width = static_cast<int>(state->labels.size()) * kButtonWidth
            + (static_cast<int>(state->labels.size()) - 1) * kButtonGap;
        int x = kButtonAreaLeft;
        if (state->alignment == kButtonAlignCenter) x += (kButtonAreaWidth - group_width) / 2;
        if (state->alignment == kButtonAlignRight) x += kButtonAreaWidth - group_width;
        for (size_t i = 0; i < state->labels.size() && i < 4; ++i) {
            HWND button = CreateWindowExW(0, L"BUTTON", state->labels[i].c_str(), WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                x, 155, kButtonWidth, 30, window, reinterpret_cast<HMENU>(100 + i), GetModuleHandleW(nullptr), nullptr);
            SendMessageW(button, WM_SETFONT, reinterpret_cast<WPARAM>(GetStockObject(DEFAULT_GUI_FONT)), TRUE);
            x += kButtonWidth + kButtonGap;
        }
        return 0;
    }
    return DefWindowProcW(window, message, wparam, lparam);
}
int show(std::string_view m,std::string_view t,int kind,const std::vector<std::string_view>& labels,int alignment, Task* task = nullptr) {
    if (task && task->cancelled.load()) return 0;
    DialogState state{task, wide(m), wide(t), {}, kind, alignment, nullptr, 0};
    if (state.message.empty()) state.message = L" ";
    if (state.title.empty()) state.title = L"Message";
    for (auto label : labels) if (!label.empty() && state.labels.size() < 4) state.labels.push_back(wide(label));
    if (state.labels.empty()) state.labels.push_back(L"OK");
    state.icon = LoadIconW(nullptr, kind == 2 ? MAKEINTRESOURCEW(IDI_WARNING) : kind == 3 ? MAKEINTRESOURCEW(IDI_ERROR) : MAKEINTRESOURCEW(IDI_INFORMATION));
    static std::once_flag class_once;
    std::call_once(class_once, [] {
        WNDCLASSW klass{}; klass.lpfnWndProc = dialog_proc; klass.hInstance = GetModuleHandleW(nullptr);
        klass.hCursor = LoadCursorW(nullptr, MAKEINTRESOURCEW(IDC_ARROW)); klass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1); klass.lpszClassName = L"MsgBoxUnicodeWindow";
        RegisterClassW(&klass);
    });
    HWND window = CreateWindowExW(WS_EX_DLGMODALFRAME, L"MsgBoxUnicodeWindow", state.title.c_str(), WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU,
        CW_USEDEFAULT, CW_USEDEFAULT, 560, 235, nullptr, nullptr, GetModuleHandleW(nullptr), &state);
    if (!window) return 0;
    if (task && task->cancelled.load()) { DestroyWindow(window); return 0; }
    RECT rect{}; GetWindowRect(window, &rect); int width = rect.right - rect.left, height = rect.bottom - rect.top;
    SetWindowPos(window, HWND_TOP, (GetSystemMetrics(SM_CXSCREEN) - width) / 2, (GetSystemMetrics(SM_CYSCREEN) - height) / 2, 0, 0, SWP_NOSIZE);
    ShowWindow(window, SW_SHOW); UpdateWindow(window);
    MSG msg{}; while (IsWindow(window) && GetMessageW(&msg, nullptr, 0, 0) > 0) { TranslateMessage(&msg); DispatchMessageW(&msg); }
    return task ? task->result.load() : state.result;
}
template<class F> int start(F f){int id=next_id.fetch_add(1);auto task=std::make_shared<Task>();{std::lock_guard l(tasks_mutex);tasks[id]=task;}task->worker=std::thread([task,f]{task->result=f(task.get());task->status.store(kDone);});return id;}
std::shared_ptr<Task> get(int id){std::lock_guard l(tasks_mutex);auto i=tasks.find(id);return i==tasks.end()?nullptr:i->second;}
}

void MsgBox_Initialize(){}
void MsgBox_Shutdown(){std::vector<std::shared_ptr<Task>> pending;{std::lock_guard l(tasks_mutex);for(auto& item:tasks)pending.push_back(item.second);tasks.clear();}for(auto& task:pending){task->cancelled.store(true);HWND window=task->window.load();if(window)PostMessageW(window,WM_CLOSE,0,0);}for(auto& task:pending)if(task->worker.joinable())task->worker.join();}
void MsgBox_ClearButtons(){std::lock_guard l(buttons_mutex);configured_buttons.clear();configured_alignment=kButtonAlignLeft;}
bool MsgBox_SetButton(int32_t index,std::string_view text){if(index<1||index>4)return false;std::lock_guard l(buttons_mutex);if(configured_buttons.size()<(size_t)index)configured_buttons.resize(index);configured_buttons[index-1]=std::string(text);return true;}
bool MsgBox_SetButtonAlignment(int32_t alignment){if(alignment<kButtonAlignLeft||alignment>kButtonAlignRight)return false;std::lock_guard l(buttons_mutex);configured_alignment=alignment;return true;}
int32_t MsgBox_ShowSync(std::string_view m,std::string_view t,int32_t k){std::vector<std::string> owned;int alignment;{std::lock_guard l(buttons_mutex);owned=configured_buttons;alignment=configured_alignment;}std::vector<std::string_view> labels;for(auto& value:owned)labels.push_back(value);return show(m,t,k,labels,alignment);}
int32_t MsgBox_ShowAsync(std::string_view m,std::string_view t,int32_t k){
    std::string message(m),title(t);std::vector<std::string> buttons;int alignment;{std::lock_guard l(buttons_mutex);buttons=configured_buttons;alignment=configured_alignment;}
    return start([message=std::move(message),title=std::move(title),k,buttons=std::move(buttons),alignment](Task* task){
        std::vector<std::string_view> labels;for(auto& value:buttons)labels.push_back(value);return show(message,title,k,labels,alignment,task);
    });
}
int32_t MsgBox_TaskStatus(int32_t id){auto t=get(id);return t?t->status.load():0;}
int32_t MsgBox_TaskResult(int32_t id){auto t=get(id);return t?t->result.load():0;}
bool MsgBox_TaskRelease(int32_t id){std::shared_ptr<Task> t;{std::lock_guard l(tasks_mutex);auto i=tasks.find(id);if(i==tasks.end()||i->second->status.load()!=kDone)return false;t=i->second;tasks.erase(i);}if(t->worker.joinable())t->worker.join();return true;}
int32_t MsgBox_Info(std::string_view m,std::string_view t){return MsgBox_ShowAsync(m,t,1);} int32_t MsgBox_Warning(std::string_view m,std::string_view t){return MsgBox_ShowAsync(m,t,2);} int32_t MsgBox_Error(std::string_view m,std::string_view t){return MsgBox_ShowAsync(m,t,3);}
