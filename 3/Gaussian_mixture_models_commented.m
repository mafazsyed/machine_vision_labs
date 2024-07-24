% Clear all variables and close all figures to ensure a clean workspace
clear all;
close all;

% Initialize video reader for input video and writer for output results
source = VideoReader('car-tracking.mp4');  % Read video file for tracking
output = VideoWriter('gmm_output.mp4', 'MPEG-4');  % Setup output video file with MPEG-4 encoding
open(output);  % Open file to start writing results

% Set up the foreground detector using Gaussian Mixture Models
n_frames = 1;  % Number of training frames, parameter affecting model sensitivity
n_gaussians = 2;  % Number of Gaussian distributions to use in the model, affects complexity
learning_rate = 0.0001;  % Rate at which the model learns, influencing adaptation to changes in the scene
threshold = 0.85;  % Threshold for classifying a background pixel, balancing between false positives and negatives
detector = vision.ForegroundDetector('NumTrainingFrames', n_frames, 'NumGaussians', n_gaussians, 'LearningRate', learning_rate, 'MinimumBackgroundRatio', threshold);

% Process each frame in the video to detect foreground objects
while hasFrame(source)
    fr = readFrame(source);  % Read the next frame from the video
    
    % Apply the foreground detector to the frame
    fgMask = step(detector, fr);  % Obtain binary foreground mask from GMM
    
    % Prepare a visualization frame 
    fg = uint8(zeros(size(fr, 1), size(fr, 2)));  % Initialize a black image for foreground visualization
    fg(fgMask) = 255;  % Set foreground pixels to white
    
    % Visualize the results in a 2-row subplot
    figure(1);
    subplot(2,1,1), imshow(fr);  % Display the original frame
    subplot(2,1,2), imshow(fg);  % Display the binary foreground image
    drawnow;  % Update figures dynamically

    % Write the binary foreground image to the output video file
    writeVideo(output, fg);
end

% Close the output video file to finalize writing
close(output);
