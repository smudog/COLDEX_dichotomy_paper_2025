#!/bin/bash

min_hf=$WAIS/orig/supl/modl-ulb/van_liefferinge2018/Gpmp_all.tif

hr24=$WAIS/targ/supl/modl-osf/HazzardRichards2024/model_output/HR24_GHF_mean_PS.tiff
shen20=$WAIS/targ/supl/grid-polenet/shen-grl20/shen-hfmag.grd
martos17=$WAIS/targ/supl/grid-pangea/Martos2017/Antarctic_GHF.grd
staal20=$WAIS/targ/supl/grid-pangea/Staal2020/aq1_1_20_Q.xyz_val.grd

bedmap=$WAIS/targ/supl/grid-uci/BedMachine/BedMachine_bed.tiff
bed=$WAIS/targ/grid/COLDEX/p_icethk/bedelv.xyz.grd

gmt grdinfo $bed 

bnd=$WAIS/targ/supl/xtra-coldex/mek_transition_zone/clipped_bnd.gmt

TARG=`pwd | sed s@code@targ@g`

X_W=-50
X_E=700
Y_N=300
Y_S=-100

X_W_M=${X_W}000
X_E_M=${X_E}000
Y_N_M=${Y_N}000
Y_S_M=${Y_S}000

mkdir -p $TARG
REGION="-R${X_W_M}/${X_E_M}/${Y_S_M}/${Y_N_M}"
REGION_KM="-R${X_W}/${W_E}/${Y_S}/${Y_N}"

#REGION=`gmt grdinfo $bed -I500`

regen=1

if [ $regen -gt 0 ]
then

    echo reformat grids
    gmt grd2xyz $min_hf | gmt select $REGION | grep -i nan | gmt grdmask -N1/NaN/NaN $REGION -S8e3 -I5e3 -G$TARG/mask.grd 
    gmt grd2xyz $min_hf | gmt select $REGION | surface -I5e3 $REGION -T.35 -G$TARG/min_hf.grd
    gmt grd2xyz $hr24 | gmt select $REGION | surface -I5e3 $REGION -T.35 -G$TARG/hf_HZ24.grd
    gmt grd2xyz $shen20 | gmt select $REGION | surface -I5e3 $REGION -T.35 -G$TARG/hf_SHEN20.grd
    gmt grd2xyz $martos17 | gmt select $REGION | surface -I5e3 $REGION -T.35 -G$TARG/hf_MARTOS17.grd
    gmt grd2xyz $martos17| gmt select $REGION | surface -I5e3 $REGION -T.35 -G$TARG/hf_MARTOS17.grd
    gmt grd2xyz $staal20| gmt select $REGION | surface -I5e3 $REGION -T.35 -G$TARG/hf_STAAL20.grd

    echo grid calculations
    gmt grdmath $TARG/hf_HZ24.grd $TARG/min_hf.grd SUB $TARG/mask.grd MUL = $TARG/excess_heat_HZ24.grd
    gmt grdmath $TARG/hf_SHEN20.grd $TARG/min_hf.grd SUB $TARG/mask.grd MUL = $TARG/excess_heat_SHEN20.grd
    gmt grdmath $TARG/hf_MARTOS17.grd $TARG/min_hf.grd SUB $TARG/mask.grd MUL = $TARG/excess_heat_MARTOS17.grd
    gmt grdmath $TARG/hf_STAAL20.grd $TARG/min_hf.grd SUB $TARG/mask.grd MUL = $TARG/excess_heat_STAAL20.grd

fi

gmt gmtset FONT_TAG=8p FONT_HEADING=12p


rm -f excess_ghf.cpt
cat <<EOF >> excess_ghf.cpt
-50 blue -25 skyblue
-25 skyblue -5 white
-5 white 5 white
5 white 25 yellow
25 yellow 50 orange
EOF


gmt makecpt -Cexcess_ghf.cpt -T-50/50/5 -D -Z > ehf.cpt

echo plot
gmt begin $TARG/excess_heat PNG
    gmt subplot begin 2x2 $REGION -Fs10c \
            -JX10c/0 -A+jTR+gwhite+p1p+o0.2c/0.2c -Bwesn -T"Comparison to van Leifferinge et al. (2018) min GHF for melting"
        echo HA24
        gmt subplot set 0 -A"versus Hazzard & Richards (2024) seismic GHF"
            gmt grdimage $bedmap -Cgray 
            gmt grdimage $TARG/excess_heat_HZ24.grd -Cehf.cpt  -Q
            gmt plot $bnd -W1p,red
            gmt grdcontour $TARG/bedelv.xyz_val.grd -C200 -A1000+f6p 

        echo S20
        gmt subplot set 1 -A"versus Shen et al. (2020) empirical seismic GHF"
            gmt grdimage $bedmap -Cgray 
            gmt grdimage $REGION $TARG/excess_heat_SHEN20.grd -Cehf.cpt -Q
            gmt plot $bnd -W1p,red
            gmt grdcontour $TARG/bedelv.xyz_val.grd -C200 -A1000+f6p 

        echo M17
        gmt subplot set 2 -A"versus Martos et al. (2017) Curie depth GHF"
            gmt grdimage $bedmap -Cgray 
            gmt grdimage $REGION $TARG/excess_heat_MARTOS17.grd -Cehf.cpt -Q
            gmt plot $bnd -W1p,red
            gmt grdcontour $TARG/bedelv.xyz_val.grd -C200 -A1000+f6p 

        echo AQ1
        gmt subplot set 3 -A"versus St@al et al. (2020) empirical geophysics GHF"
            gmt grdimage $bedmap -Cgray 
            gmt grdimage $REGION $TARG/excess_heat_STAAL20.grd -Cehf.cpt -Q
            gmt plot $bnd -W1p,red
            gmt grdcontour $TARG/bedelv.xyz_val.grd -C200 -A1000+f6p 

    gmt subplot end
    echo colorbar
    gmt colorbar -DJBC -Cehf.cpt -Bxa -Bya+l"mW m@+-2@+"
    echo colorbar done
gmt end
