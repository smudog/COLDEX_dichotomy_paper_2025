#!/bin/bash 

srf=$WAIS/orig/supl/grid-pgc/rema/1km/rema_mosaic_1km_v2.0_filled_cop30_dem.tif

bnd=$WAIS/targ/supl/xtra-coldex/mek_transition_zone/clipped_bnd.gmt
data=$WAIS/targ/comm/DATA-OPR/projected_images_COLDEX

TARG=`pwd | sed s@code@targ@`
mkdir -p $TARG

trap 'echo ERROR $0 at $LINENO; exit' ERR

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


gmt makecpt -Cglobe -Z -T-2000/2000/100 -M --COLOR_NAN=gray > dem.cpt
gmt makecpt -Cviridis -Z -T0/20/2 > dev400.cpt
gmt makecpt -Cocean -Z -T0/25/2 > basal.cpt

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
}

#Surface
gmt begin $out png
    gmt subplot begin 2x2 -Fs$WIDTH $REGION_M -M-0.5c -JX$WIDTH/0


        gmt subplot set
        gmt grdimage -Blrbt+ggray $srf -I -Cgray 
        gmt grdcontour $srf -C20 -Wc0.25p,white -Wa0.5,white -A500+f6p $REGION_M

        egrep 'MKB2o|MKB2n' < $WAIS/targ/xtra/ALL/plotpst/output/synoptic.UTIG.xyzpstt \
            | awk '{print $1,$2}' \
            | gmt plot -W0.5p,yellow $REGION_KM  

        profiles

        gmt basemap -Bxa -Bya -BWNse $REGION_KM
        gmt basemap -JS0/-90/$WIDTH -Bxg30 -Byg1 $REGION_GEO -t50

            
        gmt text -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -W -Gwhite << EOF
${X_W} ${Y_N} (a) Surface elevation and transects
EOF

        gmt legend -DJTC+w$WIDTH+o0/1c -F+glightgray --FONT_ANNOT_PRIMARY=6p <<- EOF
H 6p,Helvetica-Bold LEGEND
N 2
S - - 0.5c - 1p,blue - CLX/MKB2o/R66a (Fig. 1) 
S - - 0.5c - 1p,white - Cuesta profiles (Fig. 3) 
S - - 0.5c - 0.5p,yellow - COLDEX transects (Fig. 2) 
S - - 0.5c - 1p,black - Mapped dichotomy
EOF


    #BEDELV
    gmt subplot set
        gmt grdimage -Blrbt $TARG/bedelv.xyz_val.grd -I -Cdem.cpt --COLOR_NAN=gray $REGION_M
        gmt grdcontour $TARG/bedelv.xyz_val.grd -C200 -Wc0.1p -Wa0.25p -A1000+f6p $REGION_M 
        gmt colorbar -Cdem.cpt \
                        -DJTC \
                        -JX -Bxa -By+l"m" \

        gmt plot $bnd -W1p,black 


        gmt basemap -Bx -By -BwsNe $REGION_KM

        profiles

        gmt plot $REGION_M -W1p,yellow < spb_bounds.xy

        tail -n 1 spb_bounds.xy \
            | awk '{print $1, $2, "Fig. 4"}' \
            | pstext -F+jTL+f6p,Helvetica-Bold,yellow -D0.1c/-0.1c
        

        gmt text $REGION_KM -F+f6p,white+jBC -t25 -Gwhite << EOF
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

        gmt text $REGION_KM -F+f6p,black+jBC << EOF
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

        gmt basemap -JS0/-90/$WIDTH -Bxg30 -Byg1 $REGION_GEO -t50

        gmt text -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c  -W -Gwhite << EOF
    ${X_W} ${Y_N} (b) Bed elevation
EOF

    #BEDROUGH
    gmt subplot set

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
    gmt subplot set

        gmt grdinfo $TARG/fract_basal_ice.grd
        gmt grdmath $TARG/fract_basal_ice.grd 100 MUL = $TARG/fract_basal_ice.percent.grd

        gmt grdimage $TARG/fract_basal_ice.percent.grd -Bbrlt+ggray -JX$WIDTH/0 -Cbasal.cpt $REGION_M -Q
        gmt colorbar -Cbasal.cpt -DJBC+o0/0.5c -Bxa -By+l"%"
        gmt plot $bnd -W1p,black 

        gmt basemap -JX$WIDTH/0 -Bx -By -Bwsne $REGION_KM 

        profiles

        gmt basemap -JS0/-90/$WIDTH -Bxg30 -Byg1 $REGION_GEO -t50

        gmt text -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -W -Gwhite << EOF
        ${X_W} ${Y_N} (d) Fractional thickness of basal unit
EOF
    gmt subplot end
gmt end
