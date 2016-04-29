function [ aaa ] = stitch_images( I, top_k_matches, output, color )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    
    
    
    
    num_imgs = size(I,2);
    colored = 0;
    if (size(I{1},3)>1)
        colored = 1;
    end
    if colored == 1
        [height, width] = size(rgb2gray(I{1}));
    else 
        [height, width] = size(I{1});
    end
    
    %{
    dist_mask = zeros([height, width]);
    dist_mask(height/2, width/2) = 1;
    dist_mask = bwdist(dist_mask);
    %}
    
    %Homography accumulator
    homo_accum = cell(1,num_imgs);
    centers = cell(1, num_imgs);
    
    w_mul = 6;
    
    h_mul = 2;
    
    for i=1:num_imgs
        homo_accum{i} = eye(3);
        centers{i} = [h_mul*height/2, w_mul*width/2, 1];
    end;
    
    
    
    if (color == 1)
        channels = 3;
    else
        channels = 1;
    end
    
    
    %halphablend = vision.AlphaBlender;
    
    
    canvas = zeros(h_mul*height, w_mul*width, channels);
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
        
        im1 = I{indx};
        im2 = I{indy};
        if (color == 0 && colored == 1)
            im1 = rgb2gray(I{indx});
            im2 = rgb2gray(I{indy});
        end
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
        im_w1 = mywarp(im1, H, h_mul, w_mul);
        
        %update center of warped image
        homo_cord_cent = H*centers{indx}';
        centers{indx} = homo_cord_cent/homo_cord_cent(3,1);
        centers{indx} = centers{indx}';
        disp(['Center of ', num2str(indx), ' is ']);
        disp(centers{indx});
        
        homo_accum{indx} = H;
        
        %{
        %%%%%For blending
        mask = ones(height, width, channels);
        
        px = 35;
        mask(1:px,:,:) = 0;
        mask(height-px:height,:,:) = 0;
        
        
        mask(:,1:px,:) = 0;
        mask(:,width-px:width,:) = 0;
        %}
        
        
        disp('Adding to canvas');
        if (length(on_canvas) == 0)
            on_canvas = [on_canvas indx indy];
            im_a2 = mywarp(im2, eye(3), h_mul, w_mul);
            %{
            %%%%%For blending
            imwrite(im_a2, 'im_a2.jpg');
            imwrite(im_w1, 'im_w1.jpg');
            %mask((h_mul-1)*height/2:(h_mul+1)*height/2, (w_mul-1)*width/2:(w_mul+1)*width/2, :) = 1;
            %mask(200:300, 250:350, :) = 1;
            %maska = mywarp(mask, eye(3), 2, 2);
            %maskb = ones
            maskb = mywarp(mask, H, 2, 2);
            %mask(120:240, 160:320, :) = 1;
            %imshow(mask)
            %maskb = 1 - maska;
            %figure, imshow(maska);
            %figure, imshow(maskb);
            %canvas = blendtest(im_a2, im_w1, maskb, 1-maskb);
            %{
            figure, imshow(mask);
            blurh = fspecial('gauss',30,15); % feather the border
            maska = imfilter(maska,blurh,'replicate');
            maskb = imfilter(maskb,blurh,'replicate');
            canvas = maska.*im_a2+maskb.*im_w1;
            %}
            %figure, imshow(im_w1);
            %canvas = arrayfun(stitch_helper, im_w1, im_a2);
            %}
            
            for c = 1:size(im_a2,3)
                for i = 1:size(im_a2,1)
                    for j = 1:size(im_a2,2)
                        xc = centers{indx};
                        yc = centers{indy};
                        
                        
                        if(im_w1(i,j,c) == 0 || im_a2(i,j,c) == 0)
                            if (im_w1(i,j,c) > im_a2(i,j,c))
                                canvas(i,j,c) = im_w1(i,j,c);
                                %mask(i,j,c) = 1;
                            else
                                canvas(i,j,c) = im_a2(i,j,c);
                                %mask(i,j,c) = 0;
                            end
                        else
                            
                            d1 = dist([i,j], [xc(1,1), xc(1,2)]);
                            d2 = dist([i,j], [yc(1,1), yc(1,2)]);
                            canvas(i,j,c) = (d1*im_w1(i,j,c) + d2*im_a2(i,j,c))/(d1+d2);
                            %mask(i,j,c) = 1;
                            %{
                            if (dist([i,j], [xc(1,1), xc(1,2)]) < dist([i,j],[yc(1,1), yc(1,2)]))
                                %canvas(i,j,c) = im_w1(i,j,c);
                                mask(i,j,c) = 1;
                            else
                                %canvas(i,j,c) = im_a2(i,j,c);
                                mask(i,j,c) = 0;
                            end
                            %}
                            %canvas(i,j,c) = (im_w1(i,j,c) + im_a2(i,j,c))/2;
                        end
                        
                    end
                end
            end
            %{
            %%%%%For blending
            figure, imshow(mask);
            figure, imshow(canvas);
            canvas = blendtest(canvas, im_a2, 1-mask, mask);
            %}
            %{
            gaussfil = fspecial('gaussian', [50 50],2);
            mask_sm = imfilter(mask, gaussfil);
            canvas = im_w1.*mask_sm + im_a2.*(1-mask_sm);
            %}
            %{
            canvas = blendtest(im_w1, im_a2);
            %canvas = step(halphablend,im_w1, im_a2);
            
            gaussfil = fspecial('gaussian', [5 5], 2);
            mask_sm = imfilter(mask, gaussfil);
            canvas = im_w1.*mask_sm + im_a2.*(1-mask_sm);
            %}
            %canvas = blendtest(im_w1, im_a2, mask);
        else
            if (ismember(indx, on_canvas))
                on_canvas = [on_canvas indy];
            else
                on_canvas = [on_canvas indx];
            end
            %canvas = arrayfun(stitch_helper, im_w1, canvas);
            %figure, imshow(im_w1);
            for c = 1:size(canvas,3)
                for i = 1:size(canvas,1)
                    for j = 1:size(canvas,2)
                        if(im_w1(i,j,c) == 0 || canvas(i,j,c) == 0)
                            canvas(i,j,c) = max(im_w1(i,j,c), canvas(i,j,c));
                            if (im_w1(i,j,c) > canvas(i,j,c))
                                %canvas(i,j,c) = im_w1(i,j,c);
                                mask(i,j,c) = 1;
                            else
                                %canvas(i,j,c) = canvas(i,j,c);
                                mask(i,j,c) = 0;
                            end
                        else
                            
                            xc = centers{indx};
                            yc = centers{indy};
                            d1 = dist([i,j], [xc(1,1), xc(1,2)]);
                            d2 = dist([i,j], [yc(1,1), yc(1,2)]);
                            
                            canvas(i,j,c) = (d1*im_w1(i,j,c) + d2*canvas(i,j,c))/(d1+d2);
                            %{
                            if (dist([i,j], [xc(1,1), xc(1,2)]) < dist([i,j],[yc(1,1), yc(1,2)]))
                                %canvas(i,j,c) = im_w1(i,j,c);
                                mask(i,j,c) = 1;
                            else
                                %canvas(i,j,c) = canvas(i,j,c);
                                mask(i,j,c) = 0;
                            end
                            %}
                            %canvas(i,j,c) = (im_w1(i,j,c) + canvas(i,j,c))/2;
                        end
                    end
                end
            end
            %{
            gaussfil = fspecial('gaussian', [50 50],2);
            mask_sm = imfilter(mask, gaussfil);
            canvas = im_w1.*mask_sm + canvas.*(1-mask_sm);
            %}
            %canvas = step(halphablend,im_w1, canvas);
            %{
            gaussfil = fspecial('gaussian', [5 5],2);
            mask_sm = imfilter(mask, gaussfil);
            canvas = im_w1.*mask_sm + canvas.*(1-mask_sm);
            
            canvas = blendtest(im_w1, canvas);
            %}
            %canvas = blendtest(im_w1, canvas, mask);
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

