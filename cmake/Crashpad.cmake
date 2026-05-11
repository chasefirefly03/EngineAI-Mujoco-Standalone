list(GET ENGINEAI_ROBOTICS_THIRD_PARTY 0 _crashpad_tp_root)
set(_engineai_crashpad_lib "${_crashpad_tp_root}/lib/libclient.a")
set(_engineai_crashpad_h "${_crashpad_tp_root}/include/crashpad/client/crashpad_client.h")
message(STATUS "Crashpad lookup under: ${_crashpad_tp_root}")

if(EXISTS "${_engineai_crashpad_lib}" AND EXISTS "${_engineai_crashpad_h}")
  set(ENGINEAI_HAVE_CRASHPAD TRUE)
else()
  set(ENGINEAI_HAVE_CRASHPAD FALSE)
  message(WARNING "Crashpad not found under ${_crashpad_tp_root} (expected libclient.a + include/crashpad/...). Building executor without crash reporting.")
endif()

if(ENGINEAI_HAVE_CRASHPAD)
  add_library(crashpad_client INTERFACE)
  target_include_directories(crashpad_client INTERFACE
      "${_crashpad_tp_root}/include/crashpad/"
      "${_crashpad_tp_root}/include/crashpad/client/"
      "${_crashpad_tp_root}/include/crashpad/util/"
      "${_crashpad_tp_root}/include/crashpad/snapshot/"
      "${_crashpad_tp_root}/include/crashpad/third_party/mini_chromium/"
  )
  target_link_libraries(crashpad_client INTERFACE
      "${_crashpad_tp_root}/lib/libclient.a"
  )
endif()
