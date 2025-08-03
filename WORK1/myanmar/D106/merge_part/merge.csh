#!/bin/csh
#
if( $#argv<1) then
	echo "$0 used error"
	exit 1
endif

set input = "$argv[1]"
set input1 = "$argv[2]"
set inc = "$argv[3]"
set area = "$argv[4]"

gmt grdcut ${input} -R$area -N -G${input}_
gmt grdcut ${input1} -R$area -N -G${input}_
gmt 
