#!/bin/bash
set -e

LLVM_DEV_DIR=/home/jam/llvm-dev
RESULT_FILE=/home/jam/check-perf/results.md

# 環境定義: 名前 と コマンドプレフィックス
ENVS="${ENVS:-centos7}"
if [ -d /opt/nec/ve ]; then
  ENVS="$ENVS native"
fi

get_cmd_prefix() {
  local env=$1
  case "$env" in
    centos7) echo "apptainer exec docker://jam7/centos7-ve-llvm-build:latest" ;;
    ubuntu)  echo "apptainer exec $HOME/ubuntu-ve-llvm-build.sif" ;;
    native)  echo "" ;;
  esac
}

# リンク方式定義
LINKS="${LINKS:-static shared1 shared2}"

get_link_opts() {
  local link=$1
  case "$link" in
    static)  echo "" ;;
    shared1) echo "-DBUILD_SHARED_LIBS=ON" ;;
    shared2) echo "-DLLVM_BUILD_LLVM_DYLIB=ON -DLLVM_LINK_LLVM_DYLIB=ON" ;;
  esac
}

# 結果ファイルのヘッダを書き出す (APPEND_MODE時はスキップ)
if [ "${APPEND_MODE:-0}" != "1" ]; then
  cat > "$RESULT_FILE" << EOF
# LLVM ビルド性能比較結果
実行日時: $(date '+%Y-%m-%d %H:%M:%S')

| 環境 | リンク方式 | cmake (秒) | check-llvm (秒) | 合計 (秒) |
|------|-----------|------------|-----------------|----------|
EOF
fi

# 全パターンを実行
for env in $ENVS; do
  for link in $LINKS; do
    BUILD_DIR="${LLVM_DEV_DIR}/build-${env}-${link}"
    CMD_PREFIX=$(get_cmd_prefix "$env")
    export EXTRA_CMAKE_OPTS=$(get_link_opts "$link")

    echo "=== Running: env=$env link=$link ==="
    echo "  BUILD_DIR=$BUILD_DIR"
    echo "  EXTRA_CMAKE_OPTS=$EXTRA_CMAKE_OPTS"

    # cmake (構成)
    start=$(date +%s)
    $CMD_PREFIX make -C "$LLVM_DEV_DIR" cmake LLVM_BUILDDIR="$BUILD_DIR" BUILD_TYPE=Debug
    end=$(date +%s)
    cmake_time=$((end - start))

    # check-llvm (ビルド＋テスト)
    start=$(date +%s)
    $CMD_PREFIX make -C "$LLVM_DEV_DIR" check-llvm LLVM_BUILDDIR="$BUILD_DIR" BUILD_TYPE=Debug
    end=$(date +%s)
    check_time=$((end - start))

    total=$((cmake_time + check_time))

    echo "| $env | $link | $cmake_time | $check_time | $total |" >> "$RESULT_FILE"
    echo "=== Done: env=$env link=$link cmake=${cmake_time}s check=${check_time}s total=${total}s ==="
  done
done

echo ""
echo "Results written to $RESULT_FILE"
echo ""
cat "$RESULT_FILE"
