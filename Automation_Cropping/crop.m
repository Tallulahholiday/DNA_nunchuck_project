%this function crops each frame of the movie with "movie_name" around x, y coordinates
function crop(x,y,movie_name,ignore)
movie_info = imfinfo(movie_name);
TotalFrames = numel(movie_info);
image_height=movie_info.Height;
image_width=movie_info.Width;

% build output name: <base>_cropped.TIFF
[~, base_name, ~] = fileparts(movie_name);
out_name = strcat(base_name, '_cropped.TIFF');

%next we will load movie data into arrays, but do this in steps to avoid blowing up RAM.
block_size=200;
total_blocks=ceil(TotalFrames/block_size);
for block=1:total_blocks
    if block==total_blocks
        this_block_size=mod(TotalFrames,block_size);
        if this_block_size==0
            this_block_size=block_size;
        end
    else
        this_block_size=block_size;
    end
    ImageData=zeros(image_height,image_width,this_block_size);%prepare empty array
    frame_in_array=1;
    for frame = block_size*(block-1)+1:block_size*(block-1)+this_block_size
      ImageData(1:image_height,1:image_width,frame_in_array)=imread(movie_name,frame);
      frame_in_array=frame_in_array+1;
    end
%Next we are going to add 200 pixels of blankness (black) around the movie for future use.
    ImageData_expanded=zeros(image_height+400,image_width+400,this_block_size);
    for frame = 1:this_block_size
%determine the noise level of "black border"
        pixels=double(reshape(imread(movie_name,frame),[image_height*image_width,1]));
        dark_level=mean(pixels)-0.5*std(pixels);
        ImageData_expanded(:,:,frame)=dark_level+uint8(rand(image_height+400,image_width+400)*2-1)*15;
        ImageData_expanded(201:image_height+200,201:image_width+200,frame)=ImageData(1:image_height,1:image_width,frame);
    end
    clear ImageData
%Next we want to re-center the movie according to [x,y], and make a new 200 x 200 movie.
    NewImage=zeros(200,200,this_block_size);
    for frame=1:this_block_size
        correctFrame=frame+200*(block-1);
        NewImage(1:200,1:200,frame)=ImageData_expanded(x(correctFrame)+200-99:x(correctFrame)+200+100,...
        y(correctFrame)+200-99:y(correctFrame)+200+100,frame);
    end
    if block==1
        TotalNewImage=NewImage;
    else
        TotalNewImage=cat(3,TotalNewImage,NewImage);
    end
end
TotalNewImage=uint8(TotalNewImage);
%Now write to a new movie file
imwrite(TotalNewImage(:,:,1),out_name);
for frame=2:TotalFrames
    if ismember(frame,ignore)
        imwrite(zeros(200,200,1), out_name, 'writemode', 'append');
    else
        imwrite(TotalNewImage(:,:,frame), out_name, 'writemode', 'append');
    end
end
disp(strcat("Finished cropping: ", out_name));
