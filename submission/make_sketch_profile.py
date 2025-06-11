#!/usr/bin/env python3

import os 
import pygmt
import xarray as xr
from PIL import Image
Image.MAX_IMAGE_PIXELS = None
import rioxarray as rxa
import numpy as np
import pandas as pd
from pyproj import Transformer
from datetime import datetime,timezone
from matplotlib import pyplot as plt


def project_to_radial(lon,lat):
    ''' Obtain along track distance and EPSG X and Y coordinates '''
    origin_x=964892.757
    origin_y=384953.176

    transformer = Transformer.from_crs("EPSG:4326","EPSG:3031",always_xy=True)
    x,y = transformer.transform(lon,lat)
    d = np.sqrt((x-origin_x)**2 + (y-origin_y)**2)
    return d/1000,x,y

def read_grd(path):
    ''' Load a GeoTIFF file as an xarray DataArray '''
    raster = rxa.open_rasterio(path)
    return raster.sel(band=1)

def read_opr_picks(path,frame):
    ''' Read Open Polar Radar picks file as a Pandas Dataframe'''
    data = pd.read_csv(path)
    return data[data['FRAME'].astype(str).str.contains(frame)]

def read_radargram(path,transect):
    ''' Read a JPG formatted Open Polar Radar radargram and associated metadata '''
    radargram_path=os.path.join(path,'image',f'{transect.replace("/","_")}_image.jpg')
    img = np.array(np.asarray(Image.open(radargram_path)))[:,:,0]
    radar=140*(img.astype('float')-255)/256
    nrows, ncols = radar.shape


    metadata_path=os.path.join(path,'image',f'{transect.replace("/","_")}_image.csv')
    metadata=pd.read_csv(os.path.join(path,'metadata',f'{transect.replace("/","_")}_image.csv'))
    x0=metadata['Displayed_distance [km]'].iloc[0]
    x1=metadata['Displayed_distance [km]'].iloc[-1]
    y0=metadata['Elevation of image bottom [m]'].iloc[0]
    y1=metadata['Elevation of image top [m]'].iloc[0]
    region=[x0,x1,y0,y1]

    x_spacing = abs((x1 - x0)/ncols)
    y_spacing = abs((y1 - y0)/nrows)

    x_vals = np.linspace(x0, x1, ncols)
    y_vals = np.linspace(y1, y0, nrows)

    X, Y = np.meshgrid(x_vals, y_vals)

    xyz_table = np.column_stack((X.ravel(), Y.ravel(), radar.ravel()))

    radar_grd = pygmt.xyz2grd(xyz_table,region=region,spacing=f'{x_spacing}/{y_spacing}')
    return radar_grd, region, metadata


def plot(targ=os.getcwd().replace('code','targ'),orig=os.getcwd().replace('code','orig')):

    focus_line='CLX/R75a'

    os.makedirs(targ,exist_ok=True)

    pygmt.config(MAP_FRAME_TYPE='plain',FONT_ANNOT_PRIMARY='8p',FONT_LABEL='8p')
    fig = pygmt.Figure()

#read radargram
    data,bounds,metadata=read_radargram(os.path.join(orig,'projected_images_COLDEX'),'CLX/R75a')

#obtain gridded products along profile
    bed_grd = os.path.join(targ,'bedelv.tif')
    thk_grd = os.path.join(targ,'icethk.tif')
    basal_grd = os.path.join(targ,'fract_basal_ice_percent.tif')

    xy = metadata[['EPSG 3031 Easting [m]','EPSG 3031 Northing [m]','Displayed_distance [km]']].copy()

    bed = pygmt.grdtrack(grid=bed_grd,points=xy,newcolname='bed')
    thk = pygmt.grdtrack(grid=thk_grd,points=bed,newcolname='thk')
    basal = pygmt.grdtrack(grid=basal_grd,points=thk,newcolname='basal')
    basal['strat'] = (basal['basal']/100) * basal['thk'] + basal['bed']  

# set figure bounds
    x0=675
    x1=950

    z0=-2000
    z1=3650

    height=2
    width=-7

# get aspect ratio
    z = z1-z0
    x = 1000*(x1-x0)
    aspect = abs(height/z)/abs(width/x)
    
# get time constraints
    date = datetime(year=2023,month=12,day=29,tzinfo=timezone.utc)
    unix_date = date.timestamp()
    metadata['Seconds of Day'] = metadata['UNIX time [s]'] - unix_date 
    metadata['posix'] = pd.to_datetime(metadata['UNIX time [s]'],unit="s")
    metadata.set_index('posix',inplace=True)

    max_seconds = metadata['Seconds of Day'].max() 
    min_seconds = metadata['Seconds of Day'].min() 

#read OPR bed pick
    pick = read_opr_picks(os.path.join(orig,'2023_Antarctica_BaslerMKB.csv'),'2023122902')
#generate bed elevation
    pick['BED'] = pick['ELEVATION'] - (pick['SURFACE'] + pick['THICK'])
#get distance along radial
    pick['D'],pick['X'],pick['Y'] = project_to_radial(pick['LON'],pick['LAT'])

#filter bedpick by time
    this_pick = pick.loc[(pick['UTCTIMESOD'] > min_seconds) & (pick['UTCTIMESOD'] < max_seconds)].copy()

# make basal unit polygon
    basal.loc[len(basal)] = [0,0,basal['Displayed_distance [km]'].max(),0,0,0,z1]
    basal.loc[len(basal)] = [0,0,basal['Displayed_distance [km]'].min(),0,0,0,z1]
    basal.loc[len(basal)] = [0,0,basal['Displayed_distance [km]'].min(),0,0,0,basal['strat'].iloc[0]]
