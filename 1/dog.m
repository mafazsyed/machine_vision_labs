clear all

l = imread('Dog.jpg');
size(l);
imshow(l);
lg = rgb2gray(l);
imshow(lg);

imwrite(l,'Dog.jpg');
imfinfo Dog.jpg

l_b = l - 100;
figure, imshow(l_b)
l_s = l + 100;
figure, imshow(l_s)

flip = flipLtRt(l);
figure, imshow(flip)

% ................... %
% Color the duck yellow!
figure;
im= imread('duckMallardDrake.jpg');
imshow(im);
[nr,nc,np]= size(im);
newIm= zeros(nr,nc,np);
newIm= uint8(newIm);

for r= 1:nr
    for c= 1:nc
        if ( im(r,c,1)>180 && im(r,c,2)>180 && im(r,c,3)>180 )
            % white feather of the duck; now change it to yellow
            newIm(r,c,1)= 225;
            newIm(r,c,2)= 225;
            newIm(r,c,3)= 0;
        else % the rest of the picture; no change
            for p= 1:np
                newIm(r,c,p)= im(r,c,p);
            end
        end
    end
end
figure
imshow(newIm)

% .................... %
figure;
im = imread('Two_colour.jpg'); % read the image
imshow(im);
% extract RGB channels separatelly
red_channel = im(:, :, 1);
green_channel = im(:, :, 2);
blue_channel = im(:, :, 3);
% label pixels of yellow colour
yellow_map = green_channel > 150 & red_channel > 150 & blue_channel < 50;
% extract pixels indexes
[i_yellow, j_yellow] = find(yellow_map > 0);
% visualise the results
figure;
imshow(im); % plot the image
hold on;
scatter(j_yellow, i_yellow, 5, 'filled') % highlighted the yellow pixels