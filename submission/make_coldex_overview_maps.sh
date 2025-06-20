#!/bin/bash 

# Setting up error trapping
trap 'echo ERROR $0 at $LINENO; exit' ERR

# Setting up directories - assumes script is in a folder called 'code' and that downloaded datasets are in a folder called 'orig'
TARG=`pwd | sed s@code@targ@`
mkdir -p $TARG

ORIG=`pwd | sed s@code@orig@`
if [ ! -d $ORIG ]
then
    echo original data in $ORIG is missing
    exit
fi

#Getting pointers to original data
#srf=$TARG/srfelv.xyz_val.grd
srf=$ORIG/rema/rema_mosaic_1km_v2.0_filled_cop30_dem.tif
vel=$TARG/Mouginot2019
sanderson=$ORIG/Sanderson_2023/EA_H3_162ka.csv
bnd=$ORIG/clipped_bnd.gmt
data=$ORIG/projected_images_COLDEX
bed=$TARG/bedelv.xyz_val.tif
spec=$TARG/specularity_content.xyz_val.tif
basal=$TARG/fract_basal_ice_percent.tif
rmsd=$TARG/roughness.xyz_val.tif
hipass=$TARG/hipass_bed.xyz

#Setting up figure geometry for Supplementary Figure 2
WIDTH=8c
DOUBLE_WIDTH=`echo $WIDTH | tr -d c | awk '{print 2*$1}'` 

X_W=175
X_E=375
Y_N=175
Y_S=-25

X_W_M=${X_W}000
X_E_M=${X_E}000
Y_S_M=${Y_S}000
Y_N_M=${Y_N}000

echo '>' > S2_bounds.xy
echo $X_W_M $Y_N_M >> S2_bounds.xy
echo $X_W_M $Y_S_M >> S2_bounds.xy
echo $X_E_M $Y_S_M >> S2_bounds.xy
echo $X_E_M $Y_N_M >> S2_bounds.xy
echo $X_W_M $Y_N_M >> S2_bounds.xy

LON_1=`echo "$X_W $Y_S" | gmt mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $1}'`
LAT_1=`echo "$X_W $Y_S" | gmt mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $2}'`
LAT_2=`echo "$X_E $Y_N" | gmt mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $1}'`
LON_2=`echo "$X_E $Y_N" | gmt mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $2}'`

REGION_GEO="-R${LON_1}/${LAT_1}/${LAT_2}/${LON_2}r"
REGION_KM=-R${X_W}/${X_E}/${Y_S}/${Y_N}
REGION_M=-R${X_W_M}/${X_E_M}/${Y_S_M}/${Y_N_M}

#reused function for plotting key transects
gmt gmtset FONT_ANNOT_PRIMARY 8p
function profiles () {
    cat $data/metadata/CLX_R66a_image.csv \
        | tr ',' '\t' \
        | awk 'NR>1' \
        | awk 'NR%20==0{print $10/1000, $11/1000}' \
        | gmt plot -W1p,blue

    cat $data/metadata/CLX_R75a_image.csv \
        | tr ',' '\t' \
        | awk 'NR>1' \
        | awk 'NR%20==0{print $10/1000, $11/1000, $12/1000}' \
        | awk '$3>650' | awk '$3<950' \
        | gmt plot -W1p,orange

    for cuesta in $TARG/CLX_R*.cuestas.xy
    do

    cat $cuesta \
            | awk '{print $1/1000, $2/1000}' \
            | gmt plot -W1p,white 
    done

    echo 140 -100 \
        | gmt plot -Sc0.5c -W1p,yellow,dashed 
}

#Generated new datasets from original data
echo Generated surface slope
gmt grdgradient $srf -D -S$TARG/srfgrad.grd -G$TARG/srfslopedirection.grd


