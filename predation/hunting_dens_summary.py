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
ind_col=0 #for density

df_mouse = collect_columns(path_name, ind_col, target_col='mouse')
df_cricket = collect_columns(path_name, ind_col, target_col='cricket')
df_mouse_approach = collect_columns(path_name, ind_col, target_col='mouse_approach')
df_cricket_approach = collect_columns(path_name, ind_col, target_col='cricket_approach')
df_mouse_contact = collect_columns(path_name, ind_col, target_col='mouse_contact')
df_cricket_contact = collect_columns(path_name, ind_col, target_col='cricket_contact')
df_mouse_approach_contact = collect_columns(path_name, ind_col, target_col='mouse_approach_contact')
df_cricket_approach_contact = collect_columns(path_name, ind_col, target_col='cricket_approach_contact')


with pd.ExcelWriter(path_name + '/density.xlsx') as writer: #for density
    df_mouse.to_excel(writer, sheet_name='mouse')
    df_cricket.to_excel(writer, sheet_name='cricket')
    df_mouse_approach.to_excel(writer, sheet_name='mouse_approach')
    df_cricket_approach.to_excel(writer, sheet_name='cricket_approach')
    df_mouse_contact.to_excel(writer, sheet_name='mouse_contact')
    df_cricket_contact.to_excel(writer, sheet_name='cricket_contact')
    df_mouse_approach_contact.to_excel(writer, sheet_name='mouse_approach_contact')
    df_cricket_approach_contact.to_excel(writer, sheet_name='cricket_approach_contact')

