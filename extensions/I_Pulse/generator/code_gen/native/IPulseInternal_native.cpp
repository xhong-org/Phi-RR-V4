// ##### extgen :: Auto-generated file do not edit!! #####

#include "IPulseInternal_native.h"
#include "IPulseInternal_exports.h"

using namespace gm_structs;
using namespace gm::wire::codec;

GMEXPORT double __EXT_NATIVE__rpe_window_drag_enable(char* __arg_buffer, double __arg_buffer_length)
{
    gm::byteio::BufferReader __br{__arg_buffer, static_cast<size_t>(__arg_buffer_length)};

    // field: window, type: Pointer
    void* window = reinterpret_cast<void*>(gm::wire::codec::readValue<std::uint64_t>(__br));

    auto&& __result = rpe_window_drag_enable(window);
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__rpe_window_drag_disable()
{
    rpe_window_drag_disable();
    return 0;
}

