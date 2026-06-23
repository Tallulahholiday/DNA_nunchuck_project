clear;clc;
close all;
data_file='37PPnsIHF_2023_good.mat';
load(data_file);

%make folders, go in there, etc
cd '/Users/ambercai/Desktop/matlab/movie_analysis/NN_analysis'
if exist('for_NNopen','dir')
    rmdir('for_NNopen','s');
end
mkdir for_NNopen
cd '/Users/ambercai/Desktop/matlab/movie_analysis/NN_analysis/for_NNopen'
addpath(genpath('/Users/ambercai/Desktop/matlab'));

%prepare images for NN_open analysis
total_movies=length(data.name);
for i_movie=1:total_movies
    sharp_frames=data.sharp_frames{i_movie};
    accept=data.accept{i_movie};
    sharp_frames=sharp_frames(accept==0);
    data.NNopen_frames{i_movie}=sharp_frames;
    movie_name=data.name{i_movie};
    
    for frame=1:length(sharp_frames)
        ImageData(1:200,1:200,frame)=imread(strcat(movie_name,'.TIFF'),sharp_frames(frame));
    end
    
    if ~isempty(sharp_frames)
        %write the movie
        imwrite(ImageData(:,:,1),strcat(movie_name,'_for_NNopen.tif'))
        for frame=2:length(sharp_frames)
            imwrite(ImageData(:,:,frame),strcat(movie_name,'_for_NNopen.tif'), 'writemode', 'append');
        end
        clear ImageData
    end
end

%%%%%%%%%%%%%%%%%%%%%  run NNopen  %%%%%%%%%%%%%%%%%%%%%%%%
load('AlexNet_test4_28_open.mat');%load NN
net=AlexNet_test4_28_open;

cd '/Users/ambercai/Desktop/matlab/movie_analysis/NN_analysis'
[numStacks,folderNames]=splitStack(); %splits stacks and prepares images for NN analysis

disp('______________Stacks Analysed:_____________')

path=strcat(pwd,'/for_NNopen/');
edges=[-90:5:90];
runAnglesFiltered=[];

for i=1:numStacks%for each movie
    name=folderNames{i};
    movie_name=name(1:end-16);
    i_data=find(cellfun(@(x) any(strcmp(x,movie_name)),data.name));
    
    disp(strcat('>>> ',name(1:end-5),':'))
    
    stack_ds=imageDatastore(strcat(path,folderNames(i))); %creates imagedatastore fed to NN
    [preds,scores] = classify(net,stack_ds); %Gets predictions and scores
    [predsDouble]=convertToDouble(preds); %converts from categorical to double

    %filter out images with low (1.5std away) scores
    clear predsFiltered scoresFiltered
    
    %save files/results
    data.NNopen_nnba{i_data}=predsDouble;
    maxScores=max(scores,[],2);
    writeNewStacks(name,stack_ds,predsDouble,maxScores);
   
    rmdir(strcat(pwd,'/for_NNopen/',folderNames(i)),'s') %removes split folders
end

%make sure the "NNopen_rawmba" has the same length as other fields
if length(data.name)>length(data.NNopen_nnba)
    full_length=length(data.name);
    current_length=length(data.NNopen_nnba);
    data.NNopen_nnba(current_length+1:full_length)={[]};
end

path=strcat('/Users/ambercai/Desktop/matlab/data_files/',data_file);
save(path,'data');
disp('______________Completed_____________')

fclose('all'); %closes all opened files

%------------------Functions----------------------
function [num,out]=splitStack()
%This function splits the stack into individual images and prepares them to run though NN
%(changes resolution and type to true color)

stacks=dir('for_NNopen/*.tif*'); %tif stacks in the folder
numStacks=length(stacks) %number of stacks in the folder
folders=strings(1,numStacks); %contain folder names for analysis function

for k=1:numStacks %will split up every stack 
    stackName=stacks(k).name; %gets the file name of the stack
    
    stackPath = strcat(pwd,'/for_NNopen/',stackName); %path of stack file

    endin=strfind(stackName,'.tif');
    folderName=strcat(stackName(1:endin-1),'Split'); %foldername based on stack name
    folders(k)=folderName;
    
    if exist(strcat('for_NNopen/', folderName))==7 %Skips if split folder is present
        disp(strcat(folderName, ": Split Folder already present"))
        continue
    end
    
    mkdir ('for_NNopen', folderName); %folder wehere split is going to be saved to
    folderPath=strcat(pwd,'/for_NNopen/',folderName,'/'); %path to save folder
    
    info = imfinfo(stackPath); %info about stack 
    numFrames= numel(info); %number of frames in the stack

    for i = 1:numFrames %saves each modified frame as individual file
        if i<10 %name for individual frame files-needed for image dataStores
            name=strcat('000',num2str(i));
        elseif i<100 && i>9
            name=strcat('00',num2str(i));
        elseif i<1000 && i>99
            name=strcat('0',num2str(i));
        else
            name=num2str(i);
        end

        A = imread(stackPath, i, 'Info', info); %reads specific frame
        A(201:227,201:227)=0; %changes resolution from 200x200 to 277x277
        A = cat(3, A,A,A); %changes from 8bit to truecolor
        fileName=strcat(folderPath,name,'.tif'); %filename is frame number
        imwrite(A,fileName); %writes frame
    end
end
num=numStacks;
out=folders;
end


function [predsDouble]=convertToDouble(preds)
    %This next portion will convert the predictions from a categorical
    %array to a double array
    
    preds=string(preds);
    predsSize=numel(preds);
    predsDouble=zeros(1,predsSize);

    for j=1:predsSize
        predsDouble(j)=eval(preds(j));
        predsDouble(j)=str2num(strcat(num2str(predsDouble(j)),'.5'));
    end
end


function writeNewStacks(name,stack_ds,predsDouble,maxScores)

    numFrames=numel(stack_ds.Files); %number of frames for the movie
 
    for k=1:numFrames %loops through frames of stack
        savePath=strcat(pwd,'/for_NNopen/',name(1:end-5),'_NNAnglesInserted.tif');
        img=readimage(stack_ds,k); %reads image from split folder
        
        text=strcat(num2str(predsDouble(k)),' | ',num2str(round(maxScores(k),2))); %text that will be written
        
        img=insertText(img,[5,5],text); %inserts text
        
        img=img(1:200,1:200); %changes it back to 200x200 and grey scale
        
        if k~=1 %writes stack by appending to the stack each consecutive image
            imwrite(img,savePath,'WriteMode','append'); 
        else
            imwrite(img,savePath);
        end
    end

end