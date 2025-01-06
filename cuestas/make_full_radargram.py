#!/usr/bin/env python3

import matplotlib as mpl
mpl.use('Agg')
import os
import numpy as np
from PIL import Image
Image.MAX_IMAGE_PIXELS = None
import pandas as pd
import matplotlib.patches as patches
from matplotlib import pyplot as plt


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

def read_bas_data(bas_path):
    return 

def vertical_exaggeration(ax):
    # Get the axis limits in data coordinates
    xlim = ax.get_xlim()
    ylim = ax.get_ylim()
    
    # Calculate the aspect ratio in data coordinates
    data_aspect_ratio = (xlim[1] - xlim[0]) * 1000 / (ylim[1] - ylim[0])
    
    # Get the bounding box of the axis in figure coordinates
    bbox = ax.get_window_extent().transformed(ax.figure.dpi_scale_trans.inverted())
    width, height = bbox.width, bbox.height
    
    # Calculate the aspect ratio in figure coordinates
    fig_aspect_ratio = width / height
    
    # Calculate vertical exaggeration
    vert_exag = data_aspect_ratio / fig_aspect_ratio
    
    return vert_exag

def set_axis_color(ax, color):
    """Set the color for spines, ticks, and labels on a given axis."""
    # Set spines (frame) color
    for spine in ax.spines.values():
        spine.set_color(color)
    
    # Set ticks color
    ax.tick_params(axis='both', colors=color)
    
    # Set labels and title color
    ax.xaxis.label.set_color(color)
    ax.yaxis.label.set_color(color)
    ax.title.set_color(color)

def plot_data(radar,meta,pst):
    image_top = meta['Elevation of image top [m]'].iloc[0]
    image_bottom = meta['Elevation of image bottom [m]'].iloc[-1]
    image_start = meta['Displayed_distance [km]'].iloc[0]
    image_end = meta['Displayed_distance [km]'].iloc[-1]

    #fig,axes = plt.subplots(2,figsize=(7.48, 5))
    fig,axes = plt.subplots(2,figsize=(9, 5))

    outfile = pd.DataFrame()

    outfile['x'] = meta['EPSG 3031 Easting [m]'][::10]
    outfile['y'] = meta['EPSG 3031 Northing [m]'][::10]

    extent = (image_start,image_end,image_bottom,image_top)
    axes[0].imshow(radar, cmap='bone_r', vmin=-130,vmax=-60, extent=extent, aspect='auto')
    axes[0].set_title(f"a) MARFA radargram from radial survey line {pst}", horizontalalignment='left', x=-0)
    axes[0].set_ylim(-1100,3800)
    axes[0].set_ylabel('Elevation (m, WGS-84)')
    axes[0].text(790,-1000,"South Pole Basin",color='black',fontsize=8, horizontalalignment='center')
    axes[0].text(axes[0].get_xlim()[0],-500,"< Gambertsev Subglacial Mountains",color='black',fontsize=8,horizontalalignment='left')
    axes[0].text(650,3750,"< Dome A",color='black',fontsize=8,horizontalalignment='center',verticalalignment='top')

    zoom_x1 = 400
    zoom_x2 = 475
    zoom_y1 = 0
    zoom_y2 = 1500
    rect1 = patches.Rectangle((zoom_x1, zoom_y1), (zoom_x2-zoom_x1), (zoom_y2-zoom_y1), linewidth=1, edgecolor='gold', facecolor='none')
    rect2 = patches.Rectangle((zoom_x1, zoom_y1), (zoom_x2-zoom_x1), (zoom_y2-zoom_y1), linewidth=5, edgecolor='gold', facecolor='none',zorder=10)

    axes[0].add_patch(rect1)

    axes[1].imshow(radar, cmap='bone_r', vmin=-130,vmax=-60, extent=extent, aspect='auto')
    axes[1].set_xlim(zoom_x1,zoom_x2)
    axes[1].set_ylim(zoom_y1,zoom_y2)
    axes[1].text(430,500,"basal unit",color='black')
    axes[1].text(433,1300,"stratigraphic ice",color='black')
    axes[1].text(415,200,"bedrock",color='black')
    axes[0].set_ylabel('Elevation (m, WGS-84)')
    axes[1].add_patch(rect2)
    axes[1].set_title(f"b) Zoom in on basal region of ice sheet", horizontalalignment='left', x=-0)
    for spine in axes[1].spines.values():
            spine.set_zorder(5)

    axes[1].set_xlabel('Distance from radial origin (km)')

    plt.tight_layout()

    vert_exag0 = vertical_exaggeration(axes[0])
    vert_exag1 = vertical_exaggeration(axes[1])
    axes[0].text(0.01,0.03,f"{vert_exag0:.1f}x vertical exaggeration",
            horizontalalignment='left',verticalalignment='bottom',
            transform=axes[0].transAxes,
            fontsize=6, color='gray')
    axes[1].text(0.01,0.03,f"{vert_exag1:.1f}x vertical exaggeration",
            horizontalalignment='left',verticalalignment='bottom',
            transform=axes[1].transAxes,
            fontsize=6, color='gray')

    set_axis_color(axes[0], 'ivory')
    set_axis_color(axes[1], 'ivory')

    outdir = os.getcwd().replace('code','targ')
    os.makedirs(outdir,exist_ok=True)
    plt.savefig(f'{outdir}/{pst.replace("/","_")}.png',dpi=400,transparent=True)

    outfile.to_csv(f'{outdir}/{pst.replace("/","_")}.xy',sep='\t',index=False,header=False,na_rep="nan")

pst = 'CLX/R66a'

radar,meta = read_data('/disk/kea/WAIS/targ/comm/DATA-OPR/projected_images_COLDEX',pst)

plot_data(radar,meta,pst)
#for column in list(meta.columns):
#    print(column)
