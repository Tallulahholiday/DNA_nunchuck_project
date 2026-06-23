function [nunchuck_image,x_contour,y_contour]=nunchuck(bend_angle)%draw a nunchuck in the image

image=zeros(200,'uint8');%prepare empty frame

%draws bright arm
angleArm1=360*rand; %intial angle at which arm 1 will come out, with respect to matlab-default x direction
brightness1=randi(155,'uint8')+uint8(100);%brightness of arm 1
lower=40;%lower limit of arm 1 length
len1=50*rand+lower; %size of arm 1
center=[100,100];%when we draw an arm, we start drawing from the center of the image. We'll transpose the entire nunchuck object later
[image1,x_contour1,y_contour1]=arm(image,angleArm1,brightness1,center,len1); %draws bright arm

%draws dim arm
len2=0;%initialize len2 value
while len2<40 | len2>90 %if arm2 is too long or too short, recalculate a random len2 until it's acceptable
    len2=(2*len1-0.5*len1)*rand+0.5*len1;%arm 2 is between half and twice as long as arm 1.
end
angle_between=bend_angle-180;%angle between two arm vectors, by definition
angleArm2=angleArm1+angle_between; %angle of dim arm according to nunchuck angle desired
brightness2=uint8(normrnd((double(brightness1))/2,double(brightness1/20))); %picks second brightness usign a normal distribution
[image2,x_contour2,y_contour2]=arm(image,angleArm2,brightness2,center,len2); % draws dim arm

x_contour=[x_contour1',x_contour2']';
y_contour=[y_contour1',y_contour2']';
nunchuck_image=image1+image2; %adds two images to create a nunchuck image

if rand<0.95 % 95% of the time, the bounding box will be draw around both arms
%     %find boundary box surrounding the nunchuck
    x_min=round(min(x_contour));
    x_max=round(max(x_contour));
    y_min=round(min(y_contour));
    y_max=round(max(y_contour));
else % 5% of the time, "cropping" only recognizes the bright arm. let's imitate that.
    %find boundary box surrounding the bright arm (arm 1)
    x_min=round(min(x_contour1));
    x_max=round(max(x_contour1));
    y_min=round(min(y_contour1));
    y_max=round(max(y_contour1));
end

%calculate new centers
x_center=mean([x_min,x_max])+normrnd(0,10);%adds a bit of random-ness
y_center=mean([y_min,y_max])+normrnd(0,10);

%re-center the nunchuck
x_off=x_center-100;
y_off=y_center-100;

%shift the nunchuck image, as well as x and y arrays storing all filament pixel points
nunchuck_image=imtranslate(nunchuck_image,[-x_off,-y_off]);
x_contour=x_contour-x_off;
y_contour=y_contour-y_off;
end
