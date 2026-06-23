function out=reformatImages(img)
    img(201:227,201:227)=uint8(0);
    img = cat(3, img, img, img);
    out=img;
end