function [Ired] = mywarp(I,P)
I1=im2double(I);
height = size(I,1);
width = size(I,2);
Ired = zeros(4*height, 4*width);

for i=1:4*height
    for j=1:4*width
    v2 = [j-(width/2+width);i-(height/2+height);1];
    v1 = inv(P)*v2;
    v3 = v1/v1(3,1);
    rounded = [round(1+v3(1,1)); round(1+v3(2,1)); round(1+v3(3,1))];
    if (rounded(1,1) < 1 || rounded(2,1) < 1 || rounded(3,1) < 1 || rounded(2,1) > size(I,1) || rounded(1,1) > size(I,2))
        continue;
    else
        Ired(i,j) = I1(rounded(2,1), rounded(1,1));
    end;
    %{
    v2 = P*v1;
    v3 =v2/v2(3,1);
    if (v3(1,1) <0 || v3(2,1)<0 || v3(3,1)<0 || round(1+v3(2,1)) > size(I,1) || round(1+v3(1,1)) > size(I,2))
       continue;
    else     
        Ired(round(1+v3(2,1)),round(1+v3(1,1)))=I1(i,j);
    end
        %}
end 
end
