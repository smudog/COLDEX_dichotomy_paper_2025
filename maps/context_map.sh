#!/bin/bash


ORIG=`pwd | sed s@code@orig@g`
TARG=`pwd | sed s@code@targ@g`
mkdir -p $TARG

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

WIDTH=15c

gmt begin $TARG/historical_datasets png

    gmt basemap -JX${WIDTH}/0 $REGION_M -Blrbt+glightgray 

    #bedmap 1
    gmt plot $ORIG/BEDMAP1_1966-2000_AIR_BM1/BEDMAP1_1966-2000_AIR_BM1_points.shp -Sc1p -Gdimgray 

    for coldex in `ls $ORIG/projected_images_COLDEX/metadata/*.csv`
    do
         cat $coldex | awk -F "," 'NR>1{print $10, $11}' | awk 'NR%20==0' | gmt plot $REGION_M -W0.5p,white 
    done

    for bm2_survey in `ls $ORIG/BEDMAP2/shapeLines/*/*.shp`
    do
        case $bm2_survey in 
            *SOAR* )
            pen="0.5p,orange"
            ;;
            *AGAP* )
            pen="0.5p,blue"
            ;;
            *NASA* )
            pen="0.5p,limegreen"
            ;;
            *)
            continue
            ;;
         esac
         echo $bm2_survey
         gmt plot  $bm2_survey -W$pen -gd5e3
    done

    echo AGAP
    gmt plot $ORIG/BEDMAP2/LDEO/shapeLines/LDEO_2007_AGAP-GAMBIT_AIR_BM2/LDEO_2007_AGAP-GAMBIT_AIR_BM2_Lines.shp -W0.5p,purple -gd5e3


    for bm3_survey in `ls $ORIG/BEDMAP3/*.csv`
    do
        case $bm3_survey in 
            *POLARGAP* )
            pen="0.5p,dodgerblue"
            ;;
            *PRIC* )
            pen="0.5p,yellow"
            ;;
            *NASA_2018* )
            pen="0.5p,limegreen"
            ;;
            *)
            continue
            ;;
        esac

        echo $bm3_survey

        cat $bm3_survey | grep -v '#' | tr ',' '\t' | awk 'NR>1{print $3, $4}' \
            | gmt plot -JS0/-90/${WIDTH} $REGION_GEO -W$pen -gd0.1d

    done

gmt legend -DJTC+o0/0.5c+w${WIDTH} -F+glightgray << EOF
H 12p,Helvetica-Bold Southern Dome A ice thickness data
N 3
S - - - - 0.5p,white - NSF COLDEX
S - - - - 1p,dimgray,dotted - NSF Seismic (SPQMLT) 
S - - - - 1p,dimgray - SPRI-NSF-TUD Airborne
S - - - - 0.5p,orange - UTIG/SOAR
S - - - - 0.5p,blue - BAS/AGAP
S - - - - 0.5p,purple - LDEO/AGAP
S - - - - 0.5p,dodgerblue - BAS/DTU/Polargap
S - - - - 0.5p,limegreen - NASA/OIB
S - - - - 0.5p,yellow - PRIC/SPICECAP
EOF

    gmt basemap -JX${WIDTH}/0 $REGION_KM \
        -BWSne -Bxa+l"Eastings (km)"  -Bya+l"Northings (km)" \
        --FONT_ANNOT_PRIMARY=8p

gmt end


    

    

