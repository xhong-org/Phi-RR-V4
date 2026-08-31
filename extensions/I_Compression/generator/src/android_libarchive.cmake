include(FetchContent)
enable_language(C)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)

find_library(ZLIB_LIBRARY z REQUIRED)
find_path(ZLIB_INCLUDE_DIR zlib.h
    PATHS
        "${CMAKE_ANDROID_NDK}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include"
        "${CMAKE_SYSROOT}/usr/include"
    REQUIRED)
set(ZLIB_INCLUDE_DIRS "${ZLIB_INCLUDE_DIR}")
set(ZLIB_FOUND TRUE)

FetchContent_Declare(xz
    URL https://github.com/tukaani-project/xz/releases/download/v5.6.3/xz-5.6.3.tar.gz
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
set(XZ_TOOL_XZ OFF CACHE BOOL "" FORCE)
set(XZ_TOOL_XZDEC OFF CACHE BOOL "" FORCE)
set(XZ_TOOL_LZMADEC OFF CACHE BOOL "" FORCE)
set(XZ_TOOL_LZMAINFO OFF CACHE BOOL "" FORCE)
set(XZ_TOOL_SYMLINKS OFF CACHE BOOL "" FORCE)
set(XZ_DOC OFF CACHE BOOL "" FORCE)
set(XZ_NLS OFF CACHE BOOL "" FORCE)
set(XZ_SMALL ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(xz)

FetchContent_Declare(libarchive
    URL https://github.com/libarchive/libarchive/releases/download/v3.7.7/libarchive-3.7.7.tar.gz
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE)

set(ENABLE_TEST OFF CACHE BOOL "" FORCE)
set(ENABLE_TAR OFF CACHE BOOL "" FORCE)
set(ENABLE_CPIO OFF CACHE BOOL "" FORCE)
set(ENABLE_CAT OFF CACHE BOOL "" FORCE)
set(ENABLE_UNZIP OFF CACHE BOOL "" FORCE)
set(ENABLE_OPENSSL OFF CACHE BOOL "" FORCE)
set(ENABLE_LIBB2 OFF CACHE BOOL "" FORCE)
set(ENABLE_LZ4 OFF CACHE BOOL "" FORCE)
set(ENABLE_ZSTD OFF CACHE BOOL "" FORCE)
set(ENABLE_LIBXML2 OFF CACHE BOOL "" FORCE)
set(ENABLE_EXPAT OFF CACHE BOOL "" FORCE)
set(ENABLE_PCREPOSIX OFF CACHE BOOL "" FORCE)
set(ENABLE_PCRE2POSIX OFF CACHE BOOL "" FORCE)
set(ENABLE_CNG OFF CACHE BOOL "" FORCE)
set(ENABLE_ICONV OFF CACHE BOOL "" FORCE)
set(ENABLE_ACL OFF CACHE BOOL "" FORCE)
set(ENABLE_XATTR OFF CACHE BOOL "" FORCE)
set(ENABLE_WERROR OFF CACHE BOOL "" FORCE)
set(POSIX_REGEX_LIB "libc" CACHE STRING "" FORCE)
set(ENABLE_BZip2 OFF CACHE BOOL "" FORCE)
set(ENABLE_LZMA ON CACHE BOOL "" FORCE)
set(ENABLE_ZLIB ON CACHE BOOL "" FORCE)

set(LIBLZMA_INCLUDE_DIR "${xz_SOURCE_DIR}/src/liblzma/api" CACHE PATH "" FORCE)
set(LIBLZMA_INCLUDE_DIRS "${xz_SOURCE_DIR}/src/liblzma/api" CACHE PATH "" FORCE)
set(LIBLZMA_LIBRARY liblzma CACHE FILEPATH "" FORCE)
set(LIBLZMA_LIBRARIES liblzma CACHE STRING "" FORCE)
set(LIBLZMA_HAS_AUTO_DECODER TRUE CACHE BOOL "" FORCE)
set(LIBLZMA_HAS_EASY_ENCODER TRUE CACHE BOOL "" FORCE)
set(LIBLZMA_HAS_LZMA_PRESET TRUE CACHE BOOL "" FORCE)
set(LIBLZMA_FOUND TRUE)

FetchContent_MakeAvailable(libarchive)

set(_archive_target "")
if(TARGET archive_static)
    set(_archive_target archive_static)
elseif(TARGET archive)
    set(_archive_target archive)
else()
    message(FATAL_ERROR "libarchive target was not created")
endif()

target_compile_definitions(${_archive_target} PRIVATE HAVE_LIBLZMA=1 HAVE_LZMA_H=1 LZMA_API_STATIC)
target_include_directories(${_archive_target} PRIVATE "${xz_SOURCE_DIR}/src/liblzma/api")
target_link_libraries(${_archive_target} liblzma)
target_link_libraries(${PROJECT_NAME} PRIVATE ${_archive_target} liblzma ${ZLIB_LIBRARY})
target_include_directories(${PROJECT_NAME} PRIVATE
    "${libarchive_SOURCE_DIR}/libarchive"
    "${xz_SOURCE_DIR}/src/liblzma/api")
target_compile_definitions(${PROJECT_NAME} PRIVATE LIBARCHIVE_STATIC LZMA_API_STATIC)
