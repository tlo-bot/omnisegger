function processExp( dirname , savexls, autoomni, log_flag )
% processExp : main function for running the segmentation software.
% Used to choose the appropriate settings, and converting the images
% filenames before running BatchSuperSeggerOpti.
% Images need to have the NIS-Elements Format, or they can be converted 
% using convertImageNames.
%
% the naming convention of the image files must be of the following format
% time, xy-positions, fluorescence channel, where c1 is bright field 
% and c2,c3 etc are different fluorescent channels 
% Example of two time points, two xy positions and one fluorescent channel
% filename_t001xy1c1.tif
% filename_t001xy1c2.tif
% filename_t001xy2c1.tif
% filename_t001xy2c2.tif
% filename_t002xy1c1.tif
% filename_t002xy1c2.tif
% filename_t002xy2c1.tif
% filename_t002xy2c2.tif
%
% INPUT :
%       dirname : folder that contains .tif images in NIS elements format. 
%       savexls : save clist as .xls in addition to .mat file
%               : 1 to save as .xls; 0 to save as .mat only
%       autoomni : if Omnipose already installed/accessible to MATLAB,
%                : run Omnipose automatically in MATLAB 
%                : in case Omnipose options should be manually specified
%                : by running in Terminal rather than the default options
%                : preset in the batchSuperSeggerOpti.m file
%                : 1 to run automatically; 0 to run manually (default)
%       log_flag : save SuperSegger output from Command Window to
%                : a file in the main directory called output_log.txt
%                : 1 to save output; 0 to not save (default)
% 
%
% Copyright (C) 2024 Wiggins Lab 
% Written by Paul Wiggins, Nathan Kuwada, Stella Stylianidou, Teresa Lo.
% University of Washington, 2024
% This file is part of SuperSegger.
% 
% SuperSegger is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% SuperSegger is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with SuperSegger.  If not, see <http://www.gnu.org/licenses/>.

%% start logging Command Window

if ~exist( 'log_flag', 'var') || isempty( log_flag )
    log_flag = 0;
end

if log_flag
    diary([dirname filesep 'output_log.txt']);    
end

%% Converting other microscopes files
% For example if you are using MicroManager and the file format is the 
% followin : date-strain_00000000t_BF.tif, date-strain_00000000t_GFP.tif,
% you can run convertImageNames(dirname, 'whatever_name_you_want', '', 't',
% '','', {'BF','GFP'} )

basename = 'date-strain';
timeFilterBefore ='t';
timeFilterAfter = '_' ;
xyFilterBefore='_x';
xyFilterAfter='_';
channelNames = {'BF','GFP'};

convertImageNames(dirname, basename, timeFilterBefore, ...
    timeFilterAfter, xyFilterBefore,xyFilterAfter, channelNames )


%% Parallel Processing Mode
% to run code in parallel mode must have the parallel processing toolbox,
% for convenience default is false (non-parallel)

parallel_flag = false;

%% Load Constants
% To see the possible constants type : 
%[~, list] = getConstantsList;
% list'

res = '60XEc';
CONST = loadConstants(res,parallel_flag) ;

%% Calculation Options
% after you load the constants you can modify them according to your needs
% for more options, looks at the loadConstants file.

CONST.trackLoci.numSpots = [2]; % Max number of foci to fit in each fluorescence channel (default = [0 0])
CONST.trackOpti.NEIGHBOR_FLAG = false; % calculate number of neighbors (default = false)
CONST.imAlign.AlignChannel = 1; % change this if you want the images to be aligned to fluorescence channel
CONST.align.ALIGN_FLAG = 1; % change if don't want image alignment (default = true)

CONST.view.fluorColor = {'g'}; % color to view fluorescence channel in superSeggerViewer (eg {'g','y'})

% edit below to keep some image metadata - optional
CONST.frameRate = 5; %framerate in minutes/frame (default = 5)
CONST.res = 0.108; %um/px resolution

%% Ignore linking error resolution
% OmniSegger will attempt to fix masks if linking errors are detected.
% You can ignore possible segmentation errors/use Omnipose masks only.

CONST.ignoreerror = 0; % change to ignore error resolution (default = false)

%% Skip Frames for Segmentation
% For fast time-lapse or slow growth you can skip phase image frames 
% during segmentation to increase processing speed. Fluorescence images 
% will not be skipped. 

skip = 1;  % segment every frame
%skip = 5; % segment every fifth phase image

%% Clean previous segmented data
% If set to true, will begin processing on aligned images; if false, will 
% try to restart processing at last successful function (default = false)

cleanflag = false;


%% Start running segmentation

%no autoomni input; default to off
if ~exist( 'autoomni', 'var' ) || isempty( autoomni ) 
    autoomni = 0;
end

% save as xls
if ~exist( 'savexls', 'var') || isempty( savexls )
    CONST.savexls = 0;
else
    CONST.savexls = savexls;
end

%BatchSuperSeggerOpti( dirname, skip, cleanflag, CONST);
BatchSuperSeggerOpti( dirname, skip, cleanflag, CONST, [], [], autoomni);

%% turn off log

if log_flag
    diary off
end

end
