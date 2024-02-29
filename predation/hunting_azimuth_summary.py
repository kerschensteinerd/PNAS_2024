#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Jan 23 08:26:03 2022

@author: danielkerschensteiner
"""

import numpy as np
import pandas as pd
import tkinter as tk
import tkinter.filedialog
import glob
import os


def collect_columns(path_name, ind_col, target_col):
    
    files = glob.glob(path_name +'/**/*.csv', recursive = True)
    files.sort()
    
    for i in range(len(files)):
        df_trans = pd.read_csv(files[i])
        head, file_name = os.path.split(files[i])
        
        if ind_col==0:
            if i==0:
                df = pd.DataFrame(np.array(df_trans[target_col]), columns=[target_col])
            else:
                df[target_col] = np.array(df_trans[target_col])
        
        else:        
            if i==0:
                df = df_trans[[ind_col, target_col]].copy()
                df.set_index(ind_col, inplace=True)            
            else:
                df[target_col] = np.array(df_trans[target_col])
        
        df.rename(columns={target_col: file_name}, inplace=True)
    
    return df


initial_dir = '/Users/danielkerschensteiner/Dropbox/Figures/2022/chat_dtr'
path_name = tk.filedialog.askdirectory(initialdir=initial_dir)
ind_col = 'azimuth_angle'

df_azimuth_head_explore = collect_columns(path_name, ind_col, target_col='azimuth_head_explore')
df_azimuth_body_explore = collect_columns(path_name, ind_col, target_col='azimuth_body_explore')
df_azimuth_head_approach = collect_columns(path_name, ind_col, target_col='azimuth_head_approach')
df_azimuth_body_approach = collect_columns(path_name, ind_col, target_col='azimuth_body_approach')
df_azimuth_head_contact = collect_columns(path_name, ind_col, target_col='azimuth_head_contact')
df_azimuth_body_contact = collect_columns(path_name, ind_col, target_col='azimuth_body_contact')
df_azimuth_head_approach_contact = collect_columns(path_name, ind_col, target_col='azimuth_head_approach_contact')
df_azimuth_body_approach_contact = collect_columns(path_name, ind_col, target_col='azimuth_body_approach_contact')
df_azimuth_head_max_dist = collect_columns(path_name, ind_col, target_col='azimuth_head_max_dist')
df_azimuth_body_max_dist = collect_columns(path_name, ind_col, target_col='azimuth_body_max_dist')


with pd.ExcelWriter(path_name + '/azimuth.xlsx') as writer: #for density
    df_azimuth_head_explore.to_excel(writer, sheet_name='azimuth_head_explore')
    df_azimuth_body_explore.to_excel(writer, sheet_name='azimuth_body_explore')
    df_azimuth_head_approach.to_excel(writer, sheet_name='azimuth_head_approach')
    df_azimuth_body_approach.to_excel(writer, sheet_name='azimuth_body_approach')
    df_azimuth_head_contact.to_excel(writer, sheet_name='azimuth_head_contact')
    df_azimuth_body_contact.to_excel(writer, sheet_name='azimuth_body_contact')
    df_azimuth_head_approach_contact.to_excel(writer, sheet_name='azimuth_head_approach_contact')
    df_azimuth_body_approach_contact.to_excel(writer, sheet_name='azimuth_body_approach_contact')
    df_azimuth_head_max_dist.to_excel(writer, sheet_name='azimuth_head_max_dist')
    df_azimuth_body_max_dist.to_excel(writer, sheet_name='azimuth_body_max_dist')

