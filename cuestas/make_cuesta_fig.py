#!/usr/bin/env python3

from PIL import Image
Image.MAX_IMAGE_PIXELS = None

import numpy as np

from matplotlib import pyplot as plt
import matplotlib as mpl
mpl.use('Agg')

import os
import pandas as pd

def read_data(path,pst):
    file_path = os.path.join(path,'image',pst.replace('/','_') + '_image.jpg')
    meta_data_path = os.path.join(path,'metadata',pst.replace('/','_') + '_image.csv')
    print(file_path)
    if os.path.exists(file_path):
        img = np.array(np.asarray(Image.open(file_path)))[:,:,0]
    else:
        print('nope!')
        exit()
    if os.path.exists(meta_data_path):
        meta = pd.read_csv(meta_data_path)
    radar=140*(img.astype('float')-255)/256
    return radar, meta

def plot_data(img,ax,meta,pst,center=800,width=77,height=1000,title=None):
    print(f'plotting')
    x1=meta['Displayed_distance [km]'].iloc[0]
    x2=meta['Displayed_distance [km]'].iloc[-1]
    y1=meta['Elevation of image top [m]'].iloc[0]
    y2=meta['Elevation of image bottom [m]'].iloc[0]
    ax.imshow(img,cmap='bone_r',vmin=-130,vmax=-80,extent=(x1,x2,y2,y1),aspect='auto')
    ax.text(0,1,pst,color='blue',horizontalalignment='left',
                 verticalalignment='top', transform=ax.transAxes)
    print(center)
    display_x1 = center - width/2
    display_x2 = center + width/2
    display_y1 = -height
    display_y2 = 0
    ax.set_xlim(display_x1,display_x2)
    ax.set_ylim(display_y1,display_y2)
    x_scale = (1000*(display_x2-display_x1))/ax.bbox.width
    y_scale = ((display_y2-display_y1)/ax.bbox.height)
    print(x_scale/y_scale)
    ax.text(0,0,f'{x_scale/y_scale:.1f}x vertical exaggeration', horizontalalignment='left', verticalalignment='bottom', fontsize=6, color='ivory', transform=ax.transAxes)
    if title:
        ax.set_title(title)

    xy = {}
    
    min_easting = meta[meta['Displayed_distance [km]'].between(display_x1,display_x2)]['EPSG 3031 Easting [m]'].iloc[0]
    min_northing = meta[meta['Displayed_distance [km]'].between(display_x1,display_x2)]['EPSG 3031 Northing [m]'].iloc[0]
    max_easting = meta[meta['Displayed_distance [km]'].between(display_x1,display_x2)]['EPSG 3031 Easting [m]'].iloc[-1]
    max_northing = meta[meta['Displayed_distance [km]'].between(display_x1,display_x2)]['EPSG 3031 Northing [m]'].iloc[-1]

    return pd.DataFrame.from_dict({ 'Eastings':[ min_easting, max_easting ], 'Northings': [min_northing, max_northing] })

data = {}

mapping={
    'R60': 820,
    'R62': 820,
    'R64': 805,
    'R66': 790,
    'R68': 775,
    'R69': 767,
    'R70': 760,
    'R71': 753,
    'R72': 745,
    'R73': 750,
    'R74': 755,
    'R75': 755,
    'R76': 755,
    'R77': 745,
    'R78': 745,
    'R79': 745,
    'R80': 745
}

with open('pst_list.txt','r') as f:
    WAIS = os.environ['WAIS']
    for line in f.readlines():
        if line.strip() in ['CLX/R68b','CLX/R69a','CLX/R70b']:
            print(f'Loading {line.rstrip()}')
            img, meta = read_data(os.path.join(WAIS,'targ/comm/DATA-OPR/projected_images_COLDEX'),line.rstrip())
            data[line.strip()] = {'img':img,'meta':meta}
        else:
            continue

fig,axes = plt.subplots(len(data.keys()))


outdir = os.getcwd().replace('code','targ')
title="Dichotomy marked by upstream facing sharp cuestas\n(depth corrected radargrams, y-axis is elevation (m))"
for i,pst in enumerate(data.keys()):
    print(pst)
    for t in mapping.keys():
        if t in pst:
            center = mapping[t]
    xy = plot_data(data[pst]['img'],axes[i],data[pst]['meta'],pst,center=center,title=title,width=48)
    xy.to_csv(f'{outdir}/{pst.replace("/","_")}.cuesta.xy',sep='\t',index=False,header=False)
    title=None

plt.xlabel('Distance from radial origin (km)')    
plt.tight_layout()    

os.makedirs(outdir,exist_ok=True)
plt.savefig(f'{outdir}/cuestas.png',dpi=400,transparent=True)

