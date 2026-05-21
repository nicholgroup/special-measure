function smprintconn(smdata)
% SMPRINTCONN  Print connection status for all instruments in smdata.
%
%   smprintconn(smdata)
%
%   For each smdata.inst(i) with a .data.inst connection field, prints:
%     - instrument index, name, object type
%     - connection status: OPEN / CLOSED / INVALID / EMPTY
%     - connection address (resource name, host:port, or COM port)
%     - whether .data.fn / .data.args are populated (for smrestoreconn)
%
%   Instruments without a .data.inst field are listed as "no conn object".
%
%   See also: smfillconnargs, smrestoreconn.

HDR_FMT = '%-4s  %-16s  %-12s  %-8s  %-36s  %s\n';
ROW_FMT = '%-4s  %-16s  %-12s  %-8s  %-36s  %s\n';

fprintf(HDR_FMT, '#', 'Name', 'Type', 'Status', 'Address', 'fn/args');
fprintf('%s\n', repmat('-', 1, 92));

for i = 1:numel(smdata.inst)
    name = smdata.inst(i).name;
    d    = smdata.inst(i).data;

    if ~isstruct(d) || ~isfield(d, 'inst')
        fprintf(ROW_FMT, num2str(i), name, '—', '—', '—', 'no conn object');
        continue
    end

    hasFnArgs = isstruct(d) && isfield(d,'fn') && isfield(d,'args') ...
                && ~isempty(d.fn) && ~isempty(d.args);
    fnStr = boolStr(hasFnArgs);

    if isempty(d.inst)
        fprintf(ROW_FMT, num2str(i), name, 'empty', 'EMPTY', '—', fnStr);
        continue
    end

    % Try to read Type — throws on invalid/deleted objects.
    try
        objType = lower(d.inst.Type);
    catch
        fprintf(ROW_FMT, num2str(i), name, 'unknown', 'INVALID', '—', fnStr);
        continue
    end

    status  = connStatus(d.inst, objType);
    address = connAddress(d.inst, objType);

    fprintf(ROW_FMT, num2str(i), name, objType, status, address, fnStr);
end

end

% -------------------------------------------------------------------------
function s = connStatus(obj, objType)
oldStyle = strncmp(objType, 'visa-', 5) || strcmp(objType, 'tcpip') || strcmp(objType, 'serial');
if oldStyle
    try
        if strcmp(obj.Status, 'open')
            s = 'OPEN';
        else
            s = 'CLOSED';
        end
    catch
        s = 'INVALID';
    end
else
    s = 'OPEN';   % visadev / tcpclient: valid object means connected
end
end

% -------------------------------------------------------------------------
function addr = connAddress(obj, objType)
try
    switch objType
        case {'visa-gpib'}
            addr = sprintf('%s  (PA %d)', obj.RsrcName, obj.PrimaryAddress);
        case {'visa-tcpip'}
            addr = sprintf('%s', obj.RsrcName);
        case {'visa-serial'}
            addr = sprintf('%s  (%d baud)', obj.RsrcName, obj.BaudRate);
        case {'visa-usb', 'visa-vxi', 'visa-pxi', 'visa-generic'}
            addr = obj.RsrcName;
        case 'tcpip'
            addr = sprintf('%s:%d', obj.RemoteHost, obj.RemotePort);
        case 'serial'
            addr = sprintf('%s  (%d baud)', obj.Port, obj.BaudRate);
        case 'visadev'
            addr = obj.ResourceName;
        case 'tcpclient'
            addr = sprintf('%s:%d', obj.Address, obj.Port);
        otherwise
            addr = '?';
    end
catch
    addr = '(property read failed)';
end
end

% -------------------------------------------------------------------------
function s = boolStr(tf)
if tf
    s = 'yes';
else
    s = 'no';
end
end
