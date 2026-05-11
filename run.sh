#!/bin/bash

# Exits on error
set -e

# sudo chmod 666 /dev/ttyACM0

# Gets the source directory
readonly source_dir=$(cd $(dirname $0) && pwd)
readonly symbol_dir=""
readonly report_dir="/tmp/crashpad/report"
readonly dmpfile_dir="/tmp/crashpad/coredump/pending"

echo "[INFO] Exports the environment variables:"
cd "$source_dir"
# 强制使用本脚本所在目录为 SDK 根，避免继承外层 shell 里错误的 ENGINEAI_ROBOTICS_DIR，导致未加载 deps、Crashpad 仍指向 /opt
export ENGINEAI_ROBOTICS_DIR="$source_dir"
source ./env.sh
# 默认关闭 Crashpad，避免 handler 子进程 / ELF 解析报错（elf_dynamic_array_reader）干扰主程序；需要崩溃上报时: ENGINEAI_SKIP_CRASHPAD=0 ./run.sh
export ENGINEAI_SKIP_CRASHPAD="${ENGINEAI_SKIP_CRASHPAD:-1}"

echo "[INFO] Start the crash monitor:"
# record the core dump files before the executor is run
before_list_file=$(mktemp)
trap 'rm -f -- "$before_list_file"' EXIT
find "$dmpfile_dir" -maxdepth 1 -type f -name "*.dmp" | sort > "$before_list_file"

echo "[INFO] Run the executor:"
# 必须在工程根目录下启动：相对路径资源、插件与工作目录依赖与此一致（勿 cd 到 build/_install/bin）
install_dir="$source_dir/build/_install"
executor_bin="$install_dir/bin/src_executor"

set +e
if [ $# -gt 0 ]; then
    "$executor_bin" "$1"
else
    "$executor_bin"
fi

# Process the core dump files
exit_code=$?
if [ $exit_code -gt 128 ]; then
    new_dmp_files=$(comm -13 "$before_list_file" <(find "$dmpfile_dir" -maxdepth 1 -type f -name "*.dmp" | sort))
    if [ -n "$new_dmp_files" ]; then
        echo "[INFO] New core dump files found: $new_dmp_files"
        cd $source_dir
        ./scripts/process_dump.sh "$new_dmp_files" "$symbol_dir" "$report_dir"

        # print the full report with loaded modules
        # ./scripts/process_dump.sh -v "$new_dmp_files" "$symbol_dir" "$report_dir"
    fi
fi
