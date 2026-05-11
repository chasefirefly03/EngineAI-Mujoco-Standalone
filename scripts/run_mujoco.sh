#!/bin/bash

# Exits on error
set -e

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -d "$SCRIPT_DIR/simulation" ]]; then
  ROOT_DIR="$SCRIPT_DIR"
else
  ROOT_DIR="$(dirname "$SCRIPT_DIR")"
fi

echo "[INFO] Exports the environment variables:"
export ENGINEAI_ROBOTICS_DIR="$ROOT_DIR"
# shellcheck source=/dev/null
source "$ROOT_DIR/env.sh"

export ENGINEAI_ROBOTICS_PLATFORM="mujoco"
echo "[INFO] ENGINEAI_ROBOTICS_PLATFORM=$ENGINEAI_ROBOTICS_PLATFORM"

if [[ ! -d "$ENGINEAI_ROBOTICS_ASSETS/config" ]]; then
  echo "[WARN] 未找到 assets/config，仿真配置与模型缺失。请将仓库中的 assets/ 目录置于工程根目录。" >&2
fi

echo "[INFO] Run the executor:"
mujoco_dir="$ROOT_DIR/simulation/mujoco"
install_dir="$mujoco_dir/build"
cd "$install_dir"

if [[ $# -gt 0 ]]; then
  ./engineai_robotics_simulation_mujoco "$1"
else
  ./engineai_robotics_simulation_mujoco
fi
