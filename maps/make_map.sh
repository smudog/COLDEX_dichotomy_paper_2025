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

X_W=-50
X_E=700
Y_N=300
Y_S=-100

X_W_M=${X_W}000
X_E_M=${X_E}000
Y_N_M=${Y_N}000
Y_S_M=${Y_S}000

LON_1=`echo "$X_W $Y_S" | mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $1}'`
LAT_1=`echo "$X_W $Y_S" | mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $2}'`
LAT_2=`echo "$X_E $Y_N" | mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $1}'`
LON_2=`echo "$X_E $Y_N" | mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $2}'`
REGION_GEO="-R${LON_1}/${LAT_1}/${LAT_2}/${LON_2}r"

REGION_KM=-R${X_W}/${X_E}/${Y_S}/${Y_N}
REGION_M=-R${X_W_M}/${X_E_M}/${Y_S_M}/${Y_N_M}

gmt makecpt -Cglobe -Z -T-2000/2000/100 > dem.cpt
gmt makecpt -Cviridis -Z -T0/40/2 > dev400.cpt
gmt makecpt -Cocean -Z -T0/25/2 > basal.cpt

out=$TARG/fig1.ps

function profiles () {
    cat $TARG/../cuestas/CLX_R66a.xy \
        | awk '{print $1/1000, $2/1000}' \
        | gmt psxy -JX -R -W1p,blue \
        -O -K >> ${out}.ps

    for cuesta in $TARG/../cuestas/CLX_R*.cuesta.xy
    do
#deepskyblue
    cat $cuesta \
            | awk '{print $1/1000, $2/1000}' \
            | gmt psxy -JX -R -W1p,0/191/255 \
            -O -K >> ${out}.ps
    done
}

#Surface
gmt grdimage $srf -JX$WIDTH/0 -I -Cgray $REGION_M \
             -Y13c \
             -K > ${out}.ps

#gmt grdcontour $TARG/bedelv.xyz_val.grd -JX$WIDTH/0 -C200 -A1000+f6p $REGION_M \
#             -K -O >> ${out}.ps

gmt grdcontour $srf -JX$WIDTH/0 -C20 -Wc0.25p,white -Wa0.5,white -A500+f6p $REGION_M \
             -K -O >> ${out}.ps

egrep 'MKB2o|MKB2n' < $WAIS/targ/xtra/ALL/plotpst/output/synoptic.UTIG.xyzpstt \
    | awk '{print $1,$2}' \
    | gmt psxy -JX $REGION_KM -W0.5p,yellow \
    -O -K >> ${out}.ps

profiles

#gmt psscale -Cdem.cpt \
#                -DJTC \
#                $REGION_M -JX -Bxa -By+l"m" \
#             -K -O >> ${out}.ps

        #-Bxa+l"Eastings (km)" -Bya+l"Northings (km)" \
gmt psbasemap -JX$WIDTH/0 \
             -Bx -By \
             -BWSne $REGION_KM \
             -O -K >> ${out}.ps


gmt psbasemap -JS0/-90/$WIDTH -Bxg30 -Byg1 $REGION_GEO \
             -O -K >> ${out}.ps

gmt pstext -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -O -K -TO -W -Gwhite << EOF >> ${out}.ps
${X_W} ${Y_N} (a) Surface elevation and transects
EOF

#BEDELV
gmt grdimage $TARG/bedelv.xyz_val.grd -JX$WIDTH/0 -I -Cdem.cpt $REGION_M \
             -X$WIDTH \
             -K -O >> ${out}.ps

gmt grdcontour $TARG/bedelv.xyz_val.grd -JX$WIDTH/0 -C200 -A1000+f6p $REGION_M \
             -K -O >> ${out}.ps

#gmt grdcontour $srf -JX$WIDTH/0 -C20 -Wc0.25p,white -Wa0.5,white -A500+f6p $REGION_M \
#             -K -O >> ${out}.ps

gmt psscale -Cdem.cpt \
                -DJTC \
                $REGION_M -JX -Bxa -By+l"m" \
             -K -O >> ${out}.ps

        #-Bxa+l"Eastings (km)" -Bya+l"Northings (km)" \
gmt psbasemap -JX$WIDTH/0 \
             -Bx -By \
             -BWSne $REGION_KM \
             -O -K >> ${out}.ps
profiles

gmt psxy -JX$WIDTH/0 $REGION_M -W1p,yellow -O -K < spb_bounds.xy >> ${out}.ps

gmt pstext -JX$WIDTH/0 $REGION_KM -F+f6p,white+jBC -O -K -t25 -Gwhite << EOF >> ${out}.ps
275 30 South Pole
275 5 Basin
75 150 Penscola 
75 130 Subglacial
75 110 Basin
170 180 ReSH
600 175 Gambersevs
270 -25 'Elbow'
370 130 'Platter'
EOF

gmt pstext -JX$WIDTH/0 $REGION_KM -F+f6p,black+jBC -O -K << EOF >> ${out}.ps
275 30 South Pole
275 5 Basin
75 150 Penscola 
75 130 Subglacial
75 110 Basin
170 180 ReSH
600 175 Gambersevs
270 -25 'Elbow'
370 130 'Platter'
EOF

gmt psbasemap -JS0/-90/$WIDTH -Bxg30 -Byg1 $REGION_GEO \
             -O -K >> ${out}.ps


gmt pstext -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -O -K -TO -W -Gwhite << EOF >> ${out}.ps
${X_W} ${Y_N} (b) Bed elevation
EOF

#BEDROUGH
gmt grdimage $TARG/dev0400.xyz_val.grd -JX$WIDTH/0 -Cdev400.cpt $REGION_M \
             -X-$WIDTH \
             -Y-5c \
             -K -O >> ${out}.ps

gmt grdcontour $TARG/bedelv.xyz_val.grd -JX$WIDTH/0 -C200 -A1000+f6p $REGION_M \
             -K -O >> ${out}.ps

#gmt grdcontour $srf -JX$WIDTH/0 -C20 -Wc0.25p,white -Wa0.5,white -A500+f6p $REGION_M \
#             -K -O >> ${out}.ps

gmt psbasemap -JX$WIDTH/0 -Bwsne $REGION_KM \
             -O -K >> ${out}.ps

profiles

gmt psbasemap -JS0/-90/$WIDTH -Bxg30 -Byg1 $REGION_GEO --MAP_POLAR_CAP=88/88 \
             -O -K >> ${out}.ps

gmt psscale -Cdev400.cpt \
            -DJBC \
            $REGION_M -JX -Bxa -By+l"m" \
             -K -O >> ${out}.ps

gmt pstext -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -O -K -TO -W -Gwhite << EOF >> ${out}.ps
${X_W} ${Y_N} (c) Roughness at 400 m length scale
EOF

frac_basal=1

if [ $frac_basal -eq 1 ]
then

#FRACTIONAL ICE
gmt grdinfo $TARG/fract_basal_ice.grd

gmt grdmath $TARG/fract_basal_ice.grd $TARG/icethk.xyz_val.grd MUL $TARG/bedelv.xyz_val.grd ADD = $TARG/basal_elv.grd 

gmt grdmath $TARG/fract_basal_ice.grd $TARG/icethk.xyz_val.grd MUL $TARG/bedelv.xyz_val.grd ADD = $TARG/basal_elv.grd 

gmt grdmath $TARG/fract_basal_ice.grd 100 MUL = $TARG/fract_basal_ice.percent.grd

gmt grdmath $WAIS/targ/supl/modl-beijing_normal_university/wolovick-2021a/EchoFreeZone.grd 100 MUL = $TARG/wolovick21.grd

gmt grdmath $WAIS/targ/supl/modl-beijing_normal_university/wolovick-2021a/EchoFreeZone.grd $thk MUL $bed ADD = $TARG/wolovick_basal_elv.grd



#gmt grdimage $TARG/wolovick21.grd -JX$WIDTH/0 -Cbasal.cpt $REGION_M \
#             -X$WIDTH \
#             -K -O >> ${out}.ps
gmt grdimage $TARG/fract_basal_ice.percent.grd -JX$WIDTH/0 -Q -Cbasal.cpt $REGION_M \
             -X$WIDTH \
             -K -O >> ${out}.ps

gmt grdcontour $WAIS/targ/supl/modl-beijing_normal_university/wolovick-2021a/FreezeOnThick.grd -JX$WIDTH/0 $REGION_M -C10 -Wc0.5p,black -O -K >> ${out}.ps
             
gmt psscale -Cbasal.cpt -DJBC $REGION_M -JX -Bxa -By+l"m" \
             -K -O >> ${out}.ps


else

gmt grdimage $TARG/wolovick_basal_elv.grd -I -JX$WIDTH/0 -Cdem.cpt $REGION_M \
             -X$WIDTH \
             -K -O >> ${out}.ps

gmt grdimage $TARG/basal_elv.grd -I -JX$WIDTH/0 -Q -Cdem.cpt $REGION_M \
             -K -O >> ${out}.ps

gmt psscale -Cdem.cpt -DJBC $REGION_M -JX -Bxa -By+l"m" \
             -K -O >> ${out}.ps

fi
#gmt grdcontour $srf -JX$WIDTH/0 -C20 -Wc0.25p,white -Wa0.5,white -A500+f6p $REGION_M \
#             -K -O >> ${out}.ps

            #-Bxa+l"Eastings (km)" -Bya+l"Northings (km)" \
gmt psbasemap -JX$WIDTH/0 \
             -Bx -By \
            -BWSne $REGION_KM \
             -O -K >> ${out}.ps

profiles

gmt psbasemap -JS0/-90/$WIDTH -Bxg30 -Byg1 $REGION_GEO \
             -O -K >> ${out}.ps

gmt pstext -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -TO -W -O -Gwhite << EOF >> ${out}.ps
${X_W} ${Y_N} (d) Fractional thickness of basal unit
EOF

gmt psconvert ${out}.ps -A -Tf -P

rm -fr ${out}.ps
