#!/usr/bin/env python3

import argparse
import os
import numpy as np
from h5py import File
import pygmt #required GMT6.5

'''Converts Mouginot's 2019 phase interfometry Antarctic HDF5 velocity map into GIS friendly GeoTiff files'''

def read_and_write(data_dir='Mouginot2019'):
    print('converting Mouginot 2019 HDF5...')
    orig = os.getcwd().replace('code','orig')
    targ = os.getcwd().replace('code','targ')
    os.makedirs(os.path.join(targ,data_dir),exist_ok=True)

    print('reading')
    data = File(os.path.join(orig,data_dir,'antarctic_ice_vel_phase_map_v01.h5'),'r')

    print('getting x and y')
    x = data['x'][:]
    y = data['y'][:]

    print('meshing')
    xx, yy = np.meshgrid(x,y)

    print('unravelling')
    x_column = np.ravel(xx)
    y_column = np.ravel(yy)

    insar = {}

    region=[min(x),max(x),min(y),max(y)]
    spacing=(x[1] - x[0])

    for d in list(data.keys()):
        if d.isupper():
            print(d)
            outfile = os.path.join(targ,data_dir,f'{d}.tif=gd:GTiff')
            z = np.ravel(data[d][:,:])
            insar[d] = pygmt.xyz2grd(
                x=x_column,
                y=y_column,
                z=z,
                region=region,
                spacing=spacing)

            pygmt.xyz2grd(x=x_column,
                y=y_column,
                z=z,
                outgrid=outfile,
                region=region,
                spacing=spacing)

    insar['VELM'] = np.sqrt(insar['VX']**2 + insar['VY']**2)
    pygmt.grdsample(insar['VELM'],outgrid=os.path.join(targ,data_dir,f'VELM.tif=gd:GTiff'))
    return insar
    
def plot(insar):
    targ = os.getcwd().replace('code','targ')

    fig = pygmt.Figure()
    for name in insar.keys():
        print(name)
        print(pygmt.grdinfo(insar[name]))
        fig.grdimage(insar[name],projection='X5c/0',cmap='turbo',frame=["ag",f"wsne+t{name}"])
        fig.colorbar(position='JBC',frame='xa')
        fig.shift_origin(xshift='6c')
    fig.savefig(os.path.join(targ,'velocity_test.png'))

def main():
    targ = os.getcwd().replace('code','targ')
    parser = argparse.ArgumentParser(
		description='converts and plots the Mouginot 2019 phase interfometry Antarctic HDF5 velocity map')
    parser.add_argument('-d','--directory',default='Mouginot2019')
    parser.add_argument('--noconvert','-n',action='store_true')
    parser.add_argument('--plot','-p',action='store_true')
    args = parser.parse_args()

    if (not args.noconvert):
        insar = read_and_write(data_dir=args.directory)

    tif_dict = {}
    if args.plot:
        if args.noconvert:
            insar = {}
            print('plotting')
            tifs = os.listdir(os.path.join(targ,args.directory))
            for tif in tifs:
                print(tif)
                insar[tif.split('.')[0]] = os.path.join(targ,args.directory,tif)

        plot(insar)

if __name__ == "__main__":
    main()
    


	



