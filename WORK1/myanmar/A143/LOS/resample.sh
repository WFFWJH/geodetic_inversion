#!/bin/bash
# 用法: ./resample_grd.sh <源GRD文件> <目标GRD文件>

# 检查输入参数
if [ $# -ne 2 ]; then
    echo "错误: 需要2个参数！"
    echo "用法: $0 <源GRD文件> <目标GRD文件>"
    exit 1
fi

source_grd="$1"
target_grd="$2"

# 检查文件是否存在
if [ ! -f "$source_grd" ]; then
    echo "错误: 源文件 $source_grd 不存在"
    exit 1
fi
if [ ! -f "$target_grd" ]; then
    echo "错误: 目标文件 $target_grd 不存在"
    exit 1
fi

# 提取目标GRD的范围和间距
region=$(gmt grdinfo "$target_grd" -Cn | tail -1 | awk '{printf "-R%.9f/%.9f/%s/%s", $1, $2, $3, $4}')
spacing=$(gmt grdinfo "$target_grd" -Cn | tail -1 | awk '{printf "-I%s/%s", $7, $8}')

echo $region
echo $spacing

# 生成输出文件名
source_base=$(basename "$source_grd" .grd)
output_grd="${source_base}_resampled.grd"

# 执行重采样
echo "正在重采样 $source_grd -> $output_grd"
gmt grdsample "$source_grd" -G"$output_grd" $region $spacing -r -fg -V -nc

echo "完成！输出文件: $output_grd"
