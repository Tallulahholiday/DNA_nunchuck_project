function r260626_crop(file_name, bad, p_cutoff, jump_thresh)
% R260626_CROP  Hand-assisted centroid tracking + crop of a nunchuck movie.
%   r260626_crop(file_name)       loads confirmed bad frames from
%                                 <file_name>_bad_frames.mat (from inspect_bad_frames)
%   r260626_crop(file_name, bad)  uses the bad-frame vector you pass in
%   r260626_crop(file_name, bad, p_cutoff, jump_thresh)
%       jump_thresh: when the AUTO-tracked centroid jumps more than this many
%       px between consecutive frames, pop up a click window so a human
%       reselects the center for that frame (catches mistracks the automatic
%       nearest-neighbor logic would otherwise silently accept).
% file_name is the base name WITHOUT extension, e.g. '260302_bub2_NaCl500mM_4@0001'.
% Called by cropping_workflow.m, or run standalone.

%% ---------------- parameters ----------------
fname      = strcat(file_name, '.tif');    % read the ORIGINAL directly (no copy_ file)

% --- on-the-fly preprocessing (replaces the manual copy_ step) ---
% These are applied in-memory to each frame, for DETECTION ONLY.
% Cropping still uses the untouched original frames.
% Set these to match whatever you used when making the copy_ file.
gauss_sigma = 2;            % Gaussian blur sigma (imgaussfilt)
adjust_in   = [0.0 0.3];    % imadjust input range (low high), normalized 0-1
adjust_out  = [0.0 1.0];    % imadjust output range
adjust_gamma = 1;           % imadjust gamma (<1 brightens dim features)
preprocess = @(im) imadjust(imgaussfilt(im, gauss_sigma), adjust_in, adjust_out, adjust_gamma);

% --- bad frames from the flag -> inspect pipeline ---
% If not passed in, load the confirmed list saved by inspect_bad_frames.
if nargin < 2
    bad_mat = strcat(file_name, '_bad_frames.mat');
    if isfile(bad_mat)
        S   = load(bad_mat, 'bad');
        bad = S.bad(:)';             % frame-index row vector
        fprintf('Loaded %d confirmed bad frames from %s\n', numel(bad), bad_mat);
    else
        warning('%s not found; run flag_close_molecules + inspect_bad_frames first. Using bad = [].', bad_mat);
        bad = [];
    end
else
    bad = bad(:)';
end

manual_frames = [];
for frame = bad
    if ~ismember(frame+1, bad)
        manual_frames = [manual_frames, frame+1];
    end
end

