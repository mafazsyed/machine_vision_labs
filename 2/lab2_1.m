% Clear all previous data from workspace to ensure a clean start
clear all;

% Load RGB images of first and second GingerBreadMand and Static Red Square from JPEG files
RGB1 = imread('GingerBreadMan_first.jpg');
RGB2 = imread('GingerBreadMan_second.jpg');
RGB3 = imread('red_square_static.jpg');

% Convert RGB images to grayscale
grey1 = rgb2gray(RGB1);
grey2 = rgb2gray(RGB2);
grey3 = rgb2gray(RGB3);

% Define maximum corner thresholds for corner detection
max_corners_gingerbreadman = 700; % Set threshold to accurately capture corners of GingerBreadMan
max_corners_square = 4;           % Set threshold for the simple geometry of the red square

% Perform corner detection on the grayscale images
C_gingerbreadman = corner(grey1, max_corners_gingerbreadman);  % Detect corners in first GingerBreadMan image
C_square = corner(grey3, max_corners_square);                  % Detect corners in red square image

% Visualize the corners on the original images
% For the GingerBreadMan
imshow(RGB1);                     % Display the first GingerBreadMan image
hold on;                          % Retain the current image and its current settings
plot(C_gingerbreadman(:, 1), C_gingerbreadman(:, 2), '*b', 'MarkerSize', 5);  % Plot corners detected (in blue asterisks)
figure;                           % Create a new figure window for subsequent plots

% For the Red Square
imshow(RGB3);                     % Display the red square image
hold on;                          % Retain the current image and its current settings
plot(C_square(:, 1), C_square(:, 2), '*b', 'MarkerSize', 7);  % Plot corners detected (in blue stars, slightly larger size)
