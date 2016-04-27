function output = stitch_helper( x, y )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
    if(x == 0 || y == 0)
        output = max(x, y);
    else
        output = (x + y)/2;
    end

end

