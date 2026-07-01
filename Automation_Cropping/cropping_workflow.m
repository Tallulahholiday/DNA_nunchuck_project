% cropping_workflow.m
% One place to run the full nunchuck flag -> inspect -> crop pipeline.
% Change file_name below (base name, NO extension) and run this file.

clear; clc; close all;

%% ------------- set the movie here -------------
file_name = '260302_bub2_NaCl500mM_9@0001';   % <-- change per movie (no .tif)
fname     = strcat(file_name, '.tif');

%% ------------- 1. auto-flag candidate bad frames -------------
% flags frames where two molecules get too close OR a molecule suddenly jumps
% (blurry smears), padded by +/- Pad frames.
bad0 = flag_close_molecules(fname, 'Pad', 5);

%% ------------- 2. confirm by eye -------------
% accept/reject each flagged clip; returns the confirmed frames and also saves
% <file_name>_bad_frames.mat for reuse.
bad = inspect_bad_frames(fname, bad0);

%% ------------- 3. track + crop -------------
% blanks the confirmed bad frames in the cropped output.
% (r260626_crop sounds play_sound.m when it finishes)
r260626_crop(file_name, bad, 0.94, 50);

%% ------------- 4. quick post-crop check -------------
% fast, small-window skim through the CROPPED movie (whole thing, in chunks)
% to confirm the crop is centered and nothing got clipped or mis-blanked.
cropped_fname = strcat(file_name, '_cropped.TIFF');
inspect_cropped_movie(cropped_fname);
