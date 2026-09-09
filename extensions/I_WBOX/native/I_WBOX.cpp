#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif

#include <Windows.h>
#include <CommCtrl.h>

#include <algorithm>
#include <atomic>
#include <cstdint>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>
#include <thread>
#include <unordered_map>
#include <vector>

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "comctl32.lib")
#pragma comment(linker, "\"/manifestdependency:type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")

#define GMEXPORT extern "C" __declspec(dllexport)

namespace {

constexpr int kStatusUnknown = 0;
constexpr int kStatusRunning = 1;
constexpr int kStatusDone = 2;
constexpr int kAlignLeft = 1;
constexpr int kAlignCenter = 2;
constexpr int kAlignRight = 3;
constexpr int kMaxButtons = 4;
constexpr wchar_t kClassName[] = L"I_WBOXWindow";

struct Task {
    std::atomic<int> status{kStatusRunning};
    std::atomic<int> result{0};
    std::atomic<HWND> window{nullptr};
    std::atomic<bool> cancelled{false};
    std::thread worker;
};

std::mutex g_tasks_mutex;
std::unordered_map<int, std::shared_ptr<Task>> g_tasks;
std::atomic<int> g_next_id{1};
std::mutex g_config_mutex;
std::vector<std::wstring> g_buttons;
int g_alignment = kAlignLeft;

struct WireReader {
    const uint8_t* p = nullptr;
    const uint8_t* end = nullptr;

    bool remaining(size_t n) const { return p && end && static_cast<size_t>(end - p) >= n; }

    bool read_u8(uint8_t& out) {
        if (!remaining(1)) return false;
        out = *p++;
        return true;
    }

    bool read_u32(uint32_t& out) {
        if (!remaining(4)) return false;
        uint32_t value = 0;
        std::memcpy(&value, p, 4);
        p += 4;
        out = value;
        return true;
    }

    bool read_string(std::string& out) {
        uint32_t size = 0;
        if (!read_u32(size)) return false;
        if (!remaining(size)) return false;
        out.assign(reinterpret_cast<const char*>(p), size);
        p += size;
        if (remaining(1) && *p == 0) ++p;
        return true;
    }
};

std::wstring normalize_newlines(std::wstring text) {
    std::wstring out;
    out.reserve(text.size() + 8);
    for (size_t i = 0; i < text.size(); ++i) {
        if (text[i] == L'\r') {
            out.push_back(L'\r');
            if (i + 1 < text.size() && text[i + 1] == L'\n') {
                out.push_back(L'\n');
                ++i;
            } else {
                out.push_back(L'\n');
            }
        } else if (text[i] == L'\n') {
            out.append(L"\r\n");
        } else {
            out.push_back(text[i]);
        }
    }
    return out;
}

std::wstring utf8_to_wide(std::string_view text) {
    if (text.empty()) return {};
    int count = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text.data(), static_cast<int>(text.size()), nullptr, 0);
    UINT code_page = CP_UTF8;
    DWORD flags = MB_ERR_INVALID_CHARS;
    if (count <= 0) {
        code_page = CP_ACP;
        flags = 0;
        count = MultiByteToWideChar(code_page, flags, text.data(), static_cast<int>(text.size()), nullptr, 0);
    }
    if (count <= 0) return {};
    std::wstring wide(static_cast<size_t>(count), L'\0');
    MultiByteToWideChar(code_page, flags, text.data(), static_cast<int>(text.size()), wide.data(), count);
    return wide;
}

UINT window_dpi(HWND window) {
    using GetDpiForWindowFn = UINT(WINAPI*)(HWND);
    static GetDpiForWindowFn fn = reinterpret_cast<GetDpiForWindowFn>(
        GetProcAddress(GetModuleHandleW(L"user32.dll"), "GetDpiForWindow"));
    if (fn && window) {
        const UINT dpi = fn(window);
        if (dpi) return dpi;
    }
    HDC dc = GetDC(window);
    UINT dpi = dc ? static_cast<UINT>(GetDeviceCaps(dc, LOGPIXELSX)) : 96;
    if (dc) ReleaseDC(window, dc);
    return dpi ? dpi : 96;
}

