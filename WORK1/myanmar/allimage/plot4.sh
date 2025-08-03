#!/usr/bin/env -S bash -e
# GMT modern mode bash template
# Date:    2025-06-16T18:46:00
# User:    ffan
# Purpose: Purpose of this script
gmt begin plot_grd_areas png

# 设置统一投影和边界（取第一个文件的区域做整体范围）
minx=93.15
maxx=99.27
miny=15.1
maxy=24.54
gmt basemap -R$minx/$maxx/$miny/$maxy -JM15c -Baf

# 定义文件名和颜色
files=(a143.grd a70.grd d33.grd d106.grd)
colors=(red blue green orange)

# 逐个绘制
for i in ${!files[@]}; do
  f=${files[i]}
  c=${colors[i]}

  # 提取四个角坐标
  read x1 x2 y1 y2 <<< $(gmt grdinfo $f -C | awk '{print $2, $3, $4, $5}')

  # 构建矩形并绘制边框
  cat << EOF | gmt plot -W2p,$c -L
$x1 $y1
$x2 $y1
$x2 $y2
$x1 $y2
$x1 $y1
EOF

  # 在中心点加标签
  center_x=$(echo "($x1 + $x2)/2" | bc -l)
  center_y=$(echo "($y1 + $y2)/2" | bc -l)
  echo "$center_x $center_y $f" | gmt text -F+f10p,Helvetica-Bold,$c
done

gmt end show

