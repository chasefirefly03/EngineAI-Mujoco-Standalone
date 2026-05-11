#!/bin/bash

# Exits on error
set -e

# 定位工程根目录：本脚本位于 <root>/scripts/build_mujoco.sh
script_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -d "$script_dir/../simulation/mujoco" ]]; then
  echo "[build_mujoco] ERROR: 未找到 simulation/mujoco（相对于 $script_dir）。" >&2
  echo "[build_mujoco] 请从完整 SDK 根目录下的 scripts/ 运行本脚本。" >&2
  exit 1
fi
root_dir="$(cd "$script_dir/.." && pwd)"
mujoco_dir="$root_dir/simulation/mujoco"
deps_archive="$mujoco_dir/mujoco_deps_x86.tar.xz"
deps_dir="$mujoco_dir/_deps"

usage() {
  cat <<'EOF'
Usage: ./scripts/build_mujoco.sh [options]

Options:
  -m, --mirror-deps        Download MuJoCo dependencies from mirror repositories.
                           Use this only when GitHub is unreachable.
  -h, --help               Show this help message.
EOF
}

parse_args() {
  while (($# > 0)); do
    case "$1" in
      -m|--mirror-deps)
        use_mirror_deps=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown argument: $1"
        ;;
    esac
    shift
  done
}

download_mirrors_mujoco_deps() {
  mkdir -p "$deps_dir"
  if [ ! -f "$deps_dir/glfw3-src/CMakeLists.txt" ]; then
    git clone "https://gitee.com/mirrors/glfw.git" "$deps_dir/glfw3-src"
  fi

  if [ ! -f "$deps_dir/lodepng-src/lodepng.cpp" ]; then
    git clone "https://gitee.com/mirrors/LodePNG.git" "$deps_dir/lodepng-src"
  fi
}

has_local_mujoco_deps() {
  [ -f "$deps_dir/glfw3-src/CMakeLists.txt" ] && [ -f "$deps_dir/lodepng-src/lodepng.cpp" ]
}

parse_args "$@"

echo "[build_mujoco] SDK root: $root_dir"
echo "[build_mujoco] MuJoCo dir: $mujoco_dir"

if [[ "${use_mirror_deps:-0}" == "1" ]]; then
  echo "Downloading MuJoCo deps from gitee"
  download_mirrors_mujoco_deps
fi

if ! has_local_mujoco_deps && [ -f "$deps_archive" ]; then
  echo "Extracting local MuJoCo deps from $deps_archive ..."
  tar -xf "$deps_archive" -C "$mujoco_dir"
fi

deps_prefix="$root_dir/deps"
if [[ ! -f "$deps_prefix/vendor_glog/lib/libglog.so" ]] || [[ ! -f "$deps_prefix/vendor_fmt/lib/libfmt.so" ]]; then
  echo "[提示] 未发现 deps/vendor_glog 或 deps/vendor_fmt。预编译 Core 需要兼容的 glog 0.7+ 与 fmt 11，请先执行:"
  echo "       $root_dir/scripts/build_compat_vendor_deps.sh"
fi

cmake_args=(-DBUILD_RELEASE=ON)
if has_local_mujoco_deps; then
  echo "Using local MuJoCo deps from $deps_dir"
  cmake_args+=(-DMUJOCO_USE_LOCAL_DEPS=ON)
fi

# CMakeLists.txt 会优先使用 <root>/deps/engineai_robotics_*；此处保证 CMAKE_PREFIX_PATH 含 vendored third_party，便于 find_package(mujoco)
if [[ -d "$deps_prefix/engineai_robotics_third_party/lib/cmake" ]]; then
  export CMAKE_PREFIX_PATH="$deps_prefix/engineai_robotics_third_party:${CMAKE_PREFIX_PATH:-}"
fi

# Builds the project
build_dir="$mujoco_dir/build"
# If this tree was copied/moved, CMakeCache may still point at the old source root; drop stale build/.
if [[ -f "$build_dir/CMakeCache.txt" ]]; then
  cached_home="$(grep -m1 '^CMAKE_HOME_DIRECTORY:INTERNAL=' "$build_dir/CMakeCache.txt" 2>/dev/null | sed 's/^CMAKE_HOME_DIRECTORY:INTERNAL=//')"
  if [[ -n "$cached_home" && "$cached_home" != "$mujoco_dir" ]]; then
    echo "[build_mujoco] CMake 缓存指向其它源码目录，清理并重新配置: $cached_home -> $mujoco_dir"
    rm -rf "$build_dir"
  fi
fi
mkdir -p "$build_dir" && cd "$build_dir"
cmake "${cmake_args[@]}" ..

# Compiles with 2 threads less than the number of cores
num_cores=$(($(nproc) - 2))
if [ "$num_cores" -lt 1 ]; then
  num_cores=$(nproc)
fi
make -j"$num_cores"

echo "[build_mujoco] Done. Executable: $build_dir/engineai_robotics_simulation_mujoco"
