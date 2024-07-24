clear all

RGB1 = imread('GingerBreadMan_first.jpg');
RGB2 = imread('GingerBreadMan_second.jpg');

grey1 = rgb2gray(RGB1);
grey2 = rgb2gray(RGB2);

max_corners = 300;
C = corner(grey1, max_corners);

imshow(RGB1);
hold on
plot(C(:, 1), C(:, 2), '*b');

% Initialize the optical flow with Lucas-Kanade method
opticFlow = opticalFlowLK('NoiseThreshold',0.009);

% Estimate optical flow between the two grayscale images
flow = estimateFlow(opticFlow, grey1); % Initialize with the first frame
flow = estimateFlow(opticFlow, grey2); % Estimate flow to the second frame

% Visualize the optical flow on the second image
imshow(RGB2);
hold on;

% Define the scale for better visualization of the flow vectors
scale = 10;

% For each corner point, plot the corresponding optical flow vector
for i = 1:size(C,1)
    x = C(i, 1);
    y = C(i, 2);
    
    % Ensure the corner points are within the bounds of the flow matrix
    if x >= 1 && x <= size(flow.Vx,2) && y >= 1 && y <= size(flow.Vy,1)
        vx = flow.Vx(round(y), round(x));
        vy = flow.Vy(round(y), round(x));
        quiver(x, y, vx*scale, vy*scale, 'y', 'LineWidth', 1);
    end
end
