function output=diffus(image)%solves the 2D diffusion equation to spread out the nunchuck

Nt=round(25*rand+15); %number of time steps (random with min of 15)
dt=0.1; %time step size-arbitrary units
D=1; %diffusion coefficient
dx=1; %step size

image=im2double(image); %converts imnage to double in order to make the calculations

PNew=image; %douplicates image

for k=1:Nt %time loop
    for i=2:199 %space loops 
        for j=2:199
            PNew(i,j)=double(image(i,j))+(D*dt)/(dx^2)*(image(i+1,j)+image(i-1,j)+image(i,j+1)+image(i,j-1)-4*image(i,j));
            %finite difference method for diffusion equation
        end
    end
    image=PNew; %passes new values of image for next loop
end

image=im2uint8(image); %converts image back to 8bit

output=image;
end 