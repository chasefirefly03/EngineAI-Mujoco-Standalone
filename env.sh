# 未设置时使用当前目录作为 SDK 根（单独 source 本文件时用 $PWD）
if [ -z "$ENGINEAI_ROBOTICS_DIR" ]; then
  export ENGINEAI_ROBOTICS_DIR="$PWD"
fi
echo "[INFO] ENGINEAI_ROBOTICS_DIR=$ENGINEAI_ROBOTICS_DIR"

export ENGINEAI_ROBOTICS_ASSETS="$ENGINEAI_ROBOTICS_DIR/assets"
echo "[INFO] ENGINEAI_ROBOTICS_ASSETS=$ENGINEAI_ROBOTICS_ASSETS"

# 从 LD_LIBRARY_PATH 中移除：
# - /opt/engineai_robotics_*
# - deps/vendor_glog、deps/vendor_fmt（运行时若排在 deps/engineai_robotics_third_party 之前，
#   会加载旧 soname 的 libglog，与 Core / third_party 内的 libglog.so.3 混用 → LOG 析构段错误）
_engineai_strip_runtime_libs() {
  local _lp="${1:-}"
  local _root="${2:-}"
  local _out="" _first=1
  local _oldifs="$IFS"
  local -a _parts
  IFS=':' read -ra _parts <<< "$_lp" || true
  IFS="$_oldifs"
  local _p
  for _p in "${_parts[@]}"; do
    [[ -z "$_p" ]] && continue
    case "$_p" in
      /opt/engineai_robotics_third_party/*|/opt/engineai_robotics_hardware/*) continue ;;
    esac
    if [[ -n "$_root" ]]; then
      case "$_p" in
        "${_root}/deps/vendor_glog/lib"|"${_root}/deps/vendor_fmt/lib") continue ;;
      esac
    fi
    if [[ $_first -eq 1 ]]; then
      _out="$_p"
      _first=0
    else
      _out="$_out:$_p"
    fi
  done
  printf '%s' "$_out"
}

_use_vendored_deps=0
if [[ -d "$ENGINEAI_ROBOTICS_DIR/deps/engineai_robotics_third_party/lib" ]]; then
  export ENGINEAI_ROBOTICS_THIRD_PARTY="$ENGINEAI_ROBOTICS_DIR/deps/engineai_robotics_third_party"
  _use_vendored_deps=1
elif [[ -z "${ENGINEAI_ROBOTICS_THIRD_PARTY:-}" ]]; then
  export ENGINEAI_ROBOTICS_THIRD_PARTY="/opt/engineai_robotics_third_party"
fi
echo "[INFO] ENGINEAI_ROBOTICS_THIRD_PARTY=$ENGINEAI_ROBOTICS_THIRD_PARTY"

if [[ -f "$ENGINEAI_ROBOTICS_DIR/deps/engineai_robotics_hardware/lib/libmotor.so" ]]; then
  export ENGINEAI_ROBOTICS_HARDWARE="$ENGINEAI_ROBOTICS_DIR/deps/engineai_robotics_hardware"
  _use_vendored_deps=1
elif [[ -z "${ENGINEAI_ROBOTICS_HARDWARE:-}" ]]; then
  export ENGINEAI_ROBOTICS_HARDWARE="/opt/engineai_robotics_hardware"
fi
echo "[INFO] ENGINEAI_ROBOTICS_HARDWARE=$ENGINEAI_ROBOTICS_HARDWARE"

_lp_rest="$(_engineai_strip_runtime_libs "${LD_LIBRARY_PATH:-}" "$ENGINEAI_ROBOTICS_DIR")"

if [[ "$_use_vendored_deps" -eq 1 ]]; then
  # 仅用 deps/engineai_robotics_third_party 内的 glog/fmt（与 Core 一致）；勿前置 vendor_glog
  export LD_LIBRARY_PATH="${ENGINEAI_ROBOTICS_THIRD_PARTY}/lib:${ENGINEAI_ROBOTICS_HARDWARE}/lib:${ENGINEAI_ROBOTICS_DIR}/build/_install/lib:${ENGINEAI_ROBOTICS_DIR}/core/lib:${_lp_rest}"
  echo "[INFO] LD_LIBRARY_PATH (EngineAI: third_party+hardware+install+core; stripped vendor_glog/fmt + /opt/engineai)"
else
  export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:${ENGINEAI_ROBOTICS_THIRD_PARTY}/lib:${ENGINEAI_ROBOTICS_HARDWARE}/lib:${ENGINEAI_ROBOTICS_DIR}/build/_install/lib"
  echo "[INFO] LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
fi
