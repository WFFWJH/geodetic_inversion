#!/bin/bash
gmt begin plot_grd_mask png

gmt basemap -R93.15/99.27/15.1/24.54 -JM15c -Baf

files=(gmt_a143.grd gmt_a70.grd gmt_d33.grd gmt_d106.grd)
colors=(red blue green orange)

for i in ${!files[@]}; do
  f=${files[i]}
  c=${colors[i]}

  # 生成掩膜，非NaN点为1，NaN点为NaN
  gmt grdmath $f ISNAN 0 EQ 1 NaN  IFELSE = mask_$f.nc

  gmt grdcontour mask_$f.nc -C0.5 -W2p,$c
done

gmt end show

