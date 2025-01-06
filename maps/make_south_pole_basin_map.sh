#!/bin/bash 

srf=$WAIS/targ/supl/grid-icesat2/Smith2020/ais_grounded.grd
srf=$WAIS/targ/supl/grid-ntpdc_cn/Shen22/Antarctic_DEM_from_ICESat-2.grd
srf=$WAIS/targ/supl/grid-pgc/rema/1km/REMA_1km_dem_filled.grd

thk=$WAIS/targ/supl/modl-beijing_normal_university/wolovick-2021a/Icethick.grd
bed=$WAIS/targ/supl/modl-beijing_normal_university/wolovick-2021a/BedElev.grd

data=$WAIS/targ/comm/DATA-OPR/projected_images_COLDEX
bnd=$WAIS/targ/supl/xtra-coldex/mek_transition_zone/clipped_bnd.gmt

TARG=`pwd | sed s@code@targ@`
mkdir -p $TARG
srf=$TARG/../srfelv/srfelv.xyz_val.grd

WIDTH=8c

X_W=175
X_E=375
Y_N=175
Y_S=-25

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

gmt makecpt -Cglobe -Z -T-1000/1000/100 -M --COLOR_NAN=gray > dem.cpt
gmt makecpt -Cviridis -Z -T0/40/2 > dev400.cpt
gmt makecpt -Cocean -Z -T0/25/2 > basal.cpt
gmt makecpt -T-0.001/0.005/0.0001 -Cocean -I > srfgrad.cpt 

out=$TARG/coldex_south_pole_basin_maps

function profiles () {
    cat $TARG/../cuestas/CLX_R66a.xy \
        | awk '{print $1/1000, $2/1000}' \
        | gmt psxy -W2p,blue -t50

    for cuesta in $TARG/../cuestas/CLX_R*.cuesta.xy
    do
    cat $cuesta \
            | awk '{print $1/1000, $2/1000}' \
            | gmt psxy -W2p,white
    done
}

#Surface
gmt grdgradient $srf -D -S$TARG/srfgrad.grd -G$TARG/srfslopedirection.grd

rm $TARG/hi_pass_bed.xyz
for pst in `make_pst_list CLX | grep MKB | grep '/R'`
do

echo ">" >> $TARG/hi_pass_bed.xyz
zpeony -2xy -pps71s < $WAIS/targ/tpro/$pst/opr_foc1_bedelv/ztim_llz_bedelv.bin \
       | zvert \
       | awk '{print $4, $5, $6}' \
       | gmt grdtrack -G$TARG/bedelv.xyz_val.grd \
       | awk '{print $1, $2, $3-$4}' \
       >> $TARG/hi_pass_bed.xyz
done

gmt begin $out png 
    gmt subplot begin 1x2 -Fs$WIDTH $REGION_M -JX$WIDTH/0 -M0c
        gmt subplot set
            gmt grdimage $TARG/srfgrad.grd -Bbtlr -Csrfgrad.cpt
            gmt grdcontour $srf -C5 -Wc0.25p,white -Wa0.5p,white -A25+f6p -T 

            gmt plot $bnd -W3p,black -t50

            gmt colorbar -Csrfgrad.cpt \
                        -DJTC+o0/0.5c \
                        -Bxa -By+l"grad"

            gmt basemap -Bxfa -Byfa -BwSne $REGION_KM

            profiles

            cat $TARG/hi_pass_bed.xyz \
               | gmt wiggle $REGION_M -Z1000 -DjBR+o0.25c/0.25c+w250+lm -Gyellow+p -F+gwhite --FONT_ANNOT_PRIMARY=8p 

            gmt text $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -W -Gwhite <<- EOF
${X_W} ${Y_N} (a) Surface gradient and elevation contours
EOF

        #BEDELV
        echo doing bedelv
        gmt subplot set
        gmt grdimage $TARG/bedelv.xyz_val.grd -Bbtlr -I -Cdem.cpt $REGION_M
        gmt grdcontour $TARG/bedelv.xyz_val.grd -C200 -Wa0.5p -Wc0.1p -A600+f6p -T 
        gmt grdcontour $srf -C5 -Wc0.25p,white -Wa0.5p,white -T -A25+f6p 
        gmt plot $bnd -W3p,black -t50

        gmt basemap -JX$WIDTH/0 \
                     -Bxfa -Byfa \
                     -BWeSn $REGION_KM
        profiles

        cat $TARG/hi_pass_bed.xyz \
               | gmt wiggle $REGION_M -Z1000 -Gyellow+p 

        gmt text -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -W -Gwhite <<- EOF 
${X_W} ${Y_N} (b) Bed elevation grid
EOF
    gmt colorbar -Cdem.cpt \
                        -DJTC+o0/0.5c \
                        -Bxa -By+l"m" \

       gmt subplot end


gmt legend -DJBC+w17c+o0/1c -F+glightgray --FONT_ANNOT_PRIMARY=6p <<- EOF
H 6p,Helvetica-Bold LEGEND (Map coordinates in EPGS:3031 km)
N 4
S - - 0.5c - 2p,blue - CLX/MKB2o/R66a (Fig. 1) 
S - - 0.5c - 2p,white - Cuesta profiles (Fig. 3) 
S - t 0.25c yellow - - High pass postive bed topography 
S - - 0.5c - 3p,dimgray - Mapped dichotomy
EOF

    gmt end

