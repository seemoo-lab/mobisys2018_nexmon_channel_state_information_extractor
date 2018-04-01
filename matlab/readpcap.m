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
% Copyright (c) 2018 Matthias Schulz                                      %
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

classdef readpcap < handle
    %READPCAP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fid;
        global_header;
        prev_len;
    end
    
    methods
        function open(obj, filename)
            obj.fid = fopen(filename);
            
            % should be 0xA1B2C3D4
            obj.global_header.magic_number = fread(obj.fid, 1, '*uint32');

            % major version number
            obj.global_header.version_major = fread(obj.fid, 1, '*uint16');

            % minor version number
            obj.global_header.version_minor = fread(obj.fid, 1, '*uint16');

            % GMT to local correction
            obj.global_header.thiszone = fread(obj.fid, 1, '*int32');

            % accuracy of timestamps
            obj.global_header.sigfigs = fread(obj.fid, 1, '*uint32');

            % max length of captured packets, in octets
            obj.global_header.snaplen = fread(obj.fid, 1, '*uint32');

            % data link type
            obj.global_header.network = fread(obj.fid, 1, '*uint32');
        end
        
        function frame = next(obj)
            % timestamp seconds
            frame.header.ts_sec = fread(obj.fid, 1, '*uint32');

            % timestamp microseconds
            frame.header.ts_usec = fread(obj.fid, 1, '*uint32');

            % number of octets of packet saved in file
            frame.header.incl_len = fread(obj.fid, 1, '*uint32');

            % actual length of packet
            frame.header.orig_len = fread(obj.fid, 1, '*uint32');

            if isempty(frame.header.incl_len)
                frame = [];
                return;
            end

            % packet data
            if (mod(frame.header.incl_len,4)==0)
                frame.payload = fread(obj.fid, frame.header.incl_len/4, '*uint32');
            else
                frame.payload = fread(obj.fid, frame.header.incl_len, '*uint8');
            end
        end
        
        function frame = next_header(obj)
            % timestamp seconds
            frame.header.ts_sec = fread(obj.fid, 1, '*uint32');

            % timestamp microseconds
            frame.header.ts_usec = fread(obj.fid, 1, '*uint32');

            % number of octets of packet saved in file
            frame.header.incl_len = fread(obj.fid, 1, '*uint32');

            % actual length of packet
            frame.header.orig_len = fread(obj.fid, 1, '*uint32');

            if isempty(frame.header.incl_len)
                frame = [];
                return;
            end

            fseek(obj.fid, frame.header.incl_len, 0);
        end
        
        function from_start(obj)
            fseek(obj.fid, 24, -1);
        end
        
        function frames = all(obj)
            i = 1;
            frames = cell(1);
            obj.from_start();
            while true
                frame = obj.next();

                if isempty(frame)
                    break;
                end
                
                frames{i} = frame;
                i = i + 1;
            end
        end
        
        function len = length(obj)
            len = 0;
            obj.from_start();
            f = obj.next_header();
            while ~isempty(f)
                len = len + 1;
                f = obj.next_header();
            end
        end
    end
    
end

