function makeFolders(binSize)
numOfFolders=360/binSize;

mkdir Images %makes inital folder

for i=1:numOfFolders%make all 72 folders
    angle=(i-1)*binSize+(binSize/2)-180; %so that folder name is in the middle of the bin
    folderData=['Images\' num2str(angle)]; %path of new folder with name
    mkdir(folderData)
end
end