#!/bin/csh -f -x
#
#ln -s ../../../../WORK1/myanmar/D106/look_e.grd
#ln -s ../../../../WORK1/myanmar/D106/look_n.grd
#ln -s ../../../../WORK1/myanmar/D106/look_u.grd
#ln -s ../../../../WORK1/myanmar/D106/dem.grd
if ( -e unwrap_ll.grd) then
	gmt grdedit unwrap_ll.grd -L -Gunwrap_ll.grd
rm dem.grd
ln -s ../dem.grd
	gmt grdsample dem.grd -Runwrap_ll.grd -I2s -Gdem0.grd
	rm dem.grd
	mv dem0.grd dem.grd
	gmt grdinfo dem.grd -C
	gmt grdinfo unwrap_ll.grd -C
endif


