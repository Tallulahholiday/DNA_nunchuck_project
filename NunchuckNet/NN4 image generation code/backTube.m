function complete_image=backTube(nunchuck_image,x_arms,y_arms)

%first, determine whether to draw tubes
if rand<0.2
    tube1=1;%will draw tube 1
    if rand<0.05
        tube2=1;
    else
        tube2=0;
    end
else
    tube1=0;
end

if tube1==1 %if we decided to draw a tube
    crossing=1;%initialize default
    while crossing==1 %unless the "no_tube_crossing" criterium is satisfied, draw a new tube
        brightness=(255-20)*rand+20;%brightness is between 20 and 255      
        center=[rand*200,rand*200];%random starting point for the tube
        empty_image=zeros(200,'uint8');%prepare empty frame
        lower=15; %(originally 25)
        len=lower+85*rand;
        [tube1_image,x_tube,y_tube]=arm(empty_image,rand*360,brightness,center,len);%draws a tube
        
        %check whether there's tube crossing
        crossing=0;%initialize default, assuming no crossing until we find one
        for i=1:length(x_tube)%check each point on this tube
            for j=1:length(x_arms)
                if abs(x_tube(i)-x_arms(j))<10 & abs(y_tube(i)-y_arms(j))<10 % if any point on the tube is crossing any arm (or getting too close)
                    crossing=1;%mark crossing
                end
            end
        end
    end
    %now we havedrawn tube 1 with no crossing.
    complete_image=nunchuck_image+tube1_image;
    
    if tube2==1 %if we decided to draw a second tube
        crossing=1;%initialize default
        while crossing==1 %unless the "no_tube_crossing" criterium is satisfied, draw a new tube
            brightness=(225-50)*rand+50;%brightness is between 50 and 225      
            center=[rand*200,rand*200];%random starting point for the tube
            empty_image=zeros(200,'uint8');%prepare empty frame
            lower=15; %(originally 25)
            len=lower+85*rand;
            [tube2_image,x_tube,y_tube]=arm(empty_image,rand*360,brightness,center,len);%draws a tube

            %check whether there's tube crossing
            crossing=0;%initialize default, assuming no crossing until we find one
            for i=1:length(x_tube)%check each point on this tube
                for j=1:length(x_arms)
                    if abs(x_tube(i)-x_arms(j))<10 & abs(y_tube(i)-y_arms(j))<10 % if any point on the tube is crossing any arm
                        crossing=1;%mark crossing
                    end
                end
            end
        end
        %now we havedrawn tube 2 with no crossing.
        complete_image=complete_image+tube2_image;
    end
    
else %if we don't want to draw any tube
    complete_image=nunchuck_image;%don't modify the input image
end