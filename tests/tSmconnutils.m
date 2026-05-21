classdef tSmconnutils < matlab.unittest.TestCase
% Tests for smafillconnargs, smaprintconn, and smarestoreconn.
%
% Uses smtest.MockConn to simulate instrument connection objects so that
% tests run without real hardware or VISA drivers.

    methods (TestMethodSetup)
        function setup(~)
            repoRoot = fullfile(fileparts(mfilename('fullpath')), '..');
            addpath(fullfile(repoRoot, 'src', 'utils', 'toolbox'));
            addpath(fullfile(repoRoot, 'src', 'sm'));
        end
    end

    methods (TestMethodTeardown)
        function teardown(~)
            global smdata; %#ok<GVMIS>
            smdata = [];
            clear global smdata;
        end
    end

    % =====================================================================
    %  Helper: build a minimal smdata and install it as global
    % =====================================================================
    methods (Access = private)
        function installSmdata(~, specs)
        % specs is an N-by-1 struct array with fields:
        %   .name  — instrument name
        %   .data  — the .data sub-struct (may contain .inst, .fn, .args)
            global smdata; %#ok<GVMIS>
            smdata = struct();
            smdata.inst     = struct([]);
            smdata.channels = struct([]);
            for k = 1:numel(specs)
                smdata.inst(k).name     = specs(k).name;
                smdata.inst(k).device   = '';
                smdata.inst(k).data     = specs(k).data;
                smdata.inst(k).channels = {};
                smdata.inst(k).type     = 0;
                smdata.inst(k).datadim  = [1 1];
            end
        end
    end

    % =====================================================================
    %  smafillconnargs
    % =====================================================================
    methods (Test, TestTags = {'Unit', 'fillconnargs'})

        function fillVisaGpib(tc)
            global smdata; %#ok<GVMIS>
            mock = smtest.MockConn('Type','visa-gpib', ...
                'RsrcName','GPIB0::1::INSTR', 'Vendor','ni');
            specs.name = 'gpibInst';
            specs.data = struct('inst', mock);
            tc.installSmdata(specs);
            smafillconnargs();
            tc.verifyEqual(func2str(smdata.inst(1).data.fn), 'visa');
            tc.verifyEqual(smdata.inst(1).data.args, {'ni', 'GPIB0::1::INSTR'});
        end

        function fillVisaTcpip(tc)
            global smdata; %#ok<GVMIS>
            mock = smtest.MockConn('Type','visa-tcpip', ...
                'RsrcName','TCPIP0::192.168.1.2::INSTR', 'Vendor','ni');
            specs.name = 'tcpipVisa';
            specs.data = struct('inst', mock);
            tc.installSmdata(specs);
            smafillconnargs();
            tc.verifyEqual(func2str(smdata.inst(1).data.fn), 'visa');
            tc.verifyEqual(smdata.inst(1).data.args, ...
                {'ni', 'TCPIP0::192.168.1.2::INSTR'});
        end

        function fillVisaSerial(tc)
            global smdata; %#ok<GVMIS>
            mock = smtest.MockConn('Type','visa-serial', ...
                'RsrcName','ASRL1::INSTR', 'Vendor','ni');
            specs.name = 'serialVisa';
            specs.data = struct('inst', mock);
            tc.installSmdata(specs);
            smafillconnargs();
            tc.verifyEqual(func2str(smdata.inst(1).data.fn), 'visa');
            tc.verifyEqual(smdata.inst(1).data.args, {'ni', 'ASRL1::INSTR'});
        end

        function fillVisaUsb(tc)
            global smdata; %#ok<GVMIS>
            mock = smtest.MockConn('Type','visa-usb', ...
                'RsrcName','USB0::0x1234::0x5678::SN001::INSTR', 'Vendor','ni');
            specs.name = 'usbVisa';
            specs.data = struct('inst', mock);
            tc.installSmdata(specs);
            smafillconnargs();
            tc.verifyEqual(func2str(smdata.inst(1).data.fn), 'visa');
            tc.verifyEqual(smdata.inst(1).data.args, ...
                {'ni', 'USB0::0x1234::0x5678::SN001::INSTR'});
        end

        function fillTcpip(tc)
            global smdata; %#ok<GVMIS>
            mock = smtest.MockConn('Type','tcpip', ...
                'RemoteHost','10.0.0.5', 'RemotePort', 5025);
            specs.name = 'plainTcpip';
            specs.data = struct('inst', mock);
            tc.installSmdata(specs);
            smafillconnargs();
            tc.verifyEqual(func2str(smdata.inst(1).data.fn), 'tcpip');
            tc.verifyEqual(smdata.inst(1).data.args, {'10.0.0.5', 5025});
        end

        function fillSerial(tc)
            global smdata; %#ok<GVMIS>
            mock = smtest.MockConn('Type','serial', ...
                'Port','COM3', 'BaudRate', 115200);
            specs.name = 'serialPort';
            specs.data = struct('inst', mock);
            tc.installSmdata(specs);
            smafillconnargs();
            tc.verifyEqual(func2str(smdata.inst(1).data.fn), 'serial');
            tc.verifyEqual(smdata.inst(1).data.args, ...
                {'COM3', 'BaudRate', 115200});
        end

        function fillVisadev(tc)
            global smdata; %#ok<GVMIS>
            mock = smtest.MockConn('Type','visadev', ...
                'ResourceName','GPIB0::12::INSTR');
            specs.name = 'modernVisa';
            specs.data = struct('inst', mock);
            tc.installSmdata(specs);
            smafillconnargs();
            tc.verifyEqual(func2str(smdata.inst(1).data.fn), 'visadev');
            tc.verifyEqual(smdata.inst(1).data.args, {'GPIB0::12::INSTR'});
        end

        function fillTcpclient(tc)
            global smdata; %#ok<GVMIS>
            mock = smtest.MockConn('Type','tcpclient', ...
                'Address','192.168.1.10', 'Port', 4000);
            specs.name = 'modernTcp';
            specs.data = struct('inst', mock);
            tc.installSmdata(specs);
            smafillconnargs();
            tc.verifyEqual(func2str(smdata.inst(1).data.fn), 'tcpclient');
            tc.verifyEqual(smdata.inst(1).data.args, {'192.168.1.10', 4000});
        end

        function fillSkipsEmptyInst(tc)
            global smdata; %#ok<GVMIS>
            specs.name = 'noInst';
            specs.data = struct('inst', []);
            tc.installSmdata(specs);
            smafillconnargs();
            tc.verifyFalse(isfield(smdata.inst(1).data, 'fn'));
        end

        function fillSkipsNonStructData(tc)
            global smdata; %#ok<GVMIS>
            specs.name = 'plainData';
            specs.data = 42;
            tc.installSmdata(specs);
            smafillconnargs();  % should not error
            tc.verifyEqual(smdata.inst(1).data, 42);
        end

        function fillSkipsUnknownType(tc)
            global smdata; %#ok<GVMIS>
            mock = smtest.MockConn('Type','unknown-type');
            specs.name = 'weirdInst';
            specs.data = struct('inst', mock);
            tc.installSmdata(specs);
            smafillconnargs();
            tc.verifyFalse(isfield(smdata.inst(1).data, 'fn'));
        end

        function fillMultipleInstruments(tc)
            global smdata; %#ok<GVMIS>
            specs(1).name = 'gpib1';
            specs(1).data = struct('inst', ...
                smtest.MockConn('Type','visa-gpib', ...
                    'RsrcName','GPIB0::1::INSTR', 'Vendor','ni'));
            specs(2).name = 'tcp1';
            specs(2).data = struct('inst', ...
                smtest.MockConn('Type','tcpip', ...
                    'RemoteHost','10.0.0.1', 'RemotePort', 5025));
            specs(3).name = 'empty';
            specs(3).data = struct('inst', []);
            tc.installSmdata(specs);
            smafillconnargs();
            tc.verifyEqual(func2str(smdata.inst(1).data.fn), 'visa');
            tc.verifyEqual(func2str(smdata.inst(2).data.fn), 'tcpip');
            tc.verifyFalse(isfield(smdata.inst(3).data, 'fn'));
        end

        function fillVendorFallbackToNi(tc)
        % When Vendor property is empty, smafillconnargs falls back to 'ni'.
            global smdata; %#ok<GVMIS>
            mock = smtest.MockConn('Type','visa-gpib', ...
                'RsrcName','GPIB0::5::INSTR', 'Vendor','');
            specs.name = 'noVendor';
            specs.data = struct('inst', mock);
            tc.installSmdata(specs);
            smafillconnargs();
            tc.verifyEqual(smdata.inst(1).data.args{1}, 'ni');
        end
    end

    % =====================================================================
    %  smaprintconn
    % =====================================================================
    methods (Test, TestTags = {'Unit', 'printconn'})

        function printDoesNotError(tc)
            mock = smtest.MockConn('Type','visa-gpib', ...
                'RsrcName','GPIB0::1::INSTR', 'Status','open', ...
                'PrimaryAddress', 1);
            specs(1).name = 'gpib1';
            specs(1).data = struct('inst', mock);
            specs(2).name = 'noConn';
            specs(2).data = 42;
            specs(3).name = 'emptyConn';
            specs(3).data = struct('inst', []);
            tc.installSmdata(specs);
            smaprintconn();  % should complete without error
        end

        function printShowsFnArgs(tc)
            mock = smtest.MockConn('Type','tcpip', ...
                'RemoteHost','10.0.0.5', 'RemotePort', 5025, ...
                'Status','closed');
            specs.name = 'tcp1';
            specs.data = struct('inst', mock, 'fn', @tcpip, ...
                'args', {{'10.0.0.5', 5025}});
            tc.installSmdata(specs);
            output = evalc('smaprintconn()');
            tc.verifySubstring(output, 'yes');
        end

        function printShowsOpenStatus(tc)
            mock = smtest.MockConn('Type','visa-tcpip', ...
                'RsrcName','TCPIP::192.168.1.1::INSTR', 'Status','open');
            specs.name = 'openInst';
            specs.data = struct('inst', mock);
            tc.installSmdata(specs);
            output = evalc('smaprintconn()');
            tc.verifySubstring(output, 'OPEN');
        end

        function printShowsClosedStatus(tc)
            mock = smtest.MockConn('Type','serial', ...
                'Port','COM1', 'BaudRate', 9600, 'Status','closed');
            specs.name = 'closedInst';
            specs.data = struct('inst', mock);
            tc.installSmdata(specs);
            output = evalc('smaprintconn()');
            tc.verifySubstring(output, 'CLOSED');
        end

        function printModernApiShowsOpen(tc)
        % visadev/tcpclient: valid object always reports OPEN.
            mock = smtest.MockConn('Type','visadev', ...
                'ResourceName','GPIB0::12::INSTR');
            specs.name = 'modernInst';
            specs.data = struct('inst', mock);
            tc.installSmdata(specs);
            output = evalc('smaprintconn()');
            tc.verifySubstring(output, 'OPEN');
        end

        function printAllConnectionTypes(tc)
        % Smoke test: every supported type prints without error.
            types = {
                struct('Type','visa-gpib',   'RsrcName','GPIB0::1::INSTR', 'PrimaryAddress',1, 'Status','open')
                struct('Type','visa-tcpip',  'RsrcName','TCPIP::1.2.3.4::INSTR', 'Status','open')
                struct('Type','visa-serial', 'RsrcName','ASRL1::INSTR', 'BaudRate',9600, 'Status','open')
                struct('Type','visa-usb',    'RsrcName','USB0::0x1234::0::INSTR', 'Status','open')
                struct('Type','tcpip',       'RemoteHost','10.0.0.1', 'RemotePort',5025, 'Status','closed')
                struct('Type','serial',      'Port','COM4', 'BaudRate',115200, 'Status','open')
                struct('Type','visadev',     'ResourceName','GPIB0::3::INSTR')
                struct('Type','tcpclient',   'Address','192.168.0.1', 'Port',4000)
            };
            for k = 1:numel(types)
                t = types{k};
                fields = fieldnames(t);
                kvpairs = {};
                for f = 1:numel(fields)
                    kvpairs{end+1} = fields{f}; %#ok<AGROW>
                    kvpairs{end+1} = t.(fields{f}); %#ok<AGROW>
                end
                specs(k).name = sprintf('inst_%d', k); %#ok<AGROW>
                specs(k).data = struct('inst', smtest.MockConn(kvpairs{:})); %#ok<AGROW>
            end
            tc.installSmdata(specs);
            smaprintconn();  % no error
        end
    end

    % =====================================================================
    %  smarestoreconn — skip / error paths only (no real smopen)
    % =====================================================================
    methods (Test, TestTags = {'Unit', 'restoreconn'})

        function restoreSkipsNoDataInst(tc)
        % Instruments without .data.inst are silently skipped.
            specs.name = 'noConn';
            specs.data = 42;
            tc.installSmdata(specs);
            smarestoreconn();  % should not error
        end

        function restoreSkipsEmptyInstNoFnArgs(tc)
        % Empty .data.inst and no fn/args → prints a message, does not error.
            specs.name = 'deadInst';
            specs.data = struct('inst', []);
            tc.installSmdata(specs);
            output = evalc('smarestoreconn()');
            tc.verifySubstring(output, 'no fn/args');
        end

        function restoreReportsOKForOpenConn(tc)
        % A valid + open connection prints OK and is left untouched.
            mock = smtest.MockConn('Type','visa-gpib', ...
                'RsrcName','GPIB0::1::INSTR', 'Status','open');
            specs.name = 'liveInst';
            specs.data = struct('inst', mock);
            tc.installSmdata(specs);
            output = evalc('smarestoreconn()');
            tc.verifySubstring(output, 'OK');
        end

        function restoreEmptyInstWithFnArgsFails(tc)
        % Empty inst but fn/args present → tries to call fn, which will
        % fail (no real VISA driver) → prints creation-failed message.
            specs.name = 'deadWithFn';
            specs.data = struct('inst', [], ...
                'fn', @visa, 'args', {{'ni', 'GPIB0::1::INSTR'}});
            tc.installSmdata(specs);
            output = evalc('smarestoreconn()');
            % Expect either 'creation failed' (no VISA driver) or 'recreated'
            tc.verifyTrue( ...
                contains(output, 'creation failed') || ...
                contains(output, 'recreated'), ...
                'Expected creation-failed or recreated message');
        end
    end

end
