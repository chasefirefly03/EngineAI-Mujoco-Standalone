
# Set third-party libraries
include(${CMAKE_SOURCE_DIR}/cmake/Crashpad.cmake)

# Include auto register function
include(${CMAKE_SOURCE_DIR}/cmake/AutoRegisterRunners.cmake)

# Get the current folder name
string(REGEX REPLACE ".*/\(.*\)" "\\1" CURRENT_DIR ${CMAKE_CURRENT_SOURCE_DIR})

# Set target name
get_namespace(${CMAKE_CURRENT_SOURCE_DIR} CURRENT_TARGET_NAME)
get_alias_namespace(${CMAKE_CURRENT_SOURCE_DIR} CURRENT_TARGET_ALIAS_NAME)

# Set file collection
file(GLOB_RECURSE head_files ${CMAKE_CURRENT_SOURCE_DIR}/*.h ${CMAKE_CURRENT_SOURCE_DIR}/*.hpp)
file(GLOB_RECURSE souce_files ${CMAKE_CURRENT_SOURCE_DIR}/*.cc ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)
file(GLOB_RECURSE test_files  ${CMAKE_CURRENT_SOURCE_DIR}/test_*.cc ${CMAKE_CURRENT_SOURCE_DIR}/test_*.cpp)
list(REMOVE_ITEM souce_files ${test_files})

if(SDK_FRAMEWORK_MODE)
  list(FILTER souce_files EXCLUDE REGEX "auto_register_.*\\.cc$")
endif()

# Add target
add_executable(${CURRENT_TARGET_NAME})
add_executable(${CURRENT_TARGET_ALIAS_NAME} ALIAS ${CURRENT_TARGET_NAME})

# Set source file of target
target_sources(${CURRENT_TARGET_NAME} PRIVATE ${souce_files})

# Set head files of target
target_sources(${CURRENT_TARGET_NAME} INTERFACE ${head_files})

# Set include path of target
target_include_directories(${CURRENT_TARGET_NAME}
  PUBLIC 
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/>
)

# Set link libraries of target
target_link_libraries(${CURRENT_TARGET_NAME}
  PRIVATE
    src::app
)
if(ENGINEAI_HAVE_CRASHPAD)
  target_link_libraries(${CURRENT_TARGET_NAME} PRIVATE crashpad_client)
  target_compile_definitions(${CURRENT_TARGET_NAME} PRIVATE ENGINEAI_WITH_CRASHPAD=1)
endif()

# Auto-register runners (normal / SDK package / SDK framework modes)
auto_register_runners(${CURRENT_TARGET_NAME})

# Prebuilt EngineAICore .so files do not pull transitive shared-lib deps into the link line; link them explicitly.
if(SDK_FRAMEWORK_MODE)
  list(GET ENGINEAI_ROBOTICS_HARDWARE 0 _engineai_hw_root)
  list(GET ENGINEAI_ROBOTICS_THIRD_PARTY 0 _engineai_tp_root)
  set(_vendor_glog "${CMAKE_SOURCE_DIR}/deps/vendor_glog/lib/libglog.so")
  set(_vendor_fmt "${CMAKE_SOURCE_DIR}/deps/vendor_fmt/lib/libfmt.so")
  set(_tp_glog "${_engineai_tp_root}/lib/libglog.so.3")
  set(_tp_fmt "${_engineai_tp_root}/lib/libfmt.so.11")
  # 与 Core / src_app 一致：优先链接 third_party 内 libglog.so.3 / libfmt.so.11，避免与 vendor_glog（libglog.so.2）混链导致运行时 ABI 冲突
  if(EXISTS "${_tp_glog}")
    set(_engineai_glog_lib "${_tp_glog}")
  elseif(EXISTS "${_vendor_glog}")
    set(_engineai_glog_lib "${_vendor_glog}")
  else()
    set(_engineai_glog_lib "${_engineai_tp_root}/lib/libglog.so.3")
  endif()
  if(EXISTS "${_tp_fmt}")
    set(_engineai_fmt_lib "${_tp_fmt}")
  elseif(EXISTS "${_vendor_fmt}")
    set(_engineai_fmt_lib "${_vendor_fmt}")
  else()
    set(_engineai_fmt_lib "${_engineai_tp_root}/lib/libfmt.so.11")
  endif()
  target_link_options(${CURRENT_TARGET_NAME} PRIVATE
    "LINKER:-rpath-link,${_engineai_hw_root}/lib"
  )
  target_link_directories(${CURRENT_TARGET_NAME} PRIVATE "${_engineai_hw_root}/lib")
  target_link_libraries(${CURRENT_TARGET_NAME} PRIVATE
    "${_engineai_glog_lib}"
    "${_engineai_fmt_lib}"
    Eigen3::Eigen
    yaml-cpp::yaml-cpp
    pinocchio::pinocchio_default
    pinocchio::pinocchio_parsers
    "${_engineai_hw_root}/lib/libmotor.so"
  )
  set_target_properties(${CURRENT_TARGET_NAME} PROPERTIES
    BUILD_RPATH_USE_ORIGIN TRUE
    BUILD_RPATH "${_engineai_hw_root}/lib;${_engineai_tp_root}/lib;${CMAKE_SOURCE_DIR}/deps/vendor_glog/lib;${CMAKE_SOURCE_DIR}/deps/vendor_fmt/lib;${CMAKE_SOURCE_DIR}/core/lib"
  )
  target_link_libraries(${CURRENT_TARGET_NAME} PRIVATE
    "-Wl,--push-state,--no-as-needed"
    "${_engineai_fmt_lib}"
    "-Wl,--pop-state"
  )
endif()

# Set installation of target
install(TARGETS ${CURRENT_TARGET_NAME}
  EXPORT ${CURRENT_TARGET_ALIAS_NAME}
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION lib
  ARCHIVE DESTINATION lib
)

# Set tests
if(BUILD_TESTS AND test_files)
add_googletest(test_${CURRENT_TARGET_NAME}
  SRCS
    ${test_files}
  DEPS
    GTest::GTest
    GTest::Main
    pthread
    ${CURRENT_TARGET_NAME}
)
endif()
