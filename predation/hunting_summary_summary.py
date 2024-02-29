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


def collect_rows_to_columns(path_name):
    
    files = glob.glob(path_name +'/**/*.csv', recursive = True)
    files.sort()
    
    for i in range(len(files)):
        df_trans = pd.read_csv(files[i])
        head, file_name = os.path.split(files[i])
        df_trans.set_index('trial_id', inplace=True)
        df_trans.drop(columns='Unnamed: 0', inplace=True)
        
        if i==0:           
            df = df_trans.transpose()

        else:
            df_curr = df_trans.transpose()
            target_col = df_curr.columns[0]
            df[target_col] = df_curr[target_col]
    
    return df


initial_dir = '/Users/danielkerschensteiner/Dropbox/Figures/2022/chat_dtr'
path_name = tk.filedialog.askdirectory(initialdir=initial_dir)

df_summary = collect_rows_to_columns(path_name)


with pd.ExcelWriter(path_name + '/summary.xlsx') as writer: #for density
    df_summary.to_excel(writer, sheet_name='summary')