echo Plotting Supplementary Figure 2
gmt begin $TARG/coldex_south_pole_basin_maps png 
    gmt subplot begin 2x2 -Fs$WIDTH $REGION_M -JX$WIDTH/0 -M0c/0.5c  #-Cn1p
    echo Plotting surface slope
        gmt subplot set
            gmt makecpt -T-0.001/0.005/0.0001 -Cocean -I
            gmt grdimage $TARG/srfgrad.grd -Bbtlr -C
            gmt grdcontour $srf -C5 -Wc0.25p,white -Wa0.5p,white -A25+f6p -T 
            gmt plot $bnd -W3p,black -t50  
            gmt colorbar -C \
                        -DJTC+o0/0.25c \
                        -Bxa -By+l"gradient"
                        #-DJTC+o0.75c/0 \

            gmt basemap -Bxfa -Byfa+l"Northings (km)" -BWSne $REGION_KM

            profiles

            cat $hipass \
               | gmt wiggle $REGION_M -Z1000c -DjBL+o0.25c/0.25c+w250+l"m (high pass bed scale)" -gd1000 -Gyellow+p -F+gwhite --FONT_ANNOT_PRIMARY=8p 

            gmt text $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -W -Gwhite <<- EOF
            ${X_W} ${Y_N} (a) Surface gradient and elevation contours
EOF

        echo doing bedelv
        gmt subplot set
            gmt makecpt -Cglobe -Z -T-1000/1000/100 -M --COLOR_NAN=gray
            gmt grdimage $bed -Bbtlr -I -C $REGION_M
            gmt grdcontour $bed -C200 -Wa0.5p -Wc0.1p -A600+f6p -T 
            gmt grdcontour $srf -C5 -Wc0.25p,white -Wa0.5p,white -T -A25+f6p 
            gmt plot $bnd -W3p,black -t50  

            gmt basemap -JX$WIDTH/0 \
                         -Bxfa -Byfa \
                         -BweSn $REGION_KM
            profiles

            cat $hipass \
               | gmt wiggle $REGION_M -Z1000 -Gyellow+p -gd1000 

            gmt text -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -W -Gwhite <<- EOF 
            ${X_W} ${Y_N} (b) Bed elevation grid
EOF
            gmt colorbar -C \
                        -DJTC+o0/0.25c \
                        -Bxa -By+l"m" \

        echo doing basal ice
        gmt subplot set
            gmt makecpt -Cocean -Z -T0/25/2 -M --COLOR_NAN=gray
            gmt grdimage $basal -Bbtlr -C
            gmt grdcontour $srf -C5 -Wc0.25p,white -Wa0.5p,white -A25+f6p -T 
            gmt plot $bnd -W3p,black -t50  
            gmt colorbar -C \
                        -DJBC+o0/0.25c \
                        -Bxa -By+l"%"

            gmt basemap -Bxfa+l"Eastings (km)" -Byfa+l"Northings (km)" -BWNse $REGION_KM
            gmt text $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -W -Gwhite <<- EOF  
            ${X_W} ${Y_N} (c) Basal Ice Unit Fractional Thickness 
EOF

        echo doing roughness @ 400 m
        gmt subplot set
            gmt makecpt -Cmagma -T0/40/1 -Di -Z 
            gmt grdimage $rmsd -Bbtlr -C
            gmt grdcontour $srf -C5 -Wc0.5p,white -Wa0.5p,white -A25+f6p -T 
            gmt plot $bnd -W3p,black -t50  
            gmt colorbar -C \
                        -DJBC+o0/0.25c \
                        -Bxa -By+l"m"

            gmt basemap -Bxfa+l"Eastings (km)" -Byfa -BwsNe $REGION_KM
            gmt text $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -W -Gwhite <<- EOF
${X_W} ${Y_N} (d) RMS roughness at 400 m 
EOF
       gmt subplot end


    gmt legend -DJBC+w18c+o0/1c -F+glightgray --FONT_ANNOT_PRIMARY=6p <<- EOF
H 6p,Helvetica-Bold LEGEND (Map coordinates in EPGS:3031 km)
N 5
S - - 0.5c - 2p,blue - CLX/R66a (Fig. 1) 
S - - 0.5c - 2p,white - Cuesta profiles (Fig. 3) 
S - - 0.5c - 2p,orange - CLX/R75a (Fig. 4) 
S - t 0.25c yellow - - High pass bed topography 
S - - 0.5c - 3p,dimgray - Mapped dichotomy
EOF

