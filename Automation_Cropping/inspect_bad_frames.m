function [bad, badRanges] = inspect_bad_frames(fname, suspicious, varargin)
% INSPECT_BAD_FRAMES  Confirm-by-eye the candidates from flag_close_molecules.
%
% Shows each padded flagged clip in an axes with a frame slider +
% Accept(bad)/Reject(ok) + an editable start/end range, so you can check
% whether the auto-flagged frames are *actually* bad (molecules too close,
% or a sudden blurry jump) before they get blanked in the crop.
%
% Inline MATLAB review: no ImageJ, no app launch.
%
% Usage:
%   bad0 = flag_close_molecules(fname);
%   bad  = inspect_bad_frames(fname, bad0);   % accept/reject each clip
% On Finish it returns BAD (frame-index vector) and BADRANGES (Nx2), and
% SAVES the confirmed frames to <base>_bad_frames.mat so r260626_crop.m can
% load them.
%
% Options: 'Pad' (frames of context around each clip), 'Position' (review
% window [x y w h]), 'PlayPause' (seconds/frame on Play), 'WindowName'.
% inspect_cropped_movie.m reuses this same GUI for a smaller/faster
% post-crop check.

p = inputParser;
p.addParameter('Pad', 10);
p.addParameter('Position', [100 100 640 640]);   % [x y w h] of the review window
p.addParameter('PlayPause', 0.03);               % seconds between frames on Play
p.addParameter('WindowName', 'Bad-frame review');
p.parse(varargin{:});
opt = p.Results;

info = imfinfo(fname); n = numel(info);

