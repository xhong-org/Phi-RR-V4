#include "IPulse_native.h"

#if defined(OS_WINDOWS)
#include <windows.h>
#include <array>
#include <cstdint>
#include <cstring>

namespace {
struct KeyPress {
    std::uint32_t key;
    std::uint32_t time;
};

constexpr std::size_t keyCapacity = 1024;
HHOOK keyboardHook = nullptr;
HWND keyboardWindow = nullptr;
std::array<KeyPress, keyCapacity> keyPresses{};
std::size_t keyCount = 0;
bool keyboardOverflow = false;

LRESULT CALLBACK keyboardMessage(int code, WPARAM removed, LPARAM messagePointer) {
    if (code >= 0 && removed == PM_REMOVE) {
        const auto& message = *reinterpret_cast<const MSG*>(messagePointer);
        if (message.hwnd == keyboardWindow && message.message == WM_KEYDOWN
            && message.wParam >= 'A' && message.wParam <= 'Z'
            && (message.lParam & (1LL << 30)) == 0) {
            if (keyCount < keyCapacity) {
                keyPresses[keyCount++] = {static_cast<std::uint32_t>(message.wParam), message.time};
            } else keyboardOverflow = true;
        }
    }
    return CallNextHookEx(keyboardHook, code, removed, messagePointer);
}
}

// Buffer layout: held bit mask, event count, then (A-Z key, age in milliseconds).
// The hook runs on the runner's own thread; it does not block or suppress keys.
GMEXPORT double __EXT_NATIVE__rpe_keyboard_poll(char* argumentBuffer, double argumentLength) {
    if (!argumentBuffer || argumentLength < 16) return -1;
    std::uint64_t windowAddress = 0;
    std::uint64_t outputAddress = 0;
    std::memcpy(&windowAddress, argumentBuffer, 8);
    std::memcpy(&outputAddress, argumentBuffer + 8, 8);
    const auto window = reinterpret_cast<HWND>(windowAddress);
    auto* output = reinterpret_cast<std::uint32_t*>(outputAddress);
    if (!output || !IsWindow(window)) return -1;
    if (keyboardWindow != window) {
        keyboardWindow = window;
        keyCount = 0;
        keyboardOverflow = false;
    }
    if (!keyboardHook) {
        keyboardHook = SetWindowsHookExW(WH_GETMESSAGE, keyboardMessage, nullptr, GetCurrentThreadId());
        if (!keyboardHook) return -1;
    }
    // Read pending keyboard messages before sampling. This avoids waiting another
    // render frame for a down/up pair that is already in the window queue.
    MSG message{};
    while (PeekMessageW(&message, window, WM_KEYFIRST, WM_KEYLAST, PM_REMOVE)) {
        TranslateMessage(&message);
        DispatchMessageW(&message);
    }
    std::uint32_t held = 0;
    const bool focused = GetForegroundWindow() == window;
    if (focused) {
        for (int key = 'A'; key <= 'Z'; ++key) {
            if ((GetAsyncKeyState(key) & 0x8000) != 0) held |= 1u << (key - 'A');
        }
    } else keyCount = 0;
    output[0] = held;
    output[1] = static_cast<std::uint32_t>(keyCount);
    const DWORD now = GetTickCount();
    for (std::size_t index = 0; index < keyCount; ++index) {
        output[2 + index * 2] = keyPresses[index].key;
        output[3 + index * 2] = now - keyPresses[index].time;
    }
    keyCount = 0;
    const bool overflow = keyboardOverflow;
    keyboardOverflow = false;
    return overflow ? -2 : 1;
}

GMEXPORT double __EXT_NATIVE__rpe_keyboard_reset() {
    if (keyboardHook) UnhookWindowsHookEx(keyboardHook);
    keyboardHook = nullptr;
    keyboardWindow = nullptr;
    keyCount = 0;
    keyboardOverflow = false;
    return 0;
}

GMEXPORT double __EXT_NATIVE__rpe_pulse_shutdown() {
    __EXT_NATIVE__rpe_keyboard_reset();
    rpe_window_drag_disable();
    return 0;
}
#endif