gmt end

#Setting up primary figure geometry
echo Begining primary figure
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

LON_1=`echo "$X_W $Y_S" | gmt mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $1}'`
LAT_1=`echo "$X_W $Y_S" | gmt mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $2}'`
LAT_2=`echo "$X_E $Y_N" | gmt mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $1}'`
LON_2=`echo "$X_E $Y_N" | gmt mapproject -Fk -C -I -Js0/-90/-71/1:5000000 -R0/360/-90/-45 | awk '{print $2}'`

REGION_GEO="-R${LON_1}/${LAT_1}/${LAT_2}/${LON_2}r"
REGION_KM=-R${X_W}/${X_E}/${Y_S}/${Y_N}
REGION_M=-R${X_W_M}/${X_E_M}/${Y_S_M}/${Y_N_M}


#Plotting

gmt begin $TARG/coldex_overview_maps png
    #gmt subplot begin 2x2 -Fs$WIDTH $REGION_M -M-0.15c -JX$WIDTH/0
    gmt subplot begin 2x2 -Fs$WIDTH $REGION_M -M-0.15c -JX$WIDTH/0
#BEDELV
        gmt subplot set 0,0
            echo plotting bed
            gmt makecpt -Cglobe -Z -T-2000/2000/100 -M --COLOR_NAN=gray
            gmt grdimage -Blrbt $bed -I -C  $REGION_M
            gmt grdcontour $bed -C200 -Wc0.1p,white -Wa0.25p,white -A1000+f6p,white $REGION_M 
            gmt colorbar -C  -DJTC -JX -Bxa -By+l"m" 

            gmt plot $bnd -W1p,black   

            gmt basemap -Bxa -Bya -BWsNe $REGION_KM

            profiles
            
            cat <<-EOF > big_places.txt
            275 30 SOUTH POLE
            275 10 BASIN
            75 145 PENSACOLA 
            75 125 SUBGLACIAL
            75 105 BASIN
            170 210 RECOVERY
            170 190 SUBGLACIAL
            170 170 HIGHLANDS
            600 175 GAMBURTSEV
            600 155 SUBGLACIAL
            600 135 MOUNTAINS
EOF

    gmt text $REGION_KM -F+f6p,Palatino-Bold,white+jBC -C25%+tO -t25 -Gwhite < big_places.txt
    gmt text $REGION_KM -F+f6p,Palatino-Bold,black+jBC < big_places.txt

            cat <<-EOF > small_places.txt 
            234 -15 TL The 'Elbow' 
            354 123  TL The 'Platter' 
            87 0 BC The 'Breaches'
            140 -100 ML Jordan et al. (2018) anomaly
            0 0 TL South Pole
EOF

echo plotting smalls 
    gmt text $REGION_KM -F+f6p,Palatino-Bold,black+j  -Dj0.3c -C25%+tO -t25 -Gwhite < small_places.txt
    gmt text $REGION_KM -F+f6p,Palatino-Bold,black+j -Dj0.3c+v1p < small_places.txt

echo 0 0 | gmt psxy -St0.25c -Gblack 

            gmt text -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c  -W -Gwhite <<- EOF
            ${X_W} ${Y_N} (a) Bed elevation
EOF

#Surface slope
        gmt subplot set 0,1
            echo plotting surface

            gmt makecpt -T-0.001/0.005/0.0001 -Cocean -I
            gmt grdimage -Blrbt+ggray $TARG/srfgrad.grd -C 
            gmt colorbar -C \
                            -DJTC \
                            -JX -Bxa -By+l"gradient" \

            gmt plot $bnd $REGION_M -W1p,black   
            gmt grdvector $vel/VX.tif $vel/VY.tif -S1p -Q0.1c+e+h0+a40 -Gwhite -Ix50  -W0.5p,white
            gmt basemap -Bxa -Bya -BwNse $REGION_KM

            profiles

            gmt plot $REGION_M -W1p,yellow < S2_bounds.xy
            tail -n 1 S2_bounds.xy \
                | awk '{print $1, $2, "Fig. S1"}' \
                | gmt text -F+jTL+f6p,Helvetica-Bold,yellow -D0.1c/-0.1c

            #gmt basemap -JS0/-90/$WIDTH -Bxg30 -Byg1 $REGION_GEO -t50
            gmt text -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -W -Gwhite <<- EOF
            ${X_W} ${Y_N} (b) Surface slope and ice velocity
