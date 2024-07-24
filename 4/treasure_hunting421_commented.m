close all; 
clear all;

%% Reading Image
% im = imread('Treasure_easy.jpg');
% im = imread('Treasure_medium.jpg');
im = imread('Treasure_hard.jpg');
imshow(im);

%% Binarisation
bin_threshold = 0.07; % Optimal threshold value found via manual thresholding
bin_im = im2bw(im, bin_threshold);
figure;
imshow(bin_im);

%% Extracting Connected Components
con_com = bwlabel(bin_im);
figure;
imshow(label2rgb(con_com));

%% Computing Objects Properties
props = regionprops(con_com);

%% Drawing Bounding Boxes
n_objects = numel(props);
figure;
imshow(im);
hold on;
for object_id = 1 : n_objects
    rectangle('Position', props(object_id).BoundingBox, 'EdgeColor', 'b');
end

hold off;

%% Arrow/Non-Arrow Determination

arrow_ind = arrow_finder(props, im);

figure;
imshow(im);
hold on;
for idx = 1:length(arrow_ind)
    object_id = arrow_ind(idx);
    rectangle('Position', props(object_id).BoundingBox, 'EdgeColor', 'y', 'LineWidth', 1);
end

hold off;

%% Finding red arrow
n_arrows = numel(arrow_ind);
start_arrow_id = 0;
% Check each arrow until find the red one
for arrow_num = 1 : n_arrows
    object_id = arrow_ind(arrow_num);    % Determine the arrow id
    
    % Extract colour of the centroid point of the current arrow
    centroid_colour = im(round(props(object_id).Centroid(2)), round(props(object_id).Centroid(1)), :); 
    if centroid_colour(:, :, 1) > 240 && centroid_colour(:, :, 2) < 10 && centroid_colour(:, :, 3) < 10
	% The centroid point is red, memorise its id and break the loop
        start_arrow_id = object_id;
        break;
    end
end

%% Hunting
cur_object = start_arrow_id; % Start from the red arrow
path = cur_object; % Initialise path with current object id
clove_id = find_clove_id(props); % Find the clove id using the created function
chosen_arrows = [start_arrow_id]; % Initialise chosen arrows array with start arrow id (current arrow); used for picking closest, non-chosen arrow after robot has found the clove

% While the current object is an arrow, continue to search
while ismember(cur_object, arrow_ind)
    [cur_object, isSpecialCase] = next_object_finder(cur_object, props, im, clove_id, arrow_ind, chosen_arrows);
    if isSpecialCase
        path(end + 1) = clove_id;
        % If clove_id leads to a special case, ensure it's not treated as an arrow and not added to chosen_arrows
    end
    path(end + 1) = cur_object;
    if ismember(cur_object, arrow_ind)
        chosen_arrows(end + 1) = cur_object; % Add the current arrow to the list of chosen arrows
    end
end

%% Visualization of the Path with Adjusted Label Positions for Objects with More than 1 Visit
figure;
imshow(im);
hold on;

% Initialize a map to track how many times each ID has been labeled
labelCounts = containers.Map('KeyType', 'double', 'ValueType', 'double');

