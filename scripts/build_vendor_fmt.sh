#!/usr/bin/env bash
# Builds fmt 11.x for EngineAI Core (libsrc_app expects fmt::v11 symbols; third_party libfmt.so.11 may be older).
set -euo pipefail
root_dir="$(cd "$(dirname "$0")/.." && pwd)"
install_prefix="${root_dir}/deps/vendor_fmt"
tmp_dir="$(mktemp -d)"
cleanup() { rm -rf "${tmp_dir}"; }
trap cleanup EXIT

version="${FMT_VERSION:-11.0.2}"
echo "Fetching fmt ${version}..."
curl -fsSL -o "${tmp_dir}/src.tgz" "https://github.com/fmtlib/fmt/archive/refs/tags/${version}.tar.gz"
tar -xf "${tmp_dir}/src.tgz" -C "${tmp_dir}"
cmake -S "${tmp_dir}/fmt-${version}" -B "${tmp_dir}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${install_prefix}" \
  -DBUILD_SHARED_LIBS=ON \
  -DFMT_DOC=OFF \
  -DFMT_TEST=OFF
cmake --build "${tmp_dir}/build" -j"$(nproc)"
rm -rf "${install_prefix}"
cmake --install "${tmp_dir}/build"
echo "Installed compat fmt under ${install_prefix}/lib"
