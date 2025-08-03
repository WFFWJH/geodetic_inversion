#!/bin/csh

# 输入输出文件
set input_grd = "rng_offset_ll.grd"
set output_grd = "filtered.grd"

# 滤波参数
# 使用 3x3 的中值滤波窗口（radius = 1 grid spacing）
set filter_radius = 2
set filter_mode = "m"   # m = median

# 执行中值滤波
gmt grdfilter $input_grd -G$output_grd -F${filter_mode}${filter_radius} -D1

# 显示完成信息
echo "已完成中值滤波处理，输出文件为 $output_grd"
gmt grdimage $input_grd -JM15c -Baf -Ctest.cpt -png tobemask
gmt grdimage $output_grd -JM15c -Baf -Ctest.cpt -png masked

