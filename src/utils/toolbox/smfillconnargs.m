function smdata = smfillconnargs(smdata)
% SMFILLCONNARGS  Populate .data.fn / .data.args from live connection objects.
%
%   smdata = smfillconnargs(smdata)
%
%   For each smdata.inst(i) whose .data.inst field holds a live connection
%   object, extracts the parameters needed to recreate it and writes:
%
%       smdata.inst(i).data.fn   — function handle (e.g. @visa, @tcpip)
%       smdata.inst(i).data.args — cell array of arguments for fn
%
%   Afterwards the connection can be recreated with:
%       obj = smdata.inst(i).data.fn(smdata.inst(i).data.args{:});
%       fopen(obj);   % old-style objects only; visadev/tcpclient open on construction
%
%   Supported object types (old Instrument Control Toolbox API):
%       visa-gpib, visa-tcpip, visa-serial, visa-usb, visa-generic, visa-pxi
%       tcpip, serial
%   Supported modern API (R2019b+):
%       visadev (R2022a+), tcpclient
%
%   Instruments that are skipped (with a printed message):
%       - .data is not a struct, or has no .inst field
%       - .data.inst is empty or an invalid/deleted object
%       - object type is not in the list above

for i = 1:numel(smdata.inst)
    d = smdata.inst(i).data;

    if ~isstruct(d) || ~isfield(d, 'inst') || isempty(d.inst)
        continue
    end

    try
        [fn, args] = extractConnInfo(d.inst);
    catch err
        fprintf('smfillconnargs: inst %d (%s): skipped — %s\n', ...
            i, smdata.inst(i).name, err.message);
        continue
    end

    smdata.inst(i).data.fn   = fn;
    smdata.inst(i).data.args = args;
    fprintf('smfillconnargs: inst %d (%s): OK  fn=@%s  args={%s}\n', ...
        i, smdata.inst(i).name, func2str(fn), strjoin(cellfun(@num2str, args, 'UniformOutput', false), ', '));
end

end

% -------------------------------------------------------------------------
function [fn, args] = extractConnInfo(obj)
% Return (fn, args) such that fn(args{:}) recreates the connection object.
%
% Dispatch is on obj.Type (not class), because all old-style VISA subtypes
% share class 'visa' but have distinct Type strings ('visa-gpib', etc.).
% Accessing obj.Type also validates the object — it throws for deleted objects.

try
    objType = lower(obj.Type);
catch err
    error('invalid or deleted object (%s)', err.message);
end

switch objType

    % ------------------------------------------------------------------
    % All old-style VISA subtypes: recreate with visa(vendor, rsrcname).
    % RsrcName encodes the full address; vendor defaults to 'ni' if the
    % property is inaccessible (common on some MATLAB/toolbox versions).
    % ------------------------------------------------------------------
    case {'visa-gpib', 'visa-tcpip', 'visa-serial', ...
          'visa-usb',  'visa-vxi',   'visa-pxi',    'visa-generic'}
        rsrcname = obj.RsrcName;
        vendor   = readVendor(obj);
        fn   = @visa;
        args = {vendor, rsrcname};

    % ------------------------------------------------------------------
    % Old-style tcpip / serial objects (not going through VISA layer).
    % ------------------------------------------------------------------
    case 'tcpip'
        fn   = @tcpip;
        args = {obj.RemoteHost, obj.RemotePort};

    case 'serial'
        fn   = @serial;
        args = {obj.Port, 'BaudRate', obj.BaudRate};

    % ------------------------------------------------------------------
    % Modern API (R2022a+ visadev, R2019b+ tcpclient).
    % ------------------------------------------------------------------
    case 'visadev'
        fn   = @visadev;
        args = {obj.ResourceName};

    case 'tcpclient'
        fn   = @tcpclient;
        args = {obj.Address, obj.Port};

    otherwise
        error('unrecognised connection type ''%s''', objType);
end

end

% -------------------------------------------------------------------------
function vendor = readVendor(obj)
% Try to read the Vendor property. Falls back to 'ni' (NI-VISA) if the
% property is not accessible — common on certain MATLAB/toolbox versions.
try
    vendor = get(obj, 'Vendor');
    if isempty(vendor)
        vendor = 'ni';
    end
catch
    vendor = 'ni';
end
end
