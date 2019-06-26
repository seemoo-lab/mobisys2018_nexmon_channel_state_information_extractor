function [dataIdx,pilotIdx] = helperSubcarrierIndices(cfg,fieldType)
% helperSubcarrierIndices Return the subcarrier indices within the FFT size
%
%   [DATAIDX,PILOTIDX] = helperSubcarrierIndices(CFGFORMAT,FIELDTYPE)
%   returns the data and pilot indices within the FFT size for the
%   specified format configuration object, CFGFORMAT, and specified
%   FIELDTYPE.
%
%   DATAIDX is a column vector containing the indices of data subcarriers.
%
%   PILOTIDX is a column vector containing the indices of pilot
%   subcarriers.
%
%   CFGFORMAT is the format configuration object of type <a href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a>, 
%   <a href="matlab:help('wlanHTConfig')">wlanHTConfig</a>, or <a href="matlab:help('wlanNonHTConfig')">wlanNonHTConfig</a>, which specifies the parameters for
%   the VHT, HT-Mixed, and Non-HT formats, respectively.
%
%   FIELDTYPE is a string specifying the format of the field and must be
%   one of 'Legacy','HT' or 'VHT'.
%
%   [DATAIDX,PILOTIDX] = helperSubcarrierIndices(CHANBW) returns indices
%   for the specified channel bandwidth. CHANBW must be one of 'CBW5',
%   'CBW10', 'CBW20', 'CBW40', 'CBW80' or 'CBW160'.
%
%   Example: Return indices for a VHT format configuration. 
%
%   cfgVHT = wlanVHTConfig;
%   [dataIdx,pilotIdx] = helperSubcarrierIndices(cfgVHT,'VHT')

% Copyright 2015 The MathWorks, Inc.

%#codegen

if ischar(cfg)
    coder.internal.errorIf( ~any(strcmp(cfg, {'CBW5', 'CBW10', ...
            'CBW20', 'CBW40', 'CBW80', 'CBW160'})), ...
        'wlan:helperSubcarrierIndices:InvalidChBandwidth');

    chanBW = cfg; 
else    
    validateattributes(cfg,{'wlanVHTConfig','wlanHTConfig','wlanNonHTConfig'}, ...
        {'scalar'},mfilename,'format configuration object');

    coder.internal.errorIf(isa(cfg,'wlanNonHTConfig') && ...
        ~strcmp(cfg.Modulation,'OFDM'), ...
            'wlan:helperSubcarrierIndices:InvalidNonHTModulation')

    chanBW = cfg.ChannelBandwidth;
end

FFTLen = helperFFTLength(chanBW);

fieldType = validatestring(fieldType,{'Legacy','HT','VHT'}, ...
    mfilename,'Field type');
if strcmp(fieldType,'Legacy') 
    switch chanBW
      case 'CBW40'
        Num20MHzChan = 2;          
      case {'CBW80', 'CBW80+80'}
        Num20MHzChan = 4; 
      case 'CBW160'
        Num20MHzChan = 8; 
      otherwise   % For 'CBW20', 'CBW10', 'CBW5'
        Num20MHzChan = 1; 
    end
    
    numGuardBands = [6; 5]; 
    pilotIdx20MHz =  [12; 26; 40; 54];
 
    % Get non-data subcarrier indices per 20MHz channel bandwidth
    nonDataIdxPerGroup = [(1:numGuardBands(1))'; 33; ...
        (64-numGuardBands(2)+1:64)'; pilotIdx20MHz];
    % Get non-data subcarrier indices for the whole bandwidth
    nonDataIdxAll = bsxfun(@plus, nonDataIdxPerGroup, 64*(0:Num20MHzChan-1));
    dataIdx  = setdiff((1:FFTLen)', sort(nonDataIdxAll(:)));
    pilotIdx = reshape(bsxfun(@plus, pilotIdx20MHz, 64*(0:Num20MHzChan-1)), [], 1);
else % 'HT' & 'VHT'
    switch chanBW
      case 'CBW40'
        numGuardBands = [6; 5]; 
        customNullIdx = [-1; 1];
        pilotIdx = [-53; -25; -11; 11; 25; 53];  
      case 'CBW80'
        numGuardBands = [6; 5];
        customNullIdx = [-1; 1];
        pilotIdx = [-103; -75; -39; -11; 11; 39; 75; 103];
      case 'CBW80+80' % Merge with 80MHz case, if same. Separate for now
        numGuardBands = [6; 5];
        customNullIdx = [-1; 1];
        pilotIdx = [-103; -75; -39; -11; 11; 39; 75; 103]; 
      case 'CBW160'
        numGuardBands = [6; 5];
        customNullIdx = [(-129:-127)'; (-5:-1)'; (1:5)'; (127:129)'];
        pilotIdx = [-231; -203; -167; -139; -117; -89; -53; -25; 25; 53; 89; 117; 139; 167; 203; 231]; 
      otherwise  % CBW20
        numGuardBands = [4; 3];
        customNullIdx = [];
        pilotIdx = [-21; -7; 7; 21];
    end

    pilotIdx = pilotIdx + FFTLen/2 + 1; % Convert to 1-based indexing
    customNullIdx = customNullIdx + FFTLen/2 + 1; % Convert to 1-based indexing
    % Get non-data subcarrier indices for the whole bandwidth
    nonDataIdx = [(1:numGuardBands(1))'; FFTLen/2+1; ...
        (FFTLen-numGuardBands(2)+1:FFTLen)'; pilotIdx; customNullIdx];
    dataIdx = setdiff((1:FFTLen)', sort(nonDataIdx));
end
end