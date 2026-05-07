function [out fileDir] = get_files(ffilter)
%get_files(ffilter) is a wrapper function for uigetfile
%
% See also smgetfile.m.


if ~exist('ffilter','var')
    ffilter = '';
end
[out fileDir] = uigetfile(ffilter,'MultiSelect','On');
if isempty(out)
    return
end
if ~iscell(out)
    out = {out};
end
%out = sort(out);
end