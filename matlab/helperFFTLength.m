function Nfft = helperFFTLength(cfg)
% helperFFTLength Return the number of FFT points used in OFDM modulation
%
%   NFFT = helperFFTLength(CFGFORMAT) returns the FFT size for the
%   specified format configuration object, CFGFORMAT.
%
%   NFFT is a scalar representing the number of FFT points.
%
%   CFGFORMAT is the format configuration object of type <a href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a>, 
%   <a href="matlab:help('wlanHTConfig')">wlanHTConfig</a>, or <a href="matlab:help('wlanNonHTConfig')">wlanNonHTConfig</a>, which specifies the parameters for
%   the VHT, HT-Mixed, and Non-HT formats, respectively.
%
%   NFFT = helperFFTLength(CHANBW) returns the FFT size for the specified
%   channel bandwidth. CHANBW must be one of 'CBW5', 'CBW10', 'CBW20',
%   'CBW40', 'CBW80' or 'CBW160'.
%
%   Example: Return FFT size for a VHT format configuration. 
%
%   cfgVHT = wlanVHTConfig;
%   Nfft = helperFFTLength(cfgVHT)
%
%   Nfft = helperFFTLength(cfgVHT.ChannelBandwidth)

%   Copyright 2015 The MathWorks, Inc.

%#codegen

if ischar(cfg)
    coder.internal.errorIf( ~any(strcmp(cfg, {'CBW5', 'CBW10', ...
            'CBW20', 'CBW40', 'CBW80', 'CBW160'})), ...
        'wlan:helperFFTLength:InvalidChBandwidth');
    
    chanBW = cfg; 
else    
    validateattributes(cfg, {'wlanVHTConfig','wlanHTConfig', ...
        'wlanNonHTConfig'}, {'scalar'}, mfilename, ...
        'format configuration object');

    coder.internal.errorIf(isa(cfg,'wlanNonHTConfig') && ...
        ~strcmp(cfg.Modulation,'OFDM'), ...
        'wlan:helperFFTLength:InvalidNonHTModulation');

    chanBW = cfg.ChannelBandwidth;
end

switch chanBW
    case 'CBW40'
        Nfft = 128;
    case 'CBW80'
        Nfft = 256;
    case 'CBW160'
        Nfft = 512;
    otherwise % 'CBW20', 'CBW10', 'CBW5'
        Nfft = 64;
end

end