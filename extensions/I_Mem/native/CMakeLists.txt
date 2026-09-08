cmake_minimum_required(VERSION 3.18)
project(I_Mem LANGUAGES CXX)

add_library(I_Mem SHARED I_Mem.cpp)
target_compile_features(I_Mem PRIVATE cxx_std_20)
target_compile_definitions(I_Mem PRIVATE WIN32_LEAN_AND_MEAN NOMINMAX)
target_link_libraries(I_Mem PRIVATE psapi)
set_target_properties(I_Mem PROPERTIES
    OUTPUT_NAME "I_Mem"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/.."
    RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_CURRENT_SOURCE_DIR}/.."
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_CURRENT_SOURCE_DIR}/.."
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/.."
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../out"
)
if(MSVC)
    target_compile_options(I_Mem PRIVATE /W4 /permissive- /utf-8)
    set_property(TARGET I_Mem PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")
endif()
