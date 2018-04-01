%READCSI Extract and interpret CSI values.
%   READCSI(BASE_FILENAME, SHOULD_SAVE, SHOULD_PLOT) opens the 
%   BASE_FILENAME.pcap to extract channel state information (CSI) dumped 
%   using nexmon's CSI Extractor firmware patch. If SHOULD_SAVE is 1,
%   extracted values will be written to BASE_FILENAME.mat. If SHOULD_PLOT
%   is 1, then CSI values will directly be plotted.
%
%   Payload format:
%        14 byte: Ethernet header
%        20 byte: IPv4 header
%         8 byte: UDP header
%         4 byte: Magic String "CSIS"(0x43 0x53 0x49 0x53)
%         6 byte: HW address
%         4 byte: reserved
%      1020 byte: 255 CSI value pairs
%
%   CSI value pair format:
%         2 byte: two's complement real
%         2 byte: two's complement imag
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%          ###########   ###########   ##########    ##########           %
%         ############  ############  ############  ############          %
%         ##            ##            ##   ##   ##  ##        ##          %
%         ##            ##            ##   ##   ##  ##        ##          %
%         ###########   ####  ######  ##   ##   ##  ##    ######          %
%          ###########  ####  #       ##   ##   ##  ##    #    #          %
%                   ##  ##    ######  ##   ##   ##  ##    #    #          %
%                   ##  ##    #       ##   ##   ##  ##    #    #          %
%         ############  ##### ######  ##   ##   ##  ##### ######          %
%         ###########    ###########  ##   ##   ##   ##########           %
%                                                                         %
%            S E C U R E   M O B I L E   N E T W O R K I N G              %
%                                                                         %
% License:                                                                %
%                                                                         %
% Copyright (c) 2018 Jakob Link, Matthias Schulz                          %
%                                                                         %
% Permission is hereby granted, free of charge, to any person obtaining a %
% copy of this software and associated documentation files (the           %
% "Software"), to deal in the Software without restriction, including     %
% without limitation the rights to use, copy, modify, merge, publish,     %
% distribute, sublicense, and/or sell copies of the Software, and to      %
% permit persons to whom the Software is furnished to do so, subject to   %
% the following conditions:                                               %
%                                                                         %
% 1. The above copyright notice and this permission notice shall be       %
%    include in all copies or substantial portions of the Software.       %
%                                                                         %
% 2. Any use of the Software which results in an academic publication or  %
%    other publication which includes a bibliography must include         %
%    citations to the nexmon project a) and the paper cited under b) or   %
%    the thesis cited under c):                                           %
%                                                                         %
%    a) "Matthias Schulz, Daniel Wegemer and Matthias Hollick. Nexmon:    %
%        The C-based Firmware Patching Framework. https://nexmon.org"     %
%                                                                         %
%    b) "Matthias Schulz, Jakob Link, Francesco Gringoli, and Matthias    %
%        Hollick. Shadow Wi-Fi: Teaching Smartphones to Transmit Raw      %
%        Signals and to Extract Channel State Information to Implement    %
%        Practical Covert Channels over Wi-Fi. Accepted to appear in      %
%        Proceedings of the 16th ACM International Conference on Mobile   %
%        Systems, Applications, and Services (MobiSys 2018), June 2018."  %
%                                                                         %
%    c) "Matthias Schulz. Teaching Your Wireless Card New Tricks:         %
%        Smartphone Performance and Security Enhancements through Wi-Fi   %
%        Firmware Modifications. Dr.-Ing. thesis, Technische Universität  %
%        Darmstadt, Germany, February 2018."                              %
%                                                                         %
% 3. The Software is not used by, in cooperation with, or on behalf of    %
%    any armed forces, intelligence agencies, reconnaissance agencies,    %
%    defense agencies, offense agencies or any supplier, contractor, or   %
%    research associated.                                                 %
%                                                                         %
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS %
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF              %
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  %
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY    %
% CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,    %
% TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE       %
% SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                  %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function csi_buff = readcsi(base_filename, should_save, should_plot)

    %% parameters
    % configure WLAN object and get parameters
    cfgVHT = wlanVHTConfig;             % legacy mode
    %cfgVHT.Modulation = 'OFDM';           % OFDM
    cfgVHT.ChannelBandwidth = 'CBW80';    % 20MHz
    cfgVHT.MCS = 0;                       % BPSK 6Mbps
    cfgVHT.NumTransmitAntennas = 1;       % one antenna

    FFTLength = helperFFTLength(cfgVHT);  % get fft length
    % get data, pilot, and null carrier indices
    [dataIdx,pilotIdx] = helperSubcarrierIndices(cfgVHT,'VHT');
    dpIdx = [dataIdx; pilotIdx];
    nullIdx = 1:FFTLength;
    nullIdx(dpIdx) = [];

    %% helper
    % anonymous function: sign extend and convert binary 14-bit-twocompl to int16
    twos2dec = @(x) typecast(uint16(bin2dec(x)),'int16');

    %% read file
    p = readpcap();
    p.open([base_filename '.pcap']);
    %n = min(length(p.all()),100);
    n = p.length();
    p.from_start();

    ts = zeros(n,1);
    % matrix to store calculated csi for each packet
    csi_buff = complex(zeros(n,FFTLength),0);
    k = 1; % target matrix counter
    % iterate over each packet
    while (k <= n)
        f = p.next();
        if isempty(f)
            disp('no more frames');
            break;
        end
        if f.header.orig_len ~= 1076
            continue;
        end
        ts(k) = double(f.header.ts_sec) + double(f.header.ts_usec) * 1e-6;
        payload = f.payload;

        % convert to binary
        binary = dec2bin(payload,32);
        %disp(dec2hex(payload(14),8))
        % remove none-csi
        binary = binary(15:end,:);
        % extract imaginary and real parts
        real_b = binary(:,1:16);
        imag_b = binary(:,17:end);
        % group to cells
        real_b_cells = num2cell(real_b,2);
        imag_b_cells = num2cell(imag_b,2);
        % apply twos2dec for each cell
        real_d = cellfun(twos2dec,real_b_cells);
        imag_d = cellfun(twos2dec,imag_b_cells);
        % build complex numbers
        cmplx = complex(double(real_d), double(imag_d));

        % throw away constant value at beginning
        % and extract used carriers
        if FFTLength <= 254
            % for 20 and 40 MHz
            cmplx_bw = fftshift(cmplx(2:FFTLength+1));
        else 
            % exact format for 80 MHz currently unknown
            % only 255 values in CSI UDP, but FFTLength is 256
            cmplx_bw = fftshift([cmplx(1:FFTLength-1); 10000]);
        end

        % zero set null carriers
        cmplx_bw(nullIdx) = 0.0;
        % store csi
        csi_buff(k,:) = cmplx_bw.';
        k = k + 1;
    end

    %% save results
    if (should_save)
        save([base_filename '.mat'], 'csi_buff', '-v7.3');
    end

    %% plot
    if (should_plot)
        % y-Axis ticks and ticklabels for phase
        ticky = [-180:45:180];
        tickyL = {'-180','','-90','','0°', '', '90°', '', '180°'};
        % x-Axis
        x = -FFTLength/2:FFTLength/2-1;

        for n = 1:size(csi_buff,1)
            plot_chan = csi_buff(n,:);

            figure(1);

            % plot magnitude
            subplot(2,1,1)
            bha = bar(x,abs(plot_chan),'BarWidth',1);
            set(bha,'FaceColor',[0 0 1])
            set(bha,'EdgeColor',[0 0 0])
            title('CSI Magnitude')
            xlabel('Subcarrier Index')
            ylabel('Magnitude')
            grid on
            myAxis = axis();
            axis([min(x), max(x), myAxis(3), myAxis(4)])

            % plot phase
            subplot(2,1,2)
            bha = bar(x,rad2deg(angle(plot_chan)),'BarWidth',1);
            set(bha,'FaceColor',[1 0 0])
            set(bha,'EdgeColor',[0 0 0])
            title('CSI Phase')
            xlabel('Subcarrier Index')
            ylabel('Phase in °')
            grid on
            set(gca,'YTick',ticky)
            set(gca,'YTickLabel',tickyL)
            myAxis = axis();
            axis([min(x), max(x), myAxis(3), myAxis(4)])

            % wait for user input
            waitforbuttonpress();
        end

    end

end