if islogical(suspicious), R = local_ranges(suspicious(:)');
elseif size(suspicious,2)==2, R = suspicious;
else, error('suspicious must be a logical mask or Nx2 ranges.'); end
if isempty(R), disp('Nothing to review.'); bad=[]; badRanges=zeros(0,2); return; end

N=size(R,1); accepted=false(N,1);
rangeStart=R(:,1); rangeEnd=R(:,2); cur=1;
clip=[]; clipStart=1;                       % cached frames for current interval
isPlaying=false;                            % Play button also acts as Stop while playing

fig = uifigure('Name',opt.WindowName,'Position',opt.Position);
gl = uigridlayout(fig,[8 4]);
gl.RowHeight={28,'1x',30,30,30,34,34,'1x'}; gl.ColumnWidth={'1x','1x','1x','1x'};

hTitle=uilabel(gl,'FontWeight','bold','FontSize',14);
hTitle.Layout.Row=1; hTitle.Layout.Column=[1 4];

ax=uiaxes(gl); ax.Layout.Row=2; ax.Layout.Column=[1 4];
ax.XTick=[]; ax.YTick=[]; disableDefaultInteractivity(ax);

sld=uislider(gl,'ValueChangingFcn',@(s,ev)showFrame(round(ev.Value)));
sld.Layout.Row=3; sld.Layout.Column=[1 4];
hFrame=uilabel(gl,'HorizontalAlignment','center');
hFrame.Layout.Row=4; hFrame.Layout.Column=[1 4];

l1=uilabel(gl,'Text','bad start:'); l1.Layout.Row=5; l1.Layout.Column=1;
edS=uieditfield(gl,'numeric','Limits',[1 n],'RoundFractionalValues',true);
edS.Layout.Row=5; edS.Layout.Column=2;
l2=uilabel(gl,'Text','bad end:'); l2.Layout.Row=5; l2.Layout.Column=3;
edE=uieditfield(gl,'numeric','Limits',[1 n],'RoundFractionalValues',true);
edE.Layout.Row=5; edE.Layout.Column=4;

bAcc=uibutton(gl,'Text','Accept (bad)','BackgroundColor',[0.82 0.95 0.82],...
    'ButtonPushedFcn',@(s,e)decide(true));
bAcc.Layout.Row=6; bAcc.Layout.Column=[1 2];
bRej=uibutton(gl,'Text','Reject (ok)','BackgroundColor',[0.98 0.85 0.85],...
    'ButtonPushedFcn',@(s,e)decide(false));
bRej.Layout.Row=6; bRej.Layout.Column=[3 4];

bBack=uibutton(gl,'Text','◀ Back','ButtonPushedFcn',@(s,e)nav(-1));
bBack.Layout.Row=7; bBack.Layout.Column=1;
bPlay=uibutton(gl,'Text','▶ Play','ButtonPushedFcn',@(s,e)playClip());
bPlay.Layout.Row=7; bPlay.Layout.Column=[2 3];
bDone=uibutton(gl,'Text','Finish','ButtonPushedFcn',@(s,e)finish());
bDone.Layout.Row=7; bDone.Layout.Column=4;

hList=uitextarea(gl,'Editable','off'); hList.Layout.Row=8; hList.Layout.Column=[1 4];

loadClip(); uiwait(fig);

badRanges=sortrows([rangeStart(accepted) rangeEnd(accepted)]);
if isempty(badRanges), badRanges=zeros(0,2); end   % nothing accepted -> keep shape Nx2
bad=[]; for i=1:size(badRanges,1), bad=[bad badRanges(i,1):badRanges(i,2)]; end %#ok<AGROW>
if isempty(badRanges)
    fprintf('\nbad = [];   (no frames marked bad)\n');
else
    fprintf('\nbad = [%s];\n', strjoin(arrayfun(@(a,b)sprintf('%d:%d',a,b),...
        badRanges(:,1),badRanges(:,2),'uni',0),' '));
end

% --- persist confirmed bad frames so the crop script can load them ---
[~, base_name, ~] = fileparts(fname);
out_mat = strcat(base_name, '_bad_frames.mat');
save(out_mat, 'bad', 'badRanges');
fprintf('Saved %d confirmed bad frames to %s\n', numel(bad), out_mat);

    function loadClip()
        s=max(1,R(cur,1)-opt.Pad); e=min(n,R(cur,2)+opt.Pad);
        clipStart=s;
        f1=imread(fname,s,'Info',info);
        clip=zeros(size(f1,1),size(f1,2),e-s+1,'like',f1);
        for idx=s:e, clip(:,:,idx-s+1)=imread(fname,idx,'Info',info); end
        sld.Limits=[s e]; sld.Value=R(cur,1);
        % Numeric edit fields error if you set Limits while the CURRENT Value
        % falls outside them (e.g. jumping from chunk [1 500] to [501 1000]
        % leaves Value=1, outside the new Limits) -- that silently aborts the
        % Limits update, which is why "bad start" would get stuck. Widen
        % first (any old Value is valid in [1 n]), set the new Value, then
        % narrow to this clip's actual range.
        edS.Limits=[1 n]; edE.Limits=[1 n];
        edS.Value=rangeStart(cur); edE.Value=rangeEnd(cur);
        edS.Limits=[s e]; edE.Limits=[s e];
        hTitle.Text=sprintf('Interval %d of %d   (auto-flag %d:%d)',cur,N,R(cur,1),R(cur,2));
        showFrame(R(cur,1)); refreshList();
    end

    function showFrame(fr)
        fr=max(sld.Limits(1),min(sld.Limits(2),fr));
        img=clip(:,:,fr-clipStart+1);
        imagesc(ax,img); colormap(ax,gray); axis(ax,'image'); ax.XTick=[]; ax.YTick=[];
        inBad = fr>=edS.Value && fr<=edE.Value;
        hFrame.Text=sprintf('frame %d %s',fr, ternary(inBad,'  ← inside bad range',''));
    end

    function playClip()
        if isPlaying
            isPlaying=false;   % 2nd click while playing -> signal the running loop to stop
            return;
        end
        isPlaying=true; bPlay.Text='■ Stop';
        for fr=sld.Limits(1):sld.Limits(2)
            if ~isvalid(fig) || ~isPlaying, break; end
            sld.Value=fr; showFrame(fr); pause(opt.PlayPause);
        end
        isPlaying=false;
        if isvalid(fig), bPlay.Text='▶ Play'; end
    end

    function decide(isBad)
        if isPlaying, isPlaying=false; return; end   % swallow the click that stops playback
        if isBad && edE.Value<edS.Value, uialert(fig,'end < start','Invalid'); return; end
        rangeStart(cur)=edS.Value; rangeEnd(cur)=edE.Value; accepted(cur)=isBad;
        refreshList();
        if cur<N, cur=cur+1; loadClip(); else, finish(); end
    end

    function nav(d)
        if isPlaying, isPlaying=false; return; end   % swallow the click that stops playback
        c=cur+d; if c>=1&&c<=N, cur=c; loadClip(); end
    end
    function refreshList()
        L={'Accepted bad ranges:'};
        for i=1:N, if accepted(i), L{end+1}=sprintf('  %d:%d',rangeStart(i),rangeEnd(i)); end, end %#ok<AGROW>
        hList.Value=L;
    end
    function finish(), uiresume(fig); if isvalid(fig), close(fig); end, end
end

function r=local_ranges(mask), d=diff([0 mask 0]); r=[find(d==1)' (find(d==-1)-1)']; end
function o=ternary(c,a,b), if c, o=a; else, o=b; end, end
