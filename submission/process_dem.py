#!/usr/bin/env python3

from netCDF4 import Dataset
import os
import pandas as pd
import numpy as np
import pygmt
from pyproj import Transformer
from matplotlib import pyplot as plt

'''Code to compile laser altimetry data around South Pole'''

def lltoxy(lon,lat,epsg=3031):
    '''reprojects geographic to projected coordinates'''
    transformer = Transformer.from_crs(4326,epsg,always_xy=True)
    x, y = transformer.transform(lon,lat)
    return x, y

def read_nc(data,region=None):
    '''reads a IceSat-2 ALT14 dem file and converts to a pandas DataFrame'''
    cut_grd = pygmt.grdcut(grid=f'{data}?h',region=region,extend=np.nan)
    xyz = pygmt.grd2xyz(cut_grd)
    xyz = xyz.dropna()
    return xyz

def get_atl14(orig,region=None):
    '''retrieves ATL14 DataFrames and combines them. Windows the data using a project units region (x_min,x_max,y_min,y_max)'''
    atl14=[]
    for i in [1,2,3,4]: 
        print(f'reading ATL14_A{i}')
        atl14.append(read_nc(os.path.join(orig,f'ATL14_A{i}_0325_100m_004_05.nc'),region=region))
    return pd.concat(atl14)

def get_ILUTP2(orig):
    '''retrieves UTIG style *LUTP2 surface laser altimetry files, reprojects and concatenates them'''
    ilutp2=[]
    for d in [ 'COLDEX_SRF' , 'ICECAP2_SPC.CLUTP2' ]:
        for f in os.listdir(os.path.join(orig,d)):
            if 'LUTP2' in f:
                if f.split('.')[-1] == 'txt':
                    print(f)
                    try:
                        data = pd.read_csv(os.path.join(orig,d,f), encoding = "ISO-8859-1", comment='#', header=None, index_col=False, names=['year','day','sec','lon','lat','z'],sep=r"\s+")
                        ilutp2.append(data) 
                    except UnicodeDecodeError:
                        print(f'{f} Failed due to UnicodeDecodeError')

    data = pd.concat(ilutp2)
    data['X'],data['Y'] = lltoxy(data['lon'],data['lat'])
    return data.drop(labels=['year','day','sec','lon','lat'],axis=1)

def get_SOAR(orig):
    '''retrieves UTIG style *LUTP2 surface laser altimetry files, reprojects and concatenates them.'''
    data = pd.read_csv(os.path.join(orig,'SOAR-PPT-las_srfelv.grid'), encoding = "ISO-8859-1", comment='#', header=None, index_col=False, names=['lon','lat','z'],sep=r"\s+")
    data['X'],data['Y'] = lltoxy(data['lon'],data['lat'])
    return data.drop(labels=['lon','lat'],axis=1)

def get_BAS(orig):
    '''retrieves BAS style BM3 data files files, reprojects and concatenates them. Polargap used laser altimetry for the surface.'''
    data = pd.read_csv(os.path.join(orig,'BAS_2015_POLARGAP_AIR_BM3.csv'), encoding = "ISO-8859-1", comment='#', index_col=False)
    data['X'],data['Y'] = lltoxy(data['longitude (degree_east)'],data['latitude (degree_north)'])
    data['z'] = data['surface_altitude (m)']
    return data[['X','Y','z']]

def compile_srf(region=None):
    '''Combines SOAR, UTIG, BAS and IceSat-2 data. Filters out any points below sea level'''
    orig=os.getcwd().replace('code','orig')
    las = get_ILUTP2(orig)
    soar = get_SOAR(orig)
    bas = get_BAS(orig)
    dem = get_atl14(orig,region=region)
    dem['X'] = dem['x']
    dem['Y'] = dem['y']
    dem.drop(labels=['x','y'],axis=1)
    srf = pd.concat([las,dem,soar,bas])
    return srf.loc[srf.z > 0]

def grid_srf(srf):
    '''For development - grids the compiled data'''
    from process_data import bin_and_grid
    srf_grid = bin_and_grid(srf.loc[srf.z > 0],name='srfelv',z='z',region=region,blockspacing=5000,grdspacing=1000,maxradius=15000,filter=3000,rms=False)
    return srf_grid

def main(region=None):
    '''For development - grids and shows the compiled data'''
    srf = compile_srf(region=region)
    srf_grid = grid_srf(srf)
    plt.imshow(np.flipud(srf_grid),extent=region)
    plt.show()

if __name__ == "__main__":
    main(region=[-200e3,800e3,-200e3,400e3])
