// ##### extgen :: Auto-generated file do not edit!! #####

#include "ICompressionInternal_native.h"
#include "ICompressionInternal_exports.h"

using namespace gm_structs;
using namespace gm::wire::codec;

GMEXPORT double __EXT_NATIVE__unicode_zip_initialize()
{
    unicode_zip_initialize();
    return 0;
}

GMEXPORT double __EXT_NATIVE__unicode_zip_available()
{
    auto&& __result = unicode_zip_available();
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__unicode_zip_extract_async(char* archive_path, char* output_directory, double overwrite, double clean_output)
{
    auto&& __result = unicode_zip_extract_async(archive_path, output_directory, static_cast<bool>(overwrite), static_cast<bool>(clean_output));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__unicode_zip_compress_async(char* source_path, char* archive_path, double include_root, double overwrite)
{
    auto&& __result = unicode_zip_compress_async(source_path, archive_path, static_cast<bool>(include_root), static_cast<bool>(overwrite));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__unicode_zip_task_status(double task_id)
{
    auto&& __result = unicode_zip_task_status(static_cast<std::int32_t>(task_id));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__unicode_zip_task_exit_code(double task_id)
{
    auto&& __result = unicode_zip_task_exit_code(static_cast<std::int32_t>(task_id));
    return static_cast<double>(__result);
}

GMEXPORT char* __EXT_NATIVE__unicode_zip_task_error(double task_id)
{
    static std::string __result;
    __result = unicode_zip_task_error(static_cast<std::int32_t>(task_id));
    return (char*)__result.c_str();
}

GMEXPORT double __EXT_NATIVE__unicode_zip_task_cancel(double task_id)
{
    auto&& __result = unicode_zip_task_cancel(static_cast<std::int32_t>(task_id));
    return static_cast<double>(__result);
}

GMEXPORT double __EXT_NATIVE__unicode_zip_task_release(double task_id)
{
    auto&& __result = unicode_zip_task_release(static_cast<std::int32_t>(task_id));
    return static_cast<double>(__result);
}

GMEXPORT char* __EXT_NATIVE__unicode_zip_last_error()
{
    static std::string __result;
    __result = unicode_zip_last_error();
    return (char*)__result.c_str();
}

GMEXPORT double __EXT_NATIVE__unicode_zip_shutdown()
{
    unicode_zip_shutdown();
    return 0;
}

