clear all;

%% Load the Digits dataset
digitDatasetPath = fullfile(toolboxdir('nnet'), 'nndemos', ...
 'nndatasets', 'DigitDataset');
imds = imageDatastore(digitDatasetPath, ...
 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
imds.ReadFcn = @(loc)imresize(imread(loc), [32, 32]);
% Split the data into training and validation datasets
[imdsTrain, imdsValidation] = splitEachLabel(imds, 0.7, 'randomized');

%% Define the LeNet-5 architecture
layers = [
 imageInputLayer([32 32 1],'Name','input')
 convolution2dLayer(5,16,'Padding','same','Name','conv_1')
 averagePooling2dLayer(2,'Stride',2,'Name','avgpool_1')
 convolution2dLayer(5,32,'Padding','same','Name','conv_2')
 averagePooling2dLayer(2,'Stride',2,'Name','avgpool_2')
 fullyConnectedLayer(120,'Name','fc_1')
 fullyConnectedLayer(84,'Name','fc_2')
 fullyConnectedLayer(10,'Name','fc_3')
 softmaxLayer('Name','softmax')
 classificationLayer('Name','output')];

%% Specify the training options with Early Stopping
options = trainingOptions('sgdm', ...
 'InitialLearnRate',0.0001, ...
 'MaxEpochs',20, ...
 'Shuffle','every-epoch', ...
 'ValidationData',imdsValidation, ...
 'ValidationFrequency',30, ...
 'Verbose',true, ...
 'Plots','training-progress', ...
 'ValidationPatience',3);  % Stop training if validation loss does not improve for 3 epochs

%% Train the network
net = trainNetwork(imdsTrain, layers, options);

%% Classify validation images and compute accuracy
YPred = classify(net, imdsValidation);
YValidation = imdsValidation.Labels;
accuracy = sum(YPred == YValidation)/numel(YValidation);
fprintf('Accuracy of the network on the validation images: %f\n', accuracy);

%% Display Confusion Matrix using confusionchart
figure('Units', 'normalized', 'Position', [0.2 0.2 0.5 0.5]);
cm = confusionchart(YValidation, YPred, ...
    'Title', 'Confusion Matrix for Validation Data', ...
    'ColumnSummary', 'column-normalized', 'RowSummary', 'row-normalized');
sortClasses(cm, categories(imdsTrain.Labels));

% Calculate confusion matrix
C = confusionmat(YValidation, YPred);

% Number of classes
numClasses = size(C, 1);

%% Precision, Recall, and F1 Score Calculation

% Preallocate arrays to store metrics for each class
Precision = zeros(numClasses, 1);
Recall = zeros(numClasses, 1);
F1Score = zeros(numClasses, 1);

% Calculate TP, FP, FN, and TN for each class
for i = 1:numClasses
    TP = C(i, i);
    FP = sum(C(:, i)) - TP;  % Sum of column i, excluding TP
    FN = sum(C(i, :)) - TP;  % Sum of row i, excluding TP
    TN = sum(C(:)) - (TP + FP + FN);  % Total all elements - sum of row i - sum of column i + TP
    
    % Calculate Precision, Recall for the current class
    Precision(i) = TP / (TP + FP);
    Recall(i) = TP / (TP + FN);
    F1Score(i) = 2 * (Precision(i) * Recall(i)) / (Precision(i) + Recall(i));
end

% Calculate mean of the metrics across all classes
meanPrecision = mean(Precision);
meanRecall = mean(Recall);
meanF1Score = mean(F1Score);

% Display class-specific results
for i = 1:numClasses
    fprintf('Class %d - Precision: %f, Recall: %f, F1 Score: %f\n', i, Precision(i), Recall(i), F1Score(i));
end
fprintf('Mean Precision: %f\n', meanPrecision);
fprintf('Mean Recall: %f\n', meanRecall);
fprintf('Mean F1 Score: %f\n', meanF1Score);