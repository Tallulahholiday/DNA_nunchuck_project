clear;clc;close;

N=10000;%number of images per angle that will be made
binSize=5;
numOfBins=360/binSize;

makeFolders(binSize) %makes folders with given bin size

for i=1:numOfBins%for each bin
    parfor j=1:N%for each image
        bend_angle=(i-1)*binSize+(binSize/2)+binSize*rand-binSize/2-180;%pick a random angle value in this bin
        image=nunImage(bend_angle);%generate image
        savePath=strcat('Images\',num2str(((i-1)*binSize+(binSize/2)-180)),'\',num2str(j),')',num2str(bend_angle),'.tif'); %path to where the image will be saved
        imwrite(image,savePath);%save image
    end
    disp(strcat(num2str((i/numOfBins)*100),"% Completed"))
end