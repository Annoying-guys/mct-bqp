% Similar to the other but over multiple frames with linear interpolation

% 1	6124	11	346	206	103,466666666667	36,2666666666667	-26,8882982712729   106,109394965317
% 1	6125	11	349	206	103,466666666667	36,2666666666667	-26,4023651699848	106,109394965317
% 1	6126	11	354	206	103,466666666667	35,2000000000000	-25,5924766678381	106,109394965317
% 1	6127	11	357	206	103,466666666667	35,2000000000000	-25,1065435665500	106,109394965317
% 1	6128	11	360	206	104,533333333333	36,2666666666667	-24,6206104652619	106,109394965317
% 1	6130	11	366	206	104,533333333333	36,2666666666667	-23,6487442626858	106,109394965317
% 1	6133	11	376	208	103,466666666667	36,2666666666667	-18,1477384036103	87,3771027349569
% 1	6138	11	393	208	103,466666666667	35,2000000000000	-15,8792711031590	87,3771027349569
% 1	6143	11	409	208	104,533333333333	36,2666666666667	-13,7442430556754	87,3771027349569
% 1	6153	11	443	209	104,533333333333	35,2000000000000	-8,46187051351045	80,2858496719513

% 2	6124	11	162	160	88,5333333333333	33,0666666666667	-63,8238014031299	-11,5452414353840
% 2	6125	11	161	160	88,5333333333333	33,0666666666667	-63,6639173411481	-11,5790262786733
% 2	6126	11	160	160	88,5333333333333	33,0666666666667	-63,5047536053392	-11,6126589110008
% 2	6127	11	160	160	89,6000000000000	33,0666666666667	-63,5047536053392	-11,6126589110008
% 2	6128	11	158	161	88,5333333333333	33,0666666666667	-59,0137218480784	-10,3419768723833
% 2	6130	11	157	161	89,6000000000000	33,0666666666667	-58,8743290421772	-10,3761192971046
% 2	6133	11	155	161	90,6666666666667	33,0666666666667	-58,5973022377412	-10,4439733499381
% 2	6138	11	152	162	91,7333333333333	34,1333333333333	-54,5441903018163	-9,35329086328695
% 2	6143	11	146	162	93,8666666666667	35,2000000000000	-53,8218307727603	-9,55468019688442
% 2	6153	11	134	163	99,2000000000000	37,3333333333333	-49,3591168838728	-8,87795571298172

%frames = {'ucla/view-GL1/frame6123.jpg' 'ucla/view-GL1/frame6124.jpg' 'ucla/view-GL1/frame6125.jpg' 'ucla/view-GL1/frame6126.jpg' 'ucla/view-GL1/frame6127.jpg' 'ucla/view-GL1/frame6128.jpg' ...
%'ucla/view-GL1/frame6129.jpg' 'ucla/view-GL1/frame6130.jpg' 'ucla/view-GL1/frame6131.jpg' 'ucla/view-GL1/frame6132.jpg' 'ucla/view-GL1/frame6133.jpg' 'ucla/view-GL1/frame6134.jpg' ...
%'ucla/view-GL1/frame6135.jpg' 'ucla/view-GL1/frame6136.jpg' 'ucla/view-GL1/frame6137.jpg' 'ucla/view-GL1/frame6138.jpg' 'ucla/view-GL1/frame6139.jpg' 'ucla/view-GL1/frame6140.jpg' ...
%'ucla/view-GL1/frame6141.jpg' 'ucla/view-GL1/frame6142.jpg' 'ucla/view-GL1/frame6143.jpg' 'ucla/view-GL1/frame6144.jpg' 'ucla/view-GL1/frame6145.jpg' 'ucla/view-GL1/frame6146.jpg'};

% NOTE Was using this for debug
frames = {'ucla/view-GL1/frame6123.jpg' 'ucla/view-GL1/frame6125.jpg' 'ucla/view-GL1/frame6127.jpg'};
%start_frame = '6882.jpg';
%track_frames = {'6883.jpg' '6884.jpg' '6885.jpg' '6886.jpg' '6887.jpg'}
% Target (in start frame)
% Target in cam 1
bb_width = 36;
bb_height = 103;
cx = 346;
cy = 206;
% Target in cam 2
% bb_width = 99.34328;
% bb_height = 294.87077;
% cx = 314.29104;
% cy = 129.80417;

% --- Train

% Tuning
use_GPU = 0;
dx = 4;
dy = 10;
sigma = 60; % NOTE This actually has to be large enough?
prefilter_sigma = 2;
lambda = 20;
features = 'RGB'; % Must be either RGB, HOG or BVT
k = 81;

prev_alphaf = -1;

