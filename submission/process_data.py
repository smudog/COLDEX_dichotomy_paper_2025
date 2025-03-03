#!/usr/bin/env python3
'''Script for generating ice thickness and bed elevation grids

Code is assumed to be in a directory called 'code'
Downloaded data is assumed to be in a parallel directory called 'orig'
Generated data products will be placed in a parallel directory called 'targ'

Writing of some parts of code were aided by ChatGPT
''' 

import subprocess
import os 
from io import StringIO

'''packages requiring installation'''
import pygmt
from pygmt.clib import Session
import xarray as xr
from pyproj import Transformer
import pandas as pd
import numpy as np
import time

def read_opr(path, roughness_interval=400, epsg=3031):
    '''reads data as formated at the Open Polar Radar website
    arguments:
        path: path to downloaded csv files
        epsg: the grid projection EPSG identifier
    returns:
        pandas dataframe with x, y, bed elevation and ice thickness data
    '''
    data=pd.read_csv(path)
    transformer = Transformer.from_crs(4326,epsg,always_xy=True)
    
    data['X'], data['Y'] = transformer.transform(data['LON'],data['LAT'])
    data['BED'] = (data['ELEVATION'] - data['SURFACE']) - data['THICK']

    data[f'RMSD_{roughness_interval}'] = get_roughness(data, sample_interval=roughness_interval)

    return data[['X','Y','BED','THICK',f'RMSD_{roughness_interval}']]

def read_utig(path, roughness_interval=400, epsg=3031):
    '''reads UTIG formatted data

    arguments:
        path: path to folder with UTIG text files 
        epsg: the grid projection EPSG identifier
    returns:
        pandas dataframe with x, y, bed elevation and ice thickness data
    '''
    transformer = Transformer.from_crs(4326,epsg,always_xy=True)
    data = []

    '''headers for UTIG data are hidding in the comments, this loop extracts them'''
    for data_file in os.listdir(path):
        data_path=os.path.join(path,data_file)
        if 'txt' in data_file:
            with open(data_path,'r',errors="ignore") as f:
                this_line = ''
                for line in f.readlines():
                    columns_list = this_line
                    this_line = line
                    if line[0] == '#':
                        continue
                    else:
                        columns = columns_list.split()[1:]
                        break

            df = pd.read_csv(data_path,sep=r'\s+',comment='#',names=columns,encoding="ISO-8859-1")
            data.append(df)

    all_data = pd.concat(data)
    all_data['X'], all_data['Y'] = transformer.transform(all_data['LON'],all_data['LAT'])

    if 'THK' in all_data.columns:
        all_data['THICK'] = all_data['THK']
        all_data['BED'] = all_data['BED_ELEVATION']
        all_data[f'RMSD_{roughness_interval}'] = get_roughness(all_data, sample_interval=roughness_interval)

    return all_data

def read_bedmap(path, roughness_interval=400, epsg=3031):
    '''reads Bedmap formatted data from the UK polar data center
    see Fremand et al 2022 (https://doi.org/10.5194/essd-15-2695-2023) for details

    arguments:
        path: path to csv files 
        epsg: the grid projection EPSG identifier
    returns:
        pandas dataframe with x, y, bed elevation and ice thickness data
    '''
    data=pd.read_csv(path,comment='#',na_values=-9999)
    transformer = Transformer.from_crs(4326,epsg,always_xy=True)
    
    data['X'], data['Y'] = transformer.transform(data['longitude (degree_east)'],data['latitude (degree_north)'])
    data['BED'] = data['bedrock_altitude (m)']
    data['THICK'] = data['land_ice_thickness (m)']
    data[f'RMSD_{roughness_interval}'] = get_roughness(data, sample_interval=roughness_interval)

    return data[['X','Y','BED','THICK',f'RMSD_{roughness_interval}']]

def get_roughness(data, sample_interval=400):
    start_time = time.time()

    #data.reset_index(inplace=True)

    data['GAPS'] = np.sqrt((data['X'].diff().fillna(0)**2) + (data['Y'].diff().fillna(0)**2))
    data['DISTANCE'] = data['GAPS'].cumsum()

    max_distance = sample_interval * round(np.nanmax(data['DISTANCE'])/sample_interval)

    new_distances = np.arange(0,max_distance,sample_interval)

 #   in_gap = np.zeros_like(new_distances, dtype=bool)

    # Identify where the gap exceeds threshold
 #   large_gaps = data[data['GAPS'] > max_gap]

