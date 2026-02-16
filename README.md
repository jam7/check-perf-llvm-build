# LLVM Build Performance Benchmark

LLVM のビルド性能を、リンク方式（static / shared）ごとに比較するベンチマーク。

## リンク方式

| 名前 | CMake オプション | 説明 |
|------|-----------------|------|
| static | (デフォルト) | すべて静的リンク |
| dso1 | `-DBUILD_SHARED_LIBS=ON` | 各ライブラリを個別の .so にビルド |
| dso2 | `-DLLVM_BUILD_LLVM_DYLIB=ON -DLLVM_LINK_LLVM_DYLIB=ON` | 単一の libLLVM.so にまとめてビルド |

## Prerequisites

コンテナイメージ（SIF ファイル）を事前に取得しておく:

```bash
apptainer pull ~/centos7-ve-llvm-build.sif docker://jam7/centos7-ve-llvm-build:latest
apptainer pull ~/ubuntu-ve-llvm-build.sif docker://jam7/ubuntu-ve-llvm-build:latest
```

## Usage

```bash
bash run-bench.sh
```

環境変数で対象を絞れる:

```bash
ENVS="centos7" LINKS="static dso1" bash run-bench.sh
```

途中再開（results.md に追記）:

```bash
APPEND_MODE=1 LINKS="dso2" bash run-bench.sh
```
