set(SRC_DIR ${CMAKE_CURRENT_LIST_DIR})

# =============================================================================
# GameMaker iOS integration (optional)
# =============================================================================
set(EXT_GM_XCODEPROJ_OVERRIDE "/ABS/PATH/TO/GAME.xcodeproj" CACHE STRING "" FORCE)
set(EXT_GM_APP_TARGET_OVERRIDE "" CACHE STRING "" FORCE)

# =============================================================================
# Public headers for Apple XCFramework packaging
# Users should edit these to match their project structure.
# The packager will copy these into a headers folder passed to xcodebuild.
# =============================================================================
set(EXT_PUBLIC_HEADERS_IOS
    "${CMAKE_SOURCE_DIR}/src/ios/${PROJECT_NAME}_ios.h;${CMAKE_SOURCE_DIR}/code_gen/ios/${PROJECT_NAME}Internal_ios.h"
    CACHE STRING "Semicolon-separated list of public headers to embed in the iOS xcframework")

set(EXT_PUBLIC_HEADERS_TVOS
    "${CMAKE_SOURCE_DIR}/src/tvos/${PROJECT_NAME}_tvos.h;${CMAKE_SOURCE_DIR}/code_gen/tvos/${PROJECT_NAME}Internal_tvos.h"
    CACHE STRING "Semicolon-separated list of public headers to embed in the tvOS xcframework")

# =============================================================================
# User implementation sources per platform (editable template)
# =============================================================================
if(WIN32)
  file(GLOB TARGET_SRCS CONFIGURE_DEPENDS "${SRC_DIR}/native/*.cpp")

elseif(APPLE)
  if(CMAKE_OSX_SYSROOT MATCHES "iphone")
    file(GLOB TARGET_SRCS CONFIGURE_DEPENDS "${SRC_DIR}/ios/*.mm" "${SRC_DIR}/ios/*.cpp" "${SRC_DIR}/ios/*.swift")
  elseif(CMAKE_OSX_SYSROOT MATCHES "appletv")
    file(GLOB TARGET_SRCS CONFIGURE_DEPENDS "${SRC_DIR}/tvos/*.mm" "${SRC_DIR}/tvos/*.cpp" "${SRC_DIR}/tvos/*.swift")
  else()
    file(GLOB TARGET_SRCS CONFIGURE_DEPENDS "${SRC_DIR}/native/*.mm" "${SRC_DIR}/native/*.cpp" "${SRC_DIR}/native/*.swift")
  endif()

elseif(ANDROID)
  file(GLOB TARGET_SRCS CONFIGURE_DEPENDS "${SRC_DIR}/android/*.cpp")

elseif(UNIX)
  file(GLOB TARGET_SRCS CONFIGURE_DEPENDS "${SRC_DIR}/native/*.cpp")
endif()

target_sources(${PROJECT_NAME} PRIVATE ${TARGET_SRCS})
target_include_directories(${PROJECT_NAME} PRIVATE "${SRC_DIR}")