#    print('Create gap intervals')
#    print(time.time() - start_time)
#    gap_intervals = pd.IntervalIndex.from_tuples([
#        (data.loc[idx - 1, 'DISTANCE'], data.loc[idx, 'DISTANCE'])
#        for idx in large_gaps.index
#    ])

#    print(len(gap_intervals))
#    print('Apply gaps in a vectorized way')
#    print(time.time() - start_time)
#    for interval in gap_intervals:
#        in_gap[(new_distances > interval.left) & (new_distances < interval.right)] = True

#    print('Interpolating bed elevation data') 
#    print(time.time() - start_time)

    # Vectorized mask for interpolated data
#    interpolated_data = pd.DataFrame({
#        'DISTANCE': new_distances
#    })

    # interpolation
    interpolated_bed = np.interp(
        new_distances, 
        data['DISTANCE'],
        data['BED']  
    )

    interpolated_bed_series = pd.Series(interpolated_bed)

    interpolated_rmsd = np.sqrt((interpolated_bed_series.diff() ** 2).rolling(window=5).mean())

    rmsd = np.interp(
        data['DISTANCE'],
        new_distances, 
        interpolated_rmsd  
    )

    #interpolated_x = np.interp(
    #    new_distances, 
    #    data['DISTANCE'], 
    #    data['X'] 
    #)

    #interpolated_y = np.interp(
    #    new_distances, 
    #    data['DISTANCE'], 
    #    data['Y'] 
    #)

    #interpolated_data = pd.DataFrame({
    #'DISTANCE': new_distances,
    #'X': interpolated_x,
    #'Y': interpolated_y,
    #'BED': interpolated_bed,
    #})

    # Check if distances fall into any gap interval
    #in_gap = interpolated_data['DISTANCE'].apply(lambda x: gap_intervals.contains(x))
#    in_gap = gap_intervals.contains(pd.Series(interpolated_data['DISTANCE'].values)).any(level=0)

    #print('filtering data gaps') 
    #print(time.time() - start_time)
    ## Set values within large gaps to NaN
    #interpolated_data['BED'] = np.where(in_gap, np.nan, interpolated_bed)
    #interpolated_data['X'] = np.where(in_gap, np.nan, interpolated_x)
    #interpolated_data['Y'] = np.where(in_gap, np.nan, interpolated_y)

    #interpolated_data['RMSD'] = np.abs(interpolated_data['BED'].diff())
    #print(time.time() - start_time)
    return rmsd 
    


def bin_and_grid(data,
        name,
        region=None,
        z=None,
        blockspacing=None,
        grdspacing=None,
        maxradius=None,
        filter=None,
        rms=False
        ):
    '''Code to bin, interpolate, filter and mask grid data
    arguments:
        data: pandas dataframe with x, y, and data values
        name: name of output grid
        z: the dataframe column to use for the gridded data value
        region: array with projected coordinates with x_min, x_max, y_min, y_max
        blockspacing: the size of the bins used to reduce the input data in projected units
        grdspacing: the size of final gridded cells in projected units
        maxradius: how far from datapoints interpolated values are permitted in projected units
        filter: size of the Gaussian filter to apply to the data in projected units
        rms: Boolean to process data as RMS
    
    returns:
        two xarray grids - one masked and one unmasked
    outputs:
        two GeoTiffs - one masked and one unmasked
    '''
    print(f'Processing {name}')
    targ=os.getcwd().replace('code','targ')
    if rms:
        binned_data = np.sqrt(pygmt.blockmean(x=data['X'], y=data['Y'], z=data[z]**2, region=region, spacing=blockspacing))
    else:
        binned_data = pygmt.blockmean(x=data['X'], y=data['Y'], z=data[z], region=region, spacing=blockspacing)
    
    nn_data = nnbathy(binned_data,region,grdspacing)
    grd = pygmt.xyz2grd(data=nn_data,region=region,spacing=grdspacing)
    grd_mask = pygmt.surface(x=data['X'], y=data['Y'], z=data[z], spacing=grdspacing, region=region, maxradius=maxradius)
    mask = grd_mask.where(grd_mask.isnull(), 1)
    grd_fil = pygmt.grdfilter(grd,filter=f'g{filter}',distance='0')
    grd_masked = grd_fil * mask
    grd_masked.rio.to_raster(os.path.join(targ,f'{name}.xyz_val.tif'))
    grd_fil.rio.to_raster(os.path.join(targ,f'{name}.xyz.tif'))
    return grd_masked
    
