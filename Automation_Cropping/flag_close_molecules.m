function bad = flag_close_molecules(fname, varargin)
% FLAG_CLOSE_MOLECULES  Auto-flag candidate bad frames in a nunchuck movie.
%
% Flags a frame as bad if EITHER of the two things you don't want happens:
%   (1) two molecules get too close to each other   (minDist < MinSep)
%   (2) a molecule suddenly jumps between frames     (per-frame move > JumpThresh)
%       -- this is what a "super blurry"/smeared frame looks like: the tracked
%          centroid leaps because the blob smears or briefly merges.
%
% Returns BAD, a logical mask (n x 1). It also prints the flagged frame ranges.
%
% Usage (feeds straight into the review/crop pipeline):
%   fname = '260302_bub2_NaCl500mM_4@0001.tif';
%   bad0  = flag_close_molecules(fname);              % auto candidates
%   bad   = inspect_bad_frames(fname, bad0);          % confirm by eye -> saves .mat
%   run('r260626_crop.m');                            % crop, blanking confirmed bad
%
% All distance thresholds are in ORIGINAL (full-resolution) pixels; detection is
% done on a downsampled copy for speed and the distances are rescaled back.

p = inputParser;
p.addParameter('Scale', 0.25);
p.addParameter('MinSep', 40);        % proximity threshold, ORIGINAL px
p.addParameter('JumpThresh', 25);    % max plausible per-frame move, ORIGINAL px
p.addParameter('GateDist', 30);      % link same molecule frame-to-frame, ORIG px
p.addParameter('MinArea', 5);        % ignore specks (downsampled px)
p.addParameter('Pad', 3);            % also flag this many frames before/after every bad frame
p.addParameter('MergeGap', 5);
p.parse(varargin{:});
opt = p.Results;

info = imfinfo(fname); n = numel(info);
sc = opt.Scale; gate = opt.GateDist * sc;

minDist = nan(n,1);
jumpMask = false(n,1);
active = struct('id',{},'last',{});   % molecules alive last frame (downsampled xy)
nextID = 1;

for k = 1:n
    f = imread(fname,k,'Info',info);
    if size(f,3)>1, f = rgb2gray(f); end
    f = imresize(im2double(f), sc);
    bw = bwareaopen(f > (mean(f(:))+2*std(f(:))), opt.MinArea);
    C  = cat(1, regionprops(bw,'Centroid').Centroid);   % m x 2 downsampled

    % (1) too-close check: smallest pairwise centroid distance this frame
    if size(C,1) >= 2, minDist(k) = min(pdist(C)) / sc; else, minDist(k) = Inf; end

    % (2) jump check: greedily link this frame's blobs to molecules from last
    %     frame; a matched pair that moved > JumpThresh flags the frame.
    m = size(C,1); assigned = false(m,1);
    if ~isempty(active) && m > 0
        D = pdist2(cat(1,active.last), C);
        for step = 1:min(numel(active), m)
            [v, li] = min(D(:));
            if isempty(v) || v > gate, break; end
            [ai, bi] = ind2sub(size(D), li);
            if v/sc > opt.JumpThresh, jumpMask(k) = true; end   % this molecule jumped
            active(ai).last = C(bi,:); assigned(bi) = true;
            D(ai,:) = inf; D(:,bi) = inf;
        end
    end
    % unmatched blobs -> new molecules
    newC = C(~assigned,:);
    for bi = 1:size(newC,1)
        active(end+1) = struct('id',nextID,'last',newC(bi,:)); nextID = nextID+1; %#ok<AGROW>
    end
end

% pad every flagged frame (too-close OR jump) by +/- Pad frames
bad = pad_mask((minDist < opt.MinSep) | jumpMask, opt.Pad);
bad = merge_mask(bad, opt.MergeGap);

r = ranges_from_mask(bad);
fprintf('flag_close_molecules: %d candidate bad frames in %d ranges\n', nnz(bad), size(r,1));
for i = 1:size(r,1)
    if r(i,1)==r(i,2), fprintf('  %d\n', r(i,1));
    else,             fprintf('  %d:%d\n', r(i,1), r(i,2)); end
end
end

function mask = pad_mask(mask, pad)
% widen every flagged frame by +/- pad frames (clamped to the movie length)
if pad <= 0, return; end
n = numel(mask);
for i = find(mask(:)')
    mask(max(1,i-pad):min(n,i+pad)) = true;
end
end

function r = ranges_from_mask(mask)
mask = mask(:)'; d = diff([0 mask 0]); r = [find(d==1)' (find(d==-1)-1)'];
end

function mask = merge_mask(mask, gap)
r = ranges_from_mask(mask);
for i = 2:size(r,1)
    if r(i,1)-r(i-1,2) <= gap, mask(r(i-1,2):r(i,1)) = true; end
end
end
