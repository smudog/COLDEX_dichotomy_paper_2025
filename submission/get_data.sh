#!/bin/bash

TARG=`pwd | sed s@code@targ@g`
CODE=`pwd`
ORIG=`pwd | sed s@code@orig@g`

mkdir -p $TARG
mkdir -p $ORIG

cd $ORIG

#locations of open polar radar data
cxa1=https://data.cresis.ku.edu/data/rds/2022_Antarctica_BaslerMKB/csv_good/2022_Antarctica_BaslerMKB.csv
cxa2=https://data.cresis.ku.edu/data/rds/2023_Antarctica_BaslerMKB/csv_good/2023_Antarctica_BaslerMKB.csv
agap_ldeo=https://data.cresis.ku.edu/data/rds/2009_Antarctica_TO_Gambit/csv_good/2009_Antarctica_TO_Gambit.csv

rm -frv $ORIG/COLDEX_SRF
mkdir -p $ORIG/COLDEX_SRF
cd $ORIG/COLDEX_SRF

cxa1_las="https://dataverse.tdl.org/api/access/dataset/:persistentId/?persistentId=doi:10.18738/T8/99IEOG"
curl -O -J ${cxa1_las}
unzip *.zip
rm -rvf $ORIG/COLDEX_SRF/*.zip
cxa2_las="https://dataverse.tdl.org/api/access/dataset/:persistentId/?persistentId=doi:10.18738/T8/PNBFOL"
curl -O -J ${cxa2_las} 
unzip *.zip
rm -rvf $ORIG/COLDEX_SRF/*.zip
cd $ORIG
exit


#locations of bedmap data
recovery_ldeo=https://ramadda.data.bas.ac.uk/repository/entry/get/LDEO_2007_Recovery-Lakes_AIR_BM2.csv?entryid=synth%3A2fd95199-365e-4da1-ae26-3b6d48b3e6ac%3AL0xERU9fMjAwN19SZWNvdmVyeS1MYWtlc19BSVJfQk0yLmNzdg%3D%3D
polargap=https://ramadda.data.bas.ac.uk/repository/entry/get/BAS_2015_POLARGAP_AIR_BM3.csv?entryid=synth%3A91523ff9-d621-46b3-87f7-ffb6efcd1847%3AL0JBU18yMDE1X1BPTEFSR0FQX0FJUl9CTTMuY3N2
agap_bas=https://ramadda.data.bas.ac.uk/repository/entry/get/BAS_2007_AGAP_AIR_BM2.csv?entryid=synth%3A2fd95199-365e-4da1-ae26-3b6d48b3e6ac%3AL0JBU18yMDA3X0FHQVBfQUlSX0JNMi5jc3Y%3D
soar=https://ramadda.data.bas.ac.uk/repository/entry/get/UTIG_1999_SOAR-LVS-WLK_AIR_BM2.csv?entryid=synth:2fd95199-365e-4da1-ae26-3b6d48b3e6ac:L1VUSUdfMTk5OV9TT0FSLUxWUy1XTEtfQUlSX0JNMi5jc3Y=
oib_2018=https://ramadda.data.bas.ac.uk/repository/entry/get/NASA_2018_ICEBRIDGE_AIR_BM3.csv?entryid=synth:91523ff9-d621-46b3-87f7-ffb6efcd1847:L05BU0FfMjAxOF9JQ0VCUklER0VfQUlSX0JNMy5jc3Y=
oib_2016=https://ramadda.data.bas.ac.uk/repository/entry/get/NASA_2016_ICEBRIDGE_AIR_BM3.csv?entryid=synth:91523ff9-d621-46b3-87f7-ffb6efcd1847:L05BU0FfMjAxNl9JQ0VCUklER0VfQUlSX0JNMy5jc3Y=

wget $cxa1
wget $cxa2
wget $agap_ldeo
wget $recovery_ldeo
wget $polargap
wget $agap_bas
wget $soar
wget $oib_2018
wget $oib_2016

mv LDEO_2007_AGAP-GAMBIT_AIR_BM2.csv* LDEO_2007_AGAP-GAMBIT_AIR_BM2.csv
mv LDEO_2007_Recovery-Lakes_AIR_BM2.csv* LDEO_2007_Recovery-Lakes_AIR_BM2.csv 
mv BAS_2015_POLARGAP_AIR_BM3.csv* BAS_2015_POLARGAP_AIR_BM3.csv
mv BAS_2007_AGAP_AIR_BM2.csv* BAS_2007_AGAP_AIR_BM2.csv
mv UTIG_1999_SOAR-LVS-WLK_AIR_BM2.csv* UTIG_1999_SOAR-LVS-WLK_AIR_BM2.csv
mv NASA_2018_ICEBRIDGE_AIR_BM3.csv* NASA_2018_ICEBRIDGE_AIR_BM3.csv
mv NASA_2016_ICEBRIDGE_AIR_BM3.csv* NASA_2016_ICEBRIDGE_AIR_BM3.csv

#icesat
ATL14_A1=https://data.nsidc.earthdatacloud.nasa.gov/nsidc-cumulus-prod-protected/ATLAS/ATL14/004/ATL14_A1_0325_100m_004_05.nc
ATL14_A2=https://data.nsidc.earthdatacloud.nasa.gov/nsidc-cumulus-prod-protected/ATLAS/ATL14/004/ATL14_A2_0325_100m_004_05.nc
ATL14_A3=https://data.nsidc.earthdatacloud.nasa.gov/nsidc-cumulus-prod-protected/ATLAS/ATL14/004/ATL14_A3_0325_100m_004_05.nc
ATL14_A4=https://data.nsidc.earthdatacloud.nasa.gov/nsidc-cumulus-prod-protected/ATLAS/ATL14/004/ATL14_A4_0325_100m_004_05.nc

wget $ATL14_A1
wget $ATL14_A2
wget $ATL14_A3
wget $ATL14_A4

echo SPICECAP data cannot be automatically downloaded, it is located at the USAP Data Center at https://doi.org/10.15784/601437