# make bed polygon
    this_pick.loc[len(this_pick)] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, z1, this_pick['D'].max(), 0, 0 ]
    this_pick.loc[len(this_pick)] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, z1, this_pick['D'].min(), 0, 0 ]
    this_pick.loc[len(this_pick)] = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, this_pick['BED'].iloc[0], this_pick['D'].min(), 0, 0 ]

# make sed basin polygon
    sed_basin_x=[875, 860,755, 755]
    sed_basin_y=[1000, -1500, -750, 1000]


    fig.shift_origin(yshift='3i')
    fig.basemap(region=[x0,x1,z0,z1],frame=['af','Wsne+gdarkgray','x','y+lWGS 84 Elevation (m)'],projection=f'X{width}i/{height}i')
    pygmt.makecpt(cmap='gray',series='-140/-85/5',continuous=True)
    fig.grdimage(data,dpi='i')
    fig.text(position='TL',text=f'a) Transect {focus_line}',justify='TL',font='8p,white',offset='J0.1c')
    fig.text(position='BR',text=f'{aspect:.1f}x vertical exaggeration',justify='BR',font='8p,gray',offset='J0.1c')

    print('SPB')
    fig.text(x=825,y=-1000,text=f'INNER SOUTH POLE BASIN',justify='BC',offset='j0.05i',font='6p,Helvetica-Bold,ivory')
    fig.text(x=700,y=-1000,text=f'OUTER SOUTH POLE BASIN',justify='BC',offset='j0.05i',font='6p,Helvetica-Bold,ivory')

    print('Cuestas')
    fig.text(x=755,y=-1000,text=f'C u e s t a s',justify='TC',offset='j0.1i+v1p,ivory',font='6p,Helvetica-Bold,ivory')
    fig.plot(x=[765,745],y=[-1000,-1000],pen='2p,ivory')
    #,style='v0.3c+bt+et+a80')

    print('Elbow')
    fig.text(x=822.5,y=-1000,text=f'T h e   E l b o w   C o m p l e x',justify='TC',offset='j0.1i+v1p,ivory',font='6p,Helvetica-Bold,ivory')
    fig.plot(x=[865,770],y=[-1000,-1000],pen='2p,ivory')

    print('ReSH')
    fig.text(x=890,y=-750,text=f'RECOVERY',justify='BC',offset='j0.025i',font='6p,Helvetica-Bold,ivory')
    fig.text(x=890,y=-750,text=f'SUBGLACIAL HIGHLANDS',justify='TC',offset='j0.025i',font='6p,Helvetica-Bold,ivory')

    fig.text(x=700,y=250,text=f'Basal Unit',justify='BR',offset='j0.25i+v1p',font='6p,Helvetica-Bold,black')

    fig.shift_origin(yshift='-2.2i')

    fig.basemap(frame=['af','WSne+glightbrown','xa+lDistance from Dome A origin (km)','ya+lWGS 84 Elevation (m)'])
    fig.plot(x=sed_basin_x,y=sed_basin_y,fill='p19+bnavajowhite+flightbrown+r600',label='Sedimentary basin')
    fig.plot(x=this_pick['D'],y=this_pick['BED'],fill='cyan',label='Basal unit')
    fig.plot(x=[800,600,600,750],y=[-1000,-1000,1000,1000],fill='p19+b+flightbrown+r600',transparency=50)
    fig.plot(x=this_pick['D'],y=this_pick['BED'],pen='0.25p,black')
    fig.plot(x=basal['Displayed_distance [km]'],y=basal['strat'],fill='white',label='Stratigraphic ice')
    fig.plot(x=metadata['Displayed_distance [km]'].ewm(span=60).mean(),y=metadata['Surface_elevation [m]'].ewm(span=60).mean(),pen='1p,blue')
    fig.plot(x=[870,858], y=[200, -2000], style='f2c/0.5c+r+s45+o0.5c', pen='1.25p')
    for x in [860,850,840,830,820,810,800]:
        fig.plot(x=[x],y=[-500],direction=[270,0.4],style='v0.2c+e+a40+gdodgerblue+h0+p1p,dodgerblue',pen='1p,dodgerblue')

    fig.plot(x=[700],y=[1800],direction=[0,10],style='v1c+e+a40+gdeepskyblue+h0+p1p,deepskyblue',pen='10p,deepskyblue')
    fig.text(x=775,y=1800,text='Ice Flow Direction',font='8p,Helvetica-Bold,white',justify='MC')

    fig.plot(x=[860],y=[-1400],direction=[174,5],style='v0.3c+e+a40+gred+h0+p1p,red',pen='2p,red')

    
    fig.text(x=700,y=0,text='inflowing basal unit with trace sediment',font='8p,Helvetica-Bold,black',justify='BR',offset='j0.25i+v1p')
    fig.text(x=780,y=-750,text='basal unit melting and sediment deposition',font='8p,Helvetica-Bold,black',justify='TL',offset='j0.1i+v1p')
    fig.text(x=835,y=-700,text='subglacial water infiltration',font='8p,Helvetica-Bold,black',justify='BC',offset='j0.5i+v1p')
    fig.text(x=860,y=-1500,text='bounding fault',font='8p,Helvetica-Bold,black',justify='MR',offset='j0.1i+v1p')
    fig.text(x=800,y=-1000,text='warm groundwater return flow',font='8p,Helvetica-Bold,black',justify='TL',offset='j0.2i+v1p')

    fig.text(position='TL',text=f'b) Geological sketch',justify='TL',font='8p,black',offset='J0.1c')
    fig.legend(position="JTR+jTR+o0.2c",box='+ggray+p1p')

    fig.savefig(os.path.join(targ,'coldex_sketch_profile.png'))
    fig.savefig(os.path.join(targ,'coldex_sketch_profile.pdf'))

plot()


