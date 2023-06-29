v = VideoReader("./Case2.avi");
fgDetector = vision.ForegroundDetector('NumGaussians', 2, 'NumTrainingFrames', 500);
strelSize = 27;
shadowThreshold = 3.9;


noiseFreeMask = imopen(fgMask, strel('square', strelSize));
shadowMask = rgb2gray(frame) < shadowThreshold;
foregroundNoShadow = noiseFreeMask & ~shadowMask;

blobAnalyzer = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
    'AreaOutputPort', false, 'CentroidOutputPort', false, ...
    'MinimumBlobArea', 2500);

bbox = step(blobAnalyzer, foregroundNoShadow);


videoPlayer = vision.VideoPlayer('Name', 'Detected Cars');
videoPlayer.Position(3:4) = [650, 400];

prevBBoxes = [];
prevCentroids = [];
velocities = [];

while hasFrame(v)
    frame = readFrame(v);
    fgMask = step(fgDetector, frame);
    noiseFreeMask = imopen(fgMask, strel('square', strelSize));
    shadowMask = rgb2gray(frame) < shadowThreshold;
    foregroundNoShadow = noiseFreeMask & ~shadowMask;
    
    bbox = step(blobAnalyzer, foregroundNoShadow);
    detectedCars = insertShape(frame, 'Rectangle', bbox, 'Color', 'green');
    numCars = size(bbox, 1);
    
    detectedCars = insertText(detectedCars, [30 30], numCars, 'FontSize', 24, 'BoxOpacity', 1, 'TextColor', 'Black');


    numPrevCars = size(prevBBoxes, 1);
    numCurrCars = size(bbox, 1);
    currVelocities = zeros(numCurrCars, 2);
    for i = 1:numCurrCars
        currCentroid = [bbox(i, 1) + bbox(i, 3)/2, bbox(i, 2) + bbox(i, 4)/2];
        prevCentroids = prevCentroids(prevBBoxes(:, 1) == bbox(i, 1) & prevBBoxes(:, 2) == bbox(i, 2), :);
        numPrevCentroids = size(prevCentroids, 1);
        if numPrevCentroids > 0
            prevCentroid = prevCentroids(numPrevCentroids, :);
            carVelocity = currCentroid - prevCentroid;
            currVelocities(i, :) = carVelocity;
        end
    end

    prevBBoxes = bbox;
    prevCentroids = [bbox(:, 1) + bbox(:, 3)/2, bbox(:, 2) + bbox(:, 4)/2];
    velocities = currVelocities;

    for i = 1:numCurrCars
        currVelocity = velocities(i, :);
        if norm(currVelocity) > 0
            currVelocityStr = sprintf('%.2f km/h', norm(currVelocity));
            textPos = [bbox(i, 1) - 5, bbox(i, 2) - 20];
            detectedCars = insertText(detectedCars, textPos, currVelocityStr, 'FontSize', 14, 'BoxOpacity', 0.7, 'TextColor', 'green', 'BoxColor', 'black');
        end
    end
    
    step(videoPlayer, detectedCars);
end
