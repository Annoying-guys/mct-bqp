%NOTE: These are n dimensional because we may want the Neural Net to get different capture params for the  cameras

global cameras
cameras = {'alameda','central'};

global image_directories
image_directories = {'~/Campus_II/frames_alameda_noon_1_6_2017', '~/Campus_II/frames_central_noon_1_6_2017'};

global homography_directory
homography_directory = '~/Campus_II/homography_campus_II.mat';

global fps
fps = 9;

global resolutions
resolutions = [1024 768; 1024 768];

global durations
% Alameda then Central
durations = [15*60+2; 14*60+58];

global offset
% Offset camera Central to the camera Alameda (Central is 40s later)
offset = 40; % seconds

%-------------------------------------------------------------------------------
% The parameters 'nPerOct', 'nOctUp', 'nApprox', 'lambdas', 'pad', 'minDs'
% modify the channel feature pyramid created (see help of chnsPyramid.m for
% more details) and primarily control the scales used.

%  .nPerOct    - [] number of scales per octave
%  .nOctUp     - [] number of upsampled octaves to compute
%  .nApprox    - [] number of approx. scales to use
%  .lambdas    - [] coefficients for power law scaling (see BMVC10)
%  .pad        - [] amount to pad channels (along T/B and L/R)
%  .minDs      - [] minimum image size for channel computation

%-------------------------------------------------------------------------------
% The parameters 'pNms', 'stride', 'cascThr' and 'cascCal' modify the detector behavior
% (see help of acfTrain.m for more details). Finally, 'rescale' can be
% used to rescale the trained detector (this change is irreversible).

% Typically, set 'cascThr' to -1 and adjust 'cascCal' until the desired recall is reached
% (setting 'cascCal' shifts the final scores output by the detector by the given amount)

% .cascThr    - [] constant cascade threshold (affects speed/accuracy)
global LDCF_cascThr
LDCF_cascThr = [-1 -1];

% .cascCal    - [] cascade calibration (affects speed/accuracy)
global LDCF_cascCal
% 0.020 0.025 0.030 0.035
LDCF_cascCal = [0.030 0.031];

% .rescale    - [] rescale entire detector by given ratio, irreversible
global LDCF_rescale
LDCF_rescale = [1.0 1.0];

% .pNms       - [] params for non-maximal suppression (see bbNms.m)
global pNMS_overlap
pNMS_overlap = [0.9 1.0];

% .stride     - [] spatial stride between detection windows
global LDCF_stride
LDCF_stride = [4 4];

%-------------------------------------------------------------------------------
% The following are used to filter out the CNN detections
global score_threshold
% 0.25 0.5 0.75 1.0
score_threshold = [0.6 0.5];

global NMS_maxoverlap
% 0.25 0.5 0.75 0.9
NMS_maxoverlap = [0.9 1.0];

%-------------------------------------------------------------------------------
global order
order = 'toolbox';

global cpu_results
cpu_results = '~/mct-bqp/campus2_data/CPU/CNNdets_';

global gpu_results
gpu_results = '~/mct-bqp/campus2_data/GPU/CNNdets_';

global fp_files
fp_files = ['~/mct-bqp/campus2_data/alameda_CNN_false_positives.txt', '~/mct-bqp/campus2_data/central_CNN_false_positives.txt'];

global use_GPU
use_GPU = [0 0];
