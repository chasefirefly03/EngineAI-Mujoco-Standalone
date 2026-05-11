#!/usr/bin/env bash
# 完整构建入口：与本压缩包解压后的工程根目录同一层级运行（CMakeLists.txt、src、deps 与脚本并列）。
# 可选 apt 安装联网依赖，再执行与 build.sh 相同的编译流程。
# 用法与 build.sh 一致，并额外支持:
#   --skip-apt    跳过 apt 安装（离线或已备好环境时使用）

# 与 build.sh 一致，不使用 nounset，避免 source /opt/ros/humble/setup.sh 时未定义变量报错
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_ROOT="$SCRIPT_DIR"
source_dir="$SDK_ROOT"
build_dir="$source_dir/build"
build_type="releasewithdebinfo"
build_tests="OFF"
module_name=""
num_cores=""
SKIP_APT=0

# 解析并移除 --skip-apt，其余参数交给 getopts
filtered_args=()
for a in "$@"; do
  if [[ "$a" == "--skip-apt" ]]; then
    SKIP_APT=1
  else
    filtered_args+=("$a")
  fi
done
set -- "${filtered_args[@]}"

while getopts ":j:t:m:T" opt; do
  case $opt in
    j) num_cores=$OPTARG ;;
    t) build_type=$OPTARG ;;
    m) module_name=$OPTARG ;;
    T) build_tests="ON" ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "Usage: $0 [--skip-apt] [-j num_cores] [-t build_type] [-m module_name] [-T]" >&2
      echo "  --skip-apt  Skip apt package installation" >&2
      echo "  build_type: release, debug, releasewithdebinfo (default: releasewithdebinfo)" >&2
      echo "  -m: Compile specific module only (e.g., runner_imu)" >&2
      echo "  -T: Enable test compilation" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

if [[ "$build_type" != "release" && "$build_type" != "debug" && "$build_type" != "releasewithdebinfo" ]]; then
  echo "Invalid build type: $build_type" >&2
  exit 1
fi

if [[ -z "${num_cores:-}" ]]; then
  num_cores=$(($(nproc) - 2))
  if [[ "$num_cores" -lt 1 ]]; then
    num_cores=$(nproc)
  fi
fi

echo "[new_build] SDK root: $SDK_ROOT"
echo "[new_build] Using $num_cores cores, build type: $build_type"

# -----------------------------------------------------------------------------
# 可通过网络安装的依赖（Ubuntu 22.04 + ROS 2 Humble）
# 若尚未配置 ROS2 apt 源，请先执行官方文档中的安装步骤:
# https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debs.html
# -----------------------------------------------------------------------------
install_apt_packages() {
  if [[ "${SKIP_APT}" -eq 1 ]]; then
    echo "[new_build] SKIP_APT=1, skipping apt."
    return 0
  fi
  if ! command -v sudo >/dev/null 2>&1; then
    echo "[new_build] ERROR: sudo not found; install packages manually or use --skip-apt." >&2
    exit 1
  fi
  export DEBIAN_FRONTEND=noninteractive
  echo "[new_build] Running apt-get update / install (needs sudo)..."
  sudo apt-get update -y
  sudo apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    git \
    python3 \
    python3-pip \
    python3-colcon-common-extensions \
    libgoogle-glog-dev \
    libyaml-cpp-dev \
    libfmt-dev \
    libeigen3-dev \
    liblcm-dev \
    libgtest-dev \
    zlib1g-dev \
    ros-humble-ros-base \
    ros-humble-rclcpp \
    ros-humble-rclcpp-action \
    ros-humble-fastcdr \
    ros-humble-rmw-fastrtps-cpp \
    ros-humble-std-msgs \
    ros-humble-geometry-msgs \
    ros-humble-sensor-msgs \
    ros-humble-action-msgs \
    ros-humble-rosidl-default-generators \
    ros-humble-ament-cmake \
    ros-humble-ament-index-cpp \
    ros-humble-rosidl-adapter \
    ros-humble-rosidl-typesupport-fastrtps-cpp \
    ros-humble-rosidl-typesupport-fastrtps-c \
    ros-humble-rosidl-typesupport-introspection-cpp \
    ros-humble-rosidl-typesupport-introspection-c
  echo "[new_build] apt packages installed."
}

install_apt_packages

if [[ ! -f /opt/ros/humble/setup.bash ]]; then
  echo "[new_build] ERROR: /opt/ros/humble/setup.bash not found." >&2
  echo "Install ROS 2 Humble (Ubuntu deb): https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debs.html" >&2
  exit 1
fi

cd "$source_dir"

echo "Building ros2 env..."
if ! bash "$source_dir/scripts/build_ros2_env.sh"; then
  echo "Failed to build ros2 env."
  exit 1
fi

echo "Building project..."
mkdir -p "$build_dir"
cd "$build_dir"

if [[ -n "$module_name" ]]; then
  if [[ ! -f "$build_dir/CMakeCache.txt" ]]; then
    echo "Error: CMakeCache.txt not found. Run full build first: $0" >&2
    exit 1
  fi
  echo "Using existing cmake configuration for module compilation."
else
  # shellcheck source=/dev/null
  source /opt/ros/humble/setup.sh
  cmake -DBUILD_TYPE="$build_type" \
        -DBUILD_TESTS="$build_tests" \
        -DBUILD_ROS2=ON \
        -DBUILD_DCHECK=ON ..
fi

if [[ -n "$module_name" ]]; then
  cmake_target=$(echo "$module_name" | sed 's/\//_/g')
  if [[ ! "$cmake_target" == src_* ]]; then
    cmake_target="src_runner_${cmake_target}"
  fi
  make -j"$num_cores" "$cmake_target"
  echo "Installing module: $cmake_target"
  make install
  echo "Module compilation completed: $cmake_target"
else
  make -j"$num_cores"
  make install
  echo "Full build completed."
fi
