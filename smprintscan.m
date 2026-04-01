function smprintscan(scan)
% function smprintscan(scan)

global smdata;

if ~isfield(scan.loops, 'npoints')
    [scan.loops.npoints] = deal([]);
end

if ~isfield(scan.loops, 'ramptime')
     [scan.loops.ramptime] = deal([]);
end


if isfield(scan, 'trafofn')
  fprintf('Global transformations:\n-----------------------\n');
    for i = 1:length(scan.trafofn)
        fprintf('%s\n%', func2str(scan.trafofn{i}));
    end
  fprintf('\n');
end


Points = zeros(1,length(scan.loops));
RampTimes = zeros(1,length(scan.loops));

for i = 1:length(scan.loops)

    ch = smchanlookup(scan.loops(i).setchan);
    
    try
        Points(i) = scan.loops(i).npoints;
    catch 
        Points(i) = 0;
    end
    try
        RampTimes(i) = scan.loops(i).ramptime;
    catch 
        RampTimes(i) = 0;
    end
    
    
    if isempty(scan.loops(i).npoints)
        scan.loops(i).npoints = length(scan.loops(i).rng);
    elseif isempty(scan.loops(i).rng)
        scan.loops(i).rng = 1:scan.loops(i).npoints;
    end
    
    if isempty(scan.loops(i).ramptime)
        scan.loops(i).ramptime = nan(length(ch), 1);
    end

    fprintf('Loop %d\n-------\nx = %.3g to %.3g,   %d  points\n\n', ...
        i, scan.loops(i).rng([1, end]), scan.loops(i).npoints);

    fprintf('Channels set : ')
    fprintf('%-15s ', smdata.channels(ch).name);
    fprintf('\nRamptimes    : ')
    fprintf('%-4.2d s/point    ', scan.loops(i).ramptime);
    if isfield(scan.loops(i), 'trafofn')
            fprintf('\nTransform''s  : ')
            for j = 1:length(scan.loops(i).trafofn)
                if iscell(scan.loops(i).trafofn)
                    if isempty(scan.loops(i).trafofn{j})
                        fprintf('%-15s ', 'identity');
                    else
                        fprintf('%-15s ', func2str(scan.loops(i).trafofn{j}));
                    end
                else
                    if isempty(scan.loops(i).trafofn(j).fn)
                        fprintf('%-15s ', 'identity');
                    else
                        fprintf('%-15s ', func2str(scan.loops(i).trafofn(j).fn));
                    end
                end
            end
    end
    ch = smchanlookup(scan.loops(i).getchan);
    fprintf('\n\nChannels read: ')    
    fprintf('%-15s ', smdata.channels(ch).name);
    fprintf('\n\n');
end

% Estimate scan time

Points = Points(Points~=0);  % Remove all zeros from npoints list - these don't impact scan time
RampTimes = RampTimes(RampTimes~=0);% Remove all zeros from ramptimes list - these don't impact scan time



scanTime = 0;  % Estimated scan time in seconds
for i=1:length(Points)
    iterations = 1;
    for j=i:length(Points)
        iterations = iterations * Points(j);
    end
    if i<length(RampTimes) % only relevant when a scan has no rampTime
        scanTime = scanTime + iterations*RampTimes(i);
    end
   
end
scanTime = seconds(scanTime);
endTime = datetime('now')+scanTime;
fprintf('-------\n The scan will take at least %.2f hours \n If you start now it would finish at %s at the earliest\n-------\n ', hours(scanTime),endTime);


