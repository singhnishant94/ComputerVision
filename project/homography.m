function [A, H, S] = homography(im1, im2)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

num = match(im1, im2);

A = [];
for i = 1:10
    A = [A; [-num(i,1) -num(i,2) -1 0 0 0 num(i,1)*num(i,3) num(i,3)*num(i,2) num(i,3)]];
    A = [A; [0 0 0 -num(i,1) -num(i,2) -1 num(i,4)*num(i,1) num(i,4)*num(i,2) num(i,4)]];
end;

[U,S,V] = svd(A);

H = reshape(V(:,9), [3,3]);
H = H';
end

