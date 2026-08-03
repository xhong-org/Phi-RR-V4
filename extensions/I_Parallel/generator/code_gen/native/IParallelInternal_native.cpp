// ##### extgen :: Auto-generated file do not edit!! #####

#include "IParallelInternal_native.h"
#include "IParallelInternal_exports.h"

using namespace gm_structs;
using namespace gm::wire::codec;

GMEXPORT double __EXT_NATIVE__rpe_worker_upload_lines(char* __arg_buffer, double __arg_buffer_length)
{
    gm::byteio::BufferReader __br{__arg_buffer, static_cast<size_t>(__arg_buffer_length)};

    // field: input, type: Pointer
    void* input = reinterpret_cast<void*>(gm::wire::codec::readValue<std::uint64_t>(__br));

    // field: line_count, type: Int32
    std::int32_t line_count = gm::wire::codec::readValue<std::int32_t>(__br);

    auto&& __result = rpe_worker_upload_lines(input, line_count);
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__rpe_worker_resolve_lines(char* __arg_buffer, double __arg_buffer_length)
{
    gm::byteio::BufferReader __br{__arg_buffer, static_cast<size_t>(__arg_buffer_length)};

    // field: input, type: Pointer
    void* input = reinterpret_cast<void*>(gm::wire::codec::readValue<std::uint64_t>(__br));

    // field: line_count, type: Int32
    std::int32_t line_count = gm::wire::codec::readValue<std::int32_t>(__br);

    // field: output, type: Pointer
    void* output = reinterpret_cast<void*>(gm::wire::codec::readValue<std::uint64_t>(__br));

    auto&& __result = rpe_worker_resolve_lines(input, line_count, output);
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__rpe_worker_shutdown()
{
    rpe_worker_shutdown();
    return 0;
}