% Iterate over arrows to draw their direction vectors
for idx = 1:length(chosen_arrows)
    object_id = chosen_arrows(idx); % Current arrow ID
    bbox = round(props(object_id).BoundingBox);
    arrowImage = im(bbox(2):bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1, :);
    hsvArrowImage = rgb2hsv(arrowImage);
    maskYellow = (hsvArrowImage(:,:,1) >= 1/7) & (hsvArrowImage(:,:,1) <= 1/4) & ...
                 (hsvArrowImage(:,:,2) > 0.5) & (hsvArrowImage(:,:,3) > 0.5);
    
    % Calculate the centroid of the yellow area to determine the direction
    yellowProps = regionprops(maskYellow, 'Centroid');
    if isempty(yellowProps)
        continue; % Skip if no yellow part is detected (shouldn't happen, but just in case)
    end
    yellowCentroid = yellowProps.Centroid;
    yellowCentroidGlobal = yellowCentroid + [bbox(1), bbox(2)] - 1; % convert to global coordinates
    
    current_centroid = props(object_id).Centroid;
    directionVector = yellowCentroidGlobal - current_centroid;
    directionVectorNormalized = directionVector / norm(directionVector);
    extendeddirectionVectorNormalized = directionVectorNormalized * 100;
    endVectorPoint = current_centroid + extendeddirectionVectorNormalized;
    
    % Draw the direction vector
    quiver(current_centroid(1), current_centroid(2), extendeddirectionVectorNormalized(1), extendeddirectionVectorNormalized(2), 0, 'r--', 'LineWidth', 1.5);
end

% Calculate a vector for the direction of the arrow
for i = 1:length(path)-1
    startObjID = path(i);
    endObjID = path(i + 1);

    startPos = props(startObjID).Centroid;
    endPos = props(endObjID).Centroid;

    % Draw the line
    plot([startPos(1), endPos(1)], [startPos(2), endPos(2)], 'c', 'LineWidth', 1);

    % Arrowhead parameters
    arrowLength = 10; % Length of the arrow lines
    angle = 25; % Angle of the arrowhead

    % Calculate direction of the arrow
    direction = [endPos(1) - startPos(1), endPos(2) - startPos(2)];
    normDirection = direction / norm(direction);

    % Calculate orthogonal vector to the direction
    orthDirection = [-normDirection(2), normDirection(1)];

    % Calculate points of the arrowhead
    arrowTip = endPos;
    arrowBase1 = arrowTip - arrowLength * (cosd(angle) * normDirection + sind(angle) * orthDirection);
    arrowBase2 = arrowTip - arrowLength * (cosd(angle) * normDirection - sind(angle) * orthDirection);

    % Draw the arrowhead
    fill([arrowTip(1), arrowBase1(1), arrowBase2(1)], [arrowTip(2), arrowBase1(2), arrowBase2(2)], 'c');
end

for path_element = 1:numel(path)
    object_id = path(path_element);
    bbox = props(object_id).BoundingBox;
    
    % Check if the object has been labeled before and update the count
    if isKey(labelCounts, object_id)
        labelCounts(object_id) = labelCounts(object_id) + 1;
    else
        labelCounts(object_id) = 1;
    end
    
    % Offset based on the count
    offset = (labelCounts(object_id) - 1) * 10; % Adjust the offset multiplier as needed
    
    % Determine the rectangle color
    edgeColor = 'y'; % Default to yellow for arrows
    if ~ismember(object_id, arrow_ind) % If it's not an arrow, use green
        edgeColor = 'g';
    end
    
    % Draw the rectangle
    rectangle('Position', bbox, 'EdgeColor', edgeColor, 'LineWidth', 1);
    
    % Adjust label position to avoid overlap (label moved vertically for objects with 2 or more labels)
    label_x = bbox(1) + offset * 0;
    label_y = bbox(2) + offset * 2;
    
    % Add the path element number
    str = num2str(path_element);
    text(label_x, label_y - 8, str, 'Color', 'r', 'FontWeight', 'bold', 'FontSize', 14);
end

hold off;

%% Arrow Finding Function

% Arrow finding function using the HSV values of yellow dots to identify arrows
function arrow_inds = arrow_finder(props, im)
    % Initialize an empty array to store indices of objects identified as arrows
    arrow_inds = [];

    % Loop through each object identified in the image
    for object_id = 1:length(props)
        % Extract the bounding box of the current object and round off values
        bbox = round(props(object_id).BoundingBox);

        % Crop the region of the image corresponding to the current object
        subImage = im(bbox(2):bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1, :);

        % Convert the cropped image from RGB to HSV color space
        hsvImage = rgb2hsv(subImage);

        % Define the color range for yellow in HSV space:
        % Hue between 1/7 and 1/4 (approximately 25.7 to 51.4 degrees)
        % Saturation greater than 0.5
        % Value (brightness) greater than 0.5
        % This range is chosen to target bright yellow colors typically used for arrows
        maskYellow = (hsvImage(:,:,1) >= 1/7) & (hsvImage(:,:,1) <= 1/4) & ...
                     (hsvImage(:,:,2) > 0.5) & (hsvImage(:,:,3) > 0.5);

        % Check if there are any pixels within the defined yellow range
        if any(maskYellow(:))
            % If yellow pixels are found, add the object's index to the list
            arrow_inds = [arrow_inds, object_id];
        end
    end
end


% % ALTERNATE APPROACH: Function to identify arrow candidates based on their area from image properties
% function arrow_inds = arrow_finder(props, im)
%     % Initialize an empty array to store indices of detected objects that might be arrows
%     arrow_inds = [];
% 
%     % Loop over all detected objects provided in 'props'
%     for object_id = 1 : numel(props)  % 'numel' is used for safety, it handles any type of array input
%         % Check if the area of the current object is smaller than a threshold
%         % The threshold value 1650 (varies based on the binarisation threshold) is empirically set to distinguish arrows from other objects
%         if props(object_id).Area < 1650
%             % If the object's area is less than 1650 pixels, it is an arrow
%             % Append the index of this object to the list of arrow indices
%             arrow_inds = [arrow_inds, object_id];
%         end
%     end
% end

%% Next Object Finder Function (Includes All Cases - Arrows and Treasures): Function to determine the next object of interest based on direction vectors and special cases
function [next_object_id, isSpecialCase] = next_object_finder(current_object_id, props, im, clove_id, arrow_ind, chosen_arrows)
    % Retrieve the centroid of the current object for reference
    current_centroid = props(current_object_id).Centroid;
    
    % Isolate the portion of the image containing the current arrow using its bounding box
    bbox = round(props(current_object_id).BoundingBox);
    arrowImage = im(bbox(2):bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1, :);
    % Convert this sub-image to HSV to focus on color characteristics
    hsvArrowImage = rgb2hsv(arrowImage);
    % Create a mask for yellow regions (typically used for arrow pointers)
    maskYellow = (hsvArrowImage(:,:,1) >= 1/7) & (hsvArrowImage(:,:,1) <= 1/4) & ...
                 (hsvArrowImage(:,:,2) > 0.5) & (hsvArrowImage(:,:,3) > 0.5);
    
    % Find the centroid of the yellow region which indicates the direction of the arrow
    yellowProps = regionprops(maskYellow, 'Centroid');
    yellowCentroid = yellowProps.Centroid;
    % Adjust centroid to global image coordinates
    yellowCentroidGlobal = yellowCentroid + [bbox(1), bbox(2)] - 1;
    
    % Compute a vector from the arrow’s centroid to the yellow centroid
    directionVector = yellowCentroidGlobal - current_centroid;
    % Normalize this direction vector for consistent magnitude
    directionVector = directionVector / norm(directionVector);
    % Extend by a scalar (enough to cover the distance from one arrow's bounding box to the next object's bounding box)
    extendedVector = directionVector * 100;

    % Initialize default values for outputs
    next_object_id = -1;
    isSpecialCase = false;

    % Loop through all objects to determine the next target based on geometric analysis
    for object_id = 1 : length(props)
        if next_object_id == clove_id
            % Special case: find nearest unchosen arrow from the clove
            clove_centroid = props(clove_id).Centroid;
            min_distance = inf;
            closest_arrow_id = -1;
            
            for arrow_idx = 1:length(arrow_ind)
                arrow_id = arrow_ind(arrow_idx);
                if ismember(arrow_id, chosen_arrows)
                    continue; % Avoid revisiting already chosen arrows
                end
                arrow_centroid = props(arrow_id).Centroid;
                distance = sqrt((clove_centroid(1) - arrow_centroid(1))^2 + ...
                                (clove_centroid(2) - arrow_centroid(2))^2);
                if distance < min_distance
                    min_distance = distance;
                    closest_arrow_id = arrow_id;
                end
            end
            next_object_id = closest_arrow_id;
            isSpecialCase = true;

        elseif object_id == current_object_id
            continue; % Skip self-comparison

        else
            obj_bbox = props(object_id).BoundingBox;
            % Determine if the extended vector intersects the bounding box of any other object
            if intersects_with_bbox(current_centroid, extendedVector, obj_bbox)
                next_object_id = object_id;
            end
        end
    end
end

% Function to determine if a line segment defined by a starting point and a direction vector intersects with any side of a given bounding box.
function intersects = intersects_with_bbox(start_point, direction, bbox)

    % Expand the bounding box into its corner points for easier boundary calculations
    bbox_corners = [bbox(1), bbox(2);  % Upper left corner
                    bbox(1) + bbox(3), bbox(2); % Upper right corner
                    bbox(1) + bbox(3), bbox(2) + bbox(4); % Lower right corner
                    bbox(1), bbox(2) + bbox(4)]; % Lower left corner

    % Define the lines that make up each side of the bounding box
    bbox_lines = [bbox_corners(1, :); bbox_corners(2, :); % Top horizontal line
                  bbox_corners(2, :); bbox_corners(3, :); % Right vertical line
                  bbox_corners(3, :); bbox_corners(4, :); % Bottom horizontal line
                  bbox_corners(4, :); bbox_corners(1, :)]; % Left vertical line

    % Extend the initial direction vector to create a line segment
    end_point = start_point + direction;
    
    % Initialize the intersection flag as false
    intersects = false;
    
    % Check each side of the bounding box for intersection with the line segment
    for i = 1:2:size(bbox_lines, 1)
        p1 = bbox_lines(i, :);
        p2 = bbox_lines(i + 1, :);
        
        % Use a helper function 'lineIntersect' to check for intersection
        % between the line segment from the direction vector and each bounding box side
        if lineIntersect([start_point; end_point], [p1; p2])
            intersects = true;
            return;  % Exit the function as soon as one intersection is found
        end
    end
end

% Function to determine if two line segments intersect
function isIntersecting = lineIntersect(seg1, seg2)
    % Input segments are defined by two endpoints each: [x1, y1; x2, y2]

    % Extract starting point and directional vector for the first segment
    p = seg1(1, :); % Starting point of segment 1
    r = seg1(2, :) - seg1(1, :); % Directional vector from start to end of segment 1

    % Extract starting point and directional vector for the second segment
    q = seg2(1, :); % Starting point of segment 2
    s = seg2(2, :) - seg2(1, :); % Directional vector from start to end of segment 2

    % Check for parallel lines: if r x s = 0, segments are parallel (cross product of vectors)
    if cross([r 0], [s 0]) == 0
        isIntersecting = false; % If parallel, there is no intersection
        return; % Exit the function early
    end

    % Calculate the two parameters t and u for the intersection point
    t = cross([q - p 0], [s 0]) / cross([r 0], [s 0]); % Parameter for segment 1
    u = cross([q - p 0], [r 0]) / cross([r 0], [s 0]); % Parameter for segment 2

    % Determine if the intersection point lies within both line segments
    isIntersecting = (t >= 0 && t <= 1) && (u >= 0 && u <= 1);
    % t and u must both be between 0 and 1 for the intersection to be valid within the segments
end

% This function searches for a clove based on its area within a list of object properties
function clove_id = find_clove_id(props)
    % Each object's area is compared against a specified 'clove_area' with a tolerance.

    % Define the expected area of a clove
    clove_area = 3500;  % The typical area size for a clove, could be derived from prior measurements
    
    % Set a tolerance for area comparison
    area_tolerance = 95;  % Allows for slight variations in clove size, accounting for measurement or detection inaccuracies (or different binarisation thresholds)

    % Loop through each object in the properties array
    for i = 1:length(props)
        % Check if the current object's area is within the tolerance of the expected clove area
        if abs(props(i).Area - clove_area) <= area_tolerance
            clove_id = i;  % If it matches, assign the current index to clove_id
            return;  % Exit the function as the clove has been found
        end
    end

    % If no object matches the criteria by the end of the loop, return an empty array
    clove_id = [];  % Indicates that no clove was found
end