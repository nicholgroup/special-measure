classdef MockConn < handle
% MockConn  Lightweight mock for VISA / TCPIP / serial connection objects.
%
%   obj = smtest.MockConn('Type','visa-gpib', 'RsrcName','GPIB0::1::INSTR')
%
%   Supports dot-property access and get(obj,'Prop') — enough to satisfy
%   smfillconnargs, smprintconn, and smrestoreconn without real hardware.

    properties
        Type         = ''
        Status       = 'closed'
        RsrcName     = ''
        Vendor       = 'ni'
        RemoteHost   = ''
        RemotePort   = 0
        Port         = ''
        BaudRate     = 9600
        ResourceName = ''      % visadev
        Address      = ''      % tcpclient
        PrimaryAddress = 0     % visa-gpib
    end

    methods
        function obj = MockConn(varargin)
            for k = 1:2:numel(varargin)
                obj.(varargin{k}) = varargin{k+1};
            end
        end

        function val = get(obj, propName)
        % Mimic Instrument Control Toolbox get(obj, 'Prop').
            val = obj.(propName);
        end
    end
end
