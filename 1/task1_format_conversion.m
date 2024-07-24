clear all

% Read RGB Image
RGB = imread('Dog.jpg');
%figure, imshow(RGB);

% Convert to Grayscale
gray = rgb2gray(RGB);
%figure, imshow(grey);

% Convert to HSV
HSV = rgb2hsv(RGB);

% Convert to Binary
binary = imbinarize(gray, 0.35);
figure, imshow(binary);

% Convert to YCbCr
YCbCr = rgb2ycbcr(RGB);

% Adjust Contrast of Grayscale Image
adjustedGray = imadjust(gray);

% Edge Detection on Grayscale Image
edgessobel = edge(gray, 'sobel');
edgescanny = edge(gray, 'canny');
edgesprewitt = edge(gray, 'prewitt');
edgesroberts = edge(gray, 'roberts');
edgeslog = edge(gray, 'log');


figure, imshow (YCbCr);
figure, imshow (adjustedGray);
figure, imshow (edgessobel);
figure, imshow (edgescanny);
figure, imshow (edgesprewitt);
figure, imshow (edgesroberts);
figure, imshow (edgeslog);