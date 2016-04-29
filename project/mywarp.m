function [Ired] = mywarp(I,P, h_mul, w_mul)
I1=im2double(I);
height = size(I,1);
width = size(I,2);
channel = size(I,3);

Ired = zeros(h_mul*height, w_mul*width);

k = 0

for c=1:channel
    for i=1:h_mul*height
        for j=1:w_mul*width
        v2 = [j-((w_mul-1)*width/2);i-((h_mul-1)*height/2);1];
        v1 = inv(P)*v2;
        v3 = v1/v1(3,1);
        rounded = [round(1+v3(1,1)); round(1+v3(2,1)); round(1+v3(3,1))];
        if (rounded(1,1) < 1 || rounded(2,1) < 1 || rounded(3,1) < 1 || rounded(2,1) > size(I,1) || rounded(1,1) > size(I,2))
            continue;
        else
            Ired(i,j,c) = I1(rounded(2,1), rounded(1,1),c);
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
end