EOF

#Specularity content
        gmt subplot set 1,0
            echo plotting specularity
            gmt makecpt -Cseafloor -T0/0.5/0.01 -Z -Di 
            gmt grdimage -Bblrt+ggray $spec -C $REGION_M -Q
            gmt grdcontour $bed -C200 -A1000+f6p,white -Wc0.1p,white -Wa0.25p,white $REGION_M
            gmt plot $bnd -W1p,black   
            gmt psbasemap -BWsne -Bxa -Bya $REGION_KM 
            
            profiles
            #gmt psbasemap -JS0/-90/$WIDTH -Bxg30 -Byg1 $REGION_GEO --MAP_POLAR_CAP=88/88 -t50 
            gmt colorbar -C \
                        -DJBC+o0/0.5c \
                        $REGION_M -JX -Bxa -By+l"fraction" 

            gmt text -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -W -Gwhite <<- EOF
            ${X_W} ${Y_N} (c) Basal specularity content
EOF

#Englacial structure
echo Generated englacial layers
grep -v '#' < $sanderson | tr ',' '\t' | awk 'NR>1{print $2, $3, 100 - ($8*100)}' \
         > $TARG/162.xyz

gmt blockmean $REGION_M -I1000 < $TARG/162.xyz \
        | gmt surface $REGION_M -I500 -T.35 -G$TARG/162.grd

if [ ! -s $TARG/162.mask.grd ]
then
echo masking
gmt grdmask $REGION_M -I500 $TARG/162.xyz -S5000 -NNaN/NaN/1 -G$TARG/162.mask.grd
echo done masking
gmt grdmath $TARG/162.grd $TARG/162.mask.grd MUL = $TARG/162.xyz_val.grd
fi

        gmt subplot set 1,1
            echo plotting basal ice and horizons


            gmt makecpt -Cocean -Z -T0/40/2
            gmt grdimage $basal -Bbrlt+ggray -JX$WIDTH/0 -C $REGION_M -Q
            gmt colorbar -C -DJBC+o0/0.5c -Bxa -By+l"%"
            gmt plot $bnd -W1p,black  
            
            grep -v '#' < $sanderson | tr ',' '\t' | awk 'NR>1{print $2, $3, 100 - ($8*100)}' \
                | gmt plot -Sc0.15c -Gblack 

            gmt grdimage $TARG/162.xyz_val.grd -C -Q

            gmt basemap -JX$WIDTH/0 -Bxa -Bya -Bwsne $REGION_KM 

            profiles

            #gmt basemap -JS0/-90/$WIDTH -Bxg30 -Byg1 $REGION_GEO -t50

            gmt text -JX$WIDTH/0 $REGION_KM -F+f8p+jLT -D0.2c/-0.2c -W -Gwhite <<- EOF
            ${X_W} ${Y_N} (d) Fractional thickness: basal unit (background), ice >162 ka
EOF

    gmt subplot end

#Legend
    gmt legend -DJTC+w${DOUBLE_WIDTH}c+o0/1.5c -F+glightgray --FONT_ANNOT_PRIMARY=6p <<- EOF
H 6p,Helvetica-Bold LEGEND
N 4
S - - 0.5c - 0.1p,white - 200 m bed elevation contours 
S - - 0.5c - 1p,blue - CLX/R66a (Fig. 1) 
S - - 0.5c - 1p,white - Cuesta profiles (Fig. 3) 
S - - 0.5c - 1p,orange - CLX/R75a (Fig. 4) 
S - v 15p white 0.25p,white - Ice flow vector (15 m/yr shown)
S - - 0.5c - 1p,black - Mapped dichotomy (basal ice)    
S - c 0.25c - 1p,yellow,dashed - Thermal Anomaly    
EOF
gmt end