figure;
for f = 1:size(frames,2)-1
    %track_frame = track_frame{1};
    start_frame = frames{f};
    track_frame = frames{f + 1};

    % Get the image patch
    patch_coords = [cx - bb_width cy - bb_height 3*bb_width 3*bb_height];
    original_bb = imcrop(imread(start_frame), [cx cy bb_width bb_height]);
    [x, crop_rect] = imcrop(imread(start_frame), patch_coords);


    original_crop_rect = crop_rect;
    crop_rect(crop_rect < 0) = 0;
    % Actual distance from crop
    cdx = cx - crop_rect(1);
    cdy = cy - crop_rect(2);

    % Gaussian pre-filter outside the pedestrian bb
    x = prefilter(x, original_bb, cdx, cdy, sigma);

    I = imread(start_frame);
    I((cast(crop_rect(2), 'int32') + 1:cast(crop_rect(2), 'int32') + size(x,1)),(cast(crop_rect(1), 'int32') + 1:cast(crop_rect(1), 'int32') + size(x,2)),:) = x(:,:,:);
    subplot(3,2,1);
    imshow(I);
    drawBBs([cx cy bb_width bb_height], 'g', 2)
    drawBBs(patch_coords, 'w', 2)
    title(start_frame);

    % Generate the 2d gaussian
    gsize = [size(x,1) size(x,2)];
    cdx = cdx + bb_width/2;
    cdy = cdy + bb_height/2;
    center = [cdy cdx];
    Sig = [sigma 0; 0 sigma];
    y = gauss2d(gsize, Sig , center);
    y = y./(sum(y(:)));

    tic
    alphaf = train(x, y, sigma, lambda, use_GPU);
    toc

    % Update the weights with linear interpolation
    % TODO Henriques says they interpolate x? I'm sceptical of this but ok
    if prev_alphaf ~= -1 % Not first tracking
        alphaf = 0.5 * alphaf + 0.5 * prev_alphaf;
    end

    % Get a patch on the next frame that is in the same place
    z = imcrop(imread(track_frame), patch_coords);
    %tic
    responses = detect_patch(alphaf, x, z, sigma, use_GPU);
    %toc

    % Get the best possible value according to the KCF tracker
    maxValue= max(responses(:));
    [rowsOfMaxes, colsOfMaxes] = find(responses == maxValue);
    val_x = colsOfMaxes + crop_rect(1);
    val_y = rowsOfMaxes + crop_rect(2);
    % If many similar responses, get best
    val_x = val_x(1) - bb_width/2;
    val_y = val_y(1) - bb_height/2;
    tracked_img = imcrop(imread(track_frame), [val_x val_y bb_width bb_height]);
    subplot(3,2,2);
    imshow(imread(track_frame));
    drawBBs([val_x val_y bb_width bb_height], 'r', 2)
    drawBBs(patch_coords, 'w', 2)
    title(track_frame);

    test_cands = 0;
    max_resp = -99999999; % Variable to find best candidate
    if test_cands == 1
        % These two can be picked from the KCF patch
        xstep = ceil(bb_width/dx);
        ystep = ceil(bb_height/dy);
        % Get my k candidates and show them
        % Assign them their weights from the responses vector
        candidate_responses = zeros(sqrt(k));
        best_cand = [0 0];
        for gridx=-floor(sqrt(k)/2):floor(sqrt(k)/2)
            for gridy=-floor(sqrt(k)/2):floor(sqrt(k)/2)
                k_cx = cx + gridx * xstep + 1;
                k_cy = cy + gridy * ystep + 1;

                % Convert candidate locations in the image to patch locations
                resp_cx = k_cx - crop_rect(1);
                resp_cy = k_cy - crop_rect(2);


                if k_cx > 0 && k_cy > 0

                    candidate_responses(gridy + floor(sqrt(k)/2) + 1, gridx + floor(sqrt(k)/2) + 1) = responses(cast(resp_cy, 'int32'), cast(resp_cx, 'int32'));
                    resp = responses(cast(resp_cy, 'int32'), cast(resp_cx, 'int32'));
                    % Reverse lookup the response for this candidate
                    if resp > max_resp
                        best_cand(1) = k_cx;
                        best_cand(2) = k_cy;
                        max_resp = resp;
                    else
                        rectangle('Position',[k_cx k_cy bb_width bb_height],'EdgeColor', 'b', 'LineWidth', 1);
                    end

                    hold on
                end
            end
        end
        rectangle('Position',[best_cand(1) best_cand(2) bb_width bb_height],'EdgeColor', 'y', 'LineWidth', 1);
    end
    pause(.5);

    % Update cx and cy to the new target
    prev_alphaf = alphaf;
    cx = val_x;
    cy = val_y;

    subplot(3,2,3);
    imshow(x);
    subplot(3,2,4);
    imshow(z);
    subplot(3,2,5);
    ynorm = (y - min(y(:)))/(max(y(:)) - min(y(:)));
    imshow(ynorm);
    subplot(3,2,6);
    rnorm = (responses - min(responses(:)))/(max(responses(:)) - min(responses(:)));
    imshow(rnorm);
end

function im = prefilter(x, original_bb, cdx, cdy, sigma)
    Iblur = imgaussfilt(x, sigma);
    ceildx = cast(cdx, 'int32') + 1;
    ceilbx = cast(cdx, 'int32') + size(original_bb,2);
    ceildy = cast(cdy, 'int32') + 1;
    ceilby = cast(cdy, 'int32') + size(original_bb,1);
    Iblur((ceildy:ceilby),(ceildx:ceilbx),:) = original_bb(:,:,:);
    im = Iblur;
end


function k = kernel_correlation(x1, x2, sigma)
    c = ifft2(sum(conj(fft2(x1)) .* fft2(x2), 3));
    a = x1(:);
    b = x2(:);
    d = a'*a + b'*b - 2*c;
    k = exp(-1 / sigma^2 * abs(d) / numel(d));
end

function alphaf = train(x, y, sigma, lambda, use_GPU)
    x = cast(x, 'double');
    if use_GPU
        x = gpuArray(x);
    end
    k = kernel_correlation(x, x, sigma);
    a = fft2(y) ./ (fft2(k) + lambda);
    if use_GPU
        alphaf = gather(a);
    else
        alphaf = a;
    end
end

function responses = detect_patch(alphaf, x, z, sigma, use_GPU)
    x = cast(x, 'double');
    z = cast(z, 'double');
    if use_GPU
        x = gpuArray(x);
        z = gpuArray(z);
    end
    k = kernel_correlation(z, x, sigma);
    r = real(ifft2(alphaf .* fft2(k)));
    if use_GPU
        responses = gather(r);
    else
        responses = r;
    end
end