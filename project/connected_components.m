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
    colored = 0;
    if (size(I{1},3)>1)
        colored = 1;
    end
    if colored == 1        
        [height, width] = size(rgb2gray(I{1}));
    else
         [height, width] = size(I{1});
    end
         
    thresh = (height*width*30)/(240*320);
    edge = zeros(num_imgs, num_imgs);
    group_no = 1;
    for i=1:num_imgs
        for j=i+1:num_imgs
            %if(i==j) continue; end;
            if colored == 1
                im1 = rgb2gray(I{i});
                im2 = rgb2gray(I{j});
            else
                im1 = I{i};
                im2 = I{j};
            end
            [matches, num] = match(im1, im2);
            
            
            disp(['Matches for ', num2str(i),' ', num2str(j),' : ',num2str(length(matches))]);
            
            if(num > thresh)
                top_k_matches{i,j} = matches;
                matches(:,[1,3])=matches(:,[3,1]);
                matches(:,[2,4])=matches(:,[4,2]);
                top_k_matches{j,i} = matches;
                edge(i, j) = 1;
                edge(j, i) = 1;               
            end;
        end;
    end;
    
    done = zeros(1, num_imgs);
    group_no = 1;
    connected = zeros(1, num_imgs);
   
    for i=1:num_imgs   
        if done(i) == 0
            queue = [i];
            connected(i) = group_no;
            index = 1;
            done(i) = 1;
            while index<=size(queue, 2)
                disp(queue)
                for j=1:num_imgs
                    if done(j) == 0 && edge(queue(index), j)                     
                        done(j) = 1;
                        connected(j) = group_no;
                        queue = horzcat(queue, [j]);
                    end
                end
                index = index + 1;
            end
            group_no = group_no + 1;            
        end
    end
    
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
    