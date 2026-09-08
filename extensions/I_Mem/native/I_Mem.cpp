#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <Windows.h>
#include <psapi.h>
#include <malloc.h>

#pragma comment(lib, "psapi.lib")

#define GMEXPORT extern "C" __declspec(dllexport)

namespace {

PROCESS_MEMORY_COUNTERS_EX query_memory() {
    PROCESS_MEMORY_COUNTERS_EX info{};
    info.cb = sizeof(info);
    GetProcessMemoryInfo(
        GetCurrentProcess(),
        reinterpret_cast<PROCESS_MEMORY_COUNTERS*>(&info),
        sizeof(info));
    return info;
}

void compact_process_heaps() {
#ifdef _MSC_VER
    _heapmin();
#endif
    HANDLE heaps[64];
    DWORD count = GetProcessHeaps(64, heaps);
    if (count == 0 || count > 64) {
        HeapCompact(GetProcessHeap(), 0);
        return;
    }
    for (DWORD i = 0; i < count; ++i) {
        if (heaps[i] != nullptr) HeapCompact(heaps[i], 0);
    }
}

} // namespace

GMEXPORT double __EXT_NATIVE__i_mem_initialize() {
    return 1;
}

GMEXPORT double __EXT_NATIVE__i_mem_shutdown() {
    return 1;
}

GMEXPORT double __EXT_NATIVE__i_mem_available() {
    return 1;
}

GMEXPORT double __EXT_NATIVE__i_mem_working_set() {
    return static_cast<double>(query_memory().WorkingSetSize);
}

GMEXPORT double __EXT_NATIVE__i_mem_private_bytes() {
    return static_cast<double>(query_memory().PrivateUsage);
}

GMEXPORT double __EXT_NATIVE__i_mem_trim() {
    compact_process_heaps();

    HANDLE process = GetCurrentProcess();
    BOOL emptied = EmptyWorkingSet(process);
    BOOL resized = SetProcessWorkingSetSize(process, static_cast<SIZE_T>(-1), static_cast<SIZE_T>(-1));
    return (emptied || resized) ? 1 : 0;
}
