function [data, err_flag] = ssoSegFunPerReg( phase, CONST, header, dataname, crop_box)
% ssoSegFunPerReg : starts segmentation of phase image and sets error flags
% It creates the first set of good, bad and permanent segments and if
% CONST.seg.OPTI_FLAG is set to true it optimizes the region sizes.
% It uses perRegionOpti to optimize the regions.
% 
% INPUT :
%       phase_ : phase image
%       CONST : segmentation constants
%       header : string displayed with infromation
%       dataname : 
%
%  OUTPUT :
%       data : contains information about the segments and mask, for more
%       information look at superSeggerOpti.
%       err_flag : set to true if there are more segments than max
%       
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Stella Styliandou & Paul Wiggins.
% University of Washington, 2016
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

if ~exist('header','var')
    header = '';
end

if ~exist('dataname','var')
    dataname = '';
end

if ~exist('crop_box','var')
    crop_box = '';
end

%% skip segmentation/superSeggerOpti
%create the masks and segments
% disp_seg = ~CONST.seg.OPTI_FLAG;
% data = superSeggerOpti( phase ,[], disp_seg ,CONST, 1, header, crop_box);
% 
% if numel(data.segs.score) > CONST.superSeggerOpti.MAX_SEG_NUM;
%     err_flag = true;
%     save([dataname,'_too_many_segs'],'-STRUCT','data');
%     disp( [header,'BSSO ',dataname,'_too_many_segs'] );
%     return
% else
%     err_flag = false;    
% end

%%
% optimize the regions with bad scores
    data = [];
    data.phase = phase;
    dataname = char(dataname); %make sure dataname is char, not string
    % masks now stored adjacent to 'phase' directory 
    while ~exist([extractBefore(dataname,[filesep 'seg' filesep]) filesep 'masks' filesep],'dir')
        fprintf(2, ['Mask directory not found! ' ...
        'Check that Omnipose has run successfully, ' ...
        'or that path of dataset does not contain directory named ''seg''.' ...
        '\nPress Enter to retry, or Ctrl+C to exit.\n']);   
        pause;
    end
    
    if exist([extractBefore(dataname,[filesep 'seg' filesep]) filesep 'masks' filesep],'dir')
        maskdir = [extractBefore(dataname, [filesep 'seg' filesep]) filesep 'masks' filesep];
        % Check for png or tif/tiff files in maskdir
        pngFiles = ~isempty(dir(fullfile(maskdir, '*.png')));
        tifFiles = ~isempty(dir(fullfile(maskdir, '*.tif')))
        tiffFiles = ~isempty(dir(fullfile(maskdir, '*.tiff')));
        if ~pngFiles && ~tifFiles && ~tiffFiles
            % If no valid mask files found, warn the user
            warning(['No PNG, TIF, or TIFF files found in maskdir: ' maskdir]);
        end
    else

    end
    filename = char(extractBetween(dataname,[filesep 'seg' filesep],'_seg.mat')); %generalized to filesep 
    if pngFiles
        maskpath = strcat(maskdir,filename,'c1_cp_masks.png'); %get path of omnipose mask  
    elseif tifFiles
        maskpath = strcat(maskdir,filename,'c1_cp_masks.tif'); 
    elseif
        maskpath = strcat(maskdir,filename,'c1_cp_masks.tiff'); 
    else
        error('No valid mask files found in the specified directory.');
    end
    data = intMakeRegs( maskpath, data, CONST ); %input omnipose mask, imread mask and convert to double 
    err_flag = false; %shh no errors here...

end

