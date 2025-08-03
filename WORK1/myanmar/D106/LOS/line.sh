#!/bin/bash
# 1. 生成段格式
awk '{print ">"; print $1, $2; print $3, $4}' ../fault > lines_segment.txt

# 2. 生成标注位置和标签
awk '{midlon=($1+$3)/2; midlat=($2+$4)/2; printf "%.3f %.3f Line%d\n", midlon, midlat, NR}' ../fault > labels.txt

# 3. 绘图
gmt begin map png
  gmt grdimage unwrap_ll.grd -R93.900000000/97.233333333/17.2416666667/23.7291666667 -Cpolar  -JM15c -Baf
  gmt plot lines_segment.txt -W0.1p,red
  gmt text labels.txt -F+f12p,Helvetica-Bold,blue+jCT
  gmt colorbar -C
gmt end show

