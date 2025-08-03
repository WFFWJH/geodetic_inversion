#!/bin/csh

# 输入输出文件名
set input_grd = "rng_offset_ll.grd"
set output_grd = "cleaned.grd"

# 获取 grdinfo -L2 -Cn 输出，并分配字段
# 字段含义：xmin xmax ymin ymax zmin zmax xinc yinc nx ny mean stdev rms reg reg
set info = (`gmt grdinfo $input_grd -L2 -Cn`)
set mean = $info[11]
set stdev = $info[12]

# 计算上下限：mean ± n * stdev
set lower = `echo "$mean - 3 * $stdev" | bc -l`
set upper = `echo "$mean + 3 * $stdev" | bc -l`

# 显示信息
echo "Mean: $mean"
echo "Stdev: $stdev"
echo "Lower threshold: $lower"
echo "Upper threshold: $upper"

# 执行 grdclip
gmt grdclip $input_grd -G$output_grd -Sb${lower}/NaN -Sa${upper}/NaN

echo "完成：异常值已筛除，输出文件为 $output_grd"
gmt grdimage $input_grd -JM15c -Baf -Ctest.cpt -png tobemask
gmt grdimage $output_grd -JM15c -Baf -Ctest.cpt -png masked
