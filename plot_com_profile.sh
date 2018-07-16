rm -f .gmtdefaults4


echo 'Define Input and Output filename'
pjout_alos=ps_ALOSmean_v
ps_filename=ps_ALOSmean_v
alos=ps_ALOSmean_v.xy

#gmtset ANNOT_FONT_PRIMARY Times-Roman
#gmtset ANNOT_FONT_SECONDARY Courier
#gmtset HEADER_FONT Courier
#gmtset LABEL_FONT Courier-Bold
gmtset ANNOT_FONT 1 ANNOT_FONT_SIZE 12 ANNOT_FONT_SIZE_SECONDARY 20
gmtset LABEL_FONT_SIZE 12 TICK_LENGTH -0.1i


echo 'Load start/end points of profile line'
start=79.4/29.4
end=79.4/29.3

width=15c 
height=6c



echo '# Project data into *.gmt files #'
project  $alos -C$start -E$end -W-0.3/0.3 -Lw -Fxypz -Q > $pjout_alos.gmt
#awk '{print $1, $2, $3}' vertical_rate.dat | project   -C$start -E$end -W-10/10 -Lw -Fxypz -Q > ver_rate182.gmt

echo '# Project DEM into topo_profile.gmt (You need to prepare your own .grd topography) #'
#project -C$start -E$end -W-0.03/0.03 -Lw -Fxypz -Q >  inpfns.dat
sample1d -T0 -I0.0001 <<inpf>> point_file.dat
79.4	29.4
79.4	29.3
inpf

grdtrack India_new_point.dat -G/home/gotrc/GMT/InSAR/profile_test/India_new.grd -f > tmp
project  tmp -C$start -E$end -W-0.3/0.3 -Lw -Fxypz -Q > topo_profile.gmt

echo '# Plot profiles #'
## Plot ALOS PS LOS velocity points, ref to TN01=0, subtract 5.1547

psbasemap -R-0.5/20/-20/20 -JX$width/$height -Ba0f5::/a10f0g0WN:"LOS Velocity (mm/yr)": -Y20 -K > $ps_filename.ps
awk '{print $3, $4-5.1547, $5}' $pjout_alos.gmt | psxy -R -J -G0/200/0  -Sc0.06c -Ey0/0.1/100/100/100  -K -O>>$ps_filename.ps
psbasemap -R-0.5/20/-21.7/21.7 -JX$width/$height -Ba0/a10f0g0E:"Relative Uplift rate (mm/yr)":  -K -O >> $ps_filename.ps
#awk '{print $1, $2+1.54391, $3*2}' ./level-182/uprate_01.gmt | psxy -R -J  -G0/0/0 -Ey/thick  -K  -O>>$ps_filename.ps
#awk '{print $1, $2+2.92463, $3*2}' ./level-182/level182_05-08.gmt | psxy -R -J -G200/0/0 -Ss0.2c  -Ey/thick   -K  -O>>$ps_filename.ps

echo '# Plot Legend Box #'
psbasemap -R-0.5/20/-20/20 -JX4/1.8 -Ba0/a0f0g0n -Y4.2 -K -O >> $ps_filename.ps

psxy -R -J -Sc0.2c -G0/200/0 -K -O <<leg1>> $ps_filename.ps
2 10
leg1


psxy -R -J -Sc0.2c -G0/0/255 -K -O <<leg3>> $ps_filename.ps
2 -10
leg3

psxy -R -J -Ss0.2c -G200/0/0 -K -O <<leg2>> $ps_filename.ps
2 1
leg2

pstext -JX -R -G0/0/0 -V -K -O <<legtext>>  $ps_filename.ps
4	8	10	0	0	0	1993-99 PSI
4	-12	10	0	0	0	2005-08 PSI
4	-2	10	0	0	0	2005-08 Leveling
legtext
psbasemap -R-0.5/20/0/50 -JX$width/4 -Ba10f5:"Distance (km)":/a30f0g0WeSn:"Elevation (m)": -Y-8.2 -K -O >> $ps_filename.ps
awk '{print $3, $4}' topopf_182.gmt | psxy -R -J -Sc0.02 -G0/0/0 -K -O>>$ps_filename.ps

echo '# Generate JPG files from *.ps #'
gs -sDEVICE=jpeg -dJPEGQ=100 -dNOPAUSE -dBATCH -dSAFER -r300 -sOutputFile=$ps_filename.jpg $ps_filename.ps

rm tmp .gmt*
