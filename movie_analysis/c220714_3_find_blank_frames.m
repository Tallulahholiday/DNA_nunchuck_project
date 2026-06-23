clear;clc;close all;
data_file='37PPnsIHF_2023_good.mat';
load(data_file);

for i_movie=1:length(data.name)
    disp(i_movie);
    movie_name=data.name{i_movie};
    blank_frames=[];
    for frame=1:length(data.nnba{i_movie})
        image=imread(strcat(movie_name,'.TIFF'),'Index',frame);
        if sum(sum(image))==0
            blank_frames=[blank_frames,frame];
        end
    end
    data.blank_frames{i_movie}=blank_frames;
end

path=strcat('/Users/ambercai/Desktop/matlab/data_files/',data_file);
save(path,'data');