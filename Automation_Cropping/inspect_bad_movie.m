function [suspicious, diag] = inspect_bad_movie(fname, varargin)
p = inputParser;
p.addParameter('Scale', 0.25);
p.addParameter('JumpThresh', 15);
p.addParameter('AreaZ', 4);
p.addParameter('MergeGap', 5);
p.addParameter('Seed', []);        % [x y] in ORIGINAL px to lock onto a specific object
p.parse(varargin{:});
opt = p.Results;

info = imfinfo(fname);
n = numel(info);
cx = nan(n,1); cy = nan(n,1); area = nan(n,1); nblob = nan(n,1); meanI = nan(n,1);

prev = [];
if ~isempty(opt.Seed), prev = opt.Seed * opt.Scale; end   % scale seed to downsampled coords

for k = 1:n
    f = imread(fname, k, 'Info', info);
    if size(f,3) > 1, f = rgb2gray(f); end
    f = imresize(im2double(f), opt.Scale);
    meanI(k) = mean(f(:));

    bw = f > (mean(f(:)) + 2*std(f(:)));
    bw = bwareaopen(bw, 5);
    st = regionprops(bw, 'Centroid', 'Area');
    nblob(k) = numel(st);

    if isempty(st)
        prev = prev;                       % carry last position; frame flagged below
        continue
    end

    C = cat(1, st.Centroid);               % m x 2
    A = [st.Area]';

    if isempty(prev) || any(isnan(prev))
        [~, idx] = max(A);                 % first valid frame: seed on largest
    else
        d = hypot(C(:,1)-prev(1), C(:,2)-prev(2));
        [~, idx] = min(d);                 % otherwise: nearest to previous
    end

    cx(k) = C(idx,1); cy(k) = C(idx,2); area(k) = A(idx);
    prev = [cx(k) cy(k)];
end

jump  = [0; hypot(diff(cx), diff(cy))];
ma    = mad(area(~isnan(area)), 1);        % compute MAD on non-NaN only
areaZ = abs(area - median(area,'omitnan')) ./ (1.4826*ma + eps);

suspicious = false(n,1);
suspicious(nblob == 0)             = true;   % object lost
suspicious(nblob >= 3)             = true;   % extra clutter
suspicious(jump > opt.JumpThresh)  = true;
suspicious(areaZ > opt.AreaZ)      = true;
suspicious(isnan(cx))              = true;   % no track this frame
suspicious = merge_mask(suspicious, opt.MergeGap);

diag = table((1:n)', cx, cy, area, nblob, meanI, jump, suspicious, ...
    'VariableNames', {'frame','cx','cy','area','nblob','meanI','jump','suspicious'});

figure('Name', fname);
ax(1)=subplot(4,1,1); plot(cx,'.-'); hold on; plot(cy,'.-'); ylabel('centroid'); legend('x','y');
ax(2)=subplot(4,1,2); plot(area,'.-'); ylabel('area');
ax(3)=subplot(4,1,3); plot(jump,'.-'); ylabel('jump'); yline(opt.JumpThresh,'r--');
ax(4)=subplot(4,1,4); stem(find(suspicious), ones(nnz(suspicious),1),'r','Marker','none');
ylabel('flagged'); xlabel('frame'); linkaxes(ax,'x');

print_ranges(suspicious);
end

function r = ranges_from_mask(mask)
mask = mask(:)';
d = diff([0 mask 0]);
r = [find(d==1)' (find(d==-1)-1)'];
end

function mask = merge_mask(mask, gap)        % bridge flagged ranges < gap apart
r = ranges_from_mask(mask);
for i = 2:size(r,1)
    if r(i,1) - r(i-1,2) <= gap, mask(r(i-1,2):r(i,1)) = true; end
end
end

function print_ranges(mask)
r = ranges_from_mask(mask);
fprintf('Suspicious frame ranges:\n');
for i = 1:size(r,1)
    if r(i,1)==r(i,2), fprintf('  %d\n', r(i,1));
    else,             fprintf('  %d:%d\n', r(i,1), r(i,2)); end
end
end