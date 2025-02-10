#!/bin/bash 

srf=$WAIS/orig/supl/grid-pgc/rema/1km/rema_mosaic_1km_v2.0_filled_cop30_dem.tif
vel=$WAIS/targ/supl/grid-nsidc/Mouginot2019

sanderson=$WAIS/orig/supl/xtra-antarchitecture/Sanderson_2023/EA_H3_162ka.csv
bnd=$WAIS/targ/supl/xtra-coldex/mek_transition_zone/clipped_bnd.gmt
data=$WAIS/targ/comm/DATA-OPR/projected_images_COLDEX

TARG=`pwd | sed s@code@targ@`
mkdir -p $TARG

trap 'echo ERROR $0 at $LINENO; exit' ERR

WIDTH=8c

DOUBLE_WIDTH=`echo $WIDTH | tr -d c | awk '{print 2*$1}'` 

X_W=-50
X_E=700
Y_S=-150
Y_N=300

X_W_M=${X_W}000
X_E_M=${X_E}000
Y_S_M=${Y_S}000
Y_N_M=${Y_N}000

LON_1=`echo "$X_W $Y_S" | mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $1}'`
LAT_1=`echo "$X_W $Y_S" | mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $2}'`
LAT_2=`echo "$X_E $Y_N" | mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $1}'`
LON_2=`echo "$X_E $Y_N" | mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $2}'`
REGION_GEO="-R${LON_1}/${LAT_1}/${LAT_2}/${LON_2}r"
REGION_KM=-R${X_W}/${X_E}/${Y_S}/${Y_N}
REGION_M=-R${X_W_M}/${X_E_M}/${Y_S_M}/${Y_N_M}

srf_for_slope=$TARG/../srfelv/srfelv.xyz_val.grd
gmt grdgradient $srf_for_slope -D -S$TARG/srfgrad.grd -G$TARG/srfslopedirection.grd

gmt gmtset FONT_ANNOT_PRIMARY 8p

gmt makecpt -Cglobe -Z -T-2000/2000/100 -M --COLOR_NAN=gray > dem.cpt
gmt makecpt -Cmagma -Z -I -T0/20/2 -D > dev400.cpt
gmt makecpt -Cocean -Z -T0/40/2 > basal.cpt
gmt makecpt -T-0.001/0.005/0.0001 -Cocean -I > srfgrad.cpt 

grep -v '#' < $sanderson | tr ',' '\t' | awk 'NR>1{print $2, $3, 100 - ($8*100)}' \
         > $TARG/162.xyz

gmt blockmean $REGION_M -I1000 < $TARG/162.xyz \
        | gmt surface $REGION_M -I500 -T.35 -G$TARG/162.grd

gmt grdmask $REGION_M -I500 $TARG/162.xyz -S5000 -NNaN/NaN/1 -G$TARG/162.mask.grd

gmt grdmath $TARG/162.grd $TARG/162.mask.grd MUL = $TARG/162.xyz_val.grd

out=$TARG/coldex_overview_maps

function profiles () {
    cat $TARG/../cuestas/CLX_R66a.xy \
        | awk '{print $1/1000, $2/1000}' \
        | gmt plot -W1p,blue

    for cuesta in $TARG/../cuestas/CLX_R*.cuesta.xy
    do

    cat $cuesta \
            | awk '{print $1/1000, $2/1000}' \
            | gmt plot -W1p,white 
    done

    echo 140 -100 \
        | gmt plot -Sc0.5c -W1p,yellow,dashed 
}

#Surface
gmt begin $out png
    gmt subplot begin 2x2 -Fs$WIDTH $REGION_M -M-0.15c -JX$WIDTH/0
        gmt subplot set 0,1

        gmt grdimage -Blrbt+ggray $TARG/srfgrad.grd -Csrfgrad.cpt 
#        gmt grdcontour $srf -C20 -Wc0.25p,white -Wa0.5,white -A500+f6p $REGION_M
        gmt colorbar -Csrfgrad.cpt \
                        -DJTC \
                        -JX -Bxa -By+l"grad" \

        #egrep 'MKB2o|MKB2n' < $WAIS/targ/xtra/ALL/plotpst/output/synoptic.UTIG.xyzpstt \
        #    | awk '{print $1,$2}' \
        #    | gmt plot -W0.5p,yellow $REGION_KM -t67

        gmt plot $bnd $REGION_M -W1p,black 

        gmt grdvector $vel/vx.grd $vel/vy.grd -S1p -Q+b+n1 -Gwhite -Ix50  -W0.5p,white

        gmt basemap -Bxa -Bya -BwNse $REGION_KM
        profiles

        gmt plot $REGION_M -W1p,yellow < spb_bounds.xy

        tail -n 1 spb_bounds.xy \
            | awk '{print $1, $2, "Fig. 4"}' \
            | pstext -F+jTL+f6p,Helvetica-Bold,yellow -D0.1c/-0.1c

        gmt basemap -JS0/-90/$WIDTH -Bxg30 -Byg1 $REGION_GEO -t50
            
        gmt text -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -W -Gwhite << EOF
