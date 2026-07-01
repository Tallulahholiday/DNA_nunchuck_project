function[frame,nunchuck_center,wait_time]=click(button,frame,wait_time,x,y,found_object,i_nunchuck,all_object_centers)

nunchuck_center=[nan,nan];%just a placeholder

if isempty(button)%if pressed a non-supported key, do nothing.
    frame=frame-1;
elseif button==122%if pressed z, pause and take a break until another key is pressed.
    w=waitforbuttonpress;
    frame=frame-1;
elseif button==28%if pressed "left" arrow key on keyboard
    frame=frame-2;
elseif button==115 %if pressed "s" (meaning user will "select")
    while button~=1%keep waiting for user input unless user left clicks
        [x,y,button] = myginput(1,'fullcross');
        if button==1%if left clicked
            nunchuck_center=[x,y];
        end
    end
elseif button==32 %if user didn't press, but virtual keyboard did
    if found_object==1%if ANY object was detected
        nunchuck_center=all_object_centers(i_nunchuck,:);
    else %if no object was found, ignore the virtual keyboard press
        frame=frame-1;
    end
elseif button==1%if left clicked
    nunchuck_center=[x,y];%record clicking coordinates, move on to the next frame
elseif button==45%if user pressed "-" key
    wait_time=wait_time+0.1;
    frame=frame-1;
elseif button==61%if user pressed "+" key
    if wait_time>=0.1
        wait_time=wait_time-0.1;
    end
    frame=frame-1;
elseif button==48%if user pressed "0" key
    frame=frame-5;%go back 5 frames
elseif button==53%if user pressed "5" key
    wait_time=0.5;
    frame=frame-1;
elseif button==50%if user pressed "2" key
    wait_time=0.2;
    frame=frame-1;
elseif button==49%if user pressed "1" key
    wait_time=0.1;
    frame=frame-1;
else%if pressed some other key, in effect we should do nothing
    frame=frame-1;
end
clear button