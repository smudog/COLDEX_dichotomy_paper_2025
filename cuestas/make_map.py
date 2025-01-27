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
    z = radar.flatten


    metadata_path=os.path.join(path,'image',f'{transect.replace("/","_")}_image.csv')
    metadata=pd.read_csv(os.path.join(path,'metadata',f'{transect.replace("/","_")}_image.csv'))
    x0=metadata['Displayed_distance [km]'].iloc[0]
    x1=metadata['Displayed_distance [km]'].iloc[-1]
    y0=metadata['Elevation of image bottom [m]'].iloc[0]
    y1=metadata['Elevation of image top [m]'].iloc[0]
    region=[x0,x1,y0,y1]

    x_vals = np.linspace(x0, x1, ncols)
    y_vals = np.linspace(y0, y1, nrows)

    X, Y = np.meshgrid(x_vals, y_vals)

    xyz_table = np.column_stack((X.ravel(), Y.ravel(), radar.ravel()))

    radar_grd = pygmt.xyz2grd(xyz_table,region=region)
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

    pygmt.config(MAP_FRAME_TYPE='plain',FONT_ANNOT_PRIMARY='8p')
    fig = pygmt.Figure()
    pygmt.makecpt(cmap="oslo", series=[0, 4000])
    #fig.grdimage(raster, projection="X2.5i/0",region=region,shading="+d") 
    #fig.shift_origin(xshift="2.5i",yshift='1i')
    fig.basemap(frame='btlr+gsnow',region=region_km,projection="X2.5i/0")
    fig.grdcontour(grid=raster,region=region,projection="X2.5i/0",annotation=100,levels=10,pen='0.25p,gray')
    for transect in transects.keys():
        x = transects[transect]['EPSG 3031 Easting [m]']
        y = transects[transect]['EPSG 3031 Northing [m]']
        fig.plot(x=x,y=y,pen='0.5p,dimgray')

    fig.plot(x=transects['CLX/R66a']['EPSG 3031 Easting [m]'],y=transects['CLX/R66a']['EPSG 3031 Northing [m]'],pen='0.5p,blue')
    fig.basemap(frame=['af','wsNE'],region=region_km)
 
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
        fig.plot(x=x,y=y,pen='0.25p,dimgray')
    
    fig.text(x=123.33,y=-75.1,text='Dome C',justify='BL',font='8p',D='J0.1c+v')
    fig.text(x=77.33,y=-80.33,text='Dome A',justify='BL',font='8p',D='J0.1c+v')
    fig.text(x=0,y=-90,text='South Pole',justify='BR',font='8p',D='J0.1c+v')
    fig.text(x=166.67,y=-77.83,text='McMurdo',justify='TR',font='8p',D='J0.1c+v')

    data,bounds=read_radargram(os.path.join(WAIS,'targ/comm/DATA-OPR/projected_images_COLDEX'),'CLX/R66a')

    fig.shift_origin(yshift='-2i')
    fig.basemap(region=bounds,frame=['af','WSne'],projection='X-5i/1i')
    fig.grdimage(data,cmap='bone')




    fig.savefig(os.path.join(targ,'test.png'))

plot()


