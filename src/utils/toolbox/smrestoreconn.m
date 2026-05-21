function smrestoreconn()
% SMRESTORECONN  Validate and restore dead instrument connections in smdata.
%
%   smrestoreconn()
%
%   Operates on the global smdata (SM convention).
%   For each smdata.inst(i) that has a .data.inst connection field:
%
%     valid + open   → prints OK, leaves untouched.
%     valid + closed → calls smopen(i) to reopen it.
%     missing/dead   → recreates the object from .data.fn / .data.args,
%                      stores it in smdata.inst(i).data.inst, then smopen(i).
%     missing + no fn/args → prints a message and skips.
%
%   Instruments without a .data struct or .data.inst field are silently
%   skipped (they have no connection object to manage).
%
%   If creation or smopen fails the error is printed and that instrument
%   is skipped.
%
%   See also: smfillconnargs, smprintconn, smopen, smclose.

global smdata

for i = 1:numel(smdata.inst)
    d    = smdata.inst(i).data;
    name = smdata.inst(i).name;

    if ~isstruct(d) || ~isfield(d, 'inst')
        continue
    end

    [valid, isopen] = connStatus(d.inst);

    if valid && isopen
        fprintf('smrestoreconn: inst %d (%s): OK\n', i, name);
        continue
    end

    if valid && ~isopen
        % Object exists but connection is closed — reopen via smopen.
        try
            smopen(i);
            fprintf('smrestoreconn: inst %d (%s): reopened\n', i, name);
        catch err
            fprintf('smrestoreconn: inst %d (%s): smopen failed — %s\n', i, name, err.message);
        end
        continue
    end

    % Object is missing or deleted — recreate from fn/args.
    hasFn   = isfield(d, 'fn')   && ~isempty(d.fn);
    hasArgs = isfield(d, 'args') && ~isempty(d.args);
    if ~hasFn || ~hasArgs
        fprintf('smrestoreconn: inst %d (%s): dead, no fn/args — run smfillconnargs first\n', ...
            i, name);
        continue
    end

    try
        obj = d.fn(d.args{:});
    catch err
        fprintf('smrestoreconn: inst %d (%s): creation failed — %s\n', i, name, err.message);
        continue
    end

    smdata.inst(i).data.inst = obj;

    try
        smopen(i);
        fprintf('smrestoreconn: inst %d (%s): recreated and opened\n', i, name);
    catch err
        fprintf('smrestoreconn: inst %d (%s): smopen failed — %s\n', i, name, err.message);
    end
end

end

% -------------------------------------------------------------------------
function [valid, isopen] = connStatus(obj)
% valid  — object exists and is not deleted/invalid
% isopen — connection is active (for modern API objects, valid implies open)

if isempty(obj)
    valid  = false;
    isopen = false;
    return
end

try
    obj.Type;        % throws on deleted/invalid objects
    valid = true;
catch
    valid  = false;
    isopen = false;
    return
end

try
    isopen = strcmp(obj.Status, 'open');
catch
    isopen = true;   % modern API (visadev/tcpclient): valid means connected
end

end