if(WIN32)
  set(FFVIDEOS_FFMPEG_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../ffmpeg-minimal/out" CACHE PATH "FFmpeg development package root")
  option(FFVIDEOS_FFMPEG_STATIC "Link a minimal static FFmpeg build into FFVideos.dll" ON)
  if(NOT EXISTS "${FFVIDEOS_FFMPEG_ROOT}/include/libavcodec/avcodec.h")
    message(FATAL_ERROR "FFVIDEOS_FFMPEG_ROOT does not contain FFmpeg headers: ${FFVIDEOS_FFMPEG_ROOT}")
  endif()
  set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".dll" OUTPUT_NAME "FFVideos")
  target_compile_definitions(${PROJECT_NAME} PRIVATE _WIN32_WINNT=0x0602 WINVER=0x0602)
  target_include_directories(${PROJECT_NAME} PRIVATE "${FFVIDEOS_FFMPEG_ROOT}/include")
  if(FFVIDEOS_FFMPEG_STATIC)
    set(FFVIDEOS_FFMPEG_LIBRARIES
      "${FFVIDEOS_FFMPEG_ROOT}/lib/libavformat.a"
      "${FFVIDEOS_FFMPEG_ROOT}/lib/libavcodec.a"
      "${FFVIDEOS_FFMPEG_ROOT}/lib/libswscale.a"
      "${FFVIDEOS_FFMPEG_ROOT}/lib/libavutil.a")
  else()
    set(FFVIDEOS_FFMPEG_LIBRARIES
      "${FFVIDEOS_FFMPEG_ROOT}/lib/avformat.lib"
      "${FFVIDEOS_FFMPEG_ROOT}/lib/avcodec.lib"
      "${FFVIDEOS_FFMPEG_ROOT}/lib/avutil.lib"
      "${FFVIDEOS_FFMPEG_ROOT}/lib/swscale.lib")
  endif()
  target_link_libraries(${PROJECT_NAME} PRIVATE
    d3d11
    d3dcompiler
    dxgi
    ${FFVIDEOS_FFMPEG_LIBRARIES}
    advapi32
    bcrypt
    ole32
    secur32
    shell32
    user32
    ws2_32)
  if(FFVIDEOS_FFMPEG_STATIC)
    add_custom_target(FFVideos_ffmpeg_license ALL
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${FFVIDEOS_FFMPEG_ROOT}/COPYING.LGPLv2.1"
        "${CMAKE_CURRENT_LIST_DIR}/../../COPYING.LGPLv2.1"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${FFVIDEOS_FFMPEG_ROOT}/FFmpeg-LICENSE.md"
        "${CMAKE_CURRENT_LIST_DIR}/../../FFmpeg-LICENSE.md"
      COMMAND ${CMAKE_COMMAND} -E rm -f
        "${CMAKE_CURRENT_LIST_DIR}/../../avformat-62.dll"
        "${CMAKE_CURRENT_LIST_DIR}/../../avcodec-62.dll"
        "${CMAKE_CURRENT_LIST_DIR}/../../avutil-60.dll"
        "${CMAKE_CURRENT_LIST_DIR}/../../swscale-9.dll"
        "${CMAKE_CURRENT_LIST_DIR}/../../swresample-6.dll"
        "${CMAKE_CURRENT_LIST_DIR}/../../FFmpeg-LICENSE.txt")
    add_dependencies(${PROJECT_NAME} FFVideos_ffmpeg_license)
  else()
    add_custom_target(FFVideos_ffmpeg_runtime ALL
      COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FFVIDEOS_FFMPEG_ROOT}/bin/avformat-62.dll" "${CMAKE_CURRENT_LIST_DIR}/../../avformat-62.dll"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FFVIDEOS_FFMPEG_ROOT}/bin/avcodec-62.dll" "${CMAKE_CURRENT_LIST_DIR}/../../avcodec-62.dll"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FFVIDEOS_FFMPEG_ROOT}/bin/avutil-60.dll" "${CMAKE_CURRENT_LIST_DIR}/../../avutil-60.dll"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FFVIDEOS_FFMPEG_ROOT}/bin/swscale-9.dll" "${CMAKE_CURRENT_LIST_DIR}/../../swscale-9.dll"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different "${FFVIDEOS_FFMPEG_ROOT}/bin/swresample-6.dll" "${CMAKE_CURRENT_LIST_DIR}/../../swresample-6.dll"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${FFVIDEOS_FFMPEG_ROOT}/LICENSE.txt"
        "${CMAKE_CURRENT_LIST_DIR}/../../FFmpeg-LICENSE.txt")
    add_dependencies(${PROJECT_NAME} FFVideos_ffmpeg_runtime)
  endif()
elseif(ANDROID)
  set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "FFVideos")
  target_sources(${PROJECT_NAME} PRIVATE "${CMAKE_CURRENT_LIST_DIR}/../../native/FFVideos_android.cpp")
  find_library(_gles_lib GLESv2)
  find_library(_egl_lib EGL)
  find_library(_mediandk_lib mediandk)
  find_library(_dl_lib dl)
  target_link_libraries(${PROJECT_NAME} PRIVATE ${_gles_lib} ${_egl_lib} ${_mediandk_lib} ${_dl_lib})
endif()
