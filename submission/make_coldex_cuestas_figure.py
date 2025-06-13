#!/usr/bin/env python3

import os 
import io
import pygmt
import xarray as xr
from PIL import Image
Image.MAX_IMAGE_PIXELS = None
import rioxarray as rxa
import numpy as np
import pandas as pd
import re
from netCDF4 import Dataset
from h5py import File


def read_grd(path):
    # Load the GeoTIFF file as an xarray DataArray
    raster = rxa.open_rasterio(path)
    return raster.sel(band=1)

def read_nc(path,pst,x0=0,x1=0):
    ds = Dataset(os.path.join(path,f'{pst.replace("/","_")}_dd_analysis.nc'),'r',format="NETCDF4")
    fast_time = ds['channels'].variables['fast_time'][:]
    apertures = ds['channels'].variables['normalized_max_in_bin'].shape[0]

# Extract variables
    data = ds.groups["channels"].variables["normalized_max_in_bin"][:]  # Shape (aperture, fast_time, direction)
    ds.close()


# Extract the three directions as RGB channels
    r = ((data[:, :, 0] + data[:, :, 1]))/2 # Red channel
    g = r  # Green channel
    b = data[:, :, 2]  # Blue channel


# Stack into an RGB image (PyGMT expects a grid, so we reshape as needed)
    rgb = np.stack([r, g, b], axis=-1)  # Shape (aperture, fast_time, 3)

# Normalize the data for RGB - controls contrast
    rgb = rgb / 20 
    rgb = np.clip(rgb, a_min=0, a_max=1)
    rgb = (rgb * 255).astype('uint8')

# Convert to xarray DataArray for PyGMT compatibility
    rgb_xr = xr.DataArray(np.transpose(rgb), dims=["band","y", "x"])

    distance = np.arange(0,apertures,1)/20

    if x0 > x1:
        distance = distance[::-1] + min([x0,x1])
        rgb_xr[:,:,::-1]
    else:
        distance = distance + min([x0,x1])
    print(distance)

    #rgb_xr = rgb_xr.copy().assign_coords({"y": (0.2*np.flipud(fast_time))})
    rgb_xr.coords["y"] = ("y", 1e6 * fast_time/2)
    rgb_xr = rgb_xr.assign_coords(y=rgb_xr.y[::-1])
    rgb_xr = rgb_xr[:, ::-1, :]
    rgb_xr.coords["x"] = ("x", distance)

    return rgb_xr

def read_layer(path,flight='A10B',origin_x=964892.757,origin_y=384953.176):
    data = pd.read_csv(path,comment='#')
    data['Distance'] = (np.sqrt((data['projection_x_coordinate (m)']-origin_x)**2 + (data['projection_y_coordinate (m)']-origin_y)**2))/1000
    return data[data['trajectory_id'].str.contains(flight)]

def read_radargram(path,transect):
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
    region=[min([x0,x1]),max([x0,x1]),y0,y1]


    XYD = metadata[['EPSG 3031 Easting [m]','EPSG 3031 Northing [m]','Displayed_distance [km]']]

    x_spacing = abs((x1 - x0)/ncols)
    y_spacing = abs((y1 - y0)/nrows)

    x_vals = np.linspace(x0, x1, ncols)
    y_vals = np.linspace(y1, y0, nrows)

    X, Y = np.meshgrid(x_vals, y_vals)

    xyz_table = np.column_stack((X.ravel(), Y.ravel(), radar.ravel()))

    radar_grd = pygmt.xyz2grd(xyz_table,region=region,spacing=f'{x_spacing}/{y_spacing}')
    return radar_grd, region, XYD

def get_bounds(line,length=45):

    mapping={
        'R60': (820,0),
        'R62': (820,0),
        'R64': (805,0),
        'R66': (790,0),
        'R68': (775,773),
        'R69': (767,760),
        'R70': (760,765),
        'R71': (753,0),
        'R72': (745,0),
        'R73': (750,0),
        'R74': (755,0),
        'R75': (755,755),
        'R76': (755,0),
        'R77': (745,0),
        'R78': (745,0),
        'R79': (745,0),
        'R80': (745,0)
    }
    
    for t in mapping.keys():
        if t in line:
            print(line)
            center =  mapping[t][0]
            x0 = center - length/2
            x1 = center + length/2
            bnd = mapping[t][1]
            return x0, x1, bnd
    return None, None, None