int scale_px(int value, UINT dpi) {
    return MulDiv(value, static_cast<int>(dpi), 96);
}

HWND find_owner_window() {
    struct Search {
        DWORD pid;
        HWND result;
    } search{GetCurrentProcessId(), nullptr};
    EnumWindows([](HWND window, LPARAM param) -> BOOL {
        auto* search = reinterpret_cast<Search*>(param);
        DWORD pid = 0;
        GetWindowThreadProcessId(window, &pid);
        if (pid != search->pid || !IsWindowVisible(window) || GetWindow(window, GW_OWNER)) return TRUE;
        wchar_t cls[64]{};
        GetClassNameW(window, cls, 64);
        if (lstrcmpW(cls, kClassName) == 0) return TRUE;
        if (lstrcmpW(cls, L"YYGameMakerYY") == 0) {
            search->result = window;
            return FALSE;
        }
        if (!search->result) search->result = window;
        return TRUE;
    }, reinterpret_cast<LPARAM>(&search));
    return search.result;
}

HFONT create_ui_font(UINT dpi) {
    NONCLIENTMETRICSW metrics{};
    metrics.cbSize = sizeof(metrics);
    if (SystemParametersInfoW(SPI_GETNONCLIENTMETRICS, sizeof(metrics), &metrics, 0)) {
        metrics.lfMessageFont.lfCharSet = DEFAULT_CHARSET;
        if (dpi != 96 && metrics.lfMessageFont.lfHeight < 0) {
            metrics.lfMessageFont.lfHeight = -scale_px(-metrics.lfMessageFont.lfHeight, dpi);
        }
        HFONT font = CreateFontIndirectW(&metrics.lfMessageFont);
        if (font) return font;
    }
    return CreateFontW(-scale_px(12, dpi), 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
        OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
}

LPCWSTR icon_id(int kind) {
    if (kind == 2) return IDI_WARNING;
    if (kind == 3) return IDI_ERROR;
    return IDI_INFORMATION;
}

struct DialogState {
    Task* task = nullptr;
    std::wstring message;
    std::wstring title;
    std::vector<std::wstring> labels;
    int kind = 1;
    int alignment = kAlignLeft;
    int result = 0;
    HFONT font = nullptr;
    HWND owner = nullptr;
    HWND edit = nullptr;
    bool modal = false;
};

void enable_and_focus_owner(HWND owner) {
    if (!owner || !IsWindow(owner)) return;
    EnableWindow(owner, TRUE);
    if (IsIconic(owner)) ShowWindow(owner, SW_RESTORE);
    HWND foreground = GetForegroundWindow();
    DWORD foreground_tid = foreground ? GetWindowThreadProcessId(foreground, nullptr) : 0;
    DWORD our_tid = GetCurrentThreadId();
    BOOL attached = FALSE;
    if (foreground && foreground != owner && foreground_tid != 0 && foreground_tid != our_tid) {
        attached = AttachThreadInput(foreground_tid, our_tid, TRUE);
    }
    BringWindowToTop(owner);
    SetForegroundWindow(owner);
    SetActiveWindow(owner);
    SetFocus(owner);
    if (attached) AttachThreadInput(foreground_tid, our_tid, FALSE);
}

void copy_dialog_text(const DialogState& state) {
    std::wstring clip = state.title + L"\r\n\r\n" + state.message;
    if (!OpenClipboard(nullptr)) return;
    EmptyClipboard();
    const size_t bytes = (clip.size() + 1) * sizeof(wchar_t);
    HGLOBAL mem = GlobalAlloc(GMEM_MOVEABLE, bytes);
    if (!mem) {
        CloseClipboard();
        return;
    }
    void* locked = GlobalLock(mem);
    if (locked) {
        std::memcpy(locked, clip.c_str(), bytes);
        GlobalUnlock(mem);
        SetClipboardData(CF_UNICODETEXT, mem);
    } else {
        GlobalFree(mem);
    }
    CloseClipboard();
}

LRESULT CALLBACK dialog_proc(HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
    auto* state = reinterpret_cast<DialogState*>(GetWindowLongPtrW(window, GWLP_USERDATA));
    if (message == WM_NCCREATE) {
        state = reinterpret_cast<DialogState*>(reinterpret_cast<CREATESTRUCTW*>(lparam)->lpCreateParams);
        SetWindowLongPtrW(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(state));
        if (state && state->task) state->task->window.store(window);
    }

    switch (message) {
    case WM_COMMAND: {
        const int id = LOWORD(wparam);
        if (state && id >= 100 && id < 100 + kMaxButtons) {
            state->result = id - 99;
            if (state->task) state->task->result.store(state->result);
            // Re-enable the GameMaker owner before destroy. If it is still
            // disabled, Windows cannot activate it and the runner goes to the
            // background or minimizes.
            if (state->owner) enable_and_focus_owner(state->owner);
            DestroyWindow(window);
            return 0;
        }
        break;
    }
    case WM_CLOSE:
        if (state && state->owner) enable_and_focus_owner(state->owner);
        DestroyWindow(window);
        return 0;
    case WM_DESTROY:
        if (state) {
            if (state->task) state->task->window.store(nullptr);
            if (state->font) {
                DeleteObject(state->font);
                state->font = nullptr;
            }
            if (state->owner) enable_and_focus_owner(state->owner);
        }
        return 0;
    case WM_CTLCOLORSTATIC:
    case WM_CTLCOLOREDIT: {
        HDC dc = reinterpret_cast<HDC>(wparam);
        SetBkColor(dc, GetSysColor(COLOR_WINDOW));
        SetTextColor(dc, GetSysColor(COLOR_WINDOWTEXT));
        return reinterpret_cast<LRESULT>(GetSysColorBrush(COLOR_WINDOW));
    }
    case WM_COPY:
        if (state) copy_dialog_text(*state);
        return 0;
    default:
        break;
    }
    return DefWindowProcW(window, message, wparam, lparam);
}

void register_class() {
    static std::once_flag once;
    std::call_once(once, [] {
        INITCOMMONCONTROLSEX icc{sizeof(icc), ICC_STANDARD_CLASSES | ICC_WIN95_CLASSES};
        InitCommonControlsEx(&icc);
        WNDCLASSW klass{};
        klass.lpfnWndProc = dialog_proc;
        klass.hInstance = GetModuleHandleW(nullptr);
        klass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
        klass.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
        klass.lpszClassName = kClassName;
        klass.hIcon = LoadIconW(nullptr, IDI_APPLICATION);
        RegisterClassW(&klass);
    });
}

int show_dialog(std::wstring message, std::wstring title, int kind, std::vector<std::wstring> labels, int alignment, Task* task, bool modal) {
    if (task && task->cancelled.load()) return 0;
    if (message.empty()) message = L" ";
    if (title.empty()) title = L"Message";
    labels.erase(std::remove_if(labels.begin(), labels.end(), [](const std::wstring& text) { return text.empty(); }), labels.end());
    if (labels.size() > kMaxButtons) labels.resize(kMaxButtons);
    if (labels.empty()) labels.emplace_back(L"OK");
    if (alignment < kAlignLeft || alignment > kAlignRight) alignment = kAlignLeft;

    register_class();
    HWND owner = find_owner_window();
    const UINT dpi = window_dpi(owner);
    DialogState state;
    state.task = task;
    state.message = std::move(message);
    state.title = std::move(title);
    state.labels = std::move(labels);
    state.kind = kind;
    state.alignment = alignment;
    state.font = create_ui_font(dpi);
    state.owner = owner;
    state.modal = modal && owner;

    const int pad = scale_px(16, dpi);
    const int icon_size = scale_px(32, dpi);
    const int button_w = scale_px(108, dpi);
    const int button_h = scale_px(30, dpi);
    const int button_gap = scale_px(8, dpi);
    const int text_width = scale_px(420, dpi);
    const int min_text_h = scale_px(72, dpi);
    const int max_text_h = scale_px(280, dpi);

    RECT text_rect{0, 0, text_width, 0};
    HDC measure_dc = GetDC(owner);
    HFONT old_font = measure_dc && state.font ? static_cast<HFONT>(SelectObject(measure_dc, state.font)) : nullptr;
    DrawTextW(measure_dc, state.message.c_str(), -1, &text_rect, DT_CALCRECT | DT_WORDBREAK | DT_NOPREFIX | DT_EDITCONTROL);
    if (measure_dc && old_font) SelectObject(measure_dc, old_font);
    if (measure_dc) ReleaseDC(owner, measure_dc);
    int text_h = std::clamp(static_cast<int>(text_rect.bottom - text_rect.top) + scale_px(8, dpi), min_text_h, max_text_h);

    const int client_w = pad + icon_size + pad + text_width + pad;
    const int buttons_y = pad + std::max(icon_size, text_h) + pad;
    const int client_h = buttons_y + button_h + pad;
    RECT window_rect{0, 0, client_w, client_h};
    AdjustWindowRectEx(&window_rect, WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU, FALSE, WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE);
    const int window_w = window_rect.right - window_rect.left;
    const int window_h = window_rect.bottom - window_rect.top;

    int x = CW_USEDEFAULT;
    int y = CW_USEDEFAULT;
    if (owner) {
        RECT owner_rect{};
        GetWindowRect(owner, &owner_rect);
        x = owner_rect.left + ((owner_rect.right - owner_rect.left) - window_w) / 2;
        y = owner_rect.top + ((owner_rect.bottom - owner_rect.top) - window_h) / 2;
    } else {
        x = (GetSystemMetrics(SM_CXSCREEN) - window_w) / 2;
        y = (GetSystemMetrics(SM_CYSCREEN) - window_h) / 2;
    }

    if (state.modal) EnableWindow(owner, FALSE);
    HWND window = CreateWindowExW(
        WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE,
        kClassName,
        state.title.c_str(),
        WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU,
        x, y, window_w, window_h,
        owner,
        nullptr,
        GetModuleHandleW(nullptr),
        &state);
    if (!window) {
        if (state.modal) EnableWindow(owner, TRUE);
        if (state.font) DeleteObject(state.font);
        return 0;
    }

    HICON icon = LoadIconW(nullptr, icon_id(kind));
    CreateWindowExW(0, L"STATIC", nullptr, WS_CHILD | WS_VISIBLE | SS_ICON,
        pad, pad, icon_size, icon_size, window, reinterpret_cast<HMENU>(10), GetModuleHandleW(nullptr), nullptr);
    SendDlgItemMessageW(window, 10, STM_SETIMAGE, IMAGE_ICON, reinterpret_cast<LPARAM>(icon));

    const int edit_x = pad + icon_size + pad;
    DWORD edit_style = WS_CHILD | WS_VISIBLE | ES_MULTILINE | ES_READONLY | ES_LEFT | ES_AUTOVSCROLL;
    if (text_rect.bottom - text_rect.top + scale_px(8, dpi) > max_text_h) edit_style |= WS_VSCROLL;
    state.edit = CreateWindowExW(0, L"EDIT", state.message.c_str(), edit_style,
        edit_x, pad, text_width, text_h, window, reinterpret_cast<HMENU>(11), GetModuleHandleW(nullptr), nullptr);
    SendMessageW(state.edit, WM_SETFONT, reinterpret_cast<WPARAM>(state.font), TRUE);
    SendMessageW(state.edit, EM_SETMARGINS, EC_LEFTMARGIN | EC_RIGHTMARGIN, 0);

    const int group_width = static_cast<int>(state.labels.size()) * button_w
        + (static_cast<int>(state.labels.size()) - 1) * button_gap;
    int button_x = pad + icon_size + pad;
    if (state.alignment == kAlignCenter) button_x += (text_width - group_width) / 2;
    if (state.alignment == kAlignRight) button_x += text_width - group_width;
    for (size_t i = 0; i < state.labels.size(); ++i) {
        DWORD style = WS_CHILD | WS_VISIBLE | WS_TABSTOP | (i == 0 ? BS_DEFPUSHBUTTON : BS_PUSHBUTTON);
        HWND button = CreateWindowExW(0, L"BUTTON", state.labels[i].c_str(), style,
            button_x, buttons_y, button_w, button_h, window, reinterpret_cast<HMENU>(100 + i),
            GetModuleHandleW(nullptr), nullptr);
        SendMessageW(button, WM_SETFONT, reinterpret_cast<WPARAM>(state.font), TRUE);
        button_x += button_w + button_gap;
    }

    ShowWindow(window, SW_SHOW);
    UpdateWindow(window);
    SetForegroundWindow(window);

    MSG msg{};
    while (IsWindow(window) && GetMessageW(&msg, nullptr, 0, 0) > 0) {
        if (task && task->cancelled.load()) {
            DestroyWindow(window);
            break;
        }
        if (msg.message == WM_KEYDOWN && msg.wParam == VK_ESCAPE) {
            DestroyWindow(window);
            continue;
        }
        if (msg.message == WM_KEYDOWN && msg.wParam == 'C' && (GetKeyState(VK_CONTROL) & 0x8000)) {
            copy_dialog_text(state);
            continue;
        }
        if (!IsDialogMessageW(window, &msg)) {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
    if (owner) enable_and_focus_owner(owner);
    return task ? task->result.load() : state.result;
}

std::shared_ptr<Task> find_task(int id) {
    std::lock_guard lock(g_tasks_mutex);
    const auto it = g_tasks.find(id);
    return it == g_tasks.end() ? nullptr : it->second;
}

template <typename Work>
int start_task(Work work) {
    int id = g_next_id.fetch_add(1);
    if (id <= 0) {
        g_next_id.store(2);
        id = 1;
    }
    auto task = std::make_shared<Task>();
    {
        std::lock_guard lock(g_tasks_mutex);
        g_tasks[id] = task;
    }
    task->worker = std::thread([task, work = std::move(work)]() mutable {
        task->result.store(work(task.get()));
        task->status.store(kStatusDone);
    });
    return id;
}

bool parse_show_args(char* data, double length, std::wstring& message, std::wstring& title, int& kind) {
    if (!data || length <= 0) return false;
    WireReader reader{reinterpret_cast<const uint8_t*>(data), reinterpret_cast<const uint8_t*>(data) + static_cast<size_t>(length)};
    std::string message_utf8;
    std::string title_utf8;
    uint8_t kind_u8 = 1;
    if (!reader.read_string(message_utf8) || !reader.read_string(title_utf8) || !reader.read_u8(kind_u8)) return false;
    message = normalize_newlines(utf8_to_wide(message_utf8));
    title = utf8_to_wide(title_utf8);
    kind = kind_u8;
    return true;
}

std::vector<std::wstring> snapshot_buttons(int& alignment) {
    std::lock_guard lock(g_config_mutex);
    alignment = g_alignment;
    return g_buttons;
}

} // namespace

GMEXPORT double __EXT_NATIVE__i_wbox_initialize() {
    return 1;
}

GMEXPORT double __EXT_NATIVE__i_wbox_shutdown() {
    std::vector<std::shared_ptr<Task>> pending;
    {
        std::lock_guard lock(g_tasks_mutex);
        for (auto& item : g_tasks) pending.push_back(item.second);
        g_tasks.clear();
    }
    for (auto& task : pending) {
        task->cancelled.store(true);
        HWND window = task->window.load();
        if (window) PostMessageW(window, WM_CLOSE, 0, 0);
    }
    for (auto& task : pending) {
        if (task->worker.joinable()) task->worker.join();
    }
    return 1;
}

GMEXPORT double __EXT_NATIVE__i_wbox_available() {
    return 1;
}

GMEXPORT double __EXT_NATIVE__i_wbox_clear_buttons() {
    std::lock_guard lock(g_config_mutex);
    g_buttons.clear();
    g_alignment = kAlignLeft;
    return 1;
}

GMEXPORT double __EXT_NATIVE__i_wbox_set_button_alignment(double alignment) {
    const int value = static_cast<int>(alignment);
    if (value < kAlignLeft || value > kAlignRight) return 0;
    std::lock_guard lock(g_config_mutex);
    g_alignment = value;
    return 1;
}

GMEXPORT double __EXT_NATIVE__i_wbox_set_button(char* data, double length) {
    if (!data || length <= 0) return 0;
    WireReader reader{reinterpret_cast<const uint8_t*>(data), reinterpret_cast<const uint8_t*>(data) + static_cast<size_t>(length)};
    uint32_t index = 0;
    std::string text;
    if (!reader.read_u32(index) || !reader.read_string(text)) return 0;
    if (index < 1 || index > kMaxButtons) return 0;
    std::lock_guard lock(g_config_mutex);
    if (g_buttons.size() < index) g_buttons.resize(index);
    g_buttons[index - 1] = utf8_to_wide(text);
    return 1;
}

GMEXPORT double __EXT_NATIVE__i_wbox_show_sync(char* data, double length) {
    std::wstring message, title;
    int kind = 1;
    if (!parse_show_args(data, length, message, title, kind)) return 0;
    int alignment = kAlignLeft;
    auto labels = snapshot_buttons(alignment);
    return show_dialog(std::move(message), std::move(title), kind, std::move(labels), alignment, nullptr, true);
}

GMEXPORT double __EXT_NATIVE__i_wbox_show_async(char* data, double length) {
    std::wstring message, title;
    int kind = 1;
    if (!parse_show_args(data, length, message, title, kind)) return 0;
    int alignment = kAlignLeft;
    auto labels = snapshot_buttons(alignment);
    return start_task([message = std::move(message), title = std::move(title), kind, labels = std::move(labels), alignment](Task* task) {
        return show_dialog(message, title, kind, labels, alignment, task, false);
    });
}

GMEXPORT double __EXT_NATIVE__i_wbox_task_status(double task_id) {
    auto task = find_task(static_cast<int>(task_id));
    return task ? task->status.load() : kStatusUnknown;
}

GMEXPORT double __EXT_NATIVE__i_wbox_task_result(double task_id) {
    auto task = find_task(static_cast<int>(task_id));
    return task ? task->result.load() : 0;
}

GMEXPORT double __EXT_NATIVE__i_wbox_task_cancel(double task_id) {
    auto task = find_task(static_cast<int>(task_id));
    if (!task || task->status.load() == kStatusDone) return 0;
    task->cancelled.store(true);
    HWND window = task->window.load();
    if (window) PostMessageW(window, WM_CLOSE, 0, 0);
    return 1;
}

GMEXPORT double __EXT_NATIVE__i_wbox_task_release(double task_id) {
    std::shared_ptr<Task> task;
    {
        std::lock_guard lock(g_tasks_mutex);
        const auto it = g_tasks.find(static_cast<int>(task_id));
        if (it == g_tasks.end() || it->second->status.load() != kStatusDone) return 0;
        task = it->second;
        g_tasks.erase(it);
    }
    if (task->worker.joinable()) task->worker.join();
    return 1;
}

GMEXPORT double __EXT_NATIVE__i_wbox_info(char* data, double length) {
    std::wstring message, title;
    int kind = 1;
    if (!parse_show_args(data, length, message, title, kind)) return 0;
    int alignment = kAlignLeft;
    auto labels = snapshot_buttons(alignment);
    return start_task([message = std::move(message), title = std::move(title), labels = std::move(labels), alignment](Task* task) {
        return show_dialog(message, title, 1, labels, alignment, task, false);
    });
}

GMEXPORT double __EXT_NATIVE__i_wbox_warning(char* data, double length) {
    std::wstring message, title;
    int kind = 2;
    if (!parse_show_args(data, length, message, title, kind)) return 0;
    int alignment = kAlignLeft;
    auto labels = snapshot_buttons(alignment);
    return start_task([message = std::move(message), title = std::move(title), labels = std::move(labels), alignment](Task* task) {
        return show_dialog(message, title, 2, labels, alignment, task, false);
    });
}

GMEXPORT double __EXT_NATIVE__i_wbox_error(char* data, double length) {
    std::wstring message, title;
    int kind = 3;
    if (!parse_show_args(data, length, message, title, kind)) return 0;
    int alignment = kAlignLeft;
    auto labels = snapshot_buttons(alignment);
    return start_task([message = std::move(message), title = std::move(title), labels = std::move(labels), alignment](Task* task) {
        return show_dialog(message, title, 3, labels, alignment, task, false);
    });
}
