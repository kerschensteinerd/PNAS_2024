# -*- coding: utf-8 -*-
"""
Created on Wed Aug 26 20:08:08 2020

@author: KerschensteinerLab
"""

import pandas as pd
import numpy as np
from tkinter import filedialog, Tk
import os
from hunting_analysis_functions import *
#import cricket_hunting_analysis_dataframe as ck

#select h5 files and mp4 to analyze
#pathName = '//storage1.ris.wustl.edu/kerschensteinerd/Active/Jenna/ooDSGC_preyCapture/behavior/TrackedData/GRPCre_SC/GCaMP6s_GRPCre_tracked/JK484/tobetracked/JK474#1F'
#pathName = r'C:\Users\KerschensteinerD\Dropbox\Scripts\Python\behavior\prey_capture\for_jenna\sampleOutputFiles'
pathName = '/Users/danielkerschensteiner/Dropbox/Figures/2022/ds_pred/behavior/chat_dtr/acute/tracked_data/'
os.chdir(pathName)
root = Tk()
h5_file = filedialog.askopenfilename(parent=root,title='Choose .h5 file')
video_path = filedialog.askopenfilename(parent=root,title='Choose .mp4 file')
#These should rarely need to be changed


df = h5_to_df(h5_file, frame_rate=30)

#optional
df = interpolate_unlikely_label_positions(df, likelihood_cutoff = 0.9)
#########


df = adjust_label_positions(df, video_path)
#####
                 
save_path = get_save_path_csv(h5_file)
os.chdir(pathName)

df.to_csv(save_path)
root.destroy()