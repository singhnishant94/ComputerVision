function [ img_dir ] = connected_components( path, color)

    if ((color < 0) || (color > 1))
        disp(['Usage: connected_components(<path to directory>, <0 or 1, 0 for grayscale, 1 for color>)']);
        return;
    end
    img_dir = dir(path);
    num_imgs = length(img_dir);
    disp(num_imgs);
    I = cell(1,num_imgs-2);
    ind = 1;
    for i=1:num_imgs
        if(img_dir(i).name(1) == '.')
            continue;
        end
        disp(img_dir(i).name);
        I{ind} = imread(fullfile(path, img_dir(i).name));
        ind = ind +1;
    end;
    
        
    
    
    num_imgs = num_imgs-2;
    top_k_matches = cell(num_imgs, num_imgs);
    [height, width] = size(rgb2gray(I{1}));
    thresh = (height*width*50)/(240*320);
    connected = zeros(1, num_imgs);
    group_no = 1;
    for i=1:num_imgs
        for j=i+1:num_imgs
            %if(i==j) continue; end;
            im1 = rgb2gray(I{i});
            im2 = rgb2gray(I{j});
            [matches, num] = match(im1, im2);
            
            
            disp(['Matches for ', num2str(i),' ', num2str(j),' : ',num2str(length(matches))]);
            
            if(num > thresh)
                top_k_matches{i,j} = matches;
                matches(:,[1,3])=matches(:,[3,1]);
                matches(:,[2,4])=matches(:,[4,2]);
                top_k_matches{j,i} = matches;
                if connected(i) ~=0
                    connected(j) = connected(i);
                elseif connected(j) ~= 0
                        connected(i) = connected(j);
                else 
                    connected(i) = group_no;
                    connected(j) = group_no;
                    group_no = group_no + 1;
                end
            end;
        end;
    end;
    disp(connected)
    for i=1:(group_no-1)
        I_connected = {};
        counter = 1;
        for j=1:num_imgs
            if connected(j) == i                
                I_connected{counter} = I{j};                
                counter = counter + 1;
            end
        end
        top_k_matches_con = {};
        cnt1 = 1 ;       
        for i1=1:num_imgs
           cnt2 = cnt1+1;
           for j1=i1+1:num_imgs
               if connected(i1) == i && connected(j1)== i
                  top_k_matches_con{cnt1, cnt2} = top_k_matches{i1, j1};
                  top_k_matches_con{cnt2, cnt1} = top_k_matches{j1, i1};
                  cnt2 = cnt2+1;
               end
           end
           if cnt2 ~= cnt1+1
               cnt1 = cnt1 + 1;
           end
        end
        disp(size(top_k_matches_con))
        stitch_images(I_connected, top_k_matches_con, ['output', num2str(i), '.jpg'], color)
    end
    disp(connected);
    