def plot(grid,name='None',cmap='thermal',series=None, shade=True):
    '''GMT code to produce quality control plots of the producted grids
    arguments:
        grid: xarray data grid to plot
        name: string with the name of the grid for plotting purposes
        cmap: GMT6 colormap to use
        series: python array with min_z,max_z and interval
        shade: Boolean for shading

    output:
        png figure with contours and shaded colormapped grid
    '''


    targ=os.getcwd().replace('code','targ')
    fig = pygmt.Figure()

    info=pygmt.grdinfo(grid)
    region = [None,None,None,None]
    for line in info.split('\n'):
        if 'x_min' in line:
            region[0] = float(line.split()[2])
            region[1] = float(line.split()[4])
        if 'y_min' in line:
            region[2] = float(line.split()[2])
            region[3] = float(line.split()[4])

    region_km=[region[0]/1000, region[1]/1000, region[2]/1000, region[3]/1000]
    
    pygmt.makecpt(cmap=cmap,series=series,continuous=True,background="i")
    fig.grdimage(grid=grid, cmap=True, projection='X15/0',shading=shade,dpi=300)
    fig.grdcontour(grid=grid, levels=200, projection='X15/0')
    fig.basemap(region=region_km, projection='X15/0', frame=[f'WSne+t{name}','xa','ya'])
    fig.colorbar(position='JBC',frame=['xa','ya+lm'])
    fig.savefig(os.path.join(targ,f'{name}.png'))

def meshgrid(region,spacing):
    '''Produces a dataframe for the coordinates of every point in the grid
    arguments:
        region: array with projected coordinates with x_min, x_max, y_min, y_max
        spacing: the size of final gridded cells in projected units
    returns:
        dataframe with x and y columns
    '''
    x = np.arange(region[0],region[1],spacing)
    y = np.arange(region[2],region[3],spacing)
    xx, yy = np.meshgrid(x,y)
    xy = pd.DataFrame({'x':np.ravel(xx),'y':np.ravel(yy)})
    return xy

def nnbathy(data,region,spacing):
    '''Applies natural neighbour interpolation using Pavel Sakov's c implementation:
    https://github.com/sakov/nn-c
    download repo from github, descend into source code, 'configure' and 'make' the executable

    arguments:
        data: pandas dataframe with x,y,z data
        region: array with projected coordinates with x_min, x_max, y_min, y_max
        spacing: the size of final gridded cells in projected units
    returns:
        pandas dataframe with interpolated x,y,z data
    '''
    input_data = data.to_csv(sep=' ', header=False, index=False)
    xy = meshgrid(region,spacing)
    xy.to_csv('template.xy',sep='\t',header=False,index=False)
    
    try:
        process = subprocess.Popen(
            ['nn-c/nn/nnbathy', '-i', '-', '-o', 'template.xy', '-%'],  # Assuming nnbathy accepts stdin and stdout with '-'
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True  # Ensures input/output are strings, not bytes
        ) 
        stdout, stderr = process.communicate(input=input_data)

        if process.returncode != 0:
            print(f"nnbathy failed: {stderr}")
        else:
            # Read the output back into a DataFrame
            output_df = pd.read_csv(StringIO(stdout), sep=' ', names=['x', 'y', 'z'])

        return output_df

    except FileNotFoundError:
        exit()
        print("nnbathy executable not found. Ensure it's in your PATH.")     

        

def read_and_process_data(region,blockspacing=2.5e3,roughness_interval=400):
    targ=os.getcwd().replace('code','targ')
    os.makedirs(targ,exist_ok=True)

    orig=os.getcwd().replace('code','orig')
    os.makedirs(orig,exist_ok=True)
    
# setting corner cells to zero to stablize the interpolation
    corners = pd.DataFrame({'X': [region[0],region[0],region[1],region[1]],
               'Y': [region[2],region[3],region[2],region[3]],
               'BED': [0,0,0,0],
               'THICK': [0,0,0,0],
               'SPECULARITY_CONTENT_FILTERED': [0,0,0,0],
               'basal layer thickness': [0,0,0,0]
               })
