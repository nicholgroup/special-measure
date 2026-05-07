function [tottime] = Tmeas(file)
% Tmeas(file) determines the total measurement time for a pulsed scan.
% 
% [totttime]=Tmeas(file) takes a file whose scan was configured with fConfSeq_vX and
% determines the total measurement time the scan acquired data for in
% seconds
%
% file can be a string or a cell array. It can be a single file or
% multiple.


if ~exist('file','var')
    [~,~, file] = smgetfile('sm*.mat');
end

if ~iscell(file)
    file = {file};
end

tottime = zeros(1,length(file));
for i=1:length(file)

d = load(file{i});
time = d.data{2};
starttime = datetime(time(1),'ConvertFrom','datenum');
firstnan = min(find(isnan(d.data{1})));
if ~isempty(firstnan)
    endtime = datetime(time(firstnan-1),'ConvertFrom','datenum');
    else
        endtime = datetime(time(end),'ConvertFrom','datenum');
    end
    tottime(i) = [hours(duration(endtime-starttime,'Format','h'))*3600]; %total time of scan in seconds
end

end

