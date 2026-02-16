#!/bin/bash
set -e

LLVM_DEV_DIR=.
RESULT_FILE=results.md

# 環境定義: 名前 と コマンドプレフィックス
ENVS="${ENVS:-centos7}"
if [ -d /opt/nec/ve ]; then
  ENVS="$ENVS native"
fi

get_cmd_prefix() {
  local env=$1
  case "$env" in
    centos7) echo "apptainer exec centos7-ve-llvm-build_latest.sif" ;;
    ubuntu)  echo "apptainer exec ubuntu-ve-llvm-build_latest.sif" ;;
    native)  echo "" ;;
  esac
}

# リンク方式定義
LINKS="${LINKS:-static dso1 dso2}"

get_link_opts() {
  local link=$1
  case "$link" in
    static)  echo "" ;;
    dso1) echo "-DBUILD_SHARED_LIBS=ON" ;;
    dso2) echo "-DLLVM_BUILD_LLVM_DYLIB=ON -DLLVM_LINK_LLVM_DYLIB=ON" ;;
  esac
}

# 結果ファイルのヘッダを書き出す (APPEND_MODE時はスキップ)
if [ "${APPEND_MODE:-0}" != "1" ]; then
  cat > "$RESULT_FILE" << EOF
# LLVM ビルド性能比較結果
実行日時: $(date '+%Y-%m-%d %H:%M:%S')

| 環境 | リンク方式 | cmake (秒) | build (秒) | check-llvm (秒) | check-clang (秒) | 合計 (秒) |
|------|-----------|------------|-----------|-----------------|------------------|----------|
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

    # build (check-llvm + check-clang に必要な最小ビルド)
    start=$(date +%s)
    $CMD_PREFIX ninja -C "$BUILD_DIR" -j12 llvm-test-depends clang-test-depends
    end=$(date +%s)
    build_time=$((end - start))

    # check-llvm (テスト実行のみ、テスト失敗は無視して計測を継続)
    start=$(date +%s)
    check_llvm_rc=0
    $CMD_PREFIX ninja -C "$BUILD_DIR" -j12 check-llvm || check_llvm_rc=$?
    end=$(date +%s)
    check_llvm_time=$((end - start))

    # check-clang (テスト実行のみ、テスト失敗は無視して計測を継続)
    start=$(date +%s)
    check_clang_rc=0
    $CMD_PREFIX ninja -C "$BUILD_DIR" -j12 check-clang || check_clang_rc=$?
    end=$(date +%s)
    check_clang_time=$((end - start))

    total=$((cmake_time + build_time + check_llvm_time + check_clang_time))

    # 警告マーカーを生成
    warn=""
    [ "$check_llvm_rc" -ne 0 ] && warn="$warn check-llvm(rc=$check_llvm_rc)"
    [ "$check_clang_rc" -ne 0 ] && warn="$warn check-clang(rc=$check_clang_rc)"
    if [ -n "$warn" ]; then
      warn=" ⚠️$warn"
    fi

    echo "| $env | $link | $cmake_time | $build_time | $check_llvm_time | $check_clang_time | $total |$warn" >> "$RESULT_FILE"
    echo "=== Done: env=$env link=$link cmake=${cmake_time}s build=${build_time}s check-llvm=${check_llvm_time}s check-clang=${check_clang_time}s total=${total}s ==="
  done
done

echo ""
echo "Results written to $RESULT_FILE"
echo ""
cat "$RESULT_FILE"
