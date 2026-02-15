# LLVM ビルド性能比較結果

## SIF ファイル使用 (apptainer exec *.sif)
実行日時: 2026-02-15 17:50:10

| 環境 | リンク方式 | cmake (秒) | check-llvm (秒) | 合計 (秒) |
|------|-----------|------------|-----------------|----------|
| centos7 | static | 17 | 1052 | 1069 |
| centos7 | shared1 | 16 | 954 | 970 |
| centos7 | shared2 | 13 | 1042 | 1055 |
| ubuntu | static | 12 | 996 | 1008 |
| ubuntu | shared1 | 16 | 921 | 937 |
| ubuntu | shared2 | 15 | 991 | 1006 |

## Docker イメージ使用 (apptainer exec docker://jam7/centos7-ve-llvm-build:latest)
実行日時: 2026-02-15 21:59:30

| 環境 | リンク方式 | cmake (秒) | check-llvm (秒) | 合計 (秒) |
|------|-----------|------------|-----------------|----------|
| centos7 | static | 34 | 1045 | 1079 |
| centos7 | shared1 | 20 | 981 | 1001 |
| centos7 | shared2 | 14 | 1032 | 1046 |

## centos7 比較 (SIF vs Docker)

| リンク方式 | SIF 合計 (秒) | Docker 合計 (秒) | 差分 (秒) |
|-----------|-------------|-----------------|----------|
| static | 1069 | 1079 | +10 |
| shared1 | 970 | 1001 | +31 |
| shared2 | 1055 | 1046 | -9 |
