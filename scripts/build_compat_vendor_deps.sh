#!/usr/bin/env bash
# Optional local deps for linking against prebuilt EngineAI Core on Ubuntu 22.04 (glog / fmt ABI).
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
"${script_dir}/build_vendor_glog.sh"
"${script_dir}/build_vendor_fmt.sh"
