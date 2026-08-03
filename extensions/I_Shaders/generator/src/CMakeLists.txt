set(SRC_DIR ${CMAKE_CURRENT_LIST_DIR})
if(WIN32)
  file(GLOB TARGET_SRCS CONFIGURE_DEPENDS "${SRC_DIR}/native/*.cpp")
endif()
target_sources(${PROJECT_NAME} PRIVATE ${TARGET_SRCS})
target_include_directories(${PROJECT_NAME} PRIVATE "${SRC_DIR}")
if(WIN32)
  set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".dll" OUTPUT_NAME "I_Shaders")
  target_compile_definitions(${PROJECT_NAME} PRIVATE I_SHADERS_BUILD=1)
  target_sources(${PROJECT_NAME} PRIVATE
    "${CMAKE_CURRENT_LIST_DIR}/../../../I_NativeCommon/I_Modules.cpp"
    "${CMAKE_CURRENT_LIST_DIR}/../../native/I_Shaders.rc")
  target_link_libraries(${PROJECT_NAME} PRIVATE d3d11 d3dcompiler dxguid)
endif()
