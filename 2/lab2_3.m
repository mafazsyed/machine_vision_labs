% Clear all previous data from workspace to ensure a clean start
clear all;

% Initialize the video reader object for the input video file
videoReader = VideoReader('red_square_video.mp4');

% Read the first frame from the video and convert it to grayscale
frameRGB = readFrame(videoReader);   % Read the first video frame in RGB
frameGrey = rgb2gray(frameRGB);      % Convert the RGB frame to grayscale

% Setup the optical flow object using Lucas-Kanade method with a specified noise threshold
opticFlow = opticalFlowLK('NoiseThreshold', 0.009);

% Perform initial optical flow estimation on the first frame
flow = estimateFlow(opticFlow, frameGrey);

% Detect corners in the first frame using Harris corner detector
corners = detectHarrisFeatures(frameGrey);
pointOfInterest = corners.Location(1,:);  % Initialize tracking with the first corner (top left) position
track = pointOfInterest;  % Start tracking the point of interest

% Process each frame in the video
while hasFrame(videoReader)
    frame = readFrame(videoReader);         % Read the next frame
    grayFrame = rgb2gray(frame);            % Convert the frame to grayscale
    
    % Update the optical flow with the current frame
    flow = estimateFlow(opticFlow, grayFrame);
    
    % Redetect corners in the current frame
    corners = detectHarrisFeatures(grayFrame);
    
    % Calculate distances from the current point of interest to all detected corners
    distances = sqrt(sum((corners.Location - pointOfInterest).^2, 2));
    [minDistance, index] = min(distances);
    nearestCorner = corners.Location(index,:);
    
    % Update the point of interest based on the flow velocities at the nearest corner
    vx = flow.Vx(round(nearestCorner(2)), round(nearestCorner(1)));
    vy = flow.Vy(round(nearestCorner(2)), round(nearestCorner(1)));
    pointOfInterest = [nearestCorner(1) + vx, nearestCorner(2) + vy];
    
    % Append the new point of interest to the tracking path
    track = [track; pointOfInterest];
end

% Load ground truth tracking data
load('red_square_gt.mat', 'gt_track_spatial');

% Visualization of tracking results
figure;
imshow(frame);
hold on;
plot(track(:,1), track(:,2), '.', 'LineWidth', 1); % Plot the estimated trajectory in blue dots
plot(gt_track_spatial(:,1), gt_track_spatial(:,2), 'g', 'LineWidth', 1); % Plot the ground truth trajectory in green
legend('Estimated Trajectory', 'Ground Truth Trajectory');
hold off;

% Load revised ground truth data
load('new_red_square_gt.mat', 'ground_truth_track_spatial_coordinates');
load('red_square_gt.mat', 'gt_track_spatial');

% Adjust track data by removing the last point, which comes from the algorithm initialisation
track_adj = track(1:end-1,:);

% Adjust ground truth data by removing the first point
ground_truth_track_spatial_coordinates_adj = ground_truth_track_spatial_coordinates(2:end,:);

% Check & match the lengths of the adjusted track and ground truth data
track_adj = track_adj(1:size(ground_truth_track_spatial_coordinates_adj, 1), :);

% Calculate RMSE between the adjusted track and the ground truth
numFrames = size(track_adj, 1);
rmse_x_per_frame = zeros(numFrames, 1);
rmse_y_per_frame = zeros(numFrames, 1);
rmse_per_frame = zeros(numFrames, 1);

for i = 1:numFrames
    diff_x_frame = track_adj(i,1) - ground_truth_track_spatial_coordinates_adj(i,1);
    diff_y_frame = track_adj(i,2) - ground_truth_track_spatial_coordinates_adj(i,2);
    rmse_x_per_frame(i) = sqrt(diff_x_frame^2);
    rmse_y_per_frame(i) = sqrt(diff_y_frame^2);
    % rmse_per_frame(i) = sqrt((diff_x_frame^2 + diff_y_frame^2));
    rmse_per_frame(i) = sqrt((track_adj(i,1) - ground_truth_track_spatial_coordinates_adj(i,1))^2 + (track_adj(i,2) - ground_truth_track_spatial_coordinates_adj(i,2))^2);
end

rmse_x_mean = mean(rmse_x_per_frame);
rmse_y_mean = mean(rmse_y_per_frame);
overall_rmse = mean(rmse_per_frame);

% Display RMSE results
disp(['RMSE X: ', num2str(rmse_x_mean)]);
disp(['RMSE Y: ', num2str(rmse_y_mean)]);
disp(['Overall RMSE: ', num2str(overall_rmse)]);

% Plot the RMSE over frames
figure;
plot(2:numFrames, rmse_per_frame(2:end), '-b', 'LineWidth', 1, 'DisplayName', 'RMSE_{xy}');
hold on;
plot(2:numFrames, rmse_x_per_frame(2:end), 'Color', [0, 0.5, 0], 'LineWidth', 1, 'DisplayName', 'RMSE_{x}');
plot(2:numFrames, rmse_y_per_frame(2:end), 'Color', [0.7, 0, 0], 'LineWidth', 1, 'DisplayName', 'RMSE_{y}');
yline(overall_rmse, 'k--', 'LineWidth', 2, 'Label', [num2str(overall_rmse, '%.2f')], 'DisplayName', 'Average RMSE_{xy}');
xlabel('Frame Number');
ylabel('RMSE');
title('Frame-by-Frame RMSE');
legend('show');
grid on;
hold off;

