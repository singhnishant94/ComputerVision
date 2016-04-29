function [ img_dir ] = stitch_images( I, top_k_matches, output )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    num_imgs = size(I, 2);
    %Homography accumulator
    homo_accum = cell(1,num_imgs);
    
    for i=1:num_imgs
        homo_accum{i} = eye(3);
    end;
    
    
    %{
    %First image's closest match
    highest = 0; 
    highest_ind = 0;
    for i=2:num_imgs
        if(length(top_k_matches{1,i}) > highest)
            highest = length(top_k_matches{i,i});
            highest_ind = i;
        end
    end
    %}
    [height, width] = size(rgb2gray(I{1}));
    canvas = zeros(2*height, 2*width);
    disp(size(canvas));
    on_canvas = [];
    while (length(on_canvas) < num_imgs)
        
        indx = 0;
        indy = 0;
        max_matches = 0;
        
        disp('Finding maximum matching pair');
        for i=1:num_imgs
            for j=i+1:num_imgs
                if (length(on_canvas)==0 || (~ismember(i,on_canvas) && ismember(j,on_canvas)) || (ismember(i,on_canvas) && ~ismember(j,on_canvas)))
                    disp('ij:');
                    disp(i);
                    disp(j);
                    num_matches = length(top_k_matches{i,j});
                    disp(num_matches);
                    if (num_matches > max_matches)
                        max_matches = num_matches;
                        indx = i;
                        indy = j;
                    end
                end
            end
        end
        
        if ismember(indx, on_canvas)
            tmp = indx;
            indx = indy;
            indy = tmp;
        end
        
        disp(['Maximum matching pair is ', num2str(indx), num2str(indy)]);
        
        im1 = rgb2gray(I{indx});
        im2 = rgb2gray(I{indy});
        matches = top_k_matches{indx,indy};
        matches1 = matches(:,1:2);
        matches1 = matches1';
        matches2 = matches(:,3:4);
        matches2 = matches2';
        
        disp('Computing homography')
        [H, inliers] = ransacfithomography(matches1, matches2, 0.005);
        H = H/H(3,3);
        disp(['Accumulated H for ', num2str(indy)]);
        disp(homo_accum{indy})
        H = homo_accum{indy}*H;
        H = H/H(3,3)
        
        disp(['Warping', num2str(indx)])
        im_w1 = mywarp(im1, H);
        
        homo_accum{indx} = H;
        
        disp('Adding to canvas')
        if (length(on_canvas) == 0)
            on_canvas = [on_canvas indx indy];
            im_a2 = mywarp(im2, eye(3));
            %canvas = arrayfun(stitch_helper, im_w1, im_a2);
            
            for i = 1:size(im_a2,1)
                for j = 1:size(im_a2,2)
                    if(im_w1(i,j) == 0 || im_a2(i,j) == 0)
                        canvas(i,j) = max(im_w1(i,j), im_a2(i,j));
                    else
                        canvas(i,j) = (im_w1(i,j) + im_a2(i,j))/2;
                    end
                end
            end
            
        else
            if (ismember(indx, on_canvas))
                on_canvas = [on_canvas indy];
            else
                on_canvas = [on_canvas indx];
            end
            %canvas = arrayfun(stitch_helper, im_w1, canvas);
            
            for i = 1:size(canvas,1)
                for j = 1:size(canvas,2)
                    if(im_w1(i,j) == 0 || canvas(i,j) == 0)
                        canvas(i,j) = max(im_w1(i,j), canvas(i,j));
                    else
                        canvas(i,j) = (im_w1(i,j) + canvas(i,j))/2;
                    end
                end
            end
            
        end
        
        
        disp(on_canvas);
    end
        
    imwrite(canvas, output);
    %figure, imshow(canvas), title('Mosaic');
    
    %{
    disp(I);
    im1 = rgb2gray(I{1});
    im2 = rgb2gray(I{2});
    im3 = rgb2gray(I{3});
    %imshow(i1);
    %sift(i1);
    matches = top_k_matches{1,2};
    matches1 = matches(:,1:2);
    matches1 = matches1';
    matches2 = matches(:,3:4);
    matches2 = matches2';
    [H, inliers] = ransacfithomography(matches1, matches2, 0.005);
    disp(H);
    H = H/H(3,3);
    im_w1 = mywarp(im1, H);
    I = [1 0 0; 0 1 0; 0 0 1];
    im_a2 = mywarp(im2, I);
    disp(size(im_w1));
    disp(size(im_a2));
    %{
    figure, imshow(im1), title('first image');
    figure, imshow(im2), title('second image');
    figure, imshow(im3), title('first image warped');
    figure, imshow(im4), title('second image adjusted');
    %}
    im_res = zeros(size(im_a2));
    for i = 1:size(im_a2,1)
        for j = 1:size(im_a2,2)
            if(im_w1(i,j) == 0 || im_a2(i,j) == 0)
                im_res(i,j) = max(im_w1(i,j), im_a2(i,j));
            else
                im_res(i,j) = (im_w1(i,j) + im_a2(i,j))/2;
            end
        end
    end
    figure, imshow(im_res), title('Mosaic');
    %}
end