def plot(targ=os.getcwd().replace('code','targ'),orig=os.getcwd().replace('code','orig')):
    origin_x=964892.757
    origin_y=384953.176

    lines=['CLX/R68b','CLX/R69a','CLX/R70b']

    bas_flight='A10B'

    os.makedirs(targ,exist_ok=True)

    pygmt.config(MAP_FRAME_TYPE='plain',FONT_ANNOT_PRIMARY='8p',FONT_LABEL='8p',PS_LINE_JOIN='round')
    fig = pygmt.Figure()

    z0=-1000
    z1=500

    height=0.44
    #height=0.66
    width=-4
    pygmt.makecpt(cmap='gray',series='-135/-100/5',continuous=True)

# Make fractional layer depth profile
    sanderson_path = os.path.join(orig,'Sanderson_2023')

    ea_h1 = read_layer(os.path.join(sanderson_path,'EA_H1_38ka.csv'),flight=bas_flight,origin_x=origin_x,origin_y=origin_y)
    ea_h2 = read_layer(os.path.join(sanderson_path,'EA_H2_90ka.csv'),flight=bas_flight,origin_x=origin_x,origin_y=origin_y)
    ea_h3 = read_layer(os.path.join(sanderson_path,'EA_H3_162ka.csv'),flight=bas_flight,origin_x=origin_x,origin_y=origin_y)


# make Delay Doppler profile
    dd_transect = 'CLX/R66a'
    dd_full_transect = f'{dd_transect.split("/")[0]}_MKB2o_{dd_transect.split("/")[1]}'
    data, bounds, xyd = read_radargram(os.path.join(orig,'projected_images_COLDEX'),dd_transect)

    DelayDoppler_path=os.path.join(orig,'DelayDoppler')
    dd = read_nc(DelayDoppler_path,dd_full_transect,x0=bounds[0],x1=bounds[1])
    spec = pd.read_csv(os.path.join(DelayDoppler_path,f'{dd_full_transect}_specularity.gmt'),sep='\t')
    spec['distance'] = np.sqrt((spec['x'] - origin_x)**2 + (spec['y'] - origin_y)**2)/1000
    df = spec[['x','y','distance']]


# plot Delay Doppler profile
    #fig.grdimage(dd,region=[740,840,30,55],projection=f'X{width}i/-{height*2}i')

    region=[550,850,10,55]

    fig.basemap(region=region,projection=f'X{width}i/-{height*2}i',frame=['af','WSne','y+ldelay (µsec)'])

    fig.plot(x=region[0],y=region[2]-10,direction=[0,10],style='v0.4i+e+h0+a30+gdodgerblue+p1p,dodgerblue',no_clip=True,pen='8p,dodgerblue')
    fig.text(x=region[0],y=region[2]-10,text='Ice Flow direction',font='6p,Helvetica-Bold,white',no_clip=True,justify='MR',offset='j1i')

    fig.plot(x=region[0],y=region[2],style='s0.25c',pen='0.5p,black',fill='blue',label='Specular echoes')
    fig.plot(x=region[0],y=region[2],style='s0.25c',pen='0.5p,black',fill='yellow',label='Scattered echoes')
    fig.plot(x=region[0],y=region[2],style='s0.25c',pen='0.5p,black',fill='gray',label='Mixed echoes')
    fig.grdimage(dd)

    fig.plot(x=[784,784],y=[20,40],pen='1p,ivory,dotted')
    fig.text(x=784,y=20,text='dichotomy',justify='TL',offset='j0.1c',font='6p,Helvetica-Bold,ivory')
    fig.text(x=660,y=35,text='basal unit',justify='BR',offset='j0.3c+v0.25p,ivory',font='6p,Helvetica-Bold,ivory')
    fig.text(x=785,y=52,text='cuesta',justify='TC',offset='j0.01c+v0.25p,ivory',font='6p,Helvetica-Bold,ivory')
    fig.text(x=810,y=48,text='Elbow Complex',justify='BC',offset='j0.4c+v0.25p,ivory',font='6p,Helvetica-Bold,ivory')

    fig.plot(x=spec['distance'],y=spec['base_specular[s]']*1e6,pen='1p,white,dotted')
    fig.text(position='TL',justify='TL',fill='white',pen='0.25p,black',clearance='+tO',offset='J0.1c',text=f'a) {dd_transect} Delay Doppler color composite',font='8p,black')

    pygmt.config(FONT_ANNOT_PRIMARY='6p,black')
    fig.legend(position=f'jTR')
    pygmt.config(FONT_ANNOT_PRIMARY='8p,Helvetica,black')

    fig.shift_origin(yshift=f'{-(2*height+height/2)}i')

