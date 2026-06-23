%This function rounds off values VERY close to 0 to 0 
function [output] = round_down(input)

rounded=round(input);
if rounded>input
    output=rounded-1;
else
    output=rounded;
end