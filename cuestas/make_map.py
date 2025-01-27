#!/usr/bin/env python3

import os 
import pygmt
import xarray as xr
from PIL import Image
Image.MAX_IMAGE_PIXELS = None
import rioxarray as rxa
import numpy as np
import pandas as pd

WAIS=os.environ['WAIS']

def read_grd(path):
    # Load the GeoTIFF file as an xarray DataArray
    raster = rxa.open_rasterio(path)
    print(raster)
    return raster.sel(band=1)

def read_radargram(path,transect):
    radargram_path=os.path.join(path,'image',f'{transect.replace("/","_")}_image.jpg')
    img = np.array(np.asarray(Image.open(radargram_path)))[:,:,0]
    print(img)
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
    return radar_grd, region

def read_psts(path=os.path.join(WAIS,'targ/comm/DATA-OPR/projected_images_COLDEX/metadata')):
    transects = {}
    files = os.listdir(path)
    for f in files:
        if 'csv' in f:
            name=f'{f.split("_")[0]}/{f.split("_")[1]}'
            transects[name] = pd.read_csv(os.path.join(path,f))
    return transects

def plot_transect(fig,transect,geo=False,pen='0.5,dimgray'):
    if geo:
        x = transect['Latitude [degrees]']
        y = transect['Longitude [degrees]']
    else:
        x = transect['EPSG 3031 Easting [m]']
        y = transect['EPSG 3031 Easting [m]']
    fig.plot(x=x,y=y,pen=pen)
    return fig

def plot(targ=os.getcwd().replace('code','targ')):

    focus_line='CLX/R66a'

    os.makedirs(targ,exist_ok=True)

    x1 = -150e3
    x2 = 800e3
    y1 = -250e3
    y2 = 400e3
    region=f'{x1}/{x2}/{y1}/{y2}'
    region_km=f'{x1/1000}/{x2/1000}/{y1/1000}/{y2/1000}'

    raster = read_grd(os.path.join(WAIS,'orig/supl/grid-pgc/rema/1km/rema_mosaic_1km_v2.0_filled_cop30_dem.tif'))
    # Replace -9999 with NaN
    raster = raster.where(raster!=-9999)

    transects = read_psts()

    # Plot the raster using PyGMT
    # Download grid for Earth relief with a resolution of 10 arc-minutes and
    # gridline registration [Default]
    region_context = [0,360,-90,-60]
    #grid_map = pygmt.datasets.load_earth_relief(
    #            resolution="30m",
    #        )

    pygmt.config(MAP_FRAME_TYPE='plain',FONT_ANNOT_PRIMARY='8p',FONT_LABEL='8p')
    fig = pygmt.Figure()
    fig.basemap(frame='btlr+gsnow',region=region_km,projection="X2.5i/0")
    fig.grdcontour(grid=raster,region=region,projection="X2.5i/0",annotation=500,levels=50,pen=['c0.25p,gray','a0.5p,gray'])
    for transect in transects.keys():
        x = transects[transect]['EPSG 3031 Easting [m]']
        y = transects[transect]['EPSG 3031 Northing [m]']
        fig.plot(x=x,y=y,pen='0.5p,dimgray')

    fig.plot(x=transects[focus_line]['EPSG 3031 Easting [m]'],y=transects['CLX/R66a']['EPSG 3031 Northing [m]'],pen='0.5p,blue')
    fig.plot(x=transects[focus_line]['EPSG 3031 Easting [m]'].iloc[0],y=transects['CLX/R66a']['EPSG 3031 Northing [m]'].iloc[0],style='c0.1c',fill='blue')
    fig.basemap(frame=['af','wsNE','x+lEasting (km)','y+lNorthing (km)'],region=region_km)
 
    fig.shift_origin(xshift="-1.75i",yshift='-0.15i')
    fig.basemap(
            region=region_context,
            projection="S0/-90/2i",
            frame="g"
    )
    fig.coast(area_thresh='+ai',land="lightblue", water="skyblue")
    fig.coast(area_thresh='+ag',land="snow")
    for transect in transects.keys():
        x = transects[transect]['Longitude [degrees]']
        y = transects[transect]['Latitude [degrees]']
        fig.plot(x=x,y=y,pen='0.1p,dimgray')
    fig.plot(x=transects[focus_line]['Longitude [degrees]'],y=transects['CLX/R66a']['Latitude [degrees]'],pen='0.25p,blue')

    fig.text(x=123.33,y=-75.1,text='Dome C',justify='BL',font='8p',D='J0.1c+v')
    fig.text(x=77.33,y=-80.33,text='Dome A',justify='BL',font='8p',D='J0.1c+v')
    fig.text(x=0,y=-90,text='South Pole',justify='BR',font='8p',D='J0.1c+v')
    fig.text(x=166.67,y=-77.83,text='McMurdo',justify='TR',font='8p',D='J0.1c+v')

    data,bounds=read_radargram(os.path.join(WAIS,'targ/comm/DATA-OPR/projected_images_COLDEX'),'CLX/R66a')

    x0=bounds[0]
    x1=bounds[1]

    z0=-1000
    z1=3650

    height=1
    width=-4

    z = z1-z0
    x = 1000*(x1-x0)

    aspect = abs(height/z)/abs(width/x)

    fig.shift_origin(xshift='0.5i',yshift='-1.1i')
    fig.basemap(region=[bounds[0],bounds[1],z0,z1],frame=['af','WSne','x+lDistance from Dome A origin (km)','y+lWGS 84 Elevation (m)'],projection=f'X{width}i/{height}i')
    pygmt.makecpt(cmap='gray',series='-130/-50/5',continuous=True)
    fig.grdimage(data,dpi='i')
    fig.text(position='TL',text=f'Transect {focus_line}',justify='TL',font='8p,white',offset='J0.1c')
    fig.text(position='BR',text=f'{aspect:.1f}x vertical exageration',justify='BR',font='8p,gray',offset='J0.1c')
    fig.text(x=800,y=1000,text=f'South Pole Basin',justify='MC',font='6p,Helvetica-Bold,ivory')
    fig.text(x=550,y=1500,text=f'Gambertsev Foothils',justify='MC',font='6p,Helvetica-Bold,ivory')

    fig.shift_origin(yshift='-0.05i')
    fig.plot(x=[x0,x1],y=[z0,z0],pen='1p,blue',no_clip=True)
    fig.plot(x=[x0],y=[z0],style='c0.25c',fill='blue',no_clip=True)
    fig.savefig(os.path.join(targ,'coldex_context_map.png'))

plot()