# collecting specularity content data
    spec=[]
    spec.append(read_utig(os.path.join(orig,'2022_COLDEX_UTIG.IRSPC2')))
    spec.append(read_utig(os.path.join(orig,'2023_COLDEX_UTIG.IRSPC2')))
    spec.append(corners)
    all_spec = pd.concat(spec)

# collecting thickness and bed elevation data
    thk=[]
    thk.append(read_utig(os.path.join(orig,'ICECAP2_SPC.CRIPR2')))
    
    mkb=[]

    for f in os.listdir(orig):
        if 'csv' in f:
            if 'Antarctica_BaslerMKB' in f:
                print(f'Reading {f} as Open Polar Radar')
                mkb.append(read_opr(os.path.join(orig,f),roughness_interval=roughness_interval))
                thk.append(read_opr(os.path.join(orig,f),roughness_interval=roughness_interval))
            elif 'Antarctica_TO' in f:
                print(f'Reading {f} as Open Polar Radar')
                thk.append(read_opr(os.path.join(orig,f),roughness_interval=roughness_interval))
            else:
                print(f'Reading {f} as Bedmap')
                thk.append(read_bedmap(os.path.join(orig,f),roughness_interval=roughness_interval))
    thk.append(corners)
    all_thk = pd.concat(thk)
    all_mkb = pd.concat(mkb)

    #rms = get_roughness(all_thk)

    grids = {}

    grids['roughness'] = bin_and_grid(all_thk,'roughness',region=region,z=f'RMSD_{roughness_interval}',blockspacing=5e3,grdspacing=1e3,maxradius=8e3,filter=10e3)
    grids['icethk'] = bin_and_grid(all_thk,'icethk',region=region,z='THICK',blockspacing=5e3,grdspacing=1e3,maxradius=8e3,filter=10e3)
    grids['bedelv'] = bin_and_grid(all_thk,'bedelv',region=region,z='BED',blockspacing=5e3,grdspacing=1e3,maxradius=8e3,filter=10e3)

    try:
        basal_df = pd.read_csv(os.path.join(orig,'yan_basal_layer','cxa_bil_thickness.csv'))
        basal_df['X'] = basal_df['x']
        basal_df['Y'] = basal_df['y']
        basal_df = pd.concat([basal_df,corners])
        grids['basal_layer_thickness'] = bin_and_grid(basal_df,'basal_layer_thickness',region=region,z='basal layer thickness',blockspacing=5e3,grdspacing=1e3,maxradius=8e3,filter=10e3) 
        grids['fract_basal_ice_percent'] = 100 * (grids['basal_layer_thickness']/grids['icethk'])
        plot(grid=grids['fract_basal_ice_percent'],name='Basal Ice Fractional Thickness',cmap='ocean',series=[0,40,1],shade=False)
    except FileNotFoundError:
        print(f"could not find {os.path.join(orig,'yan_basal_layer','cxa_bil_thickness.csv')}")
    except KeyError:
        print(basal_df)

    grids['spec'] = bin_and_grid(all_spec,'specularity_content',region=region,z='SPECULARITY_CONTENT_FILTERED',blockspacing=5e3,grdspacing=1e3,maxradius=8e3,filter=10e3)

    high_pass = pygmt.grdtrack(grid=grids['bedelv'], points=all_mkb, output_type='pandas', newcolname='GRD_BED')
    high_pass['HIGH_PASS_BED'] = high_pass['BED'] - high_pass['GRD_BED']
    high_pass.drop(columns=['BED','GRD_BED','THICK',f'RMSD_{roughness_interval}'],inplace=True)
    high_pass.to_csv(os.path.join(targ,'hipass_bed.xyz'),index=False,header=False,sep='\t')

    for g in grids.keys():
        pygmt.grdsample(grids[g], outgrid = os.path.join(targ,f'{g}.tif=gd:GTiff'))

    plot(grid=grids['icethk'],name='Ice Thickness',series=[2000,4000,100])
    plot(grid=grids['bedelv'],name='Bed Elevation',cmap='globe',series=[-2500,2500,100])
    plot(grid=grids['spec'],name='Specularity Content',cmap='ocean',series=[0,0.5,0.1],shade=False)
    plot(grid=grids['roughness'],name='RMS Roughness @ 400 m',cmap='magma',series=[0,50,1],shade=False)
                

read_and_process_data([-200e3,800e3,-200e3,400e3])


        

