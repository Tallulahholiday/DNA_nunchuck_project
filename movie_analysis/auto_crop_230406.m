clear;clc;close all;
file_name='260301_Bulge6_normal_2';
movie_name=strcat('copy_',file_name);
bad=[];
manual_frames =[];
for frame=bad
    if ~ismember(frame+1,bad)
        manual_frames=[manual_frames,frame+1];
    end
end

% bw_max=100;%the brightness cutoff for making black-and-white images
% bw_change=50;%the drop in brightness threshold over the duration of the movie
min_area=300;%the min object size
max_area=40000;%the max object size
wait_time=0.5;
mag=250;%magnication for display on screen

%load video and import parameters
movie_info = imfinfo(strcat(movie_name,'.tif'));
height=movie_info.Height;
width=movie_info.Width;
TotalFrames = numel(movie_info);

%%%%%%%%% start actual cropping %%%%%%%%%
frame=1;


% % start finding objects and showing frames
while frame<TotalFrames+1
    this_frame=frame;
    
    clear area
    %read a frame and find objects
    image = imread(strcat(movie_name,'.tif'),frame);%import this frame
    pixel_values=reshape(image,1,height*width);
    bw_threshold= prctile(pixel_values, 97); % adjust if needed 97 if normal,
    bw_image = bwareaopen((image > bw_threshold),95);%95 make the image black and white, and clean up random pixels
%     imshow(bw_image,'InitialMagnification',100);
    labeled=bwlabel(bw_image);%find disconnected objects
    s = regionprops(labeled,'PixelIdxList');%s contains the pixel index list for each object
    
    %keep only objects of suitable size
    area=0;%initialize
    for i_object=1:length(s)%each object
        area(i_object)=length(s(i_object).PixelIdxList);
    end
    idx_good_size=find(area>min_area & area<max_area);
    s(setdiff([1:length(s)],idx_good_size))=[];%delete unqualified objects
    
    %calculate bounding box and center for each object
    for i_object=1:length(s)%for each qualified object
        pixels=s(i_object).PixelIdxList;%indices for all pixels of this object
        clear row col
        for j=1:length(pixels)%convert index list to row and col number for each pixel
            row(j)=mod(pixels(j),height);
            col(j)=floor(pixels(j)/height);%floor means round down to the nearest integer
        end
        row(row==0)=height;%fix the boundary values
        col(col==0)=1;
        clear bbox
        bbox(i_object,:)=[min(col),min(row),max(col)-min(col),max(row)-min(row)];%record bounding box edges for all objects
        all_object_centers(i_object,:)=[round(mean([max(col),min(col)])),round(mean([max(row),min(row)]))];%record centers for all objects
    end
    if isempty(s)
        all_object_centers=[];
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% this chunk takes user input %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if isempty(s) ||frame==1 || ismember(frame,manual_frames)% if frame = 1 or this frame needs to be manual, wait for user click by mouse
        if ismember(frame,bad)
            nunchuck_center=nunchuck_center_list(frame-1,:);
        else
            imshow(image,'InitialMagnification','fit');
            title_str=strcat("frame ",num2str(frame)," of ",num2str(TotalFrames),", frame time: ",num2str(wait_time),"s");
            title(title_str);
            [x,y,button] = myginput(1,'fullcross');%show user the "fullcross" to ask user to click
            
            [frame,nunchuck_center,wait_time]=click(button,frame,wait_time,x,y,0,[],all_object_centers);%call the function that deals with user input
        end
        
    elseif size(s)==[1,1] %if only one object is identified
        nunchuck_center=all_object_centers(1,:);
        disp(frame);
        
    else%if more than one blob is found, calculate all centers and find the one closest to the previous
        previous_center=nunchuck_center_list(frame-1,:);
        for i_object=1:length(s)%for each object, calculate center distance to previous blob
            distance(i_object)=sqrt((previous_center(1)-all_object_centers(i_object,1))^2+((previous_center(2)-all_object_centers(i_object,2))^2));
        end
        [~,idx]=min(distance);
        clear distance previous_center i_blob
        
        nunchuck_center=all_object_centers(idx,:);
        disp(frame);
    end
    
    if this_frame==frame %if we have selected the nunchuck center for this frame from the clicking event (meaning frame=frame+1 in the "click" function)
        nunchuck_center_list(frame,:)=nunchuck_center;%then we store this nunchuck center coordinate
    end
    
    %     if mod(frame,10)==0%every 10 frames, save coordinates
    %         save('temp.mat','nunchuck_center_list');
    %     end
    frame=frame+1;
end
close all;

x=nunchuck_center_list(:,2);%because ginput and matlab default defines x and y differently
y=nunchuck_center_list(:,1);
save('x_y_coords_auto.mat','x','y','bad');
% save('temp.mat','nunchuck_center_list');

crop(x,y,strcat(file_name,'.tif'),bad);

% play some alarm sound
run('play_sound.m');
