clear all
I = imread('Dog.jpg');
Im_grey = rgb2gray(I);
figure, imshow(Im_grey);
figure, imhist(Im_grey);
xlabel('Number of bins (256 by default for a greyscale image)')
ylabel('Histogram counts')

h = imhist(Im_grey);
h1 = h(1:10:256);
horz = 1:10:256;
figure, bar(horz,h1)
figure, plot(h);

r= double(I(:,:,1));
g = double(I(:,:,2));
b = double(I(:,:,3));
figure, hist(r(:),124)
title('Histogram of the red colour')
figure, hist(g(:),124)
title('Histogram of the green colour')
figure, hist(b(:),124)
title('Histogram of the blue colour')



for thresholdValue = 50:50:200;
    thresholdNormalised = thresholdValue / 255;
    ImBinary = im2bw(I, thresholdNormalised);
    figure, imshow(ImBinary);
end