${X_W} ${Y_N} (b) Surface slope and ice velocity
EOF



    #BEDELV
    gmt subplot set 0,0
        gmt grdimage -Blrbt $TARG/bedelv.xyz_val.grd -I -Cdem.cpt --COLOR_NAN=gray $REGION_M
        gmt grdcontour $TARG/bedelv.xyz_val.grd -C200 -Wc0.1p -Wa0.25p -A1000+f6p $REGION_M 
        gmt colorbar -Cdem.cpt \
                        -DJTC \
                        -JX -Bxa -By+l"m" \

        gmt plot $bnd -W1p,black 

        gmt basemap -Bxa -Bya -BWsNe $REGION_KM

        profiles

        gmt text $REGION_KM -F+f6p,white+jBC -t25 -Gwhite << EOF
        275 30 South Pole
        275 5 Basin
        75 150 Penscola 
        75 125 Subglacial
        75 105 Basin
        170 180 ReSH
        600 175 Gambersevs
        270 -25 'Elbow'
        370 130 'Platter'
        30 10 Breaches
        255 -100 Jordan 2018 anomaly
EOF

        gmt text $REGION_KM -F+f6p,black+jBC << EOF
        275 30 South Pole
        275 5 Basin
        75 150 Penscola 
        75 125 Subglacial
        75 105 Basin
        170 180 ReSH
        600 175 Gambersevs
        270 -25 'Elbow'
        370 130 'Platter'
        30 10 Breaches
        255 -100 Jordan 2018 anomaly
EOF

        gmt basemap -JS0/-90/$WIDTH -Bxg30 -Byg1 $REGION_GEO -t50

        gmt text -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c  -W -Gwhite << EOF
    ${X_W} ${Y_N} (a) Bed elevation
EOF

    #BEDROUGH
    gmt subplot set 1,0

        gmt grdimage -Bblrt+ggray $TARG/dev0400.xyz_val.grd -Cdev400.cpt $REGION_M -Q

        gmt grdcontour $TARG/bedelv.xyz_val.grd -C200 -A1000+f6p -Wc0.1p -Wa0.25p $REGION_M

        gmt plot $bnd -W1p,black 

        gmt psbasemap -BWsne -Bxa -Bya $REGION_KM 
        
        profiles

        gmt psbasemap -JS0/-90/$WIDTH -Bxg30 -Byg1 $REGION_GEO --MAP_POLAR_CAP=88/88 -t50 

        gmt colorbar -Cdev400.cpt \
                    -DJBC+o0/0.5c \
                    $REGION_M -JX -Bxa -By+l"m" 

        gmt text -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -W -Gwhite << EOF
        ${X_W} ${Y_N} (c) Roughness at 400 m length scale
EOF

    #FRACTIONAL ICE
    gmt subplot set 1,1

        gmt grdinfo $TARG/fract_basal_ice.grd
        gmt grdmath $TARG/fract_basal_ice.grd 100 MUL = $TARG/fract_basal_ice.percent.grd

        gmt grdimage $TARG/fract_basal_ice.percent.grd -Bbrlt+ggray -JX$WIDTH/0 -Cbasal.cpt $REGION_M -Q
        gmt colorbar -Cbasal.cpt -DJBC+o0/0.5c -Bxa -By+l"%"
        gmt plot $bnd -W1p,black 
        
        grep -v '#' < $sanderson | tr ',' '\t' | awk 'NR>1{print $2, $3, 100 - ($8*100)}' \
            | gmt plot -Sc0.15c -Gblack 

        gmt grdimage $TARG/162.xyz_val.grd -Cbasal.cpt -Q

        gmt basemap -JX$WIDTH/0 -Bxa -Bya -Bwsne $REGION_KM 

        profiles

        gmt basemap -JS0/-90/$WIDTH -Bxg30 -Byg1 $REGION_GEO -t50

        gmt text -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -W -Gwhite << EOF
        ${X_W} ${Y_N} (d) Fractional thickness: basal unit (background), ice >162 ka
EOF
    gmt subplot end

    gmt legend -DJTC+w${DOUBLE_WIDTH}c+o0/2.5c -F+glightgray --FONT_ANNOT_PRIMARY=6p <<- EOF
H 6p,Helvetica-Bold LEGEND
N 4
S - - 0.5c - 1p,blue - CLX/MKB2o/R66a (Fig. 1) 
S - - 0.5c - 1p,white - Cuesta profiles (Fig. 3) 
S - v 15p white 0.25p,white - Ice flow vector (15 m/yr shown)
S - - 0.5c - 1p,black - Mapped dichotomy (basal ice)
EOF

gmt end
