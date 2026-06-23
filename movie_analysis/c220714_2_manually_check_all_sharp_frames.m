clear;clc;
close all;
data_file='37PPnsIHF_2023_good.mat';
load(data_file);

for i_movie=1:length(data.name)
    
    accept_sharp=[];
    sharp_frames=find(abs(data.raw_nnba{i_movie})>140);%all sharp frames, whether it has low score or not.
%     sharp_frames2=find(abs(data.raw_nnba{i_movie})<150);0
%     sharp_frames=intersect(sharp_frames,sharp_frames2);
    
    data.sharp_frames{i_movie}=sharp_frames;
    movie_name=data.name{i_movie};
    movie_name_long=strcat(movie_name,'_NNAnglesInserted.tif');
    
    num_montages=round_down(length(sharp_frames)/32)+1;%this is basically rounding up
    i_sharp_frame=0;
    
    %make montage from 32 images
    for n_montage=1:num_montages
        montage=zeros(200*4,200*8,3);%empty canvas for these 32 images
        if n_montage<num_montages
            images_in_montage=32;
        else
            images_in_montage=mod(length(sharp_frames),32);
        end
        
        for i_montage=1:images_in_montage%for each of the 32 (or so) sub images
            %put individual images into a collage called "montage":
            real_frame=sharp_frames(i_montage+(n_montage-1)*32);
            image=imread(movie_name_long,'Index',real_frame);
            %insert frame number
            position=[130,5];
            value=num2str(real_frame);
            image=insertText(image,position,value,'TextColor','black','FontSize',15);
            if i_montage<9
                montage(1:200,(1+200*(i_montage-1)):(200+200*(i_montage-1)),:)=image;
            elseif i_montage<17 & i_montage>=9
                montage(201:400,(1+200*(i_montage-9)):(200+200*(i_montage-9)),:)=image;
            elseif i_montage<25 & i_montage>=17
                montage(401:600,(1+200*(i_montage-17)):(200+200*(i_montage-17)),:)=image;
            elseif i_montage>=25
                montage(601:800,(1+200*(i_montage-25)):(200+200*(i_montage-25)),:)=image;
            end
        end%finished making 32-image montage
        montage=montage./256;%manually converting it from greyscale to rgb...
        
        %let user process these 32 images
        i_montage=1;
        while i_montage<=images_in_montage
            i_sharp_frame=i_sharp_frame+1;
            imshow(montage,'InitialMagnification',140);
            title_str=strcat("movie ",num2str(i_movie));
            title(title_str);
            [x,y,button] = myginput(1,'fullcross');
            
            if button==31%if I pressed down key, record this frame as wrong
                if i_montage<9
                    montage=insertShape(montage,'rectangle',[3+200*(i_montage-1),2,194,194],'Color',rgb('LightCoral'),'lineWidth',5);
                elseif i_montage<17 & i_montage>=9
                    montage=insertShape(montage,'rectangle',[3+200*(i_montage-9),202,194,194],'Color',rgb('LightCoral'),'lineWidth',5);
                elseif i_montage<25 & i_montage>=17
                    montage=insertShape(montage,'rectangle',[3+200*(i_montage-17),402,194,194],'Color',rgb('LightCoral'),'lineWidth',5);
                elseif i_montage>=25
                    montage=insertShape(montage,'rectangle',[3+200*(i_montage-25),602,194,194],'Color',rgb('LightCoral'),'lineWidth',5);
                end
                %record this frame as bad
                accept_sharp(i_sharp_frame)=0;
                i_montage=i_montage+1;
            elseif button==30%if I pressed up key, record this frame as good
                if i_montage<9
                    montage=insertShape(montage,'rectangle',[3+200*(i_montage-1),2,194,194],'Color',rgb('MediumSeaGreen'),'lineWidth',5);
                elseif i_montage<17 & i_montage>=9
                    montage=insertShape(montage,'rectangle',[2+200*(i_montage-9),202,194,194],'Color',rgb('MediumSeaGreen'),'lineWidth',5);
                elseif i_montage<25 & i_montage>=17
                    montage=insertShape(montage,'rectangle',[2+200*(i_montage-17),402,194,194],'Color',rgb('MediumSeaGreen'),'lineWidth',5);
                elseif i_montage>=25
                    montage=insertShape(montage,'rectangle',[2+200*(i_montage-25),602,194,194],'Color',rgb('MediumSeaGreen'),'lineWidth',5);
                end
                %record this frame as good
                accept_sharp(i_sharp_frame)=1;
                i_montage=i_montage+1;
            elseif button==28%if I pressed left arrow, go back (effectively one frame).
                i_sharp_frame=i_sharp_frame-2;
                i_montage=i_montage-1;
            elseif button==57%if I pressed "9", then the next 8 frames are wrong
                accept_sharp(i_sharp_frame:i_sharp_frame+7)=0;
                i_sharp_frame=i_sharp_frame+7;
                i_montage=i_montage+8;
            elseif button==56%if I pressed "8", then the next 8 frames are correct
                accept_sharp(i_sharp_frame:i_sharp_frame+7)=1;
                i_sharp_frame=i_sharp_frame+7;
                i_montage=i_montage+8;
            elseif button==48%if I pressed "0", then all remaining of the 32 frames are wrong.
                accept_sharp(i_sharp_frame:i_sharp_frame+(images_in_montage-i_montage))=0;
                i_sharp_frame=i_sharp_frame+(images_in_montage-i_montage);
                i_montage=images_in_montage+1;%break for while loop
            elseif button==55%if I pressed "7", then all remaining of the 32 frames are correct.
                accept_sharp(i_sharp_frame:i_sharp_frame+(images_in_montage-i_montage))=1;
                i_sharp_frame=i_sharp_frame+(images_in_montage-i_montage);
                i_montage=images_in_montage+1;%break for while loop
            end
        end
    end
    data.accept{i_movie}=accept_sharp;
    close all
end
path=strcat('/Users/ambercai/Desktop/matlab/data_files/',data_file);
save(path,'data');