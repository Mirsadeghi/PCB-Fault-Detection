clc;clear all;close all

% Finding the Rotation and Scale of an Image Using Automated Feature Matching
% Read Input Sample Images from Disk
S1_1 = imresize(imread('S4_1.jpg'),1);
S1_2 = imresize(imread('S4_2.jpg'),1);

disp('Step 1: Preprocessing')
% Step 1: Preprocessing
% Using Gaussian Filter to reduce noise
F = fspecial('gaussian',[3 3],1.5);
S1_1 = imfilter(S1_1,F);
S2_2 = imfilter(S1_2,F);
% Convert RGB to Gray-Scale image
original = rgb2gray(S1_1);
distorted = rgb2gray(S1_2);

%%
disp('Step 2: Find Correspondences Between Images')
% Step 2: Find Correspondences Between Images
% Detect features in both images.
ptsOriginal  = detectSURFFeatures(original,'MetricThreshold',600);
ptsDistorted = detectSURFFeatures(distorted,'MetricThreshold',600);

% Assign Descriptor to each feature point.
[featuresIn ,  validPtsIn]  = extractFeatures(original,  ptsOriginal,'Method','SURF');
[featuresOut, validPtsOut]  = extractFeatures(distorted, ptsDistorted,'Method','SURF');

% Match correspondence
index_pairs = matchFeatures(featuresIn, featuresOut);

% Save matched feature in the new variable
matchedOriginal  = validPtsIn(index_pairs(:,1));
matchedDistorted = validPtsOut(index_pairs(:,2));

% Show Result of step 2
figure
showMatchedFeatures(original,distorted,matchedOriginal,matchedDistorted);
title('Putatively matched points (including outliers)');

%%
disp('Step 3: Estimate Transformation Between Images')
% Step 3: Estimate Transformation
% Estimate Geometric transfrom between two images based on matched feature
% points.we use RANSAC to remove mismatch or outliers from matched features
[tform, inlierDistorted, inlierOriginal] = estimateGeometricTransform(...
    matchedDistorted, matchedOriginal, 'similarity');

% Show Results of step 3
figure
showMatchedFeatures(original,distorted,inlierOriginal.Location,...
    inlierDistorted.Location);
title('Matching points (inliers only)');

%%
disp('Step 4: Image Registration')
% Step 4: Recover Registered Image
recovered = imwarp(distorted,tform, 'OutputView', imref2d(size(original)));
recovered_rgb = imwarp(S1_2,tform, 'OutputView', imref2d(size(original)));

%%
disp('Step 5: Find Fault in Distorted Sample')
% Step 5: Finding differences between distorted and desired sample
% compute difference by subtracting images
diff_img = abs(single(recovered) - single(original));
% Create a blob analysis System object to segment region in the image.

hblob = vision.BlobAnalysis(...
    'CentroidOutputPort', false, 'AreaOutputPort', true, ...
    'BoundingBoxOutputPort', true, 'OutputDataType', 'double', ...
    'MinimumBlobArea', 0, 'MaximumBlobArea', 50000, 'MaximumCount', 80);
% Use morphological Dilation and Opening to remove small region and make
% connected region for Blob analysis
SE1 = strel('disk', 5, 0);
SE2 = strel('disk', 25, 0);
segmentedObjects = imdilate(imopen((diff_img > 40),SE1),SE2);
% Estimate the area and bounding box of the blobs.
[~, bbox] = step(hblob, segmentedObjects);

%%
% Show Final Result
figure
subplot 131; imshow(S1_1);             title('Desired Sample')
subplot 132; imshow(segmentedObjects); title('Fault Regions')
subplot 133; imshow(recovered_rgb);    title('Distorted Sample')
hold on
for i = 1:size(bbox,1)
    B = [bbox(i,1),bbox(i,2),0,0,bbox(i,3)/bbox(i,4),bbox(i,4)];
    drawBox(B, 'g')
end