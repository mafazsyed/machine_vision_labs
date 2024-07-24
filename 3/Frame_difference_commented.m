% Clear all variables and close all figures to ensure a clean workspace
clear all;
close all;

% Initialize video reader and writer objects
source = VideoReader('car-tracking.mp4');  % Read video file for tracking
output = VideoWriter('frame_difference_output.mp4', 'MPEG-4');  % Prepare output video file with MPEG-4 encoding
open(output);  % Open the output file for writing

% Set a threshold for frame differencing
thresh = 40;  % Pixel intensity difference threshold to classify as motion

% Initialize background model using the first video frame
bg = readFrame(source);       % Read the first frame to use as initial background
bg_bw = rgb2gray(bg);         % Convert background image to grayscale to simplify calculations

% Process each frame in the video
while hasFrame(source)
    fr = readFrame(source);   % Read the next frame from the video
    fr_bw = rgb2gray(fr);     % Convert current frame to grayscale
    
    % Compute absolute difference between the current frame and the background model
    fr_diff = abs(double(fr_bw) - double(bg_bw));  % Use double precision to handle potential negative values correctly
    
    % Threshold the difference to create a binary foreground mask
    fg = uint8(zeros(size(bg_bw)));  % Initialize a foreground image
    fg(fr_diff > thresh) = 255;      % Assign white to pixels with significant difference
    
    % Update the background model to the current frame for the next iteration
    bg_bw = fr_bw;
    
    % Visualize the processing results in a 3-row subplot
    figure(1);
    subplot(3,1,1), imshow(fr);      % Show original frame
    subplot(3,1,2), imshow(fr_bw);   % Show grayscale version of the frame
    subplot(3,1,3), imshow(fg);      % Show detected foreground
    drawnow;                         % Update figures dynamically
    
    % Write the foreground mask to the output video
    writeVideo(output, fg);
end

% Close the output video file to finalize writing
close(output);
