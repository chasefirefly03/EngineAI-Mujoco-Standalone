# Finds LCM (e.g. Ubuntu liblcm-dev: headers + pkg-config, no CMake config).
find_path(LCM_INCLUDE_DIR
  NAMES lcm/lcm.h
  PATH_SUFFIXES include
)

find_library(LCM_LIBRARY
  NAMES lcm
  PATH_SUFFIXES lib lib/x86_64-linux-gnu
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(lcm
  FOUND_VAR lcm_FOUND
  REQUIRED_VARS LCM_LIBRARY LCM_INCLUDE_DIR
)

if(lcm_FOUND AND NOT TARGET lcm)
  add_library(lcm UNKNOWN IMPORTED)
  set_target_properties(lcm PROPERTIES
    IMPORTED_LOCATION "${LCM_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${LCM_INCLUDE_DIR}"
  )
endif()
