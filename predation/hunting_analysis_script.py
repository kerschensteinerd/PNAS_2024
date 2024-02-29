# -*- coding: utf-8 -*-
"""
Created on Wed Aug 26 20:23:40 2020

@author: KerschensteinerLab
"""

import pandas as pd
import numpy as np
import tkinter
from tkinter import filedialog, Tk
import os
# import matplotlib 
# matplotlib.use('TkAgg') # GUI backend 
# %matplotlib auto
import matplotlib.pyplot as plt
from hunting_analysis_functions import *
#import cricket_hunting_analysis_dataframe as ck

root = Tk()
video_path = filedialog.askopenfilename(parent=root,title='Choose .mp4 file')
h5_file = filedialog.askopenfilename(parent=root,title='Choose .h5 file')
df_path = filedialog.askopenfilename(parent=root,title='Choose _Analysis .csv file')

df = pd.read_csv(df_path)

if 'Unnamed: 0' in df.columns:
    df.drop(columns=['Unnamed: 0'], inplace=True)

os.chdir(os.path.dirname(os.path.abspath(video_path)))

corners = select_arena_manual(video_path, frame_number = 0)
cm_per_pixel = pixel_size_from_arena_coordinates(corners, arena_size_x = 45, arena_size_y = 38)
#cm_per_pixel = 0.31984778911564626
print(cm_per_pixel)

#check frame rates for different weeks varies btw 25 and 30
frame_rate = 30######################
######################################

speed_threshold = 10
contact_distance = 4
windowSize = 8
diff_frames= 4
diff_speed= -20
body_azimuth = 60 #abs threshold of body axis rel to cricket for approach determined by proportions of the box
max_dist = 19 #maximal distance from border in cm
bin_size = 1 #bin size for calculating distributions in cm
y_size = 38 #y-size of the arena in cm
x_size = 45 #x_size of the arena in cm
bin_num  = 20
bin_range = [[0, 38], [0, 45]]
#bin_range = [[0, 45], [0, 38]]
azimuth_bin_size = 5 #bin size for azimuth distribution in degrees
azimuth_range = [-180, 180]
max_dist_azimuth = 5 #distance cutoff for calculating azimuth according to Hoy (2019)

### compute paramaters for main analysis dataframe = df

#df = select_capture_frame_manual(df, video_path)
capture_frame = int(input("Enter capture frame number: "))
df = set_capture_frame(df, capture_frame)
df = calculate_head(df)
df = get_azimuth_head(df)
df = get_azimuth_body(df)
df = get_distance_to_cricket(df, cm_per_pixel)
df = get_mouse_speed(df, frame_rate, cm_per_pixel, smooth_frames=15, smooth_order=3)
df = get_cricket_speed(df, frame_rate, cm_per_pixel, smooth_frames=15, smooth_order=3)
df = get_mouse_acceleration(df, smooth_frames=29, smooth_order=3)
df = get_contacts(df, contact_distance)
df = smooth_contacts(df, windowSize =windowSize/2)
df = get_approaches(df, speed_threshold, diff_frames=diff_frames, diff_speed=diff_speed, frame_rate=frame_rate, body_azimuth=body_azimuth)
df = smooth_approaches(df, windowSize = windowSize)
#df = remove_short_approaches(df, min_approach_frames = 8, min_approach_length= 5, min_approach_distance = 5)


### no approach while contact
df['approach'][df['contact'] == 1] = 0
#df=get_pre_approaches(df,to_capture_time=True)
#df=get_pre_contacts(df,to_capture_time=True)

# projective transformation of mouse and cricket positions
target_corners = np.array([[0, 0], [x_size, 0], [0, y_size], [x_size, y_size]])

mouse_points = np.array((df['mid_x'],df['mid_y']))
mouse_adjusted = affine_transform(corners, target_corners, mouse_points)
df[['madj_x', 'madj_y']] = pd.DataFrame(np.transpose(mouse_adjusted))

cricket_points = np.array((df['cricket_x'],df['cricket_y']))
cricket_adjusted = affine_transform(corners, target_corners, cricket_points)
df[['cadj_x', 'cadj_y']] = pd.DataFrame(np.transpose(cricket_adjusted))

df = get_azimuth_head_arena(df)
df = get_azimuth_body_arena(df)

borders = get_borders(target_corners, pts_per_border=1000)
df = get_distance_to_borders(df, borders)
df = get_distance_path_to_borders(df, borders, n_samples=100)
df = add_corners(df, corners)

### compute distributions (rel to border) for dataframe = df_distribution
dist_bins = np.linspace(0, max_dist, round(max_dist/bin_size)+1)
df_distribution = get_distribution(df, dist_bins, to_capture_time=True)

### compute density for dataframe = df_density
df_density = get_density(df, bin_num, bin_range, to_capture_time=True)

### compute azimuth histograms for dataframe = df_azimuth
azimuth_bins = np.linspace(azimuth_range[0],azimuth_range[1],int((np.round(np.diff(azimuth_range)/azimuth_bin_size)+1)))
df_azimuth = get_azimuth_hist(df, azimuth_bins, max_dist_azimuth, to_capture_time=True)



### plot some results
#plot_hunt(df,cm_per_pixel=cm_per_pixel, to_capture_time=True, video_path=video_path, save_fig=True)
plot_hunt(df, to_capture_time=True, video_path=video_path, save_fig=True)
plot_approaches(df, to_capture_time=True, video_path=video_path, save_fig=True)
plot_speeds_and_distance(df, mouse=True, cricket=True, to_capture_time=True, contact_distance=contact_distance, video_path=video_path, save_fig=True)
plot_azimuth_hist(df, n_bins = 20, approach_only=True, video_path=video_path, save_fig=True)


### annotate results in videos
#annotate_video(df, video_path,fps_out=30, to_capture_time = False, show_time = True, label_bodyparts = False, show_approaches = True, show_approach_number = True, show_contacts = True, show_contact_number = True, show_azimuth = True, show_azimuth_lines = True, save_video = False, show_video = True, border_size = 40, show_distance=True, show_speed=True)

#add distance to video, change to single line from mid

annotate_video(df, video_path, fps_out=10, to_capture_time=True, show_time=True, show_borders=True, label_bodyparts=True, show_approaches=True, show_approach_number=True, show_contacts=True, show_contact_number=True, show_azimuth=True, show_azimuth_lines=True, save_video=True, show_video=False, border_size=40, show_distance=True, show_speed=True, video_path_ext='_annotated_slow')
#save_normal
#annotate_video(df, video_path, fps_out=30, to_capture_time = False, show_time = True, label_bodyparts = False, show_approaches = True, show_approach_number = True, show_contacts = True, show_contact_number = True, show_azimuth = True, show_azimuth_lines = True, save_video = True, show_video = True, border_size = 40, show_distance=True, show_speed=True)
# remove approaches while in contact
# reduce contact window

#save DFs
trial_id = video_path.split('/')[-1].split('.')[-2]
condition = "WT"
summary_df = summarize_df(df, trial_id=trial_id, condition=condition)

save_path = get_save_path_csv(h5_file)
df.to_csv(save_path)

save_path_summary = get_save_path_csv_summary(h5_file)
summary_df.to_csv(save_path_summary)

save_path_distribution = get_save_path_csv_distribution(h5_file)
df_distribution.to_csv(save_path_distribution)

save_path_density = get_save_path_csv_density(h5_file)
df_density.to_csv(save_path_density)

save_path_azimuth = get_save_path_csv_azimuth(h5_file)
df_azimuth.to_csv(save_path_azimuth)


root.destroy()
