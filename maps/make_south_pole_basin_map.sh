#!/bin/bash 

srf=$WAIS/targ/supl/grid-icesat2/Smith2020/ais_grounded.grd
srf=$WAIS/targ/supl/grid-ntpdc_cn/Shen22/Antarctic_DEM_from_ICESat-2.grd
srf=$WAIS/targ/supl/grid-pgc/rema/1km/REMA_1km_dem_filled.grd

thk=$WAIS/targ/supl/modl-beijing_normal_university/wolovick-2021a/Icethick.grd
bed=$WAIS/targ/supl/modl-beijing_normal_university/wolovick-2021a/BedElev.grd

data=$WAIS/targ/comm/DATA-OPR/projected_images_COLDEX

TARG=`pwd | sed s@code@targ@`
mkdir -p $TARG
srf=$TARG/../srfelv/srfelv.xyz_val.grd

WIDTH=8c

X_W=200
X_E=325
Y_N=150
Y_S=25

X_W_M=${X_W}000
X_E_M=${X_E}000
Y_N_M=${Y_N}000
Y_S_M=${Y_S}000

echo '>' > spb_bounds.xy
echo $X_W_M $Y_N_M >> spb_bounds.xy
echo $X_W_M $Y_S_M >> spb_bounds.xy
echo $X_E_M $Y_S_M >> spb_bounds.xy
echo $X_E_M $Y_N_M >> spb_bounds.xy
echo $X_W_M $Y_N_M >> spb_bounds.xy

LON_1=`echo "$X_W $Y_S" | mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $1}'`
LAT_1=`echo "$X_W $Y_S" | mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $2}'`
LAT_2=`echo "$X_E $Y_N" | mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $1}'`
LON_2=`echo "$X_E $Y_N" | mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $2}'`
REGION_GEO="-R${LON_1}/${LAT_1}/${LAT_2}/${LON_2}r"

REGION_KM=-R${X_W}/${X_E}/${Y_S}/${Y_N}
REGION_M=-R${X_W_M}/${X_E_M}/${Y_S_M}/${Y_N_M}

gmt makecpt -Cmagma -Z -T-1000/0/100 > dem.cpt
gmt makecpt -Cviridis -Z -T0/40/2 > dev400.cpt
gmt makecpt -Cocean -Z -T0/25/2 > basal.cpt
gmt makecpt -T-0.001/0.005/0.0001 -Cocean -I > srfgrad.cpt 

out=$TARG/fig2.ps

function profiles () {
    cat $TARG/../cuestas/CLX_R66a.xy \
        | awk '{print $1/1000, $2/1000}' \
        | gmt psxy -JX -R -W2p,blue -t50 \
        -O -K >> ${out}.ps

    for cuesta in $TARG/../cuestas/CLX_R*.cuesta.xy
    do
    cat $cuesta \
            | awk '{print $1/1000, $2/1000}' \
            | gmt psxy -JX -R -W2p,0/191/255 \
            -O -K >> ${out}.ps
    done
}

#Surface

gmt grdgradient $srf -D -S$TARG/srfgrad.grd -G$TARG/srfslopedirection.grd


gmt grdimage $TARG/srfgrad.grd -JX$WIDTH/0 -Csrfgrad.cpt $REGION_M \
             -K > ${out}.ps


gmt grdcontour $srf -JX$WIDTH/0 -C5 -Wc0.25p,white -Wa0.5p,white -A25+f6p -T $REGION_M \
             -K -O >> ${out}.ps

rm $TARG/hi_pass_bed.xyz

for pst in `make_pst_list CLX | grep MKB | grep '/R'`
do

echo $pst
echo ">" >> $TARG/hi_pass_bed.xyz
zpeony -2xy -pps71s < $WAIS/targ/tpro/$pst/opr_foc1_bedelv/ztim_llz_bedelv.bin \
       | zvert \
       | awk '{print $4, $5, $6}' \
       | gmt grdtrack -G$TARG/bedelv.xyz_val.grd \
       | awk '{print $1, $2, $3-$4}' \
       >> $TARG/hi_pass_bed.xyz
done


gmt psscale -Csrfgrad.cpt \
                -DJTC \
                $REGION_M -JX -Bxa -By+l"grad" \
             -K -O >> ${out}.ps

        #-Bxa+l"Eastings (km)" -Bya+l"Northings (km)" \
gmt psbasemap -JX$WIDTH/0 \
             -Bxf -Byf \
             -BWSne $REGION_KM \
             -O -K >> ${out}.ps

profiles

cat $TARG/hi_pass_bed.xyz \
       | pswiggle -JX$WIDTH/0 $REGION_M -Z1000 -S275e3/40e3/250/m -G-black -G+black -O -K >> ${out}.ps

gmt pstext -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -O -K -TO -W -Gwhite << EOF >> ${out}.ps
${X_W} ${Y_N} (a) Surface gradient and elevation contours
EOF

#BEDELV
echo doing bedelv
gmt grdimage $TARG/bedelv.xyz_val.grd -JX$WIDTH/0 -I -Cdem.cpt $REGION_M \
             -X$WIDTH \
             -K -O >> ${out}.ps

gmt grdcontour $TARG/bedelv.xyz_val.grd -JX$WIDTH/0 -C200 -A600+f6p -T $REGION_M \
             -K -O >> ${out}.ps

gmt grdcontour $srf -JX$WIDTH/0 -C5 -Wc0.25p,white -Wa0.5p,white -T -A25+f6p $REGION_M \
             -K -O >> ${out}.ps

gmt psbasemap -JS0/-90/$WIDTH \
             -Bxf -Byf \
             -Lx6c/1c+c-71+w50k+f+l \
             -BESnw $REGION_GEO \
             -O -K >> ${out}.ps

gmt psbasemap -JX$WIDTH/0 \
             -Bxf -Byf \
             -BWSne $REGION_KM \
             -O -K >> ${out}.ps
profiles

cat $TARG/hi_pass_bed.xyz \
       | pswiggle -JX$WIDTH/0 $REGION_M -Z1000 -G-black -G+black -O -K >> ${out}.ps


gmt pstext -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -O -K -TO -W -Gwhite << EOF >> ${out}.ps
${X_W} ${Y_N} (b) Bed elevation grid
EOF

gmt psscale -Cdem.cpt \
                -DJTC \
                $REGION_M -JX$WIDTH/0 -Bxa -By+l"m" \
                -O >> ${out}.ps

gmt psconvert ${out}.ps  -Tf -P -A

rm -fr ${out}.ps