# Plot fractional layer depth profile
    region_layers = [ 667, 867, 15, 85 ] 
    text_x = 800

    fig.basemap(frame=['tblr'], region=region_layers, projection=f'X{width}i/-{2*height}i')
    fig.plot(x=ea_h1['Distance'], y=ea_h1['fraction_depth']*100, pen='1p,darkblue')
    text_y = ea_h1[ea_h1['Distance'] < text_x]['fraction_depth'].iloc[0] * 100
    fig.text(x=text_x,y=text_y,justify='CM',fill='white',pen='0.25p,darkblue',clearance='+tO',text='H1 (38 ka) horizon',font='6p,darkblue')

    fig.plot(x=ea_h2['Distance'], y=ea_h2['fraction_depth']*100, pen='1p,blue')
    text_y = ea_h2[ea_h2['Distance'] < text_x]['fraction_depth'].iloc[0] * 100
    fig.text(x=text_x,y=text_y,justify='CM',fill='white',pen='0.25p,blue',clearance='+tO',text='H2 (90 ka) horizon',font='6p,blue')

    fig.plot(x=ea_h3['Distance'], y=ea_h3['fraction_depth']*100, pen='1p,lightblue')
    text_y = ea_h3[ea_h3['Distance'] < text_x]['fraction_depth'].iloc[0] * 100
    fig.text(x=text_x,y=text_y,justify='CM',fill='white',pen='0.25p,lightblue',clearance='+tO',text='H3 (162 ka) horizon',font='6p,lightblue')

    fig.text(position='TL',justify='TL',fill='white',pen='0.25p,black',clearance='+tO',offset='J0.1c',text=f'b) AGAP Flight {bas_flight} Horizon Fractional Depth',font='8p,black')
    fig.basemap(frame=['WSne','af','y+l% depth'])


# plot radargrams
    fig.shift_origin(yshift=f'{-(1.5*height+height/2)}i')
    for i,line in enumerate(lines):
        labels = ['c','d','e']
        x0, x1, bnd = get_bounds(line)
        region=[x0,x1,z0,z1]

        fig.basemap(frame=['tblr'], region=region, projection=f'X{width}i/{1.5*height}i')

        data, bounds, xyd = read_radargram(os.path.join(orig,'projected_images_COLDEX'),line)

        xyd_displayed = xyd[xyd['Displayed_distance [km]'].between(x0,x1,inclusive='both')].copy()
        xyd_displayed.drop(columns=['Displayed_distance [km]'],inplace=True)
        xyd_displayed.to_csv(os.path.join(targ,f'{line.replace("/","_")}.cuestas.xy'),header=False,index=False,sep='\t')

        fig.grdimage(data)

        z = z1 - z0
        x = 1000*(x1-x0)
        aspect = abs(1.5*height/z)/abs(width/x)

        fig.text(position='TL',text=f'{labels[i]}) {line}',justify='TL',font='8p,black',fill='white',pen='0.25p,black',offset='J0.1c')
        fig.text(position='BR',text=f'{aspect:.1f}x vertical exageration',justify='BR',font='8p,gray',offset='J0.1c')
        
        if bnd:
            fig.plot(x=[bnd,bnd],y=[-200,450],pen='1p,ivory,dotted')
            fig.text(x=bnd,y=450,text='dichotomy',justify='TL',offset='j0.1c',font='6p,Helvetica-Bold,ivory')

        if i == 1:
            fig.basemap(frame=['WSne','xaf','ya500f+lWGS-84 Elevation (m)'])
            fig.text(x=775,y=-750,text='lineations',justify='BC',offset='j0.4c+v0.25p,ivory',font='6p,Helvetica-Bold,ivory')
        else:
            fig.basemap(frame=['WSne','xaf','ya500f'])

        fig.shift_origin(yshift=f'{-(1.5*height+height/2)}i')

    fig.shift_origin(yshift=f'{(1.5*height+height/2)}i')
    fig.basemap(frame=['x+lDistance from Dome A origin (km)'])
    fig.savefig(os.path.join(targ,'coldex_cuestas.png'),dpi=300)

plot()


