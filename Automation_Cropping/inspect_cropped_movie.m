function [bad, badRanges] = inspect_cropped_movie(fname, varargin)
% INSPECT_CROPPED_MOVIE  Quick human QC pass on the CROPPED output.
%
% Same review GUI as inspect_bad_frames (slider + Accept/Reject + editable
% range), but tuned for a fast post-crop skim instead of a careful per-frame
% check:
%   - reviews the WHOLE movie in equal chunks (default 100 frames each),
%     not just the flagged ranges, so you catch a bad centroid/crop anywhere
%   - smaller window, since cropped frames are only 200x200
%   - faster autoplay
%
% Mark Accept(bad) on any chunk where the crop looks wrong (off-center,
% molecule clipped at the edge, wrong frame blanked, etc.); Reject(ok)
% otherwise. On Finish it returns BAD/BADRANGES and saves them to
% <base>_crop_review.mat (base name = the cropped file, e.g.
% '..._cropped_bad_frames.mat' via the same save step in inspect_bad_frames).
%
% Usage:
%   inspect_cropped_movie(strcat(file_name, '_cropped.TIFF'));

p = inputParser;
p.addParameter('ChunkSize', 500);   % frames per review chunk
p.addParameter('Pad', 0);           % chunks already tile the movie; no extra context needed
p.parse(varargin{:});
opt = p.Results;

info = imfinfo(fname); n = numel(info);

starts = (1:opt.ChunkSize:n)';
ends   = min(starts + opt.ChunkSize - 1, n);
ranges = [starts, ends];

[bad, badRanges] = inspect_bad_frames(fname, ranges, ...
    'Pad', opt.Pad, ...
    'Position', [120 120 360 400], ...
    'PlayPause', 0.015, ...
    'WindowName', 'Post-crop check');
end
