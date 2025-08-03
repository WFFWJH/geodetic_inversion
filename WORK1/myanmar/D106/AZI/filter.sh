#!/usr/bin/env -S bash -e
# GMT modern mode bash template
# Date:    2025-07-16T16:01:04
# User:    ffan
# Purpose: Purpose of this script
export GMT_SESSION_NAME=$$	# Set a unique session name
gmt begin filter png
	# Place modern session commands here
	#
	mean=$(gmt grdinfo azi.grd -L2 -Cn| awk '{print $11}')
	stdev=$(gmt grdinfo azi.grd -L2 -Cn| awk '{print $12}')
	echo "mean=$mean, stdev=$stdev"
	low=$(awk -v m="$mean" -v s="$stdev" 'BEGIN { printf "%.10f\n", m - 3*s }')
high=$(awk -v m="$mean" -v s="$stdev" 'BEGIN { printf "%.10f\n", m + 3*s }')
echo "low=$low, high=$high"

gmt grdmath  azi.grd $low $high INRANGE azi.grd MUL 0 NAN = filtered.grd

	gmt grdimage filtered.grd -JM15c -Baf -Cpolar 
gmt end show
