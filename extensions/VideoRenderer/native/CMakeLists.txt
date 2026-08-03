cmake_minimum_required(VERSION 3.20)
project(VideoRenderer LANGUAGES CXX)

add_library(VideoRenderer SHARED
    VideoRenderer.cpp
    ../third_party/amf/AMFMinimal.h
)
target_compile_features(VideoRenderer PRIVATE cxx_std_20)
target_link_libraries(VideoRenderer PRIVATE d3d11 dxgi)
set_target_properties(VideoRenderer PROPERTIES
    OUTPUT_NAME "VideoRenderer"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_CURRENT_LIST_DIR}/..")
