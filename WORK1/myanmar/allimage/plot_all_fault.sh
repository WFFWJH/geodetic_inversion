#!/bin/bash
gmt begin plot_grd_points png

gmt basemap -R93.15/99.27/15.1/24.54 -JM15c -Baf

files=(a143.grd a70.grd d33.grd d106.grd)
colors=(red blue green orange)

awk '{print ">"; print $1, $2; print $3, $4}' ../../fault > lines_segment.txt

awk '{midlon=($1+$3)/2; midlat=($2+$4)/2; printf "%.3f %.3f Line%d\n", midlon, midlat, NR}' ../../fault > labels.txt

 

skip=1000
for i in ${!files[@]}; do
  f=${files[i]}
  c=${colors[i]}

  # 只提取非NaN点，绘制散点图来代表实际区域
  gmt grd2xyz $f -s |awk "NR % $skip == 0"| gmt plot -Sc0.05c -G$c
done
 gmt plot lines_segment.txt -W2p,white
  gmt text labels.txt -F+f12p,Helvetica-Bold,blue+jCT


gmt end show

