function image=nunImage(bend_angle)%generate a fake nunchuck image with a certain bend angle

[nunchuck_image,x_arms,y_arms]=nunchuck(bend_angle); %draw a nunchuck onto the image
complete_image=backTube(nunchuck_image,x_arms,y_arms);%add background tubes
image=diffus(complete_image); %applies diffusion to image in order to make it less jagged
image=noise(image); %adds noise to image
image=reformatImages(image);
end