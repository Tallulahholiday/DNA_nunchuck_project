function [out,x_contour,y_contour]=arm(image,angle,brightness,center,len)

%from Amber's filament simulation program
n_steps=round(len)-1;%number of pixels
sigma_i=3.7;%the sigma of the Gaussian distribution from which we draw bend angle of each step
theta_i=normrnd(0,sigma_i,[1,n_steps]);
theta_i(1)=0;

%small possibility of introducing one kink in the arm
luck=rand;
if luck>0.95 & n_steps>50
    %pick a random point on the arm
    i_point=round(rand_between(n_steps*0.3,n_steps*0.9));
    theta_i(i_point)=rand_between(30,90);
end

running_sum=cumsum(theta_i);%the cumulative sum of angles for each filament
x=zeros(1,n_steps);%make empty arrays for storing x and y coordinates for random walks
y=zeros(1,n_steps);

%in this for-loop, fill x and y arrays using the simulated angles
for i=1:n_steps
    if i==1
        x=cosd(running_sum(i));
        y=sind(running_sum(i));
    else
        x(i)=x(i-1)+cosd(running_sum(i));
        y(i)=y(i-1)+sind(running_sum(i));
    end
end

%smooth the x-y curve.
for counter=1:30
    x=smooth(x);y=smooth(y);
end

%now measure the inital angle
for i=1:3%look at three vectors each of Length 2 (or 3, between 3 neighboring dots)
    vector=[x(i+4)-x(i+2),y(i+4)-y(i+2)];
    initial_angle(i)=atand(vector(2)/vector(1));
end
off_angle=mean(initial_angle);%calculate the inital angle that the filament is off by
R = [cosd(-off_angle) -sind(-off_angle); sind(-off_angle) cosd(-off_angle)];%rotation matrix so the filament is at 0 degrees
rotated = (R*[x,y]')';

% %if you want to check these filaments visually:
% plot(rotated(:,1),rotated(:,2));
% daspect([1 1 1])
% pause(1);

%rotate to achieve the desired orientation. Note the handedness.
R = [cosd(angle) -sind(angle); sind(angle) cosd(angle)];%rotation matrix
rotated_again = (R*rotated')';

%translate the filament so it starts at the desired point.
x=rotated_again(:,1)+center(1);
y=rotated_again(:,2)+center(2);

for i=1:n_steps 
    if i==1 %does not mark first point to create the characteristic void in the middle of the nunchuck
        continue
    end
    if round(x(i))-1<1 || round(x(i))+1>200 || round(y(i))-1<1 || round(y(i))+1>200
        break
    end
    image(round(y(i))-1:round(y(i))+1,round(x(i))-1:round(x(i))+1)=uint8(brightness);%marks a 2x2 area at next point with input brightness
end

%small possibility of drawing part of the arm brighter
luck=rand;
if luck>0.5 & n_steps>10
    %note that since the image is in uint8 format, bright values > 255 will become 255 automatically
    extra_bright=rand_between(brightness*0.2,brightness*0.4);
    layer=zeros(200,'uint8');
    %pick a section on the arm
    start_point=round(rand_between(1,n_steps-1));
    end_point=round(rand_between(start_point,n_steps));
    if end_point>start_point
        for i=start_point:end_point
            if round(x(i))-1<1 || round(x(i))+1>200 || round(y(i))-1<1 || round(y(i))+1>200
                break
            end
            layer(round(y(i))-1:round(y(i))+1,round(x(i))-1:round(x(i))+1)=uint8(extra_bright);%marks a 2x2 area at next point with input brightness
        end
    end
    image=image+layer;
end
%draw this section brighter

out=image;
x_contour=x;
y_contour=y;
end