% tunable constants (pulled to the top so they're easy to adjust per movie)
if nargin < 3 || isempty(p_cutoff), p_cutoff = 97; end
if p_cutoff <= 1, p_cutoff = p_cutoff * 100; end   % accept a fraction (0.94) or a percentile (94)
prctile_cutoff = p_cutoff;    % brightness percentile for B/W threshold, 0-100 (97 if normal)
clean_pixels   = 95;    % bwareaopen: remove specks smaller than this
bg_radius      = 25;    % illumination-flatten disk radius (px): bigger than a
                        % molecule's width, smaller than the illumination gradient
min_area       = 300;   % min object size
max_area       = 40000; % max object size
wait_time      = 0.5;
mag            = 250;    %#ok<NASGU> % magnification for display on screen
if nargin < 4 || isempty(jump_thresh), jump_thresh = 25; end   % px; sudden-jump reselect trigger

%% ---------------- load video ----------------
movie_info  = imfinfo(fname);
height      = movie_info(1).Height;
width       = movie_info(1).Width;
TotalFrames = numel(movie_info);

nunchuck_center_list = zeros(TotalFrames, 2);   % preallocate
thresh_frac = 0.5;       % cutoff = this fraction of the nunchuck's peak intensity
samp_radius = 5;         % px neighborhood around the click to sample
calib_done  = false;
fixed_threshold = [];

%% ---------------- main loop ----------------
frame = 1;
while frame < TotalFrames + 1
    this_frame = frame;

    % --- read frame, blur (denoise), then FLATTEN the illumination gradient ---
    % A morphological top-hat subtracts the slowly-varying background (the
    % bright-corner / dark-corner gradient) but keeps the molecules, so the
    % background is uniformly dark and ONE threshold works across the frame.
    image = imread(fname, frame);       % untouched original
    g     = imgaussfilt(image, gauss_sigma);
    gd    = imtophat(g, strel('disk', bg_radius));   % flattened frame

    % --- DETECTION on the flattened frame, tied to the nunchuck level ---
    if calib_done
        bw_threshold = fixed_threshold;                        % from your click, gd units
    else
        bw_threshold = prctile(double(gd(:)), prctile_cutoff); % fallback until calibrated
    end
    bw_image = bwareaopen(gd > bw_threshold, clean_pixels);

    % --- DISPLAY: gentle contrast on the flattened frame so molecule SHAPE
    %     shows and the molecules read as separate blobs on a flat background
    %     (click only; cropping still uses the raw frames) ---
    proc = imadjust(gd);   % stretch ~1st-99th pct; background is flat/dark now

    % --- find objects and filter by size (regionprops does it all) ---
    s     = regionprops(bw_image, 'Area', 'Centroid');
    areas = [s.Area];
    s     = s(areas > min_area & areas < max_area);

    if isempty(s)
        all_object_centers = [];
    else
        % Centroid is [x y] = [col row], matching your original convention.
        % (Use 'BoundingBox' + x+w/2,y+h/2 instead if you need the exact
        %  bounding-box-midpoint behavior of the old code.)
        all_object_centers = round(vertcat(s.Centroid));
    end

    %% ---- user input / tracking ----
    if isempty(s) || frame == 1 || ismember(frame, manual_frames)
        % frame 1, a flagged manual frame, or nothing found -> ask user
        if ismember(frame, bad)
            nunchuck_center = nunchuck_center_list(frame-1, :);
        else
            [frame, nunchuck_center, wait_time, fixed_threshold, calib_done] = manual_select( ...
                proc, gd, frame, TotalFrames, wait_time, samp_radius, thresh_frac, all_object_centers);
        end

    elseif numel(s) == 1
        % exactly one object
        nunchuck_center = all_object_centers(1, :);
        disp(frame);

    else
        % multiple objects: pick the one closest to the previous center
        prev = nunchuck_center_list(frame-1, :);
        d    = hypot(all_object_centers(:,1) - prev(1), ...
                     all_object_centers(:,2) - prev(2));
        [~, idx]        = min(d);
        nunchuck_center = all_object_centers(idx, :);
        disp(frame);
    end

    % --- human check: auto-tracked centroid jumped -> reselect by hand ---
    % Only applies to the two auto-tracked branches above (single/multiple
    % object); the manual-click and bad-frame paths are already human-set.
    auto_tracked = ~(isempty(s) || this_frame == 1 || ismember(this_frame, manual_frames) ...
                      || ismember(this_frame, bad));
    if auto_tracked
        prev = nunchuck_center_list(this_frame-1, :);
        jump = hypot(nunchuck_center(1)-prev(1), nunchuck_center(2)-prev(2));
        if jump > jump_thresh
            fprintf('frame %d: jump of %.0f px (> %d) -> click to reselect\n', ...
                this_frame, jump, jump_thresh);
            [frame, nunchuck_center, wait_time, fixed_threshold, calib_done] = manual_select( ...
                proc, gd, frame, TotalFrames, wait_time, samp_radius, thresh_frac, all_object_centers);
        end
    end

    % store center only if it was selected for THIS frame
    % (in the manual/click path the click() function advances 'frame' itself)
    if this_frame == frame
        nunchuck_center_list(frame, :) = nunchuck_center;
    end

    frame = frame + 1;
end
close all;

%% ---------------- save and crop ----------------
x = nunchuck_center_list(:, 2);   % ginput vs matlab define x/y oppositely
y = nunchuck_center_list(:, 1);
save(strcat(file_name, 'x_y_coords_auto.mat'), 'x', 'y', 'bad');

crop(x, y, strcat(file_name, '.tif'), bad);

run('play_sound.m');   % alarm when done
end

function [frame, nunchuck_center, wait_time, fixed_threshold, calib_done] = manual_select( ...
    proc, gd, frame, TotalFrames, wait_time, samp_radius, thresh_frac, all_object_centers)
% MANUAL_SELECT  Show the current frame, let a human click the center, and
% (re)calibrate the intensity threshold from the clicked object. Shared by
% the "ask user" path (frame 1 / flagged manual frame / nothing detected)
% and the sudden-jump reselect check.
imshow(proc, 'InitialMagnification', 'fit');   % show brightened version so the dim arm is visible
title_str = strcat("frame ", num2str(frame), " of ", ...
    num2str(TotalFrames), ", frame time: ", num2str(wait_time), "s");
title(title_str);
[x, y, button] = myginput(1, 'fullcross');
r  = round(y);  c = round(x);
rr = max(1,r-samp_radius):min(size(proc,1), r+samp_radius);
cc = max(1,c-samp_radius):min(size(proc,2), c+samp_radius);
patch = gd(rr, cc);                                % sample the FLATTENED frame
nunchuck_peak   = prctile(double(patch(:)), 95);   % robust peak of the clicked object
fixed_threshold = thresh_frac * nunchuck_peak;     % gd units, matches detection
calib_done      = true;
[frame, nunchuck_center, wait_time] = ...
    click(button, frame, wait_time, x, y, 0, [], all_object_centers);
end