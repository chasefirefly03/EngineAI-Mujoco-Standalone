#!/usr/bin/env bash
# Builds glog >= 0.7 next to this SDK so src_executor can link against EngineAI Core (VLOG SiteFlag ABI).
set -euo pipefail
root_dir="$(cd "$(dirname "$0")/.." && pwd)"
install_prefix="${root_dir}/deps/vendor_glog"
tmp_dir="$(mktemp -d)"
cleanup() { rm -rf "${tmp_dir}"; }
trap cleanup EXIT

version="${GLOG_VERSION:-v0.7.1}"
echo "Fetching glog ${version}..."
curl -fsSL -o "${tmp_dir}/src.tgz" "https://github.com/google/glog/archive/refs/tags/${version}.tar.gz"
tar -xf "${tmp_dir}/src.tgz" -C "${tmp_dir}"
tag_name="${version}"
if [[ "${tag_name}" =~ ^v[0-9] ]]; then
  src_dir="${tmp_dir}/glog-${tag_name#v}"
else
  src_dir="${tmp_dir}/glog-${tag_name}"
fi
cmake -S "${src_dir}" -B "${tmp_dir}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${install_prefix}" \
  -DBUILD_SHARED_LIBS=ON \
  -DWITH_GFLAGS=ON \
  -DWITH_UNWIND=ON
cmake --build "${tmp_dir}/build" -j"$(nproc)"
rm -rf "${install_prefix}"
cmake --install "${tmp_dir}/build"
# Prebuilt Core reports DT_NEEDED libglog.so.3; Ubuntu/third_party may symlink .3 to old glog — provide a .3 alias to this build.
shopt -s nullglob
for _gf in "${install_prefix}/lib"/libglog.so.[0-9]*.[0-9]*; do
  ln -sfn "$(basename "${_gf}")" "${install_prefix}/lib/libglog.so.3"
  break
done
shopt -u nullglob
echo "Installed compat glog under ${install_prefix}/